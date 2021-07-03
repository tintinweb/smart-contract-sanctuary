/**
 *Submitted for verification at Etherscan.io on 2021-07-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//ERC20 Token Standard Interface
interface ERC20Interface {
    // function totalSupply() public view returns (uint256);

    // function balanceOf(address tokenOwner) public view returns (uint256 balance);

    // function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);

    function transfer(address to, uint256 tokens)
        external
        returns (bool success);

    function approve(address spender, uint256 tokens)
        external
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool success);

    //Transfer event - useful for consumers - part of erc20
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    //Approval event - useful for consumers-part of erc20
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}

//ERC20 Token
contract DappToken is ERC20Interface {
    string public name; //token_name
    string public symbol; //token_symbol
    uint256 public TotalSupply; //read the total no. of tokens with default getter

    mapping(address => uint256) public BalanceOf; //read token balance of specific address
    mapping(address => mapping(address => uint256)) public Allowance;

    //constructor func.
    constructor(uint256 _initialSupply) {
        name = "NKTOKEN"; //token_name
        symbol = "NK"; //token_symbol
        BalanceOf[msg.sender] = _initialSupply; //ref. above mapping
        TotalSupply = _initialSupply; //set total no. of tokens
    }
    function transfer(address _to, uint256 _value)
        public
        override
        returns (bool success)
    {
        //exception if account doesn't have enough tokens
        require(BalanceOf[msg.sender] >= _value);

        //Transfer balance
        BalanceOf[msg.sender] -= _value; //deduct the value from msg.sender
        BalanceOf[_to] += _value; //increase the value of the receiver

        //Transfer event
        emit Transfer(msg.sender, _to, _value);

        //returns a boolean
        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        override
        returns (bool success)
    {
        //update the allowance
        Allowance[msg.sender][_spender] = _value;

        //approve event
        emit Approval(msg.sender, _spender, _value);

        //returns a boolean
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override returns (bool success) {
        //_from has enough tokens i.e _value is always <= balanceOf[_from]
        require(_value <= BalanceOf[_from]);

        //require allowance is big enough to send tokens
        require(_value <= Allowance[_from][msg.sender]);

        //update the allowance
        Allowance[_from][msg.sender] -= _value;

        //change balance
        BalanceOf[_from] -= _value;
        BalanceOf[_to] += _value;

        //transfer event
        emit Transfer(_from, _to, _value);

        //returns a boolean
        return true;
    }
}