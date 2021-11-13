/**
 *Submitted for verification at BscScan.com on 2021-11-13
*/

pragma solidity ^0.5.0;

contract TANETH{
    string public name;
    string  public symbol;
    uint256 public totalSupply;
    uint8   public decimals;
    address public tax_wallet;
    
    event Transfer(
        address indexed _from,
        address indexed _to, 
        uint _value
    );
    
    event Burn(
        address indexed _from,
        uint _value
    );
    
    event Approval(
        address indexed _owner,
        address indexed _spender, 
        uint _value
    );
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    constructor() public {
        name="TANETH";
        symbol="EARTH2";
        totalSupply = 1000000000*10**18;//1 billion coins
        decimals = 18;
        tax_wallet=0xc69103431D8Be8D7CF348E918ea90d3867B37c49;
        balanceOf[tax_wallet] = totalSupply;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        // require that the value is greater or equal for transfer
        require(balanceOf[msg.sender] >= _value);
        // add the balance
        balanceOf[_to] += _value;
        // transfer the amount and subtract the balance
        balanceOf[msg.sender] -= _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function burn(uint256 _value) public returns (bool success){
        require(balanceOf[msg.sender] >= _value);
        require(msg.sender==tax_wallet);
        balanceOf[tax_wallet]-=_value;
        totalSupply-=_value;
        emit Burn(tax_wallet,_value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value<= balanceOf[_from]);
        require(_value<= allowance[_from][msg.sender]);
        // add the balance for transferFrom
        balanceOf[_to] += _value;
        // subtract the balance for transferFrom
        balanceOf[_from] -= _value;
        allowance[msg.sender][_from] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}