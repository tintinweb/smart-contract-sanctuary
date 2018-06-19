pragma solidity ^0.4.21;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Autonomy is Ownable {
    address public congress;

    modifier onlyCongress() {
        require(msg.sender == congress);
        _;
    }

    /**
     * @dev initialize a Congress contract address for this token
     *
     * @param _congress address the congress contract address
     */
    function initialCongress(address _congress) onlyOwner public {
        require(_congress != address(0));
        congress = _congress;
    }

    /**
     * @dev set a Congress contract address for this token
     * must change this address by the last congress contract
     *
     * @param _congress address the congress contract address
     */
    function changeCongress(address _congress) onlyCongress public {
        require(_congress != address(0));
        congress = _congress;
    }
}

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
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

contract OwnerContract is Claimable {
    Claimable public ownedContract;
    address internal origOwner;

    /**
     * @dev bind a contract as its owner
     *
     * @param _contract the contract address that will be binded by this Owner Contract
     */
    function bindContract(address _contract) onlyOwner public returns (bool) {
        require(_contract != address(0));
        ownedContract = Claimable(_contract);
        origOwner = ownedContract.owner();

        // take ownership of the owned contract
        ownedContract.claimOwnership();

        return true;
    }

    /**
     * @dev change the owner of the contract from this contract address to the original one.
     *
     */
    function transferOwnershipBack() onlyOwner public {
        ownedContract.transferOwnership(origOwner);
        ownedContract = Claimable(address(0));
        origOwner = address(0);
    }

    /**
     * @dev change the owner of the contract from this contract address to another one.
     *
     * @param _nextOwner the contract address that will be next Owner of the original Contract
     */
    function changeOwnershipto(address _nextOwner)  onlyOwner public {
        ownedContract.transferOwnership(_nextOwner);
        ownedContract = Claimable(address(0));
        origOwner = address(0);
    }
}

contract MintDRCT is OwnerContract, Autonomy {
    using SafeMath for uint256;

    uint256 public TOTAL_SUPPLY_CAP = 1000000000E18;
    bool public capInitialized = false;

    address[] internal mainAccounts = [
        0xaD5CcBE3aaB42812aa05921F0513C509A4fb5b67, // tokensale
        0xBD37616a455f1054644c27CC9B348CE18D490D9b, // community
        0x4D9c90Cc719B9bd445cea9234F0d90BaA79ad629, // foundation
        0x21000ec96084D2203C978E38d781C84F497b0edE  // miscellaneous
    ];

    uint8[] internal mainPercentages = [30, 40, 15, 15];

    mapping (address => uint) internal accountCaps;

    modifier afterCapInit() {
        require(capInitialized);
        _;
    }

    /**
     * @dev set capacity limitation for every main accounts
     *
     */
    function initialCaps() onlyOwner public returns (bool) {
        for (uint i = 0; i < mainAccounts.length; i = i.add(1)) {
            accountCaps[mainAccounts[i]] = TOTAL_SUPPLY_CAP * mainPercentages[i] / 100;
        }

        capInitialized = true;

        return true;
    }

    /**
     * @dev Mint DRC Tokens from one specific wallet addresses
     *
     * @param _ind uint8 the main account index
     * @param _value uint256 the amounts of tokens to be minted
     */
    function mintUnderCap(uint _ind, uint256 _value) onlyOwner afterCapInit public returns (bool) {
        require(_ind < mainAccounts.length);
        address accountAddr = mainAccounts[_ind];
        uint256 accountBalance = MintableToken(ownedContract).balanceOf(accountAddr);
        require(_value <= accountCaps[accountAddr].sub(accountBalance));

        return MintableToken(ownedContract).mint(accountAddr, _value);
    }

    /**
     * @dev Mint DRC Tokens from serveral specific wallet addresses
     *
     * @param _values uint256 the amounts of tokens to be minted
     */
    function mintAll(uint256[] _values) onlyOwner afterCapInit public returns (bool) {
        require(_values.length == mainAccounts.length);

        bool res = true;
        for(uint i = 0; i < _values.length; i = i.add(1)) {
            res = mintUnderCap(i, _values[i]) && res;
        }

        return res;
    }

    /**
     * @dev Mint DRC Tokens from serveral specific wallet addresses upto cap limitation
     *
     */
    function mintUptoCap() onlyOwner afterCapInit public returns (bool) {
        bool res = true;
        for(uint i = 0; i < mainAccounts.length; i = i.add(1)) {
            require(MintableToken(ownedContract).balanceOf(mainAccounts[i]) == 0);
            res = MintableToken(ownedContract).mint(mainAccounts[i], accountCaps[mainAccounts[i]]) && res;
        }

        require(res);
        return MintableToken(ownedContract).finishMinting(); // when up to cap limit, then stop minting.
    }

    /**
     * @dev raise the supply capacity of one specific wallet addresses
     *
     * @param _ind uint the main account index
     * @param _value uint256 the amounts of tokens to be added to capacity limitation
     */
    function raiseCap(uint _ind, uint256 _value) onlyCongress afterCapInit public returns (bool) {
        require(_ind < mainAccounts.length);
        require(_value > 0);

        accountCaps[mainAccounts[_ind]] = accountCaps[mainAccounts[_ind]].add(_value);
        return true;
    }

    /**
     * @dev query the main account address of one type
     *
     * @param _ind the index of the main account
     */
    function getMainAccount(uint _ind) public view returns (address) {
        require(_ind < mainAccounts.length);
        return mainAccounts[_ind];
    }

    /**
     * @dev query the supply capacity of one type of main account
     *
     * @param _ind the index of the main account
     */
    function getAccountCap(uint _ind) public view returns (uint256) {
        require(_ind < mainAccounts.length);
        return accountCaps[mainAccounts[_ind]];
    }

    /**
     * @dev set one type of main account to another address
     *
     * @param _ind the main account index
     * @param _newAddr address the new main account address
     */
    function setMainAccount(uint _ind, address _newAddr) onlyOwner public returns (bool) {
        require(_ind < mainAccounts.length);
        require(_newAddr != address(0));

        mainAccounts[_ind] = _newAddr;
        return true;
    }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

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

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
    Transfer(_from, _to, _value);
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
    Approval(msg.sender, _spender, _value);
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
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
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

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}