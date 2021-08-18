/**
 *Submitted for verification at BscScan.com on 2021-08-17
*/

// SPDX-License-Identifier: MIT
 
pragma solidity ^0.8.0;
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
 
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
 


contract ERC20 is Context, IERC20 {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

   
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
 
    function name() public view virtual returns (string memory) {
        return _name;
    }
 
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
 
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
 
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
 
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
 
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
 
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }
 
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
 
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }
 
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }
 
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
 
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }
 
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
 
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}
 

contract ENMT is ERC20 {
    
    // Defines how to read the TokenInfo ABI, as well as the capabilities of the token
    uint256 public TOKEN_TYPE = 1;
    
    struct TokenInfo {
        uint8 decimals;
        address creator;
    }
    
    TokenInfo public INFO;
    
    constructor(string memory _name, string memory _symbol, uint8 _decimals, address _creator, uint256 _totalSupply) ERC20(_name, _symbol) {
        _mint(msg.sender, _totalSupply);
        INFO = TokenInfo(_decimals, _creator);
    }
    
    function decimals() public view virtual override returns (uint8) {
        return INFO.decimals;
    }

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }
    
}
 

// contract MintFactory is Ownable {
//     using EnumerableSet for EnumerableSet.AddressSet;
    
//     EnumerableSet.AddressSet private tokens;
//     EnumerableSet.AddressSet private tokenGenerators;
    
//     mapping(address => address[]) private tokenOwners;
    
//     event tokenRegistered(address tokenAddress, address tokenOwner);
    
//     function adminAllowTokenGenerator (address _address, bool _allow) public onlyOwner {
//         if (_allow) {
//             tokenGenerators.add(_address);
//         } else {
//             tokenGenerators.remove(_address);
//         }
//     }
 
//     function registerToken (address _tokenOwner, address _tokenAddress) public {
//         require(tokenGenerators.contains(msg.sender), 'FORBIDDEN');
//         tokens.add(_tokenAddress);
//         tokenOwners[_tokenOwner].push(_tokenAddress);
//         emit tokenRegistered(_tokenAddress, _tokenOwner);
//     }
 
//      function getTokenByOwnerAtIndex(address _tokenOwner, uint256 _index) external view returns(address) {
//          return tokenOwners[_tokenOwner][_index];
//      }
  
//      function getTokensLengthByOwner(address _tokenOwner) external view returns(uint256) {
//          return tokenOwners[_tokenOwner].length;
//      }
   
//     function tokenGeneratorsLength() external view returns (uint256) {
//         return tokenGenerators.length();
//     }
   
//     function tokenGeneratorAtIndex(uint256 _index) external view returns (address) {
//         return tokenGenerators.at(_index);
//     }
 
//     function tokenGeneratorIsAllowed(address _tokenGenerator) external view returns (bool) {
//         return tokenGenerators.contains(_tokenGenerator);
//     }
  
//     function isENMT(address _tokenAddress) external view returns (bool) {
//         return tokens.contains(_tokenAddress);
//     }
  
//     function tokensLength() external view returns (uint256) {
//         return tokens.length();
//     }
 
//     function tokenAtIndex(uint256 _index) external view returns (address) {
//         return tokens.at(_index);
//     }
    
// }
 
 
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
 
    function owner() public view virtual returns (address) {
        return _owner;
    }
 
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
 
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
 
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface ITokenFees {
    function getFlatFee() view external returns(uint256);
    function setFlatFee(uint _tokenFee) external;

    function getTotalSupplyFee() view external returns(uint256);
    function setTotalSupplyFee(uint _tokenFee) external;
    
    function getTokenFeeAddress() view external returns(address);
    function setTokenFeeAddress(address payable _tokenFeeAddress) external;
}

contract TokenFees is Ownable{
    
    struct Settings {
        uint256 FLAT_FEE;
        uint256 TS_FEE; // totalSupply fee
        address payable TOKEN_FEE_ADDRESS;
    }
    
    Settings public SETTINGS;
    
    constructor() {
        SETTINGS.FLAT_FEE = 1e18;
        SETTINGS.TS_FEE = 2;
        SETTINGS.TOKEN_FEE_ADDRESS = payable(0xAA3d85aD9D128DFECb55424085754F6dFa643eb1);
    }
    
    function getFlatFee() view external returns(uint256) {
        return SETTINGS.FLAT_FEE;
    }
    
    function setFlatFee(uint _flatFee) external onlyOwner {
        SETTINGS.FLAT_FEE = _flatFee;
    }

    function getTotalSupplyFee() view external returns(uint256) {
        return SETTINGS.TS_FEE;
    }
    
    function setTotalSupplyFee(uint _tsFee) external onlyOwner {
        SETTINGS.TS_FEE = _tsFee;
    }
    
    function getTokenFeeAddress() view external returns(address) {
        return SETTINGS.TOKEN_FEE_ADDRESS;
    }
    
    function setTokenFeeAddress(address payable _tokenFeeAddress) external onlyOwner {
        SETTINGS.TOKEN_FEE_ADDRESS = _tokenFeeAddress;
    }
} 
 
library EnumerableSet {
   
    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }
 
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }
 
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
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
 
    struct Bytes32Set {
        Set _inner;
    }
 
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }
 
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }
 
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }
 
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
 
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }
 
    struct AddressSet {
        Set _inner;
    }
 
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }
 
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }
 
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }
 
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
 
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }
 
    struct UintSet {
        Set _inner;
    }
 
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }
 
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }
 
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }
 
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
 
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}