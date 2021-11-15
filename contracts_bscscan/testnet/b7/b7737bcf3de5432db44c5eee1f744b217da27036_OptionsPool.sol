pragma solidity =0.5.16;

import "../PhoenixModules/proxyModules/versionUpdater.sol";
import "../PhoenixModules/proxyModules/ImputRange.sol";
import "../PhoenixModules/interface/IPHXOracle.sol";
import "../interfaces/IVolatility.sol";
import "../interfaces/IOptionsPrice.sol";
import "../PhoenixModules/proxyModules/proxyOperator.sol";
contract OptionsData is versionUpdater,proxyOperator,ImputRange,ImportOracle{
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
    struct underlyingOccupied {
        //latest calcutated Options Occupied value.
        uint256 callOccupied;
        uint256 putOccupied;
        //latest Options volatile occupied value when bought or selled options.
        int256 callLatestOccupied;
        int256 putLatestOccupied;
    }
    uint256 constant internal currentVersion = 1;
    function implementationVersion() public pure returns (uint256) 
    {
        return currentVersion;
    }
    IVolatility public volatility;
    IOptionsPrice public optionsPrice;
    uint32[] public underlyingAssets;
    uint256 public limitation;
    //all options information list
    OptionsInfo[] public allOptions;
    //user options balances
    mapping(address=>uint64[]) public optionsBalances;
    //expiration whitelist
    uint32[] public expirationList;
    
    // first option position which is needed calculate.
    uint256 public netWorthFirstOption;
    // options latest networth balance. store all options's net worth share started from first option.
    mapping(address=>int256) public optionsLatestNetWorth;

    // first option position which is needed calculate.
    uint256 internal occupiedFirstOption; 
    mapping(uint32=>underlyingOccupied) public underlyingOccupiedMap;
    uint256 public underlyingTotalOccupied;
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
}

pragma solidity =0.5.16;
import "./Optionsbase.sol";
/**
 * @title Options pool contract.
 * @dev store options' information and nessesary options' calculation.
 *
 */
