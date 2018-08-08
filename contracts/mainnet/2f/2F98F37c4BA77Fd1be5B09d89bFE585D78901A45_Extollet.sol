pragma solidity ^0.4.24;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

contract Controlled {
    address public controller;
    /// @notice The address of the controller is the only address that can call
    ///  a function with this modifier
    modifier onlyController { require(msg.sender == controller); _; }
    // @notice Constructor
    constructor() public { controller = msg.sender;}
    /// @notice Changes the controller of the contract
    /// @param _newController The new controller of the contract
    function changeController(address _newController) public onlyController {
        controller = _newController;
    }
}

// ERC Token Standard #20 Interface
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract SofiaToken is ERC20Interface,Controlled {

    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    /*
     * @notice &#39;constructor()&#39; initiates the Token by setting its funding
       parameters
     * @param _totalSupply Total supply of tokens
     */
    constructor(uint _totalSupply) public {
      symbol = "SFX";
      name = "Sofia Token";
      decimals = 18;
      totalSupply = _totalSupply  * (1 ether);
      balances[msg.sender] = totalSupply; //transfer all Tokens to contract creator
      emit Transfer(address(0),controller,totalSupply);
    }

    /*
     * @notice ERC20 Standard method to return total number of tokens
     */
    function totalSupply() public view returns (uint){
      return totalSupply;
    }

    /*
     * @notice ERC20 Standard method to return the token balance of an address
     * @param tokenOwner Address to query
     */
    function balanceOf(address tokenOwner) public view returns (uint balance){
       return balances[tokenOwner];
    }

    /*
     * @notice ERC20 Standard method to return spending allowance
     * @param tokenOwner Owner of the tokens, who allows
     * @param spender Token spender
     */
    function allowance(address tokenOwner, address spender) public view returns (uint remaining){
      if (allowed[tokenOwner][spender] < balances[tokenOwner]) {
        return allowed[tokenOwner][spender];
      }
      return balances[tokenOwner];
    }

    /*
     * @notice ERC20 Standard method to tranfer tokens
     * @param to Address where the tokens will be transfered to
     * @param tokens Number of tokens to be transfered
     */
    function transfer(address to, uint tokens) public  returns (bool success){
      return doTransfer(msg.sender,to,tokens);
    }

    /*
     * @notice ERC20 Standard method to transfer tokens on someone elses behalf
     * @param from Address where the tokens are held
     * @param to Address where the tokens will be transfered to
     * @param tokens Number of tokens to be transfered
     */
    function transferFrom(address from, address to, uint tokens) public returns (bool success){
      if(allowed[from][msg.sender] > 0 && allowed[from][msg.sender] >= tokens)
      {
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        return doTransfer(from,to,tokens);
      }
      return false;
    }

    /*
     * @notice method that does the actual transfer of the tokens, to be used by both transfer and transferFrom methods
     * @param from Address where the tokens are held
     * @param to Address where the tokens will be transfered to
     * @param tokens Number of tokens to be transfered
     */
    function doTransfer(address from,address to, uint tokens) internal returns (bool success){
        if( tokens > 0 && balances[from] >= tokens){
            balances[from] = balances[from].sub(tokens);
            balances[to] = balances[to].add(tokens);
            emit Transfer(from,to,tokens);
            return true;
        }
        return false;
    }

    /*
     * @notice ERC20 Standard method to give a spender an allowance
     * @param spender Address that wil receive the allowance
     * @param tokens Number of tokens in the allowance
     */
    function approve(address spender, uint tokens) public returns (bool success){
      if(balances[msg.sender] >= tokens){
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender,spender,tokens);
        return true;
      }
      return false;
    }

    /*
     * @notice revert any incoming ether
     */
    function () public payable {
        revert();
    }

  /*
   * @notice a specific amount of tokens. Only controller can burn tokens
   * @param _value The amount of token to be burned.
   */
  function burn(uint _value) public onlyController{
    require(_value <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit Burn(msg.sender, _value);
    emit Transfer(msg.sender, address(0), _value);
  }

  /*
   * Events
   */
  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
  event Burn(address indexed burner, uint value);
}

