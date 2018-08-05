pragma solidity ^0.4.16;


contract owned {
    constructor() public { owner = msg.sender; }

    address owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}


contract ERC20 {
    function balanceOf(address tokenOwner) public constant returns (uint256 balance);
    function transfer(address to, uint256 tokens) public returns (bool success);
}


contract AddressManager is owned {

    mapping (address => bool) _tankByAddress;

    function setTank(address tankAddress) public onlyOwner {
        _tankByAddress[tankAddress] = true;
    }

    function removeTank(address tankAddress) public onlyOwner {
        _tankByAddress[tankAddress] = false;
    }

    function isTank(address tankAddress) public constant returns (bool) {
        return _tankByAddress[tankAddress];
    }
}


contract Wallet {

    address _addressManagerAddress;

    constructor(address addressManagerAddress) public {
        _addressManagerAddress = addressManagerAddress;
    }

    function () payable public {}

    function transferEther(address toAddress, uint256 amount) public {
        require(AddressManager(_addressManagerAddress).isTank(msg.sender));
        toAddress.transfer(amount);
    }

    function transferToken(address token, address toAddress, uint256 amount) public {
        require(AddressManager(_addressManagerAddress).isTank(msg.sender));
        ERC20(token).transfer(toAddress, amount);
    }
}