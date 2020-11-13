// Copyright (C) 2019  Argent Labs Ltd. <https://argent.xyz>

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

import "./MakerV2Base.sol";
import "./IUniswapExchange.sol";
import "./IUniswapFactory.sol";

/**
 * @title MakerV2Loan
 * @notice Module to migrate old CDPs and open and manage new vaults. The vaults managed by
 * this module are directly owned by the module. This is to prevent a compromised wallet owner
 * from being able to use `TransferManager.callContract()` to transfer ownership of a vault
 * (a type of asset NOT protected by a wallet's daily limit) to another account.
 * @author Olivier VDB - <olivier@argent.xyz>
 */
abstract contract MakerV2Loan is MakerV2Base {

    bytes4 private constant IS_NEW_VERSION = bytes4(keccak256("isNewVersion(address)"));

    // The address of the MKR token
    GemLike internal mkrToken;
    // The address of the WETH token
    GemLike internal wethToken;
    // The address of the WETH Adapter
    JoinLike internal wethJoin;
    // The address of the Jug
    JugLike internal jug;
    // The address of the Vault Manager (referred to as 'CdpManager' to match Maker's naming)
    ManagerLike internal cdpManager;
    // The address of the SCD Tub
    SaiTubLike internal tub;
    // The Maker Registry in which all supported collateral tokens and their adapters are stored
    IMakerRegistry internal makerRegistry;
    // The Uniswap Exchange contract for DAI
    IUniswapExchange internal daiUniswap;
    // The Uniswap Exchange contract for MKR
    IUniswapExchange internal mkrUniswap;
    // Mapping [wallet][ilk] -> loanId, that keeps track of cdp owners
    // while also enforcing a maximum of one loan per token (ilk) and per wallet
    // (which will make future upgrades of the module easier)
    mapping(address => mapping(bytes32 => bytes32)) public loanIds;
    // Lock used by nonReentrant()
    bool private _notEntered = true;

    // ****************** Events *************************** //

    // Vault management events
    event LoanOpened(
        address indexed _wallet,
        bytes32 indexed _loanId,
        address _collateral,
        uint256 _collateralAmount,
        address _debtToken,
        uint256 _debtAmount
    );
    event LoanAcquired(address indexed _wallet, bytes32 indexed _loanId);
    event LoanClosed(address indexed _wallet, bytes32 indexed _loanId);
    event CollateralAdded(address indexed _wallet, bytes32 indexed _loanId, address _collateral, uint256 _collateralAmount);
    event CollateralRemoved(address indexed _wallet, bytes32 indexed _loanId, address _collateral, uint256 _collateralAmount);
    event DebtAdded(address indexed _wallet, bytes32 indexed _loanId, address _debtToken, uint256 _debtAmount);
    event DebtRemoved(address indexed _wallet, bytes32 indexed _loanId, address _debtToken, uint256 _debtAmount);


    // *************** Modifiers *************************** //

    /**
     * @notice Prevents call reentrancy
     */
    modifier nonReentrant() {
        require(_notEntered, "MV2: reentrant call");
        _notEntered = false;
        _;
        _notEntered = true;
    }

    modifier onlyNewVersion() {
        (bool success, bytes memory res) = msg.sender.call(abi.encodeWithSignature("isNewVersion(address)", address(this)));
        require(success && abi.decode(res, (bytes4)) == IS_NEW_VERSION , "MV2: not a new version");
        _;
    }

    // *************** Constructor ********************** //

    constructor(
        JugLike _jug,
        IMakerRegistry _makerRegistry,
        IUniswapFactory _uniswapFactory
    )
        public
    {
        cdpManager = ScdMcdMigrationLike(scdMcdMigration).cdpManager();
        tub = ScdMcdMigrationLike(scdMcdMigration).tub();
        wethJoin = ScdMcdMigrationLike(scdMcdMigration).wethJoin();
        wethToken = wethJoin.gem();
        mkrToken = tub.gov();
        jug = _jug;
        makerRegistry = _makerRegistry;
        daiUniswap = IUniswapExchange(_uniswapFactory.getExchange(address(daiToken)));
        mkrUniswap = IUniswapExchange(_uniswapFactory.getExchange(address(mkrToken)));
        // Authorize daiJoin to exit DAI from the module's internal balance in the vat
        vat.hope(address(daiJoin));
    }

    // *************** External/Public Functions ********************* //

    /* ********************************** Implementation of Loan ************************************* */

   /**
     * @notice Opens a collateralized loan.
     * @param _wallet The target wallet.
     * @param _collateral The token used as a collateral.
     * @param _collateralAmount The amount of collateral token provided.
     * @param _debtToken The token borrowed (must be the address of the DAI contract).
     * @param _debtAmount The amount of tokens borrowed.
     * @return _loanId The ID of the created vault.
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
        verifySupportedCollateral(_collateral);
        require(_debtToken == address(daiToken), "MV2: debt token not DAI");
        _loanId = bytes32(openVault(_wallet, _collateral, _collateralAmount, _debtAmount));
        emit LoanOpened(_wallet, _loanId, _collateral, _collateralAmount, _debtToken, _debtAmount);
    }

    /**
     * @notice Adds collateral to a loan identified by its ID.
     * @param _wallet The target wallet.
     * @param _loanId The ID of the target vault.
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
        verifyLoanOwner(_wallet, _loanId);
        addCollateral(_wallet, uint256(_loanId), _collateralAmount);
        emit CollateralAdded(_wallet, _loanId, _collateral, _collateralAmount);
    }

    /**
     * @notice Removes collateral from a loan identified by its ID.
     * @param _wallet The target wallet.
     * @param _loanId The ID of the target vault.
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
        verifyLoanOwner(_wallet, _loanId);
        removeCollateral(_wallet, uint256(_loanId), _collateralAmount);
        emit CollateralRemoved(_wallet, _loanId, _collateral, _collateralAmount);
    }

    /**
     * @notice Increases the debt by borrowing more token from a loan identified by its ID.
     * @param _wallet The target wallet.
     * @param _loanId The ID of the target vault.
     * @param _debtToken The token borrowed (must be the address of the DAI contract).
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
        verifyLoanOwner(_wallet, _loanId);
        addDebt(_wallet, uint256(_loanId), _debtAmount);
        emit DebtAdded(_wallet, _loanId, _debtToken, _debtAmount);
    }

    /**
     * @notice Decreases the debt by repaying some token from a loan identified by its ID.
     * @param _wallet The target wallet.
     * @param _loanId The ID of the target vault.
     * @param _debtToken The token to repay (must be the address of the DAI contract).
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
        verifyLoanOwner(_wallet, _loanId);
        updateStabilityFee(uint256(_loanId));
        removeDebt(_wallet, uint256(_loanId), _debtAmount);
        emit DebtRemoved(_wallet, _loanId, _debtToken, _debtAmount);
    }

    /**
     * @notice Closes a collateralized loan by repaying all debts (plus interest) and redeeming all collateral.
     * @param _wallet The target wallet.
     * @param _loanId The ID of the target vault.
     */
    function closeLoan(
        address _wallet,
        bytes32 _loanId
    )
        external
        onlyWalletOwnerOrFeature(_wallet)
        onlyWhenUnlocked(_wallet)
    {
        verifyLoanOwner(_wallet, _loanId);
        updateStabilityFee(uint256(_loanId));
        closeVault(_wallet, uint256(_loanId));
        emit LoanClosed(_wallet, _loanId);
    }

    /* *************************************** Other vault methods ***************************************** */

    /**
     * @notice Lets a vault owner transfer their vault from their wallet to the present module so the vault
     * can be managed by the module.
     * @param _wallet The target wallet.
     * @param _loanId The ID of the target vault.
     */
    function acquireLoan(
        address _wallet,
        bytes32 _loanId
    )
        external
        nonReentrant
        onlyWalletOwnerOrFeature(_wallet)
        onlyWhenUnlocked(_wallet)
    {
        require(cdpManager.owns(uint256(_loanId)) == _wallet, "MV2: wrong vault owner");
        // Transfer the vault from the wallet to the module
        invokeWallet(
            _wallet,
            address(cdpManager),
            0,
            abi.encodeWithSignature("give(uint256,address)", uint256(_loanId), address(this))
        );
        require(cdpManager.owns(uint256(_loanId)) == address(this), "MV2: failed give");
        // Mark the incoming vault as belonging to the wallet (or merge it into the existing vault if there is one)
        assignLoanToWallet(_wallet, _loanId);
        emit LoanAcquired(_wallet, _loanId);
    }

    /**
     * @notice Lets a future upgrade of this module transfer a vault to itself
     * @param _wallet The target wallet.
     * @param _loanId The ID of the target vault.
     */
    function giveVault(
        address _wallet,
        bytes32 _loanId
    )
        external
        onlyWalletFeature(_wallet)
        onlyNewVersion
        onlyWhenUnlocked(_wallet)
    {
        verifyLoanOwner(_wallet, _loanId);
        cdpManager.give(uint256(_loanId), msg.sender);
        clearLoanOwner(_wallet, _loanId);
    }

    /* ************************************** Internal Functions ************************************** */

    function toInt(uint256 _x) internal pure returns (int _y) {
        _y = int(_x);
        require(_y >= 0, "MV2: int overflow");
    }

    function assignLoanToWallet(address _wallet, bytes32 _loanId) internal returns (bytes32 _assignedLoanId) {
        bytes32 ilk = cdpManager.ilks(uint256(_loanId));
        // Check if the user already holds a vault in the MakerV2Manager
        bytes32 existingLoanId = loanIds[_wallet][ilk];
        if (existingLoanId > 0) {
            // Merge the new loan into the existing loan
            cdpManager.shift(uint256(_loanId), uint256(existingLoanId));
            return existingLoanId;
        }
        // Record the new vault as belonging to the wallet
        loanIds[_wallet][ilk] = _loanId;
        return _loanId;
    }

    function clearLoanOwner(address _wallet, bytes32 _loanId) internal {
        delete loanIds[_wallet][cdpManager.ilks(uint256(_loanId))];
    }

    function verifyLoanOwner(address _wallet, bytes32 _loanId) internal view {
        require(loanIds[_wallet][cdpManager.ilks(uint256(_loanId))] == _loanId, "MV2: unauthorized loanId");
    }

    function verifySupportedCollateral(address _collateral) internal view {
        if (_collateral != ETH_TOKEN) {
            (bool collateralSupported,,,) = makerRegistry.collaterals(_collateral);
            require(collateralSupported, "MV2: unsupported collateral");
        }
    }

    function joinCollateral(
        address _wallet,
        uint256 _cdpId,
        uint256 _collateralAmount,
        bytes32 _ilk
    )
        internal
    {
        // Get the adapter and collateral token for the vault
        (JoinLike gemJoin, GemLike collateral) = makerRegistry.getCollateral(_ilk);
        // Convert ETH to WETH if needed
        if (gemJoin == wethJoin) {
            invokeWallet(_wallet, address(wethToken), _collateralAmount, abi.encodeWithSignature("deposit()"));
        }
        // Send the collateral to the module
        invokeWallet(
            _wallet,
            address(collateral),
            0,
            abi.encodeWithSignature("transfer(address,uint256)", address(this), _collateralAmount)
        );
        // Approve the adapter to pull the collateral from the module
        collateral.approve(address(gemJoin), _collateralAmount);
        // Join collateral to the adapter. The first argument to `join` is the address that *technically* owns the vault
        gemJoin.join(cdpManager.urns(_cdpId), _collateralAmount);
    }

    function joinDebt(
        address _wallet,
        uint256 _cdpId,
        uint256 _debtAmount //  art.mul(rate).div(RAY) === [wad]*[ray]/[ray]=[wad]
    )
        internal
    {
        // Send the DAI to the module
        invokeWallet(
            _wallet,
            address(daiToken),
            0,
            abi.encodeWithSignature("transfer(address,uint256)", address(this), _debtAmount)
        );
        // Approve the DAI adapter to burn DAI from the module
        daiToken.approve(address(daiJoin), _debtAmount);
        // Join DAI to the adapter. The first argument to `join` is the address that *technically* owns the vault
        // To avoid rounding issues, we substract one wei to the amount joined
        daiJoin.join(cdpManager.urns(_cdpId), _debtAmount.sub(1));
    }

    function drawAndExitDebt(
        address _wallet,
        uint256 _cdpId,
        uint256 _debtAmount,
        uint256 _collateralAmount,
        bytes32 _ilk
    )
        internal
    {
        // Get the accumulated rate for the collateral type
        (, uint rate,,,) = vat.ilks(_ilk);
        // Express the debt in the RAD units used internally by the vat
        uint daiDebtInRad = _debtAmount.mul(RAY);
        // Lock the collateral and draw the debt. To avoid rounding issues we add an extra wei of debt
        cdpManager.frob(_cdpId, toInt(_collateralAmount), toInt(daiDebtInRad.div(rate) + 1));
        // Transfer the (internal) DAI debt from the cdp's urn to the module.
        cdpManager.move(_cdpId, address(this), daiDebtInRad);
        // Mint the DAI token and exit it to the user's wallet
        daiJoin.exit(_wallet, _debtAmount);
    }

    function updateStabilityFee(
        uint256 _cdpId
    )
        internal
    {
        jug.drip(cdpManager.ilks(_cdpId));
    }

    function debt(
        uint256 _cdpId
    )
        internal
        view
        returns (uint256 _fullRepayment, uint256 _maxNonFullRepayment)
    {
        bytes32 ilk = cdpManager.ilks(_cdpId);
        (, uint256 art) = vat.urns(ilk, cdpManager.urns(_cdpId));
        if (art > 0) {
            (, uint rate,,, uint dust) = vat.ilks(ilk);
            _maxNonFullRepayment = art.mul(rate).sub(dust).div(RAY);
            _fullRepayment = art.mul(rate).div(RAY)
                .add(1) // the amount approved is 1 wei more than the amount repaid, to avoid rounding issues
                .add(art-art.mul(rate).div(RAY).mul(RAY).div(rate)); // adding 1 extra wei if further rounding issues are expected
        }
    }

    function collateral(
        uint256 _cdpId
    )
        internal
        view
        returns (uint256 _collateralAmount)
    {
        (_collateralAmount,) = vat.urns(cdpManager.ilks(_cdpId), cdpManager.urns(_cdpId));
    }

    function verifyValidRepayment(
        uint256 _cdpId,
        uint256 _debtAmount
    )
        internal
        view
    {
        (uint256 fullRepayment, uint256 maxRepayment) = debt(_cdpId);
        require(_debtAmount <= maxRepayment || _debtAmount == fullRepayment, "MV2: repay less or full");
    }

     /**
     * @notice Lets the owner of a wallet open a new vault. The owner must have enough collateral
     * in their wallet.
     * @param _wallet The target wallet
     * @param _collateral The token to use as collateral in the vault.
     * @param _collateralAmount The amount of collateral to lock in the vault.
     * @param _debtAmount The amount of DAI to draw from the vault
     * @return _cdpId The id of the created vault.
     */
    function openVault(
        address _wallet,
        address _collateral,
        uint256 _collateralAmount,
        uint256 _debtAmount
    )
        internal
        returns (uint256 _cdpId)
    {
        // Continue with WETH as collateral instead of ETH if needed
        if (_collateral == ETH_TOKEN) {
            _collateral = address(wethToken);
        }
        // Get the ilk for the collateral
        bytes32 ilk = makerRegistry.getIlk(_collateral);
        // Open a vault if there isn't already one for the collateral type (the vault owner will effectively be the module)
        _cdpId = uint256(loanIds[_wallet][ilk]);
        if (_cdpId == 0) {
            _cdpId = cdpManager.open(ilk, address(this));
            // Mark the vault as belonging to the wallet
            loanIds[_wallet][ilk] = bytes32(_cdpId);
        }
        // Move the collateral from the wallet to the vat
        joinCollateral(_wallet, _cdpId, _collateralAmount, ilk);
        // Draw the debt and exit it to the wallet
        if (_debtAmount > 0) {
            drawAndExitDebt(_wallet, _cdpId, _debtAmount, _collateralAmount, ilk);
        }
    }

    /**
     * @notice Lets the owner of a vault add more collateral to their vault. The owner must have enough of the
     * collateral token in their wallet.
     * @param _wallet The target wallet
     * @param _cdpId The id of the vault.
     * @param _collateralAmount The amount of collateral to add to the vault.
     */
    function addCollateral(
        address _wallet,
        uint256 _cdpId,
        uint256 _collateralAmount
    )
        internal
    {
        // Move the collateral from the wallet to the vat
        joinCollateral(_wallet, _cdpId, _collateralAmount, cdpManager.ilks(_cdpId));
        // Lock the collateral
        cdpManager.frob(_cdpId, toInt(_collateralAmount), 0);
    }

    /**
     * @notice Lets the owner of a vault remove some collateral from their vault
     * @param _wallet The target wallet
     * @param _cdpId The id of the vault.
     * @param _collateralAmount The amount of collateral to remove from the vault.
     */
    function removeCollateral(
        address _wallet,
        uint256 _cdpId,
        uint256 _collateralAmount
    )
        internal
    {
        // Unlock the collateral
        cdpManager.frob(_cdpId, -toInt(_collateralAmount), 0);
        // Transfer the (internal) collateral from the cdp's urn to the module.
        cdpManager.flux(_cdpId, address(this), _collateralAmount);
        // Get the adapter for the collateral
        (JoinLike gemJoin,) = makerRegistry.getCollateral(cdpManager.ilks(_cdpId));
        // Exit the collateral from the adapter.
        gemJoin.exit(_wallet, _collateralAmount);
        // Convert WETH to ETH if needed
        if (gemJoin == wethJoin) {
            invokeWallet(_wallet, address(wethToken), 0, abi.encodeWithSignature("withdraw(uint256)", _collateralAmount));
        }
    }

    /**
     * @notice Lets the owner of a vault draw more DAI from their vault.
     * @param _wallet The target wallet
     * @param _cdpId The id of the vault.
     * @param _amount The amount of additional DAI to draw from the vault.
     */
    function addDebt(
        address _wallet,
        uint256 _cdpId,
        uint256 _amount
    )
        internal
    {
        // Draw and exit the debt to the wallet
        drawAndExitDebt(_wallet, _cdpId, _amount, 0, cdpManager.ilks(_cdpId));
    }

    /**
     * @notice Lets the owner of a vault partially repay their debt. The repayment is made up of
     * the outstanding DAI debt plus the DAI stability fee.
     * The method will use the user's DAI tokens in priority and will, if needed, convert the required
     * amount of ETH to cover for any missing DAI tokens.
     * @param _wallet The target wallet
     * @param _cdpId The id of the vault.
     * @param _amount The amount of DAI debt to repay.
     */
    function removeDebt(
        address _wallet,
        uint256 _cdpId,
        uint256 _amount
    )
        internal
    {
        verifyValidRepayment(_cdpId, _amount);
        // Move the DAI from the wallet to the vat.
        joinDebt(_wallet, _cdpId, _amount);
        // Get the accumulated rate for the collateral type
        (, uint rate,,,) = vat.ilks(cdpManager.ilks(_cdpId));
        // Repay the debt. To avoid rounding issues we reduce the repayment by one wei
        cdpManager.frob(_cdpId, 0, -toInt(_amount.sub(1).mul(RAY).div(rate)));
    }

    /**
     * @notice Lets the owner of a vault close their vault. The method will:
     * 1) repay all debt and fee
     * 2) free all collateral
     * @param _wallet The target wallet
     * @param _cdpId The id of the CDP.
     */
    function closeVault(
        address _wallet,
        uint256 _cdpId
    )
        internal
    {
        (uint256 fullRepayment,) = debt(_cdpId);
        // Repay the debt
        if (fullRepayment > 0) {
            removeDebt(_wallet, _cdpId, fullRepayment);
        }
        // Remove the collateral
        uint256 ink = collateral(_cdpId);
        if (ink > 0) {
            removeCollateral(_wallet, _cdpId, ink);
        }
    }

}