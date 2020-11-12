/**
MesChain (MES) is provided by a Company called Genesis Crypto Technology. 
We are a tech-advanced company committed to reforming the world with digital currency and technology in general.
Manufacturing Execution System (MES), MesChain manufacturing automation systems and optimization of manufacturing activities initiate,
monitor, optimize, and documents manufacturing processes from the beginning of the assignment to the manufacturing of end products in real-time.
Performance analysis (statistical and mathematical analysis, monitoring process performance, calculation of TEC, calculation of operation time 
and equipment downtime, generation of reports);

• Programming of manufacturing schedules;
• Controls of documents (electronic document circulation);
• Human resource management (employee management);
• Coordination of technological processes and end product tracking.

* Website - https://meschain.io

* Youtube - https://www.youtube.com/channel/UCmApZlx5CxZeX8lpT60WQkg

* MesChain Blog - https://blog.meschain.io

* MesChain Reward - https://reward.meschain.io

* Telegram - https://t.me/MesChain_English

* Telegram - https://t.me/Meschain_announcements

* Twitter - https://twitter.com/MeschainMES

* Facebook - https://www.facebook.com/MesChainproject

* Medium - https://medium.com/@meschain
 
**/

pragma solidity ^0.6.0;
// "SPDX-License-Identifier: UNLICENSED "

// ----------------------------------------------------------------------------
// 'MesChain' token contract

// Symbol      : Mes
// Name        : MesChain
// Total supply: 7000000000
// Decimals    : 8
// ----------------------------------------------------------------------------

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 *
*/
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function ceil(uint a, uint m) internal pure returns (uint r) {
    return (a + m - 1) / m * m;
  }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
