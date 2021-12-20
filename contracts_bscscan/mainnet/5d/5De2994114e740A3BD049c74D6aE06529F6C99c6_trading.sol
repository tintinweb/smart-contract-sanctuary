/**
 *Submitted for verification at BscScan.com on 2021-12-20
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;

interface IERC20{
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
}
interface judgeStandard{
    function dispute(uint id,uint8 requirePrecentSubjectToseller,uint8 requirePrecentDepositToseller) external payable returns(bool r);
    function getResult(uint id) external returns (uint8 precentSubjectToseller,uint8 precentDepositToseller,bool resultState);
    function getArbitrationFee(uint id) external returns(uint arbitrationFee);
}
contract trading{
    struct Order{
       uint salenumber;
       uint price;
       uint lockedblocknumber;
       address payable seller;
       address payable buyer;
       address arbitration;
       address erc20address;
       uint sellerLiquidataedDamages;
       uint buyerLiquidataedDamages;
       string describe;
       string Currency;
       uint8 state;   //0 put 1 lock 2 complete 3 judge
    }
    struct Order2{
       uint id;
       uint salenumber;
       uint price;
       uint lockedblocknumber;
       address seller;
       address buyer;
       address arbitration;
       address erc20address;
       uint sellerLiquidataedDamages;
       uint buyerLiquidataedDamages;
       string describe;
       string Currency;
       uint8 state;   //0 put 1 lock 2 complete 3 judge
    }
    struct ChargeStr{
        uint16 precent; //10 means charge 10/1000, 200 means charge 200/1000 
        uint256 limit;
    }

    address private owner;
    address private vipfeeReceiver;
    Order[] private allOrder;
    mapping(address => uint[]) public mySaleOrder;
    mapping(address => uint[]) public myBuyOrder;
    mapping(string => ChargeStr) private charge;
    uint256 public buyerdisputeblocknum;
    uint256 public sellerdisputeblocknum;
    bool private Lock;
    constructor(uint256 Buyerdisputeblocknum,uint256 Sellerdisputeblocknum,address VipfeeReceiver) {
        owner=msg.sender;
        buyerdisputeblocknum=Buyerdisputeblocknum;
        sellerdisputeblocknum=Sellerdisputeblocknum;
        vipfeeReceiver=VipfeeReceiver;
    }
    function setvipfeeReceiver(address x) public returns(bool){
        require(msg.sender==owner,"!owner");
        vipfeeReceiver = x;
        return true;
    }
    function setbuyerdisputeblocknum(uint256 x) public returns(bool){
        require(msg.sender==owner,"!owner");
        buyerdisputeblocknum = x;
        return true;
    }
    function setsellerdisputeblocknum(uint256 x) public returns(bool){
        require(msg.sender==owner,"!owner");
        sellerdisputeblocknum = x;
        return true;
    }
    function setLock(bool x) public returns(bool){
        require(msg.sender==owner,"!owner");
        Lock = x;
        return true;
    }
    function setServiceCharge(string memory currency,uint16 precent,uint256 limit ) public returns(bool){
        require(msg.sender==owner,"!owner");
        charge[currency].precent=precent;
        charge[currency].limit=limit;
        return true;
    }
    function isContract(address _addr) private view returns (bool iscontract){
        uint32 size;
        assembly {
        size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function putSaleOrder(uint salenumber,uint price,string memory describe,string memory currency,address arbitration,address erc20address,uint buyerLiquidataedDamages) public payable returns(bool){
       require(IERC20(erc20address).balanceOf(msg.sender)>=salenumber,"Out of balance");
       require(IERC20(erc20address).allowance(msg.sender,address(this))>=salenumber,"Out of allowance");
       require(isContract(erc20address),"wrong erc20address");
       require(!isContract(msg.sender),"seller can not be a contract");
       bool r=IERC20(erc20address).transferFrom(msg.sender,address(this),salenumber);
       require(r,"Transfer failed");
       Order memory temporder = Order(salenumber,price,0,payable(msg.sender),payable(address(0)),arbitration,erc20address,msg.value,buyerLiquidataedDamages,describe,currency,0);
       allOrder.push(temporder);
       mySaleOrder[msg.sender].push(allOrder.length -1);
       return r;
    }
    
    function cancelSaleOrder(uint index) public returns(bool r){
        require(allOrder[index].seller==msg.sender,"That is not your order.");
        require(allOrder[index].state==0,"Can not cancel this case right now.");
        allOrder[index].state=2;
        allOrder[index].seller.transfer(allOrder[index].sellerLiquidataedDamages);
        r=IERC20(allOrder[index].erc20address).transfer(msg.sender,allOrder[index].salenumber);
        require(r);
    }

    function lockSaleOrder(uint index) public payable returns (bool){
        require(!Lock, "maintaining smart contract");
        require(allOrder[index].state==0,"you can not lock this order.");
        require(allOrder[index].buyerLiquidataedDamages==msg.value,"wrong deposit");
        require(msg.sender!=allOrder[index].seller,"you can not lock your order");
        require(!isContract(msg.sender),"buyer can not be a contract");
        allOrder[index].state=1;
        allOrder[index].buyer=payable(msg.sender);
        allOrder[index].lockedblocknumber=block.number;
        myBuyOrder[msg.sender].push(index);
        return true;
    }

    function comfirmTransaction(uint index) public returns(bool r){
        require(allOrder[index].seller == msg.sender ,"you are not the seller of this transaction,can not comfirm");
        require(allOrder[index].state == 1,"state fault");
        allOrder[index].state=2;
        r=chargeFee(index,allOrder[index].salenumber);
        require(r);
        allOrder[index].seller.transfer(allOrder[index].sellerLiquidataedDamages);
        allOrder[index].buyer.transfer(allOrder[index].buyerLiquidataedDamages);
    }
    
    function dispute(uint index,uint8 x,uint8 y) public payable returns(bool){
        require((allOrder[index].buyer == msg.sender&&block.number>allOrder[index].lockedblocknumber+buyerdisputeblocknum) || (allOrder[index].seller == msg.sender&&block.number>allOrder[index].lockedblocknumber+sellerdisputeblocknum),"You are not the buyer or seller, or wait for more blocks");
        require(allOrder[index].state == 1 || allOrder[index].state==3,"This order is not locked or completed");
        if(allOrder[index].state == 1){
        allOrder[index].state=3;
        }
        uint fee=judgeStandard(allOrder[index].arbitration).getArbitrationFee(index);
        require(msg.value==fee,"wrong arbitration fee");
        bool r=judgeStandard(allOrder[index].arbitration).dispute{value:fee}(index,x,y);
        require(r,"dispute is refused by judgeContract");
        return true;
    }
    
    function surrender(uint index) public returns(bool r){
         require(msg.sender==allOrder[index].seller||msg.sender==allOrder[index].buyer,"you are not buyer or seller.");
         require(allOrder[index].state==3,"Can not surrender now");
         allOrder[index].state=2;
         if(msg.sender==allOrder[index].seller){
            r=chargeFee(index,allOrder[index].salenumber);
            require(r);
            allOrder[index].buyer.transfer(allOrder[index].buyerLiquidataedDamages+allOrder[index].sellerLiquidataedDamages);
         }else{
             r = IERC20(allOrder[index].erc20address).transfer(allOrder[index].seller,allOrder[index].salenumber);
             allOrder[index].seller.transfer(allOrder[index].buyerLiquidataedDamages+allOrder[index].sellerLiquidataedDamages);
             require(r);
         }
    }
    
    function execute(uint index) public returns(bool){
        require(msg.sender==allOrder[index].seller||msg.sender==allOrder[index].buyer,"you are not buyer or seller.");
        require(allOrder[index].state==3,"Can not execute now");
        uint8 x;
        uint8 y;
        bool z;
        (x,y,z)=judgeStandard(allOrder[index].arbitration).getResult(index);
        require((z)&&(0<=x&&x<=100)&&(0<=y&&y<=100),"wrong return from judge");
        allOrder[index].state=2;
        if((allOrder[index].salenumber*x)/100!=0){
            bool r1 = IERC20(allOrder[index].erc20address).transfer(allOrder[index].seller,(allOrder[index].salenumber*x)/100);
            require(r1);
        }
        uint c=(allOrder[index].salenumber*(100-x))/100;
        if(c!=0){
           bool result=chargeFee(index,c);
           require(result);
        }
        uint d=allOrder[index].buyerLiquidataedDamages+allOrder[index].sellerLiquidataedDamages;
        if((d*y)/100!=0){
            allOrder[index].seller.transfer((d*y)/100);
        }
        if((d*(100-y))/100!=0){
            allOrder[index].buyer.transfer((d*(100-y))/100);
        }
        return true;
    }
    
    function chargeFee(uint index,uint c) private returns(bool r){
        if(allOrder[index].price == 0){
             r = IERC20(allOrder[index].erc20address).transfer(allOrder[index].buyer,c);
        }else{
            uint a = (charge[allOrder[index].Currency].limit*(10**IERC20(allOrder[index].erc20address).decimals())*1000000)/allOrder[index].price ;
            if(c>=a){
                uint b=((c-a)*charge[allOrder[index].Currency].precent)/1000;
                bool r1 = IERC20(allOrder[index].erc20address).transfer(vipfeeReceiver,b);
                require(r1);
                r = IERC20(allOrder[index].erc20address).transfer(allOrder[index].buyer,c-b);
            }else{
                r = IERC20(allOrder[index].erc20address).transfer(allOrder[index].buyer,c);
            }
        }
        return r;
    }
    
    
    function getMyBuyOrder(address sender,uint lineNumber) public view returns(Order2[] memory){
       Order2[] memory s=new Order2[](lineNumber);
       Order memory d;
       uint length=myBuyOrder[sender].length;
       uint x;
         for (uint i=0;i<length&&x<lineNumber; i++) {
          d = allOrder[myBuyOrder[sender][length-i-1]];
          if(d.buyer==sender&&(d.state==1 || d.state==3)){
              s[x]=Order2(myBuyOrder[sender][length-i-1],d.salenumber,d.price,d.lockedblocknumber,d.seller,d.buyer,d.arbitration,d.erc20address,d.sellerLiquidataedDamages,d.buyerLiquidataedDamages,d.describe,d.Currency,d.state);
              x++;
         }
       }
      return (s);
    }
    
        function getMySaleOrder(address sender,uint lineNumber) public view returns(Order2[] memory ){
          Order2[] memory s=new Order2[](lineNumber);
          Order memory d;
          uint length=mySaleOrder[sender].length;
          uint x=0;
          for (uint i=0;i<length&&x<lineNumber; i++) {
          d = allOrder[mySaleOrder[sender][length-i-1]];
          if(d.state==1 || d.state==3 || d.state==0){
              s[x]=Order2(mySaleOrder[sender][length-i-1],d.salenumber,d.price,d.lockedblocknumber,d.seller,d.buyer,d.arbitration,d.erc20address,d.sellerLiquidataedDamages,d.buyerLiquidataedDamages,d.describe,d.Currency,d.state);
              x++;
         }
     }
      return (s);
    }

    
    function getAllMyOrder(address sender,uint lineNumber) public view returns(Order2[] memory ){
        Order2[] memory s=new Order2[](lineNumber);
        Order memory d;
        uint x=0;
        uint length=myBuyOrder[sender].length;
        for (uint i=0;i<length&&x<lineNumber; i++) {
          d = allOrder[myBuyOrder[sender][length-i-1]];
          if(d.buyer==sender){
              s[x]=Order2(myBuyOrder[sender][length-i-1],d.salenumber,d.price,d.lockedblocknumber,d.seller,sender,d.arbitration,d.erc20address,d.sellerLiquidataedDamages,d.buyerLiquidataedDamages,d.describe,d.Currency,d.state);
                                                        
              x++;
          }
        }
        length=mySaleOrder[sender].length;
        for (uint i=0;i<length&&x<lineNumber; i++) {
          d = allOrder[mySaleOrder[sender][length-i-1]];
          if(d.seller==sender){
              s[x]=Order2(mySaleOrder[sender][length-i-1], d.salenumber,d.price,d.lockedblocknumber,sender,d.buyer,d.arbitration,d.erc20address,d.sellerLiquidataedDamages,d.buyerLiquidataedDamages,d.describe,d.Currency,d.state);
              x++;
         }
       }
      return (s);
    }
    
    function queryOrder(uint quantity_min,uint quanity_max,uint price_min,uint  price_max,string memory currency,uint linenumber,address erc20address,uint sellerDeposit,uint buyerDeposit) view public returns(Order2[] memory){
      uint length = allOrder.length;
      Order2[] memory s=new Order2[](linenumber);
      Order memory d;
      uint x=0;
          for (uint i=0; i<length &&x<linenumber; i++) {
          d = allOrder[length-i-1];
          if(d.erc20address==erc20address && d.state == 0 && d.price<=price_max && d.price>= price_min && d.salenumber>=quantity_min && d.salenumber<=quanity_max &&keccak256(bytes(d.Currency) ) == keccak256(bytes(currency))&&d.sellerLiquidataedDamages>=sellerDeposit&&d.buyerLiquidataedDamages<=buyerDeposit){
           s[x]=Order2(length-i-1,d.salenumber,d.price,0,d.seller,d.buyer,d.arbitration,erc20address,d.sellerLiquidataedDamages,d.buyerLiquidataedDamages,d.describe,d.Currency,0);
           x++;
          }
      }
        return (s);
    }
    
    function getOrderInfo(uint index) public view returns(Order memory r){
        if(index<allOrder.length){
        r=allOrder[index];
        }
    }
}