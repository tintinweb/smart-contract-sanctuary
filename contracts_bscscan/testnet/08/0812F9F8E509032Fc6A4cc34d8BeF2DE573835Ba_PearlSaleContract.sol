/**
 *Submitted for verification at BscScan.com on 2021-11-19
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-19
*/

pragma solidity ^0.8.4;

//SPDX-License-Identifier: MIT Licensed

interface IBEP20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PearlSaleContract{
    using SafeMath for uint256;
    
    address payable public owner;
    IBEP20 public token;
    
    uint256 public tokenPerBnb;
    uint256 public bnbPerToken;
    uint256 public amountRaised;
    uint256 public soldToken;
    uint256 public dumpedToken;

    bool public isBuying;
    bool public isSelling;

    modifier onlyOwner() {
        require(msg.sender == owner,"Owned: Not an owner");
        _;
    }
    
    event BuyToken(address _user, uint256 _amount);
    event SellToken(address _user, uint256 _amount);

    constructor(address payable _owner, IBEP20 _token) {
        owner = _owner; 
        token = _token;
        tokenPerBnb = 100;
        bnbPerToken = 0.001 ether;
        isBuying = true;
        isSelling= true;
         
    }
    
    receive() external payable{}

    // to buy token => for web3 use
    function buyToken() payable public {     
        require(isBuying,"SALE: Buying disabled");

        uint256 numberOfTokens = bnbToToken(msg.value);

        token.transferFrom(owner, msg.sender, numberOfTokens);

        soldToken = soldToken.add(numberOfTokens);
        amountRaised = amountRaised.add(msg.value);
        
        emit BuyToken(msg.sender, msg.value);
    }

    // to sell token => for web3 use
    function sellToken(uint256 _tokenAmount) public {     
        require(isSelling,"SALE: selling disabled");

        uint256 numberOfBnb = tokenToBnb(_tokenAmount);

        token.transferFrom(msg.sender, address(this), _tokenAmount);
        payable(msg.sender).transfer(numberOfBnb);

        dumpedToken = dumpedToken.add(_tokenAmount);

        emit SellToken(msg.sender, _tokenAmount);
    }

    function bnbToToken(uint256 _amount) public view returns(uint256){
        uint256 numberOfTokens = _amount.mul(tokenPerBnb);
        return numberOfTokens;
    }

    function tokenToBnb(uint256 _amount) public view returns(uint256){
        uint256 numberOfBnb = _amount.mul(bnbPerToken).div(10 ** token.decimals());
        return numberOfBnb;
    }
    
    // to change Price of the token for buying
    function setPriceForBuying(uint256 _price, bool _value) external onlyOwner{
        tokenPerBnb = _price;
        isBuying = _value;
    }

    // to change Price of the token for selling
    function setPriceForSelling(uint256 _price, bool _value) external onlyOwner{
        bnbPerToken = _price;
        isSelling = _value;
    }
    
    // transfer ownership
    function changeOwner(address payable _newOwner) external onlyOwner{
        owner = _newOwner;
    }

    function changeToken(address _token) external onlyOwner{
        token = IBEP20(_token);
    }
    
    function transferBnbFunds(uint256 _value) external onlyOwner{
        owner.transfer(_value);
    }

    function transferTokenFunds(uint256 _value) external onlyOwner{
        token.transfer(owner, _value);
    }
    
    function getCurrentTime() public view returns(uint256){
        return block.timestamp;
    }
    
    function getContractBalanceBnb() external view returns(uint256){
        return address(this).balance;
    }
    
    function getContractTokenBalance() external view returns(uint256){
        return token.balanceOf(address(this));
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