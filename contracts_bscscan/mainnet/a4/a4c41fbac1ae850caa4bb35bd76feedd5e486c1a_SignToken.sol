/**
 *Submitted for verification at BscScan.com on 2021-07-24
*/

pragma solidity >=0.6.12;

/*
 ____  _           _____     _                _       
/ ___|(_) __ _ _ _|_   _|__ | | _____ _ __   (_) ___  
\___ \| |/ _` | '_ \| |/ _ \| |/ / _ \ '_ \  | |/ _ \ 
 ___) | | (_| | | | | | (_) |   <  __/ | | |_| | (_) |
|____/|_|\__, |_| |_|_|\___/|_|\_\___|_| |_(_)_|\___/ 
         |___/

* There will be 1 SIGN minted every 1 block. When 10,072,021 SIGN is reached, no more can be minted
* You will get 1 Productivity Point when you sign a name on blockchain. The more Productivity Points you have, the more SIGN you can claim
* 0.01 BNB is the fee to pay per sign. When the total fee reaches 1 BNB will use it to buy SIGN on pancakeswap. Amount SIGN bought can't be transferred to another wallet
* Amount SIGN you can claim will be calculated according to the standard formula EIP-2917: 

    The Objective of ERC2917 is to implement a decentralized staking mechanism, which calculates users' share
    by accumulating productiviy * time. And calculates users revenue from anytime t0 to t1 by the formula below:

    user_accumulated_productivity(time1) - user_accumulated_productivity(time0)
    _____________________________________________________________________________  * (gross_product(t1) - gross_product(t0))
    total_accumulated_productivity(time1) - total_accumulated_productivity(time0)
*/


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

