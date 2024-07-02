/**
 *Submitted for verification at hecoinfo.com on 2022-05-10
*/

// Verified by Darwinia Network

// hevm: flattened sources of src/ElementRafflePool.sol

pragma solidity >=0.4.23 >=0.4.24 <0.7.0 >=0.6.7 <0.7.0;

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

////// src/interfaces/ICodexRandom.sol
/* pragma solidity ^0.6.7; */

interface ICodexRandom {
    function dn(uint _s, uint _number) external view returns (uint);
}

////// src/interfaces/IERC20.sol

/* pragma solidity ^0.6.7; */

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
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

    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 _tokenId);
}

////// src/interfaces/IInterstellarEncoder.sol

/* pragma solidity ^0.6.7; */

interface IInterstellarEncoder {
    enum ObjectClass {
        NaN,
        LAND,
        APOSTLE
    }
    function getObjectClass(uint256 _tokenId) external view returns (uint8);
}

////// src/interfaces/ILandBase.sol
/* pragma solidity ^0.6.7; */

interface ILandBase {
    function resourceToken2RateAttrId(address _resourceToken) external view returns (uint256);
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

////// src/ElementRafflePool.sol
/* pragma solidity ^0.6.7; */

/* import "ds-stop/stop.sol"; */
/* import "zeppelin-solidity/proxy/Initializable.sol"; */
/* import "./interfaces/ISettingsRegistry.sol"; */
/* import "./interfaces/IERC20.sol"; */
/* import "./interfaces/IERC721.sol"; */
/* import "./interfaces/ILandBase.sol"; */
/* import "./interfaces/ICodexRandom.sol"; */
/* import "./interfaces/IInterstellarEncoder.sol"; */

contract ElementRafflePool is Initializable, DSStop {
    event SmallDraw(address user, uint256 randomness, IInterstellarEncoder.ObjectClass clss);
    event LargeDraw(address user, uint256 randomness, IInterstellarEncoder.ObjectClass clss);

    bytes32 private constant CONTRACT_LAND_BASE = "CONTRACT_LAND_BASE";
    bytes32 private constant CONTRACT_RANDOM_CODEX = "CONTRACT_RANDOM_CODEX";
    bytes32 private constant CONTRACT_OBJECT_OWNERSHIP = "CONTRACT_OBJECT_OWNERSHIP";
    bytes32 private constant CONTRACT_INTERSTELLAR_ENCODER = "CONTRACT_INTERSTELLAR_ENCODER";

    // small draw fee
    uint256 public smallDrawFee;
    // large draw fee
    uint256 public largeDrawFee;

    ISettingsRegistry public registry;
    // element token address
    address public element;

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    function initialize(address _registry, address _element) public initializer {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
        registry = ISettingsRegistry(_registry);
        require(isValidToken(_element), "Invalid element");
        element = _element;
        smallDrawFee = 10e18;
        largeDrawFee = 100e18;
    }

    function setFee(uint _smallDrawFee, uint _largeDrawFee) external auth {
        smallDrawFee = _smallDrawFee;
        largeDrawFee = _largeDrawFee;
    }

    // do a small draw
    // must approve `smallDrawFee` at least before draw
    function smallDraw() notContract stoppable external {
        IERC20(element).transferFrom(msg.sender, address(this), smallDrawFee);
        address random = registry.addressOf(CONTRACT_RANDOM_CODEX);
        uint seed = _seed();
        uint randomness = ICodexRandom(random).dn(seed, 1000);
        if (randomness == 0) {
            _reward(IInterstellarEncoder.ObjectClass.LAND);
            emit SmallDraw(msg.sender, randomness, IInterstellarEncoder.ObjectClass.LAND);
        } else if (randomness < 10 && randomness > 0) {
            _reward(IInterstellarEncoder.ObjectClass.APOSTLE);
            emit SmallDraw(msg.sender, randomness, IInterstellarEncoder.ObjectClass.APOSTLE);
        } else {
            emit SmallDraw(msg.sender, randomness, IInterstellarEncoder.ObjectClass.NaN);
        }
    }

    // do a large draw
    // must approve `largeDrawFee` at least before draw
    function largeDraw() notContract stoppable external {
        IERC20(element).transferFrom(msg.sender, address(this), largeDrawFee);
        address random = registry.addressOf(CONTRACT_RANDOM_CODEX);
        uint seed = _seed();
        uint randomness = ICodexRandom(random).dn(seed, 100);
        if (randomness == 0) {
            _reward(IInterstellarEncoder.ObjectClass.LAND);
            emit LargeDraw(msg.sender, randomness, IInterstellarEncoder.ObjectClass.LAND);
        } else if (randomness < 10 && randomness > 0) {
            _reward(IInterstellarEncoder.ObjectClass.APOSTLE);
            emit LargeDraw(msg.sender, randomness, IInterstellarEncoder.ObjectClass.APOSTLE);
        } else {
            emit LargeDraw(msg.sender, randomness, IInterstellarEncoder.ObjectClass.NaN);
        }
    }

    // balanceOf this Lands and Apostles
    function balanceOfEVO() public view returns (uint256 lands, uint apostles) {
        address self = address(this);
        address ownership = registry.addressOf(CONTRACT_OBJECT_OWNERSHIP);
        address interstellarEncoder = registry.addressOf(CONTRACT_INTERSTELLAR_ENCODER);
        uint balance = IERC721(ownership).balanceOf(self);
        for(uint i = 0; i < balance; i++) {
            uint256 tokenId = IERC721(ownership).tokenOfOwnerByIndex(self, i);
            if (IInterstellarEncoder(interstellarEncoder).getObjectClass(tokenId) == uint8(IInterstellarEncoder.ObjectClass.LAND)) {
                lands = lands + 1;
            } else if (IInterstellarEncoder(interstellarEncoder).getObjectClass(tokenId) == uint8(IInterstellarEncoder.ObjectClass.APOSTLE)) {
                apostles = apostles + 1;
            }
        }
    }

    function isValidToken(address token) public view returns (bool) {
        uint index = ILandBase(registry.addressOf(CONTRACT_LAND_BASE)).resourceToken2RateAttrId(token);
        return index > 0;
    }

    function _random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function _seed() internal view returns (uint rand) {
        rand = _random(
            string(
                abi.encodePacked(
                    gasleft(),
                    block.difficulty,
                    block.coinbase,
                    block.gaslimit
                )
            )
        );
    }

    function _reward(IInterstellarEncoder.ObjectClass _objectClass) internal {
        address self = address(this);
        address ownership = registry.addressOf(CONTRACT_OBJECT_OWNERSHIP);
        address interstellarEncoder = registry.addressOf(CONTRACT_INTERSTELLAR_ENCODER);
        uint balance = IERC721(ownership).balanceOf(self);
        for(uint i = 0; i < balance; i++) {
            uint256 tokenId = IERC721(ownership).tokenOfOwnerByIndex(self, i);
            if (IInterstellarEncoder(interstellarEncoder).getObjectClass(tokenId) == uint8(_objectClass)) {
                IERC721(ownership).transferFrom(self, msg.sender, tokenId);
                return;
            }
        }

        revert("nothing");
    }

    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}