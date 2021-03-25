/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

// Verified by Darwinia Network

// hevm: flattened sources of src/Formula.sol
pragma solidity >=0.4.23 >=0.4.24 <0.7.0 >=0.6.7 <0.7.0;

////// lib/ds-auth/src/auth.sol
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

/* pragma solidity >=0.4.23; */

interface DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) external view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "ds-auth-unauthorized");
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
}

////// lib/zeppelin-solidity/src/proxy/Initializable.sol
// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
/* pragma solidity >=0.4.24 <0.7.0; */


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

////// src/FurnaceSettingIds.sol
/* pragma solidity ^0.6.7; */

contract FurnaceSettingIds {
	uint256 public constant PREFER_GOLD = 1 << 1;
	uint256 public constant PREFER_WOOD = 1 << 2;
	uint256 public constant PREFER_WATER = 1 << 3;
	uint256 public constant PREFER_FIRE = 1 << 4;
	uint256 public constant PREFER_SOIL = 1 << 5;

	uint8 public constant DRILL_OBJECT_CLASS = 4; // Drill
	uint8 public constant ITEM_OBJECT_CLASS = 5; // Item
	uint8 public constant DARWINIA_OBJECT_CLASS = 254; // Darwinia

	//0x4655524e4143455f415050000000000000000000000000000000000000000000
	bytes32 public constant FURNACE_APP = "FURNACE_APP";

	//0x4655524e4143455f4954454d5f4d494e455f4645450000000000000000000000
	bytes32 public constant FURNACE_ITEM_MINE_FEE = "FURNACE_ITEM_MINE_FEE";

	uint128 public constant RATE_PRECISION = 10**8;

	// 0x434f4e54524143545f494e5445525354454c4c41525f454e434f444552000000
	bytes32 public constant CONTRACT_INTERSTELLAR_ENCODER =
		"CONTRACT_INTERSTELLAR_ENCODER";

	// 0x434f4e54524143545f4c414e445f4954454d5f42415200000000000000000000
	bytes32 public constant CONTRACT_LAND_ITEM_BAR = "CONTRACT_LAND_ITEM_BAR";

	// 0x434f4e54524143545f41504f53544c455f4954454d5f42415200000000000000
	bytes32 public constant CONTRACT_APOSTLE_ITEM_BAR =
		"CONTRACT_APOSTLE_ITEM_BAR";

	// 0x434f4e54524143545f4954454d5f424153450000000000000000000000000000
	bytes32 public constant CONTRACT_ITEM_BASE = "CONTRACT_ITEM_BASE";

	// 0x434f4e54524143545f4452494c4c5f4241534500000000000000000000000000
	bytes32 public constant CONTRACT_DRILL_BASE = "CONTRACT_DRILL_BASE";

	// 0x434f4e54524143545f44415257494e49415f49544f5f42415345000000000000
	bytes32 public constant CONTRACT_DARWINIA_ITO_BASE = "CONTRACT_DARWINIA_ITO_BASE";

	// 0x434f4e54524143545f4c414e445f424153450000000000000000000000000000
	bytes32 public constant CONTRACT_LAND_BASE = "CONTRACT_LAND_BASE";

	// 0x434f4e54524143545f4f424a4543545f4f574e45525348495000000000000000
	bytes32 public constant CONTRACT_OBJECT_OWNERSHIP =
		"CONTRACT_OBJECT_OWNERSHIP";

	// 0x434f4e54524143545f4552433732315f4745474f000000000000000000000000
	bytes32 public constant CONTRACT_ERC721_GEGO = "CONTRACT_ERC721_GEGO";

	// 0x434f4e54524143545f464f524d554c4100000000000000000000000000000000
	bytes32 public constant CONTRACT_FORMULA = "CONTRACT_FORMULA";

	// 0x434f4e54524143545f4d455441444154415f54454c4c45520000000000000000
	bytes32 public constant CONTRACT_METADATA_TELLER =
		"CONTRACT_METADATA_TELLER";

	//0x434f4e54524143545f4c505f454c454d454e545f544f4b454e00000000000000
	bytes32 public constant CONTRACT_LP_ELEMENT_TOKEN = 
		"CONTRACT_LP_ELEMENT_TOKEN";

	// 0x434f4e54524143545f4c505f474f4c445f45524332305f544f4b454e00000000
	bytes32 public constant CONTRACT_LP_GOLD_ERC20_TOKEN =
		"CONTRACT_LP_GOLD_ERC20_TOKEN";

	// 0x434f4e54524143545f4c505f574f4f445f45524332305f544f4b454e00000000
	bytes32 public constant CONTRACT_LP_WOOD_ERC20_TOKEN =
		"CONTRACT_LP_WOOD_ERC20_TOKEN";

	// 0x434f4e54524143545f4c505f57415445525f45524332305f544f4b454e000000
	bytes32 public constant CONTRACT_LP_WATER_ERC20_TOKEN =
		"CONTRACT_LP_WATER_ERC20_TOKEN";

	// 0x434f4e54524143545f4c505f464952455f45524332305f544f4b454e00000000
	bytes32 public constant CONTRACT_LP_FIRE_ERC20_TOKEN =
		"CONTRACT_LP_FIRE_ERC20_TOKEN";

	// 0x434f4e54524143545f4c505f534f494c5f45524332305f544f4b454e00000000
	bytes32 public constant CONTRACT_LP_SOIL_ERC20_TOKEN =
		"CONTRACT_LP_SOIL_ERC20_TOKEN";

	// 0x434f4e54524143545f52494e475f45524332305f544f4b454e00000000000000
	bytes32 public constant CONTRACT_RING_ERC20_TOKEN =
		"CONTRACT_RING_ERC20_TOKEN";

	// 0x434f4e54524143545f4b544f4e5f45524332305f544f4b454e00000000000000
	bytes32 public constant CONTRACT_KTON_ERC20_TOKEN =
		"CONTRACT_KTON_ERC20_TOKEN";

	//0x434f4e54524143545f454c454d454e545f544f4b454e00000000000000000000
	bytes32 public constant CONTRACT_ELEMENT_TOKEN = 
		"CONTRACT_ELEMENT_TOKEN";

	// 0x434f4e54524143545f474f4c445f45524332305f544f4b454e00000000000000
	bytes32 public constant CONTRACT_GOLD_ERC20_TOKEN =
		"CONTRACT_GOLD_ERC20_TOKEN";

	// 0x434f4e54524143545f574f4f445f45524332305f544f4b454e00000000000000
	bytes32 public constant CONTRACT_WOOD_ERC20_TOKEN =
		"CONTRACT_WOOD_ERC20_TOKEN";

	// 0x434f4e54524143545f57415445525f45524332305f544f4b454e000000000000
	bytes32 public constant CONTRACT_WATER_ERC20_TOKEN =
		"CONTRACT_WATER_ERC20_TOKEN";

	// 0x434f4e54524143545f464952455f45524332305f544f4b454e00000000000000
	bytes32 public constant CONTRACT_FIRE_ERC20_TOKEN =
		"CONTRACT_FIRE_ERC20_TOKEN";

	// 0x434f4e54524143545f534f494c5f45524332305f544f4b454e00000000000000
	bytes32 public constant CONTRACT_SOIL_ERC20_TOKEN =
		"CONTRACT_SOIL_ERC20_TOKEN";
}

