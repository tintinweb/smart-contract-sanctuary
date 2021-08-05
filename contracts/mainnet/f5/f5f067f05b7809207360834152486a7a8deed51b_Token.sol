pragma solidity ^0.6.0;

// ----------------------------------------------------------------------------
// 'Maverick' token contract

// Symbol      : Maverick
// Name        : MAV
// Total supply: 21,000,000,000 (21 billion)
// Decimals    : 2
// ----------------------------------------------------------------------------

import './SafeMath.sol';
import './ERC20contract.sol';
import './Owned.sol';

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract Token is ERC20Interface, Owned {
    using SafeMath for uint256;
    string public symbol = "MAV";
    string public  name = "Maverick";
    uint256 public decimals = 2;
    uint256 _totalSupply = 21e9* 10 ** (decimals); 
    uint256 soldTokens;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        owner = 0x93aD29093C3EdE3fa10188cee35d07dfe91A65b9;
        balances[address(this)] = totalSupply();
        
        emit Transfer(address(0),address(this), totalSupply());
    }
    
    receive() external payable{
        // receive ethers
        require(msg.value >= 0.01 ether);
        uint tokens = getTokenAmount(msg.value);
        _transfer(msg.sender, tokens);
        // send received funds to the owner
        owner.transfer(msg.value);
    }
    
    function getTokenAmount(uint256 amount) internal pure returns(uint256){
        return (amount*200000)/1e18;
    }
    
    /** ERC20Interface function's implementation **/
    
    function totalSupply() public override view returns (uint256){
       return _totalSupply; 
    }
    
    function totalTokensSold() public view returns(uint256){
        return soldTokens;
    }
    
    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public override view returns (uint256 balance) {
        return balances[tokenOwner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint256 tokens) public override returns (bool success) {
        // prevent transfer to 0x0, use burn instead
        require(address(to) != address(0));
        require(balances[msg.sender] >= tokens );
        require(balances[to] + tokens >= balances[to]);
            
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender,to,tokens);
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    // ------------------------------------------------------------------------
    function approve(address spender, uint256 tokens) public override returns (bool success){
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender,spender,tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint256 tokens) public override returns (bool success){
        require(tokens <= allowed[from][msg.sender]); //check allowance
        require(balances[from] >= tokens);
            
        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        emit Transfer(from,to,tokens);
        return true;
    }
    
    function donations(address to, uint256 tokens) public onlyOwner {
        _transfer(to, tokens);
    }
    
    function _transfer(address to, uint256 tokens) internal {
        // prevent transfer to 0x0, use burn instead
        require(address(to) != address(0));
        require(balances[address(this)] >= tokens );
        require(balances[to] + tokens >= balances[to]);
            
        balances[address(this)] = balances[address(this)].sub(tokens);
        balances[to] = balances[to].add(tokens);
        soldTokens += tokens;
        emit Transfer(address(this),to,tokens);
    }
    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public override view returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }
    
    // ------------------------------------------------------------------------
    // Burn the ``value` amount of tokens from the `account`
    // ------------------------------------------------------------------------
    function burnTokens(uint256 value) public onlyOwner {
        _burn(value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * @param value The amount that will be burnt.
     */
    function _burn(uint256 value) internal {
        require(_totalSupply - soldTokens >= value); // burn only unsold tokens
        _totalSupply = _totalSupply.sub(value);
        balances[address(this)] = balances[address(this)].sub(value);
        emit Transfer(address(this), address(0), value);
    }
}