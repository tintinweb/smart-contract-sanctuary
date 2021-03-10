/**
 *Submitted for verification at Etherscan.io on 2021-03-09
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-03
*/

pragma solidity ^0.5.0;


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

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
}


pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    function decimals() external view returns (uint8);

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

    function mint(address account, uint256 amount) external;

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



interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}



interface CurvePoolLike {
    function balances(uint256 idx) external view returns (uint256);
    function coins(uint256 idx) external view returns (address);
}




/**
 * @title oracle for Uniswap LP tokens which contains stable coins
 * this contract assume USDT token may be part of pool
 * all stables except USDT assumed eq 1 USD
 *
*/
contract CurveAdapterPriceOracle_Buck_Buck {
    using SafeMath for uint256;

    IERC20 public gem;
    CurvePoolLike public pool;
    uint256 public numCoins;
    address public deployer;

    AggregatorV3Interface public priceETHUSDT;
    AggregatorV3Interface public priceUSDETH;
    address public usdtAddress;

    constructor() public {
        deployer = msg.sender;
    }

    /**
     * @dev initialize oracle
     * _gem - address of CRV pool token contract
     * _pool - address of CRV pool token contract
     * num - num of tokens in pools
     */
    function setup(address _gem, address _pool, uint256 num) public {
        require(deployer == msg.sender);
        gem = IERC20(_gem);
        pool = CurvePoolLike(_pool);
        numCoins = num;
    }

    function resetDeployer() public {
        require(deployer == msg.sender);
        deployer = address(0);
    }

    function setupUsdt(
        address _priceETHUSDT,
        address _priceUSDETH,
        address _usdtAddress,
        bool usdtAsString) public {

        require(address(pool) != address(0));

        require(deployer == msg.sender);
        require(_usdtAddress != address(0));
        require(_priceETHUSDT != address(0));
        require(_priceUSDETH != address(0));


        (bool success, bytes memory returndata) =
            address(_usdtAddress).call(abi.encodeWithSignature("symbol()"));
        require(success, "USDT: low-level call failed");

        require(returndata.length > 0);
        if (usdtAsString) {
            bytes memory usdtSymbol = bytes(abi.decode(returndata, (string)));
            require(keccak256(bytes(usdtSymbol)) == keccak256("USDT"));
        } else {
            bytes32 usdtSymbol = abi.decode(returndata, (bytes32));
            require(usdtSymbol == "USDT");
        }

        priceETHUSDT = AggregatorV3Interface(_priceETHUSDT);
        priceUSDETH  = AggregatorV3Interface(_priceUSDETH);
        usdtAddress = _usdtAddress;

        deployer = address(0);
    }

    function usdtCalcValue(uint256 value) internal view returns (uint256) {
        uint256 price1Div =
            10 **
                (
                    uint256(priceETHUSDT.decimals()).add(uint256(priceUSDETH.decimals())).add(
                        uint256(IERC20(usdtAddress).decimals())
                    )
                );

        (, int256 answerUSDETH, , , ) = priceUSDETH.latestRoundData();
        (, int256 answerETHUSDT, , , ) = priceETHUSDT.latestRoundData();

        uint256 usdtPrice = uint256(answerUSDETH).mul(uint256(answerETHUSDT));
        return value.mul(usdtPrice).div(price1Div);
    }


    /**
     * @dev calculate price
     */
    function calc() internal view returns (bytes32, bool) {

        uint256 totalSupply = gem.totalSupply();
        uint256 decimals = gem.decimals();

        uint256 totalValue = 0;
        for (uint256 i = 0; i<numCoins; i++) {
            uint256 value = pool.balances(i).mul(1e18).mul(uint256(10)**decimals).div(totalSupply);

            if (pool.coins(i) == usdtAddress) {

                totalValue = totalValue.add(usdtCalcValue(value));
            }
            else {
                uint256 tokenDecimalsF = uint256(10)**uint256(IERC20(pool.coins(i)).decimals());

                totalValue = totalValue.add(value.div(tokenDecimalsF));
            }
        }

        return (
            bytes32(
                totalValue
            ),
            true
        );

    }

    /**
     * @dev base oracle interface see OSM docs
     */
    function peek() public view returns (bytes32, bool) {
        return calc();
    }

    /**
     * @dev base oracle interface see OSM docs
     */
    function read() public view returns (bytes32) {
        bytes32 wut;
        bool haz;
        (wut, haz) = calc();
        require(haz, "haz-not");
        return wut;
    }
}