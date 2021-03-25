/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

// Verified by Darwinia Network

// hevm: flattened sources of src/ItemBase.sol
pragma solidity >0.4.13 >=0.4.23 >=0.4.24 <0.7.0 >=0.6.7 <0.7.0;

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

////// lib/ds-math/src/math.sol
/// math.sol -- mixin for inline numerical wizardry

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

/* pragma solidity >0.4.13; */

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    //rounds to zero if x*y < WAD / 2
    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    //rounds to zero if x*y < WAD / 2
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    //rounds to zero if x*y < WAD / 2
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    //rounds to zero if x*y < RAY / 2
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

////// lib/ds-stop/lib/ds-note/src/note.sol
/// note.sol -- the `note' modifier, for logging calls as events

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

contract DSNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  guy,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
        uint256           wad,
        bytes             fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;
        uint256 wad;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
            wad := callvalue()
        }

        _;

        emit LogNote(msg.sig, msg.sender, foo, bar, wad, msg.data);
    }
}

////// lib/ds-stop/src/stop.sol
/// stop.sol -- mixin for enable/disable functionality

// Copyright (C) 2017  DappHub, LLC

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

/* import "ds-auth/auth.sol"; */
/* import "ds-note/note.sol"; */

contract DSStop is DSNote, DSAuth {
    bool public stopped;

    modifier stoppable {
        require(!stopped, "ds-stop-is-stopped");
        _;
    }
    function stop() public auth note {
        stopped = true;
    }
    function start() public auth note {
        stopped = false;
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

////// src/interfaces/IELIP002.sol
/* pragma solidity ^0.6.7; */

/**
@title IELIP002
@dev See https://github.com/evolutionlandorg/furnace/blob/main/elip-002.md
@author [email protected]
*/
interface IELIP002 {
	struct Item {
		// index of `Formula`
		uint256 index;
		//  strength rate
		uint128 rate;
		uint16 objClassExt;
		uint16 class;
		uint16 grade;
		// element prefer
		uint16 prefer;
		//  major material
		address major;
		uint256 id;
		// amount of minor material
		address minor;
		uint256 amount;
	}

	/**
        @dev `Enchanted` MUST emit when item is enchanted.
        The `user` argument MUST be the address of an account/contract that is approved to make the enchant (SHOULD be msg.sender).
        The `tokenId` argument MUST be token Id of the item which it is enchanted.
        The `index` argument MUST be index of the `Formula`.
        The `rate` argument MUST be rate of minor material.
        The `objClassExt` argument MUST be extension of `ObjectClass`.
        The `class` argument MUST be class of the item.
        The `grade` argument MUST be grade of the item.
        The `prefer` argument MUST be prefer of the item.
        The `major` argument MUST be token address of major material.
        The `id` argument MUST be token id of major material.
        The `minor` argument MUST be token address of minor material.
        The `amount` argument MUST be token amount of minor material.
        The `now` argument MUST be timestamp of enchant.
    */
	event Enchanced(
		address indexed user,
		uint256 indexed tokenId,
		uint256 index,
		uint128 rate,
		uint16 objClassExt,
		uint16 class,
		uint16 grade,
		uint16 prefer,
		address major,
		uint256 id,
		address minor,
		uint256 amount,
		uint256 now
	);

	/**
        @dev `Disenchanted` MUST emit when item is disenchanted.
        The `user` argument MUST be the address of an account/contract that is approved to make the disenchanted (SHOULD be msg.sender).
        The `tokenId` argument MUST be token Id of the item which it is disenchated.
        The `majors` argument MUST be major token addresses of major material.
        The `id` argument MUST be token ids of major material.
        The `minor` argument MUST be token addresses of minor material.
        The `amount` argument MUST be token amounts of minor material.
    */
	event Disenchanted(
		address indexed user,
		uint256 tokenId,
		address major,
		uint256 id,
		address minor,
		uint256 amount
	);

	/**
        @notice Caller must be owner of tokens to enchant.
        @dev Enchant function, Enchant a new NFT token from ERC721 tokens and ERC20 tokens. Enchant rule is according to `Formula`.
        MUST revert if `_index` is not in `formula`.
        MUST revert on any other error.        
		@param _index  Index of formula to enchant.
        @param _id     ID of NFT tokens.
        @param _token  Address of FT token.
		@return {
			"tokenId": "New Token ID of Enchanting."
		}
    */
	function enchant(
		uint256 _index,
		uint256 _id,
		address _token
	) external returns (uint256);

	// {
	// 	### smelt
	// 	1. check Formula rule by index
	//  2. transfer FT and NFT to address(this)
	// 	3. track FTs NFT to new NFT
	// 	4. mint new NFT to caller
	// }

	/**
        @notice Caller must be owner of token id to disenchat.
        @dev Disenchant function, A enchanted NFT can be disenchanted into origin ERC721 tokens and ERC20 tokens recursively.
        MUST revert on any other error.        
        @param _id     Token ID to disenchant.
        @param _depth   Depth of disenchanting recursively.
    */
	function disenchant(uint256 _id, uint256 _depth) external;

	// {
	// 	### disenchant
	//  1. tranfer _id to address(this)
	// 	2. burn new NFT
	// 	3. delete track FTs NFTs to new NFT
	// 	4. transfer FNs NFTs to owner
	// }

	/**
        @dev Get base info of item.
        @param _tokenId Token id of item.
		@return {
			"objClassExt": "Extension of `ObjectClass`.",
			"class": "Class of the item.",
			"grade": "Grade of the item."
		}
    */
	function getBaseInfo(uint256 _tokenId)
		external
		view
		returns (
			uint16,
			uint16,
			uint16
		);

	/**
        @dev Get rate of item.
        @param _tokenId Token id of item.
        @param _element Element item prefer.
		@return {
			"rate": "strength rate of item."
		}
    */
	function getRate(uint256 _tokenId, uint256 _element)
		external
		view
		returns (uint256);

	function getPrefer(uint256 _tokenId)
		external
		view
		returns (uint16);

	function getObjectClassExt(uint256 _tokenId) 
		external	
		view
		returns (uint16);
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

////// src/interfaces/IMetaDataTeller.sol
/* pragma solidity ^0.6.7; */

interface IMetaDataTeller {
	function addTokenMeta(
		address _token,
		uint16 _grade,
		uint112 _strengthRate
	) external;

	function getObjClassExt(address _token, uint256 _id) external view returns (uint16 objClassExt);

	//0xf666196d
	function getMetaData(address _token, uint256 _id)
		external
		view
		returns (uint16, uint16, uint16);

    //0x7999a5cf
	function getPrefer(bytes32 _minor, address _token) external view returns (uint256);

	//0x33281815
	function getRate(
		address _token,
		uint256 _id,
		uint256 _index
	) external view returns (uint256);

	//0xf8350ed0
	function isAllowed(address _token, uint256 _id) external view returns (bool);
}

////// src/interfaces/IObjectOwnership.sol
/* pragma solidity ^0.6.7; */

interface IObjectOwnership {
    function mintObject(address _to, uint128 _objectId) external returns (uint256 _tokenId);
	
    function burn(address _to, uint256 _tokenId) external;
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

////// src/ItemBase.sol
/* pragma solidity ^0.6.7; */

/* import "ds-math/math.sol"; */
/* import "ds-stop/stop.sol"; */
/* import "zeppelin-solidity/proxy/Initializable.sol"; */
/* import "./interfaces/IELIP002.sol"; */
/* import "./interfaces/IFormula.sol"; */
/* import "./interfaces/ISettingsRegistry.sol"; */
/* import "./interfaces/IMetaDataTeller.sol"; */
/* import "./interfaces/IObjectOwnership.sol"; */

contract ItemBase is Initializable, DSStop, DSMath, IELIP002 {
	// 0x434f4e54524143545f4d455441444154415f54454c4c45520000000000000000
	bytes32 public constant CONTRACT_METADATA_TELLER =
		"CONTRACT_METADATA_TELLER";

	// 0x434f4e54524143545f464f524d554c4100000000000000000000000000000000
	bytes32 public constant CONTRACT_FORMULA = "CONTRACT_FORMULA";

	// 0x434f4e54524143545f4f424a4543545f4f574e45525348495000000000000000
	bytes32 public constant CONTRACT_OBJECT_OWNERSHIP =
		"CONTRACT_OBJECT_OWNERSHIP";

	//0x434f4e54524143545f4c505f454c454d454e545f544f4b454e00000000000000
	bytes32 public constant CONTRACT_LP_ELEMENT_TOKEN =
		"CONTRACT_LP_ELEMENT_TOKEN";

	//0x434f4e54524143545f454c454d454e545f544f4b454e00000000000000000000
	bytes32 public constant CONTRACT_ELEMENT_TOKEN = "CONTRACT_ELEMENT_TOKEN";

	// rate precision
	uint128 public constant RATE_PRECISION = 10**8;
	// save about 200 gas when contract create
	bytes4 private constant _SELECTOR_TRANSFERFROM =
		bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));

    bytes4 private constant _SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

	/*** STORAGE ***/

	uint128 public lastItemObjectId;
	ISettingsRegistry public registry;
	mapping(uint256 => Item) public tokenId2Item;

	// mapping(uint256 => mapping(uint256 => uint256)) public tokenId2Rate;

	/**
	 * @dev Same with constructor, but is used and called by storage proxy as logic contract.
	 */
	function initialize(address _registry) public initializer {
		owner = msg.sender;
		emit LogSetOwner(msg.sender);
		registry = ISettingsRegistry(_registry);

		// trick test
		// lastItemObjectId = 1000000;
	}

	function _safeTransferFrom(
		address token,
		address from,
		address to,
		uint256 value
	) private {
		(bool success, bytes memory data) =
			token.call(abi.encodeWithSelector(_SELECTOR_TRANSFERFROM, from, to, value)); // solhint-disable-line
		require(
			success && (data.length == 0 || abi.decode(data, (bool))),
			"Furnace: TRANSFERFROM_FAILED"
		);
	}

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(_SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Furnace: TRANSFER_FAILED');
    }

	function enchant(
		uint256 _index,
		uint256 _id,
		address _token
	) external override stoppable returns (uint256) {
		address teller = registry.addressOf(CONTRACT_METADATA_TELLER);
		address formula = registry.addressOf(CONTRACT_FORMULA);
		require(
			IFormula(formula).isDisable(_index) == false,
			"Furnace: FORMULA_DISABLE"
		);
		(address majorAddr, uint16 originClass, uint16 originPrefer) =
			_dealMajor(teller, formula, _index, _id);
		(uint16 prefer, uint256 amount) =
			_dealMinor(teller, formula, _index, _token);
		if (originClass > 0) {
			require(prefer == originPrefer, "Furnace: INVALID_PREFER");
		}
		return _enchanceItem(formula, _index, prefer, majorAddr, _id, _token, amount);
	}

	function _dealMajor(
		address teller,
		address formula,
		uint256 _index,
		uint256 _id
	) private returns (address, uint16, uint16) {
		(
			address majorAddress,
			uint16 majorObjClassExt,
			uint16 majorClass,
			uint16 majorGrade
		) = IFormula(formula).getMajorInfo(_index);
		(uint16 objectClassExt, uint16 class, uint16 grade) =
			IMetaDataTeller(teller).getMetaData(majorAddress, _id);
		require(
			objectClassExt == majorObjClassExt,
			"Furnace: INVALID_OBJECTCLASSEXT"
		);
		require(class == majorClass, "Furnace: INVALID_CLASS");
		require(grade == majorGrade, "Furnace: INVALID_GRADE");
		_safeTransferFrom(majorAddress, msg.sender, address(this), _id);
		uint16 prefer = 0;
		if (class > 0) {
			prefer = getPrefer(_id);
		}
		return (majorAddress, class, prefer);
	}

	function _dealMinor(
		address teller,
		address formula,
		uint256 _index,
		address _token
	) private returns (uint16, uint256) {
		(bytes32 minor, uint256 amount) = IFormula(formula).getMinor(_index);
		uint16 prefer = 0;
		uint256 element = IMetaDataTeller(teller).getPrefer(minor, _token);
		require(element > 0 && element < 6, "Furnace: INVALID_MINOR");
		prefer |= uint16(1 << element);
		require(amount <= uint128(-1), "Furnace: VALUE_OVERFLOW");
		_safeTransferFrom(_token, msg.sender, address(this), amount);
		return (prefer, amount);
	}

	function _enchanceItem(
		address formula,
		uint256 _index,
		uint16 _prefer,
		address _major,
		uint256 _id,
		address _minor,
		uint256 _amount
	) private returns (uint256) {
		lastItemObjectId += 1;
		require(lastItemObjectId <= uint128(-1), "Furnace: OBJECTID_OVERFLOW");
		(uint16 objClassExt, uint16 class, uint16 grade, uint128 rate) =
			IFormula(formula).getMetaInfo(_index);
		Item memory item =
			Item({
				index: _index,
				rate: rate,
				objClassExt: objClassExt,
				class: class,
				grade: grade,
				prefer: _prefer,
				major: _major,
				id: _id,
				minor: _minor,
				amount: _amount
			});
		uint256 tokenId =
			IObjectOwnership(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP))
				.mintObject(msg.sender, lastItemObjectId);
		tokenId2Item[tokenId] = item;
		emit Enchanced(
			msg.sender,
			tokenId,
			item.index,
			item.rate,
			item.objClassExt,
			item.class,
			item.grade,
			item.prefer,
			item.major,
			item.id,
			item.minor,
			item.amount,
			now // solhint-disable-line
		);
		return tokenId;
	}

	function _disenchantItem(address to, uint256 tokenId) private {
		IObjectOwnership(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).burn(
			to,
			tokenId
		);
        delete tokenId2Item[tokenId];
	}

	function disenchant(uint256 _id, uint256 _depth)
		external
		override
		stoppable
	{
		_safeTransferFrom(
			registry.addressOf(CONTRACT_OBJECT_OWNERSHIP),
			msg.sender,
			address(this),
			_id
		);

		_disenchant(_id, _depth);
	}

	function _disenchant(uint256 _tokenId, uint256 _depth)
		private
	{
		(
			uint16 class,
			bool canDisenchant,
			address major,
			uint256 id,
			address minor,
			uint256 amount
		) = getEnchantedInfo(_tokenId);
		require(_depth > 0, "Furnace: INVALID_DEPTH");
		require(canDisenchant == true, "Furnace: DISENCHANT_DISABLE");
		require(class > 0, "Furnace: INVALID_CLASS");
		_disenchantItem(address(this), _tokenId);
		if (_depth == 1 || class == 0) {
			_safeTransferFrom(major, address(this), msg.sender, id);
		} else {
			_disenchant(id, _depth - 1);
		}
		_safeTransfer(minor, msg.sender, amount);
		emit Disenchanted(msg.sender, _tokenId, major, id, minor, amount);
	}

	function getRate(uint256 _tokenId, uint256 _element)
		public
		view
		override
		returns (uint256)
	{
		Item storage item = tokenId2Item[_tokenId];
		if (uint256(item.prefer) & (1 << _element) > 0) {
			return uint256(item.rate);
		}
		return uint256(item.rate / 2);
	}

	function getBaseInfo(uint256 _tokenId)
		public
		view
		override
		returns (
			uint16,
			uint16,
			uint16
		)
	{
		Item storage item = tokenId2Item[_tokenId];
		return (item.objClassExt, item.class, item.grade);
	}

	function getPrefer(uint256 _tokenId) public view override returns (uint16) {
		return tokenId2Item[_tokenId].prefer;
	}

	function getObjectClassExt(uint256 _tokenId)
		public
		view
		override
		returns (uint16)
	{
		return tokenId2Item[_tokenId].objClassExt;
	}

	function getEnchantedInfo(uint256 _tokenId)
		public
		view
		returns (
			uint16,
			bool,
			address,
			uint256,
			address,
			uint256
		)
	{
		Item storage item = tokenId2Item[_tokenId];
		return (
			item.class,
			IFormula(registry.addressOf(CONTRACT_FORMULA)).canDisenchant(item.index),
			item.major,
			item.id,
			item.minor,
			item.amount
		);
	}
}