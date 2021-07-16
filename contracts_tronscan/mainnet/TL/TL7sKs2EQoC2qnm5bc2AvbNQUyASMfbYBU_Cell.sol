//SourceUnit: cell.sol

pragma solidity ^0.5.0;
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
contract TokenControl{
    uint8 public peridsNumber;
    struct PERIOD{
        uint256 multiples;
        uint256 currentMultiples;
        uint256 lowerLimitQuota;
        uint256 upperLimitQuota;
        uint256 totalLockUpCount;
        uint256 currentLockUpCount;
        uint256 lockUpPercent;
        uint256 lockUpQuantity;
        uint256 totalPower;
        uint deadline;
        uint startTime;
        mapping(address=>uint256) balances;
        mapping(address =>lockUpCount) address_lockInfo;
        address[] addressList;
        bool unlockDAO;
    }
    struct lockUpCount{
        uint256  amount;
        uint256  totalPower;
        uint256  teamLockUpCount;
        uint256  directRecommendLockUpCount;
        uint256  staticIncome;
        uint256  firstSettleStaticTime;
        uint256  dynamicIncome;
        uint256  issueIncome;
        bool     is_oldAddress;
        bool     is_unlock;
    }
    uint256 public nextMultiples;
    uint256 public nextTotalLockUpCount;
    uint8 public totalNormalPerids;
    mapping(uint=>PERIOD) public Periods;
    struct User {
        uint id;
        uint directRecommendCount;
        uint teamCount;
        address referrer;
    }
    mapping(address => User) public users;
    address[] public allAddress;
    mapping(uint8 => uint) public levelPrice;
    uint8 public DynamicPercent;
    uint8 public DAOPercent;
    uint8 public LiquidityOrOtherPercent;
    uint public lastUserId = 6;
    address public daoAddress;
    address public liquidityOrOtherAddress;
    event Issue( address indexed _to, uint256 _value);
    event StaticIncome( address indexed _to, uint256 _value);
    event DynamicIncome( address indexed _to, uint256 _value);
}
contract Token {
    uint256 public totalSupply;
    uint256 public totalCirculates;
    function balanceOf(address _owner) public view returns(uint256 balance);
    function transfer(address _to,uint256 _value) public returns(bool success);
    function transferFrom(address _from,address _to,uint256 _value)public returns(bool success);
    function approve(address _spender,uint256 _value)public returns(bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract Cell is Token,TokenControl{
    event Burn(uint256 _amount);
    event AddedBlackList(address _addr);
    event RemovedBlackList(address _addr);
    using SafeMath for uint256;
    string public name;
    uint8 public decimals;
    string public symbol;
    address public owner;
    bool isStartLock;
    mapping(address=>uint256) public balances;
    mapping(address=>mapping (address=>uint256)) allowed;
    constructor(address[] memory _owner,address _superOwner,address _daoAddress,address _liquidityOrOtherAddress)public payable{
        name="Cell";
        owner=_superOwner;
        daoAddress=_daoAddress;
        liquidityOrOtherAddress=_liquidityOrOtherAddress;
        decimals=6;
        totalSupply=880000* 10 ** uint256(decimals); 
        balances[owner]=totalSupply;
        symbol="Cell";
        DynamicPercent=40;
        DAOPercent=20;
        totalNormalPerids=1;
        LiquidityOrOtherPercent=10;
        levelPrice[1] = 50;
        levelPrice[2] = 40;
        levelPrice[3] = 30;
        levelPrice[4] = 20;
        levelPrice[5] = 10;
        for(uint8 i=1;i<=5;i++){
           User memory user = User({
            id: i,
            directRecommendCount:uint(1),
            teamCount: uint(5-i),
            referrer:address(0)
            });
           if (i>1){
              user.referrer=_owner[i-2];
            }
           users[_owner[i-1]] = user;
        }
    }
    modifier onlyOwner() {
        require(msg.sender==owner);
        _;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Ownable: new owner is the zero address");
        owner = _newOwner;
    }
    function transfer(address _to,uint256 _value) public returns(bool success){
         require(msg.sender != address(0), "ERC20: approve from the zero address");
         require(_to != address(0), "ERC20: approve to the zero address");
         balances[msg.sender]=balances[msg.sender].sub(_value);
         balances[_to]=balances[_to].add(_value);
         if (msg.sender==owner){
             totalCirculates=totalCirculates.add(_value);
         }
         if (_to==owner){
             totalCirculates=totalCirculates.sub(_value);
         }
         emit Transfer(msg.sender, _to, _value);
         return true;
    }
    function transferFrom(address _from,address _to,uint256 _value) public returns(bool){
        balances[_to]=balances[_to].add(_value);
        balances[_from]=balances[_from].sub(_value);
        allowed[_from][msg.sender]=allowed[_from][msg.sender].sub(_value,"ERC20: transfer amount exceeds allowance");
        emit Transfer(_from,_to,_value);
        return true;
    }
    function balanceOf(address _owner)public view returns(uint256){
           return balances[_owner];
    }
    function approve(address _spender,uint256 _value) public returns(bool success){
        require(msg.sender != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");
        allowed[msg.sender][_spender]=_value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool) {
        approve(_spender, allowed[msg.sender][_spender].add(_addedValue));
        return true;
    }
    function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns (bool) {
        approve(_spender, allowed[msg.sender][_spender].sub(_subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
    modifier verifyStartTime() {
        require(isStartLock==true,"reorganization has not begin");
        require(now >Periods[peridsNumber].startTime,"The round of reorganization has not begin");
        require(now<Periods[peridsNumber].deadline,"The round of reorganization is not over");
        _;
    }
    function startLockup() public onlyOwner{
        require(isStartLock==false,"reorganization has begun");
        PERIOD memory period;
        peridsNumber=1;
        period.totalLockUpCount=300000000000;
        period.lowerLimitQuota=150000000;
        period.upperLimitQuota=1500000000;
        period.multiples=20;
        period.currentMultiples=20;
        period.startTime=now+24 hours;
        period.deadline=now+24 hours+30 days;
        Periods[peridsNumber]=period;
        isStartLock=true;
    }
    function setLimitedQuota(uint256 _lowerLimitedQuota,uint256 _upperLimitedQuota) onlyOwner public{
        Periods[peridsNumber].lowerLimitQuota=_lowerLimitedQuota;
        Periods[peridsNumber].upperLimitQuota=_upperLimitedQuota;
    }
    function burn(uint amount) public onlyOwner {
        require(totalSupply >= amount);
        require(balances[owner] >= amount);
        totalSupply =totalSupply.sub(amount);
        balances[owner]= balances[owner].sub(amount);
        emit Burn(amount);
    }
    function periodBurn(uint8 _peridsNumber) public{
        require(Periods[_peridsNumber].lockUpQuantity==0&&Periods[_peridsNumber].unlockDAO==true);
        totalSupply =totalSupply.sub(Periods[_peridsNumber].balances[address(this)]);
        balances[address(this)]=balances[address(this)].sub(Periods[_peridsNumber].balances[address(this)]);
        emit Burn(Periods[_peridsNumber].balances[address(this)]);
        Periods[_peridsNumber].balances[address(this)]=0;
    }
    function lockUp(uint256 _value,address _referrerAddress) public verifyStartTime payable returns(bytes memory){
        require(balances[msg.sender]>=_value,"Insufficient Cell balance at this address");
        require(_value%Periods[peridsNumber].lowerLimitQuota==0&&_value<=Periods[peridsNumber].upperLimitQuota,"The reorganization ratio is irregular");
        require(Periods[peridsNumber].address_lockInfo[msg.sender].is_oldAddress==false,"The address has been participated in this round");
        require(Periods[peridsNumber].totalLockUpCount.sub(Periods[peridsNumber].currentLockUpCount)>=_value,"out of remaining reorganization quota");
        require(isUserExists(_referrerAddress),"ReferrerAddress don't exist");
        bool isExists =isUserExists(msg.sender);
        if (!isExists){
            User memory user = User({
                id: lastUserId,
                referrer: _referrerAddress,
                teamCount: uint(0),
                directRecommendCount:0
                });
            users[msg.sender] = user;
            lastUserId++;
            users[_referrerAddress].directRecommendCount++;
            allAddress.push(msg.sender);
         }
        address userAddress=users[msg.sender].referrer;
        Periods[peridsNumber].address_lockInfo[userAddress].directRecommendLockUpCount+=1;
        uint8 i=1;
        uint8 powerBase=uint8(_value/150000000);
        while (true) {
                if (users[userAddress].id==0||i==6) {
                    break;
                }
                if (!isExists){
                   users[userAddress].teamCount++;
                }
                Periods[peridsNumber].address_lockInfo[userAddress].totalPower+=levelPrice[i]*powerBase;
                Periods[peridsNumber].address_lockInfo[userAddress].teamLockUpCount+=1;
                userAddress = users[userAddress].referrer;
                i++;
            }
        balances[msg.sender]=balances[msg.sender].sub(_value);
        Periods[peridsNumber].balances[address(this)]+=_value;
        balances[address(this)]+=_value;
        totalCirculates=totalCirculates.sub(_value);
        emit Transfer(msg.sender,address(this),_value);
        Periods[peridsNumber].addressList.push(msg.sender);
        Periods[peridsNumber].address_lockInfo[msg.sender].amount+=_value;
        uint256 firstSettleStaticTime=now+1 days;
        Periods[peridsNumber].address_lockInfo[msg.sender].firstSettleStaticTime=firstSettleStaticTime-(firstSettleStaticTime % (1440*60))-28800;
        Periods[peridsNumber].address_lockInfo[msg.sender].is_oldAddress=true;
        Periods[peridsNumber].currentLockUpCount+=_value;
        Periods[peridsNumber].totalPower+=_value/1000000;
        Periods[peridsNumber].lockUpQuantity+=1;
        Periods[peridsNumber].lockUpPercent=(Periods[peridsNumber].currentLockUpCount*100)/Periods[peridsNumber].totalLockUpCount;
        if (Periods[peridsNumber].lockUpPercent<20){
            nextMultiples=Periods[peridsNumber].currentMultiples;
            Periods[peridsNumber].multiples=7;
            nextTotalLockUpCount=Periods[peridsNumber].totalLockUpCount;
        }
        if (Periods[peridsNumber].lockUpPercent>=20&&Periods[peridsNumber].lockUpPercent<=80){
            nextMultiples=Periods[peridsNumber].currentMultiples;
            Periods[peridsNumber].multiples=10;
            nextTotalLockUpCount=Periods[peridsNumber].totalLockUpCount;
        }
        if (Periods[peridsNumber].lockUpPercent>80){
            nextMultiples=Periods[peridsNumber].currentMultiples-1;
            Periods[peridsNumber].multiples=Periods[peridsNumber].currentMultiples;
            nextTotalLockUpCount=Periods[peridsNumber].totalLockUpCount*2;      
        }
        if (Periods[peridsNumber].lockUpPercent==100){
            Periods[peridsNumber].deadline=now;
        }
        return bytes("success");
    }
    function unlockPeriods(uint8 _peridsNumber) public returns(bytes memory){
        require(now >=Periods[_peridsNumber].startTime,"The round of reorganization has not begin");
        require(now >=Periods[_peridsNumber].deadline,"The round of reorganization is not over");
        require(Periods[_peridsNumber].address_lockInfo[msg.sender].is_oldAddress==true,"You are not involved in this round");
        require(Periods[_peridsNumber].address_lockInfo[msg.sender].is_unlock==false,"You have drawn on the proceeds of this round");
        if (Periods[peridsNumber].deadline<=now&&totalNormalPerids<15){
            if (Periods[peridsNumber].lockUpPercent>80){
                totalNormalPerids+=1;
            }
            PERIOD memory period;
            peridsNumber+=1;
            if (nextMultiples<=12){
                period.multiples=12;
            }else{
                period.multiples=nextMultiples;
            }
            period.currentMultiples=period.multiples;
            period.totalLockUpCount=nextTotalLockUpCount;
            period.lowerLimitQuota=150000000;
            period.upperLimitQuota=1500000000;
            period.deadline=now+72 hours+30 days;
            period.startTime=now+72 hours;
            Periods[peridsNumber]=period;
        }
            uint256 amount=Periods[_peridsNumber].address_lockInfo[msg.sender].amount;
            uint256 addIssue=(amount*Periods[_peridsNumber].multiples)/10;
            balances[msg.sender]+=addIssue;
            totalCirculates+=addIssue;
            totalSupply+=addIssue;
            emit Issue(msg.sender,addIssue);
            Periods[_peridsNumber].address_lockInfo[msg.sender].issueIncome=addIssue;
            if (Periods[_peridsNumber].lockUpPercent>=20){
                uint256 DynamicCount=(Periods[_peridsNumber].currentLockUpCount*DynamicPercent)/100;
                uint256 power=Periods[_peridsNumber].address_lockInfo[msg.sender].totalPower;
                if (power!=0){
                    uint256 dynamicIncome=(DynamicCount*power)/Periods[_peridsNumber].totalPower;
                    balances[address(this)]=balances[address(this)].sub(dynamicIncome);
                    Periods[_peridsNumber].balances[address(this)]=Periods[_peridsNumber].balances[address(this)].sub(dynamicIncome);
                    balances[msg.sender]+=dynamicIncome;
                    totalCirculates+=dynamicIncome;
                    emit Transfer(address(this),msg.sender,dynamicIncome);
                    emit DynamicIncome(msg.sender,dynamicIncome);
                    Periods[_peridsNumber].address_lockInfo[msg.sender].dynamicIncome=dynamicIncome;
                }
           }
           if (Periods[_peridsNumber].deadline>=Periods[_peridsNumber].address_lockInfo[msg.sender].firstSettleStaticTime){
               settleStaticIncome(_peridsNumber);
           }
           Periods[_peridsNumber].lockUpQuantity=Periods[_peridsNumber].lockUpQuantity.sub(1);
           Periods[_peridsNumber].address_lockInfo[msg.sender].is_unlock=true;
           if (Periods[_peridsNumber].lockUpQuantity==0&&Periods[_peridsNumber].unlockDAO==true){
               periodBurn(_peridsNumber);
           }
           return bytes("success");

    }
    function settleStaticIncome(uint8 _peridsNumber) public returns(bytes memory){
            require(Periods[_peridsNumber].address_lockInfo[msg.sender].is_oldAddress==true,"You are not involved in this round");
            require(Periods[_peridsNumber].deadline>=Periods[_peridsNumber].address_lockInfo[msg.sender].firstSettleStaticTime,"You have no daily proceeds in this round");
            require(now>=Periods[_peridsNumber].address_lockInfo[msg.sender].firstSettleStaticTime,"Not Due time for settlement");
            uint256 nowTime;
            uint256 amount=Periods[_peridsNumber].address_lockInfo[msg.sender].amount;
            if (now>=Periods[_peridsNumber].deadline){
                  nowTime=Periods[_peridsNumber].deadline;    
                  
            }else{
                nowTime=now;
            }
            uint256 subTime;
            subTime=nowTime.sub(Periods[_peridsNumber].address_lockInfo[msg.sender].firstSettleStaticTime);
            uint256 allStaticIncome=(amount/100)*(subTime/(1 days)+1);
            uint256 balanceStaticIncome=allStaticIncome.sub(Periods[_peridsNumber].address_lockInfo[msg.sender].staticIncome);
            balances[address(this)]=balances[address(this)].sub(balanceStaticIncome);
            Periods[_peridsNumber].balances[address(this)]=Periods[_peridsNumber].balances[address(this)].sub(balanceStaticIncome);
            balances[msg.sender]+=balanceStaticIncome;
            totalCirculates+=balanceStaticIncome;
            Periods[_peridsNumber].address_lockInfo[msg.sender].staticIncome+=balanceStaticIncome;
            emit Transfer(address(this),msg.sender,balanceStaticIncome);  
            emit StaticIncome(msg.sender,balanceStaticIncome);
            return bytes("success");
    }
    function getAddressList(uint8 _peridsNumber) view public returns(address[] memory){
        return Periods[_peridsNumber].addressList;
    }
    function getPeriodAddressInfo(address _addr,uint8 _peridsNumber)view public returns(uint256 _amount,uint256 _totalPower,uint256 _teamLockUpCount,uint256 _staticIncome,uint256 _issueIncome,bool _is_oldAddress){
        return (Periods[_peridsNumber].address_lockInfo[_addr].amount,
         Periods[_peridsNumber].address_lockInfo[_addr].totalPower,
         Periods[_peridsNumber].address_lockInfo[_addr].teamLockUpCount,
         Periods[_peridsNumber].address_lockInfo[_addr].staticIncome,
         Periods[_peridsNumber].address_lockInfo[_addr].issueIncome,
         Periods[_peridsNumber].address_lockInfo[_addr].is_oldAddress);
    }
    function getPeriodAddressInfo2(address _addr,uint8 _peridsNumber)view public returns(uint256 _firstSettleStaticTime,uint256 _dynamicIncome,uint256 _directRecommendLockUpCount,bool _is_unlock){
        return (Periods[_peridsNumber].address_lockInfo[_addr].firstSettleStaticTime,
         Periods[_peridsNumber].address_lockInfo[_addr].dynamicIncome,
         Periods[_peridsNumber].address_lockInfo[_addr].directRecommendLockUpCount,
         Periods[_peridsNumber].address_lockInfo[_addr].is_unlock);
    }
    function withdrawal() onlyOwner public{
      msg.sender.transfer(address(this).balance);
    }
    function withdrawalCell(uint8 _peridsNumber) onlyOwner public{
        uint256 dao=(Periods[_peridsNumber].currentLockUpCount*DAOPercent)/100;
        balances[address(this)]=balances[address(this)].sub(dao);
        Periods[_peridsNumber].balances[address(this)]=Periods[_peridsNumber].balances[address(this)].sub(dao);
        balances[daoAddress]+=dao;
        totalCirculates+=dao;
        emit Transfer(address(this),daoAddress,dao);
        uint256 liquidityOrOther=(Periods[_peridsNumber].currentLockUpCount*LiquidityOrOtherPercent)/100;
        balances[address(this)]=balances[address(this)].sub(liquidityOrOther);
        Periods[_peridsNumber].balances[address(this)]=Periods[_peridsNumber].balances[address(this)].sub(liquidityOrOther);
        balances[liquidityOrOtherAddress]+=liquidityOrOther;
        totalCirculates+=liquidityOrOther;
        emit Transfer(address(this),liquidityOrOtherAddress,liquidityOrOther);
        Periods[_peridsNumber].unlockDAO=true;
    }
    function() payable external{}
}