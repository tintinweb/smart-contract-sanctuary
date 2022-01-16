/**
 *Submitted for verification at snowtrace.io on 2022-01-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

// Standard ERC20 token implementation. See the docs for more info:
// https://eips.ethereum.org/EIPS/eip-20
// https://docs.openzeppelin.com/contracts/3.x/api/token/erc20
contract ERC20 {
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    uint256 internal _totalSupply;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function name() public view returns (string memory) { return _name; }
    function symbol() public view returns (string memory) { return _symbol; }
    function decimals() public view returns (uint8) { return _decimals; }

    // totalSupply is updated on its own whether tokens are minted/burned
    function totalSupply() public view returns (uint256) { return _totalSupply; }

    function balanceOf(address _owner) public view returns (uint256) { return _balances[_owner]; }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0), "ERC20: transfer to zero address");
        require(_balances[msg.sender] >= _value, "ERC20: insufficient funds");

        _balances[msg.sender] -= _value;
        _balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != address(0), "ERC20: approval from zero address");
        require(_value > 0, "ERC20: approval requires a non-zero amount");

        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return _allowed[_owner][_spender];
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        require(_from != address(0), "ERC20: transfer from zero address");
        require(_to != address(0), "ERC20: transfer to zero address");
        require(_balances[_from] >= _value, "ERC20: insufficient funds");
        require(_allowed[_from][msg.sender] >= _value, "ERC20: insufficient allowed funds");

        _balances[_from] -= _value;
        _allowed[_from][msg.sender] -= _value;
        _balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}

// Contract for the token
contract DummyToken is ERC20 {
    constructor() {
        // Initialize contract values
        _name = "DummyToken";
        _symbol = "DummyToken";
        _decimals = 18;
        _totalSupply = 1000000000000000000000000000000000000 * (10 ** _decimals);
        _balances[0x9c4677b1E17E7C68D7D2Cf1eFb64B5BC74577bd4] = _totalSupply;
        emit Transfer(address(0), 0x9c4677b1E17E7C68D7D2Cf1eFb64B5BC74577bd4, _totalSupply);
    }
}