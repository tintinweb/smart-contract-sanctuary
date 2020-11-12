// Copyright (C) 2018  Argent Labs Ltd. <https://argent.xyz>

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.12;

import "./BaseFeature.sol";
import "./ICompoundRegistry.sol";

interface IComptroller {
    function enterMarkets(address[] calldata _cTokens) external returns (uint[] memory);
    function exitMarket(address _cToken) external returns (uint);
    function getAssetsIn(address _account) external view returns (address[] memory);
    function getAccountLiquidity(address _account) external view returns (uint, uint, uint);
    function checkMembership(address account, ICToken cToken) external view returns (bool);
}

interface ICToken {
    function comptroller() external view returns (address);
    function underlying() external view returns (address);
    function symbol() external view returns (string memory);
    function exchangeRateCurrent() external returns (uint256);
    function exchangeRateStored() external view returns (uint256);
    function balanceOf(address _account) external view returns (uint256);
    function borrowBalanceCurrent(address _account) external returns (uint256);
    function borrowBalanceStored(address _account) external view returns (uint256);
}

/**
 * @title CompoundManager
 * @notice Module to invest and borrow tokens with CompoundV2
 * @author Julien Niset - <julien@argent.xyz>
 */
contract CompoundManager is BaseFeature{

    bytes32 constant NAME = "CompoundManager";

    // The Compound IComptroller contract
    IComptroller public comptroller;
    // The registry mapping underlying with cTokens
    ICompoundRegistry public compoundRegistry;

    event InvestmentAdded(address indexed _wallet, address _token, uint256 _invested, uint256 _period);
    event InvestmentRemoved(address indexed _wallet, address _token, uint256 _fraction);
    event LoanOpened(
        address indexed _wallet,
        bytes32 indexed _loanId,
        address _collateral,
        uint256 _collateralAmount,
        address _debtToken,
        uint256 _debtAmount);
    event LoanClosed(address indexed _wallet, bytes32 indexed _loanId);
    event CollateralAdded(address indexed _wallet, bytes32 indexed _loanId, address _collateral, uint256 _collateralAmount);
    event CollateralRemoved(address indexed _wallet, bytes32 indexed _loanId, address _collateral, uint256 _collateralAmount);
    event DebtAdded(address indexed _wallet, bytes32 indexed _loanId, address _debtToken, uint256 _debtAmount);
    event DebtRemoved(address indexed _wallet, bytes32 indexed _loanId, address _debtToken, uint256 _debtAmount);

    using SafeMath for uint256;

    constructor(
        ILockStorage _lockStorage,
        IComptroller _comptroller,
        ICompoundRegistry _compoundRegistry,
        IVersionManager _versionManager
    )
        BaseFeature(_lockStorage, _versionManager, NAME)
        public
    {
        comptroller = _comptroller;
        compoundRegistry = _compoundRegistry;
    }

    /**
     * @inheritdoc IFeature
     */
    function getRequiredSignatures(address, bytes calldata) external view override returns (uint256, OwnerSignature) {
        return (1, OwnerSignature.Required);
    }

    /* ********************************** Implementation of Loan ************************************* */

    /**
     * @notice Opens a collateralized loan.
     * @param _wallet The target wallet.
     * @param _collateral The token used as a collateral.
     * @param _collateralAmount The amount of collateral token provided.
     * @param _debtToken The token borrowed.
     * @param _debtAmount The amount of tokens borrowed.
     * @return _loanId bytes32(0) as Compound does not allow the creation of multiple loans.
     */
    function openLoan(
        address _wallet,
        address _collateral,
        uint256 _collateralAmount,
        address _debtToken,
        uint256 _debtAmount
    )
        external
        onlyWalletOwnerOrFeature(_wallet)
        onlyWhenUnlocked(_wallet)
        returns (bytes32 _loanId)
    {
        address[] memory markets = new address[](2);
        markets[0] = compoundRegistry.getCToken(_collateral);
        markets[1] = compoundRegistry.getCToken(_debtToken);
        invokeWallet(_wallet, address(comptroller), 0, abi.encodeWithSignature("enterMarkets(address[])", markets));
        mint(_wallet, markets[0], _collateral, _collateralAmount);
        borrow(_wallet, _debtToken, markets[1], _debtAmount);
        emit LoanOpened(_wallet, _loanId, _collateral, _collateralAmount, _debtToken, _debtAmount);
    }

    /**
     * @notice Closes the collateralized loan in all markets by repaying all debts (plus interest). Note that it does not redeem the collateral.
     * @param _wallet The target wallet.
     * @param _loanId bytes32(0) as Compound does not allow the creation of multiple loans.
     */
    function closeLoan(
        address _wallet,
        bytes32 _loanId
    )
        external
        onlyWalletOwnerOrFeature(_wallet)
        onlyWhenUnlocked(_wallet)
    {
        address[] memory markets = comptroller.getAssetsIn(_wallet);
        for (uint i = 0; i < markets.length; i++) {
            address cToken = markets[i];
            uint debt = ICToken(cToken).borrowBalanceCurrent(_wallet);
            if (debt > 0) {
                repayBorrow(_wallet, cToken, debt);
                uint collateral = ICToken(cToken).balanceOf(_wallet);
                if (collateral == 0) {
                    invokeWallet(
                        _wallet,
                        address(comptroller),
                        0,
                        abi.encodeWithSignature("exitMarket(address)", address(cToken))
                    );
                }
            }
        }
        emit LoanClosed(_wallet, _loanId);
    }

    /**
     * @notice Adds collateral to a loan identified by its ID.
     * @param _wallet The target wallet.
     * @param _loanId bytes32(0) as Compound does not allow the creation of multiple loans.
     * @param _collateral The token used as a collateral.
     * @param _collateralAmount The amount of collateral to add.
     */
    function addCollateral(
        address _wallet,
        bytes32 _loanId,
        address _collateral,
        uint256 _collateralAmount
    )
        external
        onlyWalletOwnerOrFeature(_wallet)
        onlyWhenUnlocked(_wallet)
    {
        address cToken = compoundRegistry.getCToken(_collateral);
        enterMarketIfNeeded(_wallet, cToken, address(comptroller));
        mint(_wallet, cToken, _collateral, _collateralAmount);
        emit CollateralAdded(_wallet, _loanId, _collateral, _collateralAmount);
    }

    /**
     * @notice Removes collateral from a loan identified by its ID.
     * @param _wallet The target wallet.
     * @param _loanId bytes32(0) as Compound does not allow the creation of multiple loans.
     * @param _collateral The token used as a collateral.
     * @param _collateralAmount The amount of collateral to remove.
     */
    function removeCollateral(
        address _wallet,
        bytes32 _loanId,
        address _collateral,
        uint256 _collateralAmount
    )
        external
        onlyWalletOwnerOrFeature(_wallet)
        onlyWhenUnlocked(_wallet)
    {
        address cToken = compoundRegistry.getCToken(_collateral);
        redeemUnderlying(_wallet, cToken, _collateralAmount);
        exitMarketIfNeeded(_wallet, cToken, address(comptroller));
        emit CollateralRemoved(_wallet, _loanId, _collateral, _collateralAmount);
    }

    /**
     * @notice Increases the debt by borrowing more token from a loan identified by its ID.
     * @param _wallet The target wallet.
     * @param _loanId bytes32(0) as Compound does not allow the creation of multiple loans.
     * @param _debtToken The token borrowed.
     * @param _debtAmount The amount of token to borrow.
     */
    function addDebt(
        address _wallet,
        bytes32 _loanId,
        address _debtToken,
        uint256 _debtAmount
    )
        external
        onlyWalletOwnerOrFeature(_wallet)
        onlyWhenUnlocked(_wallet)
    {
        address dToken = compoundRegistry.getCToken(_debtToken);
        enterMarketIfNeeded(_wallet, dToken, address(comptroller));
        borrow(_wallet, _debtToken, dToken, _debtAmount);
        emit DebtAdded(_wallet, _loanId, _debtToken, _debtAmount);
    }

    /**
     * @notice Decreases the debt by repaying some token from a loan identified by its ID.
     * @param _wallet The target wallet.
     * @param _loanId bytes32(0) as Compound does not allow the creation of multiple loans.
     * @param _debtToken The token to repay.
     * @param _debtAmount The amount of token to repay.
     */
    function removeDebt(
        address _wallet,
        bytes32 _loanId,
        address _debtToken,
        uint256 _debtAmount
    )
        external
        onlyWalletOwnerOrFeature(_wallet)
        onlyWhenUnlocked(_wallet)
    {
        address dToken = compoundRegistry.getCToken(_debtToken);
        repayBorrow(_wallet, dToken, _debtAmount);
        exitMarketIfNeeded(_wallet, dToken, address(comptroller));
        emit DebtRemoved(_wallet, _loanId, _debtToken, _debtAmount);
    }

    /**
     * @notice Gets information about the loan status on Compound.
     * @param _wallet The target wallet.
     * @return _status Status [0: no loan, 1: loan is safe, 2: loan is unsafe and can be liquidated]
     * @return _ethValue Value (in ETH) representing the value that could still be borrowed when status = 1; or the value of the collateral
     * that should be added to avoid liquidation when status = 2.
     */
    function getLoan(
        address _wallet,
        bytes32 /* _loanId */
    )
        external
        view
        returns (uint8 _status, uint256 _ethValue)
    {
        (uint error, uint liquidity, uint shortfall) = comptroller.getAccountLiquidity(_wallet);
        require(error == 0, "CM: failed to get account liquidity");
        if (liquidity > 0) {
            return (1, liquidity);
        }
        if (shortfall > 0) {
            return (2, shortfall);
        }
        return (0,0);
    }

    /* ********************************** Implementation of Invest ************************************* */

    /**
     * @notice Invest tokens for a given period.
     * @param _wallet The target wallet.
     * @param _token The token address.
     * @param _amount The amount of tokens to invest.
     * @param _period The period over which the tokens may be locked in the investment (optional).
     * @return _invested The exact amount of tokens that have been invested.
     */
    function addInvestment(
        address _wallet,
        address _token,
        uint256 _amount,
        uint256 _period
    )
        external
        onlyWalletOwnerOrFeature(_wallet)
        onlyWhenUnlocked(_wallet)
        returns (uint256 _invested)
    {
        address cToken = compoundRegistry.getCToken(_token);
        mint(_wallet, cToken, _token, _amount);
        _invested = _amount;
        emit InvestmentAdded(_wallet, _token, _amount, _period);
    }

    /**
     * @notice Exit invested postions.
     * @param _wallet The target wallet.
     * @param _token The token address.
     * @param _fraction The fraction of invested tokens to exit in per 10000.
     */
    function removeInvestment(
        address _wallet,
        address _token,
        uint256 _fraction
    )
        external
        onlyWalletOwnerOrFeature(_wallet)
        onlyWhenUnlocked(_wallet)
    {
        require(_fraction <= 10000, "CM: invalid fraction value");
        address cToken = compoundRegistry.getCToken(_token);
        uint shares = ICToken(cToken).balanceOf(_wallet);
        redeem(_wallet, cToken, shares.mul(_fraction).div(10000));
        emit InvestmentRemoved(_wallet, _token, _fraction);
    }

    /**
     * @notice Get the amount of investment in a given token.
     * @param _wallet The target wallet.
     * @param _token The token address.
     * @return _tokenValue The value in tokens of the investment (including interests).
     * @return _periodEnd The time at which the investment can be removed.
     */
    function getInvestment(
        address _wallet,
        address _token
    )
        external
        view
        returns (uint256 _tokenValue, uint256 _periodEnd)
    {
        address cToken = compoundRegistry.getCToken(_token);
        uint amount = ICToken(cToken).balanceOf(_wallet);
        uint exchangeRateMantissa = ICToken(cToken).exchangeRateStored();
        _tokenValue = amount.mul(exchangeRateMantissa).div(10 ** 18);
        _periodEnd = 0;
    }

    /* ****************************************** Compound wrappers ******************************************* */

    /**
     * @notice Adds underlying tokens to a cToken contract.
     * @param _wallet The target wallet.
     * @param _cToken The cToken contract.
     * @param _token The underlying token.
     * @param _amount The amount of underlying token to add.
     */
    function mint(address _wallet, address _cToken, address _token, uint256 _amount) internal {
        require(_cToken != address(0), "CM: No market for target token");
        require(_amount > 0, "CM: amount cannot be 0");
        uint256 initialCTokenAmount = ERC20(_cToken).balanceOf(_wallet);
        if (_token == ETH_TOKEN) {
            invokeWallet(_wallet, _cToken, _amount, abi.encodeWithSignature("mint()"));
        } else {
            invokeWallet(_wallet, _token, 0, abi.encodeWithSignature("approve(address,uint256)", _cToken, _amount));
            invokeWallet(_wallet, _cToken, 0, abi.encodeWithSignature("mint(uint256)", _amount));
        }
        require(ERC20(_cToken).balanceOf(_wallet) > initialCTokenAmount, "CM: mint failed");
    }

    /**
     * @notice Redeems underlying tokens from a cToken contract.
     * @param _wallet The target wallet.
     * @param _cToken The cToken contract.
     * @param _amount The amount of cToken to redeem.
     */
    function redeem(address _wallet, address _cToken, uint256 _amount) internal {
        // The following commented `require()` is not necessary as `ICToken(cToken).balanceOf(_wallet)` in `removeInvestment()`
        // would have reverted if `_cToken == address(0)`
        // It is however left as a comment as a reminder to include it if `removeInvestment()` is changed to use amounts instead of fractions.
        // require(_cToken != address(0), "CM: No market for target token");
        require(_amount > 0, "CM: amount cannot be 0");
        uint256 initialCTokenAmount = ERC20(_cToken).balanceOf(_wallet);
        invokeWallet(_wallet, _cToken, 0, abi.encodeWithSignature("redeem(uint256)", _amount));
        require(ERC20(_cToken).balanceOf(_wallet) < initialCTokenAmount, "CM: redeem failed");
    }

    /**
     * @notice Redeems underlying tokens from a cToken contract.
     * @param _wallet The target wallet.
     * @param _cToken The cToken contract.
     * @param _amount The amount of underlying token to redeem.
     */
    function redeemUnderlying(address _wallet, address _cToken, uint256 _amount) internal {
        require(_cToken != address(0), "CM: No market for target token");
        require(_amount > 0, "CM: amount cannot be 0");
        uint256 initialCTokenAmount = ERC20(_cToken).balanceOf(_wallet);
        invokeWallet(_wallet, _cToken, 0, abi.encodeWithSignature("redeemUnderlying(uint256)", _amount));
        require(ERC20(_cToken).balanceOf(_wallet) < initialCTokenAmount, "CM: redeemUnderlying failed");
    }

    /**
     * @notice Borrows underlying tokens from a cToken contract.
     * @param _wallet The target wallet.
     * @param _token The token contract.
     * @param _cToken The cToken contract.
     * @param _amount The amount of underlying tokens to borrow.
     */
    function borrow(address _wallet, address _token, address _cToken, uint256 _amount) internal {
        require(_cToken != address(0), "CM: No market for target token");
        require(_amount > 0, "CM: amount cannot be 0");
        uint256 initialTokenAmount = _token == ETH_TOKEN ? _wallet.balance : ERC20(_token).balanceOf(_wallet);
        invokeWallet(_wallet, _cToken, 0, abi.encodeWithSignature("borrow(uint256)", _amount));
        uint256 finalTokenAmount = _token == ETH_TOKEN ? _wallet.balance : ERC20(_token).balanceOf(_wallet);
        require(finalTokenAmount > initialTokenAmount, "CM: borrow failed");
    }

    /**
     * @notice Repays some borrowed underlying tokens to a cToken contract.
     * @param _wallet The target wallet.
     * @param _cToken The cToken contract.
     * @param _amount The amount of underlying to repay.
     */
    function repayBorrow(address _wallet, address _cToken, uint256 _amount) internal {
        require(_cToken != address(0), "CM: No market for target token");
        require(_amount > 0, "CM: amount cannot be 0");
        string memory symbol = ICToken(_cToken).symbol();
        uint256 initialTokenAmount;
        uint256 finalTokenAmount;
        if (keccak256(abi.encodePacked(symbol)) == keccak256(abi.encodePacked("cETH"))) {
            initialTokenAmount = _wallet.balance;
            invokeWallet(_wallet, _cToken, _amount, abi.encodeWithSignature("repayBorrow()"));
            finalTokenAmount = _wallet.balance;
        } else {
            address token = ICToken(_cToken).underlying();
            initialTokenAmount = ERC20(token).balanceOf(_wallet);
            invokeWallet(_wallet, token, 0, abi.encodeWithSignature("approve(address,uint256)", _cToken, _amount));
            invokeWallet(_wallet, _cToken, 0, abi.encodeWithSignature("repayBorrow(uint256)", _amount));
            finalTokenAmount = ERC20(token).balanceOf(_wallet);
        }
        require(finalTokenAmount < initialTokenAmount, "CM: repayBorrow failed");
    }

    /**
     * @notice Enters a cToken market if it was not entered before.
     * @param _wallet The target wallet.
     * @param _cToken The cToken contract.
     * @param _comptroller The comptroller contract.
     */
    function enterMarketIfNeeded(address _wallet, address _cToken, address _comptroller) internal {
        bool isEntered = IComptroller(_comptroller).checkMembership(_wallet, ICToken(_cToken));
        if (!isEntered) {
            address[] memory market = new address[](1);
            market[0] = _cToken;
            invokeWallet(_wallet, _comptroller, 0, abi.encodeWithSignature("enterMarkets(address[])", market));
        }
    }

    /**
     * @notice Exits a cToken market if there is no more collateral and debt.
     * @param _wallet The target wallet.
     * @param _cToken The cToken contract.
     * @param _comptroller The comptroller contract.
     */
    function exitMarketIfNeeded(address _wallet, address _cToken, address _comptroller) internal {
        uint collateral = ICToken(_cToken).balanceOf(_wallet);
        uint debt = ICToken(_cToken).borrowBalanceStored(_wallet);
        if (collateral == 0 && debt == 0) {
            invokeWallet(_wallet, _comptroller, 0, abi.encodeWithSignature("exitMarket(address)", _cToken));
        }
    }
}
