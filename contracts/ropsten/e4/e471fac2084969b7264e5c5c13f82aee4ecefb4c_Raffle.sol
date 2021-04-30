/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

// Verified by Darwinia Network

// hevm: flattened sources of src/Raffle.sol

pragma solidity >0.4.13 >=0.4.23 >=0.4.24 <0.7.0 >=0.6.7 <0.7.0;

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

////// lib/ds-stop/lib/ds-auth/src/auth.sol
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
        } else if (authority == DSAuthority(address(0))) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
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

////// lib/zeppelin-solidity/contracts/proxy/Initializable.sol

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

////// src/interfaces/IERC223.sol
/* pragma solidity ^0.6.7; */

interface IERC223 {
    function transfer(address to, uint amount, bytes calldata data) external returns (bool ok);

    function transferFrom(address from, address to, uint256 amount, bytes calldata data) external returns (bool ok);
}

////// src/interfaces/IERC721.sol

/* pragma solidity ^0.6.7; */

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

////// src/interfaces/ILandResource.sol
/* pragma solidity ^0.6.7; */

interface ILandResource {
    function land2ResourceMineState(uint256 landId) external view returns (uint256,uint256,uint256,uint256,uint256,uint256);
	// function getBarItem(uint256 _tokenId, uint256 _index) external view returns (address, uint256, address);
    // function maxAmount() external view returns (uint256);
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

////// src/Raffle.sol
/* pragma solidity ^0.6.7; */

/* import "ds-math/math.sol"; */
/* import "ds-stop/stop.sol"; */
/* import "zeppelin-solidity/proxy/Initializable.sol"; */
/* import "./interfaces/ISettingsRegistry.sol"; */
/* import "./interfaces/ILandResource.sol"; */
/* import "./interfaces/IERC223.sol"; */
/* import "./interfaces/IERC721.sol"; */

contract Raffle is Initializable, DSStop, DSMath {
    event Join(uint256 indexed eventId, uint256 indexed landId, address user, uint256 amount, address subAddr, uint256 fromLandId, uint256 toLandId);
    event ChangeAmount(uint256 indexed eventId, uint256 indexed landId, address user, uint256 amount);
    event ChangeSubAddr(uint256 indexed eventId, uint256 indexed landId, address user, address subAddr);
    event Exit(uint256 indexed eventId, uint256 indexed landId, address user, uint256 amount);
    event Win(uint256 indexed eventId, uint256 indexed landId, address user, uint256 amount, address subAddr, uint256 fromLandId, uint256 toLandId);
    event Lose(uint256 indexed eventId, uint256 indexed landId, address user, uint256 amount, address subAddr);
    // 0x434f4e54524143545f4f424a4543545f4f574e45525348495000000000000000
    bytes32 public constant CONTRACT_OBJECT_OWNERSHIP = "CONTRACT_OBJECT_OWNERSHIP";
    // 0x434f4e54524143545f52494e475f45524332305f544f4b454e00000000000000
    bytes32 public constant CONTRACT_RING_ERC20_TOKEN = "CONTRACT_RING_ERC20_TOKEN";
    // 0x434f4e54524143545f4c414e445f5245534f5552434500000000000000000000
    bytes32 public constant CONTRACT_LAND_RESOURCE = "CONTRACT_LAND_RESOURCE";
    // 0x434f4e54524143545f524556454e55455f504f4f4c0000000000000000000000
    bytes32 public constant CONTRACT_REVENUE_POOL = "CONTRACT_REVENUE_POOL";
    bytes4 private constant _SELECTOR_TRANSFERFROM = bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
    // Join Gold Rush Event minimum RING amount
    uint256 public constant MINI_AMOUNT = 1 ether; 

    // user raffle info
    struct Item {
        address user;       // user address
        uint256 balance;    // user submit amount 
        address subAddr;    // crab dvm address for receiving new land
    }

    struct Conf {
        // Gold Rush start time 
        uint256 startTime;
        // Gold Rush end time 
        uint256 endTime;
        // Gold Rush lottery final time 
        uint256 finalTime;
        // Gold Rush lottery expire time 
        uint256 expireTime;
        // Gold Rush to land id 
        uint256 toLandId;
    }

    // Gold Rush begin from start block
    ISettingsRegistry public registry;
    address public supervisor;
    // Gold Rush from land id 
    uint256 public fromLandId;
    // EventID => Conf
    mapping(uint256 => Conf) public events;
    // EventID => LandID => Item
    mapping(uint256 => mapping(uint256 => Item)) public lands;


    modifier duration(uint256 _eventId) {
        Conf storage conf = events[_eventId];
       require(block.timestamp >= conf.startTime && block.timestamp < conf.endTime, "Raffle: NOT_DURATION"); 
       _;
    }

    function initialize(address _registry, address _supervisor, uint256 _fromLandId) public initializer {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
        registry = ISettingsRegistry(_registry);
        supervisor = _supervisor;
        fromLandId = _fromLandId;
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(_SELECTOR_TRANSFERFROM, from, to, value)); // solhint-disable-line
        require(success && (data.length == 0 || abi.decode(data, (bool))), "Raffle: TRANSFERFROM_FAILED");
    }
    
