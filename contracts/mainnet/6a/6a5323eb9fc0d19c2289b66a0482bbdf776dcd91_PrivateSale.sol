pragma solidity 0.4.19;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
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


contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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


contract Multivest is Ownable {

    using SafeMath for uint256;

    /* public variables */
    mapping (address => bool) public allowedMultivests;

    /* events */
    event MultivestSet(address multivest);

    event MultivestUnset(address multivest);

    event Contribution(address holder, uint256 value, uint256 tokens);

    modifier onlyAllowedMultivests(address _addresss) {
        require(allowedMultivests[_addresss] == true);
        _;
    }

    /* constructor */
    function Multivest() public {}

    function setAllowedMultivest(address _address) public onlyOwner {
        allowedMultivests[_address] = true;
        MultivestSet(_address);
    }

    function unsetAllowedMultivest(address _address) public onlyOwner {
        allowedMultivests[_address] = false;
        MultivestUnset(_address);
    }

    function multivestBuy(address _address, uint256 _value) public onlyAllowedMultivests(msg.sender) {
        require(buy(_address, _value) == true);
    }

    function multivestBuy(
        address _address,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public payable onlyAllowedMultivests(verify(keccak256(msg.sender), _v, _r, _s)) {
        require(_address == msg.sender && buy(msg.sender, msg.value) == true);
    }

    function verify(bytes32 _hash, uint8 _v, bytes32 _r, bytes32 _s) internal pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";

        return ecrecover(keccak256(prefix, _hash), _v, _r, _s);
    }

    function buy(address _address, uint256 _value) internal returns (bool);

}


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


contract GigERC20 is StandardToken, Ownable {
    /* Public variables of the token */
    uint256 public creationBlock;

    uint8 public decimals;

    string public name;

    string public symbol;

    string public standard;

    bool public locked;

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function GigERC20(
        uint256 _totalSupply,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transferAllSupplyToOwner,
        bool _locked
    ) public {
        standard = "ERC20 0.1";
        locked = _locked;
        totalSupply_ = _totalSupply;

        if (_transferAllSupplyToOwner) {
            balances[msg.sender] = totalSupply_;
        } else {
            balances[this] = totalSupply_;
        }
        name = _tokenName;
        // Set the name for display purposes
        symbol = _tokenSymbol;
        // Set the symbol for display purposes
        decimals = _decimalUnits;
        // Amount of decimals for display purposes
        creationBlock = block.number;
    }

    function setLocked(bool _locked) public onlyOwner {
        locked = _locked;
    }

    /* public methods */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(locked == false);
        return super.transfer(_to, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        if (locked) {
            return false;
        }
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
        if (locked) {
            return false;
        }
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
        if (locked) {
            return false;
        }
        return super.decreaseApproval(_spender, _subtractedValue);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (locked) {
            return false;
        }

        return super.transferFrom(_from, _to, _value);
    }

}


/*
This contract manages the minters and the modifier to allow mint to happen only if called by minters
This contract contains basic minting functionality though
*/
contract MintingERC20 is GigERC20 {

    using SafeMath for uint256;

    //Variables
    mapping (address => bool) public minters;

    uint256 public maxSupply;

    //Modifiers
    modifier onlyMinters () {
        require(true == minters[msg.sender]);
        _;
    }

    function MintingERC20(
        uint256 _initialSupply,
        uint256 _maxSupply,
        string _tokenName,
        uint8 _decimals,
        string _symbol,
        bool _transferAllSupplyToOwner,
        bool _locked
    )
        public GigERC20(_initialSupply, _tokenName, _decimals, _symbol, _transferAllSupplyToOwner, _locked)
    {
        standard = "MintingERC20 0.1";
        minters[msg.sender] = true;
        maxSupply = _maxSupply;
    }

    function addMinter(address _newMinter) public onlyOwner {
        minters[_newMinter] = true;
    }

    function removeMinter(address _minter) public onlyOwner {
        minters[_minter] = false;
    }

    function mint(address _addr, uint256 _amount) public onlyMinters returns (uint256) {
        if (true == locked) {
            return uint256(0);
        }

        if (_amount == uint256(0)) {
            return uint256(0);
        }

        if (totalSupply_.add(_amount) > maxSupply) {
            return uint256(0);
        }

        totalSupply_ = totalSupply_.add(_amount);
        balances[_addr] = balances[_addr].add(_amount);
        Transfer(address(0), _addr, _amount);

        return _amount;
    }

}


