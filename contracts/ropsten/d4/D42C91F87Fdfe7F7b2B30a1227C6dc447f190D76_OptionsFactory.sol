pragma solidity ^0.5.10;

import "./interfaces/OracleInterface.sol";
import "./interfaces/UniswapFactoryInterface.sol";
import "./interfaces/UniswapExchangeInterface.sol";
import "./packages/ERC20.sol";
import "./packages/IERC20.sol";
import "./packages/ERC20Detailed.sol";
import "./packages/Ownable.sol";
import "./packages/SafeMath.sol";


/**
 * @title Opyn's Options Contract
 * @author Opyn
 */
contract OptionsContract is Ownable, ERC20 {
    using SafeMath for uint256;

    /* represents floting point numbers, where number = value * 10 ** exponent
    i.e 0.1 = 10 * 10 ** -3 */
    struct Number {
        uint256 value;
        int32 exponent;
    }

    // Keeps track of the weighted collateral and weighted debt for each vault.
    struct Vault {
        uint256 collateral;
        uint256 oTokensIssued;
        uint256 underlying;
        bool owned;
    }

    mapping(address => Vault) internal vaults;

    address payable[] public vaultOwners;

    // 10 is 0.01 i.e. 1% incentive.
    Number public liquidationIncentive = Number(10, -3);

    /* 500 is 0.5. Max amount that a Vault can be liquidated by i.e.
    max collateral that can be taken in one function call */
    Number public liquidationFactor = Number(500, -3);

    /* 16 means 1.6. The minimum ratio of a Vault's collateral to insurance promised.
    The ratio is calculated as below:
    vault.collateral / (Vault.oTokensIssued * strikePrice) */
    Number public minCollateralizationRatio = Number(10, -1);

    // The amount of insurance promised per oToken
    Number public strikePrice;

    // The amount of underlying that 1 oToken protects.
    Number public oTokenExchangeRate;

    /* UNIX time.
    Exercise period starts at `(expiry - windowSize)` and ends at `expiry` */
    uint256 internal windowSize;

    /* The total fees accumulated in the contract any time liquidate or exercise is called */
    uint256 internal totalFee;

    // The time of expiry of the options contract
    uint256 public expiry;

    // The precision of the collateral
    int32 public collateralExp = -18;

    // The precision of the underlying
    int32 public underlyingExp = -18;

    // The collateral asset
    IERC20 public collateral;

    // The asset being protected by the insurance
    IERC20 public underlying;

    // The asset in which insurance is denominated in.
    IERC20 public strike;

    // The Oracle used for the contract
    OracleInterface public oracle;

    // The name of  the contract
    string public name;

    // The symbol of  the contract
    string public symbol;

    // The number of decimals of the contract
    uint8 public decimals;

    // the state of the option contract, if true then all option functionalities are paused other than removing collateral
    bool internal isPaused;

    /**
     * @param _collateral The collateral asset
     * @param _underlying The asset that is being protected
     * @param _oTokenExchangeExp The precision of the `amount of underlying` that 1 oToken protects
     * @param _strikePrice The amount of strike asset that will be paid out per oToken
     * @param _strikeExp The precision of the strike price.
     * @param _strike The asset in which the insurance is calculated
     * @param _expiry The time at which the insurance expires
     * @param _windowSize UNIX time. Exercise window is from `expiry - _windowSize` to `expiry`.
     * @param _oracleAddress The address of the oracle
     */
    constructor(
        address _collateral,
        address _underlying,
        address _strike,
        int32 _oTokenExchangeExp,
        uint256 _strikePrice,
        int32 _strikeExp,
        uint256 _expiry,
        uint256 _windowSize,
        address _oracleAddress
    ) public {
        require(block.timestamp < _expiry, "Can't deploy an expired contract");
        require(
            _windowSize <= _expiry,
            "Exercise window can't be longer than the contract's lifespan"
        );

        require(
            isWithinExponentRange(_strikeExp),
            "strike price exponent not within expected range"
        );
        require(
            isWithinExponentRange(_oTokenExchangeExp),
            "oToken exchange rate exponent not within expected range"
        );

        require(
            address(_underlying) != address(0),
            "OptionsContract: Can't use ETH as underlying."
        );

        collateral = IERC20(_collateral);
        underlying = IERC20(_underlying);
        strike = IERC20(_strike);

        collateralExp = getAssetExp(_collateral);
        underlyingExp = getAssetExp(_underlying);
        require(
            isWithinExponentRange(collateralExp),
            "collateral exponent not within expected range"
        );
        require(
            isWithinExponentRange(underlyingExp),
            "underlying exponent not within expected range"
        );
        require(
            _oTokenExchangeExp >= underlyingExp,
            "Options Contract: The exchange rate has greater precision than the underlying"
        );

        oTokenExchangeRate = Number(1, _oTokenExchangeExp);

        strikePrice = Number(_strikePrice, _strikeExp);

        expiry = _expiry;
        oracle = OracleInterface(_oracleAddress);
        windowSize = _windowSize;
    }

    /*** Events ***/
    event VaultOpened(address payable vaultOwner);
    event ETHCollateralAdded(
        address payable vaultOwner,
        uint256 amount,
        address payer
    );
    event ERC20CollateralAdded(
        address payable vaultOwner,
        uint256 amount,
        address payer
    );
    event IssuedOTokens(
        address issuedTo,
        uint256 oTokensIssued,
        address payable vaultOwner
    );
    event Liquidate(
        uint256 amtCollateralToPay,
        address payable vaultOwner,
        address payable liquidator
    );
    event Exercise(
        uint256 amtUnderlyingToPay,
        uint256 amtCollateralToPay,
        address payable exerciser,
        address payable vaultExercisedFrom
    );
    event RedeemVaultBalance(
        uint256 amtCollateralRedeemed,
        uint256 amtUnderlyingRedeemed,
        address payable vaultOwner
    );
    event BurnOTokens(address payable vaultOwner, uint256 oTokensBurned);
    event RemoveCollateral(uint256 amtRemoved, address payable vaultOwner);
    event UpdateParameters(
        uint256 liquidationIncentive,
        uint256 liquidationFactor,
        uint256 minCollateralizationRatio,
        address owner
    );
    event TransferFee(address payable to, uint256 fees);
    event RemoveUnderlying(
        uint256 amountUnderlying,
        address payable vaultOwner
    );
    event OptionStateUpdated(
        bool oldState,
        bool newState,
        uint256 updateTimestamp
    );

    /**
     * @dev Throws if called Options contract is expired.
     */
    modifier notExpired() {
        require(!hasExpired(), "Options contract expired");
        _;
    }

    /**
     * @notice This function gets the length of vaultOwners array
     */
    function getVaultOwnersLength() external view returns (uint256) {
        return vaultOwners.length;
    }

    /**
     * @notice Can only be called by owner. Used to update the fees, minCollateralizationRatio, etc
     * @param _liquidationIncentive The incentive paid to liquidator. 10 is 0.01 i.e. 1% incentive.
     * @param _liquidationFactor Max amount that a Vault can be liquidated by. 500 is 0.5.
     * @param _minCollateralizationRatio The minimum ratio of a Vault's collateral to insurance promised. 16 means 1.6.
     */
    function updateParameters(
        uint256 _liquidationIncentive,
        uint256 _liquidationFactor,
        uint256 _minCollateralizationRatio
    ) external onlyOwner {
        require(
            _liquidationIncentive <= 200,
            "Can't have >20% liquidation incentive"
        );
        require(
            _liquidationFactor <= 1000,
            "Can't liquidate more than 100% of the vault"
        );
        require(
            _minCollateralizationRatio >= 10,
            "Can't have minCollateralizationRatio < 1"
        );

        liquidationIncentive.value = _liquidationIncentive;
        liquidationFactor.value = _liquidationFactor;
        minCollateralizationRatio.value = _minCollateralizationRatio;

        emit UpdateParameters(
            _liquidationIncentive,
            _liquidationFactor,
            _minCollateralizationRatio,
            owner()
        );
    }

    function harvest(address _token, uint256 _amount) external onlyOwner {
        require(
            (_token != address(underlying)) &&
                (_token != address(collateral)) &&
                (_token != address(strike)),
            "Owner can't harvest this token"
        );

        ERC20(_token).transfer(msg.sender, _amount);
    }

    /**
     * @notice Can only be called by owner. Used to set the name, symbol and decimals of the contract
     * @param _name The name of the contract
     * @param _symbol The symbol of the contract
     */
    function setDetails(string calldata _name, string calldata _symbol)
        external
        onlyOwner
    {
        name = _name;
        symbol = _symbol;
        decimals = uint8(-1 * oTokenExchangeRate.exponent);
    }

    /**
     * @notice Can only be called by owner. Used to take out the protocol fees from the contract.
     * @param _address The address to send the fee to.
     */
    function transferFee(address payable _address) external onlyOwner {
        uint256 fees = totalFee;
        totalFee = 0;
        transferCollateral(_address, fees);

        emit TransferFee(_address, fees);
    }

    /**
     * @notice Can only be called by owner. Used to pause and restart the option contract.
     * @dev can not restart an already running option, and can not pause an already paused option
     * @param _isPaused The option contract state, if true then pause the contract, if false then restart contract
     */
    function setIsPaused(bool _isPaused) external onlyOwner {
        require(_isPaused != isPaused, "Option contract already in that state");

        emit OptionStateUpdated(isPaused, _isPaused, now);

        isPaused = _isPaused;
    }

    /**
     * @notice Get option contract state. If option is paused should return true, else false.
     * @return option contract state
     */
    function isSystemPaused() public view returns (bool) {
        return isPaused;
    }

    /**
     * @notice Checks if a `owner` has already created a Vault
     * @param _owner The address of the supposed owner
     * @return true or false
     */
    function hasVault(address payable _owner) public view returns (bool) {
        return vaults[_owner].owned;
    }

    /**
     * @notice Creates a new empty Vault and sets the owner of the vault to be the msg.sender.
     */
    function openVault() public notExpired returns (bool) {
        require(!isSystemPaused(), "Option contract is paused");
        require(!hasVault(msg.sender), "Vault already created");

        vaults[msg.sender] = Vault(0, 0, 0, true);
        vaultOwners.push(msg.sender);

        emit VaultOpened(msg.sender);
        return true;
    }

    /**
     * @notice If the collateral type is ETH, anyone can call this function any time before
     * expiry to increase the amount of collateral in a Vault. Will fail if ETH is not the
     * collateral asset.
     * Remember that adding ETH collateral even if no oTokens have been created can put the owner at a
     * risk of losing the collateral if an exercise event happens.
     * Ensure that you issue and immediately sell oTokens to allow the owner to earn premiums.
     * (Either call the createAndSell function in the oToken contract or batch the
     * addERC20Collateral, issueOTokens and sell transactions and ensure they happen atomically to protect
     * the end user).
     * @param vaultOwner the index of the Vault to which collateral will be added.
     */
    function addETHCollateral(address payable vaultOwner)
        public
        payable
        notExpired
        returns (uint256)
    {
        require(!isSystemPaused(), "Option contract is paused");
        require(isETH(collateral), "ETH is not the specified collateral type");
        require(hasVault(vaultOwner), "Vault does not exist");

        emit ETHCollateralAdded(vaultOwner, msg.value, msg.sender);
        return _addCollateral(vaultOwner, msg.value);
    }

    /**
     * @notice If the collateral type is any ERC20, anyone can call this function any time before
     * expiry to increase the amount of collateral in a Vault. Can only transfer in the collateral asset.
     * Will fail if ETH is the collateral asset.
     * The user has to allow the contract to handle their ERC20 tokens on his behalf before these
     * functions are called.
     * Remember that adding ERC20 collateral even if no oTokens have been created can put the owner at a
     * risk of losing the collateral. Ensure that you issue and immediately sell the oTokens!
     * (Either call the createAndSell function in the oToken contract or batch the
     * addERC20Collateral, issueOTokens and sell transactions and ensure they happen atomically to protect
     * the end user).
     * @param vaultOwner the index of the Vault to which collateral will be added.
     * @param amt the amount of collateral to be transferred in.
     */
    function addERC20Collateral(address payable vaultOwner, uint256 amt)
        public
        notExpired
        returns (uint256)
    {
        require(!isSystemPaused(), "Option contract is paused");
        require(
            collateral.transferFrom(msg.sender, address(this), amt),
            "OptionsContract: transfer collateral failed."
        );
        require(hasVault(vaultOwner), "Vault does not exist");

        emit ERC20CollateralAdded(vaultOwner, amt, msg.sender);
        return _addCollateral(vaultOwner, amt);
    }

    /**
     * @notice Returns the amount of underlying to be transferred during an exercise call
     */
    function underlyingRequiredToExercise(uint256 oTokensToExercise)
        public
        view
        returns (uint256)
    {
        uint256 underlyingPerOTokenExp = uint256(
            oTokenExchangeRate.exponent - underlyingExp
        );

        // underlyingPerOTokenExp <= 60, no danger of overflowing uint256
        return oTokensToExercise.mul(10**underlyingPerOTokenExp);
    }

    /**
     * @notice Returns true if exercise can be called
     */
    function isExerciseWindow() public view returns (bool) {
        return ((block.timestamp >= expiry.sub(windowSize)) &&
            (block.timestamp < expiry));
    }

    /**
     * @notice Returns true if the oToken contract has expired
     */
    function hasExpired() public view returns (bool) {
        return (block.timestamp >= expiry);
    }

    /**
     * @notice Called by anyone holding the oTokens and underlying during the
     * exercise window i.e. from `expiry - windowSize` time to `expiry` time. The caller
     * transfers in their oTokens and corresponding amount of underlying and gets
     * `strikePrice * oTokens` amount of collateral out. The collateral paid out is taken from
     * the each vault owner starting with the first and iterating until the oTokens to exercise
     * are found.
     * NOTE: This uses a for loop and hence could run out of gas if the array passed in is too big!
     * @param oTokensToExercise the number of oTokens being exercised.
     * @param vaultsToExerciseFrom the array of vaults to exercise from.
     */
    function exercise(
        uint256 oTokensToExercise,
        address payable[] memory vaultsToExerciseFrom
    ) public payable {
        require(!isSystemPaused(), "Option contract is paused");
        require(oTokensToExercise > 0, "Can't exercise 0 oTokens");

        for (uint256 i = 0; i < vaultsToExerciseFrom.length; i++) {
            address payable vaultOwner = vaultsToExerciseFrom[i];
            require(
                hasVault(vaultOwner),
                "Cannot exercise from a vault that doesn't exist"
            );
            Vault storage vault = vaults[vaultOwner];
            if (oTokensToExercise == 0) {
                return;
            } else if (vault.oTokensIssued >= oTokensToExercise) {
                _exercise(oTokensToExercise, vaultOwner);
                return;
            } else {
                oTokensToExercise = oTokensToExercise.sub(vault.oTokensIssued);
                _exercise(vault.oTokensIssued, vaultOwner);
            }
        }
        require(
            oTokensToExercise == 0,
            "Specified vaults have insufficient collateral"
        );
    }

    /**
     * @notice This function allows the vault owner to remove their share of underlying after an exercise
     */
    function removeUnderlying() external {
        require(hasVault(msg.sender), "Vault does not exist");
        Vault storage vault = vaults[msg.sender];

        require(vault.underlying > 0, "No underlying balance");

        uint256 underlyingToTransfer = vault.underlying;
        vault.underlying = 0;

        transferUnderlying(msg.sender, underlyingToTransfer);
        emit RemoveUnderlying(underlyingToTransfer, msg.sender);
    }

    /**
     * @notice This function is called to issue the option tokens. Remember that issuing oTokens even if they
     * haven't been sold can put the owner at a risk of not making premiums on the oTokens. Ensure that you
     * issue and immidiately sell the oTokens! (Either call the createAndSell function in the oToken contract
     * of batch the issueOTokens transaction with a sell transaction and ensure it happens atomically).
     * @dev The owner of a Vault should only be able to have a max of
     * repo.collateral * collateralToStrike / (minCollateralizationRatio * strikePrice) tokens issued.
     * @param oTokensToIssue The number of o tokens to issue
     * @param receiver The address to send the oTokens to
     */
    function issueOTokens(uint256 oTokensToIssue, address receiver)
        public
        notExpired
    {
        require(!isSystemPaused(), "Option contract is paused");
        //check that we're properly collateralized to mint this number, then call _mint(address account, uint256 amount)
        require(hasVault(msg.sender), "Vault does not exist");

        Vault storage vault = vaults[msg.sender];

        // checks that the vault is sufficiently collateralized
        uint256 newOTokensBalance = vault.oTokensIssued.add(oTokensToIssue);
        require(isSafe(vault.collateral, newOTokensBalance), "unsafe to mint");

        // issue the oTokens
        vault.oTokensIssued = newOTokensBalance;
        _mint(receiver, oTokensToIssue);

        emit IssuedOTokens(receiver, oTokensToIssue, msg.sender);
        return;
    }

    /**
     * @notice Returns the vault for a given address
     * @param vaultOwner the owner of the Vault to return
     */
    function getVault(address payable vaultOwner)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            bool
        )
    {
        Vault storage vault = vaults[vaultOwner];
        return (
            vault.collateral,
            vault.oTokensIssued,
            vault.underlying,
            vault.owned
        );
    }

    /**
     * @notice Returns true if the given ERC20 is ETH.
     * @param _ierc20 the ERC20 asset.
     */
    function isETH(IERC20 _ierc20) public pure returns (bool) {
        return _ierc20 == IERC20(0);
    }

    /**
     * @notice allows the owner to burn their oTokens to increase the collateralization ratio of
     * their vault.
     * @param amtToBurn number of oTokens to burn
     * @dev only want to call this function before expiry. After expiry, no benefit to calling it.
     */
    function burnOTokens(uint256 amtToBurn) external notExpired {
        require(!isSystemPaused(), "Option contract is paused");
        require(hasVault(msg.sender), "Vault does not exist");

        Vault storage vault = vaults[msg.sender];

        vault.oTokensIssued = vault.oTokensIssued.sub(amtToBurn);
        _burn(msg.sender, amtToBurn);

        emit BurnOTokens(msg.sender, amtToBurn);
    }

    /**
     * @notice allows the owner to remove excess collateral from the vault before expiry. Removing collateral lowers
     * the collateralization ratio of the vault.
     * @param amtToRemove Amount of collateral to remove in 10^-18.
     */
    function removeCollateral(uint256 amtToRemove) external notExpired {
        require(amtToRemove > 0, "Cannot remove 0 collateral");
        require(hasVault(msg.sender), "Vault does not exist");

        Vault storage vault = vaults[msg.sender];
        require(
            amtToRemove <= getCollateral(msg.sender),
            "Can't remove more collateral than owned"
        );

        // check that vault will remain safe after removing collateral
        uint256 newCollateralBalance = vault.collateral.sub(amtToRemove);

        require(
            isSafe(newCollateralBalance, vault.oTokensIssued),
            "Vault is unsafe"
        );

        // remove the collateral
        vault.collateral = newCollateralBalance;
        transferCollateral(msg.sender, amtToRemove);

        emit RemoveCollateral(amtToRemove, msg.sender);
    }

    /**
     * @notice after expiry, each vault holder can get back their proportional share of collateral
     * from vaults that they own.
     * @dev The owner gets all of their collateral back if no exercise event took their collateral.
     */
    function redeemVaultBalance() external {
        require(hasExpired(), "Can't collect collateral until expiry");
        require(hasVault(msg.sender), "Vault does not exist");

        // pay out owner their share
        Vault storage vault = vaults[msg.sender];

        // To deal with lower precision
        uint256 collateralToTransfer = vault.collateral;
        uint256 underlyingToTransfer = vault.underlying;

        vault.collateral = 0;
        vault.oTokensIssued = 0;
        vault.underlying = 0;

        transferCollateral(msg.sender, collateralToTransfer);
        transferUnderlying(msg.sender, underlyingToTransfer);

        emit RedeemVaultBalance(
            collateralToTransfer,
            underlyingToTransfer,
            msg.sender
        );
    }

    /**
     * This function returns the maximum amount of collateral liquidatable if the given vault is unsafe
     * @param vaultOwner The index of the vault to be liquidated
     */
    function maxOTokensLiquidatable(address payable vaultOwner)
        external
        view
        returns (uint256)
    {
        if (isUnsafe(vaultOwner)) {
            Vault storage vault = vaults[vaultOwner];
            uint256 maxCollateralLiquidatable = vault
                .collateral
                .mul(liquidationFactor.value)
                .div(10**uint256(-liquidationFactor.exponent));

            uint256 one = 10**uint256(-liquidationIncentive.exponent);
            Number memory liqIncentive = Number(
                liquidationIncentive.value.add(one),
                liquidationIncentive.exponent
            );
            return calculateOTokens(maxCollateralLiquidatable, liqIncentive);
        } else {
            return 0;
        }
    }

    /**
     * @notice This function can be called by anyone who notices a vault is undercollateralized.
     * The caller gets a reward for reducing the amount of oTokens in circulation.
     * @dev Liquidator comes with _oTokens. They get _oTokens * strikePrice * (incentive + fee)
     * amount of collateral out. They can liquidate a max of liquidationFactor * vault.collateral out
     * in one function call i.e. partial liquidations.
     * @param vaultOwner The index of the vault to be liquidated
     * @param oTokensToLiquidate The number of oTokens being taken out of circulation
     */
    function liquidate(address payable vaultOwner, uint256 oTokensToLiquidate)
        external
        notExpired
    {
        require(!isSystemPaused(), "Option contract is paused");
        require(hasVault(vaultOwner), "Vault does not exist");

        Vault storage vault = vaults[vaultOwner];

        // cannot liquidate a safe vault.
        require(isUnsafe(vaultOwner), "Vault is safe");

        // Owner can't liquidate themselves
        require(msg.sender != vaultOwner, "Owner can't liquidate themselves");

        uint256 amtCollateral = calculateCollateralToPay(
            oTokensToLiquidate,
            Number(1, 0)
        );
        uint256 amtIncentive = calculateCollateralToPay(
            oTokensToLiquidate,
            liquidationIncentive
        );
        uint256 amtCollateralToPay = amtCollateral.add(amtIncentive);

        // calculate the maximum amount of collateral that can be liquidated
        uint256 maxCollateralLiquidatable = vault.collateral.mul(
            liquidationFactor.value
        );

        if (liquidationFactor.exponent > 0) {
            maxCollateralLiquidatable = maxCollateralLiquidatable.mul(
                10**uint256(liquidationFactor.exponent)
            );
        } else {
            maxCollateralLiquidatable = maxCollateralLiquidatable.div(
                10**uint256(-1 * liquidationFactor.exponent)
            );
        }

        require(
            amtCollateralToPay <= maxCollateralLiquidatable,
            "Can only liquidate liquidation factor at any given time"
        );

        // deduct the collateral and oTokensIssued
        vault.collateral = vault.collateral.sub(amtCollateralToPay);
        vault.oTokensIssued = vault.oTokensIssued.sub(oTokensToLiquidate);

        // transfer the collateral and burn the _oTokens
        _burn(msg.sender, oTokensToLiquidate);
        transferCollateral(msg.sender, amtCollateralToPay);

        emit Liquidate(amtCollateralToPay, vaultOwner, msg.sender);
    }

    /**
     * @notice checks if a vault is unsafe. If so, it can be liquidated
     * @param vaultOwner The number of the vault to check
     * @return true or false
     */
    function isUnsafe(address payable vaultOwner) public view returns (bool) {
        bool stillUnsafe = !isSafe(
            getCollateral(vaultOwner),
            getOTokensIssued(vaultOwner)
        );
        return stillUnsafe;
    }

    /**
     * @notice This function returns if an -30 <= exponent <= 30
     */
    function isWithinExponentRange(int32 val) internal pure returns (bool) {
        return ((val <= 30) && (val >= -30));
    }

    /**
     * @notice This function calculates and returns the amount of collateral in the vault
     */
    function getCollateral(address payable vaultOwner)
        internal
        view
        returns (uint256)
    {
        Vault storage vault = vaults[vaultOwner];
        return vault.collateral;
    }

    /**
     * @notice This function calculates and returns the amount of puts issued by the Vault
     */
    function getOTokensIssued(address payable vaultOwner)
        internal
        view
        returns (uint256)
    {
        Vault storage vault = vaults[vaultOwner];
        return vault.oTokensIssued;
    }

    /**
     * @notice Called by anyone holding the oTokens and underlying during the
     * exercise window i.e. from `expiry - windowSize` time to `expiry` time. The caller
     * transfers in their oTokens and corresponding amount of underlying and gets
     * `strikePrice * oTokens` amount of collateral out. The collateral paid out is taken from
     * the specified vault holder. At the end of the expiry window, the vault holder can redeem their balance
     * of collateral. The vault owner can withdraw their underlying at any time.
     * The user has to allow the contract to handle their oTokens and underlying on his behalf before these functions are called.
     * @param oTokensToExercise the number of oTokens being exercised.
     * @param vaultToExerciseFrom the address of the vaultOwner to take collateral from.
     * @dev oTokenExchangeRate is the number of underlying tokens that 1 oToken protects.
     */
    function _exercise(
        uint256 oTokensToExercise,
        address payable vaultToExerciseFrom
    ) internal {
        // 1. before exercise window: revert
        require(
            isExerciseWindow(),
            "Can't exercise outside of the exercise window"
        );

        require(hasVault(vaultToExerciseFrom), "Vault does not exist");

        Vault storage vault = vaults[vaultToExerciseFrom];
        require(oTokensToExercise > 0, "Can't exercise 0 oTokens");
        // Check correct amount of oTokens passed in)
        require(
            oTokensToExercise <= vault.oTokensIssued,
            "Can't exercise more oTokens than the owner has"
        );

        // 1. Check sufficient underlying
        // 1.1 update underlying balances
        uint256 amtUnderlyingToPay = underlyingRequiredToExercise(
            oTokensToExercise
        );
        vault.underlying = vault.underlying.add(amtUnderlyingToPay);

        // 2. Calculate Collateral to pay
        // 2.1 Payout enough collateral to get (strikePrice * oTokens) amount of collateral
        uint256 amtCollateralToPay = calculateCollateralToPay(
            oTokensToExercise,
            Number(1, 0)
        );

        require(
            amtCollateralToPay <= vault.collateral,
            "Vault underwater, can't exercise"
        );

        // 3. Update collateral + oToken balances
        vault.collateral = vault.collateral.sub(amtCollateralToPay);
        vault.oTokensIssued = vault.oTokensIssued.sub(oTokensToExercise);

        // 4. Transfer in underlying, burn oTokens + pay out collateral
        // 4.1 Transfer in underlying
        require(
            underlying.transferFrom(
                msg.sender,
                address(this),
                amtUnderlyingToPay
            ),
            "OptionsContract: Could not transfer in tokens"
        );

        // 4.2 burn oTokens
        _burn(msg.sender, oTokensToExercise);

        // 4.3 Pay out collateral
        transferCollateral(msg.sender, amtCollateralToPay);

        emit Exercise(
            amtUnderlyingToPay,
            amtCollateralToPay,
            msg.sender,
            vaultToExerciseFrom
        );
    }

    /**
     * @notice adds `_amt` collateral to `vaultOwner` and returns the new balance of the vault
     * @param vaultOwner the index of the vault
     * @param amt the amount of collateral to add
     */
    function _addCollateral(address payable vaultOwner, uint256 amt)
        internal
        notExpired
        returns (uint256)
    {
        Vault storage vault = vaults[vaultOwner];
        vault.collateral = vault.collateral.add(amt);

        return vault.collateral;
    }

    /**
     * @notice checks if a hypothetical vault is safe with the given collateralAmt and oTokensIssued
     * @param collateralAmt The amount of collateral the hypothetical vault has
     * @param oTokensIssued The amount of oTokens generated by the hypothetical vault
     * @return true or false
     */
    function isSafe(uint256 collateralAmt, uint256 oTokensIssued)
        internal
        view
        returns (bool)
    {
        // get price from Oracle
        uint256 collateralToEthPrice = 1;
        uint256 strikeToEthPrice = 1;

        if (collateral != strike) {
            collateralToEthPrice = getPrice(address(collateral));
            strikeToEthPrice = getPrice(address(strike));
        }

        // check `oTokensIssued * minCollateralizationRatio * strikePrice <= collAmt * collateralToStrikePrice`
        uint256 leftSideVal = oTokensIssued
            .mul(minCollateralizationRatio.value)
            .mul(strikePrice.value);
        int32 leftSideExp = minCollateralizationRatio.exponent +
            strikePrice.exponent;

        uint256 rightSideVal = (collateralAmt.mul(collateralToEthPrice)).div(
            strikeToEthPrice
        );
        int32 rightSideExp = collateralExp;

        uint256 exp = 0;
        bool stillSafe = false;

        if (rightSideExp < leftSideExp) {
            exp = uint256(leftSideExp - rightSideExp);
            stillSafe = leftSideVal.mul(10**exp) <= rightSideVal;
        } else {
            exp = uint256(rightSideExp - leftSideExp);
            stillSafe = leftSideVal <= rightSideVal.mul(10**exp);
        }

        return stillSafe;
    }

    /**
     * This function returns the maximum amount of oTokens that can safely be issued against the specified amount of collateral.
     * @param collateralAmt The amount of collateral against which oTokens will be issued.
     */
    function maxOTokensIssuable(uint256 collateralAmt)
        external
        view
        returns (uint256)
    {
        return calculateOTokens(collateralAmt, minCollateralizationRatio);
    }

    /**
     * @notice This function is used to calculate the amount of tokens that can be issued.
     * @dev The amount of oTokens is determined by:
     * oTokensIssued  <= collateralAmt * collateralToStrikePrice / (proportion * strikePrice)
     * @param collateralAmt The amount of collateral
     * @param proportion The proportion of the collateral to pay out. If 100% of collateral
     * should be paid out, pass in Number(1, 0). The proportion might be less than 100% if
     * you are calculating fees.
     */
    function calculateOTokens(uint256 collateralAmt, Number memory proportion)
        internal
        view
        returns (uint256)
    {
        // get price from Oracle
        uint256 collateralToEthPrice = 1;
        uint256 strikeToEthPrice = 1;

        if (collateral != strike) {
            collateralToEthPrice = getPrice(address(collateral));
            strikeToEthPrice = getPrice(address(strike));
        }

        // oTokensIssued  <= collAmt * collateralToStrikePrice / (proportion * strikePrice)
        uint256 denomVal = proportion.value.mul(strikePrice.value);
        int32 denomExp = proportion.exponent + strikePrice.exponent;

        uint256 numeratorVal = (collateralAmt.mul(collateralToEthPrice)).div(
            strikeToEthPrice
        );
        int32 numeratorExp = collateralExp;

        uint256 exp = 0;
        uint256 numOptions = 0;

        if (numeratorExp < denomExp) {
            exp = uint256(denomExp - numeratorExp);
            numOptions = numeratorVal.div(denomVal.mul(10**exp));
        } else {
            exp = uint256(numeratorExp - denomExp);
            numOptions = numeratorVal.mul(10**exp).div(denomVal);
        }

        return numOptions;
    }

    /**
     * @notice This function calculates the amount of collateral to be paid out.
     * @dev The amount of collateral to paid out is determined by:
     * (proportion * strikePrice * strikeToCollateralPrice * oTokens) amount of collateral.
     * @param _oTokens The number of oTokens.
     * @param proportion The proportion of the collateral to pay out. If 100% of collateral
     * should be paid out, pass in Number(1, 0). The proportion might be less than 100% if
     * you are calculating fees.
     */
    function calculateCollateralToPay(
        uint256 _oTokens,
        Number memory proportion
    ) internal view returns (uint256) {
        // Get price from oracle
        uint256 collateralToEthPrice = 1;
        uint256 strikeToEthPrice = 1;

        if (collateral != strike) {
            collateralToEthPrice = getPrice(address(collateral));
            strikeToEthPrice = getPrice(address(strike));
        }

        // calculate how much should be paid out
        uint256 amtCollateralToPayInEthNum = _oTokens
            .mul(strikePrice.value)
            .mul(proportion.value)
            .mul(strikeToEthPrice);
        int32 amtCollateralToPayExp = strikePrice.exponent +
            proportion.exponent -
            collateralExp;
        uint256 amtCollateralToPay = 0;
        uint256 exp;
        if (amtCollateralToPayExp > 0) {
            exp = uint256(amtCollateralToPayExp);
            amtCollateralToPay = amtCollateralToPayInEthNum.mul(10**exp).div(
                collateralToEthPrice
            );
        } else {
            exp = uint256(-1 * amtCollateralToPayExp);
            amtCollateralToPay = amtCollateralToPayInEthNum.div(10**exp).div(
                collateralToEthPrice
            );
        }
        require(exp <= 77, "Options Contract: Exponentiation overflowed");

        return amtCollateralToPay;
    }

    /**
     * @notice This function transfers `amt` collateral to `_addr`
     * @param _addr The address to send the collateral to
     * @param _amt The amount of the collateral to pay out.
     */
    function transferCollateral(address payable _addr, uint256 _amt) internal {
        if (isETH(collateral)) {
            _addr.transfer(_amt);
        } else {
            require(
                collateral.transfer(_addr, _amt),
                "OptionsContract: transfer collateral failed."
            );
        }
    }

    /**
     * @notice This function transfers `amt` underlying to `_addr`
     * @param _addr The address to send the underlying to
     * @param _amt The amount of the underlying to pay out.
     */
    function transferUnderlying(address payable _addr, uint256 _amt) internal {
        require(
            underlying.transfer(_addr, _amt),
            "OptionsContract: transfer underlying failed"
        );
    }

    /**
     * @dev internal function to parse token decimals for constructor
     * @param _asset the asset address
     */
    function getAssetExp(address _asset) internal view returns (int32) {
        if (_asset == address(0)) return -18;
        return -1 * int32(ERC20Detailed(_asset).decimals());
    }

    /**
     * @notice This function gets the price ETH (wei) to asset price.
     * @param asset The address of the asset to get the price of
     */
    function getPrice(address asset) internal view returns (uint256) {
        return oracle.getPrice(asset);
    }
}

