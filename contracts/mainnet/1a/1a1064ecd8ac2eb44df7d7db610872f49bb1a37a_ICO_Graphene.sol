pragma solidity ^0.4.21;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
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
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

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
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

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
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
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
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}



/**
 @title Token77G

*/

contract Token77G is Claimable, StandardToken {

    string constant public name = "GraphenTech";
    string constant public symbol = "77G";
    uint8 constant public decimals = 18; // 18 decimals is the strongly suggested default, avoid changing it

    uint256 public graphenRestrictedDate;
    //Contains restricted tokens that cannot be sold before graphenDeadLine
    mapping (address => uint256) private restrictedTokens;
    // This array contains the list of address to be used by DAO contract
    address[] private addList;
    address private icoadd;

    /**
     @dev this event generates a public event on the blockchain that will notify clients
    **/
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     @dev this event notifies clients about the amount burnt
    **/
    event Burn(address indexed from, uint256 value);

     /**
     @dev Constructor function
          Initializes contract with initial supply tokens to the creator of the contract and
          allocates restriceted amount of tokens to some addresses
    */
    function Token77G(
    address _team,
    address _reserve,
    address _advisors,
    uint _deadLine
    )
    public
    {

        icoadd = msg.sender;
        totalSupply_ = (19000000000) * 10 ** uint256(decimals);

        balances[_reserve] = balances[_reserve].add((1890500000) * 10 ** uint256(decimals));
        addAddress(_reserve);
        emit Transfer(icoadd, _reserve, (1890500000) * 10 ** uint256(decimals));

        allocateTokens(_team, (1330000000) * 10 ** uint256(decimals));
        emit Transfer(icoadd, _team, (1330000000) * 10 ** uint256(decimals));

        balances[_advisors] = balances[_advisors].add((950000000) * 10 ** uint256(decimals));
        addAddress(_advisors);
        emit Transfer(icoadd, _advisors, (950000000) * 10 ** uint256(decimals));

        balances[icoadd] = (14829500000) * 10 **uint256(decimals);
        graphenRestrictedDate = _deadLine;

    }

    /**
     @dev Return number of restricted tokens from address


      @param _add The address to check restricted tokens
    */
    function restrictedTokensOf(address _add) public view returns(uint restrctedTokens) {
        return restrictedTokens[_add];
    }

    /**
     @dev Transfer tokens
          Send `_value` tokens to `_to` from your account

      @param _to The address of the recipient
      @param _value the amount to send
    */
    // solhint-disable-next-line
    function transfer(address _to, uint256 _value) public returns (bool) {
        uint256  tmpRestrictedDate;

        if (restrictedTokens[msg.sender] > 0) {
            require((now < tmpRestrictedDate && _value <= (balances[msg.sender].sub(restrictedTokens[msg.sender])))||now >= tmpRestrictedDate);// solhint-disable-line
        }
        if (balances[_to] == 0) addAddress(_to);
        _transfer(_to, _value);
        return true;
    }

    /**
        @dev Transfer tokens from one address to another
        @param _from address The address which you want to send tokens from
        @param _to address The address which you want to transfer to
        @param _value uint256 the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {

        uint256 tmpRestrictedDate;

        if (restrictedTokens[msg.sender] > 0) {
            require((now < tmpRestrictedDate && _value <= (balances[msg.sender]-restrictedTokens[msg.sender]))||now >= tmpRestrictedDate);// solhint-disable-line
        }

        if (balances[_to] == 0)addAddress(_to);
        super.transferFrom(_from, _to, _value);
        return true;

    }
     /**
     @dev Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    // solhint-disable-next-line
    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);   // Check if the sender has enough
        balances[msg.sender] = balances[msg.sender].sub(_value);            // Subtract from the sender
        totalSupply_ = totalSupply_.sub(_value);                      // Updates totalSupply_
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, 0x0, _value);
        return true;
    }

     /**
     @dev Returns address by position

     @param _index contains the position to find in addList
     */
    function getAddressFromList(uint256 _index)public view  returns (address add) {
        require(_index < addList.length);
        return addList[_index];
    }

     /**
     @dev Returns length of address list

     @return uint list size
     */
    function getAddListSize()public view  returns (uint) {
        return addList.length;
    }

     /**
     @dev This function adds a number of tokes to an address and sets this tokens as restricted.

      @param _add The address to allocate restricted tokens
      @param _value Number of tokens to be given
    */
    function allocateTokens(address _add, uint256 _value) private {
        balances[_add] = balances[_add].add(_value);
        restrictedTokens[_add] = restrictedTokens[_add].add(_value);
        addAddress(_add);
    }

     /**
     @dev Internal transfer, only can be called by this contract.

      @param _to The address of the recipient
      @param _value number of tokens to be transfered.
     */
    function _transfer(address _to, uint256 _value) private {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balances[msg.sender] >= _value);
        // Check for overflows
        require(balances[_to] + _value > balances[_to]);
        // Save this for an assertion in the future
        uint256 previousBalances = balances[msg.sender].add(balances[_to]);
        // Subtract from the sender
        balances[msg.sender] = balances[msg.sender].sub(_value);// Con libreria Maths
        // Add the same to the recipient
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balances[msg.sender] + balances[_to] == previousBalances);
    }

   /**
     @dev Adcd ..
     cd a new address to list of address
          Include `_add&#180; if doesn&#180;t exist within addList

     @param _add contains the address to be included in the addList.
     */
    function addAddress(address _add) private {
        addList.push(_add);
    }


}


