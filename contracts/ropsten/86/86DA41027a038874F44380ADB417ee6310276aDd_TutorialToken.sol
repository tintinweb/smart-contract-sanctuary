/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

pragma solidity ^0.5.16;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address from, address to, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    function mint(address to, uint256 tokens) public returns(bool);


    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
// contract ApproveAndCallFallBack {
//     function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
// }


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract TutorialToken is ERC20Interface, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint private _totalSupply;
    address public owner;
    // bool private permissionOwner;
    // bool private permissionUser;
    address[] newOwner;
    address[] mintPermissionAddress;
    
    mapping(address => bool) private minters;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
  


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public{
        symbol = "SFR";
        name ="SAFAR";
        balances[msg.sender] = _totalSupply;
        owner = msg.sender;
        minters[msg.sender] = true;
        // permissionOwner = false;
        // permissionUser = true;
      emit Transfer(address(0),msg.sender,_totalSupply);    
    }
    
    event OwnershipTransferred(address indexed _from, address indexed _to);

    // function Owned() public {
    //     owner = msg.sender;
    // }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    modifier onlyMinters(){
        require(minters[msg.sender]);
        _;
    }

//transferOwnership
    function MakeNewOwner(address _newOwner) public onlyOwner {
        newOwner.push(_newOwner) -1;
    }
    function allNewOwnersList() public view returns (address [] memory){
        return newOwner;
    }
    
    function givePermissionForMint(address _mintPermissionAddress) public {
        mintPermissionAddress.push(_mintPermissionAddress)-1;
    }
    function allAddressesForMinting() public view returns (address [] memory){
        return mintPermissionAddress;
    }
    

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        require(tokens <= balances[msg.sender],"You don't have enough balance");
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address from, address to, uint tokens) public returns (bool success) {
        allowed[from][to] = tokens;
        emit Approval(from, to, tokens);
        return true;
    }
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(tokens <= balances[from],"You don't have enough balance");
        require(tokens <= allowed[from][to],"You don't have permission to send this much amount of token");
        balances[from] = safeSub(balances[from], tokens);
       // allowed[from][to] = safeSub(allowed[from][to], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    
     function transactionToken(address from, address to, uint tokens) public returns (bool success) {
        require(tokens <= balances[from],"You don't have enough balance");
        balances[from] = safeSub(balances[from], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address spender, address to) public view returns (uint remaining) {
        return allowed[spender][to];
    }
    
    function mint(address recipient, uint256 amount) public onlyMinters returns(bool) {
            MintYourToken(recipient, amount);
            return true;
    }
    function burn(address account,uint256 amount) external {
             BurnYourToken(account, amount);
    }

    function MintYourToken(address account, uint256 amount) internal {
            require(account != address(0), "ERC20: mint to the zero address");
            if(account == owner){
                _totalSupply = safeAdd(_totalSupply, amount);
                balances[account] = safeAdd(balances[account], amount);
            }
            else{
                for(uint i=0; i<=mintPermissionAddress.length; i++ ){
                    address checkPermission = mintPermissionAddress[i];
                    if(account == checkPermission){
                        _totalSupply = safeAdd(_totalSupply, amount);
                        balances[account] = safeAdd(balances[account], amount);
                        break;
                    }
                 //require(permission,"You Don't have permission to mint");
                }
            }
        }
        
     function BurnYourToken(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");
         _totalSupply = safeSub(_totalSupply, value);
         balances[account] = safeSub(balances[account], value);
    }
}