pragma solidity 0.5.10;

import "./interfaces/CompoundOracleInterface.sol";
import "./interfaces/UniswapFactoryInterface.sol";
import "./interfaces/UniswapExchangeInterface.sol";
import "./packages/IERC20.sol";


contract OptionsExchange {
    using SafeMath for uint256;

    uint256 internal constant LARGE_BLOCK_SIZE = 1651753129000;
    uint256 internal constant LARGE_APPROVAL_NUMBER = 10**30;

    UniswapFactoryInterface public uniswapFactory;

    constructor(address _uniswapFactory) public {
        uniswapFactory = UniswapFactoryInterface(_uniswapFactory);
    }

    /*** Events ***/
    event SellOTokens(
        address seller,
        address payable receiver,
        address oTokenAddress,
        address payoutTokenAddress,
        uint256 oTokensToSell,
        uint256 payoutTokensReceived
    );
    event BuyOTokens(
        address buyer,
        address payable receiver,
        address oTokenAddress,
        address paymentTokenAddress,
        uint256 oTokensToBuy,
        uint256 premiumPaid
    );

    /**
     * @notice This function sells oTokens on Uniswap and sends back payoutTokens to the receiver
     * @param receiver The address to send the payout tokens back to
     * @param oTokenAddress The address of the oToken to sell
     * @param payoutTokenAddress The address of the token to receive the premiums in
     * @param oTokensToSell The number of oTokens to sell
     */
    function sellOTokens(
        address payable receiver,
        address oTokenAddress,
        address payoutTokenAddress,
        uint256 oTokensToSell
    ) external {
        // @note: first need to bootstrap the uniswap exchange to get the address.
        IERC20 oToken = IERC20(oTokenAddress);
        IERC20 payoutToken = IERC20(payoutTokenAddress);
        require(
            oToken.transferFrom(msg.sender, address(this), oTokensToSell),
            "OptionsExchange: pull otoken from user failed."
        );
        uint256 payoutTokensReceived = uniswapSellOToken(
            oToken,
            payoutToken,
            oTokensToSell,
            receiver
        );

        emit SellOTokens(
            msg.sender,
            receiver,
            oTokenAddress,
            payoutTokenAddress,
            oTokensToSell,
            payoutTokensReceived
        );
    }

    /**
     * @notice This function buys oTokens on Uniswap and using paymentTokens from the receiver
     * @param receiver The address to send the oTokens back to
     * @param oTokenAddress The address of the oToken to buy
     * @param paymentTokenAddress The address of the token to pay the premiums in
     * @param oTokensToBuy The number of oTokens to buy
     */
    function buyOTokens(
        address payable receiver,
        address oTokenAddress,
        address paymentTokenAddress,
        uint256 oTokensToBuy
    ) external payable {
        IERC20 oToken = IERC20(oTokenAddress);
        IERC20 paymentToken = IERC20(paymentTokenAddress);
        uniswapBuyOToken(paymentToken, oToken, oTokensToBuy, receiver);
    }

    /**
     * @notice This function calculates the amount of premiums that the seller
     * will receive if they sold oTokens on Uniswap
     * @param oTokenAddress The address of the oToken to sell
     * @param payoutTokenAddress The address of the token to receive the premiums in
     * @param oTokensToSell The number of oTokens to sell
     */
    function premiumReceived(
        address oTokenAddress,
        address payoutTokenAddress,
        uint256 oTokensToSell
    ) external view returns (uint256) {
        // get the amount of ETH that will be paid out if oTokensToSell is sold.
        UniswapExchangeInterface oTokenExchange = getExchange(oTokenAddress);
        uint256 ethReceived = oTokenExchange.getTokenToEthInputPrice(
            oTokensToSell
        );

        if (!isETH(IERC20(payoutTokenAddress))) {
            // get the amount of payout tokens that will be received if the ethRecieved is sold.
            UniswapExchangeInterface payoutExchange = getExchange(
                payoutTokenAddress
            );
            return payoutExchange.getEthToTokenInputPrice(ethReceived);
        }
        return ethReceived;
    }

    /**
     * @notice This function calculates the premiums to be paid if a buyer wants to
     * buy oTokens on Uniswap
     * @param oTokenAddress The address of the oToken to buy
     * @param paymentTokenAddress The address of the token to pay the premiums in
     * @param oTokensToBuy The number of oTokens to buy
     */
    function premiumToPay(
        address oTokenAddress,
        address paymentTokenAddress,
        uint256 oTokensToBuy
    ) public view returns (uint256) {
        // get the amount of ETH that needs to be paid for oTokensToBuy.
        UniswapExchangeInterface oTokenExchange = getExchange(oTokenAddress);
        uint256 ethToPay = oTokenExchange.getEthToTokenOutputPrice(
            oTokensToBuy
        );

        if (!isETH(IERC20(paymentTokenAddress))) {
            // get the amount of paymentTokens that needs to be paid to get the desired ethToPay.
            UniswapExchangeInterface paymentTokenExchange = getExchange(
                paymentTokenAddress
            );
            return paymentTokenExchange.getTokenToEthOutputPrice(ethToPay);
        }

        return ethToPay;
    }

    function uniswapSellOToken(
        IERC20 oToken,
        IERC20 payoutToken,
        uint256 _amt,
        address payable _transferTo
    ) internal returns (uint256) {
        require(!isETH(oToken), "Can only sell oTokens");
        UniswapExchangeInterface exchange = getExchange(address(oToken));

        require(
            oToken.approve(address(exchange), _amt),
            "OptionsExchange: approve failed"
        );

        if (isETH(payoutToken)) {
            //Token to ETH
            return
                exchange.tokenToEthTransferInput(
                    _amt,
                    1,
                    LARGE_BLOCK_SIZE,
                    _transferTo
                );
        } else {
            //Token to Token
            return
                exchange.tokenToTokenTransferInput(
                    _amt,
                    1,
                    1,
                    LARGE_BLOCK_SIZE,
                    _transferTo,
                    address(payoutToken)
                );
        }
    }

    function uniswapBuyOToken(
        IERC20 paymentToken,
        IERC20 oToken,
        uint256 _amt,
        address payable _transferTo
    ) internal returns (uint256) {
        require(!isETH(oToken), "Can only buy oTokens");

        if (!isETH(paymentToken)) {
            UniswapExchangeInterface exchange = getExchange(
                address(paymentToken)
            );

            uint256 paymentTokensToTransfer = premiumToPay(
                address(oToken),
                address(paymentToken),
                _amt
            );

            require(
                paymentToken.transferFrom(
                    msg.sender,
                    address(this),
                    paymentTokensToTransfer
                ),
                "OptionsExchange: Pull token from sender failed"
            );

            // Token to Token
            require(
                paymentToken.approve(address(exchange), LARGE_APPROVAL_NUMBER),
                "OptionsExchange: Approve failed"
            );

            emit BuyOTokens(
                msg.sender,
                _transferTo,
                address(oToken),
                address(paymentToken),
                _amt,
                paymentTokensToTransfer
            );

            return
                exchange.tokenToTokenTransferInput(
                    paymentTokensToTransfer,
                    1,
                    1,
                    LARGE_BLOCK_SIZE,
                    _transferTo,
                    address(oToken)
                );
        } else {
            // ETH to Token
            UniswapExchangeInterface exchange = UniswapExchangeInterface(
                uniswapFactory.getExchange(address(oToken))
            );

            uint256 ethToTransfer;
            uint256 amount = _amt;
            if (_amt > 0) {
                ethToTransfer = exchange.getEthToTokenOutputPrice(_amt);
                require(
                    msg.value >= ethToTransfer,
                    "Options Exchange: Insufficient ETH"
                );
                // send excess value back to user
                msg.sender.transfer(msg.value.sub(ethToTransfer));
            } else if (msg.value > 0) {
                ethToTransfer = msg.value;
                amount = exchange.getTokenToEthOutputPrice(ethToTransfer);
            }

            emit BuyOTokens(
                msg.sender,
                _transferTo,
                address(oToken),
                address(paymentToken),
                amount,
                ethToTransfer
            );

            return
                exchange.ethToTokenTransferOutput.value(ethToTransfer)(
                    amount,
                    LARGE_BLOCK_SIZE,
                    _transferTo
                );
        }
    }

    function getExchange(address _token)
        internal
        view
        returns (UniswapExchangeInterface)
    {
        UniswapExchangeInterface exchange = UniswapExchangeInterface(
            uniswapFactory.getExchange(_token)
        );

        if (address(exchange) == address(0)) {
            revert("No payout exchange");
        }

        return exchange;
    }

    function isETH(IERC20 _ierc20) internal pure returns (bool) {
        return _ierc20 == IERC20(0);
    }

    function() external payable {
        // to get ether from uniswap exchanges
    }
}

