pragma solidity ^0.4.24;
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(
        address indexed _from, 
        address indexed _to, 
        uint256 _value
    );
} 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) balances;
    uint256 totalSupply_;
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

}
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
        public view returns (uint256);
    function transferFrom(address from, address to, uint256 value)
        public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(
      address indexed _owner,
      address indexed _spender,
      uint256 _value
    );
}
contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) internal allowed;
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    function approve(address _spender, uint256 _value) public returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0), "reset allowance to 0 before change it's value.");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function allowance(
        address _owner,
        address _spender
    )
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender]; 
    } 
} 
contract BitPlatinum_Token is StandardToken { 
    string public name;                         
    string public symbol;            
    uint8 public decimals;      
    uint256 public claimAmount;
    constructor(
        string _token_name, 
        string _symbol, 
        uint256 _claim_amount, 
        uint8 _decimals
    ) public {
        name = _token_name;                              
        symbol = _symbol;     
        claimAmount = _claim_amount;                                     
        decimals = _decimals;
        totalSupply_ = claimAmount.mul(10 ** uint256(decimals)); 
        balances[msg.sender] = totalSupply_;   
        emit Transfer(0x0, msg.sender, totalSupply_); 
    }
}