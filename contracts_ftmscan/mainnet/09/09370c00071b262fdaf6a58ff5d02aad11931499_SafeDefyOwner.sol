/**
 *Submitted for verification at FtmScan.com on 2022-01-26
*/

// SPDX-License-Identifier: MIT

//Website : https://defyswap.finance/

pragma solidity ^0.6.12;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the ERC token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

// 
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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        return mod(a, b, 'SafeMath: modulo by zero');
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

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

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
    constructor () public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
interface DefyMaster {
    function secondR() external view returns (address);
    function setImpermanentLossProtection(address _ilp) external returns (bool);
    function setFeeAddress(address _feeAddress)external returns (bool) ;
    function updateEmissionRate(uint256 endTimestamp) external  ;
    function updateSecondReward(uint256 _reward, uint256 _endTimestamp) external ;
    function add(uint256 _allocPoint, uint256 _allocPointDR, IERC20 _lpToken, IERC20 _stub, IERC20 _token0, 
    IERC20 _token1, uint256 _depositFee, uint256 _withdrawalFee, bool _offerILP,  bool _issueSTUB,
    uint256 _rewardEndTimestamp) external ;

    function set(uint256 _pid, uint256 _allocPoint,uint256 _allocPointDR,IERC20 _token0, IERC20 _token1, 
    uint256 _depositFee,uint256 _withdrawalFee,bool _offerILP, bool _issueSTUB,uint256 _rewardEndTimestamp) external ;

    function dev(address _devaddr) external ;
}
// The SafeOwner is the new DefyMaster owner. Using to implement the audit suggestions.
contract SafeDefyOwner is Ownable {
    using SafeMath for uint256;

    DefyMaster public defyMaster;
    
    constructor(DefyMaster _defyMaster) public {
        defyMaster = _defyMaster;
    }

	function setImpermanentLossProtection(address _ilp)public onlyOwner returns (bool){
        require(_ilp != address(0), 'DEFY: ILP cannot be the zero address');
        defyMaster.setImpermanentLossProtection(_ilp);
        return true;
    }
    
    function setFeeAddress(address _feeAddress)public onlyOwner returns (bool){
        require(_feeAddress != address(0), 'DEFY: FeeAddress cannot be the zero address');
        defyMaster.setFeeAddress(_feeAddress);
        return true;
    }

    function updateEmissionRate(uint256 endTimestamp)public onlyOwner returns (bool){
        require(endTimestamp > ((block.timestamp).add(182 days)), "Minimum duration is 6 months");
        defyMaster.updateEmissionRate(endTimestamp);
        return true;
    }

    function updateSecondReward(uint256 _reward, uint256 _endTimestamp) public onlyOwner returns (bool){
       require(_endTimestamp > block.timestamp , "invalid End timestamp");
       defyMaster.updateSecondReward(_reward, _endTimestamp);
        return true;
    }


    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    // XXX DO NOT set ILP for non DFY pairs. 
    function add(
    uint256 _allocPoint,
    uint256 _allocPointDR,
    IERC20 _lpToken,
    IERC20 _stub,
    IERC20 _token0, 
    IERC20 _token1, 
    uint256 _depositFee,
    uint256 _withdrawalFee,
    bool _offerILP, 
    bool _issueSTUB,
    uint256 _rewardEndTimestamp
    
    ) public onlyOwner {
        
        require(_depositFee <= 600, "Add : Max Deposit Fee is 6%");
        require(_withdrawalFee <= 600, "Add : Max Deposit Fee is 6%");
        require(_rewardEndTimestamp > block.timestamp , "Add: invalid rewardEndTimestamp");
        address secondR = defyMaster.secondR();
        require(_lpToken != IERC20(secondR) , "Add: can't use secondR as a lp token");

        defyMaster.add(_allocPoint, _allocPointDR, _lpToken, _stub, _token0, _token1, _depositFee, _withdrawalFee,
         _offerILP, _issueSTUB, _rewardEndTimestamp) ;
        
    }

    // Update the given pool's DFY allocation point. Can only be called by the owner.
    function set(
    uint256 _pid, 
    uint256 _allocPoint,
    uint256 _allocPointDR,
    IERC20 _token0, 
    IERC20 _token1, 
    uint256 _depositFee,
    uint256 _withdrawalFee,
    bool _offerILP, 
    bool _issueSTUB,
    uint256 _rewardEndTimestamp
    
    ) public onlyOwner {
        
        require(_depositFee <= 600, "Add : Max Deposit Fee is 6%");
        require(_withdrawalFee <= 600, "Add : Max Deposit Fee is 6%");
        require(_rewardEndTimestamp > block.timestamp , "Add: invalid rewardEndTimestamp");
		
        defyMaster.set( _pid, _allocPoint, _allocPointDR, _token0, _token1, _depositFee, _withdrawalFee, _offerILP,
         _issueSTUB, _rewardEndTimestamp);
            
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public onlyOwner {
        require(_devaddr != address(0), 'DEFY: dev cannot be the zero address');
        defyMaster.dev(_devaddr);
    }

}