pragma solidity 0.5.10;

import "./oToken.sol";
import "./lib/StringComparator.sol";
import "./packages/Ownable.sol";
import "./packages/IERC20.sol";


contract OptionsFactory is Ownable {
    using StringComparator for string;

    mapping(address => bool) public whitelisted;
    address[] public optionsContracts;

    // The contract which interfaces with the exchange
    OptionsExchange public optionsExchange;
    address public oracleAddress;

    event OptionsContractCreated(address addr);
    event AssetWhitelisted(address indexed asset);

    /**
     * @param _optionsExchangeAddr: The contract which interfaces with the exchange
     * @param _oracleAddress Address of the oracle
     */
    constructor(OptionsExchange _optionsExchangeAddr, address _oracleAddress)
        public
    {
        optionsExchange = OptionsExchange(_optionsExchangeAddr);
        oracleAddress = _oracleAddress;
    }

    /**
     * @notice creates a new Option Contract
     * @param _collateral The collateral asset. Eg. "ETH"
     * @param _underlying The underlying asset. Eg. "DAI"
     * @param _oTokenExchangeExp Units of underlying that 1 oToken protects
     * @param _strikePrice The amount of strike asset that will be paid out
     * @param _strikeExp The precision of the strike Price
     * @param _strike The asset in which the insurance is calculated
     * @param _expiry The time at which the insurance expires
     * @param _windowSize UNIX time. Exercise window is from `expiry - _windowSize` to `expiry`.
     * @dev this condition must hold for the oToken to be safe: abs(oTokenExchangeExp - underlyingExp) < 19
     * @dev this condition must hold for the oToken to be safe: max(abs(strikeExp + liqIncentiveExp - collateralExp), abs(strikeExp - collateralExp)) <= 9
     */
    function createOptionsContract(
        address _collateral,
        address _underlying,
        address _strike,
        int32 _oTokenExchangeExp,
        uint256 _strikePrice,
        int32 _strikeExp,
        uint256 _expiry,
        uint256 _windowSize,
        string calldata _name,
        string calldata _symbol
    ) external returns (address) {
        require(whitelisted[_collateral], "Collateral not whitelisted.");
        require(whitelisted[_underlying], "Underlying not whitelisted.");
        require(whitelisted[_strike], "Strike not whitelisted.");

        require(_expiry > block.timestamp, "Cannot create an expired option");
        require(_windowSize <= _expiry, "Invalid _windowSize");

        oToken otoken = new oToken(
            _collateral,
            _underlying,
            _strike,
            _oTokenExchangeExp,
            _strikePrice,
            _strikeExp,
            _expiry,
            _windowSize,
            optionsExchange,
            oracleAddress
        );

        otoken.setDetails(_name, _symbol);

        optionsContracts.push(address(otoken));
        emit OptionsContractCreated(address(otoken));

        // Set the owner for the options contract to the person who created the options contract
        otoken.transferOwnership(msg.sender);
        return address(otoken);
    }

    /**
     * @notice The number of Option Contracts that the Factory contract has stored
     */
    function getNumberOfOptionsContracts() external view returns (uint256) {
        return optionsContracts.length;
    }

    /**
     * @notice The owner of the Factory Contract can update an asset's address, by adding it, changing the address or removing the asset
     * @param _asset The address for the asset
     */
    function whitelistAsset(address _asset) external onlyOwner {
        whitelisted[_asset] = true;
        emit AssetWhitelisted(_asset);
    }
}

