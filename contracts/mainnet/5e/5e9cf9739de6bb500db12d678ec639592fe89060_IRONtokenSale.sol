pragma solidity ^0.4.21;

/**
 * iron Bank Network
 * https://www.ironbank.network
 * Based on Open Zeppelin - https://github.com/OpenZeppelin/zeppelin-solidity
 */

/*
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

/**
 * 
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

/**
 * @title PoolParty Token
 * @author Alber Erre
 * @notice Follow up token holders to give them collected fees in the future. Holders are stored in "HOLDersList"
 * @dev This is the first part of the functionality, this contract just enable tracking token holders
 * @dev Next part is defined as "PoolPartyPayRoll" contract
 */
contract PoolPartyToken is Ownable {
  using SafeMath for uint256;

  struct HOLDers {
    address HOLDersAddress;
  }

  HOLDers[] public HOLDersList;

  function _alreadyInList(address _thisHODLer) internal view returns(bool HolderinList) {

    bool result = false;
    for (uint256 r = 0; r < HOLDersList.length; r++) {
      if (HOLDersList[r].HOLDersAddress == _thisHODLer) {
        result = true;
        break;
      }
    }
    return result;
  }

  // Call AddHOLDer function every time a token is sold, "_alreadyInList" avoids duplicates
  function AddHOLDer(address _thisHODLer) internal {

    if (_alreadyInList(_thisHODLer) == false) {
      HOLDersList.push(HOLDers(_thisHODLer));
    }
  }

  function UpdateHOLDer(address _currentHODLer, address _newHODLer) internal {

    for (uint256 r = 0; r < HOLDersList.length; r++){
      // Send individual token holder payroll
      if (HOLDersList[r].HOLDersAddress == _currentHODLer) {
        // write new holders address
        HOLDersList[r].HOLDersAddress = _newHODLer;
      }
    }
  }
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is PoolPartyToken, ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * OpenBarrier modifier by Alber Erre
  * @notice security trigger in case something fails during minting, token sale or Airdrop
  */
  bool public transferEnabled;    //allows contract to lock transfers in case of emergency

  modifier openBarrier() {
      require(transferEnabled || msg.sender == owner);
      _;
  }

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) openBarrier public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);

    // update HODLer address, for iron profit distribution to iron holders - PoolParty
    UpdateHOLDer(msg.sender, _to);

    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
}

/**
 * @title PoolParty PayRoll
 * @author Alber Erre
 * @notice This enables fees distribution (Money!) among token holders
 * @dev This is the second part of the PoolParty functionality, this contract allow us to distributed the fees collected...
 * @dev ...between token holders, if you hold you get paid, that is the idea.
 */
contract PoolPartyPayRoll is BasicToken {
  using SafeMath for uint256;

  mapping (address => uint256) PayRollCount;

  // Manually spread iron profits to token holders
  function _HOLDersPayRoll() onlyOwner public {

    uint256 _amountToPay = address(this).balance;
    uint256 individualPayRoll = _amountToPay.div(uint256(HOLDersList.length));

    for (uint256 r = 0; r < HOLDersList.length; r++){
      // Send individual token holder payroll
      address HODLer = HOLDersList[r].HOLDersAddress;
      HODLer.transfer(individualPayRoll);
      // Add counter, to check how many times an address has been paid (the higher the most time this address has HODL)
      PayRollCount[HOLDersList[r].HOLDersAddress] = PayRollCount[HOLDersList[r].HOLDersAddress].add(1);
    }
  }

  function PayRollHistory(address _thisHODLer) external view returns (uint256) {

    return uint256(PayRollCount[_thisHODLer]);
  }
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is PoolPartyPayRoll, ERC20 {

  mapping (address => mapping (address => uint256)) internal allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) openBarrier public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);

    // update HODLer address, for iron profit distribution to iron holders - PoolParty
    UpdateHOLDer(msg.sender, _to);

    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
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
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
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
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint external returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);

    // Add holder for future iron profits distribution - PoolParty
    AddHOLDer(_to);

    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint external returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

/**
 * @title Contracts that should be able to recover tokens
 * @author SylTi
 * @dev This allow a contract to recover any ERC20 token received in a contract by transferring the balance to the contract owner.
 * This will prevent any accidental loss of tokens. - updated to "recoverERC20Token_SendbyMistake"
 */
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

  /**
   * @dev Reclaim all ERC20Basic compatible tokens
   * @param missing_token ERC20Basic The address of the token contract (missing_token)
   */
  function recoverERC20Token_SendbyMistake(ERC20Basic missing_token) external onlyOwner {
    uint256 balance = missing_token.balanceOf(this);
    missing_token.safeTransfer(owner, balance);
  }
}

/**
 * @title Contracts that should not own Ether
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="89fbece4eae6c9bb">[email&#160;protected]</a>π.com>
 * @dev This tries to block incoming ether to prevent accidental loss of Ether. Should Ether end up
 * in the contract, it will allow the owner to reclaim this ether.
 * @notice Ether can still be send to this contract by:
 * calling functions labeled `payable`
 * `selfdestruct(contract_address)`
 * mining directly to the contract address
*/
contract HasEther is Ownable {

  /**
   * @dev allows direct send by settings a default function with the `payable` flag.
   */
  function() public payable {
  }

  /**
   * @dev Transfer all Ether held by the contract to the owner.
   */
  function recoverETH_SendbyMistake() external onlyOwner {
    // solium-disable-next-line security/no-send
    assert(owner.send(address(this).balance));
  }
}