contract GigToken is MintingERC20 {
    SellableToken public crowdSale; // Pre ICO & ICO
    SellableToken public privateSale;

    bool public transferFrozen = false;

    uint256 public crowdSaleEndTime;

    mapping(address => uint256) public lockedBalancesReleasedAfterOneYear;

    modifier onlyCrowdSale() {
        require(crowdSale != address(0) && msg.sender == address(crowdSale));

        _;
    }

    modifier onlySales() {
        require((privateSale != address(0) && msg.sender == address(privateSale)) ||
            (crowdSale != address(0) && msg.sender == address(crowdSale)));

        _;
    }

    event MaxSupplyBurned(uint256 burnedTokens);

    function GigToken(bool _locked) public
        MintingERC20(0, maxSupply, "GigBit", 18, "GBTC", false, _locked)
    {
        standard = "GBTC 0.1";

        maxSupply = uint256(1000000000).mul(uint256(10) ** decimals);
    }

    function setCrowdSale(address _crowdSale) public onlyOwner {
        require(_crowdSale != address(0));

        crowdSale = SellableToken(_crowdSale);

        crowdSaleEndTime = crowdSale.endTime();
    }

    function setPrivateSale(address _privateSale) public onlyOwner {
        require(_privateSale != address(0));

        privateSale = SellableToken(_privateSale);
    }

    function freezing(bool _transferFrozen) public onlyOwner {
        transferFrozen = _transferFrozen;
    }

    function isTransferAllowed(address _from, uint256 _value) public view returns (bool status) {
        uint256 senderBalance = balanceOf(_from);
        if (transferFrozen == true || senderBalance < _value) {
            return false;
        }

        uint256 lockedBalance = lockedBalancesReleasedAfterOneYear[_from];

        // check if holder tries to transfer more than locked tokens
    if (lockedBalance > 0 && senderBalance.sub(_value) < lockedBalance) {
            uint256 unlockTime = crowdSaleEndTime + 1 years;

            // fail if unlock time is not come
            if (crowdSaleEndTime == 0 || block.timestamp < unlockTime) {
                return false;
            }

            uint256 secsFromUnlock = block.timestamp.sub(unlockTime);

            // number of months over from unlock
            uint256 months = secsFromUnlock / 30 days;

            if (months > 12) {
                months = 12;
            }

            uint256 tokensPerMonth = lockedBalance / 12;

            uint256 unlockedBalance = tokensPerMonth.mul(months);

            uint256 actualLockedBalance = lockedBalance.sub(unlockedBalance);

            if (senderBalance.sub(_value) < actualLockedBalance) {
                return false;
            }
        }

        if (block.timestamp < crowdSaleEndTime &&
            crowdSale != address(0) &&
            crowdSale.isTransferAllowed(_from, _value) == false
        ) {
            return false;
        }


        return true;
    }

    function transfer(address _to, uint _value) public returns (bool) {
        require(isTransferAllowed(msg.sender, _value));

        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        // transferFrom & approve are disabled before end of ICO
        require((crowdSaleEndTime <= block.timestamp) && isTransferAllowed(_from, _value));

        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        // transferFrom & approve are disabled before end of ICO

        require(crowdSaleEndTime <= block.timestamp);

        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
        // transferFrom & approve are disabled before end of ICO

        require(crowdSaleEndTime <= block.timestamp);

        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
        // transferFrom & approve are disabled before end of ICO

        require(crowdSaleEndTime <= block.timestamp);

        return super.decreaseApproval(_spender, _subtractedValue);
    }

    function increaseLockedBalance(address _address, uint256 _tokens) public onlySales {
        lockedBalancesReleasedAfterOneYear[_address] =
            lockedBalancesReleasedAfterOneYear[_address].add(_tokens);
    }

    // burn tokens if soft cap is not reached
    function burnInvestorTokens(
        address _address,
        uint256 _amount
    ) public onlyCrowdSale returns (uint256) {
        require(block.timestamp > crowdSaleEndTime);

        require(_amount <= balances[_address]);

        balances[_address] = balances[_address].sub(_amount);

        totalSupply_ = totalSupply_.sub(_amount);

        Transfer(_address, address(0), _amount);

        return _amount;
    }

    // decrease max supply of tokens that are not sold
    function burnUnsoldTokens(uint256 _amount) public onlyCrowdSale {
        require(block.timestamp > crowdSaleEndTime);

        maxSupply = maxSupply.sub(_amount);

        MaxSupplyBurned(_amount);
    }
}

