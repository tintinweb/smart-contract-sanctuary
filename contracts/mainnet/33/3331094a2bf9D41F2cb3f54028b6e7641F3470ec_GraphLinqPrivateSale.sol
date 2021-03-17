// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

import "./libs/maths/SafeMath.sol";
import "./interfaces/IExtendedERC20.sol";

contract GraphLinqPrivateSale {
    using SafeMath for uint256;


    address private                         _owner;
    IExtendedERC20 private                  _glqToken;
    mapping(address => uint256) private     _wallets_investment;

    uint256 public                          _ethSolded;
    uint256 public                          _glqSolded;
    uint256 public                          _glqPerEth;
    uint256 public                          _maxethPerWallet;
    bool public                             _paused = false;
    bool public                             _claim = false;

    event NewAmountPresale (
        uint256 srcAmount,
        uint256 glqPereth,
        uint256 totalGlq
    );

    /*
    ** Description: constructing the contract basic informations, containing the GLQ token addr, the ratio price eth:GLQ
    ** and the max authorized eth amount per wallet
    */
    constructor(address graphLinqTokenAddr, uint256 glqPereth, uint256 maxethPerWallet)
    {
        _owner = msg.sender;
        _ethSolded = 0;
        _glqPerEth = glqPereth;
        _glqToken = IExtendedERC20(graphLinqTokenAddr);
        _maxethPerWallet = maxethPerWallet;
    }

    /*
    ** Description: Check that the transaction sender is the GLQ owner
    */
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only the owner can do this action");
        _;
    }

    /*
    ** Receive eth payment for the presale raise
    */
    receive() external payable {
        require(_paused == false, "Presale is paused");
        uint256 totalInvested = _wallets_investment[address(msg.sender)].add(msg.value);
        require(totalInvested <= _maxethPerWallet, "You depassed the limit of max eth per wallet for the presale.");
        _transfertGLQ(msg.value);
    }

    /*
    ** Description: Set the presale in pause state (no more deposits are accepted once it's turned back)
    */
    function setPaused(bool value) public payable onlyOwner {
        _paused = value;
    }

    /*
    ** Description: Set the presale claim mode 
    */
    function setClaim(bool value) public payable onlyOwner {
        _claim = value;
    }

    /*
    ** Description: Claim the GLQ once the presale is done
    */
    function claimGlq() public
    {
        require(_claim == true, "You cant claim your GLQ yet");
        uint256 srcAmount =  _wallets_investment[address(msg.sender)];
        require(srcAmount > 0, "You dont have any GLQ to claim");
        
        uint256 glqAmount = (srcAmount.mul(_glqPerEth)).div(10 ** 18);
         require(
            _glqToken.balanceOf(address(this)) >= glqAmount,
            "No GLQ amount required on the contract"
        );
        _wallets_investment[address(msg.sender)] = 0;
        _glqToken.transfer(msg.sender, glqAmount);
    }


    /*
    ** Description: Return the amount raised from the Presale (as ETH)
    */
    function getTotalRaisedEth() public view returns(uint256) {
        return _ethSolded;
    }

        /*
    ** Description: Return the amount raised from the Presale (as GLQ)
    */
    function getTotalRaisedGlq() public view returns(uint256) {
        return _glqSolded;
    }

    /*
    ** Description: Return the total amount invested from a specific address
    */
    function getAddressInvestment(address addr) public view returns(uint256) {
        return  _wallets_investment[addr];
    }

    /*
    ** Description: Transfer the specific GLQ amount to the payer address
    */
    function _transfertGLQ(uint256 _srcAmount) private {
        uint256 glqAmount = (_srcAmount.mul(_glqPerEth)).div(10 ** 18);
        emit NewAmountPresale(
            _srcAmount,
            _glqPerEth,
            glqAmount
        );

        require(
            _glqToken.balanceOf(address(this)) >= glqAmount.add(_glqSolded),
            "No GLQ amount required on the contract"
        );

        _ethSolded += _srcAmount;
        _glqSolded += glqAmount;
        _wallets_investment[address(msg.sender)] += _srcAmount;
    }

    /*
    ** Description: Authorize the contract owner to withdraw the raised funds from the presale
    */
    function withdraw() public payable onlyOwner {
        msg.sender.transfer(address(this).balance);
        _glqToken.transfer(msg.sender, _glqToken.balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IExtendedERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    function symbol() external view returns (string memory);

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


    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;

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