/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

contract SuikoToken {
    
    uint public totalSupply;
    string public name;
    string public symbol;
    uint public decimals = 18;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowence;

    event Transfer(address indexed _from, address indexed _to, uint tokens);
    event Approval(address indexed _tokenOwner, address indexed _spender, uint tokens);

    constructor(string memory tokenName, string memory tokenSymbol, uint initialSupply) {
        totalSupply = initialSupply*10**uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
    }

    function _transfer (address _from, address _to, uint256 _value) internal{
        require(_to != address(0x0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

    function transfer (address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowence[_from][msg.sender]);
        allowence[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowence[msg.sender][_spender] = _value;
        emit Approval (msg.sender, _spender, _value);
        return true;
    }

    
}

contract owned {
     address owner;

    constructor ()  {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership (address newOwner) onlyOwner external {
        owner = newOwner;
    }
}