pragma solidity ^0.5.10;
// AT MAINNET ADDRESS: 0x9B8Eb8b3d6e2e0Db36F41455185FEF7049a35CaE
import "../packages/ERC20.sol";


interface CompoundOracleInterface {
    function getUnderlyingPrice(address cToken) external view returns (uint256);

    function price(string calldata symbol) external view returns (uint256);
}

pragma solidity ^0.5.10;


interface OracleInterface {
    function getPrice(address asset) external view returns (uint256);

    function getBTCPrice() external view returns (uint256);

    function getETHPrice() external view returns (uint256);
}

pragma solidity 0.5.10;


/* solhint-disable */

// Solidity Interface
contract UniswapExchangeInterface {
    // Address of ERC20 token sold on this exchange
    function tokenAddress() external view returns (address token);

    // Address of Uniswap Factory
    function factoryAddress() external view returns (address factory);

    // Provide Liquidity
    function addLiquidity(
        uint256 min_liquidity,
        uint256 max_tokens,
        uint256 deadline
    ) external payable returns (uint256);

    function removeLiquidity(
        uint256 amount,
        uint256 min_eth,
        uint256 min_tokens,
        uint256 deadline
    ) external returns (uint256, uint256);

    // Get Prices
    function getEthToTokenInputPrice(uint256 eth_sold)
        external
        view
        returns (uint256 tokens_bought);

    function getEthToTokenOutputPrice(uint256 tokens_bought)
        external
        view
        returns (uint256 eth_sold);

    function getTokenToEthInputPrice(uint256 tokens_sold)
        external
        view
        returns (uint256 eth_bought);

    function getTokenToEthOutputPrice(uint256 eth_bought)
        external
        view
        returns (uint256 tokens_sold);

    // Trade ETH to ERC20
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline)
        external
        payable
        returns (uint256 tokens_bought);

    function ethToTokenTransferInput(
        uint256 min_tokens,
        uint256 deadline,
        address recipient
    ) external payable returns (uint256 tokens_bought);

    function ethToTokenSwapOutput(uint256 tokens_bought, uint256 deadline)
        external
        payable
        returns (uint256 eth_sold);

    function ethToTokenTransferOutput(
        uint256 tokens_bought,
        uint256 deadline,
        address recipient
    ) external payable returns (uint256 eth_sold);

    // Trade ERC20 to ETH
    function tokenToEthSwapInput(
        uint256 tokens_sold,
        uint256 min_eth,
        uint256 deadline
    ) external returns (uint256 eth_bought);

    function tokenToEthTransferInput(
        uint256 tokens_sold,
        uint256 min_eth,
        uint256 deadline,
        address recipient
    ) external returns (uint256 eth_bought);

    function tokenToEthSwapOutput(
        uint256 eth_bought,
        uint256 max_tokens,
        uint256 deadline
    ) external returns (uint256 tokens_sold);

    function tokenToEthTransferOutput(
        uint256 eth_bought,
        uint256 max_tokens,
        uint256 deadline,
        address recipient
    ) external returns (uint256 tokens_sold);

    // Trade ERC20 to ERC20
    function tokenToTokenSwapInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        uint256 deadline,
        address token_addr
    ) external returns (uint256 tokens_bought);

    function tokenToTokenTransferInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        uint256 deadline,
        address recipient,
        address token_addr
    ) external returns (uint256 tokens_bought);

    function tokenToTokenSwapOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_eth_sold,
        uint256 deadline,
        address token_addr
    ) external returns (uint256 tokens_sold);

    function tokenToTokenTransferOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_eth_sold,
        uint256 deadline,
        address recipient,
        address token_addr
    ) external returns (uint256 tokens_sold);

    // Trade ERC20 to Custom Pool
    function tokenToExchangeSwapInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        uint256 deadline,
        address exchange_addr
    ) external returns (uint256 tokens_bought);

    function tokenToExchangeTransferInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        uint256 deadline,
        address recipient,
        address exchange_addr
    ) external returns (uint256 tokens_bought);

    function tokenToExchangeSwapOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_eth_sold,
        uint256 deadline,
        address exchange_addr
    ) external returns (uint256 tokens_sold);

    function tokenToExchangeTransferOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_eth_sold,
        uint256 deadline,
        address recipient,
        address exchange_addr
    ) external returns (uint256 tokens_sold);

    // ERC20 comaptibility for liquidity tokens
    bytes32 public name;
    bytes32 public symbol;
    uint256 public decimals;

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 value
    ) external returns (bool);

    function approve(address _spender, uint256 _value) external returns (bool);

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    // Never use
    function setup(address token_addr) external;
}