/*
    The Objective of ERC2917 Demo is to implement a decentralized staking mechanism, which calculates users' share
    by accumulating productiviy * time. And calculates users revenue from anytime t0 to t1 by the formula below:

        user_accumulated_productivity(time1) - user_accumulated_productivity(time0)
       _____________________________________________________________________________  * (gross_product(t1) - gross_product(t0))
       total_accumulated_productivity(time1) - total_accumulated_productivity(time0)

*/
contract ERC2917 {
    using SafeMath for uint256;

    uint256 public mintCumulation;
    uint256 public amountPerBlock;
    uint256 public nounce;

    function incNounce() public {
        nounce++;
    }

    // implementation of ERC20 interfaces.
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public maxSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
    event InterestRatePerBlockChanged(uint256 oldValue, uint256 newValue);
    event ProductivityIncreased(address indexed user, uint256 value);
    event ProductivityDecreased(address indexed user, uint256 value);

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual {
        require(balanceOf[from] >= value, "ERC20Token: INSUFFICIENT_BALANCE");
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        if (to == address(0)) {
            // burn
            totalSupply = totalSupply.sub(value);
        }
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value)
        external
        virtual
        returns (bool)
    {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value)
        external
        virtual
        returns (bool)
    {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external virtual returns (bool) {
        require(
            allowance[from][msg.sender] >= value,
            "ERC20Token: INSUFFICIENT_ALLOWANCE"
        );
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

    // end of implementation of ERC20
    uint256 lastRewardBlock;
    uint256 totalProductivity;
    uint256 accAmountPerShare;
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt.
        uint256 rewardEarn; // Reward earn and not minted
    }

    mapping(address => UserInfo) public users;

    // creation of the interests token.
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _interestsRate,
        uint256 _maxSupply
    ) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        amountPerBlock = _interestsRate;
        maxSupply = _maxSupply;
    }

    // External function call
    // This function adjust how many token will be produced by each block, eg:
    // changeAmountPerBlock(100)
    // will set the produce rate to 100/block.
    function _changeInterestRatePerBlock(uint256 value)
        internal
        virtual
        returns (bool)
    {
        uint256 old = amountPerBlock;
        require(value != old, "AMOUNT_PER_BLOCK_NO_CHANGE");

        _update();
        amountPerBlock = value;

        emit InterestRatePerBlockChanged(old, value);
        return true;
    }

    // Update reward variables of the given pool to be up-to-date.
    function _update() internal virtual {
        if (block.number <= lastRewardBlock) {
            return;
        }

        if (totalProductivity == 0) {
            lastRewardBlock = block.number;
            return;
        }

        uint256 reward = _currentReward();
        balanceOf[address(this)] = balanceOf[address(this)].add(reward);

        // check totalSupply reached maxSupply
        if(totalSupply.add(reward) >= maxSupply) {
            reward = maxSupply - totalSupply;
            // disable mint SIGN token
            amountPerBlock = 0;
        }

        totalSupply = totalSupply.add(reward);

        accAmountPerShare = accAmountPerShare.add(
            reward.mul(1e12).div(totalProductivity)
        );
        lastRewardBlock = block.number;
    }

    function _currentReward() internal view virtual returns (uint256) {
        uint256 multiplier = block.number.sub(lastRewardBlock);
        return multiplier.mul(amountPerBlock);
    }

    // Audit user's reward to be up-to-date
    function _audit(address user) internal virtual {
        UserInfo storage userInfo = users[user];
        if (userInfo.amount > 0) {
            uint256 pending = userInfo
            .amount
            .mul(accAmountPerShare)
            .div(1e12)
            .sub(userInfo.rewardDebt);
            userInfo.rewardEarn = userInfo.rewardEarn.add(pending);
            mintCumulation = mintCumulation.add(pending);
            userInfo.rewardDebt = userInfo.amount.mul(accAmountPerShare).div(
                1e12
            );
        }
    }

    // External function call
    // This function increase user's productivity and updates the global productivity.
    // the users' actual share percentage will calculated by:
    // Formula:     user_productivity / global_productivity
    function _increaseProductivity(address user, uint256 value)
        internal
        virtual
        returns (bool)
    {
        require(value > 0, "PRODUCTIVITY_VALUE_MUST_BE_GREATER_THAN_ZERO");

        UserInfo storage userInfo = users[user];
        _update();
        _audit(user);

        totalProductivity = totalProductivity.add(value);

        userInfo.amount = userInfo.amount.add(value);
        userInfo.rewardDebt = userInfo.amount.mul(accAmountPerShare).div(1e12);
        emit ProductivityIncreased(user, value);
        return true;
    }

    // External function call
    // This function will decreases user's productivity by value, and updates the global productivity
    // it will record which block this is happenning and accumulates the area of (productivity * time)
    function _decreaseProductivity(address user, uint256 value)
        internal
        virtual
        returns (bool)
    {
        UserInfo storage userInfo = users[user];
        require(
            value > 0 && userInfo.amount >= value,
            "INSUFFICIENT_PRODUCTIVITY"
        );
        _update();
        _audit(user);

        userInfo.amount = userInfo.amount.sub(value);
        userInfo.rewardDebt = userInfo.amount.mul(accAmountPerShare).div(1e12);
        totalProductivity = totalProductivity.sub(value);

        emit ProductivityDecreased(user, value);
        return true;
    }

    function takeWithAddress(address user) public view returns (uint256) {
        UserInfo storage userInfo = users[user];
        uint256 _accAmountPerShare = accAmountPerShare;
        // uint256 lpSupply = totalProductivity;
        if (block.number > lastRewardBlock && totalProductivity != 0) {
            uint256 reward = _currentReward();
            _accAmountPerShare = _accAmountPerShare.add(
                reward.mul(1e12).div(totalProductivity)
            );
        }
        return
            userInfo
                .amount
                .mul(_accAmountPerShare)
                .div(1e12)
                .sub(userInfo.rewardDebt)
                .add(userInfo.rewardEarn);
    }

    function take() external view virtual returns (uint256) {
        return takeWithAddress(msg.sender);
    }

    // Returns how much a user could earn plus the giving block number.
    function takeWithBlock() external view virtual returns (uint256, uint256) {
        uint256 earn = takeWithAddress(msg.sender);
        return (earn, block.number);
    }

    // External function call
    // When user calls this function, it will calculate how many token will mint to user from his productivity * time
    // Also it calculates global token supply from last time the user mint to this time.
    function _mint() internal virtual returns (uint256) {
        _update();
        _audit(msg.sender);
        require(users[msg.sender].rewardEarn > 0, "NO_PRODUCTIVITY");
        uint256 amount = users[msg.sender].rewardEarn;
        _transfer(address(this), msg.sender, users[msg.sender].rewardEarn);
        users[msg.sender].rewardEarn = 0;
        return amount;
    }

    // Returns how many productivity a user has and global has.
    function getProductivity(address user)
        external
        view
        virtual
        returns (uint256, uint256)
    {
        return (users[user].amount, totalProductivity);
    }

    // Returns the current gorss product rate.
    function interestsPerBlock() external view virtual returns (uint256) {
        return accAmountPerShare;
    }
}

interface IPancakePair {
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

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);
}

