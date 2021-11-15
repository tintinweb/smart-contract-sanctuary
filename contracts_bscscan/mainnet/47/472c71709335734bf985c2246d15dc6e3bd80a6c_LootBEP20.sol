// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./others/Stakeable.sol";

/// @author @bsinicki
/// @dev Contract was not audited 
contract LootBEP20 is ERC20, ERC20Burnable, Ownable, Stakeable {
   
    /// ----- VARIABLES ----- ///

    /// @dev Max Tokens Supply
    uint256 public immutable maxSupply;

    /// @dev Is tokens minted for transaction hash
    mapping(bytes => bool) public isMinted;

    /// @dev Is Contract is verified for non-approved transactions
    mapping(address => bool) private _verifiedContracts;

    /// ----- EVENTS ----- ///

    /// @notice Emits transfered from network event
    event TransferedFromNetwork(
        address indexed _claimer,
        bytes indexed _ethTransactionHash,
        uint indexed _fromNetwork,
        uint _amount
    );

    event TransferedToNetwork(
        address indexed _sender,
        uint indexed _network,
        uint _amount
    );

    /// ----- VIEWS ----- ///

    /// @notice Returns true when contract is verified for not-approved transactions
    function verifiedContracts(address _address) external view returns (bool) {
        return _verifiedContracts[_address];
    }

    /// ----- PRIVATE METHODS ----- ///

    constructor(
        uint256 _maxSupply,
        uint256 _cycleDur,
        uint256 _minimumStake,
        uint256 _durationToUnstake,
        uint256 _maxStakingDays
    )
        ERC20("Loot Token", "LOOT")
        Stakeable(_cycleDur, _minimumStake, _durationToUnstake, _maxStakingDays)
    {
        maxSupply = _maxSupply;
    }


    function getEthSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function verifySignature(
        uint256 _amount,
        bytes memory _tzHash,
        uint _networkId,
        bytes memory _signature
    ) internal view returns (bool) {
        bytes32 messageHash = getMessageHash(_amount, _tzHash, msg.sender, _networkId);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == owner();
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        require(_signature.length == 65, "Loot: Invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    /// ----- PUBLIC METHODS ----- ///

    /// @notice Transfsfer tokens from other blockchain
    function bridgeFrom(
        uint256 _amount,
        bytes memory _tzHash,
        uint _networkId,
        bytes memory _signature
    ) external {
        require(totalSupply() + _amount <= maxSupply, "Max supply reached");
        require(!isMinted[_tzHash], "Can be used only once");
        require(
            verifySignature(_amount, _tzHash, _networkId, _signature),
            "Signature is invalid"
        );
        isMinted[_tzHash] = true;
        _mint(msg.sender, _amount);
        emit TransferedFromNetwork(msg.sender, _tzHash, _networkId, _amount);
    }

    /// @notice Add Reward Function
    function addReward(uint256 _amount) external {
        _transfer(msg.sender, address(this), _amount);
        _addReward(_amount);
    }

    /// @notice Add Stake Function
    function addStakeFor(uint256 _amount, uint256 _days, address _receiver) external {
        _transfer(msg.sender, address(this), _amount);
        _addStake(_receiver, _amount, _days);
    }

    /// @notice Extended Transfer Function, Transfers tokens when contract-transaction-sender is authorized
    function iTransferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external {
        require(_verifiedContracts[msg.sender], "Sender not authorized");
        _transfer(_from, _to, _amount);
    }

    /// @notice Finalizes unstake
    function finalizeUnstake() external {
        uint256 staked = _finalizeUnstake();
        _transfer(address(this), msg.sender, staked);
    }

    /// @notice Bridges(burns) tokens in actual blockchain and emits event
    function bridgeToNetwork(uint _amount, uint _networkId) external {
        require(_amount > 0, "Amount must be greather than zero");
        _burn(msg.sender, _amount);
        emit TransferedToNetwork(msg.sender, _networkId, _amount);
    }

    /// @notice Payouts reward to user
    function getReward(uint256[] memory _cycles) external {
        uint256 sum = _getReward(_cycles);
        _transfer(address(this), msg.sender, sum);
    }

    /// Payouts reward in tokens
    function getRewardInToken(address _address, uint256 _cycle) external {
        uint256 sum = _getRewardInToken(_address, _cycle);
        IERC20(_address).transfer(msg.sender, sum);
    }

    function getMessageHash(
        uint256 _amount,
        bytes memory _tzHash,
        address _owner,
        uint _networkId
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_amount, _tzHash, _owner, _networkId));
    }

    /// ----- OWNERS METHODS ----- ///

    function verifyContractForAll(address _address, bool _verified)
        external
        onlyOwner
    {
        _verifiedContracts[_address] = _verified;
    }

    function rescueTokens(
        address _tokenAddress,
        uint256 _amount,
        address _receiverAddress
    ) external onlyOwner {
        if (_tokenAddress == address(this)) {
            require(
                _amount <= totalSupply() - _sumStaked,
                "Cant withdraw staked tokens"
            );
        }
        IERC20(_tokenAddress).transfer(_receiverAddress, _amount);
    }

    /// @notice Initial Mint, transfers tokens from ETH blockchain to BSC
    function initialTransferMint(address[] memory _addresses, uint[] memory _amounts) external onlyOwner{
        uint len = _addresses.length;
       require(len == _amounts.length, "Loot: Arrays length error");
       require(_actualCycle == 0, "Loot: Only in first cycle");
       uint i = 0;
       for(i=0; i<len; i++){
           _mint(_addresses[i], _amounts[i]);
       }
    }

    /// @notice Initial Mint, transfers tokens from ETH blockchain to BSC
    function initialStaking(address[] memory _addresses, uint[] memory _amounts, uint[] memory _days, uint[] memory _secondsStaked) external onlyOwner{
        uint len = _addresses.length;
        require(len == _amounts.length && _amounts.length == _days.length, "Loot: Arrays length error");
        require(_actualCycle == 0, "Loot: Only in first cycle");
        uint i = 0;
        for(i=0; i<len; i++){
           _mint(address(this), _amounts[i]);
           _addStake(_addresses[i], _amounts[i], _days[i]);
           StakeMap[_addresses[i]].unstakeDate = StakeMap[_addresses[i]].unstakeDate - _secondsStaked[i];
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Staking tokens in cycles
/// @author @bsinicki
/// @dev Contract was not audited 
contract Stakeable is Ownable{

    /// ----- VARIABLES ----- ///

    /// @dev Min amount to stake
    uint internal _minStake;

    /// @dev Max stake days
    uint internal _maxStakeDays;

    /// @dev Unstake duration
    uint internal _unstakeDuration;

    /// @dev Sum of all staked tokens
    uint internal _sumStaked;

    /// @dev Sum of All Staking Power
    uint internal _sumSP;

    /// @dev Actual cycle
    uint internal _actualCycle;

    /// @dev Last cycle start date
    uint internal _actualCycleStartDate; 

    /// @dev Cycle duration
    uint internal _cycleDuration;

    /// @dev Stakes sum for each cycle
    mapping(uint => uint) internal _sumSPOnCycle;

    /// @dev Is claimed reward for address in cycle
    mapping(uint => mapping(address => bool)) internal _isClaimedForCycle;

    /// @dev Is claimed reward for user for token address for cycle , cycle=>token=>claimer_address=>bool
    mapping(uint => mapping(address => mapping(address => bool))) internal _isClaimedTokensForCycle;

    struct stakingInfo {
        uint amount; // amount of stake
        uint sp; //sp amount
        uint stakedOnCycle; // staked on cycle date
        uint unstakeDate; //when user can request unstake
        bool isUnstakeRequested; // is unstake requested
        uint withdrawDate; // date when tokens could be unstaked fully
    }

    /// @dev Stakes of each skakeholder
    mapping(address => stakingInfo) internal StakeMap;

    /// @dev The rewards for each cycle
    mapping(uint => uint) internal _rewardsInNativeToken;

    /// @dev The rewards for selected token address for each cycle
    mapping(uint => mapping(address => uint)) internal _rewardsOthers;

    /// ----- EVENTS ----- ///

    /// @notice notify when tokens are staked
    event Staked(address indexed _address, uint _staked);

    /// @notice notify when tokens are requested to unstake
    event RequestedToUnstake(address indexed _address);

    /// @notice notify when tokens are unstaked
    event Unstaked(address indexed _address, uint _unstaked);

    /// @notice notify when added rewards in tokens
    event AddedRewardInTokens(address indexed _sender, address indexed _tokenAddress, uint _amount);

    /// @notice notify when reward added
    event AddedReward(address indexed _sender, uint _amount);

    /// @notice notify when got reward
    event GotReward(address indexed _receiver, uint[] _cycles, uint _amount);

    /// @notice notify when got reward in tokens
    event GotRewardInTokens(address indexed _receiver, address indexed _tokenAddress, uint _cycle, uint _amount);

    /// @notice notify when cycle ends
    event EndedCycle(uint indexed _cycleNumber);

    /// ----- VIEWS ----- ///

    /// @notice Returns actual cycle number, start date and cycle duration
    function ActualCycle() external view returns(uint[] memory){
        uint[] memory tmp = new uint[](6);
        tmp[0] = _actualCycle;
        tmp[1] = _actualCycleStartDate;
        tmp[2] = _cycleDuration;
        tmp[3] = _minStake;
        tmp[4] = _unstakeDuration;
        tmp[5] = _maxStakeDays;
        return tmp;
    }

    function sumStaked() external view returns(uint){
        return(_sumStaked);
    }

    /// @notice Returns sum of weights of stakeholders for `_cycle` cycle
    function sumSPOnCycle(uint _cycle) external view returns(uint){
        if(_cycle == _actualCycle) return _sumSP;
        else return _sumSPOnCycle[_cycle];
    }

    /// @notice Returns true if reward for claimed for `_cycle` cycle and `_claimerAddress` address
    function isRewardClaimedForCycle(uint _cycle, address _claimerAddress) external view returns(bool){
        return _isClaimedForCycle[_cycle][_claimerAddress];
    }

    /// @notice Returns true if reward for claimed for `_cycle` cycle and `_claimerAddress` address and `_tokenAddress` token address
    function isClaimedTokensForCycle(uint _cycle, address _claimerAddress, address _tokenAddress) external view returns(bool){
        return _isClaimedTokensForCycle[_cycle][_tokenAddress][_claimerAddress];
    }

    /// @notice Returns stakingInfo objest of `_stakerAddress` stakeholder as uint(4) array where 0 - amount, 1 - staked cycle
    function stakeInfo(address _stakerAddress) external view returns(uint[] memory){
        uint[] memory tmp = new uint[](6);
        stakingInfo memory staker = StakeMap[_stakerAddress];
        uint isRequested = 0;
        if(staker.isUnstakeRequested) isRequested = 1;
        tmp[0] = staker.amount;
        tmp[1] = staker.sp;
        tmp[2] = staker.stakedOnCycle;
        tmp[3] = staker.unstakeDate;
        tmp[4] = isRequested;
        tmp[5] = staker.withdrawDate;
        return(tmp);
    }

    /// @notice Returns Sum of Rewards of `_cycle` cycle
    function RewardsOfCycle(uint _cycle) external view returns(uint){
        return _rewardsInNativeToken[_cycle];
    }

    /// @notice Returns Sum of Rewards of `_cycle` cycle and `_tokenAddress` address
    function TokensRewardsOfCycle(uint _cycle, address _tokenAddress) external view returns(uint){
        return _rewardsOthers[_cycle][_tokenAddress];
    }

    /// ----- PUBLIC METHODS ----- ///

    /** @notice A method for a stakeholder to create or add `_amount` stake  */
    /// @dev It is important to let users known that if they will add Stake to existed one they will lose prev rewards
    function _addStake(address _to, uint _amount, uint _days) internal{
        uint maxStakeDays = _maxStakeDays;
        stakingInfo memory staker = StakeMap[_to];
        require(_to!=address(0), "Stakeable: Cant stake to zero address");
        require(_amount + staker.amount >= _minStake, "Stakeable: Minimum amount required");
        require(_days <= maxStakeDays, "Stakeable: Max stake days limit");
        require(_days > 0, "Stakeable: Minimum one day stake");
        require(!staker.isUnstakeRequested, "Stakeable: Requested to unstake");
        uint actCycle = _actualCycle;
        uint newUstakeDate = block.timestamp + _days * 1 days;
        uint calculatedSP = _amount + _amount * _days/maxStakeDays;
        if(staker.amount == 0){
            staker.amount = _amount;
            staker.sp = calculatedSP;
            staker.stakedOnCycle = actCycle;
            staker.unstakeDate = newUstakeDate;
            staker.isUnstakeRequested = false;
        }
        else{
            staker.amount = staker.amount + _amount;
            staker.unstakeDate = (staker.sp * staker.unstakeDate + calculatedSP * newUstakeDate) / (staker.sp + calculatedSP);
            staker.sp = staker.sp + calculatedSP;
            staker.stakedOnCycle = actCycle;
        }
        StakeMap[_to] = staker;
        _sumStaked += _amount;
        _sumSP += calculatedSP;
        emit Staked(_to, _amount);
    }

    /** @notice A method for a stakeholder to request unstake  */
    function requestUnstake() external{
        stakingInfo memory staker = StakeMap[msg.sender];
        require(staker.amount > 0, "Stakeable: Not staker");
        require(!staker.isUnstakeRequested, "Stakeable: Already requested");
        require(staker.unstakeDate < block.timestamp, "Stakeable: Wait for unstake date");
        _sumSP -= staker.sp;
        staker.sp = 0;
        staker.withdrawDate = block.timestamp + _unstakeDuration;
        staker.isUnstakeRequested = true;
        StakeMap[msg.sender] = staker;
        emit RequestedToUnstake(msg.sender);
    }

    /** @notice A method for a stakeholder to finalize unstake  */
    function _finalizeUnstake() internal returns(uint){
        stakingInfo memory staker = StakeMap[msg.sender];
        uint staked = staker.amount;
        require(staker.amount > 0, "Stakeable: Not staker");
        require(staker.isUnstakeRequested, "Stakeable: Not requested");
        require(staker.withdrawDate < block.timestamp, "Stakeable: Wait for unstake final date");
        _sumStaked -= staker.amount;
        staker.amount = 0;
        staker.isUnstakeRequested = false;
        StakeMap[msg.sender] = staker;
        emit Unstaked(msg.sender, staked);
        return(staked);
    }

    /** @notice A method to add rewards is token to actual cycle  */
    function addRewardInTokens(address _rewardTokenAddress, uint _rewardAmount) external{
        uint actualCycle = _actualCycle;
        require(_rewardTokenAddress != address(this), "Stakeable: Please use _addReward Method");
        require(IERC20(_rewardTokenAddress).transferFrom(msg.sender, address(this), _rewardAmount));
        _rewardsOthers[actualCycle][_rewardTokenAddress] = _rewardsOthers[actualCycle][_rewardTokenAddress] + _rewardAmount;
        emit AddedRewardInTokens(msg.sender, _rewardTokenAddress, _rewardAmount);
    }

    /// @dev Function adding reward in native tokens. Need to be called extrnally 
    function _addReward(uint _rewardAmount) internal{
        _rewardsInNativeToken[_actualCycle] = _rewardsInNativeToken[_actualCycle] + _rewardAmount;
        emit AddedReward(msg.sender, _rewardAmount);
    }

    /// @dev Function for get reward in native tokens for selected cycles. Need to be called extrnally. Param _cycle need to be sorted ask. 
    function _getReward(uint[] memory _cycles) internal returns(uint){
        uint len = _cycles.length;
        uint actualCycle = _actualCycle;
        stakingInfo memory staker = StakeMap[msg.sender];
        require(actualCycle >_cycles[len-1],"Stakeable: Wait for cycle end");
        require(!_isClaimedForCycle[_cycles[0]][msg.sender], "Stakeable: Claim only once");
        require(staker.stakedOnCycle < _cycles[0], "Stakeable: Not participant of cycle");
        require(staker.sp > 0, "Stakeable: No staker");
        _isClaimedForCycle[_cycles[0]][msg.sender] = true;
        uint sum = _rewardsInNativeToken[_cycles[0]] * staker.sp / _sumSPOnCycle[_cycles[0]];
        uint index = 0;
        for(index = 1; index < len; index++){
            require(!_isClaimedForCycle[_cycles[index]][msg.sender], "Stakeable: Claim only once");
            require(_cycles[index] > _cycles[index-1], "Stakeable: Not sorted array");
            sum = sum + _rewardsInNativeToken[_cycles[index]] * staker.sp / _sumSPOnCycle[_cycles[index]];
            _isClaimedForCycle[_cycles[index]][msg.sender] = true;
        }
        emit GotReward(msg.sender, _cycles, sum);
        return sum;
    }

    /// @dev  Function for get reward in selected tokens for selected cycle. Need to be called extrnally.
    function _getRewardInToken(address _address, uint _cycle) internal returns(uint) {
        require(_actualCycle > _cycle,"Wait for cycle end");
        require(StakeMap[msg.sender].sp > 0, "Stakeable: Not staker");
        require(!_isClaimedTokensForCycle[_cycle][_address][msg.sender], "Stakeable: Claim only once");
        require(StakeMap[msg.sender].stakedOnCycle < _cycle, "Stakeable: Not participant of cycle");
        _isClaimedTokensForCycle[_cycle][_address][msg.sender] = true;
        uint sum = _rewardsOthers[_cycle][_address] * StakeMap[msg.sender].sp / _sumSPOnCycle[_cycle];
        emit GotRewardInTokens(msg.sender, _address, _cycle, sum);
        return sum;
    }

    /** @notice A method to end cycle  */
    function endCycle() external{
        uint aC = _actualCycle;
        if(aC == 0 || aC == 1){
            require(msg.sender == owner(), "Stakeable: Only owner can start first cycle");
        }
        else{
        require(_actualCycleStartDate + _cycleDuration < block.timestamp, "Stakeable: Duration error");
        require(_rewardsInNativeToken[aC] > 0, "Stakeable: No profit generated");
        }
        _sumSPOnCycle[aC] = _sumSP;
        emit EndedCycle(_actualCycle);
        _actualCycle++;
        _actualCycleStartDate = block.timestamp;
    }

    /// @dev contract constructor
    /// @param _cycleDur how long the cycle will lasts
    /// @param _minimumStake minimum stake
    /// @param _durationToUnstake duration to unstake
    /// @param _maxStakingDays max days
    constructor(uint _cycleDur, uint _minimumStake, uint _durationToUnstake, uint _maxStakingDays){
        _cycleDuration = _cycleDur;
        _minStake = _minimumStake;
        _maxStakeDays = _maxStakingDays;
        _unstakeDuration = _durationToUnstake;
        _actualCycleStartDate = block.timestamp;
    }

    /// ----- OWNERS METHODS ----- ///
    function editStakeableSettings(uint _cycleDur, uint _minimumStake, uint _durationToUnstake) external onlyOwner{
        _cycleDuration = _cycleDur;
        _minStake = _minimumStake;
        _unstakeDuration = _durationToUnstake;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
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
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
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
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
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
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
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
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
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
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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

