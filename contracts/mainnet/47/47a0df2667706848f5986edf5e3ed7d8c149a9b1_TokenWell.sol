/**
 *Submitted for verification at Etherscan.io on 2021-03-17
*/

pragma solidity ^0.6.0;

// Simple public version of the TokenWell concept
// (public means anyone can pump)
// SPDX-License-Identifier: Apache-2.0
// heckles to @deanpierce

contract TokenWell {
    
    address public token = 0x382f5DfE9eE6e309D1B9D622735e789aFde6BADe; // GST
    ERC20 erc20 = ERC20(token);

    // address public owner = 0x7ab874Eeef0169ADA0d225E9801A3FfFfa26aAC3; // me

    uint public lastPumpTime = 0;
    uint public interval = 60*10; // number of seconds in a day

    uint public flowRate = 1;
    uint public flowGuage = 100;

    function getBalance() public view returns(uint balance) {
        balance = erc20.balanceOf(address(this));
    }
    
    function pump() public returns(uint balance) {
        // require(msg.sender==owner,"NOT YOU");
        require((now-lastPumpTime)>interval, "TOO SOON");
        // lastPumpTime = now;
        
        balance = erc20.balanceOf(address(this));
        erc20.transfer(msg.sender,balance/flowGuage*flowRate); // send 1% of the current balance
    }
    
    //function transferOwnership(address newOwner) public {
    //    require(msg.sender==owner,"NOT YOU");
    //    owner = newOwner;
    //}
}


interface ERC20{
    //function approve(address spender, uint256 value)external returns(bool);
    //function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
}