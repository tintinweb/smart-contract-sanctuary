// pragma solidity >=0.4.21 <0.6.0;
pragma solidity >=0.6.6;

import "./interfaces/IPriceOracle.sol";
import "./interfaces/IDEOR.sol";
import "./interfaces/IOracles.sol";
import "./interfaces/IPriceFeed.sol";
import "./interfaces/IDataQuery.sol";
import "./library/Selection.sol";
import "./library/SafeMathDEOR.sol";
import "./library/Ownable.sol";

contract PriceOracle is Ownable, IPriceOracle, Selection {
  using SafeMathDEOR for uint256;

  IDEOR private token;
  IOracles private oracles;

  Request[] private requests; //  list of requests made to the contract
  uint256 public currentId = 1; // increasing request id
  uint256 constant private EXPIRY_TIME = 3 minutes;
  uint256 public requestFee = 100 * (10**10);   // request fee

  constructor (address tokenAddress, address oracleAddress) public {
    token = IDEOR(tokenAddress);
    oracles = IOracles(oracleAddress);
    requests.push(Request(0, 0, 0, 0, 0, false, address(0x0), ""));
  }

  function setRequestFee (uint256 fee) public onlyOwner {
    requestFee = fee;
  }

  function createRequest (
    string memory queries,
    address contractAddr
  )
  public override(IPriceOracle)
  {
    token.transferFrom(msg.sender, address(this), requestFee);

    uint256 len = oracles.getOracleCount();
    uint256 selectedOracleCount = len * 2 / 3 + 1;

    requests.push(Request(currentId, block.timestamp, 0, selectedOracleCount, 0, false, contractAddr, queries));
    Request storage r = requests[requests.length - 1];

    uint256[] memory orderingOracles = getSelectedOracles(len);
    uint256 penaltyForRequest = requestFee.div(selectedOracleCount);
    uint256 count = 0;

    for (uint256 i = 0; i < len && count < selectedOracleCount ; i ++) {
      address selOracle = oracles.getOracleByIndex(orderingOracles[i]);
      //Validate oracle's acitivity
      if (now < oracles.getOracleLastActiveTime(selOracle) + 1 days && token.balanceOf(selOracle) >= penaltyForRequest) {
        token.transferFrom(selOracle, address(this), penaltyForRequest);
        r.quorum[selOracle] = 1;
        count ++;
        oracles.increaseOracleAssigned(selOracle);
      }
    }
    r.minQuorum = (count * 2 + 2) / 3;          //minimum number of responses to receive before declaring final result(2/3 of total)

    // launch an event to be detected by oracle outside of blockchain
    emit NewRequest (
      currentId,
      queries,
      contractAddr
    );

    // increase request id
    currentId ++;
  }

  function checkRetrievedValue (int256 _priceAnswer, int256 _priceRetrieved) 
    internal pure returns (bool)
  {
    int256 diff = 0;
    if (_priceAnswer > _priceRetrieved) {
      diff = _priceAnswer - _priceRetrieved;
    }
    else {
      diff = _priceRetrieved - _priceAnswer;
    }
    if (diff < _priceRetrieved / 200) {
      return true;
    }
    return false;
  }

  //called by the oracle to record its answer
  function updateRequest (
    uint256 _id,
    int256 _priceRetrieved
  ) public override(IPriceOracle) {

    Request storage currRequest = requests[_id];

    uint256 responseTime = block.timestamp.sub(currRequest.timestamp);
    require(responseTime < EXPIRY_TIME, "Your answer is expired.");

    //update last active time
    oracles.updateOracleLastActiveTime(msg.sender);

    //check if oracle is in the list of trusted oracles
    //and if the oracle hasn't voted yet
    if(currRequest.quorum[msg.sender] == 1) {

      oracles.increaseOracleCompleted(msg.sender, responseTime);

      //marking that this address has voted
      currRequest.quorum[msg.sender] = 2;

      //save the retrieved value
      currRequest.priceAnswers[msg.sender] = _priceRetrieved;

      uint256 penaltyForRequest = requestFee.div(currRequest.selectedOracleCount);

      if (currRequest.isFinished == true) {
        if (checkRetrievedValue(currRequest.agreedPrice, _priceRetrieved)) {
          oracles.increaseOracleAccepted(msg.sender, penaltyForRequest);
          token.transfer(msg.sender, penaltyForRequest + penaltyForRequest);
        }
      }
      else {
        uint256 i = 0;
        uint256 currentQuorum = 0;
        uint256 len = oracles.getOracleCount();
        uint8[] memory flag = new uint8[](len);

        //iterate through oracle list and check if enough oracles(minimum quorum)
        //have voted the same answer has the current one
        for (i = 0 ; i < len ; i ++) {
          if (checkRetrievedValue(currRequest.priceAnswers[oracles.getOracleByIndex(i)], _priceRetrieved)) {
            currentQuorum ++;
            flag[i] = 1;
          }
        }

        //request Resolved
        if(currentQuorum >= currRequest.minQuorum) {
          for (i = 0 ; i < len ; i ++) {
            if (flag[i] == 1) {
              address addr = oracles.getOracleByIndex(i);
              oracles.increaseOracleAccepted(addr, penaltyForRequest);
              token.transfer(addr, penaltyForRequest + penaltyForRequest);
            }
          }

          currRequest.agreedPrice = _priceRetrieved;
          currRequest.isFinished = true;

          emit UpdatedPrice (
            currRequest.id,
            _priceRetrieved,
            currRequest.contractAddr
          );
        }
      }
    }
  }
}