/**
 * @title Contracts that should not own Contracts
 * @notice updated to "reclaimChildOwnership", ease to remember function&#39;s nature @AlberEre
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="7002151d131f3042">[email&#160;protected]</a>π.com>
 * @dev Should contracts (anything Ownable) end up being owned by this contract, it allows the owner
 * of this contract to reclaim ownership of the contracts.
 */
contract HasNoContracts is Ownable {

  /**
   * @dev Reclaim ownership of Ownable contracts
   * @param contractAddr The address of the Ownable to be reclaimed.
   */
  function reclaimChildOwnership(address contractAddr) public onlyOwner {
    Ownable contractInst = Ownable(contractAddr);
    contractInst.transferOwnership(owner);
  }
}

/**
 * @title iron Token Contract
 * @notice "openBarrier" modifier applied, security check during minting process
 */
contract IRONtoken is MintableToken, CanReclaimToken, HasEther, HasNoContracts {

  string public constant name = "iron Bank Network token"; // solium-disable-line uppercase
  string public constant symbol = "IRON"; // solium-disable-line uppercase
  uint8 public constant decimals = 18; // solium-disable-line uppercase

  function IRONtoken() public {
  }

  function setBarrierAsOpen(bool enable) onlyOwner public {
      // bool(false) during token sale, bool(true) once token sale is finished
      transferEnabled = enable;
  }
}

/**
 * @title iron Token Sale
 */
contract IRONtokenSale is PoolPartyToken, CanReclaimToken, HasNoContracts {
    using SafeMath for uint256;

    IRONtoken public token;

    struct Round {
        uint256 start;          //Timestamp of token sale start (this stage)
        uint256 end;            //Timestamp of token sale end (this stage)
        uint256 rate;           //How much IRON you will receive per 1 ETH within this stage
    }

    Round[] public rounds;          //Array of token sale stages
    uint256 public hardCap;         //Max amount of tokens to mint
    uint256 public tokensMinted;    //Amount of tokens already minted
    bool public finalized;          //token sale is finalized

    function IRONtokenSale (uint256 _hardCap, uint256 _initMinted) public {

      token = new IRONtoken();
      token.setBarrierAsOpen(false);
      tokensMinted = token.totalSupply();
      require(_hardCap > 0);
      hardCap = _hardCap;
      mintTokens(msg.sender, _initMinted);
    }

    function addRound(uint256 StartTimeStamp, uint256 EndTimeStamp, uint256 Rate) onlyOwner public {
      rounds.push(Round(StartTimeStamp, EndTimeStamp, Rate));
    }

    /**
    * @notice Mint tokens for Airdrops (only external) by Alber Erre
    */
    function saleAirdrop(address beneficiary, uint256 amount) onlyOwner external {
        mintTokens(beneficiary, amount);
    }
    
    /**
    * @notice Mint tokens for multiple addresses for Airdrops (only external) - Alber Erre
    */
    function MultiplesaleAirdrop(address[] beneficiaries, uint256[] amounts) onlyOwner external {
      for (uint256 r=0; r<beneficiaries.length; r++){
        mintTokens(address(beneficiaries[r]), uint256(amounts[r]));
      }
    }
    
    /**
    * @notice Shows if crowdsale is running
    */ 
    function ironTokensaleRunning() view public returns(bool){
        return (!finalized && (tokensMinted < hardCap));
    }

    function currentTime() view public returns(uint256) {
      return uint256(block.timestamp);
    }

    /**
    * @notice Return current round according to current time
    */ 
    function RoundIndex() internal returns(uint256) {
      uint256 index = 0;
      for (uint256 r=0; r<rounds.length; r++){
        if ( (rounds[r].start < uint256(block.timestamp)) && (uint256(block.timestamp) < rounds[r].end) ) {
          index = r.add(1);
        }
      }
      return index;
    }

    function currentRound() view public returns(uint256) {
      return RoundIndex();
    }

    function currentRate() view public returns(uint256) {
        uint256 thisRound = RoundIndex();
        if (thisRound != 0) {
            return uint256(rounds[thisRound.sub(1)].rate);
        } else {
            return 0;
        }
    }
    
    function _magic(uint256 _weiAmount) internal view returns (uint256) {
      uint256 tokenRate = currentRate();
      require(tokenRate > 0);
      uint256 preTransformweiAmount = tokenRate.mul(_weiAmount);
      uint256 transform = 10**18;
      uint256 TransformedweiAmount = preTransformweiAmount.div(transform);
      return TransformedweiAmount;
    }

    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     */
    function () external payable {
      require(msg.value > 0);
      require(ironTokensaleRunning());
      uint256 weiAmount = msg.value;
      uint256 tokens = _magic(weiAmount);
      JustForward(msg.value);
      mintTokens(msg.sender, tokens);
    }

    /**
    * @notice mint tokens and apply PoolParty method (Alber Erre)
    * @dev Helper function to mint tokens and increase tokensMinted counter
    */
    function mintTokens(address beneficiary, uint256 amount) internal {
        tokensMinted = tokensMinted.add(amount);       

        require(tokensMinted <= hardCap);
        assert(token.mint(beneficiary, amount));

        // Add holder for future iron profits distribution
        AddHOLDer(beneficiary);
    }

    function JustForward(uint256 weiAmount) internal {
      owner.transfer(weiAmount);
    }

    function forwardCollectedEther() onlyOwner public {
        if(address(this).balance > 0){
            owner.transfer(address(this).balance);
        }
    }

    /**
    * @notice ICO End: "openBarrier" no longer applied, allows token transfers
    */
    function finalizeTokensale() onlyOwner public {
        finalized = true;
        assert(token.finishMinting());
        token.setBarrierAsOpen(true);
        token.transferOwnership(owner);
        forwardCollectedEther();
    }
}