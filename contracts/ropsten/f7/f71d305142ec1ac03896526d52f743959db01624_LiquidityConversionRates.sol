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

// File: contracts/LiquidityFormula.sol

contract UtilMath {
    uint public constant BIG_NUMBER = (uint(1)<<uint(200));

    function checkMultOverflow(uint x, uint y) public pure returns(bool) {
        if (y == 0) return false;
        return (((x*y) / y) != x);
    }

    function compactFraction(uint p, uint q, uint precision) public pure returns (uint, uint) {
        if (q < precision * precision) return (p, q);
        return compactFraction(p/precision, q/precision, precision);
    }

    /* solhint-disable code-complexity */
    function exp(uint p, uint q, uint precision) public pure returns (uint) {
        uint n = 0;
        uint nFact = 1;
        uint currentP = 1;
        uint currentQ = 1;

        uint sum = 0;
        uint prevSum = 0;

        while (true) {
            if (checkMultOverflow(currentP, precision)) return sum;
            if (checkMultOverflow(currentQ, nFact)) return sum;

            sum += (currentP * precision) / (currentQ * nFact);

            if (sum == prevSum) return sum;
            prevSum = sum;

            n++;

            if (checkMultOverflow(currentP, p)) return sum;
            if (checkMultOverflow(currentQ, q)) return sum;
            if (checkMultOverflow(nFact, n)) return sum;

            currentP *= p;
            currentQ *= q;
            nFact *= n;

            (currentP, currentQ) = compactFraction(currentP, currentQ, precision);
        }
    }
    /* solhint-enable code-complexity */

    function countLeadingZeros(uint p, uint q) public pure returns (uint) {
        uint denomator = (uint(1)<<255);
        for (int i = 255; i >= 0; i--) {
            if ((q*denomator)/denomator != q) {
                // overflow
                denomator = denomator/2;
                continue;
            }
            if (p/(q*denomator) > 0) return uint(i);
            denomator = denomator/2;
        }

        return uint(-1);
    }

    // log2 for a number that it in [1,2)
    function log2ForSmallNumber(uint x, uint numPrecisionBits) public pure returns (uint) {
        uint res = 0;
        uint one = (uint(1)<<numPrecisionBits);
        uint two = 2 * one;
        uint addition = one;

        require((x >= one) && (x <= two));
        require(numPrecisionBits < 125);

        for (uint i = numPrecisionBits; i > 0; i--) {
            x = (x*x) / one;
            addition = addition/2;
            if (x >= two) {
                x = x/2;
                res += addition;
            }
        }

        return res;
    }

    function logBase2 (uint p, uint q, uint numPrecisionBits) public pure returns (uint) {
        uint n = 0;
        uint precision = (uint(1)<<numPrecisionBits);

        if (p > q) {
            n = countLeadingZeros(p, q);
        }

        require(!checkMultOverflow(p, precision));
        require(!checkMultOverflow(n, precision));
        require(!checkMultOverflow(uint(1)<<n, q));

        uint y = p * precision / (q * (uint(1)<<n));
        uint log2Small = log2ForSmallNumber(y, numPrecisionBits);

        require(n*precision <= BIG_NUMBER);
        require(log2Small <= BIG_NUMBER);

        return n * precision + log2Small;
    }

    function ln(uint p, uint q, uint numPrecisionBits) public pure returns (uint) {
        uint ln2Numerator   = 6931471805599453094172;
        uint ln2Denomerator = 10000000000000000000000;

        uint log2x = logBase2(p, q, numPrecisionBits);

        require(!checkMultOverflow(ln2Numerator, log2x));

        return ln2Numerator * log2x / ln2Denomerator;
    }
}