// pragma solidity >=0.4.21 <0.6.0;
pragma solidity >=0.6.6;

interface IDEOR {
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
}

// pragma solidity >=0.4.21 <0.6.0;
pragma solidity >=0.6.6;

interface IDataQuery {

  struct requestAnswer {
      uint256 id;
      uint256 timestamp;
      string answer;
  }

  function getLatestAnswer() external returns (string memory);
  function getLatestTimestamp() external returns (uint256);
  function getTimestamp(uint256 _id) external returns (uint256);
  function getAnswer(uint256 _id) external returns (string memory);
  function addRequestAnswer(string calldata _answer) external;
}

// pragma solidity >=0.4.21 <0.6.0;
pragma solidity >=0.6.6;

interface IOracles {

  struct reputation {
    bytes32 name;
    address addr;
    uint256 totalAssignedRequest;        //total number of past requests that an oracle has agreed to, both fulfilled and unfulfileed
    uint256 totalCompletedRequest;       //total number of past requests that an oracle has fulfileed
    uint256 totalAcceptedRequest;        //total number of requests that have been accepted
    uint256 totalResponseTime;           //total seconds of response time
    uint256 lastActiveTime;              //last active time of the oracle as second
    uint256 totalEarned;                 //total earned
  }

  event NewOracle(address addr);

  function getOracleCount () external returns (uint256);
  function isOracleAvailable (address addr) external returns (bool);
  function getOracleByIndex (uint256 idx) external returns (address);
  function increaseOracleAssigned (address addr) external;
  function increaseOracleCompleted (address addr, uint256 responseTime) external;
  function increaseOracleAccepted (address addr, uint256 earned) external;
  function getOracleLastActiveTime (address addr) external returns (uint256);
  function updateOracleLastActiveTime (address addr) external;
}

// pragma solidity >=0.4.21 <0.6.0;
pragma solidity >=0.6.6;

interface IPriceFeed {

  struct requestAnswer {
      uint256 id;
      uint256 timestamp;
      int256 priceAnswer;
  }

  function getLatestAnswer() external returns (int256);
  function getLatestTimestamp() external returns (uint256);
  function getTimestamp(uint256 _id) external returns (uint256);
  function getAnswer(uint256 _id) external returns (int256);
  function addRequestAnswer(int256 _priceAnswer) external;
}

// pragma solidity >=0.4.21 <0.6.0;
pragma solidity >=0.6.6;

interface IPriceOracle {
    struct Request {
        uint256 id;                            //request id
        uint256 timestamp;                     //Request Timestamp
        uint256 minQuorum;                     //minimum number of responses to receive before declaring final result
        uint256 selectedOracleCount;                //selected oracle count
        int256 agreedPrice;
        bool isFinished;
        address contractAddr;               // contract to save result
        string queries;
        mapping(address => int256) priceAnswers;     //answers provided by the oracles
        mapping(address => uint256) quorum;    //oracles which will query the answer (1=oracle hasn't voted, 2=oracle has voted)
    }

