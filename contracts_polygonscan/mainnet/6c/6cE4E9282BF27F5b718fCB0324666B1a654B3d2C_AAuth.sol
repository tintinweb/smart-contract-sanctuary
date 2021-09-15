/**
 *Submitted for verification at polygonscan.com on 2021-09-15
*/

// SPDX-License-Identifier: MIT
// File: contracts/interfaces/IDSProxy.sol


pragma solidity ^0.6.0;

interface IDSProxy {
    function execute(address _target, bytes calldata _data) external payable returns (bytes32 response);
    function owner() external view returns (address);
    function authority() external view returns (address);
    function setAuthority(address authority_) external;
}
// File: contracts/externals/dapphub/DSAuth.sol


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

pragma solidity >=0.4.23;

interface DSAuthority {
    function canCall(
        address src,
        address dst,
        bytes4 sig
    ) external view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority(address indexed authority);
    event LogSetOwner(address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority public authority;
    address public owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_) public auth {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_) public auth {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "ds-auth-unauthorized");
        _;
    }

    function isAuthorized(address src, bytes4 sig)
        internal
        view
        returns (bool)
    {
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

// File: contracts/externals/dapphub/DSGuard.sol


// guard.sol -- simple whitelist implementation of DSAuthority

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

pragma solidity >=0.4.23;


contract DSGuardEvents {
    event LogPermit(
        bytes32 indexed src,
        bytes32 indexed dst,
        bytes32 indexed sig
    );

    event LogForbid(
        bytes32 indexed src,
        bytes32 indexed dst,
        bytes32 indexed sig
    );
}

contract DSGuard is DSAuth, DSAuthority, DSGuardEvents {
    bytes32 public constant ANY = bytes32(uint256(-1));

    mapping(bytes32 => mapping(bytes32 => mapping(bytes32 => bool))) acl;

    function canCall(
        address src_,
        address dst_,
        bytes4 sig
    ) public view override returns (bool) {
        bytes32 src = bytes32(bytes20(src_));
        bytes32 dst = bytes32(bytes20(dst_));

        return
            acl[src][dst][sig] ||
            acl[src][dst][ANY] ||
            acl[src][ANY][sig] ||
            acl[src][ANY][ANY] ||
            acl[ANY][dst][sig] ||
            acl[ANY][dst][ANY] ||
            acl[ANY][ANY][sig] ||
            acl[ANY][ANY][ANY];
    }

    function permit(
        bytes32 src,
        bytes32 dst,
        bytes32 sig
    ) public auth {
        acl[src][dst][sig] = true;
        emit LogPermit(src, dst, sig);
    }

    function forbid(
        bytes32 src,
        bytes32 dst,
        bytes32 sig
    ) public auth {
        acl[src][dst][sig] = false;
        emit LogForbid(src, dst, sig);
    }

    function permit(
        address src,
        address dst,
        bytes32 sig
    ) public {
        permit(bytes32(bytes20(src)), bytes32(bytes20(dst)), sig);
    }

    function forbid(
        address src,
        address dst,
        bytes32 sig
    ) public {
        forbid(bytes32(bytes20(src)), bytes32(bytes20(dst)), sig);
    }
}

// File: contracts/utils/DelegateCallAction.sol


pragma solidity ^0.6.0;

/**
 * @dev Can only be delegate call.
 */
abstract contract DelegateCallAction {
    address private immutable self;

    modifier delegateCallOnly() {
        require(self != address(this), "Delegate call only");
        _;
    }

    constructor() internal {
        self = address(this);
    }
}

// File: contracts/utils/OwnableAction.sol


pragma solidity ^0.6.0;

/**
 * @dev Create immutable owner for action contract
 */
abstract contract OwnableAction {
    address payable public immutable actionOwner;

    constructor(address payable _owner) internal {
        actionOwner = _owner;
    }
}

// File: contracts/utils/DestructibleAction.sol


pragma solidity ^0.6.0;


/**
 * @dev Can only be destroyed by owner. All funds are sent to the owner.
 */
abstract contract DestructibleAction is OwnableAction {
    constructor(address payable _owner) internal OwnableAction(_owner) {}

    function destroy() external {
        require(
            msg.sender == actionOwner,
            "DestructibleAction: caller is not the owner"
        );
        selfdestruct(actionOwner);
    }
}

// File: contracts/actions/dsproxy/AAuth.sol


pragma solidity 0.6.12;





contract AAuth is DestructibleAction, DelegateCallAction {
    /// bytes4(keccak256("execute(address,bytes)"))
    bytes4 public constant FUNCTION_SIG_EXECUTE = 0x1cff79cd;

    constructor(address payable _owner)
        public
        DestructibleAction(_owner)
        DelegateCallAction()
    {}

    function createAndSetAuth()
        external
        payable
        delegateCallOnly
        returns (DSGuard guard)
    {
        guard = new DSGuard();
        IDSProxy(address(this)).setAuthority(address(guard));
    }

    function createAndSetAuthPrePermit(address[] calldata authCallers)
        external
        payable
        delegateCallOnly
        returns (DSGuard guard)
    {
        guard = new DSGuard();
        for (uint256 i = 0; i < authCallers.length; i++) {
            guard.permit(authCallers[i], address(this), FUNCTION_SIG_EXECUTE);
        }
        IDSProxy(address(this)).setAuthority(address(guard));
    }

    function permit(address[] calldata authCallers)
        external
        payable
        delegateCallOnly
    {
        DSGuard guard = DSGuard(IDSProxy(address(this)).authority());
        for (uint256 i = 0; i < authCallers.length; i++) {
            guard.permit(authCallers[i], address(this), FUNCTION_SIG_EXECUTE);
        }
    }

    function forbid(address[] calldata forbidCallers)
        external
        payable
        delegateCallOnly
    {
        DSGuard guard = DSGuard(IDSProxy(address(this)).authority());
        for (uint256 i = 0; i < forbidCallers.length; i++) {
            guard.forbid(forbidCallers[i], address(this), FUNCTION_SIG_EXECUTE);
        }
    }
}