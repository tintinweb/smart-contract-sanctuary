/**
 *Submitted for verification at BscScan.com on 2021-09-24
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

/**
 * @dev Custom and uniform interface to a decentralized exchange. It is used
 *      to estimate and convert funds whenever necessary. This furnishes
 *      client contracts with the flexibility to replace conversion strategy
 *      and routing, dynamically, by delegating these operations to different
 *      external contracts that share this common interface. See
 *      GExchangeImpl.sol for further documentation.
 */
interface GExchange
{
	// view functions
	function calcConversionFromInput(address _from, address _to, uint256 _inputAmount) external view returns (uint256 _outputAmount);
	function calcConversionFromOutput(address _from, address _to, uint256 _outputAmount) external view returns (uint256 _inputAmount);

	// open functions
	function convertFundsFromInput(address _from, address _to, uint256 _inputAmount, uint256 _minOutputAmount) external returns (uint256 _outputAmount);
	function convertFundsFromOutput(address _from, address _to, uint256 _outputAmount, uint256 _maxInputAmount) external returns (uint256 _inputAmount);
}

/**
 * @notice This contract implements the GExchange interface routing token
 *         conversions via a Uniswap V2 compatible exchange.
 */
contract GExchangeMigrationImpl is GExchange
{
	/**
	 * @notice Computes the amount of tokens to be received upon conversion.
	 * @param _from The contract address of the ERC-20 token to convert from.
	 * @param _to The contract address of the ERC-20 token to convert to.
	 * @param _inputAmount The amount of the _from token to be provided (may be 0).
	 * @return _outputAmount The amount of the _to token to be received (may be 0).
	 */
	function calcConversionFromInput(address _from, address _to, uint256 _inputAmount) external view override returns (uint256 _outputAmount)
	{
		return 0;
	}

	/**
	 * @notice Computes the amount of tokens to be provided upon conversion.
	 * @param _from The contract address of the ERC-20 token to convert from.
	 * @param _to The contract address of the ERC-20 token to convert to.
	 * @param _outputAmount The amount of the _to token to be received (may be 0).
	 * @return _inputAmount The amount of the _from token to be provided (may be 0).
	 */
	function calcConversionFromOutput(address _from, address _to, uint256 _outputAmount) external view override returns (uint256 _inputAmount)
	{
		return 0;
	}

	/**
	 * @notice Converts a given token amount to another token, as long as it
	 *         meets the minimum taken amount. Amounts are debited from and
	 *         and credited to the caller contract. It may fail if the
	 *         minimum output amount cannot be met.
	 * @param _from The contract address of the ERC-20 token to convert from.
	 * @param _to The contract address of the ERC-20 token to convert to.
	 * @param _inputAmount The amount of the _from token to be provided (may be 0).
	 * @param _minOutputAmount The minimum amount of the _to token to be received (may be 0).
	 * @return _outputAmount The actual amount of the _to token received (may be 0).
	 */
	function convertFundsFromInput(address _from, address _to, uint256 _inputAmount, uint256 _minOutputAmount) external override returns (uint256 _outputAmount)
	{
		require(_inputAmount == 0, "invalid amount");
		return 0;
	}

	/**
	 * @notice Converts a given token amount to another token, as long as it
	 *         meets the maximum given amount. Amounts are debited from and
	 *         and credited to the caller contract. It may fail if the
	 *         maximum input amount cannot be met.
	 * @param _from The contract address of the ERC-20 token to convert from.
	 * @param _to The contract address of the ERC-20 token to convert to.
	 * @param _outputAmount The amount of the _to token to be received (may be 0).
	 * @param _maxInputAmount The maximum amount of the _from token to be provided (may be 0).
	 * @return _inputAmount The actual amount of the _from token provided (may be 0).
	 */
	function convertFundsFromOutput(address _from, address _to, uint256 _outputAmount, uint256 _maxInputAmount) external override returns (uint256 _inputAmount)
	{
		require(_outputAmount == 0, "invalid amount");
		return 0;
	}
}