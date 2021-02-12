/**
 *Submitted for verification at Etherscan.io on 2021-02-12
*/

pragma solidity ^0.5.12;


interface cETH {
    function mint(uint256) external payable;

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);
}

contract CompoundWallet {

    event MyLog(string, uint256);

    function supplyEthToCompound(address payable _cEtherContract) public payable returns (bool) {
        // Create a reference to the corresponding cToken contract
        cETH cToken = cETH(_cEtherContract);

        // Amount of current exchange rate from cToken to underlying
        uint256 exchangeRateMantissa = cToken.exchangeRateCurrent();
        emit MyLog("Exchange Rate (scaled up by 1e18): ", exchangeRateMantissa);

        // Amount added to you supply balance this block
        uint256 supplyRateMantissa = cToken.supplyRatePerBlock();
        emit MyLog("Supply Rate: (scaled up by 1e18)", supplyRateMantissa);

        cToken.mint.value(msg.value);
        return true;
    }

    function redeemcETHTokens(uint256 amount, address _cETHContract) public returns (bool) {
        // Create a reference to the corresponding cToken contract, like cDAI
        cETH cToken = cETH(_cETHContract);

        uint256 redeemResult;

        // Retrieve your asset based on a cToken amount
        redeemResult = cToken.redeemUnderlying(amount);
    
        // Error codes are listed here:
        // https://compound.finance/developers/ctokens#ctoken-error-codes
        emit MyLog("If this is not 0, there was an error", redeemResult);

        return true;
    }

    // This is needed to receive ETH when calling `redeemCEth`
    function() external payable {}
}