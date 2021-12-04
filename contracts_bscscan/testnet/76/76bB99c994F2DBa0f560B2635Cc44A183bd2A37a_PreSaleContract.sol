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

    // Pricefeed chainlink
    address public BNB_USD = 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526;
    address public ETH_USD = 0x143db3CEEfbdfe5631aDD3E50f7614B6ba708BA7;
    // Token address
    address public ETH_TOKEN = 0x8D9A90F4b9f5918E8e60303FDB97FcbbD3E6f159;
    address public DAI_TOKEN = 0x8D9A90F4b9f5918E8e60303FDB97FcbbD3E6f159;
    address public BUSD_TOKEN = 0x8D9A90F4b9f5918E8e60303FDB97FcbbD3E6f159;

    // address public BUSD_USD = 0xcBb98864Ef56E9042e7d2efef76141f15731B82f;
    // address public DAI_USD = 0x132d3C0B1D2cEa0BC552588063bdBb210FDeecfA;
    AggregatorV3Interface internal priceFeed;
    AggregatorV3Interface internal priceFeed2;

    // Contract States
    address payable public owner;

    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;
    uint256 public soldToken;
    uint256 public amountRaised;
    uint256 public TIME_STEP = 5 minutes;
    uint256 public PERCENTS_DIVIDER = 100;
    bool public isClaimEnabled;
    uint256 public claimStartTime;
    uint256 public minJedTokens = 1000;

    // Whitelist Presale
    uint256[2] public vipTokensPerSlot = [500000000, 400000000];
    uint256[6] public whitelistClaimAmountU1 = [100, 100, 200, 200, 200, 200];
    uint256[6] public whitelistClaimAmountU2 = [250, 150, 150, 150, 150, 150];
    // Public Presale
    uint256[5] public usdSlots = [4000, 2000, 800, 10000, 8000];
    uint256[3] public tokensPerUsd = [40000000000000, 60000000000000, 80000000000000];
    uint256[5] public availableSlots = [100, 1000, 2500, 30, 50];
    uint256[5] public totalClaims = [4, 2, 1, 6, 6];
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
        priceFeed2 = AggregatorV3Interface(ETH_USD);
        minJedTokens = minJedTokens.mul(10 ** jedToken.decimals());
        // Setting presale time.
        preSaleStartTime = block.timestamp;
        preSaleEndTime = block.timestamp + TIME_STEP;
        isPublicSaleEnable = true;
    }

    receive() external payable {}

    // to buy token during public preSale time => for web3 use
    function buyTokenBNB(uint256 slotIndex)
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

    // to buy token during public preSale time => for web3 use
    function buyToken(uint256 slotIndex, uint256 amount, uint256 choice)
        public
        isContract(msg.sender)
    {
        require(choice < 3, "Invalid token");
        require(slotIndex < 3, "Wrong Slot");
        require (jedToken.balanceOf(msg.sender) >= 1000e18, "Insufficient JED Tokens.");
        require(availableSlots[slotIndex] != 0, "Presale: Slot not available.");
        require(isPublicSaleEnable, "PreSale: Sale not enabled");
        require(
            block.timestamp >= preSaleStartTime &&
                block.timestamp < preSaleEndTime,
            "PreSale: PreSale over"
        );
        // Check requried tokens for slot.
        if(choice == 1) {
            uint256 reqEth = usdToETH(usdSlots[slotIndex]);
            require(reqEth >= amount, "PreSale: Invalid Amount");
            IBEP20(ETH_TOKEN).transferFrom(msg.sender, address(this), reqEth);
        } else {
            require((usdSlots[slotIndex] ** 1e18) >= amount, "PreSale: Invalid Amount");
            if(choice == 2){
                IBEP20(DAI_TOKEN).transferFrom(msg.sender, address(this), amount);
            } else {
                IBEP20(BUSD_TOKEN).transferFrom(msg.sender, address(this), amount);
            }
        }

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
        amountRaised = amountRaised.add(amount);
        availableSlots[slotIndex] -= 1;

        // Event trigger.
        emit BuyToken(msg.sender, numberOfTokens);
    }

    // to claim tokens in vesting => for web3 use
    function claim(uint256 slotIndex) public {
        // Claim checks.
        require(slotIndex < 5, "Presale: Invalid Slot");
        require(slotIndex > 2 && whitelist[msg.sender], "Presale: Not a vip user.");
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
    function setWhitelistusers (address[] memory _users, uint256[] memory _tokensPerSlot) public {
        require(_users.length == _tokensPerSlot.length, "Users and slots are not equal");

        for(uint256 i = 0; i < _users.length; i++) {
            uint256 slotIndex;
            uint256[6] memory claimPercentage;
            if(_tokensPerSlot[i] == vipTokensPerSlot[0]){
                slotIndex = 3;
                claimPercentage = whitelistClaimAmountU1;
            } else {                
                slotIndex = 4;
                claimPercentage = whitelistClaimAmountU2;
            }

            kredToken.transferFrom(owner, address(this), _tokensPerSlot[i]);
            // Setting user data.
            users[_users[i]][slotIndex].slotNumber = slotIndex;
            users[_users[i]][slotIndex].tokenBalance = users[_users[i]][slotIndex].tokenBalance.add(_tokensPerSlot[i]);
            users[_users[i]][slotIndex].time = block.timestamp;
            users[_users[i]][slotIndex].remainingClaims = totalClaims[slotIndex];
            users[_users[i]][slotIndex].claimPercentage = claimPercentage;
            users[_users[i]][slotIndex].slotCount += 1;

            // settting total.
            tokenBalance[_users[i]] = tokenBalance[_users[i]].add(_tokensPerSlot[i]);
            soldToken = soldToken.add(_tokensPerSlot[i]);
            whitelist[_users[i]] = true;

            // Trigger event
            emit BuyToken(_users[i], _tokensPerSlot[i]);
        }
    }
    
    function usdToBNB(uint256 value) public view returns(uint256) {
        uint256 reqBNB = getBNB(value.mul(10 ** priceFeed.decimals()));
        return reqBNB.mul(1e10);
    }

    function usdToETH(uint256 value) public view returns(uint256) {
        uint256 reqEth = getETH(value.mul(10 ** priceFeed2.decimals()));
        return reqEth.mul(1e10);
    }

    function bnbToUSD(uint256 value) public view returns(uint256) {
        uint256 reqUsd = getUSD(value.mul(10 ** priceFeed.decimals()));
        return reqUsd.mul(1e10);
    }

    function getBNB(uint256 _usd) private view returns (uint256) {
        return _usd.mul(10 ** priceFeed.decimals()).div(getLatestPriceBNB());
    }

    function getETH(uint256 _usd) private view returns (uint256) {
        return _usd.mul(10 ** priceFeed2.decimals()).div(getLatestPriceETH());
    }

    function getUSD(uint256 _bnb) private view returns (uint256) {
        return getLatestPriceBNB().mul(_bnb).div(10 ** priceFeed.decimals());
    }

    function getLatestPriceBNB() public view returns (uint256) {
        (, int price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function getLatestPriceETH() public view returns (uint256) {
        (, int price, , , ) = priceFeed2.latestRoundData();
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

    function getUserSlotInfo(uint256 slotIndex) public view returns(
        uint256 purchases,
        uint256 claimed_tokens,
        uint256 next_claim_date,
        uint256 next_claim_amount,
        bool is_claimed
    ) {
        require(slotIndex < 5, "Presale: Invalid Slot");
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

        return (
            user.tokenBalance,
            user.totalClaimedTokens,
            user.nextUnlockDate,
            dividends,
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
    function withdrawBNB(address _address) external onlyOwner returns (bool) {
        payable(_address).transfer(address(this).balance);
        return true;
    }

    function withdrawToken(address _address, uint256 choice) external onlyOwner returns (bool) {
        require (choice < 3, "Invalid token");
        if(choice == 0) {
            IBEP20(ETH_TOKEN).transfer(_address, IBEP20(ETH_TOKEN).balanceOf(address(this)));
        } else if(choice == 1) {
            IBEP20(DAI_TOKEN).transfer(_address, IBEP20(DAI_TOKEN).balanceOf(address(this)));
        } else {
            IBEP20(BUSD_TOKEN).transfer(_address, IBEP20(BUSD_TOKEN).balanceOf(address(this)));
        }
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