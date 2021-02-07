//This Token Contract implements the standard token functionality (https://github.com/ethereum/EIPs/issues/20) as well as the following OPTIONAL extras intended for use by humans.
//In other words. This is intended for deployment in something like a Token Factory or Mist wallet, and then used by humans.
//Imagine coins, currencies, shares, voting weight, etc.
//Machine-based, rapid creation of many tokens would not necessarily need these extra features or will be minted in other manners.
//1) Initial Finite Supply (upon creation one specifies how much is minted).
//2) In the absence of a token registry: Optional Decimal, Symbol & Name.
//3) Optional approveAndCall() functionality to notify a contract if an approval() has occurred.
//.*/

import "./StandardToken.sol";
pragma solidity ^0.4.11;
contract HumanStandardToken is StandardToken {
    /* Public variables of the token */
    string public name;                   //名称: eg Simon Bucks
    uint8 public decimals;                //最多的小数位数How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It's like comparing 1 wei to 1 ether.
    string public symbol;                 //token简称: eg SBX
    string public version = 'H0.1';       //版本

    function HumanStandardToken(uint256 _initialAmount, string _tokenName, uint8 _decimalUnits, string _tokenSymbol) {
        balances[msg.sender] = _initialAmount; // 初始token数量给予消息发送者
        totalSupply = _initialAmount;         // 设置初始总量
        name = _tokenName;                   // token名称
        decimals = _decimalUnits;           // 小数位数
        symbol = _tokenSymbol;             // token简称
    }
    /* 同意转出并调用接收合约（根据自己需求实现） */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn't have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        
        require(_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }
}