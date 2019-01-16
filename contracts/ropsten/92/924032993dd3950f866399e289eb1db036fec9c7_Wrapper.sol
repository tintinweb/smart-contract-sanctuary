pragma solidity 0.4.18;

// File: contracts/ERC20Interface.sol

// https://github.com/ethereum/EIPs/issues/20
interface ERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf(address _owner) public view returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint remaining);
    function decimals() public view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

// File: contracts/ConversionRatesInterface.sol

interface ConversionRatesInterface {

    function recordImbalance(
        ERC20 token,
        int buyAmount,
        uint rateUpdateBlock,
        uint currentBlock
    )
        public;

    function getRate(ERC20 token, uint currentBlockNumber, bool buy, uint qty) public view returns(uint);
}

// File: contracts/Utils.sol

/// @title Kyber constants contract
contract Utils {

    ERC20 constant internal ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    uint  constant internal PRECISION = (10**18);
    uint  constant internal MAX_QTY   = (10**28); // 10B tokens
    uint  constant internal MAX_RATE  = (PRECISION * 10**6); // up to 1M tokens per ETH
    uint  constant internal MAX_DECIMALS = 18;
    uint  constant internal ETH_DECIMALS = 18;
    mapping(address=>uint) internal decimals;

    function setDecimals(ERC20 token) internal {
        if (token == ETH_TOKEN_ADDRESS) decimals[token] = ETH_DECIMALS;
        else decimals[token] = token.decimals();
    }

    function getDecimals(ERC20 token) internal view returns(uint) {
        if (token == ETH_TOKEN_ADDRESS) return ETH_DECIMALS; // save storage access
        uint tokenDecimals = decimals[token];
        // technically, there might be token with decimals 0
        // moreover, very possible that old tokens have decimals 0
        // these tokens will just have higher gas fees.
        if(tokenDecimals == 0) return token.decimals();

        return tokenDecimals;
    }

    function calcDstQty(uint srcQty, uint srcDecimals, uint dstDecimals, uint rate) internal pure returns(uint) {
        require(srcQty <= MAX_QTY);
        require(rate <= MAX_RATE);

        if (dstDecimals >= srcDecimals) {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS);
            return (srcQty * rate * (10**(dstDecimals - srcDecimals))) / PRECISION;
        } else {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS);
            return (srcQty * rate) / (PRECISION * (10**(srcDecimals - dstDecimals)));
        }
    }

    function calcSrcQty(uint dstQty, uint srcDecimals, uint dstDecimals, uint rate) internal pure returns(uint) {
        require(dstQty <= MAX_QTY);
        require(rate <= MAX_RATE);
        
        //source quantity is rounded up. to avoid dest quantity being too low.
        uint numerator;
        uint denominator;
        if (srcDecimals >= dstDecimals) {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS);
            numerator = (PRECISION * dstQty * (10**(srcDecimals - dstDecimals)));
            denominator = rate;
        } else {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS);
            numerator = (PRECISION * dstQty);
            denominator = (rate * (10**(dstDecimals - srcDecimals)));
        }
        return (numerator + denominator - 1) / denominator; //avoid rounding down errors
    }
}

// File: contracts/PermissionGroups.sol

