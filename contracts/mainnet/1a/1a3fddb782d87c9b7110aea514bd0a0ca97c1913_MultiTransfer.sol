pragma solidity ^0.4.25;

// Professor Rui-Shan Lu Team
// Rs Lu  <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="94e6e7f8e1a6a4a4a4d4f3f9f5fdf8baf7fb">[email&#160;protected]</a>m>
// Lursun <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="4f233a3d3c3a21767e7b7f7e7c0f28222e2623612c2022">[email&#160;protected]</a>>

contract ERC20{
    function transfer(address _to, uint256 _value) public;
    function transferFrom(address _from, address _to, uint256 _value) public;
    function approve(address spender, uint tokens) public;
}


contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "msg.sender != owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}


contract MultiTransfer is Owned {
    constructor() Owned() public {}
    event MultiTransferEvent(address tokenContract, uint amount);
    function send(ERC20 ercContract,address[] memory addresses, uint[] memory values, function(ERC20, address, uint) func) private {
        require(addresses.length == values.length, "addresses.length != values.length");
        // require(addresses.length <= 255, "too many people");
        uint amount;
        
        for (uint64 i = 0; i < addresses.length; i++) {
            amount += values[i];
            func(ercContract, addresses[i],values[i]);
        }
        emit MultiTransferEvent(ercContract, amount);
    }
    function ethTransfer(ERC20 ercContract, address target, uint amount) private {
        target.transfer(amount);
    }
    function transfer(ERC20 ercContract, address target, uint amount) private {
        ercContract.transfer(target, amount);
    }
    function transferFrom(ERC20 ercContract, address target, uint amount) private {
        ercContract.transferFrom(msg.sender, target, amount);
    }
    
    function mutiEthTransfer(address[] addresses, uint[] values) external payable{
        send(ERC20(0x0), addresses, values, ethTransfer);
        if (address(this).balance > 0) {
            ethTransfer(ERC20(0x0), msg.sender, address(this).balance);
        }
    }
    
    function mutiTransfer(ERC20 tokenContract, address[] addresses, uint[] values) external onlyOwner {
        send(tokenContract, addresses, values, transfer);
    }
    
    function mutiTransferFrom(ERC20 tokenContract, address[] addresses, uint[] values) external {
        send(tokenContract, addresses, values, transferFrom);
    }
}