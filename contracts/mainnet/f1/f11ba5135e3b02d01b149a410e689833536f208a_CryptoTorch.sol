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
* @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="a5d7c0c8c6cae597">[email&#160;protected]</a>π.com>
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
 * @title Crypto-Torch Contract v1.2
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
    }

    //
    // Payout Structure
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //  Special Olympics Donations  - 10%
    //  Token Pool                  - 90%
    //    - Referral                    - 10% of Token Pool
    //

    //
    // Player Data
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //
    bool private migrationFinished = false;
    uint8 public constant maxLeaders = 3; // Gold, Silver, Bronze

    uint256 private _lowestHighPrice;
    uint256 private _lowestHighMiles;
    uint256 public totalDistanceRun;
    uint256 public whaleIncreaseLimit = 2 ether;
    uint256 public whaleMax = 20 ether;

    HighPrice[maxLeaders] private _highestPrices;
    HighMileage[maxLeaders] private _highestMiles;

    address public torchRunner;
    address public donationsReceiver_;
    mapping (address => PlayerData) private playerData_;

    CryptoTorchToken internal CryptoTorchToken_;

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

    modifier onlyDuringMigration() {
        require(!migrationFinished);
        _;
    }

    //
    // Contract Initialization
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //
    function CryptoTorch() public {}

    /**
     * Initializes the Contract Dependencies as well as the Holiday Mapping for OwnTheDay.io
     */
    function initialize(address _torchRunner, address _tokenAddress) public onlyOwner {
        torchRunner = _torchRunner;
        CryptoTorchToken_ = CryptoTorchToken(_tokenAddress);
    }

    /**
     * Migrate Leader Prices
     */
    function migratePriceLeader(uint8 _leaderIndex, address _leaderAddress, uint256 _leaderPrice) public onlyOwner onlyDuringMigration {
        require(_leaderIndex >= 0 && _leaderIndex < maxLeaders);
        _highestPrices[_leaderIndex].owner = _leaderAddress;
        _highestPrices[_leaderIndex].price = _leaderPrice;
        if (_leaderIndex == maxLeaders-1) {
            _lowestHighPrice = _leaderPrice;
        }
    }

    /**
     * Migrate Leader Miles
     */
    function migrateMileageLeader(uint8 _leaderIndex, address _leaderAddress, uint256 _leaderMiles) public onlyOwner onlyDuringMigration {
        require(_leaderIndex >= 0 && _leaderIndex < maxLeaders);
        _highestMiles[_leaderIndex].owner = _leaderAddress;
        _highestMiles[_leaderIndex].miles = _leaderMiles;
        if (_leaderIndex == maxLeaders-1) {
            _lowestHighMiles = _leaderMiles;
        }
    }

    /**
     *
     */
    function finishMigration() public onlyOwner onlyDuringMigration {
        migrationFinished = true;
    }

    /**
     *
     */
    function isMigrationFinished() public view returns (bool) {
        return migrationFinished;
    }

    /**
     * Sets the external contract address of the Token Contract
     */
    function setTokenContract(address _tokenAddress) public onlyOwner {
        CryptoTorchToken_ = CryptoTorchToken(_tokenAddress);
    }

    /**
     * Set the Contract Donations Receiver
     * - Set to the Special Olympics Donations Address
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

    //
    // Public Functions
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //
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
     * Take the Torch!
     *  The Purchase Price is Paid to the Previous Torch Holder, and is also used
     *  as the Purchasers Mileage Multiplier
     */
    function takeTheTorch(address _referredBy) public nonReentrant whenNotPaused payable {
        takeTheTorch_(msg.value, msg.sender, _referredBy);
    }

    /**
     * Payments made directly to this contract are treated as direct Donations to the Special Olympics.
     *  - Note: payments made directly to the contract do not receive tokens.  Tokens
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
        uint256 forTokens = _etherToSpend.sub(_etherToSpend.div(10)); // 90% for Tokens
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
        require(_amountPaid >= 1 finney);
        require(_takenBy != torchRunner); // Torch must be passed on
        if (_referredBy == address(this)) { _referredBy = address(0); }

        // Calculate Portions
        uint256 forDonations = _amountPaid.div(10);
        uint256 forTokens = _amountPaid.sub(forDonations);

        // Pass the Torch
        onTorchPassed(torchRunner, _takenBy, _amountPaid);
        torchRunner = _takenBy;

        // Grant Mileage Tokens to Torch Holder
        uint256 mintedTokens = CryptoTorchToken_.mint.value(forTokens)(torchRunner, forTokens, _referredBy);
        if (totalDistanceRun < CryptoTorchToken_.totalSupply()) {
            totalDistanceRun = CryptoTorchToken_.totalSupply();
        }

        // Update LeaderBoards
        updateLeaders_(torchRunner, _amountPaid);

        // Handle Payouts
        playerData_[donationsReceiver_].profits = playerData_[donationsReceiver_].profits.add(forDonations);
        donationsReceiver_.transfer(forDonations);
        return mintedTokens;
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
    function updateLeaders_(address _torchRunner, uint256 _amountPaid) internal {
        // Owner can&#39;t be leader; conflict of interest
        if (_torchRunner == owner) { return; }

        // Update Highest Prices
        if (_amountPaid > _lowestHighPrice) {
            updateHighestPrices_(_amountPaid, _torchRunner);
        }

        // Update Highest Mileage
        uint256 tokenBalance = CryptoTorchToken_.balanceOf(_torchRunner);
        if (tokenBalance > _lowestHighMiles) {
            updateHighestMiles_(tokenBalance, _torchRunner);
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