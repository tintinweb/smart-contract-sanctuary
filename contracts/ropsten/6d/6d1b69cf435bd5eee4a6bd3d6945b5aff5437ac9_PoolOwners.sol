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
  constructor() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner, "Sender not authorised.");
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
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
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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
    @title ItMap, a solidity iterable map
    @dev Credit to: https://gist.github.com/ethers/7e6d443818cbc9ad2c38efa7c0f363d1
 */
library itmap {
    struct entry {
        // Equal to the index of the key of this item in keys, plus 1.
        uint keyIndex;
        uint value;
    }

    struct itmap {
        mapping(uint => entry) data;
        uint[] keys;
    }
    
    function insert(itmap storage self, uint key, uint value) internal returns (bool replaced) {
        entry storage e = self.data[key];
        e.value = value;
        if (e.keyIndex > 0) {
            return true;
        } else {
            e.keyIndex = ++self.keys.length;
            self.keys[e.keyIndex - 1] = key;
            return false;
        }
    }
    
    function remove(itmap storage self, uint key) internal returns (bool success) {
        entry storage e = self.data[key];

        if (e.keyIndex == 0) {
            return false;
        }

        if (e.keyIndex < self.keys.length) {
            // Move an existing element into the vacated key slot.
            self.data[self.keys[self.keys.length - 1]].keyIndex = e.keyIndex;
            self.keys[e.keyIndex - 1] = self.keys[self.keys.length - 1];
        }

        self.keys.length -= 1;
        delete self.data[key];
        return true;
    }
    
    function contains(itmap storage self, uint key) internal constant returns (bool exists) {
        return self.data[key].keyIndex > 0;
    }
    
    function size(itmap storage self) internal constant returns (uint) {
        return self.keys.length;
    }
    
    function get(itmap storage self, uint key) internal constant returns (uint) {
        return self.data[key].value;
    }
    
    function getKey(itmap storage self, uint idx) internal constant returns (uint) {
        return self.keys[idx];
    }
}

/**
    @title OwnersReceiver for transfer and calls
 */
contract OwnersReceiver {
    function onOwnershipTransfer(address _sender, uint _value, bytes _data) public;
}

/**
    @title PoolOwners, the crowdsale contract for LinkPool ownership
 */
