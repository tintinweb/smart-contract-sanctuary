/**
 *Submitted for verification at BscScan.com on 2021-09-08
*/

pragma solidity ^0.8.7;

contract Market {
    address addressSteak;
    address pancakeRouterAddress;

    Steak steak;
    PancakeRouter pancake;

    address payable owner;
    uint exchangeValue;
    
    constructor(address payable _owner, uint _exchangeValue) {  
        owner = _owner;
        exchangeValue = _exchangeValue;
        
        addressSteak = 0xE41E245Aad4C3FeC76F04e95cBe4038E00F53AC8;
        pancakeRouterAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        
        pancake = PancakeRouter(pancakeRouterAddress);
        steak = Steak(addressSteak);
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
        
        steak.approve(pancakeRouterAddress, out);
        pancake.addLiquidityETH{value: msg.value}(
            addressSteak,
            out,
            0, 
            0, 
            owner, 
            block.timestamp
        );

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
    
    fallback() external payable {}
}

contract Steak {
    function approve(address delegate, uint numTokens) public returns (bool) {}
    function transfer(address, uint) public returns (bool) {}
    function balanceOf(address) public view returns (uint) {}
}

contract PancakeRouter {
    function addLiquidityETH(
          address token,
          uint amountTokenDesired,
          uint amountTokenMin,
          uint amountETHMin,
          address to,
          uint deadline
        ) external payable returns (uint amountToken, uint amountETH, uint liquidity) {}
}