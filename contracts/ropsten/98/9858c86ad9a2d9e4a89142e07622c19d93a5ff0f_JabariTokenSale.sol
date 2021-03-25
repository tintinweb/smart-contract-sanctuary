/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

pragma solidity ^0.4.26;
 
// -----------------------------------------------------------------------
//
// Symbol      : JUT
// Name        : Jabari Token
// Total supply: 220000000
// Decimals    : 18
//  
// -----------------------------------------------------------------------
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

contract ERC20Interface {
function totalSupply() public view returns (uint);
function balanceOf(address tokenOwner) public view returns (uint balance);
function allowance(address tokenOwner, address spender) public view returns (uint remaining);
function transfer(address to, uint tokens) public returns (bool success);
function approve(address spender, uint tokens) public returns (bool success);
function transferFrom(address from, address to, uint tokens) public returns (bool success);
  
event Transfer(address indexed from, address indexed to, uint tokens);
event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ApproveAndCallFallBack {
function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

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

contract Lock {
    
     /**lock
     * @dev Reasons why a user's tokens have been locked
     */
    mapping(address => bytes32[]) public lockReason;
    mapping(address => uint256) public balances;

    /**
     * @dev locked token structure
     */
    struct LockToken {
        uint256 amount;
        uint256 validity;
        bool claimed;
    }

    /**
     * @dev Holds number & validity of tokens locked for a given reason for
     *      a specified address
     */
    mapping(address => mapping(bytes32 => LockToken)) public locked;

    /**
     * @dev Records data of all the tokens Locked
     */
    event Locked(
        address indexed _of,
        bytes32 indexed _reason,
        uint256 _amount,
        uint256 _validity
    );
    /**
     * @dev Records data of all the tokens unlocked
     */
    event Unlocked(
        address indexed _of,
        bytes32 indexed _reason,
        uint256 _amount
    );

    /**
     * @dev Returns tokens locked for a specified address for a
     *      specified reason
     *
     * @param _of The address whose tokens are locked
     * @param _reason The reason to query the lock tokens for
     */
    function tokensLocked(address _of, bytes32 _reason)
    public view returns(uint256 amount);

    /**
     * @dev Returns unlockable tokens for a specified address for a specified reason
     * @param _of The address to query the the unlockable token count of
     * @param _reason The reason to query the unlockable tokens for
     */
    function tokensUnlockable(address _of, bytes32 _reason)
    public view returns(uint256 amount);

    /**
     * @dev Unlocks the unlockable tokens of a specified address
     * @param _of Address of user, claiming back unlockable tokens
     */
    function unlock(address _of)
    public returns(uint256 unlockableTokens);
}

contract JabariToken is ERC20Interface, Owned, Lock {
    using SafeMath for uint;
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint256 public tokensForTokenSale; 
    address public tokenSaleAddress;                    // address of TokenSale contract
    uint256 public totalAllocatedTokens;                // variable to regulate the funds allocation
    uint256 public ownerHold; 
    uint internal _totalSupply;
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;
    
        /**
     * @dev Error messages for require statements
     */
    string internal constant AMOUNT_ZERO = "Amount can not be 0";
    string internal constant ONLY_OWNER = "Only owner has the right to perform this action";
    address public owner = msg.sender;
    
    constructor( address _tokensaleContract) public {
           symbol = "JUT";
           name = "Jabari";
           decimals = 18;
           tokenSaleAddress = _tokensaleContract;
           _totalSupply = 220*10**6 *10**uint(decimals);
           
           tokensForTokenSale = 30*10**6* 10**uint(decimals);
           ownerHold = 30*10**6* 10**uint(decimals);
           
            balances[tokenSaleAddress] = tokensForTokenSale;
            balances[owner] = ownerHold;
            
            emit Transfer(address(0), tokenSaleAddress, tokensForTokenSale);
            emit Transfer(address(0), owner, ownerHold);
         }
         // ------------------------------------------------------------------
        // Total supply
        // -------------------------------------------------------------------
        function totalSupply() public constant returns (uint) {
             return _totalSupply.sub(balances[address(0)]);
        }
     // ------------------------------------------------------------------
    // modifier
    // ------------------------------------------------------------------
      modifier onlyTokenSale() {
        require(msg.sender == tokenSaleAddress);
    _;
  }
  
    modifier onlyOwner {
        require(msg.sender == owner, ONLY_OWNER);
        _;
    }
    
       /**lock
     * @dev Transfers and Locks a specified amount of tokens,
     *      for a specified reason and time
     * @param _to adress to which tokens are to be transfered
     * @param _reason The reason to lock tokens
     * @param _amount Number of tokens to be transfered and locked
     * @param _days Number of days for locked token
     */
    function transferWithLock(address _to, bytes32 _reason, uint256 _amount, uint256 _days)
    public
    onlyOwner 
    returns(bool) {
        uint256 validUntil = now.add(_days.mul(86400)); //solhint-disable-line
        require(_amount != 0, AMOUNT_ZERO);

        if (locked[_to][_reason].amount == 0)
            lockReason[_to].push(_reason);

        transfer(address(this), _amount);

        locked[_to][_reason] = LockToken(_amount, validUntil, false);

        emit Locked(_to, _reason, _amount, validUntil);
        return true;
    }

    /**
     * @dev Returns tokens locked for a specified address for a
     *      specified reason
     * @param _of The address whose tokens are locked
     * @param _reason The reason to query the lock tokens for
     */
    function tokensLocked(address _of, bytes32 _reason)
    public
    view
    returns(uint256 amount) {
        if (!locked[_of][_reason].claimed)
            amount = locked[_of][_reason].amount;
    }

    /**
     * @dev Returns unlockable tokens for a specified address for a specified reason
     * @param _of The address to query the the unlockable token count of
     * @param _reason The reason to query the unlockable tokens for
     */
    function tokensUnlockable(address _of, bytes32 _reason)
    public
    view
    returns(uint256 amount) {
        if (locked[_of][_reason].validity <= now && !locked[_of][_reason].claimed) //solhint-disable-line
            amount = locked[_of][_reason].amount;
    }

    /**
     * @dev Unlocks the unlockable tokens of a specified address
     * @param _of Address of user, claiming back unlockable tokens 
     */
    function unlock(address _of)
    public
    returns(uint256 unlockableTokens) {
        uint256 lockedTokens;

        for (uint256 i = 0; i < lockReason[_of].length; i++) {
            lockedTokens = tokensUnlockable(_of, lockReason[_of][i]);
            if (lockedTokens > 0) {
                unlockableTokens = unlockableTokens.add(lockedTokens);
                locked[_of][lockReason[_of][i]].claimed = true;
                emit Unlocked(_of, lockReason[_of][i], lockedTokens); 
                
                if (unlockableTokens > 0){
                    this.transfer(_of, unlockableTokens);
                }
            }
        }
    }

    /**
     *  @dev Internal function that burns an amount of the token
     * @param tokens The amount that will be burnt.
     */

    function burn(uint256 tokens) public onlyOwner  returns(bool) {
        _burn(owner, tokens);
        return true;
    }
    
   /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param account The account whose tokens will be burnt.
   * @param amount The amount that will be burnt.
   */
  function _burn(address account, uint256 amount) internal {
    require(account != 0);
    require(amount <= balances[account]);

    _totalSupply = _totalSupply.sub(amount);
    balances[account] = balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }
  
 /**
      @dev function used to change the supply of total Allocated tokens in the market , it only called by TokenSale
      @param _amount amount is the token quantity added in token supply
  
   */
  function totalAllocatedTokens(uint256 _amount) public onlyTokenSale {
    totalAllocatedTokens += _amount;
  }
  
     // ------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // -------------------------------------------------------------------
     function balanceOf(address tokenOwner) public constant returns (uint balance) {
         return balances[tokenOwner];
    }
     // ------------------------------------------------------------------
     // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
     // - 0 value transfers are allowed
     // ------------------------------------------------------------------
     function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
         return true;
     }
     // ------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
     // from the token owner's account
  // recommends that there are no checks for the approval double-spend
 // attack
 // as this should be implemented in user interfaces
     // ------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
         return true;
     }
  // -------------------------------------------------------------------
  // Transfer `tokens` from the `from` account to the `to` account
  //
  // The calling account must already have sufficient tokens
 // approve(...)-d
 // for spending from the `from` account and
  // - From account must have sufficient balance to transfer
  // - Spender must have sufficient allowance to transfer
   // - 0 value transfers are allowed
  // -------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
         allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
         balances[to] = balances[to].add(tokens);
         emit Transfer(from, to, tokens);
         return true;
     }
    // -------------------------------------------------------------------
     // transferred to the spender's account
     // ------------------------------------------------------------------
     function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
         return allowed[tokenOwner][spender];
    }
     // ------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account. The `spender` contract function
     // `receiveApproval(...)` is then executed
     // ------------------------------------------------------------------
     function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
         allowed[msg.sender][spender] = tokens;
         emit Approval(msg.sender, spender, tokens);
         ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
         return true;
     }
    // -------------------------------------------------------------------
     // Don't accept ETH
    // -------------------------------------------------------------------
     function () external payable {
         revert();
     }
