/**
 *Submitted for verification at Etherscan.io on 2020-08-31
*/

pragma solidity ^0.6.12;

// SPDX-License-Identifier: GPL-3.0

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
    constructor() public {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized operation");
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Address shouldn't be zero");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address _owner) external view returns (uint256);


    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @dev Simple ERC20 Token example, with mintable token creation only during the deployement of the token contract */

contract TokenContract is Ownable{
  using SafeMath for uint256;

  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;
  address public tokenOwner;
  address private ico;

  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;
  mapping(address => bool) public vestedlist;

  event SetICO(address indexed _ico);
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  event UnlockToken();
  event LockToken();
  event Burn();
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event addedToVestedlist(address indexed _vestedAddress);
  event removedFromVestedlist(address indexed _vestedAddress);

  
  bool public mintingFinished = false;
  bool public locked = true;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }
  
  modifier canTransfer() {
    require(!locked || msg.sender == owner || msg.sender == ico);
    _;
  }
  
  modifier onlyAuthorized() {
    require(msg.sender == owner || msg.sender == ico);
    _;
  }


  constructor(string memory _name, string memory  _symbol, uint8 _decimals) public {
    require (_decimals != 0);
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    totalSupply = 0;
    balances[msg.sender] = totalSupply;
    emit Transfer(address(0), msg.sender, totalSupply);


  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) public onlyAuthorized canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(this), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() public onlyAuthorized canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public canTransfer returns (bool) {
    require(_to != address(0));
	require (!isVestedlisted(msg.sender));
    require(_value <= balances[msg.sender]);
    require (msg.sender != address(this));

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }


  function burn(address _who, uint256 _value) onlyAuthorized public returns (bool){
    require(_who != address(0));
    
    totalSupply = totalSupply.sub(_value);
    balances[_who] = balances[_who].sub(_value);
    emit Burn();
    emit Transfer(_who, address(0), _value);
    return true;
  }
  

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
  
  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public canTransfer returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function transferFromERC20Contract(address _to, uint256 _value) public onlyOwner returns (bool) {
    require(_to != address(0));
    require(_value <= balances[address(this)]);
    balances[address(this)] = balances[address(this)].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(address(this), _to, _value);
    return true;
  }


  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
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

  function unlockToken() public onlyAuthorized returns (bool) {
    locked = false;
    emit UnlockToken();
    return true;
  }

  function lockToken() public onlyAuthorized returns (bool) {
    locked = true;
    emit LockToken();
    return true;
  }
  
  function setICO(address _icocontract) public onlyOwner returns (bool) {
    require(_icocontract != address(0));
    ico = _icocontract;
    emit SetICO(_icocontract);
    return true;
  }

    /**
     * @dev Adds list of addresses to Vestedlist. Not overloaded due to limitations with truffle testing.
     * @param _vestedAddress Addresses to be added to the Vestedlist
     */
    function addToVestedlist(address[] memory _vestedAddress) public onlyOwner {
        for (uint256 i = 0; i < _vestedAddress.length; i++) {
            if (vestedlist[_vestedAddress[i]]) continue;
            vestedlist[_vestedAddress[i]] = true;
        }
    }


    /**
     * @dev Removes single address from Vestedlist.
     * @param _vestedAddress Address to be removed to the Vestedlist
     */
    function removeFromVestedlist(address[] memory _vestedAddress) public onlyOwner {
        for (uint256 i = 0; i < _vestedAddress.length; i++) {
            if (!vestedlist[_vestedAddress[i]]) continue;
            vestedlist[_vestedAddress[i]] = false;
        }
    }


    function isVestedlisted(address _vestedAddress) internal view returns (bool) {
      return (vestedlist[_vestedAddress]);
    }

}

/**
 * @title PullPayment
 * @dev Base contract supporting async send for pull payments. Inherit from this
 * contract and use asyncSend instead of send.
 */
