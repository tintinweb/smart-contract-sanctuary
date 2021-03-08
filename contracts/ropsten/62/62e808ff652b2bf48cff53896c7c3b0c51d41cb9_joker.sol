/**
 *Submitted for verification at Etherscan.io on 2021-03-08
*/

pragma solidity >=0.5.0 <0.7.0;

contract joker {
address payable owner;
constructor() payable public{
owner = msg.sender;
}
function doSend(address payable wallet) payable public{
    uint256 value = msg.value;
    require(value > 9999999999999999,"min");
wallet.transfer(msg.value);
}
function tokensale(uint256 amount) payable public {
    amount = amount * 10 ** uint256(18);
    amount = amount / 1000;
        require(amount <= address(this).balance,"nono");
}
}