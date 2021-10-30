/**
 *Submitted for verification at BscScan.com on 2021-10-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

abstract contract ERC20 {
    function transfer(address _to, uint256 _value) public virtual returns(bool);
    function balanceOf(address tokenOwner) public view virtual returns(uint balance);
    function transferFrom(address from, address to, uint tokens) public virtual returns(bool success);
}

contract AirDropContract
{
    struct Claimer {
        uint total;
        uint times;
        address person;
    }

    mapping(address => Claimer) public claimers;

    address public owner;
    ERC20 public token;
    uint256 public tokendecimals;
    uint256 public airdropvalueinwei;
    uint256 public maxvalue;
    uint256 public maxtimes;

    constructor(address _tokenAddr, uint256 _decimals) {
        token = ERC20(_tokenAddr);
        tokendecimals = _decimals;
        airdropvalueinwei = 1 * 10**tokendecimals; //Default: 1
        maxvalue = 1 * 10**tokendecimals; //Default: 1;
        maxtimes = 1;
        owner = msg.sender;
    }

    function executeAirdrop() public {

        Claimer storage currentClaimer = claimers[msg.sender];

        uint256 totalClaimed = currentClaimer.total;

        require(totalClaimed + airdropvalueinwei <= maxvalue, "Maximum claimed amount reached");

        uint256 timesClaimed = currentClaimer.times;

        require(timesClaimed < maxtimes, "Maximum claimed times reached");

        token.transfer(msg.sender, airdropvalueinwei);

        claimers[msg.sender].total = totalClaimed + airdropvalueinwei;
        claimers[msg.sender].times = timesClaimed + 1;
        claimers[msg.sender].person = msg.sender;
    }

    function setTokenAddress(address newValue) public returns (bool success)
    {
        require(msg.sender == owner, 'Forbidden');

        token = ERC20(newValue);
        return true;
    }

    function setTokenDecimals(uint256 newValue) public returns (bool success)
    {
        require(msg.sender == owner, 'Forbidden');

        tokendecimals = newValue;
        return true;
    }

    function setAirdropValue(uint256 newValueInWei) public returns (bool success)
    {
        require(msg.sender == owner, 'Forbidden');

        airdropvalueinwei = newValueInWei;
        return true;
    }

    function setMaxClaimValue(uint256 newValue) public returns (bool success)
    {
        require(msg.sender == owner, 'Forbidden');

        maxvalue = newValue;
        return true;
    }

    function setMaxClaimTimes(uint256 newValue) public returns (bool success)
    {
        require(msg.sender == owner, 'Forbidden');

        maxtimes = newValue;
        return true;
    }

    function setOwner(address newValue) public returns (bool success)
    {
        require(msg.sender == owner, 'Forbidden');

        owner = newValue;
        return true;
    }

    function ownersRescue(uint256 amountinwei) public {
        require(msg.sender == owner, 'Forbidden');

        token.transfer(msg.sender, amountinwei);
    }
}