/**
 *Submitted for verification at Etherscan.io on 2020-11-16
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */

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
}

interface IUniswapV2Router02 {
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

// Long live and prosper...
contract DexnesPresaleAndLiquidityLock {

    using SafeMath for uint256;

    IUniswapV2Router02 internal constant UNISWAP = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    struct WhitelistInfo {
        uint256 whitelisted;
        uint256 boughtAmount;
    }

    uint256 public startTimestamp = 1605535200; // 11/16/2020 @ 2:00pm (UTC)
    uint256 public endTimestamp = startTimestamp.add(1 days); // ends after a day
    uint256 public lockDuration = 31 days; // liquidity locked for 31 days

    IERC20 public dnesToken = IERC20(address(0xD1706eAf3C60b69942F29b683D857e01428c459F)); // dexnes token
    address public dexnesCaptain = address(0xA34757fC1e8EAD538C4ef2Ef23286517A7a9d0a7); // staking contract

    uint256 public locked;
    uint256 public unlockTimestamp;

    uint256 public maxAllowed = 3 ether;
    uint256 public liquidityPercentage = 75;
    uint256 public weiRaised;

    address[] internal buyers;
    mapping(address => WhitelistInfo) public whitelist;

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function addToWhitelist(address[100] calldata _addresses) public {
        require(msg.sender == owner, "Caller is not owner");

        for (uint i = 0; i < _addresses.length; i++) {
            address addy = _addresses[i];
            if (addy != address(0)) {
                whitelist[addy] = WhitelistInfo(1, 0);
            }
        }
    }

    function unlockLiquidity(IERC20 _uniLpToken) public {
        require(locked == 1, "Liquidity is not yet locked");
        require(isClosed(), "Liqudity cannot be unlocked as the presale is not yet closed");
        require(block.timestamp >= unlockTimestamp, "Liqudity cannot be unlocked as the block timestamp is before the unlock timestamp");

        _uniLpToken.transfer(owner, _uniLpToken.balanceOf(address(this)));
    }

    // adds liquidity to uniswap (ratio is 1.5 eth = 1 dnes)
    // 75% of the raised eth will be put into liquidity pool
    // 25% of the raised eth will be used for marketing
    // unsold tokens will be sent to the mining pool
    function lockLiquidity() public {
        require(locked == 0, "Liquidity is already locked");
        require(isClosed(), "Presale is either still open or not yet opened");

        locked = 1;
        unlockTimestamp = block.timestamp.add(lockDuration);

        addLiquidity();
        distributeTokensToBuyers();

        payable(owner).transfer(address(this).balance);

        dnesToken.transfer(dexnesCaptain, dnesToken.balanceOf(address(this)));
    }

    function addLiquidity() internal {
        uint256 ethForLiquidity = weiRaised.mul(liquidityPercentage).div(100);
        uint256 tokenForLiquidity = ethForLiquidity.div(150).mul(100);

        dnesToken.approve(address(UNISWAP), tokenForLiquidity);

        UNISWAP.addLiquidityETH
        {value : ethForLiquidity}
        (
            address(dnesToken),
            tokenForLiquidity,
            0,
            0,
            address(this),
            block.timestamp + 100000000
        );
    }

    function distributeTokensToBuyers() internal {
        for (uint i = 0; i < buyers.length; i++) {
            address buyer = buyers[i];
            uint256 tokens = whitelist[buyer].boughtAmount;

            if (tokens > 0) {
                dnesToken.transfer(buyer, tokens);
            }
        }
    }

    function isOpen() public view returns (bool) {
        return !isClosed() && block.timestamp >= startTimestamp;
    }

    function isClosed() public view returns (bool) {
        return block.timestamp >= endTimestamp;
    }

    function buyTokens() payable public {
        require(isOpen(), "Presale is either already closed or not yet open");
        require(whitelist[msg.sender].whitelisted == 1, "Address is not included in the whitelist");
        require(dnesToken.balanceOf(address(this)) >= msg.value, "Contract does not have enough token balance");

        uint256 boughtAmount = whitelist[msg.sender].boughtAmount.add(msg.value);
        require(boughtAmount <= maxAllowed, "Whitelisted address can only buy a maximum of 3 ether");

        buyers.push(msg.sender);
        whitelist[msg.sender].boughtAmount = boughtAmount;
        weiRaised = weiRaised.add(msg.value);

        dnesToken.transfer(msg.sender, msg.value);
    }

    receive() external payable {
        buyTokens();
    }
}