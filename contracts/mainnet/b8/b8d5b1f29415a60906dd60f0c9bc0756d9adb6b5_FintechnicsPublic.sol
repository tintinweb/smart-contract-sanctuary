pragma solidity ^0.4.21;

library SafeMath256 {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
          return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// github.com/ethereum/EIPs/issues/223
contract ERC223 {
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    function transfer(address _to, uint256 _value) public;
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract FintechnicsPublic is ERC223 {
    using SafeMath256 for uint256;

    string public constant name = "Fintechnics Public";
    string public constant symbol = "FINTP";
    uint256 public constant decimals = 18;
    uint256 public totalSupply = 150000000 * 10**decimals;
    address public owner = address(0);
    mapping (address => uint256) public balanceOf;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function isContract(address _addr) internal view returns (bool is_contract) {
        uint256 length;
        assembly { length := extcodesize(_addr) }
        return length > 0;
    }

    function mint(uint256 _value) public onlyOwner {
        balanceOf[msg.sender] = balanceOf[msg.sender].add(_value);
        totalSupply = totalSupply.add(_value);
        emit Transfer(address(0), owner, _value);
    }

    function burn(uint256 _value) public onlyOwner {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Transfer(msg.sender, address(0), _value);
    }

    function transfer(address _to, uint256 _value) public {
        require(!isContract(_to) && msg.sender != _to && balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
    }

    function FintechnicsPublic() public {
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }
}