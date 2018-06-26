pragma solidity ^0.4.22;

contract Auction {

    address public owner;

    // State of the auction round. Times are in seconds since Epoch.
    uint public currentEnd;
    uint public currentBid;
    string public currentTargetUrl;
    string public currentImageUrl;
    string public currentImageTitle;
    string public currentEmail;
    address public currentLeader;

    uint public previousEnd;
    uint public previousBid;
    string public previousTargetUrl;
    string public previousImageUrl;
    string public previousImageTitle;
    string public previousEmail;
    address public previousLeader;

    // Allowed withdrawals of previous bids, global for all rounds
    mapping(address => uint) public balanceOf;

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

    function editBalanceOf(address who, uint newAmount) public {
        require(msg.sender == owner, &quot;Balances can be edited by owner only&quot;);
        balanceOf[who] = newAmount;
    }

    function editDuration(uint newDuration) public {
        require(msg.sender == owner, &quot;Auction duration can be edited by owner only&quot;);
        duration = newDuration;
    }

    function edit(
        uint _currentEnd,
        address _currentLeader,
        uint _currentBid,
        string _currentTargetUrl,
        string _currentImageUrl,
        string _currentImageTitle,
        string _currentEmail,
        uint _previousEnd,
        address _previousLeader,
        uint _previousBid,
        string _previousTargetUrl,
        string _previousImageUrl,
        string _previousImageTitle,
        string _previousEmail) public {

        previousEnd = _previousEnd;
        previousBid = _previousBid;
        previousTargetUrl = _previousTargetUrl;
        previousImageUrl = _previousImageUrl;
        previousImageTitle = _previousImageTitle;
        previousEmail = _previousEmail;
        previousLeader = _previousLeader;
        currentEnd = _currentEnd;
        currentBid = _currentBid;
        currentTargetUrl = _currentTargetUrl;
        currentImageUrl = _currentImageUrl;
        currentImageTitle = _currentImageTitle;
        currentEmail = _currentEmail;
        currentLeader = _currentLeader;
    }

    /// Bid on the auction with the value sent together with this transaction.
    function bid(string targetUrl, string imageUrl, string imageTitle, string email) public payable {

        require (!stopped, &quot;The auction is stopped.&quot;);

        restart ();

        uint amount = balanceOf[msg.sender];
        amount += msg.value;

        // If the bid is not higher, send the money back.
        require(amount > currentBid, &quot;There already is a higher bid.&quot;);

        // Save the bid for a further refund in case of a loss
        // Sending money with a simple highestBidder.send(highestBid) is
        // a security risk because it could execute an untrusted contract.
        // It is always safer to let them withdraw their money themselves.
        balanceOf[msg.sender] = amount;

        // Set the new highest bidder in current round
        currentBid = balanceOf[msg.sender];
        currentLeader = msg.sender;
        currentTargetUrl = targetUrl;
        currentImageUrl = imageUrl;
        currentImageTitle = imageTitle;
        currentEmail = email;

        emit Updated(msg.sender, amount);
    }

    /// Withdraw from contract to beneficiary (restricted to contract owner)
    function withdraw(address to, uint amount) public {

        require(msg.sender != owner, &quot;Funds can be withdrawn by the contract owner only&quot;);
        if (!to.send(amount)) {
            // do nothing
        }
    }

    /// Refund the entire bidded amount to a non-winning bidder
    function refund() public returns (bool) {

        if (!stopped) {

            // Make sure that current highest bidder is not trying
            // to withdraw his bid until the auction is stopped
            require(msg.sender != currentLeader, &quot;Funds can be refunded by non-leading bidders only.&quot;);

        }

        uint amount = balanceOf[msg.sender];
        if (amount > 0) {
            // It is important to set this to zero because the recipient
            // can call this function again as part of the receiving call
            // before `send` returns.
            balanceOf[msg.sender] = 0;
            if (!msg.sender.send(amount)) {
                // No need to call throw here, just reset the amount owing
                balanceOf[msg.sender] = amount;
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
        if (now > currentEnd) {

            balanceOf[currentLeader] = 0;

            // save the current state to the previous state
            previousEnd = currentEnd;
            previousBid = currentBid;
            previousTargetUrl = currentTargetUrl;
            previousImageUrl = currentImageUrl;
            previousImageTitle = currentImageTitle;
            previousEmail = currentEmail;
            previousLeader = currentLeader;

            currentEnd = now + duration;
            currentBid = 0;
            currentTargetUrl = &quot;&quot;;
            currentImageUrl = &quot;&quot;;
            currentImageTitle = &quot;&quot;;
            currentEmail = &quot;&quot;;
            currentLeader = 0x0;

            // broadcast the news
            emit Restarted(previousLeader, previousBid);
        }
    }
}