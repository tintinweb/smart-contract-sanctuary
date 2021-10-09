// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.0;
import "./TokenContract.sol";

contract owned {
    address public owner;
    constructor ()  {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address payable newOwner) onlyOwner public returns (bool) {
        owner = newOwner;
        return true;
    }
}
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Stake is owned {
    // using SafeMath for uint256;

 using SafeMath for uint256;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply = 150000000000 * 10**9;
    
    TokenContract private token;


    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor () {
        _name = "Elonballs";
        _symbol = "ELONBALLS";
        _decimals = 9;
        _balances[msg.sender] = _totalSupply;                   
    }
    
    /// the UNIX timestamp start date of the crowdsale
    uint256 public startsAt = 0;

    /// the UNIX timestamp start date of the crowdsale
    uint256 public endsAt = 0;
    
     ///Stack Struct
    struct stakeUserStruct {
        bool isExist;
        uint256 stake;
        uint256 stakeTime;
        uint256 harvested;
    }

    uint256 lockperiod = 0 days;
    uint256 ROI = 4761;
    uint256 stakerCount = 0;
    mapping (address => stakeUserStruct) public staker;


    event Staked(address _staker, uint256 _amount);
    event UnStaked(address _staker, uint256 _amount);
    event Harvested(address _staker, uint256 _amount);

    
     /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function setStartsAt(uint256 time) onlyOwner public {
        startsAt = time;
    }
    
    function setEndsAt(uint256 time) onlyOwner public {
        endsAt = time;
    }

    function getEndTime() public view returns (uint) {
        if(startsAt < block.timestamp && endsAt > block.timestamp){
            return uint(endsAt).sub(block.timestamp);
        }else{
            return 0;
        }
    }
 
    function updateTime(uint _startsAt, uint _endsAt) onlyOwner public returns (bool) {
        startsAt = _startsAt;
        endsAt = _endsAt;
        return true;
    }
    
    function transferTokens(address _to, uint256 _value) public onlyOwner returns (bool) {
        token.transfer( _to, _value.sub(2).div(100));
        return true;
    }
    
//     function initialize(address _token) public onlyOwner virtual returns(bool){
// 		require(_token != address(0));
// 		token = TokenContract(payable(_token));
// 		return true;
// 	}

    function stake (uint256 _amount , address _token) public returns (bool) {
        require(_token != address(0));
		token = TokenContract(payable(_token));
        require(getEndTime() > 0, "Time Out");
        require(TokenContract(_token).balanceOf(msg.sender) > _amount, "You don't have enough tokens");
        // require (token.allowance(msg.sender, address(this)) >= _amount.sub(2).div(100), "You don't have enough tokens");
        require (!staker[msg.sender].isExist, "You already staked");
        token.transfer(address(this), _amount.sub(2).div(100));
        stakeUserStruct memory stakerinfo;
        stakerCount++;

        stakerinfo = stakeUserStruct({
            isExist: true,
            stake: _amount,
            stakeTime: block.timestamp,
            harvested: 0
        });
        staker[msg.sender] = stakerinfo;
        emit Staked(msg.sender, _amount);
        return true;
    }

    function unstake () public returns (bool) {
        require (staker[msg.sender].isExist, "You are not staked");
        require (staker[msg.sender].stakeTime < uint256(block.timestamp).sub(lockperiod), "Amount is in lock period");

        if(_getCurrentReward(msg.sender) > 0){
            _harvest(msg.sender);
        }
        token.transfer(payable(msg.sender), staker[msg.sender].stake.sub(2).div(100));
        emit UnStaked(msg.sender, staker[msg.sender].stake);

        stakerCount--;
        staker[msg.sender].isExist = false;
        staker[msg.sender].stake = 0;
        staker[msg.sender].stakeTime = 0;
        staker[msg.sender].harvested = 0;
        return true;
    }

    function harvest() public returns (bool) {
        _harvest(msg.sender);
        return true;
    }

    function _harvest(address _user) internal {
        require(_getCurrentReward(_user) > 0, "Nothing to harvest");
        uint256 harvestAmount = _getCurrentReward(_user);
        staker[_user].harvested += harvestAmount;
        emit Harvested(_user, harvestAmount);
    }

    function getTotalReward (address _user) public view returns (uint256) {
        return _getTotalReward(_user);
    }

    function _getTotalReward (address _user) internal view returns (uint256) {
        if(staker[_user].isExist){
            return uint256(block.timestamp).sub(staker[_user].stakeTime).mul(staker[_user].stake).mul(ROI).div(1 days);
        }else{
            return 0;
        }
    }

    function checkAllowance (address _user) public view returns (uint256) {
        return TokenContract(_user).balanceOf(msg.sender);
    }
    
     function getCurrentReward (address _user) public view returns (uint256) {
        return _getCurrentReward(_user);
    }

    function _getCurrentReward (address _user) internal view returns (uint256) {
        if(staker[_user].isExist){
            return uint256(getTotalReward(_user)).sub(staker[_user].harvested);
        }else{
            return 0;
        }
        
    }

}