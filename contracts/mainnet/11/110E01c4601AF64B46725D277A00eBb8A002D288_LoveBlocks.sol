pragma solidity ^0.4.24;

/**
 * @title SafeMath
 */
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract LoveBlocks {
    using SafeMath for uint256;

    event NewLoveBlock(string message, bool encrypted, uint timestamp);

    struct LoveBlock {
        string message;
        bool encrypted;
        uint timestamp;
    }

    LoveBlock[] public locks;

    mapping (uint => address) private lockToOwner;
    mapping (address => uint) private ownerToNumber;

    function myLoveBlockCount() external view returns(uint) {
        return ownerToNumber[msg.sender];
    }

    function totalLoveBlocks() external view returns(uint) {
        return locks.length;
    }

    function createLoveBlock(string _message, bool _encrypted) external {
        uint id = locks.push(LoveBlock(_message, _encrypted, now)) - 1;
        lockToOwner[id] = msg.sender;
        ownerToNumber[msg.sender] = ownerToNumber[msg.sender].add(1);
        emit NewLoveBlock(_message, _encrypted, now);
    }

    function myLoveBlocks() external view returns(uint[]) {
        uint[] memory result = new uint[](ownerToNumber[msg.sender]);

        uint counter = 0;
        for (uint i = 0; i < locks.length; i++) {
            if (msg.sender == lockToOwner[i]) {
                result[counter] = i;
                counter = counter.add(1);
            }
        }
        return result;
    }
}