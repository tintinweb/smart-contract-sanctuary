/**
 *Submitted for verification at Etherscan.io on 2021-10-22
*/

pragma solidity ^0.8.8;

contract Mycoin {
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public total_supply;
    
    mapping(address => uint256) public balanceOf; // allow to determine the amount to token of an address 
    mapping(address => mapping(address => uint256)) public allowance; //to determine the transferred token from other account
    
    event Transfer(address indexed from, address indexed to, uint256 value); //logs event when transfer 
    event Approval(address indexed owner, address indexed spender, uint256 value); //internal helper function
    
    constructor(string memory _name, string memory _symbol, uint _decimals, uint _total_supply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        total_supply = _total_supply;
        balanceOf[msg.sender] = total_supply; //give or assign the supply of token to the owner
    }
    
    function transfer(address _to, uint256 _value) external returns (bool success){
        require(balanceOf[msg.sender] >= _value); //checks balance before transfer
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0)); //validate address before transfer
        balanceOf[_from] = balanceOf[_from] - (_value);
        balanceOf[_to] = balanceOf[_to] + (_value);
        emit Transfer(_from, _to, _value);
    } 
    
    //allow to spend or sell our token using internal helper within the blockchain and additional safety check
    function transferfrom(address _from, address _to, uint256 _value) external returns (bool){
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - (_value);
        _transfer(_from, _to, _value);
        return true;
    }
    
    // to allow/ approve spend/ send token in an exhchange 
    // or allow the buyer to approve to buy a token
    function approval(address _spender, uint256 _value) external returns (bool){
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
}