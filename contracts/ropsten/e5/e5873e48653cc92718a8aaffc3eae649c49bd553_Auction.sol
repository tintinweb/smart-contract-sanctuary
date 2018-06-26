pragma solidity ^0.4.22;

contract Auction {

    address public owner;

    // State of the auction round.
    struct Round {

        // Times are in seconds since Epoch.
        uint end;
        uint bid;
        string targetUrl;
        string imageUrl;
        string imageTitle;
        string email;
        address bidder;
    }

    // State of the auction.
    Round public current;
    Round public previous;

    // Allowed withdrawals of previous bids, global for all rounds
    mapping(address => uint) bids;

    // Set to true at the end, disallows any change
    bool stopped;

    uint public duration = 10 * 1 minutes;

    // ------------------------------------------------------------------------
    // Events that will be fired on changes.

    event Updated(address bidder, uint amount);
    event Started();
    event Stopped();
    event Restarted(address winner, uint amount);

    // ------------------------------------------------------------------------
    // public functions

    // The following is a so-called natspec comment, recognizable by the three slashes.
    // It will be shown when the user is asked to confirm a transaction.

    /// Create a simple auction with msg.sender as beneficiary
    constructor() public {
        owner = msg.sender;
    }

    /// Bid on the auction with the value sent together with this transaction.
    /// The value will only be refunded if the auction is not won.
    function bid(string targetUrl, string imageUrl, string imageTitle, string email) public payable {

        require (!stopped, &quot;The auction is stopped.&quot;);

        restart ();

        // If the bid is not higher, send the money back.
        require(msg.value > current.bid, &quot;There already is a higher bid.&quot;);

        // Save the bid for a further refund in case of a loss
        // Sending money with a simple highestBidder.send(highestBid) is
        // a security risk because it could execute an untrusted contract.
        // It is always safer to let them withdraw their money themselves.
        bids[msg.sender] += msg.value;

        // Set the new highest bidder in current round
        current.bid = bids[msg.sender];
        current.bidder = msg.sender;
        current.targetUrl = targetUrl;
        current.imageUrl = imageUrl;
        current.imageTitle = imageTitle;
        current.email = email;
        current.bidder = msg.sender;

        emit Updated(msg.sender, msg.value);
    }

    function withdraw(address to, uint amount) public {

        require (msg.sender != owner, &quot;Funds can be withdrawn by the contract owner only&quot;);
        if (!to.send(amount)) {
            // do nothing
        }
    }

    /// Withdraw a bid that was overbid.
    function refund() public returns (bool) {

        if (!stopped) {

            // Make sure that current highest bidder is not trying
            // to withdraw his bid until the auction is stopped
            require(msg.sender != current.bidder, &quot;Funds can be refunded by non-leading bidders only.&quot;);

        }

        uint amount = bids[msg.sender];
        if (amount > 0) {
            // It is important to set this to zero because the recipient
            // can call this function again as part of the receiving call
            // before `send` returns.
            bids[msg.sender] = 0;
            if (!msg.sender.send(amount)) {
                // No need to call throw here, just reset the amount owing
                bids[msg.sender] = amount;
                return false;
            }
        }

        return true;
    }

    function start() public {

        require(msg.sender == owner, &quot;Auction can be started by owner only.&quot;);
        require(stopped, &quot;Auction has already been started.&quot;);
        stopped = false;
        restart ();
        emit Started();
    }

    function stop() public {

        require(msg.sender == owner, &quot;Auction can be stopped by owner only.&quot;);
        require(!stopped, &quot;Auction has already been stopped.&quot;);
        stopped = true;
        emit Stopped();
    }

    function update() public {
        require(msg.sender == owner, &quot;Auction can be updated by owner only.&quot;);
        require(!stopped, &quot;Auction has been stopped.&quot;);
        restart ();
    }

    // ------------------------------------------------------------------------
    // Internal functions

    function restart () internal {

        // if it&#39;s time to start a new round, then do it
        if (now > current.end) {

            // save the current state to the previous state
            previous = current;

            // create new current state
            current = Round ({
                end: now + duration,
                bid: 0,
                targetUrl: &quot;&quot;,
                imageUrl: &quot;&quot;,
                imageTitle: &quot;&quot;,
                email: &quot;&quot;,
                bidder: 0x0
            });

            // broadcast the news
            emit Restarted(previous.bidder, previous.bid);
        }
    }
}