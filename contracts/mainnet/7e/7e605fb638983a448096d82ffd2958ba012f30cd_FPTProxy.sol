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

// File: contracts\FNXMinePool\IFNXMinePool.sol

pragma solidity =0.5.16;

interface IFNXMinePool {
    function transferMinerCoin(address account,address recieptor,uint256 amount)external;
    function mintMinerCoin(address account,uint256 amount) external;
    function burnMinerCoin(address account,uint256 amount) external;
    function addMinerBalance(address account,uint256 amount) external;
}
contract ImportFNXMinePool is Ownable{
    IFNXMinePool internal _FnxMinePool;
    function getFNXMinePoolAddress() public view returns(address){
        return address(_FnxMinePool);
    }
    function setFNXMinePoolAddress(address fnxMinePool)public onlyOwner{
        _FnxMinePool = IFNXMinePool(fnxMinePool);
    }
}

// File: contracts\ERC20\Erc20Data.sol

pragma solidity =0.5.16;

contract Erc20Data is Ownable{
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    

    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 internal _totalSupply;
    
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

// File: contracts\modules\timeLimitation.sol

pragma solidity =0.5.16;


contract timeLimitation is Ownable {
    
    /**
     * @dev FPT has burn time limit. When user's balance is moved in som coins, he will wait `timeLimited` to burn FPT. 
     * latestTransferIn is user's latest time when his balance is moved in.
     */
    mapping(uint256=>uint256) internal itemTimeMap;
    uint256 internal limitation = 1 hours;
    /**
     * @dev set time limitation, only owner can invoke. 
     * @param _limitation new time limitation.
     */ 
    function setTimeLimitation(uint256 _limitation) public onlyOwner {
        limitation = _limitation;
    }
    function setItemTimeLimitation(uint256 item) internal{
        itemTimeMap[item] = now;
    }
    function getTimeLimitation() public view returns (uint256){
        return limitation;
    }
    /**
     * @dev Retrieve user's start time for burning. 
     * @param item item key.
     */ 
    function getItemTimeLimitation(uint256 item) public view returns (uint256){
        return itemTimeMap[item]+limitation;
    }
    modifier OutLimitation(uint256 item) {
        require(itemTimeMap[item]+limitation<now,"Time limitation is not expired!");
        _;
    }    
}

// File: contracts\FPTCoin\FPTData.sol

pragma solidity =0.5.16;




contract FPTData is Erc20Data,ImportFNXMinePool,Managerable,timeLimitation{
    /**
    * @dev lock mechanism is used when user redeem collateral and left collateral is insufficient.
    * _totalLockedWorth stores total locked worth, priced in USD.
    * lockedBalances stores user's locked FPTCoin.
    * lockedTotalWorth stores user's locked worth, priced in USD. For locked FPTCoin's net worth is constant when It was locked.
    */
    uint256 internal _totalLockedWorth;
    mapping (address => uint256) internal lockedBalances;
    mapping (address => uint256) internal lockedTotalWorth;
    /**
     * @dev Emitted when `owner` locked  `amount` FPT, which net worth is  `worth` in USD. 
     */
    event AddLocked(address indexed owner, uint256 amount,uint256 worth);
    /**
     * @dev Emitted when `owner` burned locked  `amount` FPT, which net worth is  `worth` in USD. 
     */
    event BurnLocked(address indexed owner, uint256 amount,uint256 worth);

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

// File: contracts\ERC20\Erc20BaseProxy.sol

pragma solidity =0.5.16;


/**
 * @title  Erc20Delegator Contract

 */
contract Erc20BaseProxy is baseProxy{
    constructor(address implementation_) baseProxy(implementation_) public  {
    }
    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     *  dst  The address of the destination account
     *  amount  The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
     function totalSupply() external view returns (uint256){
         delegateToViewAndReturn();
     }
    function transfer(address /*dst*/, uint /*amount*/) external returns (bool) {
        delegateAndReturn();
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     */
    function transferFrom(address /*src*/, address /*dst*/, uint256 /*amount*/) external returns (bool) {
        delegateAndReturn();
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     * @return Whether or not the approval succeeded
     */
    function approve(address /*spender*/, uint256 /*amount*/) external returns (bool) {
        delegateAndReturn();
    }

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * owner The address of the account which owns the tokens to be spent
     * spender The address of the account which may transfer tokens
     * @return The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(address /*owner*/, address /*spender*/) external view returns (uint) {
        delegateToViewAndReturn();
    }

    /**
     * @notice Get the token balance of the `owner`
     * owner The address of the account to query
     * @return The number of tokens owned by `owner`
     */
    function balanceOf(address /*owner*/) external view returns (uint) {
        delegateToViewAndReturn();
    }
}

// File: contracts\FPTCoin\FPTProxy.sol

pragma solidity =0.5.16;



/**
 * @title FPTCoin is finnexus collateral Pool token, implement ERC20 interface.
 * @dev ERC20 token. Its inside value is collatral pool net worth.
 *
 */
contract FPTProxy is FPTData,Erc20BaseProxy {
    constructor (address implementation_,address minePoolAddr,string memory tokenName) Erc20BaseProxy(implementation_) public{
        _FnxMinePool = IFNXMinePool(minePoolAddr);
        name = tokenName;
    }
    /**
     * @dev Retrieve user's start time for burning. 
     *  user user's account.
     */ 
    function getUserBurnTimeLimite(address /*user*/) public view returns (uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev Retrieve total locked worth. 
     */ 
    function getTotalLockedWorth() public view returns (uint256) {
        delegateToViewAndReturn();
    }
    /**
     * @dev Retrieve user's locked balance. 
     *  account user's account.
     */ 
    function lockedBalanceOf(address /*account*/) public view returns (uint256) {
        delegateToViewAndReturn();
    }
    /**
     * @dev Retrieve user's locked net worth. 
     *  account user's account.
     */ 
    function lockedWorthOf(address /*account*/) public view returns (uint256) {
        delegateToViewAndReturn();
    }
    /**
     * @dev Retrieve user's locked balance and locked net worth. 
     *  account user's account.
     */ 
    function getLockedBalance(address /*account*/) public view returns (uint256,uint256) {
        delegateToViewAndReturn();
    }
    /**
     * @dev Interface to manager FNX mine pool contract, add miner balance when user has bought some options. 
     *  account user's account.
     *  amount user's pay for buying options, priced in USD.
     */ 
    function addMinerBalance(address /*account*/,uint256 /*amount*/) public{
        delegateAndReturn();
    }
    /**
     * @dev Move user's FPT to locked balance, when user redeem collateral. 
     *  account user's account.
     *  amount amount of locked FPT.
     *  lockedWorth net worth of locked FPT.
     */ 
    function addlockBalance(address /*account*/, uint256 /*amount*/,uint256 /*lockedWorth*/)public {
        delegateAndReturn();
    }

    /**
     * @dev burn user's FPT when user redeem FPTCoin. 
     *  account user's account.
     *  amount amount of FPT.
     */ 
    function burn(address /*account*/, uint256 /*amount*/) public {
        delegateAndReturn();
    }
    /**
     * @dev mint user's FPT when user add collateral. 
     *  account user's account.
     *  amount amount of FPT.
     */ 
    function mint(address /*account*/, uint256 /*amount*/) public {
        delegateAndReturn();
    }
    /**
     * @dev An interface of redeem locked FPT, when user redeem collateral, only manager contract can invoke. 
     *  account user's account.
     *  tokenAmount amount of FPT.
     *  leftCollateral left available collateral in collateral pool, priced in USD.
     */ 
    function redeemLockedCollateral(address /*account*/,uint256 /*tokenAmount*/,uint256 /*leftCollateral*/)
            public returns (uint256,uint256){
        delegateAndReturn();
    }
}