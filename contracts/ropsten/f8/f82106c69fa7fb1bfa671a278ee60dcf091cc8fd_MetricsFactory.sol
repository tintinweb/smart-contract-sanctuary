/**
 *Submitted for verification at Etherscan.io on 2021-08-30
*/

// File: contracts/interface/IAddressConfig.sol

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

// File: contracts/interface/IMetrics.sol

// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.5.17;

interface IMetrics {
        function market() external view returns (address);

        function property() external view returns (address);
}

// File: contracts/src/metrics/Metrics.sol

pragma solidity 0.5.17;


/**
 * A contract for associating a Property and an asset authenticated by a Market.
 */
contract Metrics is IMetrics {
        address public market;
        address public property;

        constructor(address _market, address _property) public {
                //Do not validate because there is no AddressConfig
                market = _market;
                property = _property;
        }
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

// File: contracts/interface/IMarketGroup.sol

// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.5.17;

interface IMarketGroup {
        function addGroup(address _addr) external;

        function isGroup(address _addr) external view returns (bool);

        function getCount() external view returns (uint256);
}

// File: contracts/interface/IMetricsFactory.sol

// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.5.17;

interface IMetricsFactory {
        function create(address _property) external returns (address);

        function destroy(address _metrics) external;
}

// File: contracts/src/metrics/MetricsFactory.sol

pragma solidity 0.5.17;







/**
 * A factory contract for creating new Metrics contracts and logical deletion of Metrics contracts.
 */
contract MetricsFactory is UsingConfig, IMetricsFactory {
        event Create(address indexed _from, address _metrics);
        event Destroy(address indexed _from, address _metrics);

        /**
         * Initialize the passed address as AddressConfig address.
         */
        constructor(address _config) public UsingConfig(_config) {}

        /**
         * Creates a new Metrics contract.
         */
        function create(address _property) external returns (address) {
                /**
                 * Validates the sender is included in the Market address set.
                 */
                require(
                        IMarketGroup(config().marketGroup()).isGroup(msg.sender),
                        "this is illegal address"
                );

                /**
                 * Creates a new Metrics contract.
                 */
                Metrics metrics = new Metrics(msg.sender, _property);

                /**
                 *  Adds the new Metrics contract to the Metrics address set.
                 */
                IMetricsGroup metricsGroup = IMetricsGroup(config().metricsGroup());
                address metricsAddress = address(metrics);
                metricsGroup.addGroup(metricsAddress);

                emit Create(msg.sender, metricsAddress);
                return metricsAddress;
        }

        /**
         * Logical deletions a Metrics contract.
         */
        function destroy(address _metrics) external {
                /**
                 * Validates the passed address is included in the Metrics address set.
                 */
                IMetricsGroup metricsGroup = IMetricsGroup(config().metricsGroup());
                require(metricsGroup.isGroup(_metrics), "address is not metrics");

                /**
                 * Validates the sender is included in the Market address set.
                 */
                require(
                        IMarketGroup(config().marketGroup()).isGroup(msg.sender),
                        "this is illegal address"
                );

                /**
                 *  Validates the sender is the Market contract associated with the passed Metrics.
                 */
                IMetrics metrics = IMetrics(_metrics);
                require(msg.sender == metrics.market(), "this is illegal address");

                /**
                 * Logical deletions a Metrics contract.
                 */
                IMetricsGroup(config().metricsGroup()).removeGroup(_metrics);
                emit Destroy(msg.sender, _metrics);
        }
}