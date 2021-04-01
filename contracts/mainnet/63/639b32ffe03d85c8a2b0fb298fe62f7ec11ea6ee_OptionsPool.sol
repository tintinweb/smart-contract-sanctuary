/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

// File: contracts\modules\Ownable.sol

pragma solidity =0.5.16;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts\modules\Managerable.sol

pragma solidity =0.5.16;

contract Managerable is Ownable {

    address private _managerAddress;
    /**
     * @dev modifier, Only manager can be granted exclusive access to specific functions. 
     *
     */
    modifier onlyManager() {
        require(_managerAddress == msg.sender,"Managerable: caller is not the Manager");
        _;
    }
    /**
     * @dev set manager by owner. 
     *
     */
    function setManager(address managerAddress)
    public
    onlyOwner
    {
        _managerAddress = managerAddress;
    }
    /**
     * @dev get manager address. 
     *
     */
    function getManager()public view returns (address) {
        return _managerAddress;
    }
}

// File: contracts\interfaces\IFNXOracle.sol

pragma solidity =0.5.16;

interface IFNXOracle {
    /**
  * @notice retrieves price of an asset
  * @dev function to get price for an asset
  * @param asset Asset for which to get the price
  * @return uint mantissa of asset price (scaled by 1e8) or zero if unset or contract paused
  */
    function getPrice(address asset) external view returns (uint256);
    function getUnderlyingPrice(uint256 cToken) external view returns (uint256);
    function getPrices(uint256[] calldata assets) external view returns (uint256[]memory);
    function getAssetAndUnderlyingPrice(address asset,uint256 underlying) external view returns (uint256,uint256);
//    function getSellOptionsPrice(address oToken) external view returns (uint256);
//    function getBuyOptionsPrice(address oToken) external view returns (uint256);
}
contract ImportOracle is Ownable{
    IFNXOracle internal _oracle;
    function oraclegetPrices(uint256[] memory assets) internal view returns (uint256[]memory){
        uint256[] memory prices = _oracle.getPrices(assets);
        uint256 len = assets.length;
        for (uint i=0;i<len;i++){
        require(prices[i] >= 100 && prices[i] <= 1e30);
        }
        return prices;
    }
    function oraclePrice(address asset) internal view returns (uint256){
        uint256 price = _oracle.getPrice(asset);
        require(price >= 100 && price <= 1e30);
        return price;
    }
    function oracleUnderlyingPrice(uint256 cToken) internal view returns (uint256){
        uint256 price = _oracle.getUnderlyingPrice(cToken);
        require(price >= 100 && price <= 1e30);
        return price;
    }
    function oracleAssetAndUnderlyingPrice(address asset,uint256 cToken) internal view returns (uint256,uint256){
        (uint256 price1,uint256 price2) = _oracle.getAssetAndUnderlyingPrice(asset,cToken);
        require(price1 >= 100 && price1 <= 1e30);
        require(price2 >= 100 && price2 <= 1e30);
        return (price1,price2);
    }
    function getOracleAddress() public view returns(address){
        return address(_oracle);
    }
    function setOracleAddress(address oracle)public onlyOwner{
        _oracle = IFNXOracle(oracle);
    }
}

// File: contracts\modules\whiteList.sol

pragma solidity =0.5.16;
    /**
     * @dev Implementation of a whitelist which filters a eligible uint32.
     */
library whiteListUint32 {
    /**
     * @dev add uint32 into white list.
     * @param whiteList the storage whiteList.
     * @param temp input value
     */

    function addWhiteListUint32(uint32[] storage whiteList,uint32 temp) internal{
        if (!isEligibleUint32(whiteList,temp)){
            whiteList.push(temp);
        }
    }
    /**
     * @dev remove uint32 from whitelist.
     */
    function removeWhiteListUint32(uint32[] storage whiteList,uint32 temp)internal returns (bool) {
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        if (i<len){
            if (i!=len-1) {
                whiteList[i] = whiteList[len-1];
            }
            whiteList.length--;
            return true;
        }
        return false;
    }
    function isEligibleUint32(uint32[] memory whiteList,uint32 temp) internal pure returns (bool){
        uint256 len = whiteList.length;
        for (uint256 i=0;i<len;i++){
            if (whiteList[i] == temp)
                return true;
        }
        return false;
    }
    function _getEligibleIndexUint32(uint32[] memory whiteList,uint32 temp) internal pure returns (uint256){
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        return i;
    }
}
    /**
     * @dev Implementation of a whitelist which filters a eligible uint256.
     */
library whiteListUint256 {
    // add whiteList
    function addWhiteListUint256(uint256[] storage whiteList,uint256 temp) internal{
        if (!isEligibleUint256(whiteList,temp)){
            whiteList.push(temp);
        }
    }
    function removeWhiteListUint256(uint256[] storage whiteList,uint256 temp)internal returns (bool) {
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        if (i<len){
            if (i!=len-1) {
                whiteList[i] = whiteList[len-1];
            }
            whiteList.length--;
            return true;
        }
        return false;
    }
    function isEligibleUint256(uint256[] memory whiteList,uint256 temp) internal pure returns (bool){
        uint256 len = whiteList.length;
        for (uint256 i=0;i<len;i++){
            if (whiteList[i] == temp)
                return true;
        }
        return false;
    }
    function _getEligibleIndexUint256(uint256[] memory whiteList,uint256 temp) internal pure returns (uint256){
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        return i;
    }
}
    /**
     * @dev Implementation of a whitelist which filters a eligible address.
     */
library whiteListAddress {
    // add whiteList
    function addWhiteListAddress(address[] storage whiteList,address temp) internal{
        if (!isEligibleAddress(whiteList,temp)){
            whiteList.push(temp);
        }
    }
    function removeWhiteListAddress(address[] storage whiteList,address temp)internal returns (bool) {
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        if (i<len){
            if (i!=len-1) {
                whiteList[i] = whiteList[len-1];
            }
            whiteList.length--;
            return true;
        }
        return false;
    }
    function isEligibleAddress(address[] memory whiteList,address temp) internal pure returns (bool){
        uint256 len = whiteList.length;
        for (uint256 i=0;i<len;i++){
            if (whiteList[i] == temp)
                return true;
        }
        return false;
    }
    function _getEligibleIndexAddress(address[] memory whiteList,address temp) internal pure returns (uint256){
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        return i;
    }
}

// File: contracts\modules\underlyingAssets.sol

pragma solidity =0.5.16;


    /**
     * @dev Implementation of a underlyingAssets filters a eligible underlying.
     */