contract PermissionGroups {

    address public admin;
    address public pendingAdmin;
    mapping(address=>bool) internal operators;
    mapping(address=>bool) internal alerters;
    address[] internal operatorsGroup;
    address[] internal alertersGroup;
    uint constant internal MAX_GROUP_SIZE = 50;

    function PermissionGroups() public {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    modifier onlyOperator() {
        require(operators[msg.sender]);
        _;
    }

    modifier onlyAlerter() {
        require(alerters[msg.sender]);
        _;
    }

    function getOperators () external view returns(address[]) {
        return operatorsGroup;
    }

    function getAlerters () external view returns(address[]) {
        return alertersGroup;
    }

    event TransferAdminPending(address pendingAdmin);

    /**
     * @dev Allows the current admin to set the pendingAdmin address.
     * @param newAdmin The address to transfer ownership to.
     */
    function transferAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0));
        TransferAdminPending(pendingAdmin);
        pendingAdmin = newAdmin;
    }

    /**
     * @dev Allows the current admin to set the admin in one tx. Useful initial deployment.
     * @param newAdmin The address to transfer ownership to.
     */
    function transferAdminQuickly(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0));
        TransferAdminPending(newAdmin);
        AdminClaimed(newAdmin, admin);
        admin = newAdmin;
    }

    event AdminClaimed( address newAdmin, address previousAdmin);

    /**
     * @dev Allows the pendingAdmin address to finalize the change admin process.
     */
    function claimAdmin() public {
        require(pendingAdmin == msg.sender);
        AdminClaimed(pendingAdmin, admin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    event AlerterAdded (address newAlerter, bool isAdd);

    function addAlerter(address newAlerter) public onlyAdmin {
        require(!alerters[newAlerter]); // prevent duplicates.
        require(alertersGroup.length < MAX_GROUP_SIZE);

        AlerterAdded(newAlerter, true);
        alerters[newAlerter] = true;
        alertersGroup.push(newAlerter);
    }

    function removeAlerter (address alerter) public onlyAdmin {
        require(alerters[alerter]);
        alerters[alerter] = false;

        for (uint i = 0; i < alertersGroup.length; ++i) {
            if (alertersGroup[i] == alerter) {
                alertersGroup[i] = alertersGroup[alertersGroup.length - 1];
                alertersGroup.length--;
                AlerterAdded(alerter, false);
                break;
            }
        }
    }

    event OperatorAdded(address newOperator, bool isAdd);

    function addOperator(address newOperator) public onlyAdmin {
        require(!operators[newOperator]); // prevent duplicates.
        require(operatorsGroup.length < MAX_GROUP_SIZE);

        OperatorAdded(newOperator, true);
        operators[newOperator] = true;
        operatorsGroup.push(newOperator);
    }

    function removeOperator (address operator) public onlyAdmin {
        require(operators[operator]);
        operators[operator] = false;

        for (uint i = 0; i < operatorsGroup.length; ++i) {
            if (operatorsGroup[i] == operator) {
                operatorsGroup[i] = operatorsGroup[operatorsGroup.length - 1];
                operatorsGroup.length -= 1;
                OperatorAdded(operator, false);
                break;
            }
        }
    }
}

// File: contracts/Withdrawable.sol

/**
 * @title Contracts that should be able to recover tokens or ethers
 * @author Ilan Doron
 * @dev This allows to recover any tokens or Ethers received in a contract.
 * This will prevent any accidental loss of tokens.
 */
contract Withdrawable is PermissionGroups {

    event TokenWithdraw(ERC20 token, uint amount, address sendTo);

    /**
     * @dev Withdraw all ERC20 compatible tokens
     * @param token ERC20 The address of the token contract
     */
    function withdrawToken(ERC20 token, uint amount, address sendTo) external onlyAdmin {
        require(token.transfer(sendTo, amount));
        TokenWithdraw(token, amount, sendTo);
    }

    event EtherWithdraw(uint amount, address sendTo);

    /**
     * @dev Withdraw Ethers
     */
    function withdrawEther(uint amount, address sendTo) external onlyAdmin {
        sendTo.transfer(amount);
        EtherWithdraw(amount, sendTo);
    }
}

// File: contracts/VolumeImbalanceRecorder.sol

contract VolumeImbalanceRecorder is Withdrawable {

    uint constant internal SLIDING_WINDOW_SIZE = 5;
    uint constant internal POW_2_64 = 2 ** 64;

    struct TokenControlInfo {
        uint minimalRecordResolution; // can be roughly 1 cent
        uint maxPerBlockImbalance; // in twei resolution
        uint maxTotalImbalance; // max total imbalance (between rate updates)
                            // before halting trade
    }

    mapping(address => TokenControlInfo) internal tokenControlInfo;

    struct TokenImbalanceData {
        int  lastBlockBuyUnitsImbalance;
        uint lastBlock;

        int  totalBuyUnitsImbalance;
        uint lastRateUpdateBlock;
    }

    mapping(address => mapping(uint=>uint)) public tokenImbalanceData;

    function VolumeImbalanceRecorder(address _admin) public {
        require(_admin != address(0));
        admin = _admin;
    }

    function setTokenControlInfo(
        ERC20 token,
        uint minimalRecordResolution,
        uint maxPerBlockImbalance,
        uint maxTotalImbalance
    )
        public
        onlyAdmin
    {
        tokenControlInfo[token] =
            TokenControlInfo(
                minimalRecordResolution,
                maxPerBlockImbalance,
                maxTotalImbalance
            );
    }

    function getTokenControlInfo(ERC20 token) public view returns(uint, uint, uint) {
        return (tokenControlInfo[token].minimalRecordResolution,
                tokenControlInfo[token].maxPerBlockImbalance,
                tokenControlInfo[token].maxTotalImbalance);
    }

    function addImbalance(
        ERC20 token,
        int buyAmount,
        uint rateUpdateBlock,
        uint currentBlock
    )
        internal
    {
        uint currentBlockIndex = currentBlock % SLIDING_WINDOW_SIZE;
        int recordedBuyAmount = int(buyAmount / int(tokenControlInfo[token].minimalRecordResolution));

        int prevImbalance = 0;

        TokenImbalanceData memory currentBlockData =
            decodeTokenImbalanceData(tokenImbalanceData[token][currentBlockIndex]);

        // first scenario - this is not the first tx in the current block
        if (currentBlockData.lastBlock == currentBlock) {
            if (uint(currentBlockData.lastRateUpdateBlock) == rateUpdateBlock) {
                // just increase imbalance
                currentBlockData.lastBlockBuyUnitsImbalance += recordedBuyAmount;
                currentBlockData.totalBuyUnitsImbalance += recordedBuyAmount;
            } else {
                // imbalance was changed in the middle of the block
                prevImbalance = getImbalanceInRange(token, rateUpdateBlock, currentBlock);
                currentBlockData.totalBuyUnitsImbalance = int(prevImbalance) + recordedBuyAmount;
                currentBlockData.lastBlockBuyUnitsImbalance += recordedBuyAmount;
                currentBlockData.lastRateUpdateBlock = uint(rateUpdateBlock);
            }
        } else {
            // first tx in the current block
            int currentBlockImbalance;
            (prevImbalance, currentBlockImbalance) = getImbalanceSinceRateUpdate(token, rateUpdateBlock, currentBlock);

            currentBlockData.lastBlockBuyUnitsImbalance = recordedBuyAmount;
            currentBlockData.lastBlock = uint(currentBlock);
            currentBlockData.lastRateUpdateBlock = uint(rateUpdateBlock);
            currentBlockData.totalBuyUnitsImbalance = int(prevImbalance) + recordedBuyAmount;
        }

        tokenImbalanceData[token][currentBlockIndex] = encodeTokenImbalanceData(currentBlockData);
    }

    function setGarbageToVolumeRecorder(ERC20 token) internal {
        for (uint i = 0; i < SLIDING_WINDOW_SIZE; i++) {
            tokenImbalanceData[token][i] = 0x1;
        }
    }

    function getImbalanceInRange(ERC20 token, uint startBlock, uint endBlock) internal view returns(int buyImbalance) {
        // check the imbalance in the sliding window
        require(startBlock <= endBlock);

        buyImbalance = 0;

        for (uint windowInd = 0; windowInd < SLIDING_WINDOW_SIZE; windowInd++) {
            TokenImbalanceData memory perBlockData = decodeTokenImbalanceData(tokenImbalanceData[token][windowInd]);

            if (perBlockData.lastBlock <= endBlock && perBlockData.lastBlock >= startBlock) {
                buyImbalance += int(perBlockData.lastBlockBuyUnitsImbalance);
            }
        }
    }

    function getImbalanceSinceRateUpdate(ERC20 token, uint rateUpdateBlock, uint currentBlock)
        internal view
        returns(int buyImbalance, int currentBlockImbalance)
    {
        buyImbalance = 0;
        currentBlockImbalance = 0;
        uint latestBlock = 0;
        int imbalanceInRange = 0;
        uint startBlock = rateUpdateBlock;
        uint endBlock = currentBlock;

        for (uint windowInd = 0; windowInd < SLIDING_WINDOW_SIZE; windowInd++) {
            TokenImbalanceData memory perBlockData = decodeTokenImbalanceData(tokenImbalanceData[token][windowInd]);

            if (perBlockData.lastBlock <= endBlock && perBlockData.lastBlock >= startBlock) {
                imbalanceInRange += perBlockData.lastBlockBuyUnitsImbalance;
            }

            if (perBlockData.lastRateUpdateBlock != rateUpdateBlock) continue;
            if (perBlockData.lastBlock < latestBlock) continue;

            latestBlock = perBlockData.lastBlock;
            buyImbalance = perBlockData.totalBuyUnitsImbalance;
            if (uint(perBlockData.lastBlock) == currentBlock) {
                currentBlockImbalance = perBlockData.lastBlockBuyUnitsImbalance;
            }
        }

        if (buyImbalance == 0) {
            buyImbalance = imbalanceInRange;
        }
    }

    function getImbalance(ERC20 token, uint rateUpdateBlock, uint currentBlock)
        internal view
        returns(int totalImbalance, int currentBlockImbalance)
    {

        int resolution = int(tokenControlInfo[token].minimalRecordResolution);

        (totalImbalance, currentBlockImbalance) =
            getImbalanceSinceRateUpdate(
                token,
                rateUpdateBlock,
                currentBlock);

        totalImbalance *= resolution;
        currentBlockImbalance *= resolution;
    }

    function getMaxPerBlockImbalance(ERC20 token) internal view returns(uint) {
        return tokenControlInfo[token].maxPerBlockImbalance;
    }

    function getMaxTotalImbalance(ERC20 token) internal view returns(uint) {
        return tokenControlInfo[token].maxTotalImbalance;
    }

    function encodeTokenImbalanceData(TokenImbalanceData data) internal pure returns(uint) {
        // check for overflows
        require(data.lastBlockBuyUnitsImbalance < int(POW_2_64 / 2));
        require(data.lastBlockBuyUnitsImbalance > int(-1 * int(POW_2_64) / 2));
        require(data.lastBlock < POW_2_64);
        require(data.totalBuyUnitsImbalance < int(POW_2_64 / 2));
        require(data.totalBuyUnitsImbalance > int(-1 * int(POW_2_64) / 2));
        require(data.lastRateUpdateBlock < POW_2_64);

        // do encoding
        uint result = uint(data.lastBlockBuyUnitsImbalance) & (POW_2_64 - 1);
        result |= data.lastBlock * POW_2_64;
        result |= (uint(data.totalBuyUnitsImbalance) & (POW_2_64 - 1)) * POW_2_64 * POW_2_64;
        result |= data.lastRateUpdateBlock * POW_2_64 * POW_2_64 * POW_2_64;

        return result;
    }

    function decodeTokenImbalanceData(uint input) internal pure returns(TokenImbalanceData) {
        TokenImbalanceData memory data;

        data.lastBlockBuyUnitsImbalance = int(int64(input & (POW_2_64 - 1)));
        data.lastBlock = uint(uint64((input / POW_2_64) & (POW_2_64 - 1)));
        data.totalBuyUnitsImbalance = int(int64((input / (POW_2_64 * POW_2_64)) & (POW_2_64 - 1)));
        data.lastRateUpdateBlock = uint(uint64((input / (POW_2_64 * POW_2_64 * POW_2_64))));

        return data;
    }
}

// File: contracts/ConversionRates.sol

contract ConversionRates is ConversionRatesInterface, VolumeImbalanceRecorder, Utils {

    // bps - basic rate steps. one step is 1 / 10000 of the rate.
    struct StepFunction {
        int[] x; // quantity for each step. Quantity of each step includes previous steps.
        int[] y; // rate change per quantity step  in bps.
    }

    struct TokenData {
        bool listed;  // was added to reserve
        bool enabled; // whether trade is enabled

        // position in the compact data
        uint compactDataArrayIndex;
        uint compactDataFieldIndex;

        // rate data. base and changes according to quantity and reserve balance.
        // generally speaking. Sell rate is 1 / buy rate i.e. the buy in the other direction.
        uint baseBuyRate;  // in PRECISION units. see KyberConstants
        uint baseSellRate; // PRECISION units. without (sell / buy) spread it is 1 / baseBuyRate
        StepFunction buyRateQtyStepFunction; // in bps. higher quantity - bigger the rate.
        StepFunction sellRateQtyStepFunction;// in bps. higher the qua
        StepFunction buyRateImbalanceStepFunction; // in BPS. higher reserve imbalance - bigger the rate.
        StepFunction sellRateImbalanceStepFunction;
    }

    /*
    this is the data for tokenRatesCompactData
    but solidity compiler optimizer is sub-optimal, and cannot write this structure in a single storage write
    so we represent it as bytes32 and do the byte tricks ourselves.
    struct TokenRatesCompactData {
        bytes14 buy;  // change buy rate of token from baseBuyRate in 10 bps
        bytes14 sell; // change sell rate of token from baseSellRate in 10 bps

        uint32 blockNumber;
    } */
    uint public validRateDurationInBlocks = 10; // rates are valid for this amount of blocks
    ERC20[] internal listedTokens;
    mapping(address=>TokenData) internal tokenData;
    bytes32[] internal tokenRatesCompactData;
    uint public numTokensInCurrentCompactData = 0;
    address public reserveContract;
    uint constant internal NUM_TOKENS_IN_COMPACT_DATA = 14;
    uint constant internal BYTES_14_OFFSET = (2 ** (8 * NUM_TOKENS_IN_COMPACT_DATA));
    uint constant internal MAX_STEPS_IN_FUNCTION = 10;
    int  constant internal MAX_BPS_ADJUSTMENT = 10 ** 11; // 1B %
    int  constant internal MIN_BPS_ADJUSTMENT = -100 * 100; // cannot go down by more than 100%

    function ConversionRates(address _admin) public VolumeImbalanceRecorder(_admin)
        { } // solhint-disable-line no-empty-blocks

    function addToken(ERC20 token) public onlyAdmin {

        require(!tokenData[token].listed);
        tokenData[token].listed = true;
        listedTokens.push(token);

        if (numTokensInCurrentCompactData == 0) {
            tokenRatesCompactData.length++; // add new structure
        }

        tokenData[token].compactDataArrayIndex = tokenRatesCompactData.length - 1;
        tokenData[token].compactDataFieldIndex = numTokensInCurrentCompactData;

        numTokensInCurrentCompactData = (numTokensInCurrentCompactData + 1) % NUM_TOKENS_IN_COMPACT_DATA;

        setGarbageToVolumeRecorder(token);

        setDecimals(token);
    }

    function setCompactData(bytes14[] buy, bytes14[] sell, uint blockNumber, uint[] indices) public onlyOperator {

        require(buy.length == sell.length);
        require(indices.length == buy.length);
        require(blockNumber <= 0xFFFFFFFF);

        uint bytes14Offset = BYTES_14_OFFSET;

        for (uint i = 0; i < indices.length; i++) {
            require(indices[i] < tokenRatesCompactData.length);
            uint data = uint(buy[i]) | uint(sell[i]) * bytes14Offset | (blockNumber * (bytes14Offset * bytes14Offset));
            tokenRatesCompactData[indices[i]] = bytes32(data);
        }
    }

    function setBaseRate(
        ERC20[] tokens,
        uint[] baseBuy,
        uint[] baseSell,
        bytes14[] buy,
        bytes14[] sell,
        uint blockNumber,
        uint[] indices
    )
        public
        onlyOperator
    {
        require(tokens.length == baseBuy.length);
        require(tokens.length == baseSell.length);
        require(sell.length == buy.length);
        require(sell.length == indices.length);

        for (uint ind = 0; ind < tokens.length; ind++) {
            require(tokenData[tokens[ind]].listed);
            tokenData[tokens[ind]].baseBuyRate = baseBuy[ind];
            tokenData[tokens[ind]].baseSellRate = baseSell[ind];
        }

        setCompactData(buy, sell, blockNumber, indices);
    }

    function setQtyStepFunction(
        ERC20 token,
        int[] xBuy,
        int[] yBuy,
        int[] xSell,
        int[] ySell
    )
        public
        onlyOperator
    {
        require(xBuy.length == yBuy.length);
        require(xSell.length == ySell.length);
        require(xBuy.length <= MAX_STEPS_IN_FUNCTION);
        require(xSell.length <= MAX_STEPS_IN_FUNCTION);
        require(tokenData[token].listed);

        tokenData[token].buyRateQtyStepFunction = StepFunction(xBuy, yBuy);
        tokenData[token].sellRateQtyStepFunction = StepFunction(xSell, ySell);
    }

    function setImbalanceStepFunction(
        ERC20 token,
        int[] xBuy,
        int[] yBuy,
        int[] xSell,
        int[] ySell
    )
        public
        onlyOperator
    {
        require(xBuy.length == yBuy.length);
        require(xSell.length == ySell.length);
        require(xBuy.length <= MAX_STEPS_IN_FUNCTION);
        require(xSell.length <= MAX_STEPS_IN_FUNCTION);
        require(tokenData[token].listed);

        tokenData[token].buyRateImbalanceStepFunction = StepFunction(xBuy, yBuy);
        tokenData[token].sellRateImbalanceStepFunction = StepFunction(xSell, ySell);
    }

    function setValidRateDurationInBlocks(uint duration) public onlyAdmin {
        validRateDurationInBlocks = duration;
    }

    function enableTokenTrade(ERC20 token) public onlyAdmin {
        require(tokenData[token].listed);
        require(tokenControlInfo[token].minimalRecordResolution != 0);
        tokenData[token].enabled = true;
    }

    function disableTokenTrade(ERC20 token) public onlyAlerter {
        require(tokenData[token].listed);
        tokenData[token].enabled = false;
    }

    function setReserveAddress(address reserve) public onlyAdmin {
        reserveContract = reserve;
    }

    function recordImbalance(
        ERC20 token,
        int buyAmount,
        uint rateUpdateBlock,
        uint currentBlock
    )
        public
    {
        require(msg.sender == reserveContract);

        if (rateUpdateBlock == 0) rateUpdateBlock = getRateUpdateBlock(token);

        return addImbalance(token, buyAmount, rateUpdateBlock, currentBlock);
    }

    /* solhint-disable function-max-lines */
    function getRate(ERC20 token, uint currentBlockNumber, bool buy, uint qty) public view returns(uint) {
        // check if trade is enabled
        if (!tokenData[token].enabled) return 0;
        if (tokenControlInfo[token].minimalRecordResolution == 0) return 0; // token control info not set

        // get rate update block
        bytes32 compactData = tokenRatesCompactData[tokenData[token].compactDataArrayIndex];

        uint updateRateBlock = getLast4Bytes(compactData);
        if (currentBlockNumber >= updateRateBlock + validRateDurationInBlocks) return 0; // rate is expired
        // check imbalance
        int totalImbalance;
        int blockImbalance;
        (totalImbalance, blockImbalance) = getImbalance(token, updateRateBlock, currentBlockNumber);

        // calculate actual rate
        int imbalanceQty;
        int extraBps;
        int8 rateUpdate;
        uint rate;

        if (buy) {
            // start with base rate
            rate = tokenData[token].baseBuyRate;

            // add rate update
            rateUpdate = getRateByteFromCompactData(compactData, token, true);
            extraBps = int(rateUpdate) * 10;
            rate = addBps(rate, extraBps);

            // compute token qty
            qty = getTokenQty(token, rate, qty);
            imbalanceQty = int(qty);
            totalImbalance += imbalanceQty;

            // add qty overhead
            extraBps = executeStepFunction(tokenData[token].buyRateQtyStepFunction, int(qty));
            rate = addBps(rate, extraBps);

            // add imbalance overhead
            extraBps = executeStepFunction(tokenData[token].buyRateImbalanceStepFunction, totalImbalance);
            rate = addBps(rate, extraBps);
        } else {
            // start with base rate
            rate = tokenData[token].baseSellRate;

            // add rate update
            rateUpdate = getRateByteFromCompactData(compactData, token, false);
            extraBps = int(rateUpdate) * 10;
            rate = addBps(rate, extraBps);

            // compute token qty
            imbalanceQty = -1 * int(qty);
            totalImbalance += imbalanceQty;

            // add qty overhead
            extraBps = executeStepFunction(tokenData[token].sellRateQtyStepFunction, int(qty));
            rate = addBps(rate, extraBps);

            // add imbalance overhead
            extraBps = executeStepFunction(tokenData[token].sellRateImbalanceStepFunction, totalImbalance);
            rate = addBps(rate, extraBps);
        }

        if (abs(totalImbalance) >= getMaxTotalImbalance(token)) return 0;
        if (abs(blockImbalance + imbalanceQty) >= getMaxPerBlockImbalance(token)) return 0;

        return rate;
    }
    /* solhint-enable function-max-lines */

    function getBasicRate(ERC20 token, bool buy) public view returns(uint) {
        if (buy)
            return tokenData[token].baseBuyRate;
        else
            return tokenData[token].baseSellRate;
    }

    function getCompactData(ERC20 token) public view returns(uint, uint, byte, byte) {
        require(tokenData[token].listed);

        uint arrayIndex = tokenData[token].compactDataArrayIndex;
        uint fieldOffset = tokenData[token].compactDataFieldIndex;

        return (
            arrayIndex,
            fieldOffset,
            byte(getRateByteFromCompactData(tokenRatesCompactData[arrayIndex], token, true)),
            byte(getRateByteFromCompactData(tokenRatesCompactData[arrayIndex], token, false))
        );
    }

    function getTokenBasicData(ERC20 token) public view returns(bool, bool) {
        return (tokenData[token].listed, tokenData[token].enabled);
    }

    /* solhint-disable code-complexity */
    function getStepFunctionData(ERC20 token, uint command, uint param) public view returns(int) {
        if (command == 0) return int(tokenData[token].buyRateQtyStepFunction.x.length);
        if (command == 1) return tokenData[token].buyRateQtyStepFunction.x[param];
        if (command == 2) return int(tokenData[token].buyRateQtyStepFunction.y.length);
        if (command == 3) return tokenData[token].buyRateQtyStepFunction.y[param];

        if (command == 4) return int(tokenData[token].sellRateQtyStepFunction.x.length);
        if (command == 5) return tokenData[token].sellRateQtyStepFunction.x[param];
        if (command == 6) return int(tokenData[token].sellRateQtyStepFunction.y.length);
        if (command == 7) return tokenData[token].sellRateQtyStepFunction.y[param];

        if (command == 8) return int(tokenData[token].buyRateImbalanceStepFunction.x.length);
        if (command == 9) return tokenData[token].buyRateImbalanceStepFunction.x[param];
        if (command == 10) return int(tokenData[token].buyRateImbalanceStepFunction.y.length);
        if (command == 11) return tokenData[token].buyRateImbalanceStepFunction.y[param];

        if (command == 12) return int(tokenData[token].sellRateImbalanceStepFunction.x.length);
        if (command == 13) return tokenData[token].sellRateImbalanceStepFunction.x[param];
        if (command == 14) return int(tokenData[token].sellRateImbalanceStepFunction.y.length);
        if (command == 15) return tokenData[token].sellRateImbalanceStepFunction.y[param];

        revert();
    }
    /* solhint-enable code-complexity */

    function getRateUpdateBlock(ERC20 token) public view returns(uint) {
        bytes32 compactData = tokenRatesCompactData[tokenData[token].compactDataArrayIndex];
        return getLast4Bytes(compactData);
    }

    function getListedTokens() public view returns(ERC20[]) {
        return listedTokens;
    }

    function getTokenQty(ERC20 token, uint ethQty, uint rate) internal view returns(uint) {
        uint dstDecimals = getDecimals(token);
        uint srcDecimals = ETH_DECIMALS;

        return calcDstQty(ethQty, srcDecimals, dstDecimals, rate);
    }

    function getLast4Bytes(bytes32 b) internal pure returns(uint) {
        // cannot trust compiler with not turning bit operations into EXP opcode
        return uint(b) / (BYTES_14_OFFSET * BYTES_14_OFFSET);
    }

    function getRateByteFromCompactData(bytes32 data, ERC20 token, bool buy) internal view returns(int8) {
        uint fieldOffset = tokenData[token].compactDataFieldIndex;
        uint byteOffset;
        if (buy)
            byteOffset = 32 - NUM_TOKENS_IN_COMPACT_DATA + fieldOffset;
        else
            byteOffset = 4 + fieldOffset;

        return int8(data[byteOffset]);
    }

    function executeStepFunction(StepFunction f, int x) internal pure returns(int) {
        uint len = f.y.length;
        for (uint ind = 0; ind < len; ind++) {
            if (x <= f.x[ind]) return f.y[ind];
        }

        return f.y[len-1];
    }

    function addBps(uint rate, int bps) internal pure returns(uint) {
        require(rate <= MAX_RATE);
        require(bps >= MIN_BPS_ADJUSTMENT);
        require(bps <= MAX_BPS_ADJUSTMENT);

        uint maxBps = 100 * 100;
        return (rate * uint(int(maxBps) + bps)) / maxBps;
    }

    function abs(int x) internal pure returns(uint) {
        if (x < 0)
            return uint(-1 * x);
        else
            return uint(x);
    }
}

// File: contracts/ExpectedRateInterface.sol

interface ExpectedRateInterface {
    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) public view
        returns (uint expectedRate, uint slippageRate);
}

