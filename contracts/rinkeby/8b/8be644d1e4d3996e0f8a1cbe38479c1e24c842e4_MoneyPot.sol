/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

pragma solidity >0.4.99 <0.6.0;
contract MoneyPot {
    address  payable public moneyReceiver;
    address payable public lastMoneyProvider;
    
    constructor(address payable _moneyReceiver) public {
        moneyReceiver = _moneyReceiver;
    }
    
    function() external payable {
        if (msg.value > 100) {
            lastMoneyProvider = msg.sender;
        }
    }
    
    function claimMoney() external{
        assert(msg.sender == moneyReceiver);
        moneyReceiver.transfer(address(this).balance);
    }
    
    function claimMoneyAndTipLastProvider() external{
        assert(msg.sender == moneyReceiver);
        if (address(this).balance > 100) {
            moneyReceiver.transfer(address(this).balance - 100);
            lastMoneyProvider.transfer(100);
        }
    }
}