/**
 *Submitted for verification at Etherscan.io on 2021-10-10
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.0;

contract owned {
    address payable owner;
    constructor ()  {
        owner = msg.sender;
    }
    modifier onlyOwner{
        require(msg.sender==owner);
        _;
    }
}

contract mortal is owned {
    function destroy() public onlyOwner{
        selfdestruct(owner);
    }
}

contract Faucet is mortal {
    function withdraw(uint withdraw_amount) public {
        require(withdraw_amount<=0.1 ether);
        msg.sender.transfer(withdraw_amount);
    }
    fallback() external payable {}
    receive() external payable {}
}