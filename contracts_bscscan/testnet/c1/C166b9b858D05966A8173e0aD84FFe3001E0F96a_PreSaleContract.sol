/**
 *Submitted for verification at BscScan.com on 2021-12-03
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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }
}

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

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
    AggregatorV3Interface internal priceFeed;

    // Contract States
    address payable public owner;

    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;
    uint256 public soldToken;
    uint256 public amountRaised;
    uint256 public TIME_STEP = 5 minutes;
    uint256 public PERCENTS_DIVIDER = 100;
    uint256 public priceFeedDecimals;
    bool public isClaimEnabled;
    uint256 public claimStartTime;
    uint256 public minJedTokens = 1000;

    // Whitelist Presale
    uint256[2] public tokensPerSlot = [500000000, 400000000];
    uint256[6] public whitelistClaimAmountU1 = [100, 100, 200, 200, 200, 200];
    uint256[6] public whitelistClaimAmountU2 = [250, 150, 150, 150, 150, 150];
    // Public Presale
    uint256[3] public usdSlots = [4000, 2000, 800];
    uint256[3] public tokensPerUsd = [40000000000000, 60000000000000, 80000000000000];
    uint256[3] public availableSlots = [100, 1000, 2500];
    uint256[3] public totalClaims = [4, 2, 1];
    bool public isPublicSaleEnable;

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
        bool claimed;
    }

    struct User {
        uint256 slotCount;
        uint256 totalPurchased;
        Slot[] userSlots;
    }

    struct WhitelistSlot {
        uint256 slotId;
        uint256 slotNumber;
        uint256 tokenBalance;
        uint256 totalClaimedTokens;
        uint256 time;
        uint256 nextUnlockDate;
        uint256 lastClaimDate;
        uint256 remainingClaims;
        uint256[6] claimPercentage;
        bool claimed;
    }

    struct WhitelistUser {
        uint256 slotCount;
        uint256 totalPurchased;
        WhitelistSlot[] userSlots;
    }

    mapping(address => mapping(uint256 => Slot)) public users;
    mapping(address => WhitelistUser) public whitelistUsers;
    mapping(address => uint256) public tokenBalance;
    mapping(address => uint256) public coinBalance;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public claimTime;

    modifier onlyOwner() {
        require(msg.sender == owner, "PreSale: Not an owner");
        _;
    }

    modifier isWhitelisted(address _user) {
        require(whitelist[_user], "PreSale: Not a whitelist user");
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

        priceFeed = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);
        priceFeedDecimals = priceFeed.decimals();
        minJedTokens = minJedTokens.mul(10 ** jedToken.decimals());
        // Setting presale time.
        preSaleStartTime = block.timestamp;
        preSaleEndTime = block.timestamp + TIME_STEP;
        isPublicSaleEnable = true;
    }

    receive() external payable {}

    // to buy token during public preSale time => for web3 use
    function buyToken(uint256 slotIndex)
        public
        payable
        isContract(msg.sender)
    {
        require(slotIndex < 3, "Wrong Slot");
        require (jedToken.balanceOf(msg.sender) >= 1000e18, "Insufficient JED Tokens.");
        require(availableSlots[slotIndex] != 0, "Presale: Slot not available.");
        require(isPublicSaleEnable, "PreSale: Sale not enabled");
        require(
            block.timestamp >= preSaleStartTime &&
                block.timestamp < preSaleEndTime,
            "PreSale: PreSale over"
        );
        // Check requried bnb for slot.
        uint256 reqBNB = usdToBNB(usdSlots[slotIndex]);
        require(reqBNB >= msg.value, "PreSale: Invalid Amount");

        uint256 numberOfTokens = usdSlots[slotIndex].mul(1e36).div(tokensPerUsd[slotIndex]);
        kredToken.transferFrom(owner, address(this), numberOfTokens);

        // Set User data.
        users[msg.sender][slotIndex].slotNumber = slotIndex;
        users[msg.sender][slotIndex].tokenBalance = users[msg.sender][slotIndex].tokenBalance.add(numberOfTokens);
        users[msg.sender][slotIndex].time = block.timestamp;
        users[msg.sender][slotIndex].remainingClaims = totalClaims[slotIndex];
        users[msg.sender][slotIndex].slotCount += 1;

        // Set total info
        tokenBalance[msg.sender] = tokenBalance[msg.sender].add(numberOfTokens);
        soldToken = soldToken.add(numberOfTokens);
        amountRaised = amountRaised.add(msg.value);
        availableSlots[slotIndex] -= 1;

        // Event trigger.
        emit BuyToken(msg.sender, numberOfTokens);
    }

    // to claim tokens in vesting => for web3 use
    function claim(uint256 slotIndex) public {
        // Claim checks.
        require(slotIndex < 3, "Presale: Invalid Slot");
        require(isClaimEnabled, "Presale: Claim not started yet");
        require(tokenBalance[msg.sender] > 0, "Presale: Insufficient Balance");
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
        uint256 dividends = user.tokenBalance.mul(BASE_PERCENT).div(PERCENTS_DIVIDER);

        kredToken.transferFrom(owner, msg.sender, dividends);
        user.lastClaimDate = block.timestamp;
        // Setting next claim date.
        user.nextUnlockDate = nextUnlockDate;
        user.totalClaimedTokens = user.totalClaimedTokens.add(dividends);
        user.remainingClaims = user.remainingClaims.sub(1);

        tokenBalance[msg.sender] = tokenBalance[msg.sender].sub(dividends);

        if(user.remainingClaims == 0) {
            user.claimed = true;
        }
        // Trigger event
        emit ClaimToken(msg.sender, dividends);
    }

    function claimWhitelist(uint256 slotNumber) public {

        require(isClaimEnabled, "Presale: Claim not started yet");
        require(tokenBalance[msg.sender] > 0, "Presale: Insufficient Balance");
        require(slotNumber < whitelistUsers[msg.sender].slotCount, "Presale: Invalid Slot");
        require(!whitelistUsers[msg.sender].userSlots[slotNumber].claimed || whitelistUsers[msg.sender].userSlots[slotNumber].remainingClaims == 0, "Presale: Already Claimed");

        // Check if claim date is available
        uint256 nextUnlockDate;
        if(whitelistUsers[msg.sender].userSlots[slotNumber].nextUnlockDate == 0) {
            require (block.timestamp > claimStartTime + TIME_STEP, "Presale: Wait for next claim date.");
            nextUnlockDate = claimStartTime.add(TIME_STEP);
        } else {
            require (block.timestamp > whitelistUsers[msg.sender].userSlots[slotNumber].nextUnlockDate, "Presale: Wait for next claim date.");
            nextUnlockDate = whitelistUsers[msg.sender].userSlots[slotNumber].nextUnlockDate.add(TIME_STEP);
        }

        WhitelistUser storage user = whitelistUsers[msg.sender];
        uint256 claimIndex = user.userSlots[slotNumber].claimPercentage.length - user.userSlots[slotNumber].remainingClaims;
        uint256 dividends = (user.userSlots[slotNumber].tokenBalance
                            .mul(user.userSlots[slotNumber].claimPercentage[claimIndex])
                            .div(PERCENTS_DIVIDER));

        kredToken.transferFrom(owner, msg.sender, dividends);
        user.userSlots[slotNumber].lastClaimDate = block.timestamp;
        // Setting next claim date.
        user.userSlots[slotNumber].nextUnlockDate = nextUnlockDate;

        user.userSlots[slotNumber].totalClaimedTokens = user.userSlots[slotNumber].totalClaimedTokens.add(dividends);
        user.userSlots[slotNumber].remainingClaims = user.userSlots[slotNumber].remainingClaims.sub(1);

        tokenBalance[msg.sender] = tokenBalance[msg.sender].sub(dividends);

        if(user.userSlots[slotNumber].remainingClaims <= 0) {
            user.userSlots[slotNumber].claimed = true;
        }

        emit ClaimToken(msg.sender, dividends);
    }

    // set presale for whitelist users.
    function setWhitelistusers (address[] memory _users, uint256[] memory _tokensPerSlot) public {
        require(_users.length == _tokensPerSlot.length, "Users and slots are not equal");

        for(uint256 i = 0; i < _users.length; i++) {
            WhitelistUser storage user = whitelistUsers[_users[i]];
            uint256 index = user.slotCount;

            kredToken.transferFrom(owner, address(this), _tokensPerSlot[i]);
            user.totalPurchased = user.totalPurchased.add(_tokensPerSlot[i]);
            
            uint256[6] memory claimPercentage;
            if(_tokensPerSlot[i] == tokensPerSlot[0]){
                claimPercentage = whitelistClaimAmountU1;
            } else {                
                claimPercentage = whitelistClaimAmountU2;
            }
            WhitelistSlot memory slot = WhitelistSlot(0, 0, 0, 0, 0, 0, 0, 0, claimPercentage, false);
            user.userSlots.push(slot);
            user.userSlots[index].tokenBalance = user.userSlots[index].tokenBalance.add(_tokensPerSlot[i]);
            user.userSlots[index].time = block.timestamp;
            user.userSlots[index].remainingClaims = 6;

            tokenBalance[_users[i]] = tokenBalance[_users[i]].add(_tokensPerSlot[i]);
            soldToken = soldToken.add(_tokensPerSlot[i]);

            whitelistUsers[_users[i]].slotCount += 1;
            whitelist[_users[i]] = true;
            emit BuyToken(_users[i], _tokensPerSlot[i]);
        }
    }
    
    function usdToBNB(uint256 value) public view returns(uint256) {
        uint256 reqBNB = getBNB(value.mul(10 ** priceFeedDecimals));
        return reqBNB.mul(1e10);
    }

    function bnbToUSD(uint256 value) public view returns(uint256) {
        uint256 reqUsd = getUSD(value.mul(10 ** priceFeedDecimals));
        return reqUsd.mul(1e10);
    }

    function getBNB(uint256 _usd) private view returns (uint256) {
        return _usd.mul(10 ** priceFeedDecimals).div(getLatestPrice());
    }

    function getUSD(uint256 _bnb) private view returns (uint256) {
        return getLatestPrice().mul(_bnb).div(10 ** priceFeedDecimals);
    }

    function bnbToToken(uint256 _amount, uint256 _tokenPerUsd) public view returns (uint256) {
        if(priceFeedDecimals != 18){
            _amount = _amount.div(1e10);
            _tokenPerUsd = _tokenPerUsd.div(1e10); 
        }
        _amount = getUSD(_amount);

        uint256 numberOfTokens = _amount.div(_tokenPerUsd);
        return numberOfTokens;
    }

    function getLatestPrice() public view returns (uint256) {
        (, int price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function getPriceFeedDecimals() public view returns (uint8) {
        return priceFeed.decimals();
    }

    function startClaim() public onlyOwner {
        require(block.timestamp > preSaleEndTime && !isClaimEnabled, "Presale: Not over yet.");
        isClaimEnabled = true;
        claimStartTime = block.timestamp;
    }

    function updatePriceAggregator(address _feedAddress) public onlyOwner {
        priceFeed = AggregatorV3Interface(_feedAddress);
        priceFeedDecimals = priceFeed.decimals();
    }

    // function getUserTotalInfo() public view returns(uint256 last_slot, uint256 total_purchased_tokens, uint256 total_slots) {
    //     Slot storage user = users[msg.sender];
    //     return(
    //         (user.slotCount - 1),
    //         user.totalPurchased,
    //         user.userSlots.length
    //     );
    // }

    function getUserSlotInfo(uint256 slotIndex) public view returns(
        uint256 balance, uint256 claimed_tokens, uint256 next_claim, uint256 remaining_claims, bool is_claimed
    ) {
        require(slotIndex < 3, "Presale: Invalid Slot");
        Slot storage user = users[msg.sender][slotIndex];

        return (
            user.tokenBalance,
            user.totalClaimedTokens,
            user.nextUnlockDate,
            user.remainingClaims,
            user.claimed
        );
    }

    function setPublicPreSale(bool _value, uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
    {
        isPublicSaleEnable = _value;
        preSaleStartTime = _startTime;
        preSaleEndTime = _endTime;
    }

    // transfer ownership
    function changeOwner(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function changeToken(address _token) external onlyOwner {
        kredToken = IBEP20(_token);
    }

    // to draw funds for liquidity
    function transferFunds(uint256 _value) external onlyOwner returns (bool) {
        owner.transfer(_value);
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