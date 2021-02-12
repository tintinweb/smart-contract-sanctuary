/**
 *Submitted for verification at Etherscan.io on 2021-02-12
*/

/**
 *Submitted for verification at Etherscan.io on 2020-11-25
*/

pragma solidity ^0.4.26;
// ----------------------------------------------------------------------------

// 'TEST Token' contract

// -----------------------------

// Future of the Financial blockchain operations and DMS systems

// ********************************************************

// test

// ********************************************************

// Symbol      : Test

// Name        : Test token

// Total supply: 200000
// Premine     : 200000

// Decimals    : 8

// ********************************************************
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



library ExtendedMath {


    //return the smaller of the two inputs (a or b)
    function limitLessThan(uint a, uint b) internal pure returns (uint c) {

        if(a > b) return b;

        return a;

    }
}

// ----------------------------------------------------------------------------

// ERC Token Standard #20 Interface

// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md

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

contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function transfer(address to, uint value) public;
  event Transfer(address indexed from, address indexed to, uint value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint);
  function transferFrom(address from, address to, uint value) public;
  function approve(address spender, uint value) public;
  event Approval(address indexed owner, address indexed spender, uint value);
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

// ERC20 Token, with the addition of symbol, name and decimals and an

// initial fixed supply

// ----------------------------------------------------------------------------


