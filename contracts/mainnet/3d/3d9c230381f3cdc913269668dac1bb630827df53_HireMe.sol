pragma solidity 0.4.19;
// The frontend for this smart contract is a dApp hosted at
// https://hire.kohweijie.com
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


// The frontend for this smart contract is a dApp hosted at
// https://hire.kohweijie.com
contract HireMe is Ownable {
    struct Bid { // Data structure representing an individual bid
        bool exists;         // 0. Whether the bid exists
        uint id;             // 1. The ID of the bid.
        uint timestamp;      // 2. The timestamp of when the bid was made
        address bidder;      // 3. The address of the bidder
        uint amount;         // 4. The amount of ETH in the bid
        string email;        // 5. The bidder&#39;s email address
        string organisation; // 6. The bidder&#39;s organisation
    }

    event BidMade(uint indexed id, address indexed bidder, uint indexed amount);
    event Reclaimed(address indexed bidder, uint indexed amount);
    event Donated(uint indexed amount);

    Bid[] public bids; // Array of all bids
    uint[] public bidIds; // Array of all bid IDs

    // Constants which govern the bid prices and auction duration
    uint private constant MIN_BID = 1 ether;
    uint private constant BID_STEP = 0.01 ether;
    uint private constant INITIAL_BIDS = 4;

    uint private constant EXPIRY_DAYS_BEFORE = 7 days;
    uint private constant EXPIRY_DAYS_AFTER = 3 days;

    // For development only
    //uint private constant EXPIRY_DAYS_BEFORE = 10 minutes;
    //uint private constant EXPIRY_DAYS_AFTER = 10 minutes;

    // SHA256 checksum of https://github.com/weijiekoh/hireme/blob/master/AUTHOR.asc
    // See the bottom of this file for the contents of AUTHOR.asc
    string public constant AUTHORSIGHASH = "8c8b82a2d83a33cb0f45f5f6b22b45c1955f08fc54e7ab4d9e76fb76843c4918";

    // Whether the donate() function has been called
    bool public donated = false;

    // Whether the manuallyEndAuction() function has been called
    bool public manuallyEnded = false;

    // Tracks the total amount of ETH currently residing in the contract
    // balance per address.
    mapping (address => uint) public addressBalance;

    // The Internet Archive&#39;s ETH donation address
    address public charityAddress = 0x635599b0ab4b5c6B1392e0a2D1d69cF7d1ddDF02;

    // Only the contract owner may end this contract, and may do so only if
    // there are 0 bids.
    function manuallyEndAuction () public onlyOwner {
        require(manuallyEnded == false);
        require(bids.length == 0);

        manuallyEnded = true;
    }

    // Place a bid.
    function bid(string _email, string _organisation) public payable {
        address _bidder = msg.sender;
        uint _amount = msg.value;
        uint _id = bids.length;

        // The auction must not be over
        require(!hasExpired() && !manuallyEnded);

        // The bidder must be neither the contract owner nor the charity
        // donation address
        require(_bidder != owner && _bidder != charityAddress);

        // The bidder address, email, and organisation must valid
        require(_bidder != address(0));
        require(bytes(_email).length > 0);
        require(bytes(_organisation).length > 0);

        // Make sure the amount bid is more than the rolling minimum bid
        require(_amount >= calcCurrentMinBid());

        // Update the state with the new bid
        bids.push(Bid(true, _id, now, _bidder, _amount, _email, _organisation));
        bidIds.push(_id);

        // Add to, not replace, the state variable which tracks the total
        // amount paid per address, because a bidder may make multiple bids
        addressBalance[_bidder] = SafeMath.add(addressBalance[_bidder], _amount);

        // Emit the event
        BidMade(_id, _bidder, _amount);
    }

    function reclaim () public {
        address _caller = msg.sender;
        uint _amount = calcAmtReclaimable(_caller);

        // There must be at least 2 bids. Note that if there is only 1 bid and
        // that bid is the winning bid, it cannot be reclaimed.
        require(bids.length >= 2);

        // The auction must not have been manually ended
        require(!manuallyEnded);

        // Make sure the amount to reclaim is more than 0
        require(_amount > 0);

        // Subtract the amount to be reclaimed from the state variable which
        // tracks the total amount paid per address
        uint _newTotal = SafeMath.sub(addressBalance[_caller], _amount);

        // The amount must not be negative, or the contract is buggy
        assert(_newTotal >= 0);

        // Update the state to prevent double-spending
        addressBalance[_caller] = _newTotal;

        // Make the transfer
        _caller.transfer(_amount);

        // Emit the event
        Reclaimed(_caller, _amount);
    }

    function donate () public {
        // donate() can only be called once
        assert(donated == false);

        // Only the contract owner or the charity address may send the funds to
        // charityAddress
        require(msg.sender == owner || msg.sender == charityAddress);

        // The auction must be over
        require(hasExpired());

        // If the auction has been manually ended at this point, the contract
        // is buggy
        assert(!manuallyEnded);

        // There must be at least 1 bid, or the contract is buggy
        assert(bids.length > 0);

        // Calculate the amount to donate
        uint _amount;
        if (bids.length == 1) {
            // If there is only 1 bid, transfer that amount
            _amount = bids[0].amount;
        } else {
            // If there is more than 1 bid, transfer the second highest bid
            _amount = bids[SafeMath.sub(bids.length, 2)].amount;
        }

        // The amount to be donated must be more than 0, or this contract is
        // buggy
        assert(_amount > 0);

        // Prevent double-donating
        donated = true;

        // Transfer the winning bid amount to charity
        charityAddress.transfer(_amount);
        Donated(_amount);
    }

    function calcCurrentMinBid () public view returns (uint) {
        if (bids.length == 0) {
            return MIN_BID;
        } else {
            uint _lastBidId = SafeMath.sub(bids.length, 1);
            uint _lastBidAmt = bids[_lastBidId].amount;
            return SafeMath.add(_lastBidAmt, BID_STEP);
        }
    }

    function calcAmtReclaimable (address _bidder) public view returns (uint) {
        // This function calculates the amount that _bidder can get back.

        // A. if the auction is over, and _bidder is the winner, they should
        // get back the total amount bid minus the second highest bid.

        // B. if the auction is not over, and _bidder is not the current
        // winner, they should get back the total they had bid

        // C. if the auction is ongoing, and _bidder is the current winner,
        // they should get back the total amount they had bid minus the top
        // bid.

        // D. if the auction is ongoing, and _bidder is not the current winner,
        // they should get back the total amount they had bid.

        uint _totalAmt = addressBalance[_bidder];

        if (bids.length == 0) {
            return 0;
        }

        if (bids[SafeMath.sub(bids.length, 1)].bidder == _bidder) {
            // If the bidder is the current winner
            if (hasExpired()) { // scenario A
                uint _secondPrice = bids[SafeMath.sub(bids.length, 2)].amount;
                return SafeMath.sub(_totalAmt, _secondPrice);

            } else { // scenario C
                uint _highestPrice = bids[SafeMath.sub(bids.length, 1)].amount;
                return SafeMath.sub(_totalAmt, _highestPrice);
            }

        } else { // scenarios B and D
            // If the bidder is not the current winner
            return _totalAmt;
        }
    }

    function getBidIds () public view returns (uint[]) {
        return bidIds;
    }

    // Calcuate the timestamp after which the auction will expire
    function expiryTimestamp () public view returns (uint) {
        uint _numBids = bids.length;

        // There is no expiry if there are no bids
        require(_numBids > 0);

        // The timestamp of the most recent bid
        uint _lastBidTimestamp = bids[SafeMath.sub(_numBids, 1)].timestamp;

        if (_numBids <= INITIAL_BIDS) {
            return SafeMath.add(_lastBidTimestamp, EXPIRY_DAYS_BEFORE);
        } else {
            return SafeMath.add(_lastBidTimestamp, EXPIRY_DAYS_AFTER);
        }
    }

    function hasExpired () public view returns (bool) {
        uint _numBids = bids.length;

        // The auction cannot expire if there are no bids
        if (_numBids == 0) {
            return false;
        } else {
            // Compare with the current time
            return now >= this.expiryTimestamp();
        }
    }
}


