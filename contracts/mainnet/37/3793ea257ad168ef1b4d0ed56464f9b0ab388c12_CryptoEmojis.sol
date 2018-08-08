pragma solidity ^0.4.21;

/**
 * @title CryptoEmojis
 * @author CryptoEmojis
 */
contract CryptoEmojis {
    // Using SafeMath
    using SafeMath for uint256;    

    // The developer&#39;s address
    address dev;

    // Contract information
    string constant private tokenName = "CryptoEmojis";
    string constant private tokenSymbol = "EMO";

    // Our beloved emojis
    struct Emoji {
        string codepoints;
        string name;
        uint256 price;
        address owner;
        bool exists;
    }

    Emoji[] emojis;
    
    // For storing the username and balance of every user
    mapping(address => uint256) private balances;
    mapping(address => bytes16) private usernames;

    // Needed events for represententing of every possible action
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _id, uint256 _price);
    event PriceChange(uint256 indexed _id, uint256 _price);
    event UsernameChange(address indexed _owner, bytes16 _username);


    function CryptoEmojis() public {
        dev = msg.sender;
    }
    
    
    modifier onlyDev() {
        require(msg.sender == dev);
        _;
    }

   function name() public pure returns(string) {
       return tokenName;
   }

   function symbol() public pure returns(string) {
       return tokenSymbol;
   }

    /** @dev Get the total supply */
    function totalSupply() public view returns(uint256) {
        return emojis.length;
    }

    /** @dev Get the balance of a user */
   function balanceOf(address _owner) public view returns(uint256 balance) {
       return balances[_owner];
   }

    /** @dev Get the username of a user */
    function usernameOf(address _owner) public view returns (bytes16) {
       return usernames[_owner];
    }
    
    /** @dev Set the username of sender user  */
    function setUsername(bytes16 _username) public {
        usernames[msg.sender] = _username;
        emit UsernameChange(msg.sender, _username);
    }

    /** @dev Get the owner of an emoji */
    function ownerOf(uint256 _id) public constant returns (address) {
       return emojis[_id].owner;
    }
    
    /** @dev Get the codepoints of an emoji */
    function codepointsOf(uint256 _id) public view returns (string) {
       return emojis[_id].codepoints;
    }

    /** @dev Get the name of an emoji */
    function nameOf(uint256 _id) public view returns (string) {
       return emojis[_id].name;
    }

    /** @dev Get the price of an emoji */
    function priceOf(uint256 _id) public view returns (uint256 price) {
       return emojis[_id].price;
    }

    /** @dev Ceate a new emoji for the first time */
    function create(string _codepoints, string _name, uint256 _price) public onlyDev() {
        Emoji memory _emoji = Emoji({
            codepoints: _codepoints,
            name: _name,
            price: _price,
            owner: dev,
            exists: true
        });
        emojis.push(_emoji);
        balances[dev]++;
    }

    /** @dev Edit emoji information to maintain confirming for Unicode standard, we can&#39;t change the price or the owner */
    function edit(uint256 _id, string _codepoints, string _name) public onlyDev() {
        require(emojis[_id].exists);
        emojis[_id].codepoints = _codepoints;
        emojis[_id].name = _name;
    }

    /** @dev Buy an emoji */
    function buy(uint256 _id) payable public {
        require(emojis[_id].exists && emojis[_id].owner != msg.sender && msg.value >= emojis[_id].price);
        address oldOwner = emojis[_id].owner;
        uint256 oldPrice = emojis[_id].price;
        emojis[_id].owner = msg.sender;
        emojis[_id].price = oldPrice.div(100).mul(115);
        balances[oldOwner]--;
        balances[msg.sender]++;
        oldOwner.transfer(oldPrice.div(100).mul(96));
        if (msg.value > oldPrice) msg.sender.transfer(msg.value.sub(oldPrice));
        emit Transfer(oldOwner, msg.sender, _id, oldPrice);
        emit PriceChange(_id, emojis[_id].price);
    }

    /** @dev Changing the price by the owner of the emoji */
    function setPrice(uint256 _id, uint256 _price) public {
        require(emojis[_id].exists && emojis[_id].owner == msg.sender);
        emojis[_id].price =_price;
        emit PriceChange(_id, _price);
    }

    /** @dev Withdraw all balance. This doesn&#39;t transfer users&#39; money since the contract pay them instantly and doesn&#39;t hold anyone&#39;s money */
    function withdraw() public onlyDev() {
        dev.transfer(address(this).balance);
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
}