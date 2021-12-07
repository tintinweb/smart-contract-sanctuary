/**
 *Submitted for verification at polygonscan.com on 2021-12-07
*/

pragma solidity >=0.7.0 <0.9.0;

contract Erc20Token {
    
    // token name
    string public name;

    // token symbol
    string public symbol;

    // token decemals
    uint public decimals;

    // the total supply of token
    uint256 public totalSupply;

    // contract owner
    address owner;

    mapping (address => uint256) public balanceOf;

    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed spender, uint256 value);
    
    constructor() {
        owner = msg.sender;
        name = "1024.finance";
        symbol = "1024";
        decimals = 18;
        totalSupply = 102400000000 * 10 ** 18;
        balanceOf[msg.sender] = totalSupply;
    }
    
    function _transfer(address _from, address _to, uint _value) internal {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(_spender, _value);
        return true;
    }

}