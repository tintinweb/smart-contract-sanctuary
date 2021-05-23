/**
 *Submitted for verification at Etherscan.io on 2021-05-23
*/

// File: contract\auth.sol

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

pragma solidity >=0.4.23;

contract DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "ds-auth-unauthorized");
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
}

// File: contract\math.sol

/// math.sol -- mixin for inline numerical wizardry

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

pragma solidity >0.4.13;

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

// File: contract\erc20.sol

/// erc20.sol -- API for the ERC20 token standard

// See <https://github.com/ethereum/EIPs/issues/20>.

// This file likely does not meet the threshold of originality
// required for copyright to apply.  As a result, this is free and
// unencumbered software belonging to the public domain.

pragma solidity >0.4.20;

contract ERC20Events {
    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
}

contract ERC20 is ERC20Events {
    function totalSupply() public view returns (uint);
    function balanceOf(address guy) public view returns (uint);
    function allowance(address src, address guy) public view returns (uint);

    function approve(address guy, uint wad) public returns (bool);
    function transfer(address dst, uint wad) public returns (bool);
    function transferFrom(
        address src, address dst, uint wad
    ) public returns (bool);
}

// File: contract\simple_market.sol

/// simple_market.sol
// Copyright (C) 2016 - 2020 Maker Ecosystem Growth Holdings, INC.

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

pragma solidity ^0.5.12;



contract EventfulMarket {
    event LogItemUpdate(uint id);
    event LogTrade(uint pay_amt, address indexed pay_gem,
                   uint buy_amt, address indexed buy_gem);

    event LogMake(
        bytes32  indexed  id,
        bytes32  indexed  pair,
        address  indexed  maker,
        ERC20             pay_gem,
        ERC20             buy_gem,
        uint128           pay_amt,
        uint128           buy_amt,
        uint64            timestamp
    );

    event LogBump(
        bytes32  indexed  id,
        bytes32  indexed  pair,
        address  indexed  maker,
        ERC20             pay_gem,
        ERC20             buy_gem,
        uint128           pay_amt,
        uint128           buy_amt,
        uint64            timestamp
    );

    event LogTake(
        bytes32           id,
        bytes32  indexed  pair,
        address  indexed  maker,
        ERC20             pay_gem,
        ERC20             buy_gem,
        address  indexed  taker,
        uint128           take_amt,
        uint128           give_amt,
        uint64            timestamp
    );

    event LogKill(
        bytes32  indexed  id,
        bytes32  indexed  pair,
        address  indexed  maker,
        ERC20             pay_gem,
        ERC20             buy_gem,
        uint128           pay_amt,
        uint128           buy_amt,
        uint64            timestamp
    );
}

