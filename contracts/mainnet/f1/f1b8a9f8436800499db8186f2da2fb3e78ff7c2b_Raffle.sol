/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

// Verified by Darwinia Network

// hevm: flattened sources of src/Raffle.sol

pragma solidity >0.4.13 >=0.4.23 >=0.4.24 <0.8.0 >=0.6.2 <0.8.0 >=0.6.7 <0.7.0;

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

////// lib/zeppelin-solidity/contracts/utils/Address.sol

/* pragma solidity >=0.6.2 <0.8.0; */

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

////// lib/zeppelin-solidity/contracts/proxy/Initializable.sol

// solhint-disable-next-line compiler-version
/* pragma solidity >=0.4.24 <0.8.0; */

/* import "../utils/Address.sol"; */

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
        return !Address.isContract(address(this));
    }
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
/* import "./interfaces/IERC20.sol"; */
/* import "./interfaces/IERC223.sol"; */
/* import "./interfaces/IERC721.sol"; */

contract Raffle is Initializable, DSStop, DSMath {
    event Join(uint256 indexed eventId, uint256 indexed landId, address user, uint256 amount, address subAddr, uint256 fromLandId, uint256 toLandId);
    event ChangeAmount(uint256 indexed eventId, uint256 indexed landId, address user, uint256 amount);
    event ChangeSubAddr(uint256 indexed eventId, uint256 indexed landId, address user, address subAddr);
    event Exit(uint256 indexed eventId, uint256 indexed landId, address user, uint256 amount);
    event Win(uint256 indexed eventId, uint256 indexed landId, address user, uint256 amount, address subAddr, uint256 fromLandId, uint256 toLandId);
    event Lose(uint256 indexed eventId, uint256 indexed landId, address user, uint256 amount, address subAddr);
    event SetEvent(uint256 indexed eventId, uint256 startTime, uint256 endTime, uint256 finalTime, uint256 expireTime, uint256 toLandId);
    // 0x434f4e54524143545f4f424a4543545f4f574e45525348495000000000000000
    bytes32 public constant CONTRACT_OBJECT_OWNERSHIP = "CONTRACT_OBJECT_OWNERSHIP";
    // 0x434f4e54524143545f52494e475f45524332305f544f4b454e00000000000000
    bytes32 public constant CONTRACT_RING_ERC20_TOKEN = "CONTRACT_RING_ERC20_TOKEN";
    //0x434f4e54524143545f47454e455349535f484f4c444552000000000000000000
    bytes32 public constant CONTRACT_GENESIS_HOLDER = "CONTRACT_GENESIS_HOLDER";
    // 0x434f4e54524143545f524556454e55455f504f4f4c0000000000000000000000
    bytes32 public constant CONTRACT_REVENUE_POOL = "CONTRACT_REVENUE_POOL";
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
            IERC20(ring).transferFrom(msg.sender, address(this), _amount);
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
            IERC20(ring).transferFrom(msg.sender, address(this), diff);
        } else {
            uint256 diff = sub(item.balance, _amount);
            IERC20(ring).transfer(msg.sender, diff);
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
        IERC20(ring).transfer(msg.sender, item.balance);
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
            IERC721(ownership).transferFrom(msg.sender, registry.addressOf(CONTRACT_GENESIS_HOLDER), _landId);
            IERC223(ring).transfer(registry.addressOf(CONTRACT_REVENUE_POOL), item.balance, abi.encodePacked(bytes12(0), item.user));
            emit Win(_eventId, _landId, item.user, item.balance, item.subAddr, fromLandId, conf.toLandId);
            delete lands[_eventId][_landId];
        } else {
            require(block.timestamp >= conf.finalTime, "Raffle: NOT_PRIZE"); 
            IERC20(ring).transfer(item.user, item.balance);
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
        emit SetEvent(_eventId, events[_eventId].startTime, events[_eventId].endTime, events[_eventId].finalTime, events[_eventId].expireTime, events[_eventId].toLandId);
    }

    function _verify(bytes32 _hashmessage, uint8 _v, bytes32 _r, bytes32 _s) internal pure returns (address) {
        bytes memory prefix = "\x19EvolutionLand Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, _hashmessage));
        address signer = ecrecover(prefixedHash, _v, _r, _s);
        return signer;
    }
}