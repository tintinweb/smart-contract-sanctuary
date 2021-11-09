//SourceUnit: KYCToken.sol

pragma solidity ^0.4.18;


// ---------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// SafeMath安全库
// ----------------------------------------------------------------------------
contract SafeMath {
   function safeAdd(uint a, uint b) public pure returns (uint c) {
       c = a + b;
       require(c >= a);
   }
   function safeSub(uint a, uint b) public pure returns (uint c) {
       require(b <= a);
       c = a - b;
   }
   function safeMul(uint a, uint b) public pure returns (uint c) {
       c = a * b;
       require(a == 0 || c / a == b);
   }
   function safeDiv(uint a, uint b) public pure returns (uint c) {
       require(b > 0);
       c = a / b;
   }
}


// ----------------------------------------------------------------------------
// ERC20 代币标准
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
   //总发行数量
   function totalSupply() public constant returns (uint);
   //查询数量
   function balanceOf(address tokenOwner) public constant returns (uint balance);
   //查询授权数量
   function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    //转账
   function transfer(address to, uint tokens) public returns (bool success);
   //授权
   function approve(address spender, uint tokens) public returns (bool success);
   //授权转账
   function transferFrom(address from, address to, uint tokens) public returns (bool success);

   event Transfer(address indexed from, address indexed to, uint tokens);
   event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// 所有者合约
// ----------------------------------------------------------------------------
contract Owned {
   address public owner;
   address public newOwner;

   event OwnershipTransferred(address indexed _from, address indexed _to);
   

   function Owned() public {
       owner = msg.sender;
   }

   modifier onlyOwner {
       require(msg.sender == owner);
       _;
   }

   function transferOwnership(address _newOwner) public onlyOwner {
       newOwner = _newOwner;
   }
   function acceptOwnership() public {
       require(msg.sender == newOwner);
       OwnershipTransferred(owner, newOwner);
       owner = newOwner;
       newOwner = address(0);
   }
}


