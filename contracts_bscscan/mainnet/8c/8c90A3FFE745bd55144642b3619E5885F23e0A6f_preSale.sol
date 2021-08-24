/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

pragma solidity ^0.8.4;

//SPDX-License-Identifier: MIT Licensed

interface IBEP20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract preSale{
    
    IBEP20 public token;
    using SafeMath for uint256;

    address payable public owner;
    
    uint256 public tokenPerBnb;
    uint256 public preSaleTime;
    uint256 public amountRaised;
    uint256 public soldToken;
    uint256 public maxSell;
    uint256 public referralpercent;
    uint256[5] public bonusPercent = [100,200,300,400,500];

    modifier onlyOwner() {
        require(msg.sender == owner,"BEP20: Not an owner");
        _;
    }
    
    event BuyToken(address _user, uint256 _amount);

    constructor(address payable _owner,address _token) {
        owner = _owner;
        token = IBEP20(_token);
        tokenPerBnb = 10000000;
        preSaleTime = 1638295200;
        referralpercent = 25;
    }
    
    receive() payable external{}
    
    // to buy token during preSale time => for web3 use
    function buyToken(address _referral) payable public {

        require(block.timestamp < preSaleTime,"BEP20: PreSale over");
        uint256 numberOfTokens = bnbToToken(msg.value);
        if(msg.value == 0.01 ether){
            numberOfTokens = numberOfTokens.add(numberOfTokens.mul(bonusPercent[0]).div(1000));
        }else if(msg.value > 0.01 ether && msg.value <=0.1 ether){
            numberOfTokens = numberOfTokens.add(numberOfTokens.mul(bonusPercent[1]).div(1000));
        }else if(msg.value > 0.1 ether && msg.value <=1 ether){
            numberOfTokens = numberOfTokens.add(numberOfTokens.mul(bonusPercent[2]).div(1000));    
        }else if(msg.value > 1 ether && msg.value <=10 ether){
            numberOfTokens = numberOfTokens.add(numberOfTokens.mul(bonusPercent[3]).div(1000));
        }else if(msg.value > 10 ether && msg.value <=100 ether){
            numberOfTokens = numberOfTokens.add(numberOfTokens.mul(bonusPercent[4]).div(1000));
        }        
        token.transferFrom(owner, _referral, numberOfTokens.mul(referralpercent).div(100));
        amountRaised = amountRaised.add(msg.value);
        soldToken = soldToken.add(numberOfTokens);
         emit BuyToken(msg.sender, numberOfTokens);

    }
    
    // to check number of token for given BNB
    function bnbToToken(uint256 _amount) public view returns(uint256){
        uint256 numberOfTokens = _amount.mul(tokenPerBnb).div(1e18);
        return numberOfTokens.mul(1e8);
    }
    
    function getCurrentTime() external view returns(uint256){
        return block.timestamp;
    }
    
    // to Change claim time
    function setPreSaleTime(uint256 _time) external onlyOwner{
        preSaleTime = _time;
    }
    
    // to change price
    function setPriceOfToken(uint256 _price) external onlyOwner{
        tokenPerBnb = _price;
    }
    
    // to ref percent
    function setRefPercent(uint256 _percent) external onlyOwner{
        referralpercent = _percent;
    }

    function changebonuspercent(uint256 _bpercent0,uint256 _bpercent1,uint256 _bpercent2,uint256 _bpercent3,uint256 _bpercent4) external onlyOwner{
        bonusPercent[0] = _bpercent0;
        bonusPercent[1] = _bpercent1;
        bonusPercent[2] = _bpercent2;
        bonusPercent[3] = _bpercent3;
        bonusPercent[4] = _bpercent4;

    }

    // transfer ownership
    function changeOwner(address payable _newOwner) external onlyOwner{
        owner = _newOwner;
    }
    
    // to draw funds for liquidity
    function migrateFunds(uint256 _value) external onlyOwner{
        owner.transfer(_value);
    }
    
    function getContractBalance() external view returns(uint256){
        return address(this).balance;
    }
    
    function getContractTokenBalance() external view returns(uint256){
        return token.allowance(owner, address(this));
    }
    
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}