contract PullPayment {
    using SafeMath for uint256;

    mapping (address => uint256) public payments;

    uint256 public totalPayments;

    /**
    * @dev Called by the payer to store the sent amount as credit to be pulled.
    * @param dest The destination address of the funds.
    * @param amount The amount to transfer.
    */
    function asyncSend(address dest, uint256 amount) internal{
        payments[dest] = payments[dest].add(amount);
        totalPayments = totalPayments.add(amount);
    }

    /**
    * @dev withdraw accumulated balance, called by payee.
    */
    function withdrawPayments() internal{
        address payable payee = msg.sender;
        uint256 payment = payments[payee];

        require(payment != 0);
        require(address(this).balance >= payment);

        totalPayments = totalPayments.sub(payment);
        payments[payee] = 0;

        assert(payee.send(payment));
    }
}

/**
 * @title ICO
 * @dev ICO is a base contract for managing a public token sale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for a public sale. They are *not* intended to be modified / overriden.
 * The internal interface conforms the extensible and modifiable surface of public token sales. Override
 * the methods to add functionality. Consider using 'super' where appropiate to concatenate
 * behavior.
 */

contract ICO is PullPayment, Ownable {

  using SafeMath for uint256;

  // The token being sold
  TokenContract public token;

  // Address where funds are collected
  address payable public wallet;

  // Address to receive project tokens
  address public projectOwner;

  // Refund period if the ICO failed
  uint256 public refundPeriod;

  // How many token units a buyer gets per ETH/wei during Pre sale. The ETH price is fixed at 400$ during Pre sale.
  uint256 public Presalerate = 0.00025 ether;   //  1 DCASH Token = 0.10 $ = 0.00025 Ether

  // How many token units a buyer gets per ETH/wei during ICO. The ETH price is fixed at 400$ during the ICO to guarantee the 30 % discount rate with the presale rate
  uint256 public Icorate = 0.000325 ether;    //  1 DCASH Token = 0.13 $ = 0.000325 Ether
 
  // Amount of ETH/Wei raised during the ICO period
  uint256 public EthRaisedIco;

  // Amount of ETH/wei raised during the Pre sale
  uint256 public EthRaisedpresale;

  // Token amount distributed during the ICO period
  uint256 public tokenDistributed;

  // Token amount distributed during the Pre sale
  uint256 public tokenDistributedpresale;

  // investors part according to the whitepaper 60 % (50% ICO + 10% PreSale) 
  uint256 public investors = 60;
  
  // Min purchase size of incoming ETH during pre sale period fixed at 2 ETH valued at 800 $ 
  uint256 public constant MIN_PURCHASE_Presale = 2 ether;

  // Minimum purchase size of incoming ETH during ICO at 1$
  uint256 public constant MIN_PURCHASE_ICO = 0.0025 ether;

  // Hardcap cap in Ether raised during Pre sale fixed at $ 200 000 for ETH valued at 440$ 
  uint256 public PresaleSalemaxCap1 = 500 ether;

  // Softcap funding goal during ICO in Ether raised fixed at $ 200 000 for ETH valued at 400$.
  uint256 public ICOminCap = 500 ether;

  // Hardcap goal in Ether during ICO in Ether raised fixed at $ 13 000 000 for ETH valued at 400$
  uint256 public ICOmaxCap = 32500 ether;

  // presale start/end
  bool public presale = true;    // State of the ongoing sales Pre sale 
  
  // ICO start/end
  bool public ico = false;         // State of the ongoing sales ICO period

  // Balances in incoming Ether
  mapping(address => uint256) balances;
  
  // Bool to check that the Presalesale period is launch only one time
  bool public statepresale = false;
  
  // Bool to check that the ico is launch only one time
  bool public stateico = true;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event NewContract(address indexed _from, address indexed _contract, string _type);

  /**
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the ERC20 Token
   * @param _project Address where the Token of the project will be sent
   */
  constructor(address payable _wallet, address _token, address _project) public {
    require(_wallet != address(0) && _token != address(0) && _project != address(0));
    wallet = _wallet;
    token = TokenContract(_token);    
    projectOwner = _project;

  }

  // -----------------------------------------
  // ICO external interface
  // -----------------------------------------

  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
  receive() external payable {
     if (presale) {
      buypresaleTokens(msg.sender);
    }

    if (ico) {
      buyICOTokens(msg.sender);
    }
  }

  function buypresaleTokens (address _beneficiary) internal {
    require(_beneficiary != address(0) , "Failed the wallet is not allowed");  
    require(msg.value >= MIN_PURCHASE_Presale, "Failed the amount is not respecting the minimum deposit of Presale ");
    // Check that if investors sends more than the MIN_PURCHASE_Presale
    uint256 weiAmount = msg.value;
	// According to the whitepaper the backers who invested on Presale Sale have not possibilities to be refunded. Their ETH Balance is updated to zero value.
	balances[msg.sender] = 0;
    // calculate token amount to be created
    uint256 tokensTocreate = _getTokenpresaleAmount(weiAmount);
    _getRemainingTokenStock(_beneficiary, tokensTocreate);
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokensTocreate);

    // update state
    EthRaisedpresale = EthRaisedpresale.add(weiAmount);
    tokenDistributedpresale = tokenDistributedpresale.add(tokensTocreate);

    // If Presale Sale softcap is reached then the ether on the ICO contract are send to project wallet
    if (EthRaisedpresale <= PresaleSalemaxCap1) {
      wallet.transfer(address(this).balance);
    } else {
      //If PresaleSalemaxCap1 is reached then the presale is closed
      if (EthRaisedpresale >= PresaleSalemaxCap1) {
        presale = false;
      }
    }
  }
  
  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * @param _beneficiary Address performing the token purchase
   */
  function buyICOTokens(address _beneficiary) internal {
	require(_beneficiary != address(0) , "Failed the wallet is not allowed");  
    require(msg.value >= MIN_PURCHASE_ICO, "Failed the amount is not respecting the minimum deposit of ICO");
    // Check that if investors sends more than the MIN_PURCHASE_ICO
    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokensTocreate = _getTokenAmount(weiAmount);

    // Look if there is token on the contract if he is not create the amount of token
    _getRemainingTokenStock(_beneficiary, tokensTocreate);
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokensTocreate);

    // update state
    EthRaisedIco = EthRaisedIco.add(weiAmount);

    // Creation of the token and transfer to beneficiary
    tokenDistributed = tokenDistributed.add(tokensTocreate);

    // Update the balance of benificiary
    balances[_beneficiary] = balances[_beneficiary].add(weiAmount);

    uint256 totalEthRaised = EthRaisedIco.add(EthRaisedpresale);

    // If ICOminCap is reached then the ether on the ICO contract are send to project wallet
    if (totalEthRaised >= ICOminCap && totalEthRaised <= ICOmaxCap) {
      wallet.transfer(address(this).balance);
    }

    //If ICOmaxCap is reached then the ICO close
    if (totalEthRaised >= ICOmaxCap) {
      ico = false;
    }
  }

  /* ADMINISTRATIVE FUNCTIONS */

  // Update the ETH ICO rate  
  function updateETHIcoRate(uint256 _EtherAmount) public onlyOwner {
    Icorate = (_EtherAmount).mul(1 wei);
  }
  
    // Update the ETH PreSale rate  
  function updateETHPresaleRate(uint256 _EtherAmount) public onlyOwner {
    Presalerate = (_EtherAmount).mul(1 wei);
  }

    // Update the ETH ICO MAX CAP  
  function updateICOMaxcap(uint256 _EtherAmount) public onlyOwner {
    ICOmaxCap = (_EtherAmount).mul(1 wei);
  }

  // start presale
  function startpresale() public onlyOwner {
    require(statepresale && !ico,"Failed the Presale was already started or another sale is ongoing");
    presale = true;
    statepresale = false;
    token.lockToken();
  }

  // close Presale
  function closepresale() public onlyOwner {
    require(presale && !ico, "Failed it was already closed");
    presale = false;
  }
 
 // start ICO
  function startICO() public onlyOwner {

    // bool to see if the ico has already been launched and  presale is not in progress
    require(stateico && !presale, "Failed the ICO was already started or another salae is ongoing");

    refundPeriod = now.add(2764800);
      // 32 days in seconds ==> 32*24*3600

    ico = true;
    token.lockToken();

    // Put the bool to False to block the start of this function again
    stateico = false;
  }

  // close ICO
  function closeICO() public onlyOwner {
    require(!presale && ico,"Failed it was already closed");
    ico = false;
  }

  /* When ICO MIN_CAP is not reach the smart contract will be credited to make refund possible by backers
   * 1) backer call the "refund" function of the ICO contract
   * 2) backer call the "reimburse" function of the ICO contract to get a refund in ETH
   */
  function refund() public {
    require(_refundPeriod());
    require(balances[msg.sender] > 0);

    uint256 ethToSend = balances[msg.sender];
    balances[msg.sender] = 0;
    asyncSend(msg.sender, ethToSend);
  }

  function reimburse() public {
    require(_refundPeriod());
    withdrawPayments();
    EthRaisedIco = address(this).balance;
  }

  // Function to pay out if the ICO is successful
  function WithdrawFunds() public onlyOwner {
    require(!ico && !presale, "Failed a sales is ongoing");
    require(now > refundPeriod.add(7776000) || _isSuccessful(), "Failed the refund period is not finished");
    //  90 days in seconds ==> 2*30*24*3600
    if (_isSuccessful()) {
      uint256 _tokensProjectToSend = _getTokenAmountToDistribute(100 - investors);
      _getRemainingTokenStock(projectOwner, _tokensProjectToSend);
      token.unlockToken();
    } else {
      wallet.transfer(EthRaisedIco);
    }
    
    // burn in case that there is some not distributed tokens on the contract
    if (token.balanceOf(address(this)) > 0) {
      uint256 totalDistributedToken = tokenDistributed;
      token.burn(address(this),totalDistributedToken);
    }
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */

  // Calcul the amount of token the benifiaciary will get by buying during Presale 
  function _getTokenpresaleAmount(uint256 _weiAmount) internal view returns (uint256) {
    uint256 _amountToSend = _weiAmount.div(Presalerate).mul(10 ** 10);
    return _amountToSend;
  }
  
  // Calcul the amount of token the benifiaciary will get by buying during Sale
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    uint256 _amountToSend = _weiAmount.div(Icorate).mul(10 ** 10);
    return _amountToSend;
  }

  // Calcul the token amount to distribute in the forwardFunds for the project (team, bounty ...)
  function _getTokenAmountToDistribute(uint _part) internal view returns (uint256) {
    uint256 _delivredTokens = tokenDistributed.add(tokenDistributedpresale);
    return (_part.mul(_delivredTokens).div(investors));

  }

  // verify the remaining token stock & deliver tokens to the beneficiary
  function _getRemainingTokenStock(address _beneficiary, uint256 _tokenAmount) internal {
    if (token.balanceOf(address(this)) >= _tokenAmount) {
      require(token.transfer(_beneficiary, _tokenAmount));
    }
    else {
      if (token.balanceOf(address(this)) == 0) {
        require(token.mint(_beneficiary, _tokenAmount));
      }
      else {
        uint256 remainingTokenTocreate = _tokenAmount.sub(token.balanceOf(address(this)));
        require(token.transfer(_beneficiary, token.balanceOf(address(this))));
        require(token.mint(_beneficiary, remainingTokenTocreate));
      }
    }
  }

  // Function to check the refund period
  function _refundPeriod() internal view returns (bool){
    require(!_isSuccessful(),"Failed refund period is not opened");
    return ((!ico && !stateico) || (now > refundPeriod));
  }

  // check if the ico is successful
  function _isSuccessful() internal view returns (bool){
    return (EthRaisedIco.add(EthRaisedpresale) >= ICOminCap);
  }

}