// -------------------------------------------------------------------
     // Owner can transfer out any accidentally sent ERC20 tokens
    // -------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}

contract JabariTokenSale {

    using SafeMath for uint256;
    
//////////////////////////////////////////// VARIABLES ///////////////////////////////////////////////// 

    JabariToken public token;                         // Token variable
    uint256 public tokeSaleStartTime;               // It should be XXXXXXXXXXX starting time of tokeSale
    uint256 public tokenSaleEndTime;                // It should be xxxxxxxxxxx token Sale End Time
    uint256 public totalWeiRaised;                  // Flag to track the amount raised
    uint256 public hardCap = 2*10**6;               // Hard Cap: $2,000,000
    // token price and eth price
    uint256 ethPrice = 1600; // eth price in usd
    uint256 internal tokenPrice = 85; // token price in usd
    
    bool internal isTokenDeployed = false;               // Flag to track the token deployment
    bool public isTokenSaleActive = false;               // Flag to track the TokenSale active or not
    // Addresses
    address public founderMultiSigAddress;          // Founders multi sign address
    address public remainingTokenHolder;            // Address to hold the remaining tokens after TokenSale end
    
    enum State { TokenSale }

   
    //Events
    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount); 
    event TokenSaleClosed(uint256 _blockTimeStamp);
    event ChangeFoundersWalletAddress(uint256 _blockTimeStamp, address indexed _foundersWalletAddress);

    //Modifiers
    modifier tokenIsDeployed() {
        require(isTokenDeployed == true);
        _;
    }

    modifier nonZeroAddress(address _to) {
        require(_to != 0x0);
        _;
    }
    
    modifier nonZeroEth() {
        require(msg.value > 0);
        _;
    }
    
    modifier onlyFounders() {
        require(msg.sender == founderMultiSigAddress);
        _;
    }
     
    modifier onlyremainingTokenHolder() {
        require(msg.sender == remainingTokenHolder);
        _;
    }
    
    modifier onlyPublic() {
        require(msg.sender != founderMultiSigAddress);
        _;
    }
