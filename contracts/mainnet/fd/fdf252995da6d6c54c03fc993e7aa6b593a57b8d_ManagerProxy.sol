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

// File: contracts\modules\Halt.sol

pragma solidity =0.5.16;


contract Halt is Ownable {
    
    bool private halted = false; 
    
    modifier notHalted() {
        require(!halted,"This contract is halted");
        _;
    }

    modifier isHalted() {
        require(halted,"This contract is not halted");
        _;
    }
    
    /// @notice function Emergency situation that requires 
    /// @notice contribution period to stop or not.
    function setHalt(bool halt) 
        public 
        onlyOwner
    {
        halted = halt;
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

// File: contracts\modules\AddressWhiteList.sol

pragma solidity =0.5.16;


    /**
     * @dev Implementation of a whitelist filters a eligible address.
     */
contract AddressWhiteList is Halt {

    using whiteListAddress for address[];
    uint256 constant internal allPermission = 0xffffffff;
    uint256 constant internal allowBuyOptions = 1;
    uint256 constant internal allowSellOptions = 1<<1;
    uint256 constant internal allowExerciseOptions = 1<<2;
    uint256 constant internal allowAddCollateral = 1<<3;
    uint256 constant internal allowRedeemCollateral = 1<<4;
    // The eligible adress list
    address[] internal whiteList;
    mapping(address => uint256) internal addressPermission;
    /**
     * @dev Implementation of add an eligible address into the whitelist.
     * @param addAddress new eligible address.
     */
    function addWhiteList(address addAddress)public onlyOwner{
        whiteList.addWhiteListAddress(addAddress);
        addressPermission[addAddress] = allPermission;
    }
    function modifyPermission(address addAddress,uint256 permission)public onlyOwner{
        addressPermission[addAddress] = permission;
    }
    /**
     * @dev Implementation of revoke an invalid address from the whitelist.
     * @param removeAddress revoked address.
     */
    function removeWhiteList(address removeAddress)public onlyOwner returns (bool){
        addressPermission[removeAddress] = 0;
        return whiteList.removeWhiteListAddress(removeAddress);
    }
    /**
     * @dev Implementation of getting the eligible whitelist.
     */
    function getWhiteList()public view returns (address[] memory){
        return whiteList;
    }
    /**
     * @dev Implementation of testing whether the input address is eligible.
     * @param tmpAddress input address for testing.
     */    
    function isEligibleAddress(address tmpAddress) public view returns (bool){
        return whiteList.isEligibleAddress(tmpAddress);
    }
    function checkAddressPermission(address tmpAddress,uint256 state) public view returns (bool){
        return  (addressPermission[tmpAddress]&state) == state;
    }
}

// File: contracts\modules\ReentrancyGuard.sol

pragma solidity =0.5.16;
contract ReentrancyGuard {

  /**
   * @dev We use a single lock for the whole contract.
   */
  bool private reentrancyLock = false;
  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * @notice If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one nonReentrant function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and a `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    require(!reentrancyLock);
    reentrancyLock = true;
    _;
    reentrancyLock = false;
  }

}

// File: contracts\OptionsPool\IOptionsPool.sol

pragma solidity =0.5.16;

interface IOptionsPool {
//    function getOptionBalances(address user) external view returns(uint256[]);

    function getExpirationList()external view returns (uint32[] memory);
    function createOptions(address from,address settlement,uint256 type_ly_expiration,
        uint128 strikePrice,uint128 underlyingPrice,uint128 amount,uint128 settlePrice) external returns(uint256);
    function setSharedState(uint256 newFirstOption,int256[] calldata latestNetWorth,address[] calldata whiteList) external;
    function getAllTotalOccupiedCollateral() external view returns (uint256,uint256);
    function getCallTotalOccupiedCollateral() external view returns (uint256);
    function getPutTotalOccupiedCollateral() external view returns (uint256);
    function getTotalOccupiedCollateral() external view returns (uint256);
//    function buyOptionCheck(uint32 expiration,uint32 underlying)external view;
    function burnOptions(address from,uint256 id,uint256 amount,uint256 optionPrice)external;
    function getOptionsById(uint256 optionsId)external view returns(uint256,address,uint8,uint32,uint256,uint256,uint256);
    function getExerciseWorth(uint256 optionsId,uint256 amount)external view returns(uint256);
    function calculatePhaseOptionsFall(uint256 lastOption,uint256 begin,uint256 end,address[] calldata whiteList) external view returns(int256[] memory);
    function getOptionInfoLength()external view returns (uint256);
    function getNetWrothCalInfo(address[] calldata whiteList)external view returns(uint256,int256[] memory);
    function calRangeSharedPayment(uint256 lastOption,uint256 begin,uint256 end,address[] calldata whiteList)external view returns(int256[] memory,uint256[] memory,uint256);
    function getNetWrothLatestWorth(address settlement)external view returns(int256);
    function getBurnedFullPay(uint256 optionID,uint256 amount) external view returns(address,uint256);

}
contract ImportOptionsPool is Ownable{
    IOptionsPool internal _optionsPool;
    function getOptionsPoolAddress() public view returns(address){
        return address(_optionsPool);
    }
    function setOptionsPoolAddress(address optionsPool)public onlyOwner{
        _optionsPool = IOptionsPool(optionsPool);
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

// File: contracts\CollateralPool\ICollateralPool.sol

pragma solidity =0.5.16;

interface ICollateralPool {
    function getFeeRateAll()external view returns (uint32[] memory);
    function getUserPayingUsd(address user)external view returns (uint256);
    function getUserInputCollateral(address user,address collateral)external view returns (uint256);
    //function getNetWorthBalance(address collateral)external view returns (int256);
    function getCollateralBalance(address collateral)external view returns (uint256);

    //add
    function addUserPayingUsd(address user,uint256 amount)external;
    function addUserInputCollateral(address user,address collateral,uint256 amount)external;
    function addNetWorthBalance(address collateral,int256 amount)external;
    function addCollateralBalance(address collateral,uint256 amount)external;
    //sub
    function subUserPayingUsd(address user,uint256 amount)external;
    function subUserInputCollateral(address user,address collateral,uint256 amount)external;
    function subNetWorthBalance(address collateral,int256 amount)external;
    function subCollateralBalance(address collateral,uint256 amount)external;
        //set
    function setUserPayingUsd(address user,uint256 amount)external;
    function setUserInputCollateral(address user,address collateral,uint256 amount)external;
    function setNetWorthBalance(address collateral,int256 amount)external;
    function setCollateralBalance(address collateral,uint256 amount)external;
    function transferPaybackAndFee(address recieptor,address settlement,uint256 payback,uint256 feeType)external;

    function buyOptionsPayfor(address payable recieptor,address settlement,uint256 settlementAmount,uint256 allPay)external;
    function transferPayback(address recieptor,address settlement,uint256 payback)external;
    function transferPaybackBalances(address account,uint256 redeemWorth,address[] calldata tmpWhiteList,uint256[] calldata colBalances,
        uint256[] calldata PremiumBalances,uint256[] calldata prices)external;
    function getCollateralAndPremiumBalances(address account,uint256 userTotalWorth,address[] calldata tmpWhiteList,
        uint256[] calldata _RealBalances,uint256[] calldata prices) external view returns(uint256[] memory,uint256[] memory);
    function addTransactionFee(address collateral,uint256 amount,uint256 feeType)external returns (uint256);

    function getAllRealBalance(address[] calldata whiteList)external view returns(int256[] memory);
    function getRealBalance(address settlement)external view returns(int256);
    function getNetWorthBalance(address settlement)external view returns(uint256);
}
contract ImportCollateralPool is Ownable{
    ICollateralPool internal _collateralPool;
    function getCollateralPoolAddress() public view returns(address){
        return address(_collateralPool);
    }
    function setCollateralPoolAddress(address collateralPool)public onlyOwner{
        _collateralPool = ICollateralPool(collateralPool);
    }
}

// File: contracts\FPTCoin\IFPTCoin.sol

pragma solidity =0.5.16;

interface IFPTCoin {
    function lockedBalanceOf(address account) external view returns (uint256);
    function lockedWorthOf(address account) external view returns (uint256);
    function getLockedBalance(address account) external view returns (uint256,uint256);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
    function addlockBalance(address account, uint256 amount,uint256 lockedWorth)external; 
    function getTotalLockedWorth() external view returns (uint256);
    function addMinerBalance(address account,uint256 amount) external;
    function redeemLockedCollateral(address account,uint256 tokenAmount,uint256 leftCollateral)external returns (uint256,uint256);
}
contract ImportIFPTCoin is Ownable{
    IFPTCoin internal _FPTCoin;
    function getFPTCoinAddress() public view returns(address){
        return address(_FPTCoin);
    }
    function setFPTCoinAddress(address FPTCoinAddr)public onlyOwner{
        _FPTCoin = IFPTCoin(FPTCoinAddr);
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

// File: contracts\modules\Allowances.sol

pragma solidity =0.5.16;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * each operator can be granted exclusive access to specific functions.
 *
 */
contract Allowances is Ownable {
    mapping (address => uint256) internal allowances;
    bool internal bValid = false;
    /**
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public onlyOwner{
        allowances[spender] = amount;
    }
    function allowance(address spender) public view returns (uint256) {
        return allowances[spender];
    }
    function setValid(bool _bValid) public onlyOwner{
        bValid = _bValid;
    }
    function checkAllowance(address spender, uint256 amount) public view returns(bool){
        return (!bValid) || (allowances[spender] >= amount);
    }
    modifier sufficientAllowance(address spender, uint256 amount){
        require((!bValid) || (allowances[spender] >= amount),"Allowances : user's allowance is unsufficient!");
        _;
    }
}

// File: contracts\ERC20\IERC20.sol

pragma solidity =0.5.16;
/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
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

// File: contracts\OptionsManager\ManagerData.sol

pragma solidity =0.5.16;










/**
 * @title collateral calculate module
 * @dev A smart-contract which has operations of collateral and methods of calculate collateral occupation.
 *
 */
contract ManagerData is ReentrancyGuard,ImputRange,AddressWhiteList,Allowances,ImportIFPTCoin,
                ImportOracle,ImportOptionsPool,ImportCollateralPool,ImportOptionsPrice {
    // The minimum collateral rate for options. This value is thousandths.
    mapping (address=>uint256) collateralRate;
//    uint256 private collateralRate = 5000;
    /**
     * @dev Emitted when `from` added `amount` collateral and minted `tokenAmount` FPTCoin.
     */
    event AddCollateral(address indexed from,address indexed collateral,uint256 amount,uint256 tokenAmount);
    /**
     * @dev Emitted when `from` redeemed `allRedeem` collateral.
     */
    event RedeemCollateral(address indexed from,address collateral,uint256 allRedeem);
    event DebugEvent(uint256 id,uint256 value1,uint256 value2);
        /**
    * @dev input price valid range rate, thousandths.
    * the input price must greater than current price * minPriceRate /1000
    *       and less  than current price * maxPriceRate /1000 
    * maxPriceRate is the maximum limit of the price valid range rate
    * maxPriceRate is the minimum limit of the price valid range rage
    */   
    uint256 internal maxPriceRate = 1500;
    uint256 internal minPriceRate = 500;
    /**
     * @dev Emitted when `from` buy `optionAmount` option and create new option.
     * @param from user's account
     * @param settlement user's input settlement paid for buy new option.
     * @param optionPrice option's paid price
     * @param settlementAmount settement cost
     * @param optionAmount mint option token amount.
     */  
    event BuyOption(address indexed from,address indexed settlement,uint256 optionPrice,uint256 settlementAmount,uint256 optionAmount);
    /**
     * @dev Emitted when `from` sell `amount` option whose id is `optionId` and received sellValue,priced in usd.
     */  
    event SellOption(address indexed from,uint256 indexed optionId,uint256 amount,uint256 sellValue);
    /**
     * @dev Emitted when `from` exercise `amount` option whose id is `optionId` and received sellValue,priced in usd.
     */  
    event ExerciseOption(address indexed from,uint256 indexed optionId,uint256 amount,uint256 sellValue);
}

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

// File: contracts\OptionsManager\ManagerProxy.sol

pragma solidity =0.5.16;


/**
 * @title  Erc20Delegator Contract

 */
contract ManagerProxy is ManagerData,baseProxy{
    /**
    * @dev Options manager constructor. set other contract address
    *  oracleAddr fnx oracle contract address.
    *  optionsPriceAddr options price contract address
    *  optionsPoolAddr optoins pool contract address
    *  FPTCoinAddr FPTCoin contract address
    */
    constructor(address implementation_,address oracleAddr,address optionsPriceAddr,
            address optionsPoolAddr,address collateralPoolAddr,address FPTCoinAddr)
         baseProxy(implementation_) public  {
        _oracle = IFNXOracle(oracleAddr);
        _optionsPrice = IOptionsPrice(optionsPriceAddr);
        _optionsPool = IOptionsPool(optionsPoolAddr);
        _collateralPool = ICollateralPool(collateralPoolAddr);
        _FPTCoin = IFPTCoin(FPTCoinAddr);
/*
        allowances[0x6D14B6A933Bfc473aEDEBC3beD58cA268FEe8b4a] = 1e40;
        allowances[0x87A7604C4E9E1CED9990b6D486d652f0194A4c98] = 1e40;
        allowances[0x7ea1a45f0657D2Dbd77839a916AB83112bdB5590] = 1e40;
        allowances[0x358dba22d19789E01FD6bB528f4E75Bc06b56A79] = 1e40;
        allowances[0x91406B5d57893E307f042D71C91e223a7058Eb72] = 1e40;
        allowances[0xc89b50171C1F692f5CBC37aC4AF540f9cecEE0Ff] = 1e40;
        allowances[0x92e25B14B0B760212D7E831EB8436Fbb93826755] = 1e40;
        allowances[0x2D8f8d7737046c1475ED5278a18c4A62968f0CB2] = 1e40;
        allowances[0xaAC6A96681cfc81c756Db31D93eafb8237A27Ba8] = 1e40;
        allowances[0xB752d7a4E7ebD7B7A7b4DEEFd086571e5e7F5BB8] = 1e40;
        allowances[0x8AbD525792015E1eBae2249756729168A3c1866F] = 1e40;
        allowances[0x991b9d51e5526D497A576DF82eaa4BEA51EAD16e] = 1e40;
        allowances[0xC8e7E9e496DE394969cb377F5Df0E3cdDFB74164] = 1e40;
        allowances[0x0B173b9014a0A36aAC51eE4957BC8c7E20686d3F] = 1e40;
        allowances[0xb9cE369E36Ab9ea488887ad9483f0ce899ab8fbe] = 1e40;
        allowances[0x20C337F68Dc90D830Ac8e379e8823008dc791D56] = 1e40;
        allowances[0x10E3163a7354b16ac24e7fCeE593c22E86a0abCa] = 1e40;
        allowances[0x669cFbd063C434a5ee51adc78d2292A2D3Fe88E0] = 1e40;
        allowances[0x59F1cfc3c485b9693e3F640e1B56Fe83B5e3183a] = 1e40;
        allowances[0x4B38bf8A442D01017a6882d52Ef1B13CD069bb0d] = 1e40;
        allowances[0x9c8f005ab27AdB94f3d49020A15722Db2Fcd9F27] = 1e40;
        allowances[0x2240D781185B93DdD83C5eA78F4E64a9Cb5B0446] = 1e40;
        allowances[0xa5B7364926Ac89aBCA15D56738b3EA79B31A0433] = 1e40;
        allowances[0xafE53d85Da6b510B4fcc3774373F8880097F3E10] = 1e40;
        allowances[0xb604BE9155810e4BA938ce06f8E554D2EB3438fE] = 1e40;
        allowances[0xA27D1D94C0B4ce79d49E7c817C688c563D297fF7] = 1e40;
        allowances[0x32ACbBa480e4bA2ee3E2c620Bf7A3242631293BE] = 1e40;
        allowances[0x7Acfd797725EcCd5D3D60fB5Dd566760D0743098] = 1e40;
        allowances[0x0F8f5137C365D01f71a3fb8A4283816FB12A8Efb] = 1e40;
        allowances[0x2F160d9b63b5b8255499aB16959231275D4396db] = 1e40;
        allowances[0xf85a428D528e89E115E5C91F7347fE9ac2F92d72] = 1e40;
        allowances[0xb2c62391CCe67C5EfC1b17D442eBd24c90F6A47C] = 1e40;
        allowances[0x10d31b7063cC25F9916B390677DC473B83E84e13] = 1e40;
        allowances[0x358dba22d19789E01FD6bB528f4E75Bc06b56A79] = 1e40;
        allowances[0xe4A263230d67d30c71634CA462a00174d943A14D] = 1e40;
        allowances[0x1493572Bd9Fa9F75b0B81D6Cdd583AD87D6B358F] = 1e40;
        allowances[0x025b654306621157aE8208ebC5DD0f311F425ac3] = 1e40;
        allowances[0xCE257C6BD7aF256e1C8Dd11057F90b9A1AeD85a4] = 1e40;
        allowances[0x7D57B8B8A731Cc1fc1E661842790e1864d5Cf4E8] = 1e40;
        allowances[0xe129e34D1bD6AA1370090Cb1596207197A1a0689] = 1e40;
        allowances[0xBA096024056bB653c6E28f53C8889BFC3553bAD8] = 1e40;
        allowances[0x73DFb4bA8fFF9A975a28FF169157C7B71B9574aE] = 1e40;
        allowances[0xddbDc4a3Af9DAa4005c039BE8329c1F03F01EDb9] = 1e40;
        allowances[0x4086E0e1B3351D2168B74E7A61C0844b78f765F2] = 1e40;
        allowances[0x4ce4fe1B35F11a428DD36A78C56Cb8Cc755f8847] = 1e40;
        allowances[0x9e169106D1d406F3d51750835E01e8a34c265957] = 1e40;
        allowances[0x7EcB07AdC76b2979fbE45Af13e2B706bA3562d1d] = 1e40;
        allowances[0x3B95Df362B1857e6Db3483521057C4587C467531] = 1e40;
        allowances[0xe596470D291Cb2D32ec111afC314B07006690c72] = 1e40;
        allowances[0x80fd2a2Ed7e42Ec8bD9635285B09C773Da31eF71] = 1e40;
        allowances[0xC09ec032769b04b08BDe8ADb608d0aaF903FF9Be] = 1e40;
        allowances[0xf5F9AFBC3915075C5C62A995501fae643F5f6857] = 1e40;
        allowances[0xf010920E1B098DFA1732d41Fbc895aB6E65E4438] = 1e40;
        allowances[0xb37983510f9483A0725bC109d7f19237Aa3212d5] = 1e40;
        allowances[0x9531479AA50908c9053144eF99c235abA6168069] = 1e40;
        allowances[0x98F6a20f80FbF33153BE7ed1C8C3c10d4d6433DF] = 1e40;
        allowances[0x4c8dbbDdC95B7981a7a09dE455ddfc58173CF471] = 1e40;
        allowances[0x5acfbbF0aA370F232E341BC0B1a40e996c960e07] = 1e40;
        allowances[0x7388B46005646008ada2d6d7DC2830F6C63b9BeD] = 1e40;
        allowances[0xBFa43bf6E9FB6d5CC253Ff23c31F2b86a739bB98] = 1e40;
        allowances[0x09AEa652006F4088d389c878474e33e9B15986E5] = 1e40;
        allowances[0x0fBC222aDF84bEE9169022b28ebc3D32b5C60756] = 1e40;
        allowances[0xBD53E948a5630c409b98bFC6112c2891836d5b33] = 1e40;
        allowances[0x0eBF4005C35d525240c3237c1C448B88Deca9447] = 1e40;
        allowances[0xa1cCC796E2B44e80112c065A4d8F05661E685eD8] = 1e40;
        allowances[0x4E60bE84870FE6AE350B563A121042396Abe1eaF] = 1e40;
        allowances[0x5286CEde4a0Eda5916d639535aDFbefAd980D6E1] = 1e40;
*/
    }
    /**
     * @dev  The foundation owner want to set the minimum collateral occupation rate.
     *  collateral collateral coin address
     *  colRate The thousandths of the minimum collateral occupation rate.
     */
    function setCollateralRate(address /*collateral*/,uint256 /*colRate*/) public {
        delegateAndReturn();
    }
    /**
     * @dev Get the minimum collateral occupation rate.
     */
    function getCollateralRate(address /*collateral*/)public view returns (uint256) {
        delegateToViewAndReturn();
    }
    /**
     * @dev Retrieve user's cost of collateral, priced in USD.
     *  user input retrieved account 
     */
    function getUserPayingUsd(address /*user*/)public view returns (uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev Retrieve user's amount of the specified collateral.
     *  user input retrieved account 
     *  collateral input retrieved collateral coin address 
     */
    function userInputCollateral(address /*user*/,address /*collateral*/)public view returns (uint256){
        delegateToViewAndReturn();
    }

    /**
     * @dev Retrieve user's current total worth, priced in USD.
     *  account input retrieve account
     */
    function getUserTotalWorth(address /*account*/)public view returns (uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev Retrieve FPTCoin's net worth, priced in USD.
     */
    function getTokenNetworth() public view returns (uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev Deposit collateral in this pool from user.
     *  collateral The collateral coin address which is in whitelist.
     *  amount the amount of collateral to deposit.
     */
    function addCollateral(address /*collateral*/,uint256 /*amount*/) public payable {
        delegateAndReturn();
    }
    /**
     * @dev redeem collateral from this pool, user can input the prioritized collateral,he will get this coin,
     * if this coin is unsufficient, he will get others collateral which in whitelist.
     *  tokenAmount the amount of FPTCoin want to redeem.
     *  collateral The prioritized collateral coin address.
     */
    function redeemCollateral(uint256 /*tokenAmount*/,address /*collateral*/) public {
        delegateAndReturn();
    }
    /**
     * @dev Retrieve user's collateral worth in all collateral coin. 
     * If user want to redeem all his collateral,and the vacant collateral is sufficient,
     * He can redeem each collateral amount in return list.
     *  account the retrieve user's account;
     */
    function calCollateralWorth(address /*account*/)public view returns(uint256[] memory){
        delegateToViewAndReturn();
    }
    /**
     * @dev Retrieve the occupied collateral worth, multiplied by minimum collateral rate, priced in USD. 
     */
    function getOccupiedCollateral() public view returns(uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev Retrieve the available collateral worth, the worth of collateral which can used for buy options, priced in USD. 
     */
    function getAvailableCollateral()public view returns(uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev Retrieve the left collateral worth, the worth of collateral which can used for redeem collateral, priced in USD. 
     */
    function getLeftCollateral()public view returns(uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev Retrieve the unlocked collateral worth, the worth of collateral which currently used for options, priced in USD. 
     */
    function getUnlockedCollateral()public view returns(uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev The auxiliary function for calculate option occupied. 
     *  strikePrice option's strike price
     *  underlyingPrice option's underlying price
     *  amount option's amount
     *  optType option's type, 0 for call, 1 for put.
     */
    function calOptionsOccupied(uint256 /*strikePrice*/,uint256 /*underlyingPrice*/,uint256 /*amount*/,uint8 /*optType*/)public view returns(uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev Retrieve the total collateral worth, priced in USD. 
     */
    function getTotalCollateral()public view returns(uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev Retrieve the balance of collateral, the auxiliary function for the total collateral calculation. 
     */
    function getRealBalance(address /*settlement*/)public view returns(int256){
        delegateToViewAndReturn();
    }
    function getNetWorthBalance(address /*settlement*/)public view returns(uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev collateral occupation rate calculation
     *      collateral occupation rate = sum(collateral Rate * collateral balance) / sum(collateral balance)
     */
    function calculateCollateralRate()public view returns (uint256){
        delegateToViewAndReturn();
    }
    /**
    * @dev retrieve input price valid range rate, thousandths.
    */ 
    function getPriceRateRange() public view returns(uint256,uint256) {
        delegateToViewAndReturn();
    }
    /**
    * @dev set input price valid range rate, thousandths.
    */ 
    function setPriceRateRange(uint256 /*_minPriceRate*/,uint256 /*_maxPriceRate*/) public{
        delegateAndReturn();
    }
    /**
    * @dev user buy option and create new option.
    *  settlement user's settement coin address
    *  settlementAmount amount of settlement user want fo pay.
    *  strikePrice user input option's strike price
    *  underlying user input option's underlying id, 1 for BTC,2 for ETH
    *  expiration user input expiration,time limit from now
    *  amount user input amount of new option user want to buy.
    *  optType user input option type
    */ 
    function buyOption(address /*settlement*/,uint256 /*settlementAmount*/, uint256 /*strikePrice*/,uint32 /*underlying*/,
                uint32 /*expiration*/,uint256 /*amount*/,uint8 /*optType*/) public payable{
        delegateAndReturn();
    }
    /**
    * @dev User sell option.
    *  optionsId option's ID which was wanted to sell, must owned by user
    *  amount user input amount of option user want to sell.
    */ 
    function sellOption(uint256 /*optionsId*/,uint256 /*amount*/) public{
        delegateAndReturn();
    }
    /**
    * @dev User exercise option.
    *  optionsId option's ID which was wanted to exercise, must owned by user
    *  amount user input amount of option user want to exercise.
    */ 
    function exerciseOption(uint256 /*optionsId*/,uint256 /*amount*/) public{
        delegateAndReturn();
    }
    function getOptionsPrice(uint256 /*underlyingPrice*/, uint256 /*strikePrice*/, uint256 /*expiration*/,
                    uint32 /*underlying*/,uint256 /*amount*/,uint8 /*optType*/) public view returns(uint256){
        delegateToViewAndReturn();
    }
    function getALLCollateralinfo(address /*user*/)public view 
        returns(uint256[] memory,int256[] memory,uint32[] memory,uint32[] memory){
        delegateToViewAndReturn();
    }
}