contract OptionsPool is OptionsBase {
    constructor (address multiSignatureClient)public proxyOwner(multiSignatureClient) {
    }
    function initialize() public{
        versionUpdater.initialize();
        expirationList =  [1 days,2 days,3 days, 7 days, 10 days, 15 days,20 days, 30 days/*,90 days*/];
        limitation = 1 hours;
        maxAmount = 1e30;
        minAmount = 1e2;
    } 
    function initAddresses(address optionsCalAddr,address oracleAddr,address optionsPriceAddr,address ivAddress,uint32[] calldata underlyings)external onlyOwner {
        setOptionsNetWorthCal(optionsCalAddr);
        _oracle = IPHXOracle(oracleAddr);
        optionsPrice = IOptionsPrice(optionsPriceAddr);
        volatility = IVolatility(ivAddress);
        underlyingAssets = underlyings;
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
        uint256 totalOccupied = _getOptionsWorth(uint8(type_ly_expiration),strikePrice,underlyingPrice,amount);
        require(totalOccupied<=1e40,"Option collateral occupied calculate error");
        if (uint8(type_ly_expiration) == 0){
            underlyingOccupiedMap[uint32(type_ly_expiration>>64)].callLatestOccupied += int256(totalOccupied);
        }else{
            underlyingOccupiedMap[uint32(type_ly_expiration>>64)].putLatestOccupied += int256(totalOccupied);
        }
        underlyingTotalOccupied += totalOccupied;
        return price;
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
    /**
     * @dev deduct burned option collateral occupied value when user burn option.
     * @param info burned option's information.
     * @param amount burned option's amount.
     * @param underlyingPrice current underlying price.
     */ 
    function _burnOptionsCollateral(OptionsInfo memory info,uint256 amount,uint256 underlyingPrice) internal {
        uint256 newOccupied = _getOptionsWorth(info.optType,info.strikePrice,underlyingPrice,amount);
        require(newOccupied<=1e40,"Option collateral occupied calculate error");
        if (info.optType == 0){
            underlyingOccupiedMap[info.underlying].callLatestOccupied -= int256(newOccupied);
        }else{
            underlyingOccupiedMap[info.underlying].putLatestOccupied -= int256(newOccupied);
        }
        underlyingTotalOccupied -= newOccupied;
    }    

        /**
     * @dev calculate one option's occupied collateral.
     * @param optType  option's type, 0 for CALL, 1 for PUT.
     * @param strikePrice  option's strikePrice
     * @param underlyingPrice  underlying current price.
     */
    function _getOptionsWorth(uint8 optType,uint256 strikePrice,uint256 underlyingPrice,uint256 amount)internal pure returns(uint256){
        if ((optType == 0) == (strikePrice>underlyingPrice)){ // call
            return strikePrice*amount;
        } else {
            return underlyingPrice*amount;
        }
    }
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
     * @dev subfunction, calculate option payback fall value.
     * @param info the option information.
     * @param amount the option amount to calculate.
     * @param curPrice current underlying price.
     */
    function _calCurtimeCallateralFall(OptionsInfo memory info,uint256 amount,uint256 curPrice) internal view returns(int256){
        if (info.createTime + info.expiration<=now || amount == 0){
            return 0;
        }
        uint256 newFall = _getOptionsPayback(info.optType,info.optionsPrice,curPrice,amount);
        uint256 OriginFall = _getOptionsPayback(info.optType,info.optionsPrice,(info.strikePrice*info.priceRate)>>28,amount);
        int256 curValue = int256(newFall) - int256(OriginFall);
        require(curValue>=-1e40 && curValue<=1e40,"options fall calculate error");
        return curValue;
    }
    function getOccupiedCalInfo()public view returns(uint256,int256[] memory,int256[] memory){
        delegateToViewAndReturn();
    }
    function getUnderlyingTotalOccupiedCollateral(uint32 /*underlying*/) public view returns (uint256,uint256,uint256){
        delegateToViewAndReturn();
    }
    function getTotalOccupiedCollateral() public view returns (uint256) {
        return underlyingTotalOccupied;
    }
    /**
     * @dev calculate collateral occupied value.
     * param lastOption last option's position.
     * param beginOption begin option's poisiton.
     * param endOption end option's poisiton.
     */  
    function calculatePhaseOccupiedCollateral(uint256 /*lastOption*/,uint256 /*beginOption*/,uint256 /*endOption*/) public view returns(uint256[] memory,uint256[] memory,uint256,bool){
        delegateToViewAndReturn();
    }
    function setOccupiedCollateral() public{
        delegateAndReturn();
    }
    /**
     * @dev retrieve all information for net worth calculation. 
     * param whiteList collateral address whitelist.
     */ 
    function getNetWrothCalInfo(address[] memory /*whiteList*/)public view returns(uint256,int256[] memory){
        delegateToViewAndReturn();
    }
    function getOptionCalRangeAll(address[] memory /*whiteList*/)public view returns(uint256,int256[] memory,int256[] memory,uint256,int256[] memory,uint256,uint256){
        delegateToViewAndReturn();
    }
    function setCollateralPhase(uint256[] calldata /*totalCallOccupied*/,uint256[] calldata /*totalPutOccupied*/,uint256 /*beginOption*/,
            int256[] calldata /*latestCallOccpied*/,int256[] calldata /*latestPutOccpied*/) external{
        delegateAndReturn();
    }
    /**
     * @dev calculate options time shared value,from begin to end in the alloptionsList.
     * param lastOption the last option position.
     * param begin the begin options position.
     * param end the end options position.
     * param whiteList eligible collateral address white list.
     */
    function calRangeSharedPayment(uint256 /*lastOption*/,uint256 /*begin*/,uint256 /*end*/,address[] calldata /*whiteList*/)
            external view returns(int256[] memory,uint256[] memory,uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev calculate options payback fall value,from begin to end in the alloptionsList.
     * param lastOption the last option position.
     * param begin the begin options position.
     * param end the end options position.
     * param whiteList eligible collateral address white list.
     */
    function calculatePhaseOptionsFall(uint256 /*lastOption*/,uint256 /*begin*/,uint256 /*end*/,address[] calldata /*whiteList*/)
         external view returns(int256[] memory){    
         delegateToViewAndReturn();
    }
    function setSharedState(uint256 /*newFirstOption*/,int256[] calldata /*latestNetWorth*/,address[] calldata /*whiteList*/) external {
        delegateAndReturn();
    }
    function delegateToImplementation(bytes memory data) public returns (bytes memory) {
        (bool success, bytes memory returnData) = OptionsNetWorthCal().delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize)
            }
        }
        return returnData;
    }
    function delegateToViewAndReturn() internal view returns (bytes memory) {
        (bool success, ) = address(this).staticcall(abi.encodeWithSignature("delegateToImplementation(bytes)", msg.data));

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize)

            switch success
            case 0 { revert(free_mem_ptr, returndatasize) }
            default { return(add(free_mem_ptr, 0x40), sub(returndatasize, 0x40)) }
        }
    }

    function delegateAndReturn() internal returns (bytes memory) {
        (bool success, ) = OptionsNetWorthCal().delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize)

            switch success
            case 0 { revert(free_mem_ptr, returndatasize) }
            default { return(free_mem_ptr, returndatasize) }
        }
    }
}

