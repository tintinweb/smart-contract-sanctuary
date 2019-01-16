pragma solidity ^0.4.25;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: ..\node_modules\openzeppelin-solidity\contracts\math\SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

// File: ..\node_modules\openzeppelin-solidity\contracts\token\ERC20\ERC20.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param owner The address to query the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param owner address The address which owns the funds.
   * @param spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

  /**
  * @dev Transfer token for a specified address
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param from address The address which you want to send tokens from
   * @param to address The address which you want to transfer to
   * @param value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param addedValue The amount of tokens to increase the allowance by.
   */
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
  * @dev Transfer token for a specified addresses
  * @param from The address to transfer from.
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

  /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param account The account that will receive the created tokens.
   * @param value The amount that will be created.
   */
  function _mint(address account, uint256 value) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burn(address account, uint256 value) internal {
    require(account != 0);
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender&#39;s allowance for said account. Uses the
   * internal burn function.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);

    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// File: contracts\CoinBet.sol

/* solium-disable */
pragma solidity ^0.4.25;



contract ITeamWallet {
  function canBurn(address _member) public view returns(bool);  
  function addMember(address _member, uint256 _tokenAmount) public;
  function setAllocateTokenDone() public;
  function getMemberTokenRemain(address _member) public view returns (uint256);
  function burnMemberToken(address _memberAddress) public;
}

contract IAdvisorWallet {    
  function addAdvisor(address _member, uint256 _tokenAmount) public;
  function setAllocateTokenDone() public;
}

library ICOData {
  struct Bracket {
    uint256 total;
    uint256 remainToken;
    uint256 tokenPerEther;
    uint256 minAcceptedAmount;
  }
  
  enum SaleStates {
    InPrivateSale,
    InPresale,
    EndPresale,
    InPublicSale,
    EndPublicSale
  }
}

