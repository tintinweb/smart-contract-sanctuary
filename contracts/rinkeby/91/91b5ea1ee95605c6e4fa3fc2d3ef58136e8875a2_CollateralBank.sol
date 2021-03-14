// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Initializable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./CollateralBankInterfaces.sol";
import "./Exponential.sol";

/**
 * @title
 * @notice
 * @author
 */
contract CollateralBank is ERC20Upgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, CollateralBankInterface, Exponential {

    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    function CollateralBank_init(address admin_, address market_, uint initialExchangeRateMantissa_, string memory name_, string memory symbol_) public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
        CollateralBank_init_unchained(admin_, market_, initialExchangeRateMantissa_);
    }

    function CollateralBank_init_unchained(address admin_, address market_, uint initialExchangeRateMantissa_) internal initializer {
        setAdmin(admin_);
        setMarket(market_);
        initialExchangeRateMantissa = initialExchangeRateMantissa_;
        require(initialExchangeRateMantissa > 0, "Initial exchange rate must be greater than zero");
    }

    /*** Modifiers ***/

    modifier onlyAdmin() {
        require(_msgSender() == admin, "CollateralBank: CALLER_IS_NOT_ADMIN");
        _;
    }

    /*** External Functions ***/

    function mint(address to, uint mintAmount) external override {
        accrueInterest();
        mintInternal(to, mintAmount);
        revertOnSupplyOverflowInternal(to);
    }

    function burn(address to, uint burnTokensIn, uint burnAmountIn) external override {
        accrueInterest();
        burnInternal(to, burnTokensIn, burnAmountIn);
    }

    function exchangeRateStored() external override view returns (uint exchangeRate) {
        exchangeRate = exchangeRateStoredInternal();
    }

    function exchangeRateCurrent() external override returns (uint exchangeRate) {
        accrueInterest();
        exchangeRate = exchangeRateStoredInternal();
    }

    /*** Public Functions ***/

    function accrueInterest() public override {
        require(cToken.accrueInterest() == 0, "CollateralBank: MARKET_ACCRUE_INTEREST_FAILED");
    }

    /*** Internal Functions ***/

    function exchangeRateStoredInternal() internal view returns (uint exchangeRate) {
        uint _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            exchangeRate = initialExchangeRateMantissa;
        } else {
            (, , uint totalAssetSupply) = totalAssetSupplyInternal();
            Exp memory exchangeRateExp = getExp(totalAssetSupply, _totalSupply);
            exchangeRate = exchangeRateExp.mantissa;
        }
    }

    function totalAssetSupplyInternal() internal view returns (uint inBankSupply, uint inMarketSupply, uint total) {
        uint marketTokenBalance = cToken.totalTrustedSupply();
        uint marketExchangeRateMantissa = cToken.exchangeRateStored();
        inMarketSupply = mulScalarTruncate(Exp({mantissa: marketExchangeRateMantissa}), marketTokenBalance);
        inBankSupply = aToken.balanceOf(address(this));
        total = inBankSupply.add(inMarketSupply);
    }

    // this low-level function should be called before important safety checks
    function mintInternal(address to, uint mintAmount) internal nonReentrant whenNotPaused returns (uint mintTokens) {
        aToken.safeTransferFrom(msg.sender, address(this), mintAmount);

        uint exchangeRateMantissa = exchangeRateStoredInternal();
        mintTokens = divScalarByExpTruncate(mintAmount, Exp({mantissa: exchangeRateMantissa}));

        require(mintTokens > 0, 'CollateralBank: INSUFFICIENT_SUPPLY_MINTED');

        _mint(to, mintTokens);
        emit Mint(msg.sender, mintTokens, mintAmount, to);
    }

    // this low-level function should be called before important safety checks
    function burnInternal(address to, uint burnTokensIn, uint burnAmountIn) internal nonReentrant whenNotPaused returns (uint burnTokens, uint burnAmount) {
        uint exchangeRateMantissa = exchangeRateStoredInternal();

        if (burnTokensIn > 0) {
            burnTokens = burnTokensIn;
            burnAmount = mulScalarTruncate(Exp({mantissa: exchangeRateMantissa}), burnTokensIn);
        } else {
            burnAmount = burnAmountIn;
            burnTokens = divScalarByExpTruncate(burnAmountIn, Exp({mantissa: exchangeRateMantissa}));
        }

        require(burnTokens > 0 && burnAmount > 0, 'CollateralBank: INSUFFICIENT_SUPPLY_BURNED');

        _burn(msg.sender, burnTokens);
        aToken.safeTransfer(to, burnAmount);
        emit Burn(msg.sender, burnTokens, burnAmount, to);
    }

    function revertOnSupplyOverflowInternal(address account) internal view {
        uint exchangeRateMantissa = exchangeRateStoredInternal();
        uint tokenBalance = balanceOf(account);
        require(tokenBalance > 0, 'CollateralBank: TOKEN_ZERO_BALANCE');
        uint supplyAmount = mulScalarTruncate(Exp({mantissa: exchangeRateMantissa}), tokenBalance);

        TrustedAccount memory supplier = trustedSuppliers[account];
        if (supplier.exists) {
            require(supplier.allowance >= supplyAmount, "CollateralBank: TRUSTED_SUPPLY_OVERFLOW");
        } else if (allowUntrustedSuppliers) {
            require(untrustedSupplyAllowance >= supplyAmount, "CollateralBank: UNTRUSTED_SUPPLY_OVERFLOW");
        } else {
            revert("CollateralBank: UNTRUSTED_SUPPLIER");
        }
    }

    /*** Admin Functions ***/

    function updateSupplier(address account, bool exists, uint allowance) external onlyAdmin whenNotPaused {
        TrustedAccount storage supplier = trustedSuppliers[account];
        require(!trustedBorrowers[account].exists, "CollateralBank: ALREADY_BORROWER");
        emit UpdateSupplier(account, supplier.exists, supplier.allowance, exists, allowance);
        supplier.exists = exists;
        supplier.allowance = allowance;
    }

    function updateBorrower(address account, bool exists, uint allowance) external onlyAdmin whenNotPaused {
        TrustedAccount storage borrower = trustedBorrowers[account];
        require(!trustedSuppliers[account].exists, "CollateralBank: ALREADY_SUPPLIER");
        emit UpdateBorrower(account, borrower.exists, borrower.allowance, exists, allowance);
        borrower.exists = exists;
        borrower.allowance = allowance;
    }

    /*** Owner Functions ***/

    function setAdmin(address newAdmin) public onlyOwner {
        emit NewAdmin(admin, newAdmin);
        admin = newAdmin;
    }

    function setMarket(address newMarket) public onlyOwner {
        /*
         * !!! WARNING !!!
         * Normally market has to be changed only once, on contract creation.
         */
        emit NewMarket(address(cToken), newMarket);
        cToken = CTokenInterface(newMarket);
        cToken.isCToken(); // CToken safety check
        aToken = ERC20Upgradeable(cToken.underlying());
        aToken.safeApprove(address(cToken), uint(-1));
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function pause() public onlyOwner {
        _pause();
    }
}