////// src/interfaces/IFormula.sol
/* pragma solidity ^0.6.7; */

/**
@title IFormula
@author [email protected]
*/
interface IFormula {
	struct FormulaEntry {
		// item name
		bytes32 name;
		// strength rate
		uint128 rate;
		// extension of `ObjectClass`
		uint16 objClassExt;
		uint16 class;
		uint16 grade;
		bool canDisenchant;
		// if it is removed
		// uint256 enchantTime;
		// uint256 disenchantTime;
		// uint256 loseRate;

		bool disable;

		// minor material info
		bytes32 minor;
		uint256 amount;
		// major material info
		// [address token, uint16 objectClassExt, uint16 class, uint16 grade]
		address majorAddr;
		uint16 majorObjClassExt;
		uint16 majorClass;
		uint16 majorGrade;
	}

	event AddFormula(
		uint256 indexed index,
		bytes32 name,
		uint128 rate,
		uint16 objClassExt,
		uint16 class,
		uint16 grade,
		bool canDisenchant,
		bytes32 minor,
		uint256 amount,
		address majorAddr,
		uint16 majorObjClassExt,
		uint16 majorClass,
		uint16 majorGrade
	);
	event DisableFormula(uint256 indexed index);
	event EnableFormula(uint256 indexed index);

	/**
        @notice Only governance can add `formula`.
        @dev Add a formula rule.
        MUST revert if length of `_majors` is not the same as length of `_class`.
        MUST revert if length of `_minors` is not the same as length of `_mins` and `_maxs.
        MUST revert on any other error.        
        @param _name         New enchanted NFT name.
        @param _rate         New enchanted NFT rate.
        @param _objClassExt  New enchanted NFT objectClassExt.
        @param _class        New enchanted NFT class.
        @param _grade        New enchanted NFT grade.
        @param _minor        FT Token address of minor meterail for enchanting.
        @param _amount       FT Token amount of minor meterail for enchanting.
        @param _majorAddr    FT token address of major meterail for enchanting.
        @param _majorObjClassExt   FT token objectClassExt of major meterail for enchanting.
        @param _majorClass   FT token class of major meterail for enchanting.
        @param _majorGrade   FT token grade of major meterail for enchanting.
    */
	function insert(
		bytes32 _name,
		uint128 _rate,
		uint16 _objClassExt,
		uint16 _class,
		uint16 _grade,
		bool _canDisenchant,
		bytes32 _minor,
		uint256 _amount,
		address _majorAddr,
		uint16 _majorObjClassExt,
		uint16 _majorClass,
		uint16 _majorGrade
	) external;

