pragma solidity ^0.6.0;

import './SafeMath.sol';
import './ERC20Interface.sol';
import './Owned.sol';

contract BuildToken is ERC20Interface, Owned {
    using SafeMath for uint256;
    string public symbol = "BUILD";
    string public  name = "BUILD DAO";
    uint256 public decimals = 18;
    uint256 private maxCapSupply = 2000000 * 10**(decimals); // 1 million
    uint256 _totalSupply = 820000 * 10 ** (decimals); // 100,000
    address lego;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    constructor() public {
        balances[owner] = balances[owner].add(_totalSupply);
        emit Transfer(address(0),owner, _totalSupply);
    }
    
    function SetLego(address _address) external onlyOwner{
        require(_address != address(0), "Invalid address");
        lego = _address;
    }
    
    function MintTokens(uint256 _amount, address _beneficiary) public returns(bool){
        require(msg.sender == lego);
        require(_beneficiary != address(0), "Invalid address");
        require(_totalSupply.add(_amount) <= maxCapSupply, "exceeds max cap supply 2 million");
        _totalSupply = _totalSupply.add(_amount);
        
        balances[_beneficiary] = balances[_beneficiary].add(_amount);
        
        emit Transfer(address(0),_beneficiary, _amount);
        return true;
    }
    
    function BurnTokens(uint256 _amount) external {
        _burn(_amount, msg.sender);
    }

    function _burn(uint256 _amount, address _account) internal {
        require(balances[_account] >= _amount, "insufficient account balance");
        _totalSupply = _totalSupply.sub(_amount);
        balances[_account] = balances[_account].sub(_amount);
        emit Transfer(_account, address(0), _amount);
    }
    
    function totalSupply() public override view returns (uint256){
       return _totalSupply; 
    }
    
    function balanceOf(address tokenOwner) public override view returns (uint256 balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint256 tokens) public override returns  (bool success) {
        require(address(to) != address(0));
        require(balances[msg.sender] >= tokens );
        require(balances[to].add(tokens) >= balances[to]);
            
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender,to,tokens);
        return true;
    }

    function approve(address spender, uint256 value) public override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 tokens) public override returns (bool success){
        require(tokens <= allowed[from][msg.sender]); //check allowance
        require(balances[from] >= tokens);
        require(from != address(0), "Invalid address");
        require(to != address(0), "Invalid address");
        
        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        emit Transfer(from,to,tokens);
        return true;
    }
    
    function allowance(address tokenOwner, address spender) public override view returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }
    
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
}