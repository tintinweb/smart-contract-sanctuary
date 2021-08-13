/**
 *Submitted for verification at Etherscan.io on 2021-08-13
*/

pragma solidity >=0.7.0 <0.9.0;

contract SueToken {
    uint256 totalSupply_;
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    constructor(uint256 total) {
       totalSupply_ = total;
       balances[msg.sender] = totalSupply_;
    }
    
    function totalSupply() public view returns(uint256) {
        return totalSupply_;
    }
    
    function balanceOf(address addr) public view returns(uint256) {
        return balances[addr];
    }
    
    function transfer(address dst, uint256 amount) public returns(bool) {
        require(amount <= balances[msg.sender]);
        balances[msg.sender] -= amount;
        balances[dst] += amount;
        return true;
    }
}