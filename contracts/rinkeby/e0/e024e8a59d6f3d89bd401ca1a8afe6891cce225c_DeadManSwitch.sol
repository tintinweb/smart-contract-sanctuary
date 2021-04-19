/**
 *Submitted for verification at Etherscan.io on 2021-04-18
*/

// File: contracts/lib/Context.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/lib/Ownable.sol


pragma solidity >=0.6.0 <0.7.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/Ownership.sol


pragma solidity >=0.6.0 <0.7.0;


/**
 * @title Reference implementation of the Ownership, where it contains a single owner and a single beneficiary, and allow transfer of ownership
 */
contract Ownership is Ownable {
    /**
     * @dev the beneficiaryAccount where the DeadManSwitch's contract will send when the contract expires.
     */
    address private _beneficiary;

    event BeneficiaryTransferred(
        address indexed previousBeneficiary,
        address indexed newBeneficiary
    );

    constructor(address beneficiaryAddress) internal {
        _beneficiary = beneficiaryAddress;
        emit BeneficiaryTransferred(address(0), beneficiaryAddress);
    }

    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    modifier onlyBeneficiary() {
        require(isBeneficiary(), "Beneficiary: caller is not the beneficiary");
        _;
    }

    function isBeneficiary() public view returns (bool) {
        return _msgSender() == _beneficiary;
    }

    function transferBeneficiary(address newBeneficiary) public onlyOwner {
        _transferBeneficiary(newBeneficiary);
    }

    function _transferBeneficiary(address newBeneficiary) internal {
        require(
            newBeneficiary != address(0),
            "Beneficiary: new owner is the zero address"
        );
        emit BeneficiaryTransferred(_beneficiary, newBeneficiary);
        _beneficiary = newBeneficiary;
    }
}

// File: contracts/lib/SafeMath.sol

pragma solidity >=0.6.0 <0.7.0;

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
    function sub(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
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
    function div(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
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
    function mod(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/lib/IERC20.sol


pragma solidity >=0.6.0 <0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(address sender, address recipient, uint256 amount)
        external
        returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: contracts/DeadManSwitch.sol

pragma solidity >=0.6.0 <0.7.0;




/**
 * @title Reference implementation of the DeadManSwitch for Ether and ERC20 token locked.
 */
contract DeadManSwitch is Ownership {
    using SafeMath for uint256;

    // Storage
    /**
     * @dev Returns the last time the owner call `proveAlive` on which block.
     */
    uint256 public lastCheckInBlock;
    /**
     * @dev Returns the threshold block difference in order to allow `claim()` to be called
     * Useful for setting a certain period of time to `prove`.
     */
    uint256 public blockThreshold;

    bool public active;

    // Event
    event Transfer(
        address indexed contractAddress, 
        address indexed from,
        address indexed to,
        uint256 amount
    );

    /**
     * @dev A modifier that allows both owner and beneficiary (when owner isDead) to access to the method
     */
    modifier onlyAllowWithdrawal() {
        require(msg.sender == owner() || (msg.sender == beneficiary() && isDead()), "Required permission");
        _;
    }

    constructor(uint256 _blockThreshold, address payable _beneficiaryAccount) Ownership(_beneficiaryAccount)
        public
    {
        lastCheckInBlock = block.number;
        blockThreshold = _blockThreshold;
        active = true;
    }

    function setActive(bool _active) public onlyAllowWithdrawal {
        active = _active;
    }


    /**
     * @dev For Owner to prove alive
     */
    function proveAlive() public onlyOwner {
        lastCheckInBlock = block.number;
    }

    /**
     * @dev For Owner to update the threshold of the block
     */
    function updateBlockThreshold(uint256 _blockThreshold) public onlyOwner {
        lastCheckInBlock = block.number;
        blockThreshold = _blockThreshold;
    }

    /**
     * @dev DeadManSwitch concept of proving alive, when the blockNumDiff has passed the threshold, return true
     */
    function isDead() public view returns (bool) {
        uint256 blockNumDiff = block.number.sub(lastCheckInBlock);
        return blockNumDiff >= blockThreshold;
    }


    function refund(
        address _tokenAddress,
        uint256 _amount
    ) public onlyAllowWithdrawal {
        if (_tokenAddress == address(0)) {
            // Ether fund
            address payable self = address(this);
            require(_amount <= self.balance, "Insufficient ETH balance");
            (bool success, ) = msg.sender.call{value:_amount}("");
            require(success, "[sendFunds] ETH Transfer failure");
            emit Transfer(
                address(0),
                address(this),
                msg.sender,
                _amount
            );
        } else {
            // ERC20 fund
            IERC20 token = IERC20(_tokenAddress);
            address self = address(this);
            require(_amount <= token.balanceOf(self), "Insufficient ERC20 balance");
            require(token.transfer(msg.sender, _amount), "Cannot transsfer ERC20");
            emit Transfer(
                _tokenAddress,
                address(this),
                msg.sender,
                _amount
            );
        }
    }

    /**
     * @dev Allow deposit of ERC20 with the prerequisite of allowance, need to call `approve()` in ERC20 contract before using this
     */
    function depositERC20(address _contractAddress, uint256 _amount) external {
        IERC20 token = IERC20(_contractAddress);
        address self = address(this);
        require(_amount <= token.balanceOf(msg.sender), "Insufficient balance.");
        require(_amount <= token.allowance(msg.sender, self), "Insufficient allowance.");
        require(token.transferFrom(msg.sender, self, _amount), "Cannot transfer ERC20 token");
        assert(token.balanceOf(self) >= _amount);
        emit Transfer(
            _contractAddress,
            msg.sender,
            address(this),
            _amount
        );
    }

    function destroy() external onlyOwner {
		selfdestruct(msg.sender);
	}

    /** 
     * @dev Allow contract to receive any eth
     */
    receive() external payable {
        emit Transfer(
            address(0),
            msg.sender,
            address(this),
            msg.value
        );
    }

}