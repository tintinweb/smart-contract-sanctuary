/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;    }

    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;}
            uint256 c = a * b;
            require(c / a == b, "SafeMath: multiplication overflow");
            return c;}

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;    }
}
interface InterfaceDigi {
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function totalSupply() external view returns (uint);
    function transfer(address receiver, uint tokens) external returns (bool success);
    function transferFrom(address sender, address receiver, uint tokens) external returns (bool success);
}

interface InterfaceDaoGov {
  function getDaoGovAddress() external view returns (address);
  function getDigitradeAddress() external view returns (address);
}

 contract ProposalPool is SafeMath{

    address public digitrade;
    address pool;

    uint _poolSupply;
    uint startingSupply;

    constructor(address _digitrade){
     digitrade = _digitrade;
     pool = address(this);
     startingSupply = 20_000_000e18;
    }

    function fundStrength() public view returns (uint){
        return (InterfaceDigi(digitrade).balanceOf(pool) / startingSupply) * 100;
    }

    function getPoolSupply() public view returns (uint){
        return InterfaceDigi(digitrade).balanceOf(pool) ;
    }

    function getMaxAvailiableTokens() external view returns(uint){
        //.02 * (InterfaceDigi(digitrade).balanceOf(pool)**2) /startingSupply -> .02 * fundStrength() *10000 -> fundStrength() * 200;
        uint availiableTokens = fundStrength() * 200;
        return availiableTokens;
    }

    




}