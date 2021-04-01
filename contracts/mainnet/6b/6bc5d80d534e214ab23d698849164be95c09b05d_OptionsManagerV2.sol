/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

// File: contracts\modules\SafeMath.sol

pragma solidity =0.5.16;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'SafeMath: addition overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'SafeMath: substraction underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'SafeMath: multiplication overflow');
    }
}

// File: contracts\modules\SafeInt256.sol

pragma solidity =0.5.16;
library SafeInt256 {
    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require(((z = x + y) >= x) == (y >= 0), 'SafeInt256: addition overflow');
    }

    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        require(((z = x - y) <= x) == (y >= 0), 'SafeInt256: substraction underflow');
    }

    function mul(int256 x, int256 y) internal pure returns (int256 z) {
        require(y == 0 || (z = x * y) / y == x, 'SafeInt256: multiplication overflow');
    }
}

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

// File: contracts\modules\Address.sol

pragma solidity =0.5.16;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call.value(value )(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: contracts\ERC20\safeErc20.sol

// SPDX-License-Identifier: MIT
pragma solidity =0.5.16;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts\OptionsManager\CollateralCal.sol

pragma solidity =0.5.16;




/**
 * @title collateral calculate module
 * @dev A smart-contract which has operations of collateral and methods of calculate collateral occupation.
 *
 */
contract CollateralCal is ManagerData {
    using SafeMath for uint256;
    using SafeInt256 for int256;

    /**
     * @dev  The foundation owner want to set the minimum collateral occupation rate.
     * @param collateral collateral coin address
     * @param colRate The thousandths of the minimum collateral occupation rate.
     */
    function setCollateralRate(address collateral,uint256 colRate) public onlyOwner {
        addWhiteList(collateral);
        collateralRate[collateral] = colRate;
//        collateralRate = colRate;

    }
    /**
     * @dev Get the minimum collateral occupation rate.
     */
    function getCollateralRate(address collateral)public view returns (uint256) {
        return collateralRate[collateral];
    }
    /**
     * @dev Retrieve user's cost of collateral, priced in USD.
     * @param user input retrieved account 
     */
    function getUserPayingUsd(address user)public view returns (uint256){
        return _collateralPool.getUserPayingUsd(user);
        //userCollateralPaying[user];
    }
    /**
     * @dev Retrieve user's amount of the specified collateral.
     * @param user input retrieved account 
     * @param collateral input retrieved collateral coin address 
     */
    function userInputCollateral(address user,address collateral)public view returns (uint256){
        return _collateralPool.getUserInputCollateral(user,collateral);
        //return userInputCollateral[user][collateral];
    }

    /**
     * @dev Retrieve user's current total worth, priced in USD.
     * @param account input retrieve account
     */
    function getUserTotalWorth(address account)public view returns (uint256){
        return getTokenNetworth().mul(_FPTCoin.balanceOf(account)).add(_FPTCoin.lockedWorthOf(account));
    }
    /**
     * @dev Retrieve FPTCoin's net worth, priced in USD.
     */
    function getTokenNetworth() public view returns (uint256){
        uint256 _totalSupply = _FPTCoin.totalSupply();
        if (_totalSupply == 0){
            return 1e8;
        }
        uint256 netWorth = getUnlockedCollateral()/_totalSupply;
        return netWorth>100 ? netWorth : 100;
    }
    /**
     * @dev Deposit collateral in this pool from user.
     * @param collateral The collateral coin address which is in whitelist.
     * @param amount the amount of collateral to deposit.
     */
    function addCollateral(address collateral,uint256 amount) nonReentrant notHalted  public payable {
        amount = getPayableAmount(collateral,amount);
        uint256 fee = _collateralPool.addTransactionFee(collateral,amount,3);
        amount = amount-fee;
        uint256 price = oraclePrice(collateral);
        uint256 userPaying = price*amount;
        require(checkAllowance(msg.sender,(_collateralPool.getUserPayingUsd(msg.sender)+userPaying)/1e8),
            "Allowances : user's allowance is unsufficient!");
        uint256 mintAmount = userPaying/getTokenNetworth();
        _collateralPool.addUserPayingUsd(msg.sender,userPaying);
        _collateralPool.addUserInputCollateral(msg.sender,collateral,amount);
        emit AddCollateral(msg.sender,collateral,amount,mintAmount);
        _FPTCoin.mint(msg.sender,mintAmount);
    }
    /**
     * @dev redeem collateral from this pool, user can input the prioritized collateral,he will get this coin,
     * if this coin is unsufficient, he will get others collateral which in whitelist.
     * @param tokenAmount the amount of FPTCoin want to redeem.
     * @param collateral The prioritized collateral coin address.
     */
    function redeemCollateral(uint256 tokenAmount,address collateral) nonReentrant notHalted InRange(tokenAmount) public {
        require(checkAddressPermission(collateral,allowRedeemCollateral) , "settlement is unsupported token");
        uint256 lockedAmount = _FPTCoin.lockedBalanceOf(msg.sender);
        require(_FPTCoin.balanceOf(msg.sender)+lockedAmount>=tokenAmount,"SCoin balance is insufficient!");
        uint256 userTotalWorth = getUserTotalWorth(msg.sender);
        uint256 leftCollateral = getLeftCollateral();
        (uint256 burnAmount,uint256 redeemWorth) = _FPTCoin.redeemLockedCollateral(msg.sender,tokenAmount,leftCollateral);
        tokenAmount -= burnAmount;
        burnAmount = 0;
        if (tokenAmount > 0){
            leftCollateral -= redeemWorth;
            
            if (lockedAmount > 0){
                tokenAmount = tokenAmount > lockedAmount ? tokenAmount - lockedAmount : 0;
            }
            (uint256 newRedeem,uint256 newWorth) = _redeemCollateral(tokenAmount,leftCollateral);
            if(newRedeem>0){
                burnAmount = newRedeem;
                redeemWorth += newWorth;
            }
        }
        _redeemCollateralWorth(collateral,redeemWorth,userTotalWorth);
        if (burnAmount>0){
            _FPTCoin.burn(msg.sender, burnAmount);
        }
    }
    /**
     * @dev The subfunction of redeem collateral.
     * @param leftAmount the left amount of FPTCoin want to redeem.
     * @param leftCollateral The left collateral which can be redeemed, priced in USD.
     */
    function _redeemCollateral(uint256 leftAmount,uint256 leftCollateral)internal returns (uint256,uint256){
        uint256 tokenNetWorth = getTokenNetworth();
        uint256 leftWorth = leftAmount*tokenNetWorth;        
        if (leftWorth > leftCollateral){
            uint256 newRedeem = leftCollateral/tokenNetWorth;
            uint256 newWorth = newRedeem*tokenNetWorth;
            uint256 locked = leftAmount - newRedeem;
            _FPTCoin.addlockBalance(msg.sender,locked,locked*tokenNetWorth);
            return (newRedeem,newWorth);
        }
        return (leftAmount,leftWorth);
    }
    /**
     * @dev The auxiliary function of collateral calculation.
     * @param collateral the prioritized collateral which user input.
     * @return the collateral whitelist, in which the prioritized collateral is at the front.
     */
    function getTempWhiteList(address collateral) internal view returns (address[] memory) {
        address[] memory tmpWhiteList = whiteList;
        uint256 index = whiteListAddress._getEligibleIndexAddress(tmpWhiteList,collateral);
        if (index != 0){
            tmpWhiteList[index] = tmpWhiteList[0];
            tmpWhiteList[0] = collateral;
        }
        return tmpWhiteList;
    }
    /**
     * @dev The subfunction of redeem collateral. Calculate all redeem count and tranfer.
     * @param collateral the prioritized collateral which user input.
     * @param redeemWorth user redeem worth, priced in USD.
     * @param userTotalWorth user total worth, priced in USD.
     */
    function _redeemCollateralWorth(address collateral,uint256 redeemWorth,uint256 userTotalWorth) internal {
        if (redeemWorth == 0){
            return;
        }
        emit RedeemCollateral(msg.sender,collateral,redeemWorth);
        address[] memory tmpWhiteList = getTempWhiteList(collateral);
        (uint256[] memory colBalances,uint256[] memory PremiumBalances,uint256[] memory prices) = 
                _getCollateralAndPremiumBalances(msg.sender,userTotalWorth,tmpWhiteList);
        _collateralPool.transferPaybackBalances(msg.sender,redeemWorth,tmpWhiteList,colBalances,
                PremiumBalances,prices);
    }
    /**
     * @dev Retrieve user's collateral worth in all collateral coin. 
     * If user want to redeem all his collateral,and the vacant collateral is sufficient,
     * He can redeem each collateral amount in return list.
     * @param account the retrieve user's account;
     */
    function calCollateralWorth(address account)public view returns(uint256[] memory){
        uint256 worth = getUserTotalWorth(account);
        (uint256[] memory colBalances,uint256[] memory PremiumBalances,) = 
        _getCollateralAndPremiumBalances(account,worth,whiteList);
        uint256 whiteLen = whiteList.length;
        for (uint256 i=0; i<whiteLen;i++){
            colBalances[i] = colBalances[i].add(PremiumBalances[i]);
        }
        return colBalances;
    }
    /**
     * @dev The auxiliary function for redeem collateral calculation. 
     * @param account the retrieve user's account;
     * @param userTotalWorth user's total worth, priced in USD.
     * @param tmpWhiteList the collateral white list.
     * @return user's total worth in each collateral, priced in USD.
     */
    function _getCollateralAndPremiumBalances(address account,uint256 userTotalWorth,address[] memory tmpWhiteList) internal view returns(uint256[] memory,uint256[] memory,uint256[] memory){
        uint256[] memory prices = new uint256[](tmpWhiteList.length);
        uint256[] memory netWorthBalances = new uint256[](tmpWhiteList.length);
        for (uint256 i=0; i<tmpWhiteList.length;i++){
            if (checkAddressPermission(tmpWhiteList[i],0x0002)){
                netWorthBalances[i] = getNetWorthBalance(tmpWhiteList[i]);
            }
            prices[i] = oraclePrice(tmpWhiteList[i]);
        }
        (uint256[] memory colBalances,uint256[] memory PremiumBalances) = _collateralPool.getCollateralAndPremiumBalances(account,userTotalWorth,tmpWhiteList,
                netWorthBalances,prices);
        return (colBalances,PremiumBalances,prices);
    } 

    /**
     * @dev Retrieve the occupied collateral worth, multiplied by minimum collateral rate, priced in USD. 
     */
    function getOccupiedCollateral() public view returns(uint256){
        uint256 totalOccupied = _optionsPool.getTotalOccupiedCollateral();
        return calculateCollateral(totalOccupied);
    }
    /**
     * @dev Retrieve the available collateral worth, the worth of collateral which can used for buy options, priced in USD. 
     */
    function getAvailableCollateral()public view returns(uint256){
        return safeSubCollateral(getUnlockedCollateral(),getOccupiedCollateral());
    }
    /**
     * @dev Retrieve the left collateral worth, the worth of collateral which can used for redeem collateral, priced in USD. 
     */
    function getLeftCollateral()public view returns(uint256){
        return safeSubCollateral(getTotalCollateral(),getOccupiedCollateral());
    }
    /**
     * @dev Retrieve the unlocked collateral worth, the worth of collateral which currently used for options, priced in USD. 
     */
    function getUnlockedCollateral()public view returns(uint256){
        return safeSubCollateral(getTotalCollateral(),_FPTCoin.getTotalLockedWorth());
    }
    /**
     * @dev The auxiliary function for collateral worth subtraction. 
     */
    function safeSubCollateral(uint256 allCollateral,uint256 subCollateral)internal pure returns(uint256){
        return allCollateral > subCollateral ? allCollateral - subCollateral : 0;
    }
    /**
     * @dev The auxiliary function for calculate option occupied. 
     * @param strikePrice option's strike price
     * @param underlyingPrice option's underlying price
     * @param amount option's amount
     * @param optType option's type, 0 for call, 1 for put.
     */
    function calOptionsOccupied(uint256 strikePrice,uint256 underlyingPrice,uint256 amount,uint8 optType)public view returns(uint256){
        uint256 totalOccupied = 0;
        if ((optType == 0) == (strikePrice>underlyingPrice)){ // call
            totalOccupied = strikePrice*amount;
        } else {
            totalOccupied = underlyingPrice*amount;
        }
        return calculateCollateral(totalOccupied);
    }
    /**
     * @dev Retrieve the total collateral worth, priced in USD. 
     */
    function getTotalCollateral()public view returns(uint256){
        int256 totalNum = 0;
        uint whiteListLen = whiteList.length;
        for (uint256 i=0;i<whiteListLen;i++){
            address addr = whiteList[i];
            int256 price = int256(oraclePrice(addr));
            int256 netWorth = _collateralPool.getRealBalance(addr);
            if (netWorth != 0){
                totalNum = totalNum.add(price.mul(netWorth));
            }
        }
        return totalNum>=0 ? uint256(totalNum) : 0;  
    }
    function getAllRealBalance()public view returns(int256[] memory){
        return _collateralPool.getAllRealBalance(whiteList);
    }
    /**
     * @dev Retrieve the balance of collateral, the auxiliary function for the total collateral calculation. 
     */
    function getRealBalance(address settlement)public view returns(int256){
        return _collateralPool.getRealBalance(settlement);
    }
    function getNetWorthBalance(address settlement)public view returns(uint256){
        return _collateralPool.getNetWorthBalance(settlement);
    }
    /**
     * @dev the auxiliary function for payback. 
     */
    function _paybackWorth(uint256 worth,uint256 feeType) internal {
        uint256 totalPrice = 0;
        uint whiteLen = whiteList.length;
        uint256[] memory balances = new uint256[](whiteLen);
        uint256 i=0;
        for(;i<whiteLen;i++){
            address addr = whiteList[i];
            if (checkAddressPermission(addr,allowSellOptions)){
                uint256 price = oraclePrice(addr);
                balances[i] = getNetWorthBalance(addr);
                //balances[i] = netWorthBalances[addr];
                totalPrice = totalPrice.add(price.mul(balances[i]));
            }
        }
        require(totalPrice>=worth && worth > 0,"payback settlement is insufficient!");
        for (i=0;i<whiteLen;i++){
            uint256 _payBack = balances[i].mul(worth)/totalPrice;
            _collateralPool.transferPaybackAndFee(msg.sender,whiteList[i],_payBack,feeType);
            //addr = whiteList[i];
            //netWorthBalances[addr] = balances[i].sub(_payBack);
            //_transferPaybackAndFee(msg.sender,addr,_payBack,feeType);
        } 
    }

    /**
     * @dev the auxiliary function for getting user's transer
     */
    function getPayableAmount(address settlement,uint256 settlementAmount) internal returns (uint256) {
        require(checkAddressPermission(settlement,allowBuyOptions) , "settlement is unsupported token");
        if (settlement == address(0)){
            settlementAmount = msg.value;
            address payable poolAddr = address(uint160(address(_collateralPool)));
            poolAddr.transfer(settlementAmount);
        }else if (settlementAmount > 0){
            IERC20 oToken = IERC20(settlement);
            uint256 preBalance = oToken.balanceOf(address(_collateralPool));
            SafeERC20.safeTransferFrom(oToken,msg.sender, address(_collateralPool), settlementAmount);
//            oToken.transferFrom(msg.sender, address(_collateralPool), settlementAmount);
            uint256 afterBalance = oToken.balanceOf(address(_collateralPool));
            require(afterBalance-preBalance==settlementAmount,"settlement token transfer error!");
        }
        require(isInputAmountInRange(settlementAmount),"input amount is out of input amount range");
        return settlementAmount;
    }
    /**
     * @dev collateral occupation rate calculation
     *      collateral occupation rate = sum(collateral Rate * collateral balance) / sum(collateral balance)
     */
    function getCollateralAndRate()internal view returns (uint256,uint256){
        int256 totalNum = 0;
        uint256 totalCollateral = 0;
        uint256 totalRate = 0;
        uint whiteListLen = whiteList.length;
        for (uint256 i=0;i<whiteListLen;i++){
            address addr = whiteList[i];
            int256 balance = _collateralPool.getRealBalance(addr);
            if (balance != 0){
                balance = balance*(int256(oraclePrice(addr)));
                if (balance > 0 && collateralRate[addr] > 0){
                    totalNum = totalNum.add(balance);
                    totalCollateral = totalCollateral.add(uint256(balance));
                    totalRate = totalRate.add(uint256(balance)/collateralRate[addr]);
                } 
            }
        }
        if (totalRate > 0){
            totalRate = totalCollateral/totalRate;
        }else{
            totalRate = 5000;
        }
        return (totalNum>=0 ? uint256(totalNum) : 0,totalRate);  
    }
    /**
     * @dev collateral occupation rate calculation
     *      collateral occupation rate = sum(collateral Rate * collateral balance) / sum(collateral balance)
     */

    function calculateCollateralRate()public view returns (uint256){
        uint256 totalCollateral = 0;
        uint256 totalRate = 0;
        uint whiteLen = whiteList.length;
        uint256 i=0;
        for(;i<whiteLen;i++){
            address addr = whiteList[i];
            uint256 balance = getNetWorthBalance(addr);
            if (balance > 0 && collateralRate[addr] > 0){
                balance = oraclePrice(addr)*balance;
                totalCollateral = totalCollateral.add(balance);
                totalRate = totalRate.add(balance/collateralRate[addr]);
            }
        }
        if (totalRate > 0){
            return totalCollateral/totalRate;
        }else{
            return 5000;
        }
    }
    /**
     * @dev the auxiliary function for collateral calculation
     */
    function calculateCollateral(uint256 amount)internal view returns (uint256){
        return calculateCollateralRate()*amount/1000;
    }
}

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

// File: contracts\OptionsManager\OptionsManagerV2.sol

pragma solidity =0.5.16;



/**
 * @title Options manager contract for finnexus proposal v2.
 * @dev A Smart-contract to manage Options pool, collatral pool, mine pool, FPTCoin, etc.
 *
 */
contract OptionsManagerV2 is CollateralCal {
    using SafeMath for uint256;

    /**
    * @dev Options manager constructor. set other contract address
    * @param oracleAddr fnx oracle contract address.
    * @param optionsPriceAddr options price contract address
    * @param optionsPoolAddr optoins pool contract address
    * @param FPTCoinAddr FPTCoin contract address
    */
    constructor (address oracleAddr,address optionsPriceAddr,address optionsPoolAddr,address collateralPoolAddr,address FPTCoinAddr) public{
        _oracle = IFNXOracle(oracleAddr);
        _optionsPrice = IOptionsPrice(optionsPriceAddr);
        _optionsPool = IOptionsPool(optionsPoolAddr);
        _collateralPool = ICollateralPool(collateralPoolAddr);
        _FPTCoin = IFPTCoin(FPTCoinAddr);
    }
    function initialize() onlyOwner public {
        
    }
    function update() onlyOwner public {
        
    }
    /**
    * @dev retrieve input price valid range rate, thousandths.
    */ 
    function getPriceRateRange() public view returns(uint256,uint256) {
        return (minPriceRate,maxPriceRate);
    }
    /**
    * @dev set input price valid range rate, thousandths.
    */ 
    function setPriceRateRange(uint256 _minPriceRate,uint256 _maxPriceRate) public onlyOwner{
        require(_minPriceRate<_maxPriceRate,"minimum Price rate must be smaller than maximum price rate");
        minPriceRate = _minPriceRate;
        maxPriceRate = _maxPriceRate;
    }
    /**
    * @dev check user input price is in valid range.
    * @param strikePrice user input strikePrice
    * @param underlyingPrice current underlying price.
    */ 
    function checkStrikePrice(uint256 strikePrice,uint256 underlyingPrice)internal view{
        require(underlyingPrice*maxPriceRate/1000>=strikePrice && underlyingPrice*minPriceRate/1000<=strikePrice,
                "strikePrice is out of price range");
    }
    /**
    * @dev user buy option and create new option.
    * @param settlement user's settement coin address
    * @param settlementAmount amount of settlement user want fo pay.
    * @param strikePrice user input option's strike price
    * @param underlying user input option's underlying id, 1 for BTC,2 for ETH
    * @param expiration user input expiration,time limit from now
    * @param amount user input amount of new option user want to buy.
    * @param optType user input option type
    */ 
    function buyOption(address settlement,uint256 settlementAmount, uint256 strikePrice,uint32 underlying,
                uint32 expiration,uint256 amount,uint8 optType) nonReentrant notHalted InRange(amount) public payable{
        uint256 type_ly_expiration = optType+(uint256(underlying)<<64)+(uint256(expiration)<<128);
        (uint256 settlePrice,uint256 underlyingPrice) = oracleAssetAndUnderlyingPrice(settlement,underlying);
        checkStrikePrice(strikePrice,underlyingPrice);
        uint256 optRate = _getOptionsPriceRate(underlyingPrice,strikePrice,amount,optType);

        uint256 optPrice = _optionsPool.createOptions(msg.sender,settlement,type_ly_expiration,
            uint128(strikePrice),uint128(underlyingPrice),uint128(amount),uint128((settlePrice<<32)/optRate));
        optPrice = (optPrice*optRate)>>32;
        buyOption_sub(settlement,settlementAmount,optPrice,settlePrice,amount);
    }
    /**
    * @dev subfunction of buy option.
    * @param settlement user's settement coin address
    * @param settlementAmount amount of settlement user want fo pay.
    * @param optionPrice new option's price
    * @param amount user input amount of new option user want to buy.
    */ 
    function buyOption_sub(address settlement,uint256 settlementAmount,
            uint256 optionPrice,uint256 settlePrice,uint256 amount)internal{
        settlementAmount = getPayableAmount(settlement,settlementAmount);
        amount = uint256(uint128(amount));
        uint256 allPay = amount*optionPrice;
        uint256 allPayUSd = allPay/1e8;
        allPay = allPay/settlePrice;
        _collateralPool.buyOptionsPayfor(msg.sender,settlement,settlementAmount,allPay);
        //_FPTCoin.addMinerBalance(msg.sender,allPayUSd);
        emit BuyOption(msg.sender,settlement,optionPrice,allPay,amount); 
    }
    /**
    * @dev User sell option.
    * @param optionsId option's ID which was wanted to sell, must owned by user
    * @param amount user input amount of option user want to sell.
    */ 
    function sellOption(uint256 optionsId,uint256 amount) nonReentrant notHalted InRange(amount) public{
        require(false,"sellOption is not supported");
        // (,,uint8 optType,uint32 underlying,uint256 expiration,uint256 strikePrice,) = _optionsPool.getOptionsById(optionsId);
        // expiration = expiration.sub(now);
        // uint256 currentPrice = oracleUnderlyingPrice(underlying);
        // uint256 optPrice = _optionsPrice.getOptionsPrice(currentPrice,strikePrice,expiration,underlying,optType);
        // _optionsPool.burnOptions(msg.sender,optionsId,amount,optPrice);
        // uint256 allPay = optPrice*amount;
        // (address settlement,uint256 fullPay) = _optionsPool.getBurnedFullPay(optionsId,amount);
        // _collateralPool.addNetWorthBalance(settlement,int256(fullPay));
        // _paybackWorth(allPay,1);
        // emit SellOption(msg.sender,optionsId,amount,allPay);
    }
    /**
    * @dev User exercise option.
    * @param optionsId option's ID which was wanted to exercise, must owned by user
    * @param amount user input amount of option user want to exercise.
    */ 
    function exerciseOption(uint256 optionsId,uint256 amount) nonReentrant notHalted InRange(amount) public{
        uint256 allPay = _optionsPool.getExerciseWorth(optionsId,amount);
        require(allPay > 0,"This option cannot exercise");
        (,,uint8 optType,uint32 underlying,uint256 expiration,uint256 strikePrice,) = _optionsPool.getOptionsById(optionsId);
        expiration = expiration.sub(now);
        uint256 currentPrice = oracleUnderlyingPrice(underlying);
        uint256 optPrice = _optionsPrice.getOptionsPrice(currentPrice,strikePrice,expiration,underlying,optType);
        _optionsPool.burnOptions(msg.sender,optionsId,amount,optPrice);
        (address settlement,uint256 fullPay) = _optionsPool.getBurnedFullPay(optionsId,amount);
        _collateralPool.addNetWorthBalance(settlement,int256(fullPay));
        _paybackWorth(allPay,2);
        emit ExerciseOption(msg.sender,optionsId,amount,allPay);
    }
    function getOptionsPrice(uint256 underlyingPrice, uint256 strikePrice, uint256 expiration,
                    uint32 underlying,uint256 amount,uint8 optType) public view returns(uint256){  
        require(underlyingPrice<1e40 && strikePrice < 1e40 && expiration < 1e30 && amount < 1e40 , "Input number is too large");
        uint256 ratio = _getOptionsPriceRate(underlyingPrice,strikePrice,amount,optType);
        uint256 optPrice = _optionsPrice.getOptionsPrice(underlyingPrice,strikePrice,expiration,underlying,optType);
        return (optPrice*ratio)>>32;
    }
    function _getOptionsPriceRate(uint256 underlyingPrice, uint256 strikePrice,uint256 amount,uint8 optType) internal view returns(uint256){
        (uint256 totalCollateral,uint256 rate) = getCollateralAndRate();
        uint256 lockedWorth = _FPTCoin.getTotalLockedWorth();
        require(totalCollateral>=lockedWorth,"collateral is insufficient!");
        totalCollateral = totalCollateral - lockedWorth;
        uint256 buyOccupied = ((optType == 0) == (strikePrice>underlyingPrice)) ? strikePrice*amount:underlyingPrice*amount;
        (uint256 callCollateral,uint256 putCollateral) = _optionsPool.getAllTotalOccupiedCollateral();
        uint256 totalOccupied = (callCollateral + putCollateral + buyOccupied)*rate/1000;
        buyOccupied = ((optType == 0 ? callCollateral : putCollateral) + buyOccupied)*rate/1000;
        require(totalCollateral>=totalOccupied,"collateral is insufficient!");
        return calOptionsPriceRatio(buyOccupied,totalOccupied,totalCollateral);
    }
    function calOptionsPriceRatio(uint256 selfOccupied,uint256 totalOccupied,uint256 totalCollateral) internal pure returns (uint256){
        //r1 + 0.5
        if (selfOccupied*2<=totalOccupied){
            return 4294967296;
        }
        uint256 r1 = (selfOccupied<<32)/totalOccupied-2147483648;
        uint256 r2 = (totalOccupied<<32)/totalCollateral*2;
        //r1*r2*1.5
        r1 = (r1*r2)>>32;
        return ((r1*r1*r1)>>64)*3+4294967296;
//        return SmallNumbers.pow(r1,r2);
    }
        // totalCollateral,OccupiedCollateral,lockedCollateral,unlockedCollateral,LeftCollateral,AvailableCollateral
    function getALLCollateralinfo(address user)public view 
        returns(uint256[] memory,int256[] memory,uint32[] memory,uint32[] memory){
        uint256[] memory values = new uint256[](13); 
        values[0] = getTotalCollateral();
        values[1] = getOccupiedCollateral();
        values[2] = _FPTCoin.getTotalLockedWorth();
        values[3] = safeSubCollateral(values[0],values[2]);
        values[4] = safeSubCollateral(values[0],values[1]);
        values[5] = safeSubCollateral(values[3],values[1]);
        values[6] = getTokenNetworth();
        values[7] = getUserPayingUsd(user);
        values[8] = _FPTCoin.totalSupply();
        values[9] = _FPTCoin.balanceOf(user);
        values[10] = calculateCollateralRate();

        (values[11],values[12]) = getPriceRateRange();
        return (values,
                _collateralPool.getAllRealBalance(whiteList),
                _collateralPool.getFeeRateAll(),
                _optionsPool.getExpirationList());
    }
}