abstract contract ERC20Interface {
    function totalSupply() public virtual view returns (uint);
    function balanceOf(address tokenOwner) public virtual view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public virtual view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public virtual returns (bool success);
    function approve(address spender, uint256 tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}
// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}
// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract Token is ERC20Interface, Owned {
    using SafeMath for uint256;
    string public symbol = "MES";
    string public  name = "MesChain";
    uint256 public decimals = 8;
    uint256 private _totalSupply = 7000000000 * 10 ** (decimals);
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    address constant private wallet2 = 0x84C059eaffee898c06b414C42Abd867F39D0a10b;
    address constant private wallet3 = 0x94cdc76Bca1cA979a04E4f0b1a744C2361c32d52;
    address constant private wallet4 = 0xe30d19BFc7DB0Db9f4826C007B5a466358E1D8B2;
    address constant private wallet5 = 0x711Ea4477FCE00Fc74690f6ad883dBfb49daa188;
    
    address constant private wallet6 = 0xDdc0F00172574Ebe01234C3F24C85d32eBAD6604;
    address constant private wallet7 = 0x5dF2BAb563673BA729eCa74fa0559008EfB40D42;
    address constant private wallet8 = 0x669A3AC76a72374A3351d6EF3CC3492DfD9c1369;
    
    struct LOCKING{
        uint256 lockedTokens;
        uint256 cliff;
    }
    mapping(address => LOCKING) public walletsLocking;
    
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        owner = 0x6Fcc81b93593301B1CBfe5567a51015b7A281016;
        
        _tokenAllocation();
        _setLocking();
    }
    
    function _tokenAllocation() private {
        // send funds to owner
        balances[owner] = 2500000000 * 10 ** (decimals); // 2.500.000.000
        emit Transfer(address(0),owner,  2500000000 * 10 ** (decimals));
        
        // send funds to wallet2
        balances[wallet2] = 1000000000 * 10 ** (decimals); // 1.000.000.000
        emit Transfer(address(0), wallet2, 1000000000 * 10 ** (decimals));
        
        // send funds to wallet3
        balances[address(wallet3)] = 500000000 * 10 ** (decimals); // 500.000.000 
        emit Transfer(address(0),address(wallet3),  500000000 * 10 ** (decimals));
        
        // send funds to wallet4
        balances[address(wallet4)] = 500000000 * 10 ** (decimals); // 500.000.000 
        emit Transfer(address(0),address(wallet4), 500000000 * 10 ** (decimals));
        
        // send funds to wallet5
        balances[address(wallet5)] = 500000000 * 10 ** (decimals); // 500.000.000
        emit Transfer(address(0),address(wallet5), 500000000 * 10 ** (decimals));
        
        // send funds to wallet6
        balances[address(wallet6)] = 500000000 * 10 ** (decimals); // 500.000.000 
        emit Transfer(address(0),address(wallet6), 500000000 * 10 ** (decimals));
        
        // send funds to wallet7
        balances[address(wallet7)] = 1000000000 * 10 ** (decimals); // 1.000.000.000
        emit Transfer(address(0),address(wallet7), 1000000000 * 10 ** (decimals));
        
        // send funds to wallet8
        balances[address(wallet8)] = 500000000 * 10 ** (decimals); // 500.000.000 
        emit Transfer(address(0),address(wallet8), 500000000 * 10 ** (decimals));
        
    }
    
    function _setLocking() private{
        walletsLocking[wallet3].lockedTokens = 500000000 * 10 ** (decimals);
        walletsLocking[wallet3].cliff = 1614556800; // 1.03.2021
        
        walletsLocking[wallet4].lockedTokens = 500000000 * 10 ** (decimals);
        walletsLocking[wallet4].cliff = 1630454400; // 1.09.2021
        
        walletsLocking[wallet5].lockedTokens = 500000000 * 10 ** (decimals);
        walletsLocking[wallet5].cliff = 1646092800; // 1.03.2022
        
        walletsLocking[wallet6].lockedTokens = 500000000 * 10 ** (decimals);
        walletsLocking[wallet6].cliff = 1661990400; // 1.09.2022
        
        walletsLocking[wallet7].lockedTokens = 1000000000 * 10 ** (decimals);
        walletsLocking[wallet7].cliff = 1677628800; // 1.03.2023
        
        walletsLocking[wallet8].lockedTokens = 500000000 * 10 ** (decimals);
        walletsLocking[wallet8].cliff = 1693526400; // 1.09.2023
    }
    
    /** ERC20Interface function's implementation **/

    function totalSupply() public override view returns (uint256){
       return _totalSupply;
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
        require(address(to) != address(0), "Transfer to address 0 not allowed");
        require(balances[msg.sender] >= tokens, "SENDER: insufficient balance");
        
        if (walletsLocking[msg.sender].lockedTokens > 0){
            checkUnlocking();
        }
        
        require(balances[msg.sender].sub(tokens) >= walletsLocking[msg.sender].lockedTokens, "Please wait for tokens to be released");
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
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
        
        // prevent transfer to 0x0, use burn instead
        require(address(to) != address(0), "Transfer to address 0 not allowed");
        require(balances[from] >= tokens, "SENDER: In-sufficient balance");
        
        if (walletsLocking[from].lockedTokens > 0){
            checkUnlocking();
        }
        
        require(balances[from].sub(tokens) >= walletsLocking[from].lockedTokens, "Please wait for tokens to be released");
        
        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        emit Transfer(from,to,tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public override view returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }
    
    // ------------------------------------------------------------------------
    // @dev Internal function that burns an amount of the token from a given account
    // @param _amount The amount that will be burnt
    // @param _account The tokens to burn from
    // ------------------------------------------------------------------------
    function burnTokens(uint256 _amount, address _account) external {
        require(_account == msg.sender || _account == owner);
        require(balances[_account] >= _amount, "In-sufficient account balance");
        _totalSupply = _totalSupply.sub(_amount);
        balances[address(_account)] = balances[address(_account)].sub(_amount);
        emit Transfer(address(_account), address(0), _amount);
    }
    
    function checkUnlocking() private{
        if(block.timestamp > walletsLocking[msg.sender].cliff)
            walletsLocking[msg.sender].lockedTokens = 0;
    }
    
    function bulkTransfer(address[] calldata _wallets, uint256[] calldata _tokens, uint256[] calldata _unLockingDate) external{
        
        require(_wallets.length <= 100, "Send to max 100 accounts at once");
        require(_wallets.length == _tokens.length, "Tokens length mismatched with wallets");
        
        for(uint256 i=0; i < _wallets.length; i++){
            
            transfer(_wallets[i], _tokens[i]);
            
            walletsLocking[_wallets[i]].lockedTokens = _tokens[i];
            walletsLocking[_wallets[i]].cliff = _unLockingDate[i];
        }
    }
}