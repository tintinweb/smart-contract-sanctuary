/**
 *Submitted for verification at BscScan.com on 2022-01-24
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-21
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// File: contracts/To Be Assigned.sol


pragma solidity ^0.8.0;




contract HivePledge is Ownable{

    using SafeMath for uint256;


    uint public create_time;
    uint public day_timestamp = 10 minutes;

    IERC20 private lp;

    IERC20 private rst;

    IERC20 private tcs;



    mapping(address => uint) addressTotalPledgeAmount;
    

    uint public totalPledgeAmount;



    mapping(uint => uint) public day_total_rst;
    mapping(uint => uint) public day_total_tcs;

    mapping(uint => uint) public day_total_pledge;

    
    mapping(address => uint) public harvestRstTime;
    mapping(address => uint) public harvestRstAmount;

    mapping(address => uint) public harvestTcsTime;
    mapping(address => uint) public harvestTcsAmount;


    address public rstAddress;
    address public tcsAddress;



    event Pledge(address indexed pledgeAddress, uint256 value);
    event Release(address indexed releaseAddress, uint256 value);
    event HarvestRst(address indexed harvestAddress, uint256  value);
    event HarvestTcs(address indexed harvestAddress, uint256  value);



    constructor(address _lp, address _rst, address _tcs, address _rstAddress, address _tcsAddress) {

      lp = IERC20(_lp);
      rst = IERC20(_rst);
      tcs = IERC20(_tcs);
      rstAddress = _rstAddress;
      tcsAddress = _tcsAddress;
    }

    function getDays(uint _endtime, uint _startTime) public view returns (uint) {
      return _endtime.sub(_startTime).div(day_timestamp);
    }


    function getDayTotalPledge(uint _day) external view returns (uint){
        return day_total_pledge[_day];
    }

    function getAddressPledgeTotal(address _address) external view returns (uint){
      return addressTotalPledgeAmount[_address];
    }




    function getRewardRst(address _sender) public view returns (uint){

        if(0 < harvestRstTime[_sender]){
            uint _start = getDays(harvestRstTime[_sender], create_time);
            uint _end = getDays(block.timestamp, create_time);

            uint _totalHarvest = 0;

            if(_start < _end){
                for(uint i = _start; i < _end; i++){
                    if(0 < day_total_pledge[i]){
                        uint _harvest =  day_total_rst[i].mul(addressTotalPledgeAmount[_sender]).div(day_total_pledge[i]);
                        _totalHarvest = _totalHarvest.add(_harvest);
                    }
                }
            }
        
            return _totalHarvest.add(harvestRstAmount[_sender]);
        }else{
            return 0;
        }

    } 


    function getRewardTcs(address _sender) public view returns (uint){

        if(0 < harvestTcsTime[_sender]){
            uint _start = getDays(harvestTcsTime[_sender], create_time);
            uint _end = getDays(block.timestamp, create_time);

            uint _totalHarvest = 0;

            if(_start < _end){
                for(uint i = _start; i < _end; i++){
                    if(0 < day_total_pledge[i]){
                        uint _harvest =  day_total_tcs[i].mul(addressTotalPledgeAmount[_sender]).div(day_total_pledge[i]);
                        _totalHarvest = _totalHarvest.add(_harvest);
                    }
                }
            }
        
            return _totalHarvest.add(harvestTcsAmount[_sender]);
        }else{
            return 0;
        }

    } 




    function harvestRst() external updateHarvest returns (bool) {
        address _sender = _msgSender();

        uint harvestAmount = harvestRstAmount[_sender];
       
        require(harvestAmount > 0, 'No balance for harvest');

        rst.transferFrom(rstAddress, _sender, harvestAmount);

        harvestRstAmount[_sender] = 0;

        emit HarvestRst(_sender, harvestAmount);
        
        return true;
    }

    function harvestTcs() external updateHarvest returns (bool) {
        address _sender = _msgSender();

        uint harvestAmount = harvestTcsAmount[_sender];
       
        require(harvestAmount > 0, 'No balance for harvest');

        tcs.transferFrom(tcsAddress, _sender, harvestAmount);

        harvestTcsAmount[_sender] = 0;

        emit HarvestTcs(_sender, harvestAmount);
        
        return true;
    }



    function pledge( uint _pledgeAmount) external updateHarvest returns (bool){

      address sender = _msgSender();

      require(0 < _pledgeAmount, "PledgeAmount:  less than zero ");

      address contractAddress = address(this);

      uint approveAmount = lp.allowance(sender, contractAddress);
      require(_pledgeAmount <= approveAmount, "LP Approval: insufficient");

      uint balance = lp.balanceOf(sender);
      require(_pledgeAmount <= balance, "LP Balance:  insufficient");

      lp.transferFrom(sender, contractAddress, _pledgeAmount);

    
      addAddressTotalPledgeAmount(sender, _pledgeAmount);
      addTotalPledgeAmount(_pledgeAmount);
     
      emit Pledge(sender, _pledgeAmount);

      return true;

    }


    function release() external updateHarvest returns (bool){

        address _sender = _msgSender();

        uint _pledage_amount = addressTotalPledgeAmount[_sender];

        require(0 < _pledage_amount, 'Pledage amount is zero');

        deductionReward(_sender);

        lp.transfer(_sender, _pledage_amount);

        subAddressTotalPledgeAmount(_sender, _pledage_amount);
        subTotalPledgeAmount(_pledage_amount);

        emit Release(_sender, _pledage_amount);

        return true;

    }


    function setDayAmount(uint _rstAmount, uint _tcsAmount) external onlyOwner returns (bool){
      
      uint _days = getDays(block.timestamp, create_time);
      
      day_total_rst[_days] = _rstAmount;
      day_total_tcs[_days] = _tcsAmount;
      
      _syncDayTotalPledge();

      return true;
    }




    function start(uint _timestamp) public onlyOwner returns (bool){
      create_time = _timestamp;
      return true;
    }






    function setLp(address _lpAddress) external onlyOwner returns (bool){
      lp = IERC20(_lpAddress);
      return true;
    }

    function setRst(address _rstAddress) external onlyOwner returns (bool){
      rst = IERC20(_rstAddress);
      return true;
    }

    function setTcs(address _tcsAddress) external onlyOwner returns (bool){
      tcs = IERC20(_tcsAddress);
      return true;
    }



    function deductionReward(address _sender)  private {
        uint _days = getDays(block.timestamp, create_time);
        deductionRst(_sender, _days);
        deductionTcs(_sender, _days);
    }

    function deductionRst(address _pledgeAddress, uint _datys)  private {
        uint harvestAmount = harvestRstAmount[_pledgeAddress];
        uint realhavestAmount = harvestAmount.div(2);

        day_total_rst[_datys] = day_total_rst[_datys].add(realhavestAmount);
    }

    function deductionTcs(address _pledgeAddress, uint _datys)  private {
        uint harvestAmount = harvestTcsAmount[_pledgeAddress];
        uint realhavestAmount = harvestAmount.div(2);

        day_total_tcs[_datys] = day_total_tcs[_datys].add(realhavestAmount);
    }




    function addAddressTotalPledgeAmount(address _pledgeAddress, uint _pledgeAmount)  private {
      addressTotalPledgeAmount[_pledgeAddress] = addressTotalPledgeAmount[_pledgeAddress].add(_pledgeAmount);
    }

    function addTotalPledgeAmount(uint _pledgeAmount)  private {
       totalPledgeAmount = totalPledgeAmount.add(_pledgeAmount);
       _syncDayTotalPledge();
    }


    function subAddressTotalPledgeAmount(address _pledgeAddress, uint _pledgeAmount)  private {
        addressTotalPledgeAmount[_pledgeAddress] = addressTotalPledgeAmount[_pledgeAddress].sub(_pledgeAmount);
    }

    function subTotalPledgeAmount(uint _pledgeAmount)  private {
       totalPledgeAmount = totalPledgeAmount.sub(_pledgeAmount);
       _syncDayTotalPledge();
    }


    function _syncDayTotalPledge() private {
        uint _days = getDays(block.timestamp, create_time);
        day_total_pledge[_days] = totalPledgeAmount;
    }



    modifier updateHarvest(){
        
        address _sender = _msgSender();

        if(0 < harvestRstTime[_sender]){
            harvestRstAmount[_sender] = getRewardRst(_sender);
        }
        harvestRstTime[_sender] = block.timestamp;

        if(0 < harvestTcsTime[_sender]){
            harvestTcsAmount[_sender] = getRewardTcs(_sender);
        }
        harvestTcsTime[_sender] = block.timestamp;
        
        _;

    }

}