/**
 *Submitted for verification at Etherscan.io on 2021-10-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;


contract assignmentToken {
    
    uint256 constant MAXSUPPLY = 1000000;
    uint256 constant fee = 1; //defining the flat transfer fee
    address public minter; 
    uint256 private supply; 

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    event MintershipTransfer(
        address indexed previousMinter,
        address indexed newMinter
    );

    mapping (address => uint256) public balances;
    mapping (address => mapping(address => uint256)) public allowances;

    // Initializing the state of minter and supply, and sets the balance of the sender equal to supply
    constructor() {
        minter = msg.sender;
        supply = 50000;
        balances[msg.sender] = supply;
    }

    function totalSupply() public view returns (uint256) {
        return supply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function mint(address receiver, uint256 amount) public returns (bool) {
        require(supply + amount <= MAXSUPPLY);
        require(minter == msg.sender);
        balances[receiver] += amount;
        supply += amount;

        return true;
    }

    //assuming everyone can burn tokens from their own account
    function burn(uint256 amount) public returns (bool) {

        require(amount <= balances[msg.sender]);
        require(supply - amount >= 0); //to ensure supply does not go negative
        supply -= amount; 
        balances[msg.sender] -= amount; 
        emit Transfer(msg.sender, address(0), amount);

        return true;
    }

    function transferMintership(address newMinter) public returns (bool) {

        require(msg.sender == minter);
        minter = newMinter; 
        emit MintershipTransfer(msg.sender, newMinter);

        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {

        require(balances[msg.sender] >= _value);
        require(_value >= fee);
        balances[msg.sender] -= _value;
        balances[_to] += (_value - fee);
        balances[minter] += fee;
        emit Transfer(msg.sender, _to, (_value - fee));
        emit Transfer(msg.sender, minter, fee);

        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {

        require(balances[_from] >= _value);
        require(allowances[_from][msg.sender] >= _value);
        require(_value >= fee);
        balances[_from] -= _value;
        balances[_to] += (_value - fee);
        balances[minter] += fee;
        allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, (_value-fee));
        emit Transfer(_from, minter, fee);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        return allowances[_owner][_spender];
    }
}