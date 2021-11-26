// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * Azuro API docs: https://azuro-protocol.notion.site/Chainlink-ad014febdd7f438690dd904a15ec614d
 *
 * Azuro Rinkeby Proxy contract address: 0x95e2aD6e0BC5bfB8964D144ab049CD8042D88aC2
 *   - https://rinkeby.etherscan.io/address/0x95e2aD6e0BC5bfB8964D144ab049CD8042D88aC2#code
 *
 * Azuro Rinkeby Implementation contract address: 0x9beEE02437900D42468859dc4D7cd558F3d1886d
 *   - https://rinkeby.etherscan.io/address/0x9beee02437900d42468859dc4d7cd558f3d1886d#code
 */
/**
 * @title A testing contract for Azuro
 * @author LinkPool
 * @notice Mocks the methods `cancel`, `createCondition`, `resolveCondition` and `shift` from the implementation
 * contract Core.sol, which allows test the Azuro EA.
 */
contract MockCore {
    /* ========== CONSUMER STATE VARIABLES ========== */

    struct Condition {
        uint256 odd1;
        uint256 odd2;
        uint256 timestamp;
        bytes32 ipfsHash;
        uint256 result;
        bool isCancelled;
        bool isResolved;
    }
    // Maps
    mapping(address => bool) public maintainers;
    mapping(address => bool) public oracles;
    mapping(uint256 => Condition) public createdConditions;

    // Modifiers
    modifier onlyOracle() {
        require(oracles[msg.sender], "Core:Only Oracle");
        _;
    }

    modifier onlyMaintainer() {
        require(maintainers[msg.sender], "Core:Only Maintainer");
        _;
    }

    /* ========== MOCKED FUNCTIONS ========== */

    function cancel(uint256 _cryptoGameId) external onlyMaintainer {
        require(createdConditions[_cryptoGameId].timestamp > 0, "Azuro: condition not exists");
        require(createdConditions[_cryptoGameId].isCancelled == false, "Azuro: condition already cancelled");
        createdConditions[_cryptoGameId].isCancelled = true;
    }

    function createCondition(
        uint256 _cryptoGameId,
        uint256 _odd1,
        uint256 _odd2,
        uint256 _timestamp,
        bytes32 _ipfsHash
    ) external onlyOracle {
        require(createdConditions[_cryptoGameId].timestamp == 0, "Azuro: condition already exists");

        Condition memory condition;
        condition.odd1 = _odd1;
        condition.odd2 = _odd2;
        condition.timestamp = _timestamp;
        condition.ipfsHash = _ipfsHash;

        createdConditions[_cryptoGameId] = condition;
    }

    function shift(uint256 _cryptoGameId, uint256 _newTimestamp) external onlyMaintainer {
        require(createdConditions[_cryptoGameId].timestamp > 0, "Azuro: condition not exists");
        createdConditions[_cryptoGameId].timestamp = _newTimestamp;
    }

    function resolveCondition(uint256 _cryptoGameId, uint256 _result) external onlyMaintainer {
        require(createdConditions[_cryptoGameId].timestamp > 0, "Azuro: condition not exists");
        require(createdConditions[_cryptoGameId].isResolved == false, "Azuro: condition already resolved");
        createdConditions[_cryptoGameId].result = _result;
        createdConditions[_cryptoGameId].isResolved = true;
    }

    /* ========== HELPER FUNCTIONS ========== */

    function deleteCreatedCondition(uint256 _cryptoGameId) external onlyMaintainer {
        delete createdConditions[_cryptoGameId];
    }

    function setMaintainer(address _maintainer) external {
        maintainers[_maintainer] = true;
    }

    function renounceMaintainer(address _maintainer) external {
        maintainers[_maintainer] = false;
    }

    function setOracle(address _oracle) external {
        oracles[_oracle] = true;
    }

    function renounceOracle(address _oracle) external {
        oracles[_oracle] = false;
    }
}