    /**
    @notice This function is used to join Gold Rust event through ETH/ERC20 Tokens
    @param _eventId event id which to join
    @param _landId  The land token id which to join
    @param _amount  The ring amount which to submit
    @param _subAddr The dvm address for receiving the new land
     */
    function join(uint256 _eventId, uint256 _landId, uint256 _amount, address _subAddr) stoppable duration(_eventId) public {
        address ownership = registry.addressOf(CONTRACT_OBJECT_OWNERSHIP);
        require(msg.sender == IERC721(ownership).ownerOf(_landId), "Raffle: FORBIDDEN");
        require(lands[_eventId][_landId].user == address(0), "Raffle: NOT_EMPTY");
        require(_amount >= MINI_AMOUNT, "Raffle: TOO_SMALL");
        {
            address ring = registry.addressOf(CONTRACT_RING_ERC20_TOKEN);
            _safeTransferFrom(ring, msg.sender, address(this), _amount);
        }
        lands[_eventId][_landId] = Item({
            user: msg.sender,
            balance: _amount,
            subAddr: _subAddr
        });
        emit Join(_eventId, _landId, msg.sender, _amount, _subAddr, fromLandId, events[_eventId].toLandId);
    }

    function joins(uint256 _eventId, uint256[] calldata _landIds, uint256[] calldata _amounts, address[] calldata _subAddrs) external {
        require(_landIds.length == _amounts.length && _landIds.length == _subAddrs.length, "Raffle: INVALID_LENGTH");
        for(uint256 i = 0; i < _landIds.length; i++) {
            join(_eventId, _landIds[i], _amounts[i], _subAddrs[i]);
        }
    }


    /**
    @notice This function is used to change the ring stake amount 
    @param _eventId event id which to join
    @param _landId  The land token id which to join
    @param _amount  The new submit ring amount 
     */
    function changeAmount(uint256 _eventId, uint256 _landId, uint256 _amount) stoppable duration(_eventId) public {
        require(_amount >= MINI_AMOUNT, "Raffle: TOO_SMALL");
        Item storage item = lands[_eventId][_landId];
        require(item.user == msg.sender, "Raffle: FORBIDDEN");
        require(item.balance != _amount, "Raffle: SAME_AMOUNT");
        address ring = registry.addressOf(CONTRACT_RING_ERC20_TOKEN);
        if (_amount > item.balance) {
            uint256 diff = sub(_amount, item.balance);
            _safeTransferFrom(ring, msg.sender, address(this), diff);
        } else {
            uint256 diff = sub(item.balance, _amount);
            _safeTransferFrom(ring, address(this), msg.sender, diff);
        }
        item.balance = _amount;
        emit ChangeAmount(_eventId, _landId, item.user, item.balance);
    }

    /**
    @notice This function is used to change the dvm address   
    @param _eventId event id which to join
    @param _landId  The land token id which to join
    @param _subAddr The new submit dvm address 
     */
    function changeSubAddr(uint256 _eventId, uint256 _landId, address _subAddr) stoppable duration(_eventId) public {
        Item storage item = lands[_eventId][_landId];
        require(item.user == msg.sender, "Raffle: FORBIDDEN");
        require(item.subAddr != _subAddr, "Raffle: SAME_SUBADDR");
        item.subAddr = _subAddr;
        emit ChangeSubAddr(_eventId, _landId, item.user, item.subAddr);
    }

