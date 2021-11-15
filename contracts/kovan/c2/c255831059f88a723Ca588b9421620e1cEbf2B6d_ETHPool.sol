// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @notice ETHPool provides a service where people can deposit ETH and they will receive weekly rewards.
 */
contract ETHPool is ReentrancyGuard {
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    address public team;
    uint256 public totalBalance; // totalBalance = pool's ETH balance
    uint256 public totalScaledBalance; // index = totalBalance / totalScaledBalance
    mapping(address => uint256) public userScaledBalance; // userBalance = userScaledBalance * index

    /**
     * @dev Throws if called by any account other than the team.
     */
    modifier onlyTeam() {
        require(team == msg.sender, "caller is not the team");
        _;
    }

    constructor(address _team) ReentrancyGuard() {
        team = _team;
    }

    /**
     * @dev Returns the user's balance including rewards. (balance = scaled balance * index)
     */
    function userBalance(address user) public view returns (uint256) {
        if (userScaledBalance[user] == 0) {
            return 0;
        }

        return (userScaledBalance[user] * totalBalance) / totalScaledBalance;
    }

    /**
     * @notice Users can deposit ETH
     * @dev Calculate user's scaled balance based on the current index.
     */
    function deposit() external payable {
        uint256 scaledBalance = msg.value;
        if (totalBalance != 0) {
            scaledBalance = (scaledBalance * totalScaledBalance) / totalBalance;
        }

        userScaledBalance[msg.sender] += scaledBalance;
        totalScaledBalance += scaledBalance;
        totalBalance += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice Users can withdraw ETH
     * @dev Calculate user's balance based on the current index.
     */
    function withdraw() external nonReentrant {
        uint256 withdrawAmount = userBalance(msg.sender);
        require(withdrawAmount != 0, "no withdrawl balance");

        totalScaledBalance -= userScaledBalance[msg.sender];
        userScaledBalance[msg.sender] = 0;
        totalBalance -= withdrawAmount;

        (bool success, ) = msg.sender.call{value: withdrawAmount}("");
        require(success, "failed to withdraw");

        emit Withdraw(msg.sender, withdrawAmount);
    }

    /**
     * @notice Team can deposit rewards in ETH
     */
    function distributeRewards() external payable onlyTeam {
        totalBalance += msg.value;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

