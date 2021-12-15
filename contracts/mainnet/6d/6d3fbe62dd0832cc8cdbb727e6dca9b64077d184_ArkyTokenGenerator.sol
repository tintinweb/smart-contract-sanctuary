/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

pragma solidity >=0.4.22 <0.6.0;
	/*arkyToken V1.0 2021 Developed by Segato Andrea */

	contract ArkyTokenGenerator {

		/* This */
			string public name;
			string public symbol;
			uint8 public decimals;
		mapping (address => uint256) public balance0f;

		/* Initialize */


			constructor (uint256 initialSupply, string memory
		tokenName, string memory tokenSymbol, uint8 decimalUnits) public

		{
			balance0f[msg.sender] = initialSupply;
			name = tokenName;
			symbol = tokenSymbol;
			decimals = decimalUnits;
			}

			/* Send coins */
			function transfer(address _to, uint256 _value) public
		returns (bool success) {
			require(balance0f[msg.sender] >= _value);
            require(balance0f[_to] + _value >= balance0f[_to]);
			balance0f[msg.sender] -= _value;
			balance0f[_to] += _value;
			return true;
			}
		}