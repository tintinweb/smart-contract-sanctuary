/**
 *Submitted for verification at BscScan.com on 2021-10-04
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**

 * `````````.```````...`````....````....`````..........`````....````....`````....`````.....````````.
 * ```````...``````...```````..````...````.....-:/+/:-....````...````....`````....````......````````
 * ``````...``````....``````..````...````..-+syyyysyyyso/...````..````...`````....`````.....````````
 * `````....``````...``````...```...```...+yyyyys:.+syyyys:...``...````...`````...`````......```````
 * `````....``````...``````..````..```..`+yyyys/``.`.oyyyys-..```...```...`````....````......```````
 * `````....``````...`````...````..```...yyyy+.`:-.--`:syyy/...``...```....````....``````....```````
 * `````....``````...`````...````..```..`sys:`-:.```-:../sy:...``...```...`````....``````....```````
 * ```````..``````...`````...````...```..:ss+o+///////so+s+...```...```...`````....`````.....```````
 * ```````..``````....`````...````..```...-oyyyyyyyyyyyys/...```...```....`````...``````.....```````
 * ```````..``````....`````...````...````...:+ossyyyso+:....```...``.-:-.`````....``````....````````
 * ````````..``````....`````...``````..````.....-----.....````...`+so//oo:://///-``````.....```````.
 * ````````..```````....`````....`````...```````.....``````....```:-...`.--....-:`````.....````````.
 * :////:-:++-......`.....````....``````.....``````````......````../..`````....``````..../h-``````..
 * mmNNmmmmmmmmmmmmmddhysosyysyysyhddddyo+/-.............`````-/+sydhs/-.--:/+++///:::::+yhyyyhddddm
 * NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNmmmdhhhhhysoooo+oshmNNNNNNNNNNmmmNNNNNNmmmmmmmmNNNNNNNNNNN
 * NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
 *
 *                        .---.  _        _              .--.             
 *                        : .; ::_;      :_;            : .--'            
 *                        :   .'.-. .--. .-.,-.,-. .--. `. `. .-..-.,-.,-.
 *                        : :.`.: :`._-.': :: ,. :' .; : _`, :: :; :: ,. :
 *                        :_;:_;:_;`.__.':_;:_;:_;`._. ;`.__.'`.__.':_;:_;
 *                                                 .-. :                  
 *                                                 `._.'                  
 * 
 *  https://risingsun.finance/
 */

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

/**
 * Simple locked staking contract with static percentage rewards.
 * https://risingsun.finance/
 */
