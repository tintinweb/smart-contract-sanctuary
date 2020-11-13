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

// File: contracts\Proxy\baseProxy.sol

pragma solidity =0.5.16;

/**
 * @title  baseProxy Contract

 */
contract baseProxy is Ownable {
    address public implementation;
    constructor(address implementation_) public {
        // Creator of the contract is admin during initialization
        implementation = implementation_; 
        (bool success,) = implementation_.delegatecall(abi.encodeWithSignature("initialize()"));
        require(success);
    }
    function getImplementation()public view returns(address){
        return implementation;
    }
    function setImplementation(address implementation_)public onlyOwner{
        implementation = implementation_; 
        (bool success,) = implementation_.delegatecall(abi.encodeWithSignature("update()"));
        require(success);
    }

    /**
     * @notice Delegates execution to the implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateToImplementation(bytes memory data) public returns (bytes memory) {
        (bool success, bytes memory returnData) = implementation.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize)
            }
        }
        return returnData;
    }

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     *  There are an additional 2 prefix uints from the wrapper returndata, which we ignore since we make an extra hop.
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateToViewImplementation(bytes memory data) public view returns (bytes memory) {
        (bool success, bytes memory returnData) = address(this).staticcall(abi.encodeWithSignature("delegateToImplementation(bytes)", data));
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize)
            }
        }
        return abi.decode(returnData, (bytes));
    }

    function delegateToViewAndReturn() internal view returns (bytes memory) {
        (bool success, ) = address(this).staticcall(abi.encodeWithSignature("delegateToImplementation(bytes)", msg.data));

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize)

            switch success
            case 0 { revert(free_mem_ptr, returndatasize) }
            default { return(add(free_mem_ptr, 0x40), returndatasize) }
        }
    }

    function delegateAndReturn() internal returns (bytes memory) {
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize)

            switch success
            case 0 { revert(free_mem_ptr, returndatasize) }
            default { return(free_mem_ptr, returndatasize) }
        }
    }
}

// File: contracts\OptionsPool\OptionsProxy.sol

pragma solidity =0.5.16;


/**
 * @title  Erc20Delegator Contract

 */
contract OptionsProxy is OptionsData,baseProxy{
        /**
     * @dev constructor function , setting contract address.
     *  oracleAddr FNX oracle contract address
     *  optionsPriceAddr options price contract address
     *  ivAddress implied volatility contract address
     */  

    constructor(address implementation_,address oracleAddr,address optionsPriceAddr,address ivAddress)
         baseProxy(implementation_) public  {
        _oracle = IFNXOracle(oracleAddr);
        _optionsPrice = IOptionsPrice(optionsPriceAddr);
        _volatility = IVolatility(ivAddress);
    }
    function setTimeLimitation(uint256 /*_limit*/)public{
        delegateAndReturn();
    }
    function getTimeLimitation()public view returns(uint256){
        delegateToViewAndReturn();
    }
    
    /**
     * @dev retrieve user's options' id. 
     *  user user's account.
     */     
    function getUserOptionsID(address /*user*/)public view returns(uint64[] memory){
        delegateToViewAndReturn();
    }
    /**
     * @dev retrieve user's `size` number of options' id. 
     *  user user's account.
     *  from user's option list begin positon.
     *  size retrieve size.
     */ 
    function getUserOptionsID(address /*user*/,uint256 /*from*/,uint256 /*size*/)public view returns(uint64[] memory){
        delegateToViewAndReturn();
    }
    /**
     * @dev retrieve all option list length. 
     */ 
    function getOptionInfoLength()public view returns (uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev retrieve `size` number of options' information. 
     *  from all option list begin positon.
     *  size retrieve size.
     */     
    function getOptionInfoList(uint256 /*from*/,uint256 /*size*/)public view 
                returns(address[] memory,uint256[] memory,uint256[] memory,uint256[] memory,uint256[] memory){
        delegateToViewAndReturn();
    }
    /**
     * @dev retrieve given `ids` options' information. 
     *  ids retrieved options' id.
     */   
    function getOptionInfoListFromID(uint256[] memory /*ids*/)public view 
                returns(address[] memory,uint256[] memory,uint256[] memory,uint256[] memory,uint256[] memory){
        delegateToViewAndReturn();
    }
    /**
     * @dev retrieve given `optionsId` option's burned limit timestamp. 
     *  optionsId retrieved option's id.
     */ 
    function getOptionsLimitTimeById(uint256 /*optionsId*/)public view returns(uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev retrieve given `optionsId` option's information. 
     *  optionsId retrieved option's id.
     */ 
    function getOptionsById(uint256 /*optionsId*/)public view returns(uint256,address,uint8,uint32,uint256,uint256,uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev retrieve given `optionsId` option's extra information. 
     *  optionsId retrieved option's id.
     */
    function getOptionsExtraById(uint256 /*optionsId*/)public view returns(address,uint256,uint256,uint256,uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev calculate option's exercise worth.
     *  optionsId option's id
     *  amount option's amount
     */
    function getExerciseWorth(uint256 /*optionsId*/,uint256 /*amount*/)public view returns(uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev check option's underlying and expiration.
     *  expiration option's expiration
     *  underlying option's underlying
     */
    // function buyOptionCheck(uint32 /*expiration*/,uint32 /*underlying*/)public view{
    //     delegateToViewAndReturn();
    // }
    /**
     * @dev Implementation of add an eligible expiration into the expirationList.
     *  expiration new eligible expiration.
     */
    function addExpiration(uint32 /*expiration*/)public{
        delegateAndReturn();
    }
    /**
     * @dev Implementation of revoke an invalid expiration from the expirationList.
     *  removeExpiration revoked expiration.
     */
    function removeExpirationList(uint32 /*removeExpiration*/)public returns(bool) {
        delegateAndReturn();
    }
    /**
     * @dev Implementation of getting the eligible expirationList.
     */
    function getExpirationList()public view returns (uint32[] memory){
        delegateToViewAndReturn();
    }
    /**
     * @dev Implementation of testing whether the input expiration is eligible.
     *  expiration input expiration for testing.
     */    
    function isEligibleExpiration(uint256 /*expiration*/) public view returns (bool){
        delegateToViewAndReturn();
    }
    /**
     * @dev check option's expiration.
     *  expiration option's expiration
     */
    function checkExpiration(uint256 /*expiration*/) public view{
        delegateToViewAndReturn();
    }
    /**
     * @dev calculate `amount` number of Option's full price when option is burned.
     *  optionID  option's optionID
     *  amount  option's amount
     */
    function getBurnedFullPay(uint256 /*optionID*/,uint256 /*amount*/) public view returns(address,uint256){
        delegateToViewAndReturn();
    }
        /**
     * @dev retrieve collateral occupied calculation information.
     */    
    function getOccupiedCalInfo()public view returns(uint256,int256,int256){
        delegateToViewAndReturn();
    }
    /**
     * @dev calculate collateral occupied value, and modify database, only foundation operator can modify database.
     */  
    function setOccupiedCollateral() public {
        delegateAndReturn();
    }
    /**
     * @dev calculate collateral occupied value.
     *  lastOption last option's position.
     *  beginOption begin option's poisiton.
     *  endOption end option's poisiton.
     */  
    function calculatePhaseOccupiedCollateral(uint256 /*lastOption*/,uint256 /*beginOption*/,uint256 /*endOption*/) public view returns(uint256,uint256,uint256,bool){
        delegateToViewAndReturn();
    }
 
    /**
     * @dev set collateral occupied value, only foundation operator can modify database.
     * totalCallOccupied new call options occupied collateral calculation result.
     * totalPutOccupied new put options occupied collateral calculation result.
     * beginOption new first valid option's positon.
     * latestCallOccpied latest call options' occupied value when operater invoke collateral occupied calculation.
     * latestPutOccpied latest put options' occupied value when operater invoke collateral occupied calculation.
     */  
    function setCollateralPhase(uint256 /*totalCallOccupied*/,uint256 /*totalPutOccupied*/,
        uint256 /*beginOption*/,int256 /*latestCallOccpied*/,int256 /*latestPutOccpied*/) public{
        delegateAndReturn();
    }
    function getAllTotalOccupiedCollateral() public view returns (uint256,uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev get call options total collateral occupied value.
     */ 
    function getCallTotalOccupiedCollateral() public view returns (uint256) {
        delegateToViewAndReturn();
    }
    /**
     * @dev get put options total collateral occupied value.
     */ 
    function getPutTotalOccupiedCollateral() public view returns (uint256) {
        delegateToViewAndReturn();
    }
    /**
     * @dev get real total collateral occupied value.
     */ 
    function getTotalOccupiedCollateral() public view returns (uint256) {
        delegateToViewAndReturn();
    }
    /**
     * @dev retrieve all information for net worth calculation. 
     *  whiteList collateral address whitelist.
     */ 
    function getNetWrothCalInfo(address[] memory /*whiteList*/)public view returns(uint256,int256[] memory){
        delegateToViewAndReturn();
    }
    /**
     * @dev retrieve latest options net worth which paid in settlement coin. 
     *  settlement settlement coin address.
     */ 
    function getNetWrothLatestWorth(address /*settlement*/)public view returns(int256){
        delegateToViewAndReturn();
    }
    /**
     * @dev set latest options net worth balance, only manager contract can modify database.
     *  newFirstOption new first valid option position.
     *  latestNetWorth latest options net worth.
     *  whiteList eligible collateral address white list.
     */ 
    function setSharedState(uint256 /*newFirstOption*/,int256[] memory /*latestNetWorth*/,address[] memory /*whiteList*/) public{
        delegateAndReturn();
    }
    /**
     * @dev calculate options time shared value,from begin to end in the alloptionsList.
     *  lastOption the last option position.
     *  begin the begin options position.
     *  end the end options position.
     *  whiteList eligible collateral address white list.
     */
    function calRangeSharedPayment(uint256 /*lastOption*/,uint256 /*begin*/,uint256 /*end*/,address[] memory /*whiteList*/)
            public view returns(int256[] memory,uint256[] memory,uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev calculate options payback fall value,from begin to end in the alloptionsList.
     *  lastOption the last option position.
     *  begin the begin options position.
     *  end the end options position.
     *  whiteList eligible collateral address white list.
     */
    function calculatePhaseOptionsFall(uint256 /*lastOption*/,uint256 /*begin*/,uint256 /*end*/,address[] memory /*whiteList*/) public view returns(int256[] memory){
        delegateToViewAndReturn();
    }

    /**
     * @dev retrieve all information for collateral occupied and net worth calculation.
     *  whiteList settlement address whitelist.
     */ 
    function getOptionCalRangeAll(address[] memory /*whiteList*/)public view returns(uint256,int256,int256,uint256,int256[] memory,uint256,uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev create new option,modify collateral occupied and net worth value, only manager contract can invoke this.
     *  from user's address.
     *  settlement user's input settlement coin.
     *  type_ly_exp tuple64 for option type,underlying,expiration.
     *  strikePrice user's input new option's strike price.
     *  optionPrice current new option's price, calculated by options price contract.
     *  amount user's input new option's amount.
     */ 
    function createOptions(address /*from*/,address /*settlement*/,uint256 /*type_ly_exp*/,
    uint128 /*strikePrice*/,uint128 /*underlyingPrice*/,uint128 /*amount*/,uint128 /*settlePrice*/) public returns(uint256) {
        delegateAndReturn();
    }
    /**
     * @dev burn option,modify collateral occupied and net worth value, only manager contract can invoke this.
     *  from user's address.
     *  id user's input option's id.
     *  amount user's input burned option's amount.
     *  optionPrice current new option's price, calculated by options price contract.
     */ 
    function burnOptions(address /*from*/,uint256 /*id*/,uint256 /*amount*/,uint256 /*optionPrice*/)public{
        delegateAndReturn();
    }
    function getUserAllOptionInfo(address /*user*/)public view 
        returns(address[] memory,uint256[] memory,uint256[] memory,uint256[] memory,uint256[] memory){
        delegateToViewAndReturn();
    }
}