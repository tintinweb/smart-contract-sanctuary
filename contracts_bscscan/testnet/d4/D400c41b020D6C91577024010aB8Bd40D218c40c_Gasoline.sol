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

    mapping(address => BalanceDetail) private balances;

    event MarketEvent(address indexed _user,string eventType ,uint256 orderId,string  currency,uint256 _value,uint256 _price);

    function setBlindBox(BlindBox _blindBox) public onlyOwner {
        blindBox = _blindBox;
    }

     function setMarket(Market _market) public onlyOwner {
        market = _market;
    }

    function getBalanceOf(address account) external view returns (BalanceDetail memory) {
        return balances[account];
    }


    function sellMarket(string memory currency,uint256 value,uint256 price) public {
        BalanceDetail storage detail= balances[msg.sender];
        require(detail.amount>=0,"gasoline not balance");
        uint256 orderId= market.sell(currency, value, price,msg.sender);
        detail.amount=detail.amount.sub(value);
        detail.freeze=detail.freeze.add(value);
        emit MarketEvent(msg.sender,"Sell",orderId,currency,value,price);
    }

    function redeemMarket(uint256 _orderId, string memory currency) public {
        (uint256 value,uint256 price)= market.redeem(_orderId,currency,msg.sender);
        BalanceDetail storage detail= balances[msg.sender];
        require(detail.freeze>=value,"gasoline not balance");
        detail.amount=detail.amount.add(value);
        detail.freeze=detail.freeze.sub(value);
        emit MarketEvent(msg.sender,"Redeem",_orderId,currency,value,price);
    }


    function buyMarket(uint256 _orderId, string memory currency) public {
       (address _sellUser, uint256 value, uint256 price) =  market.buy(_orderId,currency,msg.sender);
        BalanceDetail storage sellDetail= balances[_sellUser];
        require(sellDetail.freeze>=value,"gasoline not balance");
        sellDetail.freeze=sellDetail.freeze.sub(value);
        BalanceDetail storage detail= balances[msg.sender];
        detail.amount=detail.amount.add(value);
        emit MarketEvent(msg.sender,"Buy",_orderId,currency,value,price);
    }

    function buyBlindBox(uint8 boxId,uint256 num) public {
        uint256 value=  blindBox.buyBox(boxId,num,msg.sender);
        balances[msg.sender].amount=balances[msg.sender].amount.add(value);
    }

}