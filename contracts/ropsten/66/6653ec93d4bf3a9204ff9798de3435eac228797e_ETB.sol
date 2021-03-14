/**
 *Submitted for verification at Etherscan.io on 2021-03-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }



    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}






contract ETB {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;
  using Address for address ;
  uint256 constant decimal = 18;

  //config start
  IERC20 public token ;
  mapping(uint8=>uint256[2]) private config_level_price;
  uint256 drawback_eth_percent = 86;
  uint256 drawback_etb_percent = 14;
  uint256 etb_price = 0.2*(10**18);
  uint256 usdt_price = 6.5*1000;
  
  struct DrawData{
      address payable account;
      uint8 percent;
  }
 DrawData[]  private  drawList ;
 //config end

  uint256 private total_etbnum ;
  uint256 private total_address;
  
  //static data start
  struct InvestData{
      address payable account;
      uint256 back_num;
  }
  mapping (address => uint256) private static_level_address;
  mapping (uint8=>InvestData[]) private static_level_data;
  mapping(uint8=>uint256) private static_head_index;
  
  mapping(address =>uint256) private static_sy_eth_address;
  mapping(address =>uint256) private static_sy_etb_address;
  uint256 private static_sy_eth_total ;
  uint256 private static_sy_etb_total;
  uint256 private static_pay_total;
  //static data end

  //dynamic data start
  struct DLevel{
      uint8 level;
      uint256 sonnum;
  }
  mapping (address => DLevel) private dynamic_level_address;
  mapping(address =>uint256) private dynamic_sy_eth_address;
  mapping(address =>uint256) private dynamic_sy_etb_address;
  uint256 private dynamic_sy_eth_total;
  uint256 private dynamic_sy_etb_total;
  uint256 private dynamic_pay_total;
  //dynamic data end


    

   
  uint256 constant rate =  (10**15);//(10**17)
  constructor() public payable{
      config_level_price[1] = [3*rate,5*rate];
      config_level_price[2] = [6*rate,8*rate];
      config_level_price[3] = [2*rate,12*rate];
      config_level_price[4] = [4*rate,2*rate];
      config_level_price[5] = [8*rate,4*rate];
      config_level_price[6] = [6*rate,8*rate];
      config_level_price[7] = [192*rate,16*rate];
      config_level_price[8] = [384*rate,32*rate];
      config_level_price[9] = [768*rate,64*rate];
      config_level_price[10] = [1536*rate,128*rate];
  
      
      drawList.push(DrawData({account:0x3eB2b3a3aaD0663B04DE3f54e78a1cB1ab8C1C74,percent:8}));
      drawList.push(DrawData({account:0x556a75b9d5a5c5aac0715cC130BBdC837F7a7fb7,percent:6}));
      
     dynamic_level_address[0x3eB2b3a3aaD0663B04DE3f54e78a1cB1ab8C1C74] = DLevel({level:10,sonnum:0});
     
     
  }
   

   function setToekn(IERC20 contract_address) public {
       require(address(contract_address).isContract());
       token = contract_address;
   }
  
   
   function userInfo(address account) public view returns(
   uint256 dynamic_level,
   uint256 dynamic_nodenum,
   uint256 dynamic_sy_eth,
   uint256 dynamic_sy_etb,
   uint256 static_level,
   uint256 static_sy_eth,
   uint256 static_sy_etb
   
   ){
       return(dynamic_level_address[account].level,
       dynamic_level_address[account].sonnum,
       dynamic_sy_eth_address[account],
       dynamic_sy_etb_address[account],
       static_level_address[account],
       static_sy_eth_address[account],
       static_sy_etb_address[account]); 
   }
   function totalInfo() public view returns(uint256 dynamic_sy_eth_all,
   uint256 dynamic_sy_etb_all,
   uint256 static_sy_eth_all,
   uint256 static_sy_etb_all,
   uint256 all_address,
   uint256 static_payall,
   uint256 dynamic_payall
   ){
    return(dynamic_sy_eth_total,
    dynamic_sy_etb_total,
    static_sy_eth_total,
    static_sy_etb_total,
    total_address,
    static_pay_total,
    dynamic_pay_total
    );
   }
 
  

  function staticInvest(uint8 invent_level) public payable{
     require(dynamic_level_address[msg.sender].level>=invent_level);
     require(static_level_address[msg.sender]>=invent_level-1);
     checkStaticValuePrice(invent_level);
    

    if( invent_level>static_level_address[msg.sender] ){
        static_level_address[msg.sender] = invent_level;
      }
     static_pay_total.add(msg.value);
     static_level_data[invent_level].push( InvestData({ account:msg.sender, back_num:0} ));

     if( static_level_data[invent_level].length==1){
        staticReward(static_level_data[invent_level][0].account,invent_level);
       return ;
   }
       staticWithDraw(invent_level);
  }


  
 


  function dynamicInvest(uint8 invent_level,address payable referr_address ) public payable{
       require( referr_address != address(0),"referr_address can not be  zero address ");
       require(dynamic_level_address[msg.sender].level==invent_level-1);
       require(dynamic_level_address[referr_address].level>=invent_level);
       require(dynamic_level_address[referr_address].sonnum<2);
     
       checkDynamicValuePrice(invent_level);
       
      
      if(dynamic_level_address[msg.sender].level==0){
          total_address = total_address.add(1);
      }
      dynamic_level_address[msg.sender].level = invent_level;
      
      dynamic_level_address[referr_address].sonnum = dynamic_level_address[referr_address].sonnum.add(1);
     
      dynamic_pay_total = dynamic_pay_total.add(msg.value);
      dynamicReward(referr_address,invent_level);
  }
  
   function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance2");
        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted2");
    }
   


  function sendStaticToken(address account,uint256 num) internal {
      token.safeTransfer(account,num);
      total_etbnum = total_etbnum.add(num);
      static_sy_etb_total = static_sy_etb_total.add(num);
      static_sy_etb_address[account] = static_sy_etb_address[account].add(num);
    }
   function sendStaticValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
        static_sy_eth_address[recipient] = static_sy_eth_address[recipient].add(amount);
        static_sy_eth_total = static_sy_eth_total.add(amount);
    }
    
    
  function sendDynamicToken(address account,uint256 num) internal {
      token.safeTransfer(account,num);
      total_etbnum = total_etbnum.add(num);
      dynamic_sy_etb_address[account] = dynamic_sy_etb_address[account].add(num);
      dynamic_sy_etb_total = dynamic_sy_etb_total.add(num);
    }
   function sendDynamicValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
        dynamic_sy_eth_address[recipient] = dynamic_sy_eth_address[recipient].add(amount);
        dynamic_sy_eth_total = dynamic_sy_eth_total.add(amount);
    }
    
     function cal_real_etb(uint256 value) internal view returns(uint256){
        uint256 v = etb_price*usdt_price/1000;
        uint256 ret_value = value*10000;
       return uint256(ret_value/v) *(10**18);
    
    }
    function checkStaticValuePrice(uint8 invent_level) internal{
         uint256 pay_value = msg.value;
         require(invent_level>0,"level can not be zero ");
        require(pay_value>=config_level_price[invent_level][0],"eth is small");
    }
    function checkDynamicValuePrice(uint8 invent_level) internal{
        uint256 pay_value = msg.value;
         require(invent_level>0,"level can not be zero ");
         require(pay_value>=config_level_price[invent_level][1],"eth is small");
    }
    
    
     function staticReward(address payable head_account,uint8 invent_level) internal{
        uint256 price = config_level_price[invent_level][0].div(100)*(10**18);
        
        sendStaticValue(head_account,price.mul(drawback_eth_percent).div(100));
        sendStaticToken(head_account,cal_real_etb(price.mul(drawback_etb_percent).div(100)));
      
        for(uint8 i=0;i< drawList.length;i++){
          
             sendValue(drawList[i].account,price.mul(drawList[i].percent).div(100));
        }
      
  }
  function dynamicReward(address payable referr_address,uint8 invent_level) internal{
       uint256 price = config_level_price[invent_level][1];
       
        sendDynamicValue(referr_address,price.mul(drawback_eth_percent).div(100));
        sendDynamicToken(referr_address,cal_real_etb(price.mul(drawback_etb_percent).div(100)));
   
        for(uint8 i=0;i< drawList.length;i++){
            sendValue(drawList[i].account,price.mul(drawList[i].percent).div(100));
        }
  }
  
  function staticWithDraw(uint8 invent_level) internal{
      uint256 head_index = static_head_index[invent_level];
      InvestData storage head = static_level_data[invent_level][head_index];
      head.back_num.add(1);
       if(head.back_num==2){//直接发
          staticReward(head.account,invent_level);
        }else if(head.back_num == 3){//直接发 然后自动复投
          static_head_index[invent_level].add(1);
          staticReward(head.account,invent_level);
          staticFutou(invent_level,head.account);
        }
  }
  
  function staticFutou(uint8 invent_level,address payable account) internal{
    static_level_data[invent_level].push(InvestData({
       account:account,
       back_num:0
    }));
       staticWithDraw(invent_level);
  }
}