/*
    
    Implements the Initial Distribution of MilitaryToken™, the
    true cryptocurrency token for www.MilitaryToken.io "Blockchain 
    for a better world". Copyright 2017, 2018 by MilitaryToken, LLC.
    
    All of the following might at times be used to refer to this coin: "MILS", 
    "MILs", "MIL$", "$MILS", "$MILs", "$MIL$", "MilitaryToken". In social 
    settings we prefer the text "MILs" but in formal listings "MILS" and "$MILS" 
    are the best symbols. In the Solidity code, the official symbol can be found 
    below which is "MILS". 
  
    Portions of this code fall under the following license where noted as from
    "OpenZepplin":

    The MIT License (MIT)

    Copyright (c) 2016 Smart Contract Solutions, Inc.

    Permission is hereby granted, free of charge, to any person obtaining
    a copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/

pragma solidity 0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 * @dev From https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
        return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Token {
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
}

    
/**
    @title InitialDistribution
    @author Stanford K. Easley

*/
contract InitialDistribution {

    using SafeMath for uint256;

    Token public militaryToken;
    address public owner;
    uint public lockUpEnd;
    uint public awardsEnd;
    mapping (address => uint256) public award;
    mapping (address => uint256) public withdrawn;
    uint256 public totalAwards = 0;
    uint256 public currentAwards = 0;

    /**
        @param _militaryToken The address of the MilitaryToken contract.
    */
    constructor(address _militaryToken) public {
        militaryToken = Token(_militaryToken);
        owner = msg.sender;
        lockUpEnd = now + (365 days);
        awardsEnd = now + (730 days);
    }

    /**
        @dev Restricts privileged functions to the contract owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
        @dev Functions that can only be called before the end of the lock-up period.
    */
    modifier preEnd() {
        require(now < lockUpEnd);
        _;
    }

    /**
        @dev Functions that can only be called after the end of the lock-up period.
    */
    modifier postEnd() {
        require(lockUpEnd <= now);
        _;
    }

    /**
        @dev Functions that can only be called if the awards are fully funded.
     */
    modifier funded() {
        require(currentAwards <= militaryToken.balanceOf(address(this)));
        _;
    }

    modifier awardsAllowed() {
        require(now < awardsEnd);
        _;
    }

    /**
        @notice Changes contract ownership.
        @param  newOwner The address of the new owner.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        if(newOwner != address(0)) {
            owner = newOwner;
        }
    }

    /**
        @notice Award MILs to people that will become available after lock-up period (if funded).
        @param _to The address that the MILs are being awarded to.  After lock-up period awardee will be able to acquire awarded tokens.
        @param _MILs The number of MILS being awarded.
    */
    function awardMILsTo(address _to, uint256 _MILs) public onlyOwner awardsAllowed {
        
        award[_to] = award[_to].add(_MILs);
        totalAwards = totalAwards.add(_MILs);
        currentAwards = currentAwards.add(_MILs);
    }

    /**
        @notice Transfers awarded MILs to the caller&#39;s account.
    */
    function withdrawMILs(uint256 _MILs) public postEnd funded {
        uint256 daysSinceEnd = (now - lockUpEnd) / 1 days;
        uint256 maxPct = min(((daysSinceEnd / 30 + 1) * 10), 100);
        uint256 allowed = award[msg.sender];
        allowed = allowed * maxPct / 100;
        allowed -= withdrawn[msg.sender];
        require(_MILs <= allowed);
        militaryToken.transfer(msg.sender, _MILs);
        withdrawn[msg.sender] += _MILs;
        currentAwards -= _MILs;
    }

    /**
        @notice Transfers any un-awarded MILs to the contract owner.
    */
    function recoverUnawardedMILs() public  {
        uint256 MILs = militaryToken.balanceOf(address(this));
        if(totalAwards < MILs) {
            militaryToken.transfer(owner, MILs - totalAwards);
        }
    }

    function min(uint a, uint b) private pure returns (uint) {
        return a < b ? a : b;
    }
}