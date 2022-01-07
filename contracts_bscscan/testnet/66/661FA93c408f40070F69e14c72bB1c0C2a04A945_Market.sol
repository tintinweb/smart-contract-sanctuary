// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Config.sol";


contract Market is Ownable{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    uint256 MAX_PAGE_SIZE = 50;
    address GasolineContract;
    mapping (string => uint256) private feeMap;

    uint256 orderId=1;
    Config private config;
    struct OrderDetail {
        uint256 orderId;
        address sender;
        uint256 price;
        string currency;
        uint256 value;
        uint256 blockTime;
    }
    mapping(string => OrderDetail[]) private orders;
    mapping(uint256 => uint256) private orderIndex;

    mapping(address => OrderDetail[]) private myOrders; 
    mapping(uint256 => uint256) private myOrderIndex; 
    event Sell(address indexed _user,uint256 orderId,string  currency,uint256 _value,uint256 _price,uint256 blockTime);
    event Redeem(address indexed _user,uint256 orderId,uint256 blockTime);
    event Buy(address indexed _user,uint256 orderId,uint256 _value,uint256 price,uint256 blockTime);

    function sell(string memory currency,uint256 value,uint256 price,address _user) public{
        require(msg.sender==GasolineContract,"error!");
        uint256 newOrderId=orderId;
        myOrders[_user].push(
            OrderDetail(newOrderId,_user,price,currency,value,block.timestamp)
        );
        myOrderIndex[newOrderId] = myOrders[_user].length.sub(1);    
        orders[currency].push(
            OrderDetail(newOrderId,_user,price,currency,value,block.timestamp)
        );
        orderIndex[newOrderId] = orders[currency].length.sub(1);
        orderId++;
        emit Sell(_user,newOrderId,currency,value,price,block.timestamp);   
    }

    function redeem(uint256 _orderId, string memory currency,address _user) public  returns (uint256){
        require(msg.sender==GasolineContract,"error!");
        uint256 index = orderIndex[_orderId];
        uint256 myIndex = myOrderIndex[_orderId];
        OrderDetail  storage detail=  orders[currency][index];
        require(detail.sender == _user,"sender error");
        uint256 value=detail.value;
        delete (orders[currency][index]);
        delete (myOrders[_user][myIndex]);
        emit Redeem(_user,_orderId,block.timestamp);
        return value;
    }



    function buy(uint256 _orderId, string memory currency,address _user) public returns(address,uint256) {
        //require(msg.sender==GasolineContract,"error!");
        uint256 index = orderIndex[_orderId];
        uint256 myIndex = myOrderIndex[_orderId];
        OrderDetail  storage detail=  orders[currency][index];
        IERC20 token= config.getToken(currency);
        uint256 feeRate=  feeMap[currency];
        uint256 price= detail.price;
        uint256 value= detail.value;
        address sender= detail.sender;
        uint256 oldOrderId=detail.orderId;
        uint256 fee= price.mul(feeRate).mul(token.decimals()).div(100);
        uint256 amount= price.mul(token.decimals()).sub(fee);
        if(fee>0){
            token.safeTransferFrom(_user,address(config.getReceiveAddress()),fee);
        }
        token.safeTransferFrom(_user,detail.sender,amount);
        delete (orders[currency][index]);
        delete (myOrders[_user][myIndex]);
        emit Buy(_user,oldOrderId,value,price,block.timestamp); 
        return(sender,value);
    }



    function changeFee(string memory currency,uint256 _fee) public onlyOwner {
        feeMap[currency]=feeMap[currency]=_fee;
    }

    function getFee(string memory currency) external view returns(uint256)  {
       return feeMap[currency];
    }

    function setGasolineContract(address _gasolineContract) external onlyOwner{
        GasolineContract=_gasolineContract;
    }

    function setConfig(Config _config) public onlyOwner {
        config = _config;
    }


    function getMyOrder(address _user) external view returns(OrderDetail[] memory) {
        return myOrders[_user];
    }

     function getOrders(string memory currency) external view returns(OrderDetail[] memory) {
        return orders[currency];
    }



}