/**
 *Submitted for verification at polygonscan.com on 2021-08-03
*/

// Verified by Darwinia Network

// hevm: flattened sources of src/DrillTakeBack.sol

pragma solidity >0.4.13 >=0.4.23 >=0.6.0 <0.7.0 >=0.6.7 <0.7.0;

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

////// lib/zeppelin-solidity/contracts/token/ERC20/IERC20.sol

/* pragma solidity ^0.6.0; */

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

////// src/interfaces/IDrillBase.sol
/* pragma solidity ^0.6.7; */

interface IDrillBase {
	function createDrill(uint16 grade, address to) external returns (uint256);

    function destroyDrill(address to, uint256 tokenId) external;

	function getGrade(uint256 tokenId) external pure returns (uint16);
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

////// src/DrillTakeBack.sol
/* pragma solidity ^0.6.7; */

/* import "ds-stop/stop.sol"; */
/* import "ds-math/math.sol"; */
/* import "zeppelin-solidity/token/ERC20/IERC20.sol"; */
/* import "./interfaces/ISettingsRegistry.sol"; */
/* import "./interfaces/IDrillBase.sol"; */

contract DrillTakeBack is DSMath, DSStop {
	event TakeBackDrill(
		address indexed user,
		uint256 indexed id,
		uint256 tokenId
	);
	event OpenBox(
		address indexed user,
		uint256 indexed id,
		uint256 tokenId,
		uint256 value
	);
	event ClaimedTokens(
		address indexed token,
		address indexed to,
		uint256 amount
	);

	// 0x434f4e54524143545f52494e475f45524332305f544f4b454e00000000000000
	bytes32 public constant CONTRACT_RING_ERC20_TOKEN =
		"CONTRACT_RING_ERC20_TOKEN";

	// 0x434f4e54524143545f4452494c4c5f4241534500000000000000000000000000
	bytes32 public constant CONTRACT_DRILL_BASE = "CONTRACT_DRILL_BASE";

	address public supervisor;

	uint256 public networkId;

	mapping(uint256 => bool) public ids;

	ISettingsRegistry public registry;

	modifier isHuman() {
		// solhint-disable-next-line avoid-tx-origin
		require(msg.sender == tx.origin, "robot is not permitted");
		_;
	}

	constructor(
		address _registry,
		address _supervisor,
		uint256 _networkId
	) public {
		supervisor = _supervisor;
		networkId = _networkId;
		registry = ISettingsRegistry(_registry);
	}

	// _hashmessage = hash("${address(this)}{_user}${networkId}${ids[]}${grade[]}")
	// _v, _r, _s are from supervisor's signature on _hashmessage
	// takeBack(...) is invoked by the user who want to clain drill.
	// while the _hashmessage is signed by supervisor
	function takeBack(
		uint256[] memory _ids,
		uint16[] memory _grades,
		bytes32 _hashmessage,
		uint8 _v,
		bytes32 _r,
		bytes32 _s
	) public isHuman stoppable {
		address _user = msg.sender;
		// verify the _hashmessage is signed by supervisor
		require(
			supervisor == _verify(_hashmessage, _v, _r, _s),
			"verify failed"
		);
		// verify that the address(this), _user, networkId, _ids, _grades are exactly what they should be
		require(
			keccak256(
				abi.encodePacked(address(this), _user, networkId, _ids, _grades)
			) == _hashmessage,
			"hash invaild"
		);
		require(_ids.length == _grades.length, "length invalid.");
		require(_grades.length > 0, "no drill.");
		for (uint256 i = 0; i < _ids.length; i++) {
			uint256 id = _ids[i];
			require(ids[id] == false, "already taked back.");
			uint16 grade = _grades[i];
			uint256 tokenId = _rewardDrill(grade, _user);
			ids[id] = true;
			emit TakeBackDrill(_user, id, tokenId);
		}
	}

	// _hashmessage = hash("${address(this)}${_user}${networkId}${boxId[]}${amount[]}")
	function openBoxes(
		uint256[] memory _ids,
		uint256[] memory _amounts,
		bytes32 _hashmessage,
		uint8 _v,
		bytes32 _r,
		bytes32 _s
	) public isHuman stoppable {
		address _user = msg.sender;
		// verify the _hashmessage is signed by supervisor
		require(
			supervisor == _verify(_hashmessage, _v, _r, _s),
			"verify failed"
		);
		// verify that the _user, _value are exactly what they should be
		require(
			keccak256(
				abi.encodePacked(
					address(this),
					_user,
					networkId,
					_ids,
					_amounts
				)
			) == _hashmessage,
			"hash invaild"
		);
		require(_ids.length == _amounts.length, "length invalid.");
		require(_ids.length > 0, "no box.");
		for (uint256 i = 0; i < _ids.length; i++) {
			uint256 id = _ids[i];
			require(ids[id] == false, "box already opened.");
			_openBox(_user, id, _amounts[i]);
			ids[id] = true;
		}
	}

	function _openBox(
		address _user,
		uint256 _boxId,
		uint256 _amount
	) internal {
		(uint256 prizeDrill, uint256 prizeRing) = _random(_boxId);
		uint256 tokenId;
		uint256 value;
		uint256 boxType = _boxId >> 255;
		if (boxType == 1) {
			// gold box
			if (prizeRing == 1 && _amount > 1) {
				address ring = registry.addressOf(CONTRACT_RING_ERC20_TOKEN);
				value = _amount / 2;
				IERC20(ring).transfer(_user, value);
			}
			if (prizeDrill < 10) {
				tokenId = _rewardDrill(3, _user);
			} else {
				tokenId = _rewardDrill(2, _user);
			}
		} else {
			// silver box
			if (prizeDrill == 0) {
				tokenId = _rewardDrill(3, _user);
			} else if (prizeDrill < 10) {
				tokenId = _rewardDrill(2, _user);
			} else {
				tokenId = _rewardDrill(1, _user);
			}
		}
		emit OpenBox(_user, _boxId, tokenId, value);
	}

	function _rewardDrill(uint16 _grade, address _owner)
		internal
		returns (uint256)
	{
		address drill = registry.addressOf(CONTRACT_DRILL_BASE);
		return IDrillBase(drill).createDrill(_grade, _owner);
	}

	// random algorithm
	function _random(uint256 _boxId) internal view returns (uint256, uint256) {
		uint256 seed =
			uint256(
				keccak256(
					abi.encodePacked(
						blockhash(block.number),
						block.timestamp, // solhint-disable-line not-rely-on-time
						block.difficulty,
						_boxId
					)
				)
			);
		return (seed % 100, seed >> 255);
	}

	function _verify(
		bytes32 _hashmessage,
		uint8 _v,
		bytes32 _r,
		bytes32 _s
	) internal pure returns (address) {
		bytes memory prefix = "\x19EvolutionLand Signed Message:\n32";
		bytes32 prefixedHash =
			keccak256(abi.encodePacked(prefix, _hashmessage));
		address signer = ecrecover(prefixedHash, _v, _r, _s);
		return signer;
	}

	function changeSupervisor(address _newSupervisor) public auth {
		supervisor = _newSupervisor;
	}

	//////////
	// Safety Methods
	//////////

	/// @notice This method can be used by the controller to extract mistakenly
	///  sent tokens to this contract.
	/// @param _token The address of the token contract that you want to recover
	///  set to 0 in case you want to extract ether.
	function claimTokens(address _token) public auth {
		if (_token == address(0)) {
			_makePayable(owner).transfer(address(this).balance);
			return;
		}
		IERC20 token = IERC20(_token);
		uint256 balance = token.balanceOf(address(this));
		token.transfer(owner, balance);
		emit ClaimedTokens(_token, owner, balance);
	}

	function _makePayable(address x) internal pure returns (address payable) {
		return address(uint160(x));
	}
}