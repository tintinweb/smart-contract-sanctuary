// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./maps/CryptopiaMap/ICryptopiaMap.sol";
import "./tokens/ERC777/ICryptopiaERC777.sol";

/// @title Cryptopia
/// @dev Entry point
/// @author Frank Bonnet - <[email protected]>
contract Cryptopia {

    // Ensure identical addresses across networks
    address constant PUBLISHER = 0x6C159E2aF7341e701c9538B5a87b01c3fEe0ea06;

    /**
     * Storage
     */
    // Accounts
    address public accountRegisterContract;
    
    // Map
    address public mapContract;
    address public titleDeedContract;

    // Assets
    address public assetRegisterContract;

    // Cryptos token
    address public tokenContract;

    // Self
    address[] private _operators;

    /// @dev Enforce expected publisher
    constructor()
    {
        require(address(msg.sender) == PUBLISHER, "Unexpected publisher");
    }

    /*
     * Public functions
     */
    /// @dev Publishes the account register contract.
    function publishAccountRegisterContract(bytes memory bytecode)
        public 
    {
        require(accountRegisterContract == address(0), "Account register contract already exists");
    
        // Publish using create2
        accountRegisterContract = Create2.deploy(
            0, "CryptopiaAccountRegister", bytecode);
    }

    /// @dev Publishes the asset register contract.
    function publishAssetRegisterContract(bytes memory bytecode)
        public 
    {
        require(assetRegisterContract == address(0), "Asset register contract already exists");
    
        // Publish using create2
        assetRegisterContract = Create2.deploy(
            0, "CryptopiaAssetRegister", bytecode);

        /// TODO: Add all assets and hand over control to map
    }

    /// @dev Publishes the title deed contract.
    function publishTitleDeedContract(bytes memory bytecode)
        public 
    {
        require(titleDeedContract == address(0), "Title deed contract already exists");
    
        // Publish using create2
        titleDeedContract = Create2.deploy(
            0, "CryptopiaTitleDeed", bytecode);
    }

    /// @dev Publishes the Cryptos token.
    function publishTokenContract(bytes memory bytecode)
        public
    {
        require(tokenContract == address(0), "Token contract already exists");
    
        // Publish using create2
        tokenContract = Create2.deploy(
            0, "CryptopiaToken", bytecode);

        ICryptopiaERC777(tokenContract).initialize(
            "CRYPTOS", "CRYPS", _getOperators());
    }

    /// @dev Publishes the map contract.
    function publishMapContract(bytes memory bytecode)
        public 
    {
        require(mapContract == address(0), "Map contract already exists");
        require(accountRegisterContract != address(0), "Call publishAccountRegisterContract() first");
        require(assetRegisterContract != address(0), "Call publishAssetRegisterContract() first");
        require(titleDeedContract != address(0), "Call publishTitleDeedContract() first");
        require(tokenContract != address(0), "Call publishTokenContract() first");
    
        // Publish CryptopiaMap
        mapContract = Create2.deploy(
            0, "CryptopiaMap", bytecode);

        ICryptopiaMap(mapContract).initialize(
            mapContract, assetRegisterContract, titleDeedContract, tokenContract);

        // Add map contract as only minter/burner (roles)
        // CryptopiaToken(tokenContract).authorizeOperator(mapContract);
    }

    /// @dev Retrieve operators and ensure this contract is added
    /// @return _operators
    function _getOperators() 
        internal  
        returns (address[] memory) 
    {
        if (0 == _operators.length)
        {
            _operators.push(address(this));
            _operators.push(address(msg.sender)); // TODO: Remove
        }

        return _operators;
    }
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0 <0.9.0;


/// @title Cryptopia ERC777 
/// @notice Token that extends Openzeppelin ERC777
/// @dev Implements the ERC777 standard
/// @author Frank Bonnet - <[email protected]>
interface ICryptopiaERC777 {

    /// @dev Initialize
    /// @param name Token name
    /// @param symbol Token symbol
    /// @param defaultOperators These accounts are operators for all token holders, even if authorizeOperator was never called on them.
    function initialize(string memory name, string memory symbol, address[] memory defaultOperators) 
        external;
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0 <0.9.0;

/// @title Cryptopia Maps
/// @dev Responsible for world data and player movement
/// @author Frank Bonnet - <[email protected]>
interface ICryptopiaMap {

    /*
     * Public functions
     */
    /// @param _accountRegisterContract Contract responsible for accounts.
    /// @param _assetRegisterContract Contract responsible for assets.
    /// @param _titleDeedContract Contract responsible for land ownership.
    /// @param _tokenContract Cryptos token.
    function initialize(
        address _accountRegisterContract, 
        address _assetRegisterContract,
        address _titleDeedContract, 
        address _tokenContract) 
        external;

    /// @dev Retreives the amount of maps created.
    /// @return count Number of maps created.
    function getMapCount() 
        external view 
        returns (uint256 count);

    /// @dev Retreives the map at `index`.
    /// @param index Map index (not mapping key).
    /// @return initialized True if the map is created.
    /// @return finalized True if all tiles are added and the map is immutable.
    /// @return sizeX Number of tiles in the x direction.
    /// @return sizeZ Number of tiles in the z direction.
    /// @return tileStartIndex The index of the first tile in the map (mapping key).
    /// @return name Unique name of the map
    function getMapAt(uint256 index) 
        external view 
        returns (
            bool initialized, 
            bool finalized, 
            uint8 sizeX, 
            uint8 sizeZ, 
            uint32 tileStartIndex,
            bytes32 name
        );

    /// @dev Create a new map. The map will be 'under construction' until all (`sizeX` * `sizeZ`) tiles have been set 
    /// and `finalizeMap()` is called. While a map is under construction no other map can be created.
    /// @param name Map name.
    /// @param sizeX Amount of tiles in a row.
    /// @param sizeZ Amount of tiles in a column.
    function createMap(bytes32 name, uint8 sizeX, uint8 sizeZ)
        external;

    /// @dev Finalizes the state of the last created map. Throws if no map is under construction. 
    function finalizeMap() 
        external;

    /// @dev Populate (or override) the tile at `index` with `values`. The `index` is used to determin 
    /// the map to which the tile belongs as well as it's cooridinates within that map.
    /// @param index Index of the tile.
    /// @param values Tile values.
    function setTile(uint32 index, uint8[12] memory values) 
        external;

    /// @dev Batch operation for `setTile(uint32, uint8[12])`
    /// @param indices Indices of the tiles.
    /// @param values Tile values.
    function setTiles(uint32[] memory indices, uint8[12][] memory values) 
        external;

    /// @dev Returns the number of players that is currently on the map named `mapName`
    /// @return count Number of players in map
    function getPlayerCount(bytes32 mapName) 
        external view 
        returns (uint256 count);

    /// @dev Retreives the player in the map `mapName` at `index`
    /// @return player The address of the player's CryptopiaAccount contract
    /// @return tileIndex The (global) index of the tile that the player is located at
    function getPlayerAt(bytes32 mapName, uint256 index) 
        external view 
        returns (address player, uint32 tileIndex);

    /// @dev Player entry point that adds the player to the Genesis map
    function playerEnter()
        external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}