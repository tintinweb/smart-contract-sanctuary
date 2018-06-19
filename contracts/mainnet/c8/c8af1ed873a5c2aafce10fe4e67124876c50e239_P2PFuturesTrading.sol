pragma solidity ^0.4.11;
/*

P2PFuturesTrading

Trustless trading of not already transferable tokens between two people
Author: thestral.eth

*/

// ERC20 Interface: ethereum/EIPs#20
contract ERC20 {
	function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
}

contract P2PFuturesTrading {

	struct Trade{
		address tokenAddress;
		uint tokenAmount;
		uint etherAmount;
		uint etherCollateralAmount;
		uint endTradeBlock;
		bool initialized;
		bool finalized;
	}


	// Store the open trades
	mapping (address => mapping(address => Trade)) public trades;

	// The developer address.
	address developerAddress = 0x335854eF79Fff47F9050ca853c7f3bA53eeEEE93;



	function startTrade(address tokenSellerAddress, address tokenAddress, uint tokenAmount, uint etherCollateralAmount, uint endTradeBlock) payable{
		//Variable validation. The endTradeBlock can&#39;t be smaller than the current one plus 220 (around 1 hour)
		if(msg.value == 0 || tokenAmount == 0 || endTradeBlock <= block.number + 220){
			throw;
		}
		
		Trade t1 = trades[msg.sender][tokenSellerAddress];
		Trade t2 = trades[tokenSellerAddress][msg.sender];
		
		//You can&#39;t have more than one trade at a time between the same two people. To close a non finalized trade and have you ether back, you need to call the function cancelTrade
		if(t1.initialized || t2.initialized){
			throw;
		}

		trades[msg.sender][tokenSellerAddress] = Trade(tokenAddress, tokenAmount, msg.value, etherCollateralAmount, endTradeBlock, true, false);
	}



	function finalizeTrade(address tokenBuyerAddress, uint etherAmount, address tokenAddress, uint tokenAmount, uint endTradeBlock) payable{
		Trade t = trades[tokenBuyerAddress][msg.sender];
		
		//It needs to exist already a trade between the two people and it hasn&#39;t have to be already finalized
		if(!t.initialized || t.finalized){
			throw;
		}
		
		//The trade condition specified by the two people must concide
		if(!(t.tokenAddress == tokenAddress && t.tokenAmount == tokenAmount && t.etherAmount == etherAmount && t.etherCollateralAmount == msg.value && t.endTradeBlock == endTradeBlock)){
			throw;
		}
		
		t.finalized = true;
	}

	 
	function completeTrade(address otherPersonAddress){
	    Trade t;
		address tokenBuyerAddress;
		address tokenSellerAddress;
		
		Trade tokenBuyerTrade = trades[msg.sender][otherPersonAddress];
		Trade tokenSellerTrade = trades[otherPersonAddress][msg.sender];
		
		//It needs to exist already a trade between the two people and it has to be already finalized.
		if(tokenBuyerTrade.initialized && tokenBuyerTrade.finalized){
			t = tokenBuyerTrade;
			tokenBuyerAddress = msg.sender;
			tokenSellerAddress = otherPersonAddress;
		}
		else if(tokenSellerTrade.initialized && tokenSellerTrade.finalized){
			t = tokenSellerTrade;
			tokenBuyerAddress = otherPersonAddress;
			tokenSellerAddress = msg.sender;
		}
		else{
			throw;
		}
		
		
		ERC20 token = ERC20(t.tokenAddress);
		
		//1% developer fee, 0.5% from the tokenSeller (in tokens) and 0.5% from the tokenBuyer (in ethers). In case the trade doesn&#39;t complete the fee is of 1% of the collateral.
		uint tokenSellerFee = t.tokenAmount * 5 / 1000;
		uint tokenBuyerFee = t.etherAmount * 5 / 1000;
		uint collateralFee = t.etherCollateralAmount / 100;
		
		t.initialized = false;
		t.finalized = false;
		
		//If the tokenSeller didn&#39;t allow this contract of the needed amount, one of the two following functions will return false
		if(!token.transferFrom(tokenSellerAddress, tokenBuyerAddress, t.tokenAmount - tokenSellerFee) || !token.transferFrom(tokenSellerAddress, developerAddress, tokenSellerFee)){
			//If the maximum time has passed, and the trade coudldn&#39;t be completed, the tokenBuyer will receive his ether plus the collateral. Otherwise no action is taken.
			if(t.endTradeBlock < block.number){
				tokenBuyerAddress.transfer(t.etherAmount + t.etherCollateralAmount - collateralFee);
				developerAddress.transfer(collateralFee);
				
				return;
			}
			else{
				throw;
			}
		}
		
		//Transfer to the tokenSeller the etherAmount plus his collateral
		tokenSellerAddress.transfer(t.etherAmount + t.etherCollateralAmount - tokenBuyerFee);
		developerAddress.transfer(tokenBuyerFee);
    }
    
    
	function cancelTrade(address tokenSellerAddress){
		Trade t = trades[msg.sender][tokenSellerAddress];
		
		//It needs to exist already a trade between the two people and it hasn&#39;t have to be already finalized
		if(!t.initialized || t.finalized){
			throw;
		}
		
		//Cancel the trade and give the sender his ether back	
		t.initialized = false;
		
		msg.sender.transfer(t.etherAmount);
	}
}