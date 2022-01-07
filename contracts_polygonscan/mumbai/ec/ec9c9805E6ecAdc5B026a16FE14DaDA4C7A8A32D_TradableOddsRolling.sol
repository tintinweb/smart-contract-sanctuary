/**
 *Submitted for verification at polygonscan.com on 2022-01-06
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/Address.sol

// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: contracts/TradableOdds.sol

pragma solidity ^0.8.6;



contract TradableOdds{
    using Address for address;
    address payable public owner;
    
    enum Outcome{NONE, YES, NO}
    enum BuySell{BUY, SELL}
    
    struct PredictionEvent{
        uint32 startTime;
        uint32 endTime;
        string name;
        string statement;
        address payable creator;
        Outcome outcome;
        uint16 creatorCommissionBasisPoints;
        address oracle;
    }
    struct PredictionEventState{
        uint256 pot;
        uint256 yesPool;
        uint256 noPool;
        uint256 totalPlayers;
        uint256 yPositionsTotal;
        uint256 nPositionsTotal;
    }
    struct FinancialMarket{
        uint openingPrice;
        uint closingPrice;
    }
    struct Position{
        uint256 yes;
        uint256 no;
        bool claimed;
    }

    uint public createMarketIncentive = 1e9;
    uint public resolveMarketIncentive = 1e9;
    
    
    uint256 minTxnAmount = 1000000;
    uint16 operatorCommissionBasisPoints = 0;
    mapping(bytes32 => PredictionEvent) public predictionEvents;
    mapping(bytes32 => FinancialMarket) public financialMarkets;
    mapping(bytes32 =>  PredictionEventState) public predictionEventStates;
    mapping(bytes32 =>  address[]) public players;
    mapping(bytes32 => mapping(address => Position)) public playerPositions;
    mapping(bytes32 => mapping(address => bool)) public collateralWithdrawn;
    mapping(address => uint256) public balances;
    
    event EventCreated(bytes32 indexed key, uint32 startTime, string name, address indexed creator, address oracle, string instrument);
    event BuySellTxn(bytes32 indexed key, address indexed user, uint256 blockTime, Outcome side, int256 coins, int256 txnValue, uint256 yesPool, uint256 noPool);
    event Redeem(bytes32 indexed key, address user, uint256 amount);
    event Refund(bytes32 indexed key, address user, uint256 amount);
    event CollateralWithdraw(bytes32 indexed key, address user, uint256 amount);
    event Debug(string label, bool data1, address data2);
    constructor(){
        owner = payable(msg.sender);
    }
    function getEventID(uint32 startTime, uint32 endTime, string memory name, address oracle) public pure returns (bytes32 eventID){
        eventID = keccak256(abi.encodePacked(startTime, endTime, name, oracle));
    }
    function getPlayerPosition(uint32 startTime, uint32 endTime, string calldata name, address oracle, address player) external view returns (uint yes, uint no, bool claimed){
        bytes32 id = getEventID(startTime, endTime, name, oracle);
        yes = playerPositions[id][player].yes;
        no = playerPositions[id][player].yes;
        claimed = playerPositions[id][player].claimed;
    }
    function createEvent(uint32 startTime, uint32 endTime, string memory name, string memory statement, uint16 creatorCommissionBasisPoints, uint16 yesProbabilityBasisPoints, uint256 collateral, address oracle, address creator) public {
        bytes32 key = getEventID(startTime, endTime, name, oracle);
        require(predictionEvents[key].endTime == 0, 'Already exists');
        require(creatorCommissionBasisPoints < 10000, 'Invalid commission bps');
        require(yesProbabilityBasisPoints < 10000, 'Probablity basis points should be less than 10k');
        predictionEvents[key] = PredictionEvent(startTime, endTime, name, statement, payable(creator), Outcome.NONE, creatorCommissionBasisPoints, oracle);
        require(collateral <= balances[creator], 'Not enough creator balance for collateral');
        predictionEventStates[key] = PredictionEventState(0, 0, 0, 0, 0, 0);
        balances[creator] -= collateral;
        predictionEventStates[key].pot += collateral;
        addLiquidityForBasisPoints(key, yesProbabilityBasisPoints, collateral);
        string memory instrument = '';
        if (oracle != address(0)){
            instrument = symbol(oracle);
        }
        emit EventCreated(key, startTime,  name, creator, oracle, instrument);
    }
    /*function getEventOutcome(bytes32 id) public returns (Outcome outcome){
        outcome = predictionEvents[id].outcome;
    }*/
    function symbol(address oracle) private view returns (string memory) {
        require(oracle.isContract(), "Oracle must be a contract address");
        try AggregatorV3Interface(oracle).description() returns (string memory description) {
            return description;
        } catch (bytes memory) {
            return "Oracle must be an AggregatorV3Interface contract";
        }
    }
    function addLiquidityForMarketId(bytes32 key) external payable {
        uint256 yesProbabilityBasisPoints = (predictionEventStates[key].noPool * 10000)/(predictionEventStates[key].yesPool + predictionEventStates[key].noPool);
        predictionEventStates[key].pot = predictionEventStates[key].pot + (msg.value);
        addLiquidityForBasisPoints(key, yesProbabilityBasisPoints, msg.value);
    }
    function addLiquidityForBasisPoints(bytes32 key, uint256 yesProbabilityBasisPoints, uint collateral) public payable{
        if (yesProbabilityBasisPoints < 5000){
            predictionEventStates[key].noPool += collateral *  (yesProbabilityBasisPoints) /  (10000 - yesProbabilityBasisPoints);
            predictionEventStates[key].yesPool += collateral;
        }
        else {
            predictionEventStates[key].noPool += collateral;
            predictionEventStates[key].yesPool += collateral *  (10000 - yesProbabilityBasisPoints) /  (yesProbabilityBasisPoints);
        }
    }
    function _checkPrice(bytes32 key, Outcome yesNo, int256 units, uint256 worstPrice) internal view {
        if (yesNo == Outcome.YES){
            units > 0 ? require((predictionEventStates[key].noPool * 1e18)/(predictionEventStates[key].yesPool + predictionEventStates[key].noPool) < worstPrice, 'Current Y Price Above Buy Limit') : require((predictionEventStates[key].noPool * 1e18)/(predictionEventStates[key].yesPool + predictionEventStates[key].noPool) > worstPrice, 'Current Y Price Below Sell Limit');
        }
        else if (yesNo == Outcome.NO){
            units > 0 ? require((predictionEventStates[key].yesPool * 1e18)/(predictionEventStates[key].yesPool + predictionEventStates[key].noPool) < worstPrice, 'Current N Price Above Buy Limit') : require((predictionEventStates[key].yesPool * 1e18)/(predictionEventStates[key].yesPool + predictionEventStates[key].noPool) > worstPrice, 'Current N Price Below Sell Limit');
        }
    }
    //positive units = Buy, negative = Sell
    function doBuySellTxn(bytes32 key, Outcome yesNo, int256 units, uint256 worstPrice) public {
        require(predictionEvents[key].endTime > 0, 'Invalid Event');
        require(predictionEvents[key].outcome == Outcome.NONE, 'Event Resolved');
        require(units != 0, 'Zero units received');
        int256 unitsWithSlippage = getUnitsWithSlipppage(key, yesNo, units, worstPrice);
        if (units > 0 && unitsWithSlippage < units){
            units = unitsWithSlippage;
        }
        if (units < 0 && unitsWithSlippage < units*-1){
            units = unitsWithSlippage * -1;
        }
        if (units < 0){
            if (yesNo == Outcome.YES){
                require(playerPositions[key][msg.sender].yes >= uint256(units * -1), 'Not enough Yes coins to sell');
            }
            else {
                require(playerPositions[key][msg.sender].no >= uint256(units * -1), 'Not enough No coins to sell');
            }
        }
        
        int256 yesCoins = int256(predictionEventStates[key].yesPool);
        int256 noCoins = int256(predictionEventStates[key].noPool);
        int256 temp = yesCoins + noCoins - 2*units;
        uint sqrtTemp;
        int256 cost;
        if (yesNo == Outcome.YES){
            sqrtTemp = sqrt(uint256(temp*temp + 8*units*noCoins));
        }
        else {
            sqrtTemp = sqrt(uint256(temp*temp + 8*units*yesCoins));
        } 
        
        cost = (int256(sqrtTemp)-temp)/4;
        _process(key, yesNo,  units,  cost);
    }
    function getUnitsWithSlipppage(bytes32 key, Outcome yesNo, int256 units, uint256 worstPrice) public view returns (int256 slippageUnits){
        require(worstPrice < 1e18, 'Slippage Price should be less than 1');
        int256 cost;
        int256 ySigned = int256(predictionEventStates[key].yesPool);
        int256 nSigned = int256(predictionEventStates[key].noPool);
        int256 worstPriceSigned = int256(worstPrice);
        
        if (yesNo == Outcome.YES){
            uint256 yPrice = predictionEventStates[key].noPool * 1e18 / (predictionEventStates[key].yesPool+predictionEventStates[key].noPool);
            int256 numerator = worstPriceSigned * (ySigned + nSigned)/1e18 - nSigned;
            if (units > 0){//buy Yes
                require(worstPrice > yPrice, 'Buy Worst Price below Y Price');
                cost = numerator *1e18 / (2*(1e18 - worstPriceSigned));
            }
            else {//sell Yes
                require(worstPrice < yPrice, 'Sell Worst Price above Y Price');
                cost = numerator*1e18 / (2*(worstPriceSigned - 1e18));
            }

        }
        else {
            uint256 nPrice = predictionEventStates[key].yesPool * 1e18 / (predictionEventStates[key].yesPool+predictionEventStates[key].noPool);
            int256 numerator = worstPriceSigned * (ySigned + nSigned)/1e18 - ySigned;
            if (units > 0){//buy No
                require(worstPrice > nPrice, 'Buy Worst Price below N Price');
                cost = numerator*1e18 / (2*(1e18 - worstPriceSigned));
            }
            else {//sell No
                require(worstPrice < nPrice, 'Sell Worst Price above N Price');
                cost = numerator*1e18 / (2*(worstPriceSigned - 1e18));
            }
        }
        uint256 commission = (10000 - predictionEvents[key].creatorCommissionBasisPoints);
        cost = cost * int256(commission)/10000;
        slippageUnits = cost * 1e18 / int256(worstPrice);
        require(slippageUnits > 0, 'Invalid Slippage units');
    }
    
    function _process(bytes32 key, Outcome yesNo, int256 units, int256 cost) internal {
        uint256 costWithCommission;
        if (units > 0){
            require(cost > 0, 'Buy cost should be positive');
            costWithCommission = _buyCommission(key, cost);
            _updatePool(key, yesNo, units, cost);
        }
        else {
            require(cost < 0, 'Sell cost should be negative');
            costWithCommission = _sellCommission(key, cost);
            _updatePool(key, yesNo, units, cost);
        }
        uint256 yes = predictionEventStates[key].yesPool;
        uint256 no = predictionEventStates[key].noPool;
        bool exists = false;
        for (uint i=0; i<players[key].length; i++){
            if (players[key][i] == msg.sender) {
                exists = true;
                break;
            }
        }
        if (!exists) {
            players[key].push(msg.sender);
            predictionEventStates[key].totalPlayers ++;
        }
        emit BuySellTxn(key, msg.sender, block.timestamp, yesNo, units, int256(costWithCommission), yes, no);  
    }
    function _buyCommission(bytes32 key, int256 cost) internal returns (uint256 costWithCommission){
        uint256 commission = uint256(cost) *  (predictionEvents[key].creatorCommissionBasisPoints) /  (10000);
        costWithCommission = uint256(cost) + (commission);
        require(balances[msg.sender] >= uint256(costWithCommission), 'Not enough balance');
        balances[msg.sender] -= uint256(costWithCommission);
            
        predictionEventStates[key].pot = predictionEventStates[key].pot + (uint256(cost));
        uint256 operatorCommission = commission *  (operatorCommissionBasisPoints) /  (10000);
        uint256 creatorCommission = commission -  (operatorCommission);
        if (creatorCommission > 0) balances[predictionEvents[key].creator] += creatorCommission;
        if (operatorCommission > 0) balances[owner] += operatorCommission;
    }
    function _sellCommission(bytes32 key, int256 cost) internal returns (uint256 costWithCommission) {
        uint256 commission = uint256(cost * -1) *  (predictionEvents[key].creatorCommissionBasisPoints) /  (10000);
        costWithCommission = uint256(cost * -1) -  (commission);
        uint256 operatorCommission = commission *  (operatorCommissionBasisPoints) /  (10000);
            
        uint256 creatorCommission = commission -  (operatorCommission);
        if (creatorCommission > 0) balances[predictionEvents[key].creator] += creatorCommission;
        if (operatorCommission > 0) balances[owner] += operatorCommission;
        predictionEventStates[key].pot = predictionEventStates[key].pot -  (uint256(cost * -1));
        balances[msg.sender] += uint256(costWithCommission);
    }
    function _updatePool(bytes32 key, Outcome yesNo, int256 units, int256 cost) internal {
        if (cost > 0){
            if (yesNo == Outcome.YES){
                predictionEventStates[key].yesPool = predictionEventStates[key].yesPool + (uint(cost)) -  (uint(units));
                predictionEventStates[key].noPool += (uint(cost));
                playerPositions[key][msg.sender].yes += (uint256(units));
                predictionEventStates[key].yPositionsTotal += (uint256(units)); 
            }
            else {
                predictionEventStates[key].yesPool += (uint(cost));
                predictionEventStates[key].noPool = predictionEventStates[key].noPool + (uint(cost)) -  (uint(units));
                playerPositions[key][msg.sender].no += (uint256(units));
                predictionEventStates[key].nPositionsTotal += (uint256(units)); 
            
            }
        }
        else {
            units = units * -1;
            cost = cost * -1;
            if (yesNo == Outcome.YES){
                predictionEventStates[key].yesPool = predictionEventStates[key].yesPool + (uint(units)) -  (uint(cost));
                predictionEventStates[key].noPool -=  (uint(cost));
                playerPositions[key][msg.sender].yes -= (uint256(units));
                predictionEventStates[key].yPositionsTotal -= (uint256(units)); 
            }
            else {
                predictionEventStates[key].yesPool -=  (uint(cost));
                predictionEventStates[key].noPool = predictionEventStates[key].noPool + (uint(units)) -  (uint(cost));
                playerPositions[key][msg.sender].no -= (uint256(units));
                predictionEventStates[key].nPositionsTotal -= (uint256(units)); 
            }
        }
          
    }
    function computeOpenClosePrice(bytes32 id, bool isOpen) public returns (uint){
        uint32 timeBoundary = isOpen ? predictionEvents[id].startTime : predictionEvents[id].endTime;
        (uint80 relevantRound,uint roundPrice) = getRelevantRound(predictionEvents[id].oracle, timeBoundary);
        if (relevantRound > 0){
            if (roundPrice > 0){
                isOpen ? financialMarkets[id].openingPrice = roundPrice : financialMarkets[id].closingPrice = roundPrice;
            }
        }
        return roundPrice;
    }
    function getRelevantRound(address oracle, uint timestampBoundary) public view returns (uint80 relevantRound, uint relevantRoundPrice){
        (uint80 roundId,int price,,uint roundTimestamp,) = AggregatorV3Interface(oracle).latestRoundData();
        if (roundTimestamp <= timestampBoundary) return (0,0);
        while (roundTimestamp > timestampBoundary) (roundId,,,roundTimestamp,) = AggregatorV3Interface(oracle).getRoundData(roundId - 1);
        // Todo Remove the below line and get it from temp
        (relevantRound,price,,,)  = AggregatorV3Interface(oracle).getRoundData(roundId + 1);
        relevantRoundPrice = uint(price);
    }
    function resolveFinancialMarket(bytes32 id, bool movePlayerClaims) public returns (uint){
        require(predictionEvents[id].oracle != address(0), 'No Oracle set');
        if(financialMarkets[id].openingPrice > 0){
            computeOpenClosePrice(id, false);
            if (financialMarkets[id].closingPrice > 0){
                financialMarkets[id].closingPrice > financialMarkets[id].openingPrice ? resolve(id, Outcome.YES, movePlayerClaims, true) : resolve(id, Outcome.NO, movePlayerClaims, true);  
            }
        }
        return financialMarkets[id].closingPrice;
    }
    function resolveNonFinancialMarket(bytes32 id, Outcome outcome, bool movePlayerClaims) external {
        require(msg.sender == predictionEvents[id].creator || msg.sender == owner, 'Only Creator/Operator can resolve');
        resolve(id, outcome, movePlayerClaims, true);  
    }
    function resolve(bytes32 key, Outcome outcome, bool updateWinnerBalances, bool updateCreatorBalance) internal {
        require(predictionEvents[key].endTime > 0, 'Invalid Event');
        require(predictionEvents[key].endTime < block.timestamp, 'Early to resolve');
        //require(msg.sender == predictionEvents[key].creator || msg.sender == owner, 'Only Creator/Operator can resolve');
        require(predictionEvents[key].outcome == Outcome.NONE, 'Already Resolved');
        predictionEvents[key].outcome = outcome;
        if (updateWinnerBalances) moveWinningsToPlayers(key, 0, players[key].length);
        if (updateCreatorBalance) withdrawCollateral(key, false, predictionEvents[key].creator);
    }
    function moveWinningsToPlayers(bytes32 key, uint startIndex, uint endIndex) public {
        require(predictionEvents[key].outcome != Outcome.NONE, 'Not Resolved yet');
        for (uint i=startIndex; i<endIndex; i++){
            address player = players[key][i];
            if (predictionEvents[key].outcome == Outcome.YES && playerPositions[key][player].yes > 0)
            {
                balances[player] += playerPositions[key][player].yes;
                predictionEventStates[key].yPositionsTotal -= playerPositions[key][player].yes;
                predictionEventStates[key].pot -= playerPositions[key][player].yes;
                playerPositions[key][player].yes = 0;
            }
            if (predictionEvents[key].outcome == Outcome.NO && playerPositions[key][player].no > 0)
            {
                balances[player] += playerPositions[key][player].no;
                predictionEventStates[key].nPositionsTotal -= playerPositions[key][player].no;
                predictionEventStates[key].pot -= playerPositions[key][player].no;
                playerPositions[key][player].no = 0;
            }
        }
    }
    function claim(bytes32 key, bool withdrawAmounts, address player) external {
        uint256 current;
        require(predictionEvents[key].outcome != Outcome.NONE, 'Not Resolved yet');
        if (predictionEvents[key].outcome == Outcome.YES) {
            require(playerPositions[key][player].yes > 0, 'Zero Yes Position');
            current = playerPositions[key][player].yes;
            playerPositions[key][player].yes = 0;
            predictionEventStates[key].yPositionsTotal = predictionEventStates[key].yPositionsTotal -  (current);
        }
        if (predictionEvents[key].outcome == Outcome.NO){
            require(playerPositions[key][player].no > 0, 'Zero No Position');
            current = playerPositions[key][player].no;
            playerPositions[key][player].no = 0;
            predictionEventStates[key].nPositionsTotal = predictionEventStates[key].nPositionsTotal -  (current);    
        } 
        predictionEventStates[key].pot = predictionEventStates[key].pot -  (current);
        balances[player] = balances[player] + current;
        if (withdrawAmounts) withdraw();
        emit Redeem(key, player, current);
    }
    function withdraw() public{
        transferBalance(msg.sender);
    }
    function deposit() external payable{
        balances[msg.sender] += msg.value;
    }
    function depositForUser(address trader) external payable{
        balances[trader] += msg.value;
    }
    function transferBalance(address player) public{
        uint256 balance = balances[player];
        if (balance > 0) {
            balances[player] = 0;
            payable(player).transfer(balance);
        }
    }
    function withdrawCollateral(bytes32 key, bool withdrawAmounts, address eventCreator) public {
        require(predictionEvents[key].outcome != Outcome.NONE, 'Not Resolved yet');
        //emit Debug('withdrawCollateral', collateralWithdrawn[key][eventCreator], eventCreator);
        require(!collateralWithdrawn[key][eventCreator], 'Already claimed collateral');
        uint256 withdrawable;
        if (predictionEvents[key].outcome == Outcome.YES) {
            withdrawable = predictionEventStates[key].pot -  (predictionEventStates[key].yPositionsTotal);
        }
        if (predictionEvents[key].outcome == Outcome.NO){
            withdrawable = predictionEventStates[key].pot -  (predictionEventStates[key].nPositionsTotal);
        }
        if (withdrawable > 0){
            predictionEventStates[key].pot -= withdrawable;
            collateralWithdrawn[key][eventCreator] = true;
            balances[eventCreator] = balances[eventCreator] + withdrawable;
            if (withdrawAmounts) withdraw();
        }
        emit CollateralWithdraw(key, eventCreator, withdrawable);
    }
    function setMinTxnAmount(uint256 _minTxnAmt) external isOwner{
        minTxnAmount = _minTxnAmt;
    }
    function setOperatorCommissionBps(uint16 _operatorCommissionBasisPoints) external isOwner{
        operatorCommissionBasisPoints = _operatorCommissionBasisPoints;
    }
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }
}