contract SimpleMarket is EventfulMarket, DSMath {

    uint public last_offer_id;

    mapping (uint => OfferInfo) public offers;

    bool locked;

    struct OfferInfo {
        uint     pay_amt;
        ERC20    pay_gem;
        uint     buy_amt;
        ERC20    buy_gem;
        address  owner;
        uint64   timestamp;
    }

    modifier can_buy(uint id) {
        require(isActive(id));
        _;
    }

    modifier can_cancel(uint id) {
        require(isActive(id));
        require(getOwner(id) == msg.sender);
        _;
    }

    modifier can_offer {
        _;
    }

    modifier synchronized {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }

    function isActive(uint id) public view returns (bool active) {
        return offers[id].timestamp > 0;
    }

    function getOwner(uint id) public view returns (address owner) {
        return offers[id].owner;
    }

    function getOffer(uint id) public view returns (uint, ERC20, uint, ERC20) {
      OfferInfo memory offer = offers[id];
      return (offer.pay_amt, offer.pay_gem,
              offer.buy_amt, offer.buy_gem);
    }

    // ---- Public entrypoints ---- //

    function bump(bytes32 id_)
        public
        can_buy(uint256(id_))
    {
        uint256 id = uint256(id_);
        emit LogBump(
            id_,
            keccak256(abi.encodePacked(offers[id].pay_gem, offers[id].buy_gem)),
            offers[id].owner,
            offers[id].pay_gem,
            offers[id].buy_gem,
            uint128(offers[id].pay_amt),
            uint128(offers[id].buy_amt),
            offers[id].timestamp
        );
    }

    // Accept given `quantity` of an offer. Transfers funds from caller to
    // offer maker, and from market to caller.
    function buy(uint id, uint quantity)
        public
        can_buy(id)
        synchronized
        returns (bool)
    {
        OfferInfo memory offer = offers[id];
        uint spend = mul(quantity, offer.buy_amt) / offer.pay_amt;

        require(uint128(spend) == spend);
        require(uint128(quantity) == quantity);

        // For backwards semantic compatibility.
        if (quantity == 0 || spend == 0 ||
            quantity > offer.pay_amt || spend > offer.buy_amt)
        {
            return false;
        }

        offers[id].pay_amt = sub(offer.pay_amt, quantity);
        offers[id].buy_amt = sub(offer.buy_amt, spend);
        require( offer.buy_gem.transferFrom(msg.sender, offer.owner, spend) );
        require( offer.pay_gem.transfer(msg.sender, quantity) );

        emit LogItemUpdate(id);
        emit LogTake(
            bytes32(id),
            keccak256(abi.encodePacked(offer.pay_gem, offer.buy_gem)),
            offer.owner,
            offer.pay_gem,
            offer.buy_gem,
            msg.sender,
            uint128(quantity),
            uint128(spend),
            uint64(now)
        );
        emit LogTrade(quantity, address(offer.pay_gem), spend, address(offer.buy_gem));

        if (offers[id].pay_amt == 0) {
          delete offers[id];
        }

        return true;
    }

    // Cancel an offer. Refunds offer maker.
    function cancel(uint id)
        public
        can_cancel(id)
        synchronized
        returns (bool success)
    {
        // read-only offer. Modify an offer by directly accessing offers[id]
        OfferInfo memory offer = offers[id];
        delete offers[id];

        require( offer.pay_gem.transfer(offer.owner, offer.pay_amt) );

        emit LogItemUpdate(id);
        emit LogKill(
            bytes32(id),
            keccak256(abi.encodePacked(offer.pay_gem, offer.buy_gem)),
            offer.owner,
            offer.pay_gem,
            offer.buy_gem,
            uint128(offer.pay_amt),
            uint128(offer.buy_amt),
            uint64(now)
        );

        success = true;
    }

    function kill(bytes32 id)
        public
    {
        require(cancel(uint256(id)));
    }

    function make(
        ERC20    pay_gem,
        ERC20    buy_gem,
        uint128  pay_amt,
        uint128  buy_amt
    )
        public
        returns (bytes32 id)
    {
        return bytes32(offer(pay_amt, pay_gem, buy_amt, buy_gem));
    }

    // Make a new offer. Takes funds from the caller into market escrow.
    function offer(uint pay_amt, ERC20 pay_gem, uint buy_amt, ERC20 buy_gem)
        public
        can_offer
        synchronized
        returns (uint id)
    {
        require(uint128(pay_amt) == pay_amt);
        require(uint128(buy_amt) == buy_amt);
        require(pay_amt > 0);
        require(pay_gem != ERC20(0x0));
        require(buy_amt > 0);
        require(buy_gem != ERC20(0x0));
        require(pay_gem != buy_gem);

        OfferInfo memory info;
        info.pay_amt = pay_amt;
        info.pay_gem = pay_gem;
        info.buy_amt = buy_amt;
        info.buy_gem = buy_gem;
        info.owner = msg.sender;
        info.timestamp = uint64(now);
        id = _next_id();
        offers[id] = info;

        require( pay_gem.transferFrom(msg.sender, address(this), pay_amt) );

        emit LogItemUpdate(id);
        emit LogMake(
            bytes32(id),
            keccak256(abi.encodePacked(pay_gem, buy_gem)),
            msg.sender,
            pay_gem,
            buy_gem,
            uint128(pay_amt),
            uint128(buy_amt),
            uint64(now)
        );
    }

    function take(bytes32 id, uint128 maxTakeAmount)
        public
    {
        require(buy(uint256(id), maxTakeAmount));
    }

    function _next_id()
        internal
        returns (uint)
    {
        last_offer_id++; return last_offer_id;
    }
}

// File: contract\expiring_market.sol

/// expiring_market.sol
// Copyright (C) 2016 - 2020 Maker Ecosystem Growth Holdings, INC.

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

pragma solidity ^0.5.12;



// Simple Market with a market lifetime. When the close_time has been reached,
// offers can only be cancelled (offer and buy will throw).

