// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./utility/Whitelist.sol";
import "./utility/LibMath.sol";
import "./utility/SafeERC20.sol";
import "./interfaces/IExpandedIERC20.sol";
import "./interfaces/IPriceResolver.sol";
import "./interfaces/ITokenManager.sol";
import "./interfaces/IToken.sol";
import "./TokenFactory.sol";

contract TokenManager is Lockable, Whitelist, ITokenManager {
    using LibMathSigned for int256;
    using LibMathUnsigned for uint256;
    using SafeERC20 for IToken;
    using SafeERC20 for IExpandedIERC20;

    enum ContractState {
        INITIAL,
        NORMAL,
        EMERGENCY,
        EXPIRED
    }

    struct PositionData {
        // Total tokens have been issued
        uint256 tokensOutstanding;
        // Raw collateral value of base token
        uint256 rawBaseCollateral;
        // Raw collateral value of support token (stablecoin)
        uint256 rawSupportCollateral;
    }

    struct Minters {
        uint256[] array;
        mapping(uint256 => address) list;
        mapping(address => bool) active;
    }

    struct RawCollateral {
        uint256 baseToken;
        uint256 supportToken;
    }

    // Name of this contract (SYNTHETIC_NAME + "Token Manager")
    string public name;
    // Contract state
    ContractState public state;
    // Price feeder contract.
    IPriceResolver public priceResolver;
    // Minter data
    mapping(address => PositionData) public positions;
    // Minters
    Minters private minters;
    // Synthetic token created by this contract.
    IExpandedIERC20 public override syntheticToken;
    // Support collateral token (stablecoin)
    IToken public override supportCollateralToken;
    // Base collateral token
    IToken public override baseCollateralToken;
    // Keep track of synthetic tokens that've been issued
    uint256 public tokenOutstanding;
    // Total collateral that locked in this contract
    RawCollateral public totalRawCollateral;
    // trading fee
    uint256 public mintFee = 0; // 0%
    uint256 public redeemFee = 0; // 0%
    // dev address
    address public devAddress;
    // liquidation ratio
    uint256 public constant liquidationRatio = 1200000000000000000; // 120%
    // Liquidation Incentive Fee 10%
    uint256 public constant liquidationIncentive = 100000000000000000;
    // Debts outstanding
    uint256 public debts;

    // Helpers
    uint256 constant MAX =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 constant ONE = 1000000000000000000; // 1

    event CreatedSyntheticToken();
    event NewMinter(address minter);
    event PositionCreated(
        address minter,
        uint256 baseAmount,
        uint256 supportAmount,
        uint256 syntheticAmount
    );
    event PositionDeleted(address minter);
    event Redeem(
        address minter,
        uint256 baseAmount,
        uint256 supportAmount,
        uint256 syntheticAmount
    );
    event Deposit(
        address indexed minter,
        uint256 baseAmount,
        uint256 supportAmount
    );
    event Withdrawal(
        address indexed minter,
        uint256 baseAmount,
        uint256 supportAmount
    );
    event PositionLiquidated(
        address indexed minter,
        address indexed liquidator,
        uint256 syntheticAmount,
        uint256 baseAmountBack,
        uint256 supportAmountBack
    );

    constructor(
        string memory _name,
        string memory _symbol,
        address _tokenFactoryAddress,
        address _priceResolverAddress,
        address _baseCollateralTokenAddress,
        address _supportCollateralTokenAddress,
        address _devAddress // dev wallet
    ) public nonReentrant() {
        require(
            _tokenFactoryAddress != address(0),
            "Invalid TokenFactory address"
        );
        require(
            _priceResolverAddress != address(0),
            "Invalid PriceResolver address"
        );
        require(
            _baseCollateralTokenAddress != address(0),
            "Invalid BaseCollateralToken address"
        );
        require(
            _supportCollateralTokenAddress != address(0),
            "Invalid SupportCollateralToken address"
        );

        name = string(abi.encodePacked(_name, " Token Manager"));
        state = ContractState.INITIAL;

        // Create the synthetic token
        TokenFactory tf = TokenFactory(_tokenFactoryAddress);
        syntheticToken = tf.createToken(_name, _symbol, 18);

        priceResolver = IPriceResolver(_priceResolverAddress);

        // FIXME : Allow only stablecoin addresses
        supportCollateralToken = IToken(_supportCollateralTokenAddress);
        baseCollateralToken = IToken(_baseCollateralTokenAddress);

        devAddress = _devAddress;

        // add dev into the whitelist
        addAddress(_devAddress);

        if (_devAddress != msg.sender) {
            addAddress(msg.sender);
        }

        emit CreatedSyntheticToken();
    }

    // update the contract state
    function setContractState(ContractState _state)
        public
        nonReentrant
        onlyWhitelisted
    {
        state = _state;
    }

    // mint synthetic tokens from the given collateral tokens
    function mint(
        uint256 baseCollateral, // main token
        uint256 supportCollateral, // stablecoin
        uint256 numTokens // synthetic tokens to be minted
    ) public isReady nonReentrant {
        require(baseCollateral >= 0, "baseCollateral must be greater than 0");
        require(
            supportCollateral >= 0,
            "supportCollateral must be greater than 0"
        );
        require(numTokens > 0, "numTokens must be greater than 0");

        PositionData storage positionData = positions[msg.sender];

        require(
            _checkCollateralization(
                positionData.rawBaseCollateral.add(baseCollateral),
                positionData.rawSupportCollateral.add(supportCollateral),
                positionData.tokensOutstanding.add(numTokens)
            ),
            "Position below than collateralization ratio"
        );

        if (positionData.tokensOutstanding == 0) {
            emit NewMinter(msg.sender);

            if (!minters.active[msg.sender]) {
                minters.active[msg.sender] = true;
                uint256 index = minters.array.length;
                minters.array.push(index);
                minters.list[index] = msg.sender;
            }
        }

        // Increase the position and global collateral balance by collateral amount.
        _incrementCollateralBalances(
            positionData,
            baseCollateral,
            supportCollateral
        );

        // Add the number of tokens created to the position's outstanding tokens.
        positionData.tokensOutstanding = positionData.tokensOutstanding.add(
            numTokens
        );

        tokenOutstanding = tokenOutstanding.add(numTokens);

        emit PositionCreated(
            msg.sender,
            baseCollateral,
            supportCollateral,
            numTokens
        );

        // Transfer tokens into the contract from caller and mint corresponding synthetic tokens to the caller's address.
        if (baseCollateral > 0) {
            baseCollateralToken.safeTransferFrom(
                msg.sender,
                address(this),
                baseCollateral
            );
        }
        
        if (supportCollateral > 0) {
            supportCollateralToken.safeTransferFrom(
                msg.sender,
                address(this),
                supportCollateral
            );
        }
        
        require(
            syntheticToken.mint(msg.sender, numTokens),
            "Minting synthetic tokens failed"
        );
    }

    // increase collateralization ratio by deposit more collateral
    function deposit(
        uint256 baseCollateral, // main token
        uint256 supportCollateral // stablecoin
    ) public isReady nonReentrant {
        PositionData storage positionData = positions[msg.sender];

        require(
            _checkCollateralization(
                positionData.rawBaseCollateral.add(baseCollateral),
                positionData.rawSupportCollateral.add(supportCollateral),
                positionData.tokensOutstanding
            ),
            "Position below than collateralization ratio"
        );

        // Increase the position and collateral balance by collateral amount.
        _incrementCollateralBalances(
            positionData,
            baseCollateral,
            supportCollateral
        );

        emit Deposit(msg.sender, baseCollateral, supportCollateral);

        // Move collateral tokens from sender to contract.
        baseCollateralToken.safeTransferFrom(
            msg.sender,
            address(this),
            baseCollateral
        );
        supportCollateralToken.safeTransferFrom(
            msg.sender,
            address(this),
            supportCollateral
        );
    }

    // decrease collateralization ratio by withdraw some collateral as long as the new postion above the liquidation ratio
    function withdraw(
        uint256 baseCollateral, // main token
        uint256 supportCollateral // stablecoin
    ) public isReady nonReentrant {
        PositionData storage positionData = positions[msg.sender];

        require(
            positionData.rawBaseCollateral >= baseCollateral,
            "Insufficient base collateral tokens amount"
        );
        require(
            positionData.rawSupportCollateral >= supportCollateral,
            "Insufficient support collateral tokens amount"
        );

        require(
            _checkCollateralization(
                positionData.rawBaseCollateral.sub(baseCollateral),
                positionData.rawSupportCollateral.sub(supportCollateral),
                positionData.tokensOutstanding
            ),
            "Position below than collateralization ratio"
        );

        // Decrement the minter's collateral and global collateral amounts.
        _decrementCollateralBalances(
            positionData,
            baseCollateral,
            supportCollateral
        );

        emit Withdrawal(msg.sender, baseCollateral, supportCollateral);

        // Transfer collateral from contract to minter
        baseCollateralToken.safeTransfer(msg.sender, baseCollateral);
        supportCollateralToken.safeTransfer(msg.sender, supportCollateral);
    }

    // redeem synthetic tokens back to the minter
    function redeem(
        uint256 baseCollateral, // main token
        uint256 supportCollateral, // stablecoin
        uint256 numTokens // synthetic tokens to be redeemed
    ) public isReady nonReentrant {
        require(numTokens > 0, "numTokens must be greater than 0");

        PositionData storage positionData = positions[msg.sender];

        require(
            positionData.rawBaseCollateral >= baseCollateral,
            "Insufficient base collateral tokens amount"
        );
        require(
            positionData.rawSupportCollateral >= supportCollateral,
            "Insufficient support collateral tokens amount"
        );
        require(
            positionData.tokensOutstanding >= numTokens,
            "Insufficient synthetics amount"
        );

        require(
            _checkCollateralization(
                positionData.rawBaseCollateral.sub(baseCollateral),
                positionData.rawSupportCollateral.sub(supportCollateral),
                positionData.tokensOutstanding.sub(numTokens)
            ),
            "Position below than collateralization ratio"
        );

        // Decrement the minter's collateral and global collateral amounts.
        _decrementCollateralBalances(
            positionData,
            baseCollateral,
            supportCollateral
        );

        positionData.tokensOutstanding = positionData.tokensOutstanding.sub(
            numTokens
        );
        tokenOutstanding = tokenOutstanding.sub(numTokens);

        emit Redeem(msg.sender, baseCollateral, supportCollateral, numTokens);

        // Transfer collateral from contract to caller and burn callers synthetic tokens.
        baseCollateralToken.safeTransfer(msg.sender, baseCollateral);
        supportCollateralToken.safeTransfer(msg.sender, supportCollateral);

        syntheticToken.safeTransferFrom(msg.sender, address(this), numTokens);
        syntheticToken.burn(numTokens);
    }

    // burn all synthetic tokens and send collateral tokens back to the minter
    function redeemAll() public isReadyOrEmergency nonReentrant {
        PositionData storage positionData = positions[msg.sender];

        emit Redeem(
            msg.sender,
            positionData.rawBaseCollateral,
            positionData.rawSupportCollateral,
            positionData.tokensOutstanding
        );

        // Transfer collateral from contract to minter and burn synthetic tokens.
        supportCollateralToken.safeTransfer(
            msg.sender,
            positionData.rawSupportCollateral
        );
        baseCollateralToken.safeTransfer(
            msg.sender,
            positionData.rawBaseCollateral
        );

        syntheticToken.safeTransferFrom(
            msg.sender,
            address(this),
            positionData.tokensOutstanding
        );
        syntheticToken.burn(positionData.tokensOutstanding);

        // delete the position
        _deleteSponsorPosition(msg.sender);
    }

    // estimate min. base and support tokens require to mint the given synthetic tokens
    function estimateTokensIn(uint256 numTokens)
        public
        view
        returns (uint256, uint256)
    {
        uint256 currentRate = priceResolver.getCurrentPrice();
        uint256 currentBaseRate = priceResolver.getCurrentPriceCollateral();

        uint256 totalCollateralNeed = numTokens.wmul(currentRate);
        // multiply by liquidation ratio
        totalCollateralNeed = totalCollateralNeed.wmul(liquidationRatio);

        // find suitable mint ratio from historical prices ( ratio = latestPrice / (average 30d + average 60d) )
        uint256 mintRatio = priceResolver.getCurrentRatio();
        uint256 baseCollateralNeed = totalCollateralNeed.wmul(mintRatio);

        uint256 supportCollateralNeed = totalCollateralNeed.wmul(
            ONE.sub(mintRatio)
        );

        // convert base from usd
        baseCollateralNeed = baseCollateralNeed.wdiv(currentBaseRate);

        uint256 adjustedBaseCollateralNeed = _adjustBaseAmountBack(
            baseCollateralNeed
        );
        uint256 adjustedSupportCollateralNeed = _adjustSupportAmountBack(
            supportCollateralNeed
        );

        return (adjustedBaseCollateralNeed, adjustedSupportCollateralNeed);
    }

    // estimate synthetic tokens to be redeemed from the given base and support collateral tokens
    function estimateTokensOut(
        address minter,
        uint256 baseCollateral,
        uint256 supportCollateral
    ) public view returns (uint256) {
        PositionData storage positionData = positions[minter];

        require(
            positionData.rawBaseCollateral >= baseCollateral,
            "Insufficient base collateral tokens amount"
        );
        require(
            positionData.rawSupportCollateral >= supportCollateral,
            "Insufficient support collateral tokens amount"
        );

        uint256 currentRatio = _getCollateralizationRatio(
            positionData.rawBaseCollateral,
            positionData.rawSupportCollateral,
            positionData.tokensOutstanding
        );

        return
            _calculateSyntheticRedeemed(baseCollateral, supportCollateral).wdiv(
                currentRatio
            );
    }

    // calculate the collateralization ratio from the given amounts
    function getCollateralizationRatio(
        uint256 baseCollateral, // main token
        uint256 supportCollateral, // stablecoin
        uint256 numTokens // synthetic tokens to be minted
    ) public view returns (uint256) {
        return
            _getCollateralizationRatio(
                baseCollateral,
                supportCollateral,
                numTokens
            );
    }

    // return the caller's collateralization ratio
    function myCollateralizationRatio() public view returns (uint256 ratio) {
        PositionData storage positionData = positions[msg.sender];
        return
            _getCollateralizationRatio(
                positionData.rawBaseCollateral,
                positionData.rawSupportCollateral,
                positionData.tokensOutstanding
            );
    }

    // return the caller position's outstanding synthetic tokens
    function myTokensOutstanding()
        public
        view
        returns (uint256 tokensOutstanding)
    {
        PositionData storage positionData = positions[msg.sender];
        return positionData.tokensOutstanding;
    }

    // return the caller position's collateral tokens
    function myTokensCollateral()
        public
        view
        returns (uint256 baseCollateral, uint256 supportCollateral)
    {
        PositionData storage positionData = positions[msg.sender];
        return (
            positionData.rawBaseCollateral,
            positionData.rawSupportCollateral
        );
    }

    // total minter in the system
    function totalMinter() public view returns (uint256) {
        return minters.array.length;
    }

    // return minter's address from given index
    function minterAddress(uint256 _index) public view returns (address) {
        return minters.list[_index];
    }

    // check whether the given address is minter or not
    function isMinter(address _minter) public view returns (bool) {
        return minters.active[_minter];
    }

    // check the synthetic token price
    function getSyntheticPrice() public view returns (uint256) {
        return priceResolver.getCurrentPrice();
    }

    // check base collateral token price
    function getBaseCollateralPrice() public view returns (uint256) {
        return priceResolver.getCurrentPriceCollateral();
    }

    // check support collateral token price
    function getSupportCollateralPrice() public pure returns (uint256) {
        // FIXME: Fetch the actual value
        return ONE;
    }

    // check current mint ratio
    function getMintRatio() public view returns (uint256) {
        return priceResolver.getCurrentRatio();
    }

    // return the collateralization ratio of the given address
    function collateralizationRatioOf(address minter)
        public
        view
        returns (uint256 ratio)
    {
        PositionData storage positionData = positions[minter];
        return
            _getCollateralizationRatio(
                positionData.rawBaseCollateral,
                positionData.rawSupportCollateral,
                positionData.tokensOutstanding
            );
    }

    // return deposited collaterals of the given address
    function tokensCollateralOf(address minter)
        public
        view
        returns (uint256, uint256)
    {
        PositionData storage positionData = positions[minter];
        return (
            positionData.rawBaseCollateral,
            positionData.rawSupportCollateral
        );
    }

    // check whether the given address can be liquidated or not
    function checkLiquidate(address minter)
        public
        view
        returns (bool, uint256)
    {
        PositionData storage positionData = positions[minter];

        uint256 currentRatio = _getCollateralizationRatio(
            positionData.rawBaseCollateral,
            positionData.rawSupportCollateral,
            positionData.tokensOutstanding
        );

        if (liquidationRatio > currentRatio) {
            // find no. of synthetic tokens require to liquidate the position
            uint256 remainingCollateralBase = positionData.rawBaseCollateral;
            uint256 remainingCollateralSupport = positionData.rawSupportCollateral;
            uint256 discountBase = remainingCollateralBase.wmul( liquidationIncentive );
            uint256 discountSupport = remainingCollateralSupport.wmul( liquidationIncentive );
            remainingCollateralBase = remainingCollateralBase.sub(discountBase);
            remainingCollateralSupport = remainingCollateralSupport.sub(discountSupport);

            uint256 synthsNeed = _calculateSyntheticRedeemed(remainingCollateralBase , remainingCollateralSupport);
            return (true, synthsNeed);
        } else {
            return (false, 0);
        }
    }

    // liquidate the minter's position 
    function liquidate( 
        address minter, // address of the minter to be liquidated
        uint256 maxNumTokens // max amount of synthetic tokens that effort to burn
    ) public isReadyOrEmergency nonReentrant {
        // Retrieve Position data for minter
        PositionData storage positionData = positions[minter];

        require(
            _checkCollateralization(
                positionData.rawBaseCollateral,
                positionData.rawSupportCollateral,
                positionData.tokensOutstanding
            ) == false,
            "Position above than liquidation ratio"
        );

        uint256 remainingCollateralBase = positionData.rawBaseCollateral;
        uint256 remainingCollateralSupport = positionData.rawSupportCollateral;
        uint256 discountBase = remainingCollateralBase.wmul( liquidationIncentive );
        uint256 discountSupport = remainingCollateralSupport.wmul( liquidationIncentive );
        remainingCollateralBase = remainingCollateralBase.sub(discountBase);
        remainingCollateralSupport = remainingCollateralSupport.sub(discountSupport);

        uint256 totalBurnt = _calculateSyntheticRedeemed(remainingCollateralBase , remainingCollateralSupport);

        require( maxNumTokens >= totalBurnt , "Exceeding given maxNumtokens" );

        if ( positionData.tokensOutstanding > totalBurnt ) {
            // keep tack of debts
            debts = debts.add( positionData.tokensOutstanding.sub(totalBurnt));
        }

        // pay incentives + collateral tokens to liquidator
        supportCollateralToken.safeTransfer(
            msg.sender,
            positionData.rawSupportCollateral
        );
        baseCollateralToken.safeTransfer(
            msg.sender,
            positionData.rawBaseCollateral
        );

        // transfer synthetic tokens from liquidator to burn here
        syntheticToken.safeTransferFrom(msg.sender, address(this), totalBurnt);
        syntheticToken.burn(totalBurnt);

        emit PositionLiquidated(
            minter,
            msg.sender,
            totalBurnt,
            positionData.rawBaseCollateral,
            positionData.rawSupportCollateral
        );

        // delete the position
        totalRawCollateral.baseToken = totalRawCollateral.baseToken.sub(
            positionData.rawBaseCollateral
        );
        totalRawCollateral.supportToken = totalRawCollateral.supportToken.sub(
            positionData.rawSupportCollateral
        );

        tokenOutstanding = tokenOutstanding.sub( totalBurnt );
        // Reset the sponsors position to have zero outstanding and collateral.
        delete positions[minter];
    }

    // repay debts 
    function repayDebt(uint256 amount) public nonReentrant {
        require( debts >= amount , "Amount > Outstanding debts" );

        debts = debts.sub( amount );

        syntheticToken.safeTransferFrom(msg.sender, address(this), amount);
        syntheticToken.burn(amount);
    }

    // INTERNAL FUNCTIONS

    function _getCollateralizationRatio(
        uint256 baseCollateral,
        uint256 supportCollateral,
        uint256 numTokens
    ) internal view returns (uint256) {
        baseCollateral = _adjustBaseAmount(baseCollateral);
        supportCollateral = _adjustSupportAmount(supportCollateral);

        uint256 currentRate = priceResolver.getCurrentPrice();
        uint256 currentBaseRate = priceResolver.getCurrentPriceCollateral();

        uint256 baseAmount = baseCollateral.wmul(currentBaseRate);
        uint256 totalCollateral = baseAmount.add(supportCollateral);

        return (totalCollateral.wdiv(currentRate)).wdiv(numTokens);
    }

    function _checkCollateralization(
        uint256 baseCollateral,
        uint256 supportCollateral,
        uint256 numTokens
    ) internal view returns (bool) {
        uint256 minRatio = liquidationRatio;

        uint256 thisChange = _getCollateralizationRatio(
            baseCollateral,
            supportCollateral,
            numTokens
        );

        return !(minRatio > (thisChange));
    }

    function _calculateSyntheticRedeemed(
        uint256 baseCollateral,
        uint256 supportCollateral
    ) internal view returns (uint256) {
        baseCollateral = _adjustBaseAmount(baseCollateral);
        supportCollateral = _adjustSupportAmount(supportCollateral);

        uint256 currentRate = priceResolver.getCurrentPrice();
        uint256 currentBaseRate = priceResolver.getCurrentPriceCollateral();

        uint256 baseAmount = baseCollateral.wmul(currentBaseRate);
        uint256 totalCollateral = baseAmount.add(supportCollateral);

        return (totalCollateral.wdiv(currentRate));
    }

    function _adjustBaseAmount(uint256 amount) internal view returns (uint256) {
        uint8 decimals = baseCollateralToken.decimals();
        return _adjustAmount(amount, decimals);
    }

    function _adjustSupportAmount(uint256 amount)
        internal
        view
        returns (uint256)
    {
        uint8 decimals = supportCollateralToken.decimals();
        return _adjustAmount(amount, decimals);
    }

    function _adjustAmount(uint256 amount, uint8 decimals)
        internal
        pure
        returns (uint256)
    {
        if (decimals == 18) {
            return amount;
        } else {
            uint8 remainingDecimals = 18 - decimals;
            uint256 multiplier = 10**uint256(remainingDecimals);
            return amount.mul(multiplier);
        }
    }

    function _adjustBaseAmountBack(uint256 amount)
        internal
        view
        returns (uint256)
    {
        uint8 decimals = baseCollateralToken.decimals();
        return _adjustAmountBack(amount, decimals);
    }

    function _adjustSupportAmountBack(uint256 amount)
        internal
        view
        returns (uint256)
    {
        uint8 decimals = supportCollateralToken.decimals();
        return _adjustAmountBack(amount, decimals);
    }

    function _adjustAmountBack(uint256 amount, uint8 decimals)
        internal
        pure
        returns (uint256)
    {
        if (decimals == 18) {
            return amount;
        } else {
            uint8 remainingDecimals = 18 - decimals;
            uint256 multiplier = 10**uint256(remainingDecimals);
            return amount.div(multiplier);
        }
    }

    function _incrementCollateralBalances(
        PositionData storage positionData,
        uint256 baseCollateral,
        uint256 supportCollateral
    ) internal {
        positionData.rawBaseCollateral = positionData.rawBaseCollateral.add(
            baseCollateral
        );
        positionData.rawSupportCollateral = positionData
            .rawSupportCollateral
            .add(supportCollateral);

        totalRawCollateral.baseToken = totalRawCollateral.baseToken.add(
            baseCollateral
        );
        totalRawCollateral.supportToken = totalRawCollateral.supportToken.add(
            supportCollateral
        );
    }

    function _decrementCollateralBalances(
        PositionData storage positionData,
        uint256 baseCollateral,
        uint256 supportCollateral
    ) internal {
        positionData.rawBaseCollateral = positionData.rawBaseCollateral.sub(
            baseCollateral
        );
        positionData.rawSupportCollateral = positionData
            .rawSupportCollateral
            .sub(supportCollateral);

        totalRawCollateral.baseToken = totalRawCollateral.baseToken.sub(
            baseCollateral
        );
        totalRawCollateral.supportToken = totalRawCollateral.supportToken.sub(
            supportCollateral
        );
    }

    function _deleteSponsorPosition(address _minter) internal {
        PositionData storage positionToLiquidate = positions[_minter];

        totalRawCollateral.baseToken = totalRawCollateral.baseToken.sub(
            positionToLiquidate.rawBaseCollateral
        );
        totalRawCollateral.supportToken = totalRawCollateral.supportToken.sub(
            positionToLiquidate.rawSupportCollateral
        );

        tokenOutstanding = tokenOutstanding.sub(
            positionToLiquidate.tokensOutstanding
        );

        // Reset the sponsors position to have zero outstanding and collateral.
        delete positions[_minter];

        emit PositionDeleted(_minter);
    }

    // Check if the state is ready
    modifier isReady() {
        require((state) == ContractState.NORMAL, "Contract state is not ready");
        _;
    }

    // Only Ready and Emergency
    modifier isReadyOrEmergency() {
        require(
            (state) == ContractState.NORMAL ||
                (state) == ContractState.EMERGENCY,
            "Contract state is not either ready or emergency"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";


/**
  * @dev The contract manages a list of whitelisted addresses
*/
contract Whitelist is Ownable {
    using Address for address;

    mapping (address => bool) private whitelist;

    constructor() public {
        address msgSender = _msgSender();
        whitelist[msgSender] = true;
    }


    /**
      * @dev returns true if a given address is whitelisted, false if not
      * 
      * @param _address address to check
      * 
      * @return true if the address is whitelisted, false if not
    */
    function isWhitelisted(address _address) public view returns (bool) {
        return whitelist[_address];
    }

    modifier onlyWhitelisted() {
        address sender = _msgSender();
        require(isWhitelisted(sender), "Ownable: caller is not the owner");
        _;
    }

    /**
      * @dev adds a given address to the whitelist
      * 
      * @param _address address to add
    */
    function addAddress(address _address)
        public
        onlyWhitelisted()
    {
        if (whitelist[_address]) // checks if the address is already whitelisted
            return;

        whitelist[_address] = true;
    }

    /**
      * @dev removes a given address from the whitelist
      * 
      * @param _address address to remove
    */
    function removeAddress(address _address) public onlyWhitelisted() {
        if (!whitelist[_address]) // checks if the address is actually whitelisted
            return;

        whitelist[_address] = false;
    }



}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
import "./ExpandedERC20.sol";
import "./Lockable.sol";


/**
 * @title Burnable and mintable ERC20.
 * @dev The contract deployer will initially be the only minter, burner and owner capable of adding new roles.
 */

contract SyntheticToken is ExpandedERC20, Lockable {
    /**
     * @notice Constructs the SyntheticToken.
     * @param tokenName The name which describes the new token.
     * @param tokenSymbol The ticker abbreviation of the name. Ideally < 5 chars.
     * @param tokenDecimals The number of decimals to define token precision.
     */
    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals
    ) public ExpandedERC20(tokenName, tokenSymbol, tokenDecimals) nonReentrant() {}

    /**
     * @notice Add Minter role to account.
     * @dev The caller must have the Owner role.
     * @param account The address to which the Minter role is added.
     */
    function addMinter(address account) external nonReentrant() {
        addMember(uint256(Roles.Minter), account);
    }

    /**
     * @notice Remove Minter role from account.
     * @dev The caller must have the Owner role.
     * @param account The address from which the Minter role is removed.
     */
    function removeMinter(address account) external nonReentrant() {
        removeMember(uint256(Roles.Minter), account);
    }

    /**
     * @notice Add Burner role to account.
     * @dev The caller must have the Owner role.
     * @param account The address to which the Burner role is added.
     */
    function addBurner(address account) external nonReentrant() {
        addMember(uint256(Roles.Burner), account);
    }

    /**
     * @notice Removes Burner role from account.
     * @dev The caller must have the Owner role.
     * @param account The address from which the Burner role is removed.
     */
    function removeBurner(address account) external nonReentrant() {
        removeMember(uint256(Roles.Burner), account);
    }

    /**
     * @notice Reset Owner role to account.
     * @dev The caller must have the Owner role.
     * @param account The new holder of the Owner role.
     */
    function resetOwner(address account) external nonReentrant() {
        resetMember(uint256(Roles.Owner), account);
    }

    /**
     * @notice Checks if a given account holds the Minter role.
     * @param account The address which is checked for the Minter role.
     * @return bool True if the provided account is a Minter.
     */
    function isMinter(address account) public view nonReentrantView() returns (bool) {
        return holdsRole(uint256(Roles.Minter), account);
    }

    /**
     * @notice Checks if a given account holds the Burner role.
     * @param account The address which is checked for the Burner role.
     * @return bool True if the provided account is a Burner.
     */
    function isBurner(address account) public view nonReentrantView() returns (bool) {
        return holdsRole(uint256(Roles.Burner), account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../interfaces/IERC20.sol";
import "./SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


library Exclusive {
    struct RoleMembership {
        address member;
    }

    function isMember(RoleMembership storage roleMembership, address memberToCheck) internal view returns (bool) {
        return roleMembership.member == memberToCheck;
    }

    function resetMember(RoleMembership storage roleMembership, address newMember) internal {
        require(newMember != address(0x0), "Cannot set an exclusive role to 0x0");
        roleMembership.member = newMember;
    }

    function getMember(RoleMembership storage roleMembership) internal view returns (address) {
        return roleMembership.member;
    }

    function init(RoleMembership storage roleMembership, address initialMember) internal {
        resetMember(roleMembership, initialMember);
    }
}


library Shared {
    struct RoleMembership {
        mapping(address => bool) members;
    }

    function isMember(RoleMembership storage roleMembership, address memberToCheck) internal view returns (bool) {
        return roleMembership.members[memberToCheck];
    }

    function addMember(RoleMembership storage roleMembership, address memberToAdd) internal {
        require(memberToAdd != address(0x0), "Cannot add 0x0 to a shared role");
        roleMembership.members[memberToAdd] = true;
    }

    function removeMember(RoleMembership storage roleMembership, address memberToRemove) internal {
        roleMembership.members[memberToRemove] = false;
    }

    function init(RoleMembership storage roleMembership, address[] memory initialMembers) internal {
        for (uint256 i = 0; i < initialMembers.length; i++) {
            addMember(roleMembership, initialMembers[i]);
        }
    }
}


/**
 * @title Base class to manage permissions for the derived class.
 */
abstract contract MultiRole {
    using Exclusive for Exclusive.RoleMembership;
    using Shared for Shared.RoleMembership;

    enum RoleType { Invalid, Exclusive, Shared }

    struct Role {
        uint256 managingRole;
        RoleType roleType;
        Exclusive.RoleMembership exclusiveRoleMembership;
        Shared.RoleMembership sharedRoleMembership;
    }

    mapping(uint256 => Role) private roles;

    event ResetExclusiveMember(uint256 indexed roleId, address indexed newMember, address indexed manager);
    event AddedSharedMember(uint256 indexed roleId, address indexed newMember, address indexed manager);
    event RemovedSharedMember(uint256 indexed roleId, address indexed oldMember, address indexed manager);

    /**
     * @notice Reverts unless the caller is a member of the specified roleId.
     */
    modifier onlyRoleHolder(uint256 roleId) {
        require(holdsRole(roleId, msg.sender), "Sender does not hold required role");
        _;
    }

    /**
     * @notice Reverts unless the caller is a member of the manager role for the specified roleId.
     */
    modifier onlyRoleManager(uint256 roleId) {
        require(holdsRole(roles[roleId].managingRole, msg.sender), "Can only be called by a role manager");
        _;
    }

    /**
     * @notice Reverts unless the roleId represents an initialized, exclusive roleId.
     */
    modifier onlyExclusive(uint256 roleId) {
        require(roles[roleId].roleType == RoleType.Exclusive, "Must be called on an initialized Exclusive role");
        _;
    }

    /**
     * @notice Reverts unless the roleId represents an initialized, shared roleId.
     */
    modifier onlyShared(uint256 roleId) {
        require(roles[roleId].roleType == RoleType.Shared, "Must be called on an initialized Shared role");
        _;
    }

    /**
     * @notice Whether `memberToCheck` is a member of roleId.
     * @dev Reverts if roleId does not correspond to an initialized role.
     * @param roleId the Role to check.
     * @param memberToCheck the address to check.
     * @return True if `memberToCheck` is a member of `roleId`.
     */
    function holdsRole(uint256 roleId, address memberToCheck) public view returns (bool) {
        Role storage role = roles[roleId];
        if (role.roleType == RoleType.Exclusive) {
            return role.exclusiveRoleMembership.isMember(memberToCheck);
        } else if (role.roleType == RoleType.Shared) {
            return role.sharedRoleMembership.isMember(memberToCheck);
        }
        revert("Invalid roleId");
    }

    /**
     * @notice Changes the exclusive role holder of `roleId` to `newMember`.
     * @dev Reverts if the caller is not a member of the managing role for `roleId` or if `roleId` is not an
     * initialized, ExclusiveRole.
     * @param roleId the ExclusiveRole membership to modify.
     * @param newMember the new ExclusiveRole member.
     */
    function resetMember(uint256 roleId, address newMember) public onlyExclusive(roleId) onlyRoleManager(roleId) {
        roles[roleId].exclusiveRoleMembership.resetMember(newMember);
        emit ResetExclusiveMember(roleId, newMember, msg.sender);
    }

    /**
     * @notice Gets the current holder of the exclusive role, `roleId`.
     * @dev Reverts if `roleId` does not represent an initialized, exclusive role.
     * @param roleId the ExclusiveRole membership to check.
     * @return the address of the current ExclusiveRole member.
     */
    function getMember(uint256 roleId) public view onlyExclusive(roleId) returns (address) {
        return roles[roleId].exclusiveRoleMembership.getMember();
    }

    /**
     * @notice Adds `newMember` to the shared role, `roleId`.
     * @dev Reverts if `roleId` does not represent an initialized, SharedRole or if the caller is not a member of the
     * managing role for `roleId`.
     * @param roleId the SharedRole membership to modify.
     * @param newMember the new SharedRole member.
     */
    function addMember(uint256 roleId, address newMember) public onlyShared(roleId) onlyRoleManager(roleId) {
        roles[roleId].sharedRoleMembership.addMember(newMember);
        emit AddedSharedMember(roleId, newMember, msg.sender);
    }

    /**
     * @notice Removes `memberToRemove` from the shared role, `roleId`.
     * @dev Reverts if `roleId` does not represent an initialized, SharedRole or if the caller is not a member of the
     * managing role for `roleId`.
     * @param roleId the SharedRole membership to modify.
     * @param memberToRemove the current SharedRole member to remove.
     */
    function removeMember(uint256 roleId, address memberToRemove) public onlyShared(roleId) onlyRoleManager(roleId) {
        roles[roleId].sharedRoleMembership.removeMember(memberToRemove);
        emit RemovedSharedMember(roleId, memberToRemove, msg.sender);
    }

    /**
     * @notice Removes caller from the role, `roleId`.
     * @dev Reverts if the caller is not a member of the role for `roleId` or if `roleId` is not an
     * initialized, SharedRole.
     * @param roleId the SharedRole membership to modify.
     */
    function renounceMembership(uint256 roleId) public onlyShared(roleId) onlyRoleHolder(roleId) {
        roles[roleId].sharedRoleMembership.removeMember(msg.sender);
        emit RemovedSharedMember(roleId, msg.sender, msg.sender);
    }

    /**
     * @notice Reverts if `roleId` is not initialized.
     */
    modifier onlyValidRole(uint256 roleId) {
        require(roles[roleId].roleType != RoleType.Invalid, "Attempted to use an invalid roleId");
        _;
    }

    /**
     * @notice Reverts if `roleId` is initialized.
     */
    modifier onlyInvalidRole(uint256 roleId) {
        require(roles[roleId].roleType == RoleType.Invalid, "Cannot use a pre-existing role");
        _;
    }

    /**
     * @notice Internal method to initialize a shared role, `roleId`, which will be managed by `managingRoleId`.
     * `initialMembers` will be immediately added to the role.
     * @dev Should be called by derived contracts, usually at construction time. Will revert if the role is already
     * initialized.
     */
    function _createSharedRole(
        uint256 roleId,
        uint256 managingRoleId,
        address[] memory initialMembers
    ) internal onlyInvalidRole(roleId) {
        Role storage role = roles[roleId];
        role.roleType = RoleType.Shared;
        role.managingRole = managingRoleId;
        role.sharedRoleMembership.init(initialMembers);
        require(
            roles[managingRoleId].roleType != RoleType.Invalid,
            "Attempted to use an invalid role to manage a shared role"
        );
    }

    /**
     * @notice Internal method to initialize an exclusive role, `roleId`, which will be managed by `managingRoleId`.
     * `initialMember` will be immediately added to the role.
     * @dev Should be called by derived contracts, usually at construction time. Will revert if the role is already
     * initialized.
     */
    function _createExclusiveRole(
        uint256 roleId,
        uint256 managingRoleId,
        address initialMember
    ) internal onlyInvalidRole(roleId) {
        Role storage role = roles[roleId];
        role.roleType = RoleType.Exclusive;
        role.managingRole = managingRoleId;
        role.exclusiveRoleMembership.init(initialMember);
        require(
            roles[managingRoleId].roleType != RoleType.Invalid,
            "Attempted to use an invalid role to manage an exclusive role"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


/**
 * @title A contract that provides modifiers to prevent reentrancy to state-changing and view-only methods. This contract
 * is inspired by https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol
 * and https://github.com/balancer-labs/balancer-core/blob/master/contracts/BPool.sol.
 */
contract Lockable {
    bool private _notEntered;

    constructor() internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _preEntranceCheck();
        _preEntranceSet();
        _;
        _postEntranceReset();
    }

    /**
     * @dev Designed to prevent a view-only method from being re-entered during a call to a `nonReentrant()` state-changing method.
     */
    modifier nonReentrantView() {
        _preEntranceCheck();
        _;
    }

    // Internal methods are used to avoid copying the require statement's bytecode to every `nonReentrant()` method.
    // On entry into a function, `_preEntranceCheck()` should always be called to check if the function is being re-entered.
    // Then, if the function modifies state, it should call `_postEntranceSet()`, perform its logic, and then call `_postEntranceReset()`.
    // View-only methods can simply call `_preEntranceCheck()` to make sure that it is not being re-entered.
    function _preEntranceCheck() internal view {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");
    }

    function _preEntranceSet() internal {
        // Any calls to nonReentrant after this point will fail
        _notEntered = false;
    }

    function _postEntranceReset() internal {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

library LibMathSigned {
    int256 private constant _WAD = 10 ** 18;
    int256 private constant _INT256_MIN = -2 ** 255;

    uint8 private constant FIXED_DIGITS = 18;
    int256 private constant FIXED_1 = 10 ** 18;
    int256 private constant FIXED_E = 2718281828459045235;
    uint8 private constant LONGER_DIGITS = 36;
    int256 private constant LONGER_FIXED_LOG_E_1_5 = 405465108108164381978013115464349137;
    int256 private constant LONGER_FIXED_1 = 10 ** 36;
    int256 private constant LONGER_FIXED_LOG_E_10 = 2302585092994045684017991454684364208;


    function WAD() internal pure returns (int256) {
        return _WAD;
    }

    // additive inverse
    function neg(int256 a) internal pure returns (int256) {
        return sub(int256(0), a);
    }

    /**
     * @dev Multiplies two signed integers, reverts on overflow
     * see https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.1/contracts/math/SignedSafeMath.sol#L13
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }
        require(!(a == -1 && b == _INT256_MIN), "wmultiplication overflow");

        int256 c = a * b;
        require(c / a == b, "wmultiplication overflow");

        return c;
    }

    /**
     * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
     * see https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.1/contracts/math/SignedSafeMath.sol#L32
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "wdivision by zero");
        require(!(b == -1 && a == _INT256_MIN), "wdivision overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Subtracts two signed integers, reverts on overflow.
     * see https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.1/contracts/math/SignedSafeMath.sol#L44
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "subtraction overflow");

        return c;
    }

    /**
     * @dev Adds two signed integers, reverts on overflow.
     * see https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.1/contracts/math/SignedSafeMath.sol#L54
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "addition overflow");

        return c;
    }

    function wmul(int256 x, int256 y) internal pure returns (int256 z) {
        z = roundHalfUp(mul(x, y), _WAD) / _WAD;
    }

    // solium-disable-next-line security/no-assign-params
    function wdiv(int256 x, int256 y) internal pure returns (int256 z) {
        if (y < 0) {
            y = -y;
            x = -x;
        }
        z = roundHalfUp(mul(x, _WAD), y) / y;
    }

    // solium-disable-next-line security/no-assign-params
    function wfrac(int256 x, int256 y, int256 z) internal pure returns (int256 r) {
        int256 t = mul(x, y);
        if (z < 0) {
            z = neg(z);
            t = neg(t);
        }
        r = roundHalfUp(t, z) / z;
    }

    function min(int256 x, int256 y) internal pure returns (int256) {
        return x <= y ? x : y;
    }

    function max(int256 x, int256 y) internal pure returns (int256) {
        return x >= y ? x : y;
    }

    // see https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.1/contracts/utils/SafeCast.sol#L103
    function toUint256(int256 x) internal pure returns (uint256) {
        require(x >= 0, "int overflow");
        return uint256(x);
    }

    // x ^ n
    // NOTE: n is a normal integer, do not shift 18 decimals
    // solium-disable-next-line security/no-assign-params
    function wpowi(int256 x, int256 n) internal pure returns (int256 z) {
        require(n >= 0, "wpowi only supports n >= 0");
        z = n % 2 != 0 ? x : _WAD;

        for (n /= 2; n != 0; n /= 2) {
            x = wmul(x, x);

            if (n % 2 != 0) {
                z = wmul(z, x);
            }
        }
    }

    // ROUND_HALF_UP rule helper. You have to call roundHalfUp(x, y) / y to finish the rounding operation
    // 0.5 ≈ 1, 0.4 ≈ 0, -0.5 ≈ -1, -0.4 ≈ 0
    function roundHalfUp(int256 x, int256 y) internal pure returns (int256) {
        require(y > 0, "roundHalfUp only supports y > 0");
        if (x >= 0) {
            return add(x, y / 2);
        }
        return sub(x, y / 2);
    }

    // solium-disable-next-line security/no-assign-params
    function wln(int256 x) internal pure returns (int256) {
        require(x > 0, "logE of negative number");
        require(x <= 10000000000000000000000000000000000000000, "logE only accepts v <= 1e22 * 1e18"); // in order to prevent using safe-math
        int256 r = 0;
        uint8 extraDigits = LONGER_DIGITS - FIXED_DIGITS;
        int256 t = int256(uint256(10)**uint256(extraDigits));

        while (x <= FIXED_1 / 10) {
            x = x * 10;
            r -= LONGER_FIXED_LOG_E_10;
        }
        while (x >= 10 * FIXED_1) {
            x = x / 10;
            r += LONGER_FIXED_LOG_E_10;
        }
        while (x < FIXED_1) {
            x = wmul(x, FIXED_E);
            r -= LONGER_FIXED_1;
        }
        while (x > FIXED_E) {
            x = wdiv(x, FIXED_E);
            r += LONGER_FIXED_1;
        }
        if (x == FIXED_1) {
            return roundHalfUp(r, t) / t;
        }
        if (x == FIXED_E) {
            return FIXED_1 + roundHalfUp(r, t) / t;
        }
        x *= t;

        //               x^2   x^3   x^4
        // Ln(1+x) = x - --- + --- - --- + ...
        //                2     3     4
        // when -1 < x < 1, O(x^n) < ε => when n = 36, 0 < x < 0.316
        //
        //                    2    x           2    x          2    x
        // Ln(a+x) = Ln(a) + ---(------)^1  + ---(------)^3 + ---(------)^5 + ...
        //                    1   2a+x         3   2a+x        5   2a+x
        //
        // Let x = v - a
        //                  2   v-a         2   v-a        2   v-a
        // Ln(v) = Ln(a) + ---(-----)^1  + ---(-----)^3 + ---(-----)^5 + ...
        //                  1   v+a         3   v+a        5   v+a
        // when n = 36, 1 < v < 3.423
        r = r + LONGER_FIXED_LOG_E_1_5;
        int256 a1_5 = (3 * LONGER_FIXED_1) / 2;
        int256 m = (LONGER_FIXED_1 * (x - a1_5)) / (x + a1_5);
        r = r + 2 * m;
        int256 m2 = (m * m) / LONGER_FIXED_1;
        uint8 i = 3;
        while (true) {
            m = (m * m2) / LONGER_FIXED_1;
            r = r + (2 * m) / int256(i);
            i += 2;
            if (i >= 3 + 2 * FIXED_DIGITS) {
                break;
            }
        }
        return roundHalfUp(r, t) / t;
    }

    // Log(b, x)
    function logBase(int256 base, int256 x) internal pure returns (int256) {
        return wdiv(wln(x), wln(base));
    }

    function ceil(int256 x, int256 m) internal pure returns (int256) {
        require(x >= 0, "ceil need x >= 0");
        require(m > 0, "ceil need m > 0");
        return (sub(add(x, m), 1) / m) * m;
    }
}


library LibMathUnsigned {
    uint256 private constant _WAD = 10**18;
    uint256 private constant _POSITIVE_INT256_MAX = 2**255 - 1;

    function WAD() internal pure returns (uint256) {
        return _WAD;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     * see https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.1/contracts/math/SafeMath.sol#L26
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Unaddition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     * see https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.1/contracts/math/SafeMath.sol#L55
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Unsubtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     * see https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.1/contracts/math/SafeMath.sol#L71
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "Unmultiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     * see https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.1/contracts/math/SafeMath.sol#L111
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "Undivision by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), _WAD / 2) / _WAD;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, _WAD), y / 2) / y;
    }

    function wfrac(uint256 x, uint256 y, uint256 z) internal pure returns (uint256 r) {
        r = mul(x, y) / z;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return x >= y ? x : y;
    }

    function toInt256(uint256 x) internal pure returns (int256) {
        require(x <= _POSITIVE_INT256_MAX, "uint256 overflow");
        return int256(x);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     * see https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.1/contracts/math/SafeMath.sol#L146
     */
    function mod(uint256 x, uint256 m) internal pure returns (uint256) {
        require(m != 0, "mod by zero");
        return x % m;
    }

    function ceil(uint256 x, uint256 m) internal pure returns (uint256) {
        require(m > 0, "ceil need m > 0");
        return (sub(add(x, m), 1) / m) * m;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./ERC20.sol";
import "./MultiRole.sol";
import "../interfaces/IExpandedIERC20.sol";


/**
 * @title An ERC20 with permissioned burning and minting. The contract deployer will initially
 * be the owner who is capable of adding new roles.
 */
contract ExpandedERC20 is IExpandedIERC20, ERC20, MultiRole {
    enum Roles {
        // Can set the minter and burner.
        Owner,
        // Addresses that can mint new tokens.
        Minter,
        // Addresses that can burn tokens that address owns.
        Burner
    }

    /**
     * @notice Constructs the ExpandedERC20.
     * @param _tokenName The name which describes the new token.
     * @param _tokenSymbol The ticker abbreviation of the name. Ideally < 5 chars.
     * @param _tokenDecimals The number of decimals to define token precision.
     */
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint8 _tokenDecimals
    ) public ERC20(_tokenName, _tokenSymbol) {
        _setupDecimals(_tokenDecimals);
        _createExclusiveRole(uint256(Roles.Owner), uint256(Roles.Owner), msg.sender);
        _createSharedRole(uint256(Roles.Minter), uint256(Roles.Owner), new address[](0));
        _createSharedRole(uint256(Roles.Burner), uint256(Roles.Owner), new address[](0));
    }

    /**
     * @dev Mints `value` tokens to `recipient`, returning true on success.
     * @param recipient address to mint to.
     * @param value amount of tokens to mint.
     * @return True if the mint succeeded, or False.
     */
    function mint(address recipient, uint256 value)
        external
        override
        onlyRoleHolder(uint256(Roles.Minter))
        returns (bool)
    {
        _mint(recipient, value);
        return true;
    }

    /**
     * @dev Burns `value` tokens owned by `msg.sender`.
     * @param value amount of tokens to burn.
     */
    function burn(uint256 value) external override onlyRoleHolder(uint256(Roles.Burner)) {
        _burn(msg.sender, value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "../interfaces/IERC20.sol";
import "./SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20MinterPauser}.
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
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
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
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
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
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
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
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

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
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IExpandedIERC20.sol";
import "./IToken.sol";

interface ITokenManager {

    function syntheticToken() external view returns (IExpandedIERC20);

    function supportCollateralToken() external view returns (IToken);

    function baseCollateralToken() external view returns (IToken);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";

interface IToken is IERC20 {

    function decimals() external view returns (uint8);
    

}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IPriceResolver {

    function getCurrentPrice() external view returns (uint256);

    function getCurrentPriceCollateral() external view returns (uint256);

    function getCurrentRatio() external view returns (uint256);

    function getRawRatio() external view returns (uint256);

    function getAvg30Price() external view returns (uint256);

    function getAvg60Price() external view returns (uint256);

    function isBullMarket() external view returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC20.sol";


/**
 * @title ERC20 interface that includes burn and mint methods.
 */
abstract contract IExpandedIERC20 is IERC20 {
    /**
     * @notice Burns a specific amount of the caller's tokens.
     * @dev Only burns the caller's tokens, so it is safe to leave this method permissionless.
     */
    function burn(uint256 value) external virtual;

    /**
     * @notice Mints tokens and adds them to the balance of the `to` address.
     * @dev This method should be permissioned to only allow designated parties to mint tokens.
     */
    function mint(address to, uint256 value) external virtual returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./utility/SyntheticToken.sol";
import "./interfaces/IExpandedIERC20.sol";
import "./utility/Lockable.sol";


/**
 * @title Factory for creating new mintable and burnable tokens.
 */

contract TokenFactory is Lockable {

    event TokenCreated(address indexed tokenAddress);

    /**
     * @notice Create a new token and return it to the caller.
     * @dev The caller will become the only minter and burner and the new owner capable of assigning the roles.
     * @param tokenName used to describe the new token.
     * @param tokenSymbol short ticker abbreviation of the name. Ideally < 5 chars.
     * @param tokenDecimals used to define the precision used in the token's numerical representation.
     * @return newToken an instance of the newly created token interface.
     */
    function createToken(
        string calldata tokenName,
        string calldata tokenSymbol,
        uint8 tokenDecimals
    ) external nonReentrant() returns (IExpandedIERC20 newToken) {
        SyntheticToken mintableToken = new SyntheticToken(tokenName, tokenSymbol, tokenDecimals);
        mintableToken.addMinter(msg.sender);
        mintableToken.addBurner(msg.sender);
        mintableToken.resetOwner(msg.sender);
        newToken = IExpandedIERC20(address(mintableToken));

        emit TokenCreated(address(newToken));

    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
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