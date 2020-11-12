pragma solidity ^0.6.0;
// "SPDX-License-Identifier: UNLICENSED "

// ----------------------------------------------------------------------------
// 'FORMS' token contract

// Symbol      : FORMS
// Name        : FORMS
// Total supply: 9,311,608
// Decimals    : 18
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
    string public symbol = "FORMS";
    string public  name = "FORMS";
    uint256 public decimals = 18;
    uint256 private _totalSupply = 9311608 * 10 ** (decimals);
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    address constant private TEAM = 0x24B73DC219196a5E373D73b7Cd638017f1f07E2F;
    address constant private MARKETING_FUNDS = 0x4B63B18b66Fc617B5A3125F0ABB565Dc22d732ba ;
    address constant private COMMUNITY_REWARD = 0xC071C603238F387E48Ee96826a81D608e304545A;
    
    address constant private PRIVATE_SALE_ADD1 = 0xB5Aceaa4db96d6901b492505170Ab7F1d6E7cdAd;
    address constant private PRIVATE_SALE_ADD2 = 0x8f63Fe51A3677cf02C80c11933De4B5846f2a336;
    address constant private PRIVATE_SALE_ADD3 = 0x134D97378Ed04eC0CaE4C689800Be9e96D683ac1;
    
    address private tokenSaleOpt1;
    address private tokenSaleOpt2;
    address private tokenSaleOpt3;
    
    struct LOCKING{
        uint256 lockedTokens; //DR , //PRC // lockedTokens1
        uint256 releasePeriod;
        uint256 cliff; //DR, PRC // cliff for sale option 1
        uint256 lastVisit;
        uint256 releasePercentage;
        bool directRelease; //DR
        uint256 lockedTokens2;
        uint256 cliff2;
    }
    mapping(address => LOCKING) public walletsLocking;
    
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(address _tokenSaleOpt1, address _tokenSaleOpt2, address _tokenSaleOpt3) public {
        owner = msg.sender;
        
        tokenSaleOpt1 = _tokenSaleOpt1;
        tokenSaleOpt2 = _tokenSaleOpt2;
        tokenSaleOpt3 = _tokenSaleOpt3;
        
        _tokenAllocation();
        _setLocking();
    }
    
    function _tokenAllocation() private {
        // send funds to team
        balances[address(TEAM)] = 1303625 * 10 ** (decimals); // 1303625
        emit Transfer(address(0),address(TEAM), 1303625 * 10 ** (decimals));
        
        // send funds to community reward
        balances[address(COMMUNITY_REWARD)] = 1117393 * 10 ** (decimals); // 1,117,393
        emit Transfer(address(0),address(COMMUNITY_REWARD), 1117393 * 10 ** (decimals));
        
        // send funds to marketing funds
        balances[address(MARKETING_FUNDS)] = 1117393 * 10 ** (decimals); // 1,117,393
        emit Transfer(address(0),address(MARKETING_FUNDS), 1117393 * 10 ** (decimals));
        
        // send funds to owner for exchange
        balances[address(owner)] = 1024277 * 10 ** (decimals); // 1,024,277
        emit Transfer(address(0),address(owner), 1024277 * 10 ** (decimals));
        
        // send funds for option 1 token sale
        balances[address(tokenSaleOpt1)] = 651813 * 10 ** (decimals); // 651,813
        emit Transfer(address(0),address(tokenSaleOpt1), 651813 * 10 ** (decimals));
        
        // send funds for option 2 token sale
        balances[address(tokenSaleOpt2)] = 2048554 * 10 ** (decimals); // 2,048,554
        emit Transfer(address(0),address(tokenSaleOpt2), 2048554 * 10 ** (decimals));
        
        // send funds for option 3 token sale
        balances[address(tokenSaleOpt3)] = 1024277 * 10 ** (decimals); // 1,024,277
        emit Transfer(address(0),address(tokenSaleOpt3), 1024277 * 10 ** (decimals));
        
        // Send to private sale addresses
        balances[address(0xB5Aceaa4db96d6901b492505170Ab7F1d6E7cdAd)] = 529131 * 10 ** (decimals); // 529131
        emit Transfer(address(0),address(0xB5Aceaa4db96d6901b492505170Ab7F1d6E7cdAd), 529131 * 10 ** (decimals));
        
        balances[address(0x8f63Fe51A3677cf02C80c11933De4B5846f2a336)] = 242718 * 10 ** (decimals); // 242718
        emit Transfer(address(0),address(0x8f63Fe51A3677cf02C80c11933De4B5846f2a336), 242718 * 10 ** (decimals));
        
        balances[address(0x134D97378Ed04eC0CaE4C689800Be9e96D683ac1)] = 252427 * 10 ** (decimals); // 242718
        emit Transfer(address(0),address(0x134D97378Ed04eC0CaE4C689800Be9e96D683ac1), 252427 * 10 ** (decimals));
    }
    
    function _setLocking() private{
        //////////////////////////////////TEAM////////////////////////////////////
        walletsLocking[TEAM].directRelease = true;
        walletsLocking[TEAM].lockedTokens = 1303625 * 10 ** (decimals);
        walletsLocking[TEAM].cliff = block.timestamp.add(365 days);
        
        //////////////////////////////////PRIVATE SALE ADDRESS 1////////////////////////////////////
        /////////////////////////////0xB5Aceaa4db96d6901b492505170Ab7F1d6E7cdAd////////////////////
        walletsLocking[0xB5Aceaa4db96d6901b492505170Ab7F1d6E7cdAd].directRelease = true;
        walletsLocking[0xB5Aceaa4db96d6901b492505170Ab7F1d6E7cdAd].lockedTokens = 529131 * 10 ** (decimals);
        walletsLocking[0xB5Aceaa4db96d6901b492505170Ab7F1d6E7cdAd].cliff = block.timestamp.add(180 days);
        
        //////////////////////////////////PRIVATE SALE ADDRESS 2////////////////////////////////////
        /////////////////////////////0x8f63Fe51A3677cf02C80c11933De4B5846f2a336////////////////////
        walletsLocking[0x8f63Fe51A3677cf02C80c11933De4B5846f2a336].directRelease = true;
        walletsLocking[0x8f63Fe51A3677cf02C80c11933De4B5846f2a336].lockedTokens = 242718 * 10 ** (decimals);
        walletsLocking[0x8f63Fe51A3677cf02C80c11933De4B5846f2a336].cliff = block.timestamp.add(180 days);
        
        //////////////////////////////////PRIVATE SALE ADDRESS 3////////////////////////////////////
        /////////////////////////////0x134D97378Ed04eC0CaE4C689800Be9e96D683ac1////////////////////
        walletsLocking[0x134D97378Ed04eC0CaE4C689800Be9e96D683ac1].directRelease = true;
        walletsLocking[0x134D97378Ed04eC0CaE4C689800Be9e96D683ac1].lockedTokens = 252427 * 10 ** (decimals);
        walletsLocking[0x134D97378Ed04eC0CaE4C689800Be9e96D683ac1].cliff = block.timestamp.add(180 days);
        
        //////////////////////////////////COMMUNITY_REWARD////////////////////////////////////
        walletsLocking[COMMUNITY_REWARD].directRelease = false;
        walletsLocking[COMMUNITY_REWARD].lockedTokens = 1117393 * 10 ** (decimals);
        walletsLocking[COMMUNITY_REWARD].cliff = block.timestamp.add(30 days);
        walletsLocking[COMMUNITY_REWARD].lastVisit = block.timestamp.add(30 days);
        walletsLocking[COMMUNITY_REWARD].releasePeriod = 30 days; // 1 month
        walletsLocking[COMMUNITY_REWARD].releasePercentage = 5586965e16; // 55869.65
        
        //////////////////////////////////MARKETING_FUNDS////////////////////////////////////
        walletsLocking[MARKETING_FUNDS].directRelease = false;
        walletsLocking[MARKETING_FUNDS].lockedTokens = 1117393 * 10 ** (decimals);
        walletsLocking[MARKETING_FUNDS].cliff = 1599004800; // 2 september 2020
        walletsLocking[MARKETING_FUNDS].lastVisit = 1599004800;
        walletsLocking[MARKETING_FUNDS].releasePeriod = 30 days; // 1 month
        walletsLocking[MARKETING_FUNDS].releasePercentage = 2234786e17; // 223478.6
    }
    
    function setTokenLock(uint256 lockedTokens, uint256 cliffTime, address purchaser) public {
        require(msg.sender == tokenSaleOpt1 || msg.sender == tokenSaleOpt2, "UnAuthorized: Only sale contracts allowed");
        //////////////////////////////////SET LOCK TO THE PURCHASER ACCOUNT////////////////////////////////////
        if(msg.sender == tokenSaleOpt1){
            walletsLocking[purchaser].directRelease = true;
            walletsLocking[purchaser].lockedTokens += lockedTokens;
            walletsLocking[purchaser].cliff = cliffTime;
        } else{
            walletsLocking[purchaser].directRelease = true;
            walletsLocking[purchaser].lockedTokens2 += lockedTokens;
            walletsLocking[purchaser].cliff2 = cliffTime;
        }
        
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
        
        if (walletsLocking[msg.sender].lockedTokens > 0 || walletsLocking[msg.sender].lockedTokens2 > 0){
            if(walletsLocking[msg.sender].directRelease)
                directRelease();
            else
                checkTime();
        }
        
        uint256 lockedTokens = walletsLocking[msg.sender].lockedTokens.add(walletsLocking[msg.sender].lockedTokens2);
        require(balances[msg.sender].sub(tokens) >= lockedTokens, "Please wait for tokens to be released");
        
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
        require(balances[msg.sender] >= tokens, "SENDER: insufficient balance");
        
        if (walletsLocking[msg.sender].lockedTokens > 0){
            if(walletsLocking[msg.sender].directRelease)
                directRelease();
            else
                checkTime();
        }
        
        uint256 lockedTokens = walletsLocking[msg.sender].lockedTokens.add(walletsLocking[msg.sender].lockedTokens2);
        require(balances[msg.sender].sub(tokens) >= lockedTokens, "Please wait for tokens to be released");
        
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
    function burnTokens(uint256 _amount) public {
        address _account = msg.sender;
        require(balances[_account] >= _amount, "insufficient account balance");
        _totalSupply = _totalSupply.sub(_amount);
        balances[address(_account)] = balances[address(_account)].sub(_amount);
        emit Transfer(address(_account), address(0), _amount);
    }
    
    function directRelease() private{
        if(block.timestamp > walletsLocking[msg.sender].cliff){
            walletsLocking[msg.sender].lockedTokens = 0;
        }else if(block.timestamp > walletsLocking[msg.sender].cliff2){
            walletsLocking[msg.sender].lockedTokens2 = 0;
        }
    }
    
    function checkTime() private {
        // if cliff is applied
        if(block.timestamp > walletsLocking[msg.sender].cliff){
            if(msg.sender == MARKETING_FUNDS && walletsLocking[msg.sender].lastVisit == 1599004800){
                walletsLocking[msg.sender].lockedTokens = walletsLocking[msg.sender].lockedTokens.sub(2234786e17); // 20% released   
            }
            uint256 timeSpanned = (now.sub(walletsLocking[msg.sender].lastVisit)).div(walletsLocking[msg.sender].releasePeriod);
            
            // if cliff is passed
            if (timeSpanned >= 1){
            
                uint256 released = timeSpanned.mul(walletsLocking[msg.sender].releasePercentage);
            
                if (released > walletsLocking[msg.sender].lockedTokens){
                    released = walletsLocking[msg.sender].lockedTokens;
                }
            
                walletsLocking[msg.sender].lastVisit = now;
                walletsLocking[msg.sender].lockedTokens = walletsLocking[msg.sender].lockedTokens.sub(released);
            }
        }
    }
}