/**
 *Submitted for verification at Etherscan.io on 2021-03-13
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface ITWAPOracle {

  function uniV2CompPairAddressForLastEpochUpdateBlockTimstamp( address ) external returns ( uint32 );

  function priceTokenAddressForPricingTokenAddressForLastEpochUpdateBlockTimstamp( address tokenToPrice_, address tokenForPriceComparison_, uint epochPeriod_ ) external returns ( uint32 );

  function pricedTokenForPricingTokenForEpochPeriodForPrice( address, address, uint ) external returns ( uint );

  function pricedTokenForPricingTokenForEpochPeriodForLastEpochPrice( address, address, uint ) external returns ( uint );

  function updateTWAP( address uniV2CompatPairAddressToUpdate_, uint eopchPeriodToUpdate_ ) external returns ( bool );
}

library EnumerableSet {
  struct Set {
    bytes32[] _values;
    mapping (bytes32 => uint256) _indexes;
  }

  function _add(Set storage set, bytes32 value) private returns (bool) {
    if (!_contains(set, value)) {
      set._values.push(value);
      set._indexes[value] = set._values.length;
      return true;
    } else {
      return false;
    }
  }

  function _remove(Set storage set, bytes32 value) private returns (bool) {
    uint256 valueIndex = set._indexes[value];

    if (valueIndex != 0) { // Equivalent to contains(set, value)
      uint256 toDeleteIndex = valueIndex - 1;
      uint256 lastIndex = set._values.length - 1;
      bytes32 lastvalue = set._values[lastIndex];
      set._values[toDeleteIndex] = lastvalue;
      set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based
      set._values.pop();
      delete set._indexes[value];

      return true;
    } else {
      return false;
    }
  }

  function _contains(Set storage set, bytes32 value) private view returns (bool) {
    return set._indexes[value] != 0;
  }

  function _length(Set storage set) private view returns (uint256) {
    return set._values.length;
  }

  function _at(Set storage set, uint256 index) private view returns (bytes32) {
    require(set._values.length > index, "EnumerableSet: index out of bounds");
    return set._values[index];
  }

  function _getValues( Set storage set_ ) private view returns ( bytes32[] storage ) {
    return set_._values;
  }

  function _insert(Set storage set_, uint256 index_, bytes32 valueToInsert_ ) private returns ( bool ) {
    require(  set_._values.length > index_ );
    require( !_contains( set_, valueToInsert_ ), "Remove value you wish to insert if you wish to reorder array." );
    bytes32 existingValue_ = _at( set_, index_ );
    set_._values[index_] = valueToInsert_;
    return _add( set_, existingValue_);
  } 

  struct AddressSet {
    Set _inner;
  }

  function add(AddressSet storage set, address value) internal returns (bool) {
    return _add(set._inner, bytes32(uint256(value)));
  }

  function remove(AddressSet storage set, address value) internal returns (bool) {
    return _remove(set._inner, bytes32(uint256(value)));
  }

  function contains(AddressSet storage set, address value) internal view returns (bool) {
    return _contains(set._inner, bytes32(uint256(value)));
  }

  function length(AddressSet storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  function at(AddressSet storage set, uint256 index) internal view returns (address) {
    return address(uint256(_at(set._inner, index)));
  }

  function getValues( AddressSet storage set_ ) internal view returns ( address[] memory ) {

    address[] memory addressArray;

    for( uint256 iteration_ = 0; _length(set_._inner) >= iteration_; iteration_++ ){
      addressArray[iteration_] = at( set_, iteration_ );
    }

    return addressArray;
  }

  function insert(AddressSet storage set_, uint256 index_, address valueToInsert_ ) internal returns ( bool ) {
    return _insert( set_._inner, index_, bytes32(uint256(valueToInsert_)) );
  }
}

interface IOwnable {

  function owner() external view returns (address);

  function renounceOwnership() external;
  
  function transferOwnership( address newOwner_ ) external;
}

contract Ownable is IOwnable {
    
  address internal _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () {
    _owner = msg.sender;
    emit OwnershipTransferred( address(0), _owner );
  }

  function owner() public view override returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require( _owner == msg.sender, "Ownable: caller is not the owner" );
    _;
  }

  function renounceOwnership() public virtual override onlyOwner() {
    emit OwnershipTransferred( _owner, address(0) );
    _owner = address(0);
  }

  function transferOwnership( address newOwner_ ) public virtual override onlyOwner() {
    require( newOwner_ != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred( _owner, newOwner_ );
    _owner = newOwner_;
  }
}

interface IERC20 {

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }

}

abstract contract ERC20 is IERC20 {

  using SafeMath for uint256;

  bytes32 constant private ERC20TOKEN_ERC1820_INTERFACE_ID = keccak256( "ERC20Token" );
  mapping (address => uint256) internal _balances;
  mapping (address => mapping (address => uint256)) internal _allowances;
  uint256 internal _totalSupply;
  string internal _name;
  string internal _symbol;
  uint8 internal _decimals;

  constructor (string memory name_, string memory symbol_, uint8 decimals_) {
    _name = name_;
    _symbol = symbol_;
    _decimals = decimals_;
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function decimals() public view returns (uint8) {
    return _decimals;
  }

  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view virtual override returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

  function _transfer(address sender, address recipient, uint256 amount) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(sender, recipient, amount);

    _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

    function _mint(address account_, uint256 ammount_) internal virtual {
        require(account_ != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address( this ), account_, ammount_);
        _totalSupply = _totalSupply.add(ammount_);
        _balances[account_] = _balances[account_].add(ammount_);
        emit Transfer(address( this ), account_, ammount_);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

  function _beforeTokenTransfer( address from_, address to_, uint256 amount_ ) internal virtual { }
}

library Counters {
    using SafeMath for uint256;

    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

interface IERC2612Permit {
 
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);
}

abstract contract ERC20Permit is ERC20, IERC2612Permit {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    bytes32 public DOMAIN_SEPARATOR;

    constructor() {
        uint256 chainID;
        assembly {
            chainID := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name())),
                keccak256(bytes("1")), // Version
                chainID,
                address(this)
            )
        );
    }

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "Permit: expired deadline");

        bytes32 hashStruct =
            keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, _nonces[owner].current(), deadline));

        bytes32 _hash = keccak256(abi.encodePacked(uint16(0x1901), DOMAIN_SEPARATOR, hashStruct));

        address signer = ecrecover(_hash, v, r, s);
        require(signer != address(0) && signer == owner, "ZeroSwapPermit: Invalid signature");

        _nonces[owner].increment();
        _approve(owner, spender, amount);
    }

    function nonces(address owner) public view override returns (uint256) {
        return _nonces[owner].current();
    }
}

contract TWAPOracleUpdater is ERC20Permit, Ownable {

  using EnumerableSet for EnumerableSet.AddressSet;

  event TWAPOracleChanged( address indexed previousTWAPOracle, address indexed newTWAPOracle );
  event TWAPEpochChanged( uint previousTWAPEpochPeriod, uint newTWAPEpochPeriod );
  event TWAPSourceAdded( address indexed newTWAPSource );
  event TWAPSourceRemoved( address indexed removedTWAPSource );
    
  EnumerableSet.AddressSet private _dexPoolsTWAPSources;

  ITWAPOracle public twapOracle;

  uint public twapEpochPeriod;

  constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) ERC20(name_, symbol_, decimals_) {}

  function changeTWAPOracle( address newTWAPOracle_ ) external onlyOwner() {
    emit TWAPOracleChanged( address(twapOracle), newTWAPOracle_);
    twapOracle = ITWAPOracle( newTWAPOracle_ );
  }

  function changeTWAPEpochPeriod( uint newTWAPEpochPeriod_ ) external onlyOwner() {
    require( newTWAPEpochPeriod_ > 0, "TWAPOracleUpdater: TWAP Epoch period must be greater than 0." );
    emit TWAPEpochChanged( twapEpochPeriod, newTWAPEpochPeriod_ );
    twapEpochPeriod = newTWAPEpochPeriod_;
  }

  function addTWAPSource( address newTWAPSourceDexPool_ ) external onlyOwner() {
    require( _dexPoolsTWAPSources.add( newTWAPSourceDexPool_ ), "OlympusERC20TOken: TWAP Source already stored." );
    emit TWAPSourceAdded( newTWAPSourceDexPool_ );
  }

  function removeTWAPSource( address twapSourceToRemove_ ) external onlyOwner() {
    require( _dexPoolsTWAPSources.remove( twapSourceToRemove_ ), "OlympusERC20TOken: TWAP source not present." );
    emit TWAPSourceRemoved( twapSourceToRemove_ );
  }

  function _uodateTWAPOracle( address dexPoolToUpdateFrom_, uint twapEpochPeriodToUpdate_ ) internal {
    if ( _dexPoolsTWAPSources.contains( dexPoolToUpdateFrom_ )) {
      twapOracle.updateTWAP( dexPoolToUpdateFrom_, twapEpochPeriodToUpdate_ );
    }
  }

  function _beforeTokenTransfer( address from_, address to_, uint256 amount_ ) internal override virtual {
      if( _dexPoolsTWAPSources.contains( from_ ) ) {
        _uodateTWAPOracle( from_, twapEpochPeriod );
      } else {
        if ( _dexPoolsTWAPSources.contains( to_ ) ) {
          _uodateTWAPOracle( to_, twapEpochPeriod );
        }
      }
    }
}

contract Divine is TWAPOracleUpdater {
  constructor(
    string memory name_,
    string memory symbol_,
    uint8 decimals_
  ) TWAPOracleUpdater(name_, symbol_, decimals_) {
  }
}

contract OlympusERC20TOken is Divine {

  using SafeMath for uint256;

    constructor() Divine("Olympus", "OLY", 9) {
    }

    function mint(address account_, uint256 ammount_) external onlyOwner() {
        _mint(account_, ammount_);
    }

    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account_, uint256 amount_) public virtual {
        _burnFrom(account_, amount_);
    }

    function _burnFrom(address account_, uint256 amount_) public virtual {
        uint256 decreasedAllowance_ =
            allowance(account_, msg.sender).sub(
                amount_,
                "ERC20: burn amount exceeds allowance"
            );

        _approve(account_, msg.sender, decreasedAllowance_);
        _burn(account_, amount_);
    }
}