//SourceUnit: ltt_erc20.sol

/**
 *Submitted for verification at Etherscan.io on 2020-04-17
*/


pragma solidity ^0.4.24;

contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        _assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        _assert(b > 0);
        uint256 c = a / b;
        _assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        _assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        _assert(c >= a && c >= b);
        return c;
    }

    function _assert(bool assertion) internal pure {
        if (!assertion) {
            revert();
        }
    }
}

contract LTT is SafeMath {
    string public name = "LiteToken";
    string public symbol = "LTT";
    uint8 constant public decimals = 8;
    mapping(address => uint256)  _balances;
    mapping(address => mapping(address => uint256)) public _allowed;

    uint256  public totalSupply = 21000000 * 100000000;


    constructor () public{
        _balances[msg.sender] = totalSupply;
        emit Transfer(0x0, msg.sender, totalSupply);
    }

    function balanceOf(address addr) public view returns (uint256) {
        return _balances[addr];
    }


    function transfer(address _to, uint256 _value)  public returns (bool) {
//        require(_to != address(0));
        if (_to == address(0)) {
            return burn(_value);
        } else {
            require(_balances[msg.sender] >= _value && _value > 0);
            require(_balances[_to] + _value >= _balances[_to]);

            _balances[msg.sender] = safeSub(_balances[msg.sender], _value);
            _balances[_to] = safeAdd(_balances[_to], _value);
            emit Transfer(msg.sender, _to, _value);
            return true;
        }
    }

    function burn(uint256 _value) public returns (bool) {
        require(_balances[msg.sender] >= _value && _value > 0);
        require(totalSupply >= _value);
        _balances[msg.sender] = safeSub(_balances[msg.sender], _value);
        totalSupply = safeSub(totalSupply, _value);
        emit Burn(msg.sender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value)  public returns (bool) {
        require(_to != address(0));
        require(_balances[_from] >= _value && _value > 0);
        require(_balances[_to] + _value >= _balances[_to]);

        require(_allowed[_from][msg.sender] >= _value);

        _balances[_to] = safeAdd(_balances[_to], _value);
        _balances[_from] = safeSub(_balances[_from], _value);
        _allowed[_from][msg.sender] = safeSub(_allowed[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address spender, uint256 value)  public returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address _master, address _spender) public view returns (uint256) {
        return _allowed[_master][_spender];
    }

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Transfer(address indexed _from, address indexed _to, uint256 value);
    event Burn(address indexed _from, uint256 value);
}