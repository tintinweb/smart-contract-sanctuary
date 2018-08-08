pragma solidity ^0.4.18;

contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public returns (bool){
        require(newOwner != 0x0);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        return true;
    }
}

library SafeMath {
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(a >= b);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
}

contract tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}

contract ERC20 {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function ERC20(
        uint256 initialSupply
    ) public {
        totalSupply = initialSupply;
        balanceOf[msg.sender] = totalSupply;
        Transfer(0x0, msg.sender, totalSupply);
    }

    function _transfer(address _from, address _to, uint _value) internal returns (bool){
        require(_to != 0x0);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        Transfer(_from, _to, _value);
	    return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool){
        _transfer(msg.sender, _to, _value);
	    return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
	    return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool){
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool){
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
	        return true;
        }
    }
}

contract EPVToken is Owned, ERC20 {

    string public name = "EPVToken";
    string public symbol = "EPV";
    uint8 public decimals = 18;
    uint256 public INITIAL_SUPPLY = 100000000000 * (10 ** uint256(decimals));

    function EPVToken() ERC20(INITIAL_SUPPLY) public {}

    function () payable public {

    }

    function backToken(address _to, uint256 _value) onlyOwner public returns (bool){
        _transfer(this, _to, _value);
	    return true;
    }

    function backTransfer(address _to, uint256 _value) onlyOwner public returns (bool){
        require(_to != 0x0);
        require(address(this).balance >= _value);
        _to.transfer(_value);
	    return true;
    }
}