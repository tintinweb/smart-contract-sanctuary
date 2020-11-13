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

// File: contracts\CollateralPool\CollateralData.sol

pragma solidity =0.5.16;




/**
 * @title collateral pool contract with coin and necessary storage data.
 * @dev A smart-contract which stores user's deposited collateral.
 *
 */
contract CollateralData is AddressWhiteList,Managerable,Operator,ImportOptionsPool{
        // The total fees accumulated in the contract
    mapping (address => uint256) 	internal feeBalances;
    uint32[] internal FeeRates;
     /**
     * @dev Returns the rate of trasaction fee.
     */   
    uint256 constant internal buyFee = 0;
    uint256 constant internal sellFee = 1;
    uint256 constant internal exerciseFee = 2;
    uint256 constant internal addColFee = 3;
    uint256 constant internal redeemColFee = 4;
    event RedeemFee(address indexed recieptor,address indexed settlement,uint256 payback);
    event AddFee(address indexed settlement,uint256 payback);
    event TransferPayback(address indexed recieptor,address indexed settlement,uint256 payback);

    //token net worth balance
    mapping (address => int256) internal netWorthBalances;
    //total user deposited collateral balance
    // map from collateral address to amount
    mapping (address => uint256) internal collateralBalances;
    //user total paying for collateral, priced in usd;
    mapping (address => uint256) internal userCollateralPaying;
    //user original deposited collateral.
    //map account -> collateral -> amount
    mapping (address => mapping (address => uint256)) internal userInputCollateral;
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

// File: contracts\CollateralPool\CollateralProxy.sol

pragma solidity =0.5.16;


/**
 * @title  Erc20Delegator Contract

 */
contract CollateralProxy is CollateralData,baseProxy{
        /**
     * @dev constructor function , setting contract address.
     *  oracleAddr FNX oracle contract address
     *  optionsPriceAddr options price contract address
     *  ivAddress implied volatility contract address
     */  

    constructor(address implementation_,address optionsPool)
         baseProxy(implementation_) public  {
        _optionsPool = IOptionsPool(optionsPool);
    }
        /**
     * @dev Transfer colleteral from manager contract to this contract.
     *  Only manager contract can invoke this function.
     */
    function () external payable onlyManager{

    }
    function getFeeRateAll()public view returns (uint32[] memory){
        delegateToViewAndReturn();
    }
    function getFeeRate(uint256 /*feeType*/)public view returns (uint32){
        delegateToViewAndReturn();
    }
    /**
     * @dev set the rate of trasaction fee.
     *  feeType the transaction fee type
     *  numerator the numerator of transaction fee .
     *  denominator thedenominator of transaction fee.
     * transaction fee = numerator/denominator;
     */   
    function setTransactionFee(uint256 /*feeType*/,uint32 /*thousandth*/)public{
        delegateAndReturn();
    }

    function getFeeBalance(address /*settlement*/)public view returns(uint256){
        delegateToViewAndReturn();
    }
    function getAllFeeBalances()public view returns(address[] memory,uint256[] memory){
        delegateToViewAndReturn();
    }
    function redeem(address /*currency*/)public{
        delegateAndReturn();
    }
    function redeemAll()public{
        delegateAndReturn();
    }
    function calculateFee(uint256 /*feeType*/,uint256 /*amount*/)public view returns (uint256){
        delegateToViewAndReturn();
    }
        /**
     * @dev An interface for add transaction fee.
     *  Only manager contract can invoke this function.
     *  collateral collateral address, also is the coin for fee.
     *  amount total transaction amount.
     *  feeType transaction fee type. see TransactionFee contract
     */
    function addTransactionFee(address /*collateral*/,uint256 /*amount*/,uint256 /*feeType*/)public returns (uint256) {
        delegateAndReturn();
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
    function getUserInputCollateral(address /*user*/,address /*collateral*/)public view returns (uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev Retrieve collateral balance data.
     *  collateral input retrieved collateral coin address 
     */
    function getCollateralBalance(address /*collateral*/)public view returns (uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev Opterator user paying data, priced in USD. Only manager contract can modify database.
     *  user input user account which need add paying amount.
     *  amount the input paying amount.
     */
    function addUserPayingUsd(address /*user*/,uint256 /*amount*/)public{
        delegateAndReturn();
    }
    /**
     * @dev Opterator user input collateral data. Only manager contract can modify database.
     *  user input user account which need add input collateral.
     *  collateral the collateral address.
     *  amount the input collateral amount.
     */
    function addUserInputCollateral(address /*user*/,address /*collateral*/,uint256 /*amount*/)public{
        delegateAndReturn();
    }
    /**
     * @dev Opterator net worth balance data. Only manager contract can modify database.
     *  collateral available colleteral address.
     *  amount collateral net worth increase amount.
     */
    function addNetWorthBalance(address /*collateral*/,int256 /*amount*/)public{
        delegateAndReturn();
    }
    /**
     * @dev Opterator collateral balance data. Only manager contract can modify database.
     *  collateral available colleteral address.
     *  amount collateral colleteral increase amount.
     */
    function addCollateralBalance(address /*collateral*/,uint256 /*amount*/)public{
        delegateAndReturn();
    }
    /**
     * @dev Substract user paying data,priced in USD. Only manager contract can modify database.
     *  user user's account.
     *  amount user's decrease amount.
     */
    function subUserPayingUsd(address /*user*/,uint256 /*amount*/)public{
        delegateAndReturn();
    }
    /**
     * @dev Substract user's collateral balance. Only manager contract can modify database.
     *  user user's account.
     *  collateral collateral address.
     *  amount user's decrease amount.
     */
    function subUserInputCollateral(address /*user*/,address /*collateral*/,uint256 /*amount*/)public{
        delegateAndReturn();
    }
    /**
     * @dev Substract net worth balance. Only manager contract can modify database.
     *  collateral collateral address.
     *  amount the decrease amount.
     */
    function subNetWorthBalance(address /*collateral*/,int256 /*amount*/)public{
        delegateAndReturn();
    }
    /**
     * @dev Substract collateral balance. Only manager contract can modify database.
     *  collateral collateral address.
     *  amount the decrease amount.
     */
    function subCollateralBalance(address /*collateral*/,uint256 /*amount*/)public{
        delegateAndReturn();
    }
    /**
     * @dev set user paying data,priced in USD. Only manager contract can modify database.
     *  user user's account.
     *  amount user's new amount.
     */
    function setUserPayingUsd(address /*user*/,uint256 /*amount*/)public{
        delegateAndReturn();
    }
    /**
     * @dev set user's collateral balance. Only manager contract can modify database.
     *  user user's account.
     *  collateral collateral address.
     *  amount user's new amount.
     */
    function setUserInputCollateral(address /*user*/,address /*collateral*/,uint256 /*amount*/)public{
        delegateAndReturn();
    }
    /**
     * @dev set net worth balance. Only manager contract can modify database.
     *  collateral collateral address.
     *  amount the new amount.
     */
    function setNetWorthBalance(address /*collateral*/,int256 /*amount*/)public{
        delegateAndReturn();
    }
    /**
     * @dev set collateral balance. Only manager contract can modify database.
     *  collateral collateral address.
     *  amount the new amount.
     */
    function setCollateralBalance(address /*collateral*/,uint256 /*amount*/)public{
        delegateAndReturn();
    }
    /**
     * @dev Operation for transfer user's payback and deduct transaction fee. Only manager contract can invoke this function.
     *  recieptor the recieptor account.
     *  settlement the settlement coin address.
     *  payback the payback amount
     *  feeType the transaction fee type. see transactionFee contract
     */
    function transferPaybackAndFee(address payable /*recieptor*/,address /*settlement*/,uint256 /*payback*/,
            uint256 /*feeType*/)public{
        delegateAndReturn();
    }
    function buyOptionsPayfor(address payable /*recieptor*/,address /*settlement*/,uint256 /*settlementAmount*/,uint256 /*allPay*/)public onlyManager{
        delegateAndReturn();
    }
    /**
     * @dev Operation for transfer user's payback. Only manager contract can invoke this function.
     *  recieptor the recieptor account.
     *  settlement the settlement coin address.
     *  payback the payback amount
     */
    function transferPayback(address payable /*recieptor*/,address /*settlement*/,uint256 /*payback*/)public{
        delegateAndReturn();
    }
    /**
     * @dev Operation for transfer user's payback and deduct transaction fee for multiple settlement Coin.
     *       Specially used for redeem collateral.Only manager contract can invoke this function.
     *  account the recieptor account.
     *  redeemWorth the redeem worth, priced in USD.
     *  tmpWhiteList the settlement coin white list
     *  colBalances the Collateral balance based for user's input collateral.
     *  PremiumBalances the premium collateral balance if redeem worth is exceeded user's input collateral.
     *  prices the collateral prices list.
     */
    function transferPaybackBalances(address payable /*account*/,uint256 /*redeemWorth*/,
            address[] memory /*tmpWhiteList*/,uint256[] memory /*colBalances*/,
            uint256[] memory /*PremiumBalances*/,uint256[] memory /*prices*/)public {
            delegateAndReturn();
    }
    /**
     * @dev calculate user's input collateral balance and premium collateral balance.
     *      Specially used for user's redeem collateral.
     *  account the recieptor account.
     *  userTotalWorth the user's total FPTCoin worth, priced in USD.
     *  tmpWhiteList the settlement coin white list
     *  _RealBalances the real Collateral balance.
     *  prices the collateral prices list.
     */
    function getCollateralAndPremiumBalances(address /*account*/,uint256 /*userTotalWorth*/,address[] memory /*tmpWhiteList*/,
        uint256[] memory /*_RealBalances*/,uint256[] memory /*prices*/) public view returns(uint256[] memory,uint256[] memory){
            delegateToViewAndReturn();
    } 
    function getAllRealBalance(address[] memory /*whiteList*/)public view returns(int256[] memory){
        delegateToViewAndReturn();
    }
    function getRealBalance(address /*settlement*/)public view returns(int256){
        delegateToViewAndReturn();
    }
    function getNetWorthBalance(address /*settlement*/)public view returns(uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev  The foundation operator want to add some coin to netbalance, which can increase the FPTCoin net worth.
     *  settlement the settlement coin address which the foundation operator want to transfer in this contract address.
     *  amount the amount of the settlement coin which the foundation operator want to transfer in this contract address.
     */
    function addNetBalance(address /*settlement*/,uint256 /*amount*/) public payable{
        delegateAndReturn();
    }
    /**
     * @dev Calculate the collateral pool shared worth.
     * The foundation operator will invoke this function frequently
     */
    function calSharedPayment(address[] memory /*_whiteList*/) public{
        delegateAndReturn();
    }
    /**
     * @dev Set the calculation results of the collateral pool shared worth.
     * The foundation operator will invoke this function frequently
     *  newNetworth Current expired options' net worth 
     *  sharedBalances All unexpired options' shared balance distributed by time.
     *  firstOption The new first unexpired option's index.
     */
    function setSharedPayment(address[] memory /*_whiteList*/,int256[] memory /*newNetworth*/,
            int256[] memory /*sharedBalances*/,uint256 /*firstOption*/) public{
        delegateAndReturn();
    }

}