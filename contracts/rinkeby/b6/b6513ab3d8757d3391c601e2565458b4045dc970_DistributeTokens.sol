/**
 *Submitted for verification at Etherscan.io on 2022-01-08
*/

contract DistributeTokens {
    
    
    address public owner; 
    address[] investors; 
    uint[] investorTokens; 
    uint[] usage_count;
    uint  interest;
    uint public count;
    uint public son = 2;
    uint public mon = 3;
    
   

    constructor() public {
        owner = msg.sender;
    }
    
    mapping(address=>uint)my_interest;
    mapping(address=>user_info) public userinfo; 
    mapping(address=>address)verification;
    mapping(address=>uint) public Dividing_times;
    mapping(uint=>address) number;
    mapping(address=>uint)public Amount_invested;
    mapping(address=>address)quite_user;
    
    struct user_info{
        uint amount;
        uint user_profit; //投資者的利息
        uint block_number;
        uint timestamp;
    }

    //------------------投資------------------------------
    function invest() public payable {
        require(msg.sender != verification[msg.sender],"這組帳號使用過");
        require(msg.value != 0 ,"不能為零");
        verification[msg.sender]=msg.sender;
        
        Amount_invested[msg.sender]=msg.value;
        
        investors.push(msg.sender);  //push 就是把東西加進去陣列裡面
        investorTokens.push(msg.value / interest); 
        usage_count.push(1);
        fee();//手續費
        
        userinfo[msg.sender]=user_info(msg.value,interest,block.number,block.timestamp);
        count++;
        
    }
    
    
    function fee()private{
        owner.transfer(msg.value/50);
    }
    
    function querybalance()public view returns (uint){
        return address(this).balance;
    }
    
    //------------------分配獎金------------------------------
    
    function distribute(uint a, uint b) public {
        require(msg.sender == owner); 
        
        
        for(uint i = a; i < b; i++) { 
            investors[i].transfer(investorTokens[i]);
            
            number[i]=investors[i];
            Dividing_times[number[i]] = usage_count[i]++;
        } 
    }
    
    //------------------封裝利息資訊------------------------------
    
    function getInterest() public view returns(uint){
        if(interest <= 2190 && interest >= 0)
         return interest;
        else
         return 0;
    }    
    
    
    function Set_Interest(uint key)public{
        require(msg.sender==owner);
        if(key<=2190){
            interest = key;
        }else{
            interest = interest;
        }
    }
    
    //------------------移置安全區域------------------------------
    
    function Safe_trans() public {
        require(owner==msg.sender);
        owner.transfer(querybalance());
    } 
    
    //------------------退出並出金------------------------------
    
    function Set_quota(uint _son, uint _mon)public {
        require(owner == msg.sender);
        if(_son<_mon && _son<=100 && _mon<=100){
            son=_son;
            mon=_mon;
        }else{
            son=son;
            mon=mon;
        }
    }
    
    
    function quit()public {
        
        if(quite_user[msg.sender]==msg.sender){
            revert("你已經退出了");
        }else{
        msg.sender.transfer(Amount_invested[msg.sender]*son/mon);
        quite_user[msg.sender]=msg.sender;
        userinfo[msg.sender]=user_info(0,0,block.number,block.timestamp);
        count--;
        }
    }
    
    
}