pragma solidity ^0.4.13;

contract token { 
    function transfer(address _to, uint256 _value);
	function balanceOf(address _owner) constant returns (uint256 balance);	
}

contract Crowdsale {

	token public sharesTokenAddress; // token address

	uint public startICO = now + 10 days; // start ICO
	uint public periodICO; // duration ICO
	uint public stopICO; // end ICO
	uint public price = 0.0035 * 1 ether; // ETH for 1 package of tokens
	uint coeff = 100000; // capacity of 1 package
	
	uint256 public tokenSold = 0; // tokens sold
	uint256 public tokenFree = 0; // tokens free
	bool public crowdsaleClosed = false;

	address public owner;
	
	event TokenFree(uint256 value);
	event CrowdsaleClosed(bool value);
    
	function Crowdsale(address _tokenAddress, address _owner, uint _timePeriod) {
		owner = _owner;
		sharesTokenAddress = token(_tokenAddress);
		periodICO = _timePeriod * 1 hours;
		stopICO = startICO + periodICO;
	}

	function() payable {
		tokenFree = sharesTokenAddress.balanceOf(this); // free tokens count
		if (now > (stopICO + 1)) {
			msg.sender.transfer(msg.value); // if crowdsale closed - cash back
			crowdsaleClosed = true;
		} else if (crowdsaleClosed) {
			msg.sender.transfer(msg.value); // if no more tokens - cash back
		} else {
			uint256 tokenToBuy = msg.value / price * coeff; // tokens to buy
			require(tokenToBuy > 0);
			uint256 actualETHTransfer = tokenToBuy * price / coeff;
			if (tokenFree >= tokenToBuy) { // free tokens >= tokens to buy, sell tokens
				owner.transfer(actualETHTransfer);
				if (msg.value > actualETHTransfer){ // if more than need - cash back
					msg.sender.transfer(msg.value - actualETHTransfer);
				}
				sharesTokenAddress.transfer(msg.sender, tokenToBuy);
				tokenSold += tokenToBuy;
				tokenFree -= tokenToBuy;
				if(tokenFree==0) crowdsaleClosed = true;
			} else { // free tokens < tokens to buy 
				uint256 sendETH = tokenFree * price / coeff; // price for all free tokens
				owner.transfer(sendETH); 
				sharesTokenAddress.transfer(msg.sender, tokenFree); 
				msg.sender.transfer(msg.value - sendETH); // more than need - cash back
				tokenSold += tokenFree;
				tokenFree = 0;
				crowdsaleClosed = true;
			}
		}
		TokenFree(tokenFree);
		CrowdsaleClosed(crowdsaleClosed);
	}
	
	function unsoldTokensBack(){ // after crowdsale we can take back all unsold tokens from crowdsale	    
	    require(crowdsaleClosed);
		require(msg.sender == owner);
	    sharesTokenAddress.transfer(owner, sharesTokenAddress.balanceOf(this));
		tokenFree = 0;
		crowdsaleClosed = true;
	}	
}