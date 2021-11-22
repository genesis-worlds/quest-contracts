// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./NFTBase.sol";
import "./Quest.sol";

contract NFT is NFTBase {
    // Quest Contracts Information
    uint256 public currentQuestContractId;
    address[] public allQuestContracts;
    mapping(address => uint256) public questContractIds;

    // Token Data
    mapping(uint64 => uint256) tokenTypeLimits;
    mapping(uint64 => uint256) tokenTypeCounts;
    uint256 public nftsCreated = 0;
    mapping(uint256 => bytes32) public tokenData;

    // Events
    event SetQuestContract(uint256 id, address indexed quest);
    event TokenStats(uint256 tokenId, bytes32 data);
    event TokenTypeLimit(uint64 tokenType, uint256 limit);

    /**
     * @dev Initializes the contract by setting a `name`, a `symbol` and a `baseURI` to the token collection.
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI
    ) NFTBase(name, symbol, baseURI) {
        setQuestContract(address(0));
    }

    modifier onlyCurrentQuestContract {
        require(questContractIds[_msgSender()] == currentQuestContractId);
        _;
    }

    modifier onlyAllQuestContracts {
        require(questContractIds[_msgSender()] > 0);
        _;
    }

    function setQuestContract(address quest) public onlyAdmin {
        uint256 id = questContractIds[quest];
        if (id == 0) {
            allQuestContracts.push(quest);
            id = allQuestContracts.length;
            require(id < 2**64);
            questContractIds[quest] = id;
            if (id > 1) {
                require(Quest(quest).setQuestContractId(id));
            }
        }
        currentQuestContractId = id;

        emit SetQuestContract(id, quest);
    }

    function getUserQuestAddress(uint256 id, address user) internal pure returns (address)  {
        uint256 addr = (uint256(uint160(user)) | (uint256(uint64(id) ** 2**192)));
        return address(uint160(addr));
    }

    // user need to approve spending tokens
    function goOnQuest(uint256[] memory tokenIds, address owner) public onlyCurrentQuestContract {
        Quest quest = Quest(allQuestContracts[currentQuestContractId]);
        address userQuestAddress = getUserQuestAddress(currentQuestContractId, owner);
        for (uint256 i = 0; i < tokenIds.length; i += 1) {
            require(ownerOf(tokenIds[i]) == owner);
            _transfer(owner, userQuestAddress, tokenIds[i]);
        }
    }
    
    // To check again
    // Can be called by the current or any previous quest contract; ensures that people can always get their tokens out.
    function returnFromQuest(uint256[] memory tokenIds, bytes32[] memory stats, address user) public onlyAllQuestContracts {
        uint256 id = questContractIds[_msgSender()];
        Quest quest = Quest(allQuestContracts[id]);
        require(id > 0);
        address userQuestAddress = getUserQuestAddress(id, user);
        for (uint256 i = 0; i < tokenIds.length; i += 1) {
            _transfer(userQuestAddress, user, tokenIds[i]);
            require(stats[i].length > 0);
            tokenData[tokenIds[i]] = stats[i];
        }
    }

    function updateStats(uint256 tokenId, bytes32 data) external onlyCurrentQuestContract {
        _updateStats(tokenId, data);
    }

    // Check again
    // Lets the current quest mint tokens, per the current quest’s logic, and subject to limits on each type of token. Does not specify what the type of the token is; that’s for quest contracts and front ends.
    function mintToken(uint64 tokenType, address recipient, bytes32 data) external onlyCurrentQuestContract returns (uint256 tokenId) {
        uint256 tokenNumber = tokenTypeCounts[tokenType] + 1;
        require(tokenNumber <= tokenTypeLimits[tokenType]);
        unchecked {
            tokenId = tokenType << 192 | tokenNumber;
        }
        tokenTypeCounts[tokenType] = tokenNumber;
        _updateStats(tokenId, data);
        _mint(recipient, tokenId);
    }

    // Setting 0 turns off minting, setting 0xff makes it theoretically infinite.
    function setTokenTypeLimit(uint256 tokenType, uint256 limit) external onlyAdmin {
        tokenTypeLimits[uint64(tokenType)] = limit;
        emit TokenTypeLimit(uint64(tokenType), limit);
    }

    function _updateStats(uint256 tokenId, bytes32 data) internal {
        require(data.length > 0, "can't accidently set to zero");
        tokenData[tokenId] = data;
        emit TokenStats(tokenId, data);
    }
}
