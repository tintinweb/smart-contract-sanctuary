/**
 *Submitted for verification at Etherscan.io on 2021-04-16
*/

// File: contracts\modules\SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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

// File: contracts\proxy\fnxProxy.sol

pragma solidity =0.5.16;
/**
 * @title  fnxProxy Contract

 */
contract fnxProxy {
    bytes32 private constant implementPositon = keccak256("org.Finnexus.implementation.storage");
    bytes32 private constant versionPositon = keccak256("org.Finnexus.version.storage");
    bytes32 private constant proxyOwnerPosition  = keccak256("org.Finnexus.Owner.storage");
    event Upgraded(address indexed implementation,uint256 indexed version);
    event DebugEvent(address indexed from,uint256 value1,uint256 value2);
    constructor(address implementation_,uint256 version_) public {
        // Creator of the contract is admin during initialization
        _setProxyOwner(msg.sender);
        _setImplementation(implementation_);
        _setVersion(version_);
        emit Upgraded(implementation_,version_);
        (bool success,) = implementation_.delegatecall(abi.encodeWithSignature("initialize()"));
        require(success);
    }
    /**
     * @dev Allows the current owner to transfer ownership
     * @param _newOwner The address to transfer ownership to
     */
    function transferProxyOwnership(address _newOwner) public onlyProxyOwner 
    {
        require(_newOwner != address(0));
        _setProxyOwner(_newOwner);
    }
    function _setProxyOwner(address _newOwner) internal 
    {
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, _newOwner)
        }
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
    function proxyOwner() public view returns (address owner) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            owner := sload(position)
        }
    }
    function proxyType() public pure returns (uint256){
        return 2;
    }
    /**
     * @dev Tells the address of the current implementation
     * @return address of the current implementation
     */
    function implementation() public view returns (address impl) {
        bytes32 position = implementPositon;
        assembly {
            impl := sload(position)
        }
    }
    function _setImplementation(address _newImplementation) internal 
    {
        bytes32 position = implementPositon;
        assembly {
            sstore(position, _newImplementation)
        }
    }
    function upgradeTo(address _newImplementation,uint256 version_)public onlyProxyOwner upgradeVersion(version_){
        address currentImplementation = implementation();
        require(currentImplementation != _newImplementation);
        _setImplementation(_newImplementation);
        _setVersion(version_);
        emit Upgraded(_newImplementation,version_);
        (bool success,) = _newImplementation.delegatecall(abi.encodeWithSignature("update()"));
        require(success);
    }
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyProxyOwner() {
        require (msg.sender == proxyOwner(),"proxyOwner: caller is not the proxy owner");
        _;
    }
    modifier upgradeVersion(uint256 version_) {
        require (version_>version(),"upgrade version number must greater than current version");
        _;
    }
    function () payable external {
        address _impl = implementation();
        require(_impl != address(0));

        assembly {
        let ptr := mload(0x40)
        calldatacopy(ptr, 0, calldatasize)
        let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
        let size := returndatasize
        returndatacopy(ptr, 0, size)

        switch result
        case 0 { revert(ptr, size) }
        default { return(ptr, size) }
        }
    }
}

// File: contracts\leveragedPool\ILeveragedPool.sol

pragma solidity =0.5.16;
interface ILeveragedPool {
    function leverageTokens() external view returns (address,address);
    function setOracleAddress(address oracle)external;
    function setFeeAddress(address payable addrFee) external;
    function setLeverageFee(uint64 buyFee,uint64 sellFee,uint64 rebalanceFee) external;
    function setHedgeFee(uint64 buyFee,uint64 sellFee,uint64 rebalanceFee) external;
    function setLeveragePoolInfo(address payable _feeAddress,address rebaseImplement,uint256 rebaseVersion,address leveragePool,address hedgePool,address oracle,address swapRouter,
        uint256 fees,uint256 liquidateThreshold,uint256 rebaseWorth,string calldata baseCoinName)  external;
    function rebalance() external;
}

// File: contracts\stakePool\IStakePool.sol

pragma solidity =0.5.16;
interface IStakePool {
    function poolToken()external view returns (address);
    function loan(address account) external view returns(uint256);
    function FPTCoin()external view returns (address);
    function interestRate()external view returns (uint64);
    function poolBalance() external view returns (uint256);
    function borrow(uint256 amount) external returns(uint256);
    function borrowAndInterest(uint256 amount) external returns(uint256);
    function repay(uint256 amount) external payable;
    function repayAndInterest(uint256 amount) external payable returns(uint256);
    function setPoolInfo(address fptToken,address stakeToken,uint64 interestrate) external;
}