contract ExpiringMarket is DSAuth, SimpleMarket {
    uint64 public close_time;
    bool public stopped;

    // after close_time has been reached, no new offers are allowed
    modifier can_offer {
        require(!isClosed());
        _;
    }

    // after close, no new buys are allowed
    modifier can_buy(uint id) {
        require(isActive(id));
        require(!isClosed());
        _;
    }

    // after close, anyone can cancel an offer
    modifier can_cancel(uint id) {
        require(isActive(id));
        require((msg.sender == getOwner(id)) || isClosed());
        _;
    }

    constructor(uint64 _close_time)
        public
    {
        close_time = _close_time;
    }

    function isClosed() public view returns (bool closed) {
        return stopped || getTime() > close_time;
    }

    function getTime() public view returns (uint64) {
        return uint64(now);
    }

    function stop() public auth {
        stopped = true;
    }
}

// File: contract\note.sol

/// note.sol -- the `note' modifier, for logging calls as events

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

pragma solidity >=0.4.23;

contract DSNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  guy,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
        uint256           wad,
        bytes             fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;
        uint256 wad;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
            wad := callvalue
        }

        emit LogNote(msg.sig, msg.sender, foo, bar, wad, msg.data);

        _;
    }
}

// File: contract\matching_market.sol

/// matching_market.sol
// Copyright (C) 2017 - 2020 Maker Ecosystem Growth Holdings, INC.

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

pragma solidity ^0.5.12;



contract MatchingEvents {
    event LogBuyEnabled(bool isEnabled);
    event LogMinSell(address pay_gem, uint min_amount);
    event LogMatchingEnabled(bool isEnabled);
    event LogUnsortedOffer(uint id);
    event LogSortedOffer(uint id);
    event LogInsert(address keeper, uint id);
    event LogDelete(address keeper, uint id);
}

