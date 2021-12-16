// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./ERC721Contract.sol";

contract GameContract is AccessControlEnumerable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // TODO
    address public GENESIS;
    ERC721Contract public erc721;

    uint256 public gameContractId;
    uint256 public packPrice = 1000 * 1e18;
    uint256 public neededBlockNumber;

    // These two variables are to power the commit & confirm randomness system.
    uint256 neededBlockHash = 1;
    mapping(uint256 => bytes32) blockHashes;

    mapping(uint256 => uint256) public buyPackBlockNumber;

    modifier onlyAdmin {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "ERC721: must have admin role"
        );
        _;
    }

    constructor(ERC721Contract _erc721) {
        erc721 = _erc721;
    }

    /**
     * @dev Sets `gameContractId`
     */
    function setGameContractId(uint256 id) public onlyAdmin returns (bool) {
        gameContractId = id;
        return true;
    }


    /**
     * @dev This is used by any function that requires a block hash to power a random result. It’s a way to lock in random results safely.
     */
    function fillBlockHash(uint256 blockNumber) public returns (bytes32 seed) {
        if (neededBlockHash > 1) {
            if (block.number - blockNumber > 255) {
                blockNumber = block.number + blockNumber % 256 - 256;
            }
            blockHashes[blockNumber] = blockhash(blockNumber);
            neededBlockHash = 1;
            seed = blockHashes[blockNumber];
        }
    }

    function getRandomResult(bytes32 input, uint256 blockNumber) internal view returns (bytes32) {
        require(blockHashes[blockNumber] != bytes32(0));
        return keccak256(abi.encode(input, blockHashes[blockNumber]));
    }

    function withdrawAnyErc20(address token) external onlyAdmin {
        IERC20(token).safeTransfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    function setPackPrice(uint256 price) external onlyAdmin {
        packPrice = price;
    }

    function buyItemPack() public nonReentrant {
        fillBlockHash(0);
        IERC20(GENESIS).safeTransferFrom(msg.sender, address(this), packPrice);

        // mint itemPack NFT
        uint256 packId = erc721.mintToken(uint64(1), msg.sender, bytes32(0));
        require(buyPackBlockNumber[packId] == 0);
        buyPackBlockNumber[packId] = block.number + 1;
        neededBlockNumber = block.number + 1;
    }

    function openItemPack(uint256 packId) public {
        require(erc721.ownerOf(packId) == msg.sender);
        uint256 blockNumber = buyPackBlockNumber[packId];
        require(blockNumber > 0);
        bytes32 seed = fillBlockHash(blockNumber);
        require(seed != bytes32(0));
        erc721.burnToken(packId);
        seed = createPackItem(seed);
        seed = createPackItem(seed);
        seed = createPackItem(seed);
        seed = createPackItem(seed);
        seed = createPackItem(seed);
    }

    function parse256(bytes32 data, uint256 location) external {
    }

    function randomRoll(bytes32 seed, address ethAddress) external returns (bytes32) {

    }

    function createPackItem(bytes32 seed) public returns (bytes32) {
        
    }
}
