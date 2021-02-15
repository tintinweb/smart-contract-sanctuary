// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;
import "./modules/Configable.sol";

interface IONXPool {
	function init(address supplyToken, address collateralToken) external;

	function setupConfig(address config) external;
}

contract ONXFactory is Configable {
	event PoolCreated(address indexed lendToken, address indexed collateralToken, address indexed pool);
	address[] public allPools;
	mapping(address => bool) public isPool;
	mapping(address => mapping(address => address)) public getPool;

	function initialize() public initializer {
		Configable.__config_initialize();
	}

	function createPool(address pool, address _lendToken, address _collateralToken) external onlyOwner {
		require(getPool[_lendToken][_collateralToken] == address(0), "ALREADY CREATED");
		getPool[_lendToken][_collateralToken] = pool;
		allPools.push(pool);
		isPool[pool] = true;
		IConfig(config).initPoolParams(pool);
		IONXPool(pool).setupConfig(config);
		IONXPool(pool).init(_lendToken, _collateralToken);
		emit PoolCreated(_lendToken, _collateralToken, pool);
	}

	function countPools() external view returns (uint256) {
		return allPools.length;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

interface IConfig {
		function owner() external view returns (address);
    function platform() external view returns (address);
    function factory() external view returns (address);
    function mint() external view returns (address);
    function token() external view returns (address);
    function developPercent() external view returns (uint);
    function share() external view returns (address);
    function base() external view returns (address); 
    function governor() external view returns (address);
    function getPoolValue(address pool, bytes32 key) external view returns (uint);
    function getValue(bytes32 key) external view returns(uint);
    function getParams(bytes32 key) external view returns(uint, uint, uint); 
    function getPoolParams(address pool, bytes32 key) external view returns(uint, uint, uint); 
    function wallets(bytes32 key) external view returns(address);
    function setValue(bytes32 key, uint value) external;
    function setPoolValue(address pool, bytes32 key, uint value) external;
    function initPoolParams(address _pool) external;
    function isMintToken(address _token) external returns (bool);
    function prices(address _token) external returns (uint);
    function convertTokenAmount(address _fromToken, address _toToken, uint _fromAmount) external view returns (uint);
    function DAY() external view returns (uint);
    function WETH() external view returns (address);
}

contract Configable is Initializable {
	address public config;
	address public owner;
	event OwnerChanged(address indexed _oldOwner, address indexed _newOwner);

	function __config_initialize() internal initializer {
		owner = msg.sender;
	}

	function setupConfig(address _config) external onlyOwner {
		config = _config;
		owner = IConfig(config).owner();
	}

	modifier onlyOwner() {
		require(msg.sender == owner, "OWNER FORBIDDEN");
		_;
	}

	modifier onlyPlatform() {
		require(msg.sender == IConfig(config).platform(), "PLATFORM FORBIDDEN");
		_;
	}

	modifier onlyFactory() {
			require(msg.sender == IConfig(config).factory(), 'FACTORY FORBIDDEN');
			_;
	}
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 * 
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}