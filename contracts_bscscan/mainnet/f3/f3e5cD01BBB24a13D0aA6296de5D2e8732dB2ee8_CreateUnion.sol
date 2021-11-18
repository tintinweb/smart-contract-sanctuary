/**
 *Submitted for verification at BscScan.com on 2021-11-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
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

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {// Equivalent to contains(set, value)
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
            set._indexes[lastvalue] = valueIndex;
            // Replace lastvalue's index to valueIndex

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

abstract contract Ownable is Context {
    address private _owner;
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private governments;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function addGovernment(address government) public onlyOwner {
        governments.add(government);
    }

    function deletedGovernment(address government) public onlyOwner {
        governments.remove(government);
    }

    function getGovernment(uint256 index) public view returns (address) {
        return governments.at(index);
    }

    function isGovernment(address account) public view returns (bool){
        return governments.contains(account);
    }

    function getGovernmentLength() public view returns (uint256) {
        return governments.length();
    }

    modifier onlyGovernment() {
        require(isGovernment(_msgSender()), "Ownable: caller is not the Government");
        _;
    }

    modifier onlyController(){
        require(_msgSender() == owner() || isGovernment(_msgSender()), "Ownable: caller is not the controller");
        _;
    }
}

interface IERC20 {
  
    function transfer(address recipient, uint256 amount) external returns (bool);

  
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}


struct MemberInfo{
    uint256 identity;//1 为盟主，2管理员，3成员
    uint256 []  permissions;
}

interface IUnionMember {
    function initialUniomMember(uint256 accountId,uint256 unionId) external;
    function getBelongUnion(uint256 accountId) external view returns (uint256);
    function transferUnion(uint256 fromAccountId,uint256 toAccountId, uint256 unionId) external;
    function getMemberIdentity(uint256 unionId,uint256 accountId) external view returns(uint256);
}

interface IERC721 {
  
    function balanceOf(address owner) external view returns (uint256 balance);
 
    function ownerOf(uint256 tokenId) external view returns (address owner);
    
    function existsUnion(uint256 unionId) external view returns (bool);
    
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}

interface IUnion{
    function createUnion(address to,string memory unionName, string memory avator, string memory declaration) external returns (uint256);
    function transferUnion(address from,address to, uint256 unionId) external;
    function updateUnionName(uint256 unionId,string memory unionName) external;
    function updateUnionAvator(uint256 unionId,string memory avator) external;
    function updateUnionDeclaration(uint256 unionId,string memory declaration) external;
}

contract CreateUnion is Ownable {
    address private accountAddress;
    address private unionAddress;
    address private unionMemberAddress;
    bool private isOpen = true;
    address private receiveAddress = 0x000000000000000000000000000000000000dEaD;
    Price private createUnionPrice;
    event UpdateUnionProfile(uint256 indexed unionId, uint256 indexed managerId,string  unionName,string  avator,string  declaration);
    
    constructor( address _accountAddress,address  _unionAddress,address  _unionMemberAddress){
        accountAddress = _accountAddress;
        unionAddress = _unionAddress;
        unionMemberAddress = _unionMemberAddress;
    }
    
    function createUnion(string memory unionName,string memory avator, string memory declaration) public {
        require(isOpen,"it is not open");
        require(IERC721(unionAddress).balanceOf(msg.sender) == 0,"you already has an union");
        require(IERC721(accountAddress).balanceOf(msg.sender) >0,"you haven't created an account yet");
        uint256 ownerAccountId = IERC721(accountAddress).tokenOfOwnerByIndex(msg.sender,0);
        require(getBelongUnion(ownerAccountId) == 0,"you has already join one union");
     
        IERC20(createUnionPrice.exchangeToken).transferFrom(msg.sender,receiveAddress,createUnionPrice.price);
        uint256 unionId = IUnion(unionAddress).createUnion(msg.sender,unionName,avator,declaration);
        IUnionMember(unionMemberAddress).initialUniomMember(ownerAccountId,unionId);
    }
    
    function transferUnion(uint256 toAccountId, uint256 unionId) public {
        require(isOpen,"it is not open");
        require(IERC721(unionAddress).balanceOf(msg.sender) > 0,"you already has not an union");
        require(IERC721(accountAddress).balanceOf(msg.sender) >0,"you haven't created an account yet");
        
        uint256 ownerAccountId = IERC721(accountAddress).tokenOfOwnerByIndex(msg.sender,0);
        uint256 ownerUnionId  = IERC721(unionAddress).tokenOfOwnerByIndex(msg.sender,0);
        require(ownerUnionId == unionId,"you is not this union leader");
        require(getBelongUnion(toAccountId) == unionId ,"the account is not in this union");
        
        address toAddress = IERC721(accountAddress).ownerOf(toAccountId);
        require(IERC721(unionAddress).balanceOf(toAddress) == 0,"the account already has an union");
        
        IUnion(unionAddress).transferUnion(msg.sender,toAddress,unionId);
        IUnionMember(unionMemberAddress).transferUnion(ownerAccountId,toAccountId, unionId);
    }
    
    function updateUnionProfile(uint256 unionId,string memory unionName,string memory avator,string memory declaration) public {
        require(isOpen,"it is not open");
        uint256 ownerAccountId = IERC721(accountAddress).tokenOfOwnerByIndex(msg.sender,0);
  
        uint256 identity = getMemberIdentity(unionId,ownerAccountId);
        require(identity > 0,"you is not in this union");
        require(identity != 3,"you do not have this permission");
    
        if(bytes(unionName).length > 0){
            IUnion(unionAddress).updateUnionName(unionId,unionName);
        }
        if(bytes(avator).length >0){
            IUnion(unionAddress).updateUnionAvator(unionId,avator);
        }
        if(bytes(declaration).length >0){
            IUnion(unionAddress).updateUnionDeclaration(unionId,declaration);
        }
        
        emit UpdateUnionProfile(unionId,ownerAccountId,unionName,avator,declaration);
    }
    
    function setReceiveAddress (address _receiveAddress) public onlyController {
        receiveAddress = _receiveAddress;
    } 
    
    function getReceiveAddress() public view returns (address) {
        return receiveAddress;
    }
    
    function setOpen(bool _isOpen) public onlyController {
        isOpen = _isOpen;
    }
    
    function getOpen() public view returns (bool) {
        return isOpen;
    }
    
    function setCreateUnionPrice(address _exchangeToken,uint256 _price) public onlyController {
        createUnionPrice = Price({
            exchangeToken:_exchangeToken,
            price : _price
        });
    }
    
    function getCreateUnionPrice() public view returns (Price memory) {
        return createUnionPrice;
    }
    
    function getBelongUnion(uint256 accountId) public view returns (uint256) {
        return IUnionMember(unionMemberAddress).getBelongUnion(accountId);
    }
    
    function getMemberIdentity(uint256 unionId,uint256 accountId) public view returns(uint256){
        return IUnionMember(unionMemberAddress).getMemberIdentity(unionId,accountId);
    }
    
    struct Price{
        address exchangeToken;
        uint256 price;
    }
    
}