contract SellableToken is Multivest {
    uint256 public constant MONTH_IN_SEC = 2629743;
    GigToken public token;

    uint256 public minPurchase = 100 * 10 ** 5;
    uint256 public maxPurchase;

    uint256 public softCap;
    uint256 public hardCap;

    uint256 public startTime;
    uint256 public endTime;

    uint256 public maxTokenSupply;

    uint256 public soldTokens;

    uint256 public collectedEthers;

    address public etherHolder;

    uint256 public collectedUSD;

    uint256 public etherPriceInUSD;
    uint256 public priceUpdateAt;

    mapping(address => uint256) public etherBalances;

    Tier[] public tiers;

    struct Tier {
        uint256 discount;
        uint256 startTime;
        uint256 endTime;
    }

    event Refund(address _holder, uint256 _ethers, uint256 _tokens);
    event NewPriceTicker(string _price);

    function SellableToken(
        address _token,
        address _etherHolder,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _maxTokenSupply,
        uint256 _etherPriceInUSD
    )
    public Multivest()
    {
        require(_token != address(0) && _etherHolder != address(0));
        token = GigToken(_token);

        require(_startTime < _endTime);
        etherHolder = _etherHolder;
        require((_maxTokenSupply == uint256(0)) || (_maxTokenSupply <= token.maxSupply()));

        startTime = _startTime;
        endTime = _endTime;
        maxTokenSupply = _maxTokenSupply;
        etherPriceInUSD = _etherPriceInUSD;

        priceUpdateAt = block.timestamp;
    }

    function setTokenContract(address _token) public onlyOwner {
        require(_token != address(0));
        token = GigToken(_token);
    }

    function setEtherHolder(address _etherHolder) public onlyOwner {
        if (_etherHolder != address(0)) {
            etherHolder = _etherHolder;
        }
    }

    function setPurchaseLimits(uint256 _min, uint256 _max) public onlyOwner {
        if (_min < _max) {
            minPurchase = _min;
            maxPurchase = _max;
        }
    }

    function mint(address _address, uint256 _tokenAmount) public onlyOwner returns (uint256) {
        return mintInternal(_address, _tokenAmount);
    }

    function isActive() public view returns (bool);

    function isTransferAllowed(address _from, uint256 _value) public view returns (bool);

    function withinPeriod() public view returns (bool);

    function getMinEthersInvestment() public view returns (uint256) {
        return uint256(1 ether).mul(minPurchase).div(etherPriceInUSD);
    }

    function calculateTokensAmount(uint256 _value) public view returns (uint256 tokenAmount, uint256 usdAmount);

    function calculateEthersAmount(uint256 _tokens) public view returns (uint256 ethers, uint256 bonus);

    function updatePreICOMaxTokenSupply(uint256 _amount) public;

    // set ether price in USD with 5 digits after the decimal point
    //ex. 308.75000
    //for updating the price through  multivest
    function setEtherInUSD(string _price) public onlyAllowedMultivests(msg.sender) {
        bytes memory bytePrice = bytes(_price);
        uint256 dot = bytePrice.length.sub(uint256(6));

        // check if dot is in 6 position  from  the last
        require(0x2e == uint(bytePrice[dot]));

        uint256 newPrice = uint256(10 ** 23).div(parseInt(_price, 5));

        require(newPrice > 0);

        etherPriceInUSD = parseInt(_price, 5);

        priceUpdateAt = block.timestamp;

        NewPriceTicker(_price);
    }

    function mintInternal(address _address, uint256 _tokenAmount) internal returns (uint256) {
        uint256 mintedAmount = token.mint(_address, _tokenAmount);

        require(mintedAmount == _tokenAmount);

        soldTokens = soldTokens.add(_tokenAmount);
        if (maxTokenSupply > 0) {
            require(maxTokenSupply >= soldTokens);
        }

        return _tokenAmount;
    }

    function transferEthers() internal;

    function parseInt(string _a, uint _b) internal pure returns (uint) {
        bytes memory bresult = bytes(_a);
        uint res = 0;
        bool decimals = false;
        for (uint i = 0; i < bresult.length; i++) {
            if ((bresult[i] >= 48) && (bresult[i] <= 57)) {
                if (decimals) {
                    if (_b == 0) break;
                    else _b--;
                }
                res *= 10;
                res += uint(bresult[i]) - 48;
            } else if (bresult[i] == 46) decimals = true;
        }
        if (_b > 0) res *= 10 ** _b;
        return res;
    }
}


