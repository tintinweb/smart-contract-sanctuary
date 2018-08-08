pragma solidity ^0.4.24;
 // ----------------------------------------------------------------------------
 // Safe maths
 // ----------------------------------------------------------------------------
 library SafeMath {
     function add(uint a, uint b) internal pure returns (uint c) {
         c = a + b;
         require(c >= a);
     }
     function sub(uint a, uint b) internal pure returns (uint c) {
         require(b <= a);
         c = a - b;
     }
     function mul(uint a, uint b) internal pure returns (uint c) {
         c = a * b;
         require(a == 0 || c / a == b);
     }
     function div(uint a, uint b) internal pure returns (uint c) {
         require(b > 0);
         c = a / b;
     }
 }
 
 
 // ----------------------------------------------------------------------------
 // ERC Token Standard #20 Interface
 // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 // ----------------------------------------------------------------------------
 contract ERC20Interface {
     function totalSupply() public constant returns (uint);
     function balanceOf(address tokenOwner) public constant returns (uint balance);
     function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
     function transfer(address to, uint tokens) public returns (bool success);
     function approve(address spender, uint tokens) public returns (bool success);
     function transferFrom(address from, address to, uint tokens) public returns (bool success);
 
     event Transfer(address indexed from, address indexed to, uint tokens);
     event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
 }
 
 
 // ----------------------------------------------------------------------------
 // Contract function to receive approval and execute function in one call
 //
 // Borrowed from MiniMeToken
 // ----------------------------------------------------------------------------
 contract ApproveAndCallFallBack {
     function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
 }
 
 
 // ----------------------------------------------------------------------------
 // Owned contract
 // ----------------------------------------------------------------------------
 contract Owned {
     address public owner;
     address public newOwner;
 
     event OwnershipTransferred(address indexed _from, address indexed _to);
 
     constructor() public {
         owner = msg.sender;
     }
 
     modifier onlyOwner {
         require(msg.sender == owner);
         _;
     }
 
     function transferOwnership(address _newOwner) public onlyOwner {
         newOwner = _newOwner;
     }
     function acceptOwnership() public {
         require(msg.sender == newOwner);
         emit OwnershipTransferred(owner, newOwner);
         owner = newOwner;
         newOwner = address(0);
     }
 }
 
 
 // ----------------------------------------------------------------------------
 // ERC20 Token, with the addition of symbol, name and decimals and a
 // fixed supply
 // ----------------------------------------------------------------------------
 contract WFTToken is ERC20Interface, Owned {
     using SafeMath for uint;
 
     string public symbol;
     string public  name;
     uint8 public decimals;
     uint _totalSupply;
 
     mapping(address => uint) balances;
     mapping(address => mapping(address => uint)) allowed;
     mapping (address => uint256) public frozenAccount;
 
     // ------------------------------------------------------------------------
     // Constructor
     // ------------------------------------------------------------------------
     constructor() public {
         symbol = "WFT";
         name = "Wifi Chain Token";
         decimals = 8;
         _totalSupply = 10000000000 * 10**uint(decimals);
         balances[0xfd76e9d8b164f92fdd7dee579cf8ab94c7bf79c0] =  _totalSupply.mul(65).div(100);
         balances[0x96584a6da52efbb210a0ef8e2f89056c1b41eac2] = _totalSupply.mul(35).div(100);
         emit Transfer(address(0), owner, _totalSupply);
     }

     // ------------------------------------------------------------------------
     // Total supply
     // ------------------------------------------------------------------------
     function totalSupply() public view returns (uint) {
         return _totalSupply.sub(balances[address(0)]);
     }
 
 
     // ------------------------------------------------------------------------
     // Get the token balance for account `tokenOwner`
     // ------------------------------------------------------------------------
     function balanceOf(address tokenOwner) public view returns (uint balance) {
         return balances[tokenOwner];
     }
 
 
     // ------------------------------------------------------------------------
     // Transfer the balance from token owner&#39;s account to `to` account
     // - Owner&#39;s account must have sufficient balance to transfer
     // - 0 value transfers are allowed
     // ------------------------------------------------------------------------
     function transfer(address to, uint tokens) public returns (bool success) {
         require(frozenAccount[msg.sender] < now );
         balances[msg.sender] = balances[msg.sender].sub(tokens);
         balances[to] = balances[to].add(tokens);
         emit Transfer(msg.sender, to, tokens);
         return true;
     }
 
 
     // ------------------------------------------------------------------------
     // Token owner can approve for `spender` to transferFrom(...) `tokens`
     // from the token owner&#39;s account
     //
     // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
     // recommends that there are no checks for the approval double-spend attack
     // as this should be implemented in user interfaces 
     // ------------------------------------------------------------------------
     function approve(address spender, uint tokens) public returns (bool success) {
         allowed[msg.sender][spender] = tokens;
         emit Approval(msg.sender, spender, tokens);
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
     function transferFrom(address from, address to, uint tokens) public returns (bool success) {
         balances[from] = balances[from].sub(tokens);
         allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
         balances[to] = balances[to].add(tokens);
         emit Transfer(from, to, tokens);
         return true;
     }
 
 
     // ------------------------------------------------------------------------
     // Returns the amount of tokens approved by the owner that can be
     // transferred to the spender&#39;s account
     // ------------------------------------------------------------------------
     function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
         return allowed[tokenOwner][spender];
     }
 
 
     // ------------------------------------------------------------------------
     // Token owner can approve for `spender` to transferFrom(...) `tokens`
     // from the token owner&#39;s account. The `spender` contract function
     // `receiveApproval(...)` is then executed
     // ------------------------------------------------------------------------
     function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
         allowed[msg.sender][spender] = tokens;
         emit Approval(msg.sender, spender, tokens);
         ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
         return true;
     }
 
 
     // ------------------------------------------------------------------------
     // Don&#39;t accept ETH
     // ------------------------------------------------------------------------
     function () public payable {
         revert();
     }
 
 
     // ------------------------------------------------------------------------
     // Owner can transfer out any accidentally sent ERC20 tokens
     // ------------------------------------------------------------------------
     function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
         return ERC20Interface(tokenAddress).transfer(owner, tokens);
     }

    
    //freeze account
    function freezeWithTimestamp(address target,uint256 timestamp)public onlyOwner returns (bool) {
        frozenAccount[target] = timestamp;
        return true;
    }
    
     //multi freeze account
    function multiFreezeWithTimestamp(address[] targets,uint256[] timestamps)public onlyOwner returns (bool) {
        uint256 len = targets.length;
        require(len > 0);
        require(len == timestamps.length);
        for (uint256 i = 0; i < len; i = i.add(1)) {
            frozenAccount[targets[i]] = timestamps[i];
        }
        return true;
    }

 }