    struct reputation {
        bytes32 name;
        address addr;
        uint256 totalAssignedRequest;        //total number of past requests that an oracle has agreed to, both fulfilled and unfulfileed
        uint256 totalCompletedRequest;       //total number of past requests that an oracle has fulfileed
        uint256 totalAcceptedRequest;        //total number of requests that have been accepted
        uint256 totalResponseTime;           //total seconds of response time
        uint256 lastActiveTime;              //last active time of the oracle as second
        uint256 totalEarned;                 //total earned
    }

    event NewRequest(uint256 id, string queries, address contractAddr);
    event UpdatedPrice(uint256 id, int256 agreedPrice, address contractAddr);
    event DeletedRequest(uint256 id);

    function createRequest(string calldata queries, address contractAddr) external;
    function updateRequest(uint256 _id, int256 _priceRetrieved) external;
}

pragma solidity >=0.6.6;

contract Ownable {
    address public owner;

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public {
        owner = msg.sender;
    }


    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}

// pragma solidity >=0.4.21 <0.6.0;
pragma solidity >=0.6.6;


/**
 * Randomizer to generating psuedo random numbers
 */
contract Randomizer {
    function getRandom(uint gamerange) internal view returns (uint)
    {
        return
            uint(
                keccak256(
                    abi.encodePacked(
                        block.timestamp +
                            block.difficulty +
                            uint(keccak256(abi.encodePacked(block.coinbase)))
                    )
                )
            ) % gamerange;
    }

    function getRandom(uint gamerange, uint seed) internal view returns (uint)
    {
        return
            uint(
                keccak256(
                    abi.encodePacked(
                        now +
                            block.difficulty +
                            uint(
                                keccak256(abi.encodePacked(block.coinbase))
                            ) +
                            seed
                    )
                )
            ) % gamerange;
    }

    function getRandom() internal view returns (uint) {
        return
            uint(
                keccak256(
                    abi.encodePacked(
                        block.timestamp +
                            block.difficulty +
                            uint(keccak256(abi.encodePacked(block.coinbase)))
                    )
                )
            );
    }
}

// SPDX-License-Identifier: MIT
// pragma solidity ^0.7.0;
pragma solidity >=0.6.6;
// pragma solidity >=0.4.21 <0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathDEOR {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
    * @dev Returns the subtraction of two unsigned integers, reverting on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    * - Subtraction cannot overflow.
    */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

  /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    * - Multiplication cannot overflow.
    */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
    * @dev Returns the integer division of two unsigned integers. Reverts on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }

  /**
    * @dev Returns the ceiling of log_2,
    *
    */
  function log_2(uint256 x) internal pure returns (uint256) {
    uint256 idx = 1;
    uint256 res = 0;
    while (x > idx) {
      idx = idx << 1;
      res = add(res, 1);
    }
    return res;
  }
}

// pragma solidity >=0.4.21 <0.6.0;
pragma solidity >=0.6.6;

import "./Randomizer.sol";

contract Selection is Randomizer {

    struct Pair {
        uint id;
        uint value;
    }

    function quickSort(Pair[] memory arr, int left, int right) internal pure {
        int i = left;
        int j = right;
        if (i == j) return;
        uint pivot = arr[uint(left + (right - left) / 2)].value;
        while (i <= j) {
            while (arr[uint(i)].value < pivot) i++;
            while (pivot < arr[uint(j)].value) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(arr, left, j);
        if (i < right)
            quickSort(arr, i, right);
    }

    function getSelectedOracles(uint n) internal view returns (uint[] memory) {
        Pair[] memory data = new Pair[](n);
        uint[] memory res = new uint[](n);
        uint i = 0;
        
        for (i = 0 ; i < n ; i ++) {
            data[i] = Pair(i, getRandom(n));
        }

        quickSort(data, int(0), int(data.length - 1));
        
        for (i = 0 ; i < n ; i ++) {
            res[i] = data[i].id;
        }

        return res;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}