contract TokenAllocation is Ownable {
    using SafeERC20 for ERC20Basic;
    using SafeMath for uint256;

    address public ecosystemIncentive = 0xd339D9aeDFFa244E09874D65290c09d64b2356E0;
    address public marketingAndBounty = 0x26d6EF95A51BF0A2048Def4Fb7c548c3BDE37410;
    address public liquidityFund = 0x3D458b6f9024CDD9A2a7528c2E6451DD3b29e4cc;
    address public treasure = 0x00dEaFC5959Dd0E164bB00D06B08d972A276bf8E;
    address public amirShaikh = 0x31b17e7a2F86d878429C03f3916d17555C0d4884;
    address public sadiqHameed = 0x27B5cb71ff083Bd6a34764fBf82700b3669137f3;
    address public omairLatif = 0x92Db818bF10Bf3BfB73942bbB1f184274aA63833;

    uint256 public icoEndTime;

    address public vestingApplicature;
    address public vestingSimonCocking;
    address public vestingNathanChristian;
    address public vestingEdwinVanBerg;

    mapping(address => bool) public tokenInited;
    address[] public vestings;

    event VestingCreated(
        address _vesting,
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 _periods,
        bool _revocable
    );

    event VestingRevoked(address _vesting);

    function setICOEndTime(uint256 _icoEndTime) public onlyOwner {
        icoEndTime = _icoEndTime;
    }

    function initVesting() public onlyOwner() {
        require(vestingApplicature == address(0) &&
        vestingSimonCocking == address(0) &&
        vestingNathanChristian == address(0) &&
        vestingEdwinVanBerg == address(0) &&
        icoEndTime != 0
        );

        uint256 oneYearAfterIcoEnd = icoEndTime.add(1 years);

        vestingApplicature = createVesting(
            0x760864dcdC58FDA80dB6883ce442B6ce44921Cf9, oneYearAfterIcoEnd, 0, 1 years, 2, false
        );

        vestingSimonCocking = createVesting(
            0x7f438d78a51886B24752941ba98Cc00aBA217495, oneYearAfterIcoEnd, 0, 1 years, 2, true
        );

        vestingNathanChristian = createVesting(
            0xfD86B8B016de558Fe39B1697cBf525592A233B2c, oneYearAfterIcoEnd, 0, 1 years, 2, true
        );

        vestingEdwinVanBerg = createVesting(
            0x2451A73F35874028217bC833462CCd90c72dbE6D, oneYearAfterIcoEnd, 0, 1 years, 2, true
        );
    }

    function allocate(MintingERC20 token) public onlyOwner() {
        require(tokenInited[token] == false);

        tokenInited[token] = true;

        require(vestingApplicature != address(0));
        require(vestingSimonCocking != address(0));
        require(vestingNathanChristian != address(0));
        require(vestingEdwinVanBerg != address(0));

        uint256 tokenPrecision = uint256(10) ** uint256(token.decimals());

        // allocate funds
        token.mint(ecosystemIncentive, 200000000 * tokenPrecision);
        token.mint(marketingAndBounty, 50000000 * tokenPrecision);
        token.mint(liquidityFund, 50000000 * tokenPrecision);
        token.mint(treasure, 200000000 * tokenPrecision);

        // allocate funds to founders
        token.mint(amirShaikh, 73350000 * tokenPrecision);
        token.mint(sadiqHameed, 36675000 * tokenPrecision);
        token.mint(omairLatif, 36675000 * tokenPrecision);

        // allocate funds to advisors
        token.mint(vestingApplicature, 1500000 * tokenPrecision);
        token.mint(vestingSimonCocking, 750000 * tokenPrecision);
        token.mint(vestingNathanChristian, 750000 * tokenPrecision);
        token.mint(vestingEdwinVanBerg, 300000 * tokenPrecision);
    }

    function createVesting(
        address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, uint256 _periods, bool _revocable
    ) public onlyOwner() returns (PeriodicTokenVesting) {
        PeriodicTokenVesting vesting = new PeriodicTokenVesting(
            _beneficiary, _start, _cliff, _duration, _periods, _revocable
        );

        vestings.push(vesting);

        VestingCreated(vesting, _beneficiary, _start, _cliff, _duration, _periods, _revocable);

        return vesting;
    }

    function revokeVesting(PeriodicTokenVesting _vesting, MintingERC20 token) public onlyOwner() {
        _vesting.revoke(token);

        VestingRevoked(_vesting);
    }
}


