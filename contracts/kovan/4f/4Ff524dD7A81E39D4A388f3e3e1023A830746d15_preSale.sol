pragma solidity 0.8.0;

//SPDX-License-Identifier: MIT Licensed

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract preSale{
    
    IERC20 public presaleToken;
    using SafeMath for uint256;
    address payable public owner;
    
    uint256 public tokenPerEth;
    bool public preSaleEnabled;
    uint256 public soldTokenPreSale;
    uint256 public boughtTokenPreSale;
    
    mapping(address => uint256) public balances;
    mapping(address => bool) public claimed;
    

    modifier onlyowner() {
        require(msg.sender == owner,"ERC20: Not an owner");
        _;
    }
    
    event Bought(address _user, uint256 _amount);
    event Sold(address _user, uint256 _amount);
    
    constructor(IERC20 _token) {
        owner = payable(msg.sender); 
        presaleToken = _token;
        tokenPerEth = 1000000;
        preSaleEnabled = true;
    }
    
    receive() external payable{}
    
    
    // to buy  token during preSale time => for web3 use
    function Buy() payable public {
        uint256 numberOfTokens = ETHToToken(msg.value);
        require(preSaleEnabled ,"ERC20: PreSale Not Started Yet");
        presaleToken.transferFrom(owner, msg.sender, numberOfTokens);
        boughtTokenPreSale = boughtTokenPreSale.add(numberOfTokens);
        emit Bought(msg.sender, numberOfTokens);
    }
    function Sell(uint256 _amount) public {
        
        uint256 ethAmount = tokentoETH(_amount);
        require(preSaleEnabled ,"ERC20: PreSale Not Started Yet");
        require(ethAmount <= address(this).balance ,"Insufficent Contract Funds");
        presaleToken.transferFrom(msg.sender, owner, _amount);
        payable(msg.sender).transfer(ethAmount);
        soldTokenPreSale = soldTokenPreSale.add(_amount);
        emit Sold(msg.sender, _amount);
    }
    
    
    // to check number of token for given ETH
    function ETHToToken(uint256 _amount) public view returns(uint256){
        return _amount.mul(tokenPerEth).mul(10**presaleToken.decimals()).div(1 ether);
    }
    // to check number of ETH for given token
    function tokentoETH(uint256 _amount) public view returns(uint256){
        return _amount.mul(1 ether).div(10**presaleToken.decimals()).div(tokenPerEth);
    }
    
    // to change Price of the token
    function setPrice(uint256 _tokenPerEth) external onlyowner{
        tokenPerEth = _tokenPerEth;
    }
    
    function setPreSaleEnabled(bool set) external onlyowner{
        preSaleEnabled = set;
    }
    
    // transfer ownership
    function transferownership(address payable _newowner) external onlyowner{
        owner = _newowner;
    }
    
    // to draw funds for liquidity
    function transferFunds(uint256 _value) external onlyowner returns(bool){
        owner.transfer(_value);
        return true;
    }
    
    function getCurrentTime() public view returns(uint256){
        return block.timestamp;
    }
    
    function contractBalanceETH() external view returns(uint256){
        return address(this).balance;
    }
    
    function getContractTokenAllowance() external view returns(uint256){
        return presaleToken.allowance(owner, address(this));
    }
    function getContractTokenBalance() external view returns(uint256){
        return presaleToken.balanceOf(address(this));
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