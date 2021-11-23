/**
 *Submitted for verification at Etherscan.io on 2021-11-23
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/auth/authorities/TrustAuthority.sol
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.0;

////// src/auth/Auth.sol
/* pragma solidity >=0.7.0; */

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnerUpdated(address indexed owner);

    event AuthorityUpdated(Authority indexed authority);

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnerUpdated(_owner);
        emit AuthorityUpdated(_authority);
    }

    function setOwner(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnerUpdated(owner);
    }

    function setAuthority(Authority newAuthority) public virtual requiresAuth {
        authority = newAuthority;

        emit AuthorityUpdated(authority);
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority cachedAuthority = authority;

        if (address(cachedAuthority) != address(0)) {
            try cachedAuthority.canCall(user, address(this), functionSig) returns (bool canCall) {
                if (canCall) return true;
            } catch {}
        }

        return user == owner;
    }

    modifier requiresAuth() {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }
}

////// src/auth/Trust.sol
/* pragma solidity >=0.7.0; */

/// @notice Ultra minimal authorization logic for smart contracts.
/// @author Inspired by Dappsys V2 (https://github.com/dapp-org/dappsys-v2/blob/main/src/auth.sol)
abstract contract Trust {
    event UserTrustUpdated(address indexed user, bool trusted);

    mapping(address => bool) public isTrusted;

    constructor(address initialUser) {
        isTrusted[initialUser] = true;

        emit UserTrustUpdated(initialUser, true);
    }

    function setIsTrusted(address user, bool trusted) public virtual requiresTrust {
        isTrusted[user] = trusted;

        emit UserTrustUpdated(user, trusted);
    }

    modifier requiresTrust() {
        require(isTrusted[msg.sender], "UNTRUSTED");

        _;
    }
}

////// src/auth/authorities/TrustAuthority.sol
/* pragma solidity >=0.7.0; */

/* import {Trust} from "../Trust.sol"; */
/* import {Authority} from "../Auth.sol"; */

/// @notice Simple Authority that allows a Trust to be used as an Authority.
/// @author Original work by Transmissions11 (https://github.com/transmissions11)
contract TrustAuthority is Trust, Authority {
    constructor(address initialUser) Trust(initialUser) {}

    function canCall(
        address user,
        address,
        bytes4
    ) public view virtual override returns (bool) {
        return isTrusted[user];
    }
}