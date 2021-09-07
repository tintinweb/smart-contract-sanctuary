// SPDX-License-Identifier: UNLICENSE
// Rzucam 70mln worków w tłum w tłum .. kto łapie ten jara ... XD

/**
Apes Together Strong!

About BigShortBets DeFi project:

We are creating a social&trading p2p platform that guarantees encrypted interaction between investors.
Logging in is possible via a cryptocurrency wallet (e.g. Metamask).
The security level is one comparable to the Tor network.

https://bigsb.io/ - Our Tool
https://bigshortbets.com - Project&Team info

Video explainer:
https://youtu.be/wbhUo5IvKdk

Zaorski, You Son of a bitch I’m in …
*/

pragma solidity 0.8.7;
import "./owned.sol";
import "./reentryGuard.sol";
import "./interfaces.sol";

contract BigSBsaleClaim is Owned, Guarded {
    /**
        Claiming contract for BigSB public sale
        @param sale address of sale contract
        @param token address of BigSB token tontract
     */
    constructor(address sale, address token) {
        saleContract = sale;
        tokenContract = token;
        emergencyUnlock = block.timestamp + 720 days;
    }

    /// timestamp moving 2 years of last lock made
    uint256 public emergencyUnlock;

    address public immutable tokenContract;
    address public immutable saleContract;

    struct Lock {
        uint256 reflection;
        uint256 locktime;
    }

    /// Storage of user locks by address
    mapping(address => Lock[]) public userLocks;

    /**
        Add lock for user, can be called only by sale contract.
        Using contract reflection rate it can earn from transfer fees.
        @param user address of user
        @param reflection amount of reflection tokens
        @param locktime timestamp after which tokens can be released
     */
    function addLock(
        address user,
        uint256 reflection,
        uint256 locktime
    ) external {
        require(msg.sender == saleContract, "Only sale contract");
        userLocks[user].push(Lock(reflection, locktime));
        emergencyUnlock = block.timestamp + 720 days;
    }

    /// claim all tokens than can be claimed
    function claim() external guarded {
        uint256 len = userLocks[msg.sender].length;
        require(len > 0, "Nothing locked");
        uint256 i;
        uint256 timeNow = block.timestamp;
        uint256 amt;
        for (i; i < len; i++) {
            Lock memory l = userLocks[msg.sender][i];
            if (timeNow > l.locktime && l.reflection > 0) {
                amt += IReflect(tokenContract).tokenFromReflection(
                    l.reflection
                );
                // tokens taken
                userLocks[msg.sender][i].reflection = 0;
            }
        }
        require(amt > 0, "Nothing to claim");
        IERC20(tokenContract).transfer(msg.sender, amt);
    }

    /// return all user locks
    function getUserLocks(address user) external view returns (Lock[] memory) {
        return userLocks[user];
    }

    /// return balance of user from all locks
    function balanceOf(address user) external view returns (uint256 amt) {
        uint256 len = userLocks[user].length;
        if (len == 0) return amt;
        uint256 i;
        for (i; i < len; i++) {
            amt += IReflect(tokenContract).tokenFromReflection(
                userLocks[user][i].reflection
            );
        }
        return amt;
    }

    /// How many tokens user can claim now?
    function claimable(address user) external view returns (uint256 amt) {
        uint256 len = userLocks[user].length;
        if (len == 0) return amt;
        uint256 i;
        uint256 timeNow = block.timestamp;
        for (i; i < len; i++) {
            Lock memory l = userLocks[user][i];
            if (timeNow > l.locktime) {
                amt += IReflect(tokenContract).tokenFromReflection(
                    l.reflection
                );
            }
        }
        return amt;
    }

    //
    // Emergency functions
    //
    /**
        Take ETH from contract
    */
    function withdrawEth() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    /**
        Take any ERC20 from contract
        BigSB is possible after 2 years form last lock event
    */
    function withdrawErc20(address token) external onlyOwner {
        if (token == tokenContract) {
            require(block.timestamp > emergencyUnlock, "Too soon");
        }
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "Nothing to withdraw");
        // use broken IERC20
        IUsdt(token).transfer(owner, balance);
    }
}
//This is fine!