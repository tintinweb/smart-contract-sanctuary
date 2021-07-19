//SourceUnit: updatedewaso (1).sol

pragma solidity 0.5.14;
interface AggregatorInterface {
    function latestAnswer() external view returns (int256);
    function latestTimestamp() external view returns (uint256);
    function latestRound() external view returns (uint256);
    function getAnswer(uint256 roundId) external view returns (int256);
    function getTimestamp(uint256 roundId) external view returns (uint256);
}
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

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
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

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
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

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
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

    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
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

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
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

    function mod(uint256 a, uint256 b) internal pure returns(uint256) {
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

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
contract Ewaso {
    using SafeMath for uint256;
        // Investor details
    struct userDetails{
        uint tree;
        uint currentid;
    }
    
    struct investDetails {
       bool isExist;
       uint depositAmount;
       bool active;
       uint depositTime;
       uint depositPayouts;
       uint binaryBonus;
       uint levelBonus;
       uint refCommission;
       address directReferer;
       address referer;
       address[] referals;
       address[] secondLineReferals;
       uint joinTime;
    }
    // Mapping users details by address
    mapping(address => userDetails)public users;
    // Mapping address by id
    mapping(uint => address)public userList;
    // Mapping users by tree wise
    mapping(address => mapping(uint => investDetails))public investnew;
    // Mapping users plan
    mapping(address => mapping(uint => uint))public planCalc;
    // Mapping level income by levels
    mapping(uint => uint)public levelIncome;
    // Mapping binaryshare by tree
    mapping(uint => uint)public binaryIncome;
    // Mapping roishare by tree
    mapping(uint => uint)public roiIncome;
    // Mapping userlist by tree
     mapping(uint => uint)public treeList;
    
    // Level income event
    event LevelIncome(address indexed from, address indexed to, uint value,uint tree, uint time);
     // Failsafe event
    event FailSafe(address indexed user, uint value, uint time);
      // Cumulative amounts
    event CumulativeAmount(address indexed from,uint value,uint tree,uint time);
     // Invest event
    event Invest(address indexed from, address indexed to, uint value,uint tree, uint time);
    // Referal income event
    event ReferalIncome(address indexed from, address indexed to, uint value,uint tree, uint time);
     // Withdraw event
    event Withdraw(address indexed from, uint value, uint tree, uint time);
    // Binary income
    event BinaryIncome(address indexed to,uint value,uint time,uint tree);
    // Qcapping amount
    event QcappIncome(address indexed to,uint value,uint time,uint tree);

    // Users id
    uint public currentId = 2;
    // Owner address
    address public owner;
    // Binary distributor;
    address public binaryAddress;
    // Referal limit
    uint public referLimit = 2;
    // USD price updation
    uint public dollorPrice = 150;
    // Contract lock
    bool public lockStatus;
    uint public withdrawLimit = 10;
    // Binary limit perday
    uint public binaryLimit = 1000;
    AggregatorInterface public priceFeed;
    // Status for deposit amount
    bool public depositStatus;
    // Deposit price
    uint public price;
    // Duration
    uint public duration = 15 days;
    // Payout duration
    uint public payoutDuration = 1 days;
   
   
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Ewaso: Only Owner");
        _;
    }
    
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier binaryDistributer() {
        require(msg.sender == binaryAddress, "Ewaso: Only Owner");
        _;
    }
    
    /**
     * @dev Throws if lockStatus is true
     */
    modifier isLock() {
        require(lockStatus == false, "Ewaso: Contract Locked");
        _;
    }
    
     /**
     * @dev Throws if called by other contract
     */
    modifier isContractcheck(address _user) {
        require(!isContract(_user), "Ewaso: Invalid address");
        _;
    }

    /**
     * @dev Initializes the contract setting the _owner as the initial owner.
     */
    constructor(address _owner,address _aggregator_addr,address _binary)public {
        owner = _owner;
        binaryAddress = _binary;
        address aggregator_addr = _aggregator_addr;
        priceFeed = AggregatorInterface(aggregator_addr);
        users[owner].currentid = 1;
        userList[1] = owner;
       
        for (uint i = 1; i <= 5; i++) {
            levelIncome[i] = 2e6; // For level income
        }

        for (uint i = 6; i <= 10; i++) {
            levelIncome[i] = 1e6; // For level income
        }
        
        for (uint i = 1; i<=50; i++){
            investnew[owner][i].isExist = true;
        }
    }
    
    function checkPrice()public view returns( uint ){
      uint _price = uint(getLatestPrice());
        return (1e6/_price)*1e6;
    }
    
    function getLatestPrice() public view returns (int) {
        // If the round is not complete yet, timestamp is 0
        require(priceFeed.latestTimestamp() > 0, "Round not complete");
        return priceFeed.latestAnswer();
    }
    
    function depAmount()public view returns(uint) {
        if (depositStatus == false){
          uint _price = checkPrice();
          return dollorPrice*_price;
        }
        else{
           return dollorPrice;
        }
    }
    
    function invest(uint _refid,uint _tree)external isContractcheck(msg.sender) isLock payable {
        require(users[msg.sender].tree + 1 == _tree,"Wrong tree given");
        uint count;
        uint id;
        address directRef;
        price = depAmount();
        require(msg.value == price, "Iwaso: Given wrong amount");
         if (investnew[userList[_refid]][_tree].isExist == false || _refid == 0) {
             if (62 > (currentId - 1) - 1){
                 id = 1;
             }
             else{
                 if (treeList[_tree] > 0)
                 id = treeList[_tree];
                 else id =1 ;
             }
            _refid = users[findFreeReferrer(userList[id],_tree)].currentid;
            _refpayout(msg.sender,msg.value.mul(10).div(100),userList[_refid],_tree);
            count++;
          }
           if (investnew[userList[_refid]][_tree].referals.length >= referLimit) {
                directRef = userList[_refid];
            if (62 > (currentId.sub(1) - 1)){
                 id = 1;
            }
            else{
                 id = treeList[_tree];
            }
                _refid = users[findFreeReferrer(userList[_refid],_tree)].currentid;
            }
           users[msg.sender].tree++;
           investnew[msg.sender][users[msg.sender].tree].isExist = true;
           investnew[msg.sender][users[msg.sender].tree].depositAmount = msg.value;
           investnew[msg.sender][users[msg.sender].tree].active = true;
           investnew[msg.sender][users[msg.sender].tree].depositTime = block.timestamp;
           investnew[msg.sender][users[msg.sender].tree].joinTime = block.timestamp;
           investnew[msg.sender][users[msg.sender].tree].depositPayouts = 0;
           investnew[msg.sender][users[msg.sender].tree].binaryBonus = 0;
           investnew[msg.sender][users[msg.sender].tree].levelBonus = 0;
           investnew[msg.sender][users[msg.sender].tree].refCommission = 0;
           investnew[msg.sender][users[msg.sender].tree].referer = userList[_refid];
           investnew[msg.sender][users[msg.sender].tree].referals = new address[](0);
           investnew[userList[_refid]][users[msg.sender].tree].referals.push(msg.sender);
           address refofref = investnew[userList[_refid]][users[msg.sender].tree].referer;
           investnew[refofref][users[msg.sender].tree].secondLineReferals.push(msg.sender);
            if (count == 0){
            if(directRef != address(0)){
           investnew[msg.sender][users[msg.sender].tree].directReferer = directRef; 
           investnew[directRef][_tree].refCommission = investnew[directRef][_tree].refCommission.add(msg.value.mul(10).div(100));
            emit ReferalIncome(msg.sender, directRef, msg.value.mul(10).div(100),_tree, block.timestamp);
            }
            else{
               investnew[investnew[msg.sender][_tree].referer][_tree].refCommission = investnew[investnew[msg.sender][_tree].referer][_tree].refCommission.add(msg.value.mul(10).div(100)); 
               emit ReferalIncome(msg.sender, investnew[msg.sender][_tree].referer, msg.value.mul(10).div(100),_tree, block.timestamp);
            }
            }
            
           if (users[msg.sender].currentid == 0) {
              users[msg.sender].currentid = currentId;
              userList[users[msg.sender].currentid] = msg.sender;
              currentId++;
          }
          if (investnew[investnew[msg.sender][_tree].referer][_tree].referals.length == 2) {
              updateCategory(investnew[msg.sender][_tree].referer,_tree);
          }
          treeList[_tree] = users[msg.sender].currentid;
          binaryIncome[_tree] = binaryIncome[_tree].add(msg.value.mul(40).div(100));
          roiIncome[_tree] = roiIncome[_tree].add(msg.value.mul(40).div(100));
         
          emit Invest(msg.sender, investnew[msg.sender][_tree].referer, msg.value, _tree,block.timestamp);
    }
    
    function Binary(uint[] memory _id, uint[] memory _amt,uint _tree)public binaryDistributer returns(bool) {
        
        for (uint i=0;i<_id.length;i++) {
            if (investnew[userList[_id[i]]][_tree].secondLineReferals.length == 4) {
                binaryIncome[_tree] = binaryIncome[_tree].sub(_amt[i]);
                if (_amt[i] < binaryLimit.mul(checkPrice())){
                investnew[userList[_id[i]]][_tree].binaryBonus = investnew[userList[_id[i]]][_tree].binaryBonus.add(_amt[i]);
                emit BinaryIncome(userList[_id[i]],_amt[i],block.timestamp,_tree);
                }
                if (_amt[i] > binaryLimit.mul(checkPrice())){
                uint remainAmount = _amt[i].sub(binaryLimit.mul(checkPrice()));
                _amt[i] = _amt[i].sub(remainAmount);
                investnew[userList[i]][_tree].binaryBonus = investnew[userList[i]][_tree].binaryBonus.add(_amt[i]);
                emit BinaryIncome(userList[_id[i]],_amt[i],block.timestamp,_tree);
                for (uint j=1;j<=7;j++){
                    investnew[userList[j]][_tree].binaryBonus = investnew[userList[j]][_tree].binaryBonus.add(remainAmount.div(7));
                     emit QcappIncome(userList[j],remainAmount.div(7),block.timestamp,_tree);
                }
            } 
          }
        }
         return true;
    }
    
    function updateCategory(address _user,uint _tree)internal {
        if (block.timestamp <= investnew[_user][_tree].joinTime.add(duration)) {
            planCalc[_user][_tree] = 2;
        }
        else {
            planCalc[_user][_tree] = 1;
        }
    }
    
    function _refpayout(address _user, uint _amount, address _refer,uint _tree) internal {
        address ref = _refer;
        for (uint i = 1; i <= 10; i++) {
            if (ref == address(0)) {
                ref = owner;
            }
            investnew[ref][_tree].levelBonus = investnew[ref][_tree].levelBonus.add(_amount.mul(levelIncome[i]).div(100e6));
            emit LevelIncome(_user, ref, _amount.mul(levelIncome[i]).div(100e6),_tree, block.timestamp);
            ref = investnew[ref][_tree].referer;
        }
    }
    
    /**
     * @dev withdraw: User can get amount till maximum payout reach.
     * maximum payout based on(daily ROI, Referal commission, Level bonus, Binary bonus)
     * maximum payout limit 200 percentage
     */
    function withdraw(uint _tree) public isLock {
        (uint256 to_payout, uint256 max_payout,uint _plan) = this.payout(msg.sender,_tree);
        require(investnew[msg.sender][_tree].depositPayouts < max_payout || msg.sender == owner, "Ewaso: Full payouts");
        if (planCalc[msg.sender][_tree] == 0){
        planCalc[msg.sender][_tree] = _plan;
        }
        
        // Deposit payout
        if (to_payout > 0) {
            if (investnew[msg.sender][_tree].depositPayouts.add(to_payout) > max_payout) {
                to_payout = max_payout.sub(investnew[msg.sender][_tree].depositPayouts);
            }
           investnew[msg.sender][_tree].depositPayouts = investnew[msg.sender][_tree].depositPayouts.add(to_payout);
        }
        roiIncome[_tree] = roiIncome[_tree].sub(to_payout);
        require(address(uint160(msg.sender)).send(to_payout), "Ewaso: withdraw failed");
        emit Withdraw(msg.sender, to_payout,_tree, block.timestamp);

        if (investnew[msg.sender][_tree].depositPayouts >= max_payout) {
            investnew[msg.sender][_tree].active = false;
        }
    }
    
    /**
     * @dev cumulativeWithdraw: User can withdraw their Referal commission , binary commission, level commission
     */
    function cumulativeWithdraw(uint _tree)public {
        uint amount;
        // Referal commission
        if (investnew[msg.sender][_tree].refCommission > 0) {
            amount = amount.add(investnew[msg.sender][_tree].refCommission);
            investnew[msg.sender][_tree].refCommission = 0;
        }

        // Level bonus
        if (investnew[msg.sender][_tree].levelBonus > 0) {
            amount = amount.add(investnew[msg.sender][_tree].levelBonus);
            investnew[msg.sender][_tree].levelBonus = 0;
        }

        // Binary bonus
        if (investnew[msg.sender][_tree].binaryBonus > 0 && investnew[msg.sender][_tree].secondLineReferals.length == 4) {
            amount = amount.add(investnew[msg.sender][_tree].binaryBonus);
            investnew[msg.sender][_tree].binaryBonus = 0;
        }
        require(amount >= withdrawLimit.mul(checkPrice()),"Ewaso: Not reach 10$ amount ");
        require(address(uint160(msg.sender)).send(amount), "Ewaso: Cumulative failed");
        emit CumulativeAmount(msg.sender,amount,_tree,block.timestamp);
    }
    
    /**
     * @dev maxPayoutOf: Amount calculate by 200 percentage
     */
    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount.mul(200).div(100); // 200% of deposit amount
    }
    
    /**
     * @dev payoutOf: Users daily ROI and maximum payout will be show
     */
    function payout(address _user,uint _tree) external view returns(uint _payout, uint _maxPayout,uint _plan) {
        if (block.timestamp >= investnew[_user][_tree].depositTime.add(duration)) {
            if (planCalc[_user][_tree] == 0) {
                _plan = 1;
            }
            else {
                if (planCalc[_user][_tree] == 0)
                _plan = 2;
                else
                _plan = planCalc[_user][_tree];
            }
            uint amount = investnew[_user][_tree].depositAmount;
            _maxPayout = this.maxPayoutOf(amount);
            if (investnew[_user][_tree].depositPayouts < _maxPayout) {
                _payout = ((amount.mul(0.33e6).div(100e6)).mul((block.timestamp.sub(investnew[_user][_tree].depositTime.add(duration))).div(payoutDuration))).sub(investnew[_user][_tree].depositPayouts);
                _payout = _payout.mul(_plan);
                if (investnew[_user][_tree].depositPayouts.add(_payout) > _maxPayout) {
                    _payout = _maxPayout.sub(investnew[_user][_tree].depositPayouts);
                }
            }
          } 
    }
  
    function findFreeReferrer(address _user,uint _tree) public view returns(address) {
        if (investnew[_user][_tree].referals.length < referLimit) {
            return _user;
        }
        address[] memory referrals = new address[](126);
        referrals[0] = investnew[_user][_tree].referals[0];
        referrals[1] = investnew[_user][_tree].referals[1];

        address freeReferrer;
        bool noFreeReferrer = true;

        for (uint i = 0; i < 126; i++) { // Finding FreeReferrer
            if (investnew[referrals[i]][_tree].referals.length == referLimit) {
                if (i < 62) {
                    referrals[(i + 1) * 2] = investnew[referrals[i]][_tree].referals[0];
                    referrals[(i + 1) * 2 + 1] = investnew[referrals[i]][_tree].referals[1];
                }
            }
            else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }
        require(!noFreeReferrer, "Iwaso: No Free Referrer");
        return freeReferrer;
    }
    
    function viewReferals(address _user,uint _tree)public view returns(address[] memory,address[] memory) {
        return (investnew[_user][_tree].referals,
                investnew[_user][_tree].secondLineReferals);
    }
    
    function updateDollor(uint _deposit,uint _withdrawlimit,uint _binarylimit)public onlyOwner returns(bool) {
        dollorPrice = _deposit;
        withdrawLimit = _withdrawlimit;
        binaryLimit = _binarylimit;
    }
    
    function setStatus(bool _status)public onlyOwner {
        depositStatus = _status;
    }
    
    function updateAddress(address _owner,address _binary)public onlyOwner{
        owner = _owner;
        binaryAddress = _binary;
    }
    
    /**
     * @dev updatePrice: For update deposit amount
     */
    function updatePrice(uint _price) public onlyOwner {
        require(depositStatus == true,"Already price exist");
        dollorPrice = dollorPrice.mul(_price);
        withdrawLimit = withdrawLimit.mul(_price);
        binaryLimit = binaryLimit.mul(_price);
    }
    
    function updateDuraion(uint _duration,uint _payoutTime) public onlyOwner {
        duration = _duration;
        payoutDuration = _payoutTime;
    }
    
    /**
     * @dev failSafe: Returns transfer trx
     */
    function failSafe(address payable _toUser, uint _amount) public onlyOwner returns(bool) {
        require(_toUser != address(0), "Ewaso: Invalid Address");
        require(address(this).balance >= _amount, "Ewaso: Insufficient balance");
        (_toUser).transfer(_amount);
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