// File: contracts/FeeBurnerInterface.sol

interface FeeBurnerInterface {
    function handleFees (uint tradeWeiAmount, address reserve, address wallet) public returns(bool);
}

// File: contracts/KyberReserveInterface.sol

/// @title Kyber Reserve contract
interface KyberReserveInterface {

    function trade(
        ERC20 srcToken,
        uint srcAmount,
        ERC20 destToken,
        address destAddress,
        uint conversionRate,
        bool validate
    )
        public
        payable
        returns(bool);

    function getConversionRate(ERC20 src, ERC20 dest, uint srcQty, uint blockNumber) public view returns(uint);
}

// File: contracts/WhiteListInterface.sol

contract WhiteListInterface {
    function getUserCapInWei(address user) external view returns (uint userCapWei);
}

// File: contracts/KyberNetwork.sol

////////////////////////////////////////////////////////////////////////////////////////////////////////
/// @title Kyber Network main contract
contract KyberNetwork is Withdrawable, Utils {

    uint public negligibleRateDiff = 10; // basic rate steps will be in 0.01%
    KyberReserveInterface[] public reserves;
    mapping(address=>bool) public isReserve;
    WhiteListInterface public whiteListContract;
    ExpectedRateInterface public expectedRateContract;
    FeeBurnerInterface    public feeBurnerContract;
    uint                  public maxGasPrice = 50 * 1000 * 1000 * 1000; // 50 gwei
    bool                  public enabled = false; // network is enabled
    mapping(bytes32=>uint) public info; // this is only a UI field for external app.
    mapping(address=>mapping(bytes32=>bool)) public perReserveListedPairs;

    function KyberNetwork(address _admin) public {
        require(_admin != address(0));
        admin = _admin;
    }

    event EtherReceival(address indexed sender, uint amount);

    /* solhint-disable no-complex-fallback */
    function() public payable {
        require(isReserve[msg.sender]);
        EtherReceival(msg.sender, msg.value);
    }
    /* solhint-enable no-complex-fallback */

    event ExecuteTrade(address indexed sender, ERC20 src, ERC20 dest, uint actualSrcAmount, uint actualDestAmount);

    /// @notice use token address ETH_TOKEN_ADDRESS for ether
    /// @dev makes a trade between src and dest token and send dest token to destAddress
    /// @param src Src token
    /// @param srcAmount amount of src tokens
    /// @param dest   Destination token
    /// @param destAddress Address to send tokens to
    /// @param maxDestAmount A limit on the amount of dest tokens
    /// @param minConversionRate The minimal conversion rate. If actual rate is lower, trade is canceled.
    /// @param walletId is the wallet ID to send part of the fees
    /// @return amount of actual dest tokens
    function trade(
        ERC20 src,
        uint srcAmount,
        ERC20 dest,
        address destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        address walletId
    )
        public
        payable
        returns(uint)
    {
        require(enabled);

        uint userSrcBalanceBefore;
        uint userSrcBalanceAfter;
        uint userDestBalanceBefore;
        uint userDestBalanceAfter;

        userSrcBalanceBefore = getBalance(src, msg.sender);
        if (src == ETH_TOKEN_ADDRESS)
            userSrcBalanceBefore += msg.value;
        userDestBalanceBefore = getBalance(dest, destAddress);

        uint actualDestAmount = doTrade(src,
                                        srcAmount,
                                        dest,
                                        destAddress,
                                        maxDestAmount,
                                        minConversionRate,
                                        walletId
                                        );
        require(actualDestAmount > 0);

        userSrcBalanceAfter = getBalance(src, msg.sender);
        userDestBalanceAfter = getBalance(dest, destAddress);

        require(userSrcBalanceAfter <= userSrcBalanceBefore);
        require(userDestBalanceAfter >= userDestBalanceBefore);

        require((userDestBalanceAfter - userDestBalanceBefore) >=
            calcDstQty((userSrcBalanceBefore - userSrcBalanceAfter), getDecimals(src), getDecimals(dest),
                minConversionRate));

        return actualDestAmount;
    }

    event AddReserveToNetwork(KyberReserveInterface reserve, bool add);

    /// @notice can be called only by admin
    /// @dev add or deletes a reserve to/from the network.
    /// @param reserve The reserve address.
    /// @param add If true, the add reserve. Otherwise delete reserve.
    function addReserve(KyberReserveInterface reserve, bool add) public onlyAdmin {

        if (add) {
            require(!isReserve[reserve]);
            reserves.push(reserve);
            isReserve[reserve] = true;
            AddReserveToNetwork(reserve, true);
        } else {
            isReserve[reserve] = false;
            // will have trouble if more than 50k reserves...
            for (uint i = 0; i < reserves.length; i++) {
                if (reserves[i] == reserve) {
                    reserves[i] = reserves[reserves.length - 1];
                    reserves.length--;
                    AddReserveToNetwork(reserve, false);
                    break;
                }
            }
        }
    }

    event ListReservePairs(address reserve, ERC20 src, ERC20 dest, bool add);

    /// @notice can be called only by admin
    /// @dev allow or prevent a specific reserve to trade a pair of tokens
    /// @param reserve The reserve address.
    /// @param src Src token
    /// @param dest Destination token
    /// @param add If true then enable trade, otherwise delist pair.
    function listPairForReserve(address reserve, ERC20 src, ERC20 dest, bool add) public onlyAdmin {
        (perReserveListedPairs[reserve])[keccak256(src, dest)] = add;

        if (src != ETH_TOKEN_ADDRESS) {
            if (add) {
                src.approve(reserve, 2**255); // approve infinity
            } else {
                src.approve(reserve, 0);
            }
        }

        setDecimals(src);
        setDecimals(dest);

        ListReservePairs(reserve, src, dest, add);
    }

    function setParams(
        WhiteListInterface    _whiteList,
        ExpectedRateInterface _expectedRate,
        FeeBurnerInterface    _feeBurner,
        uint                  _maxGasPrice,
        uint                  _negligibleRateDiff
    )
        public
        onlyAdmin
    {
        require(_whiteList != address(0));
        require(_feeBurner != address(0));
        require(_expectedRate != address(0));
        require(_negligibleRateDiff <= 100 * 100); // at most 100%
        
        whiteListContract = _whiteList;
        expectedRateContract = _expectedRate;
        feeBurnerContract = _feeBurner;
        maxGasPrice = _maxGasPrice;
        negligibleRateDiff = _negligibleRateDiff;
    }

    function setEnable(bool _enable) public onlyAdmin {
        if (_enable) {
            require(whiteListContract != address(0));
            require(feeBurnerContract != address(0));
            require(expectedRateContract != address(0));
        }
        enabled = _enable;
    }

    function setInfo(bytes32 field, uint value) public onlyOperator {
        info[field] = value;
    }

    /// @dev returns number of reserves
    /// @return number of reserves
    function getNumReserves() public view returns(uint) {
        return reserves.length;
    }

    /// @notice should be called off chain with as much gas as needed
    /// @dev get an array of all reserves
    /// @return An array of all reserves
    function getReserves() public view returns(KyberReserveInterface[]) {
        return reserves;
    }

    /// @dev get the balance of a user.
    /// @param token The token type
    /// @return The balance
    function getBalance(ERC20 token, address user) public view returns(uint) {
        if (token == ETH_TOKEN_ADDRESS)
            return user.balance;
        else
            return token.balanceOf(user);
    }

    /// @notice use token address ETH_TOKEN_ADDRESS for ether
    /// @dev best conversion rate for a pair of tokens, if number of reserves have small differences. randomize
    /// @param src Src token
    /// @param dest Destination token
    /* solhint-disable code-complexity */
    function findBestRate(ERC20 src, ERC20 dest, uint srcQty) public view returns(uint, uint) {
        uint bestRate = 0;
        uint bestReserve = 0;
        uint numRelevantReserves = 0;
        uint numReserves = reserves.length;
        uint[] memory rates = new uint[](numReserves);
        uint[] memory reserveCandidates = new uint[](numReserves);

        for (uint i = 0; i < numReserves; i++) {
            //list all reserves that have this token.
            if (!(perReserveListedPairs[reserves[i]])[keccak256(src, dest)]) continue;

            rates[i] = reserves[i].getConversionRate(src, dest, srcQty, block.number);

            if (rates[i] > bestRate) {
                //best rate is highest rate
                bestRate = rates[i];
            }
        }

        if (bestRate > 0) {
            uint random = 0;
            uint smallestRelevantRate = (bestRate * 10000) / (10000 + negligibleRateDiff);

            for (i = 0; i < numReserves; i++) {
                if (rates[i] >= smallestRelevantRate) {
                    reserveCandidates[numRelevantReserves++] = i;
                }
            }

            if (numRelevantReserves > 1) {
                //when encountering small rate diff from bestRate. draw from relevant reserves
                random = uint(block.blockhash(block.number-1)) % numRelevantReserves;
            }

            bestReserve = reserveCandidates[random];
            bestRate = rates[bestReserve];
        }

        return (bestReserve, bestRate);
    }
    /* solhint-enable code-complexity */

    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty)
        public view
        returns (uint expectedRate, uint slippageRate)
    {
        require(expectedRateContract != address(0));
        return expectedRateContract.getExpectedRate(src, dest, srcQty);
    }

    function getUserCapInWei(address user) public view returns(uint) {
        return whiteListContract.getUserCapInWei(user);
    }

    function doTrade(
        ERC20 src,
        uint srcAmount,
        ERC20 dest,
        address destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        address walletId
    )
        internal
        returns(uint)
    {
        require(tx.gasprice <= maxGasPrice);
        require(validateTradeInput(src, srcAmount, destAddress));

        uint reserveInd;
        uint rate;

        (reserveInd, rate) = findBestRate(src, dest, srcAmount);
        KyberReserveInterface theReserve = reserves[reserveInd];
        require(rate > 0);
        require(rate < MAX_RATE);
        require(rate >= minConversionRate);

        uint actualSrcAmount = srcAmount;
        uint actualDestAmount = calcDestAmount(src, dest, actualSrcAmount, rate);
        if (actualDestAmount > maxDestAmount) {
            actualDestAmount = maxDestAmount;
            actualSrcAmount = calcSrcAmount(src, dest, actualDestAmount, rate);
            require(actualSrcAmount <= srcAmount);
        }

        // do the trade
        // verify trade size is smaller than user cap
        uint ethAmount;
        if (src == ETH_TOKEN_ADDRESS) {
            ethAmount = actualSrcAmount;
        } else {
            ethAmount = actualDestAmount;
        }

        require(ethAmount <= getUserCapInWei(msg.sender));
        require(doReserveTrade(
                src,
                actualSrcAmount,
                dest,
                destAddress,
                actualDestAmount,
                theReserve,
                rate,
                true));

        if ((actualSrcAmount < srcAmount) && (src == ETH_TOKEN_ADDRESS)) {
            msg.sender.transfer(srcAmount - actualSrcAmount);
        }

        require(feeBurnerContract.handleFees(ethAmount, theReserve, walletId));

        ExecuteTrade(msg.sender, src, dest, actualSrcAmount, actualDestAmount);
        return actualDestAmount;
    }

    /// @notice use token address ETH_TOKEN_ADDRESS for ether
    /// @dev do one trade with a reserve
    /// @param src Src token
    /// @param amount amount of src tokens
    /// @param dest   Destination token
    /// @param destAddress Address to send tokens to
    /// @param reserve Reserve to use
    /// @param validate If true, additional validations are applicable
    /// @return true if trade is successful
    function doReserveTrade(
        ERC20 src,
        uint amount,
        ERC20 dest,
        address destAddress,
        uint expectedDestAmount,
        KyberReserveInterface reserve,
        uint conversionRate,
        bool validate
    )
        internal
        returns(bool)
    {
        uint callValue = 0;

        if (src == ETH_TOKEN_ADDRESS) {
            callValue = amount;
        } else {
            // take src tokens to this contract
            src.transferFrom(msg.sender, this, amount);
        }

        // reserve sends tokens/eth to network. network sends it to destination
        require(reserve.trade.value(callValue)(src, amount, dest, this, conversionRate, validate));

        if (dest == ETH_TOKEN_ADDRESS) {
            destAddress.transfer(expectedDestAmount);
        } else {
            require(dest.transfer(destAddress, expectedDestAmount));
        }

        return true;
    }

    function calcDestAmount(ERC20 src, ERC20 dest, uint srcAmount, uint rate) internal view returns(uint) {
        return calcDstQty(srcAmount, getDecimals(src), getDecimals(dest), rate);
    }

    function calcSrcAmount(ERC20 src, ERC20 dest, uint destAmount, uint rate) internal view returns(uint) {
        return calcSrcQty(destAmount, getDecimals(src), getDecimals(dest), rate);
    }

    /// @notice use token address ETH_TOKEN_ADDRESS for ether
    /// @dev checks that user sent ether/tokens to contract before trade
    /// @param src Src token
    /// @param srcAmount amount of src tokens
    /// @return true if input is valid
    function validateTradeInput(ERC20 src, uint srcAmount, address destAddress) internal view returns(bool) {
        if ((srcAmount >= MAX_QTY) || (srcAmount == 0) || (destAddress == 0))
            return false;

        if (src == ETH_TOKEN_ADDRESS) {
            if (msg.value != srcAmount)
                return false;
        } else {
            if ((msg.value != 0) || (src.allowance(msg.sender, this) < srcAmount))
                return false;
        }

        return true;
    }
}

