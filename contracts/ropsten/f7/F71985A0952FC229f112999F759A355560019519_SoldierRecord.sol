/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

// TODO: consider implementing solidity's safeMath to avoid integer overflow vulnerabilities

// This will be the ERC-20 compliant digital instance of a soldier's training record; all data for a specific soldier's range testing should go here
contract SoldierRecord {
    // Upon deployment, assign all specified number of tokens to contract owner
    uint256 totalSupply_;

    constructor(uint256 _total) {
        totalSupply_ = _total;
        balances[msg.sender] = totalSupply_;
    }

    // MUST trigger when tokens are transferred, including zero value transfers.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    // MUST trigger on any successful call to approve().
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    // Returns the name of the token - e.g. "MyToken".
    function name() public pure returns (string memory) {
        return "TRACRChain soldier";
    }

    // Returns the symbol of the token. E.g. “HIX”.
    function symbol() public pure returns (string memory) {
        return "TRACR";
    }

    // Returns the number of decimals the token uses - e.g. 8, means to divide the token amount by 100,000,000 to get its user representation.
    function decimals() public pure returns (uint8) {
        return 0;
    }

    // Returns the total token supply.
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    // Returns the account balance of another account with address _owner.
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    // Transfers _value amount of tokens to address _to.
    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        require(_value <= balances[msg.sender]);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // Transfers _value amount of tokens from address _from to address _to.
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] -= _value;
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    // Allows _spender to withdraw from your account multiple times, up to the _value amount.
    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // Returns the amount which _spender is still allowed to withdraw from _owner.
    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }
}