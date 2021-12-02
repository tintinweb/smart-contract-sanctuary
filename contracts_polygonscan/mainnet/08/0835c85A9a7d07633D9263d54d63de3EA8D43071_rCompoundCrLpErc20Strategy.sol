//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "hardhat/console.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./IRaiderStaking.sol";
import "./rStrategy.sol";
import "./IrOracle.sol";

/**
 * @author Oighty (h/t to Nat Eliason for authoring the RaiderStaking contract). Please contact me on Twitter (@oightytag) or Discord (Oighty #4287) if you have any questions about this contract.
 */

contract rCompoundCrLpErc20Strategy is rStrategy {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    //  -------------------- CONTRACT VARIABLES --------------------
    // Tokens and Contracts to Interface with
    IRaiderStaking internal _stakingContract; // The staking contract that the vault will compound into
    IUniswapV2Pair internal _stakingToken; // The LP token people can stake
    IERC20 internal _pairedToken; // The project token in the staking LP pair
    IERC20 internal _stakingLpBaseToken; // The base token in the staking LP pair
    
    IUniswapV2Pair internal _rewardLpToken; // The LP token for the reward token paired with MATIC
    IERC20 internal _rewardToken; // The project token people will be rewarded with
    IERC20 internal _rewardLpBaseToken; //  The base token in the reward LP pair

    IUniswapV2Router02 internal _router; // Sushiswap Router to swap tokens and provide liquidity
    address internal _wmaticAddr; // The WMATIC token address
    address[] internal _swapPath; // Path array needed for routing uniswapv2 swaps

    IrOracle internal _oracle; // Price oracle to use for swaps

    // Parameters
    uint public compoundFrequency; // number of seconds to wait between compounding
    uint public lastCompoundTime; // For calculating how recently the vault was compounded
    uint internal _priceSlippage; // Slippage tolerance on DEX transactions in big units
    uint internal _dexFee; // Amount charged by the DEX for trading fees

    //  -------------------- EVENTS ----------------------------------
    event Compounded(uint timestamp, uint256 amount);
    
    //  -------------------- CONSTRUCTOR FUNCTION --------------------
    constructor(
        string memory _name,
        address _vaultAddr,
        address _stakingContractAddr,
        address _stakingTokenAddr,
        address _rewardTokenAddr,
        address _rewardTokenLpAddr,
        address _routerAddr,
        uint _compoundFrequency,
        uint _feePercent,
        address _managerAddr,
        address _oracleAddr
    ) rStrategy(
        _name,
        _vaultAddr,
        _stakingTokenAddr,
        _feePercent,
        _managerAddr
    )
    {
        // Assign initial variable values        
        _stakingContract = IRaiderStaking(_stakingContractAddr);
        _stakingToken = IUniswapV2Pair(_stakingTokenAddr);
        _pairedToken = IERC20(_stakingToken.token1());
        _stakingLpBaseToken = IERC20(_stakingToken.token0());
        _rewardToken = IERC20(_rewardTokenAddr);
        _rewardLpToken = IUniswapV2Pair(_rewardTokenLpAddr);
        _rewardLpBaseToken = IERC20(_rewardLpToken.token0());

        _router = IUniswapV2Router02(_routerAddr);
        _wmaticAddr = _router.WETH();
        _oracle = IrOracle(_oracleAddr);

        lastCompoundTime = block.timestamp;
        compoundFrequency = _compoundFrequency;
        _priceSlippage = 2 * 10**16; // 2% slippage by default from TWAP
        _dexFee = 3 * 10**15; // 0.3% fee charged by UniswapV2
        
        // Approve Reward Token and Token to Pair for LP on Router
        _pairedToken.approve(_routerAddr, MAX_UNIT);
        if (_rewardTokenAddr != address(_pairedToken)) {
            _rewardToken.approve(_routerAddr, MAX_UNIT);
            if (address(_rewardLpBaseToken) != _wmaticAddr) {
                _rewardLpBaseToken.approve(_routerAddr, MAX_UNIT);
            }
        }

        // Approve LP Token on Router
        _stakingToken.approve(_routerAddr, MAX_UNIT);

        // Approve LP base token on the router
        _stakingLpBaseToken.approve(_routerAddr, MAX_UNIT);

        // Approve staking contract for LP Token
        _stakingToken.approve(_stakingContractAddr, MAX_UNIT);
    }

    //  -------------------- VIEW FUNCTIONS -------------------------
    // function timeSinceLastCompound() public view returns (uint) {
    //     return block.timestamp.sub(lastCompoundTime);
    // }

    function getStakingContract() external view returns (address) {
        return address(_stakingContract);
    }

    //  -------------------- UTILITY FUNCTIONS ---------------------

    function _invest(uint _amount) internal override whenNotPaused {
        _stakingContract.createStake(_amount);
        _externalContractTokenBalance = _externalContractTokenBalance.add(_amount);
    }

    function _divest(uint _amount) internal override {
        _stakingContract.removeStake(_amount);
        _externalContractTokenBalance = _externalContractTokenBalance.sub(_amount);
    }

    //  -------------------- MANAGER FUNCTIONS --------------------
    function compound() external payable whenNotPaused nonReentrant onlyRole(MANAGER_ROLE) {
        // Get outstanding rewards
        _stakingContract.getRewards();
        uint rewardsToCompound = _rewardToken.balanceOf(address(this));

        // Declare variables for swaps
        uint minAmountBaseToken;
        uint minAmountPairedToken;
        uint desiredAmountBaseToken;
        uint desiredAmountPairedToken;
        uint oracleAmount;
        uint reserveA;
        uint reserveB;
        uint[] memory amounts;

        // Swap tokens to get the right amounts for providing liquidity
        if (address(_rewardToken) == address(_pairedToken)) { // RAIDER/(ERC20) LP Case
            //// Swap 1/2 of the reward token for the LP base token
            // Get the current price from the exchange
            (reserveA, reserveB, ) = _stakingToken.getReserves();
            minAmountBaseToken = _router.getAmountOut(rewardsToCompound.mul(50 * (10 ** 16)).div(BIG_UNIT), reserveB, reserveA);

            // Compare exchange quote with oracle to make sure it's within our tolerance
            oracleAmount = _oracle.consult(
                address(_rewardToken), // address tokenIn
                rewardsToCompound.mul(50 * (10 ** 16)).div(BIG_UNIT), // uint amountIn
                address(_stakingLpBaseToken) // address tokenOut
            );

            require(
                (minAmountBaseToken >= oracleAmount.mul(BIG_UNIT.sub(_dexFee).sub(_priceSlippage)).div(BIG_UNIT)) &&
                (minAmountBaseToken <= oracleAmount.mul(BIG_UNIT.sub(_dexFee).add(_priceSlippage)).div(BIG_UNIT)),
                "Price out of bounds."
            );

            // Create the swap path
            _swapPath.push(address(_rewardToken));
            _swapPath.push(address(_stakingLpBaseToken));
            
            // Execute the swap
            amounts = _router.swapExactTokensForTokens(
                rewardsToCompound.mul(50 * (10 ** 16)).div(BIG_UNIT), // amount of _pairedToken in
                minAmountBaseToken, // minimum amonut of _stakingLpBaseToken out
                _swapPath, // _router path
                address(this), // address to send matic to (this contract)
                block.timestamp + 30 // deadline for executing the swap
            );
            
            desiredAmountBaseToken = amounts[1];
            delete amounts;
            delete _swapPath;

            desiredAmountPairedToken = _pairedToken.balanceOf(address(this));
            
        } else { //// AURUM/(ERC20) LP Case
            //// Swap the rewards for AURUM
            // Create swap path for multi-hop quote and swap
            _swapPath.push(address(_rewardToken));
            _swapPath.push(address(_rewardLpBaseToken));
            _swapPath.push(address(_pairedToken));

            // Get the current price from the exchange
            amounts = _router.getAmountsOut(rewardsToCompound, _swapPath);
            minAmountPairedToken = amounts[2];
            delete amounts;

            // Compare exchange quote with oracle to make sure it's within our tolerance
            oracleAmount = _oracle.consult(
                address(_rewardToken), // address tokenIn
                rewardsToCompound, // uint amountIn
                address(_rewardLpBaseToken) // address tokenOut
            );
            oracleAmount = _oracle.consult(
                address(_rewardLpBaseToken), // address tokenIn
                oracleAmount, // uint amountIn
                address(_pairedToken) // address tokenOut
            );

            require(
                (minAmountPairedToken >= oracleAmount.mul(BIG_UNIT.sub(_dexFee).sub(_priceSlippage)).div(BIG_UNIT)) &&
                (minAmountPairedToken <= oracleAmount.mul(BIG_UNIT.sub(_dexFee).add(_priceSlippage)).div(BIG_UNIT)),
                "Price out of bounds."
            );

            // Execute the swap
            amounts = _router.swapExactTokensForTokens(
                rewardsToCompound, // amount of _rewardToken in
                minAmountPairedToken, // minAmount of _pairedToken out
                _swapPath, // _router path
                address(this), // address to send matic to (this contract)
                block.timestamp + 20 // deadline for executing the swap
            );
            desiredAmountPairedToken = amounts[2].mul(50 * (10 ** 16)).div(BIG_UNIT);
            delete amounts;
            delete _swapPath;

            //// Swap 1/2 of the paired token for the stakingLpBaseToken
            // Get the current price from the exchange
            (reserveA, reserveB, ) = _stakingToken.getReserves(); // Token A is the base token in all of the Raider Pairs and Token B is the _pairedToken
            minAmountBaseToken = _router.getAmountOut(desiredAmountPairedToken, reserveB, reserveA); // accounts for slippage and fees
            
            // Compare exchange quote with oracle to make sure it's within our tolerance
            oracleAmount = _oracle.consult(
                address(_pairedToken), // address tokenIn
                desiredAmountPairedToken, // uint amountIn
                address(_stakingLpBaseToken) // address tokenOut
            );
            require(
                (minAmountBaseToken >= oracleAmount.mul(BIG_UNIT.sub(_dexFee).sub(_priceSlippage)).div(BIG_UNIT)) &&
                (minAmountBaseToken <= oracleAmount.mul(BIG_UNIT.sub(_dexFee).add(_priceSlippage)).div(BIG_UNIT)),
                "Price out of bounds."
            );
            
            // Create the swap path
            _swapPath.push(address(_pairedToken));
            _swapPath.push(address(_stakingLpBaseToken));
            
            // Execute the swap
            _router.swapExactTokensForTokens(
                desiredAmountPairedToken, // amount of _pairedToken in
                minAmountBaseToken, // minimum amonut of _stakingLpBaseToken out
                _swapPath, // _router path
                address(this), // address to send matic to (this contract)
                block.timestamp + 40 // deadline for executing the swap
            );
            delete _swapPath;

            desiredAmountBaseToken = _stakingLpBaseToken.balanceOf(address(this));
        }

        { // Enclose in brackets to get around compiler issues                
            //// Calculate the remaining variables for the adding the liquidity
            // Calculate the amounts based on exchange reserves (No need to use oracle here because the values have been checked already on this block)
            minAmountPairedToken = _router.getAmountOut(desiredAmountBaseToken, reserveA, reserveB);
            minAmountBaseToken = _router.quote(minAmountPairedToken, reserveB, reserveA);

            //// Add the liquidity, handle WMATIC or ERC20 base function calls
            (,, uint newStakingTokens) = _router.addLiquidity(
                address(_stakingLpBaseToken), // base token for the LP
                address(_pairedToken), // token to pair address
                desiredAmountBaseToken, // desired amount of base token
                desiredAmountPairedToken, // desired amount of token to pair
                minAmountBaseToken, // minimum amount of base token to pair - same as minimum received from swap
                minAmountPairedToken, // minimum amount of token to pair
                address(this), // address to receive the LP tokens (this contract)
                block.timestamp + 60 // deadline for supplying the liquidity
            );

            //// Update the fee balance
            _updateFeeBalance(newStakingTokens);
        }

        //// Deposit new tokens, including any deposited recently, into the staking contract
        _invest(_availableBalance());

        //// Emit event and update last compound time
        lastCompoundTime = block.timestamp;
        emit Compounded(lastCompoundTime, rewardsToCompound);
    }

    function invest(uint _amount) public whenNotPaused nonReentrant onlyRole(MANAGER_ROLE) {
        _invest(_amount);
    }

    function divest(uint _amount) public nonReentrant onlyRole(MANAGER_ROLE) {
        _divest(_amount);
    }

    //  -------------------- OWNER FUNCTIONS --------------------
    function setCompoundFrequency(uint _seconds) external onlyRole(OWNER_ROLE) {
        compoundFrequency = _seconds;
    }

    function priceSlippage() external view onlyRole(OWNER_ROLE) returns (uint) {
        return _priceSlippage;
    }

    function setPriceSlippage(uint _slippage) external onlyRole(OWNER_ROLE) {
        _priceSlippage = _slippage;
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

pragma solidity ^0.8.0;

interface IRaiderStaking {
    // --------- UTILITY FUNCTIONS ------------
    function isStaker(address _address) external view returns(bool);

    // ----------- STAKING ACTIONS ------------
    function createStake(uint _amount) external;
    function removeStake(uint _amount) external;
    // Backup function in case something happens with the update rewards functions
    function emergencyUnstake(uint _amount) external;

    // ------------ REWARD ACTIONS ---------------
    function getRewards() external;
    function updateAddressRewardsBalance(address _address) external returns (uint);
    function updateBigRewardsPerToken() external;
    function userPendingRewards(address _address) external view returns (uint);

    // ------------ ADMIN ACTIONS ---------------
    function withdrawRewards(uint _amount) external;
    function depositRewards(uint _amount) external;
    function setDailyEmissions(uint _amount) external;
    function pause() external;
    function unpause() external;

    // ------------ VIEW FUNCTIONS ---------------
    function timeSinceLastReward() external view returns (uint);
    function rewardsBalance() external view returns (uint);
    function addressStakedBalance(address _address) external view returns (uint);
    function showStakingToken() external view returns (address);
    function showRewardToken() external view returns (address);
    function showBigRewardsPerToken() external view returns (uint);
    function showBigUserRewardsCollected() external view returns (uint);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "hardhat/console.sol";

// !! IMPORTANT !! The most up to date SafeMath relies on Solidity 0.8.0's new overflow protection. 
// If you use an older version of Soliditiy you MUST also use an older version of SafeMath

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./IrVault.sol";

/**
 * @author Oighty. Please contact me on Twitter (@oightytag) or Discord (Oighty #4287) if you have any questions about this contract.
 */

abstract contract rStrategy is AccessControl, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    //  -------------------- CONTRACT VARIABLES --------------------
    string public name;

    // Tokens and Contracts to Interface with
    IrVault internal immutable _vault; // The vault contract that this strategy is deployed for, immutable
    IERC20 internal immutable _depositToken; // The depositToken that the vault can deposit in this strategy, immutable

    // Access Control
    bytes32 constant OWNER_ROLE = keccak256("OWNER");
    bytes32 constant MANAGER_ROLE = keccak256("MANAGER");
    bytes32 constant VAULT_ROLE = keccak256("VAULT");
    address public owner; // Address that has admin control over the strategy
    address public manager; // Address that calls investment actions on the vault

    // Constants
    uint constant MAX_UNIT = (2 ** 256) - 1;
    uint constant BIG_UNIT = 10 ** 18;

    // Balances
    uint internal _externalContractTokenBalance; // Total balance of deposit tokens provided to external contracts
    uint internal _feeBalance; // Balance of deposit tokens that have been accumulated by the vault as fees

    // Parameters
    uint public feePercent; // Percentage fee for performance and operations (in big units of percent * 10 ** 18)

    //  -------------------- EVENTS --------------------
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Received(address sender, uint amount);
    
    //  -------------------- CONSTRUCTOR FUNCTION --------------------
    constructor(
        string memory _name,
        address _vaultAddr,
        address _depositTokenAddr,
        uint _feePercent,
        address _managerAddr
    ) {
        // Assign initial variable values
        name = _name;
        _vault = IrVault(_vaultAddr);
        _depositToken = IERC20(_depositTokenAddr);
        feePercent = _feePercent;

        // Assign roles for access control
        owner = msg.sender;
        _setupRole(DEFAULT_ADMIN_ROLE, owner);
        _setupRole(OWNER_ROLE, owner);

        manager = _managerAddr;
        _setupRole(MANAGER_ROLE, manager);

        _setupRole(VAULT_ROLE, _vaultAddr);
    }

    //  -------------------- VIEW FUNCTIONS ----------------------
    function totalBalance() public view returns (uint) {
        return _depositToken.balanceOf(address(this)).add(_externalContractTokenBalance).sub(_feeBalance);
    }
    
    function getDepositToken() external view returns (address) {
        return address(_depositToken);
    }

    //  -------------------- UTILITY FUNCTIONS --------------------

    receive() external payable { // Receive function required by the Sushiswap Router
        emit Received(msg.sender, msg.value);
    }

    function _availableBalance() internal view returns (uint) {
        return _depositToken.balanceOf(address(this));
    }

    function _updateFeeBalance(uint _amountNewTokens) internal {
        _feeBalance = _feeBalance.add(
            _amountNewTokens
            .mul(feePercent)
            .div(BIG_UNIT)
        );
    }

    function _invest(uint _amount) internal virtual;
    function _divest(uint _amount) internal virtual;

    //  -------------------- MANAGER FUNCTIONS --------------------


    //  -------------------- OWNER FUNCTIONS ----------------------    
    function setManager(address _managerAddr) external onlyRole(OWNER_ROLE) {
        revokeRole(MANAGER_ROLE, manager);
        manager = _managerAddr;
        grantRole(MANAGER_ROLE, manager);
    }

    function setFeePercent(uint _percent) external onlyRole(OWNER_ROLE) {
        feePercent = _percent;
    }

    function feeBalance() external view onlyRole(OWNER_ROLE) returns (uint) {
        return _feeBalance;
    }

    function withdrawFees() external onlyRole(OWNER_ROLE) nonReentrant {
        require(_feeBalance > 0, "Cannot withdraw 0.");
        // Check if vault has enough to withdraw, otherwise withdraw from the strategy
        uint _balance = _availableBalance();
        if (_balance < _feeBalance) {
            uint _withdraw = _feeBalance.sub(_balance);
            _divest(_withdraw);
            uint _after = _availableBalance();
            uint _diff = _after.sub(_balance);
            if (_diff < _withdraw) { // Check is for deflationary tokens
                _feeBalance = _balance.add(_diff);
            }
        }

        // Transfer the tokens to the owner
        _depositToken.safeTransfer(owner, _feeBalance);

        // Set fee balance to zero
        _feeBalance = 0;
    }

    function pause() external onlyRole(OWNER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(OWNER_ROLE) {
        _unpause();
    }

    //  -------------------- VAULT FUNCTIONS --------------------
    function deposit(uint _amount) external whenNotPaused nonReentrant onlyRole(VAULT_ROLE) {
        // Require the deposit to be non-zero
        require(_amount > 0, "Cannot deposit 0.");

        // Transfer the staking tokens to the vault
        _depositToken.transferFrom(msg.sender, address(this), _amount);

        // Emit deposit event
        emit Deposited(msg.sender, _amount);
    }
    
    function withdraw(uint _amount) external nonReentrant onlyRole(VAULT_ROLE) {
        // Require the amount be greater than zero and the sender to have a balance greater than or equal to the amount
        require(_amount > 0, "Cannot withdraw 0.");
        require(totalBalance() >= _amount, "Cannot withdraw > your balance.");

        // Check if vault has enough to withdraw, otherwise withdraw from the strategy
        uint _balance = _availableBalance();
        if (_balance < _amount) {
            uint _withdraw = _amount.sub(_balance);
            _divest(_withdraw);
            uint _after = _availableBalance();
            uint _diff = _after.sub(_balance);
            if (_diff < _withdraw) { // Check is for deflationary tokens
                _amount = _balance.add(_diff);
            }
        }

        // Transfer the tokens to the caller
        _depositToken.transfer(msg.sender, _amount);
        emit Withdrawn(msg.sender, _amount);
    }

    function withdrawAll() external nonReentrant onlyRole(VAULT_ROLE) {
        // Require the amount be greater than zero and the sender to have a balance greater than or equal to the amount
        uint _total = totalBalance();
        require(_total >= 0, "Cannot withdraw 0.");

        // Check if vault has enough to withdraw, otherwise withdraw from the strategy
        uint _balance = _availableBalance();
        if (_balance < _total) {
            uint _withdraw = _total.sub(_balance);
            _divest(_withdraw);
            uint _after = _availableBalance();
            uint _diff = _after.sub(_balance);
            if (_diff < _withdraw) { // Check is for deflationary tokens
                _total = _balance.add(_diff);
            }
        }

        // Transfer the tokens to the caller
        _depositToken.transfer(msg.sender, _total);
        emit Withdrawn(msg.sender, _total);
    }
}

pragma solidity ^0.8.0;

interface IrOracle {
    function observationIndexOf(uint timestamp) external view returns (uint8 index);

    // update the cumulative price for the observation at the current timestamp. each observation is updated at most
    // once per epoch period.
    function update(address tokenA, address tokenB) external;

    // returns the amount out corresponding to the amount in for a given token using the moving average over the time
    // range [now - [windowSize, windowSize - periodSize * 2], now]
    // update must have been called for the bucket corresponding to timestamp `now - windowSize`
    function consult(address tokenIn, uint amountIn, address tokenOut) external view returns (uint amountOut);
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
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

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IrVault {
    //  -------------------- EVENTS --------------------
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    //  -------------------- VIEW FUNCTIONS --------------------
    function getDepositToken() external view returns (address);
    function totalBalance() external view returns (uint);
    function getPricePerFullShare() external view returns (uint256);
    function getTokensFromShares() external view returns (uint256);
    //  -------------------- ADMIN FUNCTIONS --------------------
    function setStrategy(address _strategyAddr) external;
    function pause() external;
    function unpause() external;
    function emergencyWithdrawFromStrategy() external;
    //  -------------------- USER FUNCTIONS --------------------
    function deposit(uint _amount) external payable;
    function withdraw(uint _shares) external;
    function withdrawAll() external;
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

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}