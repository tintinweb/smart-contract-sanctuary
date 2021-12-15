/**
 *Submitted for verification at BscScan.com on 2021-12-15
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-13
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/token/BEP20/lib/IBEP20.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the BEP standard.
 */
interface IBEP20 {

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

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

// File: contracts/token/BEP20/lib/BEP20.sol



pragma solidity ^0.8.0;



/**
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of BEP20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IBEP20-approve}.
 */
contract BEP20 is Ownable, IBEP20 {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address public crowdSale;

    mapping(address => uint256) public LockedAmount;


    
    modifier onlyCrowdSaler {
        require(crowdSale != address(0),'CrowdSale address is not set!');
        require(msg.sender == crowdSale,'Invalid crowdSaler!');
        _;
    }
    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_,uint256 initialBalance,address _owner) {
       require(initialBalance > 0, "EPIXBEP20: supply cannot be zero");
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
        _totalSupply = initialBalance*10**18;
        
        _balances[_owner] += _totalSupply;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {BEP20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IBEP20-balanceOf} and {IBEP20-transfer}.
     */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IBEP20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IBEP20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account]+LockedAmount[account];
    }

    /**
     * @dev See {IBEP20-getOwner}.
     */
    function getOwner() public view override returns (address) {
        return owner();
    }
    
     /**
     * @dev See {IBEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function setCrowdSale(address _crowdSale) public onlyOwner virtual returns (bool) {
        crowdSale = _crowdSale;
        return true;
    }

    /**
     * @dev See {IBEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    
    /**
     * @dev See {IBEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transferByCrowdSaler(address sender,address recipient, uint256 amount) public onlyCrowdSaler virtual  returns (bool) {
        _transfer(sender, recipient, amount);
        return true;
    }


    /**
     * @dev See {IBEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function updateLockedAmount(address userAddress, uint256 amount,uint256 addOrSub) public onlyCrowdSaler virtual  returns (bool) {
        if(addOrSub == 1){
            LockedAmount[userAddress] += amount;
        }else{
            LockedAmount[userAddress] -= amount;
        }
        return true;
    }

    /**
     * @dev See {IBEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev See {IBEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    


    /**
     * @dev See {IBEP20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IBEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IBEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "BEP20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}




// File: contracts/token/BEP20/EPIXBEP20.sol



pragma solidity ^0.8.0;



/**
 * @title EPIXBEP20
 * @dev Implementation of the EPIXBEP20
 */

contract EPIXBEP20 is BEP20 {   

    constructor (
        string memory name,
        string memory symbol,
        uint256 initialBalance,
        address owneraddress
    )
        BEP20(name, symbol,initialBalance,owneraddress)
        payable
    {
        
    
        
    }
}

