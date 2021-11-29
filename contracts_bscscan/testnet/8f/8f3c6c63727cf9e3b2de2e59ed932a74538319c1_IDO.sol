/**
 *Submitted for verification at BscScan.com on 2021-11-28
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool ok);
    
        event Transfer(address indexed from, address indexed to, uint256 value);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

}

contract IDO {
    using SafeMath for uint256;

    IBEP20 public TOKEN;
    IBEP20 public LP;
	
    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    IDEXRouter router;    
	address public dexRouter_;
	
    address public owner;
	address public airdropfundAddress;

    uint256 public startDate;  
    uint256 public duration;
    uint256 public endDate; 
    uint256 public lockTime;	
    
    uint256 public totalTokensToSell = 50000000 * 10**18;          
    uint256 public tokenPerBnb = 250000;                            
    uint256 public maxPerUser = 250000 * 10**18; 
    uint256 public softCap = 2 * 10**18;  
    uint256 public hardCap = 3 * 10**18;  		
    uint256 public totalSold;

    bool public saleEnded = false;
	bool public allowRefunds = false;
    
    mapping(address => uint256) public tokenPerAddresses;

    event tokensBought(address sender, uint256 tokens);
    event bnbRefunded(address sender, uint256 amountBNBtoRefund);
    
    
    constructor() {
        dexRouter_ = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
        router = IDEXRouter(dexRouter_);
        address _TOKEN = 0x09eC07C38b24af28358F4f1A61f5d31f221b46F3;
        address _pair = 0xD8993C54d450fc44767ce195fa6Fc8e8b5a7c22A;
        owner = msg.sender;
        TOKEN = IBEP20(_TOKEN);
        LP = IBEP20(_pair);
        airdropfundAddress = 0xc36954502FD999a5b25824a9D2992216f9E9e237;
    }

    // Function to buy TOKEN using BNB token

    function buyIDO() public payable returns(bool) {
        require(!saleEnded, 'IDO ended');     
        address sender = msg.sender;
        
        uint256 tokens = (msg.value * tokenPerBnb);
  
        if(shouldEndIDO()){ EndIDO(); }

        require(msg.value > 0, "Zero value");
        require(unsoldTokens() >= tokens, "Insufficient contract balance");
             
        uint256 sumSoFar = tokenPerAddresses[msg.sender].add(tokens);
        require(sumSoFar <= maxPerUser, 'Greater than the maximum purchase limit');

        tokenPerAddresses[msg.sender] = sumSoFar;
        totalSold = totalSold.add(tokens);
        TOKEN.transfer(sender, tokens);
        
        emit tokensBought(sender, tokens);
        return true;
    }
    
    // Function to refund BNB

    function RefundBNB() public {
        require(allowRefunds, 'Refunds is not possible');
        uint256 amountBNBtoRefund = tokenPerAddresses[msg.sender].div(tokenPerBnb);
        
        require(TOKEN.balanceOf(msg.sender) >= tokenPerAddresses[msg.sender], 'Insufficient tokens amount');        
    	payable(msg.sender).transfer(amountBNBtoRefund);
    	
    	tokenPerAddresses[msg.sender] = 0;
    	emit bnbRefunded(msg.sender, amountBNBtoRefund);
    }
    

    function shouldEndIDO() internal view returns (bool) {
        return block.timestamp >= endDate || address(this).balance >= hardCap; // End IDO if time runs out or hard cap has been reached
    }

    function EndIDO() internal {	
		if(address(this).balance >= softCap) {
			
		    uint256 amountBNBLiquidity = address(this).balance.mul(8).div(10);
            uint256 amountToLiquify = amountBNBLiquidity * 187500;
			
			uint256 amountBNBtoWithdraw = address(this).balance.sub(amountBNBLiquidity);
            payable(owner).transfer(amountBNBtoWithdraw);
			
			router.addLiquidityETH{value: amountBNBLiquidity}(
            address(TOKEN),
            amountToLiquify,
            0,
            0,
            address(this),
            block.timestamp);
            
		    if(TOKEN.balanceOf(address(this)) > 0)	{ TOKEN.transfer(airdropfundAddress, TOKEN.balanceOf(address(this))); } // Send unsold token to AirdropFund
		    lockTime = block.timestamp + 1 days; // Lock the liquidity pools for 400 days
		}
		
		// If the soft cap has not been reached, allow the funds to be returned
		else if(address(this).balance < softCap){
			allowRefunds = true;
		}
		saleEnded = true;
    }


    //function to change the owner

    function changeOwner(address payable _owner) public {
        require(msg.sender == owner);
        owner = _owner;
    }

    // function to set the IDO end date

    function changeDuration(uint256 _duration) public {
        require(msg.sender == owner && !saleEnded);
        duration = _duration * 1 days;
        endDate = endDate + duration;
    }


    // function to set the maximum amount which a user can buy
    // only owner can call this function
    function setMaxPerUser(uint256 _maxPerUser) public {
        require(msg.sender == owner);
        maxPerUser = _maxPerUser;
    }

    // function to set the total tokens to sell

    function setTokenPricePerBNB(uint256 _tokenPerBnb) public {
        require(msg.sender == owner);
        require(_tokenPerBnb > 0, "Invalid TOKEN price per BNB");
        tokenPerBnb = _tokenPerBnb;
    }

    //function to end the IDO

    function endIDO() public {
        require(msg.sender == owner && !saleEnded);
        EndIDO();
    }

    //function to start the IDO

    function startIDO(uint256 _duration) public {
        require(msg.sender == owner && !saleEnded);
         startDate = block.timestamp;  
         duration = _duration * 1 days;
         endDate = startDate + duration;
    }    

    //function to withdraw collected funds from LP
    //the LP is locked for 400 days from the end of the IDO

    function withdrawFundsFromLP() public {
        require(msg.sender == owner);
        require(block.timestamp >= lockTime, "The liquidity pool is still locked");	
        require(saleEnded, "IDO unfinished");		
		
		if(LP.balanceOf(address(this)) > 0)	{  LP.transfer(owner, LP.balanceOf(address(this)));}
		if(TOKEN.balanceOf(address(this)) > 0)	{  TOKEN.transfer(owner, TOKEN.balanceOf(address(this)));}
		if(address(this).balance > 0 && !allowRefunds)	{  payable(owner).transfer(address(this).balance);}
    }

    //function to return the amount of unsold tokens
    function unsoldTokens() public view returns (uint256) {
       return totalTokensToSell.sub(totalSold);
    }



}