// ----------------------------------------------------------------------------
// ERC20代币，增加标志、名字、精度
// 代币转移
// ----------------------------------------------------------------------------
contract KYCToken is ERC20Interface, Owned, SafeMath {
   string public symbol;
   string public  name;
   uint8 public decimals;
   uint public _totalSupply;

   mapping(address => uint) balances;
   mapping(address => mapping(address => uint)) allowed;
   
  
   
   struct Lockinfo
      {
        uint lock_token;  //剩余解锁
        uint eachrelease;  //每次释放
        uint startime;     //添加时间 
      }
   Lockinfo public  _lockinfo = Lockinfo(0,0,0);  // 按定义的顺序依次指定值
   mapping(address => Lockinfo) public locklist;
  uint public locktimelang=604800;

   event Addblock(address indexed lockaddress, uint tokens);
  
   


   // ------------------------------------------------------------------------
   // 构造函数
   // ------------------------------------------------------------------------
   function KYCToken() public {
       symbol = "KYC";
       name = "KYC Public Welfare Token";
       decimals = 6;
       _totalSupply =139000000000000;

       balances[msg.sender] = _totalSupply;

       Transfer(address(0), msg.sender, _totalSupply);
   }
   // ------------------------------------------------------------------------
   // 添加锁仓
   // ------------------------------------------------------------------------
   function addlock(address lockaddress, uint tokens) public onlyOwner  returns (bool success) {
         Lockinfo address_lockinfo=locklist[lockaddress];
         
         if (address_lockinfo.startime==0){
               _lockinfo.lock_token=tokens;
               _lockinfo.eachrelease=safeDiv(tokens,104);
               _lockinfo.startime=now;
              locklist[lockaddress]=_lockinfo;
            
           
        }else{
             return false;
        }
       
       Addblock(lockaddress, tokens);
       return true;
   }

   
    // ------------------------------------------------------------------------
   // j解锁 锁仓
   // ------------------------------------------------------------------------
   function unlock(address lockaddress) public onlyOwner  returns (bool success) {
     
              _lockinfo.lock_token=0;
               _lockinfo.eachrelease=0;
               _lockinfo.startime=0;
              locklist[lockaddress]=_lockinfo;
     
     
        
       
       Addblock(lockaddress, 0);
       return true;
   }


function getlock(address lockaddress) public  returns (uint lock_token,uint eachrelease,uint startime,uint nowlock) {
       
       
      Lockinfo  addresslock_info=locklist[lockaddress];
      
      lock_token= addresslock_info.lock_token;
      eachrelease= addresslock_info.eachrelease;
       startime= addresslock_info.startime;
        uint nowtime=now;
        uint unlocktoken=(nowtime- addresslock_info.startime)/locktimelang*addresslock_info.eachrelease;
        
        if( unlocktoken>=addresslock_info.lock_token){
             _lockinfo.lock_token=0;
               _lockinfo.eachrelease=0;
               _lockinfo.startime=0;
              locklist[lockaddress]=_lockinfo;
              nowlock=0;
        }else{
            nowlock=addresslock_info.lock_token-(nowtime- addresslock_info.startime)/locktimelang*addresslock_info.eachrelease;
        }
        
        // nowlock=addresslock_info.lock_token-(nowtime- addresslock_info.startime)/locktimelang*addresslock_info.eachrelease;
      
   }



   // ------------------------------------------------------------------------
   // 总供应量
   // ------------------------------------------------------------------------
   function totalSupply() public constant returns (uint) {
       return _totalSupply  - balances[address(0)];
   }


   // ------------------------------------------------------------------------
   // 得到资金的数量
   // ------------------------------------------------------------------------
   function balanceOf(address tokenOwner) public constant returns (uint balance) {
       return balances[tokenOwner];
   }
   
   // ------------------------------------------------------------------------
   // 转账从代币拥有者的账户到其他账户
   // - 所有者的账户必须有充足的资金去转账
   // - 0值的转账也是被允许的
   // ------------------------------------------------------------------------
   function transfer(address to, uint tokens) public returns (bool success) {
    //   验证锁仓
      Lockinfo  addresslock_info=locklist[msg.sender];
      if(addresslock_info.startime!=0){
          uint nowtime=now;
          uint nowlock=0;
           uint unlocktoken=(nowtime- addresslock_info.startime)/locktimelang*addresslock_info.eachrelease;
        
        if( unlocktoken>=addresslock_info.lock_token){
             _lockinfo.lock_token=0;
               _lockinfo.eachrelease=0;
               _lockinfo.startime=0;
              locklist[msg.sender]=_lockinfo;
            //   nowlock=0;
        }else{
            nowlock=addresslock_info.lock_token-(nowtime- addresslock_info.startime)/locktimelang*addresslock_info.eachrelease;
            if(safeSub(balances[msg.sender], tokens)<nowlock){
             return false;
         }
        }
          
          
        
          
      }
      
      
       balances[msg.sender] = safeSub(balances[msg.sender], tokens);
       balances[to] = safeAdd(balances[to], tokens);
       Transfer(msg.sender, to, tokens);
       return true;
   }


   // ------------------------------------------------------------------------
   // 授权
   // ------------------------------------------------------------------------
   function approve(address spender, uint tokens) public returns (bool success) {
       allowed[msg.sender][spender] = tokens;
       Approval(msg.sender, spender, tokens);
       return true;
   }


   // ------------------------------------------------------------------------
   // 和approve连接在一起
   //
   // The calling account must already have sufficient tokens approve(...)-d
   // for spending from the from account and
   // - From account must have sufficient balance to transfer
   // - Spender must have sufficient allowance to transfer
   // - 0 value transfers are allowed
   // ------------------------------------------------------------------------
   function transferFrom(address from, address to, uint tokens) public returns (bool success) {
       balances[from] = safeSub(balances[from], tokens);
       allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
       balances[to] = safeAdd(balances[to], tokens);
       Transfer(from, to, tokens);
       return true;
   }


   // ------------------------------------------------------------------------
   // 返回授权数量
   // ------------------------------------------------------------------------
   function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
       return allowed[tokenOwner][spender];
   }


   // ------------------------------------------------------------------------
   // 合约不接受以太币
   // ------------------------------------------------------------------------
   function () public payable {
       revert();
   }


      // ------------------------------------------------------------------------
     // Owner can transfer out any accidentally sent ERC20 tokens
     //所有者能够转移任何ERC20代币的接口
    // ------------------------------------------------------------------------
   function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
       return ERC20Interface(tokenAddress).transfer(owner, tokens);
   }
}