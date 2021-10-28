/**
 *Submitted for verification at BscScan.com on 2021-10-28
*/

/**
 *Submitted for verification at hecoinfo.com on 2021-08-31
*/

pragma solidity 0.6.6;



/*  ERC 20 token */
contract StandardToken{
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    function transfer(address _to, uint _amount) external returns (bool success) {
        require(balances[msg.sender] >= _amount,"transfer:The called function should be payable if you send value and the value you send should be less than your current balance");
        balances[msg.sender] = balances[msg.sender] - _amount;
        balances[_to] = balances[_to] + _amount;
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount)  external returns (bool success) {
        require(balances[_from] >= _amount,"transferFrom:The called function should be payable if you send value and the value you send should be less than your current balance");
        require(allowed[_from][msg.sender] >= _amount,"transferFrom:Insufficient available quantity allowed");
        balances[_to] = balances[_to] + _amount;
        balances[_from] = balances[_from] - _amount;
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }

    function approve(address _spender, uint256 _value)external returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)external view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    function withdraw()external {
        require(owner == msg.sender,"withdraw:This function can only be called by the contract owner");
        owner.transfer(address(this).balance);
    }

    receive() external  payable{
    }

    function balanceOf(address _owner)external view returns (uint256 balance) {
        return balances[_owner];
    }

    uint256 public  totalSupply;
    string public name;
    string public symbol;
    uint constant public decimals = 18;
    address payable public owner;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    constructor (uint _totalAmount,string memory _name,string memory _symbol) payable public{
        symbol = _symbol;
        name = _name;
        totalSupply =  _totalAmount * 10**uint256(decimals);
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
}