/**
 *Submitted for verification at Etherscan.io on 2021-10-23
*/

// File: contracts\interfaces\TokenInterfaceV5.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface TokenInterfaceV5{
    function burn(address, uint256) external;
    function mint(address, uint256) external;
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns(bool);
    function balanceOf(address) external view returns(uint256);
    function hasRole(bytes32, address) external view returns (bool);
    function approve(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
}

// File: contracts\GFarmTokenMigration.sol

pragma solidity 0.8.7;

contract GFarmTokenMigration{

	address public gov;
	TokenInterfaceV5 public oldToken;
	TokenInterfaceV5 public newToken;

	constructor(address _gov, TokenInterfaceV5 _oldToken){
		oldToken = _oldToken;
		gov = _gov;
	}

	// Set token after contract deployed
	// => can give minting role to this contract when deploy new token
	function setNewToken(TokenInterfaceV5 _newToken) external{
		require(msg.sender == gov, "NOT_GOV");
		require(address(_newToken) != address(0), "ADDRESS_0");
		require(address(newToken) == address(0), "ALREADY_SET");
		newToken = _newToken;
	}

	// Send x amount of GFARM2 tokens and receive 1000x GNS tokens.
	function migrateToNewToken(uint _amount) external{
		require(oldToken.balanceOf(msg.sender) >= _amount, "BALANCE_TOO_LOW");
		oldToken.transferFrom(msg.sender, address(this), _amount);
		newToken.mint(msg.sender, _amount*1000);
	}
}