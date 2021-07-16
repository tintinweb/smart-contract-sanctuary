//SourceUnit: BananaContract.sol

pragma solidity 0.5.10;

import "./IERC20.sol";
import "./SafeMath.sol";

contract BananaContract {
    using SafeMath for uint256;

    event Msg(address user, string msg);

    address payable _ownerUser;

    struct User {
        address referrerUser;
        address[] followerUsers;
        uint256 joinTime;
        uint256 totalBuySun;
        uint256 totalSellSun;
        uint256 totalWithdrawSun;
        uint256 amountBuyToken;
        uint256 withdrawableSellSun;
        uint256 withdrawableCommissionSun;
        uint256 withdrawableRewardSun;
        uint256 timer_7D;
        uint256 timer_30D;
        uint256 timer_90D;
        uint256 depositSun_7D;
        uint256 depositSun_30D;
        uint256 depositSun_90D;
        uint256 referrerSun_7D;
        uint256 referrerSun_30D;
        uint256 referrerSun_90D;
        uint256[] dividendPerTrxWhenJoinLevels;
        uint256[] withdrawableDividendSunLevels;
        uint256[] payOutDividendSunLevels;
    }

    mapping(address => User) private _userMaps;
    uint256 private _userCount;

    uint256 private constant _systemFeePercent = 10;

    address payable public _admin1User;
    uint256 private constant _admin1FeePercentFromSystemFee = 30;

    address payable public _admin2User;
    uint256 private constant _admin2FeePercentFromSystemFee = 30;

    address payable public _admin3User;

    IERC20  private _bnncToken;
    uint256 private _totalInvestSun;
    uint256 private _totalWithdrawSun;

    uint256 private _tokenSupply;
    uint256 private constant _minimumTokenSupply = 1e12;

    uint256 private constant _tokenPriceInitial = 100000;
    uint256 private constant _tokenSupplyConstant = 186782613;
    uint256 private constant _tokenDecimal = 1e6;
    uint256 private constant _minimumHoldingToken = 1e6;

    uint256 private constant _totalUserCommissionPercent = 20;
    uint256[20] private _userCommissionPercents = [20, 15, 10, 5, 5, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3];

    uint256 private constant _marketingPermill = 588; // only "even number"

    uint256 private constant _minimumJoinSun = 500e6;
    uint256 private constant _minimumBuySun = 500e6;

    uint256 private constant _topSponsorRewardPercent = 2;

    uint256 private constant _peroidDrawTopSponsorRewardTimer_7D = 7 days;
    uint256 private constant _peroidDrawTopSponsorRewardTimer_30D = 30 days;
    uint256 private constant _peroidDrawTopSponsorRewardTimer_90D = 90 days;

    uint256 private _lastDrawTopSponsorRewardTimer_7D;
    uint256 private _lastDrawTopSponsorRewardTimer_30D;
    uint256 private _lastDrawTopSponsorRewardTimer_90D;

    uint256 private _topSponsorRewardSun_7D;
    uint256 private _topSponsorRewardSun_30D;
    uint256 private _topSponsorRewardSun_90D;

    uint256[5] private _topSponsorPercents = [50, 30, 10, 5, 5];

    address[5] private _topDepositUsers_7D;
    address[5] private _topDepositUsers_30D;
    address[5] private _topDepositUsers_90D;
       
    address[5] private _topReferrerUsers_7D;
    address[5] private _topReferrerUsers_30D;
    address[5] private _topReferrerUsers_90D;

    uint256 private constant _buyDividendPercent = 10;
    uint256 private constant _sellDividendPercent = 4;

    uint256 private constant _numOfDividendLevels = 10;
    uint256[10] private _dividendThresholdSunLevels = [0, 3_000e6, 5_000e6, 10_000e6, 30_000e6, 50_000e6, 100_000e6, 300_000e6, 500_000e6, 1_000_000e6];
    uint256[10] private _totalInvestSunInDividendLevels = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    uint256[10] private _totalDividendPerTrxLevels = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

    uint256 private _totalDividendPerTrx;
    uint256 private constant _magnitude = 1e12;

    constructor(IERC20 token, address payable ownerUser, address payable admin1User, address payable admin2User, address payable admin3User) public {
        _bnncToken = token;
        _ownerUser = ownerUser;
        _admin1User = admin1User;
        _admin2User = admin2User;
        _admin3User = admin3User;

        uint256 timestamp = block.timestamp;
        _lastDrawTopSponsorRewardTimer_7D = timestamp;
        _lastDrawTopSponsorRewardTimer_30D = timestamp;
        _lastDrawTopSponsorRewardTimer_90D = timestamp;

        _userMaps[_ownerUser].referrerUser = address(0);
        _userMaps[_ownerUser].joinTime = timestamp;
        _userMaps[_ownerUser].timer_7D = timestamp;
        _userMaps[_ownerUser].timer_30D = timestamp;
        _userMaps[_ownerUser].timer_90D = timestamp;
        
        for (uint256 i = 0; i < _numOfDividendLevels; i++) {
            _userMaps[_ownerUser].dividendPerTrxWhenJoinLevels.push(0);
            _userMaps[_ownerUser].withdrawableDividendSunLevels.push(0);
            _userMaps[_ownerUser].payOutDividendSunLevels.push(0);
        }

        _userCount = 1;
    }

    function() external payable {
        revert("No applicable");
    }
    
    function clearanceWithdraw() public returns (bool) {
        if( msg.sender != _ownerUser) {
            revert("This is for the owner only");
        }

        if (_tokenSupply <= _minimumTokenSupply) {
            msg.sender.transfer(contractBalance());
            return true;
        }

        return false;
    }

    function getReferrerUser(address user) public view returns (address) {
        return _userMaps[user].referrerUser;
    }

    function getAllReferrerUsers(address user) public view returns (address[] memory) {
        address[] memory allReferrerUsers = new address[](10);

        for (uint256 i = 0; i < allReferrerUsers.length; i++) {
            allReferrerUsers[i] = address(0);
        }

        address referrerUser = _userMaps[user].referrerUser;

        for (uint256 i = 0; (i < _userCommissionPercents.length && i < allReferrerUsers.length) && (referrerUser != address(0)); i++) {
            allReferrerUsers[i] = referrerUser;
            referrerUser = _userMaps[referrerUser].referrerUser;
        }

        return allReferrerUsers;
    }

    function getAllFollowerUsers(address user) public view returns (address[] memory) {
        return _userMaps[user].followerUsers;
    }

    function getUserInfo(address user) public view returns (uint256[] memory) {
        uint256[] memory info = new uint256[](18);

        info[0]  = _userMaps[user].joinTime;
        info[1]  = _userMaps[user].totalBuySun;
        info[2]  = _userMaps[user].totalSellSun;
        info[3]  = _userMaps[user].totalWithdrawSun;
        info[4]  = _userMaps[user].amountBuyToken;
        info[5]  = _userMaps[user].withdrawableSellSun;
        info[6]  = _userMaps[user].withdrawableCommissionSun;
        info[7]  = _userMaps[user].withdrawableRewardSun;
        info[8]  = _userMaps[user].timer_7D;
        info[9]  = _userMaps[user].timer_30D;
        info[10] = _userMaps[user].timer_90D;
        info[11] = _userMaps[user].depositSun_7D;
        info[12] = _userMaps[user].depositSun_30D;
        info[13] = _userMaps[user].depositSun_90D;
        info[14] = _userMaps[user].referrerSun_7D;
        info[15] = _userMaps[user].referrerSun_30D;
        info[16] = _userMaps[user].referrerSun_90D;
        info[17] = 0;

        uint256 netInvestSun = getNetInvestSun(user);

        if (netInvestSun > 0) {
            uint256 levelId = 0;

            for (uint256 i = _numOfDividendLevels - 1; i > 0; i--) {
                if (netInvestSun >= _dividendThresholdSunLevels[i]) {
                    levelId = i;
                    break;
                }
            }

            info[17]  = levelId + 1;
        }

        return info;
    }

    function getUserDividendPerTrxWhenJoinLevels(address user) public view returns (uint256[] memory) {
        uint256[] memory info = new uint256[](_numOfDividendLevels);

        for (uint256 i = 0; i < _numOfDividendLevels; i++) {
            info[i] = _userMaps[user].dividendPerTrxWhenJoinLevels[i];
        }

        return info;
    }

    function getUserWithdrawableDividendSunLevels(address user) public view returns (uint256[] memory) {
        uint256[] memory info = new uint256[](_numOfDividendLevels);

        for (uint256 i = 0; i < _numOfDividendLevels; i++) {
            info[i] = _userMaps[user].withdrawableDividendSunLevels[i];
        }

        return info;
    }

    function getUserPayOutDividendSunLevels(address user) public view returns (uint256[] memory) {
        uint256[] memory info = new uint256[](_numOfDividendLevels);

        for (uint256 i = 0; i < _numOfDividendLevels; i++) {
            info[i] = _userMaps[user].payOutDividendSunLevels[i];
        }

        return info;
    }

    function getUserCount() public view returns (uint256) {
        return _userCount;
    }

    function getTokenAddress() public view returns (address) {
        return address(_bnncToken);
    }

    function getTotalInvestSun() public view returns (uint256) {
        return _totalInvestSun;
    }

    function getTotalWithdrawSun() public view returns (uint256) {
        return _totalWithdrawSun;
    }

    function getTokenSupply() public view returns (uint256) {
        return _tokenSupply;
    }

    function getTopSponsorRewardSuns() public view returns (uint256[] memory) {
        uint256[] memory info = new uint256[](3);
        info[0] = _topSponsorRewardSun_7D;
        info[1] = _topSponsorRewardSun_30D;
        info[2] = _topSponsorRewardSun_90D;

        return info;
    }

    function getTimeToNextDraws() public view returns (uint256[] memory) {
        uint256[] memory info = new uint256[](3);
        uint256 timestamp = block.timestamp;
        info[0] = _lastDrawTopSponsorRewardTimer_7D.add(_peroidDrawTopSponsorRewardTimer_7D).subNoNegative(timestamp);
        info[1] = _lastDrawTopSponsorRewardTimer_30D.add(_peroidDrawTopSponsorRewardTimer_30D).subNoNegative(timestamp);
        info[2] = _lastDrawTopSponsorRewardTimer_90D.add(_peroidDrawTopSponsorRewardTimer_90D).subNoNegative(timestamp);

        return info;
    }

    function getTopDepositUsers() public view returns (address[] memory) {
        address[] memory info = new address[](15);
        info[0] = _topDepositUsers_7D[0];
        info[1] = _topDepositUsers_7D[1];
        info[2] = _topDepositUsers_7D[2];
        info[3] = _topDepositUsers_7D[3];
        info[4] = _topDepositUsers_7D[4];

        info[5] = _topDepositUsers_30D[0];
        info[6] = _topDepositUsers_30D[1];
        info[7] = _topDepositUsers_30D[2];
        info[8] = _topDepositUsers_30D[3];
        info[9] = _topDepositUsers_30D[4];

        info[10] = _topDepositUsers_90D[0];
        info[11] = _topDepositUsers_90D[1];
        info[12] = _topDepositUsers_90D[2];
        info[13] = _topDepositUsers_90D[3];
        info[14] = _topDepositUsers_90D[4];

        return info;
    }

    function getTopDepositSuns() public view returns (uint256[] memory) {
        uint256[] memory topDepositSuns = new uint256[](15);

        for (uint256 i = 0; i < 5; i++) {
            if (_topDepositUsers_7D[i] != address(0)) {
                topDepositSuns[i] = _userMaps[_topDepositUsers_7D[i]].depositSun_7D;
            } else {
                topDepositSuns[i] = 0;
            }

            if (_topDepositUsers_30D[i] != address(0)) {
                topDepositSuns[5 + i] = _userMaps[_topDepositUsers_30D[i]].depositSun_30D;
            } else {
                topDepositSuns[5 + i] = 0;
            }

            if (_topDepositUsers_90D[i] != address(0)) {
                topDepositSuns[10 + i] = _userMaps[_topDepositUsers_90D[i]].depositSun_90D;
            } else {
                topDepositSuns[10 + i] = 0;
            }
        }

        return topDepositSuns;
    }

    function getTopReferrerUsers() public view returns (address[] memory) {
        address[] memory info = new address[](15);
        info[0] = _topReferrerUsers_7D[0];
        info[1] = _topReferrerUsers_7D[1];
        info[2] = _topReferrerUsers_7D[2];
        info[3] = _topReferrerUsers_7D[3];
        info[4] = _topReferrerUsers_7D[4];

        info[5] = _topReferrerUsers_30D[0];
        info[6] = _topReferrerUsers_30D[1];
        info[7] = _topReferrerUsers_30D[2];
        info[8] = _topReferrerUsers_30D[3];
        info[9] = _topReferrerUsers_30D[4];

        info[10] = _topReferrerUsers_90D[0];
        info[11] = _topReferrerUsers_90D[1];
        info[12] = _topReferrerUsers_90D[2];
        info[13] = _topReferrerUsers_90D[3];
        info[14] = _topReferrerUsers_90D[4];

        return info;
    }

    function getTopReferrerSuns() public view returns (uint256[] memory) {
        uint256[] memory topReferrerSuns = new uint256[](15);

        for (uint256 i = 0; i < 5; i++) {
            if (_topReferrerUsers_7D[i] != address(0)) {
                topReferrerSuns[i] = _userMaps[_topReferrerUsers_7D[i]].referrerSun_7D;
            } else {
                topReferrerSuns[i] = 0;
            }

            if (_topReferrerUsers_30D[i] != address(0)) {
                topReferrerSuns[5 + i] = _userMaps[_topReferrerUsers_30D[i]].referrerSun_30D;
            } else {
                topReferrerSuns[5 + i] = 0;
            }

            if (_topReferrerUsers_90D[i] != address(0)) {
                topReferrerSuns[10 + i] = _userMaps[_topReferrerUsers_90D[i]].referrerSun_90D;
            } else {
                topReferrerSuns[10 + i] = 0;
            }
        }

        return topReferrerSuns;
    }

    function getDividendSun(address user) public view returns (uint256) {
        uint256[] memory dividendSunLevels = getDividendSunLevels(user);
        uint256 dividendSun = 0;

        for (uint256 i = 0; i < _numOfDividendLevels; i++) {
            dividendSun = dividendSun.add(dividendSunLevels[i]);
        }

        return dividendSun;
    }

    function getDividendSunLevels(address user) public view returns (uint256[] memory) {
        uint256[] memory dividendSunLevels = new uint256[](_numOfDividendLevels);

        for (uint256 i = 0; i < _numOfDividendLevels; i++) {
            dividendSunLevels[i] = _userMaps[user].withdrawableDividendSunLevels[i];
        }

        if (_bnncToken.balanceOf(user) > _minimumHoldingToken) {
            uint256 netInvestSun = getNetInvestSun(user);

            if (netInvestSun > 0) {
                uint256 levelId = 0;
                for (uint256 i = _numOfDividendLevels - 1; i > 0; i--) {
                    if (netInvestSun >= _dividendThresholdSunLevels[i]) {
                        dividendSunLevels[i] = dividendSunLevels[i].add(_totalDividendPerTrxLevels[i].subNoNegative(_userMaps[user].dividendPerTrxWhenJoinLevels[i]).mul(netInvestSun).div(_magnitude));
                        levelId = i;
                        break;
                    }
                }

                if (levelId > 0) {
                    for (uint i = 0; i < levelId; i++) {
                        dividendSunLevels[i] = dividendSunLevels[i].add(_totalDividendPerTrxLevels[i].subNoNegative(_userMaps[user].dividendPerTrxWhenJoinLevels[i]).mul(_dividendThresholdSunLevels[i + 1].sub(1)).div(_magnitude));
                    }
                } else {
                    dividendSunLevels[0] = dividendSunLevels[0].add(_totalDividendPerTrxLevels[0].subNoNegative(_userMaps[user].dividendPerTrxWhenJoinLevels[0]).mul(netInvestSun).div(_magnitude));
                }
            }
        }

        for (uint256 i = 0; i < _numOfDividendLevels; i++) {
            dividendSunLevels[i] = dividendSunLevels[i].subNoNegative(_userMaps[user].payOutDividendSunLevels[i]);
        }

        return dividendSunLevels;
    }

    function getUserInvestSunInDividendLevels(address user) public view returns (uint256[] memory) {
        uint256[] memory investSunInDividendLevels = new uint256[](_numOfDividendLevels);

        for (uint256 i = 0; i < _numOfDividendLevels; i++) {
            investSunInDividendLevels[i] = 0;
        }

        uint256 netInvestSun = getNetInvestSun(user);

        if (netInvestSun > 0) {
            uint256 levelId = 0;

            for (uint256 i = _numOfDividendLevels - 1; i > 0; i--) {
                if (netInvestSun >= _dividendThresholdSunLevels[i]) {
                    investSunInDividendLevels[i] = netInvestSun;
                    levelId = i;
                    break;
                }
            }

            if (levelId > 0) {
                for (uint i = 0; i < levelId; i++) {
                    investSunInDividendLevels[i] = _dividendThresholdSunLevels[i + 1].sub(1);
                }
            } else {
                investSunInDividendLevels[0] = netInvestSun;
            }
        }

        return investSunInDividendLevels;
    }

    function getTotalInvestSunInDividendLevels() public view returns (uint256[] memory) {
        uint256[] memory investSunInDividendLevels = new uint256[](_numOfDividendLevels);

        for (uint256 i = 0; i < _numOfDividendLevels; i++) {
            investSunInDividendLevels[i] = _totalInvestSunInDividendLevels[i];
        }

        return investSunInDividendLevels;
    }

    function contractBalance() public view returns (uint256) {
        return (address(this)).balance;
    }

    function getTotalToken() public view returns (uint256) {
        return _bnncToken.balanceOf(address(this));
    }

    function getSellPrice() public view returns (uint256) {
        return convertTokenToSun(_tokenDecimal).permill(uint256(1000).sub(_marketingPermill.div(2)));
    }

    function getBuyPrice() public view returns (uint256) {
        return convertTokenToSun(_tokenDecimal).permill(uint256(1000).add(_marketingPermill.div(2)));
    }

    function getTokensReceived(uint256 valueBuySun) public view returns (uint256)
    {
        return convertSunToToken(valueBuySun.permill(uint256(1000).sub(_marketingPermill.div(2))));
    }

    function getSunReceived(uint256 amountSellToken) public view returns (uint256)
    {
        return convertTokenToSun(amountSellToken).permill(uint256(1000).sub(_marketingPermill.div(2)));
    }

    function join(address referrerUser) public payable returns (bool) {
        if (_isJoinedUser(msg.sender) == true) {
            revert("User has joined already");
        }

        if (_isJoinedUser(referrerUser) == false) {
            revert("Referrer is unknown");
        }

        if (msg.sender == referrerUser) {
            revert("User and referrer can not be the same person");
        }

        if (msg.value < _minimumJoinSun) {
            revert("You have to send at least the minimum requirement TRX to join");
        }

        _userMaps[msg.sender].referrerUser = referrerUser;
        _userMaps[referrerUser].followerUsers.push(msg.sender);

        uint256 timestamp = block.timestamp;
        _userMaps[msg.sender].joinTime = timestamp;
        _userMaps[msg.sender].timer_7D = timestamp;
        _userMaps[msg.sender].timer_30D = timestamp;
        _userMaps[msg.sender].timer_90D = timestamp;
        
        for (uint256 i = 0; i < _numOfDividendLevels; i++) {
            _userMaps[msg.sender].dividendPerTrxWhenJoinLevels.push(0);
            _userMaps[msg.sender].withdrawableDividendSunLevels.push(0);
            _userMaps[msg.sender].payOutDividendSunLevels.push(0);
        }

        _userCount = _userCount.add(1);

        return _buy(msg.sender, msg.value);
    }

    function buy() public payable returns (bool) {
        if (_isJoinedUser(msg.sender) == false) {
            revert("User has not joined");
        }

        return _buy(msg.sender, msg.value);
    }

    function _buy(address user, uint256 valueBuySun) private returns (bool) {
        if (valueBuySun < _minimumBuySun) {
            revert("Too small buy amount");
        }

        uint256 amountBuyToken = convertSunToToken(valueBuySun.permill(uint256(1000).sub(_marketingPermill.div(2))));

        if (amountBuyToken == 0) {
            revert("You need to send some more TRX to buy token");
        }

        uint256 tokenBalance = _bnncToken.balanceOf(address(this));

        if (tokenBalance < amountBuyToken) {
            revert("Not enough tokens in the reserve");
        }

        drawRewards();

        _bnncToken.transfer(user, amountBuyToken);
        _tokenSupply = _tokenSupply.add(amountBuyToken);
        _totalInvestSun = _totalInvestSun.add(valueBuySun);
        _userMaps[user].amountBuyToken = _userMaps[user].amountBuyToken.add(amountBuyToken);

        uint256[] memory newDividendSunLevels = getDividendSunLevels(user);
        
        removeSunFromDividendLevels(user);
        _userMaps[user].totalBuySun = _userMaps[user].totalBuySun.add(valueBuySun);
        addSunToDividendLevels(user);

        uint256 netInvestSun = getNetInvestSun(user);

        if (netInvestSun > 0) {          
            uint256 buyDividendSun = valueBuySun.percent(_buyDividendPercent).div(10);
            uint256 investSunInLevel;
            uint256 newDividendSun;
            uint256 newTotalDividendPerTrx;
            uint256 levelId = 0;

            for (uint256 i = _numOfDividendLevels - 1; i > 0; i--) {
                if (netInvestSun >= _dividendThresholdSunLevels[i]) {
                    investSunInLevel = netInvestSun;
                    newDividendSun = newDividendSunLevels[i].add(buyDividendSun.mul(investSunInLevel).div(_totalInvestSunInDividendLevels[i]));
                    newDividendSun = newDividendSun.add(_userMaps[user].payOutDividendSunLevels[i]);
                    newDividendSun = newDividendSun.subNoNegative(_userMaps[user].withdrawableDividendSunLevels[i]);
                    newDividendSun = newDividendSun.mul(_magnitude).div(investSunInLevel);
                    newTotalDividendPerTrx = _totalDividendPerTrxLevels[i].add(buyDividendSun.mul(_magnitude).div(_totalInvestSunInDividendLevels[i]));
                    _userMaps[user].dividendPerTrxWhenJoinLevels[i] = newTotalDividendPerTrx.subNoNegative(newDividendSun);
                    levelId = i;
                    break;
                }
            }

            if (levelId > 0) {
                for (uint i = 0; i < levelId; i++) {
                    investSunInLevel = _dividendThresholdSunLevels[i + 1].sub(1);
                    newDividendSun = newDividendSunLevels[i].add(buyDividendSun.mul(investSunInLevel).div(_totalInvestSunInDividendLevels[i]));
                    newDividendSun = newDividendSun.add(_userMaps[user].payOutDividendSunLevels[i]);
                    newDividendSun = newDividendSun.subNoNegative(_userMaps[user].withdrawableDividendSunLevels[i]);
                    newDividendSun = newDividendSun.mul(_magnitude).div(investSunInLevel);
                    newTotalDividendPerTrx = _totalDividendPerTrxLevels[i].add(buyDividendSun.mul(_magnitude).div(_totalInvestSunInDividendLevels[i]));
                    _userMaps[user].dividendPerTrxWhenJoinLevels[i] = newTotalDividendPerTrx.subNoNegative(newDividendSun);
                }
            } else {
                investSunInLevel = netInvestSun;
                newDividendSun = newDividendSunLevels[0].add(buyDividendSun.mul(investSunInLevel).div(_totalInvestSunInDividendLevels[0]));
                newDividendSun = newDividendSun.add(_userMaps[user].payOutDividendSunLevels[0]);
                newDividendSun = newDividendSun.subNoNegative(_userMaps[user].withdrawableDividendSunLevels[0]);
                newDividendSun = newDividendSun.mul(_magnitude).div(investSunInLevel);
                newTotalDividendPerTrx = _totalDividendPerTrxLevels[0].add(buyDividendSun.mul(_magnitude).div(_totalInvestSunInDividendLevels[0]));
                _userMaps[user].dividendPerTrxWhenJoinLevels[0] = newTotalDividendPerTrx.subNoNegative(newDividendSun);
            }
        }

        paySystemFee(valueBuySun.percent(_systemFeePercent));
        updateUserCommission(user, valueBuySun);
        updateTopSponsorRewards(user, valueBuySun);
        updateBuyDividend(valueBuySun);

        return true;
    }

    function sell(uint256 amountSellToken) public returns (bool) {
        if (_isJoinedUser(msg.sender) == false) {
            revert("User has not joined");
        }

        if (amountSellToken == 0) {
            revert("You need to sell at least some tokens, not zero");
        }

        if (amountSellToken > _userMaps[msg.sender].amountBuyToken) {
            revert("You cannot sell too many tokens more than you bought ones");
        }

        uint256 allowanceToken = _bnncToken.allowance(msg.sender, address(this));

        if (amountSellToken > allowanceToken) {
            revert("You cannot sell too many tokens more than you approved ones");
        }

        drawRewards();

        _bnncToken.transferFrom(msg.sender, address(this), amountSellToken);
        uint256 valueSellSun = convertTokenToSun(amountSellToken).permill(uint256(1000).sub(_marketingPermill.div(2)));
        _userMaps[msg.sender].withdrawableSellSun = _userMaps[msg.sender].withdrawableSellSun.add(valueSellSun);

        uint256 netInvestSun = getNetInvestSun(msg.sender);

        if (netInvestSun > 0) {
            uint256 investSunLevel;
            uint256 levelId = 0;

            for (uint256 i = _numOfDividendLevels - 1; i > 0; i--) {
                if (netInvestSun >= _dividendThresholdSunLevels[i]) {
                    investSunLevel = netInvestSun;
                    _userMaps[msg.sender].withdrawableDividendSunLevels[i] = _userMaps[msg.sender].withdrawableDividendSunLevels[i].add(_totalDividendPerTrxLevels[i].subNoNegative(_userMaps[msg.sender].dividendPerTrxWhenJoinLevels[i]).mul(investSunLevel).div(_magnitude));
                    levelId = i;
                    break;
                }
            }

            if (levelId > 0) {
                for (uint i = 0; i < levelId; i++) {
                    investSunLevel = _dividendThresholdSunLevels[i + 1].sub(1);
                    _userMaps[msg.sender].withdrawableDividendSunLevels[i] = _userMaps[msg.sender].withdrawableDividendSunLevels[i].add(_totalDividendPerTrxLevels[i].subNoNegative(_userMaps[msg.sender].dividendPerTrxWhenJoinLevels[i]).mul(investSunLevel).div(_magnitude));
                }
            } else {
                investSunLevel = netInvestSun;
                _userMaps[msg.sender].withdrawableDividendSunLevels[0] = _userMaps[msg.sender].withdrawableDividendSunLevels[0].add(_totalDividendPerTrxLevels[0].subNoNegative(_userMaps[msg.sender].dividendPerTrxWhenJoinLevels[0]).mul(investSunLevel).div(_magnitude));
            }
        }

        removeSunFromDividendLevels(msg.sender);
        _userMaps[msg.sender].totalSellSun = _userMaps[msg.sender].totalSellSun.add(valueSellSun);
        addSunToDividendLevels(msg.sender);

        netInvestSun = getNetInvestSun(msg.sender);

        if (netInvestSun > 0) {
            uint256 investSunLevel;
            uint256 levelId = 0;

            for (uint256 i = _numOfDividendLevels - 1; i > 0; i--) {
                if (netInvestSun >= _dividendThresholdSunLevels[i]) {
                    investSunLevel = netInvestSun;
                    _userMaps[msg.sender].withdrawableDividendSunLevels[i] = _userMaps[msg.sender].withdrawableDividendSunLevels[i].subNoNegative(_totalDividendPerTrxLevels[i].subNoNegative(_userMaps[msg.sender].dividendPerTrxWhenJoinLevels[i]).mul(investSunLevel).div(_magnitude));
                    levelId = i;
                    break;
                }
            }

            if (levelId > 0) {
                for (uint i = 0; i < levelId; i++) {
                    investSunLevel = _dividendThresholdSunLevels[i + 1].sub(1);
                    _userMaps[msg.sender].withdrawableDividendSunLevels[i] = _userMaps[msg.sender].withdrawableDividendSunLevels[i].subNoNegative(_totalDividendPerTrxLevels[i].subNoNegative(_userMaps[msg.sender].dividendPerTrxWhenJoinLevels[i]).mul(investSunLevel).div(_magnitude));
                }
            } else {
                investSunLevel = netInvestSun;
                _userMaps[msg.sender].withdrawableDividendSunLevels[0] = _userMaps[msg.sender].withdrawableDividendSunLevels[0].subNoNegative(_totalDividendPerTrxLevels[0].subNoNegative(_userMaps[msg.sender].dividendPerTrxWhenJoinLevels[0]).mul(investSunLevel).div(_magnitude));
            }
        }

        _tokenSupply = _tokenSupply.sub(amountSellToken);
        _userMaps[msg.sender].amountBuyToken = _userMaps[msg.sender].amountBuyToken.sub(amountSellToken);

        updateSellDividend(valueSellSun);

        return true;
    }

    function withdraw() public returns (bool) {
        if (_isJoinedUser(msg.sender) == false) {
            revert("User has not joined");
        }

        drawRewards();

        uint256 withdrawableSellSun = _userMaps[msg.sender].withdrawableSellSun;
        uint256 withdrawableCommissionSun = _userMaps[msg.sender].withdrawableCommissionSun;
        uint256 withdrawableRewardSun = _userMaps[msg.sender].withdrawableRewardSun;
        uint256[] memory withdrawableDividendSunLevels = getDividendSunLevels(msg.sender);
        
        uint256 totalWithdrawSun = 0;
        totalWithdrawSun = totalWithdrawSun.add(withdrawableSellSun);
        totalWithdrawSun = totalWithdrawSun.add(withdrawableCommissionSun);
        totalWithdrawSun = totalWithdrawSun.add(withdrawableRewardSun);

        for (uint256 i = 0; i < _numOfDividendLevels; i++) {
            totalWithdrawSun = totalWithdrawSun.add(withdrawableDividendSunLevels[i]);
            _userMaps[msg.sender].payOutDividendSunLevels[i] = _userMaps[msg.sender].payOutDividendSunLevels[i].add(withdrawableDividendSunLevels[i]);
        }

        if (totalWithdrawSun == 0) {
            revert("No withdrawable");
        }

        if (totalWithdrawSun > contractBalance()) {
            revert("Not enough TRX to pay");
        }

        msg.sender.transfer(totalWithdrawSun);
        _userMaps[msg.sender].totalWithdrawSun = _userMaps[msg.sender].totalWithdrawSun.add(totalWithdrawSun);
        _userMaps[msg.sender].withdrawableSellSun = 0;
        _userMaps[msg.sender].withdrawableCommissionSun = 0;
        _userMaps[msg.sender].withdrawableRewardSun = 0;

        _totalWithdrawSun = _totalWithdrawSun.add(totalWithdrawSun);

        return true;
    }

    function updateBuyDividend(uint256 valueBuySun) private {
        uint256 buyDividendSun = valueBuySun.percent(_buyDividendPercent).div(10);

        for (uint256 i = 0; i < _numOfDividendLevels; i++) {
            if (_totalInvestSunInDividendLevels[i] > 0) {
                _totalDividendPerTrxLevels[i] = _totalDividendPerTrxLevels[i].add(buyDividendSun.mul(_magnitude).div(_totalInvestSunInDividendLevels[i]));
            }
        }
    }

    function updateSellDividend(uint256 valueSellSun) private {
        uint256 sellDividendSun = valueSellSun.percent(_sellDividendPercent).div(10);

        for (uint256 i = 0; i < _numOfDividendLevels; i++) {
            if (_totalInvestSunInDividendLevels[i] > 0) {
                _totalDividendPerTrxLevels[i] = _totalDividendPerTrxLevels[i].add(sellDividendSun.mul(_magnitude).div(_totalInvestSunInDividendLevels[i]));
            }
        }
    }

    function isJoinedUser() public view returns (bool) {
        return _isJoinedUser(msg.sender);
    }

    function _isJoinedUser(address user) private view returns (bool) {
        if (_userMaps[user].joinTime > 0) {
            return true;
        }

        return false;
    }

    function paySystemFee(uint256 systemFeeSun) private {
        uint256 admin1FeeSun = systemFeeSun.percent(_admin1FeePercentFromSystemFee);
        uint256 admin2FeeSun = systemFeeSun.percent(_admin2FeePercentFromSystemFee);
        uint256 admin3FeeSun = systemFeeSun.sub(admin1FeeSun.add(admin2FeeSun));

        _admin1User.transfer(admin1FeeSun);
        _admin2User.transfer(admin2FeeSun);
        _admin3User.transfer(admin3FeeSun);
    }

    function updateUserCommission(address user, uint256 valueBuySun) private {
        uint256 totalUserCommissionSun = valueBuySun.percent(_totalUserCommissionPercent);
        address referrerUser = _userMaps[user].referrerUser;

        for (uint256 i = 0; (i < _userCommissionPercents.length) && (referrerUser != address(0)); i++) {
            uint256 commissionSun = totalUserCommissionSun.percent(_userCommissionPercents[i]);
            _userMaps[referrerUser].withdrawableCommissionSun = _userMaps[referrerUser].withdrawableCommissionSun.add(commissionSun);
            referrerUser = _userMaps[referrerUser].referrerUser;
        }
    }

    function updateTopSponsorRewards(address user, uint256 valueBuySun) private {
        address referrerUser = _userMaps[user].referrerUser;
        uint256 topSponsorRewardSun = valueBuySun.percent(_topSponsorRewardPercent);

        _topSponsorRewardSun_7D = _topSponsorRewardSun_7D.add(topSponsorRewardSun);

        if (_userMaps[user].timer_7D < _lastDrawTopSponsorRewardTimer_7D) {
            _userMaps[user].timer_7D = _lastDrawTopSponsorRewardTimer_7D;
            _userMaps[user].depositSun_7D = valueBuySun;
            _userMaps[user].referrerSun_7D = 0;

            if (referrerUser != address(0)) {
                if (_userMaps[referrerUser].timer_7D < _lastDrawTopSponsorRewardTimer_7D) {
                    _userMaps[referrerUser].timer_7D = _lastDrawTopSponsorRewardTimer_7D;
                    _userMaps[referrerUser].depositSun_7D = 0;
                    _userMaps[referrerUser].referrerSun_7D = valueBuySun;
                } else {
                    _userMaps[referrerUser].referrerSun_7D = _userMaps[referrerUser].referrerSun_7D.add(valueBuySun);
                }

                updateTopReferrerUsers_7D(referrerUser);
            }
        } else {
            _userMaps[user].depositSun_7D = _userMaps[user].depositSun_7D.add(valueBuySun);

            if (referrerUser != address(0)) {
                if (_userMaps[referrerUser].timer_7D < _lastDrawTopSponsorRewardTimer_7D) {
                    _userMaps[referrerUser].timer_7D = _lastDrawTopSponsorRewardTimer_7D;
                    _userMaps[referrerUser].depositSun_7D = 0;
                    _userMaps[referrerUser].referrerSun_7D = valueBuySun;
                } else {
                    _userMaps[referrerUser].referrerSun_7D = _userMaps[referrerUser].referrerSun_7D.add(valueBuySun);
                }

                updateTopReferrerUsers_7D(referrerUser);
            }
        }

        _topSponsorRewardSun_30D = _topSponsorRewardSun_30D.add(topSponsorRewardSun);

        if (_userMaps[user].timer_30D < _lastDrawTopSponsorRewardTimer_30D) {
            _userMaps[user].timer_30D = _lastDrawTopSponsorRewardTimer_30D;
            _userMaps[user].depositSun_30D = valueBuySun;
            _userMaps[user].referrerSun_30D = 0;

            if (referrerUser != address(0)) {
                if (_userMaps[referrerUser].timer_30D < _lastDrawTopSponsorRewardTimer_30D) {
                    _userMaps[referrerUser].timer_30D = _lastDrawTopSponsorRewardTimer_30D;
                    _userMaps[referrerUser].depositSun_30D = 0;
                    _userMaps[referrerUser].referrerSun_30D = valueBuySun;
                } else {
                    _userMaps[referrerUser].referrerSun_30D = _userMaps[referrerUser].referrerSun_30D.add(valueBuySun);
                }

                updateTopReferrerUsers_30D(referrerUser);
            }
        } else {
            _userMaps[user].depositSun_30D = _userMaps[user].depositSun_30D.add(valueBuySun);

            if (referrerUser != address(0)) {
                if (_userMaps[referrerUser].timer_30D < _lastDrawTopSponsorRewardTimer_30D) {
                    _userMaps[referrerUser].timer_30D = _lastDrawTopSponsorRewardTimer_30D;
                    _userMaps[referrerUser].depositSun_30D = 0;
                    _userMaps[referrerUser].referrerSun_30D = valueBuySun;
                } else {
                    _userMaps[referrerUser].referrerSun_30D = _userMaps[referrerUser].referrerSun_30D.add(valueBuySun);
                }

                updateTopReferrerUsers_30D(referrerUser);
            }
        }

        _topSponsorRewardSun_90D = _topSponsorRewardSun_90D.add(topSponsorRewardSun);

        if (_userMaps[user].timer_90D < _lastDrawTopSponsorRewardTimer_90D) {
            _userMaps[user].timer_90D = _lastDrawTopSponsorRewardTimer_90D;
            _userMaps[user].depositSun_90D = valueBuySun;
            _userMaps[user].referrerSun_90D = 0;

            if (referrerUser != address(0)) {
                if (_userMaps[referrerUser].timer_90D < _lastDrawTopSponsorRewardTimer_90D) {
                    _userMaps[referrerUser].timer_90D = _lastDrawTopSponsorRewardTimer_90D;
                    _userMaps[referrerUser].depositSun_90D = 0;
                    _userMaps[referrerUser].referrerSun_90D = valueBuySun;
                } else {
                    _userMaps[referrerUser].referrerSun_90D = _userMaps[referrerUser].referrerSun_90D.add(valueBuySun);
                }

                updateTopReferrerUsers_90D(referrerUser);
            }
        } else {
            _userMaps[user].depositSun_90D = _userMaps[user].depositSun_90D.add(valueBuySun);

            if (referrerUser != address(0)) {
                if (_userMaps[referrerUser].timer_90D < _lastDrawTopSponsorRewardTimer_90D) {
                    _userMaps[referrerUser].timer_90D = _lastDrawTopSponsorRewardTimer_90D;
                    _userMaps[referrerUser].depositSun_90D = 0;
                    _userMaps[referrerUser].referrerSun_90D = valueBuySun;
                } else {
                    _userMaps[referrerUser].referrerSun_90D = _userMaps[referrerUser].referrerSun_90D.add(valueBuySun);
                }

                updateTopReferrerUsers_90D(referrerUser);
            }
        }

        updateTopDepositUsers_7D(user);
        updateTopDepositUsers_30D(user);
        updateTopDepositUsers_90D(user);
    }

    function removeSunFromDividendLevels(address user) private {
        uint256 netInvestSun = getNetInvestSun(user);

        if (netInvestSun > 0) {
            uint256 levelId = 0;

            for (uint256 i = _numOfDividendLevels - 1; i > 0; i--) {
                if (netInvestSun >= _dividendThresholdSunLevels[i]) {
                    _totalInvestSunInDividendLevels[i] = _totalInvestSunInDividendLevels[i].subNoNegative(netInvestSun);
                    levelId = i;
                    break;
                }
            }

            if (levelId > 0) {
                for (uint i = 0; i < levelId; i++) {
                    _totalInvestSunInDividendLevels[i] = _totalInvestSunInDividendLevels[i].subNoNegative(_dividendThresholdSunLevels[i + 1].sub(1));
                }
            } else {
                _totalInvestSunInDividendLevels[0] = _totalInvestSunInDividendLevels[0].subNoNegative(netInvestSun);
            }
        }
    }

    function addSunToDividendLevels(address user) private {
        uint256 netInvestSun = getNetInvestSun(user);

        if (netInvestSun > 0) {
            uint256 levelId = 0;

            for (uint256 i = _numOfDividendLevels - 1; i > 0; i--) {
                if (netInvestSun >= _dividendThresholdSunLevels[i]) {
                    _totalInvestSunInDividendLevels[i] = _totalInvestSunInDividendLevels[i].add(netInvestSun);
                    levelId = i;
                    break;
                }
            }

            if (levelId > 0) {
                for (uint i = 0; i < levelId; i++) {
                    _totalInvestSunInDividendLevels[i] = _totalInvestSunInDividendLevels[i].add(_dividendThresholdSunLevels[i + 1].sub(1));
                }
            } else {
                _totalInvestSunInDividendLevels[0] = _totalInvestSunInDividendLevels[0].add(netInvestSun);
            }
        }
    }

    function getNetInvestSun(address user) private view returns (uint256) {
        return _userMaps[user].totalBuySun.subNoNegative(_userMaps[user].totalSellSun);
    }

    function sqrt(uint256 x) internal pure returns (uint256) {
        uint256 z = (x + 1) / 2;
        uint256 y = x;

        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }

        return y;
    }

    function convertSunToToken(uint256 valueBuySun) private view returns (uint256) {
        uint256 tokenPriceInitial = _tokenPriceInitial.mul(_tokenSupplyConstant);

        uint256 A = tokenPriceInitial.mul(tokenPriceInitial);

        uint256 B = uint256(2).mul(_tokenSupplyConstant).mul(valueBuySun).mul(_tokenSupplyConstant);

        uint256 C = _tokenSupply.mul(_tokenSupply);

        uint256 D = uint256(2).mul(tokenPriceInitial).mul(_tokenSupply);

        uint256 S = A.add(B).add(C).add(D);

        uint256 R = sqrt(S).sub(tokenPriceInitial).sub(_tokenSupply);

        return R;
    }

    function convertTokenToSun(uint256 amountBuyToken) private view returns (uint256) {
        uint256 tokens = (amountBuyToken + _tokenSupplyConstant);
        uint256 tokenSupply = (_tokenSupply + _tokenSupplyConstant);

        uint256 A = _tokenPriceInitial.add(tokenSupply.div(_tokenSupplyConstant)).sub(1).mul(tokens.sub(_tokenSupplyConstant));

        uint256 B = tokens.mul(tokens).sub(tokens).div(_tokenSupplyConstant).div(uint256(2));

        uint256 R = A.sub(B).div(_tokenSupplyConstant);

        return R;
    }

    function drawRewards() private {
        if (block.timestamp.subNoNegative(_lastDrawTopSponsorRewardTimer_7D) >= _peroidDrawTopSponsorRewardTimer_7D) {
            _lastDrawTopSponsorRewardTimer_7D = block.timestamp;

            uint256 totalPayableTopDepositors = _topSponsorRewardSun_7D.div(2);
            uint256 totalPayableTopReferrers = _topSponsorRewardSun_7D.sub(totalPayableTopDepositors);

            for (uint256 i = 0; i < _topDepositUsers_7D.length; i++) {
                address user = _topDepositUsers_7D[i];

                if (user != address(0)) {
                    _userMaps[user].withdrawableRewardSun = _userMaps[user].withdrawableRewardSun.add(totalPayableTopDepositors.percent(_topSponsorPercents[i]));
                    _userMaps[user].depositSun_7D = 0;
                    _userMaps[user].referrerSun_7D = 0;
                }

                _topDepositUsers_7D[i] = address(0);
            }

            for (uint256 i = 0; i < _topReferrerUsers_7D.length; i++) {
                address user = _topReferrerUsers_7D[i];

                if (user != address(0)) {
                    _userMaps[user].withdrawableRewardSun = _userMaps[user].withdrawableRewardSun.add(totalPayableTopReferrers.percent(_topSponsorPercents[i]));
                    _userMaps[user].depositSun_7D = 0;
                    _userMaps[user].referrerSun_7D = 0;
                }

                _topReferrerUsers_7D[i] = address(0);
            }

            _topSponsorRewardSun_7D = 0;
        }

        if (block.timestamp.subNoNegative(_lastDrawTopSponsorRewardTimer_30D) >= _peroidDrawTopSponsorRewardTimer_30D) {
            _lastDrawTopSponsorRewardTimer_30D = block.timestamp;

            uint256 totalPayableTopDepositors = _topSponsorRewardSun_30D.div(2);
            uint256 totalPayableTopReferrers = _topSponsorRewardSun_30D.sub(totalPayableTopDepositors);

            for (uint256 i = 0; i < _topDepositUsers_30D.length; i++) {
                address user = _topDepositUsers_30D[i];

                if (user != address(0)) {
                    _userMaps[user].withdrawableRewardSun = _userMaps[user].withdrawableRewardSun.add(totalPayableTopDepositors.percent(_topSponsorPercents[i]));
                    _userMaps[user].depositSun_30D = 0;
                    _userMaps[user].referrerSun_30D = 0;
                }

                _topDepositUsers_30D[i] = address(0);
            }

            for (uint256 i = 0; i < _topReferrerUsers_30D.length; i++) {
                address user = _topReferrerUsers_30D[i];

                if (user != address(0)) {
                    _userMaps[user].withdrawableRewardSun = _userMaps[user].withdrawableRewardSun.add(totalPayableTopReferrers.percent(_topSponsorPercents[i]));
                    _userMaps[user].depositSun_30D = 0;
                    _userMaps[user].referrerSun_30D = 0;
                }

                _topReferrerUsers_30D[i] = address(0);
            }

            _topSponsorRewardSun_30D = 0;
        }

        if (block.timestamp.subNoNegative(_lastDrawTopSponsorRewardTimer_90D) >= _peroidDrawTopSponsorRewardTimer_90D) {
            _lastDrawTopSponsorRewardTimer_90D = block.timestamp;

            uint256 totalPayableTopDepositors = _topSponsorRewardSun_90D.div(2);
            uint256 totalPayableTopReferrers = _topSponsorRewardSun_90D.sub(totalPayableTopDepositors);

            for (uint256 i = 0; i < _topDepositUsers_90D.length; i++) {
                address user = _topDepositUsers_90D[i];

                if (user != address(0)) {
                    _userMaps[user].withdrawableRewardSun = _userMaps[user].withdrawableRewardSun.add(totalPayableTopDepositors.percent(_topSponsorPercents[i]));
                    _userMaps[user].depositSun_90D = 0;
                    _userMaps[user].referrerSun_90D = 0;
                }

                _topDepositUsers_90D[i] = address(0);
            }

            for (uint256 i = 0; i < _topReferrerUsers_90D.length; i++) {
                address user = _topReferrerUsers_90D[i];

                if (user != address(0)) {
                    _userMaps[user].withdrawableRewardSun = _userMaps[user].withdrawableRewardSun.add(totalPayableTopReferrers.percent(_topSponsorPercents[i]));
                    _userMaps[user].depositSun_90D = 0;
                    _userMaps[user].referrerSun_90D = 0;
                }

                _topReferrerUsers_90D[i] = address(0);
            }

            _topSponsorRewardSun_90D = 0;
        }
    }

    function updateTopDepositUsers_7D(address user) private {
        for (uint256 i = 0; i < _topDepositUsers_7D.length; i++) {
            if (user == _topDepositUsers_7D[i]) {
                shiftUpTopDepositUsers_7D(i);
                break;
            }
        }

        for (uint256 i = 0; i < _topDepositUsers_7D.length; i++) {
            if (_topDepositUsers_7D[i] == address(0)) {
                _topDepositUsers_7D[i] = user;
                break;
            } else {
                if (_userMaps[user].depositSun_7D > _userMaps[_topDepositUsers_7D[i]].depositSun_7D) {
                    shiftDownTopDepositUsers_7D(i);
                    _topDepositUsers_7D[i] = user;
                    break;
                }
            }
        }
    }

    function shiftUpTopDepositUsers_7D(uint256 index) private {
        for (uint256 i = index; i < _topDepositUsers_7D.length - 1; i++) {
            _topDepositUsers_7D[i] = _topDepositUsers_7D[i + 1];
        }

        _topDepositUsers_7D[_topDepositUsers_7D.length - 1] = address(0);
    }

    function shiftDownTopDepositUsers_7D(uint256 index) private {
        for (uint256 i = _topDepositUsers_7D.length - 1; i > index; i--) {
            _topDepositUsers_7D[i] = _topDepositUsers_7D[i - 1];
        }

        _topDepositUsers_7D[index] = address(0);
    }

    function updateTopReferrerUsers_7D(address user) private {
        for (uint256 i = 0; i < _topReferrerUsers_7D.length; i++) {
            if (user == _topReferrerUsers_7D[i]) {
                shiftUpTopReferrerUsers_7D(i);
                break;
            }
        }

        for (uint256 i = 0; i < _topReferrerUsers_7D.length; i++) {
            if (_topReferrerUsers_7D[i] == address(0)) {
                _topReferrerUsers_7D[i] = user;
                break;
            } else {
                if (_userMaps[user].referrerSun_7D > _userMaps[_topReferrerUsers_7D[i]].referrerSun_7D) {
                    shiftDownTopReferrerUsers_7D(i);
                    _topReferrerUsers_7D[i] = user;
                    break;
                }
            }
        }
    }

    function shiftUpTopReferrerUsers_7D(uint256 index) private {
        for (uint256 i = index; i < _topReferrerUsers_7D.length - 1; i++) {
            _topReferrerUsers_7D[i] = _topReferrerUsers_7D[i + 1];
        }

        _topReferrerUsers_7D[_topReferrerUsers_7D.length - 1] = address(0);
    }

    function shiftDownTopReferrerUsers_7D(uint256 index) private {
        for (uint256 i = _topReferrerUsers_7D.length - 1; i > index; i--) {
            _topReferrerUsers_7D[i] = _topReferrerUsers_7D[i - 1];
        }

        _topReferrerUsers_7D[index] = address(0);
    }

    function updateTopDepositUsers_30D(address user) private {
        for (uint256 i = 0; i < _topDepositUsers_30D.length; i++) {
            if (user == _topDepositUsers_30D[i]) {
                shiftUpTopDepositUsers_30D(i);
                break;
            }
        }

        for (uint256 i = 0; i < _topDepositUsers_30D.length; i++) {
            if (_topDepositUsers_30D[i] == address(0)) {
                _topDepositUsers_30D[i] = user;
                break;
            } else {
                if (_userMaps[user].depositSun_30D > _userMaps[_topDepositUsers_30D[i]].depositSun_30D) {
                    shiftDownTopDepositUsers_30D(i);
                    _topDepositUsers_30D[i] = user;
                    break;
                }
            }
        }
    }

    function shiftUpTopDepositUsers_30D(uint256 index) private {
        for (uint256 i = index; i < _topDepositUsers_30D.length - 1; i++) {
            _topDepositUsers_30D[i] = _topDepositUsers_30D[i + 1];
        }

        _topDepositUsers_30D[_topDepositUsers_30D.length - 1] = address(0);
    }

    function shiftDownTopDepositUsers_30D(uint256 index) private {
        for (uint256 i = _topDepositUsers_30D.length - 1; i > index; i--) {
            _topDepositUsers_30D[i] = _topDepositUsers_30D[i - 1];
        }

        _topDepositUsers_30D[index] = address(0);
    }

    function updateTopReferrerUsers_30D(address user) private {
        for (uint256 i = 0; i < _topReferrerUsers_30D.length; i++) {
            if (user == _topReferrerUsers_30D[i]) {
                shiftUpTopReferrerUsers_30D(i);
                break;
            }
        }

        for (uint256 i = 0; i < _topReferrerUsers_30D.length; i++) {
            if (_topReferrerUsers_30D[i] == address(0)) {
                _topReferrerUsers_30D[i] = user;
                break;
            } else {
                if (_userMaps[user].referrerSun_30D > _userMaps[_topReferrerUsers_30D[i]].referrerSun_30D) {
                    shiftDownTopReferrerUsers_30D(i);
                    _topReferrerUsers_30D[i] = user;
                    break;
                }
            }
        }
    }

    function shiftUpTopReferrerUsers_30D(uint256 index) private {
        for (uint256 i = index; i < _topReferrerUsers_30D.length - 1; i++) {
            _topReferrerUsers_30D[i] = _topReferrerUsers_30D[i + 1];
        }

        _topReferrerUsers_30D[_topReferrerUsers_30D.length - 1] = address(0);
    }

    function shiftDownTopReferrerUsers_30D(uint256 index) private {
        for (uint256 i = _topReferrerUsers_30D.length - 1; i > index; i--) {
            _topReferrerUsers_30D[i] = _topReferrerUsers_30D[i - 1];
        }

        _topReferrerUsers_30D[index] = address(0);
    }

    function updateTopDepositUsers_90D(address user) private {
        for (uint256 i = 0; i < _topDepositUsers_90D.length; i++) {
            if (user == _topDepositUsers_90D[i]) {
                shiftUpTopDepositUsers_90D(i);
                break;
            }
        }

        for (uint256 i = 0; i < _topDepositUsers_90D.length; i++) {
            if (_topDepositUsers_90D[i] == address(0)) {
                _topDepositUsers_90D[i] = user;
                break;
            } else {
                if (_userMaps[user].depositSun_90D > _userMaps[_topDepositUsers_90D[i]].depositSun_90D) {
                    shiftDownTopDepositUsers_90D(i);
                    _topDepositUsers_90D[i] = user;
                    break;
                }
            }
        }
    }

    function shiftUpTopDepositUsers_90D(uint256 index) private {
        for (uint256 i = index; i < _topDepositUsers_90D.length - 1; i++) {
            _topDepositUsers_90D[i] = _topDepositUsers_90D[i + 1];
        }

        _topDepositUsers_90D[_topDepositUsers_90D.length - 1] = address(0);
    }

    function shiftDownTopDepositUsers_90D(uint256 index) private {
        for (uint256 i = _topDepositUsers_90D.length - 1; i > index; i--) {
            _topDepositUsers_90D[i] = _topDepositUsers_90D[i - 1];
        }

        _topDepositUsers_90D[index] = address(0);
    }

    function updateTopReferrerUsers_90D(address user) private {
        for (uint256 i = 0; i < _topReferrerUsers_90D.length; i++) {
            if (user == _topReferrerUsers_90D[i]) {
                shiftUpTopReferrerUsers_90D(i);
                break;
            }
        }

        for (uint256 i = 0; i < _topReferrerUsers_90D.length; i++) {
            if (_topReferrerUsers_90D[i] == address(0)) {
                _topReferrerUsers_90D[i] = user;
                break;
            } else {
                if (_userMaps[user].referrerSun_90D > _userMaps[_topReferrerUsers_90D[i]].referrerSun_90D) {
                    shiftDownTopReferrerUsers_90D(i);
                    _topReferrerUsers_90D[i] = user;
                    break;
                }
            }
        }
    }

    function shiftUpTopReferrerUsers_90D(uint256 index) private {
        for (uint256 i = index; i < _topReferrerUsers_90D.length - 1; i++) {
            _topReferrerUsers_90D[i] = _topReferrerUsers_90D[i + 1];
        }

        _topReferrerUsers_90D[_topReferrerUsers_90D.length - 1] = address(0);
    }

    function shiftDownTopReferrerUsers_90D(uint256 index) private {
        for (uint256 i = _topReferrerUsers_90D.length - 1; i > index; i--) {
            _topReferrerUsers_90D[i] = _topReferrerUsers_90D[i - 1];
        }

        _topReferrerUsers_90D[index] = address(0);
    }
}


//SourceUnit: IERC20.sol

pragma solidity 0.5.10;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



//SourceUnit: SafeMath.sol

pragma solidity 0.5.10;

library SafeMath {
    function permill(uint256 value, uint256 _permill) internal pure  returns(uint256) {
        return div(mul(value, _permill), 1000);
    }

    function percent(uint256 value, uint256 _percent) internal pure  returns(uint256) {
        return div(mul(value, _percent), 100);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a >= b, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function subNoNegative(uint256 a, uint256 b) internal pure returns (uint256) {
        if(a < b) {
            return 0;
        }
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}