pragma solidity =0.5.16;
import "./OptionsData.sol";
import "../PhoenixModules/modules/whiteListUint32.sol";
import "../PhoenixModules/modules/whiteListAddress.sol";
/**
 * @title Options data contract.
 * @dev A Smart-contract to store options info.
 *
 */
contract OptionsBase is OptionsData {
    using whiteListUint32 for uint32[];
    bytes32 private constant optionsNetWorthCalPos = keccak256("org.Phoenix.OptionsNetWorthCal.storage");
    function setOptionsNetWorthCal(address _OptionsCal) public onlyOwner 
    {
        bytes32 position = optionsNetWorthCalPos;
        assembly {
            sstore(position, _OptionsCal)
        }
    }
    function OptionsNetWorthCal() public view returns (address _OptionsCal) {
        bytes32 position = optionsNetWorthCalPos;
        assembly {
            _OptionsCal := sload(position)
        }
    }
    function setVolatilityAddress(address _volatility)public onlyOwner{
        volatility = IVolatility(_volatility);
    }
        /**
     * @dev Implementation of add an eligible underlying into the underlyingAssets.
     * @param underlying new eligible underlying.
     */
    function addUnderlyingAsset(uint32 underlying)public OwnerOrOrigin{
        underlyingAssets.addWhiteListUint32(underlying);
    }
    function setUnderlyingAsset(uint32[] memory underlyings)public OwnerOrOrigin{
        underlyingAssets = underlyings;
    }
    /**
     * @dev Implementation of revoke an invalid underlying from the underlyingAssets.
     * @param removeUnderlying revoked underlying.
     */
    function removeUnderlyingAssets(uint32 removeUnderlying)public OwnerOrOrigin returns(bool) {
        return underlyingAssets.removeWhiteListUint32(removeUnderlying);
    }
    /**
     * @dev Implementation of getting the eligible underlyingAssets.
     */
    function getUnderlyingAssets()public view returns (uint32[] memory){
        return underlyingAssets;
    }
    function setTimeLimitation(uint256 _limit)public OwnerOrOrigin{
        limitation = _limit;
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
        uint256 iv = volatility.calculateIv(uint32(type_ly_expiration>>64),uint8(type_ly_expiration),expiration,
            underlyingPrice,strikePrice); 
        uint256 optPrice = optionsPrice.getOptionsPrice_iv(underlyingPrice,strikePrice,expiration,iv,uint8(type_ly_expiration));
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
        return _getOptionsPayback(info.optType,info.strikePrice,underlyingPrice,amount);
    }
    /**
     * @dev An auxiliary function, calculate option's exercise payback.
     * @param optType option's type,0 for CALL, 1 for PUT.
     * @param strikePrice option's strikePrice
     * @param underlyingPrice underlying's price
     */
    function _getOptionsPayback(uint8 optType,uint256 strikePrice,uint256 underlyingPrice,uint256 amount)internal pure returns(uint256){
        if ((optType == 0) == (strikePrice>underlyingPrice)){ // call
            return 0;
        } else {
            return ((optType == 0) ? underlyingPrice - strikePrice : strikePrice - underlyingPrice)*amount;
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


    /**
     * @dev Implementation of add an eligible expiration into the expirationList.
     * @param expiration new eligible expiration.
     */
    function addExpiration(uint32 expiration)public OwnerOrOrigin{
        expirationList.addWhiteListUint32(expiration);
    }
    /**
     * @dev Implementation of revoke an invalid expiration from the expirationList.
     * @param removeExpiration revoked expiration.
     */
    function removeExpirationList(uint32 removeExpiration)public OwnerOrOrigin returns(bool) {
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
     * @dev calculate `amount` number of Option's full price when option is burned.
     * @param optionID  option's optionID
     * @param amount  option's amount
     */
    function getBurnedFullPay(uint256 optionID,uint256 amount) Smaller(amount) public view returns(address,uint256){
        OptionsInfo storage info = _getOptionsById(optionID);
        return (info.settlement,info.optionsPrice*amount/info.settlePrice);
    }

}

pragma solidity =0.5.16;
import "../proxyModules/proxyOwner.sol";
interface IPHXOracle {
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
contract ImportOracle is proxyOwner{
    IPHXOracle internal _oracle;
    function oraclegetPrices(uint256[] memory assets) internal view returns (uint256[]memory){
        uint256[] memory prices = _oracle.getPrices(assets);
        uint256 len = assets.length;
        for (uint i=0;i<len;i++){
        require(prices[i] >= 100 && prices[i] <= 1e30,"oracle price error");
        }
        return prices;
    }
    function oraclePrice(address asset) internal view returns (uint256){
        uint256 price = _oracle.getPrice(asset);
        require(price >= 100 && price <= 1e30,"oracle price error");
        return price;
    }
    function oracleUnderlyingPrice(uint256 cToken) internal view returns (uint256){
        uint256 price = _oracle.getUnderlyingPrice(cToken);
        require(price >= 100 && price <= 1e30,"oracle price error");
        return price;
    }
    function oracleAssetAndUnderlyingPrice(address asset,uint256 cToken) internal view returns (uint256,uint256){
        (uint256 price1,uint256 price2) = _oracle.getAssetAndUnderlyingPrice(asset,cToken);
        require(price1 >= 100 && price1 <= 1e30,"oracle price error");
        require(price2 >= 100 && price2 <= 1e30,"oracle price error");
        return (price1,price2);
    }
    function getOracleAddress() public view returns(address){
        return address(_oracle);
    }
    function setOracleAddress(address oracle)public onlyOwner{
        _oracle = IPHXOracle(oracle);
    }
}

pragma solidity >=0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */

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

pragma solidity >=0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
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

pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
interface IMultiSignature{
    function getValidSignature(bytes32 msghash,uint256 lastIndex) external view returns(uint256);
}
contract multiSignatureClient{
    uint256 private constant multiSignaturePositon = uint256(keccak256("org.Phoenix.multiSignature.storage"));
    event DebugEvent(address indexed from,bytes32 msgHash,uint256 value,uint256 value1);
    constructor(address multiSignature) public {
        require(multiSignature != address(0),"multiSignatureClient : Multiple signature contract address is zero!");
        saveValue(multiSignaturePositon,uint256(multiSignature));
    }    
    function getMultiSignatureAddress()public view returns (address){
        return address(getValue(multiSignaturePositon));
    }
    modifier validCall(){
        checkMultiSignature();
        _;
    }
    function checkMultiSignature() internal {
        uint256 value;
        assembly {
            value := callvalue()
        }
        bytes32 msgHash = keccak256(abi.encodePacked(msg.sender, address(this),value,msg.data));
        address multiSign = getMultiSignatureAddress();
        uint256 index = getValue(uint256(msgHash));
        uint256 newIndex = IMultiSignature(multiSign).getValidSignature(msgHash,index);
        require(newIndex > index, "multiSignatureClient : This tx is not aprroved");
        saveValue(uint256(msgHash),newIndex);
    }
    function saveValue(uint256 position,uint256 value) internal 
    {
        assembly {
            sstore(position, value)
        }
    }
    function getValue(uint256 position) internal view returns (uint256 value) {
        assembly {
            value := sload(position)
        }
    }
}

pragma solidity =0.5.16;
import './proxyOwner.sol';
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
contract ImputRange is proxyOwner {
    
    //The maximum input amount limit.
    uint256 internal maxAmount;
    //The minimum input amount limit.
    uint256 internal minAmount;
    
    modifier InRange(uint256 amount) {
        require(maxAmount>=amount && minAmount<=amount,"input amount is out of input amount range");
        _;
    }
    /**
     * @dev Determine whether the input amount is within the valid range
     * @param amount Test value which is user input
     */
    function isInputAmountInRange(uint256 amount)public view returns (bool){
        return(maxAmount>=amount && minAmount<=amount);
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
    function setInputAmountRange(uint256 _minAmount,uint256 _maxAmount) public OwnerOrOrigin{
        minAmount = _minAmount;
        maxAmount = _maxAmount;
    }        
}

pragma solidity =0.5.16;
/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract initializable {

    /**
    * @dev Indicates that the contract has been initialized.
    */
    bool private initialized;

    /**
    * @dev Indicates that the contract is in the process of being initialized.
    */
    bool private initializing;

    /**
    * @dev Modifier to use in the initializer function of a contract.
    */
    modifier initializer() {
        require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

        bool wasInitializing = initializing;
        initializing = true;
        initialized = true;

        _;
        initializing = wasInitializing;
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        uint256 cs;
        assembly { cs := extcodesize(address) }
        return cs == 0;
    }

}

pragma solidity =0.5.16;
import "./proxyOwner.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * each operator can be granted exclusive access to specific functions.
 *
 */
contract proxyOperator is proxyOwner {
    mapping(uint256=>address) internal _operators;
    uint256 internal constant managerIndex = 0;
    event OperatorTransferred(address indexed previousOperator, address indexed newOperator,uint256 indexed index);
    modifier onlyManager() {
        require(msg.sender == _operators[managerIndex], "Operator: caller is not the manager");
        _;
    }
    modifier onlyOperator(uint256 index) {
        require(_operators[index] == msg.sender,"Operator: caller is not the eligible Operator");
        _;
    }
    modifier onlyOperator2(uint256 index1,uint256 index2) {
        require(_operators[index1] == msg.sender || _operators[index2] == msg.sender,"Operator: caller is not the eligible Operator");
        _;
    }
    modifier onlyOperator3(uint256 index1,uint256 index2,uint256 index3) {
        require(_operators[index1] == msg.sender || _operators[index2] == msg.sender || _operators[index3] == msg.sender,
            "Operator: caller is not the eligible Operator");
        _;
    }
    function setManager(address newManager) public onlyOwner{
        _setOperator(managerIndex,newManager);
    }
    /**
     * @dev modify indexed operator by owner. 
     *
     */
    function setOperator(uint256 index,address newAddress)public OwnerOrOrigin{
        require(index>0, "Index must greater than 0");
        _setOperator(index,newAddress);
    }
    function _setOperator(uint256 index,address newAddress) internal {
        emit OperatorTransferred(_operators[index], newAddress,index);
        _operators[index] = newAddress;
    }
    function getOperator(uint256 index)public view returns (address) {
        return _operators[index];
    }
}

pragma solidity =0.5.16;

/**
 * @title  proxyOwner Contract

 */
import "../multiSignature/multiSignatureClient.sol";
contract proxyOwner is multiSignatureClient{
    bytes32 private constant ownerExpiredPosition = keccak256("org.Phoenix.ownerExpired.storage");
    bytes32 private constant versionPositon = keccak256("org.Phoenix.version.storage");
    bytes32 private constant proxyOwnerPosition  = keccak256("org.Phoenix.Owner.storage");
    bytes32 private constant proxyOriginPosition  = keccak256("org.Phoenix.Origin.storage");
    uint256 private constant oncePosition  = uint256(keccak256("org.Phoenix.Once.storage"));
    uint256 private constant ownerExpired =  90 days;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OriginTransferred(address indexed previousOrigin, address indexed newOrigin);
    constructor(address multiSignature) multiSignatureClient(multiSignature) public{
        _setProxyOwner(msg.sender);
        _setProxyOrigin(tx.origin);
    }
    /**
     * @dev Allows the current owner to transfer ownership
     * @param _newOwner The address to transfer ownership to
     */

    function transferOwnership(address _newOwner) public onlyOwner
    {
        _setProxyOwner(_newOwner);
    }
    function _setProxyOwner(address _newOwner) internal 
    {
        emit OwnershipTransferred(owner(),_newOwner);
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, _newOwner)
        }
        position = ownerExpiredPosition;
        uint256 expired = now+ownerExpired;
        assembly {
            sstore(position, expired)
        }
    }
    function owner() public view returns (address _owner) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            _owner := sload(position)
        }
    }
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require (isOwner(),"proxyOwner: caller must be the proxy owner and a contract and not expired");
        _;
    }
    function transferOrigin(address _newOrigin) public onlyOrigin
    {
        _setProxyOrigin(_newOrigin);
    }
    function _setProxyOrigin(address _newOrigin) internal 
    {
        emit OriginTransferred(txOrigin(),_newOrigin);
        bytes32 position = proxyOriginPosition;
        assembly {
            sstore(position, _newOrigin)
        }
    }
    function txOrigin() public view returns (address _origin) {
        bytes32 position = proxyOriginPosition;
        assembly {
            _origin := sload(position)
        }
    }
    function ownerExpiredTime() public view returns (uint256 _expired) {
        bytes32 position = ownerExpiredPosition;
        assembly {
            _expired := sload(position)
        }
    }
    modifier originOnce() {
        require (msg.sender == txOrigin(),"proxyOwner: caller is not the tx origin!");
        uint256 key = oncePosition+uint32(msg.sig);
        require (getValue(key)==0, "proxyOwner : This function must be invoked only once!");
        saveValue(key,1);
        _;
    }
    function isOwner() public view returns (bool) {
        return msg.sender == owner() && isContract(msg.sender);
    }
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOrigin() {
        require (msg.sender == txOrigin(),"proxyOwner: caller is not the tx origin!");
        checkMultiSignature();
        _;
    }
    modifier OwnerOrOrigin(){
        if (isOwner()){
        }else if(msg.sender == txOrigin()){
            checkMultiSignature();
        }else{
            require(false,"proxyOwner: caller is not owner or origin");
        }
        _;
    }
    function _setVersion(uint256 version_) internal 
    {
        bytes32 position = versionPositon;
        assembly {
            sstore(position, version_)
        }
    }
    function version() public view returns(uint256 version_){
        bytes32 position = versionPositon;
        assembly {
            version_ := sload(position)
        }
    }
    
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
import "./proxyOwner.sol";
import './initializable.sol';
contract versionUpdater is proxyOwner,initializable {
    function implementationVersion() public pure returns (uint256);
    function initialize() public initializer versionUpdate {

    }
    modifier versionUpdate(){
        require(implementationVersion() > version() &&  ownerExpiredTime()>now,"New version implementation is already updated!");
        _;
    }
}

pragma solidity =0.5.16;
interface IOptionsPrice {
    function getOptionsPrice(uint256 currentPrice, uint256 strikePrice, uint256 expiration,uint32 underlying,uint8 optType)external view returns (uint256);
    function getOptionsPrice_iv(uint256 currentPrice, uint256 strikePrice, uint256 expiration,
                uint256 ivNumerator,uint8 optType)external view returns (uint256);
    function calOptionsPriceRatio(uint256 selfOccupied,uint256 totalOccupied,uint256 totalCollateral) external view returns (uint256);
}

pragma solidity =0.5.16;
interface IVolatility {
    function calculateIv(uint32 underlying,uint8 optType,uint256 expiration,uint256 currentPrice,uint256 strikePrice)external view returns (uint256);
}

