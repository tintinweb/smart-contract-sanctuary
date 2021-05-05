// SPDX-License-Identifier: No License (None)
pragma solidity ^0.8.0;

import "./TransferHelper.sol";
import "./Ownable.sol";

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IValidator {
    // returns rate (with 9 decimals) = Token B price / Token A price
    function getRate(address tokenA, address tokenB) external returns (uint256);
    // returns: user balance, native (foreign for us) encoded balance, foreign (native for us) encoded balance
    function checkBalances(address factory, address[] calldata user) external returns(uint256);
    // returns: user balance
    function checkBalance(address factory, address user) external returns(uint256);
    // returns: oracle fee
    function getOracleFee(uint256 req) external returns(uint256);  //req: 1 - cancel, 2 - claim, returns: value
}

interface ISmart {
    function requestCompensation(address user, uint256 feeAmount) external returns(bool);
}

interface IAuction {
    function contributeFromSmartSwap(address payable user) external payable returns (bool);
    function contributeFromSmartSwap(address token, uint256 amount, address user) external returns (bool);
}


contract SwapFactory is Ownable {

    struct Cancel {
        uint64 pairID; // pair ID
        address sender; // user who has to receive canceled amount
        uint256 amount; // amount of token user want to cancel from order
        //uint128 foreignBalance; // amount of token already swapped (on other chain)
    }

    struct Claim {
        uint64 pairID;     // pair ID
        address sender;     // address who send tokens to swap
        address receiver;   // address who has to receive swapped amount
        bool isInvestment;  // is claim to contributeFromSmartSwap
        uint128 amount;     // amount of foreign tokens user want to swap
        uint128 currentRate;
        uint256 foreignBalance;  //[0] foreignBalance, [1] foreignSpent, [2] nativeSpent, [3] nativeRate
    }

    struct Pair {
        address tokenA;
        address tokenB;        
    }

    address constant NATIVE = address(1);  // address which holds native token ballance that was spent
    address constant FOREIGN = address(2); // address which holds foreign token encoded ballance that was spent
    address constant NATIVE_COINS = 0x0000000000000000000000000000000000000009; // 1 - BNB, 2 - ETH, 3 - BTC
    uint256 constant NOMINATOR = 10**18;
    uint256 constant PRICE_NOMINATOR = 10**9;     // price nominator
    uint256 constant MAX_AMOUNT = 2**192;

    address public foreignFactory;
    address payable public validator;
    uint256 public rateDiffLimit = 5;   // allowed difference (in percent) between LP provided rate and Oracle rate.
    mapping(address => bool) isSystem;  // system address mey change fee amount
    address public auction; // auction address
    address public contractSmart;  // the contract address to request Smart token in exchange of fee
    address public feeReceiver; // address which receive the fee (by default is validator)
    mapping (address => uint256) licenseeFee;  // the licensee may set personal fee (in percent wih 2 decimals). It have to compensate this fee with own tokens.
    mapping (address => address) licenseeCompensator;    // licensee contract which will compensate fee with tokens
 
    mapping(address => bool) public isExchange;         // is Exchange address
    mapping(address => bool) public isExcludedSender;   // address excluded from receiving SMART token as fee compensation

    // fees
    uint256 public swapGasReimbursement = 100;      // percentage of swap Gas Reimbursement by SMART tokens
    uint256 public cancelGasReimbursement = 100;    // percentage of cancel Gas Reimbursement by SMART tokens
    uint256 public companyFeeReimbursement = 100;   // percentage of company Fee Reimbursement by SMART tokens
    uint256 public companyFee = 30; // the fee (in percent wih 2 decimals) that received by company. 30 - means 0.3%
    uint256 public processingFee; // the fee in base coin, to compensate Gas when back-end call claimTokenBehalf()

    mapping(address => uint256) decimals;   // token address => token decimals
    uint256 public pairIDCounter;
    mapping(uint256 => Pair) public getPairByID;
    mapping(address => mapping(address => uint256)) public getPairID;    // tokenA => tokenB => pair ID or 0 if not exist
    mapping(uint256 => uint256) public totalSupply;    // pairID => totalSupply amount of tokenA on the pair

    // hashAddress = address(keccak256(tokenA, tokenB, sender, receiver))
    mapping(address => uint256) public balanceOf;       // hashAddress => amount of tokenA
    mapping(address => Cancel) public cancelRequest;    // hashAddress => amount of tokenA to cancel
    mapping(address => Claim) public claimRequest;      // hashAddress => amount of tokenA to swap


    mapping(address => bool) public isLiquidityProvider;    // list of Liquidity Providers

// ============================ Events ============================

    event PairAdded(address indexed tokenA, address indexed tokenB, uint256 indexed pairID);
    event PairRemoved(address indexed tokenA, address indexed tokenB, uint256 indexed pairID);
    event SwapRequest(
        address indexed tokenA,
        address indexed tokenB,
        address indexed sender,
        address receiver,
        uint256 amountA,
        bool isInvestment
    );
    event CancelRequest(address indexed hashAddress, uint256 amount);
    event CancelApprove(address indexed hashAddress, uint256 newBalance);
    event ClaimRequest(address indexed hashAddress, uint256 amount, bool isInvestment);
    event ClaimApprove(address indexed hashAddress, uint256 amount, bool isInvestment);
    event ExchangeInvestETH(address indexed exchange, address indexed whom, uint256 value);
    event SetSystem(address indexed system, bool active);
    event SetLicensee(address indexed system, address indexed compensator);

    /**
    * @dev Throws if called by any account other than the system.
    */
    modifier onlySystem() {
        require(isSystem[msg.sender] || owner() == msg.sender, "Caller is not the system");
        _;
    }
  
    constructor() {
    }

    // return balance for swap
    function getBalance(
        address tokenA,
        address tokenB, 
        address sender,
        address receiver
    )
        external
        view
        returns (uint256)
    {
        return balanceOf[_getHashAddress(tokenA, tokenB, sender, receiver)];
    }

    function getHashAddress(
        address tokenA,
        address tokenB, 
        address sender,
        address receiver
    )
        external
        pure
        returns (address)
    {
        return _getHashAddress(tokenA, tokenB, sender, receiver);
    }

    //user should approve tokens transfer before calling this function.
    //if no licensee set it to address(0)
    function swap(
        address tokenA,
        address tokenB, 
        address receiver,
        uint256 amountA,
        address licensee,
        bool isInvestment
    )
        external
        payable
        returns (bool)
    {
        _transferFee(tokenA, amountA, msg.sender, licensee);
        _swap(tokenA, tokenB, msg.sender, receiver, amountA, isInvestment);
        return true;
    }

    function cancel(
        address tokenA,
        address tokenB, 
        address receiver,
        uint256 amountA    //amount of tokenA to cancel
    )
        external
        payable
        returns (bool)
    {
        _cancel(tokenA, tokenB, msg.sender, receiver, amountA);
        return true;
    }

    function claimTokenBehalf(
        address tokenA, // foreignToken
        address tokenB, // nativeToken
        address sender,
        address receiver,
        bool isInvestment,
        uint128 amountA,    //amount of tokenA that has to be swapped
        uint128 currentRate,     // rate with 9 decimals
        uint256 foreignBalance  // total tokens amount sent bu user to pair on other chain
    )        
        external
        onlySystem
        returns (bool) 
    {
        _claimTokenBehalf(tokenA, tokenB, sender, receiver, isInvestment, amountA, currentRate, foreignBalance);
        return true;
    }

    // add liquidity to counterparty 
    function addLiquidityAndClaimBehalf(
        address tokenA, // Native token
        address tokenB, // Foreign token
        address receiver,
        bool isInvestment,
        uint128 amountA,    //amount of tokenA that has to be swapped
        uint128 currentRate,     // rate with 9 decimals: tokenB price / tokenA price
        uint256 foreignBalance,  // total tokens amount sent bu user to pair on other chain
        address senderCounterparty,
        address receiverCounterparty
    )
        external
        payable
        onlySystem
        returns (bool)
    {

        _transferFee(tokenA, amountA, msg.sender, address(0));
        _swap(tokenA, tokenB, msg.sender, receiver, amountA, false);
        uint256 amountB = amountA * 10**(18+decimals[tokenB]-decimals[tokenA]) / (currentRate * PRICE_NOMINATOR);
        _claimTokenBehalf(tokenB, tokenA, senderCounterparty, receiverCounterparty, isInvestment, uint128(amountB), currentRate, foreignBalance);
        return true;
    }

    function balanceCallback(address hashAddress, uint256 foreignBalance) external returns(bool) {
        require (validator == msg.sender, "Not validator");
        _cancelApprove(hashAddress, foreignBalance);
        return true;
    }

    function balancesCallback(
        address hashAddress, 
        uint256 foreignBalance, // total user's tokens balance on foreign chain
        uint256 foreignSpent,   // total tokens spent by SmartSwap pair
        uint256 nativeEncoded   // (nativeSpent, nativeRate) = _decode(nativeEncoded)
    ) 
        external 
        returns(bool) 
    {
        require (validator == msg.sender, "Not validator");
        _claimBehalfApprove(hashAddress, foreignBalance, foreignSpent, nativeEncoded);
        return true;
    }

// ================== For Jointer Auction =========================================================================

    // ETH side
    // function for invest ETH from from exchange on user behalf
    function contributeWithEtherBehalf(address payable _whom) external payable returns (bool) {
        require(isExchange[msg.sender], "Not an Exchange address");
        address tokenA = address(2);    // ETH (native coin)
        address tokenB = address(1);    // BNB (foreign coin)
        uint256 amount = msg.value - processingFee;
        emit ExchangeInvestETH(msg.sender, _whom, msg.value);
        _transferFee(tokenA, amount, _whom, address(0));    // no licensee
        _swap(tokenA, tokenB, _whom, auction, amount, true);
        return true;
    }

    // BSC side
    // tokenB - foreign token address or address(1) for ETH
    // amountB - amount of foreign tokens or ETH
    function claimInvestmentBehalf(
        address tokenB, // foreignToken
        address user, 
        uint128 amountB,    //amount of tokenB that has to be swapped
        uint128 currentRate,     // rate with 9 decimals
        uint256 foreignBalance  // total tokens amount sent by user to pair on other chain
    ) 
        external 
        onlySystem 
        returns (bool) 
    {
        address tokenA = address(1);    // BNB (native coin)
        _claimTokenBehalf(tokenB, tokenA, user, auction, true, amountB, currentRate, foreignBalance);
        return true;
    }
    
// ================= END For Jointer Auction ===========================================================================

// ============================ Restricted functions ============================

    function setFee(uint256 _fee) external onlySystem returns(bool) {
        processingFee = _fee;
        return true;
    }

    // set licensee compensator contract address, if this address is address(0) - remove licensee.
    // compensator contract has to compensate the fee by other tokens.
    // licensee fee in percent with 2 decimals. I.e. 10 = 0.1%
    function setLicensee(address _licensee, address _compensator, uint256 _fee) external onlySystem returns(bool) {
        licenseeCompensator[_licensee] = _compensator;
        require(_fee < 10000, "too big fee");    // fee should be less then 100%
        licenseeFee[_licensee] = _fee;
        emit SetLicensee(_licensee, _compensator);
        return true;
    }

    // set licensee fee in percent with 2 decimals. I.e. 10 = 0.1%
    function setLicenseeFee(uint256 _fee) external returns(bool) {
        require(licenseeCompensator[msg.sender] != address(0), "licensee is not registered");
        require(_fee < 10000, "too big fee");    // fee should be less then 100%
        licenseeFee[msg.sender] = _fee;
        return true;
    }

// ============================ Owner's functions ============================

    //the fee (in percent wih 2 decimals) that received by company. 30 - means 0.3%
    function setCompanyFee(uint256 _fee) external onlyOwner returns(bool) {
        require(_fee < 10000, "too big fee");    // fee should be less then 100%
        companyFee = _fee;
        return true;
    }

    // Reimbursement Percentage without decimals: 100 = 100%
    function setReimbursementPercentage (uint256 id, uint256 _fee) external onlyOwner returns(bool) {
        if (id == 1) swapGasReimbursement = _fee;      // percentage of swap Gas Reimbursement by SMART tokens
        else if (id == 2) cancelGasReimbursement = _fee;    // percentage of cancel Gas Reimbursement by SMART tokens
        else if (id == 3) companyFeeReimbursement = _fee;   // percentage of company Fee Reimbursement by SMART tokens
        return true;
    }

    function setSystem(address _system, bool _active) external onlyOwner returns(bool) {
        isSystem[_system] = _active;
        emit SetSystem(_system, _active);
        return true;
    }

    function setValidator(address payable _validator) external onlyOwner returns(bool) {
        validator = _validator;
        if(feeReceiver == address(0)) feeReceiver = _validator;
        return true;
    }

    function setForeignFactory(address _addr) external onlyOwner returns(bool) {
        foreignFactory = _addr;
        return true;
    }

    function setFeeReceiver(address _addr) external onlyOwner returns(bool) {
        feeReceiver = _addr;
        return true;
    }

    function setMSSContract(address _addr) external onlyOwner returns(bool) {
        contractSmart = _addr;
        return true;
    }


    function setAuction(address _addr) external onlyOwner returns(bool) {
        auction = _addr;
        return true;
    }

    // for ETH side only
    function changeExchangeAddress(address _which,bool _bool) external onlyOwner returns(bool){
        isExchange[_which] = _bool;
        return true;
    }
    
    function changeExcludedAddress(address _which,bool _bool) external onlyOwner returns(bool){
        isExcludedSender[_which] = _bool;
        return true;
    }

    function createPair(address tokenA, uint256 decimalsA, address tokenB, uint256 decimalsB) public onlyOwner returns (uint256) {
        require(getPairID[tokenA][tokenB] == 0, "Pair exist");
        uint256 pairID = ++pairIDCounter;
        getPairID[tokenA][tokenB] = pairID;
        getPairByID[pairID] = Pair(tokenA, tokenB);
        if (decimals[tokenA] == 0) decimals[tokenA] = decimalsA;
        if (decimals[tokenB] == 0) decimals[tokenB] = decimalsB;
        return pairID;
    }

// ============================ Internal functions ============================
    function _swap(
        address tokenA, // nativeToken
        address tokenB, // foreignToken
        address sender,
        address receiver,
        uint256 amountA,
        bool isInvestment
    )
        internal
    {
        uint256 pairID = getPairID[tokenA][tokenB];
        require(pairID != 0, "Pair not exist");
        if (tokenA > NATIVE_COINS) {
            TransferHelper.safeTransferFrom(tokenA, sender, address(this), amountA);
        }
        // (amount >= msg.value) is checking when pay fee in the function transferFee()
        address hashAddress = _getHashAddress(tokenA, tokenB, sender, receiver);
        balanceOf[hashAddress] += amountA;
        totalSupply[pairID] += amountA;
        //emit SwapRequest(hashAddress, amountA, isInvestment);
        emit SwapRequest(tokenA, tokenB, sender, receiver, amountA, isInvestment);
    }

    function _cancel(
        address tokenA, // nativeToken
        address tokenB, // foreignToken
        address sender,
        address receiver,
        uint256 amountA    //amount of tokenA to cancel
        //uint128 foreignBalance // amount of tokenA swapped by hashAddress (get by server-side)
    )
        internal
    {
        require(msg.value >= IValidator(validator).getOracleFee(1), "Insufficient fee");    // check oracle fee for Cancel request
        address hashAddress = _getHashAddress(tokenA, tokenB, sender, receiver);
        uint256 pairID = getPairID[tokenA][tokenB];
        require(pairID != 0, "Pair not exist");
        uint256 balance = balanceOf[hashAddress];
        require(balance >= amountA && amountA != 0, "Wrong amount");
        if (cancelRequest[hashAddress].amount == 0) {  // new cancel request
            totalSupply[pairID] = totalSupply[pairID] - amountA;
            balanceOf[hashAddress] = balance - amountA;
        } else { // repeat cancel request in case oracle issues.
            amountA = cancelRequest[hashAddress].amount;
        }
        cancelRequest[hashAddress] = Cancel(uint64(pairID), sender, amountA);
        // transfer fee to validator. May be changed to request tokens for compensation
        TransferHelper.safeTransferETH(feeReceiver, msg.value);
        if(contractSmart != address(0) && !isExcludedSender[sender]) {
            uint256 feeAmount = msg.value * cancelGasReimbursement / 100;
            if (feeAmount != 0)
                ISmart(contractSmart).requestCompensation(sender, feeAmount);
        }
        // request Oracle for fulfilled amount from hashAddress
        IValidator(validator).checkBalance(foreignFactory, hashAddress);
        emit CancelRequest(hashAddress, amountA);
        //emit CancelRequest(tokenA, tokenB, sender, receiver, amountA);
    }

    function _cancelApprove(address hashAddress, uint256 foreignBalance) internal {
        Cancel memory c = cancelRequest[hashAddress];
        delete cancelRequest[hashAddress];
        //require(c.foreignBalance == foreignBalance, "Oracle error");
        uint256 balance = balanceOf[hashAddress];
        uint256 amount = uint256(c.amount);
        uint256 pairID = uint256(c.pairID);
        if (foreignBalance <= balance) {
            //approved - transfer token to its sender
            _transfer(getPairByID[pairID].tokenA, c.sender, amount);
        } else {
            //disapproved
            balance += amount;
            balanceOf[hashAddress] = balance;
            totalSupply[pairID] += amount;
        }
        emit CancelApprove(hashAddress, balance);
    }

    function _claimTokenBehalf(
        address tokenA, // foreignToken
        address tokenB, // nativeToken
        address sender,
        address receiver,
        bool isInvestment,
        uint128 amountA,    //amount of tokenA that has to be swapped
        uint128 currentRate,     // rate with 9 decimals
        uint256 foreignBalance  // total tokens amount sent bu user to pair on other chain
        // [1] foreignSpent, [2] nativeSpent, [3] nativeRate
    )
        internal
    {

        require(amountA != 0, "Zero amount");
        uint256 pairID = getPairID[tokenB][tokenA]; // getPairID[nativeToken][foreignToken]
        require(pairID != 0, "Pair not exist");
        // check rate
        uint256 diffRate = uint256(currentRate) * 100 / IValidator(validator).getRate(tokenA, tokenB);
        uint256 diffLimit = rateDiffLimit;
        require(diffRate >= 100 - diffLimit && diffRate <= 100 + diffLimit, "Wrong rate");

        address hashAddress = _getHashAddress(tokenA, tokenB, sender, receiver);
        if (claimRequest[hashAddress].amount == 0) {  // new claim request
            balanceOf[hashAddress] += uint256(amountA); // total swapped amount of foreign token
        } else { // repeat claim request in case oracle issues.
            amountA = claimRequest[hashAddress].amount;
        }
        address[] memory users = new address[](3);
        users[0] = hashAddress;
        users[1] = _getHashAddress(tokenA, tokenB, NATIVE, address(0));
        users[2] = _getHashAddress(tokenA, tokenB, FOREIGN, address(0));
        claimRequest[hashAddress] = Claim(uint64(pairID), sender, receiver, isInvestment, amountA, currentRate, foreignBalance);
        IValidator(validator).checkBalances(foreignFactory, users);
        emit ClaimRequest(hashAddress, amountA, isInvestment);
        //emit ClaimRequest(tokenA, tokenB, sender, receiver, amountA);
    }

    // Approve or disapprove claim request.
    function _claimBehalfApprove(
        address hashAddress, 
        uint256 foreignBalance, // total user's tokens balance on foreign chain
        uint256 foreignSpent,   // total tokens spent by SmartSwap pair
        uint256 nativeEncoded   // (nativeSpent, nativeRate) = _decode(nativeEncoded)
    ) 
        internal 
    {
        Claim memory c = claimRequest[hashAddress];
        delete claimRequest[hashAddress];
        //address hashSwap = _getHashAddress(getPairByID[c.pairID].tokenB, getPairByID[c.pairID].tokenA, c.sender, c.receiver);
        uint256 balance = balanceOf[hashAddress];   // swapped amount of foreign tokens (include current claim amount)
        uint256 amount = uint256(c.amount);     // amount of foreign token to swap
        require (amount != 0, "No active claim request");
        require(foreignBalance == c.foreignBalance, "Oracle error");

        if (foreignBalance >= balance) {
            //approve, user deposited not less foreign tokens then want to swap
            uint256 pairID = uint256(c.pairID);
            (uint256 nativeSpent, uint256 nativeRate) = _decode(nativeEncoded);
            (uint256 nativeAmount, uint256 rest) = _calculateAmount(
                pairID,
                amount, 
                uint256(c.currentRate),
                foreignSpent,
                nativeSpent,
                nativeRate
            );
            if (rest != 0) {
                balanceOf[hashAddress] = balance - rest;    // not all amount swapped
                amount = amount - rest;     // swapped amount
            }
            require(totalSupply[pairID] > nativeAmount, "Not enough Total Supply");   // may be commented
            totalSupply[pairID] = totalSupply[pairID] - nativeAmount;
            if (c.isInvestment)
                _contributeFromSmartSwap(getPairByID[pairID].tokenA, c.receiver, c.sender, nativeAmount);
            else
                _transfer(getPairByID[pairID].tokenA, c.receiver, nativeAmount);
        } else {
            //disapprove, discard claim
            balanceOf[hashAddress] = balance - amount;
            amount = 0;
        }
        emit ClaimApprove(hashAddress, amount, c.isInvestment);
    }

    // oracleData[] contain: [0] currentRate, [1] foreignSpent, [2] nativeSpent, [3] nativeRate
    function _calculateAmount(
        uint256 pairID,
        uint256 foreignAmount,
        uint256 rate,    // Foreign token price / Native token price = (Native amount / Foreign amount)
        uint256 foreignSpent,
        uint256 nativeSpent,
        uint256 nativeRate
    )
        public //internal
        returns(uint256 nativeAmount, uint256 rest)
    {
//        uint256 rate    // Foreign token price / Native token price = (Native amount / Foreign amount)
        uint256 nativeDecimals = decimals[getPairByID[pairID].tokenA];
        uint256 foreignDecimals = decimals[getPairByID[pairID].tokenB];
        // step 1. Check is it enough unspent native tokens
        {
            address hashNative = _getHashAddress(getPairByID[pairID].tokenA, getPairByID[pairID].tokenB, NATIVE, address(0));
            //(uint256 nativeRate, uint256 nativeSpent) = _decode(nativeEncoded);  // nativeRate = Native token price / Foreign token price
            //nativeRate = nativeRate*NOMINATOR*foreignDecimals/nativeDecimals;
            nativeRate = nativeRate * 10**(18+foreignDecimals-nativeDecimals);
            require(nativeSpent >= balanceOf[hashNative], "NativeSpent balance higher then remote");
            nativeSpent = nativeSpent - balanceOf[hashNative];
            // nativeRate, nativeSpent - rate and amount ready to spend native tokens
            if (nativeSpent != 0) {
                uint256 requireAmount = foreignAmount * PRICE_NOMINATOR * NOMINATOR / nativeRate;
                if (requireAmount <= nativeSpent) {
                    nativeAmount = requireAmount;
                    foreignAmount = 0;
                }
                else {
                    nativeAmount = nativeSpent;
                    foreignAmount = (requireAmount - nativeSpent) * nativeRate / (PRICE_NOMINATOR*NOMINATOR);
                }
                balanceOf[hashNative] += nativeAmount;
            }
        }
        require(totalSupply[pairID] >= nativeAmount,"ERR: Not enough Total Supply");
        // step 2. recalculate rate for swapped tokens
        if (foreignAmount != 0) {
            // to avoid "stack too deep" we reuse variables: nativeRate (for some rate) and nativeSpent (for some amount value)
            nativeRate = rate * 10**(18+nativeDecimals-foreignDecimals);
            uint256 requireAmount = foreignAmount * nativeRate / (PRICE_NOMINATOR*NOMINATOR);
            if (totalSupply[pairID] < nativeAmount + requireAmount) {
                requireAmount = totalSupply[pairID] - nativeAmount;
                rest = foreignAmount - (requireAmount * PRICE_NOMINATOR * NOMINATOR / nativeRate);
                foreignAmount = foreignAmount - rest;
            }
            nativeAmount = nativeAmount + requireAmount;
            address hashForeign = _getHashAddress(getPairByID[pairID].tokenA, getPairByID[pairID].tokenB, FOREIGN, address(0));
            (nativeRate, nativeSpent) = _decode(balanceOf[hashForeign]);
            nativeRate = nativeRate * 10**(18+nativeDecimals-foreignDecimals);
            require(nativeSpent >= foreignSpent, "ForeignSpent balance higher then local");
            uint256 amount2 = nativeSpent - foreignSpent;
            // nativeRate, amount2 - rate and amount swapped foreign tokens
            if (amount2 != 0) { // recalculate avarage rate (native amount / foreign amount)
                rate = ((amount2 * nativeRate / (PRICE_NOMINATOR*NOMINATOR)) + requireAmount) * 10**(9+foreignDecimals) / ((amount2 + foreignAmount) * 10**nativeDecimals);
            }
            balanceOf[hashForeign] = _encode(rate, nativeSpent + foreignAmount);
        }
    }

    // transfer fee to receiver and request SMART token as compensation.
    // tokenA - token that user send
    // amount - amount of tokens that user send
    // user - address of user
    function _transferFee(address tokenA, uint256 amount, address user, address licensee) internal {
        require(licensee == address(0) || licenseeCompensator[licensee] != address(0), "licensee is not registered");
        uint256 feeAmount = msg.value;
        if (tokenA < NATIVE_COINS) {
            require(feeAmount >= amount, "Insuficiant value");   // if native coin, then feeAmount = msg.value - swap amount
            feeAmount -= amount;
        }
        require(feeAmount >= processingFee, "Insufficient fee");
        uint256 otherFee = feeAmount - processingFee;
        uint256 licenseeFeeAmount;
        uint256 licenseeFeeRate = licenseeFee[licensee];
        if (licenseeFeeRate != 0 && otherFee != 0) {
            licenseeFeeAmount = (otherFee * licenseeFeeRate)/(licenseeFeeRate + companyFee);
            feeAmount -= licenseeFeeAmount;
        }

        if (licenseeFeeAmount != 0) {
            TransferHelper.safeTransferETH(licensee, licenseeFeeAmount);
            ISmart(licenseeCompensator[licensee]).requestCompensation(user, licenseeFeeAmount);
        }

        TransferHelper.safeTransferETH(feeReceiver, feeAmount);
        if(contractSmart != address(0) && !isExcludedSender[msg.sender]) {
            feeAmount = ((feeAmount - processingFee) * companyFeeReimbursement + processingFee * swapGasReimbursement) / 100;
            if (feeAmount != 0)
                ISmart(contractSmart).requestCompensation(user, feeAmount);
        }
    }
    
    // contribute from SmartSwap on user behalf
    function _contributeFromSmartSwap(address token, address to, address user, uint256 value) internal {
        if (token < NATIVE_COINS) {
            IAuction(to).contributeFromSmartSwap{value: value}(payable(user));
        } else {
            IERC20(token).approve(to, value);
            IAuction(to).contributeFromSmartSwap(token, value, user);
        }
    }

    // call appropriate transfer function
    function _transfer(address token, address to, uint256 value) internal {
        if (token < NATIVE_COINS) 
            TransferHelper.safeTransferETH(to, value);
        else
            TransferHelper.safeTransfer(token, to, value);
    }

    // encode 64 bits of rate (decimal = 9). and 192 bits of amount 
    // into uint256 where high 64 bits is rate and low 192 bit is amount
    // rate = foreign token price / native token price
    function _encode(uint256 rate, uint256 amount) internal pure returns(uint256 encodedBalance) {
        require(amount < MAX_AMOUNT, "Amount overflow");
        require(rate < 2**64, "Rate overflow");
        encodedBalance = rate * MAX_AMOUNT + amount;
    }

    // decode from uint256 where high 64 bits is rate and low 192 bit is amount
    // rate = foreign token price / native token price
    function _decode(uint256 encodedBalance) internal pure returns(uint256 rate, uint256 amount) {
        rate = encodedBalance / MAX_AMOUNT;
        amount = uint192(encodedBalance);
    }
    
    function _getHashAddress(
        address tokenA,
        address tokenB, 
        address sender,
        address receiver
    )
        internal
        pure
        returns (address)
    {
        return address(uint160(uint256(keccak256(abi.encodePacked(tokenA, tokenB, sender, receiver)))));
    }
}