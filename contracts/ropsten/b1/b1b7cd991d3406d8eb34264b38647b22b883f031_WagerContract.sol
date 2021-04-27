/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

pragma solidity 0.8.4;

// Imports SafeMath library which prevents numerical overflow/underflow when using unsigned integers
library SafeMath {
	function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

// Sets the deploying wallet as the owner of the contract and creates a function to allow for ownership transfer
contract Owner {
    address public owner;

    event ownershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    modifier isOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public isOwner {
        owner = _newOwner;
        emit ownershipTransferred(msg.sender, _newOwner);
    }
}

// Creates the initial wager market data structures and creates functions allowing the creation of wager markets and wagers
contract WagerContract is Owner {
    using SafeMath for uint;

    bytes32[] private openMarkets;

    enum status {open, closed, pending, resolved}

    struct Market {
        bytes32 id;
        string title;
        address payable owner;
        uint[2] odds;
        bool outcome;
        status marketStatus;
    }

    struct Wager {
        bytes32 id;
        bytes32 marketId;
        uint[2] odds;
        address payable owner;
        uint amount;
        address payable matchOwner;
        uint matchAmount;
        bool outcome;
        status wagerStatus;
    }

    mapping(bytes32 => Market) private markets;
    mapping(bytes32 => bytes32[]) private marketWagers;
    mapping(bytes32 => Wager) private wagers;
    mapping(address => bytes32[]) private walletWagers;

    event marketCreated(bytes32 _marketId, string _eventTitle);
    event marketOwnershipChanged(bytes32 _marketId, address _oldOwner, address _newOwner);
    event marketOddsChanged(bytes32 _marketId, uint[2] _oldOdds, uint[2] _newOdds);
    event marketResolved(bytes32 _marketId, bool _marketOutcome);

    event wagerCreated(bytes32 _wagerId, bytes32 _marketId, uint _wagerAmount, bool _wagerOutcome);
    event wagerMatched(bytes32 _wagerId, bytes32 _marketId, uint _matchAmount, bool _matchOutcome);
    event wagerCancelled(bytes32 _wagerId, bytes32 _marketId);
    event wagerResolved(bytes32 _wagerId, bytes32 _marketId);

    // Common Functions

    function generateId() private view returns (bytes32) {
        return keccak256(abi.encodePacked(block.timestamp, msg.sender, block.gaslimit));
    }

    // Market Functions

    function createWagerMarket(string memory _eventTitle, uint[2] memory _marketOdds) public returns (bytes32) {
        bytes32 _marketId = generateId();
        Market memory market = Market(_marketId, _eventTitle, payable(msg.sender), _marketOdds, false, status.open);
        markets[_marketId] = market;
        openMarkets.push(market.id);
        emit marketCreated(_marketId, _eventTitle);
        return _marketId;
    }

    function transferMarketOwnership(bytes32 _marketId, address _newOwner) public {
        Market memory market = markets[_marketId];
        require(market.id != 0x0000000000000000000000000000000000000000000000000000000000000000, "No market exists with that Id");
        require(market.marketStatus == status.open, "Only active markets can be transferred");
        require(msg.sender == market.owner, "Only the market owner can transfer ownership");
        market.owner = payable(_newOwner);
        markets[_marketId] = market;
        emit marketOwnershipChanged(_marketId, msg.sender, _newOwner);
    }

    function editMarketOdds(bytes32 _marketId, uint[2] memory _newOdds) public {
        Market memory market = markets[_marketId];
        require(market.id != 0x0000000000000000000000000000000000000000000000000000000000000000, "No market exists with that Id");
        require(msg.sender == market.owner, "Only the market owner can edit odds");
        uint[2] memory _oldOdds = market.odds;
        market.odds = _newOdds;
        markets[_marketId] = market;
        emit marketOddsChanged(_marketId, _oldOdds, market.odds);
    }

    function returnOpenMarkets() public view returns (bytes32[] memory) {
        return openMarkets;
    }

    function returnMarketInfo(bytes32 _marketId) public view returns (Market memory) {
        return markets[_marketId];
    }

    function returnMarketOdds(bytes32 _marketId) public view returns (uint[2] memory) {
        Market memory market = markets[_marketId];
        require(market.id != 0x0000000000000000000000000000000000000000000000000000000000000000, "No market exists with that Id");
        return market.odds;
    }

    // Wager Functions

    function createWager(bytes32 _marketId, bool _outcome) public payable returns (bytes32) {
        Market memory market = markets[_marketId];
        require(market.id != 0x0000000000000000000000000000000000000000000000000000000000000000, "No market exists with that Id");
        require(market.marketStatus == status.open, "Wagers can only be placed on open markets");
        require(msg.value > 0, "Wager amount must be more than 0 ETH");
        bytes32 _wagerId = generateId();
        uint _matchAmount;
        if (_outcome) {
            _matchAmount = (msg.value / market.odds[1]) * market.odds[0];
        } else {
            _matchAmount = (msg.value / market.odds[0]) * market.odds[1];
        }
        Wager memory wager = Wager(_wagerId, _marketId, market.odds, payable(msg.sender), msg.value, payable(0x0000000000000000000000000000000000000000), _matchAmount, _outcome, status.open);
        wagers[_wagerId] = wager;
        bytes32[] storage wagerArray = marketWagers[_marketId];
        wagerArray.push(wager.id);
        bytes32[] storage walletWagerArray = walletWagers[msg.sender];
        walletWagerArray.push(wager.id);
        emit wagerCreated(_wagerId, _marketId, msg.value, _outcome);
        return _wagerId;
    }

    function matchWager(bytes32 _wagerId) public payable returns (bool) {
        Wager memory wager = wagers[_wagerId];
        require(wager.id != 0x0000000000000000000000000000000000000000000000000000000000000000, "No wager exists with that Id");
        require(wager.wagerStatus == status.open, "Wagers can only be matched if they are open");
        require(wager.matchOwner == 0x0000000000000000000000000000000000000000, "Wagers can only be matched if they are open");
        require(msg.sender != wager.owner, "Wagers cannot be matched by the wager owner");
        require(msg.value >= wager.matchAmount, "ETH received is less than the wager match amount");
        wager.matchOwner = payable(msg.sender);
        wager.wagerStatus = status.pending;
        wagers[_wagerId] = wager;
        bytes32[] storage walletWagerArray = walletWagers[msg.sender];
        walletWagerArray.push(wager.id);
        bytes32[] storage wagerArray = marketWagers[wager.marketId];
        for (uint8 i = 0; i < wagerArray.length; i++) {
            if (wagerArray[i] == _wagerId) {
            	wagerArray[i] = wagerArray[wagerArray.length - 1];
            	delete wagerArray[wagerArray.length - 1];
            	wagerArray.pop();
            }
        }
        emit wagerMatched(_wagerId, wager.marketId, wager.matchAmount, !wager.outcome);
        return true;
    }

    function cancelWager(bytes32 _wagerId) public returns (bool) {
        Wager memory wager = wagers[_wagerId];
        require(wager.id != 0x0000000000000000000000000000000000000000000000000000000000000000, "No wager exists with that Id");
        require(wager.wagerStatus == status.open, "Wagers can only be cancelled if they have not been matched");
        require(wager.matchOwner == 0x0000000000000000000000000000000000000000, "Wagers can only be cancelled if they have not been matched");
        require(msg.sender == wager.owner, "Wagers can only be cancelled by the wager owner");
        wager.wagerStatus = status.closed;
        wagers[_wagerId] = wager;
        wager.owner.transfer(wager.amount);
        emit wagerCancelled(wager.id, wager.marketId);
        return true;
    }

    function withdrawWinnings(bytes32 _wagerId) public returns (bool) {
        Wager memory wager = wagers[_wagerId];
        require(wager.id != 0x0000000000000000000000000000000000000000000000000000000000000000, "No wager exists with that Id");
        require(wager.wagerStatus != status.resolved, "Wager winnings have already been withdrawn");
        Market memory market = markets[wager.marketId];
        require(market.marketStatus == status.resolved, "Wager winnings can only be withdrawn if the market has been resolved");
        if (market.outcome == wager.outcome) {
            require(msg.sender == wager.owner, "Wager winnings can only be withdrawn by the winning user");
        } else {
            require(msg.sender == wager.matchOwner, "Wager winnings can only be withdrawn by the winning user");
        }
        wager.wagerStatus = status.resolved;
        wagers[_wagerId] = wager;
        payable(msg.sender).transfer((wager.amount.add(wager.matchAmount) / 100) * 99);
        market.owner.transfer(wager.amount.add(wager.matchAmount) / 100);
        emit wagerResolved(wager.id, wager.marketId);
        return true;
    }

    function returnOpenWagers(bytes32 _marketId) public view returns (bytes32[] memory) {
        return marketWagers[_marketId];
    }

    function returnWagerInfo(bytes32 _wagerId) public view returns (Wager memory) {
        return wagers[_wagerId];
    }

    function returnWalletWagers() public view returns (bytes32[] memory) {
        return walletWagers[msg.sender];
    }

    // Example Oracle Functions

    function emulateEventOutcome(bytes32 _marketId, bool _outcome) public isOwner returns (bool) {
        Market memory market = markets[_marketId];
        market.outcome = _outcome;
        market.marketStatus = status.resolved;
        markets[_marketId] = market;
        bytes32[] storage marketArray = openMarkets;
        for (uint8 i = 0; i < marketArray.length; i++) {
            if (marketArray[i] == _marketId) {
            	marketArray[i] = marketArray[marketArray.length - 1];
            	delete marketArray[marketArray.length - 1];
            	marketArray.pop();
            }
        }
        emit marketResolved(_marketId, _outcome);
        return true;
    }
}