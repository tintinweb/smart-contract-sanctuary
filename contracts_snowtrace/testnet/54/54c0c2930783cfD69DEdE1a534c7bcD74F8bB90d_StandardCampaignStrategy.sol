// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ICampaign.sol";
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';

 /* 
    Standard Campaign Strategy Contract for Supaheroes.org
        
    ███████████████████████████████████████████████████████████
    █─▄▄▄▄█▄─██─▄█▄─▄▄─██▀▄─██─█─█▄─▄▄─█▄─▄▄▀█─▄▄─█▄─▄▄─█─▄▄▄▄█
    █▄▄▄▄─██─██─███─▄▄▄██─▀─██─▄─██─▄█▀██─▄─▄█─██─██─▄█▀█▄▄▄▄─█
    ▀▄▄▄▄▄▀▀▄▄▄▄▀▀▄▄▄▀▀▀▄▄▀▄▄▀▄▀▄▀▄▄▄▄▄▀▄▄▀▄▄▀▄▄▄▄▀▄▄▄▄▄▀▄▄▄▄▄▀
    
    Creates a standard campaign for projects that require crowdfunding. Pledgers can safely
    pledge through this smart contract or through reward manager to receive reward and voting power.
    If found to be a fraud, campaign can be stopped by 40% quorum through voting process.

    * Standard campaign strategy requires a reward manager
    * Vesting manager is optional
    * Vesting is recommended as it gives confidence to supporters
    * Metadata standard can be seen on Supaheroes docs
    */
    
