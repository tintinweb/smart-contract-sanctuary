/**
 *Submitted for verification at arbiscan.io on 2021-11-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

contract Swap {
    // Ed25519 library
    Ed25519 immutable ed25519;

    // contract creator, Alice
    address payable immutable owner;

    // address allowed to claim the ether in this contract
    address payable immutable claimer;

    // the expected public key derived from the secret `s_b`.
    // this public key is a point on the ed25519 curve
    bytes32 public immutable pubKeyClaim;

    // the expected public key derived from the secret `s_a`.
    // this public key is a point on the ed25519 curve
    bytes32 public immutable pubKeyRefund;

    // timestamp (set at contract creation)
    // before which Alice can call either set_ready or refund
    uint256 public immutable timeout_0;

    // timestamp after which Bob cannot claim, only Alice can refund.
    uint256 public immutable timeout_1;

    // Alice sets ready to true when she sees the funds locked on the other chain.
    // this prevents Bob from withdrawing funds without locking funds on the other chain first
    bool isReady = false;

    event Constructed(bytes32 claimKey, bytes32 refundKey);
    event IsReady(bool b);
    event Claimed(bytes32 s);
    event Refunded(bytes32 s);

    constructor(bytes32 _pubKeyClaim, bytes32 _pubKeyRefund, address payable _claimer, uint256 _timeoutDuration) payable {
        owner = payable(msg.sender);
        pubKeyClaim = _pubKeyClaim;
        pubKeyRefund = _pubKeyRefund;
        claimer = _claimer;
        timeout_0 = block.timestamp + _timeoutDuration;
        timeout_1 = block.timestamp + (_timeoutDuration * 2);
        ed25519 = new Ed25519();
        emit Constructed(_pubKeyClaim, _pubKeyRefund);
    }

    // Alice must call set_ready() within t_0 once she verifies the XMR has been locked
    function set_ready() external {
        require(!isReady && msg.sender == owner);
        isReady = true;
        emit IsReady(true);
    }

    // Bob can claim if:
    // - Alice doesn't call set_ready or refund within t_0, or
    // - Alice calls ready within t_0, in which case Bob can call claim until t_1
    function claim(bytes32 _s) external {
        require(msg.sender == claimer, "only claimer can claim!");
        require(block.timestamp < timeout_1 && (block.timestamp >= timeout_0 || isReady), 
            "too late or early to claim!");

        verifySecret(_s, pubKeyClaim);
        emit Claimed(_s);

        // send eth to caller (Bob)
        //selfdestruct(payable(msg.sender));
        claimer.transfer(address(this).balance);
    }

    // Alice can claim a refund:
    // - Until t_0 unless she calls set_ready
    // - After t_1, if she called set_ready
    function refund(bytes32 _s) external {
        require(msg.sender == owner);
        require(
            block.timestamp >= timeout_1 || ( block.timestamp < timeout_0 && !isReady),
            "It's Bob's turn now, please wait!"
        );

        verifySecret(_s, pubKeyRefund);
        emit Refunded(_s);

        // send eth back to owner==caller (Alice)
        //selfdestruct(owner);
        owner.transfer(address(this).balance);
    }

    function verifySecret(bytes32 _s, bytes32 pubKey) internal view {
        // (uint256 px, uint256 py) = ed25519.derivePubKey(_s);
        (uint256 px, uint256 py) = ed25519.scalarMultBase(uint256(_s));
        uint256 canonical_p = py | ((px % 2) << 255);
        require(
            bytes32(canonical_p) == pubKey,
            "provided secret does not match the expected pubKey"
        );
    }
}

// Source https://github.com/javgh/ed25519-solidity

// Using formulas from https://hyperelliptic.org/EFD/g1p/auto-twisted-projective.html
// and constants from https://tools.ietf.org/html/draft-josefsson-eddsa-ed25519-03

contract Ed25519 {
    uint constant q = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFED;
    uint constant d = 37095705934669439343138083508754565189542113879843219016388785533085940283555;
                      // = -(121665/121666)
    uint constant Bx = 15112221349535400772501151409588531511454012693041857206046113283949847762202;
    uint constant By = 46316835694926478169428394003475163141307993866256225615783033603165251855960;

    struct Point {
        uint x;
        uint y;
        uint z;
    }

    struct Scratchpad {
        uint a;
        uint b;
        uint c;
        uint d;
        uint e;
        uint f;
        uint g;
        uint h;
    }

    function inv(uint a) internal view returns (uint invA) {
        uint e = q - 2;
        uint m = q;

        // use bigModExp precompile
        assembly {
            let p := mload(0x40)
            mstore(p, 0x20)
            mstore(add(p, 0x20), 0x20)
            mstore(add(p, 0x40), 0x20)
            mstore(add(p, 0x60), a)
            mstore(add(p, 0x80), e)
            mstore(add(p, 0xa0), m)
            if iszero(staticcall(not(0), 0x05, p, 0xc0, p, 0x20)) {
                revert(0, 0)
            }
            invA := mload(p)
        }
    }

    function ecAdd(Point memory p1,
                   Point memory p2) internal pure returns (Point memory p3) {
        Scratchpad memory tmp;

        tmp.a = mulmod(p1.z, p2.z, q);
        tmp.b = mulmod(tmp.a, tmp.a, q);
        tmp.c = mulmod(p1.x, p2.x, q);
        tmp.d = mulmod(p1.y, p2.y, q);
        tmp.e = mulmod(d, mulmod(tmp.c, tmp.d, q), q);
        tmp.f = addmod(tmp.b, q - tmp.e, q);
        tmp.g = addmod(tmp.b, tmp.e, q);
        p3.x = mulmod(mulmod(tmp.a, tmp.f, q),
                      addmod(addmod(mulmod(addmod(p1.x, p1.y, q),
                                           addmod(p2.x, p2.y, q), q),
                                    q - tmp.c, q), q - tmp.d, q), q);
        p3.y = mulmod(mulmod(tmp.a, tmp.g, q),
                      addmod(tmp.d, tmp.c, q), q);
        p3.z = mulmod(tmp.f, tmp.g, q);
    }

    function ecDouble(Point memory p1) internal pure returns (Point memory p2) {
        Scratchpad memory tmp;

        tmp.a = addmod(p1.x, p1.y, q);
        tmp.b = mulmod(tmp.a, tmp.a, q);
        tmp.c = mulmod(p1.x, p1.x, q);
        tmp.d = mulmod(p1.y, p1.y, q);
        tmp.e = q - tmp.c;
        tmp.f = addmod(tmp.e, tmp.d, q);
        tmp.h = mulmod(p1.z, p1.z, q);
        tmp.g = addmod(tmp.f, q - mulmod(2, tmp.h, q), q);
        p2.x = mulmod(addmod(addmod(tmp.b, q - tmp.c, q), q - tmp.d, q),
                      tmp.g, q);
        p2.y = mulmod(tmp.f, addmod(tmp.e, q - tmp.d, q), q);
        p2.z = mulmod(tmp.f, tmp.g, q);
    }

    function scalarMultBase(uint s) public view returns (uint, uint) {
        Point memory b;
        Point memory result;
        b.x = Bx;
        b.y = By;
        b.z = 1;
        result.x = 0;
        result.y = 1;
        result.z = 1;

        while (s > 0) {
            if (s & 1 == 1) { result = ecAdd(result, b); }
            s = s >> 1;
            b = ecDouble(b);
        }

        uint invZ = inv(result.z);
        result.x = mulmod(result.x, invZ, q);
        result.y = mulmod(result.y, invZ, q);

        return (result.x, result.y);
    }
}