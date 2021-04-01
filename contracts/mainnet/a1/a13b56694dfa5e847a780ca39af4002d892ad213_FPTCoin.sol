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

// File: contracts\FPTCoin\SharedCoin.sol

pragma solidity =0.5.16;


contract SharedCoin is FPTData  {
    using SafeMath for uint256;
    function initialize() onlyOwner public{
        _totalSupply = 0;
    }
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }


    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
    public
    returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount)
    public
    returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
    public
    returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }
/*
    function burn(uint256 amount) public onlyOwner returns (bool){
        _burn(msg.sender, amount);
        return true;
    }
    function mint(address account,uint256 amount) public onlyOwner returns (bool){
        _mint(account,amount);
        return true;
    }
    */
    /**
     * @dev add `recipient`'s balance to iterable mapping balances.
     */
    function _addBalance(address recipient, uint256 amount) internal {
        require(recipient != address(0), "ERC20: transfer to the zero address");

        balances[recipient] = balances[recipient].add(amount);
    }
    /**
     * @dev add `recipient`'s balance to iterable mapping balances.
     */
    function _subBalance(address recipient, uint256 amount) internal {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        balances[recipient] = balances[recipient].sub(amount);
    }
    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _subBalance(sender,amount);
        _addBalance(recipient,amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _addBalance(account,amount);
        emit Transfer(address(0), account, amount);
    }
    /**
    * @dev Destroys `amount` tokens from `account`, reducing the
    * total supply.
    *
    * Emits a {Transfer} event with `to` set to the zero address.
    *
    * Requirements
    *
    * - `account` cannot be the zero address.
    * - `account` must have at least `amount` tokens.
    */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        _subBalance(account,amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

}

// File: contracts\FPTCoin\FPTCoin.sol

pragma solidity =0.5.16;




/**
 * @title FPTCoin is finnexus collateral Pool token, implement ERC20 interface.
 * @dev ERC20 token. Its inside value is collatral pool net worth.
 *
 */
