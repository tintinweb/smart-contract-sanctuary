pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

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

// File: contracts\ERC20Interface.sol

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

// File: contracts\StandardToken.sol

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

// File: contracts\CoinBet.sol

/* solium-disable */
pragma solidity ^0.4.24;


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


library DataLib {
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
contract CoinBet is StandardToken, Ownable {
  
  string public constant name = "Coinbet";
  string public constant symbol = "Z88";  
  uint256 public constant decimals = 18;
  uint256 public totalSupply = 200000000 * (10 ** decimals); // 200M token will be supplied

  uint256 public constant founderAndTeamAllocation = 20000000 * (10 ** decimals); // 20M tokens allocated for founders and team
  uint256 public constant advisorAllocation = 10000000 * (10 ** decimals); // 10M tokens allocated for advisors
  uint256 public constant airdropAllocation = 50000000 * (10 ** decimals); // 50M tokens (bounty 10M, treasure 30M, partner program 10M) allocated for airdrops
  
  uint256 public constant privateSaleAllocation = 40000000 * (10 ** decimals); // 40M tokens allocated for private sale
  uint256 public constant preSaleAllocation = 20000000 * (10 ** decimals); // 20M tokens allocated for private sale

  uint256 public constant tokenPerBracket1 = 20000000 * (10 ** decimals); // 20M tokens in bracket 1 for public sale
  uint256 public constant tokenPerBracket2 = 40000000 * (10 ** decimals); // 40M tokens in bracket 2 for public sale
  
  address public admin;
  address public walletAddress;
  address public airdropAddress;  
  address public teamWalletAddress;
  address public advisorWalletAddress;
  
  uint256 public privateSaleRemain;
  DataLib.Bracket public presaleBracket;
  DataLib.SaleStates public saleState;
  bool public isSelling;
  uint public sellingTime;
  bool public isTransferable;

  DataLib.Bracket[2] public brackets;  
  uint public currentBracketIndex;

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
    require(msg.sender == admin || msg.sender == owner);
    _;
  }

  constructor(
    address _admin,
    address _walletAddress,
    address _airdropAddress,    
    uint _startPrivateSaleAfter
  ) 
    public 
  { 
    require(_admin != address(0) && _admin != msg.sender);   
    require(_walletAddress != address(0) && _walletAddress != msg.sender);
    require(_airdropAddress != address(0) && _airdropAddress != msg.sender );    

    admin = _admin;
    walletAddress = _walletAddress;
    airdropAddress = _airdropAddress;
    saleState = DataLib.SaleStates.InPrivateSale;
    sellingTime = now + _startPrivateSaleAfter;

    emit StartPrivateSale(sellingTime);
	  initTokenAndBrackets();
  }

  function getSaleState() public view returns (DataLib.SaleStates state, uint time) {
    return (saleState, sellingTime);
  }

  function () external payable isInSale {
    require(walletAddress != address(0));    

    if(saleState == DataLib.SaleStates.InPresale && now >= sellingTime ) {      
      return purchaseTokenInPresale();
    } else if(saleState == DataLib.SaleStates.InPublicSale  && now >= sellingTime ) {
      return purchaseTokenInPublicSale();
    }
    
    revert();
  }

  function getCurrentBracket() 
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
    DataLib.Bracket memory bracket = brackets[currentBracketIndex];
    return (currentBracketIndex, bracket.total, bracket.remainToken, bracket.tokenPerEther, bracket.minAcceptedAmount);
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
    require(walletAddress != _newAddress);
    walletAddress = _newAddress;
  }

  function changeAdminAddress(address _newAdmin) external onlyOwner {
    require(_newAdmin != address(0));
    require(admin != _newAdmin);
    admin = _newAdmin;
  }
  
  function transferPrivateSale(address _to, uint256 _value) 
    external 
    onlyAdminOrOwner 
    returns (bool success) 
  {
    require(saleState == DataLib.SaleStates.InPrivateSale);
    require(_to != address(0));
    require(_value > 0);
    require(privateSaleRemain >= _value);

    privateSaleRemain = privateSaleRemain.sub(_value);
    balances[owner] = balances[owner].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(owner, _to, _value);
    emit PrivateSale(_to, _value);
    return true;    
  }
  
  function setBracketPrice(uint _bracketIndex, uint256 _tokenPerEther) 
    external 
    onlyAdminOrOwner 
    returns (bool success) 
  {
    require(_tokenPerEther > 0);
    require(brackets.length > _bracketIndex && _bracketIndex >= currentBracketIndex);

    DataLib.Bracket storage bracket = brackets[_bracketIndex];
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
    require(brackets.length > _bracketIndex && _bracketIndex >= currentBracketIndex);

    DataLib.Bracket storage bracket = brackets[_bracketIndex];
    require(bracket.minAcceptedAmount != _minAcceptedAmount);

    bracket.minAcceptedAmount = _minAcceptedAmount;
    return true;
  }  

  function changeToPublicSale() external onlyAdminOrOwner returns (bool success) {
    require(saleState == DataLib.SaleStates.EndPresale);    
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
    require(saleState < DataLib.SaleStates.InPresale);
    require(_tokenPerEther > 0);    
    presaleBracket.tokenPerEther = _tokenPerEther;
    isSelling = true;
    saleState = DataLib.SaleStates.InPresale;
    sellingTime = now + _startAfter;
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
    require(teamWalletAddress == address(0) && _teamWallet != address(0));    
    teamWalletAddress = _teamWallet;
    ITeamWallet teamWallet = ITeamWallet(teamWalletAddress);    

    // allocation 20M token for team and founder
    teamWallet.addMember(0x50ce0Eb4c1C1b64f0282f7b118Dfeb72449fbBe6, 10000000 * (10 ** decimals));  
    teamWallet.addMember(0x13C82E64f460C1e000dF81080064665820756dB6, 10000000 * (10 ** decimals));
    teamWallet.setAllocateTokenDone();

    super.transfer(teamWalletAddress, founderAndTeamAllocation);
  }

  function allocateTokenForAdvisor(address _advisorWallet) external onlyOwner {
    require(advisorWalletAddress == address(0) && _advisorWallet != address(0));
    
    advisorWalletAddress = _advisorWallet;
    IAdvisorWallet advisorWallet = IAdvisorWallet(advisorWalletAddress);    

    // allocation 10 token for advisor    
    advisorWallet.addAdvisor(0x50ce0Eb4c1C1b64f0282f7b118Dfeb72449fbBe6, 5000000 * (10 ** decimals));
    advisorWallet.addAdvisor(0x13C82E64f460C1e000dF81080064665820756dB6, 5000000 * (10 ** decimals));
    advisorWallet.setAllocateTokenDone();

    super.transfer(advisorWalletAddress, advisorAllocation);
  }

  function burnMemberToken(address _member) external onlyAdminOrOwner {        
    require(teamWalletAddress != address(0));
    ITeamWallet teamWallet = ITeamWallet(teamWalletAddress);    
    bool canBurn = teamWallet.canBurn(_member);
    uint256 tokenRemain = teamWallet.getMemberTokenRemain(_member);
    require(canBurn && tokenRemain > 0);    
    
    teamWallet.burnMemberToken(_member);

    balances[teamWalletAddress] = balances[teamWalletAddress].sub(tokenRemain);
    totalSupply = totalSupply.sub(tokenRemain);

    emit Transfer(teamWalletAddress, address(0), tokenRemain);
    emit BurnTeamToken(teamWalletAddress, _member, tokenRemain);
  }

  function initTokenAndBrackets() private {
    balances[owner] = totalSupply;
	  emit Transfer(address(0), owner, totalSupply);

    // allocate token for airdrop (grow network, bounty, referral, ...)
    super.transfer(airdropAddress, airdropAllocation);

    // allocate token for private sale
    privateSaleRemain = privateSaleAllocation;

    // allocate token for presale
    uint256 minAcceptedAmountInPresale = 1 ether; // 1 ether for mininum ether acception in presale
    presaleBracket = DataLib.Bracket(preSaleAllocation, preSaleAllocation, 0, minAcceptedAmountInPresale);
    
    // bracket token allocation for public sale
    uint256 minAcceptedAmountInBracket1 = 0.5 * (1 ether); // 0.5 ether for mininum ether acception in bracket 1
    brackets[0] = DataLib.Bracket(tokenPerBracket1, tokenPerBracket1, 0, minAcceptedAmountInBracket1);

    uint256 minAcceptedAmountInBracket2 = 0.1 * (1 ether); // 0.1 ether for mininum ether acception in bracket 2
    brackets[1] = DataLib.Bracket(tokenPerBracket2, tokenPerBracket2, 0, minAcceptedAmountInBracket2);    

    // allocate token for Z88 Lotto Jackpot
    // super.transfer(jackpot645Address, jackpot645Allocation);
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
    balances[owner] = balances[owner].sub(tokenAmount);
    balances[msg.sender] = balances[msg.sender].add(tokenAmount);    

    uint256 paymentAmount = msg.value.sub(refundAmount);
    walletAddress.transfer(paymentAmount);
    if(refundAmount > 0)      
      msg.sender.transfer(refundAmount);

    emit Transfer(owner, msg.sender, tokenAmount);
    emit PreSale(msg.sender, paymentAmount, tokenAmount);

    if(presaleBracket.remainToken == 0) {
      endPresale();
    }    
  }

  function endPresale() private {    
    isSelling = false;
    saleState = DataLib.SaleStates.EndPresale;
    emit EndPresale();
    startPublicSale();
  }

  function startPublicSale() private returns (bool success) {    
    DataLib.Bracket memory bracket = brackets[currentBracketIndex];
    if(bracket.tokenPerEther == 0) return false;    
    isSelling = true;
    saleState = DataLib.SaleStates.InPublicSale;
    emit StartPublicSale(bracket.tokenPerEther);
    return true;
  }

  function purchaseTokenInPublicSale() private {
    DataLib.Bracket storage bracket = brackets[currentBracketIndex];
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
    balances[owner] = balances[owner].sub(tokenAmount);
    balances[msg.sender] = balances[msg.sender].add(tokenAmount);    

    uint256 paymentAmount = msg.value.sub(refundAmount);
    walletAddress.transfer(paymentAmount);
    if(refundAmount > 0)      
      msg.sender.transfer(refundAmount);
    
    emit Transfer(owner, msg.sender, tokenAmount);
    emit PublicSale(msg.sender, paymentAmount, tokenAmount);

    // end current bracket and move to next bracket
    if(bracket.remainToken == 0) {      
      nextBracket();
    }
  }

  function nextBracket() private {
    // last bracket - end public sale
    if(currentBracketIndex == brackets.length - 1) {
      isSelling = false;
      saleState = DataLib.SaleStates.EndPublicSale;
      isTransferable = true;
      emit EnableTransfer();
      emit EndPublicSale();
    }        
    else {
      currentBracketIndex = currentBracketIndex + 1;
      emit ChangeBracketIndex(currentBracketIndex);
    }
  }
	
}