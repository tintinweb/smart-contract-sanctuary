pragma solidity 0.4.24;


contract Adoption {
	/**
	 * Adopters
	 */
	 address[16] public adopters;

	/**
	 * Adopt a pet
	 */
	function adopt(uint _petID)
	public
	returns(uint)
	{
		// Revery if petID is not within the proper range
		require(_petID >= 0 && _petID <= 15);

		// Record the address of the adopter for the specifed petID 
		adopters[_petID] = msg.sender;

		// Return the petID as confirmation/success
		return _petID;
	}

	/**
	 * Retrieve list of adopters
	 */
	function getAdopters()
	public
	view
	returns(address[16]) 
	{
		return adopters;
	}

	/**
	 * Smartcontract constructor
	 */
  	constructor()
  	public
  	{
  	}
}