contract UnderlyingAssets is Ownable {
    using whiteListUint32 for uint32[];
    // The eligible underlying list
    uint32[] internal underlyingAssets;
    /**
     * @dev Implementation of add an eligible underlying into the underlyingAssets.
     * @param underlying new eligible underlying.
     */
    function addUnderlyingAsset(uint32 underlying)public onlyOwner{
        underlyingAssets.addWhiteListUint32(underlying);
    }
    function setUnderlyingAsset(uint32[] memory underlyings)public onlyOwner{
        underlyingAssets = underlyings;
    }
    /**
     * @dev Implementation of revoke an invalid underlying from the underlyingAssets.
     * @param removeUnderlying revoked underlying.
     */
    function removeUnderlyingAssets(uint32 removeUnderlying)public onlyOwner returns(bool) {
        return underlyingAssets.removeWhiteListUint32(removeUnderlying);
    }
    /**
     * @dev Implementation of getting the eligible underlyingAssets.
     */
    function getUnderlyingAssets()public view returns (uint32[] memory){
        return underlyingAssets;
    }
    /**
     * @dev Implementation of testing whether the input underlying is eligible.
     * @param underlying input underlying for testing.
     */    
    function isEligibleUnderlyingAsset(uint32 underlying) public view returns (bool){
        return underlyingAssets.isEligibleUint32(underlying);
    }
    function _getEligibleUnderlyingIndex(uint32 underlying) internal view returns (uint256){
        return underlyingAssets._getEligibleIndexUint32(underlying);
    }
}

// File: contracts\interfaces\IVolatility.sol

pragma solidity =0.5.16;

interface IVolatility {
    function calculateIv(uint32 underlying,uint8 optType,uint256 expiration,uint256 currentPrice,uint256 strikePrice)external view returns (uint256);
}
contract ImportVolatility is Ownable{
    IVolatility internal _volatility;
    function getVolatilityAddress() public view returns(address){
        return address(_volatility);
    }
    function setVolatilityAddress(address volatility)public onlyOwner{
        _volatility = IVolatility(volatility);
    }
}

// File: contracts\interfaces\IOptionsPrice.sol

pragma solidity =0.5.16;

interface IOptionsPrice {
    function getOptionsPrice(uint256 currentPrice, uint256 strikePrice, uint256 expiration,uint32 underlying,uint8 optType)external view returns (uint256);
    function getOptionsPrice_iv(uint256 currentPrice, uint256 strikePrice, uint256 expiration,
                uint256 ivNumerator,uint8 optType)external view returns (uint256);
    function calOptionsPriceRatio(uint256 selfOccupied,uint256 totalOccupied,uint256 totalCollateral) external view returns (uint256);
}
contract ImportOptionsPrice is Ownable{
    IOptionsPrice internal _optionsPrice;
    function getOptionsPriceAddress() public view returns(address){
        return address(_optionsPrice);
    }
    function setOptionsPriceAddress(address optionsPrice)public onlyOwner{
        _optionsPrice = IOptionsPrice(optionsPrice);
    }
}

// File: contracts\modules\Operator.sol

pragma solidity =0.5.16;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * each operator can be granted exclusive access to specific functions.
 *
 */
contract Operator is Ownable {
    using whiteListAddress for address[];
    address[] private _operatorList;
    /**
     * @dev modifier, every operator can be granted exclusive access to specific functions. 
     *
     */
    modifier onlyOperator() {
        require(_operatorList.isEligibleAddress(msg.sender),"Managerable: caller is not the Operator");
        _;
    }
    /**
     * @dev modifier, Only indexed operator can be granted exclusive access to specific functions. 
     *
     */
    modifier onlyOperatorIndex(uint256 index) {
        require(_operatorList.length>index && _operatorList[index] == msg.sender,"Operator: caller is not the eligible Operator");
        _;
    }
    /**
     * @dev add a new operator by owner. 
     *
     */
    function addOperator(address addAddress)public onlyOwner{
        _operatorList.addWhiteListAddress(addAddress);
    }
    /**
     * @dev modify indexed operator by owner. 
     *
     */
    function setOperator(uint256 index,address addAddress)public onlyOwner{
        _operatorList[index] = addAddress;
    }
    /**
     * @dev remove operator by owner. 
     *
     */
    function removeOperator(address removeAddress)public onlyOwner returns (bool){
        return _operatorList.removeWhiteListAddress(removeAddress);
    }
    /**
     * @dev get all operators. 
     *
     */
    function getOperator()public view returns (address[] memory) {
        return _operatorList;
    }
    /**
     * @dev set all operators by owner. 
     *
     */
    function setOperators(address[] memory operators)public onlyOwner {
        _operatorList = operators;
    }
}

// File: contracts\modules\ImputRange.sol

pragma solidity =0.5.16;


contract ImputRange is Ownable {
    
    //The maximum input amount limit.
    uint256 private maxAmount = 1e30;
    //The minimum input amount limit.
    uint256 private minAmount = 1e2;
    
    modifier InRange(uint256 amount) {
        require(maxAmount>=amount && minAmount<=amount,"input amount is out of input amount range");
        _;
    }
    /**
     * @dev Determine whether the input amount is within the valid range
     * @param Amount Test value which is user input
     */
    function isInputAmountInRange(uint256 Amount)public view returns (bool){
        return(maxAmount>=Amount && minAmount<=Amount);
    }
    /*
    function isInputAmountSmaller(uint256 Amount)public view returns (bool){
        return maxAmount>=amount;
    }
    function isInputAmountLarger(uint256 Amount)public view returns (bool){
        return minAmount<=amount;
    }
    */
    modifier Smaller(uint256 amount) {
        require(maxAmount>=amount,"input amount is larger than maximium");
        _;
    }
    modifier Larger(uint256 amount) {
        require(minAmount<=amount,"input amount is smaller than maximium");
        _;
    }
    /**
     * @dev get the valid range of input amount
     */
    function getInputAmountRange() public view returns(uint256,uint256) {
        return (minAmount,maxAmount);
    }
    /**
     * @dev set the valid range of input amount
     * @param _minAmount the minimum input amount limit
     * @param _maxAmount the maximum input amount limit
     */
    function setInputAmountRange(uint256 _minAmount,uint256 _maxAmount) public onlyOwner{
        minAmount = _minAmount;
        maxAmount = _maxAmount;
    }        
}

// File: contracts\OptionsPool\OptionsData.sol

pragma solidity =0.5.16;







