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



//SourceUnit: trondiamond.sol

pragma solidity 0.5.10;

import "./IERC20.sol";
import "./SafeMath.sol";

contract TronDiamondContract {
    using SafeMath for uint256;

    struct User {
        address referrerUser;
        address[] followerUsers;
        uint256 joinTime;
        uint256 totalInvestSun;
        uint256 totalWithdrawSun;
        uint256 amountToken;
        uint256 withdrawableSellSun;
        uint256 withdrawableCommissionSun;
        uint256 oneDayDepositTime;
        uint256 oneDayDepositSun;
        uint256 oneDayReferrerCount;
        uint256 withdrawableRewardSun;
        uint256 payOutDividendSun;
        uint256 dividendPerTdmWhenJoin;
        uint256 withdrawableDividendSun;
    }

    mapping(address => User) private _userMaps;
    uint256 private _userCount;

    address payable private _ownerUser;
    uint256 constant private _ownerFeePercent = 4;
    
    address payable private _programmerUser;
    uint256 constant private _programmerFeePercent = 1;

    IERC20 private _tdmToken;
    uint256 private _contractBalanceSun;
    uint256 private _totalInvestSun;
    uint256 private _totalWithdrawSun;

    // The Token/Tron exchange formula is copied from the Hourglass Smart Contract
    // However I've applied the SafeMath library to the original formula.
    // I'd like to pay respect to them by using their naming style here.
    uint256 private tokenSupply_;
    uint256 constant private tokenPriceInitial_ = 1e5;
    uint256 constant private tokenPriceIncremental_ = 1;
    uint256 constant private tokenPriceIncrementalAmplifier_ = 10;
    uint256 constant private tokenDecimals_ = 1e6;

    uint256 constant private _totalUserCommissionPercent = 20;
    uint256[10] private _userCommissionPercents = [ 35, 25, 10, 10, 5, 5, 3, 3, 2, 2 ];

    uint256 constant private _sellPayOutPercent = 70;

    uint256 constant private _minimumJoinSun = 1e8;
    uint256 constant private _minimumBuySun = 1e8;

    uint256 constant private _topSponsorRewardPercent = 2;
    uint256 private _lastDrawTopSponsorRewardTime;
    uint256 constant private _drawTopSponsorRewardPeriod = 1 days;
    
    uint256 private _topSponsorRewardSun;

    address[5] private _topDepositUsers;
    uint256[5] private _topDepositPercents = [ 30, 25, 20, 15, 10 ];
    address[5] private _topReferrerUsers;
    uint256[5] private _topReferrerPercents = [ 30, 25, 20, 15, 10 ];

    uint256 constant private _buyDividendPercent = 8;
    uint256 constant private _sellDividendPercent = 5;

    uint256 private _totalDividendPerTdm;
    uint256 constant private _minimumTokenReceived = 1e6;
    uint256 constant private _magnitude = 1e12;

    constructor(IERC20 token, address payable ownerUser) public {
        _tdmToken = token;
        _ownerUser = ownerUser;
        _programmerUser = msg.sender;
        _lastDrawTopSponsorRewardTime = block.timestamp;
    }

    function() external payable {
        if(_isJoinedUser(msg.sender) == false) {
            revert("User has not joined");
        }
        _buy(msg.sender, msg.value);
    }

    function getReferrerUser(address user) public view returns(address) {
        return _userMaps[user].referrerUser;
    }

    function getAllReferrerUsers(address user) public view returns(address[] memory) {
        address[] memory allReferrerUsers = new address[](10);

        for(uint i = 0; i < allReferrerUsers.length; i++) {
            allReferrerUsers[i] = address(0);
        }

        address referrerUser = _userMaps[user].referrerUser;

        for(uint256 i = 0; (i < _userCommissionPercents.length && i < allReferrerUsers.length) && (referrerUser != address(0)); i++) {
            allReferrerUsers[i] = referrerUser;
            referrerUser = _userMaps[referrerUser].referrerUser;
        }

        return allReferrerUsers;
    }

    function getAllFollowerUsers(address user) public view returns(address[] memory) {
        return _userMaps[user].followerUsers;
    }

    function getUserInfo(address user) public view returns(uint256[] memory) {
        uint256[] memory info = new uint256[](12);

        info[ 0] = _userMaps[user].joinTime;
        info[ 1] = _userMaps[user].totalInvestSun;
        info[ 2] = _userMaps[user].totalWithdrawSun;
        info[ 3] = _userMaps[user].amountToken;
        info[ 4] = _userMaps[user].withdrawableSellSun;
        info[ 5] = _userMaps[user].withdrawableCommissionSun;
        info[ 6] = _userMaps[user].oneDayDepositTime;
        info[ 7] = _userMaps[user].oneDayDepositSun;
        info[ 8] = _userMaps[user].oneDayReferrerCount;
        info[ 9] = _userMaps[user].withdrawableRewardSun;
        info[10] = _userMaps[user].payOutDividendSun;
        info[11] = 0;

        return info;
    }

    function getUserCount() public view returns(uint256) {
        return _userCount;
    }

    function getTokenAddress() public view returns(address) {
        return address(_tdmToken);
    }

    function getContractBalanceSun() public view returns(uint256) {
        return _contractBalanceSun;
    }

    function getTotalInvestSun() public view returns(uint256) {
        return _totalInvestSun;
    }

    function getTotalWithdrawSun() public view returns(uint256) {
        return _totalWithdrawSun;
    }

    function getTokenSupply() public view returns(uint256) {
        return tokenSupply_;
    }

    function getTopSponsorRewardSun() public view returns(uint256) {
        return _topSponsorRewardSun;
    }

    function getDividend() public view returns(uint256) {
        uint256 dividendSun = _userMaps[msg.sender].withdrawableDividendSun;

        if(_userMaps[msg.sender].amountToken >= _minimumTokenReceived) {
            dividendSun = dividendSun.add(_totalDividendPerTdm.subNoNegative(_userMaps[msg.sender].dividendPerTdmWhenJoin)
                                                              .mul(_userMaps[msg.sender].amountToken)
                                                              .div(_magnitude));
        }

        return dividendSun.subNoNegative(_userMaps[msg.sender].payOutDividendSun);
    }

    function getRewardsSun() public view returns(uint256) {
        address currentUser = msg.sender;

        uint256 totalPayableTopDepositors = _topSponsorRewardSun.div(2);
        uint256 totalPayableTopReferrers = _topSponsorRewardSun.sub(totalPayableTopDepositors);

        uint256 rewardsSun = _userMaps[currentUser].withdrawableRewardSun;

        for(uint i = 0; i < _topDepositUsers.length; i++) {
            if(currentUser == _topDepositUsers[i]) {
                rewardsSun = rewardsSun.add(totalPayableTopDepositors.percent(_topDepositPercents[i]));
                break;
            }
        }

        for(uint i = 0; i < _topReferrerUsers.length; i++) {
            if(currentUser == _topReferrerUsers[i]) {
                rewardsSun = rewardsSun.add(totalPayableTopReferrers.percent(_topReferrerPercents[i]));
                break;
            }
        }

        return rewardsSun;        
    }

    function getTimeToNextDraw() public view returns(uint256) {
        return _lastDrawTopSponsorRewardTime.add(_drawTopSponsorRewardPeriod).subNoNegative(block.timestamp);
    }

    function getTopDepositUsers() public view returns(address[5] memory) {
        return _topDepositUsers;
    }

    function getTopDepositSuns() public view returns(uint256[] memory) {
        uint256[] memory topDepositSuns = new uint256[](5);
        
        for(uint256 i = 0; i < topDepositSuns.length; i++) {
            if(_topDepositUsers[i] != address(0)) {
                topDepositSuns[i] = _userMaps[_topDepositUsers[i]].oneDayDepositSun;
            } else {
                topDepositSuns[i] = 0;
            }
        }

        return topDepositSuns;
    }

    function getTopReferrerUsers() public view returns(address[5] memory) {
        return _topReferrerUsers;
    }

    function getTopReferrerCounts() public view returns(uint256[] memory) {
        uint256[] memory topReferrerCounts = new uint256[](5);

        for(uint256 i = 0; i < topReferrerCounts.length; i++) {
            if(_topReferrerUsers[i] != address(0)) {
                topReferrerCounts[i] = _userMaps[_topReferrerUsers[i]].oneDayReferrerCount;
            } else {
                topReferrerCounts[i] = 0;
            }
        }

        return topReferrerCounts; 
    }

    function contractBalance() public view returns(uint256) {
        return (address(this)).balance;
    }

    function getTotalToken() public view returns(uint256) {
        return _tdmToken.balanceOf(address(this));
    }

    function getSellPrice() public view returns (uint256) {
        return convertTokenToSun(tokenDecimals_).percent(uint256(100).sub(uint256(100).sub(_sellPayOutPercent).div(2)));
    }

    function getBuyPrice() public view returns (uint256) {
        return convertTokenToSun(tokenDecimals_).percent(uint256(100).add(uint256(100).sub(_sellPayOutPercent).div(2)));
    }

    function getTokensReceived(uint256 valueBuySun) public view returns (uint256) {
        return convertSunToToken(valueBuySun.percent(uint256(100).sub(uint256(100).sub(_sellPayOutPercent).div(2))));
    }

    function getSunReceived(uint256 amountSellToken) public view returns (uint256) {
        if(amountSellToken > tokenSupply_) {
            revert("Too many tokens to sell");
        }

        return convertTokenToSun(amountSellToken).percent(uint256(100).sub(uint256(100).sub(_sellPayOutPercent).div(2)));
    }
    
    function join(address referrerUser) public payable returns(bool) {
        if(_isJoinedUser(msg.sender) == true) {
            revert("User has joined already");
        }

        if(msg.sender == referrerUser) {
            revert("User and referrer can not be the same person");
        }

        if(_isJoinedUser(referrerUser) == false && referrerUser != _ownerUser) {
            revert("Referrer is unknown");
        }

        if(msg.value < _minimumJoinSun) {
            revert("You have to send at least the minimum requirement TRX to join");
        }

        if(referrerUser == _ownerUser) {
            _userMaps[msg.sender].referrerUser = address(0);
        } else {
            _userMaps[msg.sender].referrerUser = referrerUser;
            _userMaps[referrerUser].followerUsers.push(msg.sender);
        }

        _userMaps[msg.sender].joinTime = block.timestamp;
        _userMaps[msg.sender].oneDayDepositTime = block.timestamp;
        _userMaps[msg.sender].dividendPerTdmWhenJoin = _totalDividendPerTdm;
        _userCount = _userCount.add(1);

        return _buy(msg.sender, msg.value);
    }

    function buy() public payable returns(bool) {
        if(_isJoinedUser(msg.sender) == false) {
            revert("User has not joined");
        }

        return _buy(msg.sender, msg.value);
    }

    function _buy(address user, uint256 valueBuySun) private returns(bool) {
        if(valueBuySun < _minimumBuySun) {
            revert("You need to send some TRX, not zero");
        }

        uint256 amountBuyToken = convertSunToToken(valueBuySun.percent(uint256(100).sub(uint256(100).sub(_sellPayOutPercent).div(2))));

        if(amountBuyToken == 0) {
            revert("You need to send some more TRX to buy token");
        }

        uint256 tokenBalance = _tdmToken.balanceOf(address(this));

        if(tokenBalance < amountBuyToken) {
            revert("Not enough tokens in the reserve");
        }

        _tdmToken.transfer(user, amountBuyToken);
        tokenSupply_ = tokenSupply_.add(amountBuyToken);

        if(isDividendReady(amountBuyToken)) {
            uint256 newDividendSun = getDividend();
            newDividendSun = newDividendSun.add(valueBuySun.percent(_buyDividendPercent).mul(_userMaps[user].amountToken.add(amountBuyToken)).div(tokenSupply_));
            newDividendSun = newDividendSun.add(_userMaps[user].payOutDividendSun);
            newDividendSun = newDividendSun.subNoNegative(_userMaps[user].withdrawableDividendSun);
            uint256 newTotalDividendPerTdm = _totalDividendPerTdm.add(valueBuySun.percent(_buyDividendPercent).mul(_magnitude).div(tokenSupply_));                                        
            _userMaps[user].dividendPerTdmWhenJoin = newTotalDividendPerTdm.subNoNegative(newDividendSun.mul(_magnitude).div(_userMaps[user].amountToken.add(amountBuyToken)));
        }

        deposit(user, valueBuySun, amountBuyToken);

        return true;
    }

    function sell(uint256 amountSellToken) public returns(bool) {
        if(_isJoinedUser(msg.sender) == false) {
            revert("User has not joined");
        }

        if(amountSellToken == 0) {
            revert("You need to sell at least some tokens, not zero");
        }

        if(amountSellToken > _userMaps[msg.sender].amountToken) {
            revert("You cannot sell too many tokens more than you bought ones");
        }

        uint256 allowanceToken = _tdmToken.allowance(msg.sender, address(this));

        if(amountSellToken > allowanceToken) {
            revert("You cannot sell too many tokens more than you approved ones");
        }

        drawRewards();

        _tdmToken.transferFrom(msg.sender, address(this), amountSellToken);
        uint256 valueSellSun = convertTokenToSun(amountSellToken).percent(uint256(100).sub(uint256(100).sub(_sellPayOutPercent).div(2)));

        _userMaps[msg.sender].withdrawableDividendSun = _userMaps[msg.sender].withdrawableDividendSun.add(
                                                        _totalDividendPerTdm.subNoNegative(_userMaps[msg.sender].dividendPerTdmWhenJoin).mul(amountSellToken).div(_magnitude)
                                                     );

        tokenSupply_ = tokenSupply_.sub(amountSellToken);

        updateUserSellToken(msg.sender, valueSellSun, amountSellToken);
        updateAllUsersSellDividend(msg.sender, valueSellSun);

        uint256 dividendAfterSellToken = getDividend();
        
        return true;
    }

    function withdraw() public returns(bool) {
        if(_isJoinedUser(msg.sender) == false) {
            revert("User has not joined");
        }

        drawRewards();

        uint256 withdrawableSellSun = _userMaps[msg.sender].withdrawableSellSun;
        uint256 withdrawableCommissionSun = _userMaps[msg.sender].withdrawableCommissionSun;
        uint256 withdrawableRewardSun = _userMaps[msg.sender].withdrawableRewardSun;
        uint256 withdrawableDividendSun = getDividend();

        uint256 totalWithdrawSun = 0;
        totalWithdrawSun = totalWithdrawSun.add(withdrawableSellSun);
        totalWithdrawSun = totalWithdrawSun.add(withdrawableCommissionSun);
        totalWithdrawSun = totalWithdrawSun.add(withdrawableRewardSun);
        totalWithdrawSun = totalWithdrawSun.add(withdrawableDividendSun);

        if(totalWithdrawSun == 0) {
            revert("No withdrawable");
        }

        _contractBalanceSun = _contractBalanceSun.sub(totalWithdrawSun);
        _totalWithdrawSun = _totalWithdrawSun.add(totalWithdrawSun);

        msg.sender.transfer(totalWithdrawSun);
        _userMaps[msg.sender].totalWithdrawSun = _userMaps[msg.sender].totalWithdrawSun.add(totalWithdrawSun);

        _userMaps[msg.sender].withdrawableSellSun = 0;
        _userMaps[msg.sender].withdrawableCommissionSun = 0;
        _userMaps[msg.sender].withdrawableRewardSun = 0;
        _userMaps[msg.sender].payOutDividendSun = _userMaps[msg.sender].payOutDividendSun.add(withdrawableDividendSun);

        return true;
    }

    function isJoinedUser() public view returns(bool) {
        return _isJoinedUser(msg.sender);
    }

    function _isJoinedUser(address user) private view returns(bool) {
        if(_userMaps[user].joinTime > 0) {
            return true;
        }

        return false;
    }

    function updateUserBuyToken(address user, uint256 valueBuySun, uint256 amountBuyToken) private {
        _userMaps[user].amountToken = _userMaps[user].amountToken.add(amountBuyToken);
    }

    function updateUserSellToken(address user, uint256 valueSellSun, uint256 amountSellToken) private {
        _userMaps[user].withdrawableSellSun = _userMaps[user].withdrawableSellSun.add(valueSellSun);
        _userMaps[user].amountToken = _userMaps[user].amountToken.sub(amountSellToken);
    }

    function updateUserCommission(address user, uint256 valueSun) private {
        uint256 totalUserCommissionSun = valueSun.percent(_totalUserCommissionPercent);
        address referrerUser = _userMaps[user].referrerUser;

        for(uint256 i = 0; (i < _userCommissionPercents.length) && (referrerUser != address(0)); i++) {
            uint256 commissionSun = totalUserCommissionSun.percent(_userCommissionPercents[i]);
            if(_userMaps[referrerUser].amountToken >= _minimumTokenReceived) {
                _userMaps[referrerUser].withdrawableCommissionSun = _userMaps[referrerUser].withdrawableCommissionSun.add(commissionSun);
            }
            referrerUser = _userMaps[referrerUser].referrerUser;
        }
    }

    function updateAllUsersBuyDividend(address user, uint256 valueSun) private {
        if(isDividendReady(0)) {
            _totalDividendPerTdm = _totalDividendPerTdm.add(valueSun.percent(_buyDividendPercent).mul(_magnitude).div(tokenSupply_));
        }
    }

    function updateAllUsersSellDividend(address user, uint256 valueSun) private {
        if(isDividendReady(0)) {
            _totalDividendPerTdm = _totalDividendPerTdm.add(valueSun.percent(_sellDividendPercent).mul(_magnitude).div(tokenSupply_));
        }
    }
    
    function sqrt(uint256 x) internal pure returns (uint256) {
        uint256 z = (x + 1) / 2;
        uint256 y = x;

        while(z < y) {
            y = z;
            z = (x / z + z) / 2;
        }

        return y;
    }

    function convertSunToToken(uint256 valueSun) private view returns(uint256) {
        uint256 tokenPriceInitial = tokenPriceInitial_.mul(tokenDecimals_);

        uint256 A = tokenPriceInitial.mul(tokenPriceInitial);

        uint256 B = uint256(2).mul(tokenPriceIncremental_).mul(tokenDecimals_).mul(valueSun).mul(tokenDecimals_).div(tokenPriceIncrementalAmplifier_);

        uint256 C = tokenPriceIncremental_.mul(tokenPriceIncremental_).mul(tokenSupply_).mul(tokenSupply_).div(tokenPriceIncrementalAmplifier_.mul(tokenPriceIncrementalAmplifier_));

        uint256 D = uint256(2).mul(tokenPriceIncremental_).mul(tokenPriceInitial).mul(tokenSupply_).div(tokenPriceIncrementalAmplifier_);

        uint256 S = A.add(B).add(C).add(D);

        uint256 R = sqrt(S)
                    .sub(tokenPriceInitial)
                    .mul(tokenPriceIncrementalAmplifier_)
                    .div(tokenPriceIncremental_)
                    .sub(tokenSupply_);

        return R;
    }

    function convertTokenToSun(uint256 amountToken) private view returns(uint256) {
        uint256 tokens_ = (amountToken + tokenDecimals_);
        uint256 tokenSupply = (tokenSupply_ + tokenDecimals_);

        uint256 A = tokenPriceInitial_
                    .add(tokenPriceIncremental_.mul(tokenSupply).div(tokenDecimals_.mul(tokenPriceIncrementalAmplifier_)))
                    //.sub(tokenPriceIncremental_.div(tokenPriceIncrementalAmplifier_))
                    .mul(tokens_.sub(tokenDecimals_));

        uint256 B = tokenPriceIncremental_.mul(tokens_.mul(tokens_).sub(tokens_).div(tokenDecimals_)).div(uint256(2).mul(tokenPriceIncrementalAmplifier_));

        uint256 R =  A.sub(B).div(tokenDecimals_);

        return R;
    }

    function deposit(address user, uint256 valueSun, uint256 amountToken) private {
        uint256 systemFeeSun = valueSun.percent(_ownerFeePercent.add(_programmerFeePercent));
        uint256 depositSun = valueSun.sub(systemFeeSun);
        _contractBalanceSun = _contractBalanceSun.add(depositSun);
        _totalInvestSun = _totalInvestSun.add(valueSun);
        _userMaps[user].totalInvestSun = _userMaps[user].totalInvestSun.add(valueSun);

        paySystemFee(systemFeeSun);
        drawRewards();

        updateUserBuyToken(user, valueSun, amountToken);
        updateAllUsersBuyDividend(user, valueSun);
        updateUserCommission(user, valueSun);

        // Find top 5 depositors and top 5 referrers
        _topSponsorRewardSun = _topSponsorRewardSun.add(valueSun.percent(_topSponsorRewardPercent));

        address referrerUser = _userMaps[user].referrerUser;

        if(_userMaps[user].oneDayDepositTime < _lastDrawTopSponsorRewardTime) {
            _userMaps[user].oneDayDepositTime = _lastDrawTopSponsorRewardTime;
            _userMaps[user].oneDayDepositSun = valueSun;
            _userMaps[user].oneDayReferrerCount = 0;
            
            if(referrerUser != address(0)) {
                if(_userMaps[referrerUser].oneDayDepositTime < _lastDrawTopSponsorRewardTime) {
                    _userMaps[referrerUser].oneDayDepositTime = _lastDrawTopSponsorRewardTime;
                    _userMaps[referrerUser].oneDayDepositSun = 0;
                    _userMaps[referrerUser].oneDayReferrerCount = valueSun;
                } else {
                    _userMaps[referrerUser].oneDayReferrerCount = _userMaps[referrerUser].oneDayReferrerCount.add(valueSun);
                }

                updateTopReferrerUsers(referrerUser);
            }
        } else {
            _userMaps[user].oneDayDepositSun = _userMaps[user].oneDayDepositSun.add(valueSun);

            if(referrerUser != address(0)) {
                if(_userMaps[referrerUser].oneDayDepositTime < _lastDrawTopSponsorRewardTime) {
                    _userMaps[referrerUser].oneDayDepositTime = _lastDrawTopSponsorRewardTime;
                    _userMaps[referrerUser].oneDayDepositSun = 0;
                    _userMaps[referrerUser].oneDayReferrerCount = valueSun;
                } else {
                    _userMaps[referrerUser].oneDayReferrerCount = _userMaps[referrerUser].oneDayReferrerCount.add(valueSun);
                }

                updateTopReferrerUsers(referrerUser);
            }
        }

        updateTopDepositUsers(user);
    }

    function drawRewards() private {
        // Pay top 5 depositors and top 5 referrers each day
        if(block.timestamp.subNoNegative(_lastDrawTopSponsorRewardTime) >= _drawTopSponsorRewardPeriod) {
            _lastDrawTopSponsorRewardTime = block.timestamp;

            uint256 totalPayableTopDepositors = _topSponsorRewardSun.div(2);
            uint256 totalPayableTopReferrers = _topSponsorRewardSun.sub(totalPayableTopDepositors);

            for(uint i = 0; i < _topDepositUsers.length; i++) {
                address user = _topDepositUsers[i];

                if(user != address(0)) {
                    _userMaps[user].withdrawableRewardSun
                        = _userMaps[user].withdrawableRewardSun.add(totalPayableTopDepositors.percent(_topDepositPercents[i]));
                    _userMaps[user].oneDayDepositSun = 0;
                    _userMaps[user].oneDayReferrerCount = 0;
                }

                _topDepositUsers[i] = address(0);
            }
            
            for(uint i = 0; i < _topReferrerUsers.length; i++) {
                address user = _topReferrerUsers[i];

                if(user != address(0)) {
                    _userMaps[user].withdrawableRewardSun
                        = _userMaps[user].withdrawableRewardSun.add(totalPayableTopReferrers.percent(_topReferrerPercents[i]));
                    _userMaps[user].oneDayDepositSun = 0;
                    _userMaps[user].oneDayReferrerCount = 0;
                }

                _topReferrerUsers[i] = address(0);
            }

            _topSponsorRewardSun = 0;
        }
    }

    function updateTopDepositUsers(address user) private {
        for(uint i = 0; i < _topDepositUsers.length; i++) {
            if(user == _topDepositUsers[i]) {
                shiftUpTopDepositUsers(i);
                break;
            }
        }

        for(uint i = 0; i < _topDepositUsers.length; i++) {
            if(_topDepositUsers[i] == address(0)) {
                _topDepositUsers[i] = user;
                break;
            } else {
                if(_userMaps[user].oneDayDepositSun > _userMaps[_topDepositUsers[i]].oneDayDepositSun) {
                    shiftDownTopDepositUsers(i);
                    _topDepositUsers[i] = user;
                    break;
                }
            }
        }
    }

    function shiftUpTopDepositUsers(uint256 index) private {
        for(uint i = index; i < _topDepositUsers.length - 1; i++) {
            _topDepositUsers[i] = _topDepositUsers[i + 1];
        }

        _topDepositUsers[_topDepositUsers.length - 1] = address(0);
    }

    function shiftDownTopDepositUsers(uint256 index) private {
        for(uint i = _topDepositUsers.length - 1; i > index; i--) {
            _topDepositUsers[i] = _topDepositUsers[i - 1];
        }

        _topDepositUsers[index] = address(0);
    }

    function updateTopReferrerUsers(address user) private {
        for(uint i = 0; i < _topReferrerUsers.length; i++) {
            if(user == _topReferrerUsers[i]) {
                shiftUpTopReferrerUsers(i);
                break;
            }
        }

        for(uint i = 0; i < _topReferrerUsers.length; i++) {
            if(_topReferrerUsers[i] == address(0)) {
                _topReferrerUsers[i] = user;
                break;
            } else {
                if(_userMaps[user].oneDayReferrerCount > _userMaps[_topReferrerUsers[i]].oneDayReferrerCount) {
                    shiftDownTopReferrerUsers(i);
                    _topReferrerUsers[i] = user;
                    break;
                }
            }
        }
    }

    function shiftUpTopReferrerUsers(uint256 index) private {
        for(uint i = index; i < _topReferrerUsers.length - 1; i++) {
            _topReferrerUsers[i] = _topReferrerUsers[i + 1];
        }

        _topReferrerUsers[_topReferrerUsers.length - 1] = address(0);
        
    }

    function shiftDownTopReferrerUsers(uint256 index) private {
        for(uint i = _topReferrerUsers.length - 1; i > index; i--) {
            _topReferrerUsers[i] = _topReferrerUsers[i - 1];
        }

        _topReferrerUsers[index] = address(0);
    }

    function paySystemFee(uint256 systemFeeSun) private {
        uint256 ownerFeeSun = systemFeeSun.percent(_ownerFeePercent.mul(100).div(_ownerFeePercent.add(_programmerFeePercent)));
        uint256 programmerFeeSun = systemFeeSun.sub(ownerFeeSun);

        _ownerUser.transfer(ownerFeeSun);
        _programmerUser.transfer(programmerFeeSun);
    }

    function isDividendReady(uint256 amountToken) private returns(bool) {
        return (tokenSupply_.add(amountToken) >= 500000000000) && (_userCount >= 20);
    }
}