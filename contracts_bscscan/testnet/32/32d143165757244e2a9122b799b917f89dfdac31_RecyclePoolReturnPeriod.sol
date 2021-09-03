/**
 *Submitted for verification at BscScan.com on 2021-09-03
*/

pragma solidity 0.8.7;

interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

interface IAccessControlEnumerable {
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
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

library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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

interface ICardSlotManager{
    struct CardSlotConfig{
        uint256 level;
        uint256 needExp;
        uint256 maxCardSlots;
        uint256 powerAdditionRate;
        uint256 powerBaseRate;
    }
    
    struct CardSlot{
        address     owner;
        uint256     level;
        uint256     totalExp;
    }
    
    struct EffectiveHeroCombinationData{
        bytes[] effectiveNames;
        mapping(uint256 => uint256) baseIdCount;
    }
    
    struct HeroCombination{
        bytes name;
        uint256[] baseIds;
        mapping(uint256 => uint256) baseIdCounts;
        uint256[] distinctBaseIds;
        uint256 pownerAdditionRate;
        uint256 baseAdditionRate;
    }
    
    
    struct ReturnHeroParValue{
        uint256 startTime;
        uint256 period;
        uint256 endTime;
        uint256 totalSupply;
        
        uint256 lastReceiveTime;
        uint256 receiveAmount;
    }
    
    function getCardSlot(address addr)view external returns(uint256 level, uint256 totalExp);
    function maxCardSlotLevel()view external returns(uint256);
    function getHeroCombination(string calldata nameBytes) view external returns(bytes memory name, uint256[] memory baseIds,uint256[] memory distinctBaseIds, uint256 pownerAdditionRate, uint256 baseAdditionRate);
    function getCardSlotConfig(uint256 level) view external returns(ICardSlotManager.CardSlotConfig memory);
    function getEffectiveHeroCombination(uint256[] calldata heroIds) external returns(bytes[] memory names);
}

interface IChecker{
    function predicateAwakening(address operator, uint256 toHeroTokenId, uint256 heroTokenId1, uint256 heroTokenId2) view external returns (bool, string memory);
    function afterAwakening(address operator, uint256 toHeroTokenId, uint256 heroTokenId1, uint256 heroTokenId2) external;
    
    function preUpgradeCardSlot(address operator, uint256 heroTokenId) view external returns (bool, string memory);
    function afterUpgradeCardSlot(address operator, uint256 heroTokenId) external;
    
    function preStartSales(address operator, uint256 tokenId, uint256 maxPrice, 
                           uint256 minPrice,uint256 startTime,uint256 durationTime, address nft, address currency) view external returns (bool, string memory);
    function afterStartSales(address operator, uint256 tokenId, uint256 maxPrice, 
                            uint256 minPrice,uint256 startTime,uint256 durationTime, address nft, address currency)external;
    function preLoadEquip(address operator, uint256 heroTokenId, uint256 equipTokenId) view external returns (bool, string memory);
    function afterLoadEquip(address operator, uint256 heroTokenId, uint256 equipTokenId) external;
    function preUnloadEquip(address operator, uint256 heroTokenId, uint256 equipTokenId) view external returns (bool, string memory);
    function afterUnloadEquip(address operator, uint256 heroTokenId, uint256 equipTokenId) external;

    function preHeroTokenSGCPoolStake(address pool, address operator, uint256 heroId) view external returns (bool, string memory);
    
    function preJoinWar(address operator, uint256 heroId) view external returns (bool, string memory);
    function afterJoinWar(address operator, uint256 heroId) external;
    
    function preLeaveWar(address operator, uint256 heroId) view external returns (bool, string memory);
    function afterLeaveWar(address operator, uint256 heroId) external;
    
    function preRecycle(address operator, uint256 heroId) view external returns (bool, string memory);
    function afterRecycle(address operator, uint256 heroId) external;
}

interface IConditionAdditionFilter{
    function filter(uint256 basePower, IEquipToken.Equip calldata equip, IHeroToken.Hero calldata hero, IHeroManager.HeroConfig calldata heroConfig) view external returns(bool);
}

interface IContractManager{
    function _heroToken()    view external returns(address);
    function _powerEnhancer() view external returns(address);
    function _heroManager() view external returns(address);
    function _equipToken() view external returns(address);
    function _checker() view external returns(address);
    function _equipManager() view external returns(address);
    function _cardSlotManager() view external returns(address);
    function _nftMarket() view external returns (address);
    function _conditionAdditionFilter() view external returns(address);
    function _warManager() view external returns(address);
    function _sgcToken() view external returns(address);
    function _equipIntegralToken() view external returns(address);
    function _heroSellFeeAddr() view external returns(address);
    function _equipSellFeeAddr() view external returns(address);
    function _awakeningReceiveHeroAddr()view external returns(address);
    function _upgradeCardSlotReceiveHeroAddr()view external returns(address);
    
