pragma solidity ^0.4.24;

contract BaseContract {
    bool public TokensAreFrozen = true;
    address public owner;

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyByOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) external onlyByOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract ERC20Contract is BaseContract {
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event BurnTokens(address indexed from, uint256 value);
    event FreezeTokensFrom(address indexed _owner);
    event UnfreezeTokensFrom(address indexed _owner);
}

library SafeMath {
    function Mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        return c;
    }

    function Sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function Add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint c = a + b;
        return c;
    }

    function Div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
}

contract Freedom is ERC20Contract {
    
    using SafeMath for uint256;

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowed;
    
    string public constant tokenName = "Freedom";
    string public constant tokenSymbol = "FREE";
    uint256 public totalSupply = 1000000000e8;
    uint8 public decimals = 8;

    constructor () public {
        balanceOf[msg.sender] = totalSupply;
        totalSupply = totalSupply;
        decimals = decimals;
    }

    modifier onlyPayloadSize(uint256 _size) {
        require(msg.data.length >= _size + 4);
        _;
    }

    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public returns (bool success) {
        require(!TokensAreFrozen);
        require(_to != 0x0);
        require(_value > 0);
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[msg.sender] = balanceOf[msg.sender].Sub(_value);
        balanceOf[_to] = balanceOf[_to].Add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(!TokensAreFrozen);
        require(_to != 0x0);
        require(_value > 0);
        require(balanceOf[_from] >= _value && allowance >= _value);
        balanceOf[_to]   = balanceOf[_to].Add(_value);
        balanceOf[_from] = balanceOf[_from].Sub(_value);
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] = allowed[_from][msg.sender].Sub(_value);
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balanceOf[_owner];
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(!TokensAreFrozen);
        require(_spender != address(0));
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function freezeTokens(address _owner) external onlyByOwner {
        require(TokensAreFrozen == false);
        TokensAreFrozen = true;
        emit FreezeTokensFrom(_owner);
    }
    
    function unfreezeTokens(address _owner) external onlyByOwner {
        require(TokensAreFrozen == true);
        TokensAreFrozen = false;
        emit UnfreezeTokensFrom(_owner);
    }
    
    function burnTokens(address _owner, uint256 _value) external onlyByOwner {
        require(!TokensAreFrozen);
        require(balanceOf[_owner] >= _value);
        balanceOf[_owner] -= _value;
        totalSupply -= _value;
        emit BurnTokens(_owner, _value);
    }
    
    function withdraw() external onlyByOwner {
        owner.transfer(address(this).balance);
    }
    
    function() payable public {
    }
}