pragma solidity 0.5.10;


// Solidity Interface
contract UniswapFactoryInterface {
    // Public Variables
    address public exchangeTemplate;
    uint256 public tokenCount;

    // // Create Exchange
    function createExchange(address token) external returns (address exchange);

    // Get Exchange and Token Info
    function getExchange(address token)
        external
        view
        returns (address exchange);

    function getToken(address exchange) external view returns (address token);

    function getTokenWithId(uint256 tokenId)
        external
        view
        returns (address token);

    // Never use
    function initializeFactory(address template) external;
    // function createExchange(address token) external returns (address exchange) {
    //     return 0x06D014475F84Bb45b9cdeD1Cf3A1b8FE3FbAf128;
    // }
    // // Get Exchange and Token Info
    // function getExchange(address token) external view returns (address exchange){
    //     return 0x06D014475F84Bb45b9cdeD1Cf3A1b8FE3FbAf128;
    // }
    // function getToken(address exchange) external view returns (address token) {
    //     return 0x06D014475F84Bb45b9cdeD1Cf3A1b8FE3FbAf128;
    // }
    // function getTokenWithId(uint256 tokenId) external view returns (address token) {
    //     return 0x06D014475F84Bb45b9cdeD1Cf3A1b8FE3FbAf128;
    // }
}