contract MatchingMarket is MatchingEvents, ExpiringMarket, DSNote {
    bool public buyEnabled = true;      //buy enabled
    bool public matchingEnabled = true; //true: enable matching,
                                         //false: revert to expiring market
    struct sortInfo {
        uint next;  //points to id of next higher offer
        uint prev;  //points to id of previous lower offer
        uint delb;  //the blocknumber where this entry was marked for delete
    }
    mapping(uint => sortInfo) public _rank;                     //doubly linked lists of sorted offer ids
    mapping(address => mapping(address => uint)) public _best;  //id of the highest offer for a token pair
    mapping(address => mapping(address => uint)) public _span;  //number of offers stored for token pair in sorted orderbook
    mapping(address => uint) public _dust;                      //minimum sell amount for a token to avoid dust offers
    mapping(uint => uint) public _near;         //next unsorted offer id
    uint _head;                                 //first unsorted offer id
    uint public dustId;                         // id of the latest offer marked as dust


    constructor(uint64 close_time) ExpiringMarket(close_time) public {
    }

    // After close, anyone can cancel an offer
    modifier can_cancel(uint id) {
        require(isActive(id), "Offer was deleted or taken, or never existed.");
        require(
            isClosed() || msg.sender == getOwner(id) || id == dustId,
            "Offer can not be cancelled because user is not owner, and market is open, and offer sells required amount of tokens."
        );
        _;
    }

    // ---- Public entrypoints ---- //

    function make(
        ERC20    pay_gem,
        ERC20    buy_gem,
        uint128  pay_amt,
        uint128  buy_amt
    )
        public
        returns (bytes32)
    {
        return bytes32(offer(pay_amt, pay_gem, buy_amt, buy_gem));
    }

    function take(bytes32 id, uint128 maxTakeAmount) public {
        require(buy(uint256(id), maxTakeAmount));
    }

    function kill(bytes32 id) public {
        require(cancel(uint256(id)));
    }

    // Make a new offer. Takes funds from the caller into market escrow.
    //
    // If matching is enabled:
    //     * creates new offer without putting it in
    //       the sorted list.
    //     * available to authorized contracts only!
    //     * keepers should call insert(id,pos)
    //       to put offer in the sorted list.
    //
    // If matching is disabled:
    //     * calls expiring market's offer().
    //     * available to everyone without authorization.
    //     * no sorting is done.
    //
    function offer(
        uint pay_amt,    //maker (ask) sell how much
        ERC20 pay_gem,   //maker (ask) sell which token
        uint buy_amt,    //taker (ask) buy how much
        ERC20 buy_gem    //taker (ask) buy which token
    )
        public
        returns (uint)
    {
        require(!locked, "Reentrancy attempt");
        function (uint256,ERC20,uint256,ERC20) returns (uint256) fn = matchingEnabled ? _offeru : super.offer;
        return fn(pay_amt, pay_gem, buy_amt, buy_gem);
    }

    // Make a new offer. Takes funds from the caller into market escrow.
    function offer(
        uint pay_amt,    //maker (ask) sell how much
        ERC20 pay_gem,   //maker (ask) sell which token
        uint buy_amt,    //maker (ask) buy how much
        ERC20 buy_gem,   //maker (ask) buy which token
        uint pos         //position to insert offer, 0 should be used if unknown
    )
        public
        can_offer
        returns (uint)
    {
        return offer(pay_amt, pay_gem, buy_amt, buy_gem, pos, true);
    }

    function offer(
        uint pay_amt,    //maker (ask) sell how much
        ERC20 pay_gem,   //maker (ask) sell which token
        uint buy_amt,    //maker (ask) buy how much
        ERC20 buy_gem,   //maker (ask) buy which token
        uint pos,        //position to insert offer, 0 should be used if unknown
        bool rounding    //match "close enough" orders?
    )
        public
        can_offer
        returns (uint)
    {
        require(!locked, "Reentrancy attempt");
        require(_dust[address(pay_gem)] <= pay_amt);

        if (matchingEnabled) {
          return _matcho(pay_amt, pay_gem, buy_amt, buy_gem, pos, rounding);
        }
        return super.offer(pay_amt, pay_gem, buy_amt, buy_gem);
    }

    //Transfers funds from caller to offer maker, and from market to caller.
    function buy(uint id, uint amount)
        public
        can_buy(id)
        returns (bool)
    {
        require(!locked, "Reentrancy attempt");
        function (uint256,uint256) returns (bool) fn = matchingEnabled ? _buys : super.buy;
        return fn(id, amount);
    }

    // Cancel an offer. Refunds offer maker.
    function cancel(uint id)
        public
        can_cancel(id)
        returns (bool success)
    {
        require(!locked, "Reentrancy attempt");
        if (matchingEnabled) {
            if (isOfferSorted(id)) {
                require(_unsort(id));
            } else {
                require(_hide(id));
            }
        }
        return super.cancel(id);    //delete the offer.
    }

    //insert offer into the sorted list
    //keepers need to use this function
    function insert(
        uint id,   //maker (ask) id
        uint pos   //position to insert into
    )
        public
        returns (bool)
    {
        require(!locked, "Reentrancy attempt");
        require(!isOfferSorted(id));    //make sure offers[id] is not yet sorted
        require(isActive(id));          //make sure offers[id] is active

        _hide(id);                      //remove offer from unsorted offers list
        _sort(id, pos);                 //put offer into the sorted offers list
        emit LogInsert(msg.sender, id);
        return true;
    }

    //deletes _rank [id]
    //  Function should be called by keepers.
    function del_rank(uint id)
        public
        returns (bool)
    {
        require(!locked, "Reentrancy attempt");
        require(!isActive(id) && _rank[id].delb != 0 && _rank[id].delb < block.number - 10);
        delete _rank[id];
        emit LogDelete(msg.sender, id);
        return true;
    }

    //set the minimum sell amount for a token
    //    Function is used to avoid "dust offers" that have
    //    very small amount of tokens to sell, and it would
    //    cost more gas to accept the offer, than the value
    //    of tokens received.
    function setMinSell(
        ERC20 pay_gem,     //token to assign minimum sell amount to
        uint dust          //maker (ask) minimum sell amount
    )
        public
        auth
        note
        returns (bool)
    {
        _dust[address(pay_gem)] = dust;
        emit LogMinSell(address(pay_gem), dust);
        return true;
    }

    //returns the minimum sell amount for an offer
    function getMinSell(
        ERC20 pay_gem      //token for which minimum sell amount is queried
    )
        public
        view
        returns (uint)
    {
        return _dust[address(pay_gem)];
    }

    //set buy functionality enabled/disabled
    function setBuyEnabled(bool buyEnabled_) public auth returns (bool) {
        buyEnabled = buyEnabled_;
        emit LogBuyEnabled(buyEnabled);
        return true;
    }

    //set matching enabled/disabled
    //    If matchingEnabled true(default), then inserted offers are matched.
    //    Except the ones inserted by contracts, because those end up
    //    in the unsorted list of offers, that must be later sorted by
    //    keepers using insert().
    //    If matchingEnabled is false then MatchingMarket is reverted to ExpiringMarket,
    //    and matching is not done, and sorted lists are disabled.
    function setMatchingEnabled(bool matchingEnabled_) public auth returns (bool) {
        matchingEnabled = matchingEnabled_;
        emit LogMatchingEnabled(matchingEnabled);
        return true;
    }

    //return the best offer for a token pair
    //      the best offer is the lowest one if it's an ask,
    //      and highest one if it's a bid offer
    function getBestOffer(ERC20 sell_gem, ERC20 buy_gem) public view returns(uint) {
        return _best[address(sell_gem)][address(buy_gem)];
    }

    //return the next worse offer in the sorted list
    //      the worse offer is the higher one if its an ask,
    //      a lower one if its a bid offer,
    //      and in both cases the newer one if they're equal.
    function getWorseOffer(uint id) public view returns(uint) {
        return _rank[id].prev;
    }

    //return the next better offer in the sorted list
    //      the better offer is in the lower priced one if its an ask,
    //      the next higher priced one if its a bid offer
    //      and in both cases the older one if they're equal.
    function getBetterOffer(uint id) public view returns(uint) {

        return _rank[id].next;
    }

    //return the amount of better offers for a token pair
    function getOfferCount(ERC20 sell_gem, ERC20 buy_gem) public view returns(uint) {
        return _span[address(sell_gem)][address(buy_gem)];
    }

    //get the first unsorted offer that was inserted by a contract
    //      Contracts can't calculate the insertion position of their offer because it is not an O(1) operation.
    //      Their offers get put in the unsorted list of offers.
    //      Keepers can calculate the insertion position offchain and pass it to the insert() function to insert
    //      the unsorted offer into the sorted list. Unsorted offers will not be matched, but can be bought with buy().
    function getFirstUnsortedOffer() public view returns(uint) {
        return _head;
    }

    //get the next unsorted offer
    //      Can be used to cycle through all the unsorted offers.
    function getNextUnsortedOffer(uint id) public view returns(uint) {
        return _near[id];
    }

    function isOfferSorted(uint id) public view returns(bool) {
        return _rank[id].next != 0
               || _rank[id].prev != 0
               || _best[address(offers[id].pay_gem)][address(offers[id].buy_gem)] == id;
    }

    function sellAllAmount(ERC20 pay_gem, uint pay_amt, ERC20 buy_gem, uint min_fill_amount)
        public
        returns (uint fill_amt)
    {
        require(!locked, "Reentrancy attempt");
        uint offerId;
        while (pay_amt > 0) {                           //while there is amount to sell
            offerId = getBestOffer(buy_gem, pay_gem);   //Get the best offer for the token pair
            require(offerId != 0);                      //Fails if there are not more offers

            // There is a chance that pay_amt is smaller than 1 wei of the other token
            if (pay_amt * 1 ether < wdiv(offers[offerId].buy_amt, offers[offerId].pay_amt)) {
                break;                                  //We consider that all amount is sold
            }
            if (pay_amt >= offers[offerId].buy_amt) {                       //If amount to sell is higher or equal than current offer amount to buy
                fill_amt = add(fill_amt, offers[offerId].pay_amt);          //Add amount bought to acumulator
                pay_amt = sub(pay_amt, offers[offerId].buy_amt);            //Decrease amount to sell
                take(bytes32(offerId), uint128(offers[offerId].pay_amt));   //We take the whole offer
            } else { // if lower
                uint256 baux = rmul(pay_amt * 10 ** 9, rdiv(offers[offerId].pay_amt, offers[offerId].buy_amt)) / 10 ** 9;
                fill_amt = add(fill_amt, baux);         //Add amount bought to acumulator
                take(bytes32(offerId), uint128(baux));  //We take the portion of the offer that we need
                pay_amt = 0;                            //All amount is sold
            }
        }
        require(fill_amt >= min_fill_amount);
    }

    function buyAllAmount(ERC20 buy_gem, uint buy_amt, ERC20 pay_gem, uint max_fill_amount)
        public
        returns (uint fill_amt)
    {
        require(!locked, "Reentrancy attempt");
        uint offerId;
        while (buy_amt > 0) {                           //Meanwhile there is amount to buy
            offerId = getBestOffer(buy_gem, pay_gem);   //Get the best offer for the token pair
            require(offerId != 0);

            // There is a chance that buy_amt is smaller than 1 wei of the other token
            if (buy_amt * 1 ether < wdiv(offers[offerId].pay_amt, offers[offerId].buy_amt)) {
                break;                                  //We consider that all amount is sold
            }
            if (buy_amt >= offers[offerId].pay_amt) {                       //If amount to buy is higher or equal than current offer amount to sell
                fill_amt = add(fill_amt, offers[offerId].buy_amt);          //Add amount sold to acumulator
                buy_amt = sub(buy_amt, offers[offerId].pay_amt);            //Decrease amount to buy
                take(bytes32(offerId), uint128(offers[offerId].pay_amt));   //We take the whole offer
            } else {                                                        //if lower
                fill_amt = add(fill_amt, rmul(buy_amt * 10 ** 9, rdiv(offers[offerId].buy_amt, offers[offerId].pay_amt)) / 10 ** 9); //Add amount sold to acumulator
                take(bytes32(offerId), uint128(buy_amt));                   //We take the portion of the offer that we need
                buy_amt = 0;                                                //All amount is bought
            }
        }
        require(fill_amt <= max_fill_amount);
    }

    function getBuyAmount(ERC20 buy_gem, ERC20 pay_gem, uint pay_amt) public view returns (uint fill_amt) {
        uint256 offerId = getBestOffer(buy_gem, pay_gem);           //Get best offer for the token pair
        while (pay_amt > offers[offerId].buy_amt) {
            fill_amt = add(fill_amt, offers[offerId].pay_amt);  //Add amount to buy accumulator
            pay_amt = sub(pay_amt, offers[offerId].buy_amt);    //Decrease amount to pay
            if (pay_amt > 0) {                                  //If we still need more offers
                offerId = getWorseOffer(offerId);               //We look for the next best offer
                require(offerId != 0);                          //Fails if there are not enough offers to complete
            }
        }
        fill_amt = add(fill_amt, rmul(pay_amt * 10 ** 9, rdiv(offers[offerId].pay_amt, offers[offerId].buy_amt)) / 10 ** 9); //Add proportional amount of last offer to buy accumulator
    }

    function getPayAmount(ERC20 pay_gem, ERC20 buy_gem, uint buy_amt) public view returns (uint fill_amt) {
        uint256 offerId = getBestOffer(buy_gem, pay_gem);           //Get best offer for the token pair
        while (buy_amt > offers[offerId].pay_amt) {
            fill_amt = add(fill_amt, offers[offerId].buy_amt);  //Add amount to pay accumulator
            buy_amt = sub(buy_amt, offers[offerId].pay_amt);    //Decrease amount to buy
            if (buy_amt > 0) {                                  //If we still need more offers
                offerId = getWorseOffer(offerId);               //We look for the next best offer
                require(offerId != 0);                          //Fails if there are not enough offers to complete
            }
        }
        fill_amt = add(fill_amt, rmul(buy_amt * 10 ** 9, rdiv(offers[offerId].buy_amt, offers[offerId].pay_amt)) / 10 ** 9); //Add proportional amount of last offer to pay accumulator
    }

    // ---- Internal Functions ---- //

    function _buys(uint id, uint amount)
        internal
        returns (bool)
    {
        require(buyEnabled);
        if (amount == offers[id].pay_amt) {
            if (isOfferSorted(id)) {
                //offers[id] must be removed from sorted list because all of it is bought
                _unsort(id);
            }else{
                _hide(id);
            }
        }
        require(super.buy(id, amount));
        // If offer has become dust during buy, we cancel it
        if (isActive(id) && offers[id].pay_amt < _dust[address(offers[id].pay_gem)]) {
            dustId = id; //enable current msg.sender to call cancel(id)
            cancel(id);
        }
        return true;
    }

    //find the id of the next higher offer after offers[id]
    function _find(uint id)
        internal
        view
        returns (uint)
    {
        require( id > 0 );

        address buy_gem = address(offers[id].buy_gem);
        address pay_gem = address(offers[id].pay_gem);
        uint top = _best[pay_gem][buy_gem];
        uint old_top = 0;

        // Find the larger-than-id order whose successor is less-than-id.
        while (top != 0 && _isPricedLtOrEq(id, top)) {
            old_top = top;
            top = _rank[top].prev;
        }
        return old_top;
    }

    //find the id of the next higher offer after offers[id]
    function _findpos(uint id, uint pos)
        internal
        view
        returns (uint)
    {
        require(id > 0);

        // Look for an active order.
        while (pos != 0 && !isActive(pos)) {
            pos = _rank[pos].prev;
        }

        if (pos == 0) {
            //if we got to the end of list without a single active offer
            return _find(id);

        } else {
            // if we did find a nearby active offer
            // Walk the order book down from there...
            if(_isPricedLtOrEq(id, pos)) {
                uint old_pos;

                // Guaranteed to run at least once because of
                // the prior if statements.
                while (pos != 0 && _isPricedLtOrEq(id, pos)) {
                    old_pos = pos;
                    pos = _rank[pos].prev;
                }
                return old_pos;

            // ...or walk it up.
            } else {
                while (pos != 0 && !_isPricedLtOrEq(id, pos)) {
                    pos = _rank[pos].next;
                }
                return pos;
            }
        }
    }

    //return true if offers[low] priced less than or equal to offers[high]
    function _isPricedLtOrEq(
        uint low,   //lower priced offer's id
        uint high   //higher priced offer's id
    )
        internal
        view
        returns (bool)
    {
        return mul(offers[low].buy_amt, offers[high].pay_amt)
          >= mul(offers[high].buy_amt, offers[low].pay_amt);
    }

    //these variables are global only because of solidity local variable limit

    //match offers with taker offer, and execute token transactions
    function _matcho(
        uint t_pay_amt,    //taker sell how much
        ERC20 t_pay_gem,   //taker sell which token
        uint t_buy_amt,    //taker buy how much
        ERC20 t_buy_gem,   //taker buy which token
        uint pos,          //position id
        bool rounding      //match "close enough" orders?
    )
        internal
        returns (uint id)
    {
        uint best_maker_id;    //highest maker id
        uint t_buy_amt_old;    //taker buy how much saved
        uint m_buy_amt;        //maker offer wants to buy this much token
        uint m_pay_amt;        //maker offer wants to sell this much token

        // there is at least one offer stored for token pair
        while (_best[address(t_buy_gem)][address(t_pay_gem)] > 0) {
            best_maker_id = _best[address(t_buy_gem)][address(t_pay_gem)];
            m_buy_amt = offers[best_maker_id].buy_amt;
            m_pay_amt = offers[best_maker_id].pay_amt;

            // Ugly hack to work around rounding errors. Based on the idea that
            // the furthest the amounts can stray from their "true" values is 1.
            // Ergo the worst case has t_pay_amt and m_pay_amt at +1 away from
            // their "correct" values and m_buy_amt and t_buy_amt at -1.
            // Since (c - 1) * (d - 1) > (a + 1) * (b + 1) is equivalent to
            // c * d > a * b + a + b + c + d, we write...
            if (mul(m_buy_amt, t_buy_amt) > mul(t_pay_amt, m_pay_amt) +
                (rounding ? m_buy_amt + t_buy_amt + t_pay_amt + m_pay_amt : 0))
            {
                break;
            }
            // ^ The `rounding` parameter is a compromise borne of a couple days
            // of discussion.
            buy(best_maker_id, min(m_pay_amt, t_buy_amt));
            t_buy_amt_old = t_buy_amt;
            t_buy_amt = sub(t_buy_amt, min(m_pay_amt, t_buy_amt));
            t_pay_amt = mul(t_buy_amt, t_pay_amt) / t_buy_amt_old;

            if (t_pay_amt == 0 || t_buy_amt == 0) {
                break;
            }
        }

        if (t_buy_amt > 0 && t_pay_amt > 0 && t_pay_amt >= _dust[address(t_pay_gem)]) {
            //new offer should be created
            id = super.offer(t_pay_amt, t_pay_gem, t_buy_amt, t_buy_gem);
            //insert offer into the sorted list
            _sort(id, pos);
        }
    }

    // Make a new offer without putting it in the sorted list.
    // Takes funds from the caller into market escrow.
    // ****Available to authorized contracts only!**********
    // Keepers should call insert(id,pos) to put offer in the sorted list.
    function _offeru(
        uint pay_amt,      //maker (ask) sell how much
        ERC20 pay_gem,     //maker (ask) sell which token
        uint buy_amt,      //maker (ask) buy how much
        ERC20 buy_gem      //maker (ask) buy which token
    )
        internal
        returns (uint id)
    {
        require(_dust[address(pay_gem)] <= pay_amt);
        id = super.offer(pay_amt, pay_gem, buy_amt, buy_gem);
        _near[id] = _head;
        _head = id;
        emit LogUnsortedOffer(id);
    }

    //put offer into the sorted list
    function _sort(
        uint id,    //maker (ask) id
        uint pos    //position to insert into
    )
        internal
    {
        require(isActive(id));

        ERC20 buy_gem = offers[id].buy_gem;
        ERC20 pay_gem = offers[id].pay_gem;
        uint prev_id;                                      //maker (ask) id

        pos = pos == 0 || offers[pos].pay_gem != pay_gem || offers[pos].buy_gem != buy_gem || !isOfferSorted(pos)
        ?
            _find(id)
        :
            _findpos(id, pos);

        if (pos != 0) {                                    //offers[id] is not the highest offer
            //requirement below is satisfied by statements above
            //require(_isPricedLtOrEq(id, pos));
            prev_id = _rank[pos].prev;
            _rank[pos].prev = id;
            _rank[id].next = pos;
        } else {                                           //offers[id] is the highest offer
            prev_id = _best[address(pay_gem)][address(buy_gem)];
            _best[address(pay_gem)][address(buy_gem)] = id;
        }

        if (prev_id != 0) {                               //if lower offer does exist
            //requirement below is satisfied by statements above
            //require(!_isPricedLtOrEq(id, prev_id));
            _rank[prev_id].next = id;
            _rank[id].prev = prev_id;
        }

        _span[address(pay_gem)][address(buy_gem)]++;
        emit LogSortedOffer(id);
    }

    // Remove offer from the sorted list (does not cancel offer)
    function _unsort(
        uint id    //id of maker (ask) offer to remove from sorted list
    )
        internal
        returns (bool)
    {
        address buy_gem = address(offers[id].buy_gem);
        address pay_gem = address(offers[id].pay_gem);
        require(_span[pay_gem][buy_gem] > 0);

        require(_rank[id].delb == 0 &&                    //assert id is in the sorted list
                 isOfferSorted(id));

        if (id != _best[pay_gem][buy_gem]) {              // offers[id] is not the highest offer
            require(_rank[_rank[id].next].prev == id);
            _rank[_rank[id].next].prev = _rank[id].prev;
        } else {                                          //offers[id] is the highest offer
            _best[pay_gem][buy_gem] = _rank[id].prev;
        }

        if (_rank[id].prev != 0) {                        //offers[id] is not the lowest offer
            require(_rank[_rank[id].prev].next == id);
            _rank[_rank[id].prev].next = _rank[id].next;
        }

        _span[pay_gem][buy_gem]--;
        _rank[id].delb = block.number;                    //mark _rank[id] for deletion
        return true;
    }

    //Hide offer from the unsorted order book (does not cancel offer)
    function _hide(
        uint id     //id of maker offer to remove from unsorted list
    )
        internal
        returns (bool)
    {
        uint uid = _head;               //id of an offer in unsorted offers list
        uint pre = uid;                 //id of previous offer in unsorted offers list

        require(!isOfferSorted(id));    //make sure offer id is not in sorted offers list

        if (_head == id) {              //check if offer is first offer in unsorted offers list
            _head = _near[id];          //set head to new first unsorted offer
            _near[id] = 0;              //delete order from unsorted order list
            return true;
        }
        while (uid > 0 && uid != id) {  //find offer in unsorted order list
            pre = uid;
            uid = _near[uid];
        }
        if (uid != id) {                //did not find offer id in unsorted offers list
            return false;
        }
        _near[pre] = _near[id];         //set previous unsorted offer to point to offer after offer id
        _near[id] = 0;                  //delete order from unsorted order list
        return true;
    }
}