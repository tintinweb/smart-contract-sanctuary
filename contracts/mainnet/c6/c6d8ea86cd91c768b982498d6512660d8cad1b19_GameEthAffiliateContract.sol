pragma solidity ^0.4.0;

// Affiliate deposit contract for https://game-eth.com
// game contract address = 0xbd2BD1bD6396E69112D1f51Cbaa57842cd1586C4
// GameEthAffiliateContract transfer some % to affiliate owner address, and remaining sum transfer to game

contract GameEthAffiliateContract{

address gameContract;
address affiliateAddress; 
uint256 affiliatePercent;
uint256 minWeiDeposit = 40000000000000000; // default 0.04 ether

	constructor(address _gameContract, address _affiliateAddress, uint256 _affiliatePercent) public {
		gameContract = _gameContract;
		require (_affiliatePercent>=0 && _affiliatePercent <=3); // check affiliate percent range
		affiliateAddress = _affiliateAddress;
		affiliatePercent = _affiliatePercent;
		
	}
	
	function () public payable{
		uint256 affiliateCom = msg.value/100*affiliatePercent; // affiliate % commission
		uint256 amount = msg.value - affiliateCom; // deposit amount is amount - commission
		require(amount >= minWeiDeposit);
		if (!gameContract.call.value(amount)(bytes4(keccak256("depositForRecipent(address)")), msg.sender)){
			revert();
		}
		affiliateAddress.transfer(affiliateCom); // transfer affiliate commission
	}
	
	// change affiliateAddress
	// only affiliate commission receiver can change affiliate address
	function changeAffiliate(address _affiliateAddress, uint256 _affiliatePercent) public {
		require (msg.sender == affiliateAddress); // check is message sender is current affiliate commission receiver 
		require (_affiliatePercent>=0 && _affiliatePercent <=3); // check affiliate percent range
		affiliateAddress =  _affiliateAddress;
		affiliatePercent = _affiliatePercent;
		
	}

}