/** @title Supaheroes Standard Campaign Strategy */
contract StandardCampaignStrategy is ICampaign, Initializable {
    event LogPledge(address indexed by, address indexed to, uint256 amount, address currency, uint256 timestamp);
    event LogRefund(address indexed by, uint256 amount, uint256 timestamp);
    event LogVote(uint256 indexed at, address to, uint256 weight);
    event CampaignStopped(uint256 indexed timestamp);

    //total voting weight
    uint256 public totalWeight;
    //total voted weight
    uint256 public votedWeight;

    //project admin
    address public admin;
    //the start time of crowdfunding session
    uint256 public fundingStartTime;
    //the end of crowdfunding session time
    uint256 public fundingEndTime;
    //the amount of funds to reach a goal
    uint256 public fundingTarget;
    //ipfs url to campaign information
    string public metadata;

    //put in the prefered currency for this campaign(recommended: stablecoins such as USDC/DAI)
    IERC20 public supportedCurrency;

    //is the campaign running?
    bool public isCampaignStopped = false;

    //address of the vesting manager contract
    address public vestingManager;
    //address of the reward manager contract
    address public rewardManager;

    /**
     * @dev StandardCampaignStrategy follows EIP-1167 Minimal Proxy use this to initialize StandardCampaign instead of constructor
     * for more information head over to https://eips.ethereum.org/EIPS/eip-1167
     * 
     * @param _currency sets the currency for the campaign
     * @param _metadata off-chain campaign data just like ERC721. Recommendation: host on IPFS
     * @param _fundingEndTime sets campaign end time
     * @param _fundTarget funding goal amount
     * @param _fundingStartTime when the campaign will start
     * @param _vestingManager the vesting manager. Set to address(0) if there is no vesting manager
     * @param _rewardManager the reward manager. required!
     */
    function initialize(
        address _currency,
        string memory _metadata,
        uint256 _fundingEndTime,
        uint256 _fundTarget,
        uint256 _fundingStartTime,
        address _vestingManager,
        address _rewardManager
    ) public initializer {
        require(_fundTarget > 0, "Fund target 0");
        require(_currency != address(0), "No currency");
        require(_rewardManager != address(0), "No reward manager");
        require(block.timestamp < _fundingStartTime, "start before this timestamp");
        require(_fundingStartTime < _fundingEndTime, "ends before start date");
        supportedCurrency = IERC20(_currency);
        metadata = _metadata;
        admin = msg.sender;
        fundingTarget = _fundTarget;
        fundingStartTime = _fundingStartTime;
        fundingEndTime = _fundingEndTime;
        vestingManager = _vestingManager;
        rewardManager = _rewardManager;
    }

    modifier onlyRewardManager() {
        require(rewardManager != address(0));
        require(msg.sender == rewardManager);
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    /**
     * @notice Campaign owners are able to change the metadata of the campaign
     * @param newMetadata the new metadata uri
     */
    function changeMetadata(string memory newMetadata) external onlyAdmin {
        require(block.timestamp < fundingEndTime, "Campaign ended");
       metadata = newMetadata;
    }

    /**
     * @notice Pledge through this contract is basically a donation. You will not receive a reward or a voting power
     * thus is not recommended unless you choose to do so. Pledge through reward manager instead to receive reward and voting power.
     * @param amount the amount of fund
     * @param weight the voting weight (see RewardManager.sol)
     * @param token currency address
     */
    function pledge(uint256 amount, uint256 weight, address token, address from) external override {
        require(amount > 0, "Amount 0");
        require(msg.sender != admin || from != admin, "Admin cannot pledge");
        require(IERC20(token) == supportedCurrency, "Currency not supported");
        require(fundingEndTime > block.timestamp, "Funding ended");

        if(msg.sender == rewardManager){
            totalWeight += weight; //re-entrancy guard
        }
        IERC20(token).transferFrom(from, address(this), amount); 
        emit LogPledge(from, address(this), amount, token, block.timestamp);      
    }

    /**
     * @notice Circuit breaker function to stop the campaign
     */
    function stopCampaign() external onlyAdmin {
        require(fundingEndTime > block.timestamp, "campaign ended");
        require(isCampaignStopped == false, "campaign stopped");
        isCampaignStopped = true;
        fundingEndTime = block.timestamp;
        emit CampaignStopped(block.timestamp);
    }

    /**
     * @notice Pledgers have the ability to vote for a refund and stop the campaign using the given ERC1155 token
     * see RewardManager.sol for more information
     * @param weight the voting weight (see rewardManager.sol)
     */
    function voteRefund(uint weight) external onlyRewardManager {
        require(isCampaignStopped == false, "Campaign stopped");
        votedWeight += weight;
        if(votedWeight  < totalWeight * 40/100) {
            isCampaignStopped = true;
        }
        emit LogVote(block.timestamp ,address(this), weight);
    }

    /**
     * @notice Call this function to unvote
     * @param weight the voting weight (see rewardManager.sol)
     */
    function unvote(uint weight) external onlyRewardManager {
        require(isCampaignStopped == false, "Campaign stopped");
        votedWeight -= weight;
    }

    /**
     * @notice Helper function to get project details
     */
    function getProjectDetails()
        public
        view
        returns (           
            address _admin,
            uint256 _target,
            string memory _metadata,
            uint256 _balance,
            uint256 _fundingEndTime,
            uint256 _fundingStartTime
        )
    {
        return (admin, fundingTarget, metadata, address(this).balance, fundingEndTime, fundingStartTime);
    }

    /**
     * @notice Once a campaign is stopped, pledgers will be able to withdraw their funds.
     * only callable through reward manager
     * @param amount the amount to withdraw
     */
    function withdrawFunds(uint256 amount, address recipient) external onlyRewardManager returns (bool success) {
        require(amount > 0, "Cannot withdraw 0");
        require(isCampaignStopped, "Campaign is still running");
        supportedCurrency.approve(msg.sender, amount);
        totalWeight -= amount; //re-entrancy guard
        supportedCurrency.transferFrom(address(this), recipient, amount); // transfer from campaign to user
        emit LogRefund(recipient, amount, block.timestamp);
        return true;
    }


    /**
     * @notice Receive the crowdfund after campaign ends. If vested, this function can only be called from vesting manager contract
     * @param to transfer to address
     * @param amount the amount to transfer
     */
    function payOut(address to,uint256 amount) external override onlyAdmin returns (bool success) {
        require(vestingManager == address(0) || msg.sender == vestingManager, "Use payOutClaimable");
        require(amount > 0, "0 amount");
        require(fundingEndTime < block.timestamp, "Campaign is still running");
        require(isCampaignStopped == false, "Campaign has been stopped");

        supportedCurrency.approve(msg.sender, amount);
        supportedCurrency.transfer(to, amount);
        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
    function transferFrom(
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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface ICampaign {

    function pledge(uint256 amount,uint256 weight, address token, address from) external;

    function payOut(address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}