// ================= Coinbet Token =======================
contract CoinBet is ERC20, Ownable {
  
  string public constant name = "Coinbet";
  string public constant symbol = "Z88";
  uint256 public constant decimals = 18;
  // 200M token will be supplied
  uint256 public constant INITIAL_SUPPLY = 200000000 * (10 ** decimals);

  // 20M tokens allocated for founders and team
  uint256 public constant FOUNDER_AND_TEAM_ALLOCATION = 20000000 * (10 ** decimals);
  // 10M tokens allocated for advisors
  uint256 public constant ADVISOR_ALLOCATION = 10000000 * (10 ** decimals);
  // 5M tokens allocated for bounty & referral
  uint256 public constant AIRDROP_ALLOCATION = 5000000 * (10 ** decimals);
  // 30M tokens allocated for treasury
  uint256 public constant TREASURY_ALLOCATION = 30000000 * (10 ** decimals);
  // 10M tokens allocated for partner
  uint256 public constant PARTNER_ALLOCATION = 10000000 * (10 ** decimals);

  // 40M tokens allocated for pre sale
  uint256 public constant PRIVATE_SALE_ALLOCATION = 40000000 * (10 ** decimals);
  // 20M tokens allocated for private sale
  uint256 public constant PRESALE_ALLOCATION = 20000000 * (10 ** decimals);
  // 20M tokens allocated for public sale in 1st bracket
  uint256 public constant PUBLIC_1_ALLOCATION = 20000000 * (10 ** decimals);
  // 40M tokens allocated for public sale in 2nd bracket
  uint256 public constant PUBLIC_2_ALLOCATION = 40000000 * (10 ** decimals);
  // 1.5M tokens allocated for Lotto645 jackpot
  uint256 public constant LOTTO645_JACKPOT_ALLOCATION = 1500000 * (10 ** decimals);
  // 3M tokens allocated for Lotto655 jackpot 1
  uint256 public constant LOTTO655_JACKPOT_1_ALLOCATION = 3000000 * (10 ** decimals);
  // 0.5M tokens allocated for Lotto655 jackpot 2
  uint256 public constant LOTTO655_JACKPOT_2_ALLOCATION = 500000 * (10 ** decimals);

  // Admin role
  address public admin;
  // Address where funds are collected
  address public fundWallet;
  // Wallet is used for Bounty & Referral program
  address public airdropWallet;
  // Wallet for tokens keeping purpose, no sale
  address public treasuryWallet;
  // Wallet is used for Coinbet Partner Program
  address public partnerWallet;
  // Contract is used for rewarding development team
  ITeamWallet public teamWallet;
  // Contract is used for rewarding advisor team
  IAdvisorWallet public advisorWallet;
  // Wallet is used for paying Z88 Lotto 645&#39;s starting Jackpot
  address public lotto645JackpotWallet;
  // Wallet is used for paying Z88 Lotto 655&#39;s starting Jackpot 1
  address public lotto655Jackpot1Wallet;
  // Wallet is used for paying Z88 Lotto 655&#39;s starting Jackpot 2
  address public lotto655Jackpot2Wallet;
  
  // Remain number of Z88 tokens for private sale
  uint256 public privateSaleRemain;
  // Info of presale bracket: total tokens, remain tokens, price
  ICOData.Bracket public presaleBracket;
  // Sale states: InPrivateSale, InPresale, EndPresale, InPublicSale, EndPublicSale
  ICOData.SaleStates public saleState;
  // The flag to specify the selling state
  bool public isSelling;
  // The start date for private sale
  uint public sellingTime;
  // The flag to specify the transferable state
  bool public isTransferable;

  // Info of 1st & 2nd public brackets: total tokens, remain tokens, price
  ICOData.Bracket[2] private publicBrackets;  
  // The index of current public bracket: 0 or 1
  uint private currentPublicBracketIndex;

  event PrivateSale(address to, uint256 tokenAmount); // Transfer token to investors in private sale
  event PublicSale(address to, uint256 amount, uint256 tokenAmount); // Investors purchase token in public sale
  event SetBracketPrice(uint bracketIndex, uint256 tokenPerEther); // Set bracket price in public sale  
  event StartPublicSale(uint256 tokenPerEther); // start public sale with price
  event EndPublicSale(); // end public sale
  event SetPresalePrice(uint256 tokenPerEther); // Set price in presale
  event PreSale(address to, uint256 amount, uint256 tokenAmount); // Investors purchase token in presale
  event StartPrivateSale(uint startedTime); // start private sale
  event StartPresale(uint256 tokenPerEther, uint startedTime); // start presale
  event EndPresale(); // end presale
  event ChangeBracketIndex(uint bracketIndex); // change to next bracket for sale  
  event EnableTransfer(); // enable transfer token
  event BurnTeamToken(address lockedWallet, address memberAddress, uint256 amount); // burn token allocated for dev team when they are inactivity

  modifier transferable() {
    require(isTransferable == true);
    _;
  }

  modifier isInSale() {
    require(isSelling == true);
    _;
  }

  modifier onlyAdminOrOwner() {
    require(msg.sender == admin || msg.sender == owner());
    _;
  }

  constructor(
  ) 
    public 
  { 
  }

  function getSaleState() public view returns (ICOData.SaleStates state, uint time) {
    return (saleState, sellingTime);
  }

  function () external payable isInSale {
    require(fundWallet != address(0));    

    if(saleState == ICOData.SaleStates.InPresale && now >= sellingTime ) {
      return purchaseTokenInPresale();
    } else if(saleState == ICOData.SaleStates.InPublicSale  && now >= sellingTime ) {
      return purchaseTokenInPublicSale();
    }
    
    revert();
  }

  function getCurrentPublicBracket()
    public 
    view 
    returns (
      uint256 bracketIndex, 
      uint256 total, 
      uint256 remainToken, 
      uint256 tokenPerEther,
      uint256 minAcceptedAmount
    ) 
  {
    if(saleState == ICOData.SaleStates.InPublicSale) {
      ICOData.Bracket memory bracket = publicBrackets[currentPublicBracketIndex];
      return (currentPublicBracketIndex, bracket.total, bracket.remainToken, bracket.tokenPerEther, bracket.minAcceptedAmount);
    } else {
      return (0, 0, 0, 0, 0);
    }
  }

  function transfer(address _to, uint256 _value) 
    public
    transferable 
    returns (bool success) 
  {
    require(_to != address(0));
    require(_value > 0);
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) 
    public 
    transferable 
    returns (bool success) 
  {
    require(_from != address(0));
    require(_to != address(0));
    require(_value > 0);
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) 
    public 
    transferable 
    returns (bool success) 
  {
    require(_spender != address(0));
    require(_value > 0);
    return super.approve(_spender, _value);
  }

  function changeWalletAddress(address _newAddress) external onlyOwner {
    require(_newAddress != address(0));
    require(fundWallet != _newAddress);
    fundWallet = _newAddress;
  }

  function changeAdminAddress(address _newAdmin) external onlyOwner {
    require(_newAdmin != address(0));
    require(admin != _newAdmin);
    admin = _newAdmin;
  }

  function enableTransfer() external onlyOwner {
    require(isTransferable == false);
    isTransferable = true;
    emit EnableTransfer();
  }
  
  function transferPrivateSale(address _to, uint256 _value) 
    external 
    onlyAdminOrOwner 
    returns (bool success) 
  {
    require(saleState == ICOData.SaleStates.InPrivateSale);
    require(_to != address(0));
    require(_value > 0);
    require(privateSaleRemain >= _value);

    privateSaleRemain = privateSaleRemain.sub(_value);
    _transfer(owner(), _to, _value);
    emit PrivateSale(_to, _value);
    return true;    
  }
  
  function setPublicPrice(uint _bracketIndex, uint256 _tokenPerEther) 
    external 
    onlyAdminOrOwner 
    returns (bool success) 
  {
    require(_tokenPerEther > 0);
    require(publicBrackets.length > _bracketIndex && _bracketIndex >= currentPublicBracketIndex);

    ICOData.Bracket storage bracket = publicBrackets[_bracketIndex];
    require(bracket.tokenPerEther != _tokenPerEther);

    bracket.tokenPerEther = _tokenPerEther;
    emit SetBracketPrice(_bracketIndex, _tokenPerEther);
    return true;
  }

  function setMinAcceptedInPublicSale(uint _bracketIndex, uint256 _minAcceptedAmount) 
    external 
    onlyAdminOrOwner 
    returns (bool success)
  {
    require(_minAcceptedAmount > 0);
    require(publicBrackets.length > _bracketIndex && _bracketIndex >= currentPublicBracketIndex);

    ICOData.Bracket storage bracket = publicBrackets[_bracketIndex];
    require(bracket.minAcceptedAmount != _minAcceptedAmount);

    bracket.minAcceptedAmount = _minAcceptedAmount;
    return true;
  }  

  function changeToPublicSale() external onlyAdminOrOwner returns (bool success) {
    require(saleState == ICOData.SaleStates.EndPresale);    
    return startPublicSale();
  }  

  function setPresalePrice(uint256 _tokenPerEther) external onlyAdminOrOwner returns (bool) {
    require(_tokenPerEther > 0);
    require(presaleBracket.tokenPerEther != _tokenPerEther);

    presaleBracket.tokenPerEther = _tokenPerEther;
    emit SetPresalePrice(_tokenPerEther);
    return true;
  }

  function startPresale(uint256 _tokenPerEther, uint _startAfter) 
    external 
    onlyAdminOrOwner 
    returns (bool) 
  {
    require(saleState < ICOData.SaleStates.InPresale);
    require(_tokenPerEther > 0);    
    presaleBracket.tokenPerEther = _tokenPerEther;
    isSelling = true;
    saleState = ICOData.SaleStates.InPresale;
    sellingTime = now + _startAfter * 1 seconds;
    emit StartPresale(_tokenPerEther, sellingTime);
    return true;
  }

  function setMinAcceptedAmountInPresale(uint256 _minAcceptedAmount) 
    external 
    onlyAdminOrOwner 
    returns (bool)
  {
    require(_minAcceptedAmount > 0);
    require(presaleBracket.minAcceptedAmount != _minAcceptedAmount);

    presaleBracket.minAcceptedAmount = _minAcceptedAmount;
    return true;
  }
  
  function allocateTokenForTeam(address _teamWallet) external onlyOwner {
    require(teamWallet == address(0) && _teamWallet != address(0));    
    teamWallet = ITeamWallet(_teamWallet);

    // allocation 20M token for team and founder
    teamWallet.addMember(0x0929C384F12914Fe20dE96af934A35b8333Bbe11, 97656 * (10 ** decimals));
    teamWallet.addMember(0x0A0aC5949FE7Af47B566F0dC02f92DF6B6980AA5, 65104 * (10 ** decimals));
    teamWallet.addMember(0x0eE878D94e22Cb50A62e4D685193B35015e3eDf8, 640000 * (10 ** decimals));
    teamWallet.addMember(0x1A5912eEb9490B0937CD36636eEEFA82aA4Aa549, 177083 * (10 ** decimals));
    teamWallet.addMember(0x1b2298A5d5342452D87D6684Fe31aEe52A31433d, 130208 * (10 ** decimals));
    teamWallet.addMember(0x1eF0f9F6CcD2528d7038d4cEe47a417cA7f4c79d, 175781 * (10 ** decimals));
    teamWallet.addMember(0x23a18F3A82F9EE302a1e6350b8D9f9F3B65ED5D7, 104167 * (10 ** decimals));
    teamWallet.addMember(0x24F29d95a0D41a1713b67b29Bf664A1b70B5D683, 97656 * (10 ** decimals));
    teamWallet.addMember(0x2598aCe98c1117f72Da929441b56a26994d5b13A, 680000 * (10 ** decimals));
    teamWallet.addMember(0x275c667B3B372Ffb03BF05B97841C66eF1f1DF99, 480000 * (10 ** decimals));
    teamWallet.addMember(0x27be83EBDC7D7917e2A4247bb8286cB192b74C51, 65104 * (10 ** decimals));
    teamWallet.addMember(0x2847aFA0348284658A2cAFf676361A26220ccE7d, 280000 * (10 ** decimals));
    teamWallet.addMember(0x29904b46fb7e411654dd16b1e9680A81Aa5A472D, 240000 * (10 ** decimals));
    teamWallet.addMember(0x2B6f1941101c633Bbe24ce13Fd49ba14480F7242, 120000 * (10 ** decimals));
    teamWallet.addMember(0x2c647B2D6a5B3FFE21bebA4467937cEd24c4292B, 720000 * (10 ** decimals));
    teamWallet.addMember(0x2d8cdfBfc3C8Df06f70257eAca63aB742db62562, 110677 * (10 ** decimals));
    teamWallet.addMember(0x3289E2310108699e22c2CDF81485885a3E9d3683, 31250 * (10 ** decimals));
    teamWallet.addMember(0x375814a2D26A8cB1a010Db1FE8cE9Bc06e5224af, 125000 * (10 ** decimals));
    teamWallet.addMember(0x401438aD9584A68D5A68FA1E8a2ef716862d82d9, 149740 * (10 ** decimals));
    teamWallet.addMember(0x44be551E017893A0dD74e5160Ef0DB0aed2BdA54, 400000 * (10 ** decimals));
    teamWallet.addMember(0x451B389a9F7365B09A24481F9EB5a125F64Ae4aB, 280000 * (10 ** decimals));
    teamWallet.addMember(0x500D157FA3E3Ab5133ee0C7EFff3Ad5cdBCE01F3, 400000 * (10 ** decimals));
    teamWallet.addMember(0x577FEE18cCD840b2a41c9180bbE6412a89c1aD2C, 720000 * (10 ** decimals));
    teamWallet.addMember(0x58eA48c5FD9ac82e6CCb8aC67aCB48D1fb38b592, 80000 * (10 ** decimals));
    teamWallet.addMember(0x5DdfCd7d8FAe31014010C3877E4Bf91F2E683F2D, 130208 * (10 ** decimals));
    teamWallet.addMember(0x5E5Fc9f5C8B2EA3436D92dC07f621496C6E3EeC4, 800000 * (10 ** decimals));
    teamWallet.addMember(0x5F89F3FeeeB67B3229b17E389D8BaD28f44d08aA, 120000 * (10 ** decimals));
    teamWallet.addMember(0x60a09Fa998a1A6625c1161C452aAab26e6151cfA, 45573 * (10 ** decimals));
    teamWallet.addMember(0x63Fa2cE8C891690fF40FB197E09C72B84Ca1030e, 121094 * (10 ** decimals));
    teamWallet.addMember(0x66e898bA75FC329d872e61eE16fc4ea0248Eb369, 320000 * (10 ** decimals));
    teamWallet.addMember(0x66F212e3Ba5F44BeB014FCe2beD1b1F290b13009, 15625 * (10 ** decimals));
    teamWallet.addMember(0x6736ead91e4E9131262Aa033B8811071BbCa3f85, 117188 * (10 ** decimals));
    teamWallet.addMember(0x6B99cE47bf47D91159109506B4722c732B5d7b46, 120000 * (10 ** decimals));
    teamWallet.addMember(0x6f9140d408Faf111eF3D693645638B863650057d, 320000 * (10 ** decimals));
    teamWallet.addMember(0x7510CC3635470Bd033c94a10B0a7ed46d98EbcC7, 156250 * (10 ** decimals));
    teamWallet.addMember(0x7692bF394c84D3a880407E8cf4167b01007A9880, 175781 * (10 ** decimals));
    teamWallet.addMember(0x7726bDa7d29FC141Eb65150eA7CBB1bC985693Dd, 93750 * (10 ** decimals));
    teamWallet.addMember(0x7B6c1d3475974d5904c31BE4F3B9aA26F6eCAebB, 400000 * (10 ** decimals));
    teamWallet.addMember(0x7D0E17DEa015B5A687385116d443466B2a42c65B, 109375 * (10 ** decimals));
    teamWallet.addMember(0x8a0D93CF316b6Eb58aa5463533d06F18Bfa58ade, 640000 * (10 ** decimals));
    teamWallet.addMember(0x8F25dD569c72fB507D72D743f070273556123AED, 169271 * (10 ** decimals));
    teamWallet.addMember(0x908D0CF89bc46510b1B472F51905169Ad025f99F, 120000 * (10 ** decimals));
    teamWallet.addMember(0x99A43289E131640534E147596F05d40699214673, 160000 * (10 ** decimals));
    teamWallet.addMember(0x9C16FA8a4e04d67781D3d02a6b17De7a3e27e168, 600000 * (10 ** decimals));
    teamWallet.addMember(0x9DAeD1073C38902a9a6dD8834f8a7c7851717b86, 360000 * (10 ** decimals));
    teamWallet.addMember(0xa0dc24Aa838946d39d3d76f0f776BE6D26cB7b2b, 520000 * (10 ** decimals));
    teamWallet.addMember(0xa40b31177E908d235FDF6AE8010e135d204BE19c, 160000 * (10 ** decimals));
    teamWallet.addMember(0xa428FEcCc9E9F972498303d2C91982f1B6813827, 109375 * (10 ** decimals));
    teamWallet.addMember(0xa7951c07d25d88D75662BD68B5dF4D6D08F17600, 104167 * (10 ** decimals));
    teamWallet.addMember(0xA7fD89962f76233b68c33b0d9795c5899Feb11B3, 320000 * (10 ** decimals));
    teamWallet.addMember(0xA8B6FB38F8BeC4C331E922Eb5a842921081267ce, 156250 * (10 ** decimals));
    teamWallet.addMember(0xafbE656FbBC42704ef04aa6D8Ee1FEa9F3b71E7F, 136719 * (10 ** decimals));
    teamWallet.addMember(0xb1cf51D7e8F987d0e64bBB2e1bE277821c600778, 130208 * (10 ** decimals));
    teamWallet.addMember(0xB694854b6d8e6eAbDC15bE93005CCd54B841a79f, 560000 * (10 ** decimals));
    teamWallet.addMember(0xb6dFc3227E2dd9CA569fFCE69014539F138D1bcC, 280000 * (10 ** decimals));
    teamWallet.addMember(0xc230934C7610e39Ae06d4799e21b938bB44E60f2, 280000 * (10 ** decimals));
    teamWallet.addMember(0xc6888650Dec537dD4f056008D9d3ED171d48F1CD, 640000 * (10 ** decimals));
    teamWallet.addMember(0xccE1fc98815307BcDdE9596544802945a664C8b7, 440000 * (10 ** decimals));
    teamWallet.addMember(0xd1326c632009979713BD92855cecc04c7ebE29F0, 36458 * (10 ** decimals));
    teamWallet.addMember(0xD3859645cECCEFB1210567BaEB9c714272c9f61B, 149740 * (10 ** decimals));
    teamWallet.addMember(0xDB252f9D8Bd0Cb0bB83df4E50870977c771C6b50, 26042 * (10 ** decimals));
    teamWallet.addMember(0xDc87F026A5d5E37B9AD67321a19802Bb5082cC67, 400000 * (10 ** decimals));
    teamWallet.addMember(0xE01b721ef02A550B11DF7e0B3f55809227a4F1B4, 680000 * (10 ** decimals));
    teamWallet.addMember(0xe13E61A210724D50F5D39cd3f8b08955993E9309, 80000 * (10 ** decimals));
    teamWallet.addMember(0xe2D9a70307383072f18bf9D0eff9Cb98d1278777, 600000 * (10 ** decimals));
    teamWallet.addMember(0xe81CF8A8F052B6dd9dFfF452a593e5638A4097ee, 109375 * (10 ** decimals));
    teamWallet.addMember(0xEC80389aF763b4d141b1AD2a1E8579f8B5500fAF, 560000 * (10 ** decimals));
    teamWallet.addMember(0xF568705D7A1Df478CF6118420fA482B71092Ca66, 156250 * (10 ** decimals));
    teamWallet.addMember(0xF662482E8196Fb5e4f680964263A5bA618E295A7, 149740 * (10 ** decimals));
    teamWallet.addMember(0xF84FB7E6d21364B4F919Cab2A205Af70ae86f013, 800000 * (10 ** decimals));
    teamWallet.addMember(0xF9Cd27047e11DdDb93C5623a97b49278B1443576, 110677 * (10 ** decimals));
    teamWallet.addMember(0xF9d41D1409cdf2AfD629ab437760Bb41260CC81D, 20833 * (10 ** decimals));
    teamWallet.addMember(0xFbAEF91d25e3cfad0aDef2F9C43f9eC957615E43, 680000 * (10 ** decimals));
    teamWallet.addMember(0xfe5e823c967476bC4cFB8D84Dfaf6699A76062F4, 140625 * (10 ** decimals));
    teamWallet.setAllocateTokenDone();

    super.transfer(teamWallet, FOUNDER_AND_TEAM_ALLOCATION);
  }

  function allocateTokenForAdvisor(address _advisorWallet) external onlyOwner {
    require(advisorWallet == address(0) && _advisorWallet != address(0));
    
    advisorWallet = IAdvisorWallet(_advisorWallet);

    // allocation 10M token for advisor    
    advisorWallet.addAdvisor(0xf8E2d6a822f70c5c5788fa10f080810a8579d407, 2000000 * (10 ** decimals));
    advisorWallet.addAdvisor(0xab74072a37e08Ff9ceA098d4E33438257589B044, 1000000 * (10 ** decimals));
    advisorWallet.addAdvisor(0x3DFD289380Cbe25456B5973306129753c4ed3dF3, 7000000 * (10 ** decimals));
    advisorWallet.setAllocateTokenDone();

    super.transfer(advisorWallet, ADVISOR_ALLOCATION);
  }

  function burnMemberToken(address _member) external onlyAdminOrOwner {        
    require(teamWallet != address(0));
    bool canBurn = teamWallet.canBurn(_member);
    uint256 tokenRemain = teamWallet.getMemberTokenRemain(_member);
    require(canBurn && tokenRemain > 0);    
    
    teamWallet.burnMemberToken(_member);

    _burn(teamWallet, tokenRemain);
    emit BurnTeamToken(teamWallet, _member, tokenRemain);
  }

  function initTokenAndBrackets() private {
    _mint(owner(), INITIAL_SUPPLY);

    // allocate token for bounty, referral, treasury, partner
    super.transfer(airdropWallet, AIRDROP_ALLOCATION);
    super.transfer(treasuryWallet, TREASURY_ALLOCATION);
    super.transfer(partnerWallet, PARTNER_ALLOCATION);

    // allocate token for private sale
    privateSaleRemain = PRIVATE_SALE_ALLOCATION;

    // allocate token for presale
    uint256 minAcceptedAmountInPresale = 1 ether; // 1 ether for mininum ether acception in presale
    presaleBracket = ICOData.Bracket(PRESALE_ALLOCATION, PRESALE_ALLOCATION, 0, minAcceptedAmountInPresale);
    
    // bracket token allocation for public sale
    uint256 minAcceptedAmountInBracket1 = 0.5 * (1 ether); // 0.5 ether for mininum ether acception in bracket 1
    publicBrackets[0] = ICOData.Bracket(PUBLIC_1_ALLOCATION, PUBLIC_1_ALLOCATION, 0, minAcceptedAmountInBracket1);

    uint256 minAcceptedAmountInBracket2 = 0.1 * (1 ether); // 0.1 ether for mininum ether acception in bracket 2
    publicBrackets[1] = ICOData.Bracket(PUBLIC_2_ALLOCATION, PUBLIC_2_ALLOCATION, 0, minAcceptedAmountInBracket2);    

    // allocate token for Z88 Lotto Jackpot
    super.transfer(lotto645JackpotWallet, LOTTO645_JACKPOT_ALLOCATION);
    super.transfer(lotto655Jackpot1Wallet, LOTTO655_JACKPOT_1_ALLOCATION);
    super.transfer(lotto655Jackpot2Wallet, LOTTO655_JACKPOT_2_ALLOCATION);
  }

  function purchaseTokenInPresale() private {
    require(msg.value >= presaleBracket.minAcceptedAmount);
    require(presaleBracket.tokenPerEther > 0 && presaleBracket.remainToken > 0);

    uint256 tokenPerEther = presaleBracket.tokenPerEther.mul(10 ** decimals);
    uint256 tokenAmount = msg.value.mul(tokenPerEther).div(1 ether);    

    uint256 refundAmount = 0;
    if(tokenAmount > presaleBracket.remainToken) {
      refundAmount = tokenAmount.sub(presaleBracket.remainToken).mul(1 ether).div(tokenPerEther);
      tokenAmount = presaleBracket.remainToken;
    }

    presaleBracket.remainToken = presaleBracket.remainToken.sub(tokenAmount);
    _transfer(owner(), msg.sender, tokenAmount);

    uint256 paymentAmount = msg.value.sub(refundAmount);
    fundWallet.transfer(paymentAmount);
    if(refundAmount > 0)      
      msg.sender.transfer(refundAmount);

    emit PreSale(msg.sender, paymentAmount, tokenAmount);

    if(presaleBracket.remainToken == 0) {
      endPresale();
    }    
  }

  function endPresale() private {    
    isSelling = false;
    saleState = ICOData.SaleStates.EndPresale;
    emit EndPresale();
    startPublicSale();
  }

  function startPublicSale() private returns (bool success) {    
    ICOData.Bracket memory bracket = publicBrackets[currentPublicBracketIndex];
    if(bracket.tokenPerEther == 0) return false;    
    isSelling = true;
    saleState = ICOData.SaleStates.InPublicSale;
    emit StartPublicSale(bracket.tokenPerEther);
    return true;
  }

  function purchaseTokenInPublicSale() private {
    ICOData.Bracket storage bracket = publicBrackets[currentPublicBracketIndex];
    require(msg.value >= bracket.minAcceptedAmount);
    require(bracket.tokenPerEther > 0 && bracket.remainToken > 0);

    uint256 tokenPerEther = bracket.tokenPerEther.mul(10 ** decimals);
    uint256 remainToken = bracket.remainToken;
    uint256 tokenAmount = msg.value.mul(tokenPerEther).div(1 ether);
    uint256 refundAmount = 0;

    // check remain token when end bracket
    if(remainToken < tokenAmount) {      
      refundAmount = tokenAmount.sub(remainToken).mul(1 ether).div(tokenPerEther);
      tokenAmount = remainToken;
    }

    bracket.remainToken = bracket.remainToken.sub(tokenAmount);
    _transfer(owner(), msg.sender, tokenAmount);

    uint256 paymentAmount = msg.value.sub(refundAmount);
    fundWallet.transfer(paymentAmount);
    if(refundAmount > 0)      
      msg.sender.transfer(refundAmount);
    
    emit PublicSale(msg.sender, paymentAmount, tokenAmount);

    // end current bracket and move to next bracket
    if(bracket.remainToken == 0) {      
      nextBracket();
    }
  }

  function nextBracket() private {
    // last bracket - end public sale
    if(currentPublicBracketIndex == publicBrackets.length - 1) {
      isSelling = false;
      saleState = ICOData.SaleStates.EndPublicSale;
      isTransferable = true;
      emit EnableTransfer();
      emit EndPublicSale();
    }        
    else {
      currentPublicBracketIndex = currentPublicBracketIndex + 1;
      emit ChangeBracketIndex(currentPublicBracketIndex);
    }
  }
}