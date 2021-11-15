// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;




interface CEth {
    function mint() external payable;

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);
}


contract MyContract {
    event MyLog(string, uint256);
    event MyOwnLog(string, uint);
    
    

    function supplyEthToCompound(address payable _cEtherContract)
        public
        payable
        returns (bool)
    {
        // Create a reference to the corresponding cToken contract
        CEth cToken = CEth(_cEtherContract);

        // Amount of current exchange rate from cToken to underlying
        uint256 exchangeRateMantissa = cToken.exchangeRateCurrent();
        emit MyLog("Exchange Rate (scaled up by 1e18): ", exchangeRateMantissa);

        // Amount added to you supply balance this block
        // uint256 supplyRateMantissa = cToken.supplyRatePerBlock();
        uint256 supplyBlockNumber = block.number;
        emit MyLog("Block number while supplying is: ", supplyBlockNumber);

        cToken.mint.value(msg.value).gas(250000)();
        return true;

                
    }

    function balanceOf() external pure returns (uint256 balance) {
        return balance;
    }

    function redeemCEth(
        // address _suppliersAddress,
        uint256 amount,
        bool redeemType,
        address _cEtherContract
    ) public returns (bool) {
        // Create a reference to the corresponding cToken contract
        CEth cToken = CEth(_cEtherContract);

        // `amount` is scaled up by 1e18 to avoid decimals

        uint256 redeemResult;

        if (redeemType == true) {
            // Retrieve your asset based on a cToken amount
            redeemResult = cToken.redeem(amount);
           
        } else {
            // Retrieve your asset based on an amount of the asset
            redeemResult = cToken.redeemUnderlying(amount);
        }

        uint256 redeemedEth;

        if (redeemType == true) {
            uint exchangeRateMantissa = cToken.exchangeRateCurrent();
            redeemedEth =(redeemResult * exchangeRateMantissa);
        }

        // Error codes are listed here:
        // https://compound.finance/docs/ctokens#ctoken-error-codes
        emit MyOwnLog("ETH redeemed :", redeemedEth);

        return true;
    }

    // This is needed to receive ETH when calling `redeemCEth`
    function() external payable {}

    

}

