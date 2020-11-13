// SPDX-License-Identifier:MIT
pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/IStakeManager.sol";

contract StakeManager is IStakeManager {
    using SafeMath for uint256;

    string public override versionSM = "2.0.0+opengsn.stakemanager.istakemanager";

    /// maps relay managers to their stakes
    mapping(address => StakeInfo) public stakes;
    function getStakeInfo(address relayManager) external override view returns (StakeInfo memory stakeInfo) {
        return stakes[relayManager];
    }

    /// maps relay managers to a map of addressed of their authorized hubs to the information on that hub
    mapping(address => mapping(address => RelayHubInfo)) public authorizedHubs;

    /// Put a stake for a relayManager and set its unstake delay.
    /// If the entry does not exist, it is created, and the caller of this function becomes its owner.
    /// If the entry already exists, only the owner can call this function.
    /// @param relayManager - address that represents a stake entry and controls relay registrations on relay hubs
    /// @param unstakeDelay - number of blocks to elapse before the owner can retrieve the stake after calling 'unlock'
    function stakeForAddress(address relayManager, uint256 unstakeDelay) external override payable {
        require(stakes[relayManager].owner == address(0) || stakes[relayManager].owner == msg.sender, "not owner");
        require(unstakeDelay >= stakes[relayManager].unstakeDelay, "unstakeDelay cannot be decreased");
        require(msg.sender != relayManager, "relayManager cannot stake for itself");
        require(stakes[msg.sender].owner == address(0), "sender is a relayManager itself");
        stakes[relayManager].owner = msg.sender;
        stakes[relayManager].stake += msg.value;
        stakes[relayManager].unstakeDelay = unstakeDelay;
        emit StakeAdded(relayManager, stakes[relayManager].owner, stakes[relayManager].stake, stakes[relayManager].unstakeDelay);
    }

    function unlockStake(address relayManager) external override {
        StakeInfo storage info = stakes[relayManager];
        require(info.owner == msg.sender, "not owner");
        require(info.withdrawBlock == 0, "already pending");
        info.withdrawBlock = block.number.add(info.unstakeDelay);
        emit StakeUnlocked(relayManager, msg.sender, info.withdrawBlock);
    }

    function withdrawStake(address relayManager) external override {
        StakeInfo storage info = stakes[relayManager];
        require(info.owner == msg.sender, "not owner");
        require(info.withdrawBlock > 0, "Withdrawal is not scheduled");
        require(info.withdrawBlock <= block.number, "Withdrawal is not due");
        uint256 amount = info.stake;
        delete stakes[relayManager];
        msg.sender.transfer(amount);
        emit StakeWithdrawn(relayManager, msg.sender, amount);
    }

    modifier ownerOnly (address relayManager) {
        StakeInfo storage info = stakes[relayManager];
        require(info.owner == msg.sender, "not owner");
        _;
    }

    modifier managerOnly () {
        StakeInfo storage info = stakes[msg.sender];
        require(info.owner != address(0), "not manager");
        _;
    }

    function authorizeHubByOwner(address relayManager, address relayHub) external ownerOnly(relayManager) override {
        _authorizeHub(relayManager, relayHub);
    }

    function authorizeHubByManager(address relayHub) external managerOnly override {
        _authorizeHub(msg.sender, relayHub);
    }

    function _authorizeHub(address relayManager, address relayHub) internal {
        authorizedHubs[relayManager][relayHub].removalBlock = uint(-1);
        emit HubAuthorized(relayManager, relayHub);
    }

    function unauthorizeHubByOwner(address relayManager, address relayHub) external override ownerOnly(relayManager) {
        _unauthorizeHub(relayManager, relayHub);
    }

    function unauthorizeHubByManager(address relayHub) external override managerOnly {
        _unauthorizeHub(msg.sender, relayHub);
    }

    function _unauthorizeHub(address relayManager, address relayHub) internal {
        RelayHubInfo storage hubInfo = authorizedHubs[relayManager][relayHub];
        require(hubInfo.removalBlock == uint(-1), "hub not authorized");
        uint256 removalBlock = block.number.add(stakes[relayManager].unstakeDelay);
        hubInfo.removalBlock = removalBlock;
        emit HubUnauthorized(relayManager, relayHub, removalBlock);
    }

    function isRelayManagerStaked(address relayManager, address relayHub, uint256 minAmount, uint256 minUnstakeDelay)
    external
    override
    view
    returns (bool) {
        StakeInfo storage info = stakes[relayManager];
        bool isAmountSufficient = info.stake >= minAmount;
        bool isDelaySufficient = info.unstakeDelay >= minUnstakeDelay;
        bool isStakeLocked = info.withdrawBlock == 0;
        bool isHubAuthorized = authorizedHubs[relayManager][relayHub].removalBlock == uint(-1);
        return
        isAmountSufficient &&
        isDelaySufficient &&
        isStakeLocked &&
        isHubAuthorized;
    }

    /// Slash the stake of the relay relayManager. In order to prevent stake kidnapping, burns half of stake on the way.
    /// @param relayManager - entry to penalize
    /// @param beneficiary - address that receives half of the penalty amount
    /// @param amount - amount to withdraw from stake
    function penalizeRelayManager(address relayManager, address payable beneficiary, uint256 amount) external override {
        uint256 removalBlock =  authorizedHubs[relayManager][msg.sender].removalBlock;
        require(removalBlock != 0, "hub not authorized");
        require(removalBlock > block.number, "hub authorization expired");

        // Half of the stake will be burned (sent to address 0)
        require(stakes[relayManager].stake >= amount, "penalty exceeds stake");
        stakes[relayManager].stake = SafeMath.sub(stakes[relayManager].stake, amount);

        uint256 toBurn = SafeMath.div(amount, 2);
        uint256 reward = SafeMath.sub(amount, toBurn);

        // Ether is burned and transferred
        address(0).transfer(toBurn);
        beneficiary.transfer(reward);
        emit StakePenalized(relayManager, beneficiary, reward);
    }
}