    /**
    @notice This function is used to change the ring stake amount and dvm address   
    @param _eventId event id which to join
    @param _landId  The land token id which to join
    @param _amount  The new submit ring amount 
    @param _subAddr The new submit dvm address 
     */
    function change(uint256 _eventId, uint256 _landId, uint256 _amount, address _subAddr) public {
        changeAmount(_eventId, _landId, _amount);
        changeSubAddr(_eventId, _landId, _subAddr);
    }

    /**
    @notice This function is used to exit Gold Rush event
    @param _eventId event id which to join
    @param _landId  The land token id which to exit
     */
    function exit(uint256 _eventId, uint256 _landId) stoppable duration(_eventId) public {
        Item storage item = lands[_eventId][_landId];
        require(item.user == msg.sender, "Raffle: FORBIDDEN");
        address ring = registry.addressOf(CONTRACT_RING_ERC20_TOKEN);
        _safeTransferFrom(ring, address(this), msg.sender, item.balance);
        emit Exit(_eventId, _landId, item.user, item.balance);
        delete lands[_eventId][_landId];
    }

    // This function is used to redeem prize after lottery
    // _hashmessage = hash("${address(this)}${fromLandId}${toLandId}${_eventId}${_landId}${_won}")
    // _v, _r, _s are from supervisor's signature on _hashmessage
    // while the _hashmessage is signed by supervisor
    function draw(uint256 _eventId, uint256 _landId, bool _won, bytes32 _hashmessage, uint8 _v, bytes32 _r, bytes32 _s) stoppable public {
        Conf storage conf = events[_eventId];
        require(supervisor == _verify(_hashmessage, _v, _r, _s), "Raffle: VERIFY_FAILED");
        require(keccak256(abi.encodePacked(address(this), fromLandId, conf.toLandId, _eventId, _landId, _won)) == _hashmessage, "Raffle: HASH_INVAILD");
        Item storage item = lands[_eventId][_landId];
        require(item.user == msg.sender, "Raffle: FORBIDDEN");
        address ring = registry.addressOf(CONTRACT_RING_ERC20_TOKEN);
        if (_won) {
            //TODO:: check Data
            require(block.timestamp >= conf.finalTime && block.timestamp < conf.expireTime, "Raffle: NOT_PRIZE OR EXPIRATION"); 
            address ownership = registry.addressOf(CONTRACT_OBJECT_OWNERSHIP);
            // return land to eve (genesisHolder)
            _safeTransferFrom(ownership, msg.sender, 0xfE3EE13c28830F7F91Bbb62305D3B616e49998EC, _landId);
            IERC223(ring).transfer(registry.addressOf(CONTRACT_REVENUE_POOL), item.balance, abi.encodePacked(bytes12(0), item.user));
            emit Win(_eventId, _landId, item.user, item.balance, item.subAddr, fromLandId, conf.toLandId);
            delete lands[_eventId][_landId];
        } else {
            require(block.timestamp >= conf.finalTime, "Raffle: NOT_PRIZE"); 
            _safeTransferFrom(ring, address(this), msg.sender, item.balance);
            emit Lose(_eventId, _landId, item.user, item.balance, item.subAddr);
            delete lands[_eventId][_landId];
        }
    }

    function setSupervisor(address _newSupervisor) public auth {
        supervisor = _newSupervisor;
    }

    function setEvent(uint256 _eventId, uint256 _toLandId, uint256 _start, uint256 _end, uint256 _final, uint256 _expire) public auth {
        events[_eventId] = Conf({
            startTime: _start,
            endTime: _end,
            finalTime: _final,
            expireTime: _expire,
            toLandId: _toLandId
        });
    }

    function _verify(bytes32 _hashmessage, uint8 _v, bytes32 _r, bytes32 _s) internal pure returns (address) {
        bytes memory prefix = "\x19EvolutionLand Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, _hashmessage));
        address signer = ecrecover(prefixedHash, _v, _r, _s);
        return signer;
    }
}