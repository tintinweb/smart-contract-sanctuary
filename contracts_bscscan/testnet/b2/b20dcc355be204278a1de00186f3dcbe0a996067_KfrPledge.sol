/**
 *Submitted for verification at BscScan.com on 2022-01-23
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-22
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




contract KfrPledge is Ownable{

    using SafeMath for uint256;


    uint public create_time;

    uint public end_time;

    uint private cycle_day = 2;

    uint private day_timestamp = 10 minutes;

    uint public cycle;

    mapping(uint => uint) setp_day_reward;

    IERC20 private lp;

    IERC20 private kfr;

    struct PledgeOrder{

      uint orderId;

      uint pledgeAmount;

      uint pledgeTime;

      uint releaseTime;

      bool releaseStatus;
    }

    mapping(address => PledgeOrder[]) addressPledgeOrders;

    mapping(address => uint) addressTotalPledgeAmount;
    mapping(address => uint) public totalReward;

    uint public totalPledgeAmount;

    address public recommender;
    mapping(address => address) addressRecommender;
    mapping(address => uint) public recommendNum; 

    uint private recommender_reward_rate = 30;

    address[] private pledgeAddresses;

    mapping(address => bool) private releaseWhite;

    mapping(address => uint) address_reward_amount;
    mapping(address => uint) address_reward_time;


    event Pledge(address indexed pledgeAddress, uint256 value);
    event Release(address indexed releaseAddress, uint256 value);
    event Reward(address indexed rewardAddress, uint256  value);
    event Harvest(address indexed harvestAddress, uint256  value);



    constructor(address _lp, address _kfr, address _recommender) {

      lp = IERC20(_lp);
      kfr = IERC20(_kfr);

      recommender = _recommender;

      setp_day_reward[0] = uint(270).mul(1e18);
      setp_day_reward[1] = uint(432).mul(1e18);
      setp_day_reward[2] = uint(666).mul(1e18);
      setp_day_reward[3] = uint(1035).mul(1e18);
      setp_day_reward[4] = uint(1602).mul(1e18);

      setCycle(cycle_day, day_timestamp);

    }


    function getAddressPledgeOrders(address _address) external view returns(PledgeOrder[] memory){
        return addressPledgeOrders[_address];
    }


    function getStep(uint _now) private view returns (uint) {
      uint _step = _now.sub(create_time).div(cycle);

      require(_step < 5, 'End of activity');

      return _step;
    }


    function earned(address _sender) public view returns (uint) {
       return address_reward_amount[_sender];
    }




    function reward(uint _now) external onlyOwner returns (bool){      

      uint _step = 0;
      if(0 == _now){
        require(create_time < block.timestamp && block.timestamp < end_time, 'No activity time');
        _step = getStep(block.timestamp);
      }else{
        _step = getStep(_now);
      }
      
      require(0 < totalPledgeAmount, "No pledge:  do not reward");

      uint _rewardTotalAmount = setp_day_reward[_step];
      uint _day_reward_amount = _rewardTotalAmount.div(cycle_day);

      for(uint i = 0; i < pledgeAddresses.length; i++){
            
        if(0 < addressTotalPledgeAmount[pledgeAddresses[i]]){
          reward(pledgeAddresses[i], _day_reward_amount, addressTotalPledgeAmount[pledgeAddresses[i]]);
        }
      }

      return true;
    }


    function harvest() external returns (bool) {
        address sender = _msgSender();
        uint harvestAmount = earned(sender);

        require(harvestAmount > 0, 'No balance for harvest');
        require(block.timestamp.sub(address_reward_time[sender]) > day_timestamp.mul(7), 'GetReward time is not up');

        kfr.transfer(sender, harvestAmount);

        address_reward_amount[sender] = 0;
        address_reward_time[sender] = block.timestamp;
        totalReward[sender] = totalReward[sender].add(harvestAmount);

        emit Harvest(sender, harvestAmount);
        return true;
    }



    function pledge(address _recommender, uint _pledgeAmount) external returns (bool){

      require(create_time < block.timestamp && block.timestamp < end_time, 'No activity time');

      address sender = _msgSender();
      require(sender != _recommender, "Recommender invalid");
      if(address(0) == addressRecommender[sender]){
        addressRecommender[sender] = _recommender;
        recommendNum[_recommender] = recommendNum[_recommender].add(1);
      }else{
        require(_recommender == addressRecommender[sender], 'Recommender invalid');
      }

      require(0 < _pledgeAmount, "PledgeAmount:  less than zero ");

      address contractAddress = address(this);

      uint approveAmount = lp.allowance(sender, contractAddress);
      require(_pledgeAmount <= approveAmount, "LP Approval: insufficient");

      uint balance = lp.balanceOf(sender);
      require(_pledgeAmount <= balance, "LP Balance:  insufficient");

      lp.transferFrom(sender, contractAddress, _pledgeAmount);

      

      createPledgeOrder(sender, _pledgeAmount);

      emit Pledge(sender, _pledgeAmount);

      return true;

    }


    function release(uint _orderId) external returns (bool){

        address sender = _msgSender();

        PledgeOrder memory pledgeOrder = addressPledgeOrders[sender][_orderId];

        require(!pledgeOrder.releaseStatus, "Pledge order: already release");

        require(pledgeOrder.releaseTime < block.timestamp || releaseWhite[sender], "Pledge order: not reaching the release time");

        lp.transfer(sender, pledgeOrder.pledgeAmount);

        updatePledgeOrder(sender, _orderId);

        subAddressTotalPledgeAmount(sender, pledgeOrder.pledgeAmount);
        subTotalPledgeAmount(pledgeOrder.pledgeAmount);

        emit Release(sender, pledgeOrder.pledgeAmount);

        return true;

    }



    function setCycle(uint _cycle_day, uint _day_seconds) public onlyOwner returns (bool){
      cycle_day = _cycle_day;
      day_timestamp = _day_seconds;
      cycle = cycle_day * day_timestamp;
      return true;
    }


    function start(uint _timestamp) public onlyOwner returns (bool){
      create_time = _timestamp;
      end_time = create_time.add(cycle.mul(5));
      return true;
    }






    function getReleaseWhite(address _address) public view returns (bool){
      return releaseWhite[_address];
    }

    function getRecommender(address _address) public view returns (address){
      return addressRecommender[_address];
    }

    function getAddressPledgeTotal(address _address) public view returns (uint){
      return addressTotalPledgeAmount[_address];
    }


    function setReleaseWhite(address _address) external onlyOwner returns (bool){
      releaseWhite[_address] = !releaseWhite[_address];
      return true;
    }

    function setRecommender(address _address) external onlyOwner returns (bool){
      recommender = _address;
      return true;
    }


    function transferKfr(address _address, uint amount) external onlyOwner returns (bool){
        kfr.transfer(_address, amount);
        return true;
    }


    function setRecommentRate(uint rate) external onlyOwner returns (bool){
      recommender_reward_rate = rate;
      return true;
    }

    function setLp(address _lpAddress) external onlyOwner returns (bool){
      lp = IERC20(_lpAddress);
      return true;
    }


    function setTba(address _address) external onlyOwner returns (bool){
      kfr = IERC20(_address);
      return true;
    }


    function createPledgeOrder(address _address, uint _pledgeAmount) private {

        addressPledgeOrders[_address].push(
            PledgeOrder(
                addressPledgeOrders[_address].length,
                _pledgeAmount,
                block.timestamp,
                block.timestamp.add(cycle.mul(2)),
                false
            )
        );

        addAddressTotalPledgeAmount(_address, _pledgeAmount);

        addTotalPledgeAmount(_pledgeAmount);

        
       
    }


    function reward(address _address, uint _rewardTotalAmount, uint _addressPledge) private{

      uint _rewardPledgeAmount = _rewardTotalAmount.mul(_addressPledge).div(totalPledgeAmount);

      if(0 != getAddressPledgeTotal(addressRecommender[_address])){
          uint _recommender_amount = _rewardPledgeAmount.mul(recommender_reward_rate).div(100);
          address_reward_amount[addressRecommender[_address]] = address_reward_amount[addressRecommender[_address]].add(_recommender_amount);
          emit Reward(addressRecommender[_address], _recommender_amount);
          _rewardPledgeAmount = _rewardPledgeAmount.sub(_recommender_amount);
      }

      address_reward_amount[_address] = address_reward_amount[_address].add(_rewardPledgeAmount);
      emit Reward(_address, _rewardPledgeAmount);
    }


    function addAddressTotalPledgeAmount(address _pledgeAddress, uint _pledgeAmount)  private {
      if(0 == addressTotalPledgeAmount[_pledgeAddress]){
        pledgeAddresses.push(_pledgeAddress);
      }  
      addressTotalPledgeAmount[_pledgeAddress] = addressTotalPledgeAmount[_pledgeAddress].add(_pledgeAmount);
    }

    function addTotalPledgeAmount(uint _pledgeAmount)  private {
       totalPledgeAmount = totalPledgeAmount.add(_pledgeAmount);
    }

    function updatePledgeOrder(address _address, uint _orderId) private {
        addressPledgeOrders[_address][_orderId].pledgeAmount = 0;
        addressPledgeOrders[_address][_orderId].releaseStatus = true;
    }


    function subAddressTotalPledgeAmount(address _pledgeAddress, uint _pledgeAmount)  private {
        addressTotalPledgeAmount[_pledgeAddress] = addressTotalPledgeAmount[_pledgeAddress].sub(_pledgeAmount);
    }

    function subTotalPledgeAmount(uint _pledgeAmount)  private {
       totalPledgeAmount = totalPledgeAmount.sub(_pledgeAmount);
    }


}