/**
 *Submitted for verification at Etherscan.io on 2021-07-05
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
   address public admin;
   address public kun_token_address;
   address public qsd_token_address;
   address public token_address;   //token 

   uint public  min_allocation;
   uint public max_allocation;
   
   uint public kun_amount; 
   uint public max_funding_goal;
   uint public min_funding_goal;
   
   uint public cur_coin_amount;
   uint public status;
   bool public be_pay_kun;
   bool public be_pay_token;
   
    bool public be_out_kun;
   bool public be_out_token;
   
   
   uint  public price;
   uint private code_success=30000;
   uint public cur_qsd_amount=0;
   
   struct User{
        uint amount; //coin num
        bool kyc;
        bool is_used;
    }
   
   mapping(address => User) public persons;
   
   event FundTransfer(uint _now,uint _auctionStart,uint _amount,address sender,address owner);
 
	   
    //构造函数，初始化出价时间，竞拍开始时间
   constructor(uint _auction_start,uint _auction_end,uint _distribution_time,
   address _admin,address _owner,  address  _kun_token_address,address  _qsd_token_address, address  _token_address,
    uint _min_allocation,uint _max_allocation,
    uint _kun_amount,uint _max_funding_goal,uint  _min_funding_goal,
    uint _price) public{
         auction_start = _auction_start;
         auction_end = _auction_end;
         distribution_time =_distribution_time;
    
         admin= _admin;
         owner =_owner;
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
        be_out_kun=be_out_token=false;
        status= 1 ;
        cur_qsd_amount=0;
        cur_coin_amount=0;
        
    }

 function pay(uint256 _amount) public   returns (uint ret){
     require(status == 8 ,'error status');
     require(now >= auction_start ,'error auction_start');
     require( now<auction_end  ,'error auction_end');
     require(_amount>= min_allocation ,'error min_allocation');

     //qsd 
	  Token qsd_token=Token(qsd_token_address);
	  uint256 qsd_price=  qsd_token.getStableTokenPrice();
	  require(qsd_price>0,'error qsd price');
	  uint256 num=  _amount* qsd_price / price;
	  
	 //require(persons[msg.sender].kyc ,'error kyc');
	 require(add( persons[msg.sender].amount,num)<=max_allocation ,'error max_allocation');
	 require(add(cur_coin_amount,num)<= max_funding_goal ,'error max_funding_goal');
	 
	
      persons[msg.sender].amount=add(persons[msg.sender].amount,num);
      cur_coin_amount=add(cur_coin_amount,num);
      cur_qsd_amount=add(cur_qsd_amount,_amount);
	  safeTransferFrom(qsd_token_address,msg.sender,address(this),_amount);
	  return code_success;
}

 
 function get_qsd_price() public view returns (uint){
     //qsd_price 
	  Token qsd_token=Token(qsd_token_address);
	  return qsd_token.getStableTokenPrice();
}

 function get_remain_amount() public view returns (uint){
      uint256 remain_coin_amount=max_funding_goal-cur_coin_amount;
	  return remain_coin_amount;
}

 function get_status() public view returns (uint _status){
     _status=status;
 
   if(now>=auction_end && status ==8&& cur_coin_amount< min_funding_goal ){
        _status=9;
    }
    
   if(now>=auction_end && status==8 && cur_coin_amount>= min_funding_goal ){
        _status=7;
    }
    
    if(!be_pay_token&& status==7 && now>distribution_time){
       _status=11;
    }
    
    if(status==4){
        _status =8;
    }
	return _status;
}

 function deposit_kun() public  returns (uint ret){
      require(!be_pay_kun && now<= distribution_time && msg.sender==owner);
      be_pay_kun=true;
      status=8;
	  safeTransferFrom(kun_token_address,owner,address(this),kun_amount);
      return code_success;
  }
   
 function withdraw_kun() public  returns (uint ret){
         require(msg.sender==owner,'owner error');
     
       if(status==9 || status==10 || status ==11){
               require(be_pay_kun,'be_pay_kun error');
               require(!be_out_kun,'be_out_kun error');
               be_out_kun=true;
            	safeTransfer(kun_token_address, owner, kun_amount); 
         }
       
        if(be_out_token&& be_out_kun){
            status=100;
        }
    	 return code_success; 
 } 
 
    
 function withdraw_qsd() public  returns (uint ret){
         require(msg.sender==owner,'owner error');
     
      if( status==10){
            require(be_pay_token,'be_pay_token error');
            require(!be_out_token,'be_out_token error');
            be_out_token=true;
            safeTransfer(qsd_token_address, owner, cur_qsd_amount); 
        }
        
        if(be_out_token&& be_out_kun){
            status=100;
        }
     return code_success; 
 } 

  function deposit_coin() public  returns (uint ret){
    	 require(!be_pay_token,'be_pay_token is error');
    	 require(now>=auction_end, 'error auction_end');
    	 require(now<=distribution_time,'error distribution_time');
    	 require(status==7,'status not =7');
     	 require(msg.sender==owner,'sender error');
          be_pay_token=true;
          status=10;
    	  safeTransferFrom(token_address,msg.sender,address(this),cur_coin_amount);
      return code_success;
  }
  
  //user提代
 function withdraw() public  returns (uint ret){
   	  require(status>=10,'status error');
   	  uint256 amount= persons[msg.sender].amount;
   	  require(amount>0,'amount error');
   	  
   	  persons[msg.sender].amount= sub(persons[msg.sender].amount,amount);
	  safeTransfer(token_address, msg.sender, amount);

	  return code_success; 
 } 
 
   //user提代
 function test_set_amount(uint num,bool kyc) public {
     User memory user=persons[msg.sender];
     user.amount=num;
     user.kyc= kyc;
     persons[msg.sender]=user;
 } 
 
 function have_claim() public view returns (bool){
    if(be_pay_token && now>distribution_time){
       return true;
    }
    return false;
 }
 
 function set_start_status() public{
      require(status==2,'pending error');
      require(msg.sender==admin,'admin error');
      status = 1;
 }
 
 function set_status(uint _status) public{
      status = _status;
 }
 
  function set_date(uint _auction_end,uint _distribution_time) public{
         auction_end = _auction_end;
         distribution_time =_distribution_time;
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
        
}