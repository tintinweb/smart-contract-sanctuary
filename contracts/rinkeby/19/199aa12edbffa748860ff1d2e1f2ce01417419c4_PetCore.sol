pragma solidity ^0.5.12;

import "./PetOwnership.sol";

contract PetCore is PetOwnership {
    string public constant name = "HPet";
    string public constant symbol = "HPet";

    function() external payable {
    }

    function withdraw() external onlyOwner {
        owner.transfer(address(this).balance);
    }

    function checkBalance() external view onlyOwner returns(uint) {
        return address(this).balance;
    }
    

}