contract FPTCoin is SharedCoin {
    using SafeMath for uint256;
    mapping (address => bool) internal timeLimitWhiteList;
    constructor (address minePoolAddr,string memory tokenName)public{
        initialize();
        //_FnxMinePool = IFNXMinePool(minePoolAddr);
        name = tokenName;
        symbol = tokenName;
    }
    /**
     * @dev constructor function. set FNX minePool contract address. 
     */ 
    function initialize() onlyOwner public{
        SharedCoin.initialize();
    }
    function update() onlyOwner public{
        timeLimitWhiteList[0xf1FF936B72499382983a8fBa9985C41cB80BE17D] = true;
    }
    /**
     * @dev Retrieve user's start time for burning. 
     * @param user user's account.
     */ 
    function getUserBurnTimeLimite(address user) public view returns (uint256){
        return getItemTimeLimitation(uint256(user));
    }
    /**
     * @dev Retrieve total locked worth. 
     */ 
    function getTotalLockedWorth() public view returns (uint256) {
        return _totalLockedWorth;
    }
    /**
     * @dev Retrieve user's locked balance. 
     * @param account user's account.
     */ 
    function lockedBalanceOf(address account) public view returns (uint256) {
        return lockedBalances[account];
    }
    /**
     * @dev Retrieve user's locked net worth. 
     * @param account user's account.
     */ 
    function lockedWorthOf(address account) public view returns (uint256) {
        return lockedTotalWorth[account];
    }
    /**
     * @dev Retrieve user's locked balance and locked net worth. 
     * @param account user's account.
     */ 
    function getLockedBalance(address account) public view returns (uint256,uint256) {
        return (lockedBalances[account],lockedTotalWorth[account]);
    }
    /**
     * @dev Interface to manager FNX mine pool contract, add miner balance when user has bought some options. 
     * @param account user's account.
     * @param amount user's pay for buying options, priced in USD.
     */ 
    function addMinerBalance(address account,uint256 amount) public onlyOwner{
        if (amount == 0){
            timeLimitWhiteList[account] = false;
        }else{
            timeLimitWhiteList[account] = true;
        }
        //_FnxMinePool.addMinerBalance(account,amount);
    }
    function setTransferTimeLimitation(address from,address recipient) internal {
        if (!timeLimitWhiteList[from]){
            setItemTimeLimitation(uint256(recipient));
        }
    }
    /**
     * dev Burn user's locked balance, when user redeem collateral. 
     * param account user's account.
     * param amount amount of burned FPT.
 
    function burnLocked(address account, uint256 amount) public onlyManager{
        require(latestTransferIn[account]+timeLimited<now,"FPT coin locked time is not expired!");
        uint256 lockedAmount = lockedBalances[account];
        require(amount<=lockedAmount,"burnLocked: balance is insufficient");
        if(lockedAmount>0){
            uint256 lockedWorth = lockedTotalWorth[account];
            if (amount == lockedAmount){
                _subLockBalance(account,lockedAmount,lockedWorth);
            }else{
                uint256 burnWorth = amount*lockedWorth/lockedAmount;
                _subLockBalance(account,amount,burnWorth);
            }
        }
    }
     */
    /**
     * @dev Move user's FPT to locked balance, when user redeem collateral. 
     * @param account user's account.
     * @param amount amount of locked FPT.
     * @param lockedWorth net worth of locked FPT.
     */ 
    function addlockBalance(address account, uint256 amount,uint256 lockedWorth)public onlyManager {
        burn(account,amount);
        _addLockBalance(account,amount,lockedWorth);
    }
    /**
     * @dev Move user's FPT to 'recipient' balance, a interface in ERC20. 
     * @param recipient recipient's account.
     * @param amount amount of FPT.
     */ 
    function transfer(address recipient, uint256 amount)public returns (bool){
        //require(address(_FnxMinePool) != address(0),"FnxMinePool is not set");
        //_FnxMinePool.transferMinerCoin(msg.sender,recipient,amount);
        setTransferTimeLimitation(msg.sender,recipient);
        return SharedCoin.transfer(recipient,amount);
    }
    /**
     * @dev Move sender's FPT to 'recipient' balance, a interface in ERC20. 
     * @param sender sender's account.
     * @param recipient recipient's account.
     * @param amount amount of FPT.
     */ 
    function transferFrom(address sender, address recipient, uint256 amount)public returns (bool){
        //require(address(_FnxMinePool) != address(0),"FnxMinePool is not set");
        //_FnxMinePool.transferMinerCoin(sender,recipient,amount);
        setTransferTimeLimitation(sender,recipient);
        return SharedCoin.transferFrom(sender,recipient,amount);
    }
    /**
     * @dev burn user's FPT when user redeem FPTCoin. 
     * @param account user's account.
     * @param amount amount of FPT.
     */ 
    function burn(address account, uint256 amount) public onlyManager OutLimitation(uint256(account)) {
        //require(address(_FnxMinePool) != address(0),"FnxMinePool is not set");
        //_FnxMinePool.burnMinerCoin(account,amount);
        SharedCoin._burn(account,amount);
    }
    /**
     * @dev mint user's FPT when user add collateral. 
     * @param account user's account.
     * @param amount amount of FPT.
     */ 
    function mint(address account, uint256 amount) public onlyManager {
        //require(address(_FnxMinePool) != address(0),"FnxMinePool is not set");
        //_FnxMinePool.mintMinerCoin(account,amount);
        setTransferTimeLimitation(address(0),account);
        SharedCoin._mint(account,amount);
    }
    /**
     * @dev An auxiliary function, add user's locked balance. 
     * @param account user's account.
     * @param amount amount of FPT.
     * @param lockedWorth net worth of FPT.
     */ 
    function _addLockBalance(address account, uint256 amount,uint256 lockedWorth)internal {
        lockedBalances[account]= lockedBalances[account].add(amount);
        lockedTotalWorth[account]= lockedTotalWorth[account].add(lockedWorth);
        _totalLockedWorth = _totalLockedWorth.add(lockedWorth);
        emit AddLocked(account, amount,lockedWorth);
    }
    /**
     * @dev An auxiliary function, deduct user's locked balance. 
     * @param account user's account.
     * @param amount amount of FPT.
     * @param lockedWorth net worth of FPT.
     */ 
    function _subLockBalance(address account,uint256 amount,uint256 lockedWorth)internal {
        lockedBalances[account]= lockedBalances[account].sub(amount);
        lockedTotalWorth[account]= lockedTotalWorth[account].sub(lockedWorth);
        _totalLockedWorth = _totalLockedWorth.sub(lockedWorth);
        emit BurnLocked(account, amount,lockedWorth);
    }
    /**
     * @dev An interface of redeem locked FPT, when user redeem collateral, only manager contract can invoke. 
     * @param account user's account.
     * @param tokenAmount amount of FPT.
     * @param leftCollateral left available collateral in collateral pool, priced in USD.
     */ 
    function redeemLockedCollateral(address account,uint256 tokenAmount,uint256 leftCollateral)public onlyManager OutLimitation(uint256(account)) returns (uint256,uint256){
        if (leftCollateral == 0){
            return(0,0);
        }
        uint256 lockedAmount = lockedBalances[account];
        uint256 lockedWorth = lockedTotalWorth[account];
        if (lockedAmount == 0 || lockedWorth == 0){
            return (0,0);
        }
        uint256 redeemWorth = 0;
        uint256 lockedBurn = 0;
        uint256 lockedPrice = lockedWorth/lockedAmount;
        if (lockedAmount >= tokenAmount){
            lockedBurn = tokenAmount;
            redeemWorth = tokenAmount*lockedPrice;
        }else{
            lockedBurn = lockedAmount;
            redeemWorth = lockedWorth;
        }
        if (redeemWorth > leftCollateral) {
            lockedBurn = leftCollateral/lockedPrice;
            redeemWorth = lockedBurn*lockedPrice;
        }
        if (lockedBurn > 0){
            _subLockBalance(account,lockedBurn,redeemWorth);
            return (lockedBurn,redeemWorth);
        }
        return (0,0);
    }
}