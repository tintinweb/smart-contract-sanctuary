/**
 *Submitted for verification at BscScan.com on 2022-01-08
*/

pragma solidity 0.7.2;
// SPDX-License-Identifier: UNLICENSED


interface Witty {
   
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

   
    function allowance(address owner, address spender) external view returns (uint256);

   
    function approve(address spender, uint256 amount) external returns (bool);

   
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

   
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract WittyStake {
    using SafeMath for uint256;
    struct user {
        bool isExist;
        uint id;
        uint incentiveAmount;
        uint creditTime;
        address referer;
        address[] referals;
        uint refCommission;
        uint8 plan;
    }
    
    struct investDetails {
        uint depositAmount;
        uint depositTime;
        uint depositPayouts;
        bool status;
    }
    
    address public owner;
    Witty public witty;
    bool public depStatus;
    uint public currentId = 2;
    uint[] public refPercent = [5,3,2];
    uint public payoutDuration = 1 days;
    bool public lockStatus;
    uint public adminWallet;
    uint public totalStake;
    
    mapping (uint => uint)public plan;
    mapping (uint => uint)public depAmount;
    mapping (address => mapping(uint => mapping(uint => investDetails)))public invest;
    mapping (address => user)public users;
    mapping (uint => uint)public roiPercentage;
    mapping (uint => uint)public maxAmount;
    mapping (address =>mapping(uint => uint))public investCount;
    
    
    event Stake(address indexed from,address  referer,uint amount,uint plan,uint id,uint time);
    event ReferalCommission(address indexed to,uint plan, uint amt,uint time);
    event Withdraw(address indexed from,uint Roi,uint amount,uint plan,uint id,uint time);
    event Charges(address indexed from,uint amount,uint plan,uint id,uint time);
    event FailSafe(address indexed user, uint value, uint time);
    
    constructor(address _owner,address _witty)  {
        owner = _owner;
        witty = Witty(_witty);
        plan[1] = 10000;
        plan[2] = 5000;
        plan[3] = 2000;
        plan[4] = 500;
        plan[5] = 100;
        
        roiPercentage[1] = 0.45e18;
        roiPercentage[2] = 0.2e18;
        roiPercentage[3] = 0.07e18;
        roiPercentage[4] = 0.015e18;
        roiPercentage[5] = 0.0027e18;
        
        maxAmount[1] = 162e18;
        maxAmount[2] = 72e18;
        maxAmount[3] = 25.2e18;
        maxAmount[4] = 5.4e18;
        maxAmount[5] = 0.972e18;
        
        users[owner].isExist = true;
        users[owner].id = 1;
    }
    
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }
    
    /**
     * @dev Throws if lockStatus is true
     */
    modifier isLock() {
        require(lockStatus == false, "Witty: Contract Locked");
        _;
    }

    /**
     * @dev Throws if called by other contract
     */
    modifier isContractCheck(address _user) {
        require(!isContract(_user), "Witty: Invalid address");
        _;
    }
    
