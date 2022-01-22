// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IERC20.sol";
import "./interfaces/SafeERC20.sol";
import "./interfaces/IERC20Metadata.sol";
import "./interfaces/IUniswapRouter.sol";
import "./interfaces/IFoundry.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/ITreasury.sol";

contract Treasury is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public oracleDollar;
    address public oracleShare;
    address public oracleGovToken;
    address public oracleCollateral;

    address public wcoin;
    address public governanceToken;
    address public dollar;
    address public share;
    address public collateral;
    bool public migrated = false;

    // pools
    address[] public poolsArray;
    mapping(address => bool) public pools;

    // Constants for various precisions
    uint private constant PRICE_PRECISION = 1e6;
    uint private constant RATIO_PRECISION = 1e6;
    uint private constant COLLATERAL_RATIO_MAX = 1e6;

    // fees
    uint public redemptionFee = 4000; // 6 decimals of precision
    uint public mintingFee    = 3000; // 6 decimals of precision

    // collateral_ratio
    uint public lastRefreshCollateralRatio;
    uint public targetCollateralRatio    = 1000000; // = 100% - fully collateralized at start; // 6 decimals of precision
    uint public effectiveCollateralRatio = 1000000; // = 100% - fully collateralized at start; // 6 decimals of precision
    uint public refreshCooldown = 1 hours; // Refresh cooldown period is set to 1h at genesis; // Seconds to wait before being able to run refreshCollateralRatio() again
    uint public ratioStep = 2500; // Amount to change the collateralization ratio by upon refreshCollateralRatio() // = 0.25% at 6 decimals of precision
    uint public priceBand = 5000; // The bound above and below the price target at which the Collateral ratio is allowed to drop
    uint public govTokenValueForDiscount = 1000; //1000$ in governance tokens
    bool public collateralRatioPaused = true; // during bootstraping phase, collateral_ratio will be fixed at 100%

    // rebalance
    address public rebalancing_pool;
    address public rebalancing_pool_collateral;
    uint public rebalanceCooldown = 12 hours; //bayback and recolaterize restriction
    uint public last_rebalance_timestamp;

    // agoDex
    address public router;

    // foundry
    address public foundry;
    uint public collateralToAllocatePercentage = 50000; // 5% per epoch
    uint public lastEpochTime;
    uint public epochDuration = 12 hours;
    uint public epoch = 0;

    /* ========== MODIFIERS ========== */
    modifier withOracleUpdates() {
        if (oracleDollar != address(0)) IOracle(oracleDollar).updateIfRequired();
        if (oracleShare != address(0)) IOracle(oracleShare).updateIfRequired();
        if (oracleGovToken != address(0)) IOracle(oracleGovToken).updateIfRequired();
        _;
    }

    modifier notMigrated() {
        require(migrated == false, "migrated");
        _;
    }

    modifier hasRebalancePool() {
        require(rebalancing_pool != address(0), "!rebalancingPool");
        require(rebalancing_pool_collateral != address(0), "!rebalancingPoolCollateral");
        _;
    }

    modifier usingRebalanceCooldown() {
        uint _blockTimestamp = block.timestamp;
        require( _blockTimestamp - last_rebalance_timestamp >= rebalanceCooldown, "<rebalanceCooldown");
        _;
        last_rebalance_timestamp = _blockTimestamp;
    }

    modifier checkEpoch() {
        uint _nextEpochPoint = nextEpochPoint();
        require(block.timestamp >= _nextEpochPoint, "Treasury: not opened yet");
        _;
        lastEpochTime = _nextEpochPoint;
        epoch++;
    }

    modifier nonZeroAddress(address addr) {
        require(addr != address(0), "received zero address");
        _;
    }

    /* ========== EVENTS ============= */
    event BoughtBack(
        uint collateral_value,
        uint collateral_amount,
        uint output_share_amount
    );
    event Recollateralized(
        uint share_amount,
        uint output_collateral_amount,
        uint output_collateral_value
    );

    constructor() {
        lastEpochTime = block.timestamp;
    }

    /*=========== VIEWS ===========*/
    function dollarPrice() public view returns (uint) {
        return IOracle(oracleDollar).consult();
    }

    function sharePrice() public view returns (uint) {
        return IOracle(oracleShare).consult();
    }

    function nextEpochPoint() public view returns (uint) {
        return lastEpochTime + epochDuration;
    }

    function redemption_fee_adjusted(address _user) public view returns (uint){
        if (governanceToken == address(0)) return redemptionFee;
        return IERC20(governanceToken).balanceOf(_user) >= discount_requirenment() ? redemptionFee / 2 : redemptionFee;
    }

    function discount_requirenment() public view returns (uint) {
        uint govTokenPrice = IOracle(oracleGovToken).consult(); // 3 *1e6
        if (govTokenPrice == 0) return 1;
        uint decimals = IERC20Metadata(governanceToken).decimals();//18
        return govTokenValueForDiscount * 10**decimals * PRICE_PRECISION / govTokenPrice;    
    }

    function info(address user) external view returns (
        uint _dollarPrice,
        uint _sharePrice,
        uint _targetCollateralRatio,
        uint _effectiveCollateralRatio,
        uint _globalCollateralValue,
        uint _mintingFee,
        uint _redemptionFeeAdjusted
    ){
        _dollarPrice = dollarPrice();
        _sharePrice = sharePrice();
        _targetCollateralRatio = targetCollateralRatio;
        _effectiveCollateralRatio = effectiveCollateralRatio;
        _globalCollateralValue = globalCollateralValue();
        _mintingFee = mintingFee;
        _redemptionFeeAdjusted = redemption_fee_adjusted(user); 
    }

    function epochInfo() external view returns (
        uint _epochNumber,
        uint _nextEpochTimestamp,
        uint _epochDuration,
        uint _allocatePercentage,
        uint _lastEpochTime
    ){
        _epochNumber = epoch;
        _nextEpochTimestamp = nextEpochPoint();
        _epochDuration = epochDuration;
        _allocatePercentage = collateralToAllocatePercentage;
        _lastEpochTime = lastEpochTime;
    }

    function hasPool(address _poolAddress) external view returns (bool) {
        return pools[_poolAddress] == true;
    }

    // Iterate through all pools and calculate all value of collateral in all pools globally
    function globalCollateralValue() public view returns (uint) {
        uint totalCollateralValue = 0;
        for (uint i = 0; i < poolsArray.length; i++) {
            if (poolsArray[i] != address(0)) {
                totalCollateralValue += IPool(poolsArray[i]).collateralDollarBalance();
            }
        }
        return totalCollateralValue;
        //TODO make single pool
    }

    function calcEffectiveCollateralRatio() public view returns (uint) {
        uint totalCollateralValue = globalCollateralValue();
        uint totalDollarValue     = IERC20(dollar).totalSupply() * dollarPrice() / PRICE_PRECISION; 
        uint ecr                  = totalCollateralValue * PRICE_PRECISION / totalDollarValue;
        return ecr > COLLATERAL_RATIO_MAX ? COLLATERAL_RATIO_MAX : ecr;
    }

    function refreshCollateralRatio() public withOracleUpdates {
        require(collateralRatioPaused == false, "Collateral Ratio has been paused");
        require(block.timestamp - lastRefreshCollateralRatio >= refreshCooldown, "Must wait for the refresh cooldown since last refresh");

        uint dollarPriceCurrent = dollarPrice();
        uint priceTarget = IOracle(oracleCollateral).consult();

        if (dollarPriceCurrent > priceTarget + priceBand) {
            targetCollateralRatio = targetCollateralRatio <= ratioStep ? 0 : targetCollateralRatio - ratioStep;
        } else if (dollarPriceCurrent < priceTarget - priceBand) {
            targetCollateralRatio = targetCollateralRatio + ratioStep >= COLLATERAL_RATIO_MAX ? COLLATERAL_RATIO_MAX : targetCollateralRatio + ratioStep;         
        }

        effectiveCollateralRatio = calcEffectiveCollateralRatio();
        lastRefreshCollateralRatio = block.timestamp;
    }

    // Check if the protocol is over- or under-collateralized, by how much
    function calcCollateralBalance() public view returns(uint collateralValue, bool exceeded){
        uint totalCollateralValue = globalCollateralValue();
        uint targetCollateralAmount = IERC20(dollar).totalSupply() * targetCollateralRatio / RATIO_PRECISION;
        uint targetCollateralValue = targetCollateralAmount * IPool(rebalancing_pool).getCollateralPrice() / PRICE_PRECISION;
        if (totalCollateralValue > targetCollateralValue) {
            collateralValue = totalCollateralValue - targetCollateralValue;
            exceeded = true;
        } else {
            collateralValue = targetCollateralValue - totalCollateralValue;
            exceeded = false;
        }
    }

    /* -========= INTERNAL FUNCTIONS ============ */

    // SWAP tokens using dex
    function _swap(
        address _input_token,
        uint _input_amount,
        uint _min_output_amount
    ) internal returns (uint) {
        require(
            (_input_token == collateral || _input_token == share) &&
            router != address(0) &&
            share != address(0) &&
            wcoin != address(0) &&
            collateral != address(0),
            "badTokenReceivedForSwap"
        );
        if (_input_amount == 0) return 0;
        address[] memory _path = new address[](3);
        if (_input_token == share) {
            _path[0] = share;
            _path[1] = wcoin;
            _path[2] = collateral;
        } else if (_input_token == collateral) {
            _path[0] = collateral;
            _path[1] = wcoin;
            _path[2] = share;
        }

        IERC20(_input_token).safeApprove(router, 0);
        IERC20(_input_token).safeApprove(router, _input_amount);
        uint[] memory out_amounts = IUniswapRouter(router).swapExactTokensForTokens(
            _input_amount,
            _min_output_amount,
            _path,
            address(this),
            block.timestamp + 1 hours
        );
        return out_amounts[out_amounts.length - 1];
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    // Add new Pool
    function addPool(address _poolAddress) public onlyOwner notMigrated {
        require(pools[_poolAddress] == false, "poolExisted");
        pools[_poolAddress] = true;
        poolsArray.push(_poolAddress);
    }

    // Remove a pool
    function removePool(address _poolAddress) public onlyOwner notMigrated {
        require(rebalancing_pool != _poolAddress, "Cant`t delete active rebalance pool");
        require(pools[_poolAddress] == true, "!pool");
        delete pools[_poolAddress];
        for (uint i = 0; i < poolsArray.length; i++) {
            if (poolsArray[i] == _poolAddress) {
                poolsArray[i] = address(0);
                break;
            }
        }
    }

    function buyback(uint _collateral_value, uint _min_share_amount)
        external
        onlyOwner
        withOracleUpdates
        notMigrated
        hasRebalancePool
        usingRebalanceCooldown
    {
        (uint excessCollateralValue, bool exceeded) = calcCollateralBalance();
        require(exceeded && excessCollateralValue > 0, "!exceeded");
        require( _collateral_value > 0 &&  _collateral_value < excessCollateralValue, "invalidCollateralAmount");
        uint _collateral_price = IPool(rebalancing_pool).getCollateralPrice(); 
        uint _collateral_amount_sell = (_collateral_value * PRICE_PRECISION) / _collateral_price;
           
        require( IERC20(rebalancing_pool_collateral).balanceOf(rebalancing_pool) > _collateral_amount_sell,"insufficentPoolBalance");

        IPool(rebalancing_pool).transferCollateralToTreasury(_collateral_amount_sell);

        uint out_share_amount = _swap(
            rebalancing_pool_collateral,
            _collateral_amount_sell,
            _min_share_amount
        );

        emit BoughtBack(
            _collateral_value,
            _collateral_amount_sell,
            out_share_amount
        );
    }

    function recollateralize(uint _shareAmount, uint _minimumCollateralAmount)
        external
        onlyOwner
        withOracleUpdates
        notMigrated
        hasRebalancePool
        usingRebalanceCooldown
    {
        (uint deficitOfCollateral, bool exceeded) = calcCollateralBalance();
        require( !exceeded && deficitOfCollateral > 0, "exceeded");
        require( _minimumCollateralAmount <= deficitOfCollateral, ">deficit");
        require( _shareAmount <= IERC20(share).balanceOf(address(this)), ">shareBalance");

        uint outCollateralAmount = _swap(share, _shareAmount, _minimumCollateralAmount);
        uint collateralBalance = IERC20(rebalancing_pool_collateral).balanceOf(address(this));
            
        if (collateralBalance > 0) {
            IERC20(rebalancing_pool_collateral).safeTransfer(rebalancing_pool, collateralBalance); 
        }

        uint collateralPrice = IPool(rebalancing_pool).getCollateralPrice();
        uint outCollateralValue = outCollateralAmount * collateralPrice / PRICE_PRECISION;

        emit Recollateralized(_shareAmount, outCollateralAmount, outCollateralValue);
    }

    function allocateSeigniorage() external onlyOwner withOracleUpdates notMigrated nonReentrant checkEpoch{
        require(!migrated, "Treasury: migrated");
        (uint excessCollateralValue, bool exceeded) = calcCollateralBalance();
        require(exceeded && excessCollateralValue > 0, "!exceeded");
        uint _collateral_price = IPool(rebalancing_pool).getCollateralPrice();
        uint missing_decimals = IPool(rebalancing_pool).getMissing_decimals();   
        uint collateralAmountExceeded = (excessCollateralValue * PRICE_PRECISION / _collateral_price) / (10**missing_decimals);
        uint _collateral_amount_allocate = collateralAmountExceeded * collateralToAllocatePercentage / COLLATERAL_RATIO_MAX;
        IPool(rebalancing_pool).transferCollateralToTreasury(_collateral_amount_allocate);

        IERC20(rebalancing_pool_collateral).safeApprove(foundry, 0);
        IERC20(rebalancing_pool_collateral).safeApprove(foundry, _collateral_amount_allocate);

        IFoundry(foundry).allocateSeigniorage(_collateral_amount_allocate);
    }

    function migrate(address _new_treasury) external onlyOwner notMigrated {
        migrated = true;
        uint _share_balance = IERC20(share).balanceOf(address(this));
        if (_share_balance > 0) {
            IERC20(share).safeTransfer(_new_treasury, _share_balance);
        }
        if (rebalancing_pool_collateral != address(0)) {
            uint collateralBalance = IERC20(rebalancing_pool_collateral).balanceOf(address(this));

            if (collateralBalance > 0) {
                IERC20(rebalancing_pool_collateral).safeTransfer(_new_treasury, collateralBalance);
            }
        }
    }

    //setters
    function setProtocolReferences(
        address _router,
        address _foundry,
        address _governanceToken,
        address _wcoin,
        address _collateral,
        address _share,
        address _dollar
    ) public onlyOwner {
        router          = _router;
        foundry         = _foundry;
        governanceToken = _governanceToken;
        wcoin           = _wcoin;
        collateral      = _collateral;
        share           = _share;
        dollar          = _dollar;
    }

    function setProtocolParams(
        uint _redemptionFee, 
        uint _mintingFee,
        uint _ratioStep,
        uint _refreshCooldown,
        uint _priceBand,
        uint _collateralToAllocatePercentage,
        uint _govTokenValueForDiscount,
        uint _epochDuration,
        uint _rebalanceCooldown
    ) public onlyOwner {
        require(_redemptionFee < PRICE_PRECISION && _mintingFee < PRICE_PRECISION, "Treasury: bad fee");
        require(_epochDuration > 0, "Treasury: epoch duration must be > 0");
        require(_rebalanceCooldown > 0, "Treasury: RebalanceCooldown duration must be > 0");

        redemptionFee   = _redemptionFee;
        mintingFee      = _mintingFee;
        ratioStep       = _ratioStep;
        refreshCooldown = _refreshCooldown;
        priceBand       = _priceBand;
        collateralToAllocatePercentage = _collateralToAllocatePercentage;
        govTokenValueForDiscount = _govTokenValueForDiscount;
        epochDuration   = _epochDuration;
        rebalanceCooldown = _rebalanceCooldown;
    }

    function setProtocolOracles(
        address _oracleDollar,
        address _oracleShare,
        address _oracleGovToken,
        address _oracleCollateral
    ) public onlyOwner {
        oracleDollar     = _oracleDollar;
        oracleShare      = _oracleShare;
        oracleGovToken   = _oracleGovToken;
        oracleCollateral = _oracleCollateral;
    }

    function pauseCollateralRatio() public onlyOwner {
        collateralRatioPaused = !collateralRatioPaused;
    }

    function updateOracles() public withOracleUpdates {
        /*empty, used only for modifier*/
    }

    function setRebalancePool(address _rebalance_pool) public onlyOwner {
        require(pools[_rebalance_pool], "!pool");
        require(IPool(_rebalance_pool).getCollateralToken() != address(0), "!poolCollateralToken");
        rebalancing_pool = _rebalance_pool;
        rebalancing_pool_collateral = IPool(_rebalance_pool).getCollateralToken();
    }//TODO remove on pool simplify

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IERC20Metadata is IERC20 {
    function decimals() external view returns (uint8);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IUniswapRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IFoundry {
    function balanceOf(address _director) external view returns (uint256);

    function earned(address _director) external view returns (uint256);

    function canWithdraw(address _director) external view returns (bool);

    function canClaimReward(address _director) external view returns (bool);

    function epoch() external view returns (uint256);

    function nextEpochPoint() external view returns (uint256);

    function getDollarPrice() external view returns (uint256);

    function setOperator(address _operator) external;

    function setLockUp(
        uint256 _withdrawLockupEpochs,
        uint256 _rewardLockupEpochs
    ) external;

    function stake(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function exit() external;

    function claimReward() external;

    function allocateSeigniorage(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IPool {
    function collateralDollarBalance() external view returns (uint256);

    function migrate(address _new_pool) external;

    function transferCollateralToTreasury(uint256 amount) external;

    function getCollateralPrice() external view returns (uint256);

    function getCollateralToken() external view returns (address);

    function getMissing_decimals() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IOracle {
    function consult() external view returns (uint256);

    function updateIfRequired() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IEpoch.sol";

interface ITreasury is IEpoch {
    function hasPool(address _address) external view returns (bool);

    function info(address _caller)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function epochInfo()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function updateOracles() external;

    function dollarPrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
pragma solidity 0.8.4;

interface IEpoch {
    function epoch() external view returns (uint256);

    function nextEpochPoint() external view returns (uint256);
}