contract CrowdSale  {
    EPIXBEP20 public EPIX_Contract;
    address public StakeOwner;
    uint256 public TotalStages;
    uint256 public TotalLockingStages;
    
    /* Staking data variables*/
    struct planStage {
        uint256 id;
        string name;
        uint256 investmentDuration; //in seconds
        uint256 stageRoundSupply;
        uint256 stageRoundSupplyReached;
        uint256 restakeReward;
    }
    
    struct investmentInfo {
        uint256 stageId;
        uint256 stakedAmount;
        bool isUnstaked;
        uint256 stakingAt;
        uint256 unstakingAt;
    }

    mapping(uint256 => planStage) public PlanStages;
    mapping(address => investmentInfo[]) public UserInvestments;
    /* Staking data variables */

    /* Locking  data variables */
    struct lockInfo {
        uint256 stageId;
        uint256 lockedAmount;
        bool isUnlocked;
        uint256 stakingAt;
        uint256 unstakingAt;
    }
    
    struct lockingStage{
        uint256 id;
        string name;
        uint256 investmentDuration; //in seconds
    }
    mapping(uint256 => lockingStage) public LockingStages;
    mapping(address => lockInfo[]) public UserLockedInvestmentsInfo;
    /* Locking  data variables */
    
    /* Restake  data variables */
    struct restakeInvestmentInfo {
        uint256 stageId;
        uint256 reStakedAmount;
        bool isUnstaked;
        uint256 stakingAt;
        uint256 unstakingAt;
    }
    mapping(address => restakeInvestmentInfo[]) public UserRestakeInvestments;
    /* Restake  data variables */

    
    event StakedEvent(address _staker,uint256 amount,uint256 investmentid);
    event StakedByLockedTokenEvent(address _staker,uint256 amount,uint256 investmentid);
    event LockedEvent(address _staker,uint256 amount,uint256 investmentid);
    event UnstakedEvent(address userAddress,uint256 investmentId);
    event UnlockedEvent(address userAddress,uint256 lockedId);

    
        
    modifier onlyOwner (){
        require(EPIX_Contract.getOwner() == msg.sender,'Unauthorized !');
        _;
    }
    
    constructor (address _EPIXTokenAddress,address _StakeOwner)  {
        
        EPIX_Contract = EPIXBEP20(_EPIXTokenAddress);
        StakeOwner = _StakeOwner;
        PlanStages[1] = planStage(1,'Stage1',12*30*24*60*60,39503882*10**18,0,5); // 1 year + 1 month
        PlanStages[2] = planStage(2,'Stage2',6*30*24*60*60,22222222*10**18,0,4); // 6 months + 1 month
        PlanStages[3] = planStage(3,'Stage3',3*30*24*60*60,14814815*10**18,0,3); // 3 months + 1 month
        PlanStages[4] = planStage(4,'Stage4',1*30*24*60*60,12121212*10**18,0,2); // 1 month + 1 month
        PlanStages[5] = planStage(5,'Stage6 for testing',3*60,11337868*10**18,0,1); // 3 minutes


        // PlanStages[1] = planStage(1,'Stage1',3*60,39503882*10**18,0,5); // 1 year
        // PlanStages[2] = planStage(2,'Stage2',3*60,22222222*10**18,0,4); // 6 months
        // PlanStages[3] = planStage(3,'Stage3',3*60,14814815*10**18,0,3); // 3 months
        // PlanStages[4] = planStage(4,'Stage4',3*60,12121212*10**18,0,2); // 1 month
        // PlanStages[5] = planStage(5,'Stage6 for testing',3*60,11337868*10**18,0,1); // 3 minutes



        TotalStages = 5;
        LockingStages[1] = lockingStage(1,'Stage1',12*30*24*60*60); // 1 year
        LockingStages[2] = lockingStage(2,'Stage2',16*30*24*60*60); // 6 months
        LockingStages[3] = lockingStage(3,'Stage3',3*30*24*60*60); // 3 months
        LockingStages[4] = lockingStage(4,'Stage4',1*30*24*60*60); // 1 month
        LockingStages[5] = lockingStage(5,'Stage5',1*7*24*60*60); // 1 week
        LockingStages[6] = lockingStage(6,'Stage6',3*60); // 3 minutes

        TotalLockingStages = 6;
    }
    
    
    function getAvailableRoundSupply(uint256 stage) public view returns (uint256){
        return PlanStages[stage].stageRoundSupply-PlanStages[stage].stageRoundSupplyReached;
    }
    
     /*
     * @dev Staking tokens .
     *     
     * Emits a {StakedEvent} event.
     *
     * Requirements:
     *
     * - `useraddress` staker address.
     * - `amount` staking amount.
     * - `stage` staking stage.
     * - `_stakingAt` staking time in seconds. It is optional.
     *- `_unstakingAt` unstaking time in seconds. It is optional.
     */
    function staking(address userAddress,uint256 amount,uint256 stage,uint256 _stakingAt,uint256 _unstakingAt) public payable onlyOwner {
        require(userAddress != address(0),'Staker address is required!');
        require(amount > 0, "You need to stake at least some tokens");
        require(getAvailableRoundSupply(stage) > 0,"Supply is not available for this stage");
        
        uint256 investmentDuration = PlanStages[stage].investmentDuration;
        uint256 stakingAt;
        uint256 unstakingAt;
        
        if(_stakingAt != 0 && _unstakingAt !=0){
            
            stakingAt = _stakingAt;
            unstakingAt = _unstakingAt;
            
        }else{
            
            stakingAt = block.timestamp;
            unstakingAt = stakingAt+investmentDuration;
        }

        UserInvestments[userAddress].push(investmentInfo(stage,amount,false,stakingAt,unstakingAt));
        PlanStages[stage].stageRoundSupplyReached += amount;
        emit StakedEvent(userAddress,amount,UserInvestments[userAddress].length);
        
    }


    function stakeByLockedTokens(address userAddress,uint256 stage,uint256 _stakingAt,uint256 _unstakingAt,uint256 lockedId) public payable onlyOwner {
        require(userAddress != address(0),'Staker address is required!');
        require(UserLockedInvestmentsInfo[userAddress][lockedId].stakingAt > 0,"Investment not exits");

        // require(amount > 0, "You need to stake at least some tokens");

        uint256 lockedAmount = UserLockedInvestmentsInfo[userAddress][lockedId].lockedAmount;

        UserLockedInvestmentsInfo[userAddress][lockedId].isUnlocked = true;
        EPIX_Contract.updateLockedAmount(userAddress, lockedAmount,2);

        uint256 nextStage;

        // uint256 stageId = UserLockedInvestmentsInfo[userAddress][lockedId].stageId;
        // if(stageId == TotalLockingStages){
        //     nextStage = 1;
        // }else{
        //     nextStage = stageId+1;
        // }
        nextStage = stage;

        uint256 totalAmounts;
        uint256 investmentDuration;
        investmentDuration = PlanStages[stage].investmentDuration+1*30*24*60*60;  
        uint256 restakeReward = PlanStages[nextStage].restakeReward;
        totalAmounts = lockedAmount+ lockedAmount*restakeReward/100;

        // totalAmounts = amount;
        

        uint256 stakingAt;
        uint256 unstakingAt;
        
        if(_stakingAt != 0 && _unstakingAt !=0){
            
            stakingAt = _stakingAt;
            unstakingAt = _unstakingAt;
        }else{
            stakingAt = block.timestamp;
            unstakingAt = stakingAt+investmentDuration;
        }
        
        
        UserInvestments[userAddress].push(investmentInfo(stage,totalAmounts,false,stakingAt,unstakingAt));
        uint256 UserInvestmentsCount = UserInvestments[userAddress].length;
        emit StakedByLockedTokenEvent(userAddress,totalAmounts,UserInvestmentsCount);
        
    }

    

    function getUserInvestmentCount(address userAddress) public view returns(uint256){
        return UserInvestments[userAddress].length;
    }

    /** @dev unStaking tokens .
     * 
     * Emits a {UnstakedEvent} event.
     *
     * Requirements:
     *
     * - `investmentId`  user investment id..
     * - `userAddress` user address.
     */
    
    function unStaking(uint256 investmentId,address userAddress) public payable  {
        
        require(msg.sender == userAddress,'Sender and userAddress are not same!');
        require(UserInvestments[userAddress][investmentId].stakingAt > 0,"Investment not exits");
        
        uint256 stakedAmount = UserInvestments[userAddress][investmentId].stakedAmount;
        
        
        require(block.timestamp > UserInvestments[userAddress][investmentId].unstakingAt ,'Staking period is not completed !');
        
        require(EPIX_Contract.balanceOf(StakeOwner) > stakedAmount ,'StakeOwner does not have funds!');
        
        UserInvestments[userAddress][investmentId].isUnstaked = true;
        
        // send the token from StakeOwner to investor
        EPIX_Contract.transferByCrowdSaler(StakeOwner,userAddress, stakedAmount);
        
        emit UnstakedEvent(userAddress,investmentId);
    }

    /** @dev reStaking tokens .
     * 
     * Emits a {RestakedEvent} event.
     *
     * Requirements:
     *
     * - `investmentId`  user investment id..
     * - `userAddress` user address.
     */
    
    function reStaking(uint256 investmentId,address userAddress) public payable  {
         
        require(UserInvestments[userAddress][investmentId].stakingAt > 0,"Investment not exits");
        
        uint256 stakedAmount = UserInvestments[userAddress][investmentId].stakedAmount;
        
        
        require(block.timestamp > UserInvestments[userAddress][investmentId].unstakingAt ,'Staking period is not completed !');
        
        require(EPIX_Contract.balanceOf(StakeOwner) > stakedAmount ,'StakeOwner does not have funds!');
        
        UserInvestments[userAddress][investmentId].isUnstaked = true;
        
        
        
        uint256 stageId = UserInvestments[userAddress][investmentId].stageId;
        uint256 nextStage;
        if(stageId == TotalStages){
            nextStage = 1;
        }else{
            nextStage = stageId+1;
        }
        uint256 investmentDuration = PlanStages[nextStage].investmentDuration;    
        uint256 restakeReward = PlanStages[nextStage].restakeReward;
        uint256 totalAmounts = stakedAmount+ stakedAmount*restakeReward/100;

        uint256 stakingAt;
        uint256 unstakingAt;

        stakingAt = block.timestamp;
        unstakingAt = stakingAt+investmentDuration;

        UserRestakeInvestments[userAddress].push(restakeInvestmentInfo(nextStage,totalAmounts,false,stakingAt,unstakingAt));
        emit UnstakedEvent(userAddress,investmentId);
    }
    
    function getUserReinvestmentCount(address userAddress) public view returns(uint256){
        return UserRestakeInvestments[userAddress].length;
    }

    function makeLocking(address userAddress,uint256 amount,uint256 stage,uint256 _stakingAt,uint256 _unstakingAt) public payable onlyOwner {
        require(userAddress != address(0),'Locker address is required!');
        require(amount > 0, "You need to stake at least some tokens");

        uint256 investmentDuration = LockingStages[stage].investmentDuration;
        uint256 stakingAt;
        uint256 unstakingAt;
        
        if(_stakingAt != 0 && _unstakingAt !=0){
            
            stakingAt = _stakingAt;
            unstakingAt = _unstakingAt;
            
        }else{
            
            stakingAt = block.timestamp;
            unstakingAt = stakingAt+investmentDuration;
        }


        UserLockedInvestmentsInfo[userAddress].push(lockInfo(stage,amount,false,stakingAt,unstakingAt));
        
        EPIX_Contract.updateLockedAmount(userAddress, amount,1);
        emit LockedEvent(userAddress,amount,UserInvestments[userAddress].length);
    }

    /** @dev unStaking tokens .
     * 
     * Emits a {UnstakedEvent} event.
     *
     * Requirements:
     *
     * - `investmentId`  user investment id..
     * - `userAddress` user address.
     */
    
    function makeUnlocking(uint256 lockedId,address userAddress) public payable  {
        
        // require(msg.sender != userAddress,'Sender and userAddress are not same!');
        require(UserLockedInvestmentsInfo[userAddress][lockedId].stakingAt > 0,"Investment not exits");
        
        uint256 lockedAmount = UserLockedInvestmentsInfo[userAddress][lockedId].lockedAmount;
        
        
        require(block.timestamp > UserLockedInvestmentsInfo[userAddress][lockedId].unstakingAt ,"Locking period is not completed !");
        
        require(EPIX_Contract.balanceOf(StakeOwner) > lockedAmount ,"StakeOwner does not have funds!");
        
        UserLockedInvestmentsInfo[userAddress][lockedId].isUnlocked = true;
        
        EPIX_Contract.updateLockedAmount(userAddress, lockedAmount,2);
        EPIX_Contract.transferByCrowdSaler(StakeOwner,userAddress, lockedAmount);
        
        emit UnlockedEvent(userAddress,lockedId);
    }

    function getUserLockedInvestmentCount(address userAddress) public view returns(uint256){
        return UserLockedInvestmentsInfo[userAddress].length;
    }
    
}