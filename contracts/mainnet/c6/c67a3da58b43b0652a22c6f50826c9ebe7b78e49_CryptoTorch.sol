// CryptoTorch Source code
// copyright 2018 CryptoTorch <https://cryptotorch.io>

pragma solidity 0.4.19;


/**
 * @title SafeMath
 * Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * Multiplies two numbers, throws on overflow.
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
    * Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


/**
* @title Ownable
 *
 * Owner rights:
 *   - change the name of the contract
 *   - change the name of the token
 *   - change the Proof of Stake difficulty
 *   - pause/unpause the contract
 *   - transfer ownership
 *
 * Owner CANNOT:
 *   - withdrawal funds
 *   - disable withdrawals
 *   - kill the contract
 *   - change the price of tokens
*/
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


/**
 * @title Pausable
 *
 * Pausing the contract will only disable deposits,
 * it will not prevent player dividend withdraws or token sales
 */
contract Pausable is Ownable {
    event OnPause();
    event OnUnpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() public onlyOwner whenNotPaused {
        paused = true;
        OnPause();
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
        OnUnpause();
    }
}


/**
* @title ReentrancyGuard
* Helps contracts guard against reentrancy attacks.
* @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="cbb9aea6a8a48bf9">[email&#160;protected]</a>π.com>
*/
contract ReentrancyGuard {
    bool private reentrancyLock = false;

    modifier nonReentrant() {
        require(!reentrancyLock);
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }
}


/**
 * DateTime Contract Interface
 * see https://github.com/pipermerriam/ethereum-datetime
 * Live Contract Address: 0x1a6184CD4C5Bea62B0116de7962EE7315B7bcBce
 */
contract DateTime {
    function getMonth(uint timestamp) public pure returns (uint8);
    function getDay(uint timestamp) public pure returns (uint8);
}


/**
 * OwnTheDay Contract Interface
 */
contract OwnTheDayContract {
    function ownerOf(uint256 _tokenId) public view returns (address);
}


/**
 * @title CryptoTorchToken
 */
contract CryptoTorchToken {
    function contractBalance() public view returns (uint256);
    function totalSupply() public view returns(uint256);
    function balanceOf(address _playerAddress) public view returns(uint256);
    function dividendsOf(address _playerAddress) public view returns(uint256);
    function profitsOf(address _playerAddress) public view returns(uint256);
    function referralBalanceOf(address _playerAddress) public view returns(uint256);
    function sellPrice() public view returns(uint256);
    function buyPrice() public view returns(uint256);
    function calculateTokensReceived(uint256 _etherToSpend) public view returns(uint256);
    function calculateEtherReceived(uint256 _tokensToSell) public view returns(uint256);

    function sellFor(address _for, uint256 _amountOfTokens) public;
    function withdrawFor(address _for) public;
    function mint(address _to, uint256 _amountForTokens, address _referredBy) public payable returns(uint256);
}


/**
 * @title Crypto-Torch Contract
 */