library PancakeLibrary {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'PancakeLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'PancakeLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'00fb7f630766e6a796048ea87d01acd3068e8ff67d078148a3fa3f4a84f69bd5' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        pairFor(factory, tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IPancakePair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'PancakeLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'PancakeLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(9975);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'PancakeLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(10000);
        uint denominator = reserveOut.sub(amountOut).mul(9975);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

interface IPancakeRouter {
    event AddLiquidity(
        address indexed player,
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB
    );
    event RemoveLiquidity(
        address indexed player,
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB
    );
    event SwapToken(
        address indexed receiver,
        address indexed fromToken,
        address indexed toToken,
        uint256 inAmount,
        uint256 outAmount
    );

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

    function swapExactTokensForTokens( uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline ) external returns (uint256[] memory amounts);
    function swapExactETHForTokens( uint256 amountOutMin, address[] calldata path, address to, uint256 deadline ) external payable returns (uint256[] memory amounts);
    function swapExactTokensForETH( uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline ) external returns (uint256[] memory amounts);
    function swapTokensForExactTokens( uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline ) external returns (uint256[] memory amounts);
    function swapTokensForExactETH( uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline ) external returns (uint256[] memory amounts);
    function swapETHForExactTokens( uint256 amountOut, address[] calldata path, address to, uint256 deadline ) external payable returns (uint256[] memory amounts);
    function WETH() external returns (address);
    function factory() external returns (address);
}

// SPDX-License-Identifier: UNLICENSED
/*
 ____  _           _____     _                _       
/ ___|(_) __ _ _ _|_   _|__ | | _____ _ __   (_) ___  
\___ \| |/ _` | '_ \| |/ _ \| |/ / _ \ '_ \  | |/ _ \ 
 ___) | | (_| | | | | | (_) |   <  __/ | | |_| | (_) |
|____/|_|\__, |_| |_|_|\___/|_|\_\___|_| |_(_)_|\___/ 
         |___/

* There will be 1 SIGN minted every 1 block. When 10,072,021 SIGN is reached, no more can be minted
* You will get 1 Productivity Point when you sign a name on blockchain. The more Productivity Points you have, the more SIGN you can claim
* 0.01 BNB is the fee to pay per sign. When the total fee reaches 1 BNB will use it to buy SIGN on pancakeswap. Amount SIGN bought can't be transferred to another wallet
* Amount SIGN you can claim will be calculated according to the standard formula EIP-2917: 

    The Objective of ERC2917 is to implement a decentralized staking mechanism, which calculates users' share
    by accumulating productiviy * time. And calculates users revenue from anytime t0 to t1 by the formula below:

    user_accumulated_productivity(time1) - user_accumulated_productivity(time0)
    _____________________________________________________________________________  * (gross_product(t1) - gross_product(t0))
    total_accumulated_productivity(time1) - total_accumulated_productivity(time0)
*/
contract SignToken is ERC2917("Sign Token", "SIGN", 18, 1 * 10**18, 10072021 * 10**18) { // amountPerBlock = 1 SIGN, maxSupply = 10072021 SIGN
    using SafeMath for uint;

    uint constant public FEE = 0.01 * 10**18;               // 0.01 BNB is the fee to pay per sign
    uint constant public MAX_FEE = 1 * 10**18;              // When the total fee reaches 1 BNB will use it to buy SIGN
    uint constant private MIN_STRING_LENGTH = 5;
    uint constant private MAX_STRING_LENGTH = 255;
    uint public nextSignId = 0;

    mapping(uint => string) private names;                  // signId => name;

    event Sign(address indexed user, uint indexed signId, string name);
    event Claim(address indexed user, uint amount);

    IPancakeRouter public immutable pancakeV2Router;

    constructor() public {
        pancakeV2Router = IPancakeRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    }

    function sign (string memory name) external payable returns (bool) {
        uint nameLength = bytes(name).length;
        require(nameLength >= MIN_STRING_LENGTH && nameLength <= MAX_STRING_LENGTH, "MIN_NAME_5 & MAX_NAME_255");
        require(msg.value >= FEE, "NOT_ENOUGH_FEE");

        _checkSwap();

        uint signId = nextSignId;
        names[signId] = name;
        uint currentProductivity = users[msg.sender].amount;
        _increaseProductivity(msg.sender, currentProductivity.add(1));

        nextSignId = nextSignId.add(1);

        emit Sign(msg.sender, signId, name);

        return true;
    }

    function claim () external returns (bool) {
        uint amount = _mint();
        emit Claim(msg.sender, amount);
        return true;
    }

    function getNameBySignId (uint signId) public view returns (string memory) {
        return names[signId];
    }

    function _checkSwap() internal {
        uint currentBalance = address(this).balance;

        if(currentBalance >= MAX_FEE) {
            _swapETHForToken(currentBalance);
        }
    }

    function _swapETHForToken(uint256 amountETH) private {
        address WETH = pancakeV2Router.WETH();
        address factory = pancakeV2Router.factory();
        address pair = PancakeLibrary.pairFor(factory, address(this), WETH);
        if(pair == address(0)) return;

        (uint reserveIn, uint reserveOut) = PancakeLibrary.getReserves(factory, WETH, address(this));
        uint amountOut = PancakeLibrary.getAmountOut(amountETH, reserveIn, reserveOut);

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(this);

        // buy token and transfer all to burn address
        pancakeV2Router.swapETHForExactTokens
        {value: amountETH}
        (
            amountOut,
            path,
            address(0), // burn address
            block.timestamp
        );
    }
}