contract OptionsData is UnderlyingAssets,ImputRange,Managerable,ImportOracle,ImportVolatility,ImportOptionsPrice,Operator{

        // store option info
        struct OptionsInfo {
        address     owner;      // option's owner
        uint8   	optType;    //0 for call, 1 for put
        uint24		underlying; // underlying ID, 1 for BTC,2 for ETH
        uint64      optionsPrice;

        address     settlement;    //user's settlement paying for option. 
        uint64      createTime;
        uint32		expiration; //


        uint128     amount; 
        uint128     settlePrice;

        uint128     strikePrice;    //  strike price		
        uint32      priceRate;    //underlying Price	
        uint64      iv;
        uint32      extra;
    }

    uint256 internal limitation = 1 hours;
    //all options information list
    OptionsInfo[] internal allOptions;
    //user options balances
    mapping(address=>uint64[]) internal optionsBalances;
    //expiration whitelist
    uint32[] internal expirationList;
    
    // first option position which is needed calculate.
    uint256 internal netWorthirstOption;
    // options latest networth balance. store all options's net worth share started from first option.
    mapping(address=>int256) internal optionsLatestNetWorth;

    // first option position which is needed calculate.
    uint256 internal occupiedFirstOption; 
    //latest calcutated Options Occupied value.
    uint256 internal callOccupied;
    uint256 internal putOccupied;
    //latest Options volatile occupied value when bought or selled options.
    int256 internal callLatestOccupied;
    int256 internal putLatestOccupied;

    /**
     * @dev Emitted when `owner` create a new option. 
     * @param owner new option's owner
     * @param optionID new option's id
     * @param optionID new option's type 
     * @param underlying new option's underlying 
     * @param expiration new option's expiration timestamp
     * @param strikePrice  new option's strikePrice
     * @param amount  new option's amount
     */
    event CreateOption(address indexed owner,uint256 indexed optionID,uint8 optType,uint32 underlying,uint256 expiration,uint256 strikePrice,uint256 amount);
    /**
     * @dev Emitted when `owner` burn `amount` his option which id is `optionID`. 
     */    
    event BurnOption(address indexed owner,uint256 indexed optionID,uint amount);
    event DebugEvent(uint256 id,uint256 value1,uint256 value2);
}
/*
contract OptionsDataV2 is OptionsData{
        // store option info
    struct OptionsInfoV2 {
        uint64     optionID;    //an increasing nubmer id, begin from one.
        uint64		expiration; // Expiration timestamp
        uint128     strikePrice;    //strike price
        uint8   	optType;    //0 for call, 1 for put
        uint32		underlying; // underlying ID, 1 for BTC,2 for ETH
        address     owner;      // option's owner
        uint256     amount;         // mint amount
    }
    // store option extra info
    struct OptionsInfoExV2 {
        address      settlement;    //user's settlement paying for option. 
        uint128      tokenTimePrice; //option's buying price based on settlement, used for options share calculation
        uint128      underlyingPrice;//underlying price when option is created.
        uint128      fullPrice;      //option's buying price.
        uint128      ivNumerator;   // option's iv numerator when option is created.
//        uint256      ivDenominator;// option's iv denominator when option is created.
    }
        //all options information list
    OptionsInfoV2[] internal allOptionsV2;
    // all option's extra information map
    mapping(uint256=>OptionsInfoExV2) internal optionExtraMapV2;
        //user options balances
//    mapping(address=>uint64[]) internal optionsBalancesV2;
}
*/

// File: contracts\modules\tuple64.sol

pragma solidity =0.5.16;
library tuple64 {
    // add whiteList
    function getValue0(uint256 input) internal pure returns (uint256){
        return uint256(uint64(input));
    }
    function getValue1(uint256 input) internal pure returns (uint256){
        return uint256(uint64(input>>64));
    }
    function getValue2(uint256 input) internal pure returns (uint256){
        return uint256(uint64(input>>128));
    }
    function getValue3(uint256 input) internal pure returns (uint256){
        return uint256(uint64(input>>192));
    }
    function getTuple(uint256 input0,uint256 input1,uint256 input2,uint256 input3) internal pure returns (uint256){
        return input0+(input1<<64)+(input2<<128)+(input3<<192);
    }
    function getTuple3(uint256 input0,uint256 input1,uint256 input2) internal pure returns (uint256){
        return input0+(input1<<64)+(input2<<128);
    }
    function getTuple2(uint256 input0,uint256 input1) internal pure returns (uint256){
        return input0+(input1<<64);
    }
}

// File: contracts\OptionsPool\Optionsbase.sol

pragma solidity =0.5.16;


/**
 * @title Options data contract.
 * @dev A Smart-contract to store options info.
 *
 */