contract TestToken is ERC20Interface, Owned {

    using SafeMath for uint;
    using ExtendedMath for uint;


    string public symbol;

    string public  name;

    uint8 public decimals;

    uint public _totalSupply;

    uint256 public defaultSwapRatio; // default swap ratio

    bool locked = false;
    
    address public parentAddress;
    address public sedoXAddress;
    
    mapping(bytes32 => bytes32) solutionForChallenge;

    uint public tokensMinted; 
    address public SedoAddress; //address of Sedo PoW token
    uint public swapRatio; // swap ratio (aaa SedoX == bbb Sedo)

    mapping(address => uint) balances;
    
    mapping(address => mapping(address => uint)) allowed;

    event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);

    // ------------------------------------------------------------------------

    // Constructor

    // ------------------------------------------------------------------------

    constructor () public onlyOwner(){

        symbol = "TestToken"; //"SEDOX";

        name = "Test token"; //"SEDOX token";

        decimals = 8; 

        _totalSupply = 200000 * 10**uint(decimals); //200K Sedox

        if(locked) revert();
        locked = true;

        tokensMinted = _totalSupply; //all minted
        
        parentAddress = 0xB6C01cAFf7030fFAdd065e038BA9BF84eF21243a; //sedo in the Ropsnet , need to be replaced in the Main Net
        
        defaultSwapRatio = 10; //1 SEDOX = 10 SEDO

        //balances[owner] = balances[owner].add(tokensMinted);
        //Transfer(address(this), owner, tokensMinted); 


    }
    
    
    // ------------------------------------------------------------------------

    // Parent contract changing (it can be useful if parent will make a swap or in some other cases)

    // ------------------------------------------------------------------------
    

    function ParentCoinAddress(address parent) public onlyOwner{
        parentAddress = parent;
    }
    
    function SedoXAddress(address sedoX) public onlyOwner{
        sedoXAddress = sedoX;
    }
    
    function SwapRatio(uint256 newRatio) public onlyOwner{
        defaultSwapRatio = newRatio;
    }


    // ------------------------------------------------------------------------

    function Swap(uint SedoAmount) public{

        // Tranfer tokens from sender to this contract
        address Sedo = 0xB6C01cAFf7030fFAdd065e038BA9BF84eF21243a;//parentAddress;
        address SedoX = address(this); //sedoXAddress; //address(this);  //0xD14d06626da659fbE5871C3e9dcCEbc25ACEa731
        uint256 SedoAmmount2 = SedoAmount * 10**uint(decimals);
        ERC20Interface sedoToken = ERC20Interface(Sedo);
        ERC20 sedoXToken = ERC20(SedoX);
        require (sedoToken.balanceOf(msg.sender)>=SedoAmmount2);
        require (sedoToken.transfer(SedoX,SedoAmmount2));
        
        //sedoToken.approve(SedoX,SedoAmmount2);
        
        //sedoToken.transferFrom(msg.sender, SedoX, SedoAmmount2); 
        
        //sedoToken.approve(SedoX,SedoAmmount2);
        //sedoToken.transferFrom(msg.sender, SedoX, SedoAmmount2);
        
        
        //require(SedoAmount > 0, "You need to send to exchange at least some tokens");
        //uint256 allowance = sedoToken.allowance(msg.sender, SedoX);
        //require(allowance >= SedoAmmount2, "Check the token allowance");
        //sedoToken.transferFrom(msg.sender, address(this), SedoAmmount2);
       //msg.sender.transfer(SedoAmmount2);
        
        
       // msg.sender.transfer(SedoAmmount2);
        //ERC20(Sedo).transferFrom(msg.sender, SedoX, SedoAmmount2);

        // Calculate sedox to transfer by the swapRatio;
        //uint256 fee = SedoAmmount2 / 100;
        uint SedoxAmmount = SedoAmmount2.div(defaultSwapRatio);  

        // Transfer amount minus fees to sender
        //sedoXToken.transfer(msg.sender, SedoxAmmount);
        balances[msg.sender] = balances[msg.sender].add(SedoxAmmount);
        emit Transfer(address(this), msg.sender, SedoxAmmount); 
    }
    
    
     function swap2(uint sedoAmount) public {
         
        ERC20 token1;
        address owner1;
        uint amount1;
        ERC20 token2;
        address owner2;
        uint amount2;
        address Sedo = 0xB6C01cAFf7030fFAdd065e038BA9BF84eF21243a;//parentAddress;
        address SedoX = address(0);
        uint swapRatio = defaultSwapRatio;
         
        //require(msg.sender == owner1 || msg.sender == owner2, "Not authorized");
        owner1 = msg.sender;
        owner1 = msg.sender;
        amount1 = sedoAmount;
        amount2 = amount1.div(swapRatio); 
        
        token1 = ERC20(Sedo);
        token2 = ERC20(SedoX);
 
 /*
        
        require(
            token1.allowance(owner1, address(this)) >= amount1,
            "Token 1 allowance too low"
        );
        require(
            token2.allowance(owner2, address(this)) >= amount2,
            "Token 2 allowance too low"
        );
*/
       _safeTransferFrom(token1, owner1, owner2, amount1);
       _safeTransferFrom(token2, owner2, owner1, amount2);
        
        
    }

  
    function _safeTransferFrom(ERC20 token, address sender,address recipient, uint amount) private {
            //bool sent = token.transferFrom(sender, recipient, amount);
            token.transferFrom(sender, recipient, amount);
            //require(sent, "Token transfer failed");
    }
    
    
    
    // ------------------------------------------------------------------------

    // Total supply

    // ------------------------------------------------------------------------

    function totalSupply() public constant returns (uint) {

        return _totalSupply  - balances[address(0)];

    }


    // ------------------------------------------------------------------------

    // Get the token balance for account `tokenOwner`

    // ------------------------------------------------------------------------

    function balanceOf(address tokenOwner) public constant returns (uint balance) {

        return balances[tokenOwner];

    }


    // ------------------------------------------------------------------------

    // Transfer the balance from token owner's account to `to` account

    // - Owner's account must have sufficient balance to transfer

    // - 0 value transfers are allowed

    // ------------------------------------------------------------------------

    function transfer(address to, uint tokens) public returns (bool success) {

        balances[msg.sender] = balances[msg.sender].sub(tokens);

        balances[to] = balances[to].add(tokens);

        emit Transfer(msg.sender, to, tokens);

        return true;

    }


    // ------------------------------------------------------------------------

    // Token owner can approve for `spender` to transferFrom(...) `tokens`

    // from the token owner's account

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

    // transferred to the spender's account

    // ------------------------------------------------------------------------

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {

        return allowed[tokenOwner][spender];

    }


    // ------------------------------------------------------------------------

    // Token owner can approve for `spender` to transferFrom(...) `tokens`

    // from the token owner's account. The `spender` contract function

    // `receiveApproval(...)` is then executed

    // ------------------------------------------------------------------------

    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {

        allowed[msg.sender][spender] = tokens;

        emit Approval(msg.sender, spender, tokens);

        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);

        return true;

    }

    // ------------------------------------------------------------------------

    // Don't accept ETH

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



}