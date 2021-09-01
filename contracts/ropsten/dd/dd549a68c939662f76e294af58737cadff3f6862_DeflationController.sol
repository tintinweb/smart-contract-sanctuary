/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
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

pragma solidity ^0.6.0;

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


contract DeflationController is Ownable {
    using SafeMath for uint256;

// what is EOA? ---> An account created by or for human users of the Ethereum network. --> https://ethereum.org/en/glossary/
//Externally owned account (EOAs): an account controlled by a private key, and if you own the private key associated with the EOA you have the ability to send ether and messages from it. 
//Basically the deflation controller will be able to interact with the address of contracts so that it burns or not, if it is not necessary.
//the maximum burn is 10%

   uint256 public eoaFee = 25; // default burn for EOA  0.25%

   uint256 public defFee = 50; // default burn for nonEOA 0.5%

   uint256 constant public MAX_DEFLATION_ALLOWED = 1000; // 10%

   event SetRule(address indexed _address,uint256 _senderFee,uint256 _callerFee,uint256 _recipientFee);
   event SetRuleStatus(address indexed _address,bool _status);
   event SetEoaFee(uint256 eoaFee);
   event SetDefFee(uint256 defFee);

 
   //deflation rule
   struct DeflationRule {
        uint256 senderFee;
        uint256 callerFee;
        uint256 recipientFee;
        bool active;
    }

   mapping (address => DeflationRule ) public rules;

    /**
     * Check burn amount following DeflationRule, returns how much amount will be burned
     *
     * */
  function checkDeflation(address origin,address caller,address _from,address recipient, uint256 amount) external view returns (uint256){

        uint256 burnAmount = 0;

        DeflationRule memory fromRule = rules[_from];
        DeflationRule memory callerRule = rules[caller];
        DeflationRule memory recipientRule = rules[recipient];

        //check transfers and transferFrom to/from caller but not fransferfrom to diferent recipient
        if(callerRule.active && callerRule.callerFee>0){
            //default caller rule fee
                 burnAmount = burnAmount.add(amount.mul(callerRule.callerFee).div(10000));
        }

         // check transfer/TransferFrom from any caller to a selected recipient
        if(recipientRule.active && recipientRule.recipientFee>0){
                burnAmount = burnAmount.add(amount.mul(recipientRule.recipientFee).div(10000));
        }

        // check fr0m fee from a selected from
        if(fromRule.active && fromRule.senderFee>0){
                burnAmount = burnAmount.add(amount.mul(fromRule.senderFee).div(10000));
        }

        //normal transfer and transferFrom from eoa (called directly)
        if( burnAmount==0 && origin==caller && eoaFee>0 && !callerRule.active && !recipientRule.active && !fromRule.active)
        {
            burnAmount = burnAmount.add(amount.mul(eoaFee).div(10000));

        //no burn because no rules on that tx, setUp default burn
        }else if(burnAmount==0 && origin!=caller &&    defFee>0 && !callerRule.active && !recipientRule.active && !fromRule.active)
        {
            burnAmount = burnAmount.add(amount.mul(defFee).div(10000));
        }


        return burnAmount;
    }

    function setRule(address _address,uint256 _senderFee,uint256 _callerFee,uint256 _recipientFee,bool _active) external onlyOwner
    {
        require(_senderFee<=MAX_DEFLATION_ALLOWED && _callerFee<=MAX_DEFLATION_ALLOWED && _recipientFee <= MAX_DEFLATION_ALLOWED );
         rules[_address] = DeflationRule({
             senderFee : _senderFee,
             callerFee:_callerFee,
             recipientFee:_recipientFee,
             active : _active
        });

        emit SetRule(_address,_senderFee,_callerFee,_recipientFee);
        emit SetRuleStatus(_address,_active);
    }

    function setRuleStatus(address _address,bool _active)  external onlyOwner
    {
         rules[_address].active=_active;

         emit SetRuleStatus(_address,_active);

    }


   function setEoaFee(uint256 _eoaFee) external onlyOwner
   {
        require(_eoaFee<=MAX_DEFLATION_ALLOWED);
        eoaFee = _eoaFee;
        emit SetEoaFee(_eoaFee);
   }

    function setDefFee(uint256 _defFee) external onlyOwner
   {
       require(_defFee<=MAX_DEFLATION_ALLOWED);
        defFee = _defFee;
        emit SetDefFee(_defFee);
   }

}