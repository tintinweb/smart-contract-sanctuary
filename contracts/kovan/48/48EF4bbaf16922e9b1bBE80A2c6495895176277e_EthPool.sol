// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @notice EthPool Contract
/// User can deposit and earn reward.
/// User can withdraw his/her deposit amount and reward.
/// Only team can deposit reward, it is separated to the depositors based on the deposit share on the pool.
/// Only owner can change the team.
contract EthPool is Ownable {
    /// @notice Info of User who deposit to the pool.
    /// `amount` Amount of Eth the user has deposited.
    /// `reward` Amount of Eth the user has been rewarded.
    struct UserInfo {
        uint amount;
        uint reward;
    }

    /// @notice Address of team - who can deposit reward.
    address public team;
    /// @notice Addresses of the users deposited to the pool.
    address[] public users;
    /// @notice Info of all users.
    mapping (address => UserInfo) public userInfo;
    /// @notice Total deposit amount.
    uint public totalAmount;

    event ChangeTeam(address indexed from, address indexed to);
    event Deposit(address indexed from, uint amount);
    event DepositReward(address from, uint indexed amount);
    event Withdraw(address to, uint amount);

    modifier onlyTeam() {
        require(msg.sender == team, "ExactlyFinancePool: Caller is not team.");
        _;
    }

    modifier onlyNonZeroAddress() {
        require(msg.sender != address(0), "ExactlyFinancePool: Caller is not valid.");
        _;
    }

    /// @notice constructor
    /// set msg sender as a team
    constructor() {
        _setTeam(msg.sender);
    }

    /// @notice set caller as a team
    /// @param _to Address of the new team
    function changeTeam(address _to) public onlyOwner {
        _setTeam(_to);
    }

    /// @notice deposit Eth to the pool
    /// updates deposit amount of user and total deposit amount
    function deposit() onlyNonZeroAddress external payable {
        require(msg.sender != address(0), "ExactlyFinancePool: Invalid address.");
        require(msg.sender != team, "ExactlyFinancePool: Team can't deposit.");

        (bool isDepositor,) = _isUserExist(msg.sender);
        if (!isDepositor)
            users.push(msg.sender);

        UserInfo storage user = userInfo[msg.sender];
        user.amount = user.amount + msg.value;
        totalAmount = totalAmount + msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    /// @notice team deposits reward
    /// reward are separated to each depositors based on the deposit share on the pool
    function depositReward() onlyTeam external payable {
        require(msg.value > 0, "ExactlyFinancePool: Invalid reward amount.");
        uint i;
        uint userReward;
        for (; i < users.length; i++) {
            userReward = msg.value * userInfo[users[i]].amount / totalAmount;
            userInfo[users[i]].reward += userReward;
        }

        emit DepositReward(msg.sender, msg.value);
    }

    /// @notice withdraw deposit & reward amount of user
    /// removes user & deposit info and transfer amount + reward to sender's address
    function withdraw() public {
        (bool isDepositor, uint userIndex) = _isUserExist(msg.sender);
        require(isDepositor, "ExactlyFinancePool: Only depositors can withdraw.");
        UserInfo storage user = userInfo[msg.sender];
        totalAmount = totalAmount - user.amount;

        uint balance = user.amount + user.reward;
        payable(msg.sender).transfer(balance);

        delete users[userIndex];
        delete userInfo[msg.sender];

        emit Withdraw(msg.sender, balance);
    }

    /// @notice update the team
    function _setTeam(address _to) internal {
        address oldTeam = team;
        team = _to;
        emit ChangeTeam(oldTeam, team);
    }

    /// @notice check if user exists on the pool
    /// @return existance and index(if not exists, returns false, 0)
    function _isUserExist(address _user) internal view returns (bool, uint) {
        uint i = 0;
        for (; i < users.length; i++)
            if (users[i] == _user)
                return (true, i);

        return (false, 0);
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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}