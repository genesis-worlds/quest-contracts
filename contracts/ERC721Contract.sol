// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721Base.sol";

interface IGameContract {
    function setGameContractId(uint256 id) external returns (bool);
}

contract ERC721Contract is ERC721Base {
    // Game Contracts Information
    address[] public allGameContracts;
    mapping(address => uint256) public gameContractIds;
    mapping(address => bool) public activeGameContracts;

    mapping(uint256 => uint256) public cooldown;
    mapping(uint256 => uint256) public cooldownOwner;

    // Token Data
    mapping(uint64 => uint256) tokenTypeLimits;
    mapping(uint64 => uint256) tokenTypeCounts;
    uint256 public nftsCreated = 0;
    mapping(uint256 => bytes32) public tokenData;

    // These two variables are to power the commit & confirm randomness system.
    uint256 neededBlockHash = 1;
    mapping(uint256 => bytes32) blockHashes;

    // Events
    event SetGameContract(uint256 id, address indexed game, bool active);
    event Cooldown(uint256 tokenId, address indexed, uint256 cooldownTime);
    event TokenStats(uint256 tokenId, bytes32 data);
    event TokenTypeLimit(uint64 tokenType, uint256 limit);

    /**
     * @dev Initializes the contract by setting a `name`, a `symbol` and a `baseURI` to the token collection.
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI
    ) ERC721Base(name, symbol, baseURI) {
        setGameContract(address(0));
    }

    modifier onlyActiveGameContract {
        require(activeGameContracts[_msgSender()]);
        _;
    }

    modifier onlyGameContract {
        require(gameContractIds[_msgSender()] > 0);
        _;
    }

    function setGameContract(address gameContract) public onlyAdmin {
        allGameContracts.push(gameContract);
        uint256 id = allGameContracts.length;
        require(id < 2**64);
        gameContractIds[gameContract] = id;
        activeGameContracts[gameContract] = true;
        if (id > 1) {
            require(IGameContract(gameContract).setGameContractId(id));
        }

        emit SetGameContract(id, gameContract, true);
    }

    function activateGameContract(address gameContract, bool isActive) external onlyAdmin {
        require(gameContractIds[gameContract] > 0);

        activeGameContracts[gameContract] = isActive;
        emit SetGameContract(gameContractIds[gameContract], gameContract, isActive);
    }

    function setNFTCooldown(uint256[] memory tokenIds, uint256 cooldownTime) external onlyActiveGameContract {
        require(cooldownTime > 1, "cooldown must be above 1");
        for(uint256 i = 0; i < tokenIds.length; i = i + 1) {
            require(cooldownOwner[tokenIds[i]] <= 1, "token must not be on cooldown");
            cooldown[tokenIds[i]] = cooldownTime;
            cooldownOwner[tokenIds[i]] = uint256(uint160(msg.sender));
            emit Cooldown(tokenIds[i], msg.sender, cooldownTime);
        } 
    }

    function clearNFTCooldown(uint256[] memory tokenIds) external onlyGameContract {
        for(uint256 i = 0; i < tokenIds.length; i = i + 1) {
            require(cooldownOwner[tokenIds[i]] == uint256(uint160(msg.sender)), "token must be on cooldown with this contract");
            cooldown[tokenIds[i]] = 1;
            cooldownOwner[tokenIds[i]] = 1;
            emit Cooldown(tokenIds[i], msg.sender, 0);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(cooldownOwner[tokenId] <= 1, "can't transfer a token used in a game");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function updateStats(uint256 tokenId, bytes32 data) external onlyActiveGameContract {
        _updateStats(tokenId, data);
    }

    function mintToken(uint64 tokenType, address recipient, bytes32 data) external onlyActiveGameContract returns (uint256 tokenId) {
        uint256 tokenNumber = tokenTypeCounts[tokenType] + 1;
        require(tokenNumber <= tokenTypeLimits[tokenType]);
        unchecked {
            tokenId = tokenType << 192 | tokenNumber;
        }
        tokenTypeCounts[tokenType] = tokenNumber;
        _updateStats(tokenId, data);
        _mint(recipient, tokenId);
    }

    /**
     * @dev Setting 0 turns off minting, setting 0xff makes it theoretically infinite.
     */
    function setTokenTypeLimit(uint256 tokenType, uint256 limit) external onlyAdmin {
        tokenTypeLimits[uint64(tokenType)] = limit;
        emit TokenTypeLimit(uint64(tokenType), limit);
    }

    function burnToken(uint256 id) external onlyActiveGameContract {
        _burn(id);
    }

    function _updateStats(uint256 tokenId, bytes32 data) internal {
        require(data != bytes32(0), "can't accidently set to zero");
        tokenData[tokenId] = data;
        emit TokenStats(tokenId, data);
    }

    /**
     * @dev This is used by any function that requires a block hash to power a random result. It's a way to lock in random results safely.
     */
    function fillBlockHash() public returns(uint256 blockToGet) {
        uint256 hashToGet = neededBlockHash;
        blockToGet = block.number + 1;
        if (hashToGet <= block.number) {
            if (block.number - hashToGet > 255) {
                hashToGet = block.number + hashToGet % 256 - 256;
            }
            blockHashes[neededBlockHash] = blockhash(hashToGet);
            neededBlockHash = blockToGet;
        }
    }

    function getRandomResult(bytes32 input, uint256 blockNumber) external view returns (bytes32) {
        require(blockHashes[blockNumber] != bytes32(0));
        return keccak256(abi.encode(input, blockHashes[blockNumber]));
    }
}