contract CryptoTorch is Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    //
    // Events
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //
    event onTorchPassed(
        address indexed from,
        address indexed to,
        uint256 pricePaid
    );

    //
    // Types
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //
    struct HighPrice {
        uint256 price;
        address owner;
    }

    struct HighMileage {
        uint256 miles;
        address owner;
    }

    struct PlayerData {
        string name;
        string note;
        string coords;
        uint256 dividends; // earnings waiting to be paid out
        uint256 profits;   // earnings already paid out
        bool champion;     // ran the torch while owning the day?
    }

    //
    // Payout Structure
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //
    //  Dev Fee               - 5%
    //  Token Pool            - 75%
    //    - Referral                - 10%
    //  Remaining             - 20%
    //    - Day Owner               - 10-25%
    //    - Remaining               - 75-90%
    //        - Last Runner             - 60%
    //        - Second Last Runner      - 30%
    //        - Third Last Runner       - 10%
    //

    //
    // Player Data
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //
    uint8 public constant maxLeaders = 3; // Gold, Silver, Bronze

    uint256 private _lowestHighPrice;
    uint256 private _lowestHighMiles;
    uint256 public whaleIncreaseLimit = 2 ether;
    uint256 public whaleMax = 20 ether;

    HighPrice[maxLeaders] private _highestPrices;
    HighMileage[maxLeaders] private _highestMiles;

    address[maxLeaders] public torchRunners;
    address internal donationsReceiver_;
    mapping (address => PlayerData) private playerData_;

    DateTime internal DateTimeLib_;
    CryptoTorchToken internal CryptoTorchToken_;
    OwnTheDayContract internal OwnTheDayContract_;
    string[3] internal holidayMap_;

    //
    // Modifiers
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //
    // ensures that the first tokens in the contract will be equally distributed
    // meaning, no divine dump will be possible
    modifier antiWhalePrice(uint256 _amount) {
        require(
            whaleIncreaseLimit == 0 ||
            (
                _amount <= (whaleIncreaseLimit.add(_highestPrices[0].price)) &&
                playerData_[msg.sender].dividends.add(playerData_[msg.sender].profits).add(_amount) <= whaleMax
            )
        );
        _;
    }

    //
    // Contract Initialization
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //
    /**
     * Set the Owner to the First Torch Runner
     */
    function CryptoTorch() public {
        torchRunners[0] = msg.sender;
    }

    /**
     * Initializes the Contract Dependencies as well as the Holiday Mapping for OwnTheDay.io
     */
    function initialize(address _dateTimeAddress, address _tokenAddress, address _otdAddress) public onlyOwner {
        DateTimeLib_ = DateTime(_dateTimeAddress);
        CryptoTorchToken_ = CryptoTorchToken(_tokenAddress);
        OwnTheDayContract_ = OwnTheDayContract(_otdAddress);
        holidayMap_[0] = "10000110000001100000000000000101100000000011101000000000000011000000000000001001000010000101100010100110000100001000110000";
        holidayMap_[1] = "10111000100101000111000000100100000100010001001000100000000010010000000001000000110000000000000100000000010001100001100000";
        holidayMap_[2] = "01000000000100000101011000000110000001100000000100000000000011100001000100000000101000000000100000000000000000010011000001";
    }

    /**
     * Sets the external contract address of the DateTime Library
     */
    function setDateTimeLib(address _dateTimeAddress) public onlyOwner {
        DateTimeLib_ = DateTime(_dateTimeAddress);
    }

    /**
     * Sets the external contract address of the Token Contract
     */
    function setTokenContract(address _tokenAddress) public onlyOwner {
        CryptoTorchToken_ = CryptoTorchToken(_tokenAddress);
    }

    /**
     * Sets the external contract address of OwnTheDay.io
     */
    function setOwnTheDayContract(address _otdAddress) public onlyOwner {
        OwnTheDayContract_ = OwnTheDayContract(_otdAddress);
    }

    /**
     * Set the Contract Donations Receiver
     */
    function setDonationsReceiver(address _receiver) public onlyOwner {
        donationsReceiver_ = _receiver;
    }

    /**
     * The Max Price-Paid Limit for Whales during the Anti-Whale Phase
     */
    function setWhaleMax(uint256 _max) public onlyOwner {
        whaleMax = _max;
    }

    /**
     * The Max Price-Increase Limit for Whales during the Anti-Whale Phase
     */
    function setWhaleIncreaseLimit(uint256 _limit) public onlyOwner {
        whaleIncreaseLimit = _limit;
    }

    /**
     * Updates the Holiday Mappings in case of updates/changes at OwnTheDay.io
     */
    function updateHolidayState(uint8 _listIndex, string _holidayMap) public onlyOwner {
        require(_listIndex >= 0 && _listIndex < 3);
        holidayMap_[_listIndex] = _holidayMap;
    }

    //
    // Public Functions
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //
    /**
     * Checks if a specific day is a holiday at OwnTheDay.io
     */
    function isHoliday(uint256 _dayIndex) public view returns (bool) {
        require(_dayIndex >= 0 && _dayIndex < 366);
        return (getHolidayByIndex_(_dayIndex) == 1);
    }

    /**
     * Checks if Today is a holiday at OwnTheDay.io
     */
    function isHolidayToday() public view returns (bool) {
        uint256 _dayIndex = getDayIndex_(now);
        return (getHolidayByIndex_(_dayIndex) == 1);
    }

    /**
     * Gets the Day-Index of Today at OwnTheDay.io
     */
    function getTodayIndex() public view returns (uint256) {
        return getDayIndex_(now);
    }

    /**
     * Gets the Owner Name of the Day at OwnTheDay.io
     */
    function getTodayOwnerName() public view returns (string) {
        address dayOwner = OwnTheDayContract_.ownerOf(getTodayIndex());
        return playerData_[dayOwner].name; // Get Name from THIS contract
    }

    /**
     * Gets the Owner Address of the Day at OwnTheDay.io
     */
    function getTodayOwnerAddress() public view returns (address) {
        return OwnTheDayContract_.ownerOf(getTodayIndex());
    }

    /**
     * Sets the Nickname for an Account Address
     */
    function setAccountNickname(string _nickname) public whenNotPaused {
        require(msg.sender != address(0));
        require(bytes(_nickname).length > 0);
        playerData_[msg.sender].name = _nickname;
    }

    /**
     * Gets the Nickname for an Account Address
     */
    function getAccountNickname(address _playerAddress) public view returns (string) {
        return playerData_[_playerAddress].name;
    }

    /**
     * Sets the Note for an Account Address
     */
    function setAccountNote(string _note) public whenNotPaused {
        require(msg.sender != address(0));
        playerData_[msg.sender].note = _note;
    }

    /**
     * Gets the Note for an Account Address
     */
    function getAccountNote(address _playerAddress) public view returns (string) {
        return playerData_[_playerAddress].note;
    }

    /**
     * Sets the Note for an Account Address
     */
    function setAccountCoords(string _coords) public whenNotPaused {
        require(msg.sender != address(0));
        playerData_[msg.sender].coords = _coords;
    }

    /**
     * Gets the Note for an Account Address
     */
    function getAccountCoords(address _playerAddress) public view returns (string) {
        return playerData_[_playerAddress].coords;
    }

    /**
     * Gets the Note for an Account Address
     */
    function isChampionAccount(address _playerAddress) public view returns (bool) {
        return playerData_[_playerAddress].champion;
    }

    /**
     * Take the Torch!
     *  The Purchase Price is Paid to the Previous Torch Holder, and is also used
     *  as the Purchasers Mileage Multiplier
     */
    function takeTheTorch(address _referredBy) public nonReentrant whenNotPaused payable {
        takeTheTorch_(msg.value, msg.sender, _referredBy);
    }

    /**
     * Do not make payments directly to this contract (unless it is a donation! :)
     *  - payments made directly to the contract do not receive tokens.  Tokens
     *    are only available via "takeTheTorch()" or through the Dapp at https://cryptotorch.io
     */
    function() payable public {
        if (msg.value > 0 && donationsReceiver_ != 0x0) {
            donationsReceiver_.transfer(msg.value); // donations?  Thank you!  :)
        }
    }

    /**
     * Sell some tokens for Ether
     */
    function sell(uint256 _amountOfTokens) public {
        CryptoTorchToken_.sellFor(msg.sender, _amountOfTokens);
    }

    /**
     * Withdraw the earned Dividends to Ether
     *  - Includes Torch + Token Dividends and Token Referral Bonuses
     */
    function withdrawDividends() public returns (uint256) {
        CryptoTorchToken_.withdrawFor(msg.sender);
        return withdrawFor_(msg.sender);
    }

    //
    // Helper Functions
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //
    /**
     * View the total balance of this contract
     */
    function torchContractBalance() public view returns (uint256) {
        return this.balance;
    }

    /**
     * View the total balance of the token contract
     */
    function tokenContractBalance() public view returns (uint256) {
        return CryptoTorchToken_.contractBalance();
    }

    /**
     * Retrieve the total token supply.
     */
    function totalSupply() public view returns(uint256) {
        return CryptoTorchToken_.totalSupply();
    }

    /**
     * Retrieve the token balance of any single address.
     */
    function balanceOf(address _playerAddress) public view returns(uint256) {
        return CryptoTorchToken_.balanceOf(_playerAddress);
    }

    /**
     * Retrieve the token dividend balance of any single address.
     */
    function tokenDividendsOf(address _playerAddress) public view returns(uint256) {
        return CryptoTorchToken_.dividendsOf(_playerAddress);
    }

    /**
     * Retrieve the referral dividend balance of any single address.
     */
    function referralDividendsOf(address _playerAddress) public view returns(uint256) {
        return CryptoTorchToken_.referralBalanceOf(_playerAddress);
    }

    /**
     * Retrieve the dividend balance of any single address.
     */
    function torchDividendsOf(address _playerAddress) public view returns(uint256) {
        return playerData_[_playerAddress].dividends;
    }

    /**
     * Retrieve the dividend balance of any single address.
     */
    function profitsOf(address _playerAddress) public view returns(uint256) {
        return playerData_[_playerAddress].profits.add(CryptoTorchToken_.profitsOf(_playerAddress));
    }

    /**
     * Return the sell price of 1 individual token.
     */
    function sellPrice() public view returns(uint256) {
        return CryptoTorchToken_.sellPrice();
    }

    /**
     * Return the buy price of 1 individual token.
     */
    function buyPrice() public view returns(uint256) {
        return CryptoTorchToken_.buyPrice();
    }

    /**
     * Function for the frontend to dynamically retrieve the price scaling of buy orders.
     */
    function calculateTokensReceived(uint256 _etherToSpend) public view returns(uint256) {
        uint256 forTokens = _etherToSpend.sub(_etherToSpend.div(4));
        return CryptoTorchToken_.calculateTokensReceived(forTokens);
    }

    /**
     * Function for the frontend to dynamically retrieve the price scaling of sell orders.
     */
    function calculateEtherReceived(uint256 _tokensToSell) public view returns(uint256) {
        return CryptoTorchToken_.calculateEtherReceived(_tokensToSell);
    }

    /**
     * Get the Max Price of the Torch during the Anti-Whale Phase
     */
    function getMaxPrice() public view returns (uint256) {
        if (whaleIncreaseLimit == 0) { return 0; }  // no max price
        return whaleIncreaseLimit.add(_highestPrices[0].price);
    }

    /**
     * Get the Highest Price per each Medal Leader
     */
    function getHighestPriceAt(uint _index) public view returns (uint256) {
        require(_index >= 0 && _index < maxLeaders);
        return _highestPrices[_index].price;
    }

    /**
     * Get the Highest Price Owner per each Medal Leader
     */
    function getHighestPriceOwnerAt(uint _index) public view returns (address) {
        require(_index >= 0 && _index < maxLeaders);
        return _highestPrices[_index].owner;
    }

    /**
     * Get the Highest Miles per each Medal Leader
     */
    function getHighestMilesAt(uint _index) public view returns (uint256) {
        require(_index >= 0 && _index < maxLeaders);
        return _highestMiles[_index].miles;
    }

    /**
     * Get the Highest Miles Owner per each Medal Leader
     */
    function getHighestMilesOwnerAt(uint _index) public view returns (address) {
        require(_index >= 0 && _index < maxLeaders);
        return _highestMiles[_index].owner;
    }

    //
    // Internal Functions
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //
    /**
     * Take the Torch!  And receive KMS Tokens!
     */
    function takeTheTorch_(uint256 _amountPaid, address _takenBy, address _referredBy) internal antiWhalePrice(_amountPaid) returns (uint256) {
        require(_takenBy != address(0));
        require(_amountPaid >= 5 finney);
        require(_takenBy != torchRunners[0]); // Torch must be passed on
        if (_referredBy == address(this)) { _referredBy = address(0); }

        // Pass the Torch
        address previousLast = torchRunners[2];
        torchRunners[2] = torchRunners[1];
        torchRunners[1] = torchRunners[0];
        torchRunners[0] = _takenBy;

        // Get the Current Day Owner at OwnTheDay
        address dayOwner = OwnTheDayContract_.ownerOf(getDayIndex_(now));

        // Calculate Portions
        uint256 forDev = _amountPaid.mul(5).div(100);
        uint256 forTokens = _amountPaid.sub(_amountPaid.div(4));
        uint256 forPayout = _amountPaid.sub(forDev).sub(forTokens);
        uint256 forDayOwner = calculateDayOwnerCut_(forPayout);
        if (dayOwner == _takenBy) {
            forTokens = forTokens.add(forDayOwner);
            forPayout = _amountPaid.sub(forDev).sub(forTokens);
            playerData_[_takenBy].champion = true;
        } else {
            forPayout = forPayout.sub(forDayOwner);
        }

        // Fire Events
        onTorchPassed(torchRunners[1], _takenBy, _amountPaid);

        // Grant Mileage Tokens to Torch Holder
        uint256 mintedTokens = CryptoTorchToken_.mint.value(forTokens)(_takenBy, forTokens, _referredBy);

        // Update LeaderBoards
        updateLeaders_(_takenBy, _amountPaid);

        // Handle Payouts
        handlePayouts_(forDev, forPayout, forDayOwner, _takenBy, previousLast, dayOwner);
        return mintedTokens;
    }

    /**
     * Payouts to the last 3 Torch Runners, the Day Owner & Dev
     */
    function handlePayouts_(uint256 _forDev, uint256 _forPayout, uint256 _forDayOwner, address _takenBy, address _previousLast, address _dayOwner) internal {
        uint256[] memory runnerPortions = new uint256[](3);

        // Determine Runner Portions
        //  Note, torch has already been passed, so torchRunners[0]
        //  is the current torch runner
        if (_previousLast != address(0)) {
            runnerPortions[2] = _forPayout.mul(10).div(100);
        }
        if (torchRunners[2] != address(0)) {
            runnerPortions[1] = _forPayout.mul(30).div(100);
        }
        runnerPortions[0] = _forPayout.sub(runnerPortions[1]).sub(runnerPortions[2]);

        // Update Player Dividends
        playerData_[_previousLast].dividends = playerData_[_previousLast].dividends.add(runnerPortions[2]);
        playerData_[torchRunners[2]].dividends = playerData_[torchRunners[2]].dividends.add(runnerPortions[1]);
        playerData_[torchRunners[1]].dividends = playerData_[torchRunners[1]].dividends.add(runnerPortions[0]);

        // Track Profits
        playerData_[owner].profits = playerData_[owner].profits.add(_forDev);
        if (_dayOwner != _takenBy) {
            playerData_[_dayOwner].profits = playerData_[_dayOwner].profits.add(_forDayOwner);
        }

        // Transfer Funds
        //  - Transfer directly since these accounts are not, or may not be, existing
        //    Torch-Runners and therefore cannot "exit" this contract
        owner.transfer(_forDev);
        if (_dayOwner != _takenBy) {
            _dayOwner.transfer(_forDayOwner);
        }
    }

    /**
     * Withdraw the earned Torch Dividends to Ether
     *  - Does not touch Token Dividends or Token Referral Bonuses
     */
    function withdrawFor_(address _for) internal returns (uint256) {
        uint256 torchDividends = playerData_[_for].dividends;
        if (playerData_[_for].dividends > 0) {
            playerData_[_for].dividends = 0;
            playerData_[_for].profits = playerData_[_for].profits.add(torchDividends);
            _for.transfer(torchDividends);
        }
        return torchDividends;
    }

    /**
     * Update the Medal Leader Boards
     */
    function updateLeaders_(address _takenBy, uint256 _amountPaid) internal {
        // Owner can&#39;t be leader; conflict of interest
        if (_takenBy == owner || _takenBy == donationsReceiver_) { return; }

        // Update Highest Prices
        if (_amountPaid > _lowestHighPrice) {
            updateHighestPrices_(_amountPaid, _takenBy);
        }

        // Update Highest Mileage
        uint256 tokenBalance = CryptoTorchToken_.balanceOf(_takenBy);
        if (tokenBalance > _lowestHighMiles) {
            updateHighestMiles_(tokenBalance, _takenBy);
        }
    }

    /**
     * Calculate the amount of Payout for the Day Owner (Holidays receive extra)
     */
    function calculateDayOwnerCut_(uint256 _price) internal view returns (uint256) {
        if (getHolidayByIndex_(getDayIndex_(now)) == 1) {
            return _price.mul(25).div(100);
        }
        return _price.mul(10).div(100);
    }

    /**
     * Get the Day-Index of the current Day for Mapping with OwnTheDay.io
     */
    function getDayIndex_(uint timestamp) internal view returns (uint256) {
        uint8 day = DateTimeLib_.getDay(timestamp);
        uint8 month = DateTimeLib_.getMonth(timestamp);
        // OwnTheDay always includes Feb 29
        uint16[12] memory offset = [0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335];
        return offset[month-1] + day;
    }

    /**
     * Determine if Day-Index is a Holiday or not
     */
    function getHolidayByIndex_(uint256 _dayIndex) internal view returns (uint result) {
        if (_dayIndex < 122) {
            return getFromList_(0, _dayIndex);
        }
        if (_dayIndex < 244) {
            return getFromList_(1, _dayIndex-122);
        }
        return getFromList_(2, _dayIndex-244);
    }
    function getFromList_(uint8 _idx, uint256 _dayIndex) internal view returns (uint result) {
        result = parseInt_(uint(bytes(holidayMap_[_idx])[_dayIndex]));
    }
    function parseInt_(uint c) internal pure returns (uint result) {
        if (c >= 48 && c <= 57) {
            result = result * 10 + (c - 48);
        }
    }

    /**
     * Update the Medal Leaderboard for the Highest Price
     */
    function updateHighestPrices_(uint256 _price, address _owner) internal {
        uint256 newPos = maxLeaders;
        uint256 oldPos = maxLeaders;
        uint256 i;
        HighPrice memory tmp;

        // Determine positions
        for (i = maxLeaders-1; i >= 0; i--) {
            if (_price >= _highestPrices[i].price) {
                newPos = i;
            }
            if (_owner == _highestPrices[i].owner) {
                oldPos = i;
            }
            if (i == 0) { break; } // prevent i going below 0
        }
        // Insert or update leader
        if (newPos < maxLeaders) {
            if (oldPos < maxLeaders-1) {
                // update price for existing leader
                _highestPrices[oldPos].price = _price;
                if (newPos != oldPos) {
                    // swap
                    tmp = _highestPrices[newPos];
                    _highestPrices[newPos] = _highestPrices[oldPos];
                    _highestPrices[oldPos] = tmp;
                }
            } else {
                // shift down
                for (i = maxLeaders-1; i > newPos; i--) {
                    _highestPrices[i] = _highestPrices[i-1];
                }
                // insert
                _highestPrices[newPos].price = _price;
                _highestPrices[newPos].owner = _owner;
            }
            // track lowest value
            _lowestHighPrice = _highestPrices[maxLeaders-1].price;
        }
    }

    /**
     * Update the Medal Leaderboard for the Highest Miles
     */
    function updateHighestMiles_(uint256 _miles, address _owner) internal {
        uint256 newPos = maxLeaders;
        uint256 oldPos = maxLeaders;
        uint256 i;
        HighMileage memory tmp;

        // Determine positions
        for (i = maxLeaders-1; i >= 0; i--) {
            if (_miles >= _highestMiles[i].miles) {
                newPos = i;
            }
            if (_owner == _highestMiles[i].owner) {
                oldPos = i;
            }
            if (i == 0) { break; } // prevent i going below 0
        }
        // Insert or update leader
        if (newPos < maxLeaders) {
            if (oldPos < maxLeaders-1) {
                // update miles for existing leader
                _highestMiles[oldPos].miles = _miles;
                if (newPos != oldPos) {
                    // swap
                    tmp = _highestMiles[newPos];
                    _highestMiles[newPos] = _highestMiles[oldPos];
                    _highestMiles[oldPos] = tmp;
                }
            } else {
                // shift down
                for (i = maxLeaders-1; i > newPos; i--) {
                    _highestMiles[i] = _highestMiles[i-1];
                }
                // insert
                _highestMiles[newPos].miles = _miles;
                _highestMiles[newPos].owner = _owner;
            }
            // track lowest value
            _lowestHighMiles = _highestMiles[maxLeaders-1].miles;
        }
    }
}