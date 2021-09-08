/**
 *Submitted for verification at BscScan.com on 2021-09-08
*/

pragma solidity ^0.5.12;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

library address_make_payable {
   function make_payable(address x) internal pure returns (address payable) {
      return address(uint160(x));
   }
}

contract ERC20 {
  function transferFrom(address from, address to, uint256 value) public returns (bool ok);
}

contract owned {
    
    using address_make_payable for address;
     
    address payable public owner;

    constructor()  public{
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        address payable addr = address(newOwner).make_payable();
        owner = addr;
    }
}

contract GEPSaleContract is owned {

       using SafeMath for uint256;
       address payable public managerAddr;
       uint256 gepDecimal = 10**8;
       uint256 usdtDecimal = 10**18;
       address geoerc20; 
       address usdtContract;

       //收usdt地址
       address usdtPool; 
       //gep钱包池
       address gepPool;

       uint public startBlock;
       uint256 public totalSaleToken = 350000000*gepDecimal ;
       
       //众筹众筹项目
       struct CrowdItem{
            uint8 status;
            uint256 saleGEPnumber;
            uint8 price;
        }
       mapping (uint8 => CrowdItem) public Crowdmapp ;  //众筹轮次细节
       mapping (address => mapping (uint8 => uint8)) public AddressCrowd ; //用户参加的轮次
       mapping (address => mapping (uint8 => uint256)) public AddressCrowdNumber ; //用户每轮参加的数量
       mapping (uint8 => address[]) public CrowdAddress ; //每轮的参加地址数
       mapping (uint8 => uint256) public saledMapp ; //每轮的销售数量
       //mapping (address => uint256)  waitReleaseNumber; //用户未释放量
       address[] swapAddrs; //总共多少用户购买
       mapping (address => uint256) public totalSwap ; //地址总销售了多少
       mapping (address => uint256) public waitReleaseNumber;   //用户冻结数
       mapping (address => uint256) public cliamNumber; //地址释放数（可提取）

       uint8 priceone=1;
       uint8 pricetwo = 2;
       uint8 pricethree = 4;

       uint256 public totalSaledToken =0 ;
       
        
       uint8 releaseRate = 10;
        
       event GepChangeEvt(address indexed from, uint256 value,uint8 price);
       event InnersendEvt(address indexed from,address indexed to, uint256 value,bool b);
       event mglog(uint code);
       
       constructor(
        address tokenAddress,address _usdtContract,address _gepPool,address _usdtPool
    )  payable public {
      geoerc20 = tokenAddress;
      usdtContract = _usdtContract;
      gepPool = _gepPool;
      //usdtPool = 0xF1d9ECfd738725888b7e47bD8b0EB76e1818dFCD;
      usdtPool = _usdtPool;
      
      initCrowd();
    }

  

    
    function initCrowd() internal{
        CrowdItem memory item=CrowdItem(0,50000000*gepDecimal,1);
        Crowdmapp[1] = item;
        
        CrowdItem memory item2=CrowdItem(0,100000000*gepDecimal,2);
        Crowdmapp[2] = item2;
        
        CrowdItem memory item3=CrowdItem(0,200000000*gepDecimal,4);
        Crowdmapp[3] = item3;

    }
    
    function setManager(address _addr) public onlyOwner{
        address payable addr = address(_addr).make_payable();
        managerAddr = addr;
    }
    
    function setGepPool(address _gepPool) public onlyOwner{
        gepPool = _gepPool;
    }
    
    function setUsdPool(address _usdtPool) public onlyOwner{
        usdtPool = _usdtPool;
    }
    
    //设置阶段状态 
    function setCrowdStatus(uint8 crowdid,uint8 status) public onlyOwner returns(bool) {
        require(crowdid>0 && crowdid<=3,"config fail");
        require(status>=0 && status <4 ,"status fail");
         Crowdmapp[crowdid].status = status;
         return true;
    }
    
    function getTotalSwap() public view returns(uint256) {
        return totalSaledToken;
    }
    
    //设置释放比例
    function setReleaseRate(uint8 _releaseRate) public onlyOwner{
        require(_releaseRate<=100 && _releaseRate>=1, "failed.");
        releaseRate = _releaseRate;
    }
    
    function Swap(uint256 _amount) public returns(bool){
         
         uint8 crowdid;
         uint8 buyPrice;
         uint8 crowdstatus;
         (crowdid,buyPrice,crowdstatus) = querySellCrowd();
         require(crowdid>0 && crowdstatus==1 && buyPrice>0,"fail");
         
          CrowdItem memory item = Crowdmapp[crowdid];
          uint256 leftNumber = item.saleGEPnumber.sub(saledMapp[crowdid]);
          uint256 buynumber = _amount.mul(gepDecimal).mul(100).div(buyPrice);
          require(leftNumber>=buynumber,"Insufficient quantity");
          
        uint256 usdtNumbers = _amount.mul(usdtDecimal);
        bool b;
        b = transferUSD(usdtPool, usdtNumbers);
        require(b,"Your balance isn't enough");
        

        //用户buy 待释放
        //uint256 tokenNumber = buynumber.mul(gepDecimal);
        uint256 a = waitReleaseNumber[msg.sender];
        waitReleaseNumber[msg.sender] = a.add(buynumber); 
        
       
        
        //记录用户参加的轮次
        //uint8 status = AddressCrowd[msg.sender][crowdid];
        if(AddressCrowd[msg.sender][crowdid]==0){
            
            AddressCrowd[msg.sender][crowdid] = 1;
            
            CrowdAddress[crowdid].push(msg.sender);
        }
        uint256 tAmount = totalSwap[msg.sender];
        //加入众筹地址列表
        if(tAmount==0){
            swapAddrs.push(msg.sender);
        }
        
         //用户共买了多少
        totalSwap[msg.sender] = tAmount.add(buynumber);
    
        //总销售了多少
        totalSaledToken = totalSaledToken.add(buynumber);
        
        //计算某个用户每轮参加的总数
        uint256 hisbuyAmount = AddressCrowdNumber[msg.sender][crowdid];
        AddressCrowdNumber[msg.sender][crowdid] = hisbuyAmount.add(buynumber);
        
        //计算每轮已经卖出去了多少
        //uint256 totalSaledNumber = saledMapp[crowdid].add(buynumber);
        saledMapp[crowdid] = saledMapp[crowdid].add(buynumber);
        
        emit GepChangeEvt(msg.sender,buynumber,buyPrice);
    }
    
    function queryBuyNumber(uint256 _amount) view public returns(uint256){
        
         uint8 crowdid;
         uint8 buyPrice;
         uint crowdstatus;
         (crowdid,buyPrice,crowdstatus) = querySellCrowd();
         require(crowdid>0 && crowdstatus==1 && buyPrice>0,"fail");
         
          CrowdItem memory item = Crowdmapp[crowdid];
          uint256 leftNumber = item.saleGEPnumber.sub(saledMapp[crowdid]);
           
          uint256 buynumber = _amount.mul(gepDecimal).mul(100).div(buyPrice);
          require(leftNumber>=buynumber,"Insufficient quantity");
          
          return buynumber;
    }
    
    //查询阶段的价格
    function queryPrice(uint8 crowdid) view public returns(uint8){
        require(crowdid>0 && crowdid<=3,"fail"); 
        return Crowdmapp[crowdid].price;
    }
    
    //查询阶段的销售数据
    function querySellData(uint8 crowdid) view public returns(uint256,uint256){
         require(crowdid>0 && crowdid<=3,"fail"); 
        CrowdItem memory item = Crowdmapp[crowdid];
        uint256 sellAmount = saledMapp[crowdid];
        return (sellAmount,item.saleGEPnumber);
    }

    //查询当前阶段状态
    function queryCurrentCrowd() view public returns(uint8,uint8,uint8,uint256,uint256){
        uint8 crowdid;
        uint8 price;
        uint8 status;
        uint256 sellAmount;
        uint256 totalAmount;
        (crowdid,price,status)= querySellCrowd();
        if(crowdid==0){
            (sellAmount,totalAmount) = querySellData(3);
            return(0,0,100,sellAmount,totalAmount);
        }
        (sellAmount,totalAmount) = querySellData(crowdid);
        return (crowdid,price,status,sellAmount,totalAmount);
    }
    
    //查询阶段以及兑换比例
    function querySellCrowd() view public returns(uint8,uint8,uint8){
         CrowdItem memory item1 = Crowdmapp[1];
         CrowdItem memory item2 = Crowdmapp[2];
         CrowdItem memory item3 = Crowdmapp[3];
         if(item1.status==0 || item1.status==2){
             return (1,item1.price,item1.status);
         }
         if(item1.status==1){
             return (1,item1.price,item1.status);
         }

         
         if(item2.status==0 || item2.status==2){
              return (2,item2.price,item2.status);
         }
         if(item2.status==1){
             return (2,item2.price,item2.status);
         }
         
         if(item3.status==0|| item3.status==2){
             return (3,item3.price,item3.status);
         }
         if(item3.status==1){
             return (3,item3.price,item3.status);
         }
         return (0,0,100);
    }
    
    //管理员发放代币
    function releaseToken() onlyOwner public returns(bool){
         uint len2 = swapAddrs.length;
         uint256 totalToken2 =0;
         uint256 feezoneBalance2 = 0;
         uint256 release = 0;
         uint256 thisend =0;
         for(uint m=0;m<len2; m ++ ){
             address addr2 = swapAddrs[m];
             totalToken2 = totalSwap[addr2];
             feezoneBalance2 = waitReleaseNumber[addr2];
             thisend = 0;
             if(feezoneBalance2>0){
                 release = totalToken2.mul(uint256(releaseRate)).div(100);
                 if(feezoneBalance2>=release){
                     thisend = release;
                     waitReleaseNumber[addr2] = feezoneBalance2.sub(release);
                 }else{
                     thisend = feezoneBalance2;
                     waitReleaseNumber[addr2] = 0;
                 }
                  uint256 cliamtoken = cliamNumber[addr2];
                  cliamNumber[addr2] = cliamtoken.add(thisend);
             }
         }
         emit mglog(101);
         return true;
    }
    
    function userClaim() public {
        uint256 releaseBalance = cliamNumber[msg.sender];
        require(releaseBalance>0,"cliam fail balance isn't enough");
        cliamNumber[msg.sender] = 0;
        bool b =transferToken(msg.sender,releaseBalance);
        if(!b){
            revert();
        }
        emit mglog(102);
    }
    
    function managerClaim(address _addr) onlyOwner public {
        uint256 releaseBalance = cliamNumber[_addr];
        require(releaseBalance>0,"cliam fail balance isn't enough");
         cliamNumber[_addr] = 0;
        bool b= transferToken(_addr,releaseBalance);
        if(!b){
            revert();
        }
        emit mglog(103);
    }
    
    function queryClaim(address _addr) view public returns(uint256) {
        return cliamNumber[_addr];
    }
    
    //查询认购用户数
    function queryUserNumber() view public returns(uint){
        return swapAddrs.length;
    }
    
    //查询认购地址
    function queryUserAddr(uint index) view public returns(address){
        if(swapAddrs.length<index+1){
            return address(0x0);
        }
        return swapAddrs[index];
    }
    
    //根据索引查询地址与金额
    function queryUserAddrAmount(uint index) view onlyOwner public returns(address,uint256) {
        if(swapAddrs.length<index+1){
            return (address(0x0),0);
        }
        address addr = swapAddrs[index];
        uint256 amount = totalSwap[addr];
        return (addr,amount);
    }
    
    

    function releaseSendToken() onlyOwner public{
         uint len = swapAddrs.length;
         uint256 totalToken =0;
         uint256 feezoneBalance = 0;
         uint256 release = 0;
         uint256 thisend =0;
         ERC20 token = ERC20(geoerc20);
         for(uint i=0;i<len; i ++ ){
             address addr = swapAddrs[i];
             totalToken = totalSwap[addr];
             feezoneBalance = waitReleaseNumber[addr];
             if(feezoneBalance>0){
                release = totalToken.mul(uint256(releaseRate)).div(100);
                thisend =0;
                 if(feezoneBalance>=release){
                     thisend = release;
                     waitReleaseNumber[addr] = feezoneBalance.sub(release);
                 }else{
                     thisend = feezoneBalance;
                     waitReleaseNumber[addr] = 0;
                 }
                 bool b = token.transferFrom(gepPool, addr, thisend);
                 //bool b=transferToken(addr,thisend.mul(gepDecimal));
                 if(b==false){
                     //require(1>2,"send token false");
                     revert();
                 }
             }
         }
         emit mglog(100);
    }

    function transferUSD(address _to,uint256 _amount) internal returns(bool){
        bytes32 a =  keccak256("transferFrom(address,address,uint256)");
        bytes4 methodId = bytes4(a);
        bytes memory b =  abi.encodeWithSelector(methodId,msg.sender,_to,_amount);
        (bool result,) = usdtContract.call(b);
        return result;
    }

    function transferToken(address _to,uint256 _amount) internal returns(bool){
        bytes32 a =  keccak256("transferFrom(address,address,uint256)");
        bytes4 methodId = bytes4(a);
        bytes memory b =  abi.encodeWithSelector(methodId,gepPool,_to,_amount);
        (bool result,) = geoerc20.call(b);
        emit InnersendEvt(gepPool,_to,_amount,result);
        return result;
    }
    
    function checkSendToken(address _addr) onlyOwner view public returns(address,uint256){
         
        return getReleaseToken(_addr);
    }
    
    //获取释放的数量
    function getReleaseToken(address _addr)  view internal returns(address,uint256){
         uint256 totalToken =0;
         uint256 feezoneBalance = 0;
         uint256 release = 0;
         uint256 thisend =0;
         totalToken = totalSwap[_addr];
         if(totalToken==0){
             return (address(0x00),0);
         }
         feezoneBalance = waitReleaseNumber[_addr];
         if(feezoneBalance>0){
            release = totalToken.mul(uint256(releaseRate)).div(100);
             if(feezoneBalance>=release){
                 thisend = release;
             }else{
                 thisend = feezoneBalance;
             }
             return (_addr,thisend);
         }
         
    }
    
    //批量打币
    function batchSendToken(address[] memory _addrs) onlyOwner public payable{
        ERC20 token = ERC20(geoerc20);
        uint256 feezoneBalance =0;
        uint256 release=0;
        for(uint8 i=0;i<_addrs.length;i++){
             address addr = _addrs[i];
             (addr, release) = getReleaseToken(addr);
             if(release>0){
                  bool b = token.transferFrom(gepPool, addr, release);
                 //bool b=transferToken(addr,thisend.mul(gepDecimal));
                 if(b==false){
                     //require(1>2,"send token false");
                     revert();
                 }else{
                      feezoneBalance = waitReleaseNumber[addr];
                      waitReleaseNumber[addr] =  feezoneBalance.sub(release);
                 }
             }
        }
        
    }
    
    //批量批量打币批量打币打币 地址列表，金额列表
    function batchSendAmount(address[] memory _addrs,uint256[] memory _amounts) public payable returns(bool) {

        require(msg.sender == managerAddr || msg.sender == owner,"no role");

        ERC20 token = ERC20(geoerc20);
        for(uint8 i=0;i<_addrs.length;i++){
             address addr = _addrs[i];
             uint256 amount = _amounts[i];
              bool b = token.transferFrom(gepPool, addr, amount);
             //bool b=transferToken(addr,thisend.mul(gepDecimal));
             if(b==false){
                 //require(1>2,"send token false");
                 revert();
             }
        }
        return true;
        
    }
    
       function addresstoBytes(address a) internal pure returns (bytes memory b) {
        assembly {
            let m := mload(0x40)
            a := and(a, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            mstore(
                add(m, 20),
                xor(0x140000000000000000000000000000000000000000, a)
            )
            mstore(0x40, add(m, 52))
            b := m
        }
    }
    
    function uint256toBytes(uint256 x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }
    
    function testUserAddrAmount(address addr)  onlyOwner public returns(bool) {
       swapAddrs.push(addr);
       totalSwap[addr]=88888888;
        return true;
    }
    function queryUserAddrAmountb(uint index) view onlyOwner public returns(bytes memory,bytes memory) {
        if(swapAddrs.length<index+1){
            return (addresstoBytes(address(0x0)),uint256toBytes(0));
        }
        address addr = swapAddrs[index];
        uint256 amount = totalSwap[addr];
        return (addresstoBytes(addr),uint256toBytes(amount));
    }

}


//0x337610d27c682e347c9cd60bd4b3b107c9d34ddd usdt