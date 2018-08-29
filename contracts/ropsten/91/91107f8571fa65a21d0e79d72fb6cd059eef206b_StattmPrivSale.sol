pragma solidity ^0.4.24;
//truffle-flattener contracts/StattmPrivSale.sol



// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

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

// File: zeppelin-solidity/contracts/math/SafeMath.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/BasicToken.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/StandardToken.sol

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

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/MintableToken.sol

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

// File: contracts/StattmToken.sol

contract StattmToken is MintableToken {

    string public constant name = "Stattm";
    string public constant symbol = "STTM";

    uint256 public constant decimals = 18;
    mapping(address => bool) public isWhiteListed;


    function burn() public {
        uint256 _b = balanceOf(msg.sender);
        balances[msg.sender] = 0;
        totalSupply_ = totalSupply_ - _b;
    }

    function addToWhitelist(address _user) public onlyOwner {
        isWhiteListed[_user] = true;
    }

    function removeFromWhitelist(address _user) public onlyOwner {
        isWhiteListed[_user] = false;
    }

    function init(address privateSale, address ito, address ico, address projectManagementAndAirdrop) public {

        require(totalSupply_ == 0);
        mint(address(privateSale), (10 ** decimals) * (5000000));
        mint(address(ito), (10 ** decimals) * (25000000));
        mint(address(ico), (10 ** decimals) * (35000000));
        mint(address(projectManagementAndAirdrop), (10 ** decimals) * (35100100));
        mintingFinished = true;
    }
}

// File: contracts/AbstractCrowdsale.sol