    function stake(uint _plan,uint _amount,address _mainRef,address[] memory _ref,uint[] memory _commissionAmt,uint _flag) public isLock isContractCheck(msg.sender) {
        require(_amount > 0 || users[msg.sender].incentiveAmount >= depAmount[_plan],"Incorrect values");
        require( _plan > 0 && _plan <= 5,"Incorrect plan");
        require(_ref.length == _commissionAmt.length,"Referer and commsiion mis match");
        require(_flag == 0 || _flag == 1,"Incorrect");
       
        if (users[msg.sender].referer != address(0)) {
            require(users[msg.sender].referer == _mainRef,"Previous referer and current referer not same");
        }
        
       investCount[msg.sender][_plan]++;
       uint count = investCount[msg.sender][_plan];
        
        
        uint calc;
        uint remainAmount;
        uint amount;
        if (_flag == 1) {
            require(users[msg.sender].incentiveAmount > 0,"No incentive amount");
            require(_plan != 5,"Incentive amount can't use for plan 5");
            require(users[msg.sender].incentiveAmount.add(_amount) >= depAmount[_plan],"insufficeient");
            if (block.timestamp < users[msg.sender].creditTime.add(30 days)) {
                calc = users[msg.sender].incentiveAmount.add(_amount);
                remainAmount = calc.sub(depAmount[_plan]);
                users[msg.sender].incentiveAmount = remainAmount;
                invest[msg.sender][_plan][count].depositAmount = depAmount[_plan];
            }
            else {
                amount = users[msg.sender].incentiveAmount;
                adminWallet = adminWallet.add(amount);
                users[msg.sender].incentiveAmount = 0;
                require(users[msg.sender].incentiveAmount.add(_amount) >= depAmount[_plan],"insufficeient amount in flag 1");
                invest[msg.sender][_plan][count].depositAmount = depAmount[_plan];
            }
        }
        else if (_flag == 0) {
            require(depStatus == true && _amount == depAmount[_plan],"Incorrect Amount");
            invest[msg.sender][_plan][count].depositAmount = _amount;
        }
        if (_amount > 0) {
        witty.transferFrom(msg.sender,address(this),_amount);
        }
        users[msg.sender].isExist = true;
        users[msg.sender].id = currentId;
        currentId++;
        invest[msg.sender][_plan][count].depositPayouts = 0;
        invest[msg.sender][_plan][count].depositTime = block.timestamp;
        invest[msg.sender][_plan][count].status = true;
        users[msg.sender].referer = _mainRef;
        users[_mainRef].referals.push(msg.sender);
        _refPayout(msg.sender,_ref,_commissionAmt,_plan);
        
        uint amt = invest[msg.sender][_plan][count].depositAmount;
        totalStake = totalStake.add(depAmount[_plan]);
        emit Stake(msg.sender,_mainRef,amt,_plan,count,block.timestamp);

    }
    
    function _refPayout(address _user,address[] memory _ref ,uint[] memory _amt,uint _plan) internal {
        //address ref = users[_user].referer;
        for (uint i = 0; i < 3; i++) {
            if(_ref[i] != address(0) && _ref[i] != _user) {
            witty.transfer(_ref[i],_amt[i]);
            users[_ref[i]].refCommission = users[_ref[i]].refCommission.add(_amt[i]);
            emit ReferalCommission(_ref[i],_plan,_amt[i],block.timestamp);
            }
        }
    }
    
    function withdraw(uint _plan,uint _amount,uint count) public isLock {
        require(invest[msg.sender][_plan][count].status == true,"User not activate");
        uint amount;
       
        (uint256 to_payout, uint256 max_payout) = this.payout(msg.sender,_plan,count);
        require(invest[msg.sender][_plan][count].depositPayouts < max_payout || msg.sender == owner, "Ewaso: Full payouts");
      
        // Deposit payout
        if (to_payout > 0) {
            if (invest[msg.sender][_plan][count].depositPayouts.add(to_payout) > max_payout) {
                to_payout = max_payout.sub(invest[msg.sender][_plan][count].depositPayouts);
            }
           invest[msg.sender][_plan][count].depositPayouts = invest[msg.sender][_plan][count].depositPayouts.add(to_payout);
        }
        
        witty.transfer(msg.sender,to_payout);

        
         if (_amount > 0) {
            invest[msg.sender][_plan][count].depositAmount = invest[msg.sender][_plan][count].depositAmount.sub(_amount);
            
            if (block.timestamp < invest[msg.sender][_plan][count].depositTime.add(90 days)) {
                amount = _amount.sub(_amount.mul(50).div(100));
                emit Charges(msg.sender,_amount.mul(50).div(100),_plan,count,block.timestamp);
            }
            else if (block.timestamp < invest[msg.sender][_plan][count].depositTime.add(240 days)) {
                amount = _amount.sub(_amount.mul(30).div(100));
                emit Charges(msg.sender,_amount.mul(30).div(100),_plan,count,block.timestamp);
            }
            else if (block.timestamp < invest[msg.sender][_plan][count].depositTime.add(365 days)) {
                amount = _amount.sub(_amount.mul(20).div(100));
                emit Charges(msg.sender,_amount.mul(20).div(100),_plan,count,block.timestamp);
            }
            else if (block.timestamp > invest[msg.sender][_plan][count].depositTime.add(365 days)) {
                amount = _amount;
            }
             invest[msg.sender][_plan][count].status = false;
             witty.transfer(msg.sender,amount);
             
        }
        emit Withdraw(msg.sender,to_payout,amount,_plan,count,block.timestamp);
    }
    
