/**
 *Submitted for verification at Etherscan.io on 2020-12-29
*/

// SPDX-License-Identifier: MIT

/*
 APDPH KEY Token
*/

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
    require(msg.sender == owner, 'only owner can call');
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * @dev This simplifies the implementation of "user permissions".
 */
contract Whitelist is Ownable {
  mapping(address => bool) public whitelist;

  event WhitelistedAddressAdded(address addr);
  event WhitelistedAddressRemoved(address addr);

  /**
   * @dev Throws if called by any account that's not whitelisted.
   */
  modifier onlyWhitelisted() {
    require(whitelist[msg.sender], 'not whitelisted');
    _;
  }

  /**
   * @dev add an address to the whitelist
   * @param addr address
   * @return success true if the address was added to the whitelist, false if the address was already in the whitelist
   */
  function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
    if (!whitelist[addr]) {
      whitelist[addr] = true;
      emit WhitelistedAddressAdded(addr);
      success = true;
    }
  }

  /**
   * @dev add addresses to the whitelist
   * @param addrs addresses
   * @return success true if at least one address was added to the whitelist,
   * false if all addresses were already in the whitelist
   */
  function addAddressesToWhitelist(address[] memory addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (addAddressToWhitelist(addrs[i])) {
        success = true;
      }
    }
  }

  /**
   * @dev remove an address from the whitelist
   * @param addr address
   * @return success true if the address was removed from the whitelist,
   * false if the address wasn't in the whitelist in the first place
   */
  function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
    if (whitelist[addr]) {
      whitelist[addr] = false;
      emit WhitelistedAddressRemoved(addr);
      success = true;
    }
  }

  /**
   * @dev remove addresses from the whitelist
   * @param addrs addresses
   * @return success true if at least one address was removed from the whitelist,
   * false if all addresses weren't in the whitelist in the first place
   */
  function removeAddressesFromWhitelist(address[] memory addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (removeAddressFromWhitelist(addrs[i])) {
        success = true;
      }
    }
  }

}

/**
 * @dev A Whitelist contract that can be locked and unlocked. Provides a modifier
 * to check for locked state plus functions and events. The contract is never locked for
 * whitelisted addresses. The contracts starts off unlocked and can be locked and
 * then unlocked a single time. Once unlocked, the contract can never be locked back.
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract LockableWhitelisted is Whitelist {
  event Locked();
  event Unlocked();

  bool public locked = false;
  bool private unlockedOnce = false;

  /**
   * @dev Modifier to make a function callable only when the contract is not locked
   * or the caller is whitelisted.
   */
  modifier whenNotLocked(address _address) {
    require(!locked || whitelist[_address], 'not unlocked or whitelisted');
    _;
  }

  /**
   * @dev Returns true if the specified address is whitelisted.
   * @param _address The address to check for whitelisting status.
   */
  function isWhitelisted(address _address) public view returns (bool) {
    return whitelist[_address];
  }

  /**
   * @dev Called by the owner to lock.
   */
  function lock() onlyOwner public {
    require(!unlockedOnce);
    if (!locked) {
      locked = true;
      emit Locked();
    }
  }

  /**
   * @dev Called by the owner to unlock.
   */
  function unlock() onlyOwner public {
    if (locked) {
      locked = false;
      unlockedOnce = true;
      emit Unlocked();
    }
  }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