// File: contracts/SanityRatesInterface.sol

interface SanityRatesInterface {
    function getSanityRate(ERC20 src, ERC20 dest) public view returns(uint);
}

// File: contracts/KyberReserve.sol

/// @title Kyber Reserve contract
contract KyberReserve is KyberReserveInterface, Withdrawable, Utils {

    address public kyberNetwork;
    bool public tradeEnabled;
    ConversionRatesInterface public conversionRatesContract;
    SanityRatesInterface public sanityRatesContract;
    mapping(bytes32=>bool) public approvedWithdrawAddresses; // sha3(token,address)=>bool

    function KyberReserve(address _kyberNetwork, ConversionRatesInterface _ratesContract, address _admin) public {
        require(_admin != address(0));
        require(_ratesContract != address(0));
        require(_kyberNetwork != address(0));
        kyberNetwork = _kyberNetwork;
        conversionRatesContract = _ratesContract;
        admin = _admin;
        tradeEnabled = true;
    }

    event DepositToken(ERC20 token, uint amount);

    function() public payable {
        DepositToken(ETH_TOKEN_ADDRESS, msg.value);
    }

    event TradeExecute(
        address indexed origin,
        address src,
        uint srcAmount,
        address destToken,
        uint destAmount,
        address destAddress
    );

    function trade(
        ERC20 srcToken,
        uint srcAmount,
        ERC20 destToken,
        address destAddress,
        uint conversionRate,
        bool validate
    )
        public
        payable
        returns(bool)
    {
        require(tradeEnabled);
        require(msg.sender == kyberNetwork);

        require(doTrade(srcToken, srcAmount, destToken, destAddress, conversionRate, validate));

        return true;
    }

    event TradeEnabled(bool enable);

    function enableTrade() public onlyAdmin returns(bool) {
        tradeEnabled = true;
        TradeEnabled(true);

        return true;
    }

    function disableTrade() public onlyAlerter returns(bool) {
        tradeEnabled = false;
        TradeEnabled(false);

        return true;
    }

    event WithdrawAddressApproved(ERC20 token, address addr, bool approve);

    function approveWithdrawAddress(ERC20 token, address addr, bool approve) public onlyAdmin {
        approvedWithdrawAddresses[keccak256(token, addr)] = approve;
        WithdrawAddressApproved(token, addr, approve);

        setDecimals(token);
    }

    event WithdrawFunds(ERC20 token, uint amount, address destination);

    function withdraw(ERC20 token, uint amount, address destination) public onlyOperator returns(bool) {
        require(approvedWithdrawAddresses[keccak256(token, destination)]);

        if (token == ETH_TOKEN_ADDRESS) {
            destination.transfer(amount);
        } else {
            require(token.transfer(destination, amount));
        }

        WithdrawFunds(token, amount, destination);

        return true;
    }

    event SetContractAddresses(address network, address rate, address sanity);

    function setContracts(address _kyberNetwork, ConversionRatesInterface _conversionRates, SanityRatesInterface _sanityRates)
        public
        onlyAdmin
    {
        require(_kyberNetwork != address(0));
        require(_conversionRates != address(0));

        kyberNetwork = _kyberNetwork;
        conversionRatesContract = _conversionRates;
        sanityRatesContract = _sanityRates;

        SetContractAddresses(kyberNetwork, conversionRatesContract, sanityRatesContract);
    }

    ////////////////////////////////////////////////////////////////////////////
    /// status functions ///////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    function getBalance(ERC20 token) public view returns(uint) {
        if (token == ETH_TOKEN_ADDRESS)
            return this.balance;
        else
            return token.balanceOf(this);
    }

    function getDestQty(ERC20 src, ERC20 dest, uint srcQty, uint rate) public view returns(uint) {
        uint dstDecimals = getDecimals(dest);
        uint srcDecimals = getDecimals(src);

        return calcDstQty(srcQty, srcDecimals, dstDecimals, rate);
    }

    function getSrcQty(ERC20 src, ERC20 dest, uint dstQty, uint rate) public view returns(uint) {
        uint dstDecimals = getDecimals(dest);
        uint srcDecimals = getDecimals(src);

        return calcSrcQty(dstQty, srcDecimals, dstDecimals, rate);
    }

    function getConversionRate(ERC20 src, ERC20 dest, uint srcQty, uint blockNumber) public view returns(uint) {
        ERC20 token;
        bool  buy;

        if (!tradeEnabled) return 0;

        if (ETH_TOKEN_ADDRESS == src) {
            buy = true;
            token = dest;
        } else if (ETH_TOKEN_ADDRESS == dest) {
            buy = false;
            token = src;
        } else {
            return 0; // pair is not listed
        }

        uint rate = conversionRatesContract.getRate(token, blockNumber, buy, srcQty);
        uint destQty = getDestQty(src, dest, srcQty, rate);

        if (getBalance(dest) < destQty) return 0;

        if (sanityRatesContract != address(0)) {
            uint sanityRate = sanityRatesContract.getSanityRate(src, dest);
            if (rate > sanityRate) return 0;
        }

        return rate;
    }

    /// @dev do a trade
    /// @param srcToken Src token
    /// @param srcAmount Amount of src token
    /// @param destToken Destination token
    /// @param destAddress Destination address to send tokens to
    /// @param validate If true, additional validations are applicable
    /// @return true iff trade is successful
    function doTrade(
        ERC20 srcToken,
        uint srcAmount,
        ERC20 destToken,
        address destAddress,
        uint conversionRate,
        bool validate
    )
        internal
        returns(bool)
    {
        // can skip validation if done at kyber network level
        if (validate) {
            require(conversionRate > 0);
            if (srcToken == ETH_TOKEN_ADDRESS)
                require(msg.value == srcAmount);
            else
                require(msg.value == 0);
        }

        uint destAmount = getDestQty(srcToken, destToken, srcAmount, conversionRate);
        // sanity check
        require(destAmount > 0);

        // add to imbalance
        ERC20 token;
        int buy;
        if (srcToken == ETH_TOKEN_ADDRESS) {
            buy = int(destAmount);
            token = destToken;
        } else {
            buy = -1 * int(srcAmount);
            token = srcToken;
        }

        conversionRatesContract.recordImbalance(
            token,
            buy,
            0,
            block.number
        );

        // collect src tokens
        if (srcToken != ETH_TOKEN_ADDRESS) {
            require(srcToken.transferFrom(msg.sender, this, srcAmount));
        }

        // send dest tokens
        if (destToken == ETH_TOKEN_ADDRESS) {
            destAddress.transfer(destAmount);
        } else {
            require(destToken.transfer(destAddress, destAmount));
        }

        TradeExecute(msg.sender, srcToken, srcAmount, destToken, destAmount, destAddress);

        return true;
    }
}

