pragma solidity ^0.4.16;

contract token{
    function transfer(address receiver, uint amount) external;
    function balanceOf(address receiver) constant public returns (uint balance);
}

contract Crowdsale {
    
    //代币地址
    token public tokenReward;
    
    uint[] public a1;
    uint[5] public a2;
    
    /**
     * 构造函数, 设置相关属性
     */
    constructor( address _addressOfToken) public payable{
           tokenReward = token(_addressOfToken);
           
    }

    function safeWithdrawal2(address addr) public view returns(uint t) {
      return tokenReward.balanceOf(addr);
    }
    
    function safeWithdrawal3(address addr) public {
        a1.push(5);
        uint r = tokenReward.balanceOf(addr);
        emit ReturnResult(r);
    }
    
    function safeWithdrawal4(address addr) public returns(uint t) {
        a2[0]=6;
        return tokenReward.balanceOf(addr);
    }
    
    event ReturnResult(uint t);
}