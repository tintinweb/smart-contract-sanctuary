// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC20PresetMinterPauser.sol";

contract DimitraToken is ERC20PresetMinterPauser {
    uint public immutable cap;
    bytes32 private constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
  
    mapping (address => mapping(uint => uint)) private lockBoxMap; // Mapping of user => releaseTime => amount
    mapping (address => uint[]) private userReleaseTimes; // user => releaseTime array
    uint [] private updatedReleaseTimes;

    uint public totalLockBoxBalance;

    event LogIssueLockedTokens(address sender, address recipient, uint amount, uint releaseTime);

    constructor() ERC20PresetMinterPauser("Dimitra Token", "DMTR") {
        cap = 1000000000 * (10 ** uint(decimals())); // Cap limit set to 1 billion tokens
        _setupRole(ISSUER_ROLE,_msgSender());
    }

    function mint(address account, uint256 amount) public virtual override {
        require(ERC20.totalSupply() + amount <= cap, "DimitraToken: Cap exceeded");
        ERC20PresetMinterPauser.mint(account, amount);
    }

    function issueLockedTokens(address recipient, uint lockAmount, uint releaseTime) public { // NOTE: releaseTime is date calculated in front end (at 12:00:00 AM)
        address sender = _msgSender();

        require(hasRole(ISSUER_ROLE, sender), "DimitraToken: Must have issuer role to issue locked tokens");
        require(releaseTime > block.timestamp, "DimitraToken: Release time must be greater than current block time");

        lockBoxMap[recipient][releaseTime] += lockAmount;

        bool releaseTimeExists = false;
        for (uint i=0; i<userReleaseTimes[recipient].length; i++) { // for a given recipient, release times should be unique
            if (userReleaseTimes[recipient][i] == releaseTime) {
                releaseTimeExists = true;
            }
        }
        if (!releaseTimeExists) {
            userReleaseTimes[recipient].push(releaseTime);
        }
        totalLockBoxBalance += lockAmount;

        _transfer(sender, recipient, lockAmount);

        emit LogIssueLockedTokens(msg.sender, recipient, lockAmount, releaseTime);
    }

    function _transfer (address sender, address recipient, uint256 amount) internal override {
        unlockTokens(sender,amount);
        return super._transfer(sender, recipient, amount);
    }

    function unlockTokens(address sender, uint amount) internal {
        uint256 len = userReleaseTimes[sender].length;
        uint256 j;
        uint lockedAmount;
        for (uint i = 0; i < len; i++) { // Release all expired locks
            uint256 releaseTime = userReleaseTimes[sender][j];
            if(block.timestamp <= releaseTime) {
                lockedAmount += lockBoxMap[sender][releaseTime];
                j++;
            } else {
                totalLockBoxBalance -= lockBoxMap[sender][releaseTime];
                delete lockBoxMap[sender][releaseTime];
                userReleaseTimes[sender][j] = userReleaseTimes[sender][userReleaseTimes[sender].length - 1];
                userReleaseTimes[sender].pop();
            }
        }
        require(balanceOf(sender) - lockedAmount >= amount, "DimitraToken: Insufficient balance");
    }

    function getLockedBalance(address user) public view returns (uint userLockBoxBalance) {
        uint[] memory releaseTimes = userReleaseTimes[user];

        for (uint i = 0; i < releaseTimes.length; i++) {
            if (block.timestamp <= releaseTimes[i]) {
                userLockBoxBalance += lockBoxMap[user][releaseTimes[i]];
            }
        }
    }

    function getReleasedBalance(address user) public view returns (uint) {
        return balanceOf(user) - getLockedBalance(user);
    }
}