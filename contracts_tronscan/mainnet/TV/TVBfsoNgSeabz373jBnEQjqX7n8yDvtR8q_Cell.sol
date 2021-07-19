//SourceUnit: cell.sol

pragma experimental ABIEncoderV2;
pragma solidity ^0.5.0;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
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

        uint256 totalPower;

        uint deadline;
        uint startTime;

        uint settleStaticIncomeTime;


        mapping(address =>lockUpCount) address_lockInfo;

        address[] addressList;

        bool is_unlock;

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

    mapping(uint=>PERIOD) public Periods;
    struct User {
        uint id;
        uint directRecommendCount;
        uint teamCount;
        address referrer;
    }


    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;

    address[] public allAddress;
    mapping(uint8 => uint) public levelPrice;

    uint public DynamicPercent;
    uint public StaticPercent;
    uint public DAOPercent;
    uint public LiquidityOrOtherPercent;

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
    event Redeem(uint256 _amount);
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

    mapping(address=>bool) public owners;
    

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
        StaticPercent=30;
        DAOPercent=20;
        LiquidityOrOtherPercent=10;

        levelPrice[1] = 50;
        levelPrice[2] = 40;
        levelPrice[3] = 30;
        levelPrice[4] = 20;
        levelPrice[5] = 10;

        User memory userA = User({
        id: 1,
        directRecommendCount:uint(1),
        teamCount: uint(4),
        referrer: address(0)
        });
        users[_owner[0]] = userA;
        idToAddress[1] = _owner[0];
        
        User memory userB = User({
        id: 2,
        directRecommendCount:uint(1),
        teamCount: uint(3),
        referrer: _owner[0]
        });
        users[_owner[1]] = userB;
        idToAddress[2] = _owner[1];
        
        User memory userC = User({
        id: 3,
        directRecommendCount:uint(1),
        teamCount: uint(2),
        referrer: _owner[1]
        });
        users[_owner[2]] = userC;
        idToAddress[3] = _owner[2];
        
        User memory userD = User({
        id: 4,
        directRecommendCount:uint(1),
        teamCount: uint(1),
        referrer: _owner[2]
        });
        users[_owner[3]] = userD;
        idToAddress[4] = _owner[3];
         
        User memory userE = User({
        id: 5,
        directRecommendCount:uint(0),
        teamCount: uint(0),
        referrer:_owner[3]
        });
        users[_owner[4]] = userE;
        idToAddress[5] = _owner[4];
    }
    modifier onlyOwner() {
        require(msg.sender==owner);
        _;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Ownable: new owner is the zero address");
        owner = _newOwner;
    }

    
    modifier verifyStartTime() {
        require(isStartLock=true,"锁仓游戏未开始");
        require(now >Periods[peridsNumber].startTime,"本轮锁仓未开始");
        require(now<Periods[peridsNumber].deadline,"本轮锁仓已结束");
        _;
    }

    function startLockup() public onlyOwner{
        require(isStartLock==false,"锁仓游戏已开启，任何人无法停止");
        PERIOD memory period;
        peridsNumber=1;
        period.totalLockUpCount=300000000000;
        period.lowerLimitQuota=150000000;
        period.upperLimitQuota=1500000000;
        period.multiples=20;
        period.currentMultiples=20;
        period.startTime=now+24 hours;
        period.deadline=now+24 hours+30 days;
        uint256 dida=period.startTime+24 hours;
        period.settleStaticIncomeTime=dida-(dida%(1440*60))-28800;
        Periods[peridsNumber]=period;
        isStartLock=true;
    }

    function setLimitedQuota(uint256 _lowerLimitedQuota,uint256 _upperLimitedQuota) onlyOwner public{
        Periods[peridsNumber].lowerLimitQuota=_lowerLimitedQuota;
        Periods[peridsNumber].upperLimitQuota=_upperLimitedQuota;
    }
    

    function redeem(uint amount) public onlyOwner {
        require(totalSupply >= amount);
        require(balances[owner] >= amount);
        totalSupply -= amount;
        balances[owner] -= amount;
        emit Redeem(amount);
    }
    

    function transfer(address _to,uint256 _value) public returns(bool success){
         require(balances[msg.sender]>=_value&&balances[_to]+_value>balances[_to]);
         balances[msg.sender]=balances[msg.sender].sub(_value);
         balances[_to]=balances[_to].add(_value);
         
         if (msg.sender==owner){
             totalCirculates+=_value;
         }

         emit Transfer(msg.sender, _to, _value);
         return true;
    }

    function transferFrom(address _from,address _to,uint256 _value) public returns(bool){
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to]=balances[_to].add(_value);
        balances[_from]=balances[_from].sub(_value);
        allowed[_from][msg.sender]=allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from,_to,_value);
        return true;
    }
    function balanceOf(address _owner)public view returns(uint256){
           return balances[_owner];
    }
    function approve(address _spender,uint256 _value) public returns(bool success){
        require(msg.sender != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");
        allowed[msg.sender][_spender]=allowed[msg.sender][_spender].add(_value);
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function lockUp(uint256 _value,address _referrerAddress) public verifyStartTime payable returns(bytes memory){
        require(balances[msg.sender]>=_value,"该地址余额不足");
        require(_value%Periods[peridsNumber].lowerLimitQuota==0&&_value<=Periods[peridsNumber].upperLimitQuota,"锁仓比例不合规则");
        require(Periods[peridsNumber].address_lockInfo[msg.sender].is_oldAddress==false,"该地址本轮已锁过仓");
        require(Periods[peridsNumber].totalLockUpCount.sub(Periods[peridsNumber].currentLockUpCount)>=_value,"锁仓数超过剩余锁仓额度");
        require(isUserExists(_referrerAddress),"推荐人不存在");
        bool isExists =isUserExists(msg.sender);
        if (!isExists){
            User memory user = User({
                id: lastUserId,
                referrer: _referrerAddress,
                teamCount: uint(0),
                directRecommendCount:0
                });
            users[msg.sender] = user;
            idToAddress[lastUserId] = msg.sender;
            lastUserId++;
            users[_referrerAddress].directRecommendCount++;
            allAddress.push(msg.sender);
         }
        address userAddress=users[msg.sender].referrer;
        Periods[peridsNumber].address_lockInfo[userAddress].directRecommendLockUpCount+=1;
        uint8 i=1;
        while (true) {
                if (users[userAddress].id==0||i==6) {
                    break;
                }
                if (!isExists){
                   users[userAddress].teamCount++;
                }
                Periods[peridsNumber].address_lockInfo[userAddress].totalPower+=levelPrice[i];
                Periods[peridsNumber].address_lockInfo[userAddress].teamLockUpCount+=1;
                userAddress = users[userAddress].referrer;
                i++;
            }
        
        balances[msg.sender]=balances[msg.sender].sub(_value);
        balances[address(this)]+=_value;
        totalCirculates=totalCirculates.sub(_value);
        emit Transfer(msg.sender,address(this),_value);
        Periods[peridsNumber].addressList.push(msg.sender);
        Periods[peridsNumber].address_lockInfo[msg.sender].amount+=_value;
        uint256 firstSettleStaticTime=now+1 days;
        Periods[peridsNumber].address_lockInfo[msg.sender].firstSettleStaticTime=firstSettleStaticTime-(firstSettleStaticTime % (1440*60))-28800;
        Periods[peridsNumber].address_lockInfo[msg.sender].is_oldAddress=true;
        Periods[peridsNumber].currentLockUpCount+=_value;
        Periods[peridsNumber].totalPower+=150;
        uint256 lockUpPercent=(Periods[peridsNumber].currentLockUpCount*100)/Periods[peridsNumber].totalLockUpCount;
        Periods[peridsNumber].lockUpPercent=lockUpPercent;
        if (lockUpPercent<20){
            nextMultiples=Periods[peridsNumber].currentMultiples;
            Periods[peridsNumber].multiples=7;
            nextTotalLockUpCount=Periods[peridsNumber].totalLockUpCount;
        }
        if (lockUpPercent>=20&&lockUpPercent<=80){
            nextMultiples=Periods[peridsNumber].currentMultiples;
            Periods[peridsNumber].multiples=10;
            nextTotalLockUpCount=Periods[peridsNumber].totalLockUpCount;
        }
        if (lockUpPercent>80){
            nextMultiples=Periods[peridsNumber].currentMultiples-1;
            Periods[peridsNumber].multiples=Periods[peridsNumber].currentMultiples;
            nextTotalLockUpCount=Periods[peridsNumber].totalLockUpCount*2;      
        }
        if (Periods[peridsNumber].totalLockUpCount==Periods[peridsNumber].currentLockUpCount){
            Periods[peridsNumber].deadline=now;
        }
        
        return bytes("锁仓已经成功");
    }

    function unlockPeriods(uint8 _peridsNumber) public returns(bytes memory){
        require(now >=Periods[_peridsNumber].startTime,"该轮锁仓未开始");
        require(now >=Periods[_peridsNumber].deadline,"该轮锁仓未结束");
        require(Periods[_peridsNumber].address_lockInfo[msg.sender].is_oldAddress==true,"您该轮未参投");
        require(Periods[_peridsNumber].address_lockInfo[msg.sender].is_unlock==false,"该轮收益你已提取");
        if (Periods[peridsNumber].deadline<=now){
            Periods[peridsNumber].is_unlock=true;
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
            period.deadline=now+24 hours+30 days;
            period.startTime=now+24 hours;
            uint256 dida=period.startTime+24 hours;
            period.settleStaticIncomeTime=dida-(dida%(1440*60))-28800;
            Periods[peridsNumber]=period;
        }
            uint256 amount=Periods[_peridsNumber].address_lockInfo[msg.sender].amount;
            uint256 addIssue=(amount*Periods[_peridsNumber].multiples)/10;
            balances[msg.sender]+=addIssue;
            totalCirculates+=addIssue;
            emit Transfer(address(this),msg.sender,addIssue);
            emit Issue(msg.sender,addIssue);
            Periods[_peridsNumber].address_lockInfo[msg.sender].issueIncome=addIssue;
            if (Periods[_peridsNumber].lockUpPercent>=20){
                uint256 DynamicCount=(Periods[_peridsNumber].currentLockUpCount*DynamicPercent)/100;
                uint256 power=Periods[_peridsNumber].address_lockInfo[msg.sender].totalPower;
                if (power!=0){
                    uint256 dynamicIncome=(DynamicCount*power)/Periods[_peridsNumber].totalPower;
                    balances[address(this)]=balances[address(this)].sub(dynamicIncome);
                    balances[msg.sender]+=dynamicIncome;
                    totalCirculates+=dynamicIncome;
                    emit Transfer(address(this),msg.sender,dynamicIncome);
                    emit DynamicIncome(msg.sender,dynamicIncome);
                    Periods[_peridsNumber].address_lockInfo[msg.sender].dynamicIncome=dynamicIncome;
                }
            
           }
           Periods[_peridsNumber].address_lockInfo[msg.sender].is_unlock=true;
           return bytes("提现已经成功");

    }
    function settleStaticIncome(uint8 _peridsNumber) public returns(bytes memory){
            require(Periods[_peridsNumber].address_lockInfo[msg.sender].is_oldAddress==true,"您该轮未参投");
            require(Periods[_peridsNumber].deadline>=Periods[_peridsNumber].settleStaticIncomeTime,"该轮重组周期小于1天,无日收益");
            require(now>=Periods[_peridsNumber].address_lockInfo[msg.sender].firstSettleStaticTime,"未到日收益结算时间");
            uint256 nowTime;
            uint256 amount=Periods[_peridsNumber].address_lockInfo[msg.sender].amount;

            if (now>=Periods[_peridsNumber].deadline){
                if (Periods[_peridsNumber].lockUpPercent<100){
                  nowTime=Periods[_peridsNumber].deadline+1 days;  
                }else{
                  nowTime=Periods[_peridsNumber].deadline;    
                }
                  
            }else{
                nowTime=now;
            }
            uint256 subTime;

            subTime=nowTime.sub(Periods[_peridsNumber].address_lockInfo[msg.sender].firstSettleStaticTime);

            uint256 allStaticIncome=(amount/100)*(subTime/(1 days)+1);
            uint256 balanceStaticIncome=allStaticIncome.sub(Periods[_peridsNumber].address_lockInfo[msg.sender].staticIncome);
            balances[address(this)]=balances[address(this)].sub(balanceStaticIncome);
            balances[msg.sender]+=balanceStaticIncome;
            totalCirculates+=balanceStaticIncome;
            Periods[_peridsNumber].address_lockInfo[msg.sender].staticIncome+=balanceStaticIncome;
            emit Transfer(address(this),msg.sender,balanceStaticIncome);  
            emit StaticIncome(msg.sender,balanceStaticIncome);
            return bytes("提现已经成功");
    }

    
    function getAddressList(uint8 _peridsNumber) view public returns(address[] memory){
        return Periods[_peridsNumber].addressList;
    }

    function getPeriodAddressInfo(address _addr,uint8 _peridsNumber)view public returns(uint256 _amount,uint256 _totalPower,uint256 _teamLockUpCount,
    uint256 _staticIncome,uint256 _issueIncome,bool _is_oldAddress){
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
        balances[daoAddress]+=dao;
        totalCirculates+=dao;
        emit Transfer(address(this),daoAddress,dao);
        uint256 liquidityOrOther=(Periods[_peridsNumber].currentLockUpCount*LiquidityOrOtherPercent)/100;
        balances[address(this)]=balances[address(this)].sub(liquidityOrOther);
        balances[liquidityOrOtherAddress]+=liquidityOrOther;
        totalCirculates+=liquidityOrOther;
        emit Transfer(address(this),liquidityOrOtherAddress,liquidityOrOther);
    }

    function() payable external{}

}