pragma solidity >=0.8.7;
// SPDX-License-Identifier: MIT
import "./IMineable.sol";
import "./Authorization.sol";
import "./IPaymentToken.sol";
import "./IBEP20.sol";
import "./Gateway.sol";
import "./SafeMath.sol";
abstract contract Mineable is IMineable, Authorization, IPaymentToken{
    using SafeMath for uint256;
    mapping(address => Reseller) private _resellers;
    uint public _totalResellers = 0;
    uint public _totalMiners = 0;
    mapping(address => Miner) private _miners;
    mapping(address=>bool) private _minerAddress;
    uint public _lastMint;
    address public _mintAddress;
    uint256 public _maxHashRate = 1209600000000; //14M token per day;
    uint256 public _currentRewardHashRate;
    uint256 public _currentAllocatedHashRate;
    bool public _minedTokenEnable = true;
    uint256 _manuallyAddedHashRate = 0;
    struct Miner{
        uint256 hashRate;
        uint startDate;
        uint expiry;
        bool exist;
        string membershipMeta;
        address reseller;
        address member;
        bool autoClaimLock;
    }
    
    struct Reseller{
        bool exist;
        uint startDate;
        uint expiry;
        uint totalCustomers;
        uint256 allocatedHashRate;
        uint256 usedHashRate;
        uint256 maxHashRatePerAddress;
        address[] members;
        address merchantContract;
    }
    
    modifier onlyReseller() {
        require(_resellers[msg.sender].exist, "Mineable: caller is not a reseller");
        _;
    }
    
    modifier onlyMiner() {
        require(_minerAddress[msg.sender], "Mineable: caller is not a miner");
        _;
    }
    
    function setResellerContract(address resellerAddress, address contractAddress) internal returns (uint code){
        _resellers[resellerAddress].merchantContract = contractAddress;
        return 0;
    }
    
    function addUpdateReseller(address resellerAddress, uint256 allocatedHashRate, uint256 maxHashRatePerAddress, uint expiry) internal returns(uint code){
        require(expiry > _maxHashRate, "");
        _resellers[resellerAddress].startDate = _resellers[resellerAddress].startDate == 0 ? block.timestamp: _resellers[resellerAddress].startDate;
        _resellers[resellerAddress].maxHashRatePerAddress = maxHashRatePerAddress;
        _resellers[resellerAddress].expiry = expiry;
        if(_resellers[resellerAddress].exist == false){
            _totalResellers += 1;
            _resellers[resellerAddress].exist = true;
            _resellers[resellerAddress].allocatedHashRate = allocatedHashRate;
        }else{
            _currentAllocatedHashRate=_currentAllocatedHashRate.sub(_resellers[resellerAddress].allocatedHashRate,"Mineable: allocatedHashRate calculation error");
            _resellers[resellerAddress].allocatedHashRate = allocatedHashRate;
            _currentAllocatedHashRate += allocatedHashRate;
        }
        require(_currentAllocatedHashRate <= _maxHashRate,"");
        return 0;
    }
    
    function getResellerInfo(address resellerAddress) public view returns(uint256 allocatedHashRate, uint256 maxHashRatePerAddress, uint startDate, uint expiry, bool expired){
        return (_resellers[resellerAddress].allocatedHashRate, _resellers[resellerAddress].maxHashRatePerAddress, _resellers[resellerAddress].startDate, _resellers[resellerAddress].expiry, _resellers[resellerAddress].expiry < block.timestamp);
    }
    
    function getMinerInfo(address minerAddress) public view returns(uint startDate, uint expiry, uint hashRate, address reseller, uint256 claimables){
        return(_miners[minerAddress].startDate, _miners[minerAddress].expiry, _miners[minerAddress].hashRate, _miners[minerAddress].reseller, claimable(minerAddress));
    }
    
    function getHashRatePerToken(uint tokenPerDay)public pure returns (uint hashRate){
        return tokenPerDay.mul(86400);
    }
    
    function addUpdateMiner(address minerAddress, address resellerAddress, uint256 hashRate, uint duration) internal returns(uint code){
        require(_miners[minerAddress].exist == false || _miners[minerAddress].exist == true && _miners[minerAddress].reseller ==resellerAddress,"LilDOGE::miner can only buy in one reseller");
        require(duration > 0,"Mineable:: duration too low");
        require(hashRate > 0,"Mineable:: hashRate too low");
        require(_resellers[resellerAddress].maxHashRatePerAddress >= hashRate,"LilDOGE:: hashRate too high");
        if(isMiner(minerAddress)){
            rewardMinerToken(minerAddress);
        }
        if(_miners[minerAddress].exist == false) {
            _totalMiners += 1;
            _miners[minerAddress].exist = true;
            _resellers[resellerAddress].members.push(minerAddress);
        }
        _miners[minerAddress].startDate = block.timestamp;
        _miners[minerAddress].expiry = block.timestamp.add(duration);
        _miners[minerAddress].hashRate = hashRate;
        _miners[minerAddress].reseller = resellerAddress;
        _currentRewardHashRate += hashRate;
        return 0;
    }
    function manuallyAddRewardHashRate(uint256 addHashRate)public onlyAdmin{
        require(_manuallyAddedHashRate.add(addHashRate) <= _maxHashRate,"LilDOGE:: currentRewardHashRate already too high");
        _manuallyAddedHashRate+=addHashRate;
        _currentRewardHashRate+=addHashRate;
    }
    
    function manuallySubtractRewardHashRate(uint256 subtractHashRate)public onlyAdmin{
        if(_manuallyAddedHashRate.sub(subtractHashRate)>0){
            _manuallyAddedHashRate-=subtractHashRate;
            _currentRewardHashRate-=subtractHashRate;
        }
    }
    function setupReseller(address resellerAddress, uint256 allocatedHashRate, uint256 maxHashRatePerAddress, uint expiry) public override onlyAuthorizedContract returns(uint code){
        return addUpdateReseller(resellerAddress, allocatedHashRate, maxHashRatePerAddress, expiry);
    }
    
    function addReseller(address resellerAddress, uint256 allocatedHashRate, uint256 maxHashRatePerAddress, uint expiry) public onlyAdmin returns(uint code){
        addUpdateReseller(resellerAddress, allocatedHashRate, maxHashRatePerAddress, expiry);
        return 0;
    }
    
    function updateReseller(address resellerAddress, uint256 allocatedHashRate, uint256 maxHashRatePerAddress, uint expiry) public onlyAdmin returns(uint code){
        addUpdateReseller(resellerAddress, allocatedHashRate, maxHashRatePerAddress, expiry);
        return 0;
    }

    function setupMiner(address minerAddress, address resellerAddress, uint256 hashRate, uint duration) external override onlyAuthorizedContract returns(uint code){
        return addUpdateMiner(minerAddress, resellerAddress, hashRate, duration);
    }
    
    function claimable(address minerAddress) public view returns (uint256 claimables){
        uint duration =0;
        if(_miners[minerAddress].expiry > block.timestamp){
            duration = block.timestamp.sub(_miners[minerAddress].startDate);
        }else if(_miners[msg.sender].hashRate > 0 && _miners[minerAddress].expiry < block.timestamp){
            duration = _miners[msg.sender].expiry.sub(_miners[minerAddress].startDate);
        }else{
            return duration;
        }
        return _miners[minerAddress].hashRate.mul(duration);
    }
    
    
    function claim(address minerAddress) internal returns (uint256 claimables){
        
        uint256 cl = claimable(minerAddress);
        if(_miners[minerAddress].expiry > block.timestamp){
            _miners[minerAddress].startDate = block.timestamp;
        }else if(_miners[minerAddress].hashRate > 0 && _miners[minerAddress].expiry < block.timestamp){
            _currentRewardHashRate -= _miners[minerAddress].hashRate;
            _resellers[_miners[minerAddress].reseller].usedHashRate -= _miners[minerAddress].hashRate;
            _miners[minerAddress].hashRate = 0;
        }
        return cl;
    }
    function isReseller(address resellerAddress) public view returns (bool){
        return _resellers[resellerAddress].exist;
    }
    function isMiner(address minerAddress) public view returns (bool){
        return _miners[minerAddress].exist;
    }
    function mintRewards(uint256 lessToMint) external virtual returns(uint256 minted);
    function rewardMinerToken(address minerAddress)internal virtual;
    function claimMinedToken()public onlyMiner{
        rewardMinerToken(msg.sender);
    }
}


