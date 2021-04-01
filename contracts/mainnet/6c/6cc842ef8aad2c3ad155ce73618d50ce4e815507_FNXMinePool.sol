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

// File: contracts\FNXMinePool\MinePoolData.sol

pragma solidity =0.5.16;



/**
 * @title FPTCoin mine pool, which manager contract is FPTCoin.
 * @dev A smart-contract which distribute some mine coins by FPTCoin balance.
 *
 */
contract MinePoolData is Managerable,AddressWhiteList,ReentrancyGuard {
    //Special decimals for calculation
    uint256 constant calDecimals = 1e18;
    // miner's balance
    // map mineCoin => user => balance
    mapping(address=>mapping(address=>uint256)) internal minerBalances;
    // miner's origins, specially used for mine distribution
    // map mineCoin => user => balance
    mapping(address=>mapping(address=>uint256)) internal minerOrigins;
    
    // mine coins total worth, specially used for mine distribution
    mapping(address=>uint256) internal totalMinedWorth;
    // total distributed mine coin amount
    mapping(address=>uint256) internal totalMinedCoin;
    // latest time to settlement
    mapping(address=>uint256) internal latestSettleTime;
    //distributed mine amount
    mapping(address=>uint256) internal mineAmount;
    //distributed time interval
    mapping(address=>uint256) internal mineInterval;
    //distributed mine coin amount for buy options user.
    mapping(address=>uint256) internal buyingMineMap;
    // user's Opterator indicator 
    uint256 constant internal opBurnCoin = 1;
    uint256 constant internal opMintCoin = 2;
    uint256 constant internal opTransferCoin = 3;
    /**
     * @dev Emitted when `account` mint `amount` miner shares.
     */
    event MintMiner(address indexed account,uint256 amount);
    /**
     * @dev Emitted when `account` burn `amount` miner shares.
     */
    event BurnMiner(address indexed account,uint256 amount);
    /**
     * @dev Emitted when `from` redeem `value` mineCoins.
     */
    event RedeemMineCoin(address indexed from, address indexed mineCoin, uint256 value);
    /**
     * @dev Emitted when `from` transfer to `to` `amount` mineCoins.
     */
    event TranserMiner(address indexed from, address indexed to, uint256 amount);
    /**
     * @dev Emitted when `account` buying options get `amount` mineCoins.
     */
    event BuyingMiner(address indexed account,address indexed mineCoin,uint256 amount);
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

// File: contracts\FNXMinePool\FNXMinePool.sol

pragma solidity =0.5.16;



/**
 * @title FPTCoin mine pool, which manager contract is FPTCoin.
 * @dev A smart-contract which distribute some mine coins by FPTCoin balance.
 *
 */
contract FNXMinePool is MinePoolData {
    using SafeMath for uint256;
    constructor () public{
        initialize();
    }
    function initialize() onlyOwner public{
    }
    function update() onlyOwner public{
    }
    /**
     * @dev default function for foundation input miner coins.
     */
    function()external payable{

    }
    /**
     * @dev foundation redeem out mine coins.
     * @param mineCoin mineCoin address
     * @param amount redeem amount.
     */
    function redeemOut(address mineCoin,uint256 amount)public onlyOwner{
        if (mineCoin == address(0)){
            msg.sender.transfer(amount);
        }else{
            IERC20 token = IERC20(mineCoin);
            uint256 preBalance = token.balanceOf(address(this));
            token.transfer(msg.sender,amount);
            uint256 afterBalance = token.balanceOf(address(this));
            require(preBalance - afterBalance == amount,"settlement token transfer error!");
        }
    }
    /**
     * @dev retrieve total distributed mine coins.
     * @param mineCoin mineCoin address
     */
    function getTotalMined(address mineCoin)public view returns(uint256){
        uint256 _totalSupply = totalSupply();
        uint256 _mineInterval = mineInterval[mineCoin];
        if (_totalSupply > 0 && _mineInterval>0){
            uint256 _mineAmount = mineAmount[mineCoin];
            uint256 latestMined = _mineAmount.mul(now-latestSettleTime[mineCoin])/_mineInterval;
            return totalMinedCoin[mineCoin].add(latestMined);
        }
        return totalMinedCoin[mineCoin];
    }
    /**
     * @dev retrieve minecoin distributed informations.
     * @param mineCoin mineCoin address
     * @return distributed amount and distributed time interval.
     */
    function getMineInfo(address mineCoin)public view returns(uint256,uint256){
        return (mineAmount[mineCoin],mineInterval[mineCoin]);
    }
    /**
     * @dev retrieve user's mine balance.
     * @param account user's account
     * @param mineCoin mineCoin address
     */
    function getMinerBalance(address account,address mineCoin)public view returns(uint256){
        uint256 totalBalance = minerBalances[mineCoin][account];
        uint256 _totalSupply = totalSupply();
        uint256 balance = balanceOf(account);
        if (_totalSupply > 0 && balance>0){
            uint256 tokenNetWorth = _getCurrentTokenNetWorth(mineCoin);
            totalBalance= totalBalance.add(_settlement(mineCoin,account,balance,tokenNetWorth));
        }
        return totalBalance;
    }
    /**
     * @dev Set mineCoin mine info, only foundation owner can invoked.
     * @param mineCoin mineCoin address
     * @param _mineAmount mineCoin distributed amount
     * @param _mineInterval mineCoin distributied time interval
     */
    function setMineCoinInfo(address mineCoin,uint256 _mineAmount,uint256 _mineInterval)public onlyOwner {
        require(_mineAmount<1e30,"input mine amount is too large");
        require(_mineInterval>0,"input mine Interval must larger than zero");
        _mineSettlement(mineCoin);
        mineAmount[mineCoin] = _mineAmount;
        mineInterval[mineCoin] = _mineInterval;
        addWhiteList(mineCoin);
    }
    /**
     * @dev Set the reward for buying options.
     * @param mineCoin mineCoin address
     * @param _mineAmount mineCoin reward amount
     */
    function setBuyingMineInfo(address mineCoin,uint256 _mineAmount)public onlyOwner {
//        require(_mineAmount<1e30,"input mine amount is too large");
        buyingMineMap[mineCoin] = _mineAmount;
        addWhiteList(mineCoin);
    }
    /**
     * @dev Get the reward for buying options.
     * @param mineCoin mineCoin address
     */
    function getBuyingMineInfo(address mineCoin)public view returns(uint256){
        return buyingMineMap[mineCoin];
    }
    /**
     * @dev Get the all rewards for buying options.
     */
    function getBuyingMineInfoAll()public view returns(address[] memory,uint256[] memory){
        uint256 len = whiteList.length;
        address[] memory mineCoins = new address[](len);
        uint256[] memory mineNums = new uint256[](len);
        for (uint256 i=0;i<len;i++){
            mineCoins[i] = whiteList[i];
            mineNums[i] = buyingMineMap[mineCoins[i]];
        }
        return (mineCoins,mineNums);
    }
    /**
     * @dev transfer mineCoin to recieptor when account transfer amount FPTCoin to recieptor, only manager contract can modify database.
     * @param account the account transfer from
     * @param recieptor the account transfer to
     * @param amount the mine shared amount
     */
    function transferMinerCoin(address account,address recieptor,uint256 amount) public onlyManager {
        _mineSettlementAll();
        _transferMinerCoin(account,recieptor,amount);
    }
    /**
     * @dev mint mineCoin to account when account add collateral to collateral pool, only manager contract can modify database.
     * @param account user's account
     * @param amount the mine shared amount
     */
    function mintMinerCoin(address account,uint256 amount) public onlyManager {
        _mineSettlementAll();
        _mintMinerCoin(account,amount);
        emit MintMiner(account,amount);
    }
    /**
     * @dev Burn mineCoin to account when account redeem collateral to collateral pool, only manager contract can modify database.
     * @param account user's account
     * @param amount the mine shared amount
     */
    function burnMinerCoin(address account,uint256 amount) public onlyManager {
        _mineSettlementAll();
        _burnMinerCoin(account,amount);
        emit BurnMiner(account,amount);
    }
    /**
     * @dev give amount buying reward to account, only manager contract can modify database.
     * @param account user's account
     * @param amount the buying shared amount
     */
    function addMinerBalance(address account,uint256 amount) public onlyManager {
        uint256 len = whiteList.length;
        for (uint256 i=0;i<len;i++){
            address addr = whiteList[i];
            uint256 mineNum = buyingMineMap[addr];
            if (mineNum > 0){
                uint128 mineRate = uint128(mineNum);
                uint128 mineAdd = uint128(mineNum>>128);
                uint256 _mineAmount = mineRate*amount/calDecimals + mineAdd;
                minerBalances[addr][account] = minerBalances[addr][account].add(_mineAmount);
                //totalMinedCoin[addr] = totalMinedCoin[addr].add(_mineAmount);
                emit BuyingMiner(account,addr,_mineAmount);
            }
        }
    }
    /**
     * @dev changer mine coin distributed amount , only foundation owner can modify database.
     * @param mineCoin mine coin address
     * @param _mineAmount the distributed amount.
     */
    function setMineAmount(address mineCoin,uint256 _mineAmount)public onlyOwner {
        require(_mineAmount<1e30,"input mine amount is too large");
        _mineSettlement(mineCoin);
        mineAmount[mineCoin] = _mineAmount;
    }
    /**
     * @dev changer mine coin distributed time interval , only foundation owner can modify database.
     * @param mineCoin mine coin address
     * @param _mineInterval the distributed time interval.
     */
    function setMineInterval(address mineCoin,uint256 _mineInterval)public onlyOwner {
        require(_mineInterval>0,"input mine Interval must larger than zero");
        _mineSettlement(mineCoin);
        mineInterval[mineCoin] = _mineInterval;
    }
    /**
     * @dev user redeem mine rewards.
     * @param mineCoin mine coin address
     * @param amount redeem amount.
     */
    function redeemMinerCoin(address mineCoin,uint256 amount)public nonReentrant notHalted {
        _mineSettlement(mineCoin);
        _settlementAllCoin(mineCoin,msg.sender);
        uint256 minerAmount = minerBalances[mineCoin][msg.sender];
        require(minerAmount>=amount,"miner balance is insufficient");

        minerBalances[mineCoin][msg.sender] = minerAmount-amount;
        _redeemMineCoin(mineCoin,msg.sender,amount);
    }
    /**
     * @dev subfunction for user redeem mine rewards.
     * @param mineCoin mine coin address
     * @param recieptor recieptor's account
     * @param amount redeem amount.
     */
    function _redeemMineCoin(address mineCoin,address payable recieptor,uint256 amount)internal {
        if (amount == 0){
            return;
        }
        if (mineCoin == address(0)){
            recieptor.transfer(amount);
        }else{
            IERC20 minerToken = IERC20(mineCoin);
            uint256 preBalance = minerToken.balanceOf(address(this));
            minerToken.transfer(recieptor,amount);
            uint256 afterBalance = minerToken.balanceOf(address(this));
            require(preBalance - afterBalance == amount,"settlement token transfer error!");
        }
        emit RedeemMineCoin(recieptor,mineCoin,amount);
    }
    /**
     * @dev settle all mine coin.
     */    
    function _mineSettlementAll()internal{
        uint256 addrLen = whiteList.length;
        for(uint256 i=0;i<addrLen;i++){
            _mineSettlement(whiteList[i]);
        }
    }
    /**
     * @dev the auxiliary function for _mineSettlementAll.
     */    
    function _mineSettlement(address mineCoin)internal{
        uint256 latestMined = _getLatestMined(mineCoin);
        uint256 _mineInterval = mineInterval[mineCoin];
        if (latestMined>0){
            totalMinedWorth[mineCoin] = totalMinedWorth[mineCoin].add(latestMined.mul(calDecimals));
            totalMinedCoin[mineCoin] = totalMinedCoin[mineCoin]+latestMined;
        }
        if (_mineInterval>0){
            latestSettleTime[mineCoin] = now/_mineInterval*_mineInterval;
        }else{
            latestSettleTime[mineCoin] = now;
        }
    }
    /**
     * @dev the auxiliary function for _mineSettlementAll. Calculate latest time phase distributied mine amount.
     */ 
    function _getLatestMined(address mineCoin)internal view returns(uint256){
        uint256 _mineInterval = mineInterval[mineCoin];
        uint256 _totalSupply = totalSupply();
        if (_totalSupply > 0 && _mineInterval>0){
            uint256 _mineAmount = mineAmount[mineCoin];
            uint256 mintTime = (now-latestSettleTime[mineCoin])/_mineInterval;
            uint256 latestMined = _mineAmount*mintTime;
            return latestMined;
        }
        return 0;
    }
    /**
     * @dev subfunction, transfer mineCoin to recieptor when account transfer amount FPTCoin to recieptor
     * @param account the account transfer from
     * @param recipient the account transfer to
     * @param amount the mine shared amount
     */
    function _transferMinerCoin(address account,address recipient,uint256 amount)internal{
        uint256 addrLen = whiteList.length;
        for(uint256 i=0;i<addrLen;i++){
            settleMinerBalance(whiteList[i],account,recipient,amount,opTransferCoin);
        }
        emit TranserMiner(account,recipient,amount);
    }
    /**
     * @dev subfunction, mint mineCoin to account when account add collateral to collateral pool
     * @param account user's account
     * @param amount the mine shared amount
     */
    function _mintMinerCoin(address account,uint256 amount)internal{
        uint256 addrLen = whiteList.length;
        for(uint256 i=0;i<addrLen;i++){
            settleMinerBalance(whiteList[i],account,address(0),amount,opMintCoin);
        }
    }
    /**
     * @dev subfunction, settle user's mint balance when user want to modify mine database.
     * @param mineCoin the mine coin address
     * @param account user's account
     */
    function _settlementAllCoin(address mineCoin,address account)internal{
        settleMinerBalance(mineCoin,account,address(0),0,0);
    }
    /**
     * @dev subfunction, Burn mineCoin to account when account redeem collateral to collateral pool
     * @param account user's account
     * @param amount the mine shared amount
     */
    function _burnMinerCoin(address account,uint256 amount)internal{
        uint256 addrLen = whiteList.length;
        for(uint256 i=0;i<addrLen;i++){
            settleMinerBalance(whiteList[i],account,address(0),amount,opBurnCoin);
        }
    }
    /**
     * @dev settle user's mint balance when user want to modify mine database.
     * @param mineCoin the mine coin address
     * @param account user's account
     * @param recipient the recipient's address if operator is transfer
     * @param amount the input amount for operator
     * @param operators User operator to modify mine database.
     */
    function settleMinerBalance(address mineCoin,address account,address recipient,uint256 amount,uint256 operators)internal{
        uint256 _totalSupply = totalSupply();
        uint256 tokenNetWorth = _getTokenNetWorth(mineCoin);
        if (_totalSupply > 0){
            minerBalances[mineCoin][account] = minerBalances[mineCoin][account].add(
                    _settlement(mineCoin,account,balanceOf(account),tokenNetWorth));
            if (operators == opBurnCoin){
                totalMinedWorth[mineCoin] = totalMinedWorth[mineCoin].sub(tokenNetWorth.mul(amount));
            }else if (operators==opMintCoin){
                totalMinedWorth[mineCoin] = totalMinedWorth[mineCoin].add(tokenNetWorth.mul(amount));
            }else if (operators==opTransferCoin){
                minerBalances[mineCoin][recipient] = minerBalances[mineCoin][recipient].add(
                    _settlement(mineCoin,recipient,balanceOf(recipient),tokenNetWorth));
                minerOrigins[mineCoin][recipient] = tokenNetWorth;
            }
        }
        minerOrigins[mineCoin][account] = tokenNetWorth;
    }
    /**
     * @dev subfunction, settle user's latest mine amount.
     * @param mineCoin the mine coin address
     * @param account user's account
     * @param amount the input amount for operator
     * @param tokenNetWorth the latest token net worth
     */
    function _settlement(address mineCoin,address account,uint256 amount,uint256 tokenNetWorth)internal view returns (uint256) {
        uint256 origin = minerOrigins[mineCoin][account];
        require(tokenNetWorth>=origin,"error: tokenNetWorth logic error!");
        return amount.mul(tokenNetWorth-origin)/calDecimals;
    }
    /**
     * @dev subfunction, calculate current token net worth.
     * @param mineCoin the mine coin address
     */
    function _getCurrentTokenNetWorth(address mineCoin)internal view returns (uint256) {
        uint256 latestMined = _getLatestMined(mineCoin);
        uint256 _totalSupply = totalSupply();
        if (_totalSupply > 0){
            return (totalMinedWorth[mineCoin].add(latestMined*calDecimals))/_totalSupply;
        }
        return 0;
    }
    /**
     * @dev subfunction, calculate token net worth when settlement is completed.
     * @param mineCoin the mine coin address
     */
    function _getTokenNetWorth(address mineCoin)internal view returns (uint256) {
        uint256 _totalSupply = totalSupply();
        if (_totalSupply > 0){
            return totalMinedWorth[mineCoin]/_totalSupply;
        }
        return 0;
    }
    /**
     * @dev get FPTCoin's total supply.
     */
    function totalSupply()internal view returns(uint256){
        IERC20 _FPTCoin = IERC20(getManager());
        return _FPTCoin.totalSupply();
    }
    /**
     * @dev get FPTCoin's user balance.
     */
    function balanceOf(address account)internal view returns(uint256){
        IERC20 _FPTCoin = IERC20(getManager());
        return _FPTCoin.balanceOf(account);
    }
}