/**
 *Submitted for verification at BscScan.com on 2021-12-11
*/

//SPDX-License-Identifier: MIT Licensed
pragma solidity ^0.8.7;

interface IBEP20 {

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

interface AggregatorV3Interface {
  
  function decimals() external view returns (uint8);

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

contract PreSaleContract {
    using SafeMath for uint256;
    using Address for address;

    IBEP20 public kredToken;
    IBEP20 public jedToken;

    // Pricefeed chainlink
    address public BNB_USD = 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526;
    // Token address
    // 0 USDT, 1 DAI, 2 BUSD
    address[3] public OTHER_TOKENS = [
        0x8D9A90F4b9f5918E8e60303FDB97FcbbD3E6f159, 
        0x20B34cF0152d1eECdF06769a304ff9d151bc8D9b,
        0x5841e01f1b95a659aBB66a3b610940D5022EB590
    ];

    AggregatorV3Interface internal priceFeed;

    // Contract States
    address payable public owner;

    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;
    uint256 public soldToken;
    uint256 public amountRaised;
    uint256 public TIME_STEP = 5 minutes;
    uint256 public PERCENTS_DIVIDER = 100;
    uint256 public claimStartTime;
    uint256 public minJedTokens = 1000;
    bool public isClaimEnabled;

    // Whitelist Presale
    uint256[2] public vipTokensPerSlot = [500000000, 400000000];
    uint256[6] public whitelistClaimAmountU1 = [100, 100, 200, 200, 200, 200];
    uint256[6] public whitelistClaimAmountU2 = [250, 150, 150, 150, 150, 150];
    // Public Presale
    uint256[5] public usdSlots = [4000, 2000, 800, 10000, 8000];
    uint256[3] public tokensPerUsd = [40000000000000, 60000000000000, 80000000000000];
    uint256[5] public availableSlots = [100, 1000, 2500, 30, 50];
    uint256[5] public totalClaims = [4, 2, 1, 6, 6];

    struct Slot {
        uint256 slotNumber;
        uint256 tokenBalance;
        uint256 totalClaimedTokens;
        uint256 time;
        uint256 nextUnlockDate;
        uint256 lastClaimDate;
        uint256 remainingClaims;
        uint256 slotCount;
        uint256[4] claimDate;
        uint256[] claimPercentage;
        bool claimed;
    }

    struct User {
        uint256 slotCount;
        uint256 totalPurchased;
        Slot[] userSlots;
    }

    mapping(address => mapping(uint256 => Slot)) public users;
    mapping(address => uint256) public tokenBalance;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public claimTime;

    modifier onlyOwner() {
        require(msg.sender == owner, "PreSale: Not an owner");
        _;
    }

    modifier isWhitelisted(address _user) {
        require(whitelist[_user], "PreSale: Not a vip user");
        _;
    }

    modifier isContract(address _user) {
        require(!address(_user).isContract(), "PreSale: contract can not buy");
        _;
    }

    event BuyToken(address _user, uint256 _amount);
    event ClaimToken(address _user, uint256 _amount);

    constructor(address payable _owner, IBEP20 _kredToken, IBEP20 _jedToken) {
        owner = _owner;
        kredToken = _kredToken;
        jedToken = _jedToken;

        priceFeed = AggregatorV3Interface(BNB_USD);
        minJedTokens = minJedTokens.mul(10 ** jedToken.decimals());
        // Setting presale time.
        preSaleStartTime = block.timestamp;
        preSaleEndTime = block.timestamp + TIME_STEP;
    }

    receive() external payable {}

    // to buy token during public preSale time => for web3 use
    function buyTokenBNB(uint256 slotIndex, uint256 slotsQty)
        public
        payable
        isContract(msg.sender)
    {
        require(slotsQty > 0, "Invalid Quantity");
        require(slotIndex < 3, "Wrong Slot");
        require (jedToken.balanceOf(msg.sender) >= 1000e18, "Insufficient JED Tokens.");
        require(availableSlots[slotIndex] != 0, "Presale: Slot not available.");
        require(
            block.timestamp >= preSaleStartTime &&
                block.timestamp < preSaleEndTime,
            "PreSale: PreSale over"
        );
        // Check requried bnb for slot.
        uint256 reqBNB = usdToBNB(usdSlots[slotIndex].mul(slotsQty));
        require(msg.value >= reqBNB, "PreSale: Invalid Amount");

        uint256 numberOfTokens = (usdSlots[slotIndex].mul(slotsQty)).mul(1e36).div(tokensPerUsd[slotIndex]);
        kredToken.transferFrom(owner, address(this), numberOfTokens);

        // Set User data.
        users[msg.sender][slotIndex].slotNumber = slotIndex;
        users[msg.sender][slotIndex].tokenBalance = users[msg.sender][slotIndex].tokenBalance.add(numberOfTokens);
        users[msg.sender][slotIndex].time = block.timestamp;
        users[msg.sender][slotIndex].remainingClaims = totalClaims[slotIndex];
        users[msg.sender][slotIndex].slotCount += slotsQty;

        // Set total info
        tokenBalance[msg.sender] = tokenBalance[msg.sender].add(numberOfTokens);
        soldToken = soldToken.add(numberOfTokens);
        amountRaised = amountRaised.add(msg.value);
        availableSlots[slotIndex] -= slotsQty;

        // Event trigger.
        emit BuyToken(msg.sender, numberOfTokens);
    }

    // to buy token during public preSale time => for web3 use
    function buyToken(uint256 slotIndex, uint256 choice, uint256 slotsQty)
        public
        isContract(msg.sender)
    {
        require(slotsQty > 0, "Invalid Quantity");
        require(choice < OTHER_TOKENS.length, "Invalid token");
        require(slotIndex < 3, "Wrong Slot");
        require (jedToken.balanceOf(msg.sender) >= 1000e18, "Insufficient JED Tokens.");
        require(availableSlots[slotIndex] != 0, "Presale: Slot not available.");
        require(
            block.timestamp >= preSaleStartTime &&
                block.timestamp < preSaleEndTime,
            "PreSale: PreSale over"
        );

        uint256 amount = usdSlots[slotIndex].mul(slotsQty).mul(1e18);
        // Check requried tokens for slot.
        IBEP20(OTHER_TOKENS[choice]).transferFrom(msg.sender, address(this), amount);

        uint256 numberOfTokens = (usdSlots[slotIndex].mul(slotsQty)).mul(1e36).div(tokensPerUsd[slotIndex]);
        kredToken.transferFrom(owner, address(this), numberOfTokens);

        // Set User data.
        users[msg.sender][slotIndex].slotNumber = slotIndex;
        users[msg.sender][slotIndex].tokenBalance = users[msg.sender][slotIndex].tokenBalance.add(numberOfTokens);
        users[msg.sender][slotIndex].time = block.timestamp;
        users[msg.sender][slotIndex].remainingClaims = totalClaims[slotIndex];
        users[msg.sender][slotIndex].slotCount += slotsQty;

        // Set total info
        tokenBalance[msg.sender] = tokenBalance[msg.sender].add(numberOfTokens);
        soldToken = soldToken.add(numberOfTokens);
        amountRaised = amountRaised.add(amount);
        availableSlots[slotIndex] -= slotsQty;

        // Event trigger.
        emit BuyToken(msg.sender, numberOfTokens);
    }

    // to claim tokens in vesting => for web3 use
    function claim() public {
        // Claim checks.
        require(block.timestamp > preSaleEndTime, "PreSale: PreSale not over");
        require(isClaimEnabled, "Presale: Claim not started yet");
        require(tokenBalance[msg.sender] > 0, "Presale: Insufficient Balance");

        uint256 totClaimedSlots;
        for(uint256 slotIndex = 0; slotIndex < usdSlots.length; slotIndex++) {
            (, , uint256 nextClaimDate, ,) = getUserSlotInfo(msg.sender, slotIndex);
            // Check if claim date is available
            if(block.timestamp > nextClaimDate) {
                _claim(slotIndex);
                totClaimedSlots++;
            }
        }

        require (totClaimedSlots > 0, "Wait for next claim.");
    }

    function _claim(uint256 slotIndex) public {
        // Claim checks.
        require(slotIndex < 5, "Presale: Invalid Slot");
        if(slotIndex > 2) {
            require(whitelist[msg.sender], "Presale: Not a vip user.");                
        }
        require(!users[msg.sender][slotIndex].claimed || users[msg.sender][slotIndex].remainingClaims == 0, "Presale: Already Claimed");

        // Check if claim date is available
        uint256 nextUnlockDate;
        if(users[msg.sender][slotIndex].nextUnlockDate == 0) {
            require (block.timestamp > claimStartTime + TIME_STEP, "Presale: Wait for next claim date.");
            nextUnlockDate = claimStartTime.add(TIME_STEP);
        } else {
            require (block.timestamp > users[msg.sender][slotIndex].nextUnlockDate, "Presale: Wait for next claim date.");
            nextUnlockDate = users[msg.sender][slotIndex].nextUnlockDate.add(TIME_STEP);
        }

        // Claim processing.
        Slot storage user = users[msg.sender][slotIndex];  
        uint256 BASE_PERCENT = PERCENTS_DIVIDER.div(totalClaims[user.slotNumber]);
        // Get Dividend by user type
        uint256 dividends;
        if(slotIndex > 2) {
            uint256 claimIndex = user.claimPercentage.length - user.remainingClaims;
            dividends = user.tokenBalance
                                    .mul(user.claimPercentage[claimIndex])
                                    .div(PERCENTS_DIVIDER);
        } else{
            dividends = user.tokenBalance.mul(BASE_PERCENT).div(PERCENTS_DIVIDER);                
        }

        kredToken.transferFrom(owner, msg.sender, dividends);
        user.lastClaimDate = block.timestamp;
        // Setting next claim date.
        user.nextUnlockDate = nextUnlockDate;
        user.totalClaimedTokens = user.totalClaimedTokens.add(dividends);
        user.remainingClaims = user.remainingClaims.sub(1);

        // Total info
        tokenBalance[msg.sender] = tokenBalance[msg.sender].sub(dividends);
        if(user.remainingClaims == 0) {
            user.claimed = true;
        }
        
        // Trigger event
        emit ClaimToken(msg.sender, dividends);
    }

    // set presale for whitelist users.
    function setWhitelistusers (address[] memory _users, uint256[] memory _slotIndexes) public {
        require(_users.length == _slotIndexes.length, "Users and slots are not equal");

        for(uint256 i = 0; i < _users.length; i++) {
            uint256 slotIndex;
            uint256[6] memory claimPercentage;
            if(_slotIndexes[i] == 0){
                slotIndex = 3;
                claimPercentage = whitelistClaimAmountU1;
            } else {                
                slotIndex = 4;
                claimPercentage = whitelistClaimAmountU2;
            }

            kredToken.transferFrom(owner, address(this), vipTokensPerSlot[_slotIndexes[i]]);
            // Setting user data.
            users[_users[i]][slotIndex].slotNumber = slotIndex;
            users[_users[i]][slotIndex].tokenBalance = users[_users[i]][slotIndex].tokenBalance.add(vipTokensPerSlot[_slotIndexes[i]]);
            users[_users[i]][slotIndex].time = block.timestamp;
            users[_users[i]][slotIndex].remainingClaims = totalClaims[slotIndex];
            users[_users[i]][slotIndex].claimPercentage = claimPercentage;
            users[_users[i]][slotIndex].slotCount += 1;

            // settting total.
            tokenBalance[_users[i]] = tokenBalance[_users[i]].add(vipTokensPerSlot[_slotIndexes[i]]);
            soldToken = soldToken.add(vipTokensPerSlot[_slotIndexes[i]]);
            whitelist[_users[i]] = true;

            // Trigger event
            emit BuyToken(_users[i], vipTokensPerSlot[_slotIndexes[i]]);
        }
    }
    
    function usdToBNB(uint256 value) public view returns(uint256) {
        uint256 reqBNB = getBNB(value.mul(10 ** priceFeed.decimals()));
        return reqBNB.mul(1e10);
    }

    function bnbToUSD(uint256 value) public view returns(uint256) {
        uint256 reqUsd = getUSD(value.mul(10 ** priceFeed.decimals()));
        return reqUsd.mul(1e10);
    }

    function getBNB(uint256 _usd) private view returns (uint256) {
        return _usd.mul(10 ** priceFeed.decimals()).div(getLatestPriceBNB());
    }

    function getUSD(uint256 _bnb) private view returns (uint256) {
        return getLatestPriceBNB().mul(_bnb).div(10 ** priceFeed.decimals());
    }

    function getLatestPriceBNB() public view returns (uint256) {
        (, int price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function startClaim() public onlyOwner {
        require(block.timestamp > preSaleEndTime && !isClaimEnabled, "Presale: Not over yet.");
        isClaimEnabled = true;
        claimStartTime = block.timestamp;
    }

    function updatePriceAggregator(address _feedAddress) public onlyOwner {
        priceFeed = AggregatorV3Interface(_feedAddress);
    }

    function getUserSlotInfo(address _user, uint256 slotIndex) public view returns(
        uint256 purchases,
        uint256 claimed_tokens,
        uint256 next_claim_date,
        uint256 next_claim_amount,
        bool is_claimed
    ) {
        require(slotIndex < 5, "Presale: Invalid Slot");
        Slot storage user = users[_user][slotIndex];
        uint256 BASE_PERCENT = PERCENTS_DIVIDER.div(totalClaims[user.slotNumber]);
        // Get Dividend by user type
        uint256 dividends;
        if(slotIndex > 2) {
            uint256 claimIndex = user.claimPercentage.length - user.remainingClaims;
            dividends = user.tokenBalance
                                    .mul(user.claimPercentage[claimIndex])
                                    .div(PERCENTS_DIVIDER);
        } else{
            dividends = user.tokenBalance.mul(BASE_PERCENT).div(PERCENTS_DIVIDER);                
        }

        uint256 nextUnlockDate = user.nextUnlockDate;
        if(claimStartTime != 0 && user.nextUnlockDate == 0) {
            nextUnlockDate = claimStartTime + TIME_STEP;
        }

        return (
            user.tokenBalance,
            user.totalClaimedTokens,
            nextUnlockDate,
            dividends,
            user.claimed
        );
    }

    function setPublicPreSale(uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
    {
        preSaleStartTime = _startTime;
        preSaleEndTime = _endTime;
        claimStartTime = 0;
        isClaimEnabled = false;
    }

    // transfer ownership
    function changeOwner(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function changeToken(address _token) external onlyOwner {
        kredToken = IBEP20(_token);
    }

    // to draw funds for liquidity
    function withdrawBNB(address _address) external onlyOwner returns (bool) {
        payable(_address).transfer(address(this).balance);
        return true;
    }

    function updateCurrencyTokenAddress(uint256 choice, address _tokenAddress) external onlyOwner {
        require (choice < OTHER_TOKENS.length, "Invalid token");
        require(_tokenAddress.isContract(), "PreSale: Address incorrect!");
        OTHER_TOKENS[choice] = _tokenAddress;
    }

    function updateBNBUSDChainlink(address _feedAddress) external onlyOwner {
        require(_feedAddress.isContract(), "PreSale: Address incorrect!");
        BNB_USD = _feedAddress;
    }

    function withdrawToken(address _address, uint256 choice) external onlyOwner returns (bool) {
        require (choice < OTHER_TOKENS.length, "Invalid token");
        IBEP20(OTHER_TOKENS[choice])
                .transfer(_address, IBEP20(OTHER_TOKENS[choice]).balanceOf(address(this)));
        return true;
    }

    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }

    function contractBalanceBnb() external view returns (uint256) {
        return address(this).balance;
    }

    function getContractTokenBalance() external view returns (uint256) {
        return kredToken.allowance(owner, address(this));
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}