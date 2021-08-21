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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
  Timelock contract.
  Fixed token payout and timing.
  Can add recipients and multiple grants per recipient.

  @author iain
  github.com/iainnash/simple-timelock
 */
contract Timelock {
    // From IERC20
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    /**
        Error codes lookup:
        1: Recover and recieve grant days need to be greater than 0
        2: Grant not valid.
        3: Only owner can add grants.
        4: Only owner can recover
        5: Cannot set the recovery grant before the unlock time
        6: Too early to recover
        7: Too early to claim
        8: Recover timestamp needs to be after receive timestamp
        9: Already granted
        10: Cannot grant after unlock
        11: Token not approved or not enough
        12: Invalid ownership
    */

    // Timestamp for when the recovery begins
    uint256 public immutable timeRecoverGrant;
    // Timestamp for when the receive begins
    uint256 public immutable timeReceiveGrant;
    // Owner that can recover grant and add new grant addresses
    address private immutable owner;
    // Token to lock
    IERC20 private immutable token;

    // Mapping of address to grant
    mapping(address => uint256) private grants;

    // Emitted when a claim is recovered
    event Recovered(address recipient, uint256 amount);

    // Emitted when a claim is claimed
    event Claimed(address actor, uint256 amount);

    // Emitted when a grant is added
    event GrantsAdded(address actor, address[] newRecipients);

    modifier onlyOwner() {
        require(msg.sender == owner, "3");
        _;
    }

    /**
        Sets up grant created by TimelockCreator Contract
     */
    constructor(
        address _owner,
        IERC20 _token,
        uint256 unlockTimestamp,
        uint256 recoverTimestamp
    ) {
        token = _token;
        owner = _owner;
        require(
            unlockTimestamp > block.timestamp &&
                recoverTimestamp > block.timestamp,
            "1"
        );
        require(recoverTimestamp > unlockTimestamp, "8");
        timeReceiveGrant = unlockTimestamp;
        timeRecoverGrant = recoverTimestamp;
    }

    /**
        Returns token for timelock and amount per recipient
     */
    function getToken() public view returns (IERC20) {
        return token;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    /** 
        Returns the time users can recieve the grant / when the timelock expires
     */
    function getTimeUnlock() public view returns (uint256) {
        return timeReceiveGrant;
    }

    /** 
        Returns the admin can recover unclaimed grants
     */
    function getTimeRecover() public view returns (uint256) {
        return timeRecoverGrant;
    }

    /**
        Proxied token information for bookkeeping / discoverability
        Not implemented:
            1. approvals
            2. transfers
            etc.
    */
    function balanceOf(address user) public view returns (uint256) {
        return grants[user];
    }

    function totalSupply() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function decimals() public view returns (uint8) {
        return IERC20Metadata(address(token)).decimals();
    }

    function name() public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "Timelocked ",
                    IERC20Metadata(address(token)).name()
                )
            );
    }

    function symbol() public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "LOCK_",
                    IERC20Metadata(address(token)).symbol()
                )
            );
    }

    /** 
        @dev Adds a grant to the timelock
        Grants can be added at any time before claim period.
    */
    function addGrants(address[] memory newRecipients, uint256 grantSize)
        external
        onlyOwner
    {
        require(grantSize > 0, "2");
        require(getTimeUnlock() > block.timestamp, "10");
        require(
            token.allowance(msg.sender, address(this)) >=
                newRecipients.length * grantSize,
            "11"
        );

        uint256 numberRecipients = newRecipients.length;
        token.transferFrom(
            msg.sender,
            address(this),
            grantSize * numberRecipients
        );
        for (uint256 i = 0; i < numberRecipients; i++) {
            emit Transfer(address(0), newRecipients[i], grantSize);
            grants[newRecipients[i]] += grantSize;
        }
        emit GrantsAdded(owner, newRecipients);
    }

    /** 
        Returns the status of the grant.
     */
    function grantedAmount(address recipient) external view returns (uint256) {
        return grants[recipient];
    }

    /**
        Allows a user to claim their grant. Claimee has to be msg.sender.
     */
    function claim() external {
        address recipient = msg.sender;
        require(block.timestamp >= timeReceiveGrant, "7");
        uint256 grantAmount = grants[recipient];
        require(grantAmount > 0, "2");
        token.transfer(recipient, grantAmount);
        grants[recipient] = 0;
        // Emit grant claimed event
        emit Claimed(recipient, grantAmount);
        // Burn tracker token
        emit Transfer(recipient, address(0x0), grantAmount);
    }

    /**
        The owner of the grant can recover after the recovery timestamp passes.
        This sweeps remaining funds and destroys the contract data.
     */
    function recover() external onlyOwner {
        address payable sender = payable(msg.sender);
        require(block.timestamp >= timeRecoverGrant, "6");
        uint256 balance = token.balanceOf(address(this));
        emit Recovered(sender, balance);
        token.transfer(sender, balance);
        selfdestruct(sender);
    }
}

{
  "evmVersion": "berlin",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 40
  },
  "remappings": [],
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