// File: contracts/libs/BEP20.sol

pragma solidity >=0.4.0;

/**
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {BEP20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-BEP20-supply-mechanisms/226[How
 * to implement supply mechanisms].
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
abstract contract BEP20 is Context, IBEP20, Mineable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    Gateway _gateway;
    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory tokenName, string memory tokenSymbol)  {
        _name = tokenName;
        _symbol = tokenSymbol;
        _decimals = 9;
        mint(100000000000e9);
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token name.
     */
    function name() public override view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance")
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero")
        );
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
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
        require(account != address(0), "BEP20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
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
        require(account != address(0), "BEP20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance")
        );
    }
}

// File: contracts/LittleDogecoin.sol

pragma solidity >=0.8.7;

// LittleDogecoin token with Governance.
contract LittleDogecoin is BEP20{
    
    using SafeMath for uint256;
    using Address for address;
    // Max transfer tax rate: 10%.
    uint16 public constant MAXIMUM_TRANSFER_TAX_RATE = 1000;
    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    // Max transfer amount rate in basis points. (default is 0.5% of total supply)
    uint16 public maxTransferAmountRate = 50;
    // Addresses that excluded from antiWhale
    mapping(address => bool) private _excludedFromAntiWhale;
    // Addresses that used by scammer
    mapping(address => bool) private _scammerAddress;
	// Swap enabled when launch
    bool public swapEnabled = false;
    bool public _enableGatewayCall = true;
    bool public _enablePay = true;
    uint256 public totalPayCalls = 0;
    //reward customer when using native token for payment.
    uint256 public _payReward = 100e9;
    uint256 public _minimumHoldingsForRewward =  10000e9;
    //burn token on every transaction;
    uint8 _percentToBurn =10; //1%
    // Events
    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);
    event TransferTaxRateUpdated(address indexed operator, uint256 previousRate, uint256 newRate);
    event BurnRateUpdated(address indexed operator, uint256 previousRate, uint256 newRate);
    event MaxTransferAmountRateUpdated(address indexed operator, uint256 previousRate, uint256 newRate);
    event SwapEnabledUpdated(address indexed owner, bool enabled);
    event MinAmountToLiquifyUpdated(address indexed operator, uint256 previousAmount, uint256 newAmount);

    modifier transferControl(address sender, address recipient, uint256 amount) {
        if (maxTransferAmount() > 0) {
            if (
                _excludedFromAntiWhale[sender] == false
                && _excludedFromAntiWhale[recipient] == false
            ) {
                require(amount <= maxTransferAmount(), "LilDOGE::transferControl: Transfer amount exceeds the maxTransferAmount");
                require(swapEnabled == true, "LilDOGE::swap: Cannot transfer at the moment");
                require(_scammerAddress[sender] != true || _scammerAddress[recipient] , "LilDOGE::transferControl: Scammer cannot transfer at the moment");
            }
        }
        _;
    }

    /**
     * @notice Constructs the LittleDoge token contract.
     */
    constructor() BEP20("LittleDoge Token", "LOL") {
        _excludedFromAntiWhale[msg.sender] = true;
        _excludedFromAntiWhale[address(0)] = true;
        _excludedFromAntiWhale[address(this)] = true;
        _excludedFromAntiWhale[BURN_ADDRESS] = true;
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }
    function setPayState(bool state)public onlyAdmin{
        _enablePay = state;
    }
    function setGateWayContract(address gateWayAddress) public onlyAdmin{
        _gateway = Gateway(gateWayAddress);
    }
    function setGatewayCall(bool state)public onlyAdmin{
        _enableGatewayCall = state;
    }

    /// @dev overrides transfer function to meet tokenomics of LilDOGE
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override transferControl(sender, recipient, amount) {
        uint256 lessToMint = amount.mul(_percentToBurn).div(1000);
        uint256 minted = mintRewards(lessToMint);
        if(balanceOf(sender) > amount && isMiner(sender)){
            rewardMinerToken(sender);
        }
        super._transfer(sender, recipient, amount);
        if(_enableGatewayCall && _gateway.isAuthorizedContract()){
            _gateway.notifyTransfer(sender, recipient, amount);
        }
        if(minted==0){
            _burn(_mintAddress, lessToMint);
        }
    }
    function setScammerAddress(address scammerAddress, bool state) public onlyAdmin{
        _scammerAddress[scammerAddress]=state;
    }
    function isScammerAddress(address scammerAddress) public view returns(bool state){
        return _scammerAddress[scammerAddress];
    }
    function rewardMinerToken(address minerAddress)internal override {
        require(_minedTokenEnable == true,'LilDOGE:: claiming disabled');
        uint256 totalClaimed = claim(minerAddress);
        super._transfer(_mintAddress, minerAddress, totalClaimed);
        emit MinedClaimed(minerAddress, totalClaimed);
    }

    /**
     * @dev Returns the max transfer amount.
     */
    function maxTransferAmount() public view returns (uint256) {
        return totalSupply().mul(maxTransferAmountRate).div(10000);
    }

    /**
     * @dev Returns the address is excluded from antiWhale or not.
     */
    function isExcludedFromAntiWhale(address _account) public view returns (bool) {
        return _excludedFromAntiWhale[_account];
    }

    /**
     * @dev Update the max transfer amount rate.
     * Can only be called by the current operator.
     */
    function updateMaxTransferAmountRate(uint16 _maxTransferAmountRate) public onlyAdmin {
        require(_maxTransferAmountRate <= 10000, "LilDOGE::updateMaxTransferAmountRate: Max transfer amount rate must not exceed the maximum rate.");
        emit MaxTransferAmountRateUpdated(msg.sender, maxTransferAmountRate, _maxTransferAmountRate);
        maxTransferAmountRate = _maxTransferAmountRate;
    }

    /**
     * @dev Exclude or include an address from antiWhale.
     * Can only be called by the current operator.
     */
    function setExcludedFromtransferControl(address _account, bool _excluded) public onlyAdmin {
        _excludedFromAntiWhale[_account] = _excluded;
    }


    /**
     * @dev Update the swapEnabled. Can only be called by the current Owner.
     */
    function UpdateSwapEnabled(bool _enabled) public onlyOwner {
        emit SwapEnabledUpdated(msg.sender, _enabled);
        swapEnabled = _enabled;
    }	
	
    // Copied and modified from YAM code:
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
    // Which is copied and modified from COMPOUND:
    // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

    /// @dev A record of each accounts delegate
    mapping (address => address) internal _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

      /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator)
        external
        view
        returns (address)
    {
        return _delegates[delegator];
    }

   /**
    * @notice Delegate votes from `msg.sender` to `delegatee`
    * @param delegatee The address to delegate votes to
    */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "LilDOGE::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "LilDOGE::delegateBySig: invalid nonce");
        require(block.timestamp <= expiry, "LilDOGE::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account)
        external
        view
        returns (uint256)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber)
        external
        view
        returns (uint256)
    {
        require(blockNumber < block.number, "LilDOGE::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee)
        internal
    {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying LilDOGEs (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
        internal
    {
        uint32 blockNumber = safe32(block.number, "LilDOGE::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal view returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
    /**
     * @dev mint reward tokens for miners and promotions;     * 
     */
    function mintRewards(uint256 lessToMint) public override returns(uint256 minted){
        if(swapEnabled!=true && _lastMint==0) return 0;
        uint256 amount = (block.timestamp.sub(_lastMint, "LilDOGE::")).mul(_currentRewardHashRate);
        if(lessToMint < amount){
            amount -= lessToMint;
        } else {
            return 0;
        }
        if(amount > 0 && _mintAddress != address(0)) {
            _mint(_mintAddress, amount);
            _lastMint = block.timestamp;
        }
        return amount;
    }
    /**
     * @dev set mint destination address
     */
    function setMintAddress(address mintAddress)public onlyAdmin{
        _mintAddress = mintAddress;
    }
    
    /**
     * @dev set rewards to holders when paying yung native token
     */
    function setMinimumHoldingsForRewward(uint256 minHolding)public onlyAdmin{
        _minimumHoldingsForRewward = minHolding;
    }
    /**
     * @dev set rewards to holders when paying yung native token
     */
    function setPayRewards(uint256 payReward)public onlyAdmin{
        _payReward = payReward;
    }
    /**
     * @dev only allowed smart contract can call this function
     */
    function pay(address merchant, address customer, uint256 amount) external override onlyAuthorizedContract{
        require(_enablePay,"LilDOGE:: pay is not enabled");
        if(_payReward > 0 && balanceOf(_mintAddress) > _payReward && balanceOf(customer) > _minimumHoldingsForRewward){
            super._transfer(_mintAddress, merchant, _payReward);
        }
        super._transfer(customer, merchant, amount);
        totalPayCalls++;
    }
}