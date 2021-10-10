// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ETHPoolStorage.sol";
import "./IETHPool.sol";


contract ETHPool is ETHPoolStorage, IETHPool, Ownable {

    event UserDeposit(address indexed depositor, uint256 depositValue, uint256 sharesGiven);
    event UserWithdraw(address indexed depositor, uint256 withdrawValue, uint256 sharesTaken);
    event TeamAddressChanged(address newAddress);
    event RewardsDeposited(address team, uint256 rewardAmount);

    /**
     * @dev Check if the account is registered as the team.
     */
    modifier isTeamAccount {
        require(_msgSender() == teamAddress, "!TeamAccount");
        _;
    }

    /**
     * @dev Initialize this contract. Owner defaults in constructor to contract deployer.
     * Initialization should be preferred over constructor for compatibility with proxies & upgrades.
     * @param _teamAddress The ETH address of the team responsible for reward deposits.
     */
    function initialize(address _teamAddress) external onlyOwner {
        _setTeamAddress(_teamAddress);
    }

    /**
     * @dev Deposit funds into the pool, and recieve shares entitling the user to ETH from the reward pool.
     */
    function userDeposit() external payable override returns (uint256) {
        // Get the deposit data
        Depositor storage depositor = pool.depositors[_msgSender()];
        uint256 depositValue = msg.value;

        // Calculate & validate shares to issue
        uint256 shares = (pool.eth == 0) ? depositValue : ((depositValue * pool.shares) / pool.eth);
        require(shares > 0, "Shares !> 0");

        // Update the deposit pool and individual share ownership
        pool.eth += depositValue;
        pool.shares += shares;
        depositor.shares += shares;
        emit UserDeposit(_msgSender(), depositValue, shares);
        return shares;

    }

    /**
     * @dev Withdraw funds from the pool, based on the amount of available shares a user has.
     * @param _sharesToWithdraw The number of shares a user wishes to exchange for ETH in the reward pool. Stored as calldata.
     */
    function userWithdraw(uint256 _sharesToWithdraw) external override returns (uint256) {
        // Can only withdraw a non-zero amount of shares
        require(_sharesToWithdraw > 0, "Need >0 Shares");
        Depositor storage depositor = pool.depositors[_msgSender()];

        // Validate shares and calculate ETH return
        require(depositor.shares >= _sharesToWithdraw, "Not enough shares");
        uint256 eth = ((_sharesToWithdraw * pool.eth) / pool.shares);

        // Update the deposit pool and individual shares
        pool.eth -= eth;
        pool.shares -= _sharesToWithdraw;
        depositor.shares -= _sharesToWithdraw;

        // Withdraw the ETH, reverting on failure
        payable(_msgSender()).transfer(eth);
        emit UserWithdraw(_msgSender(), eth, _sharesToWithdraw);
        return eth;
    }

    /**
     * @dev Deposit ETH rewards into the pool. May only be called by the team account.
     */
    function depositRewards() external payable override isTeamAccount {
        pool.eth += msg.value;
        emit RewardsDeposited(_msgSender(), msg.value);
    }

    /**
     * @dev Set the team address. Private, used by the initilizer.
     * @param _address The ETH address to set the team address to.
     */
    function _setTeamAddress(address _address) private {
        teamAddress = _address;
        emit TeamAddressChanged(_address);
    }


    /**
    * @dev Get the number of shares owned by a user. Required here as a custom getter, as
    * Solidity does not auto-generate public getters for mappings inside structs.
    * See more here: https://docs.soliditylang.org/en/v0.8.9/contracts.html?highlight=public#getter-functions
    * @param _depositor The ETH address to get the shares for.
    */
    function getDepositedShares(address _depositor) external view returns (uint256) {
        return pool.depositors[_depositor].shares;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./IETHPoolData.sol";

contract ETHPoolStorage {
    // Address of team T able to depost ETH rewards
    address public teamAddress;

    // Aggregate pool for reward collection and distribution
    IETHPoolData.Pool public pool;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./IETHPoolData.sol";

interface IETHPool is IETHPoolData{

    // User Functions
    function userDeposit() external payable returns (uint256);

    function userWithdraw(uint256 _sharesToWithdraw) external returns (uint256);
    
    
    // Team Functions
    function depositRewards() external payable;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IETHPoolData {
    /**
     * @dev ETHPool data. Captures data related to aggregate tokens & shares for the pool.
     */
    struct Pool {
        uint256 eth;                                        // Total eth reserves in the pool
        uint256 shares;                                     // Total shares minted for the pool
        mapping(address => Depositor) depositors;           // Mapping of depositors participating in the pool
    }

    /**
     * @dev ETHPool data. Captures data related to
     * Designed to be extensible, in the event that other params need to be added (cooldowns, limits, etc.)
     */
    struct Depositor {
        uint256 shares;                                     // Pool shares owned by the depositor
    }
}