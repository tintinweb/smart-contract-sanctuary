pragma solidity ^0.4.12;

/**
 * ===== Zeppelin library =====
 */

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

/**
 * @title Contracts that should not own Ether
 * @author Remco Bloemen <<span class="__cf_email__" data-cfemail="2a584f4749456a18">[email&#160;protected]</span>π.com>
 * @dev This tries to block incoming ether to prevent accidental loss of Ether. Should Ether end up
 * in the contract, it will allow the owner to reclaim this ether.
 * @notice Ether can still be send to this contract by:
 * calling functions labeled `payable`
 * `selfdestruct(contract_address)`
 * mining directly to the contract address
*/
contract HasNoEther is Ownable {

  /**
  * @dev Constructor that rejects incoming Ether
  * @dev The `payable` flag is added so we can access `msg.value` without compiler warning. If we
  * leave out payable, then Solidity will allow inheriting contracts to implement a payable
  * constructor. By doing it this way we prevent a payable constructor from working. Alternatively
  * we could use assembly to access msg.value.
  */
  function HasNoEther() payable {
    require(msg.value == 0);
  }

  /**
   * @dev Disallows direct send by settings a default function without the `payable` flag.
   */
  function() external {
  }

  /**
   * @dev Transfer all Ether held by the contract to the owner.
   */
  function reclaimEther() external onlyOwner {
    assert(owner.send(this.balance));
  }
}


/** 
 * @title Contracts that should not own Contracts
 * @author Remco Bloemen <<span class="__cf_email__" data-cfemail="0371666e606c4331">[email&#160;protected]</span>π.com>
 * @dev Should contracts (anything Ownable) end up being owned by this contract, it allows the owner
 * of this contract to reclaim ownership of the contracts.
 */
contract HasNoContracts is Ownable {

  /**
   * @dev Reclaim ownership of Ownable contracts
   * @param contractAddr The address of the Ownable to be reclaimed.
   */
  function reclaimContract(address contractAddr) external onlyOwner {
    Ownable contractInst = Ownable(contractAddr);
    contractInst.transferOwnership(owner);
  }
}

/**
 * @title Contracts that should not own Tokens
 * @author Remco Bloemen <<span class="__cf_email__" data-cfemail="ed9f88808e82addf">[email&#160;protected]</span>π.com>
 * @dev This blocks incoming ERC23 tokens to prevent accidental loss of tokens.
 * Should tokens (any ERC20Basic compatible) end up in the contract, it allows the
 * owner to reclaim the tokens.
 */
contract HasNoTokens is Ownable {

 /**
  * @dev Reject all ERC23 compatible tokens
  * @param from_ address The address that is transferring the tokens
  * @param value_ uint256 the amount of the specified token
  * @param data_ Bytes The data passed from the caller.
  */
  function tokenFallback(address from_, uint256 value_, bytes data_) external {
    revert();
  }

  /**
   * @dev Reclaim all ERC20Basic compatible tokens
   * @param tokenAddr address The address of the token contract
   */
  function reclaimToken(address tokenAddr) external onlyOwner {
    ERC20Basic tokenInst = ERC20Basic(tokenAddr);
    uint256 balance = tokenInst.balanceOf(this);
    tokenInst.transfer(owner, balance);
  }
}



/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
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

  /**
   * @dev Function to mint tokens
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

/**
 * ===== DFS contracts =====
 */


/**
 * @title DFS token
 */
contract DFSToken is MintableToken, HasNoEther, HasNoContracts, HasNoTokens { //MintableToken is StandardToken, Ownable
    using SafeMath for uint256;

    string public name = "DFS";
    string public symbol = "DFS";
    uint256 public decimals = 18;

}

/**
 * @title DFS Crowdsale
 */
contract DFSCrowdsale is Ownable, HasNoTokens {
    using SafeMath for uint256;

    uint256 public constant MAXIMUM_SUPPLY = 50000000000000000000000000; //Supply of tokens available for ICO. Initial value = 50 000 000 tokens, converted to token units
    uint256 public constant OWNER_TOKENS = MAXIMUM_SUPPLY * 25 / 100;


    uint256 public availableSupply;     //Supply of tokens available for ICO.
    uint256 public startTimestamp;      //Start crowdsale timestamp
    uint256 public endTimestamp;        //End crowdsale timestamp
    uint256 public price;               //Price: how many token units one will receive per wei
    DFSToken public dfs;               //Token contract
    bool public finalized;              //crowdsale is finalized

  /**
   * Event for token sale logging
   * @param to who purshased tokens
   * @param eth weis paid for purchase
   * @param tokens amount of token units purchased
   */ 
    event LogSale(address indexed to, uint256 eth, uint256 tokens);

    /**
     * Throws if crowdsale is not running: not started, ended or max cap reached
     */
    modifier crowdsaleIsRunning(){
        //require(now > startTimestamp);
        //require(now <= endTimestamp);
        //require(availableSupply > 0);
        require(crowdsaleRunning());
        _;
    }

    /**
     * @dev DFS Crowdsale Contract
     * @param _startTimestamp time when crowdsale is staring
     * @param _endTimestamp time when crowdsale is finished
     * @param _price crowdsale price (how many token units one will receive per wei)
     */
    function DFSCrowdsale(uint256 _startTimestamp, uint256 _endTimestamp, uint256 _price){
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        price = _price;
        availableSupply = MAXIMUM_SUPPLY;

        dfs = new DFSToken();
        mintTokens(owner, OWNER_TOKENS);
    }

    function() payable crowdsaleIsRunning {
        require(msg.value > 0);
        uint256 tokens = price.mul(msg.value);
        assert(tokens > 0);
        require(availableSupply - tokens >= 0);

        mintTokens(msg.sender, tokens);
        LogSale(msg.sender, msg.value, tokens);
    } 

    function crowdsaleRunning() constant public returns(bool){
        return (now > startTimestamp) &&  (now <= endTimestamp) && (availableSupply > 0) && !finalized;
    }


    /**
    * @dev Mints tokens for owner and for crowdsale participants 
    * @param _to whom to send tokens
    * @param _amount how many tokens to send
    */
    function mintTokens(address _to, uint256 _amount) private {
        availableSupply = availableSupply.sub(_amount);
        dfs.mint(_to, _amount);
    }


    /**
    * @dev Finalizes crowdsale when one of conditions met:
    * - end time reached OR
    * - no more tokens available (cap reached) OR
    * - message sent by owner
    */
    function finalizeCrowdsale() public {
        require ( (now > endTimestamp) || (availableSupply == 0) || (msg.sender == owner) );
        finalized = dfs.finishMinting();
        dfs.transferOwnership(owner);
    } 

    /**
    * @dev Sends collected funds to owner
    */
    function withdrawFunds(uint256 amount) public onlyOwner {
        owner.transfer(amount);
    }

}