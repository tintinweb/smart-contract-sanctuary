/**
 *Submitted for verification at polygonscan.com on 2022-01-03
*/

pragma solidity >=0.7.0;

contract NamrContract {
    string private name;
    uint256 private amount;

    event onNewName(string name);
    event onNewAmount(uint256 amount);

    function setName(string memory newName) public {
        name = newName;
        emit onNewName(name);
    }

    function getName() public view returns (string memory) {
        return name;
    }

    function setAmount(uint256 newAmount) public {
        amount = newAmount;
        emit onNewAmount(amount);
    }

    function getAmount() public view returns (uint256) {
        return amount;
    }
}