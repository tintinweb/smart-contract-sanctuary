/* Orchid - WebRTC P2P VPN Market (on Ethereum)
 * Copyright (C) 2017-2021  The Orchid Authors
*/

/* GNU Affero General Public License, Version 3 {{{ */
/* SPDX-License-Identifier: AGPL-3.0-or-later */
/*
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.

 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
**/
/* }}} */


pragma solidity 0.7.6;
pragma abicoder v2;

interface IERC20 {}

contract OrchidLottery1 {
    uint64 private immutable day_;

    constructor(uint64 day) {
        day_ = day;
    }


    struct Account {
        uint256 escrow_amount_;
        uint256 unlock_warned_;
    }

    mapping(bytes32 => Account) accounts_;

    event Create(IERC20 indexed token, address indexed funder, address indexed signer);
    event Update(bytes32 indexed key, uint256 escrow_amount);
    event Delete(bytes32 indexed key, uint256 unlock_warned);

    function read(IERC20 token, address funder, address signer) external view returns (uint256, uint256) {
        Account storage account = accounts_[keccak256(abi.encodePacked(token, funder, signer))];
        return (account.escrow_amount_, account.unlock_warned_);
    }


    function send_(address sender, IERC20 token, uint256 retrieve) private {
        if (retrieve != 0) {
            (bool success, bytes memory result) = address(token).call(
                abi.encodeWithSignature("transfer(address,uint256)", sender, retrieve));
            require(success && (result.length == 0 || abi.decode(result, (bool))));
        }
    }

    function edit(IERC20 token, uint256 amount, address signer, int256 adjust, int256 warn, uint256 retrieve) external {
        require(token != IERC20(0));
        (bool success, bytes memory result) = address(token).call(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, this, amount));
        require(success && abi.decode(result, (bool)));

        edit_(msg.sender, token, amount, signer, adjust, warn, retrieve);
        send_(msg.sender, token, retrieve);
    }

    function tokenFallback(address sender, uint256 amount, bytes calldata data) public {
        require(data.length >= 4);
        bytes4 selector; assembly { selector := calldataload(data.offset) }

        if (false) {
        } else if (selector == bytes4(keccak256("edit(address,int256,int256,uint256)"))) {
            address signer; int256 adjust; int256 warn; uint256 retrieve;
            (signer, adjust, warn, retrieve) = abi.decode(data[4:],
                (address, int256, int256, uint256));
            edit_(sender, IERC20(msg.sender), amount, signer, adjust, warn, retrieve);
            send_(sender, IERC20(msg.sender), retrieve);
        } else require(false);
    }

    function onTokenTransfer(address sender, uint256 amount, bytes calldata data) external returns (bool) {
        tokenFallback(sender, amount, data);
        return true;
    }

    function edit(address signer, int256 adjust, int256 warn, uint256 retrieve) external payable {
        edit_(msg.sender, IERC20(0), msg.value, signer, adjust, warn, retrieve);

        if (retrieve != 0) {
            (bool success,) = msg.sender.call{value: retrieve}("");
            require(success);
        }
    }

    function edit_(address funder, IERC20 token, uint256 amount, address signer, int256 adjust, int256 warn, uint256 retrieve) private {
        bytes32 key = keccak256(abi.encodePacked(token, funder, signer));
        Account storage account = accounts_[key];

        uint256 backup;
        uint256 escrow;

        if (adjust != 0 || amount != retrieve) {
            backup = account.escrow_amount_;
            if (backup == 0)
                emit Create(token, funder, signer);
            escrow = backup >> 128;
            amount += uint128(backup);
        }
    {
        uint256 marked;
        uint256 warned;
        uint256 unlock;

        if (adjust < 0 || warn != 0) {
            warned = account.unlock_warned_;
            marked = warned >> 192;
            unlock = uint64(warned >> 128);
            warned = uint128(warned);
        }

        if (warn > 0) {
            unlock = block.timestamp + day_;

            warned += uint256(warn);
            require(warned >= uint256(warn));
        }

        if (adjust < 0) {
            require(unlock - 1 < block.timestamp);

            uint256 recover = uint256(-adjust);
            require(int256(recover) != adjust);

            require(recover <= escrow);
            amount += recover;
            escrow -= recover;

            require(recover <= warned);
            warned -= recover;
        } else if (adjust != 0) {
            uint256 transfer = uint256(adjust);

            require(transfer <= amount);
            amount -= transfer;
            escrow += transfer;
        }

        if (warn < 0) {
            uint256 decrease = uint256(-warn);
            require(int256(decrease) != warn);

            require(decrease <= warned);
            warned -= decrease;
        }

        if (retrieve != 0) {
            require(retrieve <= amount);
            amount -= retrieve;
        }

        if (unlock != 0) {
            require(warned < 1 << 128);

            uint256 cache = marked << 192 | (warned == 0 ? 0 : unlock << 128 | warned);
            account.unlock_warned_ = cache;
            emit Delete(key, cache);
        }
    } {
        require(amount < 1 << 128);
        require(escrow < 1 << 128);

        uint256 cache = escrow << 128 | amount;
        if (cache != backup) {
            account.escrow_amount_ = cache;
            emit Update(key, cache);
        }
    } }


    struct Loop {
        uint256 closed_;
        mapping(address => uint256) merchants_;
    }

    mapping(address => Loop) private loops_;

    event Enroll(address indexed funder, address indexed recipient);

    function enroll(bool cancel, address[] calldata recipients) external {
        Loop storage loop = loops_[msg.sender];

        uint i = recipients.length;
        if (i == 0) {
            loop.closed_ = cancel ? 0 : block.timestamp + day_;
            emit Enroll(msg.sender, address(0));
        } else {
            uint256 value = cancel ? uint256(-1) : block.timestamp + day_;
            do {
                address recipient = recipients[--i];
                require(recipient != address(0));
                loop.merchants_[recipient] = value;
                emit Enroll(msg.sender, recipient);
            } while (i != 0);
        }
    }

    function enrolled(address funder, address recipient) external view returns (uint256) {
        Loop storage loop = loops_[funder];
        if (recipient == address(0))
            return loop.closed_;
        else
            return loop.merchants_[recipient];
    }

    function mark(IERC20 token, address signer, uint64 marked) external {
        require(marked <= block.timestamp);
        bytes32 key = keccak256(abi.encodePacked(token, msg.sender, signer));
        Account storage account = accounts_[key];
        uint256 cache = account.unlock_warned_;
        cache = uint256(marked) << 192 | uint192(cache);
        account.unlock_warned_ = cache;
        emit Delete(key, cache);
    }


    /*struct Track {
        uint96 expire;
        address owner;
    }*/

    struct Track {
        uint256 packed;
    }

    mapping(bytes32 => Track) private tracks_;

    function save(uint256 count, bytes32 seed) external {
        for (seed = keccak256(abi.encodePacked(
            keccak256(abi.encodePacked(seed, msg.sender))
        , address(0))); count-- != 0; seed = keccak256(abi.encodePacked(seed)))
            tracks_[seed].packed = uint256(msg.sender);
    }

    function spend_(bytes32 refund) private {
        Track storage track = tracks_[refund];
        uint256 packed = track.packed;
        if (packed >> 160 <= block.timestamp)
            if (address(packed) == msg.sender)
                delete track.packed;
    }


    /*struct Ticket {
        uint256 data;
        uint256 reveal;

        uint64 issued;
        uint64 nonce;
        uint128 amount;

        uint31 expire;
        uint64 ratio;
        address funder;
        uint1 v;

        bytes32 r;
        bytes32 s;
    }*/

    struct Ticket {
        bytes32 data;
        bytes32 reveal;
        uint256 packed0;
        uint256 packed1;
        bytes32 r;
        bytes32 s;
    }

    function claim_(IERC20 token, address recipient, Ticket calldata ticket) private returns (uint256) {
        uint256 expire = (ticket.packed0 >> 192) + (ticket.packed1 >> 225);
        if (expire <= block.timestamp)
            return 0;

        if (uint64(ticket.packed1 >> 161) < uint64(uint256(keccak256(abi.encodePacked(ticket.reveal, uint128(ticket.packed0 >> 128))))))
            return 0;

        bytes32 digest; assembly { digest := chainid() }
        digest = keccak256(abi.encodePacked(
            byte(0x19), byte(0x00), this, digest, token,
            recipient, keccak256(abi.encodePacked(ticket.reveal)),
            ticket.packed0, ticket.packed1 >> 1, ticket.data));

        address signer = ecrecover(digest, uint8((ticket.packed1 & 1) + 27), ticket.r, ticket.s);

        address funder = address(ticket.packed1 >> 1);
        bytes32 key = keccak256(abi.encodePacked(token, funder, signer));
        Account storage account = accounts_[key];
    {
        Loop storage loop = loops_[funder];
        if (loop.closed_ - 1 < block.timestamp)
            if (loop.merchants_[recipient] <= account.unlock_warned_ >> 192)
                return 0;
    } {
        Track storage track = tracks_[keccak256(abi.encodePacked(digest, signer))];
        if (track.packed != 0)
            return 0;
        track.packed = expire << 160 | uint256(msg.sender);
    }
        uint256 amount = uint128(ticket.packed0);
        uint256 cache = account.escrow_amount_;

        if (uint128(cache) >= amount)
            cache -= amount;
        else {
            amount = uint128(cache);
            cache = 0;
        }

        account.escrow_amount_ = cache;
        emit Update(key, cache);
        return amount;
    }

    function claim(IERC20 token, address recipient, Ticket[] calldata tickets, bytes32[] calldata refunds) external {
        for (uint256 i = refunds.length; i != 0; )
            spend_(refunds[--i]);

        uint256 segment; assembly { segment := mload(0x40) }

        uint256 amount = 0;
        for (uint256 i = tickets.length; i != 0; ) {
            amount += claim_(token, recipient, tickets[--i]);
            assembly { mstore(0x40, segment) }
        }

        if (amount != 0) {
            bytes32 key = keccak256(abi.encodePacked(token, recipient, recipient));
            Account storage account = accounts_[key];

            uint256 cache = account.escrow_amount_;
            if (cache == 0)
                emit Create(token, recipient, recipient);

            require(uint128(cache) + amount < 1 << 128);
            cache += amount;
            account.escrow_amount_ = cache;
            emit Update(key, cache);
        }
    }
}