/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

// SPDX-License-Identifier: GNU
pragma solidity ^0.8.2;

/*
    ERC20 Standard Token interface
*/
interface IERC20 {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
}

/**
 * @dev Time-locks tokens according to an unlock schedule and address.
 */
contract TokenLock {
    IERC20 public immutable token;
    uint256 public immutable unlockBegin;
    uint256 public immutable unlockCliff;
    uint256 public immutable unlockEnd;
    
    address[] public lockedAddress;

    mapping(address=>uint256) public lockedAmounts;
    mapping(address=>uint256) public claimedAmounts;

    event Locked(address indexed sender, address indexed recipient, uint256 amount);
    event Claimed(address indexed owner, address indexed recipient, uint256 amount);

    /**
     * @dev Constructor.
     * @param _token The token this contract will lock.
     * @param _unlockBegin The time at which unlocking of tokens will begin.
     * @param _unlockCliff The first time at which tokens are claimable.
     * @param _unlockEnd The time at which the last token will unlock.
     */
    constructor(IERC20 _token, uint256 _unlockBegin, uint256 _unlockCliff, uint256 _unlockEnd) {
        require(_unlockBegin >= block.timestamp, "ERC20Locked: Unlock must begin in the future");
        require(_unlockCliff >= _unlockBegin, "ERC20Locked: Unlock cliff must not be before unlock begin");
        require(_unlockEnd >= _unlockCliff, "ERC20Locked: Unlock end must not be before unlock cliff");
        token = _token;
        unlockBegin = _unlockBegin;
        unlockCliff = _unlockCliff;
        unlockEnd = _unlockEnd;
    }

    /**
     * @dev Returns the maximum number of tokens currently claimable by `owner`.
     * @param owner The account to check the claimable amounts of.
     * @return The number of tokens currently claimable.
     */
    function claimableAmounts(address owner) public view returns(uint256) {
        if(block.timestamp < unlockCliff) {
            return 0;
        }
        uint256 locked = lockedAmounts[owner];
        uint256 claimed = claimedAmounts[owner];
        if(block.timestamp >= unlockEnd) {
            return locked - claimed;
        }
        return (locked * (block.timestamp - unlockBegin)) / (unlockEnd - unlockBegin) - claimed;
    }

    /**
     * @dev Transfers tokens from the caller to the token lock contract and locks them for benefit of `recipient`.
     *      Requires that the caller has authorised this contract with the token contract.
     * @param recipient The account the tokens will be claimable by.
     * @param amount The number of tokens to transfer and lock.
     */
    function lock(address recipient, uint256 amount) external {
        require(block.timestamp < unlockEnd, "TokenLock: Unlock period already complete");
        lockedAmounts[recipient] += amount;
        require(token.transferFrom(msg.sender, address(this), amount), "TokenLock: Transfer failed");
        emit Locked(msg.sender, recipient, amount);
        lockedAddress.push(recipient);
    }

    /**
     * @dev Claims the caller's tokens that have been unlocked, sending them to `recipient`.
     * @param recipient The account to transfer unlocked tokens to.
     * @param amount The amount to transfer. If greater than the claimable amount, the maximum is transferred.
     */
    function claim(address recipient, uint256 amount) external {
        uint256 claimable = claimableAmounts(msg.sender);
        if(amount > claimable) {
            amount = claimable;
        }
        claimedAmounts[msg.sender] += amount;
        require(token.transfer(recipient, amount), "TokenLock: Transfer failed");
        emit Claimed(msg.sender, recipient, amount);
    }

    /**
     * @dev Return total locked amount for all addresses.
     * @return Return total locked amount for all addresses.
     */
    function totalLockedAmount() public view returns(uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < lockedAddress.length; i++) {
            total += lockedAmounts[lockedAddress[i]];
        }
        return total;
    }

    /**
     * @dev Return total claimed amount for all addresses.
     * @return Return total claimed amount for all addresses.
     */
    function totalClaimedAmount() public view returns(uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < lockedAddress.length; i++) {
            total += claimedAmounts[lockedAddress[i]];
        }
        return total;
    }

    /**
     * @dev Return total claimable amount for all addresses.
     * @return Return total claimable amount for all addresses.
     */
    function totalClaimableAmount() public view returns(uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < lockedAddress.length; i++) {
            total += claimableAmounts(lockedAddress[i]);
        }
        return total;
    }

    /**
     * @dev Return all locked addresses.
     * @return Return all locked addresses.
     */
    function getLockedAddresses() public view returns (address[] memory) {
        return lockedAddress;
    }
}