contract OptionsBase is OptionsData {
    using whiteListUint32 for uint32[];
    constructor () public{
        initialize();
    }
    function initialize() onlyOwner public {
        expirationList =  [1 days,2 days,3 days, 7 days, 10 days, 15 days,20 days, 30 days/*,90 days*/];
        underlyingAssets = [1,2];
    }
    function setTimeLimitation(uint256 _limit)public onlyOwner{
        limitation = _limit;
    }
    function getTimeLimitation()public view returns(uint256){
        return limitation;
    }
    
    /**
     * @dev retrieve user's options' id. 
     * @param user user's account.
     */     
    function getUserOptionsID(address user)public view returns(uint64[] memory){
        return optionsBalances[user];
    }
    /**
     * @dev retrieve user's `size` number of options' id. 
     * @param user user's account.
     * @param from user's option list begin positon.
     * @param size retrieve size.
     */ 
    function getUserOptionsID(address user,uint256 from,uint256 size)public view returns(uint64[] memory){
        require(from <optionsBalances[user].length,"input from is overflow");
        require(size>0,"input size is zero");
        uint64[] memory userIdAry = new uint64[](size);
        if (from+size>optionsBalances[user].length){
            size = optionsBalances[user].length-from;
        }
        for (uint256 i= 0;i<size;i++){
            userIdAry[i] = optionsBalances[user][from+i];
        }
        return userIdAry;
    }
    /**
     * @dev retrieve all option list length. 
     */ 
    function getOptionInfoLength()public view returns (uint256){
        return allOptions.length;
    }
    function getOptionInfo(uint64 id)internal view returns(address,uint256,uint256,uint256,uint256){
        OptionsInfo memory info = allOptions[id-1];
        return (info.owner,
            (uint256(id) << 128)+(uint256(info.underlying) << 64) + info.optType,
            (uint256(info.createTime+limitation) << 128)+(uint256(info.createTime) << 64)+info.createTime+info.expiration,
            info.strikePrice,
            info.amount);
            
    }
    /**
     * @dev retrieve `size` number of options' information. 
     * @param from all option list begin positon.
     * @param size retrieve size.
     */     
    function getOptionInfoList(uint256 from,uint256 size)public view 
                returns(address[] memory,uint256[] memory,uint256[] memory,uint256[] memory,uint256[] memory){
        uint256 allLen = allOptions.length;
        require(from <allLen,"input from is overflow");
        require(size>0,"input size is zero");
        if (from+size>allLen){
            size = allLen - from;
        }
        address[] memory ownerArr = new address[](size);
        uint256[] memory type_underlying_id = new uint256[](size);
        uint256[] memory exp_create_limit = new uint256[](size);
        uint256[] memory priceArr = new uint256[](size);
        uint256[] memory amountArr = new uint256[](size);
        for (uint i=0;i<size;i++){
            (ownerArr[i],type_underlying_id[i],exp_create_limit[i],priceArr[i],amountArr[i]) = 
                getOptionInfo(uint64(from+i+1));
        }
        return (ownerArr,type_underlying_id,exp_create_limit,priceArr,amountArr);
    }

    /**
     * @dev retrieve given `ids` options' information. 
     * @param ids retrieved options' id.
     */   
    function getOptionInfoListFromID(uint64[] memory ids)public view 
                returns(address[] memory,uint256[] memory,uint256[] memory,uint256[] memory,uint256[] memory){
        uint256 size = ids.length;
        require(size > 0, "input ids array is empty");
        address[] memory ownerArr = new address[](size);
        uint256[] memory type_underlying_id = new uint256[](size);
        uint256[] memory exp_create_limit = new uint256[](size);
        uint256[] memory priceArr = new uint256[](size);
        uint256[] memory amountArr = new uint256[](size);
        for (uint i=0;i<size;i++){
            (ownerArr[i],type_underlying_id[i],exp_create_limit[i],priceArr[i],amountArr[i]) = 
                getOptionInfo(ids[i]);
        }
        return (ownerArr,type_underlying_id,exp_create_limit,priceArr,amountArr);
    }
        /**
     * @dev retrieve given `ids` options' information. 
     * @param user retrieved user's address.
     */   
    function getUserAllOptionInfo(address user)public view 
                returns(address[] memory,uint256[] memory,uint256[] memory,uint256[] memory,uint256[] memory){
        return getOptionInfoListFromID(optionsBalances[user]);
    }
    /**
     * @dev retrieve given `optionsId` option's burned limit timestamp. 
     * @param optionsId retrieved option's id.
     */ 
    function getOptionsLimitTimeById(uint256 optionsId)public view returns(uint256){
        require(optionsId>0 && optionsId <= allOptions.length,"option id is not exist");
        OptionsInfo storage info = allOptions[optionsId-1];
        return info.createTime + limitation;
    }
    /**
     * @dev retrieve given `optionsId` option's information. 
     * @param optionsId retrieved option's id.
     */ 
    function getOptionsById(uint256 optionsId)public view returns(uint256,address,uint8,uint32,uint256,uint256,uint256){
        OptionsInfo memory info = _getOptionsById(optionsId);
        return (optionsId,info.owner,info.optType,info.underlying,info.createTime+info.expiration,info.strikePrice,info.amount);
    }
    /**
     * @dev retrieve given `optionsId` option's extra information. 
     * @param optionsId retrieved option's id.
     */
    function getOptionsExtraById(uint256 optionsId)public view returns(address,uint256,uint256,uint256,uint256){
        OptionsInfo memory info = _getOptionsById(optionsId);
        return (info.settlement,info.settlePrice,(info.strikePrice*info.priceRate)>>28,
                info.optionsPrice,info.iv);
    }
    /**
     * @dev An auxiliary function, get underlying prices. 
     */
    function getUnderlyingPrices()internal view returns(uint256[] memory){
        uint256 underlyingLen = underlyingAssets.length;
        uint256[] memory prices = new uint256[](underlyingLen);
        for (uint256 i = 0;i<underlyingLen;i++){
            prices[i] = oracleUnderlyingPrice(underlyingAssets[i]);
        }
        return prices;
    }
    /**
     * @dev create new option, store option info.
     * @param from option's owner
     * @param type_ly_expiration the tuple64 of option type, underlying,expiration
     * @param strikePrice option's strike price and underlying price
     * @param underlyingPrice option's paid price and price rate
     * @param amount option's amount
     */
    function _createOptions(address from,address settlement,uint256 type_ly_expiration,
        uint128 strikePrice,uint128 underlyingPrice,uint128 amount,uint128 settlePrice) internal returns(uint256){
        uint32 expiration = uint32(type_ly_expiration>>128);
        require(underlyingAssets.isEligibleUint32(uint32(type_ly_expiration>>64)) , "underlying is unsupported asset");
        require(expirationList.isEligibleUint32(expiration),"expiration value is not supported");
        uint256 iv = _volatility.calculateIv(uint32(type_ly_expiration>>64),uint8(type_ly_expiration),expiration,
            underlyingPrice,strikePrice); 
        uint256 optPrice = _optionsPrice.getOptionsPrice_iv(underlyingPrice,strikePrice,expiration,iv,uint8(type_ly_expiration));
        allOptions.push(OptionsInfo(from,
            uint8(type_ly_expiration),
            uint24(type_ly_expiration>>64),
            uint64(optPrice),
            settlement,
            uint64(now),
            expiration,
            amount,
            settlePrice,
            strikePrice,
            uint32((underlyingPrice<<28)/strikePrice),
            uint64(iv),
            0));
        uint64 optionID = uint64(allOptions.length);
        optionsBalances[from].push(optionID);
        emit CreateOption(from,optionID,uint8(type_ly_expiration),uint32(type_ly_expiration>>64),expiration+now,
            strikePrice,amount);
        return optPrice;
    }
    /**
     * @dev An auxiliary function, store new option's extra information.
     * @param info option's information
     * @param settlement the Coin address which user's paying for
     * @param priceAndRate option's paid price
     * @param underlyingAndStrike option's strike price and underlying price
     */
     /*
    function setOptionsExtra(OptionsInfo memory info,address settlement,uint256 priceAndRate,uint256 underlyingAndStrike,uint256 settlePrice) internal{
        uint256 underlyingPrice = (underlyingAndStrike>>128);
        uint256 expiration = info.expiration - now;
        uint256 ivNumerator = _volatility.calculateIv(info.underlying,info.optType,expiration,underlyingPrice,uint256(uint128(underlyingAndStrike)));
        uint128 optionPrice = uint128(priceAndRate>>128);
        uint128 rate = uint128(priceAndRate);
        settlePrice = settlePrice/(uint256(rate));
        optionExtraMap[info.optionID-1]= OptionsInfoEx(settlement,settlePrice,underlyingPrice,(uint256(optionPrice)*rate)>>32,ivNumerator,1<<32);
    }
    */
    /**
     * @dev burn an exist option whose id is `id`.
     * @param from option's owner
     * @param amount option's amount
     */
    function _burnOptions(address from,uint256 id,OptionsInfo memory info,uint256 amount)internal{
//        OptionsInfo storage info = _getOptionsById(id);
        require(info.createTime+info.expiration>now,"option is expired");
        require(info.owner == from,"caller is not the options owner");
        require(info.amount >= amount,"option amount is insufficient");
        allOptions[id-1].amount = info.amount-uint128(amount);
        emit BurnOption(from,id,amount);
    }
    /**
     * @dev calculate option's exercise worth.
     * @param optionsId option's id
     * @param amount option's amount
     */
    function getExerciseWorth(uint256 optionsId,uint256 amount)public view returns(uint256){
        OptionsInfo memory info = _getOptionsById(optionsId);
        require(info.createTime+info.expiration>now,"option is expired");
        require(info.amount >= amount,"option amount is insufficient");
        uint256 underlyingPrice = oracleUnderlyingPrice(info.underlying);
        uint256 tokenPayback = _getOptionsPayback(info.optType,info.strikePrice,underlyingPrice);
        if (tokenPayback == 0 ){
            return 0;
        } 
        return tokenPayback*amount;
    }
    /**
     * @dev An auxiliary function, calculate option's exercise payback.
     * @param optType option's type
     * @param strikePrice option's strikePrice
     * @param underlyingPrice underlying's price
     */
    function _getOptionsPayback(uint8 optType,uint256 strikePrice,uint256 underlyingPrice)internal pure returns(uint256){
        if ((optType == 0) == (strikePrice>underlyingPrice)){ // call
            return 0;
        } else {
            return (optType == 0) ? underlyingPrice - strikePrice : strikePrice - underlyingPrice;
        }
    }
    /**
     * @dev retrieve option by id, check option's id.
     * @param id option's id
     */
    function _getOptionsById(uint256 id)internal view returns(OptionsInfo storage){
        require(id>0 && id <= allOptions.length,"option id is not exist");
        return allOptions[id-1];
    }

    // /**
    //  * @dev check option's underlying and expiration.
    //  * @param expiration option's expiration
    //  * @param underlying option's underlying
    //  */
    // function buyOptionCheck(uint32 expiration,uint32 underlying)public view{
    //     require(underlyingAssets.isEligibleUint32(underlying) , "underlying is unsupported asset");
    //     require(expirationList.isEligibleUint32(expiration),"expiration value is not supported");
    // }
    /**
     * @dev Implementation of add an eligible expiration into the expirationList.
     * @param expiration new eligible expiration.
     */
    function addExpiration(uint32 expiration)public onlyOwner{
        expirationList.addWhiteListUint32(expiration);
    }
    /**
     * @dev Implementation of revoke an invalid expiration from the expirationList.
     * @param removeExpiration revoked expiration.
     */
    function removeExpirationList(uint32 removeExpiration)public onlyOwner returns(bool) {
        return expirationList.removeWhiteListUint32(removeExpiration);
    }
    /**
     * @dev Implementation of getting the eligible expirationList.
     */
    function getExpirationList()public view returns (uint32[] memory){
        return expirationList;
    }
    /**
     * @dev Implementation of testing whether the input expiration is eligible.
     * @param expiration input expiration for testing.
     */    
    function isEligibleExpiration(uint32 expiration) public view returns (bool){
        return expirationList.isEligibleUint32(expiration);
    }

    /**
     * @dev An auxiliary function, retrieve first available option's positon.
     * @param begin  the start of option's positon
     * @param latestBegin  the latest begin option positon.
     * @param end  the end of option's positon
     */
    function getFirstOption(uint256 begin,uint256 latestBegin,uint256 end) internal view returns(uint256,uint256){
        uint256 newFirstOption = latestBegin;
        if (begin > newFirstOption){
            //if in other phase, begin != new begin
            return (begin,newFirstOption);
        }
        begin = newFirstOption;
        for (;begin<end;begin++){
            OptionsInfo storage info = allOptions[begin];
            if(info.createTime+info.expiration<now || info.amount == 0){
                continue;
            }
            break;
        }
        //if in first phase, begin = new begin
        return (begin,begin);
    }
    /**
     * @dev calculate option's occupied collateral.
     * @param option  option's information
     * @param underlyingPrice  underlying current price.
     */
    function calOptionsCollateral(OptionsInfo memory option,uint256 underlyingPrice)internal view returns(uint256){
        uint256 amount = option.amount;
        if (option.createTime+option.expiration<=now || amount == 0){
            return 0;
        }
        uint256 totalOccupied = _getOptionsWorth(option.optType,option.strikePrice,underlyingPrice)*amount;
        require(totalOccupied<=1e40,"Option collateral occupied calculate error");
        return totalOccupied;
    }
    /**
     * @dev calculate one option's occupied collateral.
     * @param optType  option's type
     * @param strikePrice  option's strikePrice
     * @param underlyingPrice  underlying current price.
     */
    function _getOptionsWorth(uint8 optType,uint256 strikePrice,uint256 underlyingPrice)internal pure returns(uint256){
        if ((optType == 0) == (strikePrice>underlyingPrice)){ // call
            return strikePrice;
        } else {
            return underlyingPrice;
        }
    }
    /**
     * @dev calculate `amount` number of Option's full price when option is burned.
     * @param optionID  option's optionID
     * @param amount  option's amount
     */
    function getBurnedFullPay(uint256 optionID,uint256 amount) Smaller(amount) public view returns(address,uint256){
        OptionsInfo memory info = _getOptionsById(optionID);
        return (info.settlement,info.optionsPrice*amount/info.settlePrice);
    }
}

