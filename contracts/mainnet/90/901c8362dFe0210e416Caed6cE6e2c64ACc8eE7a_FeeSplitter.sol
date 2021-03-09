// SPDX-License-Identifier: P-P-P-PONZO!!!
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./IGatedERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./TokensRecoverable.sol";

contract FeeSplitter is TokensRecoverable
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    mapping (IGatedERC20 => address[]) public feeCollectors;
    mapping (IGatedERC20 => uint256[]) public feeRates;
    mapping (IGatedERC20 => uint256) public burnRates;

    function setFees(IGatedERC20 token, uint256 burnRate, address[] memory collectors, uint256[] memory rates) public ownerOnly() // 100% = 10000
    {
        require (collectors.length == rates.length && collectors.length > 0, "Fee Collectors and Rates should be the same size and not empty");
        
        if (token.balanceOf(address(this)) > 0)
        {
            payFees(token);
        }

        feeCollectors[token] = collectors;
        feeRates[token] = rates;
        burnRates[token] = burnRate;
    }

    function payFees(IGatedERC20 token) public
    {
        uint256 balance = token.balanceOf(address(this));
        require (balance > 0, "Nothing to pay");

        if (burnRates[token] > 0)
        {
            uint256 burnAmount = burnRates[token] * balance / 10000;
            token.burn(address(this), burnAmount);
        }

        address[] memory collectors = feeCollectors[token];
        uint256[] memory rates = feeRates[token];

        for (uint256 i = 0; i < collectors.length; i++)
        {
            address collector = collectors[i];
            uint256 rate = rates[i];

            if (rate > 0)
            {
                uint256 feeAmount = rate * balance / 10000;
                token.transfer(collector, feeAmount);
            }
        }
    }

    function canRecoverTokens(IERC20 token) internal override view returns (bool) 
    { 
        address[] memory collectors = feeCollectors[IGatedERC20(address(token))];
        return address(token) != address(this) && collectors.length == 0; 
    }
}