pragma solidity ^0.4.23;

// File: contracts/TIIMTokenInterface.sol

interface TIIMTokenInterface {
    function transfer(address to, uint amount) external returns (bool);
    function transferBonus(address to, uint amount) external returns (bool);
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
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/BasicToken.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol

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
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
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
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint _addedValue
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
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
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

// File: contracts/TIIMToken.sol

contract TIIMToken is TIIMTokenInterface, StandardToken, Ownable {

    using SafeMath for uint;

    event Released(uint amount);
    event Burn(address indexed burner, uint value);

    mapping(address => uint) public bonusBalances;

    uint    public decimals = 18;
    string  public name = "TriipMiles";
    string  public symbol = "TIIM";
    uint    public totalSupply = 500 * 10 ** 6 * TIIM_UNIT;                // 500,000,000 TIIM

    uint    public constant TIIM_UNIT = 10 ** 18;
    uint    public constant tiimCrowdFundAllocation = 165 * 10 ** 6 * TIIM_UNIT;    // 33% = 165,000,000 TIIM
    uint    public constant tiimCommunityReserveAllocation = 125 * 10 ** 6 * TIIM_UNIT;    // 25% = 125,000,000 TIIM
    uint    public constant teamAllocation = 50 * 10 ** 6 * TIIM_UNIT;               // allocate for team : 10% = 50,000,000 TIIM

    uint    public constant HOLDING_PERIOD = 180 days;
    
    bool    public stopped = false;
    bool    public isReleasedToPublic = false;

    address public tiimPrivateSaleAddress = 0x0;
    address public tiimKyberGoAddress = 0xb1;
    address public tiimCommunityReserve = 0x0;

    address public bonusWallet = 0x3F3;
    uint    public totalAllocated = 0;
    uint    public totalAllocatedForPrivateSale = 0;

    uint    public startTime;
    uint    public endTime;

    // TIIM team allocation variables
    address public teamAddress = 0x0;
    
    uint    public totalTeamAllocated = 0;
    uint    public teamTranchesReleased = 0;
    uint    public maxTeamTranches = 12;                                    // release team tokens 12 tranches every 30 days period
    uint    public constant RELEASE_PERIOD = 30 days;

    constructor() public {
        balances[tiimCommunityReserve] = tiimCommunityReserveAllocation;
    }

    /*
        @dev Bonus vesting condition
    */
    modifier afterHolding() {
        require(endTime > 0);

        uint validTime = endTime + HOLDING_PERIOD;

        require(now > validTime);

        _;
    }

    /*
        @dev assign private sale contract and allocate distributed token
     */
    function setTiimPrivateSaleAddress(address _tiimPrivateSaleAddress) onlyOwner public {
        require(tiimPrivateSaleAddress == address(0));
        tiimPrivateSaleAddress = _tiimPrivateSaleAddress;
        balances[_tiimPrivateSaleAddress] = tiimCrowdFundAllocation;
    }

    /*
        @dev start public ICO function
        assign Kyber GO contract and allocate private sale&#39;s remaining balance
    */
    function startPublicIco(address _tiimKyberGoAddress) onlyOwner public {
        require(startTime == 0, "Start time must be not setup yet");
        startTime = now;
        setTiimKyberGoAddress(_tiimKyberGoAddress);
    }

    function setTiimKyberGoAddress(address _tiimKyberGoAddress) internal {
        tiimKyberGoAddress = _tiimKyberGoAddress;
        balances[_tiimKyberGoAddress] = balances[tiimPrivateSaleAddress];
        balances[tiimPrivateSaleAddress] = 0;
    }

    /*
        @dev end public ICO function
        burn Kyber GO&#39;s remaining balance
     */
    function endPublicIco() onlyOwner public {

        require(startTime > 0);
        require(endTime < startTime, "Start time must be setup already");
        require(endTime == 0, "End time must be not setup yet");
        
        endTime = now;
        isReleasedToPublic = true;
        // burn remaining distributed token
        burnRemaining(tiimKyberGoAddress);
    }

    function burnRemaining(address _kyberGo) internal {
        uint _value = balances[_kyberGo];
        if(_value > 0) {
            balances[_kyberGo] = 0;

            totalSupply = totalSupply.sub(_value);
            emit Burn(_kyberGo, _value);
            emit Transfer(_kyberGo, address(0), _value);
        }
    }

    function setTeamAddress(address _teamAddress) onlyOwner public {
        teamAddress = _teamAddress;
    }

    
    function transfer(address _to, uint _value) public returns (bool success) {
        if (isReleasedToPublic || msg.sender == tiimPrivateSaleAddress) {
            assert(super.transfer(_to, _value));
            return true;
        }

        if (msg.sender == tiimKyberGoAddress) {
            totalAllocated = totalAllocated.add(_value);
            assert(super.transfer(_to, _value));
            return true;
        }
        revert();
    }

    /*
        @dev transfer and allocate bonus for client
        only private sale contract allows to call this function
     */
    function transferBonus(address _to, uint _value) public returns (bool success) {
        require(msg.sender == tiimPrivateSaleAddress);
        bonusBalances[_to] = bonusBalances[_to].add(_value);
        // allocate bonus
        super.transfer(bonusWallet, _value);
        return true;
    }


    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        if (isReleasedToPublic || msg.sender == tiimPrivateSaleAddress || msg.sender == tiimKyberGoAddress) {
            assert(super.transferFrom(_from, _to, _value));
            return true;
        }
        revert();
    }

