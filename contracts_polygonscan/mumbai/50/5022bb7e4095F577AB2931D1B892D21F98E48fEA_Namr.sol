pragma solidity ^0.8.0;

import "./Ownable.sol";

contract Namr is Ownable {
    string private name;
    string private premiumName;

    uint256 premiumNamePrice = 0.001 ether;

    event onNewName(string name);
    event onNewPremiumName(string name);

    function setName(string memory newName) public {
        name = newName;
        emit onNewName(name);
    }

    function getName() public view returns (string memory) {
        return name;
    }

    function setPremiumName(string memory newPremiumName) public payable {
        require(msg.value == premiumNamePrice);
        premiumName = newPremiumName;
        emit onNewPremiumName(name);
    }

    function getPremiumName() public view returns (string memory) {
        return premiumName;
    }

    function withdraw() external onlyOwner {
        address payable _owner = payable(owner());
        _owner.transfer(address(this).balance);
    }
}