contract PoolOwners is Ownable {

    using SafeMath for uint256;
    using itmap for itmap.itmap;

    itmap.itmap private ownerMap;

    mapping(address => mapping(address => uint256)) allowance;
    mapping(address => bool) public tokenWhitelist;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public distributionMinimum;
    
    uint256 public totalContributed   = 0;
    bool    public distributionActive = false;
    uint256 public precisionMinimum   = 0.04 ether;
    bool    public locked             = false;
    address public wallet;

    bool    private contributionStarted = false;
    uint256 private valuation           = 4000 ether;
    uint256 private hardCap             = 1000 ether;
    uint    private distribution        = 1;
    address private dToken              = address(0);

    event Contribution(address indexed sender, uint256 share, uint256 amount);
    event TokenDistributionActive(address indexed token, uint256 amount, uint256 amountOfOwners);
    event TokenWithdrawal(address indexed token, address indexed owner, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner, uint256 amount);
    event TokenDistributionComplete(address indexed token, uint amount, uint256 amountOfOwners);

    modifier onlyPoolOwner() {
        require(ownerMap.get(uint(msg.sender)) != 0, "You are not authorised to call this function");
        _;
    }

    /**
        @dev Constructor set set the wallet initally
        @param _wallet Address of the ETH wallet
     */
    constructor(address _wallet) public {
        require(_wallet != address(0), "The ETH wallet address needs to be set");
        wallet = _wallet;
    }

    /**
        @dev Fallback function, redirects to contribution
        @dev Transfers tokens to LP wallet address
     */
    function() public payable {
        require(contributionStarted, "Contribution is not active");
        require(whitelist[msg.sender], "You are not whitelisted");
        contribute(msg.sender, msg.value); 
        wallet.transfer(msg.value);
    }

    /**
        @dev Manually set a contribution, used by owners to increase owners amounts
        @param _sender The address of the sender to set the contribution for you
        @param _amount The amount that the owner has sent
     */
    function addContribution(address _sender, uint256 _amount) public onlyOwner() { contribute(_sender, _amount); }

    /**
        @dev Registers a new contribution, sets their share
        @param _sender The address of the wallet contributing
        @param _amount The amount that the owner has sent
     */
    function contribute(address _sender, uint256 _amount) private {
        require(is128Bit(_amount), "Contribution amount isn&#39;t 128bit or smaller");
        require(!locked, "Crowdsale period over, contribution is locked");
        require(!distributionActive, "Cannot contribute when distribution is active");
        require(_amount >= precisionMinimum, "Amount needs to be above the minimum contribution");
        require(hardCap >= _amount, "Your contribution is greater than the hard cap");
        require(_amount % precisionMinimum == 0, "Your amount isn&#39;t divisible by the minimum precision");
        require(hardCap >= totalContributed.add(_amount), "Your contribution would cause the total to exceed the hardcap");

        totalContributed = totalContributed.add(_amount);
        uint256 share = percent(_amount, valuation, 5);

        uint owner = ownerMap.get(uint(_sender));
        if (owner != 0) { // Existing owner
            share += owner >> 128;
            uint amount = (owner << 128 >> 128).add(_amount);
            require(ownerMap.insert(uint(_sender), share << 128 | amount), "Sender does not exist in the map");
        } else { // New owner
            require(!ownerMap.insert(uint(_sender), share << 128 | _amount), "Map replacement detected");
        }

        emit Contribution(_sender, share, _amount);
    }

    /**
        @dev Whitelist a wallet address
        @param _owner Wallet of the owner
     */
    function whitelistWallet(address _owner) external onlyOwner() {
        require(!locked, "Can&#39;t whitelist when the contract is locked");
        require(_owner != address(0), "Blackhole address");
        whitelist[_owner] = true;
    }

    /**
        @dev Start the distribution phase
     */
    function startContribution() external onlyOwner() {
        require(!contributionStarted, "Contribution has started");
        contributionStarted = true;
    }

    /**
        @dev Manually set a share directly, used to set the LinkPool members as owners
        @param _owner Wallet address of the owner
        @param _value The equivalent contribution value
     */
    function setOwnerShare(address _owner, uint256 _value) public onlyOwner() {
        require(!locked, "Can&#39;t manually set shares, it&#39;s locked");
        require(!distributionActive, "Cannot set owners share when distribution is active");
        require(is128Bit(_value), "Contribution value isn&#39;t 128bit or smaller");

        uint owner = ownerMap.get(uint(_owner));
        uint share;
        if (owner == 0) {
            share = percent(_value, valuation, 5);
            require(!ownerMap.insert(uint(_owner), share << 128 | _value), "Map replacement detected");
        } else {
            share = (owner >> 128).add(percent(_value, valuation, 5));
            uint value = (owner << 128 >> 128).add(_value);
            require(ownerMap.insert(uint(_owner), share << 128 | value), "Sender does not exist in the map");
        }
    }

    /**
        @dev Transfer part or all of your ownership to another address
        @param _receiver The address that you&#39;re sending to
        @param _amount The amount of ownership to send, for your balance refer to `ownerShareTokens`
     */
    function sendOwnership(address _receiver, uint256 _amount) public onlyPoolOwner() {
        _sendOwnership(msg.sender, _receiver, _amount);
    }

    /**
        @dev Transfer part or all of your ownership to another address and call the receiving contract
        @param _receiver The address that you&#39;re sending to
        @param _amount The amount of ownership to send, for your balance refer to `ownerShareTokens`
     */
    function sendOwnershipAndCall(address _receiver, uint256 _amount, bytes _data) public onlyPoolOwner() {
        _sendOwnership(msg.sender, _receiver, _amount);
        if (isContract(_receiver)) {
            contractFallback(_receiver, _amount, _data);
        }
    }

    /**
        @dev Transfer part or all of your ownership to another address on behalf of an owner
        @dev Same principle as approval in ERC20, to be used mostly by external contracts, eg DEX&#39;s
        @param _owner The address of the owner who&#39;s having tokens sent on behalf of
        @param _receiver The address that you&#39;re sending to
        @param _amount The amount of ownership to send, for your balance refer to `ownerShareTokens`
     */
    function sendOwnershipFrom(address _owner, address _receiver, uint256 _amount) public {
        require(allowance[_owner][msg.sender] >= _amount, "Sender is not approved to send ownership of that amount");
        allowance[_owner][msg.sender] = allowance[_owner][msg.sender].sub(_amount);
        if (allowance[_owner][msg.sender] == 0) {
            delete allowance[_owner][msg.sender];
        }
        _sendOwnership(_owner, _receiver, _amount);
    }

    function _sendOwnership(address _owner, address _receiver, uint256 _amount) private {
        uint o = ownerMap.get(uint(_owner));
        uint r = ownerMap.get(uint(_receiver));

        uint oTokens = o << 128 >> 128;
        uint rTokens = r << 128 >> 128;

        require(is128Bit(_amount), "Amount isn&#39;t 128bit or smaller");
        require(_owner != _receiver, "You can&#39;t send to yourself");
        require(_receiver != address(0), "Ownership cannot be blackholed");
        require(oTokens > 0, "You don&#39;t have any ownership");
        require(oTokens >= _amount, "The amount exceeds what you have");
        require(!distributionActive, "Distribution cannot be active when sending ownership");
        require(_amount % precisionMinimum == 0, "Your amount isn&#39;t divisible by the minimum precision amount");

        oTokens = oTokens.sub(_amount);

        if (oTokens == 0) {
            require(ownerMap.remove(uint(_owner)), "Address doesn&#39;t exist in the map");
        } else {
            uint oPercentage = percent(oTokens, valuation, 5);
            require(ownerMap.insert(uint(_owner), oPercentage << 128 | oTokens), "Sender does not exist in the map");
        }
        
        uint rTNew = rTokens.add(_amount);
        uint rPercentage = percent(rTNew, valuation, 5);
        if (rTokens == 0) {
            require(!ownerMap.insert(uint(_receiver), rPercentage << 128 | rTNew), "Map replacement detected");
        } else {
            require(ownerMap.insert(uint(_receiver), rPercentage << 128 | rTNew), "Sender does not exist in the map");
        }

        emit OwnershipTransferred(_owner, _receiver, _amount);
    }

    function contractFallback(address _receiver, uint256 _amount, bytes _data) private {
        OwnersReceiver receiver = OwnersReceiver(_receiver);
        receiver.onOwnershipTransfer(msg.sender, _amount, _data);
    }

    function isContract(address _addr) private view returns (bool hasCode) {
        uint length;
        assembly { length := extcodesize(_addr) }
        return length > 0;
    }

    /**
        @dev Increase the allowance of a sender
        @param _sender The address of the sender on behalf of the owner
        @param _amount The amount to increase approval by
     */
    function increaseAllowance(address _sender, uint256 _amount) public {
        uint o = ownerMap.get(uint(msg.sender));
        require(o << 128 >> 128 >= _amount, "The amount to increase allowance by is higher than your balance");
        allowance[msg.sender][_sender] = allowance[msg.sender][_sender].add(_amount);
    }

    /**
        @dev Decrease the allowance of a sender
        @param _sender The address of the sender on behalf of the owner
        @param _amount The amount to decrease approval by
     */
    function decreaseAllowance(address _sender, uint256 _amount) public {
        require(allowance[msg.sender][_sender] >= _amount, "The amount to decrease allowance by is higher than the current allowance");
        allowance[msg.sender][_sender] = allowance[msg.sender][_sender].sub(_amount);
        if (allowance[msg.sender][_sender] == 0) {
            delete allowance[msg.sender][_sender];
        }
    }

    /**
        @dev Lock the contribution/shares methods
     */
    function finishContribution() public onlyOwner() {
        require(!locked, "Shares already locked");
        locked = true;
    }

    /**
        @dev Start the distribution phase in the contract so owners can claim their tokens
        @param _token The token address to start the distribution of
     */
    function distributeTokens(address _token) public onlyPoolOwner() {
        require(tokenWhitelist[_token], "Token is not whitelisted to be distributed");
        require(!distributionActive, "Distribution is already active");
        distributionActive = true;

        uint256 currentBalance = ERC20(_token).balanceOf(this);
        if (!is128Bit(currentBalance)) {
            currentBalance = 1 << 128;
        }
        require(currentBalance > distributionMinimum[_token], "Amount in the contract isn&#39;t above the minimum distribution limit");

        distribution = currentBalance << 128;
        dToken = _token;

        emit TokenDistributionActive(_token, currentBalance, ownerMap.size());
    }

    /**
        @dev Batch claiming of tokens for owners
        @param _count The amount of owners to claim tokens for
     */
    function batchClaim(uint256 _count) public onlyPoolOwner() {
        uint claimed = distribution << 128 >> 128;
        uint to = _count.add(claimed);

        require(_count.add(claimed) <= ownerMap.size(), "To value is greater than the amount of owners");
        for (uint256 i = claimed; i < to; i++) {
            claimTokens(i);
        }

        claimed = claimed.add(_count);
        if (claimed == ownerMap.size()) {
            distributionActive = false;
            emit TokenDistributionComplete(dToken, distribution >> 128, ownerMap.size());
        } else {
            distribution = distribution >> 128 << 128 | claimed;
        }
    }

    /**
        @dev Claim the tokens for the next owner in the map
     */
    function claimTokens(uint _i) private {
        address owner = address(ownerMap.getKey(_i));
        uint o = ownerMap.get(uint(owner));

        require(o >> 128 > 0, "You need to have a share to claim tokens");
        require(distributionActive, "Distribution isn&#39;t active");

        uint256 tokenAmount = (distribution >> 128).mul(o >> 128).div(100000);
        require(ERC20(dToken).transfer(owner, tokenAmount), "ERC20 transfer failed");
    }

    /**
        @dev Whitelist a token so it can be distributed
        @dev Token whitelist is due to the potential of minting tokens and constantly lock this contract in distribution
     */
    function whitelistToken(address _token, uint256 _minimum) public onlyOwner() {
        require(!tokenWhitelist[_token], "Token is already whitelisted");
        tokenWhitelist[_token] = true;
        distributionMinimum[_token] = _minimum;
    }

    /**
        @dev Set the minimum amount to be of transfered in this contract to start distribution
        @param _minimum The minimum amount
     */
    function setDistributionMinimum(address _token, uint256 _minimum) public onlyOwner() {
        distributionMinimum[_token] = _minimum;
    }

    /**
        @dev Get the amount of unclaimed owners in a distribution cycle
     */
    function getClaimedOwners() public view returns (uint) {
        return distribution << 128 >> 128;
    }

    /**
        @dev Return an owners percentage
        @param _owner The address of the owner
     */
    function getOwnerPercentage(address _owner) public view returns (uint) {
        return ownerMap.get(uint(_owner)) >> 128;
    }

    /**
        @dev Return an owners share token amount
        @param _owner The address of the owner
     */
    function getOwnerTokens(address _owner) public view returns (uint) {
        return ownerMap.get(uint(_owner)) << 128 >> 128;
    }

    /**
        @dev Returns the current amount of active owners, ie share above 0
     */
    function getCurrentOwners() public view returns (uint) {
        return ownerMap.size();
    }

    /**
        @dev Returns owner address based on the key
        @param _i The index of the owner in the map
     */
    function getOwnerAddress(uint _i) public view returns (address) {
        require(_i < ownerMap.size(), "Index is greater than the map size");
        return address(ownerMap.getKey(_i));
    }

    /**
        @dev Returns the allowance amount for a sender address
        @param _owner The address of the owner
        @param _sender The address of the sender on an owners behalf
     */
    function getAllowance(address _owner, address _sender) public view returns (uint256) {
        return allowance[_owner][_sender];
    }

    /**
        @dev Credit to Rob Hitchens: https://stackoverflow.com/a/42739843
     */
    function percent(uint numerator, uint denominator, uint precision) private pure returns (uint quotient) {
        uint _numerator = numerator * 10 ** (precision+1);
        uint _quotient = ((_numerator / denominator) + 5) / 10;
        return ( _quotient);
    }

    /**
        @dev Strict type check for data packing
        @param _val The value for checking
     */
    function is128Bit(uint _val) private pure returns (bool) {
        return _val < 1 << 128;
    }
}