contract AbstractCrowdsale is Ownable{

    StattmToken public token;
    bool public softCapReached = false;
    bool public hardCapReached = false;
    uint256 private _now =0;

    event WhiteListReqested(address _adr);


    address public beneficiary;

    function saleStartTime() public constant returns(uint256);
    function saleEndTime() public constant returns(uint256);
    function softCapInTokens() public constant returns(uint256);
    function hardCapInTokens() public constant returns(uint256);

    function withdrawEndTime() public constant returns(uint256){
      return saleEndTime() + 30 days;
    }

    mapping(address => uint256) public ethPayed;
    mapping(address => uint256) public tokensToTransfer;
    uint256 public totalTokensToTransfer = 0;

    constructor(address _token, address _beneficiary) public {
        token = StattmToken(_token);
        beneficiary = _beneficiary;
    }

    function getCurrentPrice() public  constant returns(uint256) ;

    function forceReturn(address _adr) public onlyOwner{

        if (token.isWhiteListed(_adr) == false) {
          //send tokens, presale successful
          require(msg.value == 0);
          uint256 amountToSend = tokensToTransfer[msg.sender];
          tokensToTransfer[msg.sender] = 0;
          ethPayed[msg.sender] = 0;
          totalTokensToTransfer=totalTokensToTransfer-amountToSend;
          softCapReached = totalTokensToTransfer >= softCapInTokens();
          require(token.transfer(msg.sender, amountToSend));
        }
    }

    function getNow() public constant returns(uint256){
      if(_now!=0){
        return _now;
      }
      return now;
    }

    function setNow(uint256 _n) public returns(uint256){
/*Allowed only in tests*///      _now = _n;
      return now;
    }
    event Stage(uint256 blockNumber,uint256 index);
    event Stage2(address adr,uint256 index);
    function buy() public payable {
        require(getNow()  > saleStartTime());
        if (getNow()  > saleEndTime()
          && (softCapReached == false
          || token.isWhiteListed(msg.sender) == false)) {

            //return funds, presale unsuccessful or user not whitelisteed
            emit Stage(block.number,10);
            require(msg.value == 0);
            emit Stage(block.number,11);
            uint256 amountToReturn = ethPayed[msg.sender];
            totalTokensToTransfer=totalTokensToTransfer-tokensToTransfer[msg.sender];
            tokensToTransfer[msg.sender] = 0;
            ethPayed[msg.sender] = 0;
            softCapReached = totalTokensToTransfer >= softCapInTokens();
            emit Stage(block.number,12);
            msg.sender.transfer(amountToReturn);
            emit Stage(block.number,13);

        }
        if (getNow()  > saleEndTime()
          && softCapReached == true
          && token.isWhiteListed(msg.sender)) {

            emit Stage(block.number,20);
            //send tokens, presale successful
            require(msg.value == 0);
            emit Stage(block.number,21);
            uint256 amountToSend = tokensToTransfer[msg.sender];
            tokensToTransfer[msg.sender] = 0;
            ethPayed[msg.sender] = 0;
            require(token.transfer(msg.sender, amountToSend));
            emit Stage(block.number,22);

        }
        if (getNow()  <= saleEndTime() && getNow()  > saleStartTime()) {
            emit Stage(block.number,30);
            ethPayed[msg.sender] = ethPayed[msg.sender] + msg.value;
            tokensToTransfer[msg.sender] = tokensToTransfer[msg.sender] + getCurrentPrice() * msg.value;
            totalTokensToTransfer = totalTokensToTransfer + getCurrentPrice() * msg.value;

            if (totalTokensToTransfer >= hardCapInTokens()) {
                //hardcap exceeded - revert;
                emit Stage(block.number,31);
                revert();
                emit Stage(block.number,32);
            }
        }
        if(tokensToTransfer[msg.sender] > 0 &&  token.isWhiteListed(msg.sender) && softCapInTokens()==0){
          emit Stage(block.number,40);
          uint256 amountOfTokens = tokensToTransfer[msg.sender] ;
          tokensToTransfer[msg.sender] = 0;
          emit Stage(block.number,41);
          require(token.transfer(msg.sender,amountOfTokens));
          emit Stage(block.number,42);
        }
        if (totalTokensToTransfer >= softCapInTokens()) {
            emit Stage(block.number,50);
            softCapReached = true;
            emit Stage(block.number,51);
        }
        if (getNow()  > withdrawEndTime() && softCapReached == true && msg.sender == owner) {
            emit Stage(block.number,60);
            emit Stage(address(this).balance,60);
            //sale end successfully all eth is send to beneficiary
            beneficiary.transfer(address(this).balance);
            emit Stage(address(this).balance,60);
            emit Stage(block.number,61);
            token.burn();
            emit Stage(block.number,62);
        }

    }

}

// File: contracts/StattmPrivSale.sol

contract StattmPrivSale is AbstractCrowdsale{

    function softCapInTokens() public constant returns(uint256){
      return uint256(0);
    }

    function hardCapInTokens() public constant returns(uint256){
      return uint256(5000000*(10**18));
    }

    function saleStartTime() public constant returns(uint256){
      return 1535223482;  // 2018-08-25 00:00:00 GMT - start time for pre sale
    }

    function saleEndTime() public constant returns(uint256){
      return 1538765882;// 2018-10-5 23:59:59 GMT - end time for pre sale
    }
    address private dev;
    uint256 private devSum = 15 ether;

    constructor(address _token, address _dev, address _beneficiary) public AbstractCrowdsale(_token,_beneficiary) {
      dev = _dev;
    }

    function getCurrentPrice() public constant returns(uint256) {
        return 3000;
    }

    function() public payable {
      buy();
      if(softCapInTokens()==0 && token.isWhiteListed(msg.sender)==false){
        revert(&#39;User needs to be immediatly whiteListed in Presale&#39;);
      }

        if (address(this).balance < devSum) {
            devSum = devSum - address(this).balance;
            uint256 tmp = address(this).balance;
            dev.transfer(tmp);

        } else {
            dev.transfer(devSum);
            emit Stage2(dev,70);
            devSum = 0;
        }
        if(softCapInTokens()==0){
          beneficiary.transfer(address(this).balance);
        }
    }

}