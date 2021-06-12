/**
 *Submitted for verification at Etherscan.io on 2021-06-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

contract MultiSend {

    using SafeMath for uint256;

    // to save the owner of the contract in construction
    address private owner;

    // to save the amount of ethers in the smart-contract
    uint256 public totalValue_Maincoin;

    // to save the amount of ethers in the smart-contract
    uint256 public totalValue_Token;

    // token address
    IERC20 public token;

    // Add whitelistedaddresses in this
    mapping(address => bool) public whitelistedAddresses; // addresses eligible in presale

    address payable[] allWhitelistedAddresses;

    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    // modifier to check if the caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    /**
     * @dev Set contract deployer as owner
     */
    constructor() public {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);

        //total_value = msg.value;  // msg.value is the ethers of the transaction
    }

    // the owner of the smart-contract can chage its owner to whoever
    // he/she wants
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }

    // load amount in the contract
    // function loadMaincoin() payable public {
    //     // adding the message value to the smart contract
    //     totalValue_Maincoin += msg.value;
    // }

     // load amount in the contract
    function loadToken(address _token, uint256 _amount) public {
        // setting token address
        token = IERC20(_token);

        // adding the message value to the smart-contract
        totalValue_Token += _amount;

        // storing the token amount in the smart-contract
        token.transferFrom(msg.sender, address(this), _amount);
    }

    // charge enable the owner to store ether in the smart-contract
    // function chargeMaincoin() payable public isOwner {
    //     // adding the message value to the smart contract
    //     totalValue_Maincoin += msg.value;
    // }

     // charge enable the owner to store ether in the smart-contract
    function chargeToken(uint256 _amount) public isOwner {
        // adding the message value to the smart-contract
        totalValue_Token += _amount;

        // storing the token amount in the smart-contract
        token.transferFrom(msg.sender, address(this), _amount);
    }

    // sum adds the different elements of the array and return its sum
    function sum(uint[] memory amounts) private pure returns (uint retVal) {
        // the value of message should be exact of total amounts
        uint totalAmnt = 0;

        for (uint i=0; i < amounts.length; i++) {
            totalAmnt += amounts[i];
        }
        return totalAmnt;
    }

    //withdrawMaincoin perform the transfering of ethers
    function withdrawMaincoin(address payable receiverAddr, uint receiverAmnt) private {
        receiverAddr.transfer(receiverAmnt);
    }

    // withdrawToken perform the transfering of tokens
    function withdrawToken(address receiverAddr, uint receiverAmnt) private {
        token.transfer(receiverAddr, receiverAmnt);
    }

    function addwhitelistedAddresses(address payable[] calldata _whitelistedAddresses)
    public isOwner
    {
        uint256 local_variable = _whitelistedAddresses.length;
        for (uint256 i = 0; i < local_variable; i++) {
            whitelistedAddresses[_whitelistedAddresses[i]] = true;
            allWhitelistedAddresses.push(_whitelistedAddresses[i]);
        }
    }

    // withdrawls enable to multiple withdraws to different accounts
    // at one call, and decrease the network fee
    function withdrawlsToken(uint amnt) public isOwner {

        require(totalValue_Token >= amnt, "The value is not sufficient or exceed");

        totalValue_Token -= amnt;

        uint256 finalAmt = amnt.div(allWhitelistedAddresses.length);

        for (uint i=0; i < allWhitelistedAddresses.length; i++) {
            withdrawToken(allWhitelistedAddresses[i], finalAmt);
        }
    }

    // withdrawls enable to multiple withdraws to different accounts
    // at one call, and decrease the network fee
    // function withdrawlsMaincoin() payable public {

    //     require(address(this).balance >= msg.value, "The value is not sufficient or exceed");

    //     totalValue_Maincoin -= msg.value;

    //     //uint256 amount = address(this).balance.sub(msg.value);
    //     uint256 finalAmt = msg.value.div(allWhitelistedAddresses.length);

    //     for (uint i=0; i < allWhitelistedAddresses.length; i++) {
    //         withdrawMaincoin(allWhitelistedAddresses[i], finalAmt);
    //     }
    // }
}