pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../utils/SafeERC20.sol";
import "../../exchange/SaverExchangeCore.sol";
import "../../interfaces/CTokenInterface.sol";
import "../../utils/Discount.sol";
import "../helpers/CompoundSaverHelper.sol";
import "../../loggers/DefisaverLogger.sol";

/// @title Implements the actual logic of Repay/Boost with FL
contract CompoundSaverFlashProxy is SaverExchangeCore, CompoundSaverHelper  {

    address public constant DEFISAVER_LOGGER = 0x5c55B921f590a89C1Ebe84dF170E655a82b62126;

    using SafeERC20 for ERC20;

    /// @notice Repays the position and sends tokens back for FL
    /// @param _exData Exchange data
    /// @param _cAddresses cTokens addreses and exchange [cCollAddress, cBorrowAddress]
    /// @param _gasCost Gas cost for transaction
    /// @param _flashLoanData Data about FL [amount, fee]
    function flashRepay(
        ExchangeData memory _exData,
        address[2] memory _cAddresses, // cCollAddress, cBorrowAddress
        uint256 _gasCost,
        uint[2] memory _flashLoanData // amount, fee
    ) public payable {
        enterMarket(_cAddresses[0], _cAddresses[1]);

        address payable user = payable(getUserAddress());
        uint flashBorrowed = _flashLoanData[0] + _flashLoanData[1];

        uint maxColl = getMaxCollateral(_cAddresses[0], address(this));

        // draw max coll
        require(CTokenInterface(_cAddresses[0]).redeemUnderlying(maxColl) == 0);

        address collToken = getUnderlyingAddr(_cAddresses[0]);
        address borrowToken = getUnderlyingAddr(_cAddresses[1]);

        uint swapAmount = 0;

        if (collToken != borrowToken) {
            // swap max coll + loanAmount
            _exData.srcAmount = maxColl + _flashLoanData[0];
            (,swapAmount) = _sell(_exData);

            // get fee
            swapAmount -= getFee(swapAmount, user, _gasCost, _cAddresses[1]);
        } else {
            swapAmount = (maxColl + _flashLoanData[0]);
            swapAmount -= getGasCost(swapAmount, _gasCost, _cAddresses[1]);
        }

        // payback debt
        paybackDebt(swapAmount, _cAddresses[1], borrowToken, user);

        // draw collateral for loanAmount + loanFee
        require(CTokenInterface(_cAddresses[0]).redeemUnderlying(flashBorrowed) == 0);

        // repay flash loan
        returnFlashLoan(collToken, flashBorrowed);

        DefisaverLogger(DEFISAVER_LOGGER).Log(address(this), msg.sender, "CompoundRepay", abi.encode(_exData.srcAmount, swapAmount, collToken, borrowToken));
    }

    /// @notice Boosts the position and sends tokens back for FL
    /// @param _exData Exchange data
    /// @param _cAddresses cTokens addreses and exchange [cCollAddress, cBorrowAddress]
    /// @param _gasCost Gas cost for specific transaction
    /// @param _flashLoanData Data about FL [amount, fee]
    function flashBoost(
        ExchangeData memory _exData,
        address[2] memory _cAddresses, // cCollAddress, cBorrowAddress
        uint256 _gasCost,
        uint[2] memory _flashLoanData // amount, fee
    ) public payable {
        enterMarket(_cAddresses[0], _cAddresses[1]);

        address payable user = payable(getUserAddress());
        uint flashBorrowed = _flashLoanData[0] + _flashLoanData[1];

        // borrow max amount
        uint borrowAmount = getMaxBorrow(_cAddresses[1], address(this));
        require(CTokenInterface(_cAddresses[1]).borrow(borrowAmount) == 0);

        address collToken = getUnderlyingAddr(_cAddresses[0]);
        address borrowToken = getUnderlyingAddr(_cAddresses[1]);

        uint swapAmount = 0;

        if (collToken != borrowToken) {
            // get dfs fee
            borrowAmount -= getFee((borrowAmount + _flashLoanData[0]), user, _gasCost, _cAddresses[1]);
            _exData.srcAmount = (borrowAmount + _flashLoanData[0]);

            (,swapAmount) = _sell(_exData);
        } else {
            swapAmount = (borrowAmount + _flashLoanData[0]);
            swapAmount -= getGasCost(swapAmount, _gasCost, _cAddresses[1]);
        }

        // deposit swaped collateral
        depositCollateral(collToken, _cAddresses[0], swapAmount);

        // borrow token to repay flash loan
        require(CTokenInterface(_cAddresses[1]).borrow(flashBorrowed) == 0);

        // repay flash loan
        returnFlashLoan(borrowToken, flashBorrowed);

        DefisaverLogger(DEFISAVER_LOGGER).Log(address(this), msg.sender, "CompoundBoost", abi.encode(_exData.srcAmount, swapAmount, collToken, borrowToken));
    }

    /// @notice Helper method to deposit tokens in Compound
    /// @param _collToken Token address of the collateral
    /// @param _cCollToken CToken address of the collateral
    /// @param _depositAmount Amount to deposit
    function depositCollateral(address _collToken, address _cCollToken, uint _depositAmount) internal {
        approveCToken(_collToken, _cCollToken);

        if (_collToken != ETH_ADDRESS) {
            require(CTokenInterface(_cCollToken).mint(_depositAmount) == 0);
        } else {
            CEtherInterface(_cCollToken).mint{value: _depositAmount}(); // reverts on fail
        }
    }

    /// @notice Returns the tokens/ether to the msg.sender which is the FL contract
    /// @param _tokenAddr Address of token which we return
    /// @param _amount Amount to return
    function returnFlashLoan(address _tokenAddr, uint _amount) internal {
        if (_tokenAddr != ETH_ADDRESS) {
            ERC20(_tokenAddr).safeTransfer(msg.sender, _amount);
        }

        msg.sender.transfer(address(this).balance);
    }

}
