/**
 *Submitted for verification at BscScan.com on 2021-12-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IERC20 {
    function balanceOf(address _owner) view external  returns (uint256 balance);
    function transfer(address _to, uint256 _value) external  returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external  returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }   
}

contract AVETPresale {
    using SafeMath for uint256;
    IERC20 public token;
    address payable public owner;
    
    uint8 decimals = 8; 
    uint256 DEC = 10 ** uint256(decimals);
    uint256 public tokensPerBnb = 1800000000 * DEC; // 1,800,000,000 token presale price per BNB
    uint256 public minBnbInvestInWei; // minimum wei amount that can be invested per wallet address
    uint256 public maxBnbInvestInWei; // maximum wei amount that can be invested per wallet address

    mapping(address => uint256) public investments; // total wei invested per address
    
    modifier onlyOwner() {
        require(msg.sender == owner,"ERC20: Not owner");
        _;
    }

    constructor(address _token) {
       owner = payable(msg.sender);
       token = IERC20(_token);
    }
   
    function tokentobnb(uint256 _numberOfTokens) public view returns(uint256){
        uint256 a = _numberOfTokens.mul(1 ether).div(tokensPerBnb);
        return a;
    }

    function bnbtotoken(uint256 amount) public view returns(uint256){
        return (amount.mul(tokensPerBnb)).div(1 ether);
    }
     
    function setSaleInfo(
        uint256 _minInvestInWei,
        uint256 _maxInvestInWei
    ) external onlyOwner {
        require(_minInvestInWei <= _maxInvestInWei, "Min. wei investment > max. wei investment");

        minBnbInvestInWei = _minInvestInWei;
        maxBnbInvestInWei = _maxInvestInWei;
    }

    function invest() public payable returns(bool){
        uint256 totalInvestmentInWei = investments[msg.sender].add(msg.value);
        require(totalInvestmentInWei >= minBnbInvestInWei, "Min investment not reached");
        require(maxBnbInvestInWei == 0 || totalInvestmentInWei <= maxBnbInvestInWei, "Max investment reached");

        investments[msg.sender] = totalInvestmentInWei;
        uint256 _numberOfTokens = bnbtotoken(msg.value);
        token.transfer(msg.sender, _numberOfTokens);
        return true;
    }

    function changePrice(uint256 _amount) public onlyOwner returns(bool){
        require(_amount > 0);
        tokensPerBnb = _amount * DEC;
        return true;
    }

    function getter(uint256 _value) onlyOwner public returns(bool){
        owner.transfer(_value);
        return true;
    }
    
    function withdrawTokens() onlyOwner public returns (bool) {
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }
}