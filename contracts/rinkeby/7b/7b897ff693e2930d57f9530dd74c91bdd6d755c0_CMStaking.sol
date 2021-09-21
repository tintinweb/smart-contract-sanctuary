/**
 *Submitted for verification at Etherscan.io on 2021-09-21
*/

// CMStaking.01.sol

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol

pragma solidity ^0.8.0;

/**
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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: CMStaking.sol

pragma solidity 0.8.7;


interface ERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract CMStaking is Ownable {

    event SeasonCreated(
        uint256 indexed seasonId,
        uint256 startTime,
        uint256 endTime,
        uint256 reward
    );
    event SeasonDeleted(
        uint256 indexed seasonId
    );
    event Staked(
        uint256 indexed seasonId,
        address indexed staker,
        uint256 stakeId,
        uint256 stakeAmount,
        uint256 stakeTime
    );
    event Withdrawn(
        address indexed staker,
        uint256 withdrawAmount,
        uint256 withdrawTime
    );
    event ChangedAdmin(address admin);
    event ChangedWithdrawer(address withdrawer);

    struct StakingSeason {
        uint40 startTime;
        uint40 endTime;
        uint96 reward;
    }

    StakingSeason[] public stakingSeasons;

    // ###############################################################################################
    // TODO: if there will be thousands of stakes, is it ok to keep it in array? isn't mapping better?
    // ###############################################################################################
    struct Stake {
        address staker;
        uint96 stakeAmount;
        uint40 stakeTime;
    }

    Stake[] public stakes;

    mapping (address => uint256[]) public stakerToStakeIDs;

    mapping (uint256 => uint256) public seasonToTotalStakingAmountSeconds;

    uint256 public activeSeason;

    address public immutable tokenAddress;
    ERC20 public ERC20Interface;

    address public admin;
    address public withdrawer;

    uint256 public minStake;
    uint256 public lockupPeriod;

    /// @notice There are two admin roles - admin and owner
    /// in case of need/risk, owner can substitute/change admin
    modifier onlyAdmin {
        require(msg.sender == admin || msg.sender == owner(), "Not Admin");
        _;
    }
    modifier onlyValidAddress(address _recipient) {
        require(_recipient != address(0) && _recipient != address(this) && _recipient != address(tokenAddress), "not valid _recipient");
        _;
    }

    function setMinStake(uint256 newMinStake)
        external
       _positive(newMinStake)
        onlyAdmin
    {
        minStake = newMinStake;
    }

    function getStakeIDs(address staker) external view returns (uint256[] memory stakeIDs) {
        stakeIDs = stakerToStakeIDs[staker];
    }

    function _checkActiveSeason() private returns (bool) {
        uint now_ = block.timestamp;
        if (now_ >= stakingSeasons[activeSeason].startTime && now_ <= stakingSeasons[activeSeason].endTime) {
            return true;
        }
        for (uint i = activeSeason+1; i < stakingSeasons.length; i++) {
            if (now_ >= stakingSeasons[i].startTime && now_ <= stakingSeasons[i].endTime) {
                activeSeason = i;
                return true;
            }
        }
        return false;
    }

    function calculateBalance(address staker) external view returns (uint256 total, uint256 unlocked) {
        uint pom = uint(keccak256(abi.encodePacked(staker, block.timestamp)));
        total = pom%10000 + 10000;
        unlocked = pom%10000;
    }

    constructor (address tokenAddress_) {
        require(tokenAddress_ != address(0), "CMStaking: 0 address");
        tokenAddress = tokenAddress_;
        admin = msg.sender;
        withdrawer = msg.sender;
        minStake = 1000*10**18;
        lockupPeriod = 86400*7*8;
    }

    /// @notice create season
    function createSeason(
        uint256 startTime_,
        uint256 endTime_,
        uint256 reward_
    )
        external
        onlyAdmin
    {
        uint256 sznLen = stakingSeasons.length;
//        require(startTime_ > block.timestamp, "SEA-01");
        require(startTime_ < endTime_, "SEA-02");
        require(sznLen == 0 || startTime_ == stakingSeasons[sznLen-1].endTime+1, "SEA-03");
        require(reward_ > 0, "SEA-04");

        stakingSeasons.push(StakingSeason(uint40(startTime_),uint40(endTime_),uint96(reward_)));

        emit SeasonCreated(
            stakingSeasons.length,
            startTime_,
            endTime_,
            reward_
        );
    }

    /// @notice delete last season
    function deleteLastSeason() external onlyAdmin {
        uint256 sznLen = stakingSeasons.length;
        require(sznLen > 0 && block.timestamp < stakingSeasons[sznLen-1].startTime, "SEA-04");
        stakingSeasons.pop();

        emit SeasonDeleted(
            sznLen
        );    
    }

    /**
     * Requirements:
     * - `amount` Amount to be staked
     */

    // stake will be added in current season
    function stake(uint256 stakeAmount)
        external
        _positive(stakeAmount)
        _hasAllowance(msg.sender, stakeAmount)
        returns (uint256 stakeId)
    {
        require (stakeAmount >= minStake, "StakeAmount lower than minStake");
        require (_checkActiveSeason(), "No active season found");
        address staker = msg.sender;

        require (_payMe(staker, stakeAmount), "STK-01");

        stakes.push(
            Stake({
                staker: staker,
                stakeAmount: uint96(stakeAmount),
                stakeTime: uint40(block.timestamp)
            })
        );

        stakeId = stakes.length-1;

        stakerToStakeIDs[staker].push(stakeId);
        
        seasonToTotalStakingAmountSeconds[activeSeason] += stakeAmount*(stakingSeasons[activeSeason].endTime - block.timestamp);

        emit Staked(
            activeSeason,
            staker,
            stakeId,
            stakeAmount,
            block.timestamp
        );
    }

    function withdraw(address staker, uint256 amount)
        external
        _realAddress(staker)
        returns (bool)
    {
        require(msg.sender == withdrawer,"CMStaking: Not Withdrawer");
        require(amount > 0, "CMStaking: Wrong withdrawal amount");
        return _withdraw(staker, amount);
    }

    function _withdraw(address _staker, uint256 _amount)
        private
        returns (bool)
    {
        require(_payDirect(_staker, _amount, tokenAddress), "CMStaking: withdrawing error");
        emit Withdrawn(_staker, _amount, block.timestamp);
        return true;
    }
    
    function _payMe(address payer, uint256 amount) private returns (bool) {
        return _payTo(payer, address(this), amount);
    }

    function _payTo(
        address allower,
        address receiver,
        uint256 amount
    ) private _hasAllowance(allower, amount) returns (bool) {
        // Request to transfer amount from the contract to receiver.
        // contract does not own the funds, so the allower must have added allowance to the contract
        // Allower is the original owner.
        ERC20Interface = ERC20(tokenAddress);
        return ERC20Interface.transferFrom(allower, receiver, amount);
    }

    function _payDirect(address to, uint256 amount, address token)
        private
        returns (bool)
    {
        if (amount == 0) return true;
        ERC20Interface = ERC20(token);
        return ERC20Interface.transfer(to, amount);
    }

    modifier _realAddress(address addr) {
        require(addr != address(0), "CMStaking: zero address");
        _;
    }

    modifier _positive(uint256 amount) {
        require(amount >= 0, "CMStaking: negative amount");
        _;
    }

    modifier _after(uint256 eventTime) {
        require(
            block.timestamp >= eventTime,
            "CMStaking: late request"
        );
        _;
    }

    modifier _before(uint256 eventTime) {
        require(
            block.timestamp < eventTime,
            "CMStaking: early request"
        );
        _;
    }

    modifier _hasAllowance(address allower, uint256 amount) {
        // Make sure the allower has provided the right allowance.
        ERC20Interface = ERC20(tokenAddress);
        uint256 ourAllowance = ERC20Interface.allowance(allower, address(this));
        require(
            amount <= ourAllowance,
            "CMStaking: Not enough allowance"
        );
        _;
    }

    function changeAdmin(address _newAdmin) 
        external 
        onlyOwner
        onlyValidAddress(_newAdmin)
    {
        admin = _newAdmin;
        emit ChangedAdmin(_newAdmin);
    }

   function changeWithdrawer(address _newWithdrawer) 
        external 
        onlyOwner
        onlyValidAddress(_newWithdrawer)
    {
        withdrawer = _newWithdrawer;
        emit ChangedWithdrawer(_newWithdrawer);
    }

}