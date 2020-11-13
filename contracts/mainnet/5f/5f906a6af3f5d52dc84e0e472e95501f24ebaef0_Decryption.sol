// SPDX-License-Identifier: AGPL-3.0-only

/*
    Decryption.sol - SKALE Manager
    Copyright (C) 2018-Present SKALE Labs
    @author Artem Payvin

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity 0.6.10;

/**
 * @title Decryption
 * @dev This contract performs encryption and decryption functions.
 * Decrypt is used by SkaleDKG contract to decrypt secret key contribution to
 * validate complaints during the DKG procedure.
 */
contract Decryption {

    /**
     * @dev Returns an encrypted text given a secret and a key.
     */
    function encrypt(uint256 secretNumber, bytes32 key) external pure returns (bytes32 ciphertext) {
        return bytes32(secretNumber) ^ key;
    }

    /**
     * @dev Returns a secret given an encrypted text and a key.
     */
    function decrypt(bytes32 ciphertext, bytes32 key) external pure returns (uint256 secretNumber) {
        return uint256(ciphertext ^ key);
    }
}
