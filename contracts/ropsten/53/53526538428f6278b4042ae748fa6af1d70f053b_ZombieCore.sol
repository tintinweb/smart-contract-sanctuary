pragma solidity ^0.5.12;

import "./zombieMarket.sol";
import "./zombieFeeding.sol";
import "./zombieAttack.sol";

contract ZombieCore is ZombieMarket,ZombieFeeding,ZombieAttack {

    string public constant name = "MyCryptoZombie";
    string public constant symbol = "MCZ";

    function() external payable {
    }

    function withdraw() external onlyOwner {
        owner.transfer(address(this).balance);
    }

    function checkBalance() external view onlyOwner returns(uint) {
        return address(this).balance;
    }

}