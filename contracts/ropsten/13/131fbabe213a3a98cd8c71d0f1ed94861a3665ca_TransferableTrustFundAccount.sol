/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

pragma solidity ^0.5.0;

contract TransferableTrustFundAccount {
    address owner;

    constructor() public {
        owner = msg.sender;
    }

    function withdrawAll() public {
        require(owner == msg.sender);
        msg.sender.transfer(address(this).balance);
    }

    function withdrawAmount(uint256 amount) public {
        require(owner == msg.sender);
        require(address(this).balance >= amount);
        msg.sender.transfer(amount);
    }

    function() external payable {}

    function transferAccount(address newAccount) public {
    require(owner == msg.sender);
    require(newAccount != address(0));
    owner = newAccount;
    }

    function terminateAccount() public {
    require(owner == msg.sender);
    selfdestruct(msg.sender);
    }
}