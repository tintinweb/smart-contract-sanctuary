pragma solidity ^ 0.6.3;

import "./cubbyToken.sol";

contract CubCoin is CubbyToken{

    string public name;
    uint8 public decimals;
    string public symbol;
    uint256 public unitsOneEthCanBuy;
    uint256 public totalRaisedEthInWei;
    address payable public owner;


    constructor() public{
        decimals = 18;
        _totalSupply = 10000000000000000000000;
        _balances[msg.sender]= _totalSupply;
        name = "Cubby Coin";
        symbol = "CUB";
        unitsOneEthCanBuy = 100;
        owner = msg.sender;
    }

    receive() external payable{
        totalRaisedEthInWei = totalRaisedEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        require(_balances[owner] >= amount);
        _balances[owner] -= amount;
        _balances[msg.sender] += amount;
        Transfer(owner, msg.sender, amount);
        owner.transfer(msg.value);
    }


}