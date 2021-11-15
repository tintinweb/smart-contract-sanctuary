pragma solidity 0.7.5;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

contract RAINPresale is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // The number of unclaimed tokens the user has
    mapping(address => uint256) public tokenUnclaimed;
	// The number of unclaimed tokens the user bought total
    mapping(address => uint256) public tokenBoughtTotal;
    // // Last time user claimed
    // mapping(address => uint256) public lastTokenClaimed;
    // Whitelisting list
    mapping(address => bool) public whiteListed;

    uint256 public saleIndex = 1;
    // Total BuyingToken spend for limits
    mapping(uint256 => mapping(address => uint256)) public totalBuyingTokenSpend;

    // RAIN token
    IERC20 RAIN;
    // BuyingToken token
    IERC20 BuyingToken;
    // Sale active
    bool public isSaleActive;
    // Claim active
    bool public isClaimActive;
    // Claim active
    bool public isWhitelistEnabled = true;
    // Starting timestamp
    uint256 public startingTimeStamp;
    // Starting timestamp
    uint256 public claimStartedTimestamp;
    // Total RAIN sold
    uint256 public totalTokenSold = 0;
    // Price of presale RAINs
    uint256 public price = 5000;

    uint256 public hardcap = 150000_000_000_000;

    // Minimum BuyingTokens to spend
    uint256 public minSpend = 300_000_000_000_000_000_000;

    // Max BuyingTokens to spend
    uint256 public maxSpendPerUser = 1000_000_000_000_000_000_000;

    address payable owner;

    // Time per percent
    uint256 public secondPerPercent = 17280;

    uint256 private constant FIRST_CLAIM_PERCENT = 5000;

    modifier onlyOwner() {
        require(msg.sender == owner, "You're not the owner");
        _;
    }

    event TokenBuy(address user, uint256 tokens);
    event TokenClaim(address user, uint256 tokens);

    constructor(
        address _RAIN,
        uint256 _startingTimestamp,
        address _BuyingToken
    ) public {
        RAIN = IERC20(_RAIN);
        BuyingToken = IERC20(_BuyingToken);
        isSaleActive = false;
        owner = msg.sender;
        startingTimeStamp = _startingTimestamp;
    }

    /* User methods */
    function buy(uint256 _amount, address _buyer) public nonReentrant {
        require(isSaleActive, "Presale has not started");
        require(
            block.timestamp >= startingTimeStamp,
            "Presale has not started"
        );
        require(
            !isWhitelistEnabled || whiteListed[msg.sender] == true,
            'Not whitelisted'
        );
        require(
            totalBuyingTokenSpend[saleIndex][msg.sender] + _amount >= minSpend,
            "Below minimum amount"
        );
        require(
            totalBuyingTokenSpend[saleIndex][msg.sender] + _amount <= maxSpendPerUser,
            "You have reached maximum spend amount per user"
        );

        address buyer = _buyer;
        uint256 tokens = _amount.div(price).mul(1000).div(1_000_000_000);

        require(
            totalTokenSold + tokens <= hardcap,
            "Token presale hardcap reached"
        );

        BuyingToken.transferFrom(buyer, address(this), _amount);

        tokenUnclaimed[buyer] = tokenUnclaimed[buyer].add(tokens);
 		tokenBoughtTotal[buyer] = tokenBoughtTotal[buyer].add(tokens);
        totalBuyingTokenSpend[saleIndex][msg.sender] = totalBuyingTokenSpend[saleIndex][msg.sender].add(_amount);

        totalTokenSold = totalTokenSold.add(tokens);
        emit TokenBuy(buyer, tokens);
    }

    
    function claim() external {
        require(isClaimActive, "Claim is not allowed yet");
        require(
            tokenUnclaimed[msg.sender] > 0,
            "You don't have any unclaimed tokens"
        );
        require(
            RAIN.balanceOf(address(this)) >= tokenUnclaimed[msg.sender],
            "There are not enough tokens in presale contract to transfer. Please report to contract admin."
        );

        uint256 allowedPercentToClaim = block
            .timestamp
            .sub(claimStartedTimestamp).mul(100)
            .div(secondPerPercent);

        allowedPercentToClaim = allowedPercentToClaim.add(FIRST_CLAIM_PERCENT);

        // ensure user cannot claim more than they have.
        if (allowedPercentToClaim > 10000) {
            allowedPercentToClaim = 10000;
        }

        uint256 tokenToClaimTotal = tokenBoughtTotal[msg.sender]
                                    .mul(allowedPercentToClaim)
                                    .div(10000);

        uint256 tokenAlreadyClaimed = tokenBoughtTotal[msg.sender].sub(tokenUnclaimed[msg.sender]);						
        uint256 tokenToClaim = tokenToClaimTotal.sub(tokenAlreadyClaimed);

        tokenUnclaimed[msg.sender] = tokenUnclaimed[msg.sender].sub(tokenToClaim);

        RAIN.transfer(msg.sender, tokenToClaim);
        emit TokenClaim(msg.sender, tokenToClaim);
    }

    /* Admin methods */

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setHardcap(uint256 _hardcap) external onlyOwner {
        hardcap = _hardcap;
    }

    function setStartingTimestamp(uint256 _timestamp) external onlyOwner {
        startingTimeStamp = _timestamp;
    }

    function setWhitelistEnabled(bool _isWhitelistEnabled) external onlyOwner {
        isWhitelistEnabled = _isWhitelistEnabled;
    }

    function setSaleActive(bool _isSaleActive) external onlyOwner {
        isSaleActive = _isSaleActive;
    }

    function setSecondPerPercent(uint256 _secondPerPercent) external onlyOwner {
        secondPerPercent = _secondPerPercent;
    }

    function setClaimActive(bool _isClaimActive) external onlyOwner {
        isClaimActive = _isClaimActive;
        if (_isClaimActive) {
            claimStartedTimestamp = block.timestamp;
        }
    }

    function set(uint256 _price, uint256 _hardcap, uint256 _startingTimeStamp, uint256 _minSpend, uint256 _maxSpendPerUser, uint256 _setSaleIndex) external onlyOwner {
        price = _price;
        hardcap = _hardcap;
        startingTimeStamp = _startingTimeStamp;
        minSpend = _minSpend;
        maxSpendPerUser = _maxSpendPerUser;
        saleIndex = _setSaleIndex;
    }

    function whiteListBuyers(address[] memory _buyers) external onlyOwner {
        // require(isSaleActive == false, 'Already started');

        for (uint256 i; i < _buyers.length; i++) {
            whiteListed[_buyers[i]] = true;
        }
    }

    function withdrawFunds() external onlyOwner {
        BuyingToken.transfer(msg.sender, BuyingToken.balanceOf(address(this)));
    }

    function withdrawUnsoldRAIN() external onlyOwner {
        uint256 amount = RAIN.balanceOf(address(this)) - totalTokenSold;
        RAIN.transfer(msg.sender, amount);
    }

    function emergencyWithdraw() external onlyOwner {
        RAIN.transfer(msg.sender, RAIN.balanceOf(address(this)));
    }
}