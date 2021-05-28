pragma solidity ^0.8.4;

import "./SafeMath.sol";
import "./IERC20.sol";

contract EmToken is IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowed;
    uint256 _totalSupply;
    
    string public name;
    string public symbol;
    uint8  public decimals;

    constructor(uint256 _initialAmount, string memory tokenName, uint8 _decimalUnits, string memory tokenSymbol)
    {
        _balances[msg.sender] = _initialAmount;
        _totalSupply = _initialAmount;
        name = tokenName;
        decimals = _decimalUnits;
        symbol = tokenSymbol;
        
    }

    function totalSupply() public view override returns(uint256)
    {
      return _totalSupply;
    }

    function balanceOf(address addr) public view override returns(uint256)
    {
        return _balances[addr];
    }

    function allowance(address owner, address spender) public view override returns(uint256)
    {
        return _allowed[owner][spender];
    }

    function transfer(address to, uint256 amount) public override returns(bool)
    {
        require(_balances[msg.sender] >= amount);
        require(to != address(0));

        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _balances[to] = _balances[to].add(amount);

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 value) override public returns(bool)
    {
        require(spender != address(0));
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) override public returns(bool)
    {
        require(_balances[from] >= value);
        require(_allowed[from][msg.sender] >= value);
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

        emit Transfer(from, to, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns(bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns(bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

}