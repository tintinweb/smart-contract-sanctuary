// SPDX-License-Identifier: UNLICENSED
pragma experimental ABIEncoderV2;
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * Smart Contract to store predictions for DAX stocks
 */
contract PredictionsDB {
    using SafeMath for uint256;

    // Payable constructor can receive Ether
    constructor() public {
        owner = payable(msg.sender);
    }

    struct Prediction {
        address predictor;
        string symbol;
        string date;
        uint256 unixDate;
        uint256 price;
        bool checked;
    }

    // Payable address can receive Ether
    address payable public owner;
    address private cbContract;
    mapping(address => Prediction[]) public predictions;

    // modifier that requires a date in unix format to be within Xetra opening hours
    // modifier withinOpeningHours(uint256 _unixDate) {
    //     require(
    //         _unixDate > now &&
    //             _unixDate.div(3600).mod(24) >= 7 &&
    //             _unixDate.div(3600).mod(24) <= 15 &&
    //             _unixDate.div(86400).add(4).mod(7) >= 1 &&
    //             _unixDate.div(86400).add(4).mod(7) <= 5,
    //         "Insufficient date!"
    //     );
    //     if (_unixDate.div(3600).mod(24) == 15) {
    //         require(_unixDate.div(60).mod(60) <= 30, "Insufficient date!");
    //     }
    //     _;
    // }

    // modifier that requires that there is no similar prediction
    // modifier onlyNewPredictions(
    //     address _predictor,
    //     uint256 _unixDate,
    //     string memory _symbol,
    //     uint256 _price
    // ) {
    //     bool existingPrediction;
    //     for (uint256 i = 0; i < predictions[_predictor].length; i++) {
    //         if (
    //             predictions[_predictor][i].unixDate == _unixDate &&
    //             (keccak256(
    //                 abi.encodePacked((predictions[_predictor][i].symbol))
    //             ) == keccak256(abi.encodePacked((_symbol)))) &&
    //             predictions[_predictor][i].price == _price
    //         ) {
    //             existingPrediction = true;
    //         }
    //     }
    //     require(existingPrediction == false, "Prediction already exists!");
    //     _;
    // }

    // modifier that requires that a predictor has at least one prediction
    modifier onlyPredictors(address _predictor) {
        require(
            predictions[_predictor].length > 0,
            "No predictions available!"
        );
        _;
    }

    // modifier that requires the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    // modifier that requires the contract owner
    modifier onlyRepTokenContract() {
        require(
            msg.sender == cbContract,
            "Caller is not the RepToken contract"
        );
        _;
    }

    event PredictionAdded(
        address predictor,
        string symbol,
        string date,
        uint256 _unixDate,
        uint256 price
    );

    /**
     * Function to add a prediction to the mapping predictions, only within Xetra opening hours
     *
     * @param _symbol - the symbol of the DAX stock (e.g. "DAI")
     * @param _date - the date in the future of the prediction, within Xetra opening hours (e.g. 2021-06-17 17:28)
     * @param _unixDate - same as _date but in unix format (e.g. 1623943680)
     * @param _price - real price multiplied by 100000 to get rid of comma (e.g. 79.41000 * 10000 => 7941000)
     */
    function addPrediction(
        string calldata _symbol,
        string calldata _date,
        uint256 _unixDate,
        uint256 _price
    ) external {
        predictions[msg.sender].push(
            Prediction(msg.sender, _symbol, _date, _unixDate, _price, false)
        );
        emit PredictionAdded(msg.sender, _symbol, _date, _unixDate, _price);
    }

    /**
     * Function to get predictions from the mapping predictions
     *
     * @param _predictor - the address of the predictor
     */
    function getPredictions(address _predictor)
        external
        view
        onlyPredictors(_predictor)
        returns (
            string[] memory,
            string[] memory,
            uint256[] memory,
            uint256[] memory,
            bool[] memory
        )
    {
        string[] memory symbols = new string[](predictions[_predictor].length);
        string[] memory dates = new string[](predictions[_predictor].length);
        uint256[] memory unixDates = new uint256[](
            predictions[_predictor].length
        );
        uint256[] memory prices = new uint256[](predictions[_predictor].length);
        bool[] memory checks = new bool[](predictions[_predictor].length);

        for (uint256 i = 0; i < predictions[_predictor].length; i++) {
            symbols[i] = predictions[_predictor][i].symbol;
            dates[i] = predictions[_predictor][i].date;
            unixDates[i] = predictions[_predictor][i].unixDate;
            prices[i] = predictions[_predictor][i].price;
            checks[i] = predictions[_predictor][i].checked;
        }

        return (symbols, dates, unixDates, prices, checks);
    }

    /**
     * Function to set that a prediction was checked
     *
     * @param _predictor - the address of the predictor
     * @param index - the index of the prediction
     */
    function setPredictionChecked(address _predictor, uint256 index)
        external
        onlyRepTokenContract
    {
        predictions[_predictor][index].checked = true;
    }

    /**
     * Function to set the contract address that can call the StockAPI
     *
     * @param _cbContract - address of the calling contract for callback
     */
    function setCallerContract(address _cbContract) external onlyOwner {
        cbContract = _cbContract;
    }

    function kill() external onlyOwner {
        selfdestruct(owner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "petersburg",
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