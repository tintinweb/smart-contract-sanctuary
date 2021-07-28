/**
 *Submitted for verification at Etherscan.io on 2021-07-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return recover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return recover(hash, r, vs);
        } else {
            revert("ECDSA: invalid signature length");
        }
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`, `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

interface IPersonalContract {
    struct Event {
        bool enabled;
        uint256 when;
        address who;
        bool open;
        // TODO: maybe something for "where" either physical or virtual? (privacy)
    }

    // Redeem a signature given in the qr code of a paper wallet. A single hour long time slot is awarded to 
    // redeem at some future time;
    function redeemCard(bytes32 hash, uint8 v, bytes32 r, bytes32 s) external returns (bool);
    
    // Redeems one hour slot for a specific timestamp
    //function scheduleSlot(uint256 when, uint256 slot) external returns (bool);
    function scheduleSlot(uint256 num) external returns (bool);

    
    function getEvent(uint256 num) external view returns (Event memory);
    
    /*  Conract owner actions */
    
    function addEvent(uint256 when) external returns (bool);

    
    // decline the communication with a string reason why and return of spent "token" (? is token the right word)?
    //function decline(uint256 when, string memory reason) external returns (bool);
    
    // block this address from creating future events (does this matter, user can use some other address and still redeem card)
//    function blockUser(address who, string memory reason) external returns (bool);
    function blockAddress(address who) external returns (bool);

    // TODO: set some website? or some bio information?
    
    /* Functions anyone can call */
    function destroyPastEvents(uint256 eventHash) external returns (bool);
    
    
    
}

contract PersonalContract is IPersonalContract {
	string private name;
	address private _owner = msg.sender;


    mapping (address => uint256) balances;
    mapping (uint256 => Event) private _events;
    mapping (uint256 => uint256) private _whenFromNum;
    mapping (address => bool) private _allowed;

	modifier onlyOwner() {
		require (msg.sender == _owner);
		_;
	}

    modifier onlyAllowed() {
        require(_allowed[msg.sender] == true);
        _;
    }

    uint256[] private seedSlots;
    uint256 private _interval;
    uint256 private _numEvents;
    
    
    uint256 constant ONEDAY = 86400;
    uint256 constant ONEWEEK = 604800;

    event NewEvent(uint256 indexed when, address indexed who);
    event Cancelled(uint256 indexed when, address indexed who, string reason);
    event Blocked(address indexed who, string reason);


    function events(uint256 key) external view returns (Event memory e) {
        e = _events[key];
    }
    
    function whenFromNum(uint256 key) external view returns (uint256 w) {
        w = _whenFromNum[key];
    }
    
    function allowed(address key) external view returns (bool b) {
        b = _allowed[key];
    }
    
    function numEvents() external view returns (uint256 n) {
        n = _numEvents;
    }
    
    function owner() external returns (address o) {
        o = _owner;
    }

    /*
      _name: name of the user
      slots: an array representing the starting timestamp of the hourlong slots you have destroyPastEvents
      interval: how do these slots repeat? interval could be 1 week so the contract accesses the slot mapping contract 
                slot[i] and  slot[i] + interval and slot[i] + 2*interval, and so on for all slots
    */
	constructor (string memory _name) public {
	   // require(period == ONEDAY || period == ONEWEEK);
		name = _name;
// 		uint i;
// 		for (i = 0; i < slots.length; i++) {
// 		    seedSlots.push(slots[i]);
// 		}
		//interval = period;
	}
	
	
    function redeemCard(bytes32 hash, uint8 v, bytes32 r, bytes32 s) external override returns (bool) {
        require( _allowed[ECDSA.recover(hash, v, r, s)] == true );
        balances[msg.sender] += 1;
        return true;
    }
    
    //function getEvent(uint256 num) public view returns (uint256 when, address who, bool cancelled, string memory reason) {
    function getEvent(uint256 num) public override view returns (Event memory) {
        Event storage e = _events[_whenFromNum[num]];
        return e;
        // when = e.when;
        // who = e.who;
        // cancelled = e.cancelled;
        // reason = e.reason;
    }
    
    // Redeems one hour slot for a specific timestamp
    // function scheduleSlot(uint256 slot, uint256 when) external override returns (bool) {
    //     require(balances[msg.sender] >= 1);
    //     require(block.timestamp <= when);
    //     require((when - seedSlots[slot]) % interval == 0 );
    //     require(events[when].who == address(0));
        
    //     balances[msg.sender] -= 1;
    //     numEvents += 1;
        
    //     events[when] = Event(when, msg.sender, false, "");
    //     whenFromNum[numEvents] = when;
        
    //     emit NewEvent(when, msg.sender);
    //     return true;
    // }
    
    
    function scheduleSlot(uint256 num) onlyAllowed override external returns (bool) {
        require(balances[msg.sender] > 0);
        Event storage e = _events[num];
        require(e.enabled == true);
        require(e.open == true);
        
        e.open = false;
        e.who = msg.sender;
        balances[msg.sender] -= 1;
        
        emit NewEvent(e.when, e.who);
        return true;
    }
    
    /*  Conract owner actions */

    
    function addEvent(uint256 when) onlyOwner override external returns (bool) {
        _numEvents += 1;
        _events[_numEvents].enabled = true;
        _events[_numEvents].when = when;
        return true;
    }
    
    // function decline(uint256 when, string memory reason) external override returns (bool) {
    //     Event storage e = events[when];
    //     require( events[when].who != address(0) );
    //     require( e.cancelled == false );
    //     require(block.timestamp >= e.when);
        
    //     e.cancelled = true;
    //     e.reason = reason;

    //     emit Cancelled(when, e.who, e.reason);
    //     return true;
    // }
    
    // block this address from creating future events (does this matter, user can use some other address and still redeem card)
    // function blockUser(address who, string memory reason) public override returns (bool) {
    //     // TODO implementation
    //     require(balances[who] > 0);
    //     balances[who] = 0;
        
    //     emit Blocked(who, reason);
    //     return true;
    // }
    
    
    function blockAddress(address who) public override returns (bool) {
        require(balances[who] > 0);
        balances[who] = 0;
        return true;
    }
    
    // TODO: set some website? or some bio information?
    
    /* Functions anyone can call */
    function destroyPastEvents(uint256 eventHash) external override returns (bool) {
        // TODO implementation
        return true;
    }

	
}