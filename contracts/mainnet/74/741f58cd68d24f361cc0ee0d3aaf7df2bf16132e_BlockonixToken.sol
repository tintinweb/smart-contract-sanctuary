pragma solidity ^0.4.24;

/*
*
*  Blockonix Tokens are governed by the Terms & Conditions separately notified to each existing token holder
*  of Bitindia, and available on https://blockonix.com and https://blockonix.com/tokenswap
*
*/


/**
 *  Standard Interface for ERC20 Contract
 */
contract IERC20 {
    function totalSupply() public constant returns (uint _totalSupply);
    function balanceOf(address _owner) public constant returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) constant public returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


/**
 * Checking overflows for various operations
 */
library SafeMathLib {

/**
* Issue: Change to internal pure
**/
  function minus(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

/**
* Issue: Change to internal pure
**/
  function plus(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

}

/**
 * @title Ownable
 * @notice The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

  address public owner;

  /**
   * @notice The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @notice Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @notice Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    owner = newOwner;
  }
    
}

contract HasAddresses {
    address founder1FirstLockup = 0xfC866793142059C79E924d537C26E5E68a3d0CB4;
    address founder1SecondLockup = 0xa5c5EdA285866a89fbe9434BF85BC7249Fa98D45;
    address founder1ThirdLockup = 0xBE2D892D27309EE50D53aa3460fB21A2762625d6;
    
    address founder2FirstLockup = 0x7aeFB5F308C60D6fD9f9D79D6BEb32e2BbEf8F3C;
    address founder2SecondLockup = 0x9d92785510fadcBA9D0372e96882441536d6876a;
    address founder2ThirdLockup = 0x0e0B9943Ea00393B596089631D520bF1489d4d2E;

    address founder3FirstLockup = 0x8E06EdC382Dd2Bf3F2C36f7e2261Af2c7Eb84835;
    address founder3SecondLockup = 0x6A5AebCd6fA054ff4D10c51bABce17F189A9998a;
    address founder3ThirdLockup = 0xe10E613Be00a6383Dde52152Bc33007E5669e861;

}


contract VestingPeriods{
    uint firstLockup = 1544486400; // Human time (GMT): Tuesday, 11 December 2018 00:00:00  
    uint secondLockup = 1560211200; // Human time (GMT): Tuesday, 11 June 2019 00:00:00
    uint thirdLockup = 1576022400; // Human time (GMT): Wednesday, 11 December 2019 00:00:00
}


contract Vestable {

    mapping(address => uint) vestedAddresses ;    // Addresses vested till date
    bool isVestingOver = false;
    event AddVestingAddress(address vestingAddress, uint maturityTimestamp);

    function addVestingAddress(address vestingAddress, uint maturityTimestamp) internal{
        vestedAddresses[vestingAddress] = maturityTimestamp;
        emit AddVestingAddress(vestingAddress, maturityTimestamp);
    }

    function checkVestingTimestamp(address testAddress) public view returns(uint){
        return vestedAddresses[testAddress];
    }

    function checkVestingCondition(address sender) internal view returns(bool) {
        uint vestingTimestamp = vestedAddresses[sender];
        if(vestingTimestamp > 0) {
            return (now > vestingTimestamp);
        }
        else {
            return true;
        }
    }

}

contract IsUpgradable{
    address oldTokenAddress = 0x420335D3DEeF2D5b87524Ff9D0fB441F71EA621f;
    uint upgradeDeadline = 1543536000;
    address oldTokenBurnAddress = 0x30E055F7C16B753dbF77B57f38782C11A9f1C653;
    IERC20 oldToken = IERC20(oldTokenAddress);


}

/**
 * @title BlockonixToken Token
 * @notice The ERC20 Token.
 */
contract BlockonixToken is IERC20, Ownable, Vestable, HasAddresses, VestingPeriods, IsUpgradable {
    
    using SafeMathLib for uint256;
    
    uint256 public constant totalTokenSupply = 1009208335 * 10**16;    // Total Supply:10,092,083.35

    uint256 public burntTokens;

    string public constant name = "Blockonix";    // Blockonix
    string public constant symbol = "BDT";  // BDT
    uint8 public constant decimals = 18;            

    mapping (address => uint256) public balances;
    mapping(address => mapping(address => uint256)) approved;
    
    event Upgraded(address _owner, uint256 amount); 
    constructor() public {
        
        uint256 lockedTokenPerAddress = 280335648611111000000000;   // Total Founder Tokens(LOCKED): 2,523,020.8375, divided equally in 9 chunks
        balances[founder1FirstLockup] = lockedTokenPerAddress;
        balances[founder2FirstLockup] = lockedTokenPerAddress;
        balances[founder3FirstLockup] = lockedTokenPerAddress;
        balances[founder1SecondLockup] = lockedTokenPerAddress;
        balances[founder2SecondLockup] = lockedTokenPerAddress;
        balances[founder3SecondLockup] = lockedTokenPerAddress;
        balances[founder1ThirdLockup] = lockedTokenPerAddress;
        balances[founder2ThirdLockup] = lockedTokenPerAddress;
        balances[founder3ThirdLockup] = lockedTokenPerAddress;

        emit Transfer(address(this), founder1FirstLockup, lockedTokenPerAddress);
        emit Transfer(address(this), founder2FirstLockup, lockedTokenPerAddress);
        emit Transfer(address(this), founder3FirstLockup, lockedTokenPerAddress);
        
        emit Transfer(address(this), founder1SecondLockup, lockedTokenPerAddress);
        emit Transfer(address(this), founder2SecondLockup, lockedTokenPerAddress);
        emit Transfer(address(this), founder3SecondLockup, lockedTokenPerAddress);

        emit Transfer(address(this), founder1ThirdLockup, lockedTokenPerAddress);
        emit Transfer(address(this), founder2ThirdLockup, lockedTokenPerAddress);
        emit Transfer(address(this), founder3ThirdLockup, lockedTokenPerAddress);


        addVestingAddress(founder1FirstLockup, firstLockup);
        addVestingAddress(founder2FirstLockup, firstLockup);
        addVestingAddress(founder3FirstLockup, firstLockup);

        addVestingAddress(founder1SecondLockup, secondLockup);
        addVestingAddress(founder2SecondLockup, secondLockup);
        addVestingAddress(founder3SecondLockup, secondLockup);

        addVestingAddress(founder1ThirdLockup, thirdLockup);
        addVestingAddress(founder2ThirdLockup, thirdLockup);
        addVestingAddress(founder3ThirdLockup, thirdLockup);

    }

    function burn(uint256 _value) public {
        require (balances[msg.sender] >= _value);                 // Check if the sender has enough
        balances[msg.sender] = balances[msg.sender].minus(_value);
        burntTokens += _value;
        emit BurnToken(msg.sender, _value);
    } 

    
    function totalSupply() view public returns (uint256 _totalSupply) {
        return totalTokenSupply - burntTokens;
    }
    
    function balanceOf(address _owner) view public returns (uint256 balance) {
        return balances[_owner];
    }
    
    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint256 _value) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balances[_from] >= _value);                 // Check if the sender has enough
        require (balances[_to] + _value > balances[_to]);   // Check for overflows
        balances[_from] = balances[_from].minus(_value);    // Subtract from the sender
        balances[_to] = balances[_to].plus(_value);         // Add the same to the recipient
        emit Transfer(_from, _to, _value);
    }

    /**
     * @notice Send `_value` tokens to `_to` from your account
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success){
        require(checkVestingCondition(msg.sender));
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    /**
     * @notice Send `_value` tokens to `_to` on behalf of `_from`
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(checkVestingCondition(_from));
        require (_value <= approved[_from][msg.sender]);     // Check allowance
        approved[_from][msg.sender] = approved[_from][msg.sender].minus(_value);
        _transfer(_from, _to, _value);
        return true;
    }
    
    /**
     * @notice Approve `_value` tokens for `_spender`
     * @param _spender The address of the sender
     * @param _value the amount to send
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(checkVestingCondition(_spender));
        if(balances[msg.sender] >= _value) {
            approved[msg.sender][_spender] = _value;
            emit Approval(msg.sender, _spender, _value);
            return true;
        }
        return false;
    }
        
    /**
     * @notice Check `_value` tokens allowed to `_spender` by `_owner`
     * @param _owner The address of the Owner
     * @param _spender The address of the Spender
     */
    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
        return approved[_owner][_spender];
    }
        
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    event BurnToken(address _owner, uint256 _value);
    
     /**
     * Upgrade function, requires the owner to first approve tokens equal to their old token balance to this address 
     *
     */
    function upgrade() external {
        require(now <=upgradeDeadline);
        uint256 balance = oldToken.balanceOf(msg.sender);
        require(balance>0);
        oldToken.transferFrom(msg.sender, oldTokenBurnAddress, balance);
        balances[msg.sender] += balance;
        emit Transfer(this, msg.sender, balance);
        emit Upgraded(msg.sender, balance);
    }

}