/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

pragma solidity ^0.5.1;

contract Token{
    using SafeMath for uint;
    string public name = "EthToken";
    string public symbol = "Eth";
    uint256 public decimal= 0;
    string public standard = "EthToken v1.0";
    uint256 public TotalSupply;
    
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
        );
        event Approve(
            address indexed _owner,
            address indexed _spender,
            uint256 value);
            
    mapping(address=> uint256) public balanceOf;
    mapping(address=>mapping(address=> uint256)) public allowance;
    constructor(uint256 _initialSupply) public{
        balanceOf[msg.sender] = _initialSupply;
        TotalSupply = _initialSupply;
    }
    function transfer(address _to, uint256 _value) public returns (bool success){
        require(balanceOf[msg.sender]>= _value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        emit Transfer(msg.sender, _to,_value);
        return true;
        }
        function approve(address _spender, uint256 _value) public returns (bool success){
         
         allowance[msg.sender][_spender] = _value;
         
         emit Approve(msg.sender, _spender, _value);
         return true;

        }
        function transferFrom(address _from, address _to, uint256 _value) public returns (bool){
            require(allowance[_from][msg.sender]>= _value, "allowance insufficient");
            require(balanceOf[_from]>= _value, "balance is insufficient");
            balanceOf[_to] = balanceOf[_to].add(_value);
            balanceOf[_from] = balanceOf[_from].sub(_value);
            emit Transfer(_from, _to, _value);
            allowance [_from][msg.sender]=  allowance [_from][msg.sender].sub(_value);
        }
        function allowed(address _owner, address _spender) public view returns(uint256){
            return allowance[_owner][_spender];
        }
        
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}