pragma solidity ^0.4.23;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c &gt;= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b &lt;= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b &gt; 0);
        c = a / b;
    }
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner, &quot;ONLY OWNER IS ALLOWED&quot;);
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

contract IBelottoToken{
    function transfer(address to, uint tokens) public returns (bool success);
    function burn(uint256 _value) public;
    function balanceOf(address tokenOwner) public constant returns (uint balance);
}

/**
 * @title BelottoCrowdsale
 * @dev BelottoCrowdsale accepting contributions only within a time frame.
 */
contract BelottoCrowdsale is Owned {
  using SafeMath for uint256; 
  uint256 public presaleopeningTime;
  uint256 public presaleclosingTime;
  uint256 public saleopeningTime;
  uint256 public saleclosingTime;
  uint256 public secondsaleopeningTime;
  uint256 public secondsaleclosingTime;
  address public reserverWallet;    // Address where reserve tokens will be sent
  address public bountyWallet;      // Address where bounty tokens will be sent
  address public teamsWallet;       // Address where team&#39;s tokens will be sent
  address public fundsWallet;       // Address where funds are collected
  uint256 public fundsRaised;         // Amount of total fundsRaised
  uint256 public preSaleTokens;
  uint256 public saleTokens;
  uint256 public teamAdvTokens;
  uint256 public reserveTokens;
  uint256 public bountyTokens;
  uint256 public hardCap;
  uint256 public minTxSize;
  uint256 public maxTxSize;
  bool    public presaleOpen;
  bool    public firstsaleOpen;
  bool    public secondsaleOpen;
  mapping(address =&gt; uint) preSaleFunds;
  mapping(address =&gt; uint) firstSaleFunds;
  mapping(address =&gt; uint) secondSaleFunds;
  struct Funds {
    address spender;
    uint256 amount;
    uint256 time;
    }
    Funds[]  preSaleFundsArray;
    Funds[]  firstSaleFundsArray;
    Funds[]  secondSaleFundsArray;
  
  IBelottoToken public token;
  
  event Burn(address indexed burner, uint256 value);
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  /** @dev Reverts if not in crowdsale time range. */
  modifier onlyWhilePreSaleOpen {
    require(now &gt;= presaleopeningTime &amp;&amp; now &lt;= presaleclosingTime, &quot;Pre Sale Close&quot;);
    _;
  }
  
  modifier onlyWhileFirstSaleOpen {
    require(now &gt;= saleopeningTime &amp;&amp; now &lt;= saleclosingTime, &quot;First Sale Close&quot;);
    _;
  }
  
  modifier onlyWhileSecondSaleOpen {
    require(now &gt;= secondsaleopeningTime &amp;&amp; now &lt;= secondsaleclosingTime, &quot;Second Sale Close&quot;);
    _;
  }
  
  function totalRemainingTokens() public view returns(uint256 remainingTokens){
    return token.balanceOf(this);      
  }
  
  function BelottoCrowdsale(uint256 _preST, uint256 _saleT, uint256 _teamAdvT, uint256 _reserveT, uint256 _bountyT, address _reserverWallet, 
                            address _bountyWallet, address _teamsWallet, address _fundsWallet, address _tokenContractAdd, address _owner) 
                            public {
    
    
    _setWallets(_reserverWallet,_bountyWallet,_teamsWallet,_fundsWallet);
    _setMoreDetails(_preST,_saleT,_teamAdvT,_reserveT,_bountyT,_owner);
    _setTimes();
    
    // takes an address of the existing token contract as parameter
    token = IBelottoToken(_tokenContractAdd);
  }
  
  function _setTimes() internal{
    presaleopeningTime    = 1524873600; // 28th April 2018 00:00:00 GMT 
    presaleclosingTime    = 1527379199; // 26th May 2018 23:59:59 GMT   
    saleopeningTime       = 1527724800; // 31st May 2018 00:00:00 GMT 
    saleclosingTime       = 1532908799; // 29th July 2018 23:59:59 GMT
    secondsaleopeningTime = 1532908800; // 30th July 2018 00:00:00 GMT
    secondsaleclosingTime = 1535673599; // 30th August 2018 23:59:59 GMT
  }
  
  function _setWallets(address _reserverWallet, address _bountyWallet, address _teamsWallet, address _fundsWallet) internal{
    reserverWallet        = _reserverWallet;
    bountyWallet          = _bountyWallet;
    teamsWallet           = _teamsWallet;
    fundsWallet           = _fundsWallet;
  }
  
  function _setMoreDetails(uint256 _preST, uint256 _saleT, uint256 _teamAdvT, uint256 _reserveT, uint256 _bountyT, address _owner) internal{
    preSaleTokens         = _preST * 10**uint(18);
    saleTokens            = _saleT * 10**uint(18);
    teamAdvTokens         = _teamAdvT * 10**uint(18);
    reserveTokens         = _reserveT * 10**uint(18);
    bountyTokens          = _bountyT * 10**uint(18);
    hardCap               = 16000 * 10**(uint(18));   //in start only, it&#39;ll be set by Owner
    minTxSize             = 100000000000000000; // in wei&#39;s. (0,1 ETH)
    maxTxSize             = 200000000000000000000; // in wei&#39;s. (200 ETH)
    owner = _owner;
  }
  
  function TokenAllocate(address _wallet,uint256 _amount) internal returns (bool success) {
      uint256 tokenAmount = _amount;
      token.transfer(_wallet,tokenAmount);
      return true;
  }
  
  function startSecondSale() public onlyOwner{
      presaleOpen = false;
      firstsaleOpen  = false;
      secondsaleOpen = true;
  }
  
  
  function stopSecondSale() public onlyOwner{
      presaleOpen = false;
      firstsaleOpen = false;
      secondsaleOpen = false;
      if(teamAdvTokens &gt;= 0 &amp;&amp; bountyTokens &gt;=0){
          TokenAllocate(teamsWallet,teamAdvTokens);
          teamAdvTokens = 0;
          TokenAllocate(bountyWallet,bountyTokens);
          bountyTokens = 0;
      }
  }

  function _checkOpenings(uint256 _weiAmount) internal{
      if((fundsRaised + _weiAmount &gt;= hardCap)){
            presaleOpen = false;
            firstsaleOpen  = false;
            secondsaleOpen = true;
      }
      else if(secondsaleOpen){
          presaleOpen = false;
          firstsaleOpen  = false;
          secondsaleOpen = true;
      }
      else if(now &gt;= presaleopeningTime &amp;&amp; now &lt;= presaleclosingTime){
          presaleOpen = true;
          firstsaleOpen = false;
          secondsaleOpen = false;
          if(reserveTokens &gt;= 0){
            if(TokenAllocate(reserverWallet,reserveTokens)){
                reserveTokens = 0;
            }
          }
      }
      else if(now &gt;= saleopeningTime &amp;&amp; now &lt;= saleclosingTime){
          presaleOpen = false;
          firstsaleOpen = true;
          secondsaleOpen = false;
      }
      else if(now &gt;= secondsaleopeningTime &amp;&amp; now &lt;= secondsaleclosingTime){
            presaleOpen = false;
            firstsaleOpen  = false;
            secondsaleOpen = true;
      }
      else{
          presaleOpen = false;
          firstsaleOpen = false;
          secondsaleOpen = false;
          if(teamAdvTokens &gt;= 0 &amp;&amp; bountyTokens &gt;=0){
            TokenAllocate(teamsWallet,teamAdvTokens);
            teamAdvTokens = 0;
            TokenAllocate(bountyWallet,bountyTokens);
            bountyTokens = 0;
          }
      }
  }
  
  function () external payable {
    buyTokens(msg.sender);
  }

  function buyTokens(address _beneficiary) public payable {
    
    uint256 ethers = msg.value;
    
    _preValidatePurchase(_beneficiary, ethers);
    
    _checkOpenings(ethers);
    
    _setFunds(_beneficiary,ethers);
    
    // update state of wei&#39;s raised during complete ICO
    fundsRaised = fundsRaised.add(ethers);
    //sjfhj
    _forwardFunds(_beneficiary); 
  }
  
  function _setFunds(address _beneficiary, uint256 _ethers) internal{
      if(presaleOpen){
          preSaleFundsArray.push(Funds(_beneficiary,_ethers, now));
      }
      else if(firstsaleOpen){
          firstSaleFundsArray.push(Funds(_beneficiary,_ethers, now));
      }
      else if(secondsaleOpen){
          secondSaleFundsArray.push(Funds(_beneficiary,_ethers, now));
      }
  }
  
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal{
   require(_beneficiary != address(0), &quot;WRONG Address&quot;);
   require(_weiAmount != 0, &quot;Insufficient funds&quot;);
   require(_weiAmount &gt;= minTxSize  &amp;&amp; _weiAmount &lt;= maxTxSize ,&quot;FUNDS should be MIN 0,1 ETH and Max 200 ETH&quot;);
  }
  
  function TotalSpenders() public view returns (uint256 preSaleSpenders,uint256 firstSaleSpenders,uint256 secondSaleSpenders){
      return ((preSaleFundsArray.length),(firstSaleFundsArray.length),(secondSaleFundsArray.length));
  }
  
  function _forwardFunds(address _beneficiary) internal {
    fundsWallet.transfer(msg.value);
  }
  
  function preSaleDelivery(address _beneficiary, uint256 _tokenAmount) public onlyOwner{
      _checkOpenings(0);
      require(!presaleOpen, &quot;Pre-Sale is NOT CLOSE &quot;);
      require(preSaleTokens &gt;= _tokenAmount,&quot;NO Pre-SALE Tokens Available&quot;);
      token.transfer(_beneficiary,_tokenAmount);
      preSaleTokens = preSaleTokens.sub(_tokenAmount);
  }
  
  function firstSaleDelivery(address _beneficiary, uint256 _tokenAmount) public onlyOwner{
      require(!presaleOpen &amp;&amp; !firstsaleOpen, &quot;First Sale is NOT CLOSE&quot;);
      if(saleTokens &lt;= _tokenAmount &amp;&amp; preSaleTokens &gt;= _tokenAmount){
          saleTokens = saleTokens.add(_tokenAmount);
          preSaleTokens = preSaleTokens.sub(_tokenAmount);
      }
      token.transfer(_beneficiary,_tokenAmount);
      saleTokens = saleTokens.sub(_tokenAmount);
  }
  
  function secondSaleDelivery(address _beneficiary, uint256 _tokenAmount) public onlyOwner{
      require(!presaleOpen &amp;&amp; !firstsaleOpen &amp;&amp; !secondsaleOpen, &quot;Second Sale is NOT CLOSE&quot;);
      require(saleTokens &gt;= _tokenAmount,&quot;NO Sale Tokens Available&quot;);
      token.transfer(_beneficiary,_tokenAmount);
      saleTokens = saleTokens.sub(_tokenAmount);
  }
  
  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burnTokens(uint256 _value) public onlyOwner {
      token.burn(_value);
  }
 
  function preSaleSpenderTxDetails(uint _index) public view returns(address spender, uint256 amount, uint256 time){
      return (preSaleFundsArray[_index].spender,preSaleFundsArray[_index].amount,preSaleFundsArray[_index].time);
  }
  
  function firstSaleSpenderTxDetails(uint _index) public view returns(address spender, uint256 amount, uint256 time){
      return (firstSaleFundsArray[_index].spender,firstSaleFundsArray[_index].amount,firstSaleFundsArray[_index].time);
  }
  
  function secSaleSpenderTxDetails(uint _index) public view returns(address spender, uint256 amount, uint256 time){
      return (secondSaleFundsArray[_index].spender,secondSaleFundsArray[_index].amount,secondSaleFundsArray[_index].time);
  }
  
  
  function transferRemainingTokens(address _to,uint256 _tokens) public onlyOwner {
      require(!presaleOpen &amp;&amp; !firstsaleOpen &amp;&amp; !secondsaleOpen);
      uint myBalance = token.balanceOf(this); 
      require(myBalance &gt;= _tokens);
      token.transfer(_to,_tokens);
  }
  
  function updateHardCap(uint256 _hardCap)public onlyOwner {
      hardCap = _hardCap * 10**uint(18);
  }
}