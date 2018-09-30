pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

/**
 * @title Contracts that should not own Ether
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="b9cbdcd4dad6f98b">[email&#160;protected]</a>π.com>
 * @dev This tries to block incoming ether to prevent accidental loss of Ether. Should Ether end up
 * in the contract, it will allow the owner to reclaim this Ether.
 * @notice Ether can still be sent to this contract by:
 * calling functions labeled `payable`
 * `selfdestruct(contract_address)`
 * mining directly to the contract address
 */
contract HasNoEther is Ownable {

  /**
  * @dev Constructor that rejects incoming Ether
  * The `payable` flag is added so we can access `msg.value` without compiler warning. If we
  * leave out payable, then Solidity will allow inheriting contracts to implement a payable
  * constructor. By doing it this way we prevent a payable constructor from working. Alternatively
  * we could use assembly to access msg.value.
  */
  constructor() public payable {
    require(msg.value == 0);
  }

  /**
   * @dev Disallows direct send by setting a default function without the `payable` flag.
   */
  function() external {
  }

  /**
   * @dev Transfer all Ether held by the contract to the owner.
   */
  function reclaimEther() external onlyOwner {
    owner.transfer(address(this).balance);
  }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}

/**
 * @title Contracts that should be able to recover tokens
 * @author SylTi
 * @dev This allow a contract to recover any ERC20 token received in a contract by transferring the balance to the contract owner.
 * This will prevent any accidental loss of tokens.
 */
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

  /**
   * @dev Reclaim all ERC20Basic compatible tokens
   * @param _token ERC20Basic The address of the token contract
   */
  function reclaimToken(ERC20Basic _token) external onlyOwner {
    uint256 balance = _token.balanceOf(this);
    _token.safeTransfer(owner, balance);
  }

}

/**
 * @title Contracts that should not own Tokens
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="285a4d454b47681a">[email&#160;protected]</a>π.com>
 * @dev This blocks incoming ERC223 tokens to prevent accidental loss of tokens.
 * Should tokens (any ERC20Basic compatible) end up in the contract, it allows the
 * owner to reclaim the tokens.
 */
contract HasNoTokens is CanReclaimToken {

 /**
  * @dev Reject all ERC223 compatible tokens
  * @param _from address The address that is transferring the tokens
  * @param _value uint256 the amount of the specified token
  * @param _data Bytes The data passed from the caller.
  */
  function tokenFallback(
    address _from,
    uint256 _value,
    bytes _data
  )
    external
    pure
  {
    _from;
    _value;
    _data;
    revert();
  }

}

/**
 * @title Contracts that should not own Contracts
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="24564149474b6416">[email&#160;protected]</a>π.com>
 * @dev Should contracts (anything Ownable) end up being owned by this contract, it allows the owner
 * of this contract to reclaim ownership of the contracts.
 */
contract HasNoContracts is Ownable {

  /**
   * @dev Reclaim ownership of Ownable contracts
   * @param _contractAddr The address of the Ownable to be reclaimed.
   */
  function reclaimContract(address _contractAddr) external onlyOwner {
    Ownable contractInst = Ownable(_contractAddr);
    contractInst.transferOwnership(owner);
  }
}

/**
 * @title Base contract for contracts that should not own things.
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="c1b3a4aca2ae81f3">[email&#160;protected]</a>π.com>
 * @dev Solves a class of errors where a contract accidentally becomes owner of Ether, Tokens or
 * Owned contracts. See respective base contracts for details.
 */
contract NoOwner is HasNoEther, HasNoTokens, HasNoContracts {
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to,
    uint256 _amount
  )
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

/**
 * @title Token Lockup Mixin
 * @dev Token mixin that gives possibility for token holders to have locked up (till release time) amounts of tokens on their balances. 
 * Token should check a balance spot for transfer and transferFrom functions to use this feature.
 */
