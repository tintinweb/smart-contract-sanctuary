/**
 *Submitted for verification at Etherscan.io on 2021-03-18
*/

pragma solidity ^0.6.0;

// TokenWell - slowly dispense tokens at a regulated interval
// (public means anyone can pump)
// SPDX-License-Identifier: Apache-2.0
// heckles to @deanpierce
//
// This instance intended as the primary nweb GST payout well.
//
//   more information at scantoken.org and nweb.io

contract TokenWell {
    
    address public token = 0x382f5DfE9eE6e309D1B9D622735e789aFde6BADe; // GST
    //address public token = 0xaD6D458402F60fD3Bd25163575031ACDce07538D; // ropDAI (testing)
    ERC20 erc20 = ERC20(token);

    address public owner = 0x7ab874Eeef0169ADA0d225E9801A3FfFfa26aAC3; // me
    mapping (address => bool) public pumpers;

    uint public lastPumpTime = 0;
    uint public interval = 60*60*24*7; // one week intervals

    uint public flowRate = 1; // dispense 1% each time
    uint public flowGuage = 100;

    function getBalance() public view returns(uint balance) {
        balance = erc20.balanceOf(address(this));
    }
    
    function pump() public returns(uint haul) {
        require(pumpers[msg.sender],"NOT YOU"); // only pumpers may get free tokens
        require((now-lastPumpTime)>interval, "TOO SOON"); // enforce time interval between pumps
        lastPumpTime = now;
        
        // send 0.1% of the current balance
        haul = erc20.balanceOf(address(this))/flowGuage*flowRate;
        erc20.transfer(msg.sender,haul);
    }
    
    function transferOwnership(address newOwner) public {
        require(msg.sender==owner,"NOT YOU");
        owner = newOwner;
    }
    
    function addPumper(address newAddr) public {
        require(msg.sender==owner,"NOT YOU");
        pumpers[newAddr]=true;
    }
    
    function delPumper(address badAddr) public {
        require(msg.sender==owner,"NOT YOU");
        pumpers[badAddr]=false;
    }
}


interface ERC20{
    //function approve(address spender, uint256 value)external returns(bool);
    //function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
}