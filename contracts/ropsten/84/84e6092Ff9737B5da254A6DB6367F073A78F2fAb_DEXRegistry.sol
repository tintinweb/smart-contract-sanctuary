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

pragma solidity ^0.8.9;

import "./DEXTokenPool.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DEXRegistry is Ownable {
    // Store the Tokens Pool's Location
    mapping(address => mapping(address => address)) public registry;

    // Store the pool's locations
    address[] public pools;

    // Event triggered when a new pair is created
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    /**
     * Return Total Number of Pools created
     */
    function countPools() external view returns (uint256) {
        return pools.length;
    }

    /**
     * Retrieve a List of All Pools
     *
     * Useful for the frontend
     */
    function allPools() public view returns (address[] memory) {
        return pools;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, "Must be different tokens");
        require(tokenA != address(0), "Invalid Token");

        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(registry[token0][token1] == address(0), "Pool already exists");

        bytes memory bytecode = type(DEXTokenPool).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));

        // solhint-disable-next-line no-inline-assembly
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        DEXTokenPool(pair).initialize(token0, token1);

        registry[token0][token1] = pair;
        registry[token1][token0] = pair;
        pools.push(pair);

        // Send a new event for frontend
        emit PairCreated(token0, token1, pair, pools.length);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DEXTokenPool {
    // Store the Registry address
    address public registry;

    // Store the ERC20 Tokens addresses
    address public token0;
    address public token1;

    // Pool Settings
    // -------------------------------------

    // Stores the total amount of share issued for the pool
    uint256 public totalShares;

    // Stores the amount of Token0 locked in the pool
    uint256 public totalToken0;

    // Stores the amount of Token1 locked in the pool
    uint256 public totalToken1;

    // Algorithmic constant used to determine price (k = totalToken0 * totalToken1)
    uint256 public k;

    // Stores the share holding of each provider
    uint256 public constant PRECISION = 1_000_000; // Precision of 6 decimal places for shares
    mapping(address => uint256) public shares;

    // Restricts withdraw, swap feature till liquidity is added to the pool
    modifier activePool() {
        require(totalShares > 0, "Zero Liquidity");
        _;
    }

    /**
     * DEXTokenPool Constructor
     *
     * This contract will be built by `DEXRegistry`, so we need to
     * assign it as a registry rulling this pool.
     */
    constructor() {
        registry = msg.sender;
    }

    /**
     * Initialize the Pool
     *
     * Since this contract will be deployed by `DEXRegistry`, we cannot pass
     * information to the constructor method. We will call this method once to
     * assign the token addresses to this pool.
     */
    function initialize(address _token0, address _token1) external {
        require(token0 == address(0) && token1 == address(0), "Already initialized");
        token0 = _token0;
        token1 = _token1;
    }

    /**
     * Retrieve Pool Details
     */
    function getPoolDetails()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (totalToken0, totalToken1, totalShares);
    }

    /**
     * Return Estimatives for Token Locking
     */
    function getEquivalentToken0Estimate(uint256 _amountToken1) public view activePool returns (uint256 reqToken0) {
        reqToken0 = (totalToken0 * _amountToken1) / totalToken1;
    }

    function getEquivalentToken1Estimate(uint256 _amountToken0) public view activePool returns (uint256 reqToken1) {
        reqToken1 = (totalToken1 * _amountToken0) / totalToken0;
    }

    /**
     * Add Liquidity into the Pool
     *
     * This method will withdraw the specified amount of tokens
     * from the user and will lock into the pool, receiving the
     * proportional amount of tokens.
     */
    function provide(uint256 _amountToken0, uint256 _amountToken1) external returns (uint256 share) {
        // Check if user allowed us to spend his tokens and has enough
        // tokens
        {
            require(IERC20(token0).balanceOf(msg.sender) >= _amountToken0, "Insufficient Funds of Token0");
            require(IERC20(token1).balanceOf(msg.sender) >= _amountToken1, "Insufficient Funds of Token1");
            uint256 allowance0 = IERC20(token0).allowance(msg.sender, address(this));
            uint256 allowance1 = IERC20(token1).allowance(msg.sender, address(this));
            require(allowance0 >= _amountToken0, "You need allow us to spend token0");
            require(allowance1 >= _amountToken1, "You need allow us to spend token1");
        }

        // Retrieve amount of shares
        if (totalShares == 0) {
            // Genesis liquidity is issued 100 Shares
            share = 100 * PRECISION;
        } else {
            uint256 share0 = (totalShares * _amountToken0) / totalToken0;
            uint256 share1 = (totalShares * _amountToken1) / totalToken1;
            require(share0 == share1, "Equivalent value of tokens not provided...");
            share = share0;
        }

        require(share > 0, "Asset value less than threshold for contribution!");

        // Transfer the tokens to this contract
        IERC20(token0).transferFrom(msg.sender, address(this), _amountToken0);
        IERC20(token1).transferFrom(msg.sender, address(this), _amountToken1);

        totalToken0 += _amountToken0;
        totalToken1 += _amountToken1;
        k = totalToken0 * totalToken1;

        totalShares += share;
        shares[msg.sender] += share;
    }

    // Returns the estimate of Token1 & Token2 that will be released on burning given _share
    function getWithdrawEstimate(uint256 _share)
        public
        view
        activePool
        returns (uint256 amountToken0, uint256 amountToken1)
    {
        require(_share <= totalShares, "Share should be less than totalShare");
        amountToken0 = (_share * totalToken0) / totalShares;
        amountToken1 = (_share * totalToken1) / totalShares;
    }

    // Removes liquidity from the pool and releases corresponding Token1 & Token2 to the withdrawer
    function withdraw(uint256 _share) external activePool returns (uint256 amountToken0, uint256 amountToken1) {
        require(shares[msg.sender] >= _share, "Insuficcient amount of shares");
        (amountToken0, amountToken1) = getWithdrawEstimate(_share);

        shares[msg.sender] -= _share;
        totalShares -= _share;

        totalToken0 -= amountToken0;
        totalToken1 -= amountToken1;
        k = totalToken0 * totalToken1;

        // Transfer Tokens
        require(IERC20(token0).transfer(msg.sender, amountToken0), "Failed transfer token0");
        require(IERC20(token1).transfer(msg.sender, amountToken1), "Failed transfer token1");
    }

    /**
     * Token Swaps
     * ----------------------------------------------
     */

    /**
     * Estimate the Number of Token1 with a specified deposit of Token0
     */
    function getSwapToken0Estimate(uint256 _amountToken0) public view activePool returns (uint256 amountToken1) {
        uint256 token0After = totalToken0 + _amountToken0;
        uint256 token1After = k / token0After;
        amountToken1 = totalToken1 - token1After;

        // To ensure that Token2's pool is not completely depleted leading to inf:0 ratio
        if (amountToken1 == totalToken1) amountToken1--;
    }

    /**
     * Estimate the Required Amount of Token0 to Get a Specified Amount of Token1
     */
    function getSwapToken0EstimateGivenToken1(uint256 _amountToken1)
        public
        view
        activePool
        returns (uint256 amountToken0)
    {
        require(_amountToken1 < totalToken1, "Insufficient pool balance");
        uint256 token1After = totalToken1 / _amountToken1;
        uint256 token0After = k / token1After;
        amountToken0 = token0After - totalToken0;
    }

    /**
     * Swap: Token0 -> Token1
     */
    function swapToken0(uint256 _amountToken0) external activePool returns (uint256 amountToken1) {
        // Check
        require(IERC20(token0).balanceOf(msg.sender) >= _amountToken0, "Insufficient funds");
        require(
            IERC20(token0).allowance(msg.sender, address(this)) >= _amountToken0,
            "You need allow us to spend this amount"
        );

        // Caclulate the amount of tokens to receive
        amountToken1 = getSwapToken0Estimate(_amountToken0);

        // Update the state
        totalToken0 += _amountToken0;
        totalToken1 -= amountToken1;

        // Transfer
        IERC20(token0).transferFrom(msg.sender, address(this), _amountToken0);
        IERC20(token1).transfer(msg.sender, amountToken1);
    }

    /**
     * Estimate the Number of Token0 with a specified deposit of Token1
     */
    function getSwapToken1Estimate(uint256 _amountToken1) public view activePool returns (uint256 amountToken0) {
        uint256 token1After = totalToken1 + _amountToken1;
        uint256 token0After = k / token1After;
        amountToken0 = totalToken0 - token0After;

        // To ensure that Token0's pool is not completely depleted leading to inf:0 ratio
        if (amountToken0 == totalToken0) amountToken0--;
    }

    /**
     * Estimate the Required Amount of Token1 to Get a Specified Amount of Token0
     */
    function getSwapToken1EstimateGivenToken0(uint256 _amountToken0)
        public
        view
        activePool
        returns (uint256 amountToken1)
    {
        require(_amountToken0 < totalToken0, "Insufficient pool balance");
        uint256 token0After = totalToken0 / _amountToken0;
        uint256 token1After = k / token0After;
        amountToken1 = token1After - totalToken1;
    }

    /**
     * Swap: Token1 -> Token0
     */
    function swapToken1(uint256 _amountToken1) external activePool returns (uint256 amountToken0) {
        // Check
        require(IERC20(token1).balanceOf(msg.sender) >= _amountToken1, "Insufficient funds");
        require(
            IERC20(token1).allowance(msg.sender, address(this)) >= _amountToken1,
            "You need allow us to spend this amount"
        );

        // Caclulate the amount of tokens to receive
        amountToken0 = getSwapToken0Estimate(_amountToken1);

        // Update the state
        totalToken1 += _amountToken1;
        totalToken0 -= amountToken0;

        // Transfer
        IERC20(token1).transferFrom(msg.sender, address(this), _amountToken1);
        IERC20(token0).transfer(msg.sender, amountToken0);
    }
}