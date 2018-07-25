// Token Faucet for U42 Token Specification (version A or B)
//

pragma solidity ^0.4.24;

contract U42 {
	function balanceOf (
			address _owner ) 
		public view returns (
			uint256 );

	function transfer (
			address _to, 
			uint256 _value ) 
		public returns (
			bool );
}

contract U42_Faucet {

	//intentionally hard-coded token contract address -- this should be a ropsten-deployed
	// version of U42_A_Audited or U42_B or U42_B_Audited
	U42 u42c = U42(0xB0901Baf520bd3E67Ad1d4a442f5f7A0c8428e69);

	function requestTokens() public returns (bool success) {
		//will attempt to transfer tokens on u42c to msg.sender
		//ammount to send will be 0.1% of the balance of tokens held by this contract

		//get token balance
		uint256 b = u42c.balanceOf(this);

		//amount to give to caller
		uint256 giveAmt = b / 1000;

		//call transfer
		return u42c.transfer(msg.sender, giveAmt);
	}

}