    function addHeroTokenSGCPool(address addr) external;
    function removeHeroTokenSGCPool(address addr) external;
    function getHeroTokenSGCPools() external view returns(address[] memory);
    function isHeroTokenSGCPoolExist(address addr) external view returns(bool);
}

interface IEquipIntegralToken is IERC20{
    function mint(address account, uint256 amount) external returns (bool);
    function destroy(address account, uint256 amount) external;
}

interface IEquipManager{
    struct EquipConfig{
        uint256   id;
        uint256   conditionId;
        uint256[] conditionParams;
        uint256 fixedAdditionRate; 
        uint256 conditionAdditionRate;
        uint256 baseAdditionRate;
    }
    
    struct HeroEquip{
        uint256 heroTokenId;
        uint256 maxEquips;
        uint256 []equipTokenIds;
        bool    isAwakening;
    }
    
    struct ReturnHeroParValue{
        uint256 startTime;
        uint256 period;
        uint256 endTime;
        uint256 totalSupply;
        //  ISGCToken returnToken;
        
        uint256 lastReceiveTime;
        uint256 receiveAmount;
    }
    
    function getEquipConfig(uint256 id) view external returns (IEquipManager.EquipConfig memory);
    function equipLoads(uint256 equipTokenId) view external returns(bool);
    function IsHeroHasEquip(uint256 heroTokenId) view external returns(bool);
    function getHeroEquip(uint256 heroTokenId)view external returns(uint256 maxEquips, uint256[] memory equipTokenIds, bool isAwakening);
}

interface IHeroManager{
    struct HeroConfig{
        uint256 id;
    }
    
    function getHeroPower(uint256 tokenId) view external returns (uint256 power);
    function isConfigExist(uint256 id) view external returns (bool);
}

interface IHeroTokenSGCPool{
	function isHeroInStake(uint256 heroId) external view returns(bool);
	function refreshHeroPower(uint256 heroId) external;
	function getStakeHeros(address addr) external view returns(uint256[] memory);
}

interface INFTMarket {
}

interface IPowerEnhancer{
    function enhance(IHeroManager.HeroConfig calldata config,IHeroToken.Hero calldata hero) view external returns(uint256);
}

interface IRewardToken is IERC20{
    function mint(address account, uint256 amount) external returns (bool);
}

interface ISGCToken is IERC20{
    function mint(address account, uint256 amount) external returns (bool);
    function destroy(address account, uint256 amount) external;
    function decimals() external view returns (uint8);
}

interface IWarManager {
    enum WarResult{
        TIE,
        WIN,
        FAIL
    }
    
    struct WarInfo{
        mapping(address => uint256[]) _heroes;
        mapping(uint256 => bool) _heroJointheWar;
        mapping(address => bytes[]) _effectiveHeroCombinations;
        
        mapping(address => bool) userJointheWar;
        mapping(address => uint256) userPower;
        
        IRewardToken[]  rewardTokens;
        uint256[] rewardAmounts;
        
        uint256 totalPower;
        bool    isOccur;
        WarResult result;
        uint256 occurTime;        
        uint256 createTime;
    }
    