library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}


contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);
  event Revoked();

  // beneficiary of tokens after they are released
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

  /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
   * of the balance will have vested.
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
   * @param _duration duration in seconds of the period in which the tokens will vest
   * @param _revocable whether the vesting is revocable or not
   */
  function TokenVesting(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable) public {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   * @param token ERC20 token which is being vested
   */
  function release(ERC20Basic token) public {
    uint256 unreleased = releasableAmount(token);

    require(unreleased > 0);

    released[token] = released[token].add(unreleased);

    token.safeTransfer(beneficiary, unreleased);

    Released(unreleased);
  }

  /**
   * @notice Allows the owner to revoke the vesting. Tokens already vested
   * remain in the contract, the rest are returned to the owner.
   * @param token ERC20 token which is being vested
   */
  function revoke(ERC20Basic token) public onlyOwner {
    require(revocable);
    require(!revoked[token]);

    uint256 balance = token.balanceOf(this);

    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);

    revoked[token] = true;

    token.safeTransfer(owner, refund);

    Revoked();
  }

  /**
   * @dev Calculates the amount that has already vested but hasn&#39;t been released yet.
   * @param token ERC20 token which is being vested
   */
  function releasableAmount(ERC20Basic token) public view returns (uint256) {
    return vestedAmount(token).sub(released[token]);
  }

  /**
   * @dev Calculates the amount that has already vested.
   * @param token ERC20 token which is being vested
   */
  function vestedAmount(ERC20Basic token) public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[token]);

    if (now < cliff) {
      return 0;
    } else if (now >= start.add(duration) || revoked[token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(now.sub(start)).div(duration);
    }
  }
}


contract PeriodicTokenVesting is TokenVesting {
    uint256 public periods;

    function PeriodicTokenVesting(
        address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, uint256 _periods, bool _revocable
    )
        public TokenVesting(_beneficiary, _start, _cliff, _duration, _revocable)
    {
        periods = _periods;
    }

    /**
    * @dev Calculates the amount that has already vested.
    * @param token ERC20 token which is being vested
    */
    function vestedAmount(ERC20Basic token) public view returns (uint256) {
        uint256 currentBalance = token.balanceOf(this);
        uint256 totalBalance = currentBalance.add(released[token]);

        if (now < cliff) {
            return 0;
        } else if (now >= start.add(duration * periods) || revoked[token]) {
            return totalBalance;
        } else {

            uint256 periodTokens = totalBalance.div(periods);

            uint256 periodsOver = now.sub(start).div(duration) + 1;

            if (periodsOver >= periods) {
                return totalBalance;
            }

            return periodTokens.mul(periodsOver);
        }
    }
}


