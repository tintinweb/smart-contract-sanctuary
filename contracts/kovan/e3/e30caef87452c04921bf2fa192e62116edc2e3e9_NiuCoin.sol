/**
 *Submitted for verification at Etherscan.io on 2021-08-19
*/

pragma solidity >=0.7.0 <0.9.0;

contract NiuCoin {
    mapping(address => uint256) balances;
    
    constructor(uint256 initalSupply) {
        balances[msg.sender] = initalSupply;
    }
    
    event Transfer(uint256 srcChain, uint256 dstChain, address indexed from, address indexed to, uint256 indexed value);
    
    function transfer(uint256 srcChain, uint256 dstChain, address from, address to, uint256 value) public returns(bool isSuccess) {
        require(balances[from] >= value);
        require(balances[to] + value >= balances[to]);
        
        uint256 previousBalances = balances[from] + balances[to];
        balances[from] -= value;
        balances[to] += value;
        
        assert(balances[from] + balances[to] == previousBalances);
        emit Transfer(srcChain, dstChain, from, to, value);
        return true;
    }
    
    function getBalance(address target) public view returns(uint256) {
       return  balances[target];
    }
}