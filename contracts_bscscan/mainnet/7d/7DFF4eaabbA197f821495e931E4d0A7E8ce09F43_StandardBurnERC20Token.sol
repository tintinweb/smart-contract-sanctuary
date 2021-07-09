/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-03
*/

pragma solidity ^0.5.10;


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


contract StandardBurnERC20Token {
    using SafeMath for uint256;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);


    uint256 public totalSupply;
    string public name;
    uint8 public decimals;
    string public symbol;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) _allowances;


    constructor(string memory _tokenName, string memory _tokenSymbol, uint8 _decimalUnits, uint256 _initialAmount) public {
        totalSupply = _initialAmount * 10 ** uint256(_decimalUnits);
        balances[msg.sender] = totalSupply;
        name = _tokenName;
        decimals = _decimalUnits;
        symbol = _tokenSymbol;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns
    (bool success) {
        require(_allowances[_from][msg.sender] >= _value, "ERC20: transferFrom amount exceeds allowance");
        _transfer(_from, _to, _value);
        _allowances[_from][msg.sender] = _allowances[_from][msg.sender].sub(_value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(balances[_from] >= _value, "ERC20: transfer amount exceeds balance");
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }


    function approve(address _spender, uint256 _value) public returns (bool success)
    {
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return _allowances[_owner][_spender];
    }

    function _burn(address _from, uint256 _value) internal {
        require(balances[_from] >= _value, "ERC20: burn amount exceeds balance");
        balances[_from] = balances[_from].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Transfer(_from, address(0), _value);
    }

    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }

    function burnFrom(address _from, uint256 _value) public {
        require(_allowances[_from][msg.sender] >= _value, "ERC20: burn amount exceeds allowance");
        _burn(msg.sender, _value);
        _allowances[_from][msg.sender] = _allowances[_from][msg.sender].sub(_value);
        emit Transfer(_from, address(0), _value);
    }


    function transferArray(address[] memory _to, uint256[] memory _value) public {
        require(_to.length == _value.length);
        uint256 sum = 0;
        for (uint256 i = 0; i < _value.length; i++) {
            sum = sum.add(_value[i]);
        }
        require(balances[msg.sender] >= sum);
        for (uint256 k = 0; k < _to.length; k++) {
            _transfer(msg.sender, _to[k], _value[k]);
        }
    }

}