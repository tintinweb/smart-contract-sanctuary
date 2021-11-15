// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract ERC20 {

    uint256 totalSupply_;

    mapping (address => uint256) balances;
    mapping (address => mapping(address => uint256)) allowed;

    constructor (uint256 total) {
        totalSupply_ = total;
        balances[msg.sender] = totalSupply_;
    }

    event Transfer(address indexed _from, address indexed _to, uint tokens);
    event Approval(address indexed _tokenOwner, address indexed _spender, uint _tokens);


    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address _tokenOwner) public view returns (uint256) {
        return balances[_tokenOwner];
    }

    function allowance(address _tokenOwner, address _spender) public view returns (uint256) {
        return allowed[_tokenOwner][_spender];
    }

    function _transfer(address _from, address _to, uint256 _amount) internal {
        require(_amount <= balances[_from]);
        balances[_from] = balances[_from] - _amount;
        balances[_to] = balances[_to] + _amount;
        emit Transfer(_from, _to, _amount);
    }

    function _approve(address _owner, address _spender, uint256 _amount) internal {
        require(_spender != address(0), "Approve to zero address");
        allowed[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function transfer(address _receiver, uint256 _numTokens) public returns (bool) {
        _transfer(msg.sender, _receiver, _numTokens);
        return true;
    }

    function approve(address _spender, uint256 _numTokens) public returns (bool) {
        _approve(msg.sender, _spender, _numTokens);
        return true;
    }

    function transferFrom(address _sender, address _receiver, uint256 _amount) public returns (bool) {
        uint256 currentAllowance = allowed[_sender][_receiver];
        require(currentAllowance >= _amount, "Not allowed");
        _transfer(_sender, _receiver, _amount);
        _approve(_sender, _receiver, currentAllowance - _amount);
        return true;
    }

}

