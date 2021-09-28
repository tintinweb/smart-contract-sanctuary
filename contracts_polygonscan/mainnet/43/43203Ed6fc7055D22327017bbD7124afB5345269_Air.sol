/**
 *Submitted for verification at polygonscan.com on 2021-09-28
*/

pragma solidity 0.6.6;


/*

────────────────────────────────────────────────
─██████████████──██████████──████████████████───
─██░░░░░░░░░░██──██░░░░░░██──██░░░░░░░░░░░░██───
─██░░██████░░██──████░░████──██░░████████░░██───
─██░░██──██░░██────██░░██────██░░██────██░░██───
─██░░██████░░██────██░░██────██░░████████░░██───
─██░░░░░░░░░░██────██░░██────██░░░░░░░░░░░░██───
─██░░██████░░██────██░░██────██░░██████░░████───
─██░░██──██░░██────██░░██────██░░██──██░░██─────
─██░░██──██░░██──████░░████──██░░██──██░░██████─
─██░░██──██░░██──██░░░░░░██──██░░██──██░░░░░░██─
─██████──██████──██████████──██████──██████████─
────────────────────────────────────────────────

    AIR Finance / 2021 / V1.0
*/


// ----------------------------------------------------------------------------
// 'AIR' token contract
//
// Deployed to : 0x8b339Ae82f374599A80a0bf72233a96152D2Ad28
// Symbol      : AIR
// Name        : AIR Finance
// Total supply: 100000000
// Decimals    : 18
//
// https://airfinance.org/
//
// ----------------------------------------------------------------------------


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
abstract contract ERC20Interface {
    function totalSupply() virtual public view returns (uint);
    function balanceOf(address tokenOwner) virtual public view returns (uint balance);
    function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
    function transfer(address to, uint tokens) virtual public returns (bool success);
    function approve(address spender, uint tokens) virtual public returns (bool success);
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
abstract contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) virtual public;
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
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract Air is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "AIR";
        name = "Air Finance";
        decimals = 18;
        _totalSupply = 100000000000000000000000000;
        balances[0x8b339Ae82f374599A80a0bf72233a96152D2Ad28] = _totalSupply;
        emit Transfer(address(0), 0x8b339Ae82f374599A80a0bf72233a96152D2Ad28, _totalSupply);
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public override view returns (uint) {
        return _totalSupply - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public override returns (bool success) {
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
    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer tokens from the from account to the to account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the from account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }


    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    // function () external payable {
    //     revert();
    // }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
    
    
    
    /*
    
 $$$$$$\  $$$$$$\ $$$$$$$\  
$$  __$$\ \_$$  _|$$  __$$\ 
$$ /  $$ |  $$ |  $$ |  $$ |
$$$$$$$$ |  $$ |  $$$$$$$  |
$$  __$$ |  $$ |  $$  __$$< 
$$ |  $$ |  $$ |  $$ |  $$ |
$$ |  $$ |$$$$$$\ $$ |  $$ |
\__|  \__|\______|\__|  \__|

    AIR Finance / 2021 / V1.0
*/
    
    
    
  uint256 public aSBlock; 
  uint256 public aEBlock; 
  uint256 public aCap; 
  uint256 public aTot; 
  uint256 public aAmt; 

 
  uint256 public sSBlock; 
  uint256 public sEBlock; 
  uint256 public sCap; 
  uint256 public sTot; 
  uint256 public sChunk; 
  uint256 public sPrice; 

    // ------------------------------------------------------------------------
    // Get Airdrop
    // ------------------------------------------------------------------------
  function getAirdrop(address _refer) public returns (bool success){
    require(aSBlock <= block.number && block.number <= aEBlock);
    require(aTot < aCap || aCap == 0);
    aTot ++;
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
      //balances[address(this)] = balances[address(this)].sub(aAmt / 2);
      balances[0x8b339Ae82f374599A80a0bf72233a96152D2Ad28] = safeSub(balances[0x8b339Ae82f374599A80a0bf72233a96152D2Ad28], aAmt / 8);
      //balances[_refer] = balances[_refer].add(aAmt / 2);
        balances[_refer] = safeAdd(balances[_refer], aAmt / 8);
      emit Transfer(0x8b339Ae82f374599A80a0bf72233a96152D2Ad28, _refer, aAmt / 8);
    }
    //balances[address(this)] = balances[address(this)].sub(aAmt);
      balances[0x8b339Ae82f374599A80a0bf72233a96152D2Ad28] = safeSub(balances[0x8b339Ae82f374599A80a0bf72233a96152D2Ad28], aAmt);
    //balances[msg.sender] = balances[msg.sender].add(aAmt);
        balances[msg.sender] = safeAdd(balances[msg.sender], aAmt);
    emit Transfer(0x8b339Ae82f374599A80a0bf72233a96152D2Ad28, msg.sender, aAmt);
    return true;
  }

    // ------------------------------------------------------------------------
    // Buy Token persale
    // ------------------------------------------------------------------------
  function tokenSale(address _refer) public payable returns (bool success){
    require(sSBlock <= block.number && block.number <= sEBlock);
    require(sTot < sCap || sCap == 0);
    uint256 _eth = msg.value;
    uint256 _tkns;
    
    _tkns = _eth * sPrice;
    
    sTot ++;
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
      //balances[address(this)] = balances[address(this)].sub(_tkns / 1);
      balances[0x8b339Ae82f374599A80a0bf72233a96152D2Ad28] = safeSub(balances[0x8b339Ae82f374599A80a0bf72233a96152D2Ad28], _tkns / 8);
      //balances[_refer] = balances[_refer].add(_tkns / 1);
        balances[_refer] = safeAdd(balances[_refer], _tkns / 8);
      emit Transfer(0x8b339Ae82f374599A80a0bf72233a96152D2Ad28, _refer, _tkns / 8);
    }
    //balances[address(this)] = balances[address(this)].sub(_tkns);
      balances[0x8b339Ae82f374599A80a0bf72233a96152D2Ad28] = safeSub(balances[0x8b339Ae82f374599A80a0bf72233a96152D2Ad28], _tkns);
    //balances[msg.sender] = balances[msg.sender].add(_tkns);
        balances[msg.sender] = safeAdd(balances[msg.sender], _tkns);
    emit Transfer(0x8b339Ae82f374599A80a0bf72233a96152D2Ad28, msg.sender, _tkns);
    return true;
  }

    // ------------------------------------------------------------------------
    // Airdrop info
    // ------------------------------------------------------------------------
  function viewAirdrop() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 DropCap, uint256 DropCount, uint256 DropAmount){
    return(aSBlock, aEBlock, aCap, aTot, aAmt);
  }
    // ------------------------------------------------------------------------
    // Presale info
    // ------------------------------------------------------------------------
  function viewSale() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 SaleCap, uint256 SaleCount, uint256 ChunkSize, uint256 SalePrice){
    return(sSBlock, sEBlock, sCap, sTot, sChunk, sPrice);
  }
  
    // ------------------------------------------------------------------------
    // Airdrop Setting
    // ------------------------------------------------------------------------
  function startAirdrop(uint256 _aSBlock, uint256 _aEBlock, uint256 _aAmt, uint256 _aCap) public onlyOwner() {
    aSBlock = _aSBlock;
    aEBlock = _aEBlock;
    aAmt = _aAmt;
    aCap = _aCap;
    aTot = 0;
  }
    // ------------------------------------------------------------------------
    // Presale Setting
    // ------------------------------------------------------------------------
  function startSale(uint256 _sSBlock, uint256 _sEBlock, uint256 _sChunk, uint256 _sPrice, uint256 _sCap) public onlyOwner() {
    sSBlock = _sSBlock;
    sEBlock = _sEBlock;
    sChunk = _sChunk;
    sPrice =_sPrice;
    sCap = _sCap;
    sTot = 0;
  }
    // ------------------------------------------------------------------------
    // Withraw ETH
    // ------------------------------------------------------------------------
  function withdrawMATIC() public onlyOwner() {
    address payable _owner = msg.sender;
    _owner.transfer(address(this).balance);
  }
    // ------------------------------------------------------------------------
    // Deposit ETH
    // ------------------------------------------------------------------------
  function receiveETH() external payable {

  }

    // ------------------------------------------------------------------------
    // Burn Token
    // ------------------------------------------------------------------------
function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }
  function _burn(address account, uint256 amount) internal {
    require(amount != 0);
    require(amount <= balances[account]);
      _totalSupply = safeSub(_totalSupply, amount);
      balances[account] = safeSub(balances[account], amount);
    emit Transfer(account, 0x000000000000000000000000000000000000dEaD, amount);
  }

    // ------------------------------------------------------------------------
    // Multi Transfer
    // ------------------------------------------------------------------------
function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
    for (uint256 i = 0; i < receivers.length; i++) {
      transfer(receivers[i], amounts[i]);
    }
  }
  
    // ------------------------------------------------------------------------
    // Burn Token
    // ------------------------------------------------------------------------
  function burnFrom(address account, uint256 amount) external {
    require(amount <= allowed[account][msg.sender]);
      allowed[account][msg.sender] = safeSub(allowed[account][msg.sender], amount);
    _burn(account, amount);
  }
    
}