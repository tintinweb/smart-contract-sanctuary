pragma solidity ^0.4.19;


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
        standard = &#39;ERC20 0.1&#39;;
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
        standard = &#39;MintingERC20 0.1&#39;;
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



/*
    Tests:
    - check that created token has correct name, symbol, decimals, locked, maxSupply
    - check that setPrivateSale updates privateSale, and not affects crowdSaleEndTime
    - check that setCrowdSale updates crowdSale, and changes crowdSaleEndTime
    - check that trasnferFrom, approve, increaseApproval, decreaseApproval are forbidden to call before end of ICO
    - check that burn is not allowed to call before end of CrowdSale
    - check that increaseLockedBalance only increases investor locked amount
    - check that isTransferAllowed failed if transferFrozen
    - check that isTransferAllowed failed if user has not enough unlocked balance
    - check that isTransferAllowed failed if user has not enough unlocked balance, after transfering enough tokens balance
    - check that isTransferAllowed succeed if user has enough unlocked balance
    - check that isTransferAllowed succeed if user has enough unlocked balance, after transfering enough tokens balance
*/

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
        MintingERC20(0, maxSupply, &#39;GigBit&#39;, 18, &#39;GBTC&#39;, false, _locked)
    {
        standard = &#39;GBTC 0.1&#39;;

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
        bytes memory prefix = &#39;\x19Ethereum Signed Message:\n32&#39;;

        return ecrecover(keccak256(prefix, _hash), _v, _r, _s);
    }

    function buy(address _address, uint256 _value) internal returns (bool);

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


contract CrowdSale is SellableToken {
    uint256 public constant PRE_ICO_TIER_FIRST = 0;
    uint256 public constant PRE_ICO_TIER_LAST = 4;
    uint256 public constant ICO_TIER_FIRST = 5;
    uint256 public constant ICO_TIER_LAST = 8;

    SellableToken public privateSale;

    uint256 public price;

    Stats public preICOStats;
    mapping(address => uint256) public icoBalances;

    struct Stats {
        uint256 soldTokens;
        uint256 maxTokenSupply;
        uint256 collectedUSD;
        uint256 collectedEthers;
        bool burned;
    }

    function CrowdSale(
        address _token,
        address _etherHolder,
        uint256 _maxPreICOTokenSupply,
    //10000000000000000000000000-527309544043097299200271 + 177500000000000000000000000 = 186972690455956902700799729
        uint256 _maxICOTokenSupply, //62500000000000000000000000
        uint256 _price,
        uint256[2] _preIcoDuration, //1530432000  -1533081599
        uint256[2] _icoDuration, // 1533110400 - 1538351999
        uint256 _etherPriceInUSD
    ) public
    SellableToken(
        _token,
        _etherHolder,
            _preIcoDuration[0],
            _icoDuration[1],
        _maxPreICOTokenSupply.add(_maxICOTokenSupply),
        _etherPriceInUSD
    ) {
        softCap = 250000000000;
        hardCap = 3578912800000;
        price = _price;
        preICOStats.maxTokenSupply = _maxPreICOTokenSupply;
        //0.2480* 10^5
        //PreICO
        tiers.push(
            Tier(
                uint256(65),
                _preIcoDuration[0],
                _preIcoDuration[0].add(1 hours)
            )
        );
        tiers.push(
            Tier(
                uint256(60),
                _preIcoDuration[0].add(1 hours),
                _preIcoDuration[0].add(1 days)
            )
        );
        tiers.push(
            Tier(
                uint256(57),
                _preIcoDuration[0].add(1 days),
                _preIcoDuration[0].add(2 days)
            )
        );
        tiers.push(
            Tier(
                uint256(55),
                _preIcoDuration[0].add(2 days),
                _preIcoDuration[0].add(3 days)
            )
        );
        tiers.push(
            Tier(
                uint256(50),
                _preIcoDuration[0].add(3 days),
                _preIcoDuration[1]
            )
        );
        //ICO
        tiers.push(
            Tier(
                uint256(25),
                _icoDuration[0],
                _icoDuration[0].add(1 weeks)
            )
        );
        tiers.push(
            Tier(
                uint256(15),
                _icoDuration[0].add(1 weeks),
                _icoDuration[0].add(2 weeks)
            )
        );
        tiers.push(
            Tier(
                uint256(10),
                _icoDuration[0].add(2 weeks),
                _icoDuration[0].add(3 weeks)
            )
        );
        tiers.push(
            Tier(
                uint256(5),
                _icoDuration[0].add(3 weeks),
                _icoDuration[1]
            )
        );

    }

    function changeICODates(uint256 _tierId, uint256 _start, uint256 _end) public onlyOwner {
        require(_start != 0 && _start < _end && _tierId < tiers.length);
        Tier storage icoTier = tiers[_tierId];
        icoTier.startTime = _start;
        icoTier.endTime = _end;
        if (_tierId == PRE_ICO_TIER_FIRST) {
            startTime = _start;
        } else if (_tierId == ICO_TIER_LAST) {
            endTime = _end;
        }
    }

    function isActive() public view returns (bool) {
        if (hardCap == collectedUSD.add(preICOStats.collectedUSD)) {
            return false;
        }
        if (soldTokens == maxTokenSupply) {
            return false;
        }

        return withinPeriod();
    }

    function withinPeriod() public view returns (bool) {
        return getActiveTier() != tiers.length;
    }

    function setPrivateSale(address _privateSale) public onlyOwner {
        if (_privateSale != address(0)) {
            privateSale = SellableToken(_privateSale);
        }
    }

    function getActiveTier() public view returns (uint256) {
        for (uint256 i = 0; i < tiers.length; i++) {
            if (block.timestamp >= tiers[i].startTime && block.timestamp <= tiers[i].endTime) {
                return i;
            }
        }

        return uint256(tiers.length);
    }

    function calculateTokensAmount(uint256 _value) public view returns (uint256 tokenAmount, uint256 usdAmount) {
        if (_value == 0) {
            return (0, 0);
        }
        uint256 activeTier = getActiveTier();

        if (activeTier == tiers.length) {
            if (endTime < block.timestamp) {
                return (0, 0);
            }
            if (startTime > block.timestamp) {
                activeTier = PRE_ICO_TIER_FIRST;
            }
        }
        usdAmount = _value.mul(etherPriceInUSD);

        tokenAmount = usdAmount.div(price * (100 - tiers[activeTier].discount) / 100);

        usdAmount = usdAmount.div(uint256(10) ** 18);

        if (usdAmount < minPurchase) {
            return (0, 0);
        }
    }

    function calculateEthersAmount(uint256 _tokens) public view returns (uint256 ethers, uint256 usdAmount) {
        if (_tokens == 0) {
            return (0, 0);
        }

        uint256 activeTier = getActiveTier();

        if (activeTier == tiers.length) {
            if (endTime < block.timestamp) {
                return (0, 0);
            }
            if (startTime > block.timestamp) {
                activeTier = PRE_ICO_TIER_FIRST;
            }
        }

        usdAmount = _tokens.mul((price * (100 - tiers[activeTier].discount) / 100));
        ethers = usdAmount.div(etherPriceInUSD);

        if (ethers < getMinEthersInvestment()) {
            return (0, 0);
        }

        usdAmount = usdAmount.div(uint256(10) ** 18);
    }

    function getStats(uint256 _ethPerBtc) public view returns (
        uint256 sold,
        uint256 maxSupply,
        uint256 min,
        uint256 soft,
        uint256 hard,
        uint256 tokenPrice,
        uint256 tokensPerEth,
        uint256 tokensPerBtc,
        uint256[24] tiersData
    ) {
        sold = soldTokens;
        maxSupply = maxTokenSupply.sub(preICOStats.maxTokenSupply);
        min = minPurchase;
        soft = softCap;
        hard = hardCap;
        tokenPrice = price;
        uint256 usd;
        (tokensPerEth, usd) = calculateTokensAmount(1 ether);
        (tokensPerBtc, usd) = calculateTokensAmount(_ethPerBtc);
        uint256 j = 0;
        for (uint256 i = 0; i < tiers.length; i++) {
            tiersData[j++] = uint256(tiers[i].discount);
            tiersData[j++] = uint256(tiers[i].startTime);
            tiersData[j++] = uint256(tiers[i].endTime);
        }
    }

    function burnUnsoldTokens() public onlyOwner {
        if (block.timestamp >= endTime && maxTokenSupply > soldTokens) {
            token.burnUnsoldTokens(maxTokenSupply.sub(soldTokens));
            maxTokenSupply = soldTokens;
        }
    }

    function isTransferAllowed(address _from, uint256 _value) public view returns (bool status){
        if (collectedUSD.add(preICOStats.collectedUSD) < softCap) {
            if (token.balanceOf(_from) >= icoBalances[_from] && token.balanceOf(_from).sub(icoBalances[_from])> _value) {
                return true;
            }
            return false;
        }
        return true;
    }

    function isRefundPossible() public view returns (bool) {
        if (isActive() || block.timestamp < startTime || collectedUSD.add(preICOStats.collectedUSD) >= softCap) {
            return false;
        }
        return true;
    }

    function refund() public returns (bool) {
        if (!isRefundPossible() || etherBalances[msg.sender] == 0) {
            return false;
        }

        uint256 burnedAmount = token.burnInvestorTokens(msg.sender, icoBalances[msg.sender]);
        if (burnedAmount == 0) {
            return false;
        }
        uint256 etherBalance = etherBalances[msg.sender];
        etherBalances[msg.sender] = 0;

        msg.sender.transfer(etherBalance);

        Refund(msg.sender, etherBalance, burnedAmount);

        return true;
    }

    function updatePreICOMaxTokenSupply(uint256 _amount) public {
        if (msg.sender == address(privateSale)) {
            maxTokenSupply = maxTokenSupply.add(_amount);
            preICOStats.maxTokenSupply = preICOStats.maxTokenSupply.add(_amount);
        }
    }

    function moveUnsoldTokensToICO() public onlyOwner {
        uint256 unsoldTokens = preICOStats.maxTokenSupply - preICOStats.soldTokens;
        if (unsoldTokens > 0) {
            preICOStats.maxTokenSupply = preICOStats.soldTokens;
        }
    }

    function transferEthers() internal {
        if (collectedUSD.add(preICOStats.collectedUSD) >= softCap) {
            etherHolder.transfer(this.balance);
        }
    }

    function mintPreICO(
        address _address,
        uint256 _tokenAmount,
        uint256 _ethAmount,
        uint256 _usdAmount
    ) internal returns (uint256) {
        uint256 mintedAmount = token.mint(_address, _tokenAmount);

        require(mintedAmount == _tokenAmount);

        preICOStats.soldTokens = preICOStats.soldTokens.add(_tokenAmount);
        preICOStats.collectedEthers = preICOStats.collectedEthers.add(_ethAmount);
        preICOStats.collectedUSD = preICOStats.collectedUSD.add(_usdAmount);

        require(preICOStats.maxTokenSupply >= preICOStats.soldTokens);
        require(maxTokenSupply >= preICOStats.soldTokens);

        return _tokenAmount;
    }

    function buy(address _address, uint256 _value) internal returns (bool) {
        if (_value == 0 || _address == address(0)) {
            return false;
        }

        uint256 activeTier = getActiveTier();
        if (activeTier == tiers.length) {
            return false;
        }

        uint256 tokenAmount;
        uint256 usdAmount;
        uint256 mintedAmount;

        (tokenAmount, usdAmount) = calculateTokensAmount(_value);
        require(usdAmount > 0 && tokenAmount > 0);

        if (activeTier >= PRE_ICO_TIER_FIRST && activeTier <= PRE_ICO_TIER_LAST) {
            mintedAmount = mintPreICO(_address, tokenAmount, _value, usdAmount);
            etherHolder.transfer(this.balance);
        } else {
            mintedAmount = mintInternal(_address, tokenAmount);
            require(soldTokens <= maxTokenSupply.sub(preICOStats.maxTokenSupply));
            collectedUSD = collectedUSD.add(usdAmount);
            require(hardCap >= collectedUSD.add(preICOStats.collectedUSD) && usdAmount > 0 && mintedAmount > 0);

            collectedEthers = collectedEthers.add(_value);
            etherBalances[_address] = etherBalances[_address].add(_value);
            icoBalances[_address] = icoBalances[_address].add(tokenAmount);
            transferEthers();
        }

        Contribution(_address, _value, tokenAmount);

        return true;
    }
}