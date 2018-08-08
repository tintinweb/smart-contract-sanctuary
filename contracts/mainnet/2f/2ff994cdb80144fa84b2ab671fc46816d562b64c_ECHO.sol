pragma solidity ^0.4.21;

/**
 * @title SafeMath for performing valid mathematics.
 */
library SafeMath {
 
  function Mul(uint a, uint b) internal pure returns (uint) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function Div(uint a, uint b) internal pure returns (uint) {
    //assert(b > 0); // Solidity automatically throws when Dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function Sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  } 

  function Add(uint a, uint b) internal pure returns (uint) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  } 
}

/**
* @title Contract that will work with ERC223 tokens.
*/
contract ERC223ReceivingContract { 
    /**
     * @dev Standard ERC223 function that will handle incoming token transfers.
     *
     * @param _from  Token sender address.
     * @param _value Amount of tokens.
     * @param _data  Transaction metadata.
     */
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

/**
 * Contract "Ownable"
 * Purpose: Defines Owner for contract and provide functionality to transfer ownership to another account
 */
contract Ownable {

  //owner variable to store contract owner account
  address public owner;
  //add another owner
  address deployer;

  //Constructor for the contract to store owner&#39;s account on deployement
  function Ownable() public {
    owner = msg.sender;
    deployer = msg.sender;
  }

  //modifier to check transaction initiator is only owner
  modifier onlyOwner() {
    require (msg.sender == owner || msg.sender == deployer);
      _;
  }

  //ownership can be transferred to provided newOwner. Function can only be initiated by contract owner&#39;s account
  function transferOwnership(address _newOwner) public onlyOwner {
    require (_newOwner != address(0));
    owner = _newOwner;
  }

}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;
  uint256 public startTime;
  uint256 public endTime;
  uint256 private pauseTime;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    //Record the pausing time only if any startTime is defined
    //in other cases, it will work as a toggle switch only
    if(startTime > 0){
        pauseTime = now;
    }
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    //if endTime is defined, only then proceed with its updation
    if(endTime > 0 && pauseTime > startTime){
        uint256 pauseDuration = pauseTime - startTime;
        endTime = endTime + pauseDuration;
    }
    emit Unpause();
  }
}

/**
 * @title ERC20 interface
 */
contract ERC20 is Pausable {
    uint256 public totalSupply;
    function balanceOf(address _owner) public view returns (uint256 value);
    function transfer(address _to, uint256 _value) public returns (bool _success);
    function allowance(address owner, address spender) public view returns (uint256 _value);
    function transferFrom(address from, address to, uint256 value) public returns (bool _success);
    function approve(address spender, uint256 value) public returns (bool _success);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed _from, address indexed _to, uint _value);
}

