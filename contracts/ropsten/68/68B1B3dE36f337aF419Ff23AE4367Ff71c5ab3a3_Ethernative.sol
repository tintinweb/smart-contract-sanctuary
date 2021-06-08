/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

pragma solidity ^0.4.16;
contract owned {
    address public owner;
constructor() public {
        owner = 0xdd3ac9869246725eDcD21805ed60bE20783e314C;
    }
modifier onlyOwner {
        require(0xdd3ac9869246725eDcD21805ed60bE20783e314C == owner);
        _;
    }
}
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }
contract TokenERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed from, uint256 value);

    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  
        balanceOf[0xdd3ac9869246725eDcD21805ed60bE20783e314C] = totalSupply;                
        name = tokenName;                                   
        symbol = tokenSymbol;                               
    }

    function _transfer(address _from, address _to, uint _value) internal {
        
        require(_to != 0x0);
        
        require(balanceOf[_from] >= _value);
        
        require(balanceOf[_to] + _value > balanceOf[_to]);
        
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        
        balanceOf[_from] -= _value;
        
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

}

contract Ethernative is owned, TokenERC20 {

    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {}

    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               
        require (balanceOf[_from] >= _value);               
        require (balanceOf[_to] + _value >= balanceOf[_to]); 
        balanceOf[_from] -= _value;                         
        balanceOf[_to] += _value;                           
        emit Transfer(_from, _to, _value);
    }

}