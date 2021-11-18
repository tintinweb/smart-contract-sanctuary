/**
 *Submitted for verification at BscScan.com on 2021-11-17
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

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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

    uint256 public startDate = block.timestamp;  
    uint256 public duration = 30 days;
    uint256 public endDate = startDate + duration; 
    uint256 public lockTime;	
    
    uint256 public totalTokensToSell = 50000000 * 10**18;          
    uint256 public tokenPerBnb = 25000;                            
    uint256 public maxPerUser = 250000 * 10**18; 
    uint256 public softCap = 1000 * 10**18;  
    uint256 public hardCap = 2000 * 10**18;  		
    uint256 public totalSold;

    bool public saleEnded = false;
	bool public allowRefunds = false;
    
    mapping(address => uint256) public tokenPerAddresses;

    event tokensBought(address sender, uint256 tokens);
    event bnbRefunded(address sender, uint256 amountBNBtoRefund);
    
    
    constructor() {
        dexRouter_ = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
        router = IDEXRouter(dexRouter_);
        address _TOKEN = 0xb5078c14Ca146BfA8040Db3664C8a074056c41BD;
        address _pair = 0x57936b7286e5a64F52Aa6214e994009A2dDc5736;
        owner = msg.sender;
        TOKEN = IBEP20(_TOKEN);
        LP = IBEP20(_pair);
        airdropfundAddress = 0x8a048A82827CD70DDfAE0a5ac1A9FD783f2e6f11;
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

    function RefundBNB(uint256 tokens) public {
        uint256 amountBNBtoRefund = tokens / tokenPerBnb;
		
        require(allowRefunds, 'Refunds is not possible');
        TOKEN.allowance(msg.sender, address(this)).add(tokens);
        TOKEN.transferFrom(msg.sender, address(this), tokens);
		
		payable(msg.sender).transfer(amountBNBtoRefund);
		emit bnbRefunded(msg.sender, amountBNBtoRefund);        
    }
    
    
        function RefundBNBbyMapping() public {
        uint256 amountBNBtoRefund = tokenPerAddresses[msg.sender].div(tokenPerBnb);
		payable(msg.sender).transfer(amountBNBtoRefund);
		tokenPerAddresses[msg.sender] = 0;
		emit bnbRefunded(msg.sender, amountBNBtoRefund);
    }
    

    function shouldEndIDO() internal view returns (bool) {
        return block.timestamp > endDate || address(this).balance >= hardCap;
    }

    function EndIDO() internal {	
		if(address(this).balance >= softCap) {
			
		    uint256 amountBNBLiquidity = address(this).balance.mul(8).div(10);
            uint256 amountToLiquify = amountBNBLiquidity * 18750;
			
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
		    lockTime = block.timestamp + 400 days; // Lock the liquidity pools for 400 days
		}
		
		// If the soft cap has not been reached, allow the funds to be returned
		else if(address(this).balance < softCap){
			allowRefunds = true;
		}
		saleEnded = true;
    }


    //function to change the owner
    //only owner can call this function
    function changeOwner(address payable _owner) public {
        require(msg.sender == owner);
        owner = _owner;
    }

    // function to set the IDO end date
    // only owner can call this function
    function setEndDate(uint256 _duration) public {
        require(msg.sender == owner && !saleEnded);
        duration = _duration * 1 days;
        endDate = startDate + duration;
    }


    // function to set the maximum amount which a user can buy
    // only owner can call this function
    function setMaxPerUser(uint256 _maxPerUser) public {
        require(msg.sender == owner);
        maxPerUser = _maxPerUser;
    }

    // function to set the total tokens to sell
    // only owner can call this function
    function setTokenPricePerBNB(uint256 _tokenPerBnb) public {
        require(msg.sender == owner);
        require(_tokenPerBnb > 0, "Invalid TOKEN price per BNB");
        tokenPerBnb = _tokenPerBnb;
    }

    //function to end the sale
    //only owner can call this function
    function endSale() public {
        require(msg.sender == owner && !saleEnded);
        EndIDO();
    }

    //function to withdraw collected funds from LP
    //the LP is locked for 400 days from the end of the IDO
    //only owner can call this function

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