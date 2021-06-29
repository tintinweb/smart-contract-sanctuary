/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface Token {
    function transfer(address receiver, uint amount) external returns (bool success) ;
    function approve(address _spender, uint256 _amount) external returns (bool success) ;
     function transferFrom(address _from, address _to, uint256 _amount)  external returns (bool success) ;
}

contract launchpad {
   
 address public seller;  
   uint  public auctionStart;//拍卖开始时间
   uint public  auctionEnd;//结束时间
   uint public  kun_max_balance;
   bool public be_paid;
   uint public  min_allocation;
   uint public max_allocation;
   
   uint public fundingGoal;  
   uint public amountRaised;   // 参与数量
   bool is_end;
       
   address public token_address;   // 要卖的token
   address public kun_token_address=0x5034e1591A908092f02e000a6Bae09D1DDc08510;

   mapping(address => uint) public persons;
   
   event FundTransfer(uint _now,uint _auctionStart,uint _amount,address sender,address owner);
 
	   
    //构造函数，初始化出价时间，竞拍开始时间
    constructor(uint _auctionStart,uint _auctionEnd,
    uint _min_allocation,uint _max_allocation,uint _kun_max_balance,address _seller,address _token_address,
     uint  _fundingGoal) public{
        auctionStart = auctionStart;
        auctionEnd = _auctionEnd;
      
        min_allocation= _min_allocation;
        max_allocation= _max_allocation;
        kun_max_balance = _kun_max_balance;
        be_paid=false;
        seller=_seller;
        fundingGoal=_fundingGoal;
        amountRaised=0;
        token_address =_token_address;
        is_end=false;
    }

   function pay1(uint256 _amount) public returns (uint reNum1){
       uint reNum=500;
	   
	   emit FundTransfer(now,auctionStart,_amount,msg.sender,address(this));
	   
         if(now < auctionStart){
             reNum =501;
             revert(); 
			
        }
    
        
        if(now >= auctionEnd){
          reNum =502;
          is_end=true;
           revert(); 
        }
        if(!be_paid){
             reNum =503;
           revert(); 
        }
 
       if(_amount< min_allocation){
           reNum1 =min_allocation;
		   return reNum1;
         revert(); 
       }
      
       if(persons[msg.sender]==0){
                 persons[msg.sender]=_amount;
       }
       
        uint _a= persons[msg.sender];
         if(_amount+_a> max_allocation){
            reNum =505;
           revert(); 
         }
        if(amountRaised+_amount>fundingGoal){
                reNum =509;
           revert(); 
        }
   
          //处理
        //IERC20(info.token).transerFrom(msg.sender,address(this),info.debts);
      
          // msg.sender.transfer(_amount);
             //当授权时触发Approval事件
    //    if(!tokenReward.approve(address(this),_amount)){
         //        reNum =507;
         //        revert(); 
         //   }
    
            //if(!tokenReward.transferFrom(msg.sender,address(this), _amount)){
            //     reNum =508;
             //    revert(); 
           // }
         // Person _person(_a+_amount,0);
       //   persons[msg.sender]=_a+_amount;
          amountRaised+=_amount;
          if(amountRaised> _amount){
             is_end=true;
          }
   }
   
 function safeApprove(address token, address to, uint value) internal {
         bytes4 id=bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }


function safeTransferFrom(address token, address from, address to, uint value) internal {
       bytes4 id=bytes4(keccak256("transferFrom(address,address,uint256)"));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd,from,to,value));
     require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        bytes4 id= bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }


function Approval(uint256 _amount) public returns (uint ret){
      ret= 30000;
 	 safeApprove(token_address,address(this),_amount);
	 return ret; 
}

function token_transfer(address _to,uint256 _amount) public returns (uint ret){
     ret= 30000;
	 safeTransfer(token_address,_to,_amount);
	 return ret; 
}
 
function pay(uint256 _amount) public returns (uint ret){
	  ret= 30000;
	  Token token=Token(token_address);
	  safeTransferFrom(token_address,msg.sender,address(this),_amount);
	  //token.transfer(msg.sender,,_amount);
	  amountRaised+=_amount;
	  return ret; 
	   // if(!tokenReward.approve(address(this),_amount)){
       //       ret= 30003;
       //   return (_amount,send); 
       // }
     
        //if(!tokenReward.transferFrom(msg.sender,address(this), _amount)){
        //        ret= 30004;
        //       return ret;
        //    }
       //return ret;
}

   
  function deposit_kun() public  returns (uint ret){
      ret= 30000;
      Token token=Token(kun_token_address);
	  token.transfer(msg.sender, kun_max_balance);
      return ret;
  }
   
 function withdraw_kun() public  returns (uint ret){
    ret= 30000;
	safeTransfer(kun_token_address, msg.sender, kun_max_balance);
	 return ret; 
 } 

  function deposit_coin() public  returns (uint ret){
      ret= 30000;
      Token token=Token(token_address);
	  token.transfer(msg.sender, amountRaised);
      return ret;
  }
  //提代
 function withdraw() public returns (uint ret){
      ret= 30000;
	  safeTransfer(kun_token_address, msg.sender, 10);
	  return ret; 
 } 

  function () external{
        revert();
      }
}