contract PrivateSale is SellableToken {

    uint256 public price;
    uint256 public discount;
    SellableToken public crowdSale;

    function PrivateSale(
        address _token,
        address _etherHolder,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _maxTokenSupply, //14000000000000000000000000
        uint256 _etherPriceInUSD
    ) public SellableToken(
        _token,
        _etherHolder,
        _startTime,
        _endTime,
        _maxTokenSupply,
        _etherPriceInUSD
    ) {
        price = 24800;// $0.2480 * 10 ^ 5
        discount = 75;// $75%
    }

    function changeSalePeriod(uint256 _start, uint256 _end) public onlyOwner {
        if (_start != 0 && _start < _end) {
            startTime = _start;
            endTime = _end;
        }
    }

    function isActive() public view returns (bool) {
        if (soldTokens == maxTokenSupply) {
            return false;
        }

        return withinPeriod();
    }

    function withinPeriod() public view returns (bool) {
        return block.timestamp >= startTime && block.timestamp <= endTime;
    }

    function calculateTokensAmount(uint256 _value) public view returns (uint256 tokenAmount, uint256 usdAmount) {
        if (_value == 0) {
            return (0, 0);
        }

        usdAmount = _value.mul(etherPriceInUSD);

        tokenAmount = usdAmount.div(price * (100 - discount) / 100);

        usdAmount = usdAmount.div(uint256(10) ** 18);

        if (usdAmount < minPurchase) {
            return (0, 0);
        }
    }

    function calculateEthersAmount(uint256 _tokens) public view returns (uint256 ethers, uint256 usdAmount) {
        if (_tokens == 0) {
            return (0, 0);
        }

        usdAmount = _tokens.mul((price * (100 - discount) / 100));
        ethers = usdAmount.div(etherPriceInUSD);

        if (ethers < getMinEthersInvestment()) {
            return (0, 0);
        }

        usdAmount = usdAmount.div(uint256(10) ** 18);
    }

    function getStats(uint256 _ethPerBtc) public view returns (
        uint256 start,
        uint256 end,
        uint256 sold,
        uint256 maxSupply,
        uint256 min,
        uint256 tokensPerEth,
        uint256 tokensPerBtc
    ) {
        start = startTime;
        end = endTime;
        sold = soldTokens;
        maxSupply = maxTokenSupply;
        min = minPurchase;
        uint256 usd;
        (tokensPerEth, usd) = calculateTokensAmount(1 ether);
        (tokensPerBtc, usd) = calculateTokensAmount(_ethPerBtc);
    }

    function setCrowdSale(address _crowdSale) public onlyOwner {
        require(_crowdSale != address(0));

        crowdSale = SellableToken(_crowdSale);
    }

    function moveUnsoldTokens() public onlyOwner {
        require(address(crowdSale) != address(0) && now >= endTime && !isActive() && maxTokenSupply > soldTokens);

        crowdSale.updatePreICOMaxTokenSupply(maxTokenSupply.sub(soldTokens));
        maxTokenSupply = soldTokens;
    }

    function updatePreICOMaxTokenSupply(uint256) public {
        require(false);
    }

    function isTransferAllowed(address, uint256) public view returns (bool) {
        return false;
    }

    function buy(address _address, uint256 _value) internal returns (bool) {
        if (_value == 0 || _address == address(0)) {
            return false;
        }

        uint256 tokenAmount;
        uint256 usdAmount;

        (tokenAmount, usdAmount) = calculateTokensAmount(_value);

        uint256 mintedAmount = mintInternal(_address, tokenAmount);
        collectedUSD = collectedUSD.add(usdAmount);
        require(usdAmount > 0 && mintedAmount > 0);

        collectedEthers = collectedEthers.add(_value);
        etherBalances[_address] = etherBalances[_address].add(_value);

        token.increaseLockedBalance(_address, mintedAmount);

        transferEthers();

        Contribution(_address, _value, tokenAmount);
        return true;
    }

    function transferEthers() internal {
        etherHolder.transfer(this.balance);
    }
}