// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./ERC721Contract.sol";

// Traits, Monsters missing
contract DungeonDelve is AccessControlEnumerable {
    using SafeERC20 for IERC20;

    ERC721Contract public erc721;

    mapping (address => uint256) public dungeonLevel;
    mapping (address => uint256) public progress;
    mapping (address => uint256) public balance;
    mapping (address => uint256) public levelBlock;

    uint256[] probabilities;
    mapping(uint256 => uint256[]) monstersByLevel;
    
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

    function setupProbabilities(uint256 baseProbability) external onlyAdmin {
        delete probabilities;
        uint256 probability = 65535;
        for (uint256 i = 0; i < 100; i = i + 1) {
            probabilities.push(probability);
            probability = probability * 1000 / baseProbability;
        }
    }

    function enterDungeon(uint256 level) external {
        require(levelBlock[msg.sender] > 1, "already in a dungeon level");
        erc721.fillBlockHash(block.number + 1);
        levelBlock[msg.sender] = block.number + 1;
    }

    function isSendersItem(uint256 item) internal {
        require(uint64(item) == 1, "must be an item");
        require(erc721.ownerOf(item) == msg.sender, "item must be owned by sender");
    }

    // function resolveFight(uint256 item1, uint256 item2, uint256 item3) external {
    //     isSendersItem(item1);
    //     isSendersItem(item2);
    //     isSendersItem(item3);

    //     uint256 traits = getTraits();
    // }
}
