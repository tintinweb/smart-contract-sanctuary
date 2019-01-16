pragma solidity ^0.4.25;
contract ERC20 {
    function balanceOf(address who) public view returns(uint);
    function transfer(address to, uint value) public returns(bool);
}
contract KiOS {
    address owner;
    string public Description;
    mapping(address => uint) rates;
    event Sent(address indexed recipient, ERC20 indexed token, uint amount);
    constructor() public {
        owner = msg.sender;
        Description = "Make sure you call the purchase method, otherwise it will be considered a donation :)";
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "This method is only for contract owners!");
        _;
    }
    modifier allowed(address who) {
        require(who != address(0) && address(this) != who, "The address entered must be different from this contract and or zero address!");
        _;
    }
    function changeOwner(address newOwner) public onlyOwner allowed(newOwner) returns(bool) {
        owner = newOwner;
        return true;
    }
    function tokenBalances(ERC20 token) public view returns(uint) {
        if (ERC20(0) == token) return address(this).balance;
        else return token.balanceOf(address(this));
    }
    function tokenRates(ERC20 token) public view returns(uint) {
        return rates[token];
    }
    function updateRate(ERC20 token, uint price) public onlyOwner allowed(token) returns(bool) {
        rates[token] = price;
        return true;
    }
    function() public payable {}
    function purchase(ERC20 token) public payable allowed(token) returns(bool) {
        require(tokenRates(token) > 0);
        require(msg.value > 1 szabo, "The transaction must be greater than 0.000001 ETH!");
        uint ethVal = msg.value;
        uint availToken = tokenBalances(token);
        uint tokenVal = ethVal * tokenRates(token);
        uint returnEth = 0;
        if (tokenVal > availToken) {
            returnEth = (tokenVal - availToken) / tokenRates(token);
            tokenVal = availToken;
            msg.sender.transfer(returnEth);
            emit Sent(msg.sender, ERC20(0), returnEth);
        }
        if (!token.transfer(msg.sender, tokenVal))
        revert("An error occurred while sending the token!");
        emit Sent(msg.sender, token, tokenVal);
        return true;
    }
    function sendTo(address recipient, uint amount, ERC20 token) public onlyOwner allowed(recipient) returns(bool) {
        require(amount > 0 && amount <= tokenBalances(token),"The amount is too small and or exceeds the balance!");
        if (ERC20(0) == token) recipient.transfer(amount);
        else if (!token.transfer(recipient, amount)) revert("An error occurred while sending the token!");
        emit Sent(recipient, token, amount);
        return true;
    }
}