abstract contract ERC20Basic {
  function totalSupply() public virtual view returns (uint256);
  function balanceOf(address who) public virtual view returns (uint256);
  function transfer(address to, uint256 value) public virtual returns (bool);
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
  function totalSupply() public override view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return balance An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public override view returns (uint256 balance) {
    return balances[_owner];
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public override virtual returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

}

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
    // no need to require value <= totalSupply, since that would imply the
    // sender's balance is greater than the totalSupply, which *should* be an assertion failure

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(burner, _value);
    emit Transfer(burner, address(0), _value);
  }
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
abstract contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public virtual view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public virtual returns (bool);
  function approve(address spender, uint256 value) public virtual returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string memory _name, string memory _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
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
  function transferFrom(address _from, address _to, uint256 _value) public override virtual returns (bool) {
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
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public override virtual returns (bool) {
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
  function allowance(address _owner, address _spender) public override view returns (uint256) {
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
  function increaseApproval(address _spender, uint _addedValue) public virtual returns (bool) {
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
  function decreaseApproval(address _spender, uint _subtractedValue) public virtual returns (bool) {
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
 * @title Batch Mintable token
 * @dev Standard ERC20 Token, with mintable token creation arranged in batches
 */
contract BatchMintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  struct Batch {
      string pubKey;
      bool minted;
  }

  Batch[MAX_BATCHES] private batches;
  uint256 private mintedCount = 0;
  bool public mintingFinished = false;
  
  /* Max supply = SUPPLY_PER_BATCH * MAX_BATCHES */
  uint256 constant internal SUPPLY_PER_BATCH = 3000;
  uint256 constant internal MAX_BATCHES = 50;

 constructor(string[] memory pubKeys) public {
      require(pubKeys.length <= MAX_BATCHES, 'Too many batches specified');
      for(uint256 i=0; i < pubKeys.length; i++) {
          batches[i].pubKey = pubKeys[i];
          batches[i].minted = false;
      }
  }

  modifier canMint() {
    require(!mintingFinished, 'minting is finished');
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _batchIndex 0-based index in batches array for the current batch required to mint.
   * @param _priKey the private key which SHA256 corresponds to the public key associated to the specified batch.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(uint256 _batchIndex, string memory _priKey) onlyOwner canMint public returns (bool) {
    address _to = owner;
    Batch storage batch = batches[_batchIndex];
    require(!batch.minted, 'this batch is already minted');
    require(keccak256(abi.encodePacked(batch.pubKey)) == keccak256(abi.encodePacked(sha256(abi.encodePacked(_priKey)))), 'the private key does not match with public key');
    uint256 _amount = SUPPLY_PER_BATCH;
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    batch.minted = true;
    mintedCount += 1;
    if(mintedCount == batches.length) {
        finishMinting();
    }
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

/**
 * @title Main contract
 * @dev ERC20 Token with ownership transferability and airdrop
 */
contract KEYToken is BurnableToken, BatchMintableToken, DetailedERC20, LockableWhitelisted {

  uint256 constant internal DECIMALS = 0;
  
  string[] BATCH_PUBKEYS = [
        hex"c1e0c482e26c766321b605caa63ec13df1fb7a4ca5df6a1f72c30eeb9b08d05d",
        hex"80ed5b54272de359098e4ff77ce0478d121ef97519ff6e1c9be6040fa33cb4bd",
        hex"cc5f133fed0549fbb4e717ac231787e14dad350e0f0b4b0fd5158ccb280cf567",
        hex"85ff44f555cc3029e692cd1a6e729d550be0ced93c597d0961b01038fa26e4d4",
        hex"2357cf57ab951fe3e134f38415a3f61925064138cbf627ea0e07ca167b28073b",
        hex"cf2fe9dd1b260eb670fea7a86a324283558902a494dea65533131afd89794952",
        hex"9edef1f6a26b3b27cf1fdc151743af54e3fd57e14a3333c98eaa5a4450339e3e",
        hex"eeb96b9970ee067a1dae2e1d016a183c35c2f30d595130e7de1166a990fb41c7",
        hex"fc848a9d6c02dc7d1ebc300b35956d1accec3509b2151ebadf0a7c12c44c6716",
        hex"4f88a2e42ed0dcd5d770d82de16240cc253cd586fb8ddfc2650260a8c21b6e5c",
        hex"9ad3e3d08d700c8f5e992e4bdb73d2abe4c98353965ea397e57e6e007e883e8c",
        hex"4d365d1c4178e0b7ed896587ddb7b4cd2daa5cc3f60c6a5ef5a24217d4c7ad9d",
        hex"ab661b7b144a3e60c83ef89a9c3dd9174c42b19b6249759b8d841c134f6b6e29",
        hex"662649471d40d624b17f2d06ae0817aac772e7e86aa46eacef1af29989c037c9",
        hex"8cde9fd75fa4f653a3a7c8fe22b61f0aa6ba51f2bca1d5c9d65faf7b29059b27",
        hex"75af680489e2d4e0b6cfbb9f1994122f93f99aaf56347976b2b3048ab6c9e01d",
        hex"797a9465e8065075f6621863ee35738aa52cbce7f6f353db695125039c28e65c",
        hex"4bf75db70ff3ea7e85ebbd9fb401db61d1502a0b26cc426bca6d879ef042d21e",
        hex"35d80d2be6b9ebfab8359c6da01ccce322c4df8e230bd105e7e11e6cc6fa5ab1",
        hex"c17ce98aa13bf3cc42c523e5916c106bd6a21a5978bbaec108218080d90425ae",
        hex"8df7abd0ce3b318942c585a0a13379c5a1895c2fe1c2757fbb66fc0b8908ca62",
        hex"15b0cf9ae71282084a3cc05048162fc70f15928a830f4d0186f6ac4d8b4e509f",
        hex"73d21866581f5416037ba33bcd6a2c2cd077035a25b6f9d72d6a273a4d60656b",
        hex"59d2230f46e3708b7f00836bffc09b9d223ca89505567e546350d057f627fa7d",
        hex"1fbd7e81f7ccfb38f6558161bdeaacd865114b8d966e77546ee9bac1e217ef8f",
        hex"e061b03bc2181d9f95f0325bdcc4b51d5fd6433b8938f32b59cdf9aa2046439a",
        hex"a3ce9ffb333d9c86c046668042187f1f1035339e7f9784e89e8a06b25247389a",
        hex"d84aab1491d8e986df98a3423e63202b8bd7f010ff72d2429cfc851368ce8271",
        hex"c7d95a30ad9dcb6d84ba2c8ef11488d181b46f0102cf1ad15f183756df6eea09",
        hex"2c43b6ffefcf00684fc1df04f35eb62a857ca2f48b6bf428afd943cfad121fbb",
        hex"003be61803b7f23b69c082e231c346347879b3cd2c33b49f548ddb0649c5c2f7",
        hex"412cbdd4f60cf16b84e80ea68b90423544aff9d5321abfa62389ea615f882cf9",
        hex"949a220adbca7475a81f3807d25e8bc51a31ec5c4437062328515c58372d4664",
        hex"5d9b4e6753a3548f73e8510a3ad26522dc956f4dc1ef0575b98189afae5581d9",
        hex"957bf00ec8191c6f09b3d419746ad2c323c2b4f634fdb0dde1edaa43cc682bd8",
        hex"6127372d05a5f7700e18a0149795b8730e2d31d6a8eedc712cb87d673dc0f809",
        hex"a75dad07f9685534d60f36e3c9bfa4216a55b88876e8a73a9659f3ead8899977",
        hex"e6f593701489c496b9259cb953179738a1471e8c900f4fe89d83ee204202b6cf",
        hex"1c23c41c6ec0ac9fe660b9d339b0ce38bd4f924d7d6719ff1954046929c7d70d",
        hex"79688526e766e5c800046e103a6108fdd4851ff1e70c4f18b3e2dcd04dcd6472",
        hex"8e2aba52d97e270de9332622aba675ab9892d63bca18950dde6bce670349a703",
        hex"e2cd01ba0b0ab39f0ff9d62ef7e95eaf856af6be897829026a45f7a13b2509b3",
        hex"4de870bff6654d36604375a111dbbbdf354d9c01f4fa4f805d83b0a837f8aa64",
        hex"dce2d10bd7878b2a339257c1f1895634e70169ea8cd2e3801a73789131c45159",
        hex"3cc05d57c4b3232fed3b6a507bf32cacefa3ea7fab6f7db263ae8481ee5b0c2a",
        hex"1440ce47ea44a34914802c6185b86656a9e1db9ca5e389480924eadb1bc535fb",
        hex"e5a07bc2a037452dd4a2842f33742349eb3db6af6195307d297e2590a392a05c",
        hex"11dad0f9cb06510d83479820cd3f7144bfca8792279e8a5fa98ba20518e181e4",
        hex"bb05ef5e70625d218015c6198cda93076681e8b673d76f6431341b6fcfeaa1ce",
        hex"0ee9005fe1dccae74334d9afe619f4ee22ec5b1e7f302311a4a089d37a2e98bc"
    ];

  constructor () public
    BurnableToken()
    BatchMintableToken(BATCH_PUBKEYS)
    DetailedERC20('KEY Token', 'KEY', uint8(DECIMALS))
    LockableWhitelisted()
  {
    addAddressToWhitelist(owner);
    // lock(); /* init lock disabled */
  }

  function transfer(address _to, uint256 _value) public override(BasicToken, ERC20Basic) whenNotLocked(msg.sender) returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public override(ERC20, StandardToken) whenNotLocked(_from) returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public override(ERC20, StandardToken)  whenNotLocked(msg.sender) returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public override whenNotLocked(msg.sender) returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public override whenNotLocked(msg.sender) returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }

  function transferOwnership(address _newOwner) public override onlyOwner {
    if (owner != _newOwner) {
      addAddressToWhitelist(_newOwner);
      removeAddressFromWhitelist(owner);
    }
    super.transferOwnership(_newOwner);
  }

  /**
  * @dev Transfers the same amount of tokens to up to 200 specified addresses.
  * If the sender runs out of balance then the entire transaction fails.
  * @param _to The addresses to transfer to.
  * @param _value The amount to be transferred to each address.
  */
  function airdrop(address[] memory _to, uint256 _value) public whenNotLocked(msg.sender)
  {
    require(_to.length <= 200);
    require(balanceOf(msg.sender) >= _value.mul(_to.length));

    for (uint i = 0; i < _to.length; i++) {
      transfer(_to[i], _value);
    }
  }

  /**
  * @dev Transfers a variable amount of tokens to up to 200 specified addresses.
  * If the sender runs out of balance then the entire transaction fails.
  * For each address a value must be specified.
  * @param _to The addresses to transfer to.
  * @param _values The amounts to be transferred to the addresses.
  */
  function multiTransfer(address[] memory _to, uint256[] memory _values) public whenNotLocked(msg.sender)
  {
    require(_to.length <= 200);
    require(_to.length == _values.length);

    for (uint i = 0; i < _to.length; i++) {
      transfer(_to[i], _values[i]);
    }
  }

}