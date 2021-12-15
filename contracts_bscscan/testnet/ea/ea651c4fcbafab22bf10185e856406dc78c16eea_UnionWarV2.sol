/**
 *Submitted for verification at BscScan.com on 2021-12-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        mapping (bytes32 => uint256) _indexes;
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
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

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

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function existsUnion(uint256 unionId) external view returns (bool);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}


interface IUnionMember{
    function getMemberIdentity(uint256 unionId,uint256 accountId) external view returns(uint256);
    function getBelongUnion(uint256 accountId) external view returns (uint256);
}

interface IRewardsWallet {
    function transfer(address recipient, uint256 amount) external;
}

contract UnionWarV2 is Ownable {
    address private accountContract;
    address private unionMemberContract;
    address private unionContract;
    address private walletAddress;
    address private funAddress;
    uint256[] private difficulties;
    mapping(uint256 => MineInfo) mines;
    mapping(uint256 => uint256[]) difficultyMines;
    mapping(uint256 => mapping(uint256 =>uint256)) receivedAmount;
    mapping(uint256 => uint256) unionBalance;
    bool private memberClaimOpen = true;
    mapping(bytes32 => bool) hashList;
    mapping(uint256 =>uint256) unionOccupyMine;

    event RewardsAdded(uint256 indexed difficulty, uint256 indexed mineId, uint256 rewards);
    event Quitted(uint256 indexed unionId, uint256 operatorId, uint256 difficulty, uint256 mineId);
    event RewardsPaid(uint256 indexed unionId, uint256 operatorId, uint256 difficulty, uint256 mineId, uint256 rewards);
    event Occupied(uint256 indexed unionId, uint256 difficulty, uint256 mineId);
    event MemberClaim(address tokenAddress,address to,uint256 amount,uint256 timestamp,bytes32 hash);

    constructor(address _accountContract,address _unionMemberContract,address _unionContract,address _walletAddress,address _funAddress) {
        accountContract = _accountContract;
        unionMemberContract = _unionMemberContract;
        unionContract = _unionContract;
        walletAddress = _walletAddress;
        funAddress = _funAddress;
    }

    function occupy(uint256 unionId,uint256 difficulty,uint256 mineId) public onlyController {
       uint256 status = mines[mineId].mineStatus;
       if(status == 2){
            uint256 _unionId = mines[mineId].unionId;
            quitOccupy( _unionId, difficulty, mineId);
       }
    
       uint256 _mineId = unionOccupyMine[unionId];
       if(_mineId!=0){
         quitOccupy(unionId, getMineInfo(_mineId).difficulty, _mineId);
       }
       mines[mineId].unionId = unionId;
       mines[mineId].mineStatus = 2;
       mines[mineId].occupyTime = block.timestamp;
       unionOccupyMine[unionId] = mineId;

       emit Occupied(unionId, difficulty, mineId);
    }

    function claimReward(uint256 unionId,uint256 difficulty,uint256 mineId) public {
        require(mines[mineId].unionId == unionId,"Quit failed, union is not occupy mine");
        uint256 accountId = getAccountId(msg.sender);
        uint256 identity =  IUnionMember(unionMemberContract).getMemberIdentity(unionId, accountId);
        require(identity == 1 || identity == 2 || isGovernment(msg.sender), "Quit failed, account is not permission");
        uint256 amount = earned(mineId);
        if(amount>0){
            IRewardsWallet(walletAddress).transfer(address(this),amount);
            unionBalance[unionId] += amount;
            receivedAmount[mineId][unionId] += amount;
            emit RewardsPaid(unionId, accountId, difficulty, mineId, amount);
        }
      
    }

    function quitOccupy(uint256 unionId,uint256 difficulty,uint256 mineId) public {
        require(mines[mineId].unionId == unionId,"Quit failed, union is not occupy mine");
        uint256 accountId = getAccountId(msg.sender);
        uint256 identity =  IUnionMember(unionMemberContract).getMemberIdentity(unionId, accountId);
        require(identity == 1 || identity == 2 || isGovernment(msg.sender) , "Quit failed, account is not permission");
        claimReward(unionId, difficulty, mineId);
        mines[mineId].unionId = 0;
        mines[mineId].mineStatus = 1;
        mines[mineId].occupyTime = 0;
        delete unionOccupyMine[unionId];
        delete receivedAmount[mineId][unionId];

        emit Quitted(unionId, accountId, difficulty, mineId);
    }

    function memberClaim(address tokenAddress,address to,uint256 amount,uint256 timestamp,bytes32 hash,bytes32 r,bytes32 s,uint8 v) public {
        require(memberClaimOpen,"can not claim now");
        require(msg.sender == to,"to address is not owner");
        require(block.timestamp <= timestamp,"already expired");
        require(!hashList[hash],"the hash has used");
        address _funAddress = ecrecover(hash, v, r, s);
        require(funAddress == _funAddress,"data is wrong");

        
        string memory signDataStr = string(abi.encodePacked("Cybertron",string(abi.encodePacked("0x",addressToStr(tokenAddress))), string(abi.encodePacked("0x",addressToStr(to))),uint2str(amount),uint2str(timestamp),string(abi.encodePacked("0x",addressToStr(funAddress)))));
        
        bytes32 signData  =keccak256(abi.encodePacked(signDataStr));

        require(signData == hash,"data is wrong");

        if(amount >0){
            IERC20(tokenAddress).transfer(to,amount);
        }
        
        hashList[hash] = true;
        uint256 unionId =  IUnionMember(unionMemberContract).getBelongUnion( getAccountId(msg.sender));
        unionBalance[unionId] -= amount;
        emit MemberClaim(tokenAddress,to,amount,timestamp,hash);
    }

    function addressToStr(address account) private pure returns (string memory) {
       bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(account)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function containsHash(bytes32 hash) public view returns (bool) {
        return hashList[hash];
    }

    function char(bytes1 b) private pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function earned(uint256 mineId) public view returns(uint256) {
        MineInfo memory mineInfo = mines[mineId];
        if(mineInfo.mineStatus == 1){
            return 0;
        }
        uint256 periodTime = block.timestamp - getMineInfo(mineId).occupyTime;
        uint256 secondRewards = mineInfo.dailyRewards / 86400;
        uint256 amount = secondRewards*periodTime - receivedAmount[mineId][mineInfo.unionId];
        return amount;
    }

    function addDifficulty(uint256 [] memory difficultys) public onlyController {
        uint256 length = difficultys.length;
        for(uint256 i = 0;i<length ;i++){
            require(!isSupportedDifficulty(difficultys[i]), "Add failed, difficulty already exists");
            difficulties.push(difficultys[i]);
        }
    }

    function addMineInfo(MineData[] memory mineData) public onlyController {
        uint256 length = mineData.length;
        for(uint256 i=0;i<length;i++){
            require(isSupportedDifficulty(mineData[i].difficulty), "Add failed, unsupported difficulty");
            require(mines[mineData[i].mineId].mineId == 0,"Add failed, mine already exists");
            MineInfo memory mine = MineInfo ({
            mineId : mineData[i].mineId,
            difficulty : mineData[i].difficulty,
            mineStatus : 1,
            monsterIcon : mineData[i].monsterIcon,
            dailyRewards : mineData[i].dailyRewards,
            unionId : 0,
            occupyTime : 0
            });
            
            mines[mineData[i].mineId] = mine;
            difficultyMines[mineData[i].difficulty].push(mineData[i].mineId);
            emit RewardsAdded(mineData[i].difficulty, mineData[i].mineId, mineData[i].dailyRewards);
        }
    }

    function removeMine(uint256 mineId) public onlyController {
        MineInfo memory mine = mines[mineId];
        require(mine.mineStatus == 0 || mine.mineStatus == 1, "Remove failed, unsupported remove");
        uint256 removeIndex = 0;
        uint256 mineIdsLength = difficultyMines[mine.difficulty].length;
        for(uint256 idx = 0; idx < mineIdsLength; idx++) {
            if(difficultyMines[mine.difficulty][idx] == mineId) {
                removeIndex = idx;
                break;
            }
        }
        for(uint256 idx = removeIndex; idx < mineIdsLength-1; idx++){
            difficultyMines[mine.difficulty][idx] = difficultyMines[mine.difficulty][idx+1];
        }
        difficultyMines[mine.difficulty].pop();
        delete mines[mineId];
    }

    function getDifficultyMinesLength(uint256 difficulty) public view returns(uint256) {
        return difficultyMines[difficulty].length;
    }

    function getDifficultyMinesByIndex(uint256 difficulty,uint256 index) public view returns (MineInfo memory) {
        uint256 mineId = difficultyMines[difficulty][index];
        return mines[mineId];
    }

    function getMineInfo(uint256 mineId) public view returns (MineInfo memory) {
        return  mines[mineId];
    }

    function isSupportedDifficulty(uint256 difficulty) public view returns (bool) {
        bool isSupported = false;
        for(uint256 idx = 0; idx < difficulties.length; idx++){
            if(difficulties[idx] == difficulty){
                isSupported = true;
                break;
            }
        }
        return isSupported;
    }

    function getDifficulties() public view returns(uint256[] memory) {
        return difficulties;
    }

    function getDifficultiesLength() public view returns(uint256) {
        return difficulties.length;
    }

    function getDifficultyByIndex(uint256 index) public view returns(uint256) {
        return difficulties[index];
    }

    function changeMonsterIcon(uint256 mineId,uint256 monsterIcon) public onlyController {
        mines[mineId].monsterIcon = monsterIcon;
    } 

    function getAccountId(address ownerAccount) public view returns(uint256) {
        return IERC721(accountContract).tokenOfOwnerByIndex(ownerAccount, 0);
    }

    function setMemberClaimOpen(bool _memberClaimOpen) public onlyController {
        memberClaimOpen = _memberClaimOpen;
    }
    
    function getMemberClaimOpen() public view returns (bool) {
        return memberClaimOpen;
    }

    function getUnionBalance(uint256 unionId) public view returns (uint256) {
        return unionBalance[unionId];
    }

    function withdraw(address tokenAddress,address account,uint256 amount) public onlyOwner {
        IERC20(tokenAddress).transfer(account,amount);
    }

    function getUnionOccupyMine(uint256 unionId) public view returns (uint256) {
        return unionOccupyMine[unionId];
    }

    struct MineData{
        uint256 mineId;
        uint256 difficulty;
        uint256  monsterIcon;
        uint256 dailyRewards;
    }

     struct MineInfo {
        uint256 mineId;
        uint256 difficulty;
        uint256 mineStatus;
        uint256 monsterIcon;
        uint256 dailyRewards;
        uint256 unionId;
        uint256 occupyTime;
    }

    function uint2str(uint256 _i) private pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }

        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        str = string(bstr);
    }

}