    function approve(address _spender, uint _value) public returns (bool success) {
        // if the allowance is not `0`, it can only be updated to `0` to prevent an allowance change immediately after withdrawal
        require(_value == 0 || allowed[msg.sender][_spender] == 0);

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allocateForPrivateSale(uint amount) public {
        require(msg.sender == tiimPrivateSaleAddress);

        totalAllocated = totalAllocated.add(amount);
        totalAllocatedForPrivateSale = totalAllocatedForPrivateSale.add(amount);
    }

    /*
        @dev Manual allows public transfer by owner
    */
    function allowTransfers() onlyOwner public {
        isReleasedToPublic = true;
    }

    function bonusBalanceOf(address _owner) public view returns (uint) {
        return bonusBalances[_owner];
    }

    /*
        @dev client can redeem bonus after holding period
    */
    function redeem() public afterHolding {

        uint redeemAmount = bonusBalances[msg.sender];
        require(redeemAmount > 0);
        uint bonusWalletBalance = balances[bonusWallet];
        require(bonusWalletBalance >= redeemAmount);
        // subtract from bonus wallet which was allocated
        balances[bonusWallet] = balances[bonusWallet].sub(redeemAmount);
        balances[msg.sender] = balances[msg.sender].add(redeemAmount);
        bonusBalances[msg.sender] = 0;
    }

    /**
        @dev Release TIIM Token to Team based on 12 tranches release every 30 days
        @return true if successful
    */
    function releaseTeamTokens() onlyOwner public returns (bool) {

        require(endTime > 0);
        require(teamAddress != 0x0);
        require(totalTeamAllocated < teamAllocation);
        require(teamTranchesReleased < maxTeamTranches);

        uint currentTranche = now.sub(endTime).div(RELEASE_PERIOD);

        if (teamTranchesReleased < maxTeamTranches && currentTranche > teamTranchesReleased) {

            uint amount = teamAllocation.div(maxTeamTranches);

            balances[teamAddress] = balances[teamAddress].add(amount);

            totalAllocated = totalAllocated.add(amount);
            totalTeamAllocated = totalTeamAllocated.add(amount);

            teamTranchesReleased++;

            emit Transfer(0x0, teamAddress, amount);
            emit Released(amount);
        }
        return true;
    }

    // ------------------------------------------------------------------------
    // Don&#39;t accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }

    /*
        Time changer => for testing purpose
     */

    function nextPeriod() onlyOwner public {
        endTime = endTime.add(RELEASE_PERIOD);
    }

    function endPublicIcoForTesing() onlyOwner public {
        endTime = now.sub(181 days);
    }
}