// File: contracts\ERC20\IERC20.sol

pragma solidity =0.5.16;
/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
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
     * EXTERNAL FUNCTION
     *
     * @dev change token name
     * @param _name token name
     * @param _symbol token symbol
     *
     */
    function changeTokenName(string calldata _name, string calldata _symbol)external;

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

// File: contracts\LeveragedManager\leveragedFactroy.sol

pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * FinNexus
 * Copyright (C) 2020 FinNexus Options Protocol
 */







/**
 * @title FNX period mine pool.
 * @dev A smart-contract which distribute some mine coins when user stake FPT-A and FPT-B coins.
 *
 */
contract leveragedFactroy is Ownable{
    using SafeMath for uint256;
    mapping(address=>address payable) public stakePoolMap;
    mapping(bytes32=>address payable) public leveragePoolMap;

    string public baseCoinName;

    address public stakePoolImpl;
    uint256 public stakePoolVersion;

    address public leveragePoolImpl;
    uint256 public leveragePoolVersion;

    address public FPTCoinImpl;
    uint256 public FPTCoinVersion;

    address public rebaseTokenImpl;
    uint256 public rebaseTokenVersion;

    address public fnxOracle;
    address public uniswap;

    address payable public feeAddress;

    //feeDecimals = 8; 
    uint64 public buyFee;
    uint64 public sellFee;
    uint64 public rebalanceFee;
    uint64 public interestRate;
    uint64 public liquidateThreshold;


    address payable[] public fptCoinList;
    address payable[] public stakePoolList;
    address payable[] public leveragePoolList;
    constructor() public {

    } 
    function initFactroryInfo(string memory _baseCoinName,address _stakePoolImpl,address _leveragePoolImpl,address _FPTCoinImpl,
        address _rebaseTokenImpl,address _fnxOracle,address _uniswap,address payable _feeAddress,
             uint64 _buyFee, uint64 _sellFee, uint64 _rebalanceFee,uint64 _liquidateThreshold,uint64 _interestRate) public onlyOwner{
                baseCoinName = _baseCoinName;
                stakePoolImpl = _stakePoolImpl;
                leveragePoolImpl = _leveragePoolImpl;
                FPTCoinImpl = _FPTCoinImpl;
                rebaseTokenImpl = _rebaseTokenImpl;
                fnxOracle = _fnxOracle;
                uniswap = _uniswap;
                feeAddress = _feeAddress;
                buyFee = _buyFee;
                sellFee = _sellFee;
                rebalanceFee = _rebalanceFee;
                liquidateThreshold = _liquidateThreshold;
                interestRate = _interestRate;
             }
    function createLeveragePool(address tokenA,address tokenB,uint64 leverageRatio,
        uint128 leverageRebaseWorth,uint128 hedgeRebaseWorth)external 
        onlyOwner returns (address payable _leveragePool){
        bytes32 poolKey = getPairHash(tokenA,tokenB,leverageRatio);
        _leveragePool = leveragePoolMap[poolKey];
        if(_leveragePool == address(0)){
            _leveragePool = createLeveragePool_sub(getStakePool(tokenA),getStakePool(tokenB),leverageRatio,leverageRebaseWorth,hedgeRebaseWorth);
            leveragePoolMap[poolKey] = _leveragePool;
            leveragePoolList.push(_leveragePool);
        }
    }
    function createLeveragePool_sub(address _stakePoolA,address _stakePoolB,uint64 leverageRatio,
        uint256 leverageRebaseWorth,uint256 hedgeRebaseWorth)internal returns (address payable _leveragePool){
        require(_stakePoolA!=address(0) && _stakePoolB!=address(0),"Stake pool is not created");
        ILeveragedPool newPool = ILeveragedPool(address(new fnxProxy(leveragePoolImpl,leveragePoolVersion)));
        newPool.setLeveragePoolInfo(feeAddress,rebaseTokenImpl,leveragePoolVersion,_stakePoolA,_stakePoolB,
            fnxOracle,uniswap,uint256(buyFee)+(uint256(sellFee)<<64)+(uint256(rebalanceFee)<<128)+(uint256(leverageRatio)<<192),
            liquidateThreshold,leverageRebaseWorth+(hedgeRebaseWorth<<128),baseCoinName);
        _leveragePool = address(uint160(address(newPool)));
    }
    function getLeveragePool(address tokenA,address tokenB,uint256 leverageRatio)external 
        view returns (address _stakePoolA,address _stakePoolB,address _leveragePool){
        _stakePoolA = stakePoolMap[tokenA];
        _stakePoolB = stakePoolMap[tokenB];
        bytes32 poolKey = getPairHash(tokenA,tokenB,leverageRatio);
        _leveragePool = leveragePoolMap[poolKey];
    }
    function getStakePool(address token)public view returns (address _stakePool){
        _stakePool = stakePoolMap[token];
    }
    function getAllStakePool()external view returns (address payable[] memory){
        return stakePoolList;
    }
    function getAllLeveragePool()external view returns (address payable[] memory){
        return leveragePoolList;
    }
    function rebalanceAll()external onlyOwner {
        uint256 len = leveragePoolList.length;
        for(uint256 i=0;i<len;i++){
            ILeveragedPool(leveragePoolList[i]).rebalance();
        }
    }
    function getPairHash(address tokenA,address tokenB,uint256 leverageRatio) internal pure returns (bytes32) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        return keccak256(abi.encodePacked(token0, token1,leverageRatio));
    }
    function createStatePool(address token,uint64 _interestrate)public returns(address payable){
        address payable stakePool = stakePoolMap[token];
        if(stakePool == address(0)){
            address fptCoin = createFptCoin(token);
            fnxProxy newPool = new fnxProxy(stakePoolImpl,stakePoolVersion);
            stakePool = address(newPool);
            IStakePool(stakePool).setPoolInfo(fptCoin,token,_interestrate);
            Managerable(fptCoin).setManager(stakePool);
            stakePoolMap[token] = stakePool;
            stakePoolList.push(stakePool);
            
        }
        return stakePool;
    }
    function createFptCoin(address token)internal returns(address){
        fnxProxy newCoin = new fnxProxy(FPTCoinImpl,FPTCoinVersion);
        fptCoinList.push(address(newCoin));
        string memory tokenName = (token == address(0)) ? string(abi.encodePacked("FPT_", baseCoinName)):
                 string(abi.encodePacked("FPT_",IERC20(token).symbol()));
        IERC20(address(newCoin)).changeTokenName(tokenName,tokenName);
        return address(newCoin);
    }
    function upgradeStakePool(address _stakePoolImpl,uint256 _stakePoolVersion) public onlyOwner{
        uint256 len = stakePoolList.length;
        for(uint256 i = 0;i<len;i++){
            fnxProxy(stakePoolList[i]).upgradeTo(_stakePoolImpl,_stakePoolVersion);
        }
        stakePoolImpl = _stakePoolImpl;
        stakePoolVersion = _stakePoolVersion;
    }
    function upgradeLeveragePool(address _leveragePoolImpl,uint256 _leveragePoolVersion) public onlyOwner{
        uint256 len = leveragePoolList.length;
        for(uint256 i = 0;i<len;i++){
            fnxProxy(leveragePoolList[i]).upgradeTo(_leveragePoolImpl,_leveragePoolVersion);
        }
        leveragePoolImpl = _leveragePoolImpl;
        leveragePoolVersion = _leveragePoolVersion;
    }
    function upgradeFPTCoin(address _FPTCoinImpl,uint256 _FPTCoinVersion) public onlyOwner{
        uint256 len = fptCoinList.length;
        for(uint256 i = 0;i<len;i++){
            fnxProxy(fptCoinList[i]).upgradeTo(_FPTCoinImpl,_FPTCoinVersion);
        }
        FPTCoinImpl = _FPTCoinImpl;
        FPTCoinVersion = _FPTCoinVersion;
    }
    function upgradeRebaseToken(address _rebaseTokenImpl,uint256 _rebaseTokenVersion) public onlyOwner{
        uint256 len = leveragePoolList.length;
        for(uint256 i = 0;i<len;i++){
            (address leverageToken,address hedgeToken) = ILeveragedPool(leveragePoolList[i]).leverageTokens();
            fnxProxy(address(uint160(leverageToken))).upgradeTo(_rebaseTokenImpl,_rebaseTokenVersion);
            fnxProxy(address(uint160(hedgeToken))).upgradeTo(_rebaseTokenImpl,_rebaseTokenVersion);
        }
        rebaseTokenImpl = _rebaseTokenImpl;
        rebaseTokenVersion = _rebaseTokenVersion;
    }
    function setFnxOracle(address _fnxOracle) public onlyOwner{
        fnxOracle = _fnxOracle;
        uint256 len = leveragePoolList.length;
        for(uint256 i=0;i<len;i++){
            ILeveragedPool(leveragePoolList[i]).setOracleAddress(_fnxOracle);
        }
    }
}