/**
 *Submitted for verification at Etherscan.io on 2021-08-30
*/

// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.5.17;

interface IAddressConfig {
        function token() external view returns (address);

        function allocator() external view returns (address);

        function allocatorStorage() external view returns (address);

        function withdraw() external view returns (address);

        function withdrawStorage() external view returns (address);

        function marketFactory() external view returns (address);

        function marketGroup() external view returns (address);

        function propertyFactory() external view returns (address);

        function propertyGroup() external view returns (address);

        function metricsGroup() external view returns (address);

        function metricsFactory() external view returns (address);

        function policy() external view returns (address);

        function policyFactory() external view returns (address);

        function policySet() external view returns (address);

        function policyGroup() external view returns (address);

        function lockup() external view returns (address);

        function lockupStorage() external view returns (address);

        function voteTimes() external view returns (address);

        function voteTimesStorage() external view returns (address);

        function voteCounter() external view returns (address);

        function voteCounterStorage() external view returns (address);

        function setAllocator(address _addr) external;

        function setAllocatorStorage(address _addr) external;

        function setWithdraw(address _addr) external;

        function setWithdrawStorage(address _addr) external;

        function setMarketFactory(address _addr) external;

        function setMarketGroup(address _addr) external;

        function setPropertyFactory(address _addr) external;

        function setPropertyGroup(address _addr) external;

        function setMetricsFactory(address _addr) external;

        function setMetricsGroup(address _addr) external;

        function setPolicyFactory(address _addr) external;

        function setPolicyGroup(address _addr) external;

        function setPolicySet(address _addr) external;

        function setPolicy(address _addr) external;

        function setToken(address _addr) external;

        function setLockup(address _addr) external;

        function setLockupStorage(address _addr) external;

        function setVoteTimes(address _addr) external;

        function setVoteTimesStorage(address _addr) external;

        function setVoteCounter(address _addr) external;

        function setVoteCounterStorage(address _addr) external;
}

// File: contracts/src/common/config/UsingConfig.sol

pragma solidity 0.5.17;


/**
 * Module for using AddressConfig contracts.
 */
contract UsingConfig {
        address private _config;

        /**
         * Initialize the argument as AddressConfig address.
         */
        constructor(address _addressConfig) public {
                _config = _addressConfig;
        }

        /**
         * Returns the latest AddressConfig instance.
         */
        function config() internal view returns (IAddressConfig) {
                return IAddressConfig(_config);
        }

        /**
         * Returns the latest AddressConfig address.
         */
        function configAddress() external view returns (address) {
                return _config;
        }
}

// File: contracts/interface/IAllocator.sol

// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.5.17;

interface IAllocator {
        function beforeBalanceChange(
                address _property,
                address _from,
                address _to
        ) external;

        function calculateMaxRewardsPerBlock() external view returns (uint256);
}

// File: contracts/interface/IWithdraw.sol

// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.5.17;

interface IWithdraw {
        function withdraw(address _property) external;

        function getRewardsAmount(address _property)
                external
                view
                returns (uint256);

        function beforeBalanceChange(
                address _property,
                address _from,
                address _to
        ) external;

        /**
         * caution!!!this function is deprecated!!!
         * use calculateRewardAmount
         */
        function calculateWithdrawableAmount(address _property, address _user)
                external
                view
                returns (uint256);

        function calculateRewardAmount(address _property, address _user)
                external
                view
                returns (
                        uint256 _amount,
                        uint256 _price,
                        uint256 _cap,
                        uint256 _allReward
                );

        function devMinter() external view returns (address);
}

// File: contracts/interface/IPolicy.sol

// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.5.17;

interface IPolicy {
        function rewards(uint256 _lockups, uint256 _assets)
                external
                view
                returns (uint256);

        function holdersShare(uint256 _amount, uint256 _lockups)
                external
                view
                returns (uint256);

        function authenticationFee(uint256 _assets, uint256 _propertyAssets)
                external
                view
                returns (uint256);

        function marketVotingBlocks() external view returns (uint256);

        function policyVotingBlocks() external view returns (uint256);

        function shareOfTreasury(uint256 _supply) external view returns (uint256);

        function treasury() external view returns (address);

        function capSetter() external view returns (address);
}

// File: contracts/interface/ILockup.sol

// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.5.17;

interface ILockup {
        function lockup(
                address _from,
                address _property,
                uint256 _value
        ) external;

        function update() external;

        function withdraw(address _property, uint256 _amount) external;

        function calculateCumulativeRewardPrices()
                external
                view
                returns (
                        uint256 _reward,
                        uint256 _holders,
                        uint256 _interest,
                        uint256 _holdersCap
                );

        function calculateRewardAmount(address _property)
                external
                view
                returns (uint256, uint256);

        /**
         * caution!!!this function is deprecated!!!
         * use calculateRewardAmount
         */
        function calculateCumulativeHoldersRewardAmount(address _property)
                external
                view
                returns (uint256);

        function getPropertyValue(address _property)
                external
                view
                returns (uint256);

        function getAllValue() external view returns (uint256);

        function getValue(address _property, address _sender)
                external
                view
                returns (uint256);

        function calculateWithdrawableInterestAmount(
                address _property,
                address _user
        ) external view returns (uint256);

        function cap() external view returns (uint256);

        function updateCap(uint256 _cap) external;

        function devMinter() external view returns (address);
}

// File: contracts/interface/IPropertyGroup.sol

// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.5.17;

interface IPropertyGroup {
        function addGroup(address _addr) external;

        function isGroup(address _addr) external view returns (bool);
}

// File: contracts/interface/IMetricsGroup.sol

// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.5.17;

interface IMetricsGroup {
        function addGroup(address _addr) external;

        function removeGroup(address _addr) external;

        function isGroup(address _addr) external view returns (bool);

        function totalIssuedMetrics() external view returns (uint256);

        function hasAssets(address _property) external view returns (bool);

        function getMetricsCountPerProperty(address _property)
                external
                view
                returns (uint256);

        function totalAuthenticatedProperties() external view returns (uint256);
}

// File: contracts/src/allocator/Allocator.sol

pragma solidity 0.5.17;








/**
 * A contract that determines the total number of mint.
 * Lockup contract and Withdraw contract mint new DEV tokens based on the total number of new mint determined by this contract.
 */
contract Allocator is UsingConfig, IAllocator {
        /**
         * @dev Initialize the passed address as AddressConfig address.
         * @param _config AddressConfig address.
         */
        constructor(address _config) public UsingConfig(_config) {}

        /**
         * @dev Returns the maximum number of mints per block.
         * @return Maximum number of mints per block.
         */
        function calculateMaxRewardsPerBlock() external view returns (uint256) {
                uint256 totalAssets = IMetricsGroup(config().metricsGroup())
                        .totalIssuedMetrics();
                uint256 totalLockedUps = ILockup(config().lockup()).getAllValue();
                return IPolicy(config().policy()).rewards(totalLockedUps, totalAssets);
        }

        /**
         * @dev Passthrough to `Withdraw.beforeBalanceChange` funtion.
         * @param _property Address of the Property address to transfer.
         * @param _from Address of the sender.
         * @param _to Address of the recipient.
         */
        function beforeBalanceChange(
                address _property,
                address _from,
                address _to
        ) external {
                require(
                        IPropertyGroup(config().propertyGroup()).isGroup(msg.sender),
                        "this is illegal address"
                );

                IWithdraw(config().withdraw()).beforeBalanceChange(
                        _property,
                        _from,
                        _to
                );
        }
}