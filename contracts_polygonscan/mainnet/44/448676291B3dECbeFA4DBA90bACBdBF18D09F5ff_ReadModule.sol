pragma solidity ^0.8.0;


import "../common/variables.sol";

contract ReadModule is Variables {

    function tokenEnabled(address token_) external view returns (bool) {
        return _tokenEnabled[token_];
    }

    function markets() external view returns (address[] memory) {
        return _markets;
    }

    function marketsLength() external view returns (uint length_) {
        return _markets.length;
    }

    function tokenToItoken(address token_) external view returns (address) {
        return _itokens[token_];
    }

    function itokenToToken(address itoken_) external view returns (address) {
        return _tokens[itoken_];
    }

    function rewardTokens(address token_) external view returns (address[] memory) {
        return _rewardTokens[token_];
    }

    function rewardRate(address token_, address rewardToken_) external view returns (uint) {
        return _rewardRate[token_][rewardToken_];
    }

    function rewardPrice(address token_, address rewardToken_) external view returns (uint rewardPrice_, uint lastUpdateTime_) {
        rewardPrice_ = _rewardPrice[token_][rewardToken_].rewardPrice;
        lastUpdateTime_ = _rewardPrice[token_][rewardToken_].lastUpdateTime;
    }

    function userRewards(address user_, address token_, address rewardToken_) external view returns (uint lastRewardPrice_, uint reward_) {
        lastRewardPrice_ = _userRewards[user_][token_][rewardToken_].lastRewardPrice;
        reward_ = _userRewards[user_][token_][rewardToken_].reward;
    }

}

pragma solidity ^0.8.0;


import "../../common/ILiquidity.sol";

contract Variables {

    // status for re-entrancy. 1 = allow/non-entered, 2 = disallow/entered
    uint256 internal _status;

    ILiquidity constant internal liquidity = ILiquidity(address(0x4EE6eCAD1c2Dae9f525404De8555724e3c35d07B)); // TODO: add the core liquidity address

    // tokens enabled to supply in
    mapping (address => bool) internal _tokenEnabled;

    // array of all the tokens enabled
    address[] internal _markets;

    // token to itoken mapping (itoken are similar to ctokens)
    mapping (address => address) internal _itokens;

    // itoken to token mapping (itoken are similar to ctokens)
    mapping (address => address) internal _tokens;

    struct RewardPrice {
        uint256 rewardPrice; // rewards per itoken from start. Keeping it 256 bit as we're multiplying with 1e27 for proper decimal calculation
        uint256 lastUpdateTime; // in sec
    }

    struct UserReward {
        uint256 lastRewardPrice; // last updated reward price for this user. Keeping it 256 bit as we're multiplying with 1e27 for proper decimal calculation
        uint256 reward; // rewards available for claiming for user
    }

    // token => reward tokens. One token can have multiple rewards going on.
    mapping (address => address[]) internal _rewardTokens;

    // token => reward token => reward rate per sec
    mapping (address => mapping (address => uint)) internal _rewardRate;

    // rewards per itoken current. _rewardPrice = _rewardPrice + (_rewardRate * timeElapsed) / total itoken
    // multiplying with 1e27 to get decimal precision otherwise the number could get 0. To calculate users reward divide by 1e27 in the end.
    // token => reward token => reward price
    mapping (address => mapping (address => RewardPrice)) internal _rewardPrice; // starts from 0 & increase overtime.

    // last reward price stored for a user. Multiplying (current - last) * user_itoken will give users new rewards earned
    // user => token => reward token => reward amount
    mapping (address => mapping (address => mapping (address => UserReward))) internal _userRewards;

}

pragma solidity ^0.8.0;


interface ILiquidity {

    function supply(
        address token_,
        uint amount_
    ) external returns (
        uint newSupplyRate_,
        uint newBorrowRate_,
        uint newSupplyExchangePrice_,
        uint newBorrowExchangePrice_
    );

    function withdraw(
        address token_,
        uint amount_
    ) external returns (
        uint newSupplyRate_,
        uint newBorrowRate_,
        uint newSupplyExchangePrice_,
        uint newBorrowExchangePrice_
    );

    function borrow(
        address token_,
        uint amount_
    ) external returns (
        uint newSupplyRate_,
        uint newBorrowRate_,
        uint newSupplyExchangePrice_,
        uint newBorrowExchangePrice_
    );

    function payback(
        address token_,
        uint amount_
    ) external returns (
        uint newSupplyRate_,
        uint newBorrowRate_,
        uint newSupplyExchangePrice_,
        uint newBorrowExchangePrice_
    );

    function updateInterest(
        address token_
    ) external view returns (
        uint newSupplyExchangePrice,
        uint newBorrowExchangePrice
    );

    function isProtocol(address protocol_) external view returns (bool);

    function protocolSupplyLimit(address protocol_, address token_) external view returns (uint256);

    function protocolBorrowLimit(address protocol_, address token_) external view returns (uint256);

    function totalSupplyRaw(address token_) external view returns (uint256);

    function totalBorrowRaw(address token_) external view returns (uint256);

    function protocolRawSupply(address protocol_, address token_) external view returns (uint256);

    function protocolRawBorrow(address protocol_, address token_) external view returns (uint256);

    struct Rates {
        uint96 lastSupplyExchangePrice; // last stored exchange price. Increases overtime.
        uint96 lastBorrowExchangePrice; // last stored exchange price. Increases overtime.
        uint48 lastUpdateTime; // in sec
        uint16 utilization; // utilization. 10000 = 100%
    }

    function rate(address token_) external view returns (Rates memory);

}