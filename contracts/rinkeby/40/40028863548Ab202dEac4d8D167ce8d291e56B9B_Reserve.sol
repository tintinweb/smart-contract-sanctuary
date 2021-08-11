/**
 *Submitted for verification at Etherscan.io on 2021-08-11
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

contract Reserve {
    // address of Owner
    address public owner;
    // tradeFlag = true: allow trading
    bool public tradeFlag;
    // information about custom token
    struct Token {
        address addressToken;
        uint buyRate;
        uint sellRate;
    }
    // address of native Token
    address public constant addressEth = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    Token public token;
    
    function Reserve(bool _tradeFlag, address reserveToken, uint _buyRate, uint _sellRate) public {
        owner = msg.sender;
        tradeFlag = _tradeFlag;
        token.addressToken = reserveToken;
        token.buyRate = _buyRate;
        token.sellRate = _sellRate;
    }
    
    function withdrawFunds(address tokenAddr, uint amount) public onlyOwner {
        if(tokenAddr == token.addressToken) {
            ERC20(token.addressToken).transfer(msg.sender, amount);
            Transfer(token.addressToken, msg.sender, amount);
        } else {
            msg.sender.transfer(amount);
            Transfer(address(this), msg.sender, amount);
        }
    }
    
    function setExchangeRates(uint buyRate, uint sellRate) public onlyOwner {
        token.buyRate = buyRate;
        token.sellRate = sellRate;
    }
    
    function getExchangeRates(bool isSell) public view returns(uint) {
        if(isSell) {
            return token.sellRate;
        } else {
            return token.buyRate;
        }
    }
    
    function setTradeFlag(bool value) public onlyOwner {
        tradeFlag = value;
    }
    
    function exchange(bool _isSell, uint amount) payable public requireFlag returns(uint) {
        if(_isSell) {
            require(msg.value == amount);
            uint currentTokenBalance = ERC20(token.addressToken).balanceOf(address(this));
            require(currentTokenBalance >= (amount/token.sellRate));
            ERC20(token.addressToken).transfer(msg.sender, amount/token.sellRate);
            Transfer(token.addressToken, msg.sender, amount/token.sellRate);
        } else {
            require(this.balance >= (amount*token.buyRate));
            ERC20(token.addressToken).transferFrom(msg.sender, this, amount);
            msg.sender.transfer(amount*token.buyRate);
            return amount*token.buyRate;
        }
    }
    
    function getBalance()public view returns(uint){
        return this.balance;
    }
    
    function getBalanceToken() public view returns(uint){
        uint256 amount = ERC20(token.addressToken).balanceOf(address(this));
        return amount;
    }
    
    function () payable public {}
    
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    modifier requireFlag(){
        require(tradeFlag == true);
        _;
    }
    
    event Transfer(address indexed from, address indexed to, uint tokens);
}