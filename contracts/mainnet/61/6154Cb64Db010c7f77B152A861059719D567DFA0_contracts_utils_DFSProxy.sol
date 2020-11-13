pragma solidity ^0.6.0;

import "../auth/Auth.sol";
import "../interfaces/DSProxyInterface.sol";

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

contract DFSProxy is Auth {
    string public constant NAME = "DFSProxy";
    string public constant VERSION = "v0.1";

    mapping(address => mapping(uint => bool)) public nonces;

    // --- EIP712 niceties ---
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_TYPEHASH = keccak256("callProxy(address _user,address _proxy,address _contract,bytes _txData,uint256 _nonce)");

    constructor(uint256 chainId_) public {
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(NAME)),
            keccak256(bytes(VERSION)),
            chainId_,
            address(this)
        ));
    }

    function callProxy(address _user, address _proxy, address _contract, bytes calldata _txData, uint256 _nonce,
                    uint8 _v, bytes32 _r, bytes32 _s) external payable onlyAuthorized
    {
        bytes32 digest =
            keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH,
                                     _user,
                                     _proxy,
                                     _contract,
                                     _txData,
                                     _nonce))
        ));

        // user must be proxy owner
        require(DSProxyInterface(_proxy).owner() == _user);
        require(_user == ecrecover(digest, _v, _r, _s), "DFSProxy/user-not-valid");
        require(!nonces[_user][_nonce], "DFSProxy/invalid-nonce");
        
        nonces[_user][_nonce] = true;

        DSProxyInterface(_proxy).execute{value: msg.value}(_contract, _txData);
    }
}