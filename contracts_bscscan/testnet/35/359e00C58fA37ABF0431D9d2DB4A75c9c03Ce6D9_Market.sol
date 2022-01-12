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
    event Sell(address indexed _user,uint256 orderId,string  currency,uint256 _value,uint256 _price);
    event Redeem(address indexed _user,uint256 orderId);
    event Buy(address indexed _user,uint256 orderId,uint256 _value,uint256 price);

    function sell(string memory currency,uint256 value,uint256 price,address _user) public returns(uint256){
       // require(msg.sender==GasolineContract,"error!");
        require(value>0 && value.mod(5)==0 && price>0 ,"value error!");
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
        emit Sell(_user,newOrderId,currency,value,price);
        return newOrderId;
    }

    function redeem(uint256 _orderId, string memory currency,address _user) public  returns (uint256,uint256){
        //require(msg.sender==GasolineContract,"error!");
        uint256 index = orderIndex[_orderId];
        uint256 myIndex = myOrderIndex[_orderId];
        OrderDetail  memory detail=  orders[currency][index];
        require(detail.sender == _user,"sender error");
        delete (orders[currency][index]);
        delete (myOrders[_user][myIndex]);
        emit Redeem(_user,_orderId);
        return (detail.value,detail.price);
    }


    function buy(uint256 _orderId, string memory currency,address _user) public returns(address,uint256,uint256) {
        //require(msg.sender==GasolineContract,"error!");
        uint256 index = orderIndex[_orderId];
        OrderDetail  memory detail=  orders[currency][index];
        IERC20 token= config.getToken(currency);
        uint256 decimals= uint256(10).mul(token.decimals());
        uint256 feeRate =  feeMap[currency].mul(decimals).div(100);
        uint256 fee= detail.price.mul(feeRate).div(decimals);
        uint256 realAmount= detail.price.sub(fee);
        if(fee>0){
            token.safeTransferFrom(_user,address(config.getReceiveAddress()),fee);
        }
        token.safeTransferFrom(_user,address(detail.sender),realAmount);
        delete (orders[currency][index]);
        delete (myOrders[detail.sender][myOrderIndex[_orderId]]);
        emit Buy(_user,_orderId,detail.value,detail.price); 
        return(detail.sender,detail.value,detail.price);
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

    function getOrderDetail(string memory currency,uint256 _orderId) external view returns(OrderDetail memory) {
        return orders[currency][orderIndex[_orderId]];
    }


}