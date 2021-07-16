//SourceUnit: perl1.sol

pragma solidity ^0.4.24;

contract TokenAdmin {
    bool public isPaused = false;
    bool public canBurn = false;

    address public ownerAddr;
    address public adminAddr;

    constructor() public {
        ownerAddr = msg.sender;
        adminAddr = msg.sender;
    }

    /// @dev Black Lists
    mapping (address => bool) blackLists;

    modifier isOwner() {
        require(msg.sender == ownerAddr);
        _;
    }

    modifier isAdmin() {
        require(msg.sender == adminAddr);
        _;
    }

    modifier isNotPaused() {
        require(isPaused == false);
        _;
    }

    modifier isNotBlackListed(address _addr){
       require(!blackLists[_addr]);
        _;
    }

    function setAdmin(address _newAdmin) external isOwner {
        require(_newAdmin != address(0));
        adminAddr = _newAdmin;
    }

    function setPause(bool _pause) external isAdmin {
        isPaused = _pause;
    }

    function setCanBurn(bool _val) external isAdmin {
        canBurn = _val;
    }

    function addBlackList(address _addr) external isAdmin {
      blackLists[_addr] = true;
    }

    function removeBlackList(address _addr) external isAdmin {
      delete blackLists[_addr];
    }

    function getBlackListStatus(address _addr) external view returns (bool) {
      return blackLists[_addr];
    }

}


interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}

contract withDraw{
  function transfer(address _to, uint256 _value) public;
}



interface TokenContract {
   function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external  view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external  returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
}





