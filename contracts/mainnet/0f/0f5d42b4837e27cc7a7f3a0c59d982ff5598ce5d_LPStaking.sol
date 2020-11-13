// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

library SafeMath {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


contract Pausable is Context {
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
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
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
        require(!_paused, "Pausable: paused");
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
        require(_paused, "Pausable: not paused");
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


contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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


contract ReentrancyGuard {
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

    constructor () internal {
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


pragma solidity ^0.6.0;

/// @title LP Staking Contract

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface INodeRunnersNFT {
    function getFighter(uint256 tokenId) external view returns (uint256, uint256, uint256, uint256, uint256, uint256);
    function mint(address to, uint256 id, uint256 amount) external;
}

interface IUniswap {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function WETH() external pure returns(address);
    function getAmountsOut(uint amountIn, address[] memory path) external pure returns (uint[] memory amounts);
}

interface IFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function totalSupply() external view returns (uint);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
}

contract LPStaking is ReentrancyGuard, Pausable, Ownable {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    address payable public treasury;
    address public NFT;
    address public NDR;
    IERC20 public rewardsToken;
    IERC20 public stakingToken;
    IUniswap public uniswap;
    IFactory public factory;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration = 360 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public interest = 10;
    uint256 public minLp = 2250000000000000000;
    uint256 public maxLp = 22500000000000000000;
    uint256 public mulHero1;
    uint256 public mulHero2;
    uint256 public mulSupport1;
    uint256 public mulSupport2;
    uint256 public deadline = 180;
    uint256 public feeRate = 50;
    uint256 private _totalSupply;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) private _balances;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address payable _treasury,
        address _NFT,
        address _NDR,
        address _rewardsToken,
        address _stakingToken,
        address _uniswap,
        address _factory
    ) public {
        treasury = _treasury;
        NFT = _NFT;
        NDR = _NDR;
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        uniswap = IUniswap(_uniswap);
        factory = IFactory(_factory);
    }

    /**
    * @dev Initiate the account of destinations[i] with values[i]. The function must only be called when the contract is paused. The caller must check that destinations are unique addresses.
    * For a large number of destinations, separate the balances initialization in different calls to batchTransfer.
    * @param destinations List of addresses to set the values
    * @param values List of values to set
    */
    function batchTransfer(address[] memory destinations, uint256[] memory values) public onlyOwner whenPaused {
        require(destinations.length == values.length);

        uint256 length = destinations.length;
        uint i;

        for (i=0; i < length; i++) {
            rewards[destinations[i]] = values[i];
        }
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            _balances[account]
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    function min(uint256 a, uint256 b) public pure returns (uint256) {
        return a < b ? a : b;
    }

    /* ========== UNISWAP FUNCTIONS ========== */

    receive() payable external {
        assert(msg.sender == uniswap.WETH());
    }

    function getAmountsOut(uint amount, address token) internal view returns (uint) {
        uint[] memory amounts = uniswap.getAmountsOut(amount, getPathForTokenToEth(token));
        uint256 outputTokenCount = uint256(amounts[amounts.length - 1]);
        return outputTokenCount;
    }

    function getPathForTokenToEth(address token) internal view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = uniswap.WETH();
        path[1] = token;
        return path;
    }

    function swapExactETHForTokens(uint amountEth) internal {
        uniswap.swapExactETHForTokens.value(amountEth)(0, getPathForTokenToEth(address(NDR)), address(this), now + deadline);
    }

    function addLiquidityETH(uint amountTokenDesired, uint amountEth) internal {
        IERC20(NDR).approve(address(uniswap), amountTokenDesired);
        uint amountADesired = getAmountsOut(amountEth, NDR);
        (uint amountTokenMin,) = quote(amountADesired, amountEth);
        uniswap.addLiquidityETH.value(amountEth)
        (address(NDR), amountTokenDesired, amountTokenMin, amountEth, address(0), now + deadline);
    }

    function quote(uint amountADesired, uint amountBDesired) internal view returns(uint, uint) {
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(address(factory), NDR, uniswap.WETH());
        uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
        uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
        return (amountAOptimal, amountBOptimal);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function pause() public onlyOwner whenNotPaused {
        _pause();
        emit Paused(msg.sender);
    }

    function unpause() public onlyOwner whenPaused {
        _unpause();
        emit Unpaused(msg.sender);
    }

    function changeAddresses(address payable _treasury, address _NFT, address _NDR, address _rewardsToken, address _stakingToken, address _uniswap, address _factory) public onlyOwner {
        treasury = _treasury;
        NFT = _NFT;
        NDR = _NDR;
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        uniswap = IUniswap(_uniswap);
        factory = IFactory(_factory);
    }

    function changeMultiplierHero(uint256 _mulHero1, uint256 _mulHero2) public onlyOwner returns(uint256, uint256) {
        mulHero1 = _mulHero1;
        mulHero2 = _mulHero2;
        return (mulHero1, mulHero2);
    }
    
    function changeMultiplierSupport(uint256 _mulSupport1, uint256 _mulSupport2) public onlyOwner returns(uint256, uint256) {
        mulSupport1 = _mulSupport1;
        mulSupport2 = _mulSupport2;
        return (mulSupport1, mulSupport2);
    }

    function changeDeadline(uint256 _deadline) public onlyOwner returns(uint256) {
        deadline = _deadline;
        return deadline;
    }

    function changeInterest(uint256 _interest) public onlyOwner returns(uint256) {
        interest = _interest;
        return interest;
    }

    function changeLpAmount(uint256 _minLp, uint256 _maxLp) public onlyOwner returns(uint256, uint256) {
        minLp = _minLp;
        maxLp = _maxLp;
        return (minLp, maxLp);
    }

    function changeFeeRate(uint256 _feeRate) public onlyOwner returns(uint256) {
        feeRate = _feeRate;
        return feeRate;
    }

    function withdrawDust(uint256 amount) public onlyOwner {
        treasury.transfer(amount);
    }

    function stake(uint256 amount) external nonReentrant whenNotPaused updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        require(_balances[msg.sender].add(amount) >= minLp && _balances[msg.sender].add(amount) <= maxLp, "wrong amount");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakingToken.transferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        require(_balances[msg.sender].sub(amount) >= minLp || _balances[msg.sender].sub(amount) == 0, "wrong amount");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        uint256 fee = amount.div(feeRate);
        stakingToken.transfer(0x1111111111111111111111111111111111111111, fee);
        stakingToken.transfer(msg.sender, amount.sub(fee));
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
    }
    
    function getPriceHero(uint256 rarity) public view returns (uint) {
        (,uint reserves2) = UniswapV2Library.getReserves(address(factory), NDR, uniswap.WETH());
        uint price = reserves2 * 1e18 / IUniswapV2Pair(address(stakingToken)).totalSupply() * 2;
        return price * rarity * mulHero1 / mulHero2;
    }
    
    function getPriceSupport(uint256 rarity) public view returns (uint) {
        (,uint reserves2) = UniswapV2Library.getReserves(address(factory), NDR, uniswap.WETH());
        uint price = reserves2 * 1e18 / IUniswapV2Pair(address(stakingToken)).totalSupply() * 2;
        return price * rarity * mulSupport1 / mulSupport2;
    }

    function redeem(uint256 tokenId) public nonReentrant whenNotPaused updateReward(msg.sender) {
        (,,,,uint256 hashPrice,) = INodeRunnersNFT(address(NFT)).getFighter(tokenId);
        require(hashPrice > 0, "can't buy in hash");
        uint256 reward = rewards[msg.sender];
        require(reward >= hashPrice, "not enough hash");
        rewards[msg.sender] = rewards[msg.sender].sub(hashPrice);
        INodeRunnersNFT(NFT).mint(msg.sender, tokenId, 1);
        emit RewardPaid(msg.sender, reward);
    }

    function buy(uint256 tokenId) public nonReentrant whenNotPaused payable {
        (,,,uint256 rarity,,uint256 series) = INodeRunnersNFT(address(NFT)).getFighter(tokenId);
        uint256 price;
        if (series == 1) {
            price = getPriceHero(rarity);
        } else if (series == 2) {
            price = getPriceSupport(rarity);
        } else {
            revert("wrong id");
        }
        require(msg.value >= price, "wrong value");
        uint fee = msg.value / interest;
        treasury.transfer(fee);
        uint amountEth = (msg.value - fee) / 2;
        uint amountToken = getAmountsOut(amountEth, address(NDR));
        swapExactETHForTokens(amountEth);
        addLiquidityETH(amountToken, amountEth * 99 / 100);
        INodeRunnersNFT(NFT).mint(msg.sender, tokenId, 1);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward) external onlyOwner updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }
        uint256 balance = rewardsToken.balanceOf(address(this));
        require(
            rewardRate <= balance.div(rewardsDuration),
            "Provided reward too high"
        );
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        // Cannot recover the staking token or the rewards token
        require(
            tokenAddress != address(stakingToken) &&
                tokenAddress != address(rewardsToken),
            "Cannot withdraw the staking or rewards tokens"
        );
        IERC20(tokenAddress).transfer(this.owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);
}