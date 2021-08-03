/**
 *Submitted for verification at polygonscan.com on 2021-08-03
*/

// Verified by Darwinia Network

// hevm: flattened sources of src/DrillLuckyBoxV2.sol

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

////// src/DrillBoxPrice.sol
/* pragma solidity ^0.6.7; */

contract DrillBoxPrice {
	uint256 public constant DECIMALS = 10**18;

	uint256 public constant GOLD_BOX_BASE_PRICE = 1000;
	uint256 public constant GOLD_BOX_MAX_PRICE = 10000;
	uint256 public constant SILVER_BOX_BASE_PRICE = 100;
	uint256 public constant SILVER_BOX_MAX_PRICE = 1000;

	// solhint-disable-next-line var-name-mixedcase
	uint16[91] public GOLD_BOX_PRICE = [
		1000,
		1026,
		1052,
		1080,
		1108,
		1136,
		1166,
		1196,
		1227,
		1259,
		1292,
		1326,
		1360,
		1396,
		1432,
		1469,
		1507,
		1547,
		1587,
		1628,
		1670,
		1714,
		1758,
		1804,
		1851,
		1899,
		1949,
		1999,
		2051,
		2105,
		2159,
		2216,
		2273,
		2332,
		2393,
		2455,
		2519,
		2585,
		2652,
		2721,
		2791,
		2864,
		2938,
		3015,
		3093,
		3174,
		3256,
		3341,
		3428,
		3517,
		3608,
		3702,
		3798,
		3897,
		3999,
		4103,
		4209,
		4319,
		4431,
		4546,
		4664,
		4786,
		4910,
		5038,
		5169,
		5303,
		5441,
		5583,
		5728,
		5877,
		6030,
		6186,
		6347,
		6512,
		6682,
		6855,
		7034,
		7216,
		7404,
		7597,
		7794,
		7997,
		8205,
		8418,
		8637,
		8861,
		9092,
		9328,
		9571,
		9820,
		10000
	];

	// solhint-disable-next-line var-name-mixedcase
	uint16[91] public SILVER_BOX_PRICE = [
		100,
		102,
		105,
		108,
		110,
		113,
		116,
		119,
		122,
		126,
		129,
		132,
		136,
		139,
		143,
		147,
		150,
		154,
		158,
		162,
		167,
		171,
		175,
		180,
		185,
		190,
		194,
		200,
		205,
		210,
		216,
		221,
		227,
		233,
		239,
		245,
		251,
		258,
		265,
		272,
		279,
		286,
		293,
		301,
		309,
		317,
		325,
		334,
		342,
		351,
		360,
		370,
		379,
		389,
		399,
		410,
		421,
		431,
		443,
		454,
		466,
		478,
		491,
		503,
		516,
		530,
		544,
		558,
		572,
		587,
		603,
		618,
		634,
		651,
		668,
		685,
		703,
		721,
		740,
		759,
		779,
		799,
		820,
		841,
		863,
		886,
		909,
		932,
		957,
		982,
		1000
	];
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

////// src/DrillLuckyBoxV2.sol
/* pragma solidity ^0.6.7; */

/* import "ds-stop/stop.sol"; */
/* import "ds-math/math.sol"; */
/* import "zeppelin-solidity/token/ERC20/IERC20.sol"; */
/* import "./interfaces/ISettingsRegistry.sol"; */
/* import "./DrillBoxPrice.sol"; */

contract DrillLuckyBoxV2 is DSMath, DSStop, DrillBoxPrice {
	event GoldBoxSale(address indexed buyer, uint256 amount, uint256 price);
	event SilverBoxSale(address indexed buyer, uint256 amount, uint256 price);
	event ClaimedTokens(
		address indexed token,
		address indexed to,
		uint256 amount
	);

	// 0x434f4e54524143545f52494e475f45524332305f544f4b454e00000000000000
	bytes32 public constant CONTRACT_RING_ERC20_TOKEN =
		"CONTRACT_RING_ERC20_TOKEN";

	address payable public wallet;

	uint256 public priceIncreaseBeginTime;

	ISettingsRegistry public registry;

	constructor(
		address _registry,
		address payable _wallet,
		uint256 _priceIncreaseBeginTime
	) public {
		require(_wallet != address(0), "Need a good wallet to store fund");

		registry = ISettingsRegistry(_registry);
		wallet = _wallet;
		priceIncreaseBeginTime = _priceIncreaseBeginTime;
	}

	/**
	 * @param _from - person who transfer token in for buying box.
	 * @param goldBoxAmount - buy gold box amount.
	 * @param silverBoxAmount - buy silver box amount.
	 * @param amountMax - buy box max amount.
	 */
    function buyBox(
		address _from,
        uint256 goldBoxAmount,
        uint256 silverBoxAmount,
        uint256 amountMax
	) external stoppable {
		(uint256 priceGoldBox, uint256 priceSilverBox) = getPrice();
		uint256 chargeGoldBox = mul(goldBoxAmount, priceGoldBox);
		uint256 chargeSilverBox = mul(silverBoxAmount, priceSilverBox);
		uint256 charge = add(chargeGoldBox, chargeSilverBox);
		//  Only supported tokens can be called
		address ring = registry.addressOf(CONTRACT_RING_ERC20_TOKEN);
		require(
			goldBoxAmount > 0 || silverBoxAmount > 0,
			"Buy gold or silver box"
		);
		require(amountMax >= charge, "No enough ring for buying lucky boxes.");

		IERC20(ring).transferFrom(msg.sender, wallet, charge);

		if (goldBoxAmount > 0) {
			emit GoldBoxSale(_from, goldBoxAmount, priceGoldBox);
		}
		if (silverBoxAmount > 0) {
			emit SilverBoxSale(_from, silverBoxAmount, priceSilverBox);
		}
	}

	function getPrice()
		public
		view
		returns (uint256 priceGoldBox, uint256 priceSilverBox)
	{
		// solhint-disable-next-line not-rely-on-time
		if (now <= priceIncreaseBeginTime) {
			priceGoldBox = GOLD_BOX_BASE_PRICE;
			priceSilverBox = SILVER_BOX_BASE_PRICE;
		} else {
			// solhint-disable-next-line not-rely-on-time
			uint256 numDays = sub(now, priceIncreaseBeginTime) / 1 days;
			if (numDays > 90) {
				priceGoldBox = GOLD_BOX_MAX_PRICE;
				priceSilverBox = SILVER_BOX_MAX_PRICE;
			} else {
				priceGoldBox = uint256(GOLD_BOX_PRICE[numDays]);
				priceSilverBox = uint256(SILVER_BOX_PRICE[numDays]);
			}
		}
		priceGoldBox = mul(priceGoldBox, DECIMALS);
		priceSilverBox = mul(priceSilverBox, DECIMALS);
	}

    function setBeginTime(uint256 _priceIncreaseBeginTime) public auth {
        priceIncreaseBeginTime = _priceIncreaseBeginTime;
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