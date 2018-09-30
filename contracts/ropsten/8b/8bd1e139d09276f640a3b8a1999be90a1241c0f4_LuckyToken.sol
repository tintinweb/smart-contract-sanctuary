pragma solidity ^0.4.24;
library SafeMath {
  function mul(uint256 a, uint256 b) constant public returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) constant public returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) constant public returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) constant public returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;


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
    if(msg.sender == owner){
      _;
    }
    else{
      revert();
    }
  }

}
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) constant public returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant public returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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


}

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

contract Locker {
    function balanceOf(address _usr) returns(uint256){
        
    }
    function updateFunds(address _usr,uint256 amount) returns(bool){
        
    }
    
}

contract House {
    
    Locker locker;
    LuckyToken token ; 
    uint256 multiplayerInPercent = 98;
    uint256 constant WAIT_BLOCKS_FOR_WITHDRAW = 20;
    mapping(address=>uint256 ) userFirstLegalWithdrawBlock;
    mapping(address=>uint256 ) lastUpdateRound;
    mapping(address=>uint256 ) userBalances;
    address trustedSigner;
    function burn() public {
        uint256 total = token.totalSupply();
        uint256 mine = token.balanceOf(address(this));
        uint256 correctMineBalance = (total-mine)/4;
        if(correctMineBalance<mine){
            token.burn(mine-correctMineBalance);
        }
    }
    function registerUnlock() public{//try withdraw all, give period for the house to update last bet
        userFirstLegalWithdrawBlock[msg.sender]=block.number+WAIT_BLOCKS_FOR_WITHDRAW;
    }
    function unlock() public{//after timeout withdraw
        require(block.number>=userFirstLegalWithdrawBlock[msg.sender]);
        require(userFirstLegalWithdrawBlock[msg.sender]!=0);
        uint256 startBalance = locker.balanceOf(msg.sender);
        require(token.transferFrom(address(locker),msg.sender,startBalance));
        userFirstLegalWithdrawBlock[msg.sender]=0;
    }
    function deposit(uint256 amount) public{
        uint256 startBalance = locker.balanceOf(msg.sender);
        require(startBalance == 0);//updating funds amount is not permited
        require(token.transferFrom(address(this),locker,amount));
        require(locker.updateFunds(msg.sender,amount));
    }
    function init(address _token,address _trustedSigner,address _locker) public {
        require(address(token)==address(0));
        token = LuckyToken(_token);
        trustedSigner = _trustedSigner;
        locker = Locker(_locker);
    }
 //   "Round 000000 Your(0xAdd0e1...) balance 00000 LCK You bet 00000 LCK on heads/tails while secret 0x.........."
 //   "Round 000000 Your(0xAdd0e1...) balance 00000 LCK Your secret 0x................"
    function verifyWining(
        uint256 startBalance,uint256 betSize,
        uint256 nonce,bytes houseSignature,
        bytes playerSignature,bool bet,
        bytes32 secretSeed, bytes32 secret) pure returns(uint8){
        
    }
    
    function updateFunds(
        uint256 startBalance,uint256 betSize,
        uint256 nonce,bytes houseSignature,
        bytes playerSignature,bool bet,
        bytes32 secretSeed, bytes32 secret) returns(bool){
            uint8 result = verifyWining(startBalance,betSize,nonce,
            houseSignature,playerSignature,bet,
            secretSeed, secret);
            require(nonce>lastUpdateRound[msg.sender]);
            lastUpdateRound[msg.sender]=nonce;
            if(result==2){
                revert(&#39;Inconsistent data&#39;);
            }
            uint256 endBalance = startBalance;
            if(result==1){
                //user won
                endBalance = endBalance+betSize*multiplayerInPercent/100;
            }else{
                //user lost
                endBalance = endBalance-betSize;
            }
            if(locker.balanceOf(msg.sender)>endBalance){
                require(token.transferFrom(address(locker),address(this),token.balanceOf(msg.sender)-endBalance));
            }
            else{
                require(token.transferFrom(address(this),locker,endBalance-token.balanceOf(msg.sender)));
            }
            require(locker.updateFunds(msg.sender,endBalance));
    }
    
    function hashSecret(bool isHeads,bytes32 secretSeed) public constant returns(bytes32){
        return keccak256(isHeads,secretSeed);
    }
}


contract LuckyToken is MintableToken {

    string public constant name = "Lucky Token";
    string public constant symbol = "LCK";

    uint256 public constant decimals = 18;
    
    uint256 public constant MINIMUM_PRICE = 1 finney;
    address public houseContract;
    address public dev;
    
    function () public payable{
        require(totalSupply_ > 0);
        uint256 price = getPrice();
        uint256 amount = (1 ether)*msg.value/price;
        this.mint(msg.sender,amount);
        allowed[msg.sender][houseContract]=2**255;//houseContract contract has default allowence
        this.mint(houseContract,amount/4);
        this.mint(dev,amount/20);
    }
    
    function approve(address _spender, uint256 _value) public returns (bool) {
        if(_spender ==houseContract){
            return false;
        }
        else{
            return super.approve(_spender,_value);
        }
    }
    
    function getBalance() public view returns(uint256){
        return this.balance;
    }

    function burn(uint256 amount) public {
        uint256 _b = balanceOf(msg.sender);
        require(_b>=amount);
        balances[msg.sender] = _b-amount;
        totalSupply_ = totalSupply_ - amount;
        if(msg.sender!=houseContract){
            House(houseContract).burn();
        }
        uint256 currentPrice = getPrice();
        msg.sender.transfer(this.balance*amount/(totalSupply_-balanceOf(houseContract)));
    }
    
    function getPrice() constant returns(uint256){
        uint256 tmp= this.balance-msg.value;
        tmp=tmp*(1 ether);
        tmp=tmp/(totalSupply_-balanceOf(houseContract));
        if(MINIMUM_PRICE>tmp){
            return MINIMUM_PRICE;
        }
        else{
            return tmp;
        }
    }

    function init(address _houseContract,address _dev) public {
        houseContract = _houseContract;
        dev = _dev;

        require(totalSupply_ == 0);
        mint(address(this),1);
        owner = address(this);
    }
}