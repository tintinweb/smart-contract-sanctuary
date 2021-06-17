/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

pragma solidity ^0.8.0;


/*
This contract allows anyone to atomically mutate ERC20 tokens to a new token and back at a 1:1 ratio.  
This contract is atomic, decentralized, and has no owner.
*/
 

abstract contract ERC20Basic {
  function totalSupply() virtual public view returns (uint256);
  function balanceOf(address who) virtual public view returns (uint256);
  function transfer(address to, uint256 value) virtual public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

abstract contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    virtual public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    virtual public returns (bool);

  function approve(address spender, uint256 value) virtual public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

abstract contract ApproveAndCallFallBack {

    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) virtual public;

}
 

contract _AtomicProxyToken {
    
  
    address public _originalToken;

    string public name;
    string public symbol;
    uint8  public decimals = 8;
    uint private _totalSupply;
    
    uint public supplyFactor = 100000000;

    event  Approval(address src, address ext, uint amt);
    event  Transfer(address src, address dst, uint amt); 

    mapping (address => uint)                       public  balances;
    mapping (address => mapping (address => uint))  public  allowance;
    mapping (address => uint)                       public  nonces;
    
    uint256 immutable MAX_INT  = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    
    /// @notice The EIP-712 typehash for the permit struct used by the contract
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");


  

   constructor(string memory tokenName, string memory tokenSymbol, address mutatingToken){
       name = tokenName;
       symbol = tokenSymbol;
       _originalToken = mutatingToken;
   }    

    /**
     *  
     * @dev Deposit original tokens, receive proxy tokens 
     * @param amount Amount of original tokens to charge
     */
    function depositTokens(address from, uint amount) internal returns (bool)
    {
        require( amount > 0 );
        
        require( ERC20( _originalToken ).transferFrom( from, address(this), amount) );
            
        balances[from] += (amount * supplyFactor);
        _totalSupply += (amount * supplyFactor);
        
        emit Transfer(address(0x0), from, amount);
        
        return true;
    }



    /**
     * @dev Withdraw original tokens, dissipate proxy tokens 
     * @param amount Amount of original tokens to release
     */
    function withdrawTokens(uint amount) public returns (bool)
    {
        address from = msg.sender;
        require( amount > 0 );
        
        balances[from] -= (amount * supplyFactor);
        _totalSupply -=  (amount * supplyFactor);
        
        emit Transfer( from, address(0x0), amount);
            
        require( ERC20( _originalToken ).transfer( from, amount) ); 
        
        return true;
    }
    
    
     /**
     * Do not allow Ether to enter 
     */
     fallback()  external payable  
    {
        revert();
    }
    
    
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function approve(address ext, uint amt) public returns (bool) {
        allowance[msg.sender][ext] = amt;
        emit Approval(msg.sender, ext, amt);
        return true;
    }

    function transfer(address to, uint tokens) public returns (bool) {
        address from = msg.sender;
        balances[from] = balances[from] - (tokens);
        
        balances[to] = balances[to] + (tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


     function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from] - (tokens);
        allowance[from][msg.sender] = allowance[from][msg.sender] - (tokens);
        balances[to] = balances[to] + (tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    
    
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {

        allowance[msg.sender][spender] = tokens;

        emit Approval(msg.sender, spender, tokens);

        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);

        return true;

    }
    
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public returns (bool success) {
        
        require( token == _originalToken );
        
        require( depositTokens(from, tokens) );

        return true;

     }
     
     
      /**
     * @notice Triggers an approval from owner to spends
     * @param owner The address to approve from
     * @param spender The address to be approved
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @param deadline The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function permit(address owner, address spender, uint rawAmount, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        
       
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, rawAmount, nonces[owner]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "permit: invalid signature");
        require(signatory == owner, "permit: unauthorized");
        require(block.timestamp <= deadline, "permit: signature expired");

        allowance[owner][spender] = rawAmount;

        emit Approval(owner, spender, rawAmount);
    }
    
    
    function getChainId() internal view returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

}