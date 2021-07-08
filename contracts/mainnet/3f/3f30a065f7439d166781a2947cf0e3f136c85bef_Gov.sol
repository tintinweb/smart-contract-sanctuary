/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

/**
 *Submitted for verification at Etherscan.io on 2021-07-02
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



contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}


contract Governable is Initializable {
    address public governor;

    event GovernorshipTransferred(address indexed previousGovernor, address indexed newGovernor);

    /**
     * @dev Contract initializer.
     * called once by the factory at time of deployment
     */
    function initialize(address governor_) virtual public initializer {
        governor = governor_;
        emit GovernorshipTransferred(address(0), governor);
    }

    modifier governance() {
        require(msg.sender == governor);
        _;
    }

    /**
     * @dev Allows the current governor to relinquish control of the contract.
     * @notice Renouncing to governorship will leave the contract without an governor.
     * It will not be possible to call the functions with the `governance`
     * modifier anymore.
     */
    function renounceGovernorship() public governance {
        emit GovernorshipTransferred(governor, address(0));
        governor = address(0);
    }

    /**
     * @dev Allows the current governor to transfer control of the contract to a newGovernor.
     * @param newGovernor The address to transfer governorship to.
     */
    function transferGovernorship(address newGovernor) public governance {
        _transferGovernorship(newGovernor);
    }

    /**
     * @dev Transfers control of the contract to a newGovernor.
     * @param newGovernor The address to transfer governorship to.
     */
    function _transferGovernorship(address newGovernor) internal {
        require(newGovernor != address(0));
        emit GovernorshipTransferred(governor, newGovernor);
        governor = newGovernor;
    }
}


contract Configurable is Governable {

    mapping (bytes32 => uint) internal config;
    
    function getConfig(bytes32 key) public view returns (uint) {
        return config[key];
    }
    function getConfig(bytes32 key, uint index) public view returns (uint) {
        return config[bytes32(uint(key) ^ index)];
    }
    function getConfig(bytes32 key, address addr) public view returns (uint) {
        return config[bytes32(uint(key) ^ uint(addr))];
    }

    function _setConfig(bytes32 key, uint value) internal {
        if(config[key] != value)
            config[key] = value;
    }
    function _setConfig(bytes32 key, uint index, uint value) internal {
        _setConfig(bytes32(uint(key) ^ index), value);
    }
    function _setConfig(bytes32 key, address addr, uint value) internal {
        _setConfig(bytes32(uint(key) ^ uint(addr)), value);
    }
    
    function setConfig(bytes32 key, uint value) external governance {
        _setConfig(key, value);
    }
    function setConfig(bytes32 key, uint index, uint value) external governance {
        _setConfig(bytes32(uint(key) ^ index), value);
    }
    function setConfig(bytes32 key, address addr, uint value) public governance {
        _setConfig(bytes32(uint(key) ^ uint(addr)), value);
    }
}


