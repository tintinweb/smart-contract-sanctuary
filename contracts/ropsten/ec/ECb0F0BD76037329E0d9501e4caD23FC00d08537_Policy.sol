// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

/**
 * From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/1488d4f6782f76f74f3652e44da9b9e241146ccb/contracts/access/AccessControl.sol
 *
 * Changes:
 * - Compiled for 0.7.6
 * - Removed ERC165 Introspection
 * - Removed _checkRole
 * - Reformatted styling in line with this repository.
 */

/*
The MIT License (MIT)

Copyright (c) 2016-2020 zOS Global Limited

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/utils/Context.sol";

import "../interfaces/IAccessControl.sol";

abstract contract AccessControl is Context, IAccessControl {
	struct RoleData {
		mapping(address => bool) members;
		bytes32 adminRole;
	}

	mapping(bytes32 => RoleData) private _roles;

	bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

	/* Modifiers */

	modifier onlyRole(bytes32 role) {
		require(hasRole(role, _msgSender()), "AccessControl: access denied");
		_;
	}

	/* External Views */

	/**
	 * @dev Returns `true` if `account` has been granted `role`.
	 */
	function hasRole(bytes32 role, address account)
		public
		view
		override
		returns (bool)
	{
		return _roles[role].members[account];
	}

	/**
	 * @dev Returns the admin role that controls `role`. See {grantRole} and
	 * {revokeRole}.
	 *
	 * To change a role's admin, use {_setRoleAdmin}.
	 */
	function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
		return _roles[role].adminRole;
	}

	/* External Mutators */

	/**
	 * @dev Grants `role` to `account`.
	 *
	 * If `account` had not been already granted `role`, emits a {RoleGranted}
	 * event.
	 *
	 * Requirements:
	 *
	 * - the caller must have ``role``'s admin role.
	 */
	function grantRole(bytes32 role, address account)
		public
		virtual
		override
		onlyRole(getRoleAdmin(role))
	{
		_grantRole(role, account);
	}

	/**
	 * @dev Revokes `role` from `account`.
	 *
	 * If `account` had been granted `role`, emits a {RoleRevoked} event.
	 *
	 * Requirements:
	 *
	 * - the caller must have ``role``'s admin role.
	 */
	function revokeRole(bytes32 role, address account)
		public
		virtual
		override
		onlyRole(getRoleAdmin(role))
	{
		_revokeRole(role, account);
	}

	/**
	 * @dev Revokes `role` from the calling account.
	 *
	 * Roles are often managed via {grantRole} and {revokeRole}: this function's
	 * purpose is to provide a mechanism for accounts to lose their privileges
	 * if they are compromised (such as when a trusted device is misplaced).
	 *
	 * If the calling account had been granted `role`, emits a {RoleRevoked}
	 * event.
	 *
	 * Requirements:
	 *
	 * - the caller must be `account`.
	 */
	function renounceRole(bytes32 role, address account)
		public
		virtual
		override
	{
		require(
			account == _msgSender(),
			"AccessControl: can only renounce roles for self"
		);

		_revokeRole(role, account);
	}

	/* Internal Mutators */

	/**
	 * @dev Grants `role` to `account`.
	 *
	 * If `account` had not been already granted `role`, emits a {RoleGranted}
	 * event. Note that unlike {grantRole}, this function doesn't perform any
	 * checks on the calling account.
	 *
	 * [WARNING]
	 * ====
	 * This function should only be called from the constructor when setting
	 * up the initial roles for the system.
	 *
	 * Using this function in any other way is effectively circumventing the admin
	 * system imposed by {AccessControl}.
	 * ====
	 */
	function _setupRole(bytes32 role, address account) internal virtual {
		_grantRole(role, account);
	}

	/**
	 * @dev Sets `adminRole` as ``role``'s admin role.
	 *
	 * Emits a {RoleAdminChanged} event.
	 */
	function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
		emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
		_roles[role].adminRole = adminRole;
	}

	function _grantRole(bytes32 role, address account) private {
		if (!hasRole(role, account)) {
			_roles[role].members[account] = true;
			emit RoleGranted(role, account, _msgSender());
		}
	}

	function _revokeRole(bytes32 role, address account) private {
		if (hasRole(role, account)) {
			_roles[role].members[account] = false;
			emit RoleRevoked(role, account, _msgSender());
		}
	}
}

// SPDX-License-Identifier: Apache-2.0

/**
 * Copyright 2021 weiWard LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity 0.7.6;

interface IAccessControl {
	/* Views */

	function getRoleAdmin(bytes32 role) external view returns (bytes32);

	function hasRole(bytes32 role, address account) external view returns (bool);

	/* Mutators */

	function grantRole(bytes32 role, address account) external;

	function revokeRole(bytes32 role, address account) external;

	function renounceRole(bytes32 role, address account) external;

	/* Events */
	event RoleAdminChanged(
		bytes32 indexed role,
		bytes32 indexed previousAdminRole,
		bytes32 indexed newAdminRole
	);
	event RoleGranted(
		bytes32 indexed role,
		address indexed account,
		address indexed sender
	);
	event RoleRevoked(
		bytes32 indexed role,
		address indexed account,
		address indexed sender
	);
}

// SPDX-License-Identifier: Apache-2.0

/**
 * Copyright 2021 weiWard LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity 0.7.6;

import "../access/AccessControl/AccessControl.sol";

interface IGasPrice {
	function setGasPrice(uint256) external;
}

interface IETHtx {
	function rebase() external;
}

contract Policy is AccessControl {
	bytes32 public constant POLICY_ROLE = keccak256("POLICY_ROLE");

	address public immutable ethtx;
	address public immutable gasOracle;

	constructor(
		address admin,
		address policyMaker,
		address gasOracle_,
		address ethtx_
	) {
		_setupRole(DEFAULT_ADMIN_ROLE, admin);
		_setupRole(POLICY_ROLE, policyMaker);
		ethtx = ethtx_;
		gasOracle = gasOracle_;
	}

	function update(uint256 gasPrice) external onlyRole(POLICY_ROLE) {
		IGasPrice(gasOracle).setGasPrice(gasPrice);
		IETHtx(ethtx).rebase();
	}
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 999999
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}