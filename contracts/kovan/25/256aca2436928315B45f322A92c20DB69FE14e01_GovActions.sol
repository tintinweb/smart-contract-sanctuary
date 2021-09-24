/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

// hevm: flattened sources of /nix/store/6g10a1a7534iq4igxya4vmlgnlpgcax9-dss-deploy/dapp/dss-deploy/src/govActions.sol

pragma solidity >=0.5.12;

////// /nix/store/6g10a1a7534iq4igxya4vmlgnlpgcax9-dss-deploy/dapp/dss-deploy/src/govActions.sol
/// govActions.sol

// Copyright (C) 2018-2020 Maker Ecosystem Growth Holdings, INC.

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.


/* pragma solidity >=0.5.12; */

interface SetterLike {
    function file(bytes32, address) external;
    function file(bytes32, uint) external;
    function file(bytes32, bytes32, uint) external;
    function file(bytes32, bytes32, address) external;
    function rely(address) external;
    function deny(address) external;
    function init(bytes32) external;
    function drip() external;
    function drip(bytes32) external;
}

interface EndLike_1 {
    function cage() external;
    function cage(bytes32) external;
}

interface PauseLike {
    function setAuthority(address) external;
    function setDelay(uint) external;
}

contract GovActions {
    function file(address who, bytes32 what, address data) public {
        SetterLike(who).file(what, data);
    }

    function file(address who, bytes32 what, uint data) public {
        SetterLike(who).file(what, data);
    }

    function file(address who, bytes32 ilk, bytes32 what, uint data) public {
        SetterLike(who).file(ilk, what, data);
    }

    function file(address who, bytes32 ilk, bytes32 what, address data) public {
        SetterLike(who).file(ilk, what, data);
    }

    function dripAndFile(address who, bytes32 what, uint data) public {
        SetterLike(who).drip();
        SetterLike(who).file(what, data);
    }

    function dripAndFile(address who, bytes32 ilk, bytes32 what, uint data) public {
        SetterLike(who).drip(ilk);
        SetterLike(who).file(ilk, what, data);
    }

    function rely(address who, address to) public {
        SetterLike(who).rely(to);
    }

    function deny(address who, address to) public {
        SetterLike(who).deny(to);
    }

    function init(address who, bytes32 ilk) public {
        SetterLike(who).init(ilk);
    }

    function cage(address end) public {
        EndLike_1(end).cage();
    }

    function setAuthority(address pause, address newAuthority) public {
        PauseLike(pause).setAuthority(newAuthority);
    }

    function setDelay(address pause, uint newDelay) public {
        PauseLike(pause).setDelay(newDelay);
    }

    function setAuthorityAndDelay(address pause, address newAuthority, uint newDelay) public {
        PauseLike(pause).setAuthority(newAuthority);
        PauseLike(pause).setDelay(newDelay);
    }
}