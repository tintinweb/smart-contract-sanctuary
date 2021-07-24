// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IDnsClusterMetadataStore {
    function dnsToClusterMetadata(bytes32)
        external
        returns (
            address,
            string memory,
            string memory,
            uint256,
            uint256,
            bool,
            uint256,
            bool
        );

    function addDnsToClusterEntry(
        bytes32 _dns,
        address _clusterOwner,
        string memory ipAddress,
        string memory _whitelistedIps
    ) external;

    function removeDnsToClusterEntry(bytes32 _dns) external;

    function upvoteCluster(bytes32 _dns) external;

    function downvoteCluster(bytes32 _dns) external;

    function markClusterAsDefaulter(bytes32 _dns) external;

    function getClusterOwner(bytes32 clusterDns) external returns (address);
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../cluster-metadata/IDnsClusterMetadataStore.sol";

contract Staking is Ownable {
    uint256 constant EXP = 10**18;
    uint256 constant DAY = 86400;
    address public stackToken;
    address public dnsClusterStore;
    uint256 public slashFactor;
    uint256 public rewardsPerShare;
    uint256 public rewardsPerUpvote;
    uint256 public stakingAmount;
    uint256 public slashCollected;

    struct Stake {
        uint256 amount;
        uint256 stakedAt;
        uint256 share;
        uint256 lastWithdraw;
        bytes32 dns;
        uint256 lastRewardsCollectedAt;
    }

    mapping(address => Stake) public stakes;

    event SlashCollectedLog(
        address collector,
        uint256 collectedSlash,
        uint256 slashCollectedAt
    );

    /*
     * @dev - constructor (being called at contract deployment)
     * @param Address of DNSClusterMetadata Store deployed contract
     * @param Address of stackToken deployed contract
     * @param Minimum staking amount
     * @param Slash Factor - Number of rewards be Slashed for bad actors
     * @param Number of rewards for every Upvotes
     * @param Number of rewards for every share of the whole staking pool
     */
    constructor(
        address _dnsClusterStore,
        address _stackToken,
        uint256 _stakingAmount,
        uint256 _slashFactor,
        uint256 _rewardsPerUpvote,
        uint256 _rewardsPerShare
    ) public {
        stackToken = _stackToken;
        dnsClusterStore = _dnsClusterStore;
        stakingAmount = _stakingAmount;
        slashFactor = _slashFactor;
        rewardsPerUpvote = _rewardsPerUpvote;
        rewardsPerShare = _rewardsPerShare;
    }

    /*
     * @title Update the minimum staking amount
     * @param Updated minimum staking amount
     * @dev Could only be invoked by the contract owner
     */
    function setStakingAmount(uint256 _stakingAmount) public onlyOwner {
        stakingAmount = _stakingAmount;
    }

    /*
     * @title Update the Slash Factor
     * @param New slash factor amount
     * @dev Could only be invoked by the contract owner
     */
    function setSlashFactor(uint256 _slashFactor) public onlyOwner {
        slashFactor = _slashFactor;
    }

    /*
     * @title Update the Rewards per Share
     * @param Updated amount of Rewards for each share
     * @dev Could only be invoked by the contract owner
     */
    function setRewardsPerShare(uint256 _rewardsPerShare) public onlyOwner {
        rewardsPerShare = _rewardsPerShare;
    }

    /*
     * @title Users could stake there stack tokens
     * @param Number of stack tokens to stake
     * @param Name of DNS
     * @param IPAddress of the DNS
     * @param whitelisted IP
     * @return True if successfully invoked
     */
    function deposit(
        uint256 _amount,
        bytes32 _dns,
        string memory _ipAddress,
        string memory _whitelistedIps
    ) public returns (bool) {
        require(
            _amount > stakingAmount,
            "Amount should be greater than the stakingAmount"
        );
        Stake storage stake = stakes[msg.sender];
        IERC20(stackToken).transferFrom(msg.sender, address(this), _amount);
        stake.stakedAt = block.timestamp;
        stake.amount = _amount;
        stake.dns = _dns;
        stake.share = _calcStakedShare(_amount, msg.sender);

        // Staking contract creates a ClusterMetadata Entry
        IDnsClusterMetadataStore(dnsClusterStore).addDnsToClusterEntry(
            _dns,
            address(msg.sender),
            _ipAddress,
            _whitelistedIps
        );
        return true;
    }

    /*
     * @title Staker could withdraw there staked stack tokens
     * @param Amount of stack tokens to unstake
     * @return True if successfully invoked
     */
    function withdraw(uint256 _amount) public returns (bool) {
        Stake storage stake = stakes[msg.sender];
        require(stake.amount >= _amount, "Insufficient amount to withdraw");

        (
            ,
            ,
            ,
            uint256 upvotes,
            uint256 downvotes,
            bool isDefaulter,
            ,

        ) = IDnsClusterMetadataStore(dnsClusterStore).dnsToClusterMetadata(
            stake.dns
        );
        uint256 slash;
        if (isDefaulter == true) {
            slash = (downvotes / upvotes) * slashFactor;
        }
        uint256 actualWithdrawAmount;
        if (_amount > slash) {
            actualWithdrawAmount = _amount - slash;
        } else {
            actualWithdrawAmount = 0;
        }
        stake.lastWithdraw = block.timestamp;
        stake.amount = stake.amount - (actualWithdrawAmount + slash);
        if (stake.amount <= 0) {
            // Remove entry from metadata contract
            IDnsClusterMetadataStore(dnsClusterStore).removeDnsToClusterEntry(
                stake.dns
            );
        }
        stake.share = _calcStakedShare(stake.amount, msg.sender);
        slashCollected = slashCollected + slash;

        IERC20(stackToken).transfer(msg.sender, actualWithdrawAmount);
        return true;
    }

    /*
     * @title Non Defaulter Users could claim the slashed rewards that is accumulated from bad actors
     */
    function claimSlashedRewards() public {
        Stake storage stake = stakes[msg.sender];
        require(stake.stakedAt > 0, "Not a staker");
        require(
            (block.timestamp - stake.lastRewardsCollectedAt) > DAY,
            "Try again after 24 Hours"
        );
        (
            ,
            ,
            ,
            uint256 upvotes,
            ,
            bool isDefaulter,
            ,

        ) = IDnsClusterMetadataStore(dnsClusterStore).dnsToClusterMetadata(
            stake.dns
        );
        require(
            !isDefaulter,
            "Stakers marked as defaulters are not eligible to claim the rewards"
        );
        uint256 stakedShare = getStakedShare();
        uint256 stakedShareRewards = stakedShare * rewardsPerShare;
        uint256 upvoteRewards = upvotes * rewardsPerUpvote;
        uint256 rewardFunds = stakedShareRewards + upvoteRewards;
        require(slashCollected >= rewardFunds, "Insufficient reward funds");
        slashCollected = slashCollected - (rewardFunds);
        stake.lastRewardsCollectedAt = block.timestamp;
        IERC20(stackToken).transfer(msg.sender, rewardFunds);

        emit SlashCollectedLog(msg.sender, rewardFunds, block.timestamp);
    }

    /*
     * @title Fetches the Invoker Staked share from the total pool
     * @return User's Share
     */
    function getStakedShare() public view returns (uint256) {
        Stake storage stake = stakes[msg.sender];
        return _calcStakedShare(stake.amount, msg.sender);
    }

    function _calcStakedShare(uint256 stakedAmount, address staker)
        internal
        view
        returns (uint256 share)
    {
        uint256 totalSupply = IERC20(stackToken).balanceOf(address(this));
        uint256 exponentialAmount = EXP * stakedAmount;
        share = exponentialAmount / totalSupply;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}