contract Extollet is Controlled {

    using SafeMath for uint;

    string public name;                     //Campaign name
    uint256 public startFundingTime;        //In UNIX Time Format
    uint256 public endFundingTime;          //In UNIX Time Format
    uint public volume;                     //Total volume of tokens in this Campaign
    uint public totalCollected;             //In WEI
    uint public totalTokensSold;            //Number of tokens sold so far
    uint public rate;                       //Rate in WEI
    SofiaToken public tokenContract;        //The token for this Campaign
    address public vaultAddress;           //The address to hold the funds donated

  /*
   * @notice &#39;constructor()&#39; initiates the Campaign by setting its funding parameters
   * @param _startFundingTime The time that the Campaign will be able to start receiving funds
   * @param _endFundingTime The time that the Campaign will stop being able to receive funds
   * @param _volume Total volume
   * @param _rate Rate in wei
   * @param _vaultAddress The address that will store the donated funds
   * @param _tokenAddress Address of the token contract this contract controls
   */
  constructor(
      uint256 _startFundingTime,
      uint256 _endFundingTime,
      uint _volume,
      uint _rate,
      address _vaultAddress,
      address _tokenAddress
    ) public {
     require ((_endFundingTime >= now) &&            //Cannot end in the past
              (_endFundingTime > _startFundingTime) &&
              (_volume > 0) &&
              (_rate > 0) &&
              (_vaultAddress != 0));                 //To prevent burning ETH
      startFundingTime = _startFundingTime;
      endFundingTime = _endFundingTime;
      volume = _volume.mul(1 ether);
      rate = _rate;
      vaultAddress = _vaultAddress;
      totalCollected = 0;
      totalTokensSold = 0;
      tokenContract = SofiaToken(_tokenAddress); //The Deployed Token Contract
      name = "Extollet";
      }

  /*
   * @notice The fallback function is called when ether is sent to the contract, it
     simply calls `doPayment()` with the address that sent the ether as the
     `_owner`. Payable is a required solidity modifier for functions to receive
     ether, without this modifier functions will throw if ether is sent to them
   */
  function () public payable{
    doPayment(msg.sender);
  }

  /*
   * @notice `proxyPayment()` allows the caller to send ether to the Campaign and
     have the tokens created in an address of their choosing
   * @param _owner The address that will hold the newly created tokens
   */
  function proxyPayment(address _owner) public payable returns(bool) {
      doPayment(_owner);
      return true;
  }

  /*
   * @notice `doPayment()` is an internal function that sends the ether that this
     contract receives to the `vault` and creates tokens in the address of the
     `_owner` assuming the Campaign is still accepting funds
   * @param _owner The address that will hold the newly created tokens
   */
  function doPayment(address _owner) internal {
//   Calculate token amount
    uint tokenAmount = getTokenAmount(msg.value);
//   Check that the Campaign is allowed to receive this donation
    require ((now >= startFundingTime) &&
            (now <= endFundingTime) &&
            (tokenContract.controller() != 0) &&            //Extra check
            (msg.value != 0) &&
            ((totalTokensSold + tokenAmount) <= volume)
            );
  //Send the ether to the vault
    preValidatePurchase(_owner,msg.value);
    require (vaultAddress.send(msg.value));
    require (tokenContract.transfer(_owner,tokenAmount));
//  Track how much the Campaign has collected
    totalCollected += msg.value;
    totalTokensSold += tokenAmount;
    emit FundTransfer(msg.sender,tokenAmount,true);
    return;
    }

    /*
     * @notice Validation of an incoming purchase. Use require statemens to revert state when conditions are not met.
     * @param _beneficiary Address performing the token purchase
     * @param _weiAmount Value in wei involved in the purchase
     */
    function preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal pure{
      require(_beneficiary != address(0));
      require(_weiAmount != 0);
    }

    /*
     * @param _weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function getTokenAmount(uint _weiAmount) internal view returns (uint) {
      uint preDecimalAmount = _weiAmount.div(rate);
      uint postDecimalAmount = preDecimalAmount.mul(1 ether);
      return postDecimalAmount;
    }

    /*
     * @notice `onlyController` changes the location that ether is sent
     * @param _newVaultAddress The address that will receive the ether sent to this
     */
    function setVault(address _newVaultAddress) public onlyController {
        vaultAddress = _newVaultAddress;
    }

    /*
     * @notice `onlyController` changes the campaing ending time
     * @param newEndingTime The new campaign end time in UNIX time format
     */
    function modifyEndFundingTime(uint256 newEndingTime) public onlyController{
      require((now < endFundingTime) && (now < newEndingTime));
      endFundingTime = newEndingTime;
    }

    /*
     * @dev `finalizeFunding()` can only be called after the end of the funding period.
     */
      function finalizeFunding(address to) public onlyController{
        require(now >= endFundingTime);
        uint tokensLeft = tokenContract.balanceOf(this);
        require(tokensLeft > 0);
        require(tokenContract.transfer(to,tokensLeft));
      }

    /*
     *Events
     */
    event FundTransfer(address backer, uint amount, bool isContribution);
}