contract Gov is Governable {
    using SafeMath for uint256;
    
    uint256 public thresholdPropose;
    
    uint256 public proposeCount;
    address public stakeToken;
    
    
    struct Propose {
        address payable creator;
        string subject;
        string content;
        uint endTime;
        uint span;
        uint totalStake;
        uint yes;
        uint no;
    }

   
    
    struct User{
        uint stakeEndTime;
        uint256 totalYes;
        uint256 totalNo;
        uint256 totalStake;
    }

    Propose[] public proposes;
    mapping(uint256=>mapping(address => User)) public users;

    

    // account => amount of daily staking
    mapping(address => uint256) public myTotalStake;
 

   // event Staked (address sender, uint256 amount);
    event UnStaked (address sender,uint propID, uint256 amount);
    event Withdrawn (address sender, uint256 amount);
  
  
    function initialize(address _governor,address _stakeToken) public governance  {
        require(msg.sender == governor || governor == address(0), "invalid governor");
        governor = _governor;
        stakeToken = _stakeToken;
        thresholdPropose = 100000 ether; //tmp 10w

        // config[StakeTokenAddress] = uint(0xAbF690E2EbC6690c4Fdc303fc3eE0FBFEb1818eD);		// Rinkeby
        //config[StakeTokenAddress] = uint(0x6669Ee1e6612E1B43eAC84d4CB9a94Af0A98E740);//uint(0x1C9491865a1DE77C5b6e19d2E6a5F1D7a6F2b25F);//matter //test
    }


	event CreatePropose(uint indexed propID, string subject, string content, uint span, uint stakeAmount);
    function propose(string memory _subject, string memory _content, uint _span, uint _stakeAmount) public virtual {
		address sender = msg.sender;
		require(_span >= 3 days, 'Span is too short'); //tmp 3day
		require(_span <= 7 days, 'Span is too long');
		require(_stakeAmount >= thresholdPropose, 'Proponent has not enough Matter!');
		
		uint propID = proposes.length;
      
        IERC20 _stakeToken = IERC20(stakeToken);
        _stakeToken.transferFrom(sender, address(this), _stakeAmount);        // transfer amount of staking to contract
        //_stakeToken.approve(address(this), 0);                          // reset allowance to 0
        
        myTotalStake[sender] += _stakeAmount.sub(100 ether); 
        users[propID][sender].stakeEndTime = now.add(_span);
        users[propID][sender].totalStake += _stakeAmount.sub(100 ether);
        
        Propose memory prop;
        prop.creator = msg.sender;
        prop.subject = _subject;
        prop.content = _content;
        prop.endTime = now.add(_span);
        prop.span = _span;
        proposes.push(prop);
        proposeCount=propID.add(1);
        
        emit CreatePropose(propID, _subject,  _content,  _span, _stakeAmount);
     }
    

    function unStaking(uint propID) public virtual {
        address sender = msg.sender;
        uint amount = users[propID][sender].totalStake;
        require(users[propID][sender].stakeEndTime < now, "Staking not due");
        require(amount > 0, "no matter to unStaking");
        
        IERC20(stakeToken).transfer(sender, amount);
        myTotalStake[sender] = myTotalStake[sender].sub(amount);        
        users[propID][sender].totalStake = 0;
        emit UnStaked(sender,propID, amount);
    }


    function getVotes(uint propID) public view returns(uint ,uint , uint ) {//uint totalStake,uint yes, uint no
        return (proposes[propID].totalStake,proposes[propID].yes,proposes[propID].no);
    }
    
    function getResult(uint propID) public view returns(uint) {//1 yes 2 no 0 pending
        if (now<proposes[propID].endTime)
            return 0;
        if((proposes[propID].yes>proposes[propID].no)&&(proposes[propID].totalStake>=2000000 ether))//tmp 200w
            return 1;
        else 
            return 2;
 
    }

    event Vote(address indexed user, uint indexed propID, uint voteType, uint amount);
    function vote(uint propID, uint voteType, uint amount) public virtual {  //_vote=1 yes  _vote=2 no
        address sender = msg.sender;
        require(amount > 0, "amount must > 0");
        require(now<proposes[propID].endTime,"prop is over");
        IERC20 _stakeToken = IERC20(stakeToken);
        _stakeToken.transferFrom(sender, address(this), amount);  
        users[propID][sender].stakeEndTime = now.add(proposes[propID].span);
        myTotalStake[sender] = myTotalStake[sender].add(amount);
        users[propID][sender].totalStake = users[propID][sender].totalStake.add(amount);

        if (voteType==1) {//yes
            users[propID][sender].totalYes = users[propID][sender].totalYes.add(amount);
            proposes[propID].yes = proposes[propID].yes.add(amount);
        }else{
            users[propID][sender].totalNo = users[propID][sender].totalNo.add(amount);
            proposes[propID].no = proposes[propID].no.add(amount);
        }
        emit Vote(sender, propID, voteType, amount);
        
        proposes[propID].totalStake = proposes[propID].totalStake.add(amount);
    }
    
   
    function transferFee(address payable to, uint amount) public governance {
        to.transfer(amount);
    }
    
    function transferStakeFee(address payable to, uint amount) public governance {
        IERC20(stakeToken).transfer(to, amount);
    }    
    uint256[50] private __gap;
}