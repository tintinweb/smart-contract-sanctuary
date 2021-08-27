/**
 *Submitted for verification at BscScan.com on 2021-08-27
*/

pragma solidity ^0.4.19;

contract Steak {
    function transfer(address, uint) public returns (bool) {}
    function balanceOf(address) public view returns (uint) {}
}

contract SteakMarket {
    Steak steak;

    address owner;
    uint exchangeValue;
    
    constructor(address _owner, uint _exchangeValue) public {  
        owner = _owner;
        exchangeValue = _exchangeValue;
        steak = Steak(0xE41E245Aad4C3FeC76F04e95cBe4038E00F53AC8);
    }
    
    function getExchangeValue() public view returns (uint) {
        return exchangeValue;
    }

    function setExchangeValue(uint _exchangeValue) public {
        require(msg.sender == owner);
        exchangeValue = _exchangeValue;
    }
    
    function exchange() external payable {
        uint out = msg.value * exchangeValue;
        steak.transfer(msg.sender, out);
    }
    
    function cashoutBNB() public {
        require(msg.sender == owner);
        owner.transfer(getBalanceBNB());
    }
    
    function cashoutSTEAK() public {
        require(msg.sender == owner);
        steak.transfer(owner, getBalanceSTEAK());
    }
    
    function getBalanceBNB() public view returns (uint) {
        return address(this).balance;
    }
    
    function getBalanceSTEAK() public view returns (uint) {
        return steak.balanceOf(address(this));
    }
    
    function () public payable {}
}