// File: contracts\OptionsPool\OptionsOccupiedCal.sol

pragma solidity =0.5.16;

/**
 * @title Options collateral occupied calculation contract for finnexus proposal v2.
 * @dev A Smart-contract for collateral occupied calculation.
 *
 */
contract OptionsOccupiedCal is OptionsBase {

    /**
     * @dev retrieve collateral occupied calculation information.
     */    
    function getOccupiedCalInfo()public view returns(uint256,int256,int256){
        return (occupiedFirstOption,callLatestOccupied,putLatestOccupied);
    }
    /**
     * @dev calculate collateral occupied value, and modify database, only foundation operator can modify database.
     */  
    function setOccupiedCollateral() public onlyOperatorIndex(1) {
        int256 latestCallOccupied = callLatestOccupied;
        int256 latestPutOccupied = putLatestOccupied;
        uint256 lastOption = allOptions.length;
        (uint256 totalCallOccupied,uint256 totalPutOccupied,uint256 beginOption,bool success) = calculatePhaseOccupiedCollateral(lastOption, occupiedFirstOption,lastOption);
        if (success){
            setCollateralPhase(totalCallOccupied,totalPutOccupied,beginOption,latestCallOccupied,latestPutOccupied);
        }
    }
    /**
     * @dev calculate collateral occupied value.
     * @param lastOption last option's position.
     * @param beginOption begin option's poisiton.
     * @param endOption end option's poisiton.
     */  
    function calculatePhaseOccupiedCollateral(uint256 lastOption,uint256 beginOption,uint256 endOption) public view returns(uint256,uint256,uint256,bool){
        if (beginOption <  occupiedFirstOption){
            beginOption =  occupiedFirstOption;
        }
        if (beginOption>=lastOption){
            return (0,0,0,false);
        }
        if (endOption>lastOption) {
            endOption = lastOption;
        }else if(endOption <  occupiedFirstOption){
            return (0,0,0,false);
        }
        (uint256 totalCallOccupied,uint256 totalPutOccupied,uint256 newFirstOption) = _calculateOccupiedCollateral(beginOption,endOption);
        return (totalCallOccupied,totalPutOccupied,newFirstOption,true);
    }
    /**
     * @dev subfunction, calculate collateral occupied value.
     * @param begin begin option's poisiton.
     * @param end end option's poisiton.
     */  
    function _calculateOccupiedCollateral(uint256 begin,uint256 end)internal view returns(uint256,uint256,uint256){
        uint256 newFirstOption;
        (begin,newFirstOption) = getFirstOption(begin, occupiedFirstOption,end);
        uint256[] memory prices = getUnderlyingPrices();
        uint256 totalCallOccupied = 0;
        uint256 totalPutOccupied = 0;
        for (;begin<end;begin++){
            uint256 index = _getEligibleUnderlyingIndex(allOptions[begin].underlying);
            uint256 value = calOptionsCollateral(allOptions[begin],prices[index]);
            if (allOptions[begin].optType == 0){
                totalCallOccupied += value;
            }else{
                totalPutOccupied += value;
            }
        }
        return (totalCallOccupied,totalPutOccupied,newFirstOption);
    }
    /**
     * @dev set collateral occupied value, only foundation operator can modify database.
     * @param totalCallOccupied new call options occupied collateral calculation result.
     * @param totalPutOccupied new put options occupied collateral calculation result.
     * @param beginOption new first valid option's positon.
     * @param latestCallOccpied latest call options' occupied value when operater invoke collateral occupied calculation.
     * @param latestPutOccpied latest put options' occupied value when operater invoke collateral occupied calculation.
     */  
    function setCollateralPhase(uint256 totalCallOccupied,uint256 totalPutOccupied,uint256 beginOption,
            int256 latestCallOccpied,int256 latestPutOccpied) public onlyOperatorIndex(1){
        require(beginOption <= allOptions.length, "beginOption calculate Error");
        if (beginOption >  occupiedFirstOption){
             occupiedFirstOption = beginOption;
        }
        callOccupied = totalCallOccupied;
        putOccupied = totalPutOccupied;
        require(latestCallOccpied>=-1e40 && latestCallOccpied<=1e40,"options fall calculate error");
        require(latestPutOccpied>=-1e40 && latestPutOccpied<=1e40,"options fall calculate error");
        callLatestOccupied -= latestCallOccpied;
        putLatestOccupied -= latestPutOccpied;
    }
    /**
     * @dev get real total collateral occupied value.
     */ 
    function getAllTotalOccupiedCollateral() public view returns (uint256,uint256) {
        return (getCallTotalOccupiedCollateral(),getPutTotalOccupiedCollateral());
    }
    /**
     * @dev get call options total collateral occupied value.
     */ 
    function getCallTotalOccupiedCollateral() public view returns (uint256) {
        if (callLatestOccupied>=0){
            uint256 result = callOccupied+uint256(callLatestOccupied);
            require(result>=callOccupied,"TotalOccupiedCollateral calculate overflow");
            return result;
        }else{
            uint256 latestOccupied = uint256(-callLatestOccupied);
            if (callOccupied>latestOccupied){
                return callOccupied - latestOccupied;
            }else{
                return 0;
            }
        }
    }
        /**
     * @dev get put options total collateral occupied value.
     */ 
    function getPutTotalOccupiedCollateral() public view returns (uint256) {
        if (putLatestOccupied>=0){
            uint256 result = putOccupied+uint256(putLatestOccupied);
            require(result>=putOccupied,"TotalOccupiedCollateral calculate overflow");
            return result;
        }else{
            uint256 latestOccupied = uint256(-putLatestOccupied);
            if (putOccupied>latestOccupied){
                return putOccupied - latestOccupied;
            }else{
                return 0;
            }
        }
    }
    /**
     * @dev get real total collateral occupied value.
     */ 
    function getTotalOccupiedCollateral() public view returns (uint256) {
        return getCallTotalOccupiedCollateral() + getPutTotalOccupiedCollateral();
    }
//     /**
//      * @dev add new option collateral occupied value when user create a new option.
//      * @param optionID new option's ID.
//      */ 
//     function _addOptionsCollateral(uint256 optionID) internal {
//         OptionsInfo memory info = allOptions[optionID-1];
// //        OptionsInfoEx storage infoEx =  optionExtraMap[optionID-1];
//         uint256 newOccupied = calOptionsCollateral(info,(info.strikePrice*info.priceRate)>>28);
//         if (info.optType == 0){
//             callLatestOccupied += int256(newOccupied);
//         }else{
//             putLatestOccupied += int256(newOccupied);
//         }
//     }
    /**
     * @dev deduct burned option collateral occupied value when user burn option.
     * @param info burned option's information.
     * @param amount burned option's amount.
     * @param underlyingPrice current underlying price.
     */ 
    function _burnOptionsCollateral(OptionsInfo memory info,uint256 amount,uint256 underlyingPrice) internal {
        uint256 newOccupied = _getOptionsWorth(info.optType,info.strikePrice,underlyingPrice)*amount;
        require(newOccupied<=1e40,"Option collateral occupied calculate error");
        if (info.optType == 0){
            callLatestOccupied -= int256(newOccupied);
        }else{
            putLatestOccupied -= int256(newOccupied);
        }
    }

}

