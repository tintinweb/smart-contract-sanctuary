// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./interfaces/IUniswapRouter.sol";
import "./interfaces/IFoundry.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/ITreasury.sol";

contract Treasury is ITreasury, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public oracleDollar;//custom token oracle
    address public oracleShare;//custom token oracle
    address public oracleGovToken;//custom token oracle

    address public dollar;
    address public share;
    address public governanceToken;
    address public wcoin;
    address public collateral;
    address public strategist;
    bool public migrated = false;

    // pools
    address[] public pools_array;
    mapping(address => bool) public pools;

    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e6;
    uint256 private constant RATIO_PRECISION = 1e6;

    // fees
    uint256 public redemption_fee = 4000; // 6 decimals of precision
    uint256 public minting_fee = 3000; // 6 decimals of precision

    // collateral_ratio
    uint256 public last_refresh_cr_timestamp;
    uint256 public target_collateral_ratio = 1000000; // = 100% - fully collateralized at start; // 6 decimals of precision
    uint256 public effective_collateral_ratio = 1000000; // = 100% - fully collateralized at start; // 6 decimals of precision
    uint256 public refresh_cooldown = 600; // Refresh cooldown period is set to 10min at genesis; // Seconds to wait before being able to run refreshCollateralRatio() again
    uint256 public ratio_step = 2500; // Amount to change the collateralization ratio by upon refreshCollateralRatio() // = 0.25% at 6 decimals of precision
    uint256 public price_target = 1000000; // = $1. (6 decimals of precision). Collateral ratio will adjust according to the $1 price target at genesis; // The price of dollar at which the collateral ratio will respond to; this value is only used for the collateral ratio mechanism and not for minting and redeeming which are hardcoded at $1
    uint256 public price_band = 5000; // The bound above and below the price target at which the Collateral ratio is allowed to drop
    uint256 public gov_token_value_for_discount = 1000;//1000$ in governance tokens
    uint256 private constant COLLATERAL_RATIO_MAX = 1e6;
    bool public collateral_ratio_paused = true; // during bootstraping phase, collateral_ratio will be fixed at 100%

    // rebalance
    address public rebalancing_pool;
    address public rebalancing_pool_collateral;
    uint256 public rebalance_cooldown = 12 hours;
    uint256 public last_rebalance_timestamp;

    // uniswap
    address public uniswap_router;

    // foundry
    uint256 public startTime;
    address public foundry;
    uint256 public excess_collateral_distributed_ratio = 50000; // 5% per epoch
    uint256 public lastEpochTime;
    uint256 public epoch_length;
    uint256 private _epoch = 0;


    /* ========== MODIFIERS ========== */
    modifier withOracleUpdates(){
        if (oracleDollar != address(0)) IOracle(oracleDollar).updateIfRequired();//custom token oracle
        if (oracleShare != address(0)) IOracle(oracleShare).updateIfRequired();//custom token oracle
        if (oracleGovToken != address(0)) IOracle(oracleGovToken).updateIfRequired();//custom token oracle
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

    modifier checkRebalanceCooldown() {
        uint256 _blockTimestamp = block.timestamp;
        require(_blockTimestamp - last_rebalance_timestamp >= rebalance_cooldown, "<rebalance_cooldown");
        _;
        last_rebalance_timestamp = _blockTimestamp;
    }

    modifier checkEpoch {
        uint256 _nextEpochPoint = nextEpochPoint();
        require(block.timestamp >= _nextEpochPoint, "Treasury: not opened yet");
        _;
        lastEpochTime = _nextEpochPoint;
        _epoch = _epoch + 1;
    }

    modifier onlyStrategist{
        require(msg.sender == strategist, "!strategist");
        _;
    }
    
    modifier nonZeroAddress(address addr){
        require(addr != address(0), "received zero address");
        _;
    }


    /* ========== EVENTS ============= */
    event BoughtBack(uint256 collateral_value, uint256 collateral_amount, uint256 output_share_amount);
    event Recollateralized(uint256 share_amount, uint256 output_collateral_amount, uint256 output_collateral_value);
    event New_GovTokenValueForDiscount(uint256 value);
    event New_RedemptionFee(uint256 _redemption_fee);
    event New_MintingFee(uint256 _minting_fee);
    event New_RatioStep(uint256 _ratio_step);
    event New_PriceTarget(uint256 _price_target);
    event New_RefreshCooldown(uint256 _refresh_cooldown);
    event New_PriceBand(uint256 _price_band);
    event New_OracleDollar(address _oracle);
    event New_OracleShare(address _oracle);
    event New_OracleGovToken(address _oracle);
    event New_Foundry(address _foundry);
    event New_EpochLength(uint256 _epoch_length);
    event New_RebalanceCooldown(uint256 _cooldown);
    event New_ExcessDistributionRatio(uint256 _ratio);
    event New_Strategist(address _strategist);
    event New_Tokens(address _uniswap_router,address _governanceToken,address _wcoin,address _collateral,address _share,address _dollar);
    event New_RebalancePool(address _rebalance_pool);
    

    constructor (uint256 _startTime, uint256 _epoch_length){
        require(_startTime >= block.timestamp, "Start time initialized to the past");
        startTime = _startTime;
        epoch_length = _epoch_length;
        lastEpochTime = _startTime - epoch_length;
        setStrategist(msg.sender);
    }

    /*=========== VIEWS ===========*/
    function dollarPrice() public view returns (uint256) {return IOracle(oracleDollar).consult();}
    function sharePrice() public view returns (uint256) {return IOracle(oracleShare).consult();}
    function gov_token_price() public view returns (uint256) {return IOracle(oracleGovToken).consult();}
    function hasPool(address _address) external view override returns (bool) {return pools[_address] == true;}
    function nextEpochPoint() public view override returns (uint256) {return lastEpochTime + epoch_length;}
    function epoch() public view override returns (uint256) {return _epoch;}

    function redemption_fee_adjusted(address _caller) public view returns (uint256 redemptionFee) {
        if (governanceToken == address(0)) return redemption_fee;
        if (IERC20(governanceToken).balanceOf(_caller) >= discount_requirenment()) return redemption_fee / 2;
        return redemption_fee;
    }

    function discount_requirenment() public view returns (uint256) {
        uint256 govTokenPrice = gov_token_price();
        if (govTokenPrice == 0) return 1;
        uint256 decimals = IERC20Metadata(governanceToken).decimals();
        return  gov_token_value_for_discount * PRICE_PRECISION * 10**decimals / govTokenPrice;
    }

    function info(address _caller) external view override returns (
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    ){
        return (
            dollarPrice(), 
            sharePrice(), 
            target_collateral_ratio, 
            effective_collateral_ratio, 
            globalCollateralValue(),    
            minting_fee, 
            redemption_fee_adjusted(_caller)
        );
    }

    function epochInfo() external view override returns (
        uint256,
        uint256,
        uint256,
        uint256
    ){
        return (
            epoch(), 
            nextEpochPoint(), 
            epoch_length, 
            excess_collateral_distributed_ratio
        );
    }

    // Iterate through all pools and calculate all value of collateral in all pools globally
    function globalCollateralValue() public view returns (uint256) {
        uint256 total_collateral_value = 0;
        for (uint256 i = 0; i < pools_array.length; i++) {
            if (pools_array[i] != address(0)) {
                total_collateral_value = total_collateral_value + IPool(pools_array[i]).collateralDollarBalance();
            }
        }
        return total_collateral_value;
    }

    function calcEffectiveCollateralRatio() public view returns (uint256) {
        uint256 total_collateral_value = globalCollateralValue();
        uint256 total_supply_dollar = IERC20(dollar).totalSupply();
        uint256 ecr = total_collateral_value * PRICE_PRECISION / total_supply_dollar;
        if (ecr > COLLATERAL_RATIO_MAX) return COLLATERAL_RATIO_MAX;
        return ecr;
    }

    function refreshCollateralRatio() public withOracleUpdates{
        require(collateral_ratio_paused == false, "Collateral Ratio has been paused");
        require(block.timestamp - last_refresh_cr_timestamp >= refresh_cooldown, "Must wait for the refresh cooldown since last refresh");
        uint256 current_dollar_price = dollarPrice();
        
        if (current_dollar_price > price_target + price_band ) {
            if (target_collateral_ratio <= ratio_step) {// decrease collateral ratio
                target_collateral_ratio = 0;// if within a step of 0, go to 0
            } else {
                target_collateral_ratio = target_collateral_ratio - ratio_step;
            }
        }
        // Dollar price is below $1 - `price_band`. Need to increase `collateral_ratio`
        else if (current_dollar_price < price_target - price_band) {
            if (target_collateral_ratio + ratio_step >= COLLATERAL_RATIO_MAX) {// increase collateral ratio
                target_collateral_ratio = COLLATERAL_RATIO_MAX; // cap collateral ratio at 1.000000
            } else {
                target_collateral_ratio = target_collateral_ratio + ratio_step;
            }
        }

        effective_collateral_ratio = calcEffectiveCollateralRatio();
        last_refresh_cr_timestamp = block.timestamp;
    }

    // Check if the protocol is over- or under-collateralized, by how much
    function calcCollateralBalance() public view returns (uint256 _collateral_value, bool _exceeded) {
        uint256 total_collateral_value = globalCollateralValue();
        uint256 target_collateral_value = IERC20(dollar).totalSupply() * target_collateral_ratio / PRICE_PRECISION;
        if (total_collateral_value >= target_collateral_value) {
            _collateral_value = total_collateral_value - target_collateral_value;
            _exceeded = true;
        } else {
            _collateral_value = target_collateral_value - total_collateral_value;
            _exceeded = false;
        }
    }

    /* -========= INTERNAL FUNCTIONS ============ */

    // SWAP tokens using quickswap
    function _swap(address _input_token, uint256 _input_amount, uint256 _min_output_amount) internal returns (uint256) {
        require(
            (_input_token == collateral || _input_token == share) &&
            uniswap_router != address(0) && 
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
        } else if(_input_token == collateral) {
            _path[0] = collateral;
            _path[1] = wcoin;
            _path[2] = share;
        }
        
        IERC20(_input_token).safeApprove(uniswap_router, 0);
        IERC20(_input_token).safeApprove(uniswap_router, _input_amount);
        uint256[] memory out_amounts = IUniswapRouter(uniswap_router).swapExactTokensForTokens(_input_amount, _min_output_amount, _path, address(this), block.timestamp + 1800);
        return out_amounts[out_amounts.length - 1];
    }
    /* ========== RESTRICTED FUNCTIONS ========== */

    // Add new Pool
    function addPool(address pool_address) public onlyOwner notMigrated {
        require(pools[pool_address] == false, "poolExisted");
        pools[pool_address] = true;
        pools_array.push(pool_address);
    }

    // Remove a pool
    function removePool(address pool_address) public onlyOwner notMigrated {
        require(rebalancing_pool != pool_address, "Cant`t delete active rebalance pool");
        require(pools[pool_address] == true, "!pool");        
        delete pools[pool_address];// Delete from the mapping
        for (uint256 i = 0; i < pools_array.length; i++) {
            if (pools_array[i] == pool_address) {
                pools_array[i] = address(0); // This will leave a null in the array and keep the indices the same
                break;
            }
        }
    }

    function buyback(uint256 _collateral_value, uint256 _min_share_amount) external onlyStrategist withOracleUpdates notMigrated hasRebalancePool checkRebalanceCooldown {
        (uint256 _excess_collateral_value, bool _exceeded) = calcCollateralBalance();
        require(_exceeded && _excess_collateral_value > 0, "!exceeded");
        require(_collateral_value > 0 && _collateral_value < _excess_collateral_value, "invalidCollateralAmount");
        uint256 _collateral_price = IPool(rebalancing_pool).getCollateralPrice();
        uint256 _collateral_amount_sell = _collateral_value * PRICE_PRECISION / _collateral_price;
        require(IERC20(rebalancing_pool_collateral).balanceOf(rebalancing_pool) > _collateral_amount_sell, "insufficentPoolBalance");
        IPool(rebalancing_pool).transferCollateralToTreasury(_collateral_amount_sell); // Transfer collateral from pool to treasury
        uint256 out_share_amount = _swap(rebalancing_pool_collateral, _collateral_amount_sell, _min_share_amount);
        emit BoughtBack(_collateral_value, _collateral_amount_sell, out_share_amount);
    }

    function recollateralize(uint256 _share_amount, uint256 _min_collateral_amount) external onlyStrategist withOracleUpdates notMigrated hasRebalancePool checkRebalanceCooldown {
        (uint256 _deficit_collateral_value, bool _exceeded) = calcCollateralBalance();
        require(!_exceeded && _deficit_collateral_value > 0, "exceeded");
        require(_min_collateral_amount <= _deficit_collateral_value, ">deficit");
        uint256 _share_balance = IERC20(share).balanceOf(address(this));
        require(_share_amount <= _share_balance, ">shareBalance");
        uint256 out_collateral_amount = _swap(share, _share_amount, _min_collateral_amount);
        uint256 _collateral_balance = IERC20(rebalancing_pool_collateral).balanceOf(address(this));
        if (_collateral_balance > 0) {
            IERC20(rebalancing_pool_collateral).safeTransfer(rebalancing_pool, _collateral_balance); // Transfer collateral from Treasury to Pool
        }
        uint256 collateral_price = IPool(rebalancing_pool).getCollateralPrice();
        uint256 out_collateral_value = out_collateral_amount * collateral_price / PRICE_PRECISION;
        emit Recollateralized(_share_amount, out_collateral_amount, out_collateral_value);
    }

    function allocateSeigniorage() external withOracleUpdates notMigrated nonReentrant checkEpoch {
        require(!migrated, "Treasury: migrated");
        require(block.timestamp >= startTime, "Treasury: not started yet");
        (uint256 _excess_collateral_value, bool _exceeded) = calcCollateralBalance();
        require(_exceeded && _excess_collateral_value > 0, "!exceeded");
        uint256 _collateral_price = IPool(rebalancing_pool).getCollateralPrice();
        uint256 missing_decimals = IPool(rebalancing_pool).getMissing_decimals();
        uint256 _collateral_amount_allocate = (_excess_collateral_value * PRICE_PRECISION / _collateral_price) / missing_decimals;
        IPool(rebalancing_pool).transferCollateralToTreasury(_collateral_amount_allocate); // Transfer collateral from pool to treasury
        IERC20(rebalancing_pool_collateral).safeApprove(foundry, 0);
        IERC20(rebalancing_pool_collateral).safeApprove(foundry, _collateral_amount_allocate);// div for 18 - decimals
        IFoundry(foundry).allocateSeigniorage(_collateral_amount_allocate);
    }

    function migrate(address _new_treasury) external onlyOwner notMigrated {
        migrated = true;
        uint256 _share_balance = IERC20(share).balanceOf(address(this));
        if (_share_balance > 0) {
            IERC20(share).safeTransfer(_new_treasury, _share_balance);
        }
        if (rebalancing_pool_collateral != address(0)) {
            uint256 _collateral_balance = IERC20(rebalancing_pool_collateral).balanceOf(address(this));
            if (_collateral_balance > 0) {
                IERC20(rebalancing_pool_collateral).safeTransfer(_new_treasury, _collateral_balance);
            }
        }
    }

    //setters
    function setGovTokenValueForDiscount(uint256 value) public onlyOwner {
        gov_token_value_for_discount = value;
        emit New_GovTokenValueForDiscount(gov_token_value_for_discount);
    }
    
    function setRedemptionFee(uint256 _redemption_fee) public onlyOwner {
        redemption_fee = _redemption_fee;
        emit New_RedemptionFee(redemption_fee);
    }
    
    function setMintingFee(uint256 _minting_fee) public onlyOwner {
        minting_fee = _minting_fee;
        emit New_MintingFee(minting_fee);
    }
    
    function setRatioStep(uint256 _ratio_step) public onlyOwner {
        ratio_step = _ratio_step;
        emit New_RatioStep(ratio_step);
    }

    function setPriceTarget(uint256 _price_target) public onlyOwner {
        price_target = _price_target;
        emit New_PriceTarget(price_target);
    }
    
    function setRefreshCooldown(uint256 _refresh_cooldown) public onlyOwner {
        refresh_cooldown = _refresh_cooldown;
        emit New_RefreshCooldown(refresh_cooldown);
    }
    
    function setPriceBand(uint256 _price_band) external onlyOwner {
        price_band = _price_band;
        emit New_PriceBand(price_band);
    }
    
    function unpauseCollateralRatio() public onlyOwner {
        require(collateral_ratio_paused, "already unpaused");
        collateral_ratio_paused = false;
    }
    
    function setOracleDollar(address _oracle) public onlyOwner nonZeroAddress(_oracle) {
        oracleDollar = _oracle;
        emit New_OracleDollar(oracleDollar);
    }
    
    function setOracleShare(address _oracle) public onlyOwner nonZeroAddress(_oracle) {
        oracleShare = _oracle;
        emit New_OracleShare(oracleShare);
    }
    
    function setOracleGovToken(address _oracle) public onlyOwner nonZeroAddress(_oracle) {
        oracleGovToken = _oracle;
        emit New_OracleGovToken(oracleGovToken);
    }
    
    function setFoundry(address _foundry) public onlyOwner nonZeroAddress(_foundry){
        foundry = _foundry; 
        emit New_Foundry(foundry);
    }
    
    function setEpochLength(uint256 _epoch_length) public onlyOwner {
        epoch_length = _epoch_length;
        emit New_EpochLength(epoch_length);
    }
    
    function setRebalanceCooldown(uint256 _cooldown) public onlyOwner {
        rebalance_cooldown = _cooldown;
        emit New_RebalanceCooldown(rebalance_cooldown);
    }
    
    function setExcessDistributionRatio(uint256 _ratio) public onlyOwner {
        excess_collateral_distributed_ratio = _ratio;
        emit New_ExcessDistributionRatio(excess_collateral_distributed_ratio);
    }

    function updateOracles() public override withOracleUpdates {/*empty, used only for modifier*/}
    
    function setStrategist(address _strategist) public onlyOwner {
        strategist = _strategist; 
        emit New_Strategist(strategist);
    }
    
    function installTokens(
        address _uniswap_router,
        address _governanceToken,
        address _wcoin,
        address _collateral,
        address _share,
        address _dollar
    ) public onlyOwner {
        
        uniswap_router  = _uniswap_router;
        governanceToken = _governanceToken;
        wcoin           = _wcoin;
        collateral      = _collateral;
        share           = _share;
        dollar          = _dollar;
        
        emit New_Tokens(
            uniswap_router,
            governanceToken,
            wcoin,
            collateral,
            share,
            dollar
        );
    }

    function setRebalancePool(address _rebalance_pool) public onlyOwner  {
        require(pools[_rebalance_pool], "!pool");
        require(IPool(_rebalance_pool).getCollateralToken() != address(0), "!poolCollateralToken");
        rebalancing_pool = _rebalance_pool;
        rebalancing_pool_collateral = IPool(_rebalance_pool).getCollateralToken();
        emit New_RebalancePool(rebalancing_pool);
    }
    
    function resetStartTime(uint256 _startTime) external onlyOwner {
        require(_epoch == 0, "already started");
        startTime = _startTime;
        lastEpochTime = _startTime - 8 hours;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IEpoch {
    function epoch() external view returns (uint256);
    function nextEpochPoint() external view returns (uint256);
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

    function setLockUp(uint256 _withdrawLockupEpochs, uint256 _rewardLockupEpochs) external;

    function stake(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function exit() external;

    function claimReward() external;

    function allocateSeigniorage(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IOracle {
    function consult() external view returns (uint256);
    function updateIfRequired() external;
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
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IUniswapRouter{
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
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

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

pragma solidity ^0.8.0;

/*
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