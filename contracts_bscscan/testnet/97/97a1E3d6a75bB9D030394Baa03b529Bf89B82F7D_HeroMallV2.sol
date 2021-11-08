/**
 *Submitted for verification at BscScan.com on 2021-11-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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



interface INFT {
     function mint(address to,string memory _name,uint256 _level,uint256 _rarity,uint256 _series,uint256 _race,uint256 _mineralLevel) external returns (bool);
}

interface IWhiteList {
    function isInWhiteList(address account) external view returns (bool);
}

interface IFreeHeroHolder {
    function hasFreeHero(address account) external view returns (bool);
    function addFreeHeroHolder(address account) external;
}


contract HeroMallV2 is Ownable {
    address private heroAddress;
    bool private isOpen = true;
    bool private isFreeOpen = true;
    bool private isPaidOpen = true;
    Price[] private sellPrice;
    address private receiverAddress = 0x000000000000000000000000000000000000dEaD;
    address private whiteListContract;
    address private freeHeroHolders;
    uint256 private totalSupply;
    uint256 private periodTotalSupply;
    uint256 private lastUpdateTime;
    uint256 private periodSellAmount;
    uint256 private period;
    HeroDeploy [] private heroDeploys;
    uint256 private seed = uint256(keccak256(abi.encodePacked(block.number, msg.sender, block.timestamp))) % 10000;
    uint256 []  ids ;
    address private swapPoolAddress=0x5b09f3cB856224d233b480fd5a96Ad0DA82B8c99;
    address private usdtTokenAddress = 0x55d398326f99059fF775485246999027B3197955;
    address private cwtTokenAddress =0x8fF22201D69583b3f081E49E16caf86f3cB708F7;
    
    constructor(address _heroAddress,uint256 _periodTotalSupply,uint256 _period){
        heroAddress = _heroAddress;
        periodTotalSupply = _periodTotalSupply;
        lastUpdateTime = block.timestamp;
        period = _period;
    }
    
    function recruit(uint256 priceIndex) public {
        require(isOpen,"the mall is Close");
        require(isPaidOpen,"can not recruit free hero now");
        require(sellPrice.length>0 , "you can not recruit hero now");
        
        uint256 timestamp = block.timestamp - lastUpdateTime;
        if(timestamp > period){
            uint256 periods = timestamp / period;
            lastUpdateTime = lastUpdateTime + period*periods;
            periodSellAmount = 0;
        }
        require(periodSellAmount+1 <= periodTotalSupply,"hero is sold out current period");
        
        
        // Price memory price = sellPrice[priceIndex];
        CurrentPrice memory price = getPriceByIndex(priceIndex);
        if(whiteListContract != address(0)){
            require(IWhiteList(whiteListContract).isInWhiteList(msg.sender),"your can not recruit hero");
        }
        
        // uint256 currentId = totalSupply + 1;
        uint256 length = heroDeploys.length;
        delete ids;
        for(uint256 i=0;i<length;i++){
            if(heroDeploys[i].totalSupply>heroDeploys[i].sellAmount){
                ids.push(i);
            }
        }
        require(ids.length>0,"all hero is sold out");
        uint256 index = ids[getRandom() % ids.length];
        string memory _name = heroDeploys[index].name;
        heroDeploys[index].sellAmount += 1;
        string memory name = string(abi.encodePacked(_name, "#", uint2str(heroDeploys[index].sellAmount)));
        
        if(price.cwtPrice>0){
            IERC20(price.cwtToken).transferFrom(msg.sender,receiverAddress,price.cwtPrice);
        }
        
        INFT(heroAddress).mint(msg.sender,name,1,price.rarity,1,1,price.mineralLevel);
        totalSupply += 1;
        periodSellAmount +=1;
        
    }
    
    function recruitFree() public{
        require(isOpen,"the mall is Close");
        require(isFreeOpen,"can not recruit free hero now");
        require(!hasFreeHero(msg.sender),"you already has free hero");
        if(freeHeroHolders!=address(0)){
            IFreeHeroHolder(freeHeroHolders).addFreeHeroHolder(msg.sender); 
        }
        
        uint256 timestamp = block.timestamp - lastUpdateTime;
        if(timestamp > period){
            uint256 periods = timestamp / period;
            lastUpdateTime = lastUpdateTime + period*periods;
            periodSellAmount = 0;
        }
        require(periodSellAmount+1 <= periodTotalSupply,"hero is sold out current period");
        
        // uint256 currentId = totalSupply + 1;
        uint256 length = heroDeploys.length;
        delete ids;
        for(uint256 i=0;i<length;i++){
            if(heroDeploys[i].totalSupply>heroDeploys[i].sellAmount){
                ids.push(i);
            }
        }
        require(ids.length>0,"all hero is sold out");
        uint256 index = ids[getRandom() % ids.length];
        string memory _name = heroDeploys[index].name;
        heroDeploys[index].sellAmount += 1;
        string memory name = string(abi.encodePacked(_name, "#", uint2str(heroDeploys[index].sellAmount)));
        
        INFT(heroAddress).mint(msg.sender,name,1,0,1,1,1);
        totalSupply += 1;
        periodSellAmount +=1;
    }
    
    function getPeriodTotalSupply() public view returns (uint256) {
        return periodTotalSupply;
    }
    
    function setPeriodTotalSupply(uint256 _periodTotalSupply) public onlyController {
        periodTotalSupply = _periodTotalSupply;
    }
    
    
    function getPeriodSellAmount() public view returns (uint256) {
        return periodSellAmount;
    }
    
    function setPeriod(uint256 _period) public onlyController {
        period = _period;
    }
    
    function getPeriod() public view returns (uint256) {
        return period;
    }
    
    function getLastUpdateTime() public view returns (uint256) {
        return lastUpdateTime;
    }
    
    function getCurrentPeriodSellAmount () public view returns (uint256) {
        if(block.timestamp - lastUpdateTime > period){
            return 0;
        }else{
            return periodSellAmount;
        }
    }
    
    function setPrice(address _exchangeToken,uint256 _rarity,uint256 _mineralLevel,uint256 _price) public onlyController {
        Price memory price = Price({
            exchangeToken:_exchangeToken,
            rarity:_rarity,
            mineralLevel:_mineralLevel,
            price:_price
        }); 
        
        sellPrice.push(price);
    }
    
    function updatePrice(uint256 index,address _exchangeToken,uint256 _rarity,uint256 _mineralLevel,uint256 _price) public onlyController {
        sellPrice[index].exchangeToken = _exchangeToken;
        sellPrice[index].rarity = _rarity;
        sellPrice[index].mineralLevel = _mineralLevel;
        sellPrice[index].price = _price;
    }
    
    function setOpen(bool _isOpen) public onlyController {
        isOpen = _isOpen;
    }
    
    function getIsOpen() public view returns (bool) {
        return isOpen;
    }
    
    function setFreeOpen(bool _isFreeOpen) public onlyController {
        isFreeOpen = _isFreeOpen;
    }
    
    function getIsFreeOpen() public view returns (bool) {
        return isFreeOpen;
    }
    
    function getIsPaidOpen () public view returns (bool) {
        return isPaidOpen;
    }
    
    function setPaidOpen(bool _isPaidOpen) public onlyController {
        isPaidOpen = _isPaidOpen;
    }
    
    function setFreeHeroHoldersAddress(address _freeHeroHolders) public onlyController {
        freeHeroHolders = _freeHeroHolders;
    }
    
    function getFreeHeroHoldersAddress() public view returns (address) {
       return freeHeroHolders;
    }
    
    function hasFreeHero(address account) public view returns (bool) {
        if(freeHeroHolders == address(0)){
            return false;
        }else{
            return IFreeHeroHolder(freeHeroHolders).hasFreeHero(account);
        }
    }
    
    function setWhiteListContract(address _whiteListContract) public onlyController {
        whiteListContract = _whiteListContract;
    }
    
    function accountIsInWhiteList(address account) public view returns (bool) {
        if(whiteListContract == address(0)){
            return true;
        }else{
            return IWhiteList(whiteListContract).isInWhiteList(account);
        }
    }
    
    function getWhiteListContract() public view returns (address) {
        return whiteListContract;
    }
    
    function setReceiverAddress(address _receiverAddress) public onlyController {
        receiverAddress = _receiverAddress;
    }
    
    function getReceiverAddress() public view returns (address) {
        return receiverAddress;
    }
    
    function getRandom() private  returns (uint256) {
        uint256 randomNumber = uint256(
            uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, seed))) % 10000
        );
        seed = seed + 1;
        return randomNumber;
    }
    
    function addHeroDeploy(string memory _name,uint256 _totalSupply) public onlyController {
        HeroDeploy memory heroDeploy = HeroDeploy({
            name:_name,
            totalSupply:_totalSupply,
            sellAmount:0
        });
        
        heroDeploys.push(heroDeploy);
    }
    
    function updateHeroDeploy(uint256 index,string memory _name,uint256 _totalSupply,uint256 _sellAmount) public onlyController {
        heroDeploys[index].name = _name;
        heroDeploys[index].totalSupply = _totalSupply;
        heroDeploys[index].sellAmount = _sellAmount;
    }
    
    function getHeroDeployLength() public view returns (uint256) {
        return heroDeploys.length;
    }
    
    function getHeroDeployByIndex(uint256 index) public view returns (HeroDeploy memory) {
        return heroDeploys[index];
    }
    
    function getHeroDeploys() public view returns (HeroDeploy [] memory){
        return heroDeploys;
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
    
    // function getPriceByIndex(uint256 index) public view returns (CurrentPrice memory) {
    //     Price memory price =  sellPrice[index];
    //     uint256 _cwtPrice = price.price * _getPrice() / 1e18;
    //     CurrentPrice memory currentPrice = CurrentPrice({
    //         exchangeToken:price.exchangeToken,
    //         rarity:price.rarity,
    //         mineralLevel:price.mineralLevel,
    //         price:price.price,
    //         cwtToken:cwtTokenAddress,
    //         cwtPrice:_cwtPrice
    //     });
    //     return currentPrice;
    // }
    
    function getPriceByIndex(uint256 index) public view returns (CurrentPrice memory) {
        Price memory price =  sellPrice[index];
        uint256 _cwtPrice = price.price * 1000;
        CurrentPrice memory currentPrice = CurrentPrice({
            exchangeToken:price.exchangeToken,
            rarity:price.rarity,
            mineralLevel:price.mineralLevel,
            price:price.price,
            cwtToken:0xA7b194Fb8f9b5A3a92bD5e99E2028C922727c770,
            cwtPrice:_cwtPrice
        });
        return currentPrice;
    }
    
    function getPricesLength() public view returns (uint256) {
        return sellPrice.length;
    }
    
     function _getPrice() private  view returns (uint256){
        uint256 cwtBalance = IERC20(cwtTokenAddress).balanceOf(swapPoolAddress);
        uint256 usdBalance = IERC20(usdtTokenAddress).balanceOf(swapPoolAddress);
        uint256 amountInWithFee = 1e18 * 9975;
        uint256 numerator = amountInWithFee * cwtBalance;
        uint256 denominator = usdBalance * 10000 + amountInWithFee;
        uint256 amount = numerator / denominator;
        return amount;
    }
    struct CurrentPrice{
        address exchangeToken;
        uint256 rarity;
        uint256 mineralLevel;
        uint256 price;
        address cwtToken;
        uint256 cwtPrice;
    }
    
    struct Price {
        address exchangeToken;
        uint256 rarity;
        uint256 mineralLevel;
        uint256 price;
        
    }
    
    struct HeroDeploy {
        string name;
        uint256 totalSupply;
        uint256 sellAmount;
    }
}