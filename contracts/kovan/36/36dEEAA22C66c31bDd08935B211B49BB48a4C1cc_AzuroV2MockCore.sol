// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * Azuro V2 API docs: https://azuro-protocol.notion.site/Chainlink-V2-23b8d3b1cdbc48bd859a3eee0fd18747
 * Azuro V1 API docs: https://azuro-protocol.notion.site/Chainlink-ad014febdd7f438690dd904a15ec614d
 *
 * Azuro V2 Rinkeby Core Proxy contract address: 0x2c68a27c3384d5542450aFcbD3b298Ac64a2338b
 *   - https://rinkeby.etherscan.io/address/0x2c68a27c3384d5542450aFcbD3b298Ac64a2338b#code
 *
 * Azuro V2 Rinkeby Core Implementation contract address: 0x0cBfbff50edB705e8675b2C4f0176F4d54FE2C0D
 *   - https://rinkeby.etherscan.io/address/0x0cBfbff50edB705e8675b2C4f0176F4d54FE2C0D#code
 *
 * Azuro V2 Rinkeby LP Proxy contract address: 0xdD1F799518837A7a9B508E0a94682BBF214e8B76
 *   - https://rinkeby.etherscan.io/address/0xdd1f799518837a7a9b508e0a94682bbf214e8b76#code
 *
 * Azuro V2 Rinkeby LP Implementation contract address: 0xbE73f65B8D4f6c533fFfc2f4718a6caa25EB4aC0
 *   - https://rinkeby.etherscan.io/address/0xbE73f65B8D4f6c533fFfc2f4718a6caa25EB4aC0#code
 *
 * Azuro V1 Rinkeby Proxy contract address: 0x95e2aD6e0BC5bfB8964D144ab049CD8042D88aC2
 *   - https://rinkeby.etherscan.io/address/0x95e2aD6e0BC5bfB8964D144ab049CD8042D88aC2#code
 *
 * Azuro V1 Rinkeby Implementation contract address: 0x9beEE02437900D42468859dc4D7cd558F3d1886d
 *   - https://rinkeby.etherscan.io/address/0x9beee02437900d42468859dc4d7cd558f3d1886d#code
 */
/**
 * @title A testing contract for Azuro
 * @author LinkPool
 * @notice Mocks the methods `cancel`, `createCondition`, `resolveCondition` and `shift` from the implementation
 * contract Core.sol, which allows test the Azuro EA.
 */
contract AzuroV2MockCore {
    /* ========== CONSUMER STATE VARIABLES ========== */

    struct Condition {
        uint256[2] odds;
        uint256[2] outcomes;
        uint256 timestamp;
        bytes32 ipfsHash;
        uint256 result;
        bool isCancelled;
        bool isResolved;
    }
    address public lpAddress;

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
        uint256[2] memory _odds,
        uint256[2] memory _outcomes,
        uint256 _timestamp,
        bytes32 _ipfsHash
    ) external onlyOracle {
        require(createdConditions[_cryptoGameId].timestamp == 0, "Azuro: condition already exists");

        Condition memory condition;
        condition.odds = _odds;
        condition.outcomes = _outcomes;
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

    function setLpAddress(address _lpAddress) external {
        lpAddress = _lpAddress;
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