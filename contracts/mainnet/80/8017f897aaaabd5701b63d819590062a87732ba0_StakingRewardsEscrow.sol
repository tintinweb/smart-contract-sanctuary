/**
 *Submitted for verification at Etherscan.io on 2021-08-15
*/

/// StakingRewardsEscrow.sol

// Copyright (C) 2021 Reflexer Labs, INC
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.6.7;

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

    constructor () internal {
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

abstract contract TokenLike {
    function balanceOf(address) virtual public view returns (uint256);
    function transfer(address, uint256) virtual external returns (bool);
}

contract StakingRewardsEscrow is ReentrancyGuard {
    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) virtual external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) virtual external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "StakingRewardsEscrow/account-not-authorized");
        _;
    }

    // --- Structs ---
    struct EscrowSlot {
        uint256 total;
        uint256 startDate;
        uint256 duration;
        uint256 claimedUntil;
        uint256 amountClaimed;
    }

    // --- Variables ---
    // The address allowed to request escrows
    address   public escrowRequestor;
    // The time during which a chunk is escrowed
    uint256   public escrowDuration;
    // Time in a slot during which rewards to escrow can be added without creating a new escrow slot
    uint256   public durationToStartEscrow;
    // Current amount of slots to claim in one shot
    uint256   public slotsToClaim;
    // The token to escrow
    TokenLike public token;

    uint256   public constant MAX_ESCROW_DURATION          = 365 days;
    uint256   public constant MAX_DURATION_TO_START_ESCROW = 30 days;
    uint256   public constant MAX_SLOTS_TO_CLAIM           = 25;

    // Oldest slot from which to start claiming unlocked rewards
    mapping (address => uint256)                        public oldestEscrowSlot;
    // Next slot to fill for every user
    mapping (address => uint256)                        public currentEscrowSlot;
    // All escrows for all accounts
    mapping (address => mapping(uint256 => EscrowSlot)) public escrows;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ModifyParameters(bytes32 indexed parameter, uint256 data);
    event ModifyParameters(bytes32 indexed parameter, address data);
    event EscrowRewards(address indexed who, uint256 amount, uint256 currentEscrowSlot);
    event ClaimRewards(address indexed who, uint256 amount);

    constructor(
      address escrowRequestor_,
      address token_,
      uint256 escrowDuration_,
      uint256 durationToStartEscrow_
    ) public {
      require(escrowRequestor_ != address(0), "StakingRewardsEscrow/null-requestor");
      require(token_ != address(0), "StakingRewardsEscrow/null-token");
      require(both(escrowDuration_ > 0, escrowDuration_ <= MAX_ESCROW_DURATION), "StakingRewardsEscrow/invalid-escrow-duration");
      require(both(durationToStartEscrow_ > 0, durationToStartEscrow_ < escrowDuration_), "StakingRewardsEscrow/invalid-duration-start-escrow");
      require(escrowDuration_ > durationToStartEscrow_, "StakingRewardsEscrow/");

      authorizedAccounts[msg.sender] = 1;

      escrowRequestor        = escrowRequestor_;
      token                  = TokenLike(token_);
      escrowDuration         = escrowDuration_;
      durationToStartEscrow  = durationToStartEscrow_;
      slotsToClaim           = MAX_SLOTS_TO_CLAIM;

      emit AddAuthorization(msg.sender);
    }

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    // --- Math ---
    function addition(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "StakingRewardsEscrow/add-overflow");
    }
    function subtract(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "StakingRewardsEscrow/sub-underflow");
    }
    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "StakingRewardsEscrow/mul-overflow");
    }
    function minimum(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    // --- Administration ---
    /*
    * @notify Modify an uint256 parameter
    * @param parameter The name of the parameter to modify
    * @param data New value for the parameter
    */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "escrowDuration") {
          require(both(data > 0, data <= MAX_ESCROW_DURATION), "StakingRewardsEscrow/invalid-escrow-duration");
          require(data > durationToStartEscrow, "StakingRewardsEscrow/smaller-than-start-escrow-duration");
          escrowDuration = data;
        }
        else if (parameter == "durationToStartEscrow") {
          require(both(data > 1, data <= MAX_DURATION_TO_START_ESCROW), "StakingRewardsEscrow/duration-to-start-escrow");
          require(data < escrowDuration, "StakingRewardsEscrow/not-lower-than-escrow-duration");
          durationToStartEscrow = data;
        }
        else if (parameter == "slotsToClaim") {
          require(both(data >= 1, data <= MAX_SLOTS_TO_CLAIM), "StakingRewardsEscrow/invalid-slots-to-claim");
          slotsToClaim = data;
        }
        else revert("StakingRewardsEscrow/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }
    /*
    * @notify Modify an address parameter
    * @param parameter The name of the parameter to modify
    * @param data New value for the parameter
    */
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        require(data != address(0), "StakingRewardsEscrow/null-data");

        if (parameter == "escrowRequestor") {
            escrowRequestor = data;
        }
        else revert("StakingRewardsEscrow/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }

    // --- Core Logic ---
    /*
    * @notice Put more rewards under escrow for a specific address
    * @param who The address that will get escrowed tokens
    * @param amount Amount of tokens to escrow
    */
    function escrowRewards(address who, uint256 amount) external nonReentrant {
        require(escrowRequestor == msg.sender, "StakingRewardsEscrow/not-requestor");
        require(who != address(0), "StakingRewardsEscrow/null-who");
        require(amount > 0, "StakingRewardsEscrow/null-amount");

        if (
          either(currentEscrowSlot[who] == 0,
          now > addition(escrows[who][currentEscrowSlot[who] - 1].startDate, durationToStartEscrow))
        ) {
          escrows[who][currentEscrowSlot[who]] = EscrowSlot(amount, now, escrowDuration, now, 0);
          currentEscrowSlot[who] = addition(currentEscrowSlot[who], 1);
        } else {
          escrows[who][currentEscrowSlot[who] - 1].total = addition(escrows[who][currentEscrowSlot[who] - 1].total, amount);
        }

        emit EscrowRewards(who, amount, currentEscrowSlot[who] - 1);
    }
    /**
    * @notice Return the total amount of tokens that are being escrowed for a specific account
    * @param who The address for which we calculate the amount of tokens that are still waiting to be unlocked
    */
    function getTokensBeingEscrowed(address who) public view returns (uint256) {
        if (oldestEscrowSlot[who] >= currentEscrowSlot[who]) return 0;

        EscrowSlot memory escrowReward;

        uint256 totalEscrowed;
        uint256 endDate;

        for (uint i = oldestEscrowSlot[who]; i <= currentEscrowSlot[who]; i++) {
            escrowReward = escrows[who][i];
            endDate      = addition(escrowReward.startDate, escrowReward.duration);

            if (escrowReward.amountClaimed >= escrowReward.total) {
              continue;
            }

            if (both(escrowReward.claimedUntil < endDate, now >= endDate)) {
              continue;
            }

            totalEscrowed = addition(totalEscrowed, subtract(escrowReward.total, escrowReward.amountClaimed));
        }

        return totalEscrowed;
    }
    /*
    * @notice Return the total amount of tokens that can be claimed right now for an address
    * @param who The address to claim on behalf of
    */
    function getClaimableTokens(address who) public view returns (uint256) {
        if (currentEscrowSlot[who] == 0) return 0;
        if (oldestEscrowSlot[who] >= currentEscrowSlot[who]) return 0;

        uint256 lastSlotToClaim = (subtract(currentEscrowSlot[who], oldestEscrowSlot[who]) > slotsToClaim) ?
          addition(oldestEscrowSlot[who], subtract(slotsToClaim, 1)) : subtract(currentEscrowSlot[who], 1);

        EscrowSlot memory escrowReward;

        uint256 totalToTransfer;
        uint256 endDate;
        uint256 reward;

        for (uint i = oldestEscrowSlot[who]; i <= lastSlotToClaim; i++) {
            escrowReward = escrows[who][i];
            endDate      = addition(escrowReward.startDate, escrowReward.duration);

            if (escrowReward.amountClaimed >= escrowReward.total) {
              continue;
            }

            if (both(escrowReward.claimedUntil < endDate, now >= endDate)) {
              totalToTransfer = addition(totalToTransfer, subtract(escrowReward.total, escrowReward.amountClaimed));
              continue;
            }

            if (escrowReward.claimedUntil == now) continue;

            reward = subtract(escrowReward.total, escrowReward.amountClaimed) / subtract(endDate, escrowReward.claimedUntil);
            reward = multiply(reward, subtract(now, escrowReward.claimedUntil));
            if (addition(escrowReward.amountClaimed, reward) > escrowReward.total) {
              reward = subtract(escrowReward.total, escrowReward.amountClaimed);
            }

            totalToTransfer = addition(totalToTransfer, reward);
        }

        return totalToTransfer;
    }
    /*
    * @notice Claim vested tokens
    * @param who The address to claim on behalf of
    */
    function claimTokens(address who) public nonReentrant {
        require(currentEscrowSlot[who] > 0, "StakingRewardsEscrow/invalid-address");
        require(oldestEscrowSlot[who] < currentEscrowSlot[who], "StakingRewardsEscrow/no-slot-to-claim");

        uint256 lastSlotToClaim = (subtract(currentEscrowSlot[who], oldestEscrowSlot[who]) > slotsToClaim) ?
          addition(oldestEscrowSlot[who], subtract(slotsToClaim, 1)) : subtract(currentEscrowSlot[who], 1);

        EscrowSlot storage escrowReward;

        uint256 totalToTransfer;
        uint256 endDate;
        uint256 reward;

        for (uint i = oldestEscrowSlot[who]; i <= lastSlotToClaim; i++) {
            escrowReward = escrows[who][i];
            endDate      = addition(escrowReward.startDate, escrowReward.duration);

            if (escrowReward.amountClaimed >= escrowReward.total) {
              oldestEscrowSlot[who] = addition(oldestEscrowSlot[who], 1);
              continue;
            }

            if (both(escrowReward.claimedUntil < endDate, now >= endDate)) {
              totalToTransfer            = addition(totalToTransfer, subtract(escrowReward.total, escrowReward.amountClaimed));
              escrowReward.amountClaimed = escrowReward.total;
              escrowReward.claimedUntil  = now;
              oldestEscrowSlot[who]      = addition(oldestEscrowSlot[who], 1);
              continue;
            }

            if (escrowReward.claimedUntil == now) continue;

            reward = subtract(escrowReward.total, escrowReward.amountClaimed) / subtract(endDate, escrowReward.claimedUntil);
            reward = multiply(reward, subtract(now, escrowReward.claimedUntil));
            if (addition(escrowReward.amountClaimed, reward) > escrowReward.total) {
              reward = subtract(escrowReward.total, escrowReward.amountClaimed);
            }

            totalToTransfer            = addition(totalToTransfer, reward);
            escrowReward.amountClaimed = addition(escrowReward.amountClaimed, reward);
            escrowReward.claimedUntil  = now;
        }

        if (totalToTransfer > 0) {
            require(token.transfer(who, totalToTransfer), "StakingRewardsEscrow/cannot-transfer-rewards");
        }

        emit ClaimRewards(who, totalToTransfer);
    }
}