contract LiquidityFormula is UtilMath {
    function pE(uint r, uint pMIn, uint e, uint precision) public pure returns (uint) {
        uint expRE = exp(r*e, precision*precision, precision);
        require(!checkMultOverflow(expRE, pMIn));
        return pMIn*expRE / precision;
    }

    function deltaTFunc(uint r, uint pMIn, uint e, uint deltaE, uint precision) public pure returns (uint) {
        uint pe = pE(r, pMIn, e, precision);
        uint rpe = r * pe;
        uint erdeltaE = exp(r*deltaE, precision*precision, precision);

        require(erdeltaE >= precision);
        require(!checkMultOverflow(erdeltaE - precision, precision));
        require(!checkMultOverflow((erdeltaE - precision)*precision, precision));
        require(!checkMultOverflow((erdeltaE - precision)*precision*precision, precision));
        require(!checkMultOverflow(rpe, erdeltaE));
        require(!checkMultOverflow(r, pe));

        return (erdeltaE - precision) * precision * precision * precision / (rpe*erdeltaE);
    }

    function deltaEFunc(uint r, uint pMIn, uint e, uint deltaT, uint precision, uint numPrecisionBits)
        public pure
        returns (uint)
    {
        uint pe = pE(r, pMIn, e, precision);
        uint rpe = r * pe;
        uint lnPart = ln(precision*precision + rpe*deltaT/precision, precision*precision, numPrecisionBits);

        require(!checkMultOverflow(r, pe));
        require(!checkMultOverflow(precision, precision));
        require(!checkMultOverflow(rpe, deltaT));
        require(!checkMultOverflow(lnPart, precision));

        return lnPart * precision / r;
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

// File: contracts/LiquidityConversionRates.sol

contract LiquidityConversionRates is ConversionRatesInterface, LiquidityFormula, Withdrawable, Utils {
    ERC20 public token;
    address public reserveContract;

    uint public numFpBits;
    uint public formulaPrecision;

    uint public rInFp;
    uint public pMinInFp;

    uint public maxEthCapBuyInFp;
    uint public maxEthCapSellInFp;
    uint public maxQtyInFp;

    uint public feeInBps;
    uint public collectedFeesInTwei = 0;

    uint public maxBuyRateInPrecision;
    uint public minBuyRateInPrecision;
    uint public maxSellRateInPrecision;
    uint public minSellRateInPrecision;

    function LiquidityConversionRates(address _admin, ERC20 _token) public {
        transferAdminQuickly(_admin);
        token = _token;
        setDecimals(token);
        require(getDecimals(token) <= MAX_DECIMALS);
    }

    event ReserveAddressSet(address reserve);

    function setReserveAddress(address reserve) public onlyAdmin {
        reserveContract = reserve;
        ReserveAddressSet(reserve);
    }

    event LiquidityParamsSet(
        uint rInFp,
        uint pMinInFp,
        uint numFpBits,
        uint maxCapBuyInFp,
        uint maxEthCapSellInFp,
        uint feeInBps,
        uint formulaPrecision,
        uint maxQtyInFp,
        uint maxBuyRateInPrecision,
        uint minBuyRateInPrecision,
        uint maxSellRateInPrecision,
        uint minSellRateInPrecision
    );

    function setLiquidityParams(
        uint _rInFp,
        uint _pMinInFp,
        uint _numFpBits,
        uint _maxCapBuyInWei,
        uint _maxCapSellInWei,
        uint _feeInBps,
        uint _maxTokenToEthRateInPrecision,
        uint _minTokenToEthRateInPrecision
    ) public onlyAdmin {

        require(_numFpBits < 256);
        require(formulaPrecision <= MAX_QTY);
        require(_feeInBps < 10000);
        require(_minTokenToEthRateInPrecision < _maxTokenToEthRateInPrecision);

        rInFp = _rInFp;
        pMinInFp = _pMinInFp;
        formulaPrecision = uint(1)<<_numFpBits;
        maxQtyInFp = fromWeiToFp(MAX_QTY);
        numFpBits = _numFpBits;
        maxEthCapBuyInFp = fromWeiToFp(_maxCapBuyInWei);
        maxEthCapSellInFp = fromWeiToFp(_maxCapSellInWei);
        feeInBps = _feeInBps;
        maxBuyRateInPrecision = PRECISION * PRECISION / _minTokenToEthRateInPrecision;
        minBuyRateInPrecision = PRECISION * PRECISION / _maxTokenToEthRateInPrecision;
        maxSellRateInPrecision = _maxTokenToEthRateInPrecision;
        minSellRateInPrecision = _minTokenToEthRateInPrecision;

        LiquidityParamsSet(
            rInFp,
            pMinInFp,
            numFpBits,
            maxEthCapBuyInFp,
            maxEthCapSellInFp,
            feeInBps,
            formulaPrecision,
            maxQtyInFp,
            maxBuyRateInPrecision,
            minBuyRateInPrecision,
            maxSellRateInPrecision,
            minSellRateInPrecision
        );
    }

    function recordImbalance(
        ERC20 conversionToken,
        int buyAmountInTwei,
        uint rateUpdateBlock,
        uint currentBlock
    )
        public
    {
        conversionToken;
        rateUpdateBlock;
        currentBlock;

        require(msg.sender == reserveContract);
        if (buyAmountInTwei > 0) {
            // Buy case
            collectedFeesInTwei += calcCollectedFee(abs(buyAmountInTwei));
        } else {
            // Sell case
            collectedFeesInTwei += abs(buyAmountInTwei) * feeInBps / 10000;
        }
    }

    event CollectedFeesReset(uint resetFeesInTwei);

    function resetCollectedFees() public onlyAdmin {
        uint resetFeesInTwei = collectedFeesInTwei;
        collectedFeesInTwei = 0;

        CollectedFeesReset(resetFeesInTwei);
    }

    function getRate(
            ERC20 conversionToken,
            uint currentBlockNumber,
            bool buy,
            uint qtyInSrcWei
    ) public view returns(uint) {

        currentBlockNumber;

        require(qtyInSrcWei <= MAX_QTY);
        uint eInFp = fromWeiToFp(reserveContract.balance);
        uint rateInPrecision = getRateWithE(conversionToken, buy, qtyInSrcWei, eInFp);
        require(rateInPrecision <= MAX_RATE);
        return rateInPrecision;
    }

    function getRateWithE(ERC20 conversionToken, bool buy, uint qtyInSrcWei, uint eInFp) public view returns(uint) {
        uint deltaEInFp;
        uint sellInputTokenQtyInFp;
        uint deltaTInFp;
        uint rateInPrecision;

        require(qtyInSrcWei <= MAX_QTY);
        require(eInFp <= maxQtyInFp);
        if (conversionToken != token) return 0;

        if (buy) {
            // ETH goes in, token goes out
            deltaEInFp = fromWeiToFp(qtyInSrcWei);
            if (deltaEInFp > maxEthCapBuyInFp) return 0;

            if (deltaEInFp == 0) {
                rateInPrecision = buyRateZeroQuantity(eInFp);
            } else {
                rateInPrecision = buyRate(eInFp, deltaEInFp);
            }
        } else {
            sellInputTokenQtyInFp = fromTweiToFp(qtyInSrcWei);
            deltaTInFp = valueAfterReducingFee(sellInputTokenQtyInFp);
            if (deltaTInFp == 0) {
                rateInPrecision = sellRateZeroQuantity(eInFp);
                deltaEInFp = 0;
            } else {
                (rateInPrecision, deltaEInFp) = sellRate(eInFp, sellInputTokenQtyInFp, deltaTInFp);
            }

            if (deltaEInFp > maxEthCapSellInFp) return 0;
        }

        rateInPrecision = rateAfterValidation(rateInPrecision, buy);
        return rateInPrecision;
    }

    function rateAfterValidation(uint rateInPrecision, bool buy) public view returns(uint) {
        uint minAllowRateInPrecision;
        uint maxAllowedRateInPrecision;

        if (buy) {
            minAllowRateInPrecision = minBuyRateInPrecision;
            maxAllowedRateInPrecision = maxBuyRateInPrecision;
        } else {
            minAllowRateInPrecision = minSellRateInPrecision;
            maxAllowedRateInPrecision = maxSellRateInPrecision;
        }

        if ((rateInPrecision > maxAllowedRateInPrecision) || (rateInPrecision < minAllowRateInPrecision)) {
            return 0;
        } else if (rateInPrecision > MAX_RATE) {
            return 0;
        } else {
            return rateInPrecision;
        }
    }

    function buyRate(uint eInFp, uint deltaEInFp) public view returns(uint) {
        uint deltaTInFp = deltaTFunc(rInFp, pMinInFp, eInFp, deltaEInFp, formulaPrecision);
        require(deltaTInFp <= maxQtyInFp);
        deltaTInFp = valueAfterReducingFee(deltaTInFp);
        return deltaTInFp * PRECISION / deltaEInFp;
    }

    function buyRateZeroQuantity(uint eInFp) public view returns(uint) {
        uint ratePreReductionInPrecision = formulaPrecision * PRECISION / pE(rInFp, pMinInFp, eInFp, formulaPrecision);
        return valueAfterReducingFee(ratePreReductionInPrecision);
    }

    function sellRate(
        uint eInFp,
        uint sellInputTokenQtyInFp,
        uint deltaTInFp
    ) public view returns(uint rateInPrecision, uint deltaEInFp) {
        deltaEInFp = deltaEFunc(rInFp, pMinInFp, eInFp, deltaTInFp, formulaPrecision, numFpBits);
        require(deltaEInFp <= maxQtyInFp);
        rateInPrecision = deltaEInFp * PRECISION / sellInputTokenQtyInFp;
    }

    function sellRateZeroQuantity(uint eInFp) public view returns(uint) {
        uint ratePreReductionInPrecision = pE(rInFp, pMinInFp, eInFp, formulaPrecision) * PRECISION / formulaPrecision;
        return valueAfterReducingFee(ratePreReductionInPrecision);
    }

    function fromTweiToFp(uint qtyInTwei) public view returns(uint) {
        require(qtyInTwei <= MAX_QTY);
        return qtyInTwei * formulaPrecision / (10 ** getDecimals(token));
    }

    function fromWeiToFp(uint qtyInwei) public view returns(uint) {
        require(qtyInwei <= MAX_QTY);
        return qtyInwei * formulaPrecision / (10 ** ETH_DECIMALS);
    }

    function valueAfterReducingFee(uint val) public view returns(uint) {
        require(val <= BIG_NUMBER);
        return ((10000 - feeInBps) * val) / 10000;
    }

    function calcCollectedFee(uint val) public view returns(uint) {
        require(val <= MAX_QTY);
        return val * feeInBps / (10000 - feeInBps);
    }

    function abs(int val) public pure returns(uint) {
        if (val < 0) {
            return uint(val * (-1));
        } else {
            return uint(val);
        }
    }

}