/**
 *Submitted for verification at Etherscan.io on 2021-08-09
*/

pragma solidity ^0.4.17;

interface ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

interface Reserve{
    function withdraw(address tokenAddress, uint amount) public;
    function getExchangeRates(bool isBuy) public view returns(uint);
    function setExchangeRates(uint buyRate, uint sellRate) public;
    function setTradeFlag(bool value) public;
    function exchange(bool _isBuy, uint amount) payable public returns(uint);
    function getBalance()public view returns(uint);
    function getBalanceToken() public view returns(uint);
}

contract Exchange {
    // address of Owner
    address owner;
    // address of native token
    address public constant addressEth = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    mapping(address => Reserve) listReserves;
    
    function Exchange() public {
        owner = msg.sender;
    }
    
    function addReserve(address reserveAddress, address tokenAddress, bool isAdd) public {
        if(isAdd) {
            Reserve reserve = Reserve(reserveAddress);
            listReserves[tokenAddress] = reserve;
        } else {
            delete(listReserves[tokenAddress]);
        }
    }
    
    function setExchangeRates(address tokenAddress, uint buyRate, uint sellRate) public onlyOwner {
        listReserves[tokenAddress].setExchangeRates(buyRate, sellRate);
    }
    
    function getExchangeRates(address srcToken, address destToken, uint amount) public view returns(uint) {
        if(srcToken == destToken) return 1;
        
        if(srcToken != addressEth && destToken != addressEth) {
            // Swap between 2 Tokens
            Reserve reserveSrc = listReserves[srcToken];
            Reserve reserveDest = listReserves[destToken];
            
            uint rateSellFromSrc = reserveSrc.getExchangeRates(false);
            uint rateBuyFromDest = reserveDest.getExchangeRates(true);
            uint rate = (amount/rateSellFromSrc)*rateBuyFromDest;
            return rate;
        } else if(srcToken == addressEth) {
            // Swap from ETH to custom Token ~ buy Token
            Reserve reserveD = listReserves[destToken];
            uint rateD = amount*reserveD.getExchangeRates(true);
            return rateD;
        } else if(destToken == addressEth) {
            // Swap from custom Token to ETH ~ sell Token
            Reserve reserveS = listReserves[srcToken];
            uint rateS = amount/reserveS.getExchangeRates(false);
            return rateS;
        }
    }
    
    function exchangeTokens(address srcToken, address destToken, uint amount) public payable {
        if(srcToken == destToken) return;
        
        Reserve reserveSrc = listReserves[srcToken];
        Reserve reserveDest = listReserves[destToken];
        uint amountToken = 0;
        uint amountEth = 0;
        
        if(srcToken != addressEth && destToken != addressEth) {
            // Swap between 2 Tokens
            ERC20(srcToken).transferFrom(msg.sender, address(this), amount);
            ERC20(srcToken).approve(reserveSrc, amount);
            reserveSrc.exchange(true, amount);
            amountEth = amount*reserveSrc.getExchangeRates(true);
            
            reserveDest.exchange.value(amountEth)(false, amountEth);
            amountToken = amountEth/reserveDest.getExchangeRates(false);
            ERC20(destToken).transfer(msg.sender, amountToken);
            
            return;
        } 
        if(srcToken == addressEth) {
            // Swap from ETH to custom Token ~ buy Token
            require(msg.value == amount);
            reserveDest.exchange.value(amount)(false, amount);
            amountToken = amount/reserveDest.getExchangeRates(false);
            ERC20(destToken).transfer(msg.sender, amountToken);
            return;
        } 
        if(destToken == addressEth) {
            // Swap from custom Token to ETH ~ sell Token
            ERC20(srcToken).transferFrom(msg.sender, address(this), amount);
            ERC20(srcToken).approve(reserveSrc, amount);
            reserveSrc.exchange(true, amount);
            amountEth = amount*reserveSrc.getExchangeRates(true);
            msg.sender.transfer(amountEth);
            return;
        }
    }
    
    function sendTokens(address srcToken, uint amount) payable public {
        ERC20(srcToken).transferFrom(msg.sender, address(this), amount);
        Reserve reserve = listReserves[srcToken];
        
        ERC20(srcToken).approve(reserve, amount);
        reserve.exchange(false, amount);
        msg.sender.transfer(this.balance);
    }
    
    function withdraw(address tokenAddress, uint amount) public onlyOwner {
        if(tokenAddress != addressEth) {
            ERC20(tokenAddress).transfer(msg.sender, amount);
        } else {
            msg.sender.transfer(amount);
        }
    }
    
    function () payable public {}
    
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
}