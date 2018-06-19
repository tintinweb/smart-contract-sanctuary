// Copyright New Alchemy Limited, 2017. All rights reserved.
pragma solidity >=0.4.10;

// Just the bits of ERC20 that we need.
contract Token {
    function balanceOf(address addr) returns(uint);
    function transfer(address to, uint amount) returns(bool);
}

// Receiver is the contract that takes contributions
contract Receiver {
    event StartSale();
    event EndSale();
    event EtherIn(address from, uint amount);

    address public owner;    // contract owner
    address public newOwner; // new contract owner for two-way ownership handshake
    string public notice;    // arbitrary public notice text

    Sale public sale;

    function Receiver() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlySale() {
        require(msg.sender == address(sale));
        _;
    }

    function live() constant returns(bool) {
        return sale.live();
    }

    // callback from sale contract when the sale begins
    function start() onlySale {
        StartSale();
    }

    // callback from sale contract when sale ends
    function end() onlySale {
        EndSale();
    }

    function () payable {
        // forward everything to the sale contract
        EtherIn(msg.sender, msg.value);
        require(sale.call.value(msg.value)());
    }

    // 1st half of ownership change
    function changeOwner(address next) onlyOwner {
        newOwner = next;
    }

    // 2nd half of ownership change
    function acceptOwnership() {
        require(msg.sender == newOwner);
        owner = msg.sender;
        newOwner = 0;
    }

    // put some text in the contract
    function setNotice(string note) onlyOwner {
        notice = note;
    }

    // set the target sale address
    function setSale(address s) onlyOwner {
        sale = Sale(s);
    }

    // Ether gets sent to the main sale contract,
    // but tokens get sent here, so we still need
    // withdrawal methods.

    // withdraw tokens to owner
    function withdrawToken(address token) onlyOwner {
        Token t = Token(token);
        require(t.transfer(msg.sender, t.balanceOf(this)));
    }

    // refund early/late tokens
    function refundToken(address token, address sender, uint amount) onlyOwner {
        Token t = Token(token);
        require(t.transfer(sender, amount));
    }
}

contract Sale {
    // once the balance of this contract exceeds the
    // soft-cap, the sale should stay open for no more
    // than this amount of time
    uint public constant SOFTCAP_TIME = 4 hours;

    address public owner;    // contract owner
    address public newOwner; // new contract owner for two-way ownership handshake
    string public notice;    // arbitrary public notice text
    uint public start;       // start time of sale
    uint public end;         // end time of sale
    uint public cap;         // Ether hard cap
    uint public softcap;     // Ether soft cap
    bool public live;        // sale is live right now

    Receiver public r0;
    Receiver public r1;
    Receiver public r2;

    function Sale() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // tell the receivers that the sale has begun
    function emitBegin() internal {
        r0.start();
        r1.start();
        r2.start();
    }

    // tell the receivers that the sale is over
    function emitEnd() internal {
        r0.end();
        r1.end();
        r2.end();
    }

    function () payable {
        // only accept contributions from receiver contracts
        require(msg.sender == address(r0) || msg.sender == address(r1) || msg.sender == address(r2));
        require(block.timestamp >= start);

        // if we&#39;ve gone past the softcap, make sure the sale
        // stays open for no longer than SOFTCAP_TIME past the current block
        if (this.balance > softcap && block.timestamp < end && (end - block.timestamp) > SOFTCAP_TIME)
            end = block.timestamp + SOFTCAP_TIME;

        // If we&#39;ve reached end-of-sale conditions, accept
        // this as the last contribution and emit the EndSale event.
        // (Technically this means we allow exactly one contribution
        // after the end of the sale.)
        // Conversely, if we haven&#39;t started the sale yet, emit
        // the StartSale event.
        if (block.timestamp > end || this.balance > cap) {
            require(live);
            live = false;
            emitEnd();
        } else if (!live) {
            live = true;
            emitBegin();
        }
    }

    function init(uint _start, uint _end, uint _cap, uint _softcap) onlyOwner {
        start = _start;
        end = _end;
        cap = _cap;
        softcap = _softcap;
    }

    function setReceivers(address a, address b, address c) onlyOwner {
        r0 = Receiver(a);
        r1 = Receiver(b);
        r2 = Receiver(c);
    }

    // 1st half of ownership change
    function changeOwner(address next) onlyOwner {
        newOwner = next;
    }

    // 2nd half of ownership change
    function acceptOwnership() {
        require(msg.sender == newOwner);
        owner = msg.sender;
        newOwner = 0;
    }

    // put some text in the contract
    function setNotice(string note) onlyOwner {
        notice = note;
    }

    // withdraw all of the Ether
    function withdraw() onlyOwner {
        msg.sender.transfer(this.balance);
    }

    // withdraw some of the Ether
    function withdrawSome(uint value) onlyOwner {
        require(value <= this.balance);
        msg.sender.transfer(value);
    }

    // withdraw tokens to owner
    function withdrawToken(address token) onlyOwner {
        Token t = Token(token);
        require(t.transfer(msg.sender, t.balanceOf(this)));
    }

    // refund early/late tokens
    function refundToken(address token, address sender, uint amount) onlyOwner {
        Token t = Token(token);
        require(t.transfer(sender, amount));
    }
}