//////////////////////////////////////////// CONSTRUCTOR //////////////////////////////////////////
   
    constructor(address _founderWalletAddress , address _remainingTokenHolder) public {
        founderMultiSigAddress = _founderWalletAddress;
        remainingTokenHolder = _remainingTokenHolder;
      
    }

    /**
        @dev function to change the founder multisig wallet address
        @param _newFounderAddress new address of founder
     */

     function setFounderMultiSigAddress(address _newFounderAddress) public
     onlyFounders 
     {
        founderMultiSigAddress = _newFounderAddress;
        emit ChangeFoundersWalletAddress(now, founderMultiSigAddress);
     }
    

    /**
        @dev attach the token address with the TokenSale conract 
        @param _tokenAddress address of the respective token contract 
    
     */
         
    function setTokenAddress(address _tokenAddress) 
    external 
    onlyFounders 
    nonZeroAddress(_tokenAddress) 
    {
        require(isTokenDeployed == false);
        token = JabariToken(_tokenAddress);
        isTokenDeployed = true;
    }

    /**
        @dev startTokenSale function use to start the TokenSale at the calling function time
        @dev _days No. of days to which TokenSale get active
        @return bool
     */
    
    function startTokenSale(uint8 _days) public
    onlyFounders 
    tokenIsDeployed 
    returns (bool)
    {
            tokeSaleStartTime = now;                            
            tokenSaleEndTime = tokeSaleStartTime + _days * 1 days; 
            isTokenSaleActive = !isTokenSaleActive;
            return true;
    }


    /**
        @dev function call after tokenSaleEndTime 
        it transfers the remaining tokens to remainingTokenHolder address
        @return bool
    */

    function endTokenSale() public onlyremainingTokenHolder returns (bool) {
        require(now > tokenSaleEndTime);
        uint256 remainingToken = token.balanceOf(this);  // remaining tokens

        if (remainingToken != 0) {
          token.transfer(remainingTokenHolder, remainingToken); 
          isTokenSaleActive = false;
          tokenSaleEndTime = now; 
          emit TokenSaleClosed(now);
          return true; 
        } 
        return false;
    }

    // function to get the current state of the token sale
    function getState() internal constant returns(State) {
        if(isTokenSaleActive) {
            return State.TokenSale;
        }
    }

   // get the amount of tokens a user would receive for a specific amount of ether
   function getTotalTokens(uint256 _amountOfEth) public view returns(uint256) {
       if (getState() == State.TokenSale) {
           return calcToken(_amountOfEth);
       }else {
           revert();
       }
      
   } 
  
   // set the price of 1 eth in usd
  function setEthPrice(uint256 value)
    external
    onlyFounders
    {
        ethPrice = value;

    }
    
    // calculate the amount of tokens
    function calcToken(uint256 value)
        internal
        view
        returns(uint256 amount){
            uint amountval;
            uint discountedamount;
             if(5000 >= ethPrice.mul(value)){
             amountval = ethPrice.mul(1000).mul(value).div(tokenPrice);
             discountedamount = amountval.mul(2).div(100);
             amount = discountedamount + amountval;
             return amount;
             
        } else if(10000 >= ethPrice.mul(value)){
             amountval = ethPrice.mul(1000).mul(value).div(tokenPrice);
             discountedamount = amountval.mul(4).div(100);
             amount = discountedamount + amountval;
             return amount;
             
        } else {
             amount = ethPrice.mul(1000).mul(value).div(tokenPrice);
             return amount;
        }
    }
        
    // Buy token function call only in duration of TokenSale active 
    function buyTokens(address beneficiary) public nonZeroEth tokenIsDeployed onlyPublic nonZeroAddress(beneficiary) payable returns(bool) {
        if(getState() == State.TokenSale) {
            require(now < tokenSaleEndTime);
            fundTransfer(msg.value);
            totalWeiRaised = totalWeiRaised.add(msg.value);
             uint256 amount = calcToken(msg.value);
        
         if (token.transfer(beneficiary, amount)) {
                token.totalAllocatedTokens(amount); 
                emit TokenPurchase(beneficiary, msg.value, amount);
            }
            return true;         
        }
        else {
            revert();
        }
        
    }
    
    // function to transfer the funds to founders account
    function fundTransfer(uint256 weiAmount) internal {
        founderMultiSigAddress.transfer(weiAmount);
    }
    
    // send ether to the contract address
    function() public payable {
        if(100 <= ethPrice.mul(msg.value)){
        buyTokens(msg.sender);
        }
        else {
            revert();
        }
    }
}