contract PERL is TokenAdmin {
  using SafeMath for uint256;
  // Public variables of the token
  string public name = "PERL";
  string public symbol = "PERL";
  uint8 public decimals = 6;
  uint256 public totalSupply = 10000000000 * (10 ** uint256(decimals)); // 10 billion tokens;
  uint256 public circulatingSupply;
  uint public _preMinted = 10000000 * (10 ** uint256(decimals)); //10 million preminted

  // This creates an array with all balances
  mapping (address => uint256) public _balances;
  mapping (address => mapping(address => uint256)) public _allowed;

  // This generates a public event on the blockchain that will notify clients
 event Transfer(address indexed from, address indexed to, uint256 value);

 event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  // This notifies clients about the amount burnt
  event Burn(address indexed from, uint256 value);

  event Freeze(address indexed from, uint256 value);


  event UnFreezeRequest(address indexed from, uint256 value);

  event UnFreezeApproved(address indexed from, uint256 value);

  event stageChanged(uint currentStaageNum , uint currentRate);

  event tokenCreated_unconfirmed(address indexed creator , uint amount , uint indexed currentStage );

  event tokenCreated_confirmed(address indexed creator , uint amount);






  uint public totalFreezeUserAllTime;
  uint public totalTVDFreeze;

  mapping (uint => address) public indAdd ;
  mapping (address => uint) public addInd ;
  mapping(address => uint) public myTVDfreeze;
  mapping(address => bool) public indexCheck; // user id check



  mapping(address => bool) public ifPending ;
  uint public totalPendingUnfreezeUsers;
  mapping(address => uint) public myTVDUnfreezeTime ;
  mapping(address => uint) public pendingUnfreeze ;
  uint public freezeLimit;



 //mining

  uint weii = 10 ** 6;
  uint public initialRateTRX = 32 * weii; //cons
  uint public currentRate;
  uint public stageSize = 5000000 * weii; //cons
  uint public thisStageMined;
  uint public currentStageNum;
  mapping (address => uint) public myMining;
  mapping (address => uint) public myMiningWithdraw;


  /**
    * Constructor function
    * Initializes contract with initial supply tokens to the creator of the contract
  */

  constructor() public {
    _balances[msg.sender] = _preMinted;
    freezeLimit = 172800; //2 days
    currentRate = initialRateTRX;
    totalPendingUnfreezeUsers = 0;
    totalFreezeUserAllTime = 0;
    totalTVDFreeze = 0;
    circulatingSupply = _preMinted;
    currentStageNum = 1;
    thisStageMined = 0;
    gameContract = msg.sender;

  }





  function balanceOf(address _owner) external view returns (uint256) {
    return _balances[_owner];
  }

  function allowance(address _owner, address _spender) external view returns (uint256) {
        return _allowed[_owner][_spender];
  }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
  function transfer(address _to, uint256 _value)
    public
    isNotPaused
    isNotBlackListed(_to)
    isNotBlackListed(msg.sender)
  {
    require(_value <= _balances[msg.sender] && _value > 0);
    require(_to != address(0));

    _balances[msg.sender] = _balances[msg.sender].sub(_value);
    _balances[_to] = _balances[_to].add(_value);

    emit Transfer(msg.sender, _to, _value);
  }

    /**
     * Transfer tokens from other address
     * Send `_value` tokens to `_to` on behalf of `_from`     
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
  function transferFrom(address _from, address _to, uint256 _value)
    public
    isNotPaused
    isNotBlackListed(_from)
    isNotBlackListed(_to)
    isNotBlackListed(msg.sender)
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= _balances[_from] && _value > 0);
    require(_value <= _allowed[_from][msg.sender]);

    _balances[_from] = _balances[_from].sub(_value);
    _balances[_to] = _balances[_to].add(_value);
    _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
  function approve(address _spender, uint256 _value)
    public
    isNotPaused
    isNotBlackListed(_spender)
    isNotBlackListed(msg.sender)
    returns (bool)
  {
    require(_spender != address(0));
    _allowed[msg.sender][_spender] = _value;
    //emit Approval(msg.sender, _spender, _value);
    return true;
  }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
  function approveAndCall(address _spender, uint256 _value, bytes _extraData)
    public
    isNotPaused
    isNotBlackListed(msg.sender)
    isNotBlackListed(_spender)

    returns (bool)
  {
    tokenRecipient spender = tokenRecipient(_spender);
    if (approve(_spender, _value)) {
      spender.receiveApproval(msg.sender, _value, this, _extraData);
      return true;
      }
  }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
  function burn(uint256 _value)
    public
    isNotPaused
    isNotBlackListed(msg.sender)
    returns (bool)
  {
    require (canBurn == true);                  // check if TVD can be burnt
    require(_balances[msg.sender] >= _value);   // Check if the sender has enough
    _balances[msg.sender] = _balances[msg.sender].sub(_value);   // Subtract from the sender
    totalSupply = totalSupply.sub(_value);                      // Updates totalSupply
    emit Burn(msg.sender, _value);
    return true;
  }
  function Time_call() returns (uint256){
        return now;
    }

//Freeze and Un-freeze
/*

THIS IS THE DATA STRUCTURE OF FREEZE AND UNFREEZE it's SILENCED HERE FOR DEVELOPER
  uint public totalFreezeUserAllTime = 0;
  uint public totalTVDFreeze = 0;

  mapping (uint => address) indAdd;
  mapping (address => uint) addInd;
  mapping(address => uint) myTVDfreeze;
  mapping(address => bool) indexCheck; // user id check



  mapping(address => bool) ifPending;
  uint totalPendingUnfreezeUsers = 0;
  mapping(address => uint) myTVDUnfreezeTime;
  mapping(address => uint) pendingUnfreeze;
  uint freezeLimit = 172800; //2 days

*/

  function changeUnfreezeTimeDif(uint _val) external
  isOwner
  isNotPaused
  isNotBlackListed(msg.sender)
  {
    require(_val > 0);
    freezeLimit = _val;
  }

  function freezeTVD(uint256 amount) public
  isNotPaused
  isNotBlackListed(msg.sender)
  returns (address,uint256)
{

    require(_balances[msg.sender] >= amount);
    //uint256 _now = Time_call();
    _balances[msg.sender] = (_balances[msg.sender]).sub(amount);


    if(indexCheck[msg.sender] == false) {

      indAdd[totalFreezeUserAllTime] = msg.sender;
      addInd[msg.sender] = totalFreezeUserAllTime;
      indexCheck[msg.sender] = true;
      totalFreezeUserAllTime += 1;
     }
    totalTVDFreeze += amount;
    myTVDfreeze[msg.sender] += amount;
    //myTVDfreezeTime[msg.sender] = now;
    emit Freeze(msg.sender,amount);
    return(msg.sender,amount);


  }
  function unfreezeTVD(uint256 amount) public
  isNotPaused
  isNotBlackListed(msg.sender)
  returns (address,uint256)

  {

    // require(now > (myTVDfreezeTime[msg.sender]+2 days));
    require(amount <= myTVDfreeze[msg.sender]);
    require (amount != 0);


    if(ifPending[msg.sender] == false)     {

      ifPending[msg.sender] = true;
      //uint8 _active = cdDiscInfo.activeWriteDb;
      //dbBoth[_active][cdDiscInfo.]
      //addIndWid[msg.sender] = totalPendingUnfreezeUsers;
      totalPendingUnfreezeUsers += 1;
    }
    totalTVDFreeze = totalTVDFreeze - amount;
    myTVDUnfreezeTime[msg.sender] = now;
    myTVDfreeze[msg.sender] = myTVDfreeze[msg.sender] - amount;
  /*  if(myTVDfreeze[msg.sender] == 0)
    {
      totalFreezeUser -= 1;
    } */
    //balances[address(this)] = (balances[address(this)]).add(amount);


    //record the pending transaction
    pendingUnfreeze[msg.sender] += amount;

    emit UnFreezeRequest(msg.sender,amount);

    return(msg.sender,amount);

  }

  function unfreezeApprove() public
  isNotPaused
  isNotBlackListed(msg.sender)
   returns(uint)

  {

    require (myTVDUnfreezeTime[msg.sender] > 1568615925 );
    uint _time = now;
    uint _diff = _time - myTVDUnfreezeTime[msg.sender];

    require (_diff >= freezeLimit );
    _balances[msg.sender] += pendingUnfreeze[msg.sender];
    emit UnFreezeApproved(msg.sender,pendingUnfreeze[msg.sender]);
    pendingUnfreeze[msg.sender] = 0;
     myTVDUnfreezeTime[msg.sender] = 0;
    totalPendingUnfreezeUsers = totalPendingUnfreezeUsers  - 1;
    return _diff;
  }

 /*

 //Mining Database

  weii = 10 ** 6; _
  uint public initialRateTRX = 32 * weii;
  uint public currentRate;
  uint public stageSize = 5000000 * weii;
  uint public thisStageMined;
  uint public currentStaageNum;
  mapping (address => uint) public myMining;
  mapping (address => uint) public myMiningWithdraw;

  */


  address gameContract;
  function setGameContract(address _gameContractAddr)
  isNotPaused
  isOwner
  external
  returns(bool res) {
    gameContract = _gameContractAddr;
    res = true;
  }


  function mining(uint _val)
  public
  returns(uint , uint ) {
    //Validate game contract address

    require (msg.sender == gameContract);
    //Check if _val can mine more less all than the tokens left in this current stage




   while(_val > 0)
    {
      //how much worth trx of tvd can I mine in this stage
           uint _diff = stageSize.sub(thisStageMined); //tvd
            _diff = _diff * currentRate; // trx
            _diff = _diff/weii;

            uint x; //debug code delete l8r
      //if value is more less or equal to _diff
            if(_val < _diff)
            {


              x=2; //debug code delete l8r



              _temp = (_val*weii)/currentRate;
              myMining[tx.origin] += _temp;
              myMiningWithdraw[tx.origin] += _temp;
              //event Token mined tokenCreated_unconfirmed -> (mined amount , address)
              emit tokenCreated_unconfirmed(tx.origin , _temp , currentStageNum );
              //stage n rate remains same

              thisStageMined += _temp; //full mined last stage
              //_diff = 0;
              _val = 0;
              break;
            }else if(_val > _diff)
            {
              x=1; //debug code delete l8r




              uint _temp = (_diff*weii)/currentRate;
              //transfer _diff amount
              myMining[tx.origin] += _temp;
              myMiningWithdraw[tx.origin] += _temp;
              //event Token mined tokenCreated_unconfirmed  -> (mined amount , address)
               emit tokenCreated_unconfirmed(tx.origin , _temp , currentStageNum );

              currentRate = currentRate + weii;
              currentStageNum = currentStageNum + 1; //stage shift +1
              //event for stage change -> emit the price and stage number
               emit stageChanged(currentStageNum , currentRate);

              thisStageMined = 0; //full mined last stage
              _diff = 0;
              _val = _val.sub(_diff);

            }

            else{
              x = 3;


              _temp = (_val*weii)/currentRate;
              myMining[tx.origin] += _temp;
              myMiningWithdraw[tx.origin] += _temp;
              //event Token mined tokenCreated_unconfirmed -> (mined amount , address)
              emit tokenCreated_unconfirmed(tx.origin , _temp , currentStageNum );

              currentRate = currentRate + weii;
              currentStageNum = currentStageNum + 1;
              thisStageMined = 0;
              _val = 0;

              emit stageChanged(currentStageNum , currentRate);
              break;
            }




    }


   //debug code delete l8r
    return(x,_diff);


  }

  //list of functions that will let the gemsbet admins withdraw any trx trc10,trc20 from this contract address
  //paste extra here
    function withdraw(address _withdrawAddr, uint _amount)  public isOwner
    {
      require(address(this).balance >=  _amount);
      _withdrawAddr.transfer(_amount);
    }
     function withdrawTRC10(address _withdrawAddr, uint _withdrawabletoken, uint _tokenId) external isOwner
    {
      address ContractAddress = address(this);
      uint tokenBalanceInContrct = ContractAddress.tokenBalance(_tokenId);
      require(_withdrawabletoken <=  tokenBalanceInContrct, "Not enought Token Available");
      _withdrawAddr.transferToken(_withdrawabletoken, _tokenId);
    }
    function withdrawTRC20(address _withdrawAddr, uint _withdrawabletoken, address _tokenAd) public  isOwner{
        withDraw tokencontract = withDraw(_tokenAd);
        tokencontract.transfer(_withdrawAddr,_withdrawabletoken);
    }

  /*
  event stageChanged(uint currentStaageNum , uint currentRate);

  event tokenCreated_unconfirmed(address indexed creator , uint amount , uint indexed currentStage );

  event tokenCreated_confirmed(address indexed creator , uint amount  );
  */

  function minedWithdraw()
  public
  returns(bool _res , uint _withdrawAmount){

     require (myMiningWithdraw[tx.origin] >= _withdrawAmount);

    _withdrawAmount = myMiningWithdraw[tx.origin];
    circulatingSupply  += _withdrawAmount;
    //mint
     _balances[address(this)] += myMiningWithdraw[tx.origin];

     //trans
    _balances[address(this)] -= myMiningWithdraw[tx.origin];
    _balances[tx.origin] += myMiningWithdraw[tx.origin];
     myMiningWithdraw[tx.origin] = 0;

     _res = true;



     //event -> tokenCreated_confirmed
     emit Transfer(address(this),tx.origin,_withdrawAmount);
     emit tokenCreated_confirmed(tx.origin , _withdrawAmount );

  }

  function burnFrom(address _from, uint256 _value)
    public
    isNotPaused
    isNotBlackListed(_from)
    isNotBlackListed(msg.sender)
    returns (bool)
  {
    require (canBurn == true);                                                     // check if TVD can be burnt
    require(_balances[_from] >= _value);                                           // Check if the targeted balance is enough
    require(_value <= _allowed[_from][msg.sender]);                                // Check allowance
    _balances[_from] = _balances[_from].sub(_value);                               // Subtract from the targeted balance
    _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value);         // Subtract from the sender's allowance
    totalSupply = totalSupply.sub(_value);                                          // Update totalSupply
    emit Burn(_from, _value);
    return true;
  }


  //Fallback
  uint x;
    function() external payable {
    x = x + 1;
    }
    function get() public view returns (uint) {
    return x;
    }

    function kill() public isOwner {
      selfdestruct(gameContract);
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
}