/**
 @title ICO_Graphene
*/

contract ICO_Graphene is Claimable {

    using SafeMath for uint256;

    // Shows  number of tokens available for Private-ICO
    uint256 public availablePrivateICO;
    // Shows  number of tokens available for PRE-ICO
    uint256 public availablePreICO;
    // Shows  number of tokens available for ICO_w1
    uint256 public availableICO_w1;
    // Shows  number of tokens available for ICO_w2
    uint256 public availableICO_w2;

    // Shows  number of tokens totals available for ICO
    uint256 public availableICO;

    // Counts ETHs raised in the ICO
    uint256 public amountRaised;
    // Number of tokens sold within Private-ICO, PRE-ICO and ICO_w1 and ICO_w2
    uint256 public tokensSold;
    // Number of token decimals
    uint256 private decimals;

    // Shows PrivateICO starting timestamp
    uint256 public startPrivateICO = 1528329600; // 1528329600 Thursday, 07-Jun-18 00:00:00 UTC
    // Shows PrivateICO ending timestamp
    uint256 public endPrivateICO = 1532649599; // 1532649599 Thursday, 26-Jul-18 23:59:59 UTC

    // Shows Pre-ICO starting timestamp
    uint256 public startPreICO = 1532649600; // 1532649600 Friday, 27-Jul-18 00:00:00 UTC
    // Shows Pre-ICO ending timestamp
    uint256 public endPreICO = 1535327999; // 1535327999 Sunday, 26-Aug-18 23:59:59 UTC

    // Shows ICO starting timestamp
    uint256 public startICO_w1 = 1535328000; // 1535328000 Monday, 27-Aug-18 00:00:00 UTC
    // Shows ICO ending timestamp
    uint256 public endICO_w1 = 1538006399; // 1538006399 Thursday, 26-Sep-18 23:59:59 UTC

    // Shows ICO starting timestamp
    uint256 public startICO_w2 = 1538006400; // 1538006400 Friday, 27-Sep-18 00:00:00 UTC
    // Shows ICO ending timestamp
    uint256 public endICO_w2 = 1540684799; // 1540684799 Wednesday, 27-Oct-18 23:59:59 UTC

    // ICO status list
    enum StatusList { NotStarted, Running, Waiting, Closed, Paused}
    // ICO current status
    StatusList public status;
    // ICO stages list
    enum StagesList { N_A, PrivateICO, PreICO, ICO_w1, ICO_w2}
    // ICO current status
    StagesList public stage;
    // Contains token price within each stage
    uint256[5] private tokenPrice;
    // Contains token contract
    Token77G private tokenReward;

    // Some tokens cannot be sold before this date.
    // 6 moths after finish ico
    uint256 public restrictedTokensDate = 1550447999; // Sunday, 17-Feb-19 23:59:59 UTC

    // Contains token contract address
    address public tokenAdd;

    // Shows purchase address and amount
    mapping(address => uint256) public purchaseMap;
    // Contains ETHs that cannot be sent to an address.
    // mapping(address => uint256) public failToTranferList;

    // List of address

    // Token&#39;s delivery
    address constant private TOKENSRESERVE = 0xA89779a50b3540677495e12eA09f02B6Bf09803F;
    address constant private TEAM = 0x39E545F03d26334d735815Bb9882423cE46d8326;
    address constant private ADVISORS = 0x96DFaBbD575C48d82e5bCC92f64E0349Da60712a;

    // Eth&#39;s delivery
    address constant private SALARIES = 0x99330754059f1348296526a52AA4F787a7648B46;
    address constant private MARKETINGandBUSINESS = 0x824663D62c22f2592c5a3DC37638C09907adE7Ec;
    address constant private RESEARCHandDEVELOPMENT = 0x7156023Cd4579Eb6a7A171062A44574809B353C8;
    address constant private RESERVE = 0xAE55c485Fe70Ce6E547A30f5F4b28F32D9c1c093;
    address constant private FACTORIES = 0x30CF1d5F0c561118fA017f15B86f914ef5C078e6;
    address constant private PLANEQUIPMENT = 0xC74c83d8eC7c6233715b0aD8Ba4da8f72301fA24;
    address constant private PRODUCTION = 0xEa0553a23469cb7140190d443762d70664a36343;


    /**
     @dev This event notifies a tokens purchase
    **/
    event Purchase(address _from, uint _amount, uint _tokens);

    /**
     @dev Checks if ICO is active
     @param _status StatusList condition to compare with current status
    **/
    modifier onlyInState (StatusList _status) {
        require(_status == status);
        _;
    }

    /**
     @dev Checks if ICO status is not PAUSED
    **/
    modifier onlyIfNotPaused() {
        require(status != StatusList.Paused);
        _;
    }

     /**
     @dev Constructor. Creates ICO_Graphene tokens and define PrivateICO, PreICO, ICO tokens.
          ICO status and stages are set to initial values.
    */
    function ICO_Graphene() public {

        tokenReward = new Token77G(TEAM, TOKENSRESERVE, ADVISORS, restrictedTokensDate);

        tokenAdd = tokenReward;
        decimals = tokenReward.decimals();
        status = StatusList.NotStarted;
        stage = StagesList.N_A;
        amountRaised = 0;
        tokensSold = 0;

        availablePrivateICO = (1729000000) * 10 ** uint256(decimals);
        availablePreICO = (3325000000) * 10 ** uint256(decimals);
        availableICO_w1 = (5120500000) * 10 ** uint256(decimals);
        availableICO_w2 = (4655000000) * 10 ** uint256(decimals);

        tokenPrice = [0, 13860000000000, 14850000000000, 17820000000000, 19800000000000];

    }

     /**

     @dev The function (Fallback) without name is the default function that is called whenever
          anyone sends funds to a contract, this method starts purchase process.
     */
    function () public payable onlyIfNotPaused {
        updateStatus();
        if (stage == StagesList.PrivateICO) {
            require(msg.value >= 1000000000000000000 wei);
        }
        _transfer();
        updateStatusViaTokens();
    }

      /**
     @dev Standar function to kill ICO contract and return ETHs to owner.
    */
    function kill()
    external onlyOwner onlyInState(StatusList.Closed) {
        selfdestruct(owner);
    }

    /**
     @dev Public function to be call by owner that changes ICO status to Pause.
          No other function will be available if status is Pause but unpause()
     */
    function pause() public onlyOwner {
        updateStatus();
        require(status != StatusList.Closed);
        status = StatusList.Paused;
    }

    /**
     @dev Public function to be call by owner when ICO status is Paused, it changes ICO status to the right status
          based on ICO dates.
     */
    function unpause() public onlyOwner onlyInState(StatusList.Paused) {
        updateStatus();
        updateStatusViaTokens();
    }

    /**
     @dev PRE-ICO and ICO times can be changed with this function by the owner if ICO has not started.
    *     This function changes startTimestamp time with _startingTime given.
     @param     _startPrivateICO contains new starting date for PRE-ICO
     @param     _endPrivateICO contains new ending date for PRE-ICO
     @param     _startPreICO contains new starting date for ICO
     @param     _endPreICO contains new ending date for ICO
     @param     _startICO_w1 contains new starting date for PRE-ICO
     @param     _endICO_w1 contains new ending date for PRE-ICO
     @param     _startICO_w2 contains new starting date for ICO
     @param     _endICO_w2 contains new ending date for ICO
    */
    function setNewICOTime(
    uint _startPrivateICO,
    uint _endPrivateICO,
    uint _startPreICO,
    uint _endPreICO,
    uint _startICO_w1,
    uint _endICO_w1,
    uint _startICO_w2,
    uint _endICO_w2
    )
    public
    onlyOwner onlyInState(StatusList.NotStarted) {
        require(now < startPrivateICO && startPrivateICO < endPrivateICO && startPreICO < endPreICO && startICO_w1 < endICO_w1 && startICO_w2 < endICO_w2); // solhint-disable-line
        startPrivateICO = _startPrivateICO;
        endPrivateICO = _endPrivateICO;
        startPreICO = _startPreICO;
        endPreICO = _endPreICO;
        startICO_w1 = _startICO_w1;
        endICO_w1 = _endICO_w1;
        startICO_w2 = _startICO_w2;
        endICO_w2 = _endICO_w2;
    }

    /**
     @dev This function can be call by owner to close the ICO if status is closed .
    *     Transfer the excess tokens to RESERVE if there are available tokens
    */
     function closeICO() public onlyOwner {
        updateStatus();
        require(status == StatusList.Closed);
        transferExcessTokensToReserve();
    }

    function transferExcessTokensToReserve() internal {
      availableICO = tokenReward.balanceOf(this);
      if (availableICO > 0) {
        tokenReward.transfer(TOKENSRESERVE, availableICO);
      }
    }

    /**
     @dev Internal function to manage ICO status, as described in the withepaper
          ICO is available for purchases if date & time is within the PRE-ICO or ICO dates.
     */
    function updateStatus() internal {
        if (now >= endICO_w2) {// solhint-disable-line
            status = StatusList.Closed;
        } else {
            // solhint-disable-next-line
            if ((now > endPrivateICO && now < startPreICO) || (now > endPreICO && now < startICO_w1)) {
                status = StatusList.Waiting;
            } else {
                if (now < startPrivateICO) {// solhint-disable-line
                    status = StatusList.NotStarted;
                } else {
                    status = StatusList.Running;
                    updateStages();
                }
            }
        }
    }

    /**
     @dev Internal function to manage ICO status when tokens are sold out.
          ICO has a number of limmited tokens to be sold within PrivateICO, PRE-ICO and ICO stages,
          this method changes status to WaitingICO if PRE-ICO tokens are sold out or
          Closed when ICO tokens are sold out.
     */
    function updateStatusViaTokens() internal {
        availableICO = tokenReward.balanceOf(this);
        if (availablePrivateICO == 0 && stage == StagesList.PrivateICO) status = StatusList.Waiting;
        if (availablePreICO == 0 && stage == StagesList.PreICO) status = StatusList.Waiting;
        if (availableICO_w1 == 0 && stage == StagesList.ICO_w1) status = StatusList.Waiting;
        if (availableICO_w2 == 0 && stage == StagesList.ICO_w2) status = StatusList.Waiting;
        if (availableICO == 0) status = StatusList.Closed;
    }

    /**
     @dev Internal function to manage ICO stages.
          Stage is used in order to calculate the proper token price.
     */
    function updateStages() internal onlyInState(StatusList.Running) {
        if (now <= endPrivateICO && now > startPrivateICO) { stage = StagesList.PrivateICO; return;}// solhint-disable-line
        if (now <= endPreICO && now > startPreICO) { stage = StagesList.PreICO; return;}// solhint-disable-line
        if (now <= endICO_w1 && now > startICO_w1) { stage = StagesList.ICO_w1; return;}// solhint-disable-line
        if (now <= endICO_w2 && now > startICO_w2) { stage = StagesList.ICO_w2; return;}// solhint-disable-lin
        stage = StagesList.N_A;
    }

     /**
      @dev Private function to manage GrapheneTech purchases by calculating the right number
           of tokens based on the value sent.
           Includes any purchase within a mapping to track address and amount spent.
           Tracks the number of tokens sold. and ICO amount raised
           Transfer tokens to the buyer address.
           Calculates refound value if applais.
     */
    function _transfer() private onlyInState(StatusList.Running) {
        uint amount = msg.value;
        uint amountToReturn = 0;
        uint tokens = 0;
        (tokens, amountToReturn) = getTokens(amount);
        purchaseMap[msg.sender] = purchaseMap[msg.sender].add(amount);
        tokensSold = tokensSold.add(tokens);
        amount = amount.sub(amountToReturn);
        amountRaised = amountRaised.add(amount);
        if (stage == StagesList.PrivateICO) availablePrivateICO = availablePrivateICO.sub(tokens);
        if (stage == StagesList.PreICO) availablePreICO = availablePreICO.sub(tokens);
        if (stage == StagesList.ICO_w1) availableICO_w1 = availableICO_w1.sub(tokens);
        if (stage == StagesList.ICO_w2) availableICO_w2 = availableICO_w2.sub(tokens);
        tokenReward.transfer(msg.sender, tokens);
        sendETH(amount);

        if (amountToReturn > 0) {
            bool refound = msg.sender.send(amountToReturn);
            require(refound);
        }

        emit Purchase(msg.sender, amount, tokens);
    }

     /**
      @dev Returns the number of tokens based on the ETH sent and token price.

      @param _value this contais the ETHs sent and it is used to calculate the right number of tokens to be transfered.
      @return number of tokens based on the ETH sent and token price.
     */
    function getTokens(uint256 _value)
    private view
    onlyInState(StatusList.Running)
    returns(uint256 numTokens, uint256 amountToReturn) {

        uint256 eths = _value.mul(10**decimals);//Adding decimals to get an acurate number of tokens
        numTokens = 0;
        uint256 tokensAvailable = 0;
        numTokens = eths.div(tokenPrice[uint256(stage)]);

        if (stage == StagesList.PrivateICO) {
            tokensAvailable = availablePrivateICO;
        } else if (stage == StagesList.PreICO) {
            tokensAvailable = availablePreICO;
        } else if (stage == StagesList.ICO_w1) {
            tokensAvailable = availableICO_w1;
        } else if (stage == StagesList.ICO_w2) {
            tokensAvailable = availableICO_w2;
        }

        if (tokensAvailable >= numTokens) {
            amountToReturn = 0;
        } else {
            numTokens = tokensAvailable;
            amountToReturn = _value.sub(numTokens.div(10**decimals).mul(tokenPrice[uint256(stage)]));
        }

        return (numTokens, amountToReturn);
    }

    /**
     @dev This function sends ETHs to the list of address SALARIES, MARKETINGandBUSINESS, RESEARCHandDEVELOPMENT, RESERVE, FACTORIES, PLANEQUIPMENT, PRODUCTION
     @param _amount this are the ETHs that have to be send between different address.

    */
    function sendETH(uint _amount)  private {

        uint paymentSALARIES = _amount.mul(3).div(100);
        uint paymentMARKETINGandBUSINESS = _amount.mul(4).div(100);
        uint paymentRESEARCHandDEVELOPMENT = _amount.mul(14).div(100);
        uint paymentRESERVE = _amount.mul(18).div(100);
        uint paymentFACTORIES = _amount.mul(24).div(100);
        uint paymentPLANEQUIPMENT = _amount.mul(19).div(100);
        uint paymentPRODUCTION = _amount.mul(18).div(100);

        SALARIES.transfer(paymentSALARIES);
        MARKETINGandBUSINESS.transfer(paymentMARKETINGandBUSINESS);
        RESEARCHandDEVELOPMENT.transfer(paymentRESEARCHandDEVELOPMENT);
        RESERVE.transfer(paymentRESERVE);
        FACTORIES.transfer(paymentFACTORIES);
        PLANEQUIPMENT.transfer(paymentPLANEQUIPMENT);
        PRODUCTION.transfer(paymentPRODUCTION);

    }

}