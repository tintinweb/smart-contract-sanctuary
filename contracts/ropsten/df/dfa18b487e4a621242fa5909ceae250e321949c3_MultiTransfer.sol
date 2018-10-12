pragma solidity ^0.4.25;

// Professor Rui-Shan Lu Team
// Rs Lu  <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="e597968990d7d5d5d5a58288848c89cb868a88">[email&#160;protected]</a>>
// Lursun <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="cba7beb9b8bea5f2fafffbfaf88baca6aaa2a7e5a8a4a6">[email&#160;protected]</a>>

contract ERC20{
    function transfer(address _to, uint256 _value) public;
    function transferFrom(address _from, address _to, uint256 _value) public ;
}


contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}


contract MultiTransfer is Owned {
    constructor() Owned() public {}
    event MultiTransfer(address tokenContract, uint amount);
    function mutiEthTransfer(address[] addresses, uint[] values) payable public {
        require(addresses.length == values.length);
        require(addresses.length <= 255, "too many people");
        uint256 beforeValue = msg.value;
        uint256 afterValue = 0;
        
        for (uint8 i = 0; i < addresses.length; i++) {
            afterValue = afterValue + values[i];
            addresses[i].transfer(values[i]);
        }
        // send back remaining value to sender
        uint256 remainingValue = beforeValue - afterValue;
        if (remainingValue > 0) {
            msg.sender.transfer(remainingValue);
        }
        emit MultiTransfer(0x0, beforeValue);
    }
    
    function mutiTransfer(address tokenContract, address[] addresses, uint[] values) onlyOwner public {
        require(addresses.length == values.length);
        require(addresses.length <= 255, "too many people");
        ERC20 ercContract = ERC20(tokenContract);
        uint amount;
        for(uint i = 0; i < addresses.length; i++) {
            amount += values[i];
            ercContract.transfer(addresses[i], values[i]);
        }
        emit MultiTransfer(tokenContract, amount);
    }
    
    function mutiTransferFrom(address tokenContract, address[] addresses, uint[] values) public {
        require(addresses.length == values.length);
        require(addresses.length <= 255, "too many people");
        ERC20 ercContract = ERC20(tokenContract);
        uint amount;
        for(uint i = 0; i < addresses.length; i++) {
            amount += values[i];
            ercContract.transferFrom(msg.sender, addresses[i], values[i]);
        }
        emit MultiTransfer(tokenContract, amount);
    }
}