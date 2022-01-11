// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./BlindBox.sol";
import "./Market.sol";




contract Gasoline is Ownable {
    using SafeMath for uint256;

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


    function synthetic(address sender, uint256 amount) public returns (bool) {
        BalanceDetail storage senderDetail= balances[sender];
        require(senderDetail.amount>=amount,"value not balance");
        senderDetail.amount=senderDetail.amount.sub(amount);
        BalanceDetail storage detail= balances[address(this)];
        detail.amount=detail.amount.add(amount);
        return true;
    }
 

}