	/**
        @notice Only governance can enable `formula`.
        @dev Enable a formula rule.
        MUST revert on any other error.        
        @param _index  index of formula.
    */
	function disable(uint256 _index) external;

	/**
        @notice Only governance can disble `formula`.
        @dev Disble a formula rule.
        MUST revert on any other error.        
        @param _index  index of formula.
    */
	function enable(uint256 _index) external;

	/**
        @dev Returns the length of the formula.
	         0x1f7b6d32
     */
	function length() external view returns (uint256);

	/**
        @dev Returns the availability of the formula.
     */
	function isDisable(uint256 _index) external view returns (bool);

	/**
        @dev returns the minor material of the formula.
     */
	function getMinor(uint256 _index)
		external
		view
		returns (bytes32, uint256);

	/**
        @dev Decode major info of the major.
	         0x6ef2fd27
		@return {
			"token": "Major token address.",
			"objClassExt": "Major token objClassExt.",
			"class": "Major token class.",
			"grade": "Major token address."
		}
     */
	function getMajorInfo(uint256 _index)
		external
		view	
		returns (
			address,
			uint16,
			uint16,
			uint16
		);

	/**
        @dev Returns meta info of the item.
	         0x78533046
		@return {
			"objClassExt": "Major token objClassExt.",
			"class": "Major token class.",
			"grade": "Major token address.",
			"base":  "Base strength rate.",
			"enhance": "Enhance strength rate.",
		}
     */
	function getMetaInfo(uint256 _index)
		external
		view
		returns (
			uint16,
			uint16,
			uint16,
			uint128
		);

	/**
        @dev returns canDisenchant of the formula.
     */
	function canDisenchant(uint256 _index) external view returns (bool);
}

////// src/interfaces/ISettingsRegistry.sol
/* pragma solidity ^0.6.7; */

interface ISettingsRegistry {
    function uintOf(bytes32 _propertyName) external view returns (uint256);

    function stringOf(bytes32 _propertyName) external view returns (string memory);

    function addressOf(bytes32 _propertyName) external view returns (address);

    function bytesOf(bytes32 _propertyName) external view returns (bytes memory);

    function boolOf(bytes32 _propertyName) external view returns (bool);

    function intOf(bytes32 _propertyName) external view returns (int);

    function setUintProperty(bytes32 _propertyName, uint _value) external;

    function setStringProperty(bytes32 _propertyName, string calldata _value) external;

