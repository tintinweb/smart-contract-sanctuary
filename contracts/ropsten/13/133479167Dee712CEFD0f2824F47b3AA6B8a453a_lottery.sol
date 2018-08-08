pragma solidity ^0.4.21;
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor () public{
    owner = msg.sender;
  }   
//   function Ownable() public {
//     owner = msg.sender;
//   }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}


contract checkF {
  
  //判断期数是否可以添加，大于上一期的才可以添加
  modifier checkCreateLottery(uint32 _lotteryDate , uint32 _lastlotteryDate) {
    require(_lotteryDate > _lastlotteryDate);
    _;
  }
  
  //判断期数是否可以保存（投注），存在的期数的才可以保存（投注）
  modifier checkSaveLottery(uint32 _lotteryDate , uint32 _lastlotteryDate ,uint open){
    require(_lotteryDate <= _lastlotteryDate && open == 2);
    _;
  }
  
  //必须有投注号码
  modifier checkLotteryNum(uint32 _lotteryNum){
    require(_lotteryNum > 0);
    _;
  }
  //必须有道琼指数
  modifier checkdowjones(uint256 _dowjones,uint256 _nasdaq){
    require(_dowjones > 0 && _nasdaq > 0);
    _;
  }  
}

contract lottery is Ownable , checkF{
    //所有投注期数
    struct Lottery {
        uint32  lotteryDate;
    }
    //User betting
    struct LotteryUserResult {
        address  userAddress;//用户地址 
        uint32  lotteryDate;//投注期数
        uint64  userBettingTime;//用户投注时间
        uint32  lotteryNum;//用户投注号码
        uint8  result;//投注结果
        uint256 money;//投注金额
        uint256 takemoney; //获得金额
    }
    
    struct LotteryTimeResult {
        uint32  lotteryNum;//开奖号码
        uint256  dowjones;//道琼指数（整数）
        uint256  nasdaq;//纳斯达克指数（整数）
        uint8  open; //0默认  1开奖 2首次创建
        uint256  allbettingtime;//总的投注人数
        uint256  resultprizeNum;//本期奖励金额
        //各个等级的金额
        uint256  result66Num;
        uint256  result1Num;
        uint256  result2Num;
        uint256  result3Num;
        uint256  result4Num;
        uint256  result5Num;
        uint256  result6Num;//没中奖
    }
    
    struct userLog {
        uint32  lotteryDate;
        uint256  index;
    }
    
    //投注期数的次数
    uint256 public lotteryAllCount;
    //总的投注彩池金额
    uint256 public lotteryAllMoney;

    //上次期数日期;
    uint32 public lastlotteryDate;
    Lottery[] lotteryList;
    //映射每期投注用户列表
    mapping (uint32 => LotteryUserResult[]) public lotteryuserresultlist;
    //映射用户投注列表数量
     mapping (address => uint256) public userBettingCount;
    //映射用户投注列表
    mapping (address => userLog[]) public userBettingList;
    //映射每期是否开奖还有投注人数以及中奖情况
    mapping (uint32 => LotteryTimeResult) public lotterytimeresultinfo;
 
    
    //返回创建期数结果
    event createLotteryResult(uint32 _lotteryDate);
    //返回保存期数结果
    event saveLotteryResult(uint32 _lotteryDate, uint256 _dowjones, uint256 _nasdaq); 
    //用户投注结果
    event userResult(uint32 _lotteryDate, uint32 _lotteryNum, uint256 _money);
    
    //创建期数（管理员才可以操作）
    /// @param _lotteryDate  投注期数
    function CreateLottery(uint32 _lotteryDate )  public checkCreateLottery(_lotteryDate,lastlotteryDate) onlyOwner{
        Lottery memory _Lottery = Lottery({
            lotteryDate : _lotteryDate
        });
        lotteryList.push(_Lottery) - 1;
        //增加投注期数的次数
        lotteryAllCount++;
        //修改上期投注期数
        lastlotteryDate = _lotteryDate;
        //首次创建
        lotterytimeresultinfo[_lotteryDate].open = 2;
        //日志
        emit createLotteryResult(_lotteryDate);
    }
    
    
    //保存开奖的信息（管理员才可以操作）
    /// @param _lotteryDate  投注期数     
    /// @param _dowjones 	 道琼指数
    /// @param _nasdaq 	     纳斯达克指数
    function saveLottery(uint32 _lotteryDate , uint256 _dowjones,uint256 _nasdaq)  public checkdowjones(_dowjones,_nasdaq)
    checkSaveLottery(_lotteryDate,lastlotteryDate,lotterytimeresultinfo[_lotteryDate].open) onlyOwner{
        //道琼指数+ 纳斯达克指数生成开奖结果
        uint32 _lotteryNum = _getLotteryNum( _dowjones, _nasdaq);
        //开奖（遍历用户中奖情况）
        _openPrize(_lotteryDate, _lotteryNum, _dowjones, _nasdaq);
        emit saveLotteryResult(_lotteryDate,_dowjones,_nasdaq);
    }
    
    //道琼指数+ 纳斯达克指数生成开奖结果
    //道琼指数 后3位 拼接 纳斯达克后4位
    function _getLotteryNum(uint256 _dowjones,uint256 _nasdaq) internal pure returns(uint32 lotteryNum){
        uint nowdowjones = _dowjones % 1000 ;
        uint nasdaq = _nasdaq % 10000 ;
        uint resultlotteryNum = nowdowjones * 10000 +  nasdaq;
        lotteryNum = uint32(resultlotteryNum);
        
    }
    
    //用户投注
    /// @param _lotteryDate  Winning number date     
    /// @param _lotteryNum 	Winning number
    function createUserLottery(uint32 _lotteryDate , uint32 _lotteryNum)  public payable
        checkLotteryNum(_lotteryNum)
        checkSaveLottery(_lotteryDate,lastlotteryDate,lotterytimeresultinfo[_lotteryDate].open) {
            address _userAddress = msg.sender;
            uint256 _money = msg.value;
            //地址要存在 and 金额至少0.01以太币
            require(_userAddress != address(0) && _money >= 10 finney);
            LotteryUserResult memory userlottery = LotteryUserResult({
                userAddress:_userAddress,    
                lotteryDate:_lotteryDate,
                userBettingTime: uint64(now),
                lotteryNum: _lotteryNum,
                result:0,
                money:_money,
                takemoney:0
            });
            //投注的钱增加
            lotteryAllMoney += _money;
            //本期投注数量
            lotterytimeresultinfo[_lotteryDate].allbettingtime++ ;
            //本期用户投注列表
            uint256 index = lotteryuserresultlist[_lotteryDate].push(userlottery) - 1;
            
            //用户投注数量+1
            userBettingCount[_userAddress] ++ ;
            //用户投注列表
            userLog memory userloges = userLog({
                lotteryDate:_lotteryDate,
                index:index
            });            
            userBettingList[_userAddress].push(userloges) - 1;
            
            emit userResult(_lotteryDate , _lotteryNum, _money);
   
    }

    //获取投注期数
    /// @param _id 投注期数数组ID
    function getLotteryInfo(uint256 _id) external view returns (uint32  lotteryDate, uint32  lotteryNum,uint8 open){
        Lottery storage lotteryes = lotteryList[_id];
        lotteryDate = uint32(lotteryes.lotteryDate);
        lotteryNum = lotterytimeresultinfo[lotteryDate].lotteryNum;//本期开奖号码
        open = lotterytimeresultinfo[lotteryDate].open;//本期是否开奖
    }
    
    //获取用户投注信息
    /// @param _userAddress  用户投注地址
    /// @param _id           用户投注数组ID
    function getUserBettingInfo(address _userAddress, uint256 _id) external view 
      returns 
      (uint32  lotteryDate,uint64 userBettingTime,uint32  lotteryNum,uint8  result,uint256 money,uint256 takemoney){
          
        uint32 date =   userBettingList[_userAddress][_id].lotteryDate;
        uint256 index =   userBettingList[_userAddress][_id].index;
          
        lotteryDate = lotteryuserresultlist[date][index].lotteryDate;
        userBettingTime = lotteryuserresultlist[date][index].userBettingTime;
        lotteryNum = lotteryuserresultlist[date][index].lotteryNum;
        result = lotteryuserresultlist[date][index].result;
        money = lotteryuserresultlist[date][index].money;
        takemoney = lotteryuserresultlist[date][index].takemoney;
    }    

    //开奖（遍历用户中奖情况）
    function _openPrize(uint32 _lotteryDate , uint32 _lotteryNum , uint256 _dowjones, uint256 _nasdaq) internal{
        //修改这一期的信息
        //修改开奖号码
        lotterytimeresultinfo[_lotteryDate].lotteryNum = _lotteryNum;
        //修改道琼指数
        lotterytimeresultinfo[_lotteryDate].dowjones = _dowjones;
        //修改纳斯达克指数
        lotterytimeresultinfo[_lotteryDate].nasdaq = _nasdaq;        
        //改成开奖状态
        lotterytimeresultinfo[_lotteryDate].open = 1;

        for (uint i = 0; i < lotterytimeresultinfo[_lotteryDate].allbettingtime; i++) {
            uint8 result = _checklottery(_lotteryNum , lotteryuserresultlist[_lotteryDate][i].lotteryNum);
            if(result == 66){
                //处理中特等奖
                //本期特等奖数量+1
                lotterytimeresultinfo[_lotteryDate].result66Num += lotteryuserresultlist[_lotteryDate][i].money;
                //修改用户中奖情况
                lotteryuserresultlist[_lotteryDate][i].result = 66 ;
            }else if(result == 1){
                lotterytimeresultinfo[_lotteryDate].result1Num += lotteryuserresultlist[_lotteryDate][i].money;
                lotteryuserresultlist[_lotteryDate][i].result = 1 ;                
            }else if(result == 2){
                lotterytimeresultinfo[_lotteryDate].result2Num += lotteryuserresultlist[_lotteryDate][i].money;
                lotteryuserresultlist[_lotteryDate][i].result = 2 ;                
            }else if(result == 3){
                lotterytimeresultinfo[_lotteryDate].result3Num += lotteryuserresultlist[_lotteryDate][i].money;
                lotteryuserresultlist[_lotteryDate][i].result = 3 ;                
            }else if(result == 4){
                lotterytimeresultinfo[_lotteryDate].result4Num += lotteryuserresultlist[_lotteryDate][i].money;
                lotteryuserresultlist[_lotteryDate][i].result = 4 ;                
            }else if(result == 5){
                lotterytimeresultinfo[_lotteryDate].result5Num += lotteryuserresultlist[_lotteryDate][i].money;
                lotteryuserresultlist[_lotteryDate][i].result = 5 ;                
            }else{
                lotterytimeresultinfo[_lotteryDate].result6Num += lotteryuserresultlist[_lotteryDate][i].money;
                lotteryuserresultlist[_lotteryDate][i].result = 6 ;                
            }
        }
        
        //奖金处理
        uint256 useLotteryMoney = 0 ;

        //处理5等奖
        if(lotterytimeresultinfo[_lotteryDate].result5Num > 0){
            useLotteryMoney +=  _eachPrize(_lotteryDate,lotterytimeresultinfo[_lotteryDate].result5Num , 5 , 2, 3);
        }        
        
        //处理4等奖
        if(lotterytimeresultinfo[_lotteryDate].result4Num > 0){
            useLotteryMoney +=  _eachPrize(_lotteryDate,lotterytimeresultinfo[_lotteryDate].result4Num , 4 , 50, 1);
        }
        
        //处理3等奖
        if(lotterytimeresultinfo[_lotteryDate].result3Num > 0){
            useLotteryMoney +=  _eachPrize(_lotteryDate,lotterytimeresultinfo[_lotteryDate].result3Num , 3 , 100, 1);
        }

        //处理2等奖
        if(lotterytimeresultinfo[_lotteryDate].result2Num > 0){
            useLotteryMoney +=  _eachPrize(_lotteryDate,lotterytimeresultinfo[_lotteryDate].result2Num , 2 , 1000, 1);
        }        
        //处理1等奖
        if(lotterytimeresultinfo[_lotteryDate].result1Num > 0){
            useLotteryMoney +=  _eachPrize(_lotteryDate,lotterytimeresultinfo[_lotteryDate].result1Num , 1 , 10000, 1);
        }
        //处理特等奖
        if(lotterytimeresultinfo[_lotteryDate].result66Num > 0){
            useLotteryMoney +=  _eachPrize(_lotteryDate,lotterytimeresultinfo[_lotteryDate].result66Num , 66 , 200000, 3);
        }
        //保存本期总的奖励金额
        lotterytimeresultinfo[_lotteryDate].resultprizeNum = useLotteryMoney ;
        assert(useLotteryMoney <= lotteryAllMoney);
        //总彩池金额减少
        lotteryAllMoney -= useLotteryMoney; 
    }

    //各个等级奖励情况
    /// @param _lotteryDate  投注期数   
    /// @param _resultNum 	 每期中奖金额    
    /// @param _prize 	     中奖等级
    /// @param _mul          投注奖励倍数     
    /// @param _ratio 	     中奖等级最多可分配比例   
    function _eachPrize(uint32 _lotteryDate , uint256 _resultNum,uint8 _prize , uint32 _mul, uint _ratio) internal returns(uint256){
        uint256 useLotteryMoney = 0 ;
        uint256 thismul = 0;

        //可分配奖励金额 (总奖金的中奖等级最多可分配比例,没有小数，先扩大倍数)
        uint256 thislottery = uint256(10000) * lotteryAllMoney * _ratio  / 10 ;
        //判断是否够中奖的人分配（中奖金额投注奖励倍数）
        if(thislottery >=  _resultNum * _mul * 10000){
            //如果够分，每人各自的倍数
            thismul = _mul * 10000;
        }else{
            //如果不够分，平均分配可分配金额
            thismul = thislottery / _resultNum ;
        }
        
        for (uint i = 0; i < lotterytimeresultinfo[_lotteryDate].allbettingtime; i++) {
            if(lotteryuserresultlist[_lotteryDate][i].result == _prize){
                //用户中奖金额(扩大的倍数返回)
                uint256 allprizemonty = uint256(thismul) * lotteryuserresultlist[_lotteryDate][i].money / 10000;
                //金额分配给用户90%
                uint256 userprizemonty = allprizemonty * 9 / 10 ;
                //抽10%给开发商，当做维护费
                uint256 developprizemonty = allprizemonty * 1 / 10 ;
                //保存用户中奖记录
                lotteryuserresultlist[_lotteryDate][i].takemoney = userprizemonty;
                //转账eth 给用户和开发商
                lotteryuserresultlist[_lotteryDate][i].userAddress.transfer(userprizemonty);
                owner.transfer(developprizemonty);

                useLotteryMoney += allprizemonty;
            }
        }
        
        return useLotteryMoney;
              
    }
    

    //开奖号码和用户号码对比，检查中奖情况
    /// @param _lotteryNum 	开奖号码
    /// @param _userBetNum  用户投注号码  
    function _checklottery(uint32 _lotteryNum , uint32 _userBetNum) internal pure  returns(uint8){
        if(_lotteryNum == _userBetNum){
            return 66; //特等价
        }else if(_lotteryNum % 1000000 == _userBetNum % 1000000 ){
            return 1 ;//1等奖
        }else if(_lotteryNum % 100000 == _userBetNum % 100000 ){
            return 2 ;//2等奖
        }else if(_lotteryNum % 10000 == _userBetNum % 10000 ){
            return 3 ;//3等奖
        }else if(_lotteryNum % 1000 == _userBetNum % 1000 ){
            return 4 ;//4等奖
        }else if(_lotteryNum % 10 == _userBetNum % 10 ){
            return 5 ;//5等奖
        }else{
            return 6 ;//没中奖
        }
    }
    //查看合约地址金额
    function getBalance() public view returns(uint) {
      address contractaddress = this;  
      return contractaddress.balance;
    } 
}