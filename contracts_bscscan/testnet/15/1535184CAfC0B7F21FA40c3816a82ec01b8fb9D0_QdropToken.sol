/**
 *Submitted for verification at BscScan.com on 2021-10-26
*/

// SPDX-License-Identifier: --🦉--

//File Context.sol
pragma solidity =0.7.6;

contract Context {

    /**
     * @dev returns address executing the method
     */
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    /**
     * @dev returns data passed into the method
     */
    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

//File SafeMath.sol

pragma solidity =0.7.6;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

//File SafeMath8.sol
pragma solidity =0.7.6;

library SafeMath8 {

    function add(uint8 a, uint8 b) internal pure returns (uint8) {
        uint8 c = a + b;
        require(c >= a);
        return c;
    }

    function sub(uint8 a, uint8 b) internal pure returns (uint8) {
        require(b <= a);
        uint8 c = a - b;
        return c;
    }

    function mul(uint8 a, uint8 b) internal pure returns (uint8) {

        if (a == 0) {
            return 0;
        }

        uint8 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint8 a, uint8 b) internal pure returns (uint8) {
        require(b > 0);
        uint8 c = a / b;
        return c;
    }

    function mod(uint8 a, uint8 b) internal pure returns (uint8) {
        require(b != 0);
        return a % b;
    }
}

//File Events.sol
pragma solidity =0.7.6;

contract Events {

    event Withdraw_Reward (
        address indexed withdrawOwner,
        uint256 withdrawAmount
    );

    event Withdraw_Ido (
        address indexed withdrawOwner,
        uint256 withdrawAmount
    );

    event Withdraw_Marketing (
        address indexed withdrawOwner,
        uint256 withdrawAmount
    );

    event Withdraw_Advisor (
        address indexed withdrawOwner,
        uint256 withdrawAmount
    );

    event Withdraw_Team (
        address indexed withdrawOwner,
        uint256 withdrawAmount
    );

    event Withdraw_Strategic (
        address indexed withdrawOwner,
        uint256 withdrawAmount
    );

    event Withdraw_Private_sale (
        address indexed withdrawOwner,
        uint256 withdrawAmount
    );

    event Reward(
        address indexed to,
        uint256 value
    );

    event Claim(
        address indexed to,
        uint256 value
    );

    event Lock(
        address indexed from,
        uint256 value
    );

    event UnLock(
        address indexed from
    );
}

//File IERC20.sol
pragma solidity =0.7.6;

interface IERC20 {
    function decimals() external view returns (uint256);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function rewardAllowance(address spender)
        external
        view
        returns (uint256);

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
    function approveReward(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferReward(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

//File Ownable.sol
pragma solidity =0.7.6;
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
  address internal _owner;

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


//File QdropToken.sol
pragma solidity =0.7.6;

abstract contract BPContract{
    function protect(
        address sender,
        address receiver,
        uint256 amount
    ) external virtual;
}

contract QdropToken is Context, Ownable {

    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => mapping (address => uint256)) private _rewards;

    /**
     * @dev initial private
     */
    string private _name = "Quizdrop";
    string private _symbol = "Qdrop";
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 1000000 ether;

//    address public TaxAddress;
    address public GameRewardContract;
    address public LiquidityAddress;
    address public RewardAddress;
    address public MarketingAddress;
    address public GiveawayAddress;

    uint256 public LiquidityFee;
    uint256 public RewardFee;
    uint256 public MarketingFee;
    uint256 public GiveawayFee;
    uint256 public TaxUpperLimit;

    BPContract public BP;
    bool public bpEnabled;
    bool public BPDisabledForever = false;

    mapping (address => bool) public isExcludedFromFee;

    /**
     * @dev 👻 ghost supply - unclaimable
     */

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor () {
        _balances[_owner] = _totalSupply;
        isExcludedFromFee[_owner] = true;
        GameRewardContract = address(0x0);
        LiquidityAddress = 0x5c84A233b59c9566918a5300215596c99523b377;
        RewardAddress = 0xd7D11Ce20eA022A3f8bC4D33F58FB1b5341924D4;
        MarketingAddress = 0x1f6261e9dd44F3D2cCd2b5A7CC88b2570737b354;
        GiveawayAddress= 0xF145D57a9bB4700c79b061D00fA2133974DB3297;

        LiquidityFee = 1; //1%
        RewardFee = 2; //2%
        MarketingFee = 1; //1%
        GiveawayFee = 2; //2%
        TaxUpperLimit = 6; //6%

        emit Transfer(address(0x0), _owner, _totalSupply);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the total supply of the token.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the token balance of specific address.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function mint(address account, uint256 amount) internal returns (bool) {
        _mint(account, amount);
        return true;
    }

    function getRewardAddress() public view returns (address Address) {
        return RewardAddress;
    }

    function excludeFromFee(address address_, bool isExcluded) external onlyOwner {
        isExcludedFromFee[address_] = isExcluded;
    }
    /**
     * @dev Set Addresses and Fees For Token
     */
    function setLiquidityAddressAndFee(address newAddress,uint256 newFee) public onlyOwner {
        uint256 totalTax = RewardFee + MarketingFee + GiveawayFee + newFee;
        require(totalTax <= TaxUpperLimit, "Tax is too large.");

        LiquidityAddress = newAddress;
        LiquidityFee = newFee;
    }
    function setRewardAddressAndFee(address newAddress,uint256 newFee) public onlyOwner {
        uint256 totalTax = LiquidityFee + MarketingFee + GiveawayFee + newFee;
        require(totalTax <= TaxUpperLimit, "Tax is too large.");

        RewardAddress = newAddress;
        RewardFee = newFee;
    }
    function setMarketingAddressAndFee(address newAddress,uint256 newFee) public onlyOwner {
        uint256 totalTax = LiquidityFee + RewardFee + GiveawayFee + newFee;
        require(totalTax <= TaxUpperLimit, "Tax is too large.");

        MarketingAddress = newAddress;
        MarketingFee = newFee;
    }
    function setGiveawayAddressAndFee(address newAddress,uint256 newFee) public onlyOwner {
        uint256 totalTax = LiquidityFee + RewardFee + MarketingFee + newFee;
        require(totalTax <= TaxUpperLimit, "Tax is too large.");

        GiveawayAddress = newAddress;
        GiveawayFee = newFee;
    }
    function setGameRewardContract(address newAddress) public onlyOwner {
        GameRewardContract = newAddress;
    }

    function setBPAddrss(address _bp) external onlyOwner {
        require(address(BP)== address(0), "Can only be initialized once");
        BP = BPContract(_bp);
    }

    function setBpEnabled(bool _enabled) external onlyOwner {
        bpEnabled = _enabled;
    }

    function setBotProtectionDisableForever() external onlyOwner{
        require(BPDisabledForever == false);
        BPDisabledForever = true;
    }

    function transfer(address recipient, uint256 amount) public returns (bool)
    {
        require(amount != 0, "can not transfer 0 amount");
        require(amount <= _balances[_msgSender()]);

        _transfer(_msgSender(), recipient, amount);

        return true;
    }

    /**
     * @dev Returns approved balance to be spent by another address
     * by using transferFrom method
     */
    function allowance(address owner,address spender) public view returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev Sets the token allowance to another spender
     */
    function approve(address spender,uint256 amount) public returns (bool)
    {
        _approve(_msgSender(),spender,amount);
        return true;
    }

    /**
     * @dev Allows to transfer tokens on senders behalf
     * based on allowance approved for the executer
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool)
    {
        require(amount <= _balances[sender], "there's no allowed balance");
        require(amount <= _allowances[sender][recipient], "there's no allowed balance");
        require(recipient != address(0), "Not a valid address");
        _approve(sender, recipient, _allowances[sender][_msgSender()].sub(amount));

        if (isExcludedFromFee[sender] || isExcludedFromFee[recipient]) {
            _transfer(sender, recipient, amount);
            return true;
        }

        uint256 liquidityFee = amount.mul(LiquidityFee).div(100);
        uint256 rewardFee = amount.mul(RewardFee).div(100);
        uint256 marketFee = amount.mul(MarketingFee).div(100);
        uint256 giveawayFee = amount.mul(GiveawayFee).div(100);

        _transfer(sender, recipient, amount - liquidityFee - rewardFee - marketFee - giveawayFee);

        if(liquidityFee > 0){
            _transfer(sender, LiquidityAddress, liquidityFee);
        }
        if(rewardFee > 0){
            _transfer(sender, RewardAddress, rewardFee);
        }
        if(marketFee > 0){
            _transfer(sender, MarketingAddress, marketFee);
        }
        if(giveawayFee > 0){
            _transfer(sender, GiveawayAddress, giveawayFee);
        }

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * Emits a {Transfer} event.
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual
    {
        require(sender != address(0x0));

        require(recipient != address(0x0));

        if (bpEnabled && !BPDisabledForever){
            BP.protect(sender, recipient, amount);
        }

        _balances[sender] = _balances[sender].sub(amount);

        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual
    {
        require(account != address(0x0));

        _totalSupply = _totalSupply.add(amount);

        _balances[account] = _balances[account].add(amount);

        emit Transfer(address(0x0), account, amount );
    }

    /**
     * @dev Allows to burn tokens if token sender
     * wants to reduce totalSupply() of the token
     */
    function burn(uint256 amount) external
    {
        _burn(msg.sender, amount);
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
    function _burn(address account, uint256 amount) internal virtual
    {
        require(account != address(0x0));

        _balances[account] = _balances[account].sub(amount);

        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(account, address(0x0), amount );
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve( address owner, address spender, uint256 amount) internal virtual
    {
        require(owner != address(0x0));

        require(spender != address(0x0));

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Returns approved rewards to be claimed by another address
     * by using transferReward method
     */
    function rewardAllowance(address claimer) public view returns (uint256)
    {
        return _rewards[GameRewardContract][claimer];
    }

    /**
     * @dev Sets the token reward to player
     */
    function approveReward(address spender,uint256 amount) public returns (bool)
    {
        require(_msgSender() == GameRewardContract, "You have no permission");
        require(spender != address(0x0));
        _rewards[_msgSender()][spender] = amount;
        return true;
    }

    /**
     * @dev Allows transfer reward tokens to players
     * based on rewards approved of the executer
     */
    function transferReward(address sender, address recipient, uint256 amount) public returns (bool)
    {
        require(_msgSender() == GameRewardContract, "You have no permission");
        require(amount <= _balances[sender], "No available rewards");
        require(amount <= _rewards[_msgSender()][recipient], "You have no rewards available");
        require(recipient != address(0), "Not a valid address");

        _rewards[_msgSender()][recipient] = _rewards[_msgSender()][recipient].sub(amount);
        _transfer(sender, recipient, amount);
        return true;
    }
}

//File GameReward.sol
pragma solidity =0.7.6;

contract GameReward is Ownable, Events {
    using SafeMath for uint256;
    using SafeMath8 for uint8;

    address public qdropToken;
    QdropToken public qdropContract;

    address public qdropRewardAddress;

    uint256 constant public  unlockTaxPercentage = 5;
    address constant public lockAddress = 0x0DC2F71bc86bD691Cc267Beb42889b7b3a11c76e;
    struct DataReward {
        uint lastTimeStamp;
        uint256 totalRewards;
    }

    struct DataLock{
        bool locked;
        uint8 membership;
        uint lastLockTimeStamp;
    }

    mapping (address => DataReward) private _rewards;
    mapping (address => DataLock) private _locks;

    constructor (address _qdropToken) {
        qdropToken = _qdropToken;
        qdropContract = QdropToken(_qdropToken);
        qdropRewardAddress = qdropContract.getRewardAddress();
    }

    function getUpdatedRewardAddress() public returns(address){
       qdropRewardAddress = qdropContract.getRewardAddress();
       return qdropRewardAddress;
    }

    function claim(address _to, uint256 amount) public returns(bool){
        DataReward memory _reward = _rewards[_to];
        require(_to != address(0x0));
        uint256 balance = IERC20(qdropToken).balanceOf(qdropRewardAddress);
        require(_reward.totalRewards != 0 && _reward.totalRewards <= balance, "No available funds.");
        _rewards[_to].totalRewards = _rewards[_to].totalRewards.sub(amount);

        if(_reward.lastTimeStamp + 7 days > block.timestamp)
            amount = amount.sub(amount.mul(unlockTaxPercentage).div(100));

        _rewards[_to].lastTimeStamp = block.timestamp;
        IERC20(qdropToken).transferReward(qdropRewardAddress, _to, amount);

        emit Claim(
            _to,
            amount
        );
        return true;
    }

    function addReward(address _to, uint256 amount) public onlyOwner {
        require(_to != address(0x0));
        uint256 balance = IERC20(qdropToken).balanceOf(qdropRewardAddress);
        uint256 totalReward = IERC20(qdropToken).rewardAllowance(_to);
        require(amount <= balance, "No available funds.");
        require(IERC20(qdropToken).approveReward(_to, totalReward + amount), "Approve function does not work");
        _rewards[_to].totalRewards += amount;

        emit Reward(
            _to,
            amount
        );
    }

    function lock(address _from, uint256 amount) public returns(bool){
        require(_from != address(0x0) && !_locks[_from].locked, "Already Locked or 0x00 address");

        require(amount == 2*10**18 || amount == 4*10**18 || amount == 6*10**18 || amount == 8*10**18 || amount == 10*10**18, "Invalid Amount");

        _locks[_from].locked = true;
        _locks[_from].membership = uint8(amount.div(1 ether).div(2));
        _locks[_from].lastLockTimeStamp = block.timestamp;

        uint256 totalReward = IERC20(qdropToken).rewardAllowance(_from);
        IERC20(qdropToken).approveReward(lockAddress, totalReward + amount);
        IERC20(qdropToken).transferReward(_from, lockAddress, amount);

        emit Lock(
            _from,
            amount
        );
        return true;
    }

    function unlock(address _to) public returns(bool){
        DataLock memory _lock = _locks[_to];
        uint256 amount = uint256(_lock.membership).mul(1 ether).mul(2);
        uint256 tax;

        require(_to != address(0x0) && _lock.locked,"Wrong address or not locked");

        if(_lock.lastLockTimeStamp + 7 days > block.timestamp){
            tax = amount.mul(unlockTaxPercentage).div(100);
        }

        _locks[_to].locked = false;

        uint256 totalReward = IERC20(qdropToken).rewardAllowance(_to);
        IERC20(qdropToken).approveReward(_to, totalReward + amount.sub(tax));
        IERC20(qdropToken).transferReward(lockAddress, _to, amount.sub(tax));

        if(tax != 0){
            uint256 Reward_allowance = IERC20(qdropToken).rewardAllowance(qdropRewardAddress);
            IERC20(qdropToken).approveReward(qdropRewardAddress, Reward_allowance + tax); //
            IERC20(qdropToken).transferReward(lockAddress, qdropRewardAddress, tax);
        }

        emit UnLock(
            _to
        );

        return true;
    }

    function reward(address _to) public view returns (uint256, uint, address, address) {
        DataReward memory _reward = _rewards[_to];
        return (_reward.totalRewards, _reward.lastTimeStamp, msg.sender, qdropRewardAddress);
    }

    function checkLock(address _from) public view returns(bool, uint8, uint256){
        return (_locks[_from].locked, _locks[_from].membership, _locks[_from].lastLockTimeStamp);
    }
}