    /**
     * @dev maxPayoutOf: Amount calculate by 310 percentage
     */
    function maxPayoutOf(uint256 _amount,uint _plan) view external returns(uint256) {
        return _amount.mul(maxAmount[_plan]).div(100e18); 
    }
    
    function payout(address _user,uint _plan,uint count) external view returns(uint _payout, uint _maxPayout) {
        require(invest[_user][_plan][count].status == true,"User not activate");
        require(invest[_user][_plan][count].depositAmount > 0,"Not yet deposit");
            uint amount = invest[_user][_plan][count].depositAmount;
            _maxPayout = this.maxPayoutOf(amount,_plan);
            if (invest[_user][_plan][count].depositPayouts < _maxPayout) {
                _payout = ((amount.mul(roiPercentage[_plan]).div(100e18)).mul((block.timestamp.sub(invest[_user][_plan][count].depositTime))
                .div(payoutDuration))).sub(invest[_user][_plan][count].depositPayouts);
                
                if (invest[_user][_plan][count].depositPayouts.add(_payout) > _maxPayout) {
                    _payout = _maxPayout.sub(invest[_user][_plan][count].depositPayouts);
                }
            }
     } 
          
    function incentiveDistribute(address _user,uint amount)public onlyOwner {

        users[_user].incentiveAmount = users[_user].incentiveAmount.add(amount);
        users[_user].creditTime = block.timestamp;
    }
    
    function viewReferer(address _user)public view returns(address,address,address){
        return (users[_user].referals[0],
                users[_user].referals[1],
                users[_user].referals[2]);
    }
    
    function adminWithdraw(uint _amt)public onlyOwner{
        adminWallet = adminWallet.sub(_amt);
        witty.transfer(owner,_amt);
    }
    
    
    function setAmount(uint _price) public onlyOwner{
        for (uint i = 1; i <= 5; i++){
            depAmount[i] = plan[i].mul(_price);
        }
        depStatus = true;
    }
    
    function setDuration(uint _duration)public onlyOwner{
        payoutDuration = _duration;
    }
    
    function updatePlan(uint[5] memory _plan,uint[5] memory _dollor) public onlyOwner {
    
        for (uint i = 0; i < 5; i++){
            plan[_plan[i]] = _dollor[i];
        }
    }
    
    /**
     * @dev failSafe: Returns transfer trx
     */
    function failSafe(address  _toUser, uint _amount) public onlyOwner returns(bool) {
        require(_toUser != address(0), "Witty: Invalid Address");
        require(witty.balanceOf(address(this)) >= _amount, "Witty: Insufficient balance");
        witty.transfer(_toUser,_amount);
        emit FailSafe(_toUser, _amount, block.timestamp);
        return true;
    }

    /**
     * @dev contractLock: For contract status
     */
    function contractLock(bool _lockStatus) public onlyOwner returns(bool) {
        lockStatus = _lockStatus;
        return true;
    }

    /**
     * @dev isContract: Returns true if account is a contract
     */
    function isContract(address _account) public view returns(bool) {
        uint32 size;
        assembly {
            size:= extcodesize(_account)
        }
        if (size != 0)
            return true;
        return false;
    }
    
    
}