contract TokenLockup is ERC20 {
    using SafeMath for uint256;  

    // LockedUp struct
    struct LockedUp {
        uint256 amount; // lockedup amount
        uint256 release; // release timestamp
    }

    // list of lockedup amounts and release timestamps
    mapping (address => LockedUp[]) public lockedup;

    // lockup event logging
    event Lockup(address indexed to, uint256 amount, uint256 release);

    /**
     * @dev Get the lockedup list count
     * @param _who address Address owns lockedup list
     * @return uint256 Lockedup list count     
     */
    function lockedUpCount(address _who) public view returns (uint256) {
        return lockedup[_who].length;
    }

    /**
     * @dev Find out if the address has locked up amounts
     * @param _who address Address checked for lockedup amounts
     * @return bool Returns true if address has lockedup amounts     
     */    
    function hasLockedUp(address _who) public view returns (bool) {
        return lockedup[_who].length > 0;
    }    

    /**
     * @dev Get balance locked up to the current moment of time
     * @param _who address Address owns lockedup amounts
     * @return uint256 Balance locked up to the current moment of time     
     */       
    function balanceLockedUp(address _who) public view returns (uint256) {
        uint256 _balanceLokedUp = 0;
        for (uint256 i = 0; i < lockedup[_who].length; i++) {
            if (lockedup[_who][i].release > block.timestamp) // solium-disable-line security/no-block-members
                _balanceLokedUp = _balanceLokedUp.add(lockedup[_who][i].amount);
        }
        return _balanceLokedUp;
    }    

    /**
     * @dev Lockup amount till release time
     * @param _who address Address gets the lockedup amount
     * @param _amount uint256 Amount to lockup
     * @param _release uint256 Release timestamp     
     */     
    function _lockup(address _who, uint256 _amount, uint256 _release) internal {
        if (_release > 0) {
            require(_who != address(0), "Lockup target address can&#39;t be zero.");
            require(_amount > 0, "Lockup amount should be > 0.");   
            require(_release > block.timestamp, "Lockup release time should be > now."); // solium-disable-line security/no-block-members 
            lockedup[_who].push(LockedUp(_amount, _release));
            emit Lockup(_who, _amount, _release);
        }            
    }      
}

/**
 * @title DiscoperiToken
 * @dev Discoperi Token contract. Tokens are generated during sales. Token
 * uses lockup capability.
 */