    function setAddressProperty(bytes32 _propertyName, address _value) external;

    function setBytesProperty(bytes32 _propertyName, bytes calldata _value) external;

    function setBoolProperty(bytes32 _propertyName, bool _value) external;

    function setIntProperty(bytes32 _propertyName, int _value) external;

    function getValueTypeOf(bytes32 _propertyName) external view returns (uint /* SettingsValueTypes */ );

    event ChangeProperty(bytes32 indexed _propertyName, uint256 _type);
}

////// src/Formula.sol
/* pragma solidity ^0.6.7; */

/* import "zeppelin-solidity/proxy/Initializable.sol"; */
/* import "ds-auth/auth.sol"; */
/* import "./interfaces/IFormula.sol"; */
/* import "./interfaces/ISettingsRegistry.sol"; */
/* import "./FurnaceSettingIds.sol"; */

contract Formula is Initializable, DSAuth, IFormula {
	event SetStrength(uint256 indexed inde, uint128 rate);

	event SetAmount(uint256 indexed index, uint256 amount);

	// 0x434f4e54524143545f4552433732315f4745474f000000000000000000000000
	bytes32 public constant CONTRACT_ERC721_GEGO = "CONTRACT_ERC721_GEGO";

	// 0x434f4e54524143545f4f424a4543545f4f574e45525348495000000000000000
	bytes32 public constant CONTRACT_OBJECT_OWNERSHIP =
		"CONTRACT_OBJECT_OWNERSHIP";

	//0x434f4e54524143545f454c454d454e545f544f4b454e00000000000000000000
	bytes32 public constant CONTRACT_ELEMENT_TOKEN = 
		"CONTRACT_ELEMENT_TOKEN";

	//0x434f4e54524143545f4c505f454c454d454e545f544f4b454e00000000000000
	bytes32 public constant CONTRACT_LP_ELEMENT_TOKEN = 
		"CONTRACT_LP_ELEMENT_TOKEN";

	uint128 public constant RATE_DECIMALS = 10 ** 6;
	uint256 public constant UNIT = 10 ** 18;

	/*** STORAGE ***/

	ISettingsRegistry public registry;
	FormulaEntry[] public formulas;

	function initialize(address _registry) public initializer {
		owner = msg.sender;
		emit LogSetOwner(msg.sender);
		registry = ISettingsRegistry(_registry);

		_init();
	}

	function _init() internal {
		address gego = registry.addressOf(CONTRACT_ERC721_GEGO); 
		address ownership = registry.addressOf(CONTRACT_OBJECT_OWNERSHIP);
		// 0
		insert("合金镐", uint128(5 * RATE_DECIMALS), uint16(256), uint16(1), uint16(1), true, CONTRACT_ELEMENT_TOKEN, 500 * UNIT, gego, 256, 0, 1);

		// 1
		insert("人力铸铁钻机", uint128(5 * RATE_DECIMALS), uint16(4), uint16(1), uint16(1), true, CONTRACT_ELEMENT_TOKEN, 500 * UNIT, ownership, 4, 0, 1);

		// 2
		insert("人力镍钢钻机", uint128(12 * RATE_DECIMALS), uint16(4), uint16(1), uint16(2), true, CONTRACT_ELEMENT_TOKEN, 500 * UNIT, ownership, 4, 0, 2);

		// 3
		insert("人力金刚钻机", uint128(25 * RATE_DECIMALS), uint16(4), uint16(1), uint16(3), true, CONTRACT_ELEMENT_TOKEN, 500 * UNIT, ownership, 4, 0, 3);

		// 4
		insert("高级合金镐", uint128(28 * RATE_DECIMALS), uint16(256), uint16(2), uint16(1), true, CONTRACT_LP_ELEMENT_TOKEN, 450 * UNIT, ownership, 256, 1, 1);

		// 5
		insert("燃油铸铁钻机", uint128(28 * RATE_DECIMALS), uint16(4), uint16(2), uint16(1), true, CONTRACT_LP_ELEMENT_TOKEN, 450 * UNIT, ownership, 4, 1, 1);

		// 6
		insert("燃油钨钢钻机", uint128(68 * RATE_DECIMALS), uint16(4), uint16(2), uint16(2), true, CONTRACT_LP_ELEMENT_TOKEN, 450 * UNIT, ownership, 4, 1, 2);

		// 7
		insert("燃油金刚钻机", uint128(120 * RATE_DECIMALS), uint16(4), uint16(2), uint16(3), true, CONTRACT_LP_ELEMENT_TOKEN, 450 * UNIT, ownership, 4, 1, 3);
	}

	function insert(
		bytes32 _name,
		uint128 _rate,
		uint16 _objClassExt,
		uint16 _class,
		uint16 _grade,
		bool _canDisenchant,
		bytes32 _minor,
		uint256 _amount,
		address _majorAddr,
		uint16 _majorObjClassExt,
		uint16 _majorClass,
		uint16 _majorGrade
	) public override auth {
		FormulaEntry memory formula =
			FormulaEntry({
				name: _name,
				rate: _rate,
				objClassExt: _objClassExt,
				disable: false,
				class: _class,
				grade: _grade,
				canDisenchant: _canDisenchant,
				minor: _minor,
				amount: _amount,
				majorAddr: _majorAddr,
		        majorObjClassExt: _majorObjClassExt,
		        majorClass: _majorClass,
		        majorGrade:_majorGrade
			});
		formulas.push(formula);
		emit AddFormula(
			formulas.length - 1,
			formula.name,
			formula.rate,
			formula.objClassExt,
			formula.class,
			formula.grade,
			formula.canDisenchant,
			formula.minor,
			formula.amount,
			formula.majorAddr,
			formula.majorObjClassExt,
			formula.majorClass,
			formula.majorGrade
		);
	}

	function disable(uint256 _index) external override auth {
		require(_index < formulas.length, "Formula: OUT_OF_RANGE");
		formulas[_index].disable = true;
		emit DisableFormula(_index);
	}

	function enable(uint256 _index) external override auth {
		require(_index < formulas.length, "Formula: OUT_OF_RANGE");
		formulas[_index].disable = false;
		emit EnableFormula(_index);
	}

	function setStrengthRate(uint256 _index, uint128 _rate) external auth {
		require(_index < formulas.length, "Formula: OUT_OF_RANGE");
		FormulaEntry storage formula = formulas[_index];
		formula.rate = _rate;
		emit SetStrength(_index, formula.rate);
	}

	function setAmount(uint256 _index, uint256 _amount)
		external
		auth
	{
		require(_index < formulas.length, "Formula: OUT_OF_RANGE");
		FormulaEntry storage formula = formulas[_index];
		formula.amount = _amount;
		emit SetAmount(_index, formula.amount);
	}

	function length() external view override returns (uint256) {
		return formulas.length;
	}

	function isDisable(uint256 _index) external view override returns (bool) {
		require(_index < formulas.length, "Formula: OUT_OF_RANGE");
		return formulas[_index].disable;
	}

	function getMinor(uint256 _index)
		external
		view
		override
		returns (bytes32, uint256)
	{
		require(_index < formulas.length, "Formula: OUT_OF_RANGE");
		return (formulas[_index].minor, formulas[_index].amount);
	}

	function canDisenchant(uint256 _index)
		external
		view
		override
		returns (bool)
	{
		require(_index < formulas.length, "Formula: OUT_OF_RANGE");
		return formulas[_index].canDisenchant;
	}

	function getMetaInfo(uint256 _index)
		external
		view
		override
		returns (
			uint16,
			uint16,
			uint16,
			uint128
		)
	{
		require(_index < formulas.length, "Formula: OUT_OF_RANGE");
		FormulaEntry storage formula = formulas[_index];
		return (
			formula.objClassExt,
			formula.class,
			formula.grade,
			formula.rate
		);
	}

	function getMajorInfo(uint256 _index)
		public
		view	
		override
		returns (
			address,
			uint16,
			uint16,
			uint16
		)
	{
		require(_index < formulas.length, "Formula: OUT_OF_RANGE");
		FormulaEntry storage formula = formulas[_index];
		return (
			formula.majorAddr,
			formula.majorObjClassExt,
			formula.majorClass,
			formula.majorGrade
		);
	}
}