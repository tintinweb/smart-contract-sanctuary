/**
 *Submitted for verification at Etherscan.io on 2021-07-20
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >= 0.8.0;

interface ERC20 {
    function transferFrom(address, address, uint) external returns (bool);
    function decimals() external returns (uint8);
}

struct Order {
    address baseTkn;
    address quoteTkn;
    uint8 baseDecimals;
    bool buying;
    address owner;
    uint expires; // timestamp
    uint baseAmt;
    uint price;
    uint minBaseAmt;
}

contract Board {
    event Make(uint id, Order order);
    event Take(address sender, uint id, uint baseAmt, uint quoteAmt);
    event Cancel(address sender, uint id);

    uint private next = 1;

    mapping (uint => bytes32) public orders;

    uint constant public TTL = 30 * 24 * 60 * 60; // 30 days

    function make(Order calldata o) external returns (uint id) {
        require(o.owner == msg.sender, 'board/not-owner');
        require(o.expires > block.timestamp, 'board/too-late');
        require(o.expires <= block.timestamp + TTL, 'board/too-long');
        require(o.baseAmt >= o.minBaseAmt, 'board/min-base-too-big');
        id = next++;
        orders[id] = getHash(o);
        emit Make(id, o);
    }

    function take(uint id, uint baseAmt, Order calldata o) external {
        require(orders[id] == getHash(o), 'board/wrong-hash');
        require(o.expires > block.timestamp, 'board/expired');
        require(baseAmt <= o.baseAmt, 'board/base-too-big');
        require(baseAmt >= o.minBaseAmt || baseAmt == o.baseAmt, 'board/base-too-small');

        uint one = 10 ** uint(o.baseDecimals);
        uint rounding = !o.buying && (baseAmt * o.price) % one > 0 ? one : 0;
        uint quoteAmt = (baseAmt * o.price + rounding) / one;

        if(baseAmt < o.baseAmt) {
            Order memory n = o;
            n.baseAmt = n.baseAmt - baseAmt;
            orders[id] = getHash(n);
        } else {
            delete orders[id];
        }

        emit Take(msg.sender, id, baseAmt, quoteAmt);

        if(o.buying) {
            safeTransferFrom(ERC20(o.baseTkn), msg.sender, o.owner, baseAmt);
            safeTransferFrom(ERC20(o.quoteTkn), o.owner, msg.sender, quoteAmt);

        } else {
            safeTransferFrom(ERC20(o.baseTkn), o.owner, msg.sender, baseAmt);
            safeTransferFrom(ERC20(o.quoteTkn), msg.sender, o.owner, quoteAmt);
        }
    }

    function cancel(uint id, Order calldata o) external {
        require(orders[id] == getHash(o), 'board/wrong-hash');
        require(o.expires <= block.timestamp || o.owner == msg.sender, 'board/invalid-cancel');
        delete orders[id];
        emit Cancel(msg.sender, id);
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint amount) private {
        uint256 size;
        assembly { size := extcodesize(token) }
        require(size > 0, "board/not-a-contract");

        bytes memory data = abi.encodeWithSelector(
            ERC20(token).transferFrom.selector, from, to, amount
        );
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "board/token-call-failed");
        if (returndata.length > 0) { // Return data is optional
            require(abi.decode(returndata, (bool)), "board/transfer-failed");
        }
    }

    function getHash(Order memory o) private pure returns (bytes32) {
        return keccak256(abi.encode(
            o.baseTkn, o.quoteTkn, o.baseDecimals,
            o.buying, o.owner, o.expires, o.baseAmt,
            o.price, o.minBaseAmt
        ));
    }
}