/**
 *Submitted for verification at polygonscan.com on 2021-12-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    function mul(int256 a, int256 b) internal pure returns (int256) {
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

contract AggregatedALTSOracle is Ownable, IERC165 {
  using SignedSafeMath for int256;

  AggregatorV3Interface internal aggregatorContractTotal;
  AggregatorV3Interface internal aggregatorContractBtc;
  AggregatorV3Interface internal aggregatorContractEth;

  bytes4 private constant _INTERFACE_ID_CHAINLINK_ORACLE = 0x85be402b;

  bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

  constructor(address _aggregatorTotal, address _aggregatorBtc, address _aggregatorEth) {
    aggregatorContractTotal = AggregatorV3Interface(_aggregatorTotal);
    aggregatorContractBtc = AggregatorV3Interface(_aggregatorBtc);
    aggregatorContractEth = AggregatorV3Interface(_aggregatorEth);
  }

  function setReferenceContract(address _aggregatorTotal) public onlyOwner() {
    aggregatorContractTotal = AggregatorV3Interface(_aggregatorTotal);
  }

  function setReferenceContractBtc(address _aggregatorBtc) public onlyOwner() {
    aggregatorContractBtc = AggregatorV3Interface(_aggregatorBtc);
  }

  function setReferenceContractEth(address _aggregatorEth) public onlyOwner() {
    aggregatorContractEth = AggregatorV3Interface(_aggregatorEth);
  }

  function getLatestAnswerTotal() public view returns (int256) {
    (
      uint80 roundID,
      int256 price,
      ,
      uint256 timeStamp,
      uint80 answeredInRound
    ) = aggregatorContractTotal.latestRoundData();
    require(
      timeStamp != 0,
      "ChainlinkOracle::getLatestAnswerTotal: round is not complete"
    );
    require(
      answeredInRound >= roundID,
      "ChainlinkOracle::getLatestAnswerTotal: stale data"
    );
    return price;
  }

    function getLatestAnswerBtc() public view returns (int256) {
    (
      uint80 roundID,
      int256 price,
      ,
      uint256 timeStamp,
      uint80 answeredInRound
    ) = aggregatorContractBtc.latestRoundData();
    require(
      timeStamp != 0,
      "ChainlinkOracle::getLatestAnswerBtc: round is not complete"
    );
    require(
      answeredInRound >= roundID,
      "ChainlinkOracle::getLatestAnswerBtc: stale data"
    );
    return price;
  }

    function getLatestAnswerEth() public view returns (int256) {
    (
      uint80 roundID,
      int256 price,
      ,
      uint256 timeStamp,
      uint80 answeredInRound
    ) = aggregatorContractEth.latestRoundData();
    require(
      timeStamp != 0,
      "ChainlinkOracle::getLatestAnswerEth: round is not complete"
    );
    require(
      answeredInRound >= roundID,
      "ChainlinkOracle::getLatestAnswerEth: stale data"
    );
    return price;
  }

  function getLatestAnswer() public view returns (int256) {
    int256 totalMarketCap = getLatestAnswerTotal();
    int256 btcMarketCap = getLatestAnswerBtc();
    int256 ethMarketCap = getLatestAnswerEth();

    int256 altsMarketCap = totalMarketCap.sub(btcMarketCap).sub(ethMarketCap).div(1000000000);

    return altsMarketCap;
  }

  function getLatestRound()
    public
    view
    returns (
      uint80,
      int256,
      uint256,
      uint256,
      uint80
    )
  {
    (
      uint80 roundID,
      int256 price,
      uint256 startedAt,
      uint256 timeStamp,
      uint80 answeredInRound
    ) = aggregatorContractTotal.latestRoundData();

    return (roundID, price, startedAt, timeStamp, answeredInRound);
  }

  function getRound(uint80 _id)
    public
    view
    returns (
      uint80,
      int256,
      uint256,
      uint256,
      uint80
    )
  {
    (
      uint80 roundID,
      int256 price,
      uint256 startedAt,
      uint256 timeStamp,
      uint80 answeredInRound
    ) = aggregatorContractTotal.getRoundData(_id);

    return (roundID, price, startedAt, timeStamp, answeredInRound);
  }

  function getLatestTimestamp() public view returns (uint256) {
    (, , , uint256 timeStamp, ) = aggregatorContractTotal.latestRoundData();
    return timeStamp;
  }

  function getPreviousAnswer(uint80 _id) public view returns (int256) {
    (uint80 roundID, int256 price, , , ) = aggregatorContractTotal.getRoundData(_id);
    require(
      _id <= roundID,
      "ChainlinkOracle::getPreviousAnswer: not enough history"
    );
    return price;
  }

  function getPreviousTimestamp(uint80 _id) public view returns (uint256) {
    (uint80 roundID, , , uint256 timeStamp, ) =
      aggregatorContractTotal.getRoundData(_id);
    require(
      _id <= roundID,
      "ChainlinkOracle::getPreviousTimestamp: not enough history"
    );
    return timeStamp;
  }

  function supportsInterface(bytes4 interfaceId)
    external
    pure
    override
    returns (bool)
  {
    return (interfaceId == _INTERFACE_ID_CHAINLINK_ORACLE ||
      interfaceId == _INTERFACE_ID_ERC165);
  }
}