// File: contracts\OptionsPool\OptionsNetWorthCal.sol

pragma solidity =0.5.16;

/**
 * @title Options net worth calculation contract for finnexus proposal v2.
 * @dev A Smart-contract for net worth calculation.
 *
 */
contract OptionsNetWorthCal is OptionsOccupiedCal {
    /**
     * @dev retrieve all information for net worth calculation. 
     * @param whiteList collateral address whitelist.
     */ 
    function getNetWrothCalInfo(address[] memory whiteList)public view returns(uint256,int256[] memory){
        uint256 len = whiteList.length;
        int256[] memory latestNetWorth = new int256[](len);
            for (uint256 i = 0;i<len;i++){
            latestNetWorth[i] = optionsLatestNetWorth[whiteList[i]];
        }
        return ( netWorthirstOption,latestNetWorth);
    }
    /**
     * @dev retrieve latest options net worth which paid in settlement coin. 
     * @param settlement settlement coin address.
     */ 
    function getNetWrothLatestWorth(address settlement)public view returns(int256){
        return optionsLatestNetWorth[settlement];
    }
    /**
     * @dev set latest options net worth balance, only manager contract can modify database.
     * @param newFirstOption new first valid option position.
     * @param latestNetWorth latest options net worth.
     * @param whiteList eligible collateral address white list.
     */ 
    function setSharedState(uint256 newFirstOption,int256[] memory latestNetWorth,address[] memory whiteList) public onlyOperatorIndex(0){
        require(newFirstOption <= allOptions.length, "newFirstOption calculate Error");
        if (newFirstOption >  netWorthirstOption){
             netWorthirstOption = newFirstOption;
        }
        uint256 len = whiteList.length;
        for (uint256 i = 0;i<len;i++){
            require(latestNetWorth[i]>=-1e40 && latestNetWorth[i]<=1e40,"latestNetWorth calculate error");
            optionsLatestNetWorth[whiteList[i]] += latestNetWorth[i];
        }
    }
    /**
     * @dev calculate options time shared value,from begin to end in the alloptionsList.
     * @param lastOption the last option position.
     * @param begin the begin options position.
     * @param end the end options position.
     * @param whiteList eligible collateral address white list.
     */
    function calRangeSharedPayment(uint256 lastOption,uint256 begin,uint256 end,address[] memory whiteList)
            public view returns(int256[] memory,uint256[] memory,uint256){
        if (begin>=lastOption || end <  netWorthirstOption){
            return(new int256[](whiteList.length),new uint256[](whiteList.length),0);
        }
        if (end>lastOption) {
            end = lastOption;
        }
        (uint256[] memory sharedBalances,uint256 _firstOption) = _calculateSharedPayment(begin,end,whiteList);
        if (begin < _firstOption){
            int256[] memory newNetworth = calculateExpiredPayment(begin,_firstOption,whiteList);
            return (newNetworth,sharedBalances,_firstOption);
        }
        
        return (new int256[](whiteList.length),sharedBalances,_firstOption);
    }
    /**
     * @dev subfunction, calculate options time shared value,from begin to end in the alloptionsList.
     * @param begin the begin options position.
     * @param end the end options position.
     * @param whiteList eligible collateral address white list.
     */
    function _calculateSharedPayment(uint256 begin,uint256 end,address[] memory whiteList)
            internal view returns(uint256[] memory,uint256){
        uint256[] memory totalSharedPayment = new uint256[](whiteList.length);
        uint256 newFirstOption;
        (begin,newFirstOption) = getFirstOption(begin, netWorthirstOption,end); 
        for (;begin<end;begin++){
            OptionsInfo storage info = allOptions[begin];
            uint256 timeValue = _calculateCurrentPrice((info.strikePrice*info.priceRate)>>28,info.optionsPrice,
                info.createTime+info.expiration,info.iv,info.optType);
            if (timeValue<info.optionsPrice){
                timeValue = info.optionsPrice - timeValue;
                uint256 index = whiteListAddress._getEligibleIndexAddress(whiteList,info.settlement);
                timeValue = timeValue*info.amount/info.settlePrice;
                require(timeValue<=1e40,"option time shared value calculate error");
                totalSharedPayment[index] = totalSharedPayment[index]+timeValue;
            }
        }
        return (totalSharedPayment,newFirstOption);
    }
    /**
     * @dev subfunction, calculate expired options shared value,from begin to end in the alloptionsList.
     * @param begin the begin options position.
     * @param end the end options position.
     * @param whiteList eligible collateral address white list.
     */
    function calculateExpiredPayment(uint256 begin,uint256 end,address[] memory whiteList)internal view returns(int256[] memory){
        int256[] memory totalExpiredPayment = new int256[](whiteList.length);
        for (;begin<end;begin++){
            OptionsInfo storage info = allOptions[begin];
            uint256 amount = info.amount;
            if (amount>0){
                uint256 index = whiteListAddress._getEligibleIndexAddress(whiteList,info.settlement);
                uint256 timeValue = info.optionsPrice*amount/info.settlePrice;
                require(timeValue<=1e40,"option time shared value calculate error");
                totalExpiredPayment[index] = totalExpiredPayment[index]+int256(timeValue);
            }
        }
        return totalExpiredPayment;
    }
    /**
     * @dev calculate options payback fall value,from begin to end in the alloptionsList.
     * @param lastOption the last option position.
     * @param begin the begin options position.
     * @param end the end options position.
     * @param whiteList eligible collateral address white list.
     */
    function calculatePhaseOptionsFall(uint256 lastOption,uint256 begin,uint256 end,address[] memory whiteList) public view returns(int256[] memory){
        if (begin>=lastOption || end <  netWorthirstOption){
            return new int256[](whiteList.length);
        }
        if (end>lastOption) {
            end = lastOption;
        }
        if (begin <=  netWorthirstOption) {
            begin =  netWorthirstOption;
        }
        uint256[] memory prices = getUnderlyingPrices();
        int256[] memory OptionsFallBalances = _calRangeOptionsFall(begin,end,whiteList,prices);
        uint256 whiteListLen = whiteList.length;
        for (uint256 index = 0;index<whiteListLen;index++){
            OptionsFallBalances[index] = OptionsFallBalances[index]/(int256(oraclePrice(whiteList[index])));
        }
        return OptionsFallBalances;
    }
    /**
     * @dev subfunction, calculate options payback fall value,from begin to lastOption in the alloptionsList.
     * @param begin the begin option position.
     * @param lastOption the last option position.
     * @param whiteList eligible collateral address white list.
     * @param prices eligible underlying price list.
     */
    function _calRangeOptionsFall(uint256 begin,uint256 lastOption,address[] memory whiteList,uint256[] memory prices)
                 internal view returns(int256[] memory){
        int256[] memory OptionsFallBalances = new int256[](whiteList.length);
        for (;begin<lastOption;begin++){
            OptionsInfo storage info = allOptions[begin];
            uint256 amount = info.amount;
            if(info.createTime + info.expiration<now || amount == 0){
                continue;
            }
            uint256 index = _getEligibleUnderlyingIndex(info.underlying);
            int256 curValue = _calCurtimeCallateralFall(info,amount,prices[index]);
            if (curValue != 0){
                index = whiteListAddress._getEligibleIndexAddress(whiteList,info.settlement);
                OptionsFallBalances[index] = OptionsFallBalances[index]-curValue;
            }
        }
        return OptionsFallBalances;
    }
    /**
     * @dev subfunction, calculate option payback fall value.
     * @param info the option information.
     * @param amount the option amount to calculate.
     * @param curPrice current underlying price.
     */
    function _calCurtimeCallateralFall(OptionsInfo memory info,uint256 amount,uint256 curPrice) internal view returns(int256){
        if (info.createTime + info.expiration<=now || amount == 0){
            return 0;
        }
        uint256 newFall = _getOptionsPayback(info.optType,info.optionsPrice,curPrice)*amount;
        uint256 OriginFall = _getOptionsPayback(info.optType,info.optionsPrice,(info.strikePrice*info.priceRate)>>28)*amount;
        int256 curValue = int256(newFall) - int256(OriginFall);
        require(curValue>=-1e40 && curValue<=1e40,"options fall calculate error");
        return curValue;
    }
    /*
    function _addNewOptionsNetworth(OptionsInfo memory info)  internal {
        OptionsInfoEx storage infoEx =  optionExtraMap[info.optionID-1];
        uint256 price = oraclePrice(info.underlying);
        uint256 curValue = _calCurtimeCallateralFall(info,getOptionAmount(info),(info.strikePrice*info.priceRate)>>28)/price;
        optionsLatestNetWorth[nfo.underlying] = optionsLatestNetWorth[nfo.underlying].sub(int256(curValue));
    }
    */
    /**
     * @dev set burn option net worth change.
     * @param info the option information.
     * @param amount the option amount to calculate.
     * @param underlyingPrice underlying price when option is created.
     * @param currentPrice current underlying price.
     */
    function _burnOptionsNetworth(OptionsInfo memory info,uint256 amount,uint256 underlyingPrice,uint256 currentPrice) internal {
        int256 curValue = _calCurtimeCallateralFall(info,amount,underlyingPrice);
        uint256 timeWorth = info.optionsPrice>currentPrice ? info.optionsPrice-currentPrice : 0;
        timeWorth = timeWorth*amount/info.settlePrice;
        address settlement = info.settlement;
        curValue = curValue / int256(oraclePrice(settlement));
        int256 value = curValue - int256(timeWorth);
        optionsLatestNetWorth[settlement] = optionsLatestNetWorth[settlement]+value;
    }
    /**
     * @dev An anxiliary function, calculate time shared current option price.
     * @param curprice underlying price when option is created.
     * @param strikePrice the option strikePrice.
     * @param expiration option time expiration time left, equal option.expiration - now.
     * @param ivNumerator Implied valotility numerator when option is created.
     */
    function _calculateCurrentPrice(uint256 curprice,uint256 strikePrice,uint256 expiration,uint256 ivNumerator,uint8 optType)internal view returns (uint256){
        if (expiration > now){
            return _optionsPrice.getOptionsPrice_iv(curprice,strikePrice,expiration-now,ivNumerator,
                optType);
        }
        return 0;
    }
}