// File: contracts/mockContracts/Wrapper.sol

contract Wrapper is Utils {

    function getBalances(address reserve, ERC20[] tokens) public view returns(uint[]) {
        uint[] memory result = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            uint balance = 0;
            if (tokens[i] == ETH_TOKEN_ADDRESS) {
                balance = reserve.balance;
            } else {
                balance = tokens[i].balanceOf(reserve);
            }

            result[i] = balance;
        }

        return result;
    }

    function getTokenAllowances(address owner, address spender, ERC20[] tokens) public view returns(uint[]) {
        uint[] memory result = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            result[i] = tokens[i].allowance(owner, spender);
        }
        return result;
    }

    function getByteFromBytes14(bytes14 x, uint byteInd) public pure returns(byte) {
        require(byteInd <= 13);
        return x[byteInd];
    }

    function getInt8FromByte(bytes14 x, uint byteInd) public pure returns(int8) {
        require(byteInd <= 13);
        return int8(x[byteInd]);
    }

    function getCompactData(ConversionRates ratesContract, ERC20 token) internal view returns(int8,int8,uint) {
        uint bulkIndex; uint index; byte buy; byte sell; uint updateBlock;
        (bulkIndex, index, buy, sell) = ratesContract.getCompactData(token);
        updateBlock = ratesContract.getRateUpdateBlock(token);

        return (int8(buy), int8(sell), updateBlock);
    }

    function getTokenRates(ConversionRates ratesContract, ERC20[] tokenList)
        public view
        returns(uint[], uint[], int8[], int8[], uint[])
    {
        uint[] memory buyBases = new uint[](tokenList.length);
        uint[] memory sellBases = new uint[](tokenList.length);
        int8[] memory compactBuy = new int8[](tokenList.length);
        int8[] memory compactSell = new int8[](tokenList.length);
        uint[] memory updateBlock = new uint[](tokenList.length);

        for (uint i = 0;  i < tokenList.length; i++) {
            buyBases[i] = ratesContract.getBasicRate(tokenList[i], true);
            sellBases[i] = ratesContract.getBasicRate(tokenList[i], false);

            (compactBuy[i], compactSell[i], updateBlock[i]) = getCompactData(ratesContract, tokenList[i]);
        }

        return (buyBases, sellBases, compactBuy, compactSell, updateBlock);
    }

    function getTokenIndicies(ConversionRates ratesContract, ERC20[] tokenList) public view returns(uint[], uint[]) {
        uint[] memory bulkIndices = new uint[](tokenList.length);
        uint[] memory tokenIndexInBulk = new uint[](tokenList.length);

        for (uint i = 0; i < tokenList.length; i++) {
            uint bulkIndex; uint index; byte buy; byte sell;
            (bulkIndex, index, buy, sell) = ratesContract.getCompactData(tokenList[i]);

            bulkIndices[i] = bulkIndex;
            tokenIndexInBulk[i] = index;
        }

        return (bulkIndices,tokenIndexInBulk);
    }


    function getExpectedRates( KyberNetwork network, ERC20[] srcs, ERC20[] dests, uint[] qty )
        public view returns(uint[], uint[])
    {
        require( srcs.length == dests.length );
        require( srcs.length == dests.length );

        uint[] memory rates = new uint[](srcs.length);
        uint[] memory slippage = new uint[](srcs.length);
        for ( uint i = 0; i < srcs.length; i++ ) {
            (rates[i],slippage[i]) = network.getExpectedRate(srcs[i],dests[i],qty[i]);
        }

        return (rates, slippage);
    }

    function getReserveRate(KyberReserve reserve, ERC20[] srcs, ERC20[] dests)
        public view returns(uint[], uint[])
    {
        require( srcs.length == dests.length );
        require( srcs.length == dests.length );

        uint[] memory rates      = new uint[](srcs.length);
        uint[] memory sanityRate = new uint[](srcs.length);

        for(uint i = 0 ; i < srcs.length ; i++) {
            if(reserve.sanityRatesContract() != address(0x0)){
                sanityRate[i] = reserve.sanityRatesContract().getSanityRate(srcs[i],
                                                                            dests[i]);
            }
            rates[i] = reserve.getConversionRate(srcs[i],
                                                 dests[i],
                                                 0,
                                                 block.number);
        }

return (rates,sanityRate);
    }
}