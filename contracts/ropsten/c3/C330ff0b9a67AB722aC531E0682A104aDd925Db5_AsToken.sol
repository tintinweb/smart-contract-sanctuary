/**
 *Submitted for verification at Etherscan.io on 2021-10-08
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract AsToken {
    
    string public name;
    string public symbol;
    string public version;

    // how much there will be total tokens
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    // events 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    
    constructor(string memory _name,string memory _symbol,string memory _version ,uint256 _totalSupply) public {
        name = _name;
        symbol = _symbol;
        version = _version;

        // adding all balance to deployer
        balanceOf[msg.sender] = _totalSupply;
        totalSupply = _totalSupply;

    }

    // transfer tokens
    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        require(balanceOf[msg.sender] >= _value);

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        // transfer event
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // approve funtion for token transfer
    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        // allowance
        allowance[msg.sender][_spender] = _value;
        //approve event
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        // Require _from has enough tokens
        require(_value <= balanceOf[_from]);
        //Require allowance is big enough
        require(_value <= allowance[_from][msg.sender]);
        // change the balance
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        // update the allowance
        allowance[_from][msg.sender] -= _value;
        // transfer event
        emit Transfer(_from, _to, _value);
        // return boolean
        return true;
    }
}