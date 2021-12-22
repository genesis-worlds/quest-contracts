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

    function withdrawAnyErc20(address token) external onlyAdmin {
        IERC20(token).safeTransfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    function setPackPrice(uint256 price) external onlyAdmin {
        packPrice = price;
    }

    function buyItemPack() public nonReentrant {
        IERC20(GENESIS).safeTransferFrom(msg.sender, address(this), packPrice);

        // mint itemPack NFT
        uint256 packId = erc721.mintToken(uint64(1), msg.sender, bytes32(0));
        require(buyPackBlockNumber[packId] <= 1);
        buyPackBlockNumber[packId] = erc721.fillBlockHash();
        neededBlockNumber = block.number + 1;
    }

    function openItemPack(uint256 packId) public {
        require(erc721.ownerOf(packId) == msg.sender);

        uint256 blockNumber = buyPackBlockNumber[packId];
        require(blockNumber > 1 && blockNumber <= block.number);
        buyPackBlockNumber[packId] = 1;
        erc721.fillBlockHash();
        bytes32 seed = erc721.getRandomResult(bytes32(uint256(uint160(msg.sender))), blockNumber);
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
