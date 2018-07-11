/**
 *
 *  MIT License
 *
 *  Copyright (c) 2018 Vladimir Khramov
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the &quot;Software&quot;), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED &quot;AS IS&quot;, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
 *
 * Modified version of https://github.com/AltCoinExchange/ethatomicswap
 *
 * Original license:
 * Copyright 2017 Altcoin Exchange
 *
 * Permission to use, copy, modify, and/or distribute this software for any purpose with or
 * without fee is hereby granted, provided that the above copyright notice and this permission
 * notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED &quot;AS IS&quot; AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS
 * SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
 * AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
 * NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE
 * OF THIS SOFTWARE.
 */

pragma solidity ^0.4.15;

contract AtomicSwapRegistry {

    enum State {Empty, Initiator, Participant}

    struct Swap {
        uint initTimestamp;
        uint refundTime;
        bytes32 hashedSecret;
        string secret;
        address initiator;
        address participant;
        uint256 value;
        bool emptied;
        State state;
    }

    mapping(bytes32 => Swap) public swaps;

    event Refunded(uint _refundTime);
    event Redeemed(uint _redeemTime);
    event Participated(
        address _initiator,
        address _participator,
        bytes32 _hashedSecret,
        uint256 _value
    );
    event Initiated(
        uint _initTimestamp,
        uint _refundTime,
        bytes32 _hashedSecret,
        address _participant,
        address _initiator,
        uint256 _funds
    );


    modifier isRefundable(bytes32 _hashedSecret) {
        require(block.timestamp > swaps[_hashedSecret].initTimestamp + swaps[_hashedSecret].refundTime);
        require(swaps[_hashedSecret].emptied == false);
        _;
    }

    modifier isRedeemable(bytes32 _hashedSecret, string _secret) {
        require(sha256(_secret) == _hashedSecret);
        require(block.timestamp < swaps[_hashedSecret].initTimestamp + swaps[_hashedSecret].refundTime);
        require(swaps[_hashedSecret].emptied == false);
        _;
    }

    modifier isInitiator(bytes32 _hashedSecret) {
        require(msg.sender == swaps[_hashedSecret].initiator);
        _;
    }

    modifier isNotInitiated(bytes32 _hashedSecret) {
        require(swaps[_hashedSecret].state == State.Empty);
        _;
    }

    function initiate(address _initiator, uint _refundTime, bytes32 _hashedSecret, address _participant)
        public payable
        isNotInitiated(_hashedSecret)
    {
        swaps[_hashedSecret].refundTime = _refundTime;
        swaps[_hashedSecret].initTimestamp = block.timestamp;
        swaps[_hashedSecret].hashedSecret = _hashedSecret;
        swaps[_hashedSecret].participant = _participant;
        swaps[_hashedSecret].initiator = _initiator;
        swaps[_hashedSecret].state = State.Initiator;
        swaps[_hashedSecret].value = msg.value;
        Initiated(
            swaps[_hashedSecret].initTimestamp,
            _refundTime,
            _hashedSecret,
            _participant,
            _initiator,
            msg.value
        );
    }

    function participate(address _participant, uint _refundTime, bytes32 _hashedSecret, address _initiator)
        public payable
        isNotInitiated(_hashedSecret)
    {
        swaps[_hashedSecret].refundTime = _refundTime;
        swaps[_hashedSecret].initTimestamp = block.timestamp;
        swaps[_hashedSecret].participant = _participant;
        swaps[_hashedSecret].initiator = _initiator;
        swaps[_hashedSecret].value = msg.value;
        swaps[_hashedSecret].hashedSecret = _hashedSecret;
        swaps[_hashedSecret].state = State.Participant;
        Participated(_initiator, _participant, _hashedSecret, msg.value);
    }

    function redeem(string _secret, bytes32 _hashedSecret) public
        isRedeemable(_hashedSecret, _secret)
    {
        swaps[_hashedSecret].emptied = true;
        Redeemed(block.timestamp);
        swaps[_hashedSecret].secret = _secret;

        if (swaps[_hashedSecret].state == State.Participant) {
            swaps[_hashedSecret].initiator.transfer(swaps[_hashedSecret].value);
        } else if (swaps[_hashedSecret].state == State.Initiator) {
            swaps[_hashedSecret].participant.transfer(swaps[_hashedSecret].value);
        } else {
            revert();
        }

    }

    function refund(bytes32 _hashedSecret) public
        isRefundable(_hashedSecret)
    {
        swaps[_hashedSecret].emptied = true;
        Refunded(block.timestamp);

        if (swaps[_hashedSecret].state == State.Participant) {
            swaps[_hashedSecret].participant.transfer(swaps[_hashedSecret].value);
        } else if (swaps[_hashedSecret].state == State.Initiator) {
            swaps[_hashedSecret].initiator.transfer(swaps[_hashedSecret].value);
        } else {
            revert();
        }

    }

}

contract AtomicSwapRegistryConstructed is AtomicSwapRegistry {
    function AtomicSwapRegistryConstructed() 
        public payable 
    {
        
    }
}