    function isJoinWar(uint256 heroId) view external returns(bool);
    function refreshPower(uint256 heroId) external;
    function getLastJoinInfo(address addr) view external returns(uint256 power, uint256[] memory heroes);
    function getUserJoinWars(address addr) view external returns(uint256[] memory);
}

library ContractManagerUtil{
    function  heroToken(IContractManager contractManager) view internal  returns(IHeroToken){ return  IHeroToken(contractManager._heroToken()); }
    function  heroManager(IContractManager contractManager) view internal  returns(IHeroManager){ return  IHeroManager(contractManager._heroManager()); }
    function  powerEnhancer(IContractManager contractManager) view internal  returns(IPowerEnhancer){ return  IPowerEnhancer(contractManager._powerEnhancer()); }
    function  equipToken(IContractManager contractManager) view internal  returns(IEquipToken){ return  IEquipToken(contractManager._equipToken()); }
    function  checker(IContractManager contractManager) view internal  returns(IChecker){ return  IChecker(contractManager._checker()); }
    function  equipManager(IContractManager contractManager) view internal  returns(IEquipManager){ return  IEquipManager(contractManager._equipManager()); }
    function  cardSlotManager(IContractManager contractManager) view internal  returns(ICardSlotManager){ return  ICardSlotManager(contractManager._cardSlotManager()); }
    function  nftMarket(IContractManager contractManager) view internal  returns(INFTMarket){ return  INFTMarket(contractManager._nftMarket()); }
    function  conditionAdditionFilter(IContractManager contractManager) view internal  returns(IConditionAdditionFilter){ return  IConditionAdditionFilter(contractManager._conditionAdditionFilter()); }
    function  warManager(IContractManager contractManager) view internal  returns(IWarManager){ return  IWarManager(contractManager._warManager()); }
    function  sgcToken(IContractManager contractManager) view internal  returns(ISGCToken){ return  ISGCToken(contractManager._sgcToken()); }
    function  equipIntegralToken(IContractManager contractManager) view internal  returns(IEquipIntegralToken){ return  IEquipIntegralToken(contractManager._equipIntegralToken()); }
    function  isHeroStakeInHeroTokenSGCPool(IContractManager contractManager, uint256 heroId)view internal  returns(bool){
        address[] memory heroTokenSGCPools = contractManager.getHeroTokenSGCPools();
        for(uint256 i = 0; i < heroTokenSGCPools.length; i++){
            if(IHeroTokenSGCPool(heroTokenSGCPools[i]).isHeroInStake(heroId)){
                return true;
            }
        }
        
        return false;
    }
    
    function refreshHeroPowerToHeroStakeInHeroTokenSGCPool(IContractManager contractManager, uint256 heroId) internal{
        address[] memory heroTokenSGCPools = contractManager.getHeroTokenSGCPools();
        for(uint256 i = 0; i < heroTokenSGCPools.length; i++){
            if(IHeroTokenSGCPool(heroTokenSGCPools[i]).isHeroInStake(heroId)){
                IHeroTokenSGCPool(heroTokenSGCPools[i]).refreshHeroPower(heroId);
            }
        }
    }
}

library EquipTokenUtil{
    function getEquipStruct(IEquipToken equipToken, uint256 tokenId)internal view returns(IEquipToken.Equip memory equip) {
        require(address(equipToken) != address(0x0));
		return equipToken.getEquip(tokenId);
    }
    
    function belongTo(IEquipToken equipToken, uint256 tokenId, address owner)internal view returns(bool){
        require(equipToken.exists(tokenId));
        return  equipToken.ownerOf(tokenId) == owner;
    }
}

library HeroTokenUtil{
    function getHeroStruct(IHeroToken heroToken, uint256 tokenId)internal view returns(IHeroToken.Hero memory hero) {
        require(address(heroToken) != address(0x0));
        return heroToken.getHero(tokenId);
    }
    
    function belongTo(IHeroToken heroToken, uint256 tokenId, address owner)internal view returns(bool){
        require(heroToken.exists(tokenId));
        return  heroToken.ownerOf(tokenId) == owner;
    }
}

abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IEquipToken is IERC721{
    enum EquipQuality{
        R,
        SR,
        SSR
    }
    
    struct Equip{
        uint256 id;
        uint256 baseId;
        uint256 star;
        EquipQuality quality;
        uint256 fixedAdditionRate;
        uint256 conditionAdditionRate;
        uint256 conditionId;
        uint256 [] conditionParams;
        uint256 baseAdditionRate;
        uint256 block;
        uint256 timestamp;
        address creator;
    }
    
    function exists(uint256 tokenId) view external returns(bool);
    function mint(address to, uint256 baseId ,uint256 star, 
                 IEquipToken.EquipQuality quality,uint256 fixedAdditionRate, uint256 conditionAdditionRate,
                 uint256 conditionId, uint256[] calldata conditionParams, uint256 baseAdditionRate) external returns(uint256);
                 
    function destroy(uint256 tokenId) external;
    function getEquip(uint256 tokenId) view external returns(Equip memory);
}

interface IHeroToken is IERC721{
    enum HeroQuality{
        R,
        SR,
        SSR
    }
    
    struct Hero{
        uint256 id;
        uint256 star;
        HeroQuality quality;
        uint256 parValue;
        address parToken;
        uint256 baseId;
        bool fromFixed;
        uint256 block;
        uint256 timestamp;
        address creator;
    }
    