// File: contracts\OptionsPool\OptionsPool.sol

pragma solidity =0.5.16;

/**
 * @title Options pool contract.
 * @dev store options' information and nessesary options' calculation.
 *
 */
contract OptionsPool is OptionsNetWorthCal {
    /**
     * @dev constructor function , setting contract address.
     * @param oracleAddr FNX oracle contract address
     * @param optionsPriceAddr options price contract address
     * @param ivAddress implied volatility contract address
     */  
    constructor (address oracleAddr,address optionsPriceAddr,address ivAddress)public{
        _oracle = IFNXOracle(oracleAddr);
        _optionsPrice = IOptionsPrice(optionsPriceAddr);
        _volatility = IVolatility(ivAddress);
    }
    function update() onlyOwner public {

    }
    /**
     * @dev retrieve all information for collateral occupied and net worth calculation.
     * @param whiteList settlement address whitelist.
     */ 
    function getOptionCalRangeAll(address[] memory whiteList)public view returns(uint256,int256,int256,uint256,int256[] memory,uint256,uint256){
        (uint256 occupiedFirst,int256 callOccupiedlatest,int256 putOccupiedlatest) = getOccupiedCalInfo();
        (uint256 netFirst,int256[] memory netLatest) = getNetWrothCalInfo(whiteList);
        return (occupiedFirst,callOccupiedlatest,putOccupiedlatest,netFirst,netLatest,allOptions.length,block.number);
    }
    /**
     * @dev create new option,modify collateral occupied and net worth value, only manager contract can invoke this.
     * @param from user's address.
     * @param type_ly_expiration tuple64 for option type,underlying,expiration.
     * @param strikePrice user's input new option's strike price.
     * @param underlyingPrice current new option's price, calculated by options price contract.
     * @param amount user's input new option's amount.
     */ 
    function createOptions(address from,address settlement,uint256 type_ly_expiration,
        uint128 strikePrice,uint128 underlyingPrice,uint128 amount,uint128 settlePrice) onlyManager public returns(uint256){
        uint256 price = _createOptions(from,settlement,type_ly_expiration,strikePrice,underlyingPrice,amount,settlePrice);
        uint256 totalOccupied = _getOptionsWorth(uint8(type_ly_expiration),strikePrice,underlyingPrice)*amount;
        require(totalOccupied<=1e40,"Option collateral occupied calculate error");
        if (uint8(type_ly_expiration) == 0){
            callLatestOccupied += int256(totalOccupied);
        }else{
            putLatestOccupied += int256(totalOccupied);
        }
        //_addOptionsCollateral(allOptions.length);
        return price;
//        _addNewOptionsNetworth(info);
    }
    /**
     * @dev burn option,modify collateral occupied and net worth value, only manager contract can invoke this.
     * @param from user's address.
     * @param id user's input option's id.
     * @param amount user's input burned option's amount.
     * @param optionPrice current new option's price, calculated by options price contract.
     */ 
    function burnOptions(address from,uint256 id,uint256 amount,uint256 optionPrice)public onlyManager Smaller(amount) OutLimitation(id){
        OptionsInfo memory info = _getOptionsById(id);
        _burnOptions(from,id,info,amount);
        uint256 currentPrice = oracleUnderlyingPrice(info.underlying);
        _burnOptionsCollateral(info,amount,currentPrice);
        _burnOptionsNetworth(info,amount,currentPrice,optionPrice);
    }
        modifier OutLimitation(uint256 id) {
        require(allOptions[id-1].createTime+limitation<now,"Time limitation is not expired!");
        _;
    }   
}