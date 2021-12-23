// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract MockRandom {

    // These two variables are to power the commit & confirm randomness system.
    uint256 neededBlockHash = 1;
    mapping(uint256 => bytes32) blockHashes;

    mapping(address => uint256) storageForSomeReason;

    event Reveal(bytes32 randomness);

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

    function getRandomResult(bytes32 input, uint256 blockNumber) internal view returns (bytes32) {
        require(blockHashes[blockNumber] != bytes32(0));
        return keccak256(abi.encode(input, blockHashes[blockNumber]));
    }

    function commit() external {
        require(storageForSomeReason[msg.sender] <= 1);
        uint256 blockToGet = fillBlockHash();
        storageForSomeReason[msg.sender] = blockToGet;
    }

    function reveal() external returns (bytes32 seed) {
        require(storageForSomeReason[msg.sender] > 1);
        require(storageForSomeReason[msg.sender] <= block.number);
        fillBlockHash();
        storageForSomeReason[msg.sender] = 1;
        seed = getRandomResult(bytes32(uint256(uint160(msg.sender))), storageForSomeReason[msg.sender]);
        emit Reveal(seed);
    }
}
