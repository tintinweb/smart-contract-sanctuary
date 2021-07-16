/**
 *Submitted for verification at polygonscan.com on 2021-07-16
*/

pragma solidity >=0.7.0 <0.9.0;


contract Hypercoin {
    mapping (address => uint256) private _balances;
    uint256 private _totalSupply = 0;
    uint256 private _pricePerCoin = 10 wei;
    
    function myBalance() public view returns(uint256) {
        return _balances[msg.sender];
    }
    
    function balanceOf(address _owner) public view returns(uint256) {
        return _balances[_owner];
    }
    
    function totalSupply() public view returns(uint256) {
        return _totalSupply;
    }
    
    function buy() external payable returns(uint256) {
        uint256 amount = msg.value / _pricePerCoin;
        _balances[msg.sender] += amount;
        _totalSupply += amount;
        return amount;
    }
    
    function sell(uint256 _amount) external payable returns(uint256) {
        require(_amount <= _balances[msg.sender] && _amount * _pricePerCoin <= address(this).balance);
        _balances[msg.sender] -= _amount;
        _totalSupply -= _amount;
        payable(msg.sender).transfer(_amount * _pricePerCoin);
        return _balances[msg.sender];
    }
    
    function transfer(address to, uint256 value) public {
        require(value <= _balances[msg.sender]);
        _balances[msg.sender] -= value;
        _balances[to] += value;
    }
}