pragma solidity ^0.5.17;

import "./MarketBase.sol";

contract MatchingEvents {
    event LogMinSell(address payGem, uint256 minAmount, address caller);
    event LogSortedOffer(uint256 id);
}

contract MatchingMarket is MatchingEvents, SimpleMarket {
    modifier can_cancel(uint256 id) {
        require(isActive(id), _T101);
        require(msg.sender == getOwner(id) || id == dustId, _S101);
        _;
    }

    // ---- Public entrypoints ---- //

    // Make a new offer. Takes funds from the caller into market escrow.
    function offer(
        uint256 payAmt, //maker (ask) sell how much
        address payGem, //maker (ask) sell which token
        uint256 buyAmt, //maker (ask) buy how much
        address buyGem, //maker (ask) buy which token
        uint256 pos, //position to insert offer, 0 should be used if unknown
        bool rounding, //match "close enough" orders?
        uint8 offerType
    ) public returns (uint256) {
        require(!_locked, _S102);
        require(dust[address(payGem)] <= payAmt, _T104);
        require(offerTypes[offerType], _T103);

        return _matcho(payAmt, payGem, buyAmt, buyGem, pos, rounding, offerType);
    }

    // Cancel an offer. Refunds offer maker.
    function cancel(uint256 id) public can_cancel(id) returns (bool success) {
        require(!_locked, _S102);
        require(_unsort(id), _T110);

        return super.cancel(id); //delete the offer.
    }

    //set the minimum sell amount for a token
    //    Function is used to avoid "dust offers" that have
    //    very small amount of tokens to sell, and it would
    //    cost more gas to accept the offer, than the value
    //    of tokens received.
    function setMinSell(
        address payGem, //token to assign minimum sell amount to
        uint256 dustAmt //maker (ask) minimum sell amount
    ) public auth returns (bool) {
        dust[address(payGem)] = dustAmt;
        emit LogMinSell(address(payGem), dustAmt, msg.sender);
        return true;
    }

    //returns the minimum sell amount for an offer
    function getMinSell(
        address payGem //token for which minimum sell amount is queried
    ) public view returns (uint256) {
        return dust[address(payGem)];
    }

    //return the best offer for a token pair
    //      the best offer is the lowest one if it's an ask,
    //      and highest one if it's a bid offer
    function getBestOffer(address sellGem, address buyGem) public view returns (uint256) {
        return best[address(sellGem)][address(buyGem)];
    }

    //return the next worse offer in the sorted list
    //      the worse offer is the higher one if its an ask,
    //      a lower one if its a bid offer,
    //      and in both cases the newer one if they're equal.
    function getWorseOffer(uint256 id) public view returns (uint256) {
        return rank[id].prev;
    }

    //return the next better offer in the sorted list
    //      the better offer is in the lower priced one if its an ask,
    //      the next higher priced one if its a bid offer
    //      and in both cases the older one if they're equal.
    function getBetterOffer(uint256 id) public view returns (uint256) {
        return rank[id].next;
    }

    //return the amount of better offers for a token pair
    function getOfferCount(address sellGem, address buyGem) public view returns (uint256) {
        return span[address(sellGem)][address(buyGem)];
    }

    function sellAllAmount(
        address payGem,
        uint256 payAmt,
        address buyGem,
        uint256 minFillAmount,
        uint8 offerType
    ) public returns (uint256 fillAmt) {
        require(!_locked, _S102);
        require(offerType == uint8(2), _T103);

        uint256 offerId;
        while (payAmt > 0) {
            //while there is amount to sell
            offerId = getBestOffer(buyGem, payGem); //Get the best offer for the token pair
            require(offerId != 0, _T108); //Fails if there are not more offers

            // There is a chance that payAmt is smaller than 1 wei of the other token
            if (payAmt * 1 ether < wdiv(offers[offerId].buyAmt, offers[offerId].payAmt)) {
                break; //We consider that all amount is sold
            }
            if (payAmt >= offers[offerId].buyAmt) {
                //If amount to sell is higher or equal than current offer amount to buy
                //Add amount bought to acumulator
                fillAmt = add(fillAmt, offers[offerId].payAmt);
                //Decrease amount to sell
                payAmt = sub(payAmt, offers[offerId].buyAmt);
                //We take the whole offer
                _take(offerId, uint128(offers[offerId].payAmt), offerType);
            } else {
                // if lower
                uint256 baux = rmul(
                    payAmt * 10**9,
                    rdiv(offers[offerId].payAmt, offers[offerId].buyAmt)
                ) / 10**9;
                //Add amount bought to acumulator
                fillAmt = add(fillAmt, baux);
                //We take the portion of the offer that we need
                _take(offerId, uint128(baux), offerType);
                payAmt = 0; //All amount is sold
            }
        }
        require(fillAmt >= minFillAmount, _T111);
    }

    function buyAllAmount(
        address buyGem,
        uint256 buyAmt,
        address payGem,
        uint256 maxFillAmount,
        uint8 offerType
    ) public returns (uint256 fillAmt) {
        require(!_locked, _S102);
        require(offerType == uint8(2), _T103);

        uint256 offerId;
        while (buyAmt > 0) {
            //Meanwhile there is amount to buy
            offerId = getBestOffer(buyGem, payGem); //Get the best offer for the token pair
            require(offerId != 0, _T108);

            // There is a chance that buyAmt is smaller than 1 wei of the other token
            if (buyAmt * 1 ether < wdiv(offers[offerId].payAmt, offers[offerId].buyAmt)) {
                break; //We consider that all amount is sold
            }
            if (buyAmt >= offers[offerId].payAmt) {
                //If amount to buy is higher or equal than current offer amount to sell
                //Add amount sold to acumulator
                fillAmt = add(fillAmt, offers[offerId].buyAmt);
                //Decrease amount to buy
                buyAmt = sub(buyAmt, offers[offerId].payAmt);
                //We take the whole offer
                _take(offerId, uint128(offers[offerId].payAmt), offerType);
            } else {
                //if lower
                fillAmt = add(
                    fillAmt,
                    rmul(buyAmt * 10**9, rdiv(offers[offerId].buyAmt, offers[offerId].payAmt)) /
                        10**9
                ); //Add amount sold to acumulator
                //We take the portion of the offer that we need
                _take(offerId, uint128(buyAmt), offerType);
                buyAmt = 0; //All amount is bought
            }
        }
        require(fillAmt <= maxFillAmount, _T112);
    }

    function getBuyAmount(
        address buyGem,
        address payGem,
        uint256 payAmt
    ) public view returns (uint256 fillAmt) {
        uint256 offerId = getBestOffer(buyGem, payGem); //Get best offer for the token pair
        while (payAmt > offers[offerId].buyAmt) {
            fillAmt = add(fillAmt, offers[offerId].payAmt); //Add amount to buy accumulator
            payAmt = sub(payAmt, offers[offerId].buyAmt); //Decrease amount to pay
            if (payAmt > 0) {
                //If we still need more offers
                offerId = getWorseOffer(offerId); //We look for the next best offer
                require(offerId != 0, _T108); //Fails if there are not enough offers to complete
            }
        }
        fillAmt = add(
            fillAmt,
            rmul(payAmt * 10**9, rdiv(offers[offerId].payAmt, offers[offerId].buyAmt)) / 10**9
        ); //Add proportional amount of last offer to buy accumulator
    }

    function getPayAmount(
        address payGem,
        address buyGem,
        uint256 buyAmt
    ) public view returns (uint256 fillAmt) {
        uint256 offerId = getBestOffer(buyGem, payGem); //Get best offer for the token pair
        while (buyAmt > offers[offerId].payAmt) {
            fillAmt = add(fillAmt, offers[offerId].buyAmt); //Add amount to pay accumulator
            buyAmt = sub(buyAmt, offers[offerId].payAmt); //Decrease amount to buy
            if (buyAmt > 0) {
                //If we still need more offers
                offerId = getWorseOffer(offerId); //We look for the next best offer
                require(offerId != 0, _T108); //Fails if there are not enough offers to complete
            }
        }
        fillAmt = add(
            fillAmt,
            rmul(buyAmt * 10**9, rdiv(offers[offerId].buyAmt, offers[offerId].payAmt)) / 10**9
        ); //Add proportional amount of last offer to pay accumulator
    }

    // ---- Internal Functions ---- //

    //Transfers funds from caller to offer maker, and from market to caller.
    function _buy(
        uint256 id,
        uint256 amount,
        uint8 offerType
    ) internal can_buy(id) returns (bool) {
        require(!_locked, _S102);

        if (amount == offers[id].payAmt) {
            //offers[id] must be removed from sorted list because all of it is bought
            _unsort(id);
        }

        require(super._buy(id, amount, offerType), _T109);
        // If offer has become dust during buy, we cancel it
        if (isActive(id) && (offers[id].payAmt < dust[address(offers[id].payGem)])) {
            dustId = id; //enable current msg.sender to call cancel(id)
            cancel(id);
        }

        return true;
    }

    function _take(
        uint256 id,
        uint128 maxTakeAmount,
        uint8 offerType
    ) internal {
        require(_buy(id, maxTakeAmount, offerType), _T109);
    }

    //find the id of the next higher offer after offers[id]
    function _find(uint256 id) internal view returns (uint256) {
        require(id > 0, _T102);

        address buyGem = address(offers[id].buyGem);
        address payGem = address(offers[id].payGem);
        uint256 top = best[payGem][buyGem];
        uint256 oldTop = 0;

        // Find the larger-than-id order whose successor is less-than-id.
        while (top != 0 && _isPricedLtOrEq(id, top)) {
            oldTop = top;
            top = rank[top].prev;
        }
        return oldTop;
    }

    //find the id of the next higher offer after offers[id]
    function _findpos(uint256 id, uint256 pos) internal view returns (uint256) {
        require(id > 0, _T102);

        // Look for an active order.
        while (pos != 0 && !isActive(pos)) {
            pos = rank[pos].prev;
        }

        if (pos == 0) {
            //if we got to the end of list without a single active offer
            return _find(id);
        } else {
            // if we did find a nearby active offer
            // Walk the order book down from there...
            if (_isPricedLtOrEq(id, pos)) {
                uint256 oldPos;

                // Guaranteed to run at least once because of
                // the prior if statements.
                while (pos != 0 && _isPricedLtOrEq(id, pos)) {
                    oldPos = pos;
                    pos = rank[pos].prev;
                }
                return oldPos;

                // ...or walk it up.
            } else {
                while (pos != 0 && !_isPricedLtOrEq(id, pos)) {
                    pos = rank[pos].next;
                }
                return pos;
            }
        }
    }

    //return true if offers[low] priced less than or equal to offers[high]
    function _isPricedLtOrEq(
        uint256 low, //lower priced offer's id
        uint256 high //higher priced offer's id
    ) internal view returns (bool) {
        return
            mul(offers[low].buyAmt, offers[high].payAmt) >=
            mul(offers[high].buyAmt, offers[low].payAmt);
    }

    //these variables are global only because of solidity local variable limit

    //match offers with taker offer, and execute token transactions
    function _matcho(
        uint256 tPayAmt, //taker sell how much
        address tPayGem, //taker sell which token
        uint256 tBuyAmt, //taker buy how much
        address tBuyGem, //taker buy which token
        uint256 pos, //position id
        bool rounding, //match "close enough" orders?
        uint8 offerType
    ) internal returns (uint256 id) {
        uint256 tPayAmtInit = tPayAmt;
        uint256 tBuyAmtOld; //taker buy how much saved
        uint256 mBuyAmt; //maker offer wants to buy this much token
        uint256 mPayAmt; //maker offer wants to sell this much token

        // Init offer history
        OfferInfoHistory memory infoHistory;
        infoHistory.payAmt = tPayAmt;
        infoHistory.payGem = tPayGem;
        infoHistory.buyAmt = tBuyAmt;
        infoHistory.buyGem = tBuyGem;
        infoHistory.owner = msg.sender;
        infoHistory.timestamp = uint64(now); // solhint-disable-line not-rely-on-time
        infoHistory.id = uint256(0);
        infoHistory.cancelled = false;
        infoHistory.filled = false;
        infoHistory.filledPayAmt = uint256(0);
        infoHistory.filledBuyAmt = uint256(0);
        infoHistory.offerType = offerType;

        // There is at least one offer stored for token pair
        // If "buy" is executed within the while loop, the sender becomes taker
        // This can happen with both market and limit order
        while (best[address(tBuyGem)][address(tPayGem)] > 0) {
            // best[address][address] gets the best maker ID
            mBuyAmt = offers[best[address(tBuyGem)][address(tPayGem)]].buyAmt;
            mPayAmt = offers[best[address(tBuyGem)][address(tPayGem)]].payAmt;

            // Ugly hack to work around rounding errors. Based on the idea that
            // the furthest the amounts can stray from their "true" values is 1.
            // Ergo the worst case has tPayAmt and mPayAmt at +1 away from
            // their "correct" values and mBuyAmt and tBuyAmt at -1.
            // Since (c - 1) * (d - 1) > (a + 1) * (b + 1) is equivalent to
            // c * d > a * b + a + b + c + d, we write...
            if (
                mul(mBuyAmt, tBuyAmt) >
                mul(tPayAmt, mPayAmt) + (rounding ? mBuyAmt + tBuyAmt + tPayAmt + mPayAmt : 0)
            ) {
                break;
            }
            // ^ The `rounding` parameter is a compromise borne of a couple days
            // of discussion.
            _buy(best[address(tBuyGem)][address(tPayGem)], min(mPayAmt, tBuyAmt), offerType);
            tBuyAmtOld = tBuyAmt;
            tBuyAmt = sub(tBuyAmt, min(mPayAmt, tBuyAmt));
            tPayAmt = mul(tBuyAmt, tPayAmt) / tBuyAmtOld;

            infoHistory.filledPayAmt = sub(tPayAmtInit, tPayAmt);
            infoHistory.filledBuyAmt = add(infoHistory.filledBuyAmt, min(mPayAmt, tBuyAmt));

            if (tPayAmt == 0 || tBuyAmt == 0) {
                infoHistory.filled = true;
                break;
            }
        }

        // offerType = 0 -> Limit Order
        // Market order never puts a new offer
        // Market order acts as Immediate-or-Cancel order,
        // and fills as much as possible, the remaining amount is cancelled
        // if there is any
        if (offerType == uint8(0)) {
            // Limit orders are given with an ID
            // Below makes the sender a maker as it sets a new offer
            if (tBuyAmt > 0 && tPayAmt > 0 && tPayAmt >= dust[address(tPayGem)]) {
                //new offer should be created
                id = _offer(tPayAmt, tPayGem, tBuyAmt, tBuyGem, uint8(0));
                //insert offer into the sorted list
                _sort(id, pos);

                offersHistoryIndices[msg.sender][id] = _nextIndex();

                infoHistory.id = id;
                offersHistory[msg.sender].push(infoHistory);
            }
        } else if (offerType == uint8(1)) {
            // offerType = 1 -> Market Order
            // Market orders are not given an ID
            // Increase the history index as we push to the array
            // But do not update offersHistoryIndices as this order
            // does not have an ID
            _nextIndex();
            offersHistory[msg.sender].push(infoHistory);
        }
    }

    //put offer into the sorted list
    function _sort(
        uint256 id, //maker (ask) id
        uint256 pos //position to insert into
    ) internal {
        require(isActive(id), _T101);

        address buyGem = offers[id].buyGem;
        address payGem = offers[id].payGem;
        uint256 prevId; //maker (ask) id

        pos = pos == 0 || offers[pos].payGem != payGem || offers[pos].buyGem != buyGem
            ? _find(id)
            : _findpos(id, pos);

        if (pos != 0) {
            //offers[id] is not the highest offer
            //requirement below is satisfied by statements above
            //require(_isPricedLtOrEq(id, pos));
            prevId = rank[pos].prev;
            rank[pos].prev = id;
            rank[id].next = pos;
        } else {
            //offers[id] is the highest offer
            prevId = best[address(payGem)][address(buyGem)];
            best[address(payGem)][address(buyGem)] = id;
        }

        if (prevId != 0) {
            //if lower offer does exist
            //requirement below is satisfied by statements above
            //require(!_isPricedLtOrEq(id, prevId));
            rank[prevId].next = id;
            rank[id].prev = prevId;
        }

        span[address(payGem)][address(buyGem)]++;
        emit LogSortedOffer(id);
    }

    // Remove offer from the sorted list (does not cancel offer)
    function _unsort(
        uint256 id //id of maker (ask) offer to remove from sorted list
    ) internal returns (bool) {
        address buyGem = address(offers[id].buyGem);
        address payGem = address(offers[id].payGem);
        require(span[payGem][buyGem] > 0 && rank[id].delb == 0, _T110);

        if (id != best[payGem][buyGem]) {
            // offers[id] is not the highest offer
            require(rank[rank[id].next].prev == id, _T110);
            rank[rank[id].next].prev = rank[id].prev;
        } else {
            //offers[id] is the highest offer
            best[payGem][buyGem] = rank[id].prev;
        }

        if (rank[id].prev != 0) {
            //offers[id] is not the lowest offer
            require(rank[rank[id].prev].next == id, _T110);
            rank[rank[id].prev].next = rank[id].next;
        }

        span[payGem][buyGem]--;
        rank[id].delb = block.number; //mark rank[id] for deletion
        return true;
    }
}