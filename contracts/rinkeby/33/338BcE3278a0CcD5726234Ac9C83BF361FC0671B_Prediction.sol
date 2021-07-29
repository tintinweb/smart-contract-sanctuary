/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

pragma solidity >0.8.0;


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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

// File: @openzeppelin/contracts/utils/Pausable.sol


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: contracts/interfaces/AggregatorV3Interface.sol


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

contract Prediction is Ownable, Pausable {
    using SafeMath for uint256;

    address public adminAddress;
    address public operatorAddress;
    enum Position {Bull, Bear}
    struct Round {
        uint256 epoch;
        uint256 startBlock;
        uint256 lockBlock;
        uint256 endBlock;
        int256 startPrice;
        int256 closePrice;
        uint256 totalAmount;
        uint256 bullAmount;
        uint256 bearAmount;
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;
        bool oracleCalled;
        Position result;
        uint256 percentage;
    }


    struct BetInfo {
        Position position;
        uint256 amount;
        bool claimed; // default false
    }

    //    mapping(uint256 => Round) public rounds;
    mapping(string => mapping(uint256 => Round)) symbolRounds;
    //    mapping(uint256 => mapping(address => BetInfo)) public ledger;
    mapping(string => mapping(uint256 => mapping(address => BetInfo))) ledgerMap;
    mapping(string => mapping(address => uint256[])) public userRounds;
    mapping(string => address) public symbolOracle;
    mapping(string => uint) symbolSwitch;
    mapping(string => uint256) currentRoundMap;
    mapping(string => uint256) oracleLatestRoundIdMap;
    //投注时间（区块数）
    uint256  bettingBlockCount;
    address ptToken;
    address blackHoleAddress = 0x000000000000000000000000000000000000dEaD;
    address teamAddress;
    uint256 requestLock = 0;

    constructor(address _ptToken,uint256 _bettingBlockCount,address _teamAddress){
        ptToken = _ptToken;
        symbolOracle['ETH'] = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
        symbolOracle['BNB'] = 0xcf0f51ca2cDAecb464eeE4227f5295F2384F84ED;
        symbolOracle['BTC'] = 0xECe365B379E1dD183B20fc5f022230C044d51404;
        symbolSwitch['ETH'] = 1;
        symbolSwitch['BNB'] = 1;
        symbolSwitch['BTC'] = 1;
        bettingBlockCount = _bettingBlockCount;
        teamAddress = _teamAddress;
        initStart();
    }

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "admin: wut?");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "operator: wut?");
        _;
    }

    modifier onlyAdminOrOperator() {
        require(msg.sender == adminAddress || msg.sender == operatorAddress, "admin | operator: wut?");
        _;
    }

    modifier methodLock(){
        require(requestLock == 0,"tryAgainLater");
        requestLock = 1;
        _;
        requestLock = 0;

    }

    /**
     * @dev set admin address
     * callable by owner
     */
    function setAdmin(address _adminAddress) external onlyOwner {
        require(_adminAddress != address(0), "Cannot be zero address");
        adminAddress = _adminAddress;
    }
    /**
    *设置投注时间
    */
    function setbettingBlockCount(uint256 _bettingBlockCount) external onlyOwner {
        require(_bettingBlockCount < 1, "TIME_IS_TOO_SHORT");
        bettingBlockCount = _bettingBlockCount;
    }

    /**
     * @dev set operator address
     * callable by admin
     */
    function setOperator(address _operatorAddress) external onlyAdmin {
        require(_operatorAddress != address(0), "Cannot be zero address");
        operatorAddress = _operatorAddress;
    }

    function setSymbolOracle(string memory _symbol,address _oracleAddress) external onlyAdmin(){
        symbolOracle[_symbol] = _oracleAddress;
    }

    function getSymbolOracle(string memory _symbol) view external returns(address){
        return  symbolOracle[_symbol];
    }

    function setPtToken(address _ptToken) external onlyAdmin {
        require(_ptToken != address(0), "Cannot be zero address");
        ptToken = _ptToken;
    }

    function getPtToken() view external returns(address){
        return ptToken;
    }
    //开始初始化
    function initStart() internal{
        startRound("ETH");
        startRound("BNB");
        startRound("BTC");
    }

    event startRoundPrice(uint256 currentRound,uint80 roundId, int256 price, uint256 timestamp);

    /*
    *开始回合
    * return （状态，当前）
    */
    function startRound(string memory _symbol) internal whenNotPaused returns(bool,uint256){
        if(symbolSwitch[_symbol] != 1){
            return(false,0);
        }
        address _ore= symbolOracle[_symbol];
        if(_ore == address(0)){
            return(false,0);
        }
        (uint80 roundId, int256 price, , uint256 timestamp, ) = AggregatorV3Interface(_ore).latestRoundData();
        require(oracleLatestRoundIdMap[_symbol] < roundId, "Oracle update roundId must be larger than oracleLatestRoundId");
        oracleLatestRoundIdMap[_symbol] = uint256(roundId);
        //当前回合
        uint256 currentRound = currentRoundMap[_symbol];
        //当前回合+1 开启下一回合
        uint256 blockNumber = block.number;
        //取上一回合判断结束区块和当前区块
        Round storage lastRount = symbolRounds[_symbol][currentRound];
        if(lastRount.endBlock > currentRound){
            return(false,0);
        }
        Round storage round = symbolRounds[_symbol][currentRound+1];
        round.startBlock = blockNumber;

        round.endBlock = blockNumber.add(bettingBlockCount);
        //结束区块2个块之前不允许下注
        round.lockBlock =round.endBlock.sub(2);
        round.epoch = currentRound+1;
        round.totalAmount = 0;
        round.startPrice = price;
        symbolRounds[_symbol][currentRound].closePrice = price;
        currentRoundMap[_symbol] = currentRound+1;
        emit startRoundPrice(currentRound+1,roundId,price,timestamp);
        return (true,currentRound+1);
    }

    function getLatestRoundData(string memory _symbol) external view returns( uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound){
        address _ore= symbolOracle[_symbol];
        return AggregatorV3Interface(_ore).latestRoundData();
    }

    function getOracleLatestRoundIdMap(string memory _symbol) external view returns(uint256){
        return oracleLatestRoundIdMap[_symbol];
    }

    function startRoundAdmin(string memory _symbol) external onlyAdminOrOperator  whenNotPaused returns(bool,uint256){
        return startRound(_symbol);
    }

    function bettingBull(string memory _symbol,uint256 amount) external whenNotPaused returns(bool){
        uint256 currentEpoch = currentRoundMap[_symbol];
        require(canItBeInvested(_symbol,currentEpoch),"not_allowed_to_invest");
        require(ledgerMap[_symbol][currentEpoch][msg.sender].amount == 0, "Can only bet once per round");
        TransferHelper.safeTransferFrom(ptToken,_msgSender(),address(this),amount);
        Round storage round = symbolRounds[_symbol][currentEpoch];
        BetInfo storage betInfo = ledgerMap[_symbol][currentEpoch][msg.sender];
        round.totalAmount = round.totalAmount.add(amount);
        betInfo.position = Position.Bull;
        round.bullAmount = round.bullAmount.add(amount);

        // Update user data

        betInfo.amount = amount;
        userRounds[_symbol][msg.sender].push(currentEpoch);
        return true;

    }

    function bettingBear(string memory _symbol,uint256 amount) external whenNotPaused returns(bool){
        uint256 currentEpoch = currentRoundMap[_symbol];
        require(canItBeInvested(_symbol,currentEpoch),"not_allowed_to_invest");
        require(ledgerMap[_symbol][currentEpoch][msg.sender].amount == 0, "Can only bet once per round");
        TransferHelper.safeTransferFrom(ptToken,_msgSender(),address(this),amount);
        Round storage round = symbolRounds[_symbol][currentEpoch];
        BetInfo storage betInfo = ledgerMap[_symbol][currentEpoch][msg.sender];
        round.totalAmount = round.totalAmount.add(amount);
        round.bearAmount = round.bearAmount.add(amount);
        betInfo.position = Position.Bear;

        // Update user data

        betInfo.amount = amount;
        userRounds[_symbol][msg.sender].push(currentEpoch);
        return true;

    }
    //判断是否可以投入
    function canItBeInvested(string memory _symbol,uint256 _currentEpoch) internal returns(bool){
        Round storage r = symbolRounds[_symbol][_currentEpoch];
        return symbolSwitch[_symbol] == 1 && r.startBlock > 0 && r.endBlock >0 && r.lockBlock > block.number;
    }
    //需要下一区块计算收益
    event nextBlockSettlement(string _symbol,uint256 _currentEpoch);
    //手续费占比
    uint256 feeProportion = 25;
    uint256 percentage = 1000;
    //销毁比例
    uint256 percentageOfDestruction = 500;

    //结算
    //根据币种查询上一回合 总投入 和 做多做空 计算做多做空的占比
    function settleAccounts(string memory _symbol,uint256 _epoch) external onlyAdminOrOperator  whenNotPaused methodLock {
        Round storage round = symbolRounds[_symbol][_epoch];
        if(round.endBlock == 0){
            return;
        }
        if(block.number < round.endBlock){
            emit nextBlockSettlement(_symbol,_epoch);
        }
        //计算收取的手续费
        uint256 fee = round.totalAmount.mul(feeProportion).div(percentage);
        //销毁
        uint256 destroy = fee.mul(percentageOfDestruction).div(percentage);
        TransferHelper.safeTransfer(ptToken,blackHoleAddress,destroy);
        TransferHelper.safeTransfer(ptToken,teamAddress,fee.sub(destroy));
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;
        uint256 treasuryAmt;
        if (round.closePrice > round.startPrice) {
            round.result = Position.Bull;
            rewardBaseCalAmount = round.bullAmount;
            rewardAmount = round.totalAmount.sub(fee);
            treasuryAmt = fee;
        }
        // Bear wins
        else if (round.closePrice < round.startPrice) {
            round.result = Position.Bear;
            rewardBaseCalAmount = round.bearAmount;
            rewardAmount = round.totalAmount.sub(fee);
            treasuryAmt = fee;
        }
        // House wins
        else {
            rewardBaseCalAmount = 0;
            rewardAmount = 0;
            treasuryAmt = round.totalAmount;
        }
        round.oracleCalled = true;
        round.rewardBaseCalAmount = rewardBaseCalAmount;
        round.rewardAmount = rewardAmount;
        //计算占比
        round.percentage = round.rewardAmount.div(round.rewardBaseCalAmount);
    }

    //领取奖励
    function receiveAward(string memory _symbol,uint256 _epoch) external{
        Round storage round = symbolRounds[_symbol][_epoch];
        require(round.oracleCalled,"not_yet_settled");
        BetInfo storage betInfo = ledgerMap[_symbol][_epoch][_msgSender()];
        require(!betInfo.claimed,"Rewards claimed");
        //        require(utilCompareInternal(round.result,betInfo.position),"Position opening direction is different from the correct result");
        require(round.result == betInfo.position,"Position opening direction is different from the correct result");
        TransferHelper.safeTransfer(ptToken,_msgSender(),round.percentage.mul(betInfo.amount));
        betInfo.claimed = true;
    }

}

//代码通用于5点几到6点几版本

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }


}