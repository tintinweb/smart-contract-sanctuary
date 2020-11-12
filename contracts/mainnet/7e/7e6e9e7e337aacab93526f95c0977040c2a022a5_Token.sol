pragma solidity ^0.6.0;
// SPDX-License-Identifier: UNLICENSED

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
// 'ORNG' token contract

// Symbol      : ORNG
// Name        : Orange Protocol
// Total supply: 1,000,000,000 (1 billion)
// Decimals    : 18
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract Token is ERC20Interface, Owned {
    using SafeMath for uint256;
    string public symbol = "ORNG";
    string public  name = "Orange Protocol";
    uint256 public decimals = 18;
    uint256 _totalSupply = 1e9 * 10 ** decimals;
    bool public _openTransfer = false;
    address team = 0x0d69E8cecc87906ED08020C436256F608517297C;
    address nodesReward = 0x2029673627358274e79a83d7bD9c2A5A8B9C4eEb;
    address rangeFoundation = 0x2eDb23b4aFa0Eb0058cfF90caCC823B11fC2865f;
    
    address public earlyBird;
    uint256 public preSaleAllocations;
    uint256 public earlyBirdAllocations;
    
    address uniswap = 0x2029673627358274e79a83d7bD9c2A5A8B9C4eEb;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    struct LOCKING{
        uint256 lockedTokens;
        uint256 cliff;
        bool earlyBird;
    }
    mapping(address => LOCKING) public walletsLocking;

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(address _earlyBird) public {
        owner = 0x2029673627358274e79a83d7bD9c2A5A8B9C4eEb;
        earlyBird = _earlyBird;
        balances[address(this)] = totalSupply();

        emit Transfer(address(0),address(this), totalSupply());

        balances[address(this)] = balances[address(this)].sub(80000000 * 10 ** decimals);
        balances[team] = balances[team].add(80000000 * 10 ** decimals);
        emit Transfer(address(this), team, 80000000 * 10 ** decimals);

        balances[address(this)] = balances[address(this)].sub(450000000 * 10 ** decimals);
        balances[nodesReward] = balances[nodesReward].add(450000000 * 10 ** decimals);
        emit Transfer(address(this), nodesReward, 450000000 * 10 ** decimals);

        balances[address(this)] = balances[address(this)].sub(200000000 * 10 ** decimals);
        balances[rangeFoundation] = balances[rangeFoundation].add(200000000 * 10 ** decimals);
        emit Transfer(address(this), rangeFoundation, 200000000 * 10 ** decimals);

        balances[address(this)] = balances[address(this)].sub(50000000 * 10 ** decimals);
        balances[earlyBird] = balances[earlyBird].add(50000000 * 10 ** decimals);
        emit Transfer(address(this), earlyBird, 50000000 * 10 ** decimals);
        earlyBirdAllocations = 50000000 * 10 ** decimals;
        
        balances[address(this)] = balances[address(this)].sub(190000000 * 10 ** decimals);
        balances[owner] = balances[owner].add(190000000 * 10 ** decimals); // for presale
        emit Transfer(address(this), owner, 190000000 * 10 ** decimals);
        preSaleAllocations = 190000000 * 10 ** decimals;

        balances[address(this)] = balances[address(this)].sub(30000000 * 10 ** decimals);
        balances[uniswap] = balances[uniswap].add(30000000 * 10 ** decimals);
        emit Transfer(address(this), uniswap, 30000000 * 10 ** decimals);

        _setLocking();
    }
    
    function _setLocking() private {
        walletsLocking[team].lockedTokens = 80000000 * 10 ** (decimals);
        walletsLocking[team].cliff = block.timestamp.add(730 days);
        walletsLocking[team].earlyBird = false;
        
        walletsLocking[nodesReward].lockedTokens = 450000000 * 10 ** (decimals);
        walletsLocking[nodesReward].cliff = 1609459199; // 31.12.2020 11:59:59
        walletsLocking[nodesReward].earlyBird = false;
        
        walletsLocking[rangeFoundation].lockedTokens = 166000000 * 10 ** (decimals); // 17% already released, 83% locked
        walletsLocking[rangeFoundation].cliff = 1609459199; // 31.12.2020 11:59:59
        walletsLocking[rangeFoundation].earlyBird = false;
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
        require(address(to) != address(0));
        require(balances[msg.sender] >= tokens);
        require(balances[to] + tokens >= balances[to]);
        
        if(walletsLocking[msg.sender].earlyBird == false){
            if (walletsLocking[msg.sender].lockedTokens > 0 ){
                if(block.timestamp > walletsLocking[msg.sender].cliff){
                    walletsLocking[msg.sender].lockedTokens = 0;
                }
            }
        } else{
            if(_openTransfer){
                walletsLocking[msg.sender].lockedTokens = 0;
            } 
        }
        
        require(balances[msg.sender].sub(tokens) >= walletsLocking[msg.sender].lockedTokens, "Please wait for tokens to be released");
        
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
        require(balances[to] + tokens >= balances[to]);
        
        if(walletsLocking[from].earlyBird == false){
            if (walletsLocking[from].lockedTokens > 0 ){
                if(block.timestamp > walletsLocking[from].cliff){
                    walletsLocking[from].lockedTokens = 0;
                }
            }
        } else{
            if(_openTransfer){
                walletsLocking[from].lockedTokens = 0;
            } 
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
    // @dev Public function that burns an amount of the token from a given account
    // @param _amount The amount that will be burnt
    // @param _account The tokens to burn from
    // can be used from account owner or contract owner
    // ------------------------------------------------------------------------
    function burnTokens(uint256 _amount, address _account) public {
        require(msg.sender == _account || msg.sender == owner, "UnAuthorized");
        require(balances[_account] >= _amount, "Insufficient account balance");
        _totalSupply = _totalSupply.sub(_amount);
        balances[_account] = balances[_account].sub(_amount);
        emit Transfer(_account, address(0), _amount);
    }
    
    function setTokenLock(uint256 lockedTokens, address purchaser) public {
        require(msg.sender == earlyBird, "UnAuthorized: Only early bird contract is allowed");
        walletsLocking[purchaser].lockedTokens += lockedTokens;
        walletsLocking[purchaser].earlyBird = true;
    }
    
    function enableOpenTransfer() external onlyOwner {
        _openTransfer = true;
    }
}