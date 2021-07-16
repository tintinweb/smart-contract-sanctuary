//SourceUnit: ewaso.sol

pragma solidity 0.5.14;
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
       uint currentid;
       bool isExist;
       uint depositAmount;
       bool active;
       uint depositTime;
       uint depositPayouts;
       uint binaryBonus;
       uint refCommission;
       address directReferer;
       address referer;
       address[] referals;
       address[] secondLineReferals;
       uint joinTime;
       address leftSide;
       address rightSide;
       uint flagNo;
    }
    
    struct magic{
       uint magicBonus;
       uint magicRefererid;
       uint magicId;
       address[] referals;
       bool magicStatus;
    }
   
    // Mapping users details by address
    mapping(address => userDetails)public users;
    // Mapping address by id
    mapping(uint => address)public userList;
    // Mapping users by tree wise
    mapping(address => mapping(uint => magic)) public magicTree;
    // Mapping users plan
    mapping(address => uint)public planCalc;
    // Mapping level income by levels
    mapping(uint => uint)public levelIncome;
    // Mapping users left count 
    mapping(address => uint)public leftCount;
    // Mapping users right count
    mapping(address => uint)public rightCount;
    // Mapping tree users by magic id
    mapping(uint => mapping(uint => address))public TreeUserList;
    // Mapping joining time
    mapping(address => uint)public JoinTime;
    
    
    // Level income event
    event LevelIncome(address indexed from, address indexed to, uint value, uint time);
     // Failsafe event
    event FailSafe(address indexed user, uint value, uint time);
      // Cumulative amounts
    event CumulativeAmount(address indexed from,uint value,uint time);
     // Invest event
    event Invest(address indexed from, address indexed to, uint value,uint flag, uint time);
    // Referal income event
    event ReferalIncome(address indexed from, address indexed to, uint value,uint flag, uint time);
     // Withdraw event
    event Withdraw(address indexed from, uint value, uint time);
    // Binary income
    event BinaryIncome(address indexed to,uint value,uint time);
    // Qcapping amount
    event QcappIncome(address indexed to,uint value,uint time);
    // Reinvest Event
    event ReInvest(address indexed from,address indexed to,uint value,uint time);

    // Users id
    uint public currentId = 2;
    // Magic users id
    uint public magicCurrId = 2;
    // Owner address
    address public owner;
    // Binary distributor;
    address public binaryAddress;
    // Referal limit
    uint public referLimit = 2;
    // USD price updation
    uint public dollorPrice = 150;
    // trx price in usd
    uint public trxUSDPrice;
    // Contract lock
    bool public lockStatus;
    uint public withdrawLimit = 10;
    // Binary limit perday
    uint public binaryLimit = 1000;
    // Status for deposit amount
    bool public depositStatus;
    // Deposit price
    uint public price;
    // Duration
    uint public duration = 15 days;
    // Payout duration
    uint public payoutDuration = 1 days;
    // Binary income
    uint public binaryIncome;
    // ROI income
    uint public roiIncome;
    // Creation time
    uint public contractCreation = block.timestamp;
   
   
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
    constructor(address _owner,address _binary)public {
        owner = _owner;
        binaryAddress = _binary;
        users[owner].currentid = 1;
        userList[1] = owner;
        magicTree[owner][1].magicId = 1;
        TreeUserList[1][1] = owner;
       
        for (uint i = 1; i <= 5; i++) {
            levelIncome[i] = 2; // For level income
        }

        for (uint i = 6; i <= 10; i++) {
            levelIncome[i] = 1; // For level income
        }
        
       
            users[owner].isExist = true;
        
    }
    
    function checkPrice()public view returns(uint){
        return trxUSDPrice;
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
    
    function checkjointime(address _user)external view returns(uint){
        return JoinTime[_user];
    }
    
    function invest(uint _refid,uint flag)  external isContractcheck(msg.sender) isLock payable {
        require(flag == 1 || flag == 2,"Wrong flag id");
        price = depAmount();
        require(msg.value == price, "Ewaso: Given wrong amount");
        if (users[msg.sender].depositTime > 0 || msg.sender == owner){
            require(users[msg.sender].depositPayouts >= this.maxPayoutOf(users[msg.sender].depositAmount),"Deposit exists");
            users[msg.sender].depositPayouts = 0;
            users[msg.sender].depositAmount = msg.value;
            users[msg.sender].depositTime = block.timestamp;
            users[msg.sender].active = true;
            binaryIncome = binaryIncome.add(msg.value.mul(40).div(100));
            roiIncome = roiIncome.add(msg.value.mul(40).div(100));
            emit ReInvest(msg.sender,users[msg.sender].referer,msg.value,block.timestamp);
            return;
        }
          address refofref;
         if (_refid == 0) {
             _refid = 1;
         }
         magicUpdate(msg.sender,userList[1],msg.value.mul(10).div(100));
         require(userList[_refid] != address(0),"Incorrect refer id");
        if (flag == 1){
            if(users[userList[_refid]].leftSide == address(0)){
                users[userList[_refid]].leftSide = msg.sender;
                users[msg.sender].referer = userList[_refid];
                refofref = users[userList[_refid]].referer;
                users[userList[_refid]].referals.push(msg.sender);
                users[refofref].secondLineReferals.push(msg.sender);
            }
            else{
                address ref = findLeftReferer(userList[_refid]);
                users[ref].leftSide = msg.sender;
                users[msg.sender].referer = ref;
                refofref = users[ref].referer;
                users[ref].referals.push(msg.sender);
                users[refofref].secondLineReferals.push(msg.sender);
                }
        }
        else if(flag == 2){
            if(users[userList[_refid]].rightSide == address(0)){
                users[userList[_refid]].rightSide = msg.sender;
                users[msg.sender].referer = userList[_refid];
                refofref = users[userList[_refid]].referer;
                users[userList[_refid]].referals.push(msg.sender);
                users[refofref].secondLineReferals.push(msg.sender);
            }
            else{
                address ref = findRightReferer(userList[_refid]);
                users[ref].rightSide = msg.sender;
                users[msg.sender].referer = ref;
                refofref = users[ref].referer;
                users[ref].referals.push(msg.sender);
                users[refofref].secondLineReferals.push(msg.sender);
                }
        }
        
        users[userList[_refid]].refCommission = users[userList[_refid]].refCommission.add(msg.value.mul(10).div(100));
        emit ReferalIncome(msg.sender, userList[_refid], msg.value.mul(10).div(100),flag, block.timestamp);
        
        users[msg.sender].currentid = currentId;
        currentId++;
        userList[users[msg.sender].currentid] = msg.sender;
        users[msg.sender].isExist = true;
        users[msg.sender].depositAmount = msg.value;
        users[msg.sender].active = true;
        users[msg.sender].depositTime = block.timestamp;
        users[msg.sender].joinTime = block.timestamp;
        users[msg.sender].depositPayouts = 0;
        users[msg.sender].binaryBonus = 0;
        users[msg.sender].refCommission = 0;
        users[msg.sender].directReferer = userList[_refid];
        users[msg.sender].flagNo = flag;
        
        updateCounts(msg.sender,users[msg.sender].referer);
        
         if (users[users[msg.sender].referer].referals.length == 2) {
               updateCategory(users[msg.sender].referer);
           }
           binaryIncome = binaryIncome.add(msg.value.mul(40).div(100));
           roiIncome = roiIncome.add(msg.value.mul(40).div(100));
           JoinTime[msg.sender] = block.timestamp;
            emit Invest(msg.sender, users[msg.sender].referer, msg.value, flag,block.timestamp);
    }
    
    function updateCategory(address _user)internal {
        if (block.timestamp <= users[_user].joinTime.add(duration)) {
            planCalc[_user] = 2;
        }
        else {
            planCalc[_user] = 1;
        }
    }
    
    function updateCounts(address _user,address _ref)internal{
        address user = _user;
        address ref = _ref;
        for (uint i = 0; i<50; i++){
        if (ref == address(0)){
        break;
        }
        if (users[ref].leftSide == user){
            leftCount[ref] = leftCount[ref].add(1);
        }
        else {
            rightCount[ref] = rightCount[ref].add(1);
        }
        user = users[user].referer;
        ref = users[ref].referer;
        }
    }
    
    function findLeftReferer(address _user)public view returns(address){
          if (users[_user].leftSide ==  address(0)) {
            return _user;
          }
           if (users[_user].leftSide !=  address(0)) {
           address ref = users[_user].leftSide;
               for(uint i = 0; i<62; i++){
                   if (users[ref].leftSide == address(0)){
                       return ref;
                   }
                   ref = users[ref].leftSide;
               }
           }
    }
    
    function findRightReferer(address _user)public view returns(address){
         if (users[_user].rightSide ==  address(0)) {
            return _user;
          }
           if (users[_user].rightSide !=  address(0)) {
           address ref = users[_user].rightSide;
               for(uint i = 0; i<62; i++){
                   if (users[ref].rightSide == address(0)){
                       return ref;
                   }
                   ref = users[ref].rightSide;
               }
           }
    }
    
    function magicUpdate(address _user,address _ref,uint _amt)internal{
        if (magicTree[_ref][1].referals.length >= referLimit){
            uint id = magicTree[findFreeReferrer(_ref,1)][1].magicId;
            magicTree[_user][1].magicRefererid = id;
        }
        else{
            magicTree[_user][1].magicRefererid = magicTree[_ref][1].magicId;
        }
         magicTree[_user][1].magicId = magicCurrId;
         TreeUserList[magicTree[_user][1].magicId][1] = _user;
         magicTree[_user][1].magicBonus = 0;
         magicTree[TreeUserList[magicTree[_user][1].magicRefererid][1]][1].referals.push(_user);
         magicTree[_user][1].magicStatus = true;
         magicCurrId++;
         _refpayout(_user,_amt,TreeUserList[magicTree[_user][1].magicRefererid][1],1);
    }
    
    function _refpayout(address _user, uint _amount, address _refer,uint _tree) internal {
        address ref = _refer;
        uint calc = _amount.div(15);
        for (uint i = 1; i <= 10; i++) {
            if (ref == owner) {
                uint amount;
                for (uint j = i; j<=10; j++){
                    amount = amount.add(levelIncome[j].mul(calc));
                }
                magicTree[owner][_tree].magicBonus = magicTree[owner][_tree].magicBonus.add(amount);
                emit LevelIncome(_user, owner, amount, block.timestamp);
                break;
            }
            magicTree[ref][_tree].magicBonus = magicTree[ref][_tree].magicBonus.add(levelIncome[i].mul(calc));
            emit LevelIncome(_user, ref, levelIncome[i].mul(calc), block.timestamp);
            ref = TreeUserList[magicTree[ref][1].magicRefererid][1];
        }
    }
    
    function Binary(uint[] memory _id, uint[] memory _amt)public binaryDistributer returns(bool) {
        require(_id.length == _amt.length,"Invalid Input");
        for (uint i=0;i<_id.length;i++) {
                if (_amt[i] < binaryLimit.mul(checkPrice()) || _id[i] <= 7 ){
                binaryIncome= binaryIncome.sub(_amt[i]);
                users[userList[_id[i]]].binaryBonus = users[userList[_id[i]]].binaryBonus.add(_amt[i]);
                emit BinaryIncome(userList[_id[i]],_amt[i],block.timestamp);
                }
                if (_amt[i] > binaryLimit.mul(checkPrice()) && _id[i] > 7){
                binaryIncome= binaryIncome.sub(_amt[i]);
                uint remainAmount = _amt[i].sub(binaryLimit.mul(checkPrice()));
                _amt[i] = _amt[i].sub(remainAmount);
                users[userList[_id[i]]].binaryBonus = users[userList[_id[i]]].binaryBonus.add(_amt[i]);
                emit BinaryIncome(userList[_id[i]],_amt[i],block.timestamp);
                for (uint j=1;j<=7;j++){
                    users[userList[j]].binaryBonus = users[userList[j]].binaryBonus.add(remainAmount.div(7));
                     emit QcappIncome(userList[j],remainAmount.div(7),block.timestamp);
                }
            } 
          
        }
         return true;
    }
    
    function withdraw() public isLock {
        (uint256 to_payout, uint256 max_payout,uint _plan) = this.payout(msg.sender);
        require(users[msg.sender].depositPayouts < max_payout || msg.sender == owner, "Ewaso: Full payouts");
        if (planCalc[msg.sender] == 0){
        planCalc[msg.sender] = _plan;
        }
        
        // Deposit payout
        if (to_payout > 0) {
            if (users[msg.sender].depositPayouts.add(to_payout) > max_payout) {
                to_payout = max_payout.sub(users[msg.sender].depositPayouts);
            }
           users[msg.sender].depositPayouts = users[msg.sender].depositPayouts.add(to_payout);
        }
        roiIncome = roiIncome.sub(to_payout);
        require(address(uint160(msg.sender)).send(to_payout), "Ewaso: withdraw failed");
        emit Withdraw(msg.sender, to_payout, block.timestamp);

        if (users[msg.sender].depositPayouts >= max_payout) {
            users[msg.sender].active = false;
        }
    }
    
     /**
     * @dev cumulativeWithdraw: User can withdraw their Referal commission , binary commission, level commission
     */
    function cumulativeWithdraw()public {
        uint amount;
        // Referal commission
        if (users[msg.sender].refCommission > 0) {
            amount = amount.add(users[msg.sender].refCommission);
            users[msg.sender].refCommission = 0;
        }

        // magic bonus
        if (magicTree[msg.sender][1].magicBonus > 0) {
            amount = amount.add(magicTree[msg.sender][1].magicBonus);
            magicTree[msg.sender][1].magicBonus = 0;
        }

        // Binary bonus
        if (users[msg.sender].binaryBonus > 0 ) {
            amount = amount.add(users[msg.sender].binaryBonus);
            users[msg.sender].binaryBonus = 0;
        }
        require(amount >= withdrawLimit.mul(checkPrice()),"Ewaso: Not reach 10$ amount ");
        require(address(uint160(msg.sender)).send(amount), "Ewaso: Cumulative failed");
        emit CumulativeAmount(msg.sender,amount,block.timestamp);
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
    function payout(address _user) external view returns(uint _payout, uint _maxPayout,uint _plan) {
        if (block.timestamp >= users[_user].depositTime.add(duration)) {
            if (planCalc[_user] == 0) {
                _plan = 1;
            }
            else {
                if (planCalc[_user] == 0)
                _plan = 2;
                else
                _plan = planCalc[_user];
            }
            uint amount = users[_user].depositAmount;
            _maxPayout = this.maxPayoutOf(amount);
            if (users[_user].depositPayouts < _maxPayout) {
                _payout = ((amount.mul(0.33e6).div(100e6)).mul((block.timestamp.sub(users[_user].depositTime.add(duration))).div(payoutDuration)));
                _payout = _payout.mul(_plan).sub(users[_user].depositPayouts);
                if (users[_user].depositPayouts.add(_payout) > _maxPayout) {
                    _payout = _maxPayout.sub(users[_user].depositPayouts);
                }
            }
          } 
    }
    
    function findFreeReferrer(address _user,uint _tree) public view returns(address) {
        if (magicTree[_user][_tree].referals.length < referLimit) {
            return _user;
        }
        address[] memory referrals = new address[](126);
        referrals[0] = magicTree[_user][_tree].referals[0];
        referrals[1] = magicTree[_user][_tree].referals[1];

        address freeReferrer;
        bool noFreeReferrer = true;

        for (uint i = 0; i < 126; i++) { // Finding FreeReferrer
            if (magicTree[referrals[i]][_tree].referals.length == referLimit) {
                if (i < 62) {
                    referrals[(i + 1) * 2] = magicTree[referrals[i]][_tree].referals[0];
                    referrals[(i + 1) * 2 + 1] = magicTree[referrals[i]][_tree].referals[1];
                }
            }
            else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }
        require(!noFreeReferrer, "Ewaso: No Free Referrer");
        return freeReferrer;
    }
    
    function updateDuraion(uint _duration,uint _payoutTime) public onlyOwner {
        duration = _duration;
        payoutDuration = _payoutTime;
    }
    
    function updateDollor(uint _deposit,uint _withdrawlimit,uint _binarylimit)public onlyOwner returns(bool) {
        dollorPrice = _deposit;
        withdrawLimit = _withdrawlimit;
        binaryLimit = _binarylimit;
    }
    
    function updateTrxUSDPrice( uint _trxUSDPrice) public {
        require((msg.sender == binaryAddress) || (msg.sender == owner),"updateTrxUSDPrice : not a binaryAddress wallet");
        trxUSDPrice =  _trxUSDPrice;
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
    
    function updateAmount(uint value)public onlyOwner{
        roiIncome = roiIncome.add(value);
        binaryIncome = binaryIncome.sub(value);
    }
    
    function viewCount(address _user)public view returns(uint,uint,address){
        return(leftCount[_user],
               rightCount[_user],
               _user);
    }
    
    function viewMagicReferals(address _user)public view returns(address[] memory){
        return magicTree[_user][1].referals;
    }
    
    function viewReferals(address _user)public view returns(address[] memory,address[] memory){
        return (users[_user].referals,
                users[_user].secondLineReferals);
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