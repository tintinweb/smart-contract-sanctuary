/**
 *Submitted for verification at Etherscan.io on 2021-02-14
*/

/// GebDeployPauseProxyActions.sol

// Copyright (C) 2018 Gonzalo Balabasquer <[email protected]>
//
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

pragma solidity 0.6.7;

abstract contract PauseLike {
    function scheduleTransaction(address, bytes32, bytes memory, uint) virtual public;
    function executeTransaction(address, bytes32, bytes memory, uint) virtual public;
}

contract GebDeployPauseProxyActions {
    function modifyParameters(address pause, address actions, address who, bytes32 parameter, uint data) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("modifyParameters(address,bytes32,uint256)", who, parameter, data),
            now
        );
        PauseLike(pause).executeTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("modifyParameters(address,bytes32,uint256)", who, parameter, data),
            now
        );
    }

    function modifyParameters(address pause, address actions, address who, bytes32 parameter, address data) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("modifyParameters(address,bytes32,address)", who, parameter, data),
            now
        );
        PauseLike(pause).executeTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("modifyParameters(address,bytes32,address)", who, parameter, data),
            now
        );
    }

    function modifyParameters(address pause, address actions, address who, bytes32 collateralType, bytes32 parameter, uint data) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("modifyParameters(address,bytes32,bytes32,uint256)", who, collateralType, parameter, data),
            now
        );
        PauseLike(pause).executeTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("modifyParameters(address,bytes32,bytes32,uint256)", who, collateralType, parameter, data),
            now
        );
    }

    function modifyParameters(address pause, address actions, address who, bytes32 collateralType, bytes32 parameter, address data) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("modifyParameters(address,bytes32,bytes32,address)", who, collateralType, parameter, data),
            now
        );
        PauseLike(pause).executeTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("modifyParameters(address,bytes32,bytes32,address)", who, collateralType, parameter, data),
            now
        );
    }

    function modifyParameters(address pause, address actions, address who, bytes32 collateralType, uint data1, uint data2) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("modifyParameters(address,bytes32,uint256,uint256)", who, collateralType, data1, data2),
            now
        );
        PauseLike(pause).executeTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("modifyParameters(address,bytes32,uint256,uint256)", who, collateralType, data1, data2),
            now
        );
    }

    function modifyParameters(address pause, address actions, address who, bytes32 collateralType, uint data1, uint data2, address data3) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("modifyParameters(address,bytes32,uint256,uint256,address)", who, collateralType, data1, data2, data3),
            now
        );
        PauseLike(pause).executeTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("modifyParameters(address,bytes32,uint256,uint256,address)", who, collateralType, data1, data2, data3),
            now
        );
    }

    function addAuthorization(address pause, address actions, address who, address to) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("addAuthorization(address,address)", who, to),
            now
        );
        PauseLike(pause).executeTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("addAuthorization(address,address)", who, to),
            now
        );
    }

    function updateRedemptionRate(address pause, address actions, address who, bytes32 parameter, uint data) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("updateRedemptionRate(address,bytes32,uint256)", who, parameter, data),
            now
        );
        PauseLike(pause).executeTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("updateRedemptionRate(address,bytes32,uint256)", who, parameter, data),
            now
        );
    }

    function updateRateAndModifyParameters(address pause, address actions, address who, bytes32 parameter, uint data) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("updateRateAndModifyParameters(address,bytes32,uint256)", who, parameter, data),
            now
        );
        PauseLike(pause).executeTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("updateRateAndModifyParameters(address,bytes32,uint256)", who, parameter, data),
            now
        );
    }

    function taxSingleAndModifyParameters(address pause, address actions, address who, bytes32 collateralType, bytes32 parameter, uint data) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("taxSingleAndModifyParameters(address,bytes32,bytes32,uint256)", who, collateralType, parameter, data),
            now
        );
        PauseLike(pause).executeTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("taxSingleAndModifyParameters(address,bytes32,bytes32,uint256)", who, collateralType, parameter, data),
            now
        );
    }

    function setAuthorityAndDelay(address pause, address actions, address newAuthority, uint newDelay) external {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("setAuthorityAndDelay(address,address,uint256)", pause, newAuthority, newDelay),
            now
        );
        PauseLike(pause).executeTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("setAuthorityAndDelay(address,address,uint256)", pause, newAuthority, newDelay),
            now
        );
    }

    function setProtester(address pause, address actions, address protester) public {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("setProtester(address,address)", pause, protester),
            now
        );
        PauseLike(pause).executeTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("setProtester(address,address)", pause, protester),
            now
        );
    }

    function setOwner(address pause, address actions, address owner) public {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("setOwner(address,address)", pause, owner),
            now
        );
        PauseLike(pause).executeTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("setOwner(address,address)", pause, owner),
            now
        );
    }

    function setDelay(address pause, address actions, uint newDelay) public {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("setDelay(address,uint256)", pause, newDelay),
            now
        );
        PauseLike(pause).executeTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("setDelay(address,uint256)", pause, newDelay),
            now
        );
    }

    function setDelayMultiplier(address pause, address actions, uint delayMultiplier) public {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("setDelayMultiplier(address,uint256)", pause, delayMultiplier),
            now
        );
        PauseLike(pause).executeTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("setDelayMultiplier(address,uint256)", pause, delayMultiplier),
            now
        );
    }

    function setTotalAllowance(address pause, address actions, address who, address account, uint rad) public {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("setTotalAllowance(address,address,uint256)", who, account, rad),
            now
        );
        PauseLike(pause).executeTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("setTotalAllowance(address,address,uint256)", who, account, rad),
            now
        );
    }

    function setPerBlockAllowance(address pause, address actions, address who, address account, uint rad) public {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("setPerBlockAllowance(address,address,uint256)", who, account, rad),
            now
        );
        PauseLike(pause).executeTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("setPerBlockAllowance(address,address,uint256)", who, account, rad),
            now
        );
    }

    function setAllowance(address pause, address actions, address join, address account, uint allowance) public {
        bytes32 tag;
        assembly { tag := extcodehash(actions) }
        PauseLike(pause).scheduleTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("setAllowance(address,address,uint256)", join, account, allowance),
            now
        );
        PauseLike(pause).executeTransaction(
            address(actions),
            tag,
            abi.encodeWithSignature("setAllowance(address,address,uint256)", join, account, allowance),
            now
        );
    }
}