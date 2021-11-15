// SPDX-License-Identifier: GNU-3
pragma solidity 0.7.6;

import "./DSAuth.sol";

/// @notice Permissions whitelist with a reasonable level of granularity.
/// @author Rari Capital + DappHub (https://github.com/dapphub/ds-guard)
contract SimpleDSGuard is DSAuth, DSAuthority {
    event LogPermit(bytes32 indexed src, bytes32 indexed sig);

    event LogForbid(bytes32 indexed src, bytes32 indexed sig);

    bytes4 public constant ANY = 0xffffffff;

    mapping(bytes32 => mapping(bytes4 => bool)) internal acl;

    function canCall(
        address src_,
        address, // We don't care about the destination
        bytes4 sig
    ) external view override returns (bool) {
        bytes32 src = bytes32(bytes20(src_));

        return acl[ANY][sig] || acl[src][sig] || acl[src][ANY] || acl[ANY][ANY];
    }

    // Internal Utils //

    function permitBytes(bytes32 src, bytes4 sig) internal auth {
        acl[src][sig] = true;
        emit LogPermit(src, sig);
    }

    function forbidBytes(bytes32 src, bytes4 sig) internal auth {
        acl[src][sig] = false;
        emit LogForbid(src, sig);
    }

    function addressToBytes32(address src) internal pure returns (bytes32) {
        return bytes32(bytes20(src));
    }

    // Permit Public API //

    function permit(address src, bytes4 sig) public {
        permitBytes(addressToBytes32(src), sig);
    }

    function permitAnySource(bytes4 sig) external {
        permitBytes(ANY, sig);
    }

    function permitSourceToCallAny(address src) external {
        permit(src, ANY);
    }

    // Forbid Public API //

    function forbid(address src, bytes4 sig) public {
        forbidBytes(addressToBytes32(src), sig);
    }

    function forbidAnySource(bytes4 sig) external {
        forbidBytes(ANY, sig);
    }

    function forbidSourceToCallAny(address src) external {
        forbid(src, ANY);
    }
}

// SPDX-License-Identifier: GNU-3
pragma solidity 0.7.6;

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author DappHub (https://github.com/dapphub/ds-auth)
abstract contract DSAuth {
    event LogSetAuthority(address indexed authority);
    event LogSetOwner(address indexed owner);

    DSAuthority public authority;
    address public owner;

    constructor() {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_) external auth {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_) external auth {
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

interface DSAuthority {
    function canCall(
        address src,
        address dst,
        bytes4 sig
    ) external view returns (bool);
}

