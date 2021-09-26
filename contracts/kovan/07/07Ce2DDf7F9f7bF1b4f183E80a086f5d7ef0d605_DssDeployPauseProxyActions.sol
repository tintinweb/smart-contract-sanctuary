/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

// hevm: flattened sources of /nix/store/pwxv6slqp9gzdbdn31s5g6wgr8imcj5y-dss-deploy-pause-proxy-actions/dapp/dss-deploy-pause-proxy-actions/src/DssDeployPauseProxyActions.sol

pragma solidity >=0.5.12;

////// /nix/store/pwxv6slqp9gzdbdn31s5g6wgr8imcj5y-dss-deploy-pause-proxy-actions/dapp/dss-deploy-pause-proxy-actions/src/DssDeployPauseProxyActions.sol
/// DssDeployPauseProxyActions.sol

// Copyright (C) 2019-2020 Maker Ecosystem Growth Holdings, INC.

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

interface PauseLike_2 {
    function plot(address, bytes32, bytes calldata, uint) external;
    function exec(address, bytes32, bytes calldata, uint) external;
}

contract DssDeployPauseProxyActions {
    function file(address pause, address actions, address who, bytes32 what, uint data) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike_2(pause).plot(
            address(actions),
            tag,
            abi.encodeWithSignature("file(address,bytes32,uint256)", who, what, data),
            now
        );
        PauseLike_2(pause).exec(
            address(actions),
            tag,
            abi.encodeWithSignature("file(address,bytes32,uint256)", who, what, data),
            now
        );
    }

    function file(address pause, address actions, address who, bytes32 ilk, bytes32 what, uint data) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike_2(pause).plot(
            address(actions),
            tag,
            abi.encodeWithSignature("file(address,bytes32,bytes32,uint256)", who, ilk, what, data),
            now
        );
        PauseLike_2(pause).exec(
            address(actions),
            tag,
            abi.encodeWithSignature("file(address,bytes32,bytes32,uint256)", who, ilk, what, data),
            now
        );
    }

    function file(address pause, address actions, address who, bytes32 ilk, bytes32 what, address data) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike_2(pause).plot(
            address(actions),
            tag,
            abi.encodeWithSignature("file(address,bytes32,bytes32,address)", who, ilk, what, data),
            now
        );
        PauseLike_2(pause).exec(
            address(actions),
            tag,
            abi.encodeWithSignature("file(address,bytes32,bytes32,address)", who, ilk, what, data),
            now
        );
    }

    function rely(address pause, address actions, address who, address to) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike_2(pause).plot(
            address(actions),
            tag,
            abi.encodeWithSignature("rely(address,address)", who, to),
            now
        );
        PauseLike_2(pause).exec(
            address(actions),
            tag,
            abi.encodeWithSignature("rely(address,address)", who, to),
            now
        );
    }

    function dripAndFile(address pause, address actions, address who, bytes32 what, uint data) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike_2(pause).plot(
            address(actions),
            tag,
            abi.encodeWithSignature("dripAndFile(address,bytes32,uint256)", who, what, data),
            now
        );
        PauseLike_2(pause).exec(
            address(actions),
            tag,
            abi.encodeWithSignature("dripAndFile(address,bytes32,uint256)", who, what, data),
            now
        );
    }

    function dripAndFile(address pause, address actions, address who, bytes32 ilk, bytes32 what, uint data) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike_2(pause).plot(
            address(actions),
            tag,
            abi.encodeWithSignature("dripAndFile(address,bytes32,bytes32,uint256)", who, ilk, what, data),
            now
        );
        PauseLike_2(pause).exec(
            address(actions),
            tag,
            abi.encodeWithSignature("dripAndFile(address,bytes32,bytes32,uint256)", who, ilk, what, data),
            now
        );
    }

    function setAuthorityAndDelay(address pause, address actions, address newAuthority, uint newDelay) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike_2(pause).plot(
            address(actions),
            tag,
            abi.encodeWithSignature("setAuthorityAndDelay(address,address,uint256)", pause, newAuthority, newDelay),
            now
        );
        PauseLike_2(pause).exec(
            address(actions),
            tag,
            abi.encodeWithSignature("setAuthorityAndDelay(address,address,uint256)", pause, newAuthority, newDelay),
            now
        );
    }
}