    function exists(uint256 tokenId) view external returns(bool);
    function mint(address to, uint256 star, HeroQuality quality, uint256 parValue, address parToken, uint256 baseId, bool fromFixed) external;
    function destroy(uint256 tokenId) external;
    function getHero(uint256 tokenId) view external returns(Hero memory);
    function refreshPower(uint256 tokenId) external;
}

abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping (bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
}

contract RecyclePoolReturnPeriod is AccessControlEnumerable, ReentrancyGuard{
    
    struct ReturnHeroParValue{
        uint256 startTime;
        uint256 period;
        uint256 endTime;
        uint256 totalSupply;
        
        uint256 lastReceiveTime;
        uint256 receiveAmount;
    }
    
    using HeroTokenUtil for IHeroToken;
    using EquipTokenUtil for IEquipToken;
    using ContractManagerUtil for IContractManager;
    
    bytes32 public constant GOVERNOR_ROLE   = keccak256("GOVERNOR_ROLE");
    
    IContractManager public contractManager;
    
    uint256 public  recycleRate = 8000;
    uint256 public  baseRate = 10000;
    
    mapping(address => ReturnHeroParValue[]) public returnHeroParValues;
    uint256 public returnParValueInterval = 7 days;
    
    constructor(address _contractManager){
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(GOVERNOR_ROLE, _msgSender());
        setContractManager(_contractManager);
    }
    
    function setContractManager(address addr) onlyRole(GOVERNOR_ROLE) public{
        require(address(0x0) != addr);
        contractManager = IContractManager(addr);
    }
    
    function setReturnParValueInterval(uint256 val) onlyRole(GOVERNOR_ROLE) public{
        returnParValueInterval = val;
    }
    
    function setRecycleRate(uint256 _recycleRate, uint256 _baseRate) onlyRole(GOVERNOR_ROLE) public{
        recycleRate = _recycleRate;
        baseRate = _baseRate;
    }
    
    function recycle(uint256 heroTokenId) nonReentrant public {
        address caller = _msgSender();
        //  require(contractManager.heroToken().belongTo(heroTokenId, caller),"CardSlotManager:hero not belong to you");
        (bool success, string memory errMsg) = contractManager.checker().preRecycle(caller, heroTokenId);
        if(!success){
            revert(errMsg);
        }
        
        contractManager.heroToken().destroy(heroTokenId);
        IHeroToken.Hero memory hero = contractManager.heroToken().getHeroStruct(heroTokenId);
        uint256 returnTokenAmount =  hero.parValue*recycleRate/baseRate;
        require(returnTokenAmount > 0);
        
        ReturnHeroParValue memory returnHeroParValue;
        returnHeroParValue.startTime = block.timestamp;
        returnHeroParValue.period    = returnParValueInterval;
        returnHeroParValue.endTime   = returnHeroParValue.startTime + returnHeroParValue.period;
        returnHeroParValue.totalSupply = returnTokenAmount;
        returnHeroParValue.lastReceiveTime = block.timestamp;
        returnHeroParValue.receiveAmount = 0;
        returnHeroParValues[caller].push(returnHeroParValue);

        contractManager.checker().afterRecycle(caller, heroTokenId);
    }
    
    function viewReturnHeroParValueTotalAmount(address addr) view public returns(uint256 totalAmount){
        for(uint256 i = 0; i < returnHeroParValues[addr].length; i++){
            ReturnHeroParValue storage returnHeroParValue = returnHeroParValues[addr][i];
            totalAmount += returnHeroParValue.totalSupply;
        }
    }
    
    function viewReturnHeroParValueReceiveAmount(address addr)view public returns(uint256 receiveAmount){
        for(uint256 i = 0; i < returnHeroParValues[addr].length; i++){
            ReturnHeroParValue storage returnHeroParValue = returnHeroParValues[addr][i];
            receiveAmount += returnHeroParValue.receiveAmount;
        }
    }
    
    function viewReturnHeroParValue(address addr) view public returns(uint256 reward){
        uint256 nowTime = block.timestamp;
        
        for(uint256 i = 0; i < returnHeroParValues[addr].length; i++){
            ReturnHeroParValue storage returnHeroParValue = returnHeroParValues[addr][i];
            if(returnHeroParValue.lastReceiveTime < returnHeroParValue.endTime){
                if(nowTime >= returnHeroParValue.endTime){
                    reward += (returnHeroParValue.totalSupply - returnHeroParValue.receiveAmount);
                }else{
                    uint256 elapseTime = nowTime - returnHeroParValue.lastReceiveTime;
                    reward += (returnHeroParValue.totalSupply*elapseTime/returnHeroParValue.period);
                }
            }
        }
    }
    
    function getReturnHeroParValue(address toAddr) nonReentrant public {
        require(toAddr != address(0x0));
        require(address(contractManager.sgcToken())!= address(0x0));
        
        address operator = _msgSender();
        uint256 nowTime = block.timestamp;
        uint256 reward  = 0;
        for(uint256 i = 0; i < returnHeroParValues[operator].length; i++){
            ReturnHeroParValue storage returnHeroParValue = returnHeroParValues[operator][i];
            if(returnHeroParValue.lastReceiveTime < returnHeroParValue.endTime){
                if(nowTime >= returnHeroParValue.endTime){
                    reward = (returnHeroParValue.totalSupply - returnHeroParValue.receiveAmount);
                    returnHeroParValue.lastReceiveTime = returnHeroParValue.endTime;
                }else{
                    uint256 elapseTime = nowTime - returnHeroParValue.lastReceiveTime;
                    reward = (returnHeroParValue.totalSupply*elapseTime/returnHeroParValue.period);
                    returnHeroParValue.lastReceiveTime = nowTime;
                }
                
                returnHeroParValue.receiveAmount += reward;
                contractManager.sgcToken().mint(toAddr, reward);
            }
        }
    }
}