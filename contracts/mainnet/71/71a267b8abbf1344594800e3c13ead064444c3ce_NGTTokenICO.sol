pragma solidity ^0.4.23;

contract owned {
    address public owner;

    constructor() public {
        owner = 0x318d9e2fFEC1A7Cd217F77f799deBAd1e9064556;
    }

    modifier onlyOwner {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }
}

contract NGTToken {
    function transfer(address _recipient, uint256 _value) public returns (bool success);
}

contract NGTTokenICO is owned {

    constructor() public {
        // Add Values to Initialize during the contract deployment
    }

    event EtherTransfer(address indexed _from,address indexed _to,uint256 _value);

    function withdrawEther(address _account) public onlyOwner payable returns (bool success) {
        _account.transfer(address(this).balance);

        emit EtherTransfer(this, _account, address(this).balance);
        return true;
    }

    function destroyContract() public onlyOwner {
        if (msg.sender == owner) {
            selfdestruct(owner);
        }
    }

    function tokenDrop(NGTToken token, address[] recipients, uint256[] values) public onlyOwner{
        for (uint256 i = 0; i < recipients.length; i++) {
            token.transfer(recipients[i], values[i]);
        }
    }

    function () payable public {
        // Receive Ether for Presale and ICO
    }

}