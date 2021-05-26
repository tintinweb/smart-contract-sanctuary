// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "../../interface/IOneTokenV1.sol";
import "../../_openzeppelin/token/ERC20/SafeERC20.sol";
import "./OneTokenV1Base.sol";

contract OneTokenV1 is IOneTokenV1, OneTokenV1Base {

    using AddressSet for AddressSet.Set;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public override mintingFee; // defaults to 0%
    uint256 public override redemptionFee; // defaults to 0%

    /**
     @notice sum of userBalances for each collateral token are not counted in treasury valuations
     @dev token => liability
     */
    mapping(address => uint256) public liabilities;
  
    event Minted(address indexed sender, address indexed collateral, uint256 oneTokens, uint256 memberTokens, uint256 collateralTokens);
    event Redeemed(address indexed sender, address indexed collateral, uint256 amount);
    event NewMintingFee(address sender, uint256 fee);
    event NewRedemptionFee(address sender, uint256 fee);
    
    /// @dev there is no constructor for proxy deployment. Use init()

    /**
     @notice convert member tokens and collateral tokens into oneTokens. requires sufficient allowances for both tokens
     @dev takes the lessor of memberTokens allowance or the maximum allowed by the minting ratio and the balance in collateral
     @param collateralToken a registered ERC20 collateral token contract
     @param oneTokens exact number of oneTokens to receive
     */
    function mint(address collateralToken, uint256 oneTokens) external initialized override {
        require(collateralTokenSet.exists(collateralToken), "OTV1: offer a collateral token");
        require(oneTokens > 0, "OTV1: order must be > 0");
        
        // update collateral and memberToken oracles
        IOracle(assets[collateralToken].oracle).update(collateralToken);
        IOracle(assets[memberToken].oracle).update(memberToken);
        
        // update oneToken oracle and evaluate
        (uint256 mintingRatio, uint256 maxOrderVolume) = updateMintingRatio(collateralToken);

        // future mintmasters may return a maximum order volume to tamp down on possible manipulation
        require(oneTokens <= maxOrderVolume, "OTV1: order exceeds limit");

        // compute the member token value and collateral value requirement
        uint256 collateralUSDValue = oneTokens.mul(mintingRatio).div(PRECISION);
        uint256 memberTokensUSDValue = oneTokens.sub(collateralUSDValue);
        collateralUSDValue = collateralUSDValue.add(oneTokens.mul(mintingFee).div(PRECISION));

        // compute the member tokens required
        (uint256 memberTokensReq, /* volatility */) = IOracle(assets[memberToken].oracle).amountRequired(memberToken, memberTokensUSDValue);

        // check the memberToken allowance - the maximum we can draw from the user
        uint256 memberTokenAllowance = IERC20(memberToken).allowance(msg.sender, address(this));

        // increase collateral required if the memberToken allowance is too low
        if(memberTokensReq > memberTokenAllowance) {
            uint256 memberTokenRate = memberTokensUSDValue.mul(PRECISION).div(memberTokensReq);
            memberTokensReq = memberTokenAllowance;
            // re-evaluate the memberToken value and collateral value required using the oracle rate already obtained
            memberTokensUSDValue = memberTokenRate.mul(memberTokensReq).div(PRECISION);
            collateralUSDValue = oneTokens.sub(memberTokensUSDValue);
            collateralUSDValue = collateralUSDValue.add(oneTokens.mul(mintingFee).div(PRECISION));
        }

        require(IERC20(memberToken).balanceOf(msg.sender) >= memberTokensReq, "OTV1: NSF: member token");

        // compute actual collateral tokens required in case of imperfect collateral pegs
        // a pegged oracle can be used to reduce the cost of this step but it will not account for price differences
        (uint256 collateralTokensReq, /* volatility */) = IOracle(assets[collateralToken].oracle).amountRequired(collateralToken, collateralUSDValue);

        require(IERC20(collateralToken).balanceOf(msg.sender) >= collateralTokensReq, "OTV1: NSF: collateral token");
        require(collateralTokensReq > 0, "OTV1: order too small");

        // transfer tokens in
        IERC20(memberToken).safeTransferFrom(msg.sender, address(this), memberTokensReq);
        IERC20(collateralToken).safeTransferFrom(msg.sender, address(this), collateralTokensReq);
        
        // mint oneTokens
        _mint(msg.sender, oneTokens);

        emit Minted(msg.sender, collateralToken, oneTokens, memberTokensReq, collateralTokensReq);
    }

    /**
     @notice redeem oneTokens for collateral tokens at 1:1 - applies fee %
     @dev first grant allowances, then redeem. Consider infinite collateral allowance and a sufficient memberToken allowance. Updates ratio and triggers controller.
     @param collateral form of ERC20 stable token to receive
     @param amount oneTokens to redeem equals collateral tokens to receive
     */
    function redeem(address collateral, uint256 amount) external override {
        require(isCollateral(collateral), "OTV1: unknown collateral");
        require(amount > 0, "OTV1: amount must be > 0");
        require(balanceOf(msg.sender) >= amount, "OTV1: NSF: oneToken");
        IOracle co = IOracle(assets[collateral].oracle);
        co.update(collateral);

        // implied transfer approval and allowance
        _burn(msg.sender, amount);

        uint256 netUsd = amount.sub(amount.mul(redemptionFee).div(PRECISION));
        (uint256 netTokens, /* uint256 volatility */)  = co.amountRequired(collateral, netUsd);

        IERC20(collateral).safeTransfer(msg.sender, netTokens);
        emit Redeemed(msg.sender, collateral, amount);
        
        // updates the oneToken oracle price history
        updateMintingRatio(collateral);

        // periodic automated processes
        IController(controller).periodic();
    }

    /**
     @notice governance sets the adjustable fee
     @param fee fee, 18 decimals, e.g. 2% = 20000000000000000
     */
    function setMintingFee(uint256 fee) external onlyOwner override {
        require(fee <= PRECISION, "OTV1: fee must be <= 100%");
        mintingFee = fee;
        emit NewMintingFee(msg.sender, fee);
    }

    /**
     @notice governance sets the adjustable fee
     @param fee fee, 18 decimals, e.g. 2% = 20000000000000000
     */
    function setRedemptionFee(uint256 fee) external onlyOwner override {
        require(fee <= PRECISION, "OTV1: fee must be <= 100%");
        redemptionFee = fee;
        emit NewRedemptionFee(msg.sender, fee);
    }    

    /**
     @notice adjust the minting ratio
     @dev acceptable for gas-paying external actors to call this function
     @param collateralToken token to use for ratio calculation
     @param ratio minting ratio
     @param maxOrderVolume maximum order size
     */
    function updateMintingRatio(address collateralToken) public override returns(uint256 ratio, uint256 maxOrderVolume) {
        return IMintMaster(mintMaster).updateMintingRatio(collateralToken);
    }

    /**
     @notice read the minting ratio and maximum order volume prescribed by the mintMaster
     @param collateralToken token to use for ratio calculation
     @param ratio minting ratio
     @param maxOrderVolume maximum order size
     */
    function getMintingRatio(address collateralToken) external view override returns(uint256 ratio, uint256 maxOrderVolume) {
        return IMintMaster(mintMaster).getMintingRatio(collateralToken);
    }

    /**
     @notice read the vault balance and strategy balance of a given token
     @dev not restricted to registered assets
     @param token ERC20 asset to report
     @param vaultBalance tokens held in this vault
     @param strategyBalance tokens in assigned strategy
     */
    function getHoldings(address token) external view override returns(uint256 vaultBalance, uint256 strategyBalance) {   
        IERC20 t = IERC20(token);
        vaultBalance = t.balanceOf(address(this));
        Asset storage a = assets[token];
        if(a.strategy != NULL_ADDRESS) strategyBalance = t.balanceOf(a.strategy);
    } 
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

import "./IOneTokenV1Base.sol";

interface IOneTokenV1 is IOneTokenV1Base {

    function mintingFee() external view returns(uint);
    function redemptionFee() external view returns(uint);
    function mint(address collateral, uint oneTokens) external;
    function redeem(address collateral, uint amount) external;
    function setMintingFee(uint fee) external;
    function setRedemptionFee(uint fee) external;
    function updateMintingRatio(address collateralToken) external returns(uint ratio, uint maxOrderVolume);
    function getMintingRatio(address collateralToken) external view returns(uint ratio, uint maxOrderVolume);
    function getHoldings(address token) external view returns(uint vaultBalance, uint strategyBalance);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

import "../../common/ICHICommon.sol";
import "../../_openzeppelin/token/ERC20/SafeERC20.sol";
import "../../oz_modified/ICHIERC20Burnable.sol";
import "../../lib/AddressSet.sol";
import "../../interface/IOneTokenFactory.sol";
import "../../interface/IOneTokenV1Base.sol";
import "../../interface/IController.sol";
import "../../interface/IStrategy.sol";
import "../../interface/IMintMaster.sol";
import "../../interface/IOracle.sol";

contract OneTokenV1Base is IOneTokenV1Base, ICHICommon, ICHIERC20Burnable {

    using SafeERC20 for IERC20;
    using AddressSet for AddressSet.Set;

    bytes32 public constant override MODULE_TYPE = keccak256(abi.encodePacked("ICHI V1 OneToken Implementation"));

    address public override oneTokenFactory;
    address public override controller;
    address public override mintMaster;
    address public override memberToken;
    AddressSet.Set collateralTokenSet;
    AddressSet.Set otherTokenSet;

    struct Asset {
        address oracle;
        address strategy;
    }

    AddressSet.Set assetSet;
    mapping(address => Asset) public override assets;

    event Initialized(address sender, string name, string symbol, address controller, address mintMaster, address memberToken, address collateral);
    event ControllerChanged(address sender, address controller);
    event MintMasterChanged(address sender, address mintMaster, address oneTokenOracle);
    event StrategySet(address sender, address token, address strategy, uint256 allowance);
    event StrategyExecuted(address indexed sender, address indexed token, address indexed strategy);
    event StrategyRemoved(address sender, address token, address strategy);
    event StrategyClosed(address sender, address token, address strategy);
    event ToStrategy(address sender, address strategy, address token, uint256 amount);
    event FromStrategy(address sender, address strategy, address token, uint256 amount);
    event StrategyAllowanceIncreased(address sender, address token, address strategy, uint256 amount);
    event StrategyAllowanceDecreased(address sender, address token, address strategy, uint256 amount);
    event AssetAdded(address sender, address token, address oracle);
    event AssetRemoved(address sender, address token);
    event NewFactory(address sender, address factory);

    modifier onlyOwnerOrController {
        if(msg.sender != owner()) {
            require(msg.sender == controller, "OTV1B: not owner or controller");
        }
        _;
    }

    /**
     @notice initializes a proxied instance of the implementation
     @dev constructors are ineffective for proxy deployments
     @param name_ ERC20 name value
     @param symbol_ ERC20 symbol value
     @param oneTokenOracle_ a deployed, compatible oracle supporting the minimum interface
     @param controller_ a deployed, compatible controller supporting the minimum interface
     @param mintMaster_ a deployed, compatible mintMaster supporting the minimum interface
     @param memberToken_ a deployed, registered (in the factory) ERC20 token supporting the minimum interface
     @param collateral_ a deployed, registered (in the factory) usd-pegged ERC20 token supporting the minimum interface
     */
    function init(
        string memory name_,
        string memory symbol_,
        address oneTokenOracle_,
        address controller_,
        address mintMaster_,
        address memberToken_,
        address collateral_
    )
        external
        initializer
        override
    {
        // transfer oneToken governance to the deployer
        initOwnable();

        oneTokenFactory = msg.sender;
        initERC20(name_, symbol_); // decimals is always 18

        // no null properties
        require(bytes(name_).length > 0 && bytes(symbol_).length > 0, "OTV1B: name and symbol are RQD");

        // Confirm the modules are known and valid
        require(IOneTokenFactory(oneTokenFactory).isValidModuleType(oneTokenOracle_, ModuleType.Oracle), "OTV1B: unknown oracle");
        require(IOneTokenFactory(oneTokenFactory).isValidModuleType(controller_, ModuleType.Controller), "OTV1B: unknown controller");
        require(IOneTokenFactory(oneTokenFactory).isValidModuleType(mintMaster_, ModuleType.MintMaster), "OTV1B: unknown mint master");
        require(IOneTokenFactory(oneTokenFactory).isForeignToken(memberToken_), "OTV1B: unknown MEM token");
        require(IOneTokenFactory(oneTokenFactory).isCollateral(collateral_), "OTV1B: unknown collateral");

        // register the modules
        controller = controller_;
        mintMaster = mintMaster_;

        // register the member token
        memberToken = memberToken_;

        // register the first acceptable collateral and note the existance of the member token
        collateralTokenSet.insert(collateral_, "OTV1B: ERR inserting collateral");
        otherTokenSet.insert(memberToken_, "OTV1B: ERR inserting MEM token");
        assetSet.insert(collateral_, "OTV1B: ERR inserting collateral as asset");
        assetSet.insert(memberToken_, "OTV1B: ERR inserting MEM token as asset");

        // instantiate the memberToken and collateralToken records
        Asset storage mt = assets[memberToken_];
        Asset storage ct = assets[collateral_];

        // default to the first known oracles for the memberToken and collateralToken
        // change default oracle with remove/add asset

        mt.oracle = IOneTokenFactory(oneTokenFactory).foreignTokenOracleAtIndex(memberToken_, 0);
        ct.oracle = IOneTokenFactory(oneTokenFactory).foreignTokenOracleAtIndex(collateral_, 0);

        // let the modules initialize the context if they need to
        IController(controller_).init();
        IMintMaster(mintMaster_).init(oneTokenOracle_);
       
        // force the oracles to make observations
        IOracle(oneTokenOracle_).update(address(this));
        IOracle(mt.oracle).update(memberToken);
        IOracle(ct.oracle).update(collateral_);

        emit Initialized(msg.sender, name_, symbol_, controller_, mintMaster_, memberToken_, collateral_);
    }

    /**
     @notice governance can appoint a new controller with distinct internal logic
     @dev controllers support the periodic() function which should be called occasionally to send gas to the controller
     @param controller_ a deployed controller contract supporting the minimum interface and registered with the factory
     */
    function changeController(address controller_) external onlyOwner override {
        require(IOneTokenFactory(oneTokenFactory).isModule(controller_), "OTV1B: unregistered controller");
        require(IOneTokenFactory(oneTokenFactory).isValidModuleType(controller_, ModuleType.Controller), "OTV1B: unknown controller");
        IController(controller_).init();
        controller = controller_;
        emit ControllerChanged(msg.sender, controller_);
    }

    /**
     @notice change the mintMaster
     @dev controllers support the periodic() function which should be called occasionally to send gas to the controller
     @param mintMaster_ the new mintMaster implementation
     @param oneTokenOracle_ intialize the mintMaster with this oracle. Must be registed in the factory.
     */
    function changeMintMaster(address mintMaster_, address oneTokenOracle_) external onlyOwner override {
        require(IOneTokenFactory(oneTokenFactory).isModule(mintMaster_), "OTV1B: unregistered mint master");
        require(IOneTokenFactory(oneTokenFactory).isValidModuleType(mintMaster_, ModuleType.MintMaster), "OTV1B: unknown mint master");
        require(IOneTokenFactory(oneTokenFactory).isOracle(address(this), oneTokenOracle_), "OTV1B: unregistered oneToken oracle");
        IOracle(oneTokenOracle_).update(address(this));
        IMintMaster(mintMaster_).init(oneTokenOracle_);
        mintMaster = mintMaster_;
        emit MintMasterChanged(msg.sender, mintMaster_, oneTokenOracle_);
    }

    /**
     @notice governance can add an asset
     @dev asset inventory helps evaluate local holdings and enables strategy assignment
     @param token ERC20 token
     @param oracle oracle to use for usd valuation. Must be registered in the factory and associated with token.
     */
    function addAsset(address token, address oracle) external onlyOwner override {
        require(IOneTokenFactory(oneTokenFactory).isOracle(token, oracle), "OTV1B: unknown oracle or token");
        (bool isCollateral_, /* uint256 oracleCount */) = IOneTokenFactory(oneTokenFactory).foreignTokenInfo(token);
        Asset storage a = assets[token];
        a.oracle = oracle;
        IOracle(oracle).update(token);
        if(isCollateral_) {
            collateralTokenSet.insert(token, "OTV1B: collateral already exists");
        } else {
            otherTokenSet.insert(token, "OTV1B: token already exists");
        }
        assetSet.insert(token, "OTV1B: ERR inserting asset");
        emit AssetAdded(msg.sender, token, oracle);
    }

    /**
     @notice governance can remove an asset from treasury and collateral value accounting
     @dev does not destroy holdings, but holdings are not accounted for
     @param token ERC20 token
     */
    function removeAsset(address token) external onlyOwner override {
        (uint256 inVault, uint256 inStrategy) = balances(token);
        require(inVault == 0, "OTV1B: can't remove token with vault balance > 0");
        require(inStrategy == 0, "OTV1B: can't remove asset with strategy balance > 0");
        require(assetSet.exists(token), "OTV1B: unknown token");
        if(collateralTokenSet.exists(token)) collateralTokenSet.remove(token, "OTV1B: ERR removing collateral token");
        if(otherTokenSet.exists(token)) otherTokenSet.remove(token, "OTV1B: ERR removing MEM token");
        assetSet.remove(token, "OTV1B: ERR removing asset");
        delete assets[token];
        emit AssetRemoved(msg.sender, token);
    }

    /**
     @notice governance optionally assigns a strategy to an asset and sets a strategy allowance
     @dev strategy must be registered with the factory
     @param token ERC20 asset
     @param strategy deployed strategy contract that is registered with the factor
     @param allowance ERC20 allowance sets a limit on funds to transfer to the strategy
     */
    function setStrategy(address token, address strategy, uint256 allowance) external onlyOwner override {

        require(assetSet.exists(token), "OTV1B: unknown token");
        require(IOneTokenFactory(oneTokenFactory).isModule(strategy), "OTV1B: unknown strategy");
        require(IOneTokenFactory(oneTokenFactory).isValidModuleType(strategy, ModuleType.Strategy), "OTV1B: unknown strategy");
        require(IStrategy(strategy).oneToken() == address(this), "OTV1B: can't assign strategy that doesn't recognize this vault");
        require(IStrategy(strategy).owner() == owner(), "OTV1B: unknown strategy owner");

        // close the old strategy, may not be possible to recover all funds, e.g. locked tokens
        // the old strategy continues to respect oneToken goverancea and controller for manual token recovery

        Asset storage a = assets[token];
        closeStrategy(token);

        // initialize the new strategy
        IStrategy(strategy).init();
        IERC20(token).safeApprove(strategy, allowance);

        // appoint the new strategy
        a.strategy = strategy;
        emit StrategySet(msg.sender, token, strategy, allowance);
    }

    /**
     @notice governance can remove a strategy
     @dev closes the strategy and requires that all funds in the strategy are returned to the vault
     @param token the token strategy to remove. There are 0-1 strategys per asset
     */
    function removeStrategy(address token) external onlyOwner override {
        Asset storage a = assets[token];
        closeStrategy(token);
        address strategy = a.strategy;
        a.strategy = NULL_ADDRESS;
        emit StrategyRemoved(msg.sender, token, strategy);
    }

    /**
     @notice governance can close a strategy
     @dev strategy remains assigned the asset with allowance set to 0.
     @param token ERC20 asset with a strategy to close. 
     */
    function closeStrategy(address token) public override onlyOwnerOrController {
        require(assetSet.exists(token), "OTV1B:cs: unknown token");
        Asset storage a = assets[token];
        address oldStrategy = a.strategy;
        if(oldStrategy != NULL_ADDRESS) IERC20(token).safeApprove(oldStrategy, 0);
        emit StrategyClosed(msg.sender, token, oldStrategy);
    }

    /**
     @notice governance can execute a strategy to trigger innner logic within the strategy
     @dev normally used by the controller
     @param token the token strategy to execute
     */
    function executeStrategy(address token) external onlyOwnerOrController override {
        require(assetSet.exists(token), "OTV1B:es: unknown token");
        Asset storage a = assets[token];
        address strategy = a.strategy;
        IStrategy(strategy).execute();
        emit StrategyExecuted(msg.sender, token, strategy);
    }

    /**
     @notice governance can transfer assets from the vault to a strategy
     @dev works independently of strategy allowance
     @param strategy receiving address must match the assigned strategy
     @param token ERC20 asset
     @param amount amount to send
     */
    function toStrategy(address strategy, address token, uint256 amount) external onlyOwnerOrController {
        Asset storage a = assets[token];
        require(a.strategy == strategy, "OTV1B: not the token strategy");
        IERC20(token).safeTransfer(strategy, amount);
        emit ToStrategy(msg.sender, strategy, token, amount);
    }

    /**
     @notice governance can transfer assets from the strategy to this vault
     @param strategy receiving address must match the assigned strategy
     @param token ERC20 asset
     @param amount amount to draw from the strategy
     */
    function fromStrategy(address strategy, address token, uint256 amount) external onlyOwnerOrController {
        Asset storage a = assets[token];
        require(a.strategy == strategy, "OTV1B: not the token strategy");
        IStrategy(strategy).toVault(token, amount);
        emit FromStrategy(msg.sender, strategy, token, amount);
    }

    /**
     @notice governance can manage an allowance for a token strategy
     @dev adjusts the remaining allowance for automated transfers executed by the controller
     @param token ERC20 asset
     @param amount allowance increase
     */
    function increaseStrategyAllowance(address token, uint256 amount) external onlyOwnerOrController override {
        Asset storage a = assets[token];
        address strategy = a.strategy;
        require(a.strategy != NULL_ADDRESS, "OTV1B: no strategy");
        IERC20(token).safeIncreaseAllowance(strategy, amount);
        emit StrategyAllowanceIncreased(msg.sender, token, strategy, amount);
    }

    /**
     @notice governance can manage an allowance for a token strategy
     @dev adjusts the remaining allowance for automated transfers executed by the controller
     @param token ERC20 asset
     @param amount allowance decrease
     */    
    function decreaseStrategyAllowance(address token, uint256 amount) external onlyOwnerOrController override {
        Asset storage a = assets[token];
        address strategy = a.strategy;
        require(a.strategy != NULL_ADDRESS, "OTV1B: no strategy");
        IERC20(token).safeDecreaseAllowance(strategy, amount);
        emit StrategyAllowanceDecreased(msg.sender, token, strategy, amount);
    }

    /**
     @notice adopt a new factory
     @dev accomodates factory upgrades
     @param newFactory address of the new factory
     */
    function setFactory(address newFactory) external override onlyOwner {
        require(IOneTokenFactory(newFactory).MODULE_TYPE() == COMPONENT_FACTORY, "OTV1B: new factory doesn't emit factory fingerprint");
        oneTokenFactory = newFactory;
        emit NewFactory(msg.sender, newFactory);
    }

    /**
     * View functions
     */

    /**
     @notice returns the local balance and funds held in the assigned strategy, if any
     @param token to inspect
     */
    function balances(address token) public view override returns(uint256 inVault, uint256 inStrategy) {
        IERC20 asset = IERC20(token);
        inVault = asset.balanceOf(address(this));
        address strategy = assets[token].strategy;
        if(strategy != NULL_ADDRESS) inStrategy = asset.balanceOf(strategy);
    }

    /**point
     @notice returns the number of acceptable collateral token contracts
     */
    function collateralTokenCount() external view override returns(uint256) {
        return collateralTokenSet.count();
    }

    /**
     @notice returns the address of an ERC20 token collateral contract at the index
     @param index row to inspect
     */
    function collateralTokenAtIndex(uint256 index) external view override returns(address) {
        return collateralTokenSet.keyAtIndex(index);
    }

    /**
     @notice returns true if the token contract is recognized collateral
     @param token token to inspect
     */
    function isCollateral(address token) public view override returns(bool) {
        return collateralTokenSet.exists(token);
    }

    /**
     @notice returns the count of registered ERC20 asset contracts that not collateral
     */
    function otherTokenCount() external view override returns(uint256) {
        return otherTokenSet.count();
    }

    /**
     @notice returns the non-collateral token contract at the index
     @param index row to inspect
     */
    function otherTokenAtIndex(uint256 index) external view override returns(address) {
        return otherTokenSet.keyAtIndex(index);
    }

    /**
     @notice returns true if the token contract is registered and is not collateral
     @param token token to inspect
     */
    function isOtherToken(address token) external view override returns(bool) {
        return otherTokenSet.exists(token);
    }

    /**
     @notice returns the sum of collateral and non-collateral ERC20 token contracts
     */
    function assetCount() external view override returns(uint256) {
        return assetSet.count();
    }

    /**
     @notice returns the ERC20 contract address at the index
     @param index row to inspect
     */
    function assetAtIndex(uint256 index) external view override returns(address) {
        return assetSet.keyAtIndex(index);
    }

    /**
     @notice returns true if the token contract is a registered asset of either type
     @param token token to inspect
     */
    function isAsset(address token) external view override returns(bool) {
        return assetSet.exists(token);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "./IICHICommon.sol";
import "./IERC20Extended.sol";

interface IOneTokenV1Base is IICHICommon, IERC20 {
    
    function init(string memory name_, string memory symbol_, address oneTokenOracle_, address controller_,  address mintMaster_, address memberToken_, address collateral_) external;
    function changeController(address controller_) external;
    function changeMintMaster(address mintMaster_, address oneTokenOracle) external;
    function addAsset(address token, address oracle) external;
    function removeAsset(address token) external;
    function setStrategy(address token, address strategy, uint256 allowance) external;
    function executeStrategy(address token) external;
    function removeStrategy(address token) external;
    function closeStrategy(address token) external;
    function increaseStrategyAllowance(address token, uint256 amount) external;
    function decreaseStrategyAllowance(address token, uint256 amount) external;
    function setFactory(address newFactory) external;

    function MODULE_TYPE() external view returns(bytes32);
    function oneTokenFactory() external view returns(address);
    function controller() external view returns(address);
    function mintMaster() external view returns(address);
    function memberToken() external view returns(address);
    function assets(address) external view returns(address, address);
    function balances(address token) external view returns(uint256 inVault, uint256 inStrategy);
    function collateralTokenCount() external view returns(uint256);
    function collateralTokenAtIndex(uint256 index) external view returns(address);
    function isCollateral(address token) external view returns(bool);
    function otherTokenCount() external view  returns(uint256);
    function otherTokenAtIndex(uint256 index) external view returns(address); 
    function isOtherToken(address token) external view returns(bool);
    function assetCount() external view returns(uint256);
    function assetAtIndex(uint256 index) external view returns(address); 
    function isAsset(address token) external view returns(bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "./IICHIOwnable.sol";
import "./InterfaceCommon.sol";

interface IICHICommon is IICHIOwnable, InterfaceCommon {}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "../_openzeppelin/token/ERC20/IERC20.sol";

interface IERC20Extended is IERC20 {
    
    function decimals() external view returns(uint8);
    function symbol() external view returns(string memory);
    function name() external view returns(string memory);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

interface IICHIOwnable {
    
    function renounceOwnership() external;
    function transferOwnership(address newOwner) external;
    function owner() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

interface InterfaceCommon {

    enum ModuleType { Version, Controller, Strategy, MintMaster, Oracle }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "../oz_modified/ICHIOwnable.sol";
import "../oz_modified/ICHIInitializable.sol";
import "../interface/IERC20Extended.sol";
import "../interface/IICHICommon.sol";

contract ICHICommon is IICHICommon, ICHIOwnable, ICHIInitializable {

    uint256 constant PRECISION = 10 ** 18;
    uint256 constant INFINITE = uint256(0-1);
    address constant NULL_ADDRESS = address(0);
    
    // @dev internal fingerprints help prevent deployment-time governance errors

    bytes32 constant COMPONENT_CONTROLLER = keccak256(abi.encodePacked("ICHI V1 Controller"));
    bytes32 constant COMPONENT_VERSION = keccak256(abi.encodePacked("ICHI V1 OneToken Implementation"));
    bytes32 constant COMPONENT_STRATEGY = keccak256(abi.encodePacked("ICHI V1 Strategy Implementation"));
    bytes32 constant COMPONENT_MINTMASTER = keccak256(abi.encodePacked("ICHI V1 MintMaster Implementation"));
    bytes32 constant COMPONENT_ORACLE = keccak256(abi.encodePacked("ICHI V1 Oracle Implementation"));
    bytes32 constant COMPONENT_VOTERROLL = keccak256(abi.encodePacked("ICHI V1 VoterRoll Implementation"));
    bytes32 constant COMPONENT_FACTORY = keccak256(abi.encodePacked("ICHI OneToken Factory"));
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../_openzeppelin/utils/Context.sol";
import "./ICHIERC20.sol";

/**
 * @dev Uses the modified ERC20 with Initializer.
 */
contract ICHIERC20Burnable is ICHIERC20 {
    
    using SafeMath for uint256;

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ICHIERC20Burnable: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

/**
 * @notice Key sets with enumeration and delete. Uses mappings for random access
 * and existence checks and dynamic arrays for enumeration. Key uniqueness is enforced. 
 * @dev Sets are unordered. Delete operations reorder keys. All operations have a 
 * fixed gas cost at any scale, O(1). 
 */

library AddressSet {
    
    struct Set {
        mapping(address => uint256) keyPointers;
        address[] keyList;
    }

    /**
     @notice insert a key. 
     @dev duplicate keys are not permitted.
     @param self storage pointer to a Set. 
     @param key value to insert.
     */    
    function insert(Set storage self, address key, string memory errorMessage) internal {
        require(!exists(self, key), errorMessage);
        self.keyList.push(key);
        self.keyPointers[key] = self.keyList.length-1;
    }

    /**
     @notice remove a key.
     @dev key to remove must exist. 
     @param self storage pointer to a Set.
     @param key value to remove.
     */    
    function remove(Set storage self, address key, string memory errorMessage) internal {
        require(exists(self, key), errorMessage);
        uint256 last = count(self) - 1;
        uint256 rowToReplace = self.keyPointers[key];
        address keyToMove = self.keyList[last];
        self.keyPointers[keyToMove] = rowToReplace;
        self.keyList[rowToReplace] = keyToMove;
        delete self.keyPointers[key];
        self.keyList.pop();
    }

    /**
     @notice count the keys.
     @param self storage pointer to a Set. 
     */       
    function count(Set storage self) internal view returns(uint256) {
        return(self.keyList.length);
    }

    /**
     @notice check if a key is in the Set.
     @param self storage pointer to a Set.
     @param key value to check. Version
     @return bool true: Set member, false: not a Set member.
     */  
    function exists(Set storage self, address key) internal view returns(bool) {
        if(self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }

    /**
     @notice fetch a key by row (enumerate).
     @param self storage pointer to a Set.
     @param index row to enumerate. Must be < count() - 1.
     */      
    function keyAtIndex(Set storage self, uint256 index) internal view returns(address) {
        return self.keyList[index];
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

import "./InterfaceCommon.sol";

interface IOneTokenFactory is InterfaceCommon {

    function oneTokenProxyAdmins(address) external returns(address);
    function deployOneTokenProxy(
        string memory name,
        string memory symbol,
        address governance, 
        address version,
        address controller,
        address mintMaster,              
        address memberToken, 
        address collateral,
        address oneTokenOracle
    ) 
        external 
        returns(address newOneTokenProxy, address proxyAdmin);

    function admitModule(address module, ModuleType moduleType, string memory name, string memory url) external;
    function updateModule(address module, string memory name, string memory url) external;
    function removeModule(address module) external;

    function admitForeignToken(address foreignToken, bool collateral, address oracle) external;
    function updateForeignToken(address foreignToken, bool collateral) external;
    function removeForeignToken(address foreignToken) external;

    function assignOracle(address foreignToken, address oracle) external;
    function removeOracle(address foreignToken, address oracle) external; 

    /**
     * View functions
     */
    
    function MODULE_TYPE() external view returns(bytes32);

    function oneTokenCount() external view returns(uint256);
    function oneTokenAtIndex(uint256 index) external view returns(address);
    function isOneToken(address oneToken) external view returns(bool);
 
    // modules

    function moduleCount() external view returns(uint256);
    function moduleAtIndex(uint256 index) external view returns(address module);
    function isModule(address module) external view returns(bool);
    function isValidModuleType(address module, ModuleType moduleType) external view returns(bool);

    // foreign tokens

    function foreignTokenCount() external view returns(uint256);
    function foreignTokenAtIndex(uint256 index) external view returns(address);
    function foreignTokenInfo(address foreignToken) external view returns(bool collateral, uint256 oracleCount);
    function foreignTokenOracleCount(address foreignToken) external view returns(uint256);
    function foreignTokenOracleAtIndex(address foreignToken, uint256 index) external view returns(address);
    function isOracle(address foreignToken, address oracle) external view returns(bool);
    function isForeignToken(address foreignToken) external view returns(bool);
    function isCollateral(address foreignToken) external view returns(bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

interface IController {
    
    function oneTokenFactory() external returns(address);
    function description() external returns(string memory);
    function init() external;
    function periodic() external;
    function MODULE_TYPE() external view returns(bytes32);    
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "./IModule.sol";

interface IStrategy is IModule {
    
    function init() external;
    function execute() external;
    function setAllowance(address token, uint256 amount) external;
    function toVault(address token, uint256 amount) external;
    function fromVault(address token, uint256 amount) external;
    function closeAllPositions() external returns(bool);
    function closePositions(address token) external returns(bool success);
    function oneToken() external view returns(address);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "./IModule.sol";

interface IMintMaster is IModule {
    
    function oneTokenOracles(address) external view returns(address);
    function init(address oneTokenOracle) external;
    function updateMintingRatio(address collateralToken) external returns(uint256 ratio, uint256 maxOrderVolume);
    function getMintingRatio(address collateral) external view returns(uint256 ratio, uint256 maxOrderVolume);
    function getMintingRatio2(address oneToken, address collateralToken) external view returns(uint256 ratio, uint256 maxOrderVolume);  
    function getMintingRatio4(address oneToken, address oneTokenOracle, address collateralToken, address collateralOracle) external view returns(uint256 ratio, uint256 maxOrderVolume); 
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "./IModule.sol";

interface IOracle is IModule {

    function init(address baseToken) external;
    function update(address token) external;
    function indexToken() external view returns(address);

    /**
     @param token ERC20 token
     @param amountTokens quantity, token native precision
     @param amountUsd US dollar equivalent, precision 18
     @param volatility metric for future use-cases
     */
    function read(address token, uint amountTokens) external view returns(uint amountUsd, uint volatility);

    /**
     @param token ERC20 token
     @param amountTokens token quantity, token native precision
     @param amountUsd US dollar equivalent, precision 18
     @param volatility metric for future use-cases
     */    
    function amountRequired(address token, uint amountUsd) external view returns(uint amountTokens, uint volatility);

    /**
     @notice converts normalized precision-18 amounts to token native precision amounts, truncates low-order values
     @param token ERC20 token contract
     @param amountNormal quantity, precision 18
     @param amountTokens quantity scaled to token precision
     */    
    function normalizedToTokens(address token, uint amountNormal) external view returns(uint amountTokens);

    /**
     @notice converts token native precision amounts to normalized precision-18 amounts
     @param token ERC20 token contract
     @param amountNormal quantity, precision 18
     @param amountTokens quantity scaled to token precision
     */  
    function tokensToNormalized(address token, uint amountTokens) external view returns(uint amountNormal);
}

// SPDX-License-Identifier: MIT

/**
 * @dev Constructor visibility has been removed from the original.
 * _transferOwnership() has been added to support proxied deployments.
 * Abstract tag removed from contract block.
 * Added interface inheritance and override modifiers.
 * Changed contract identifier in require error messages.
 */

pragma solidity >=0.6.0 <0.8.0;

import "../_openzeppelin/utils/Context.sol";
import "../interface/IICHIOwnable.sol";
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
contract ICHIOwnable is IICHIOwnable, Context {
    
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
     
    modifier onlyOwner() {
        require(owner() == _msgSender(), "ICHIOwnable: caller is not the owner");
        _;
    }    

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     * Ineffective for proxied deployed. Use initOwnable.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     @dev initialize proxied deployment
     */
    function initOwnable() internal {
        require(owner() == address(0), "ICHIOwnable: already initialized");
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual override returns (address) {
        return _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual override onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */

    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev be sure to call this in the initialization stage of proxied deployment or owner will not be set
     */

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "ICHIOwnable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "../_openzeppelin/utils/Address.sol";

contract ICHIInitializable {

    bool private _initialized;
    bool private _initializing;

    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "ICHIInitializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    modifier initialized {
        require(_initialized, "ICHIInitializable: contract is not initialized");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
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

/// @dev removed constructor visibility and relocated the file
/// @dev added initERC20 for proxied deployments

pragma solidity >=0.6.0 <0.8.0;

import "../_openzeppelin/utils/Context.sol";
import "../_openzeppelin/token/ERC20/IERC20.sol";
import "../_openzeppelin/math/SafeMath.sol";
import "./ICHIInitializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
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
contract ICHIERC20 is IERC20, Context, ICHIInitializable {
    using SafeMath for uint256;

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

    /**
     * @dev this constructor is ineffective in proxy deployment. Use init().
     */

    /*
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }
    */

    function initERC20(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ICHIERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ICHIERC20: decreased allowance below zero"));
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
        require(sender != address(0), "ICHIERC20: transfer from the zero address");
        require(recipient != address(0), "ICHIERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ICHIERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ICHIERC20: mint to the zero address");

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
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ICHIERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ICHIERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
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
        require(owner != address(0), "ICHIERC20: approve from the zero address");
        require(spender != address(0), "ICHIERC20: approve to the zero address");

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
    function _setupDecimals(uint8 decimals_) internal virtual {
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
    function _beforeTokenTransfer(address /* from */, address /* to */, uint256 /* amount */) internal virtual { }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "./IICHICommon.sol";
import "./InterfaceCommon.sol";

interface IModule is IICHICommon { 
       
    function oneTokenFactory() external view returns(address);
    function updateDescription(string memory description) external;
    function moduleDescription() external view returns(string memory);
    function MODULE_TYPE() external view returns(bytes32);
    function moduleType() external view returns(ModuleType);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}