// Contents of AUTHOR.asc and AUTHOR (remove the backslashes which preface each
// line)

// AUTHOR.asc:
//-----BEGIN PGP SIGNATURE-----
//
//iQIzBAABCAAdBQJak6eBFhxjb250YWN0QGtvaHdlaWppZS5jb20ACgkQkNtDYXzM
//FjKytA/+JF75jH+d/9nEitJKRcsrFgadVjMwNjUt1B7IvoZJqpHj9BSHtKhsVEI5
//iME24rgbr3YRXLi7GbQS+Ovyf3Ks7BHCA/t12PWOVm9zRBEswojZIg1UjTqtYboS
//0xrnrY8A71g1RX/jN4uCQ9FohRMAPzTTV9Gt6XDpB9Uzk0HBkUOpVHPnqxSerzbp
//fSwTCzLgcsTKUJYfeOQMuSwTTXc/btJss82WQpK76xdi5+4hp3tjyZZuY7ruj60N
//g9f9pHafsWRujMhmX0G8btjK/7/cJL/KbFFafb3sA7Xes0uoUbs+pQXTvuMBx2g5
//1/BH63aHXdZC2/767JyR18gZN6PnwsZt7i8CowvDcGMni5f0la4O53HCZEGaHYFf
//IKnJX4LhEJEezcflqSgxm1y7hlUFqC1T7janL0s4rCxoW7iPgNlii62vSzg0TTwH
//9L6v8aYwWgAwfma2o3XWMCjA/K/BIfWd2w+1ex/gvTVCefOxz1zEPdjhWh89fopb
//ydxV4fllXLXoB2wmv305E4eryq4lX40w9WxO7Dxq3yU+fmK8BaXLsjUf4fT9AU1m
//VEo3ndjFXkSELwqTQalxod41j4rYxS6SyxOj6R3/3ejbJIL0kzwKuDlZIkj8Xsfx
//o2b+QtKANMwC2KRZQBnNdnF2XVOCEFW1XZykWPW6FR1iYS6WEJ0=
//=J3JJ
//-----END PGP SIGNATURE-----

// AUTHOR:
//Koh Wei Jie <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="c3a0acadb7a2a0b783a8acabb4a6aaa9aaa6eda0acae">[email&#160;protected]</a>>