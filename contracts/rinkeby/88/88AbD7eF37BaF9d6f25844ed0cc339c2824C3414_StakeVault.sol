// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./new_LaunchPoolTracker.sol";
import "./interfaces/IERC20Minimal.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakeVault is Ownable {
    struct Stake {
        uint128 id;
        address staker;
        address token;
        uint128 amount;
        uint128 poolId;
        bool isCommitted;
    }

    LaunchPoolTracker private _poolTrackerContract;
    uint128 private _curStakeId = 0;
    mapping(uint256 => Stake) public stakes;
    mapping(address => uint256[]) public stakesByInvestor; // holds an array of stakes for one investor. Each element of the array is an ID for the stakes array

    enum PoolStatus {AcceptingStakes, AcceptingCommitments, Delivering, Claiming, Closed}

    struct PoolInfo {
        address sponsor;
        PoolStatus status;
        uint256 expiration;
    }

    mapping(uint256 => PoolInfo) poolsById;
    mapping(uint256 => bool) pool_emergency;    //emergency by pool

    event PoolOpened(uint, address, uint);
    event PoolClosed(uint, address);
    event StakeAdded(uint, uint, address, uint, address);
    event Unstake(uint, address);
    event EmergencyUnstake(uint, address);
    event Emergency(uint, bool, address);
    event StakeCommitted(uint, bool, address);
    event StakesUncommitted(uint, address);
    event ClaimStatus(uint, address, PoolStatus);
    event Claim(uint, address);

    function setPoolContract(LaunchPoolTracker poolTrackerContract_) external onlyOwner{
        _poolTrackerContract = poolTrackerContract_;
    }

    // Called  by a launchPool. Adds to the poolsById mapping in the stakeVault. Passes the id from the poolIds array.
    // Sets the sponsor and the expiration date and sets the status to “Staking”
    // The sponsor becomes the owner
    function addPool (uint256 poolId, address sponsor, uint256 expiration) external {
   
        PoolInfo storage pi = poolsById[poolId];
        pi.sponsor = sponsor;
        pi.status = PoolStatus.AcceptingStakes;
        pi.expiration = expiration;

        emit PoolOpened(poolId, sponsor, expiration);
    }

    function updatePoolStatus (uint256 poolId, uint256 status) external {
        PoolInfo storage pi = poolsById[poolId];
        pi.status = PoolStatus(status);
    }

    // Can be called by the admin or the sponsor. Can be called by any address after the expiration date. Sends back all stakes.
    // A closed pool only allows unStake actions
    function closePool (uint256 poolId) external {
        PoolInfo storage poolInfo = poolsById[poolId];

        require(
            (msg.sender == poolInfo.sponsor) || 
            (msg.sender == owner()) ||
            (poolInfo.expiration <= block.timestamp), 
            
            "ClosePool is not allowed for this case.");

        poolInfo.status = PoolStatus.Closed;
        
        for(uint256 i = 0 ; i < _curStakeId ; i ++) {
            if(stakes[i].poolId == poolId) {
                _sendBack(i);
                break;
            }
        }

        emit PoolClosed(poolId, msg.sender);
    }

    // Make a stake structure
    // get the staker from the sender
    // Add this stake to a map that uses the staker address as a key
    // Generate an ID so we can look this up
    // Also call the launchpool to add this stake to its list, with the ID
    function addStake(
        uint128 poolId,
        address token,
        uint128 amount
    ) external
    {
        address staker = msg.sender;
        _curStakeId = _curStakeId + 1;

        Stake storage st = stakes[_curStakeId];
        st.id = _curStakeId;
        st.staker = staker;
        st.token = token;
        st.amount = amount;
        st.poolId = poolId;
        st.isCommitted = false;

        stakesByInvestor[staker].push(_curStakeId);

        _poolTrackerContract.addStake(poolId, _curStakeId);

        IERC20Minimal(token).transferFrom(staker, address(this), amount);

        emit StakeAdded(poolId, _curStakeId, token, amount, msg.sender);
    }

    /// @notice Un-Stake
    function unStake (uint256 stakeId) external {
        require(!stakes[stakeId].isCommitted, "cannot unstake commited stake");
        require(msg.sender == stakes[stakeId].staker, "Must be the staker to call this");      //Omited in emergency
        _sendBack(stakeId); 

        emit Unstake(stakeId, msg.sender);
    }

    /// @notice emergency unstake must be toggled on by owner. Allows anyone to unstake commited stakes
    function emergencyUnstake(uint256 stakeId) external {
        require(pool_emergency[stakes[stakeId].poolId], "Owner must declare emergency for this pool");
        _sendBack(stakeId);

        emit EmergencyUnstake(stakeId, msg.sender);
    }

    /// @notice owner can declare a pool in emergency
    function declareEmergency(uint256 poolId) external onlyOwner {
        require(pool_emergency[poolId] != true, "already in emergency state");
        pool_emergency[poolId] = true;

        emit Emergency(poolId, pool_emergency[poolId], msg.sender);
    }

    /// @notice owner can declare a pool in emergency
    function removeEmergency(uint256 poolId) external onlyOwner {
        require(pool_emergency[poolId] != false, "Pool not in emergency state");
        pool_emergency[poolId] = false;

        emit Emergency(poolId, pool_emergency[poolId], msg.sender);
    }

    function commitStake (uint256 stakeId) external {
        require(!stakes[stakeId].isCommitted, "Stake is already committed");
        require(stakes[stakeId].staker == msg.sender, "You are not the owner of this stake");
        stakes[stakeId].isCommitted = true;
        
        emit StakeCommitted(stakeId, stakes[stakeId].isCommitted, msg.sender);
    }

    function getCommittedAmount(uint256 stakeId) external view returns(uint256) {
        if(stakes[stakeId].isCommitted) {
            return stakes[stakeId].amount;
        } else {
            return 0;
        }       
    }

    // the Launchpool calls this if the offer does not reach a minimum value
    function unCommitStakes (uint256 poolId) external{
    require(
        msg.sender == owner() ||
        msg.sender == address(_poolTrackerContract),            // CONFIRM this function is called by pool tracker
        "Only owner or pool tracker contract can call this function"        
    );
        for(uint256 i = 0 ; i < _curStakeId ; i ++) {
            if(stakes[i].poolId == poolId){
                stakes[i].isCommitted = false;
            }
        }

        emit StakesUncommitted(poolId, msg.sender);
    }

    function setDeliveringStatus(uint256 poolId) external onlyOwner {
        PoolInfo storage poolInfo = poolsById[poolId];
        poolInfo.status = PoolStatus.Delivering;

        emit ClaimStatus(poolId, msg.sender, poolInfo.status);
    }

    // Put the pool into “Claim” status. The administrator can do this after checking delivery
    function setPoolClaimStatus(uint256 poolId) external onlyOwner {
        PoolInfo storage poolInfo = poolsById[poolId];
        require(poolInfo.status == PoolStatus.Delivering, "LaunchPool is not delivering status.");
        
        poolInfo.status = PoolStatus.Claiming;

        emit ClaimStatus(poolId, msg.sender, poolInfo.status);
    }

    // must be called by the sponsor address
    // The sponsor claims committed stakes in a pool. This checks to see if the admin has put the pool in “claiming” state. It sends or allows all stakes to the sponsor address. It closes the pool (sending back all uncommitted stakes)
    function claim (uint256 poolId) external{
        PoolInfo storage poolInfo = poolsById[poolId];
        require(msg.sender == poolInfo.sponsor, "Claim should be called by sponsor.");
        require(poolInfo.status == PoolStatus.Claiming, "Claim should be called when the pool is in claiming state.");
        
        for(uint256 i = 0 ; i < _curStakeId ; i ++) {
            if(stakes[i].poolId == poolId) {
                if(stakes[i].isCommitted == true) {
                    IERC20Minimal(stakes[i].token).transfer(poolInfo.sponsor, stakes[i].amount);
                }
                else {
                    IERC20Minimal(stakes[i].token).transfer(stakes[i].staker, stakes[i].amount);
                }
            }
        }
        poolInfo.status = PoolStatus.Closed;

        emit Claim(poolId, msg.sender);
    }

    /// @notice send back tokens to investor or investors
    function _sendBack (uint256 stakeId) private {
        //withdraw Stake
        uint temp = stakes[stakeId].amount;
        stakes[stakeId].amount = 0;
        IERC20Minimal(stakes[stakeId].token).transfer(stakes[stakeId].staker, temp);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./new_StakeVault.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LaunchPoolTracker is Ownable {

    mapping(address => bool) private _allowedTokenAddresses;
    // Tokens to stake. We will upgrade this later.

    bool private _isTrackerClosed; // is tracker open or closed

    uint256 private _curPoolId = 0; // count of pools in the array and map
    mapping(uint256 => LaunchPool) public poolsById;
    uint256[] public poolIds;

    enum PoolStatus {AcceptingStakes, AcceptingCommitments, Delivering, Claiming, Closed}

    struct OfferBounds {
        uint256 minimum;
        uint256 maximum;
    }

    struct Offer {
        OfferBounds bounds;
        string url;
    }

    struct ExpiryData {
        uint256 startTime;
        uint256 duration;
    }

    struct LaunchPool {
        string name;
        string url;
        address sponsor;
        PoolStatus status;
        ExpiryData poolExpiry;
        ExpiryData offerExpiry;
        uint256[] stakes;
        Offer offer;
        uint256 totalCommittedAmount;
    }    

    StakeVault _stakeVault;

    event NewOffer(uint, address);
    event UpdateOffer(uint, address);
    event OfferCancelled(uint, address);
    event OfferEnded(uint, address);
    event PoolClosed(uint, address);

    /// @notice creates a new LaunchPoolTracker.
    /// @dev up to 3 tokens are allowed to be staked.
    constructor(address[] memory allowedAddresses_, StakeVault stakeVault_) {
        require(
            allowedAddresses_.length >= 1,
            "There must be at least 1"
        );
        
        for(uint256 i = 0 ; i < allowedAddresses_.length ; i ++) {
            _allowedTokenAddresses[allowedAddresses_[i]] = true;
        }

       _stakeVault = stakeVault_;
    }

    /* Modifers */

    // @notice check the launchPool is not closed and not expired
    modifier isPoolOpen(uint256 poolId) {
        LaunchPool storage lp = poolsById[poolId];
        if (block.timestamp > lp.poolExpiry.startTime + lp.poolExpiry.duration) {
            lp.status = PoolStatus.Closed;
        }
        require(!_atStatus(poolId, PoolStatus.Closed), "LaunchPool is closed");
        _;
    }

    // @notice check launchPoolTracker is open
    modifier isTrackerOpen () {
        require(
            _isTrackerClosed == false,
            "LaunchPoolTracker is closed."
        );
        _;
    }

    // @notice check the poolId is not out of range
    modifier isValidPoolId(uint256 poolId) {
        require(poolId <= _curPoolId, "LaunchPool Id is out of range.");
        _;
    }

    // @notice check the token is allowed
    function tokenAllowed(address token) public view returns (bool) {
        return _allowedTokenAddresses[token];
    }

    function addTokenAllowness(address token) public onlyOwner {
        _allowedTokenAddresses[token] = true;
    }

    // @notice add a pool and call addPool() in StakeVault contract
    function addPool(
        string memory _poolName,
        string memory _url,
        uint256 poolValidDuration_,
        uint256 offerValidDuration_,
        uint256 minOfferAmount_,
        uint256 maxOfferAmount_) public {

        _curPoolId = _curPoolId + 1;
        LaunchPool storage lp = poolsById[_curPoolId];

        lp.name = _poolName;
        lp.url = _url;
        lp.status = PoolStatus.AcceptingStakes;
        lp.poolExpiry.startTime = block.timestamp;
        lp.poolExpiry.duration = poolValidDuration_;

        lp.offerExpiry.duration = offerValidDuration_;

        lp.offer.bounds.minimum = minOfferAmount_;
        lp.offer.bounds.maximum = maxOfferAmount_;

        lp.sponsor = msg.sender;

        poolIds.push(_curPoolId);

        _stakeVault.addPool(_curPoolId, msg.sender, block.timestamp + poolValidDuration_);
    }

    function updatePoolStatus(uint256 poolId, uint256 status) public onlyOwner {
        LaunchPool storage lp = poolsById[poolId];
        lp.status = PoolStatus(status);

        _stakeVault.updatePoolStatus(poolId, status);
    }

    // @notice return the launchpool status is same as expected
    function _atStatus(uint256 poolId, PoolStatus status) private view returns (bool) {
        LaunchPool storage lp = poolsById[poolId];
        return lp.status == status;
    }

    // @notice Check the launchPool offer is expired or not
    function _isAfterOfferClose(uint256 poolId) private view returns (bool) {
        LaunchPool storage lp = poolsById[poolId];
        return block.timestamp >= lp.offerExpiry.startTime + lp.offerExpiry.duration;
    }

    // @notice Check the launchPool offer is able to claim or not
    function canClaimOffer(uint256 poolId) public view returns (bool) {
        LaunchPool storage lp = poolsById[poolId];
        return _isAfterOfferClose(poolId) && getTotalCommittedAmount(poolId) >= lp.offer.bounds.minimum;
    }
    
    
    // @notice return poolIds
    function getPoolIds() public view returns (uint256 [] memory) {
        return poolIds;
    }

    // called from the stakeVault. Adds to a list of the stakes in a pool, in stake order
    function addStake (uint256 poolId, uint256 stakeId) public isValidPoolId(poolId){
        LaunchPool storage lp = poolsById[poolId];
        lp.stakes.push(stakeId);
    }

    // Get a list of stakes for the pool. This will be used by users, and also by the stakeVault
    // returns a list of IDs (figure out how to identify stakes in the stakevault. We know the pool)
    function getStakes (uint256 poolId) public view returns(uint256 [] memory) {
        LaunchPool storage lp = poolsById[poolId];
        return lp.stakes;
    }
    
    // Put in committing status. Save a link to the offer
    // url contains the site that the description of the offer made by the sponsor
    function newOffer (uint256 poolId, string memory url, uint256 duration) public isValidPoolId(poolId) isPoolOpen(poolId) {
        LaunchPool storage lp = poolsById[poolId];
        lp.status = PoolStatus.AcceptingCommitments;
        lp.offerExpiry.startTime = block.timestamp;
        lp.offerExpiry.duration = duration;
        lp.offer.url = url;
        _stakeVault.updatePoolStatus(poolId, uint256(lp.status));
        emit NewOffer(poolId, msg.sender);
    }
    
    // put back in staking status.
    function cancelOffer (uint256 poolId) public onlyOwner isValidPoolId(poolId) {
        LaunchPool storage lp = poolsById[poolId];
        lp.status = PoolStatus.AcceptingStakes;
        _stakeVault.updatePoolStatus(poolId, uint256(lp.status));
        emit OfferCancelled(poolId, msg.sender);
    }
    
    // runs the logic for an offer that fails to reach minimum commitment, or succeeds and goes to Delivering status
    function endOffer (uint256 poolId) public onlyOwner isValidPoolId(poolId) {
        LaunchPool storage lp = poolsById[poolId];
        if(canClaimOffer(poolId)) {
            lp.status = PoolStatus.Delivering;
        }
        if(!canClaimOffer(poolId)) {
            lp.status = PoolStatus.AcceptingStakes;
            _stakeVault.unCommitStakes(poolId);
        }

        _stakeVault.updatePoolStatus(poolId, uint256(lp.status));

        emit OfferEnded(poolId, msg.sender);
    }

    function updateOffer (uint256 poolId, string memory url, uint256 duration) public onlyOwner isValidPoolId(poolId) {
        LaunchPool storage lp = poolsById[poolId];
        lp.offerExpiry.startTime = block.timestamp;
        lp.offerExpiry.duration = duration;
        lp.offer.url = url;

        emit UpdateOffer(poolId, msg.sender);
    }

    function getTotalCommittedAmount(uint256 poolId) public view returns(uint256) {
        LaunchPool storage lp = poolsById[poolId];
        uint256 totalCommittedAmount = 0;
        for(uint i = 0; i < lp.stakes.length; i++) {
            totalCommittedAmount += _stakeVault.getCommittedAmount(lp.stakes[i]);
        }
        return totalCommittedAmount;
    }

    // OPTIONAL IN THIS VERSION. calculates new dollar values for stakes. 
    // Eventually, we will save these values at the point were we go to “deliver” the investment amount based on the dollar value of a committed stake.
    function setValues () public onlyOwner {}
    
    // OPTIONAL IN THIS VERSION. We need a way to report the list of committed stakes, with the value of the committed stakes and the investor. 
    //This forms a list of the investments that need to be delivered. It is basically a “setValues” followed by getStakes.
    function getInvestmentValues () public {}
    
    // calls stakeVault closePool, sets status to closed
    function closePool (uint256 poolId) public isValidPoolId(poolId) {
        _stakeVault.closePool(poolId);
        LaunchPool storage lp = poolsById[poolId];
        lp.status = PoolStatus.Closed;
        _stakeVault.updatePoolStatus(poolId, uint256(lp.status));
        emit PoolClosed(poolId, msg.sender);
    }

    // calls closePool for all LaunchPools, sets _isTrackerClosed to true
    function closeTracker () public {
        for(uint256 i = 0 ; i < _curPoolId ; i ++) {
            closePool(poolIds[i]);
        }

        _isTrackerClosed = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

/// @title Minimal ERC20 interface for Uniswap
/// @notice Contains a subset of the full ERC20 interface that is used in Uniswap V3
interface IERC20Minimal {
    /// @notice Returns the balance of a token
    /// @param account The account for which to look up the number of tokens it has, i.e. its balance
    /// @return The number of tokens held by the account
    function balanceOf(address account) external view returns (uint256);

    /// @notice Transfers the amount of token from the `msg.sender` to the recipient
    /// @param recipient The account that will receive the amount transferred
    /// @param amount The number of tokens to send from the sender to the recipient
    /// @return Returns true for a successful transfer, false for an unsuccessful transfer
    function transfer(address recipient, uint256 amount) external returns (bool);

    /// @notice Returns the current allowance given to a spender by an owner
    /// @param owner The account of the token owner
    /// @param spender The account of the token spender
    /// @return The current allowance granted by `owner` to `spender`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets the allowance of a spender from the `msg.sender` to the value `amount`
    /// @param spender The account which will be allowed to spend a given amount of the owners tokens
    /// @param amount The amount of tokens allowed to be used by `spender`
    /// @return Returns true for a successful approval, false for unsuccessful
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Transfers `amount` tokens from `sender` to `recipient` up to the allowance given to the `msg.sender`
    /// @param sender The account from which the transfer will be initiated
    /// @param recipient The recipient of the transfer
    /// @param amount The amount of the transfer
    /// @return Returns true for a successful transfer, false for unsuccessful
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /// @notice Event emitted when tokens are transferred from one address to another, either via `#transfer` or `#transferFrom`.
    /// @param from The account from which the tokens were sent, i.e. the balance decreased
    /// @param to The account to which the tokens were sent, i.e. the balance increased
    /// @param value The amount of tokens that were transferred
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Event emitted when the approval amount for the spender of a given owner's tokens changes.
    /// @param owner The account that approved spending of its tokens
    /// @param spender The account for which the spending allowance was modified
    /// @param value The new allowance from the owner to the spender
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