pragma solidity 0.5.10;

library StringComparator {
    function compareStrings (string memory a, string memory b) public pure
       returns (bool) {
        return keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b)));
    }
}

pragma solidity 0.5.10;

import "./OptionsContract.sol";
import "./OptionsExchange.sol";


/**
 * @title Opyn's Options Contract
 * @author Opyn
 */

contract oToken is OptionsContract {
    OptionsExchange public optionsExchange;

    /**
     * @param _collateral The collateral asset
     * @param _underlying The asset that is being protected
     * @param _oTokenExchangeExp The precision of the `amount of underlying` that 1 oToken protects
     * @param _strikePrice The amount of strike asset that will be paid out
     * @param _strikeExp The precision of the strike asset (-18 if ETH)
     * @param _strike The asset in which the insurance is calculated
     * @param _expiry The time at which the insurance expires
     * @param _optionsExchange The contract which interfaces with the exchange + oracle
     * @param _oracleAddress The address of the oracle
     * @param _windowSize UNIX time. Exercise window is from `expiry - _windowSize` to `expiry`.
     */
    constructor(
        address _collateral,
        address _underlying,
        address _strike,
        int32 _oTokenExchangeExp,
        uint256 _strikePrice,
        int32 _strikeExp,
        uint256 _expiry,
        uint256 _windowSize,
        OptionsExchange _optionsExchange,
        address _oracleAddress
    )
        public
        OptionsContract(
            _collateral,
            _underlying,
            _strike,
            _oTokenExchangeExp,
            _strikePrice,
            _strikeExp,
            _expiry,
            _windowSize,
            _oracleAddress
        )
    {
        optionsExchange = _optionsExchange;
    }

    /**
     * @notice opens a Vault, adds ETH collateral, and mints new oTokens in one step
     * Remember that creating oTokens can put the owner at a risk of losing the collateral
     * if an exercise event happens.
     * The sell function provides the owner a chance to earn premiums.
     * Ensure that you create and immediately sell oTokens atmoically.
     * @param amtToCreate number of oTokens to create
     * @param receiver address to send the Options to
     */
    function createETHCollateralOption(uint256 amtToCreate, address receiver)
        external
        payable
    {
        openVault();
        addETHCollateralOption(amtToCreate, receiver);
    }

    /**
     * @notice adds ETH collateral, and mints new oTokens in one step to an existing Vault
     * Remember that creating oTokens can put the owner at a risk of losing the collateral
     * if an exercise event happens.
     * The sell function provides the owner a chance to earn premiums.
     * Ensure that you create and immediately sell oTokens atmoically.
     * @param amtToCreate number of oTokens to create
     * @param receiver address to send the Options to
     */
    function addETHCollateralOption(uint256 amtToCreate, address receiver)
        public
        payable
    {
        addETHCollateral(msg.sender);
        issueOTokens(amtToCreate, receiver);
    }

    /**
     * @notice opens a Vault, adds ETH collateral, mints new oTokens and sell in one step
     * @param amtToCreate number of oTokens to create
     * @param receiver address to receive the premiums
     */
    function createAndSellETHCollateralOption(
        uint256 amtToCreate,
        address payable receiver
    ) external payable {
        openVault();
        addETHCollateralOption(amtToCreate, address(this));
        this.approve(address(optionsExchange), amtToCreate);
        optionsExchange.sellOTokens(
            receiver,
            address(this),
            address(0),
            amtToCreate
        );
    }

    /**
     * @notice adds ETH collateral to an existing Vault, and mints new oTokens and sells the oTokens in one step
     * @param amtToCreate number of oTokens to create
     * @param receiver address to send the Options to
     */
    function addAndSellETHCollateralOption(
        uint256 amtToCreate,
        address payable receiver
    ) external payable {
        addETHCollateral(msg.sender);
        issueOTokens(amtToCreate, address(this));
        this.approve(address(optionsExchange), amtToCreate);
        optionsExchange.sellOTokens(
            receiver,
            address(this),
            address(0),
            amtToCreate
        );
    }

    /**
     * @notice opens a Vault, adds ERC20 collateral, and mints new oTokens in one step
     * Remember that creating oTokens can put the owner at a risk of losing the collateral
     * if an exercise event happens.
     * The sell function provides the owner a chance to earn premiums.
     * Ensure that you create and immediately sell oTokens atmoically.
     * @param amtToCreate number of oTokens to create
     * @param amtCollateral amount of collateral added
     * @param receiver address to send the Options to
     */
    function createERC20CollateralOption(
        uint256 amtToCreate,
        uint256 amtCollateral,
        address receiver
    ) external {
        openVault();
        addERC20CollateralOption(amtToCreate, amtCollateral, receiver);
    }

    /**
     * @notice adds ERC20 collateral, and mints new oTokens in one step
     * Remember that creating oTokens can put the owner at a risk of losing the collateral
     * if an exercise event happens.
     * The sell function provides the owner a chance to earn premiums.
     * Ensure that you create and immediately sell oTokens atmoically.
     * @param amtToCreate number of oTokens to create
     * @param amtCollateral amount of collateral added
     * @param receiver address to send the Options to
     */
    function addERC20CollateralOption(
        uint256 amtToCreate,
        uint256 amtCollateral,
        address receiver
    ) public {
        addERC20Collateral(msg.sender, amtCollateral);
        issueOTokens(amtToCreate, receiver);
    }

    /**
     * @notice opens a Vault, adds ERC20 collateral, mints new oTokens and sells the oTokens in one step
     * @param amtToCreate number of oTokens to create
     * @param amtCollateral amount of collateral added
     * @param receiver address to send the Options to
     */
    function createAndSellERC20CollateralOption(
        uint256 amtToCreate,
        uint256 amtCollateral,
        address payable receiver
    ) external {
        openVault();
        addERC20CollateralOption(amtToCreate, amtCollateral, address(this));
        this.approve(address(optionsExchange), amtToCreate);
        optionsExchange.sellOTokens(
            receiver,
            address(this),
            address(0),
            amtToCreate
        );
    }

    /**
     * @notice adds ERC20 collateral, mints new oTokens and sells the oTokens in one step
     * @param amtToCreate number of oTokens to create
     * @param amtCollateral amount of collateral added
     * @param receiver address to send the Options to
     */
    function addAndSellERC20CollateralOption(
        uint256 amtToCreate,
        uint256 amtCollateral,
        address payable receiver
    ) external {
        addERC20Collateral(msg.sender, amtCollateral);
        issueOTokens(amtToCreate, address(this));
        this.approve(address(optionsExchange), amtToCreate);
        optionsExchange.sellOTokens(
            receiver,
            address(this),
            address(0),
            amtToCreate
        );
    }
}

pragma solidity ^0.5.0;


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(
                amount,
                "ERC20: burn amount exceeds allowance"
            )
        );
    }
}

pragma solidity ^0.5.0;

import "./IERC20.sol";


/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

pragma solidity ^0.5.0;


/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

pragma solidity ^0.5.0;

import "./Context.sol";


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "petersburg",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}