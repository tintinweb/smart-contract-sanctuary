/**
 *Submitted for verification at BscScan.com on 2021-09-05
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

   
       uint256 gepDecimal = 10**8;
       uint256 usdtDecimal = 10**18;
       address geoerc20; 
       address usdtContract;

       //收usdt地址
       address usdtPool; 
       //gep钱包池
       address gepPool;

       uint public startBlock;
       uint256 totalSaleToken = 350000000;
       //uint256 saleOne = 50000000;
       //uint256 saleTwo = 100000000;
       //uint256 saleThree = 200000000;
       
       //zhong c众筹众筹项目
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
       mapping (address => uint256)  releaseNumber;   //用户冻结数
       mapping (address => uint256) public cliamNumber; //地址释放数（可提取）

       uint8 priceone=1;
       uint8 pricetwo = 2;
       uint8 pricethree = 4;

       uint256 public totalSaledToken =0 ;
       
        
       uint8 releaseRate = 10;
        
       event GepChangeEvt(address indexed from, uint256 value,uint8 price);
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
        CrowdItem memory item=CrowdItem(0,50000000,1);
        Crowdmapp[1] = item;
        
        CrowdItem memory item2=CrowdItem(0,100000000,2);
        Crowdmapp[2] = item2;
        
        CrowdItem memory item3=CrowdItem(0,200000000,4);
        Crowdmapp[3] = item3;
    }
    
    function setGepPool(address _gepPool) public onlyOwner{
        gepPool = _gepPool;
    }
    
    function setUsdPool(address _usdtPool) public onlyOwner{
        usdtPool = _usdtPool;
    }
    
    function getTotalSwap() public view returns(uint256) {
        return totalSaledToken;
    }
    
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
          uint256 buynumber = _amount.mul(100).div(buyPrice);
          require(leftNumber>=buynumber,"Insufficient quantity");
          
        uint256 usdtNumbers = _amount.mul(usdtDecimal);
        bool b;
        b = transferUSD(usdtPool, usdtNumbers);
    
        //用户buy 待释放
        uint256 tokenNumber = buynumber.mul(gepDecimal);
        uint256 a = releaseNumber[msg.sender];
        releaseNumber[msg.sender] = a.add(tokenNumber); 
        
        //记录用户参加的轮次
        //uint8 status = AddressCrowd[msg.sender][crowdid];
        if(AddressCrowd[msg.sender][crowdid]==0){
            
            AddressCrowd[msg.sender][crowdid] = 1;
            
            CrowdAddress[crowdid].push(msg.sender);
        }
        //
        //waitReleaseNumber[msg.sender] = waitReleaseNumber[msg.sender].add(tokenNumber);
        
        //用户共买了多少
        totalSwap[msg.sender] = totalSwap[msg.sender].add(tokenNumber);
        
        //总销售了多少
        totalSaledToken = totalSaledToken.add(tokenNumber);
        
        //计算某个用户每轮参加的总数
        uint256 hisbuyAmount = AddressCrowdNumber[msg.sender][crowdid];
        AddressCrowdNumber[msg.sender][crowdid] = hisbuyAmount.add(buynumber);
        
        //计算每轮已经卖出去了多少
        uint256 totalSaledNumber = saledMapp[crowdid].add(buynumber);
        saledMapp[crowdid] = totalSaledNumber;
        
        emit GepChangeEvt(msg.sender,tokenNumber,buyPrice);
    }
    
    function queryBuyNumber(uint256 _amount) view public returns(uint256){
        
         uint8 crowdid;
         uint8 buyPrice;
         uint crowdstatus;
         (crowdid,buyPrice,crowdstatus) = querySellCrowd();
         require(crowdid>0 && crowdstatus==1 && buyPrice>0,"fail");
         
          CrowdItem memory item = Crowdmapp[crowdid];
          uint256 leftNumber = item.saleGEPnumber.sub(saledMapp[crowdid]);
           
          uint256 buynumber = _amount.mul(100).div(buyPrice);
          require(leftNumber>=buynumber,"Insufficient quantity");
          
          return buynumber;
    }
    
    function queryPrice(uint8 crowdid) view public returns(uint8){
        require(crowdid>0 && crowdid<=3,"fail"); 
        return Crowdmapp[crowdid].price;
    }
    
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
    
    function Swap_old(uint256 _value) public returns(bool){
      
       uint256 tokenNumber =0;
       uint8 realRateate =0;

       uint256 totalSale = totalSaledToken.add(_value);
       require(totalSale<totalSaleToken, "Transfer failed.");

      if(tokenNumber.add(_value)<=5000){
          
        realRateate = priceone;
        
      }else if ( tokenNumber.add(_value)>5000 &&  tokenNumber.add(_value)<=100000000 ) {
          realRateate = pricetwo;
        
      }else{
          realRateate = pricethree;
      }
        
        tokenNumber = _value.mul(gepDecimal).mul(100).div(realRateate);
        
      uint256 usdtNumbers = _value.mul(usdtDecimal);
        bool b;
        b = transferUSD(usdtPool, usdtNumbers);
        /*if(b){
          b=transferToken(msg.sender,tokenNumber);
          if(b){
              emit GepChangeEvt(msg.sender,tokenNumber);
          }
        } */
        uint256 totalbuy = totalSwap[msg.sender];
        totalSwap[msg.sender] = totalbuy.add(tokenNumber);
        if(totalbuy==0){
            swapAddrs.push(msg.sender);
        }
        
        uint256 a = releaseNumber[msg.sender];
        releaseNumber[msg.sender] = a.add(tokenNumber); 
        
         
        emit GepChangeEvt(msg.sender,tokenNumber,realRateate);
        return b;
    }
    
    function releaseToken() onlyOwner public{
         uint len2 = swapAddrs.length;
         uint256 totalToken2 =0;
         uint256 feezoneBalance2 = 0;
         uint256 release = 0;
         uint256 thisend =0;
         for(uint m=0;m<len2; m ++ ){
             address addr2 = swapAddrs[m];
             totalToken2 = totalSwap[addr2];
             feezoneBalance2 = releaseNumber[addr2];
             thisend = 0;
             if(feezoneBalance2>0){
                 release = totalToken2.mul(100).div(uint256(releaseRate));
                 if(feezoneBalance2>=release){
                     thisend = release;
                     releaseNumber[addr2] = feezoneBalance2.sub(release);
                 }else{
                     thisend = feezoneBalance2;
                     releaseNumber[addr2] = 0;
                 }
                  uint256 cliamtoken = cliamNumber[addr2];
                  cliamNumber[addr2] = cliamtoken.add(thisend);
             }
         }
         emit mglog(101);
    }
    
    function userClaim() public {
        uint256 releaseBalance = cliamNumber[msg.sender];
        require(releaseBalance>0,"cliam fail balance isn't enough");
        cliamNumber[msg.sender] = 0;
        transferToken(msg.sender,releaseBalance);
        emit mglog(102);
    }
    
    function managerClaim(address _addr) onlyOwner public {
        uint256 releaseBalance = cliamNumber[_addr];
        require(releaseBalance>0,"cliam fail balance isn't enough");
         cliamNumber[_addr] = 0;
        transferToken(_addr,releaseBalance);
        emit mglog(103);
    }
    
    
    function releaseSendToken() onlyOwner public{
         uint len = swapAddrs.length;
         uint256 totalToken =0;
         uint256 feezoneBalance = 0;
         for(uint i=0;i<len; i ++ ){
             address addr = swapAddrs[i];
             totalToken = totalSwap[addr];
             feezoneBalance = releaseNumber[addr];
             if(feezoneBalance>0){
                 uint256 a = totalToken.mul(100).div(releaseRate);
                 uint256 thisend =0;
                 if(feezoneBalance>=a){
                     thisend = a;
                     releaseNumber[addr] = feezoneBalance.sub(a);
                 }else{
                     thisend = feezoneBalance;
                     releaseNumber[addr] = 0;
                 }
                 transferToken(addr,thisend);
             }
         }
         emit mglog(100);
    }

    function transferUSD(address _to,uint256 _amount) public returns(bool){
        bytes32 a =  keccak256("transferFrom(address,address,uint256)");
        bytes4 methodId = bytes4(a);
        bytes memory b =  abi.encodeWithSelector(methodId,msg.sender,_to,_amount);
        (bool result,) = usdtContract.call(b);
        return result;
    }

    function transferToken(address _to,uint256 _amount) public returns(bool){
        bytes32 a =  keccak256("transferFrom(address,address,uint256)");
        bytes4 methodId = bytes4(a);
        bytes memory b =  abi.encodeWithSelector(methodId,gepPool,_to,_amount);
        (bool result,) = geoerc20.call(b);
        return result;
    }

}