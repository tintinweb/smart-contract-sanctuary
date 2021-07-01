/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface Token {
  

    function transfer(address receiver, uint amount) external returns (bool success) ;
    function approve(address _spender, uint256 _amount) external returns (bool success) ;
    function transferFrom(address _from, address _to, uint256 _amount)  external returns (bool success) ;
    function getStableTokenPrice() external view returns (uint256 price) ;
}

contract launchpad {
   
   uint  public auction_start;
   uint  public  auction_end;
   uint  public   distribution_time; //end pay token time
   
      
   address public owner;  
   address public kun_token_address;
   address public qsd_token_address;
   address public token_address;   //token 

   uint public  min_allocation;
   uint public max_allocation;
   
   uint public kun_amount; 
   uint public max_funding_goal;
   uint public min_funding_goal;
   uint public cur_funding_goal;
   
   
   uint public cur_coin_amount;
   uint public status;
   bool public be_pay_kun;
   bool public be_pay_token;
   
   uint  public price;
   uint private code_success=30000;
   
   mapping(address => uint) public persons;
   
   event FundTransfer(uint _now,uint _auctionStart,uint _amount,address sender,address owner);
 
	   
    //构造函数，初始化出价时间，竞拍开始时间
    /*constructor(uint _auction_start,uint _auction_end,uint _distribution_time,
     address  _kun_token_address,address  _qsd_token_address, address  _token_address,
    uint _min_allocation,uint _max_allocation,
    uint _kun_amount,uint _max_funding_goal,uint  _min_funding_goal,
    uint _price) public{
         auction_start = _auction_start;
         auction_end = _auction_end;
         distribution_time =_distribution_time;
    
         owner =msg.sender;
         kun_token_address =_kun_token_address;
         qsd_token_address =_qsd_token_address;
         token_address =_token_address;
         
        min_allocation= _min_allocation;
        max_allocation= _max_allocation;
        
        kun_amount = _kun_amount;
        max_funding_goal=_max_funding_goal;
        min_funding_goal=_min_funding_goal;
        
        price=_price;
        
        be_pay_token=be_pay_kun=false;
       
  
        status= 1 ;
        cur_coin_amount=0;
    }*/
    
    constructor() public{
 
         auction_start = 1624861987;
         auction_end = 1627453987;
         distribution_time =1627463987;
    
         owner =msg.sender;
         kun_token_address =0x5034e1591A908092f02e000a6Bae09D1DDc08510;
         qsd_token_address =0xb9914a6a631F028458f55d18B245Db75f194a21A;
         token_address = 0x6AD2a6Ef6fE006830D6e35449B302F3D5cE8afc2;
         
        min_allocation= 1000;
        max_allocation= 10000000000000000;
        
        kun_amount = 10000;
        max_funding_goal=50000;
        min_funding_goal=2000;
        
        price=500003215706477846;
        
        be_pay_token=be_pay_kun=false;
       
  
        status= 1 ;
        cur_coin_amount=0;
    }
    

modifier  set_status(){
    if(now>=auction_start && now<auction_end && status ==4){
        status=8;
    }
    
   if(now>=auction_end && status ==4&& cur_funding_goal< min_funding_goal ){
        status=9;
    }
    
   if( (status ==4 ||status==8)&& cur_funding_goal>= min_funding_goal ){
        status=7;
    }
    
   if(!be_pay_token&& now>distribution_time){
       status=11;
    }
    
    _;   
}

 function pay(uint256 _amount) public set_status returns (uint ret){
     
      require(now >= auction_start && now<auction_end 
       && _amount>= min_allocation && add( persons[msg.sender],_amount)<=max_allocation
       && add(cur_funding_goal,_amount)<= max_funding_goal);
       

     //qsd 
	  Token qsd_token=Token(qsd_token_address);
	  uint256 qsd_price=  qsd_token.getStableTokenPrice();
	  uint256 num=  _amount* qsd_price / price;
	 
	 
      persons[msg.sender]=add(persons[msg.sender],num);
      cur_coin_amount=add(cur_coin_amount,num);
      
	  safeTransferFrom(token_address,msg.sender,address(this),_amount);
	  return code_success;
}

 function get_qsd_price() public view returns (uint){
     //qsd_price 
	  Token qsd_token=Token(qsd_token_address);
	  return qsd_token.getStableTokenPrice();
}

 function get_remain_amount() public view returns (uint){
      uint256 remain_coin_amount=(max_funding_goal-cur_funding_goal)* get_qsd_price()/price;
	  return remain_coin_amount;
}

 function get_status() public view returns (uint){
	  return status;
}

 function deposit_kun() public set_status returns (uint ret){
      require(!be_pay_kun && now<= auction_start && msg.sender==owner);
      be_pay_kun=true;
      status=4;
	  safeTransferFrom(kun_token_address,owner,address(this),kun_amount);
      return code_success;
  }
   
 function withdraw_kun() public set_status returns (uint ret){
     require(be_pay_kun && msg.sender==owner);
     require(status==9 &&status==10 && status==11);
	 safeTransfer(kun_token_address, owner, kun_amount);
	 return code_success; 
 } 

  function deposit_coin() public set_status returns (uint ret){
	 require(!be_pay_token&& now>=auction_end && now<=distribution_time);
	 require(status==7);
      be_pay_token=true;
      status=4;
	  safeTransferFrom(token_address,msg.sender,address(this),cur_coin_amount);
      return code_success;
  }
  
  //提代
 function withdraw() public set_status returns (uint ret){
   	  require(status==10);
   	  uint256 amount= persons[msg.sender];
   	  require(amount>0);
	  safeTransfer(token_address, msg.sender, amount);
	 
	  return code_success; 
 } 
 
 function test_set_status(uint _status,uint _auction_start,uint _auction_end,uint _distribution_time,
     address  _kun_token_address,address  _qsd_token_address, address  _token_address,
    uint _min_allocation,uint _max_allocation,
    uint _kun_amount,uint _max_funding_goal,uint  _min_funding_goal,
    uint _price) public{
     //qsd_price 
	     auction_start = _auction_start;
         auction_end = _auction_end;
         _distribution_time =_distribution_time;
    
         owner =owner;
         kun_token_address =_kun_token_address;
         qsd_token_address =_qsd_token_address;
         token_address =_token_address;
         
        min_allocation= _min_allocation;
        max_allocation= _max_allocation;
        
        kun_amount = _kun_amount;
        max_funding_goal=_max_funding_goal;
        min_funding_goal=_min_funding_goal;
        
        price=_price;
        
        status=_status;
}
 
  function safeApprove(address token, address to, uint value) internal {
             bytes4 id=bytes4(keccak256(bytes('approve(address,uint256)')));
            (bool success, bytes memory data) = token.call(abi.encodeWithSelector(id, to, value));
            require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
   }
    
    
    function safeTransferFrom(address token, address from, address to, uint value) internal {
           bytes4 id=bytes4(keccak256("transferFrom(address,address,uint256)"));
            (bool success, bytes memory data) = token.call(abi.encodeWithSelector(id,from,to,value));
         require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
        }
    
        function safeTransfer(address token, address to, uint value) internal {
            bytes4 id= bytes4(keccak256(bytes('transfer(address,uint256)')));
            (bool success, bytes memory data) = token.call(abi.encodeWithSelector(id, to, value));
            require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
        }
      
       function add(uint256 a, uint256 b) internal pure  returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
        }
            
        function sub(uint256 a, uint256 b) internal pure returns (uint256) {
            assert(b <= a);
            return a - b;
        }

        function mul(uint256 a, uint256 b) internal pure returns (uint256) {
            uint256 c = a * b;
            assert(a == 0 || c / a == b);
            return c;
        }
        
  function () external{
        revert();
      }
}

   
// function Approval(uint256 _amount) public payable returns (uint ret){
//      ret= 30000;
//  	 safeApprove(token_address,address(this),_amount);
// 	 return ret; 
// }



// function token_transfer(address _to,uint256 _amount) public returns (uint ret){
//      ret= 30000;
// 	 safeTransfer(token_address,_to,_amount);
// 	 return ret; 
// }