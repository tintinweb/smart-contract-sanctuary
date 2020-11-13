pragma solidity ^0.6.6;
import "./IERC721.sol";
import "./SafeMath.sol";

// What changed for V2 (June 2020 update):
// - Medium Severity Fixes:
// - Added a check on buy to prevent front-running. Needs to give currentPrice when buying.
// - Removed ability for someone to block buying through revert on ETH send. Funds get sent to a pull location.
// - Added patron check on depositWei. Since anyone can send, it can be front-run, stealing a deposit by buying before deposit clears.
// - Other Minor Changes:
// - Added past foreclosureTime() if it happened in the past.
// - Moved patron modifier checks to AFTER patronage. Thus, not necessary to have steward state anymore.
// - Removed steward state. Only check on price now. If price = zero = foreclosed. 
// - Removed paid mapping. Wasn't used.
// - Moved constructor to a function in case this is used with upgradeable contracts.
// - Changed currentCollected into a view function rather than tracking variable. This fixed a bug where CC would keep growing in between ownerships.
// - Kept the numerator/denominator code (for reference), but removed to save gas costs for 100% patronage rate.

// - Changes for UI:
// - Need to have additional current price when buying.
// - foreclosureTime() will now backdate if past foreclose time.

contract ArtSteward {
    
    /*
    This smart contract collects patronage from current owner through a Harberger tax model and 
    takes stewardship of the artwork if the patron can't pay anymore.

    Harberger Tax (COST): 
    - Artwork is always on sale.
    - You have to have a price set.
    - Tax (Patronage) is paid to maintain ownership.
    - Steward maints control over ERC721.
    */
    using SafeMath for uint256;
    
    uint256 public price; //in wei
    IERC721 public art; // ERC721 NFT.
    
    uint256 public totalCollected; // all patronage ever collected

    /* In the event that a foreclosure happens AFTER it should have been foreclosed already,
    this variable is backdated to when it should've occurred. Thus: timeHeld is accurate to actual deposit. */
    uint256 public timeLastCollected; // timestamp when last collection occurred
    uint256 public deposit; // funds for paying patronage
    address payable public artist; // beneficiary
    uint256 public artistFund; // what artist has earned and can withdraw

    /*
    If for whatever reason the transfer fails when being sold,
    it's added to a pullFunds such that previous owner can withdraw it.
    */
    mapping (address => uint256) public pullFunds; // storage area in case a sale can't send the funds towards previous owner.
    mapping (address => bool) public patrons; // list of whom have owned it
    mapping (address => uint256) public timeHeld; // time held by particular patron

    uint256 public timeAcquired; // when it is newly bought/sold
    
    // percentage patronage rate. eg 5% or 100% 
    // granular to an additionial 10 zeroes.
    uint256 patronageNumerator; 
    uint256 patronageDenominator;

    bool init;

    constructor(address payable _artist, address _artwork) public {
    //function setup(address payable _artist, address _artwork) public {
        // this is kept here in case you want to use this in an upgradeable contract
        require(init == false, "Steward already initialized.");
        // 100% patronage: only here for reference
        patronageNumerator = 1000000000000;
        patronageDenominator = 1000000000000;
        art = IERC721(_artwork);
        art.setup();
        artist = _artist;

        //sets up initial parameters for foreclosure
        _forecloseIfNecessary();

        init = true;
    }

    event LogBuy(address indexed owner, uint256 indexed price);
    event LogPriceChange(uint256 indexed newPrice);
    event LogForeclosure(address indexed prevOwner);
    event LogCollection(uint256 indexed collected);
    
    modifier onlyPatron() {
        require(msg.sender == art.ownerOf(42), "Not patron");
        _;
    }

    modifier collectPatronage() {
       _collectPatronage(); 
       _;
    }

    /* public view functions */
    /* used internally in external actions */

    // how much is owed from last collection to now.
    function patronageOwed() public view returns (uint256 patronageDue) {
        //return price.mul(now.sub(timeLastCollected)).mul(patronageNumerator).div(patronageDenominator).div(365 days);
        return price.mul(now.sub(timeLastCollected)).div(365 days);
    }

    /* not used internally in external actions */
    function patronageOwedRange(uint256 _time) public view returns (uint256 patronageDue) {
        //return price.mul(_time).mul(patronageNumerator).div(patronageDenominator).div(365 days);
        return price.mul(_time).div(365 days);
    }

    function currentCollected() public view returns (uint256 patronageDue) {
        if(timeLastCollected > timeAcquired) {
            return patronageOwedRange(timeLastCollected.sub(timeAcquired));
        } else { return 0; }
    }

    function patronageOwedWithTimestamp() public view returns (uint256 patronageDue, uint256 timestamp) {
        return (patronageOwed(), now);
    }

    function foreclosed() public view returns (bool) {
        // returns whether it is in foreclosed state or not
        // depending on whether deposit covers patronage due
        // useful helper function when price should be zero, but contract doesn't reflect it yet.
        uint256 collection = patronageOwed();
        if(collection >= deposit) {
            return true;
        } else {
            return false;
        }
    }

    // same function as above, basically
    function depositAbleToWithdraw() public view returns (uint256) {
        uint256 collection = patronageOwed();
        if(collection >= deposit) {
            return 0;
        } else {
            return deposit.sub(collection);
        }
    }

    /*
    now + deposit/patronage per second 
    now + depositAbleToWithdraw/(price*nume/denom/365).
    */
    function foreclosureTime() public view returns (uint256) {
        // patronage per second
        uint256 pps = price.mul(patronageNumerator).div(patronageDenominator).div(365 days);
        uint256 daw = depositAbleToWithdraw();
        if(daw > 0) {
            return now + depositAbleToWithdraw().div(pps);
        } else if (pps > 0) {
            // it is still active, but in foreclosure state
            // it is NOW or was in the past
            uint256 collection = patronageOwed();
            return timeLastCollected.add(((now.sub(timeLastCollected)).mul(deposit).div(collection)));
        } else {
            // not active and actively foreclosed (price is zero)
            return timeLastCollected; // it has been foreclosed or in foreclosure.
        }
    }

    /* actions */
    // determine patronage to pay
    function _collectPatronage() public {

        if (price != 0) { // price > 0 == active owned state
            uint256 collection = patronageOwed();
            
            if (collection >= deposit) { // foreclosure happened in the past

                // up to when was it actually paid for?
                // TLC + (time_elapsed)*deposit/collection
                timeLastCollected = timeLastCollected.add((now.sub(timeLastCollected)).mul(deposit).div(collection));
                collection = deposit; // take what's left.
            } else { 
                timeLastCollected = now; 
            } // normal collection

            deposit = deposit.sub(collection);
            totalCollected = totalCollected.add(collection);
            artistFund = artistFund.add(collection);
            emit LogCollection(collection);

            _forecloseIfNecessary();
        }

    }

    function buy(uint256 _newPrice, uint256 _currentPrice) public payable collectPatronage {
        /* 
            this is protection against a front-run attack.
            the person will only buy the artwork if it is what they agreed to.
            thus: someone can't buy it from under them and change the price, eating into their deposit.
        */
        require(price == _currentPrice, "Current Price incorrect");
        require(_newPrice > 0, "Price is zero");
        require(msg.value > price, "Not enough"); // >, coz need to have at least something for deposit

        address currentOwner = art.ownerOf(42);

        uint256 totalToPayBack = price.add(deposit);
        if(totalToPayBack > 0) { // this won't execute if steward owns it. price = 0. deposit = 0.
            // pay previous owner their price + deposit back.
            address payable payableCurrentOwner = address(uint160(currentOwner));
            bool transferSuccess = payableCurrentOwner.send(totalToPayBack);

            // if the send fails, keep the funds separate for the owner
            if(!transferSuccess) { pullFunds[currentOwner] = pullFunds[currentOwner].add(totalToPayBack); }
        }

        // new purchase
        timeLastCollected = now;
        
        deposit = msg.value.sub(price);
        transferArtworkTo(currentOwner, msg.sender, _newPrice);
        emit LogBuy(msg.sender, _newPrice);
    }

    /* Only Patron Actions */
    function depositWei() public payable collectPatronage onlyPatron {
        deposit = deposit.add(msg.value);
    }

    function changePrice(uint256 _newPrice) public collectPatronage onlyPatron {
        require(_newPrice > 0, 'Price is zero'); 
        price = _newPrice;
        emit LogPriceChange(price);
    }
    
    function withdrawDeposit(uint256 _wei) public collectPatronage onlyPatron {
        _withdrawDeposit(_wei);
    }

    function exit() public collectPatronage onlyPatron {
        _withdrawDeposit(deposit);
    }

    /* Actions that don't affect state of the artwork */
    /* Artist Actions */
    function withdrawArtistFunds() public {
        require(msg.sender == artist, "Not artist");
        uint256 toSend = artistFund;
        artistFund = 0;
        artist.transfer(toSend);
    }

    /* Withdrawing Stuck Deposits */
    /* To reduce complexity, pull funds are entirely separate from current deposit */
    function withdrawPullFunds() public {
        require(pullFunds[msg.sender] > 0, "No pull funds available.");
        uint256 toSend = pullFunds[msg.sender];
        pullFunds[msg.sender] = 0;
        msg.sender.transfer(toSend);
    }

    /* internal */
    function _withdrawDeposit(uint256 _wei) internal {
        // note: can withdraw whole deposit, which puts it in immediate to be foreclosed state.
        require(deposit >= _wei, 'Withdrawing too much');

        deposit = deposit.sub(_wei);
        msg.sender.transfer(_wei); // msg.sender == patron

        _forecloseIfNecessary();
    }

    function _forecloseIfNecessary() internal {
        if(deposit == 0) {
            // become steward of artwork (aka foreclose)
            address currentOwner = art.ownerOf(42);
            transferArtworkTo(currentOwner, address(this), 0);
            emit LogForeclosure(currentOwner);
        }
    }

    function transferArtworkTo(address _currentOwner, address _newOwner, uint256 _newPrice) internal {
        // note: it would also tabulate time held in stewardship by smart contract
        timeHeld[_currentOwner] = timeHeld[_currentOwner].add((timeLastCollected.sub(timeAcquired)));
        
        art.transferFrom(_currentOwner, _newOwner, 42);

        price = _newPrice;
        timeAcquired = now;
        patrons[_newOwner] = true;
    }
}