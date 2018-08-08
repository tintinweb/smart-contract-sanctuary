pragma solidity 0.4.20;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
	uint256 public totalSupply;

    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract Token is Ownable {
    using SafeMath for uint;

    string public name = "Invox";
    string public symbol = "INVOX";
    uint8 public decimals = 18;
    uint256 public totalSupply = 0;

    address private owner;

    address internal constant FOUNDERS = 0x16368c58BDb7444C8b97cC91172315D99fB8dc81;
    address internal constant OPERATIONAL_FUND = 0xc97E0F6AcCB18e3B3703c85c205509d02700aCAa;

    uint256 private constant MAY_15_2018 = 1526342400;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    function Token () public {
        balances[msg.sender] = 0;
    }

    function balanceOf(address who) public constant returns (uint256) {
        return balances[who];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(balances[msg.sender] >= value);

        require(now >= MAY_15_2018 + 14 days);

        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);

        Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(from != address(0));
        require(to != address(0));
        require(balances[from] >= value && allowed[from][msg.sender] >= value && balances[to] + value >= balances[to]);

        balances[from] = balances[from].sub(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        balances[to] = balances[to].add(value);

        Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        require(spender != address(0));
        require(allowed[msg.sender][spender] == 0 || amount == 0);

        allowed[msg.sender][spender] = amount;
        Approval(msg.sender, spender, amount);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ICO is Token {
    using SafeMath for uint256;

    uint256 private constant MARCH_15_2018 = 1521072000;
    uint256 private constant MARCH_25_2018 = 1521936000;
    uint256 private constant APRIL_15_2018 = 1523750400;
    uint256 private constant APRIL_17_2018 = 1523923200;
    uint256 private constant APRIL_20_2018 = 1524182400;
    uint256 private constant APRIL_30_2018 = 1525046400;
    uint256 private constant MAY_15_2018 = 1526342400;

    uint256 private constant PRE_SALE_MIN = 1 ether;
    uint256 private constant MAIN_SALE_MIN = 10 ** 17 wei;

    uint256 private constant PRE_SALE_HARD_CAP = 2491 ether;
    uint256 private constant MAX_CAP = 20000 ether;
    uint256 private constant TOKEN_PRICE = 10 ** 14 wei;

    uint256 private constant TIER_1_MIN = 10 ether;
    uint256 private constant TIER_2_MIN = 50 ether;

    uint8 private constant FOUNDERS_ADVISORS_ALLOCATION = 20; //Percent
    uint8 private constant OPERATIONAL_FUND_ALLOCATION = 20; //Percent
    uint8 private constant AIR_DROP_ALLOCATION = 5; //Percent

    address private constant FOUNDERS_LOCKUP = 0x0000000000000000000000000000000000009999;
    address private constant OPERATIONAL_FUND_LOCKUP = 0x0000000000000000000000000000000000008888;

    address private constant WITHDRAW_ADDRESS = 0x8B7aa4103Ae75A7dDcac9d2E90aEaAe915f2C75E;
    address private constant AIR_DROP = 0x1100784Cb330ae0BcAFEd061fa95f8aE093d7769;

    mapping (address => bool) public whitelistAdmins;
    mapping (address => bool) public whitelist;
    mapping (address => address) public tier1;
    mapping (address => address) public tier2;

    uint32 public whitelistCount;
    uint32 public tier1Count;
    uint32 public tier2Count;

    uint256 public preICOwei = 0;
    uint256 public ICOwei = 0;

    function getCurrentBonus(address participant) public constant returns (uint256) {

        if (isInTier2(participant)) {
            return 60;
        }

        if (isInTier1(participant)) {
            return 40;
        }

        if (inPublicPreSalePeriod()) {
            return 30;
        }

        if (inAngelPeriod()) {
            return 20;
        }

        if (now >= APRIL_17_2018 && now < APRIL_20_2018) {
            return 10;
        }

        if (now >= APRIL_20_2018 && now < APRIL_30_2018) {
            return 5;
        }

        return 0;
    }

    function inPrivatePreSalePeriod() public constant returns (bool) {
        if (now >= MARCH_15_2018 && now < APRIL_15_2018) {
            return true;
        } else {
            return false;
        }
    }

    function inPublicPreSalePeriod() public constant returns (bool) {
        if (now >= MARCH_15_2018 && now < MARCH_25_2018) {
            return true;
        } else {
            return false;
        }
    }

    function inAngelPeriod() public constant returns (bool) {
        if (now >= APRIL_15_2018 && now < APRIL_17_2018) {
            return true;
        } else {
            return false;
        }
    }

    function inMainSalePeriod() public constant returns (bool) {
        if (now >= APRIL_17_2018 && now < MAY_15_2018) {
            return true;
        } else {
            return false;
        }
    }

    function addWhitelistAdmin(address newAdmin) public onlyOwner {
        whitelistAdmins[newAdmin] = true;
    }

    function isInWhitelist(address participant) public constant returns (bool) {
        require(participant != address(0));
        return whitelist[participant];
    }

    function addToWhitelist(address participant) public onlyWhiteLister {
        require(participant != address(0));
        require(!isInWhitelist(participant));
        whitelist[participant] = true;
        whitelistCount += 1;

        NewWhitelistParticipant(participant);
    }

    function addMultipleToWhitelist(address[] participants) public onlyWhiteLister {
        require(participants.length != 0);
        for (uint16 i = 0; i < participants.length; i++) {
            addToWhitelist(participants[i]);
        }
    }

    function isInTier1(address participant) public constant returns (bool) {
        require(participant != address(0));
        return !(tier1[participant] == address(0));
    }

    function addTier1Member(address participant) public onlyWhiteLister {
        require(participant != address(0));
        require(!isInTier1(participant)); // unless we require this, the count variable could get out of sync
        tier1[participant] = participant;
        tier1Count += 1;

        NewTier1Participant(participant);
    }

    function addMultipleTier1Members(address[] participants) public onlyWhiteLister {
        require(participants.length != 0);
        for (uint16 i = 0; i < participants.length; i++) {
            addTier1Member(participants[i]);
        }
    }

    function isInTier2(address participant) public constant returns (bool) {
        require(participant != address(0));
        return !(tier2[participant] == address(0));
    }

    function addTier2Member(address participant) public onlyWhiteLister {
        require(participant != address(0));
        require(!isInTier2(participant)); // unless we require this, the count variable could get out of sync
        tier2[participant] = participant;
        tier2Count += 1;

        NewTier2Participant(participant);
    }

    function addMultipleTier2Members(address[] participants) public onlyWhiteLister {
        require(participants.length != 0);
        for (uint16 i = 0; i < participants.length; i++) {
            addTier2Member(participants[i]);
        }
    }

    function buyTokens() public payable {

        require(msg.sender != address(0));
        require(isInTier1(msg.sender) || isInTier2(msg.sender) || isInWhitelist(msg.sender));
        
        require(inPrivatePreSalePeriod() || inPublicPreSalePeriod() || inAngelPeriod() || inMainSalePeriod());

        if (isInTier1(msg.sender)) {
            require(msg.value >= TIER_1_MIN);
        }

        if (isInTier2(msg.sender)) {
            require(msg.value >= TIER_2_MIN);
        }

        if (inPrivatePreSalePeriod() == true) {
            require(msg.value >= PRE_SALE_MIN);

            require(PRE_SALE_HARD_CAP >= preICOwei.add(msg.value));
            preICOwei = preICOwei.add(msg.value);
        }

        if (inMainSalePeriod() == true) {
            require(msg.value >= MAIN_SALE_MIN);

            require(MAX_CAP >= preICOwei + ICOwei.add(msg.value));
            ICOwei = ICOwei.add(msg.value);
        }

        uint256 deltaTokens = 0;

        uint256 tokens = msg.value.div(TOKEN_PRICE);
        uint256 bonusTokens = getCurrentBonus(msg.sender).mul(tokens.div(100));

        tokens = tokens.add(bonusTokens);
        balances[msg.sender] = balances[msg.sender].add(tokens);

        deltaTokens = deltaTokens.add(tokens);

        balances[FOUNDERS] += tokens.mul(100).div(FOUNDERS_ADVISORS_ALLOCATION).div(2);
        balances[FOUNDERS_LOCKUP] += tokens.mul(100).div(FOUNDERS_ADVISORS_ALLOCATION).div(2);
        deltaTokens += tokens.mul(100).div(FOUNDERS_ADVISORS_ALLOCATION);

        balances[OPERATIONAL_FUND] += tokens.mul(100).div(OPERATIONAL_FUND_ALLOCATION).div(2);
        balances[OPERATIONAL_FUND_LOCKUP] += tokens.mul(100).div(OPERATIONAL_FUND_ALLOCATION).div(2);
        deltaTokens += tokens.mul(100).div(OPERATIONAL_FUND_ALLOCATION);

        balances[AIR_DROP] += tokens.mul(100).div(AIR_DROP_ALLOCATION);
        deltaTokens += tokens.mul(100).div(AIR_DROP_ALLOCATION);

        totalSupply = totalSupply.add(deltaTokens);

        TokenPurchase(msg.sender, msg.value, tokens);
    }

    function() public payable {
        buyTokens();
    }

    function withdrawPreICOEth() public {
        require(now > MARCH_25_2018);
        WITHDRAW_ADDRESS.transfer(preICOwei);
    }

    function withdrawICOEth() public {
        require(now > MAY_15_2018);
        WITHDRAW_ADDRESS.transfer(ICOwei);
    }

    function withdrawAll() public {
        require(now > MAY_15_2018);
        WITHDRAW_ADDRESS.transfer(this.balance);
    }

    function unlockTokens() public {
        require(now > (MAY_15_2018 + 180 days));
        balances[FOUNDERS] += balances[FOUNDERS_LOCKUP];
        balances[FOUNDERS_LOCKUP] = 0;
        balances[OPERATIONAL_FUND] += balances[OPERATIONAL_FUND_LOCKUP];
        balances[OPERATIONAL_FUND_LOCKUP] = 0;
    }

    event TokenPurchase(address indexed _purchaser, uint256 _value, uint256 _amount);

    event NewWhitelistParticipant(address indexed _participant);
    event NewTier1Participant(address indexed _participant);
    event NewTier2Participant(address indexed _participant);

    //
    modifier onlyWhiteLister() {
        require(whitelistAdmins[msg.sender]);
        _;
    }
}