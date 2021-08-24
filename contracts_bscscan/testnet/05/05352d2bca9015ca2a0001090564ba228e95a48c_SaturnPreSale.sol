/**
 *Submitted for verification at BscScan.com on 2021-08-23
*/

/**
 *Submitted for verification at BscScan.com on 2021-03-31
*/

pragma solidity 0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
	
    constructor() public {
        owner = msg.sender;
    }
	
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

interface Token {
    function transfer(address _to, uint _amount) public returns (bool success);
    function balanceOf(address _owner) public constant returns (uint balance);
}

contract SaturnPreSale is Ownable {

    using SafeMath for uint;
	
    // the token being sold
    address public tokenAddr;
	
	// the token decimals
	uint256 public decimals = 8;
	
	// address where funds are collected
	address public wallet;
	
	// amount of raised money in wei
    uint256 public weiRaised;
	
	// token sold in presale
    uint256 public tokenSold;
	
	// how many wei units a buyer pay per token
	uint256 public rate;
	
	// minimum investment in BNB
	uint256 public minInvestment;
	
	// Maximum buy limit per address
	uint256 public buyLimit;
	
	event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
	
	mapping (address => uint256) private balance;
	
    constructor(address _tokenAddr,address _walletAddr,uint256 _minInvestment,uint256 _rate,uint256 _limit) public {
        tokenAddr = _tokenAddr;
		wallet = _walletAddr;
		minInvestment = _minInvestment;
		rate = _rate;
		buyLimit = _limit;
    }
	
	function () external payable {
	   buyTokens(msg.sender); 
	}
	
	function buyTokens(address beneficiary) public payable
	{
	    require(beneficiary != 0x0, "can't transfer to the zero address");
		require(msg.value >= minInvestment,"min investment required");
		
		uint256 weiAmount = msg.value;
		uint256 tokens = convertWeiToTokens(weiAmount);
		require(Token(tokenAddr).balanceOf(this) >= tokens,"insufficient token balance on contract");
		require(buyLimit >= tokens,"buy limit exceeded per transection");
		require(buyLimit >= balance[beneficiary].add(tokens),"buy limit exceeded per address");
		
		require(Token(tokenAddr).transfer(beneficiary,tokens));
		TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
		forwardFunds();
		weiRaised = weiRaised.add(weiAmount);
		tokenSold = tokenSold.add(tokens);
		balance[beneficiary] = balance[beneficiary].add(tokens);
	}
	
	function forwardFunds() internal {
       wallet.transfer(msg.value);
    }
	
    function updateTokenAddress(address newTokenAddr) public onlyOwner {
       tokenAddr = newTokenAddr;
    }
	
	function updateWalletAddress(address newWalletAddr) public onlyOwner {
        wallet = newWalletAddr;
    }
	
	function updateTokenRate(uint256 newRate) public onlyOwner {
        rate = newRate;
    }
	
	function updateMinInvestment(uint256 newMinInvestment) public onlyOwner {
        minInvestment = newMinInvestment;
    }
	
	function updateDecimals(uint256 newDecimals) public onlyOwner {
        decimals = newDecimals;
    }
	
	function updateBuyLimit(uint256 newLimit) public onlyOwner {
        buyLimit = newLimit;
    }
	
	function withdrawTokens(address beneficiary) public onlyOwner {
        require(Token(tokenAddr).transfer(beneficiary, Token(tokenAddr).balanceOf(this)));
    }
	
    function availableLimit(address beneficiary) constant returns (uint256){
	   uint256 totalBuy = balance[beneficiary];
	   uint256 tokens = buyLimit-totalBuy;
       return tokens;
    }
	
    function tokenBalance() public constant returns (uint256 balance){
        return Token(tokenAddr).balanceOf(this);
    }
	
	function convertWeiToTokens(uint256 weiAmount) constant returns (uint256) {
	   uint256 tokens = weiAmount*10**decimals;
	   tokens = tokens.div(rate);
	   return tokens;
	}
}