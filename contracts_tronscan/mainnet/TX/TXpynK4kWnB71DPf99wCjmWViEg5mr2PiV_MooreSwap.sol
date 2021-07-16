//SourceUnit: swap.sol


pragma solidity ^0.5.10;

contract Token {
    function transfer(address _to, uint256 _value) public returns (bool){}
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){}
    function balanceOf(address _who) public view returns (uint256){}
    function allowance(address _owner, address _spender) public returns (uint) {}
    function decimals() public view returns(uint8){}
    function approve(address spender, uint256 value) public returns (bool) {}
}

contract MooreSwap{
    Token public token;
    address payable owner;
    address payable developer;
    uint32 pricePerToken = 500000;
    uint32 TokenPrecision = 1000000;
    constructor(address payable own, address tokenAd, address payable dev) public {
        developer = dev;
        owner = own;
        token = Token(tokenAd);
    }
    function getTokenOutFromTrx(uint trxAmount) public view returns(uint){
        return (trxAmount*TokenPrecision)/pricePerToken;
    }

    function buyToken() payable external{
        require(token.transfer(msg.sender, getTokenOutFromTrx(msg.value)), "Sending Failed");
        developer.transfer((msg.value*20)/100);
        owner.transfer((msg.value*80)/100);
    }
    function withdrawAllTokens() external{
        require(msg.sender == owner);
        token.transfer(owner, token.balanceOf(address(this)));
    }
}