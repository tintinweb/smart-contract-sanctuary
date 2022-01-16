/**
 *Submitted for verification at polygonscan.com on 2022-01-15
*/

/*
SPDX-License-Identifier: UNLICENSED
(c) Developed by AgroToken
This work is unlicensed.
*/
pragma solidity 0.8.11;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}


interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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


interface AggregatorInterface {
  function latestAnswer()
    external
    view
    returns (
      int256
    );
  
  function latestTimestamp()
    external
    view
    returns (
      uint256
    );

  function latestRound()
    external
    view
    returns (
      uint256
    );

  function getAnswer(
    uint256 roundId
  )
    external
    view
    returns (
      int256
    );

  function getTimestamp(
    uint256 roundId
  )
    external
    view
    returns (
      uint256
    );

  event AnswerUpdated(
    int256 indexed current,
    uint256 indexed roundId,
    uint256 updatedAt
  );

  event NewRound(
    uint256 indexed roundId,
    address indexed startedBy,
    uint256 startedAt
  );
}


interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}


contract AgrotokenPrice is AggregatorV2V3Interface {

    struct RoundData {
        uint80 roundId;
        int256 answer;
        uint256 startedAt;
        uint256 updatedAt;
    }

    address public priceManager;
    address public board;
    address public assetContract;
    address public assetToRead;
    uint256 version_;
    string description_;
    bool public requestTokenToRead;
    uint80 public actualRoundId;
    mapping(uint80 => RoundData) historyData;

    modifier OnlyManagerOrBoard() {
        require(msg.sender == priceManager || msg.sender == board, "Only manager or board can perform this change");
        _;
    }

    modifier OnlyManager() {
        require(msg.sender == priceManager, "Only manager can performed this change");
        _;
    }

    constructor() {
        priceManager = msg.sender;
        board = address(0xA01cD92f06f60b9fdcCCdF6280CE9A10803bA720);
        assetContract = address(0x8E0d37Afd3B9320Cf909959515fb50922d511c95);        
        assetToRead = address(0x8E0d37Afd3B9320Cf909959515fb50922d511c95);        
        version_ = 1;
        description_ = "SOYA / USD";
        requestTokenToRead = false;
        actualRoundId = 1;
        RoundData memory newRoundData = RoundData({roundId: actualRoundId, answer: 3500000, startedAt: block.timestamp, updatedAt: block.timestamp});
        historyData[actualRoundId] = newRoundData;
    }

    function setRoundData(int256 newAnswer) external OnlyManager returns (bool) {
        RoundData memory oldRoundData = historyData[actualRoundId];
        actualRoundId = actualRoundId + 1;
        historyData[actualRoundId] = RoundData({roundId: actualRoundId, answer: newAnswer, startedAt: oldRoundData.updatedAt, updatedAt: block.timestamp});
        return true;
    }
    
    function changeManager(address newManager) external returns(bool) {
        require(msg.sender == priceManager || msg.sender == board, "Only ex-manager or board can change the manager");
        priceManager = newManager;
        return true;
    }

    function changeBoard(address newBoard) external returns(bool) {
        require(msg.sender == board, "Only ex-board can change the board");
        board = newBoard;
        return true;
    }

    function changeAssetToRead(address newAsset) external OnlyManager returns (bool) {
        assetToRead = newAsset;
        return true;
    }

    function changeAsset(address newAsset) external OnlyManager returns (bool) {
        assetContract = newAsset;
        return true;
    }

    function changeVersion(uint256 newVersion) external OnlyManager returns (bool) {
        version_ = newVersion;
        return true;
    }

    function changeChargePolicy(bool newPolicy) external OnlyManager returns (bool) {
        requestTokenToRead = newPolicy;
        return true;
    }


    function latestAnswer() external view returns (int256) {
        if (requestTokenToRead) {
            require(IERC20Metadata(assetToRead).balanceOf(msg.sender) > 0, "You need to be a token holder to be able to read this data");
        }
        return historyData[actualRoundId].answer;
    }
  
    function latestTimestamp()  external  view  returns ( uint256 ) {
        return historyData[actualRoundId].updatedAt;
    }

    function latestRound() external view returns ( uint256 ) {
        return actualRoundId;
    }

    function getAnswer(uint256 roundId) external view returns (int256) {
        if (requestTokenToRead) {
            require(IERC20Metadata(assetToRead).balanceOf(msg.sender) > 0, "You need to be a token holder to be able to read this data");
        }
        return historyData[uint80(roundId)].answer;
    }

    function getTimestamp(uint256 roundId) external view returns (uint256) {
        return historyData[uint80(roundId)].updatedAt;
    }

    function decimals() external view returns ( uint8 ) {
        return IERC20Metadata(assetContract).decimals();
    }

    function description() external view returns ( string memory ) {
        return description_;
    }

    function version() external view returns (  uint256 ) {
        return version_;
    }

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData( uint80 _roundId) external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        if (requestTokenToRead) {
            require(IERC20Metadata(assetToRead).balanceOf(msg.sender) > 0, "You need to be a token holder to be able to read this data");
        }
        RoundData memory hRoundData = historyData[uint80(_roundId)];
        return (hRoundData.roundId, hRoundData.answer, hRoundData.startedAt, hRoundData.updatedAt, actualRoundId);
    }

    function latestRoundData() external view returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    ) {
        if (requestTokenToRead) {
            require(IERC20Metadata(assetToRead).balanceOf(msg.sender) > 0, "You need to be a token holder to be able to read this data");
        }
        RoundData memory hRoundData = historyData[uint80(actualRoundId)];
        return (hRoundData.roundId, hRoundData.answer, hRoundData.startedAt, hRoundData.updatedAt, actualRoundId);
    }
}