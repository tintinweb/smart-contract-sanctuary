/*
  Copyright 2019,2020 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
pragma solidity ^0.5.2;

import "MainStorage.sol";
import "LibConstants.sol";
import "MGovernance.sol";
import "MKeyGetters.sol";

/**
  Users of the Stark Exchange are identified within the exchange by their Stark Key which is a
  public key defined over a Stark-friendly elliptic curve that is different from the standard
  Ethereum elliptic curve. These keys may be generated using the same private key used by the user
  on Ethereum.

  The Stark-friendly elliptic curve used is defined as follows:

  .. math:: y^2 = (x^3 + \alpha \cdot x + \beta) \% p

  where:

  .. math:: \alpha = 1
  .. math:: \beta = 3141592653589793238462643383279502884197169399375105820974944592307816406665
  .. math:: p = 3618502788666131213697322783095070105623107215331596699973092056135872020481

  In order to associate exchange users with Ethereum account addresses, an Ethereum address must be
  registered with the Stark Key on the exchange contract before any other user operation can take
  place.
  User registration is performed by calling :sol:func:`registerUser` with the selected Stark Key,
  representing an `x` coordinate on the Stark-friendly elliptic curve, and the `y` coordinate of
  the key on the curve (due to the nature of the curve, only two such possible `y` coordinates
  exist).

  The registration is accepted if the following holds:

  1. The key registered is not zero and has not been registered in the past by the user or anyone else.
  2. The key provided represents a valid point on the Stark-friendly elliptic curve.
  3. The linkage between the provided Ethereum key and the selected Stark Key is signed by the User Admin (typically the exchange operator).

  If the above holds, the Stark Key is registered by the contract, mapping it to the Ethereum key.
  This mapping is later used to ensure that withdrawals from accounts mapped to the Stark Keys can
  only be performed by users authenticated with the associated Ethereum public keys (see :sol:mod:`Withdrawals`).
*/
contract Users is MainStorage, LibConstants, MGovernance, MKeyGetters {
    event LogUserRegistered(address ethKey, uint256 starkKey, address sender);
    event LogUserAdminAdded(address userAdmin);
    event LogUserAdminRemoved(address userAdmin);

    function isOnCurve(uint256 starkKey) private view returns (bool) {
        uint256 xCubed = mulmod(mulmod(starkKey, starkKey, K_MODULUS), starkKey, K_MODULUS);
        return isQuadraticResidue(addmod(addmod(xCubed, starkKey, K_MODULUS), K_BETA, K_MODULUS));
    }

    function registerUserAdmin(address newAdmin) external onlyGovernance() {
        userAdmins[newAdmin] = true;
        emit LogUserAdminAdded(newAdmin);
    }

    function unregisterUserAdmin(address oldAdmin) external onlyGovernance() {
        userAdmins[oldAdmin] = false;
        emit LogUserAdminRemoved(oldAdmin);
    }

    function isUserAdmin(address testedAdmin) public view returns (bool) {
        return userAdmins[testedAdmin];
    }

    function registerUser(address ethKey, uint256 starkKey, bytes calldata signature) external {
        // Validate keys and availability.
        require(starkKey != 0, "INVALID_STARK_KEY");
        require(starkKey < K_MODULUS, "INVALID_STARK_KEY");
        require(ethKey != ZERO_ADDRESS, "INVALID_ETH_ADDRESS");
        require(ethKeys[starkKey] == ZERO_ADDRESS, "STARK_KEY_UNAVAILABLE");
        require(isOnCurve(starkKey), "INVALID_STARK_KEY");
        require(signature.length == 65, "INVALID_SIGNATURE");

        bytes32 signedData = keccak256(abi.encodePacked("UserRegistration:", ethKey, starkKey));

        bytes memory sig = signature;
        uint8 v = uint8(sig[64]);
        bytes32 r;
        bytes32 s;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
        }

        address signer = ecrecover(signedData, v, r, s);
        require(isUserAdmin(signer), "INVALID_SIGNATURE");

        // Update state.
        ethKeys[starkKey] = ethKey;

        // Log new user.
        emit LogUserRegistered(ethKey, starkKey, msg.sender);
    }

    function fieldPow(uint256 base, uint256 exponent) internal view returns (uint256) {
        // solium-disable-next-line security/no-low-level-calls
        // NOLINTNEXTLINE: low-level-calls reentrancy-events reentrancy-no-eth.
        (bool success, bytes memory returndata) = address(5).staticcall(
            abi.encode(0x20, 0x20, 0x20, base, exponent, K_MODULUS)
        );
        require(success, string(returndata));
        return abi.decode(returndata, (uint256));
    }

    function isQuadraticResidue(uint256 fieldElement) private view returns (bool) {
        return 1 == fieldPow(fieldElement, ((K_MODULUS - 1) / 2));
    }
}
