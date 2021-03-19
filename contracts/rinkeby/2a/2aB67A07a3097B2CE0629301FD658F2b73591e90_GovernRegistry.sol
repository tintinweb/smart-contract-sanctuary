/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.6.8;

abstract contract ERC165 {
    // Includes supportsInterface method:
    bytes4 internal constant ERC165_INTERFACE_ID = bytes4(0x01ffc9a7);

    /**
    * @dev Query if a contract implements a certain interface
    * @param _interfaceId The interface identifier being queried, as specified in ERC-165
    * @return True if the contract implements the requested interface and if its not 0xffffffff, false otherwise
    */
    function supportsInterface(bytes4 _interfaceId) virtual public view returns (bool) {
        return _interfaceId == ERC165_INTERFACE_ID;
    }
}

/*
 * SPDX-License-Identifier:    GPL-3.0
 */

pragma solidity 0.6.8;

import "erc3k/contracts/IERC3000.sol";
import "erc3k/contracts/IERC3000Executor.sol";
import "erc3k/contracts/IERC3000Registry.sol";

import "@aragon/govern-contract-utils/contracts/erc165/ERC165.sol";

contract GovernRegistry is IERC3000Registry {
    mapping(string => bool) public nameUsed;

    function register(
        IERC3000Executor _executor,
        IERC3000 _queue,
        IERC20 _token,
        string calldata _name,
        bytes calldata _initialMetadata
    ) override external
    {
        require(!nameUsed[_name], "registry: name used");

        nameUsed[_name] = true;

        emit Registered(_executor, _queue, _token, msg.sender, _name);
        //_setMetadata(_executor, _initialMetadata);
    }

    function setMetadata(bytes memory _metadata) override public {
        _setMetadata(IERC3000Executor(msg.sender), _metadata);
    }

    function _setMetadata(IERC3000Executor _executor, bytes memory _metadata) internal {
        emit SetMetadata(_executor, _metadata);
    }
}

/*
 * SPDX-License-Identifier:    GPL-3.0
 */

pragma solidity ^0.6.8;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "./IERC3000Executor.sol";

