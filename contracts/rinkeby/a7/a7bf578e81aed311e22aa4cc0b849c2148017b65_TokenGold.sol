/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >0.4.2;

contract TokenGold {
    string  public name = "Token Gold";
    string  public symbol = "GLD";
    uint8 public decimals = 18;
    address public owner;
    uint256 public totalSupply;

    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public frozenAccount;
    // Events
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    event Burn(
        address indexed from, 
        uint256 value
        );


    event Frozen(
        address indexed _add, 
        bool _froz);
    // modifier

    modifier onlyOwner {
      require(msg.sender == owner);
      _;
   }

    constructor (uint256 _initialSupply) public {
        owner = msg.sender;
        balanceOf[msg.sender] = _initialSupply;
        totalSupply = _initialSupply;
    }

    // transfer
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(!frozenAccount[msg.sender]);

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        require(!frozenAccount[msg.sender]);

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }


    // Burn 
    function burn(uint256 _value) public returns (bool success){
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender,_value);
        return true;
    }


    function burnFrom(address _From,uint256 _value) public returns (bool success){
        require(balanceOf[_From] >= _value);
        require(allowance[_From][msg.sender] >= _value);
        balanceOf[_From] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender,_value);
        return true;
    }

    // Mint

    function mint(address _target,uint256 _mintedAmount) public onlyOwner {
        balanceOf[_target] += _mintedAmount;
        totalSupply += _mintedAmount; 
    }

    //Frozen
    function frozen(address _add) public onlyOwner{
        frozenAccount[_add] = true;
        emit Frozen(_add,true);
    }

}