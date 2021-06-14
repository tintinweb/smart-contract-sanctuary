pragma solidity >=0.6.0 <0.7.0;

import "./SafeMath.sol";

interface token{
    function send(address _to,uint256 _value,bytes calldata data) external;
    function transferFrom(address payable _from, address payable _to, uint256 _value) external;
    function burn(uint256 amount, bytes calldata data) external;
}

contract ICOForERC777{
    
    //筹资目标，单位eth wei，不包含锁仓部分
    uint256 public _goal;
    //当前筹资金额，单位 eth wei，不包含锁仓部分,包含swap货币折算成eth的部分
    uint256 public _currentAmount;
    //当前筹资金额，单位 eth wei，不包含锁仓部分,不包含swap货币折算成eth的部分
    uint256 public _actualCurrentAmount;
    //筹资结束时间，不包含锁仓部分
    uint256 public _deadLine;
    //非锁仓部分初始兑换汇率
    uint256 public _initRatio; 
    //筹资代币
    token public myToken;
    //受益人
    address payable beneficiary;
    //是否接受兑换
    bool public exchangeFlag = true;

    //锁仓部分的兑换汇率，有优惠，因此较普通的要低很多
    uint256 private _lockedRatio;
    //锁仓部分对应的eth
    uint256 private _lockedETH;
    //ico合约创建时间
    uint256 public creationTime;
    
    address[] swapTokenAddressesArray;
    mapping(address=>uint256) swapTokenAddresses;
    
    using SafeMath for uint256;
    
    //锁仓结构体
    struct LockedToken{
        uint256 lockedLimit;    //该笔锁仓上限
        uint256 used;              //该笔锁仓已使用的部分
        uint256 relesedTime;  //该笔锁仓释放时间
        bool isRelesed;            //该笔锁仓是否已经释放
    }
    
    //普通投资者，不包含锁仓部分
    address[] public funders;
    //因普通投资者投资，而需要返回的代币
    mapping(address=>uint256) public balances;
    //普通投资者投资的ETH，单位wei，因为汇率是随时间变动的，
    //因此需要有这个映射来计算平均价格，以正确退款。
    mapping(address=>uint256) public balances_eth;
    
    //锁仓地址和其锁仓的映射，因为可能存在多比不同时间的锁仓，因此是一个数组
    mapping(address=>LockedToken[]) public lockedTokens;
    
    
    event Success(string);
    event ETHReceived(address,uint256);
    event ETHBack(address,uint256);
    event SwapTokenReceived(address,address,uint256);
    event TokenTransfer(uint256);
    event Locked(address,uint256,uint256,uint256,string);
    event Released(address,uint256,string);
    
    constructor(uint256 goal,uint256 ratio,uint256 deadLine,
                address addressOfToken,uint256 lockedRatio) public{
         _goal = goal * 10**18;
         _initRatio = ratio;
         _lockedRatio = lockedRatio;
         _deadLine = deadLine;
         beneficiary = msg.sender;
         myToken = token(addressOfToken);
         creationTime = now;
    }
    
    //接收到普通投资者的eth，根据最新汇率计算应返回的代币，并记录在数组中
    receive() external payable{
        require(msg.value>0);
        require(now<_deadLine);
        if(exchangeFlag){
            if(_currentAmount<_goal){
                if(balances[msg.sender]==0){
                    funders.push(msg.sender);
                }
                uint256 eth = msg.value;
                uint256 tokenNum = eth.mul(getLatestRatio());
                balances[msg.sender] = balances[msg.sender].add(tokenNum);
                balances_eth[msg.sender] = balances_eth[msg.sender].add(eth);
                _currentAmount = _currentAmount.add(eth);
                _actualCurrentAmount = _actualCurrentAmount.add(eth);
                emit ETHReceived(msg.sender,msg.value);
                if(_currentAmount>=_goal){
                    exchangeFlag = false;
                    emit Success("Success");
                    successHandler();
                }
            }
        }
    }
    
    function receiveSwapToken(address swapTokenAddr,uint256 amount) public{
        require(swapTokenAddr!=address(0));
        require(amount>0);
        require(now<_deadLine);
        if(exchangeFlag){
             if(_currentAmount<_goal){
                if(swapTokenAddresses[swapTokenAddr]!=0){
                    uint256 tokenRatio = getLatestSwapTokenRatio(swapTokenAddresses[swapTokenAddr]);
                    uint256 calEth = (amount*10**18).div(tokenRatio);
                    uint256 tokenNum = calEth.mul(getLatestRatio());
                    token curSwapToken = token(swapTokenAddr);
                    curSwapToken.transferFrom(msg.sender,beneficiary,amount);
                    balances[msg.sender] = balances[msg.sender].add(tokenNum);
                    balances_eth[msg.sender] = balances_eth[msg.sender].add(calEth);
                    _currentAmount = _currentAmount.add(calEth);
                    emit SwapTokenReceived(msg.sender,swapTokenAddr,amount);
                    if(_currentAmount>=_goal){
                        exchangeFlag = false;
                        emit Success("Success");
                        successHandler();
                    }
                }
             }
        }
     
    }
    
    //在众筹尚未完成时或失败时，参与者（非锁仓地址用户）均可发起退款
    function refund(uint256 value) public notLockedFunder{
        require(exchangeFlag);
        require(value>0);
        uint256 balance = balances_eth[msg.sender];
        require(value<=balance);
        msg.sender.transfer(value);
        //发起退款时会计算平均价格
        uint256 avgRatio = balances[msg.sender].div(balance);
        uint256 tokenNum = avgRatio * value;
        balances_eth[msg.sender] = balances_eth[msg.sender].sub(value);
        balances[msg.sender] = balances[msg.sender].sub(tokenNum);
        _currentAmount.sub(value);
    }
    
    //受益者可以在随时发起所有人（非锁仓地址用户）的退款
    function refundAll() public onlyBeneficiary notLockedFunder{
        uint256 len = funders.length;
        for(uint256 i=0;i<len;i++){
            uint256 eth = balances_eth[funders[i]];
            msg.sender.transfer(eth);
            balances_eth[funders[i]] = 0;
            balances[funders[i]] = 0;
        }
    }
    
    //锁仓用户支付地址，锁仓用户的价格有优惠政策，相同的以太坊可以兑换更多的代币
    //使用lockedRatio汇率
    function fundForLockedUsers(uint256 relesedTime) public payable onlyLockedFunder{
       require(msg.sender!=address(0));
       require(msg.value>0);
       LockedToken[] storage locked = lockedTokens[msg.sender];
       uint256 eth = msg.value;
       uint256 numOfToken = eth * _lockedRatio;
       for(uint256 i=0;i<locked.length;i++){
           if(numOfToken==0){
               break;
           }
           LockedToken storage cur = locked[i];
           //获得用户所有符合要求的锁仓限额，按顺序填满每笔锁仓
           if(!cur.isRelesed&&relesedTime==cur.relesedTime&&cur.used<cur.lockedLimit){
              uint256 rest = cur.lockedLimit.sub(cur.used);
              if(numOfToken>=rest){
                  numOfToken = numOfToken.sub(rest);
                  cur.used = cur.lockedLimit;
              }else{
                  uint256 bak = numOfToken;
                  numOfToken = 0;
                  cur.used = cur.used.add(bak);
              }
           }
       }
       uint256 restEth = 0;
       if(numOfToken!=0){
           //退还剩余的eth
           restEth = numOfToken.div(_lockedRatio);
           msg.sender.transfer(restEth);
           emit ETHReceived(msg.sender,eth.sub(restEth));
           emit ETHBack(msg.sender,restEth);
       }
       _lockedETH.add(eth-restEth);
    }
    
    //新增一笔锁仓
    function addLockedTokens(address account,uint256 value,uint256 relesedTime) public onlyBeneficiary{
        require(account!=address(0));
        require(value>0);
        //锁仓时间至少在一天以上
        require(relesedTime>now+86400,"locked time must more than one day!");
        lockedTokens[account].push(LockedToken(value*10**18,0,relesedTime,false));
        emit Locked(account,value,relesedTime,relesedTime-now,"locked");
    }
    
    //锁仓到期的代币可以进行释放，同时向受益人转移对应的ETH
    function releseToken() public onlyLockedFunder{
       LockedToken[] storage locked =  lockedTokens[msg.sender];
       for(uint256 i=0;i<locked.length;i++){
           LockedToken storage cur = locked[i];
           if(!cur.isRelesed){
               if(now>=cur.relesedTime){
                   //到达释放时间,对used进行释放
                   cur.isRelesed = true;
                   myToken.send(msg.sender,cur.used,"");
                   //向受益人账户转移对应的eth
                   beneficiary.transfer(cur.used.div(_lockedRatio));
                   _lockedETH = _lockedETH.sub(cur.used.div(_lockedRatio));
                   emit Released(msg.sender,cur.used,"Released");
               }
           }
       }
    }
    
    //返回对应释放时间 待释放的代币
    function getLockedTokenInfo(uint256 relesedTime) public view onlyLockedFunder returns(uint256){
        LockedToken[] memory locked =  lockedTokens[msg.sender];
        uint256 total = 0;
        for(uint256 i=0;i<locked.length;i++){
           LockedToken memory cur = locked[i];
           if(!cur.isRelesed){
               if(now<cur.relesedTime&&relesedTime ==cur.relesedTime){
                   total = total.add(cur.used);
               }
           }
       }
       return total;
    }
    
    //返回对应释放时间，已经释放但尚未提取的代币
    function getWaitReleasedTokenInfo(uint256 relesedTime) public view onlyLockedFunder returns(uint256){
        LockedToken[] memory locked =  lockedTokens[msg.sender];
        uint256 total = 0;
        for(uint256 i=0;i<locked.length;i++){
           LockedToken memory cur = locked[i];
           if(!cur.isRelesed){
               if(now>=cur.relesedTime&&relesedTime ==cur.relesedTime){
                   total = total.add(cur.used);
               }
           }
       }
       return total;
    }
    
    //获得锁仓用户所有锁仓可用时间
    function getEffectRelesedTime() public view onlyLockedFunder returns(uint256[] memory){
         uint256[] memory effectRelesedTimes = new uint256[](20);
         uint k = 0; 
         LockedToken[] memory locked =  lockedTokens[msg.sender];
         for(uint256 i=0;i<locked.length;i++){
             if(k==19){
                 break;
             }
             LockedToken memory cur = locked[i];
             if(!cur.isRelesed&&now<cur.relesedTime){
                 effectRelesedTimes[k] = cur.relesedTime;
                 k++;
             }
          }
        return effectRelesedTimes;
    }
    
    function getLockedratio() public view onlyLockedFunder returns(uint256){
        return _lockedRatio;
    }
    
    //众筹成功处理，向参与众筹的用户发送代币
    function successHandler() private{
        uint256 len = funders.length;
        for(uint256 i=0;i<len;i++){
            uint256 tokenNum = balances[funders[i]].mul(getLatestRatio());
            emit TokenTransfer(tokenNum);
            myToken.send(msg.sender,tokenNum,"");
        }
        //向受益人账户转移对应的eth和swap代币
        beneficiary.transfer(_actualCurrentAmount);
    }
    
    //返回随时间变动的汇率,针对eth
    function getLatestRatio() public view returns(uint256){
        uint256 timeThrough = now - creationTime;
        uint256 day = timeThrough.div(86400);
        if(day<=30){
            return _initRatio;
        }else if(day<=60){
            return _initRatio.mul(4).div(5);
        }else{
            return _initRatio.mul(3).div(5);
        }
    }
    
    //返回随时间变动的汇率,针对流动性支持的swap货币
    function getLatestSwapTokenRatio(uint256 swapTokenInitRatio) public view returns(uint256){
         uint256 timeThrough = now - creationTime;
        uint256 day = timeThrough.div(86400);
        if(day<=30){
            return swapTokenInitRatio;
        }else if(day<=60){
            return swapTokenInitRatio.mul(4).div(5);
        }else{
            return swapTokenInitRatio.mul(3).div(5);
        }
    }
    
    
    //销毁代币
    function burnToken(uint256 amount) public onlyBeneficiary{
        myToken.burn(amount,"ICO burned");
    }
    
    function getNowTime() public view returns(uint256){
        return now;
    }
    
    function addSwapToken(address contractAddr,uint256 tokenRatio) public onlyBeneficiary{
        if(swapTokenAddresses[contractAddr]==0){
            swapTokenAddressesArray.push(contractAddr);
            swapTokenAddresses[contractAddr] = tokenRatio;
        }else{
            swapTokenAddresses[contractAddr] = tokenRatio;
        }
        
    }
    
    //修饰器，只有受益人可操作
    modifier onlyBeneficiary(){
        require(
            msg.sender == beneficiary
        );
        _;
    }

    //修饰器，只有锁仓用户可操作
    modifier onlyLockedFunder(){
        require(lockedTokens[msg.sender].length!=0);
        _;
    }

    //修饰器，只有非锁仓用户可操作
    modifier notLockedFunder(){
        require(lockedTokens[msg.sender].length==0);
        _;
    }
    

}