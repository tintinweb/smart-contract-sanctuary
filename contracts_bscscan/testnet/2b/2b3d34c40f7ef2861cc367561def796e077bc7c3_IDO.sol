/**
 *Submitted for verification at BscScan.com on 2021-11-29
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

contract IDO {
    using SafeMath for uint256;

    IBEP20 public TOKEN;
	
    address public owner;
	address public airdropfundAddress;

    uint256 public startDate;  
    uint256 public endDate; 
	 
    uint256 public totalTokensToSell = 50000 * 10**18;          
    uint256 public tokenPerBnb = 250000;                            
    uint256 public maxPerUser = 2500000 * 10**18; 
    uint256 public softCap = 1 * 10**17;  
    uint256 public hardCap = 2 * 10**17;  		
    uint256 public totalSold;

    bool public saleEnded = false;
	bool public allowRefunds = false;
    
    mapping(address => uint256) public tokenPerAddresses;

    event tokensBought(address sender, uint256 tokens);
    event bnbRefunded(address sender, uint256 amountBNBtoRefund);
    
    constructor() {
        address _TOKEN = 0xBCFd96E02f88D89EEba7A541C0F497214F1e06E6;
        owner = msg.sender;
        TOKEN = IBEP20(_TOKEN);
        airdropfundAddress = 0x302309F747c11E8DA56e42E2727e2C7A61562CAe;
    }

    // Function to buy TOKEN using BNB token
    function buyIDO() public payable returns(bool) {
        require(!saleEnded, "IDO ended");
        require(msg.value > 0, "Zero value");  
        require(unsoldTokens() > 0, "Insufficient contract balance");        
        address sender = msg.sender;   
        uint256 tokens = (msg.value * tokenPerBnb);

        //if the buyer wants to buy more tokens than available on the smart contract then send the available amount of tokens and send the rest of the BNB
        if(unsoldTokens() > 0 && unsoldTokens() < tokens){
            tokens = unsoldTokens();
            payable(sender).transfer(msg.value.sub(tokens.div(tokenPerBnb)));
            }

        uint256 sumSoFar = tokenPerAddresses[msg.sender].add(tokens);
        require(sumSoFar <= maxPerUser, "Greater than the maximum purchase limit");

        tokenPerAddresses[msg.sender] = sumSoFar;
        totalSold = totalSold.add(tokens);
        TOKEN.transfer(sender, tokens);
        if(shouldEndIDO()){ EndIDO(); }
        
        emit tokensBought(sender, tokens);
        return true;
    }
    
    // Function to refund BNB
    function RefundBNB() public {
        require(allowRefunds, "Refunds is not possible");
        uint256 amountBNBtoRefund = tokenPerAddresses[msg.sender].div(tokenPerBnb);
        
        require(TOKEN.balanceOf(msg.sender) >= tokenPerAddresses[msg.sender], "Insufficient tokens amount");        
    	payable(msg.sender).transfer(amountBNBtoRefund);
    	
    	tokenPerAddresses[msg.sender] = 0;
    	emit bnbRefunded(msg.sender, amountBNBtoRefund);
    }
    
    function shouldEndIDO() internal view returns (bool) {
        return block.timestamp >= endDate || address(this).balance >= hardCap; // End IDO if time runs out or hard cap has been reached
    }

    function EndIDO() internal {	
		if(address(this).balance >= softCap) {
			uint256 amountBNBtoWithdraw = address(this).balance.mul(20).div(100);
            uint256 amountBNBLiquidity = address(this).balance.sub(amountBNBtoWithdraw);
            payable(owner).transfer(amountBNBtoWithdraw);	
            payable(address(TOKEN)).transfer(amountBNBLiquidity);   	   
		}
		
		// If the soft cap has not been reached, refunds are possible
		else if(address(this).balance < softCap){
			allowRefunds = true;
		}
		saleEnded = true;
        sendUnsoldTokens();
    }

    function changeOwner(address _owner) public {
        require(msg.sender == owner);
        owner = _owner;
    }

    function changeDuration(uint256 duration) public {
        require(msg.sender == owner && !saleEnded);
        endDate = endDate + (duration * 1 days);
    }

    function setMaxPerUser(uint256 _maxPerUser) public {
        require(msg.sender == owner);
        maxPerUser = _maxPerUser;
    }

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

    function sendUnsoldTokens() internal {
 		    if(TOKEN.balanceOf(address(this)) > 0)	{ 
                 TOKEN.transfer(airdropfundAddress, TOKEN.balanceOf(address(this))); } // Send unsold token to AirdropFund
    }

    //function to start the IDO
    function startIDO(uint256 duration) public {
        require(msg.sender == owner && !saleEnded);
         startDate = block.timestamp;  
         endDate = startDate + (duration * 1 days);
    }    

    //function to return the amount of unsold tokens
    function unsoldTokens() public view returns (uint256) {
       return totalTokensToSell.sub(totalSold);
    }

}