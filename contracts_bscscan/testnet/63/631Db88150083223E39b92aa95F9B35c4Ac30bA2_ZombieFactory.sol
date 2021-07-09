/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

// SPDX-License-Identifier: UNLICENSED
// 0x631Db88150083223E39b92aa95F9B35c4Ac30bA2

pragma solidity 0.6.12;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract ZombieFactory {
    using SafeMath for uint;
    
    uint dnaDigits = 16;
    uint dnaModulus = 10 ** dnaDigits;
    
    struct Zombie {
        uint id;
        string name;
        uint dna;
    }
    
    Zombie[] public zombies;
    
    event NewZombie(uint zombieId, string name, uint dna);
    
    function getZombiesSize() external view returns(uint) {
        return zombies.length;
    }
    
    function _createZombie(string memory _name, uint _dna) internal {
        uint id = zombies.length + 1;
        zombies.push(Zombie(id, _name, _dna));
        emit NewZombie(id, _name, _dna);
    }
    
    function _generateRandomDna(string memory _str) internal view returns(uint) {
        uint rand = uint(keccak256(abi.encodePacked(_str, block.difficulty, now)));
        return rand.mod(dnaModulus);
    }
    
    function createRandomZombie(string memory _name) external {
        uint randDna = _generateRandomDna(_name);
        _createZombie(_name, randDna);
    }
    
}