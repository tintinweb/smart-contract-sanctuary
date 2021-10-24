/**
 *Submitted for verification at BscScan.com on 2021-10-23
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol



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

// File: contracts/LPGame.sol


// email "contracts [at] royalprotocol.io" for licensing information
pragma solidity ^0.8.7;



// This is the main building block for smart contracts.
contract LP {

    using SafeMath for uint256;
    //using 50 here with 1000 divisor instead of 5/100 so that we can reduce to 2.5% at end
    uint256 public depositTax = 50;
    uint256 public withdrawTax = 50;

    address public owner;
    address public _lpToken;
    address public _gRoyToken;

    uint256 public totalLP;
    uint256 public taxedLP;
    bool public _paused = true;
    bool public _ended = false;

    mapping(address => uint256) balances;
    mapping(address =>  uint) public _gRoyTokenBalance;
    mapping(address =>  bool) public _gRoyClaimable;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier paused {
        require(_paused == false);
        _;
    }

    modifier ended {
        require(_ended == true);
        _;
    }

    event Deposit(address indexed _from, uint amount, uint taxedAmount);
    event Withdrawal(address indexed _from, uint amount, uint taxedAmount);

    constructor(address lpToken, address gRoyToken) {
        owner = msg.sender;
        _lpToken = lpToken;
        _gRoyToken = gRoyToken;
    }

    function deposit(uint256 amount) external paused() {
        uint256 postTaxedAmount;
        uint256 taxes;
        taxes = amount * depositTax / 1000;
        postTaxedAmount = amount.sub(taxes);
        totalLP += amount;
        taxedLP += taxes;
        balances[msg.sender].add(postTaxedAmount);

        //requires approval
        IERC20(_lpToken).transferFrom(
            msg.sender,
            address(this),
            amount
        );

        emit Deposit(msg.sender, amount, postTaxedAmount);
    }

    function withdraw(uint256 amount) external paused() {
        uint256 addressBalance;
        uint256 postTaxedAmount;
        uint256 taxes;

        addressBalance = balances[msg.sender];
        require(addressBalance >= amount, "Not enough tokens");
        taxes = amount * withdrawTax / 1000;
        postTaxedAmount = amount.sub(taxes);

        require(addressBalance >= postTaxedAmount, "balance varies from withdraw request");
        balances[msg.sender] = addressBalance.sub(postTaxedAmount);

        require(addressBalance >= amount, "Not enough tokens");
        IERC20(_lpToken).transfer(
                msg.sender, 
                postTaxedAmount
                );


        emit Withdrawal(msg.sender, amount, postTaxedAmount);
    }

    event GroyClaim(address indexed _address, uint amount);
    function withdrawGroy() external paused() {
            uint256 gRoyBalance;
            require(_gRoyClaimable[msg.sender] == true, "You are not eligable to claim this yet");
            gRoyBalance = _gRoyTokenBalance[msg.sender];
            _gRoyTokenBalance[msg.sender] = gRoyBalance.sub(_gRoyTokenBalance[msg.sender]);
            _gRoyClaimable[msg.sender] = false;

            IERC20(_gRoyToken).transfer(
                msg.sender,
                gRoyBalance
                );

            emit GroyClaim(msg.sender, gRoyBalance);
        }

    function endGame() external onlyOwner() {
            _ended = true;
        }

    // once the game is ended the owner can withdraw the remaining gRoy and LP taxes
    function withdrawGroyAdmin(uint amount) external onlyOwner() ended() {
            IERC20(_gRoyToken).transfer(
                msg.sender, 
                amount
                );
        }

    function withdrawLpAdmin(uint amount) external onlyOwner() ended() {
            IERC20(_lpToken).transfer(
                msg.sender, 
                amount
                );
        }

    // depositing and withdrawal costs a fee of 5% tax, after ended the tax will go down for withdrawal
    // this will change to 25
    function updateWithdrawTax(uint amount) external onlyOwner() ended() {
            require(amount == 50 || amount == 25,"can't tax this, dun dununun");
            withdrawTax = amount;
        }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function distributeLpRewards(address[] calldata users, uint[] calldata amounts) external onlyOwner() {

        require(users.length == amounts.length, "the lists don't match lengths");
        uint256 listSize;
        listSize = users.length;

        for (uint i = 0; i < listSize; i++) {
                balances[users[i]] = balances[users[i]].add(amounts[i]);
            }
    }
    
    //requires us depositing enough GROY to this contract so withdrawals are happy
    function distributeGroyRewards(address[] calldata users, uint[] calldata amounts) external onlyOwner() {
        require(users.length == amounts.length, "the lists don't match lengths");
        uint256 listSize;
        listSize = users.length;

        for (uint i = 0; i < listSize; i++) {
            _gRoyTokenBalance[users[i]] = _gRoyTokenBalance[users[i]].add(amounts[i]);
            _gRoyClaimable[users[i]] = true;
        }
    }

    //does this work or do I need eip-165?
    function withdrawBadSend(address tokenAddress, uint256 amount) external onlyOwner() ended() {
        IERC20(tokenAddress).transfer(
                msg.sender, 
                amount
        );
    }
}