contract DiscoperiToken is TokenLockup, MintableToken, NoOwner {
    using SafeMath for uint256;

    // token constants
    string public constant name = "Discoperi Token"; // solium-disable-line uppercase
    string public constant symbol = "DISC"; // solium-disable-line uppercase
    uint8 public constant decimals = 18; // solium-disable-line uppercase

    // Total Tokens Supply
    uint256 public constant TOTAL_SUPPLY = 200000000000 * (10 ** uint256(decimals)); // 200,000,000,000 DISC

    // TOTAL_SUPPLY is distributed as follows
    uint256 public constant SALES_SUPPLY = 50000000000 * (10 ** uint256(decimals)); // 50,000,000,000 DISC - 25%
    uint256 public constant MARKET_DEV_SUPPLY = 50000000000 * (10 ** uint256(decimals)); // 50,000,000,000 DISC - 25%
    uint256 public constant TEAM_SUPPLY = 30000000000 * (10 ** uint256(decimals)); // 30,000,000,000 DISC - 15%
    uint256 public constant RESERVE_SUPPLY = 30000000000 * (10 ** uint256(decimals)); // 30,000,000,000 DISC - 15%
    uint256 public constant INVESTORS_ADVISORS_SUPPLY = 20000000000 * (10 ** uint256(decimals)); // 20,000,000,000 DISC - 10%
    uint256 public constant PR_ADVERSTISING_SUPPLY = 20000000000 * (10 ** uint256(decimals)); // 20,000,000,000 DISC - 10%

    // HARD CAPS
    uint256 public constant SEED_FUNDING_HARD_CAP = 1550000; // 1,550,000 USD
    uint256 public constant PRIVATE_PRESALE_HARD_CAP = 40000000; // 40,000,000 USDƒ
    uint256 public constant PUBLIC_PRESALE_HARD_CAP = 40000000; // 40,000,000 USD
    uint256 public constant ICO_HARD_CAP = 50000000; // 50,000,000 USD

    // private pre-sale address
    address public privatePresale;

    // public pre-sale address
    address public publicPresale;

    // public ico address
    address public ico;

    // tokens distributed suring sale stages
    uint256 public saleDitributed;

    // allocation event logging
    event Allocate(address indexed to, uint256 amount);

    // onlySaleContract modifier, restrict execution for sale contracts addresses
    modifier onlySaleContract() {
        require(_isSaleContract(), "Unauthorized attempt");
        _;
    }

    // spotTransfer modifier, check balance spot on transfer
    modifier spotTransfer(address _from, uint256 _value) {
        require(_value <= balanceSpot(_from), "Attempt to transfer more than balance spot");
        _;
    }

    /**
     * @dev Set Discoperi sale contracts addresses
     * @param _privatePresale address of the Discoperi Private ico contract
     * @param _publicPresale address of the Discoperi Private ico contract
     * @param _ico address of the Discoperi ico contract
     */  
    function setSaleContracts(address _privatePresale, address _publicPresale, address _ico) external onlyOwner {
        require(_privatePresale != address(0), "Private pre-sale address should not be equal to zero address");
        require(_publicPresale != address(0), "Public Pre-sale address should not be equal to zero address");
        require(_ico != address(0), "ICO address should not be equal to zero address");

        require(privatePresale == address(0), "Attempt to override already existing private pre-sale address");
        require(publicPresale == address(0), "Attempt to override already existing public pre-sale address");
        require(ico == address(0), "Attempt to override already existing ICO address");

        privatePresale = _privatePresale;
        publicPresale = _publicPresale;
        ico = _ico;
    }

    /**
     * @dev Allocate tokens during sales, amount can be locked up
     * @param _to address Address gets the tokens
     * @param _amount uint256 Amount to allocate
     * @param _releaseTime uint256 Tokens release timestamp (can be zero to omit locking up) 
     */ 
    function allocate(address _to, uint256 _amount, uint256 _releaseTime) external onlySaleContract {
        require(_to != address(0), "Allocate To address can&#39;t be zero");
        require(_amount > 0, "Allocate amount should be > 0.");
       
        totalSupply_ = totalSupply_.add(_amount);
        saleDitributed = saleDitributed.add(_amount);  
        balances[_to] = balances[_to].add(_amount);

        require(saleDitributed <= SALES_SUPPLY, "Can&#39;t allocate more than SALES SUPPLY.");
        require(totalSupply_ <= TOTAL_SUPPLY, "Can&#39;t allocate more than TOTAL SUPPLY.");

        emit Transfer(address(0), _to, _amount);

        mint(_to, _amount);  

        if (_releaseTime != uint256(0)) {
            _lockup(_to, _amount, _releaseTime);
        }
    }  

    /**
     * @dev Get balance spot for the current moment of time
     * @param _who Address owns balance spot
     * @return uint256 Balance spot for the current moment of time     
     */   
    function balanceSpot(address _who) public view returns (uint256) {
        uint256 _balanceSpot = balanceOf(_who);
        _balanceSpot = _balanceSpot.sub(balanceLockedUp(_who));      
        return _balanceSpot;
    }     
       
    /**
     * @dev Transfer tokens from one address to another
     * @param _to address The address which you want to transfer to
     * @param _value uint256 The amount of tokens to be transferred
     * @return bool Returns true if the transfer was succeeded
     */
    function transfer(address _to, uint256 _value) public spotTransfer(msg.sender, _value) returns (bool) {
        return super.transfer(_to, _value);
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 The amount of tokens to be transferred
     * @return bool Returns true if the transfer was succeeded
     */
    function transferFrom(address _from, address _to, uint256 _value) public spotTransfer(_from, _value) returns (bool) {    
        return super.transferFrom(_from, _to, _value);
    }

    /**
     * @dev  Check if caller is sale contract
     * @return bool Returns true if caller is sale contract
     */
    function _isSaleContract() internal view returns (bool) {
        if (msg.sender == ico || msg.sender == publicPresale || msg.sender == privatePresale)
            return true;
        return false;
    }
}

/**
 * @title DiscoperiPrivatePresale
 * @dev Pre-sale contract that distributes tokens sold during the private pre-sale stage.
 * Appropriate distribute functions should be called outside the blockchain to 
 * distribute the pre-sale tokens amount to the pre-sale funders
 */
contract DiscoperiPrivatePresale is HasNoEther {
    using SafeMath for uint256;

    // Discoperi Token contract
    DiscoperiToken public token;

    // amount of tokens distributed during private pre-sale 
    uint256 public privatePresaleDistributed;

    // private pre-sale funders
    address[] public privatePresaleFunders;

    // LockedBalance struct
    struct PrivatePresaleBalance {
        uint256 amount; // amount of tokens
        uint256 release; // tokens release timestamp
    }

    // tokens to allocate to private pre-sale funders
    mapping (address => PrivatePresaleBalance) public privatePresaleBalances;

    // is private pre-sale tokens allocated
    bool public privatePresaleTokensAllocated;

    // private pre-sale distribute event logging
    event PrivatePresaleDistribute(address indexed to, uint256 amount);
    

    /**
     * @dev Constructor
     * @param _token address DiscoperiToken contract address  
     */
    constructor(DiscoperiToken _token) public {
        require(_token != address(0), "Token address can&#39;t be zero.");
        token = DiscoperiToken(_token); 
    }

    /**
     * @dev Get private pre-sale funders count
     * @return uint256 Private pre-sale funders count
     */
    function getPrivatePresaleFundersCount() public view returns(uint256) {
        return privatePresaleFunders.length;
    }

    /**
     * @dev Allocate tokens to private pre-sale funders
     */
    function allocatePrivatePresaleTokens() external {
        require(!privatePresaleTokensAllocated, "Attemp to allocate private pre-sale tokens twice");

        for (uint256 i = 0; i < getPrivatePresaleFundersCount(); i++) {
            address _funder = privatePresaleFunders[i];
            uint256 _tokens = privatePresaleBalances[_funder].amount;

            token.allocate(_funder, _tokens, 0);
            privatePresaleDistributed = privatePresaleDistributed.add(_tokens);

            emit PrivatePresaleDistribute(_funder, _tokens);
        }
        
        privatePresaleTokensAllocated = true;
    } 

}