contract ECHO is ERC20 {

    using SafeMath for uint256;
    //The name of the  token
    string public constant name = "ECHO token";
    //The token symbol
    string public constant symbol = "ECHO";
    //To denote the locking on transfer of tokens among token holders
    bool public locked;
    //The precision used in the calculations in contract
    uint8 public constant decimals = 18;
    //number of tokens available for 1 eth
    uint256 public constant PRICE=4000;
    //maximum number of tokens
    uint256 constant MAXCAP = 322500000e18;
    //maximum number of tokens available for Sale
    uint256 constant HARD_CAP = 8e7*1e18;
    //the account which will receive all balance
    address ethCollector;
    //to save total number of ethers received
    uint256 public totalWeiReceived;
    //type of sale: 1=presale, 2=ICO
    uint256 public saleType;
    

    //Mapping to relate owner and spender to the tokens allowed to transfer from owner
    mapping(address => mapping(address => uint256)) allowed;
    //Mapping to relate number of token to the account
    mapping(address => uint256) balances;
    
    function isSaleRunning() public view returns (bool){
        bool status = false;
        // 1522972800 = 6 april 2018
        // 1525392000 = 4 may 2018
        // 1527811200 = 1 june 2018
        // 1531094400 = 9 july 2018
        
        //Presale is going on
        if(now >= startTime  && now <= 1525392000){
            //Aprill 6 to before 4 may
            status = true;
        }
    
        //ICO is going on
        if(now >= 1527811200 && now <= endTime){
            // june 1 to before july 9
            status = true;
        }
        return status;
    }

    function countDownToEndCrowdsale() public view returns(uint256){
        assert(isSaleRunning());
        return endTime.Sub(now);
    }
    //events
    event StateChanged(bool);

    function ECHO() public{
        totalSupply = 0;
        startTime = 1522972800; //April 6, 2018 GMT
        endTime = 1531094400; //9 july, 2018 GMT
        locked = true;
        setEthCollector(0xc8522E0444a94Ec9a5A08242765e1196DF1EC6B5);
    }
    //To handle ERC20 short address attack
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    modifier onlyUnlocked() { 
        require (!locked); 
        _; 
    }

    modifier validTimeframe(){
        require(isSaleRunning());
        _;
    }
    
    function setEthCollector(address _ethCollector) public onlyOwner{
        require(_ethCollector != address(0));
        ethCollector = _ethCollector;
    }

    //To enable transfer of tokens
    function unlockTransfer() external onlyOwner{
        locked = false;
    }

    /**
    * @dev Check if the address being passed belongs to a contract
    *
    * @param _address The address which you want to verify
    * @return A bool specifying if the address is that of contract or not
    */
    function isContract(address _address) private view returns(bool _isContract){
        assert(_address != address(0) );
        uint length;
        //inline assembly code to check the length of address
        assembly{
            length := extcodesize(_address)
        }
        if(length > 0){
            return true;
        }
        else{
            return false;
        }
    }

    /**
    * @dev Check balance of given account address
    *
    * @param _owner The address account whose balance you want to know
    * @return balance of the account
    */
    function balanceOf(address _owner) public view returns (uint256 _value){
        return balances[_owner];
    }

    /**
    * @dev Transfer sender&#39;s token to a given address
    *
    * @param _to The address which you want to transfer to
    * @param _value the amount of tokens to be transferred
    * @return A bool if the transfer was a success or not
    */
    function transfer(address _to, uint _value) onlyUnlocked onlyPayloadSize(2 * 32) public returns(bool _success) {
        require( _to != address(0) );
        bytes memory _empty;
        assert((balances[msg.sender] >= _value) && _value > 0 && _to != address(0));
        balances[msg.sender] = balances[msg.sender].Sub(_value);
        balances[_to] = balances[_to].Add(_value);
        if(isContract(_to)){
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _empty);
        }
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Transfer tokens to an address given by sender. To make ERC223 compliant
    *
    * @param _to The address which you want to transfer to
    * @param _value the amount of tokens to be transferred
    * @param _data additional information of account from where to transfer from
    * @return A bool if the transfer was a success or not
    */
    function transfer(address _to, uint _value, bytes _data) onlyUnlocked onlyPayloadSize(3 * 32) public returns(bool _success) {
        assert((balances[msg.sender] >= _value) && _value > 0 && _to != address(0));
        balances[msg.sender] = balances[msg.sender].Sub(_value);
        balances[_to] = balances[_to].Add(_value);
        if(isContract(_to)){
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        emit Transfer(msg.sender, _to, _value);
        return true;
        
    }

    /**
    * @dev Transfer tokens from one address to another, for ERC20.
    *
    * @param _from The address which you want to send tokens from
    * @param _to The address which you want to transfer to
    * @param _value the amount of tokens to be transferred
    * @return A bool if the transfer was a success or not 
    */
    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3*32) public onlyUnlocked returns (bool){
        bytes memory _empty;
        assert((_value > 0)
           && (_to != address(0))
           && (_from != address(0))
           && (allowed[_from][msg.sender] >= _value ));
       balances[_from] = balances[_from].Sub(_value);
       balances[_to] = balances[_to].Add(_value);
       allowed[_from][msg.sender] = allowed[_from][msg.sender].Sub(_value);
       if(isContract(_to)){
           ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
           receiver.tokenFallback(msg.sender, _value, _empty);
       }
       emit Transfer(_from, _to, _value);
       return true;
    }

    /**
    * @dev Function to check the amount of tokens that an owner has allowed a spender to recieve from owner.
    *
    * @param _owner address The address which owns the funds.
    * @param _spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender to spend.
    */
    function allowance(address _owner, address _spender) public view returns (uint256){
        return allowed[_owner][_spender];
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    *
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint256 _value) public returns (bool){
        if( _value > 0 && (balances[msg.sender] >= _value)){
            allowed[msg.sender][_spender] = _value;
            emit Approval(msg.sender, _spender, _value);
            return true;
        }
        else{
            return false;
        }
    }

    function mintAndTransfer(address beneficiary, uint256 tokensToBeTransferred) public validTimeframe onlyOwner {
        require(totalSupply.Add(tokensToBeTransferred) <= MAXCAP);
        totalSupply = totalSupply.Add(tokensToBeTransferred);
        balances[beneficiary] = balances[beneficiary].Add(tokensToBeTransferred);
        emit Transfer(0x0, beneficiary ,tokensToBeTransferred);
    }

    function getBonus(uint256 _tokensBought)public view returns(uint256){
        uint256 bonus = 0;
        /*April 6- April 13 -- 20% 
        April 14- April 21 -- 10% 
        April 22 - May 3-- 5% 
        
        ICO BONUS WEEKS: 
        June 1 - June 9 -- 20% 
        June 10 - June 17 -- 10% 
        June 18 - June 30 -- 5% 
        July 1 - July 9 -- No bonus 
        */
        // 1522972800 = 6 april 2018
        // 1523577600 = 13 April 2018
        // 1523664000 = 14 April 2018
        // 1524268800 = 21 April 2018
        // 1524355200 = 22 April 2018
        // 1525305600 = 3 April 2018
        // 1525392000 = 4 may 2018
        // 1527811200 = 1 june 2018
        // 1528502400 = 9 june 2018
        // 1528588800 = 10 june 2018
        // 1529193600 = 17 june 2018
        // 1529280000 = 18 june 2018
        // 1530316800 = 30 june 2018
        // 1530403200 = 1 july 2018
        // 1531094400 = 9 july 2018
        if(saleType == 1){
            //Presale is going on
            if(now >= 1522972800 && now < 1523664000){
                //6 april to before 14 april
                bonus = _tokensBought*20/100;
            }
            else if(now >= 1523664000 && now < 1524355200){
                //14 april to before 22 april
                bonus = _tokensBought*10/100;
            }
            else if(now >= 1524355200 && now < 1525392000){
                //Aprill 22 to before 4 may
                bonus = _tokensBought*5/100;
            }
        }
        if(saleType == 2){
            //ICO is going on
            if(now >= 1527811200 && now < 1528588800){
                // 1 june to before 10 june
                bonus = _tokensBought*20/100;
            }
            else if(now >= 1528588800 && now < 1529280000){
                // june 10 to before june 18
                bonus = _tokensBought*10/100;
            }
            else if(now >= 1529280000 && now < 1530403200){
                // june 18 to before july 1
                bonus = _tokensBought*5/100;
            }
        }
        return bonus;
    }
    function buyTokens(address beneficiary) internal validTimeframe {
        uint256 tokensBought = msg.value.Mul(PRICE);
        tokensBought = tokensBought.Add(getBonus(tokensBought));
        balances[beneficiary] = balances[beneficiary].Add(tokensBought);
        totalSupply = totalSupply.Add(tokensBought);
       
        assert(totalSupply <= HARD_CAP);
        totalWeiReceived = totalWeiReceived.Add(msg.value);
        ethCollector.transfer(msg.value);
        emit Transfer(0x0, beneficiary, tokensBought);
    }

    /**
    * Finalize the crowdsale
    */
    function finalize() public onlyUnlocked onlyOwner {
        //Make sure Sale is not running
        //If sale is running, then check if the hard cap has been reached or not
        assert(!isSaleRunning() || (HARD_CAP.Sub(totalSupply)) <= 1e18);
        endTime = now;

        //enable transferring of tokens among token holders
        locked = false;
        //Emit event when crowdsale state changes
        emit StateChanged(true);
    }

    function () public payable {
        buyTokens(msg.sender);
    }

    /**
    * Failsafe drain
    */
    function drain() public onlyOwner {
        owner.transfer(address(this).balance);
    }
}