library ERC3000Data {
    // TODO: come up with a non-shitty name
    struct Container {
        Payload payload;
        Config config;
    }

    // WARN: Always remember to change the 'hash' function if modifying the struct
    struct Payload {
        uint256 nonce;
        uint256 executionTime;
        address submitter;
        IERC3000Executor executor;
        Action[] actions;
        bytes32 allowFailuresMap;
        bytes proof;
    }

    struct Action {
        address to;
        uint256 value;
        bytes data;
    }

    struct Config {
        uint256 executionDelay;
        Collateral scheduleDeposit;
        Collateral challengeDeposit;
        address resolver;
        bytes rules;
    }

    struct Collateral {
        address token;
        uint256 amount;
    }

    function containerHash(bytes32 payloadHash, bytes32 configHash) internal view returns (bytes32) {
        uint chainId;
        assembly {
            chainId := chainid()
        }

        return keccak256(abi.encodePacked("erc3k-v1", address(this), chainId, payloadHash, configHash));
    }

    function hash(Container memory container) internal view returns (bytes32) {
        return containerHash(hash(container.payload), hash(container.config));
    }

    function hash(Payload memory payload) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                payload.nonce,
                payload.executionTime,
                payload.submitter,
                payload.executor,
                keccak256(abi.encode(payload.actions)),
                payload.allowFailuresMap,
                keccak256(payload.proof)
            )
        );
    }

    function hash(Config memory config) internal pure returns (bytes32) {
        return keccak256(abi.encode(config));
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "./ERC3000Data.sol";

abstract contract IERC3000 {
    /**
     * @notice Schedules an action for execution, allowing for challenges and vetos on a defined time window
     * @param container A Container struct holding both the payload being scheduled for execution and
     * the current configuration of the system
     * @return containerHash
     */
    function schedule(ERC3000Data.Container memory container) virtual public returns (bytes32 containerHash);
    event Scheduled(bytes32 indexed containerHash, ERC3000Data.Payload payload);

    /**
     * @notice Executes an action after its execution delay has passed and its state hasn't been altered by a challenge or veto
     * @param container A ERC3000Data.Container struct holding both the payload being scheduled for execution and
     * the current configuration of the system
     * MUST be an ERC3000Executor call: payload.executor.exec(payload.actions)
     * @return failureMap
     * @return execResults
     */
    function execute(ERC3000Data.Container memory container) virtual public returns (bytes32 failureMap, bytes[] memory execResults);
    event Executed(bytes32 indexed containerHash, address indexed actor);

    /**
     * @notice Challenge a container in case its scheduling is illegal as per Config.rules. Pulls collateral and dispute fees from sender into contract
     * @param container A ERC3000Data.Container struct holding both the payload being scheduled for execution and
     * the current configuration of the system
     * @param reason Hint for case reviewers as to why the scheduled container is illegal
     * @return resolverId
     */
    function challenge(ERC3000Data.Container memory container, bytes memory reason) virtual public returns (uint256 resolverId);
    event Challenged(bytes32 indexed containerHash, address indexed actor, bytes reason, uint256 resolverId, ERC3000Data.Collateral collateral);

    /**
     * @notice Apply arbitrator's ruling over a challenge once it has come to a final ruling
     * @param container A ERC3000Data.Container struct holding both the payload being scheduled for execution and
     * the current configuration of the system
     * @param resolverId disputeId in the arbitrator in which the dispute over the container was created
     * @return failureMap
     * @return execResults
     */
    function resolve(ERC3000Data.Container memory container, uint256 resolverId) virtual public returns (bytes32 failureMap, bytes[] memory execResults);
    event Resolved(bytes32 indexed containerHash, address indexed actor, bool approved);

    /**
     * @notice Apply arbitrator's ruling over a challenge once it has come to a final ruling
     * @param container A ERC3000Data.Container struct holding both the payload being scheduled for execution and
     * the current configuration of the system
     * @param reason Justification for the veto
     */
    function veto(ERC3000Data.Container memory container, bytes memory reason) virtual public;
    event Vetoed(bytes32 indexed containerHash, address indexed actor, bytes reason);

    /**
     * @notice Apply a new configuration for all *new* containers to be scheduled
     * @param config A ERC3000Data.Config struct holding all the new params that will control the system
     * @return configHash
     */
    function configure(ERC3000Data.Config memory config) virtual public returns (bytes32 configHash);
    event Configured(bytes32 indexed configHash, address indexed actor, ERC3000Data.Config config);
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "./ERC3000Data.sol";

abstract contract IERC3000Executor {
    bytes4 internal constant ERC3000_EXEC_INTERFACE_ID = this.exec.selector;

    /**
     * @notice Executes all given actions
     * @param actions A array of ERC3000Data.Action for later executing those
     * @param allowFailuresMap A map with the allowed failures
     * @param memo The hash of the ERC3000Data.Container
     * @return failureMap
     * @return execResults
     */
    function exec(ERC3000Data.Action[] memory actions, bytes32 allowFailuresMap, bytes32 memo) virtual public returns (bytes32 failureMap, bytes[] memory execResults);
    event Executed(address indexed actor, ERC3000Data.Action[] actions, bytes32 memo, bytes32 failureMap, bytes[] execResults);
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity 0.6.8;

import "./IERC3000.sol";
import "./IERC3000Executor.sol";

import "@aragon/govern-token/contracts/interfaces/IERC20.sol";

abstract contract IERC3000Registry {
    /**
     * @notice Registers a IERC3000Executor and IERC3000 contract by a name and with his metadata
     * @param executor IERC3000Executor contract
     * @param queue IERC3000 contract
     * @param name The name of this DAO
     * @param token Governance token of the DAO
     * @param initialMetadata Additional data to store for this DAO
     */
    function register(IERC3000Executor executor, IERC3000 queue, IERC20 token, string calldata name, bytes calldata initialMetadata) virtual external;
    event Registered(IERC3000Executor indexed executor, IERC3000 queue, IERC20 indexed token, address indexed registrant, string name);

    /**
     * @notice Sets or updates the metadata of a DAO
     * @param metadata Additional data to store for this DAO
     */
    function setMetadata(bytes memory metadata) virtual public;
    event SetMetadata(IERC3000Executor indexed executor, bytes metadata);
}