// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./SafeMath.sol";


interface BlindBox {
   function buyBox(uint8 boxId,uint256 num,address _user) external  returns (uint256);
}

interface Market {
    function sell(string memory currency,uint256 value,uint256 price,address _user) external returns(uint256);
    function redeem(uint256 _orderId, string memory currency,address _user) external  returns (uint256,uint256);
    function buy(uint256 _orderId, string memory currency,address _user) external returns(address,uint256,uint256);
}

contract Gasoline is Ownable {
    using SafeMath for uint256;
    address VehicleContract;
    BlindBox private blindBox;
    Market private market;

    struct BalanceDetail {
        uint256 amount;
        uint256 freeze;
    }
    uint256 totalAmount;

    mapping(address => BalanceDetail) private balances;

    event MarketEvent(address indexed _user,uint256 orderId,string  currency,uint256 _value,uint256 _price,string eventType);

    function setBlindBox(BlindBox _blindBox) public onlyOwner {
        blindBox = _blindBox;
    }

    function setMarket(Market _market) public onlyOwner {
        market = _market;
    }
    function setVehicleContract(address _vehicleContract) external onlyOwner{
        VehicleContract=_vehicleContract;
    }

    function addBalance(uint256 value,address user) public onlyOwner {
        balances[user].amount=balances[user].amount.add(value);
    }

    function getBalanceOf(address account) external view returns (BalanceDetail memory) {
        return balances[account];
    }


    function sellMarket(string memory currency,uint256 value,uint256 price) external  {
        BalanceDetail storage detail= balances[msg.sender];
        require(detail.amount>=0,"gasoline not balance");
        uint256 orderId= market.sell(currency, value, price,msg.sender);
        detail.amount=detail.amount.sub(value);
        detail.freeze=detail.freeze.add(value);
        emit MarketEvent(msg.sender,orderId,currency,value,price,"sell");
    }

    function redeemMarket(uint256 _orderId, string memory currency) external {
        (uint256 value,uint256 price)= market.redeem(_orderId,currency,msg.sender);
        BalanceDetail storage detail= balances[msg.sender];
        require(detail.freeze>=value,"gasoline not balance");
        detail.amount=detail.amount.add(value);
        detail.freeze=detail.freeze.sub(value);
        emit MarketEvent(msg.sender,_orderId,currency,value,price,"redeem");
    }

    function buyMarket(uint256 _orderId, string memory currency)external  {
       (address _sellUser, uint256 value, uint256 price) =  market.buy(_orderId,currency,msg.sender);
        BalanceDetail storage sellDetail= balances[_sellUser];
        require(sellDetail.freeze>=value,"gasoline not balance");
        sellDetail.freeze=sellDetail.freeze.sub(value);
        BalanceDetail storage detail= balances[msg.sender];
        detail.amount=detail.amount.add(value);
        emit MarketEvent(msg.sender,_orderId,currency,value,price,"buy");
    }

    function buyBlindBox(uint8 boxId,uint256 num) external {
        uint256 value=  blindBox.buyBox(boxId,num,msg.sender);
        balances[msg.sender].amount=balances[msg.sender].amount.add(value);
        totalAmount=totalAmount.add(value);
    }


    function transfer(address sender, address to,uint256 amount) external returns (bool) {
        // require(msg.sender==VehicleContract,"error!");
        BalanceDetail storage senderDetail= balances[sender];
        require(senderDetail.amount>=amount,"value not balance");
        senderDetail.amount=senderDetail.amount.sub(amount);
        BalanceDetail storage detail= balances[address(to)];
        detail.amount=detail.amount.add(amount);
        return true;
    }
 
  
}