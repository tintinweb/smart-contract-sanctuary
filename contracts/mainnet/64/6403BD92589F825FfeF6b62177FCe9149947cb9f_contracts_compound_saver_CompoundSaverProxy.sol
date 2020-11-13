pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../exchange/SaverExchangeCore.sol";
import "../../loggers/DefisaverLogger.sol";
import "../helpers/CompoundSaverHelper.sol";

/// @title Contract that implements repay/boost functionality
contract CompoundSaverProxy is CompoundSaverHelper, SaverExchangeCore {

    DefisaverLogger public constant logger = DefisaverLogger(0x5c55B921f590a89C1Ebe84dF170E655a82b62126);

    /// @notice Withdraws collateral, converts to borrowed token and repays debt
    /// @dev Called through the DSProxy
    /// @param _exData Exchange data
    /// @param _cAddresses Coll/Debt addresses [cCollAddress, cBorrowAddress]
    /// @param _gasCost Gas cost for specific transaction
    function repay(
        ExchangeData memory _exData,
        address[2] memory _cAddresses, // cCollAddress, cBorrowAddress
        uint256 _gasCost
    ) public payable {
        enterMarket(_cAddresses[0], _cAddresses[1]);

        address payable user = payable(getUserAddress());

        uint maxColl = getMaxCollateral(_cAddresses[0], address(this));

        uint collAmount = (_exData.srcAmount > maxColl) ? maxColl : _exData.srcAmount;

        require(CTokenInterface(_cAddresses[0]).redeemUnderlying(collAmount) == 0);

        address collToken = getUnderlyingAddr(_cAddresses[0]);
        address borrowToken = getUnderlyingAddr(_cAddresses[1]);

        uint swapAmount = 0;

        if (collToken != borrowToken) {
            _exData.srcAmount = collAmount;

            (, swapAmount) = _sell(_exData);
            swapAmount -= getFee(swapAmount, user, _gasCost, _cAddresses[1]);
        } else {
            swapAmount = collAmount;
            swapAmount -= getGasCost(swapAmount, _gasCost, _cAddresses[1]);
        }

        paybackDebt(swapAmount, _cAddresses[1], borrowToken, user);

        // handle 0x fee
        tx.origin.transfer(address(this).balance);

        // log amount, collToken, borrowToken
        logger.Log(address(this), msg.sender, "CompoundRepay", abi.encode(_exData.srcAmount, swapAmount, collToken, borrowToken));
    }

    /// @notice Borrows token, converts to collateral, and adds to position
    /// @dev Called through the DSProxy
    /// @param _exData Exchange data
    /// @param _cAddresses Coll/Debt addresses [cCollAddress, cBorrowAddress]
    /// @param _gasCost Gas cost for specific transaction
    function boost(
        ExchangeData memory _exData,
        address[2] memory _cAddresses, // cCollAddress, cBorrowAddress
        uint256 _gasCost
    ) public payable {
        enterMarket(_cAddresses[0], _cAddresses[1]);

        address payable user = payable(getUserAddress());

        uint maxBorrow = getMaxBorrow(_cAddresses[1], address(this));
        uint borrowAmount = (_exData.srcAmount > maxBorrow) ? maxBorrow : _exData.srcAmount;

        require(CTokenInterface(_cAddresses[1]).borrow(borrowAmount) == 0);

        address collToken = getUnderlyingAddr(_cAddresses[0]);
        address borrowToken = getUnderlyingAddr(_cAddresses[1]);

        uint swapAmount = 0;

        if (collToken != borrowToken) {
            borrowAmount -= getFee(borrowAmount, user, _gasCost, _cAddresses[1]);

            _exData.srcAmount = borrowAmount;
            (,swapAmount) = _sell(_exData);
        } else {
            swapAmount = borrowAmount;
            swapAmount -= getGasCost(swapAmount, _gasCost, _cAddresses[1]);
        }

        approveCToken(collToken, _cAddresses[0]);

        if (collToken != ETH_ADDRESS) {
            require(CTokenInterface(_cAddresses[0]).mint(swapAmount) == 0);
        } else {
            CEtherInterface(_cAddresses[0]).mint{value: swapAmount}(); // reverts on fail
        }

        // handle 0x fee
        tx.origin.transfer(address(this).balance);

        // log amount, collToken, borrowToken
        logger.Log(address(this), msg.sender, "CompoundBoost", abi.encode(_exData.srcAmount, swapAmount, collToken, borrowToken));
    }

}