contract RisingSunSoloStaking is Auth, Pausable {

    address public token;

    struct StakeOption {
        uint40 lockPeriod;        // seconds
        uint16 bonusPercentage;   // 10000 divisor, 0012 => .12%, 0120 => 1/2%, 1200 => 12%
        bool enabled;
    }
    uint128 public constant divisor = 10000;

    struct Stake {
        uint16 bonusPercentage;
        uint40 unlockTimestamp;
        uint128 amount;
        bool withdrawn;
    }

    StakeOption[] public options;

    mapping(address => Stake[]) public addressToStakes;
    address[] public addresses; // allow enumeration of addressToStakes

    // manually control reward cap
    uint128 public maxRewardAmount = 50000000 gwei;  // RSUN is 9 digits
    uint128 public totalRewardAmount = 0;

    event StakeOpened(address indexed staker, uint indexed optionId, uint amount);
    event StakeClosed(address indexed staker, uint amount, uint rewardAmount);

    constructor(address _token) Auth(msg.sender) {
		token = _token;

        options.push(StakeOption( 7 minutes,  115, true));
        options.push(StakeOption(14 minutes,  346, true));
        options.push(StakeOption(30 minutes, 1042, true));
        options.push(StakeOption(90 minutes, 6164, true));
	}

    function getStakes(address user) external view returns (Stake[] memory) {
        return addressToStakes[user];
    }

    function getStakesLength(address user) external view returns (uint) {
        return addressToStakes[user].length;
    }

    function getAddresses() external view returns (address[] memory) {
        return addresses;
    }

    function getAddressesLength() external view returns (uint) {
        return addresses.length;
    }

    // For client convenience, don't require client to be aware of StakeOption indicies
    function stake7Days(uint128 _amount) external whenNotPaused {
        doStake(_amount, 0);
    }

    function stake14Days(uint128 _amount) external whenNotPaused {
        doStake(_amount, 1);
    }

    function stake30Days(uint128 _amount) external whenNotPaused {
        doStake(_amount, 2);
    }

    function stake90Days(uint128 _amount) external whenNotPaused {
        doStake(_amount, 3);
    }

    function stakeWithIndex(uint128 _amount, uint8 _optionIndex) external whenNotPaused {
        doStake(_amount, _optionIndex);
    }

    /**
     * Create a stake
     */
    function doStake(uint128 _amount, uint8 _optionIndex) internal {
        IBEP20 t = IBEP20(token);
        StakeOption memory option = options[_optionIndex];
        uint128 expectedReward = _amount * option.bonusPercentage / divisor;
        require(t.balanceOf(msg.sender) >= _amount, "You do not own enough tokens.");
		require(t.transferFrom(msg.sender, address(this), _amount), "We didn't receive the tokens.");
        require(option.enabled, "StakeOption is not enabled.");
        require(expectedReward + totalRewardAmount < maxRewardAmount, "No rewards left.");

        totalRewardAmount += expectedReward;

        addressToStakes[msg.sender].push(Stake({
            bonusPercentage: option.bonusPercentage,
            unlockTimestamp: option.lockPeriod + uint40(block.timestamp),
            amount: _amount,
            withdrawn: false
        }));

        addresses.push(msg.sender);
        emit StakeOpened(msg.sender, _optionIndex, _amount);
    }

    /**
     * Withdraw a stake.
     */
    function unstake(uint _stakeIndex) external whenNotPaused {
        Stake memory _stake = addressToStakes[msg.sender][_stakeIndex];

        require(block.timestamp > _stake.unlockTimestamp, "Stake is not unlocked.");
        require(_stake.withdrawn == false, "Stake is already withdrawn.");

        // update storage
        addressToStakes[msg.sender][_stakeIndex].withdrawn = true;

        uint128 _rewardAmount = _stake.amount * _stake.bonusPercentage / divisor;

        require(IBEP20(token).transfer(
            msg.sender,
            _stake.amount + _rewardAmount),
            "Failed to send the tokens."
        );

        emit StakeClosed(msg.sender, _stake.amount, _rewardAmount);
    }

    /**
     * Update stake options. Bonus percentage has 10000 divisor.
     */
    function updateStakeOption(
        uint8 _optionIndex,
        uint40 _lockPeriodDays,
        uint16 _bonusPercentage,
        bool _enabled
    ) external authorized {
        options[_optionIndex].lockPeriod = _lockPeriodDays * 1 days;
        options[_optionIndex].bonusPercentage = _bonusPercentage;
        options[_optionIndex].enabled = _enabled;
    }

    function addStakeOption(
        uint40 _lockPeriodDays,
        uint16 _bonusPercentage,
        bool _enabled
    ) external authorized {
        options.push(StakeOption(_lockPeriodDays * 1 days, _bonusPercentage, _enabled));
    }

    /**
     * Update max reward amount if allowing additional stakers is desired
     */
    function updateMaxRewardAmount(uint128 _amount) external authorized {
        maxRewardAmount = _amount;
    }

    /**
     * Retreive stuck tokens. This can be useful if we deposit excess reward tokens.
     * It would be better if we separately tracked deposited reward tokens, but this works
     * and gives flexibility to migrate to a different staking contract if necessary.
     */
    function retrieveTokens(address _token, uint amount) external authorized {
        require(IBEP20(_token).transfer(msg.sender, amount), "Transfer failed");
    }

    /**
     * See retrieveTokens() doc above. Migration flexibility.
     */
    function retrieveTokens(address _token, address target, uint amount) external authorized {
        require(IBEP20(_token).transfer(target, amount), "Transfer failed");
    }

    /**
     * Retreive stuck BNB. 
     */
    function retrieveBNB(uint amount) external authorized {
        (bool success,) = payable(msg.sender).call{ value: amount }("");
        require(success, "Failed to retrieve BNB");
    }
}