pragma solidity ^0.4.21;

// File: node_modules\zeppelin-solidity\contracts\ownership\Ownable.sol

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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: node_modules\zeppelin-solidity\contracts\ownership\HasNoEther.sol

/**
 * @title Contracts that should not own Ether
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="582a3d353b37186a">[email&#160;protected]</a>╧&#199;.com>
 * @dev This tries to block incoming ether to prevent accidental loss of Ether. Should Ether end up
 * in the contract, it will allow the owner to reclaim this ether.
 * @notice Ether can still be send to this contract by:
 * calling functions labeled `payable`
 * `selfdestruct(contract_address)`
 * mining directly to the contract address
*/
contract HasNoEther is Ownable {

  /**
  * @dev Constructor that rejects incoming Ether
  * @dev The `payable` flag is added so we can access `msg.value` without compiler warning. If we
  * leave out payable, then Solidity will allow inheriting contracts to implement a payable
  * constructor. By doing it this way we prevent a payable constructor from working. Alternatively
  * we could use assembly to access msg.value.
  */
  function HasNoEther() public payable {
    require(msg.value == 0);
  }

  /**
   * @dev Disallows direct send by settings a default function without the `payable` flag.
   */
  function() external {
  }

  /**
   * @dev Transfer all Ether held by the contract to the owner.
   */
  function reclaimEther() external onlyOwner {
    assert(owner.send(this.balance));
  }
}

// File: node_modules\zeppelin-solidity\contracts\math\SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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

// File: node_modules\zeppelin-solidity\contracts\token\ERC20\ERC20Basic.sol

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

// File: node_modules\zeppelin-solidity\contracts\token\ERC20\BasicToken.sol

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

// File: node_modules\zeppelin-solidity\contracts\token\ERC20\ERC20.sol

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

// File: node_modules\zeppelin-solidity\contracts\token\ERC20\StandardToken.sol

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

// File: contracts\token\GCToken.sol

contract GCToken is StandardToken, HasNoEther {

    string constant public name = "GlobeCas";
    string constant public symbol = "GCT";
    uint8 constant public decimals = 8;
    
    event Mint(address indexed to, uint256 amount);
    event Claim(address indexed from, uint256 amount);
    
    address constant public CROWDSALE_ACCOUNT    = 0x52e35C4FfFD6fcf550915C5eCafeE395860DDcD5;
    address constant public COMPANY_ACCOUNT      = 0x7862a8f56C450866B4859EF391A85c535Df18c87;
    address constant public PRIVATE_SALE_ACCOUNT = 0x66FA34A9c50873b344a24B662720B632ad8E1517;
    address constant public TEAM_ACCOUNT         = 0x492C8b81D22Ad46b19419Df3D88Fd77b6850A9E4;
    address constant public PROMOTION_ACCOUNT    = 0x067724fb3439B5c52267d1ddDb3047C037290756;

    // -------------------------------------------------- TOKENS  -----------------------------------------------------------------------------------------------------------------
    uint constant public CAPPED_SUPPLY       = 20000000000e8; // maximum of GCT token
    uint constant public TEAM_RESERVE        = 2000000000e8;  // total tokens team can claim - certain amount of GCT will mint for each claim stage
    uint constant public COMPANY_RESERVE     = 8000000000e8;  // total tokens company reserve for - lock for 6 months than can mint this amount of GCT
    uint constant public PRIVATE_SALE        = 900000000e8;   // total tokens for private sale
    uint constant public PROMOTION_PROGRAM   = 1000000000e8;  // total tokens for promotion program -  405,000,000 for referral and  595,000,000 for bounty
    uint constant public CROWDSALE_SUPPLY    = 8100000000e8;  // total tokens for crowdsale
    // ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   
   // is company already claimed reserve pool
    bool public companyClaimed;

    // company reseved release minutes
    uint constant public COMPANY_RESERVE_FOR = 182 days; // this equivalent to 6 months
    
    // team can start claiming tokens N days after ICO
    uint constant public TEAM_CAN_CLAIM_AFTER = 120 days;// this equivalent to 4 months

    // period between each claim from team
    uint constant public CLAIM_STAGE = 30 days;

    // the amount of token each stage team can claim
    uint[] public teamReserve = [8658000e8, 17316000e8, 25974000e8, 34632000e8, 43290000e8, 51948000e8, 60606000e8, 69264000e8, 77922000e8, 86580000e8, 95238000e8, 103896000e8, 112554000e8, 121212000e8, 129870000e8, 138528000e8, 147186000e8, 155844000e8, 164502000e8, 173160000e8, 181820000e8];
        
    // Store the ico finish time 
    uint public icoEndTime = 1540339199; // initial ico end date 23-Oct-2018(Subject to change)

    modifier canMint() {
        require(totalSupply_ < CAPPED_SUPPLY);
        _;
    }

    function GCToken() public {
        mint(PRIVATE_SALE_ACCOUNT, PRIVATE_SALE);
        mint(PROMOTION_ACCOUNT, PROMOTION_PROGRAM);
        mint(CROWDSALE_ACCOUNT, CROWDSALE_SUPPLY);
    }

    function claimCompanyReserve () external {
        require(!companyClaimed);
        require(msg.sender == COMPANY_ACCOUNT);        
        require(now >= icoEndTime.add(COMPANY_RESERVE_FOR));
        mint(COMPANY_ACCOUNT, COMPANY_RESERVE);
        companyClaimed = true;
    }

    function claimTeamToken() external {
        require(msg.sender == TEAM_ACCOUNT);
        require(now >= icoEndTime.add(TEAM_CAN_CLAIM_AFTER));
        require(teamReserve[20] > 0);

        // store time check for each claim stage
        uint claimableTime = icoEndTime.add(TEAM_CAN_CLAIM_AFTER);
        uint totalClaimable;

        for(uint i = 0; i < 21; i++){
            if(teamReserve[i] > 0){
                // each month can claim the next stage starts from TEAM_CAN_CLAIM_AFTER
                if(claimableTime.add(i.mul(CLAIM_STAGE)) < now){
                    totalClaimable = totalClaimable.add(teamReserve[i]);
                    teamReserve[i] = 0;
                }else{
                    break;
                }
            }
        }
        if(totalClaimable > 0){
            mint(TEAM_ACCOUNT, totalClaimable);
        }
    }
    
    
    /**
    * @dev Function to mint tokens referenced from https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/token/ERC20/CappedToken.sol
    * @param _to The address that will receive the minted tokens.
    * @param _amount The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
    function mint(address _to, uint256 _amount) canMint internal returns (bool) {
        require(totalSupply_.add(_amount) <= CAPPED_SUPPLY);
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint (_to, _amount);
        return true;
    }

    /**
     * @dev Update the end of ICO time.
     * @param _icoEndTime Expected ICO end time
     */
    function setIcoEndTime(uint _icoEndTime) public onlyOwner {
        require(_icoEndTime >= now);
        icoEndTime = _icoEndTime;
    }
}