// File: contracts/TradableOddsRolling.sol

pragma solidity ^0.8.6;



contract TradableOddsRolling is TradableOdds{

    enum BetDuration {None, FifteenMinutes, OneHour, OneDay, OneWeek, OneMonth}

    uint16 public feeBasispoints = 0;
    mapping(BetDuration => uint32) public durations;
    mapping(BetDuration => uint) public minLiquidityForDuration;
    mapping(BetDuration => uint8) public futureWindowsAllowed;
    uint8 operatorBalanceMultiplier = 5;
    constructor() {
        owner = payable(msg.sender);
        durations[BetDuration.FifteenMinutes] = 15 * 60;
        durations[BetDuration.OneHour] = 1 * 60 * 60;
        durations[BetDuration.OneDay] = 24 * 60 * 60;
        durations[BetDuration.OneWeek] = 7 * 24 * 60 * 60;
        durations[BetDuration.OneMonth] = 31 * 24 * 60 * 60;
        minLiquidityForDuration[BetDuration.FifteenMinutes] = 1e18;
        minLiquidityForDuration[BetDuration.OneHour] = 1e18;
        minLiquidityForDuration[BetDuration.OneDay] = 10e18;
        futureWindowsAllowed[BetDuration.OneHour] = 1;
        futureWindowsAllowed[BetDuration.OneDay] = 1;
    }
    receive() external payable {
        balances[owner] += msg.value;
    }
    function createMarket(address oracle, BetDuration duration, uint32 startsAt) public{
        require(startsAt % durations[duration] == 0, 'Invalid Start Time');
        uint farthestWindowAllowed = block.timestamp - (block.timestamp % durations[duration]) + futureWindowsAllowed[duration] * durations[duration];
        require(startsAt >= block.timestamp - (block.timestamp % durations[duration]), 'Past time');
        require(startsAt <= farthestWindowAllowed, 'Far into future');
        require(balances[owner] >= (minLiquidityForDuration[duration] + createMarketIncentive), 'Not enough balance to create new market plus incentive');
        createEvent(startsAt, startsAt + durations[duration], '', '', feeBasispoints, 5000, minLiquidityForDuration[duration], oracle, owner);
    }
    function transact(address oracle, BetDuration duration, uint32 startsAt, TradableOdds.Outcome yesNo, int256 units, uint256 worstPrice, bool movePlayerClaims) external payable{
        require(duration != BetDuration.None, "Invalid bet duration");
        require(yesNo != TradableOdds.Outcome.NONE, "Invalid bet direction");
        require(units != 0, 'Zero units received');
        bytes32 key = getEventID(startsAt, startsAt + durations[duration], '', oracle);
        bytes32 prevMarketKey = getEventID(startsAt - durations[duration], startsAt, '', oracle);
        uint prevClosingPrice = 0;
        if ((predictionEvents[prevMarketKey].startTime > 0) && predictionEvents[prevMarketKey].outcome == TradableOdds.Outcome.NONE){
            prevClosingPrice = resolveFinancialMarket(prevMarketKey, movePlayerClaims);
        }
        if (predictionEvents[key].startTime == 0){
            createMarket(oracle, duration, startsAt);
            balances[msg.sender] += createMarketIncentive;
            balances[owner] -= createMarketIncentive;
        }
        if (financialMarkets[key].openingPrice == 0){
             if (prevClosingPrice > 0) financialMarkets[key].openingPrice = prevClosingPrice;
             else computeOpenClosePrice(key, true);
        }
        balances[msg.sender] += msg.value;
        doBuySellTxn(getEventID(startsAt, startsAt + durations[duration], '', oracle), yesNo, units, worstPrice);
    }
    function getMarketId(address oracle, BetDuration duration, uint32 startTime) external view returns (bytes32 id){
        id = getEventID(startTime, startTime + durations[duration], '', oracle);
    }
    function getMarket(address oracle, BetDuration duration, uint32 startTime) external view returns (PredictionEvent memory predictionEvent){
        predictionEvent = predictionEvents[getEventID(startTime, startTime + durations[duration], '', oracle)];
    }
    function setMinLiquidity(uint256 _minimumLiquidity, BetDuration duration) external isOwner {
        minLiquidityForDuration[duration] = _minimumLiquidity;
    }
    function setWindowsAllowed(uint8 _futureWindowsAllowed, BetDuration duration) external isOwner {
        futureWindowsAllowed[duration] = _futureWindowsAllowed;
    }
    function setFeeBasisPoints(uint16 _feeBasispoints) external isOwner {
        feeBasispoints = _feeBasispoints;
    }
    function setCreateMarketIncentive(uint _createMarketIncentive) external isOwner {
        createMarketIncentive = _createMarketIncentive;
    }
    function setResolveMarketIncentive(uint _resolveMarketIncentive) external isOwner {
        resolveMarketIncentive = _resolveMarketIncentive;
    }
    function setOperatorBalanceMultiplier(uint8 _operatorBalanceMultiplier) external isOwner {
        operatorBalanceMultiplier = _operatorBalanceMultiplier;
    }
    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }
    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    
}