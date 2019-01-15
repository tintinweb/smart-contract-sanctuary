pragma solidity 0.4.18;

// File: contracts/FeeBurnerInterface.sol

interface FeeBurnerInterface {
    function handleFees (uint tradeWeiAmount, address reserve, address wallet) public returns(bool);
    function setReserveData(address reserve, uint feesInBps, address kncWallet) public;
}

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

// File: contracts/KyberNetworkInterface.sol

/// @title Kyber Network interface
interface KyberNetworkInterface {
    function maxGasPrice() public view returns(uint);
    function getUserCapInWei(address user) public view returns(uint);
    function getUserCapInTokenWei(address user, ERC20 token) public view returns(uint);
    function enabled() public view returns(bool);
    function info(bytes32 id) public view returns(uint);

    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) public view
        returns (uint expectedRate, uint slippageRate);

    function tradeWithHint(address trader, ERC20 src, uint srcAmount, ERC20 dest, address destAddress,
        uint maxDestAmount, uint minConversionRate, address walletId, bytes hint) public payable returns(uint);
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

// File: contracts/Utils2.sol

contract Utils2 is Utils {

    /// @dev get the balance of a user.
    /// @param token The token type
    /// @return The balance
    function getBalance(ERC20 token, address user) public view returns(uint) {
        if (token == ETH_TOKEN_ADDRESS)
            return user.balance;
        else
            return token.balanceOf(user);
    }

    function getDecimalsSafe(ERC20 token) internal returns(uint) {

        if (decimals[token] == 0) {
            setDecimals(token);
        }

        return decimals[token];
    }

    function calcDestAmount(ERC20 src, ERC20 dest, uint srcAmount, uint rate) internal view returns(uint) {
        return calcDstQty(srcAmount, getDecimals(src), getDecimals(dest), rate);
    }

    function calcSrcAmount(ERC20 src, ERC20 dest, uint destAmount, uint rate) internal view returns(uint) {
        return calcSrcQty(destAmount, getDecimals(src), getDecimals(dest), rate);
    }

    function calcRateFromQty(uint srcAmount, uint destAmount, uint srcDecimals, uint dstDecimals)
        internal pure returns(uint)
    {
        require(srcAmount <= MAX_QTY);
        require(destAmount <= MAX_QTY);

        if (dstDecimals >= srcDecimals) {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS);
            return (destAmount * PRECISION / ((10 ** (dstDecimals - srcDecimals)) * srcAmount));
        } else {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS);
            return (destAmount * PRECISION * (10 ** (srcDecimals - dstDecimals)) / srcAmount);
        }
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

// File: contracts/FeeBurner.sol

interface BurnableToken {
    function transferFrom(address _from, address _to, uint _value) public returns (bool);
    function burnFrom(address _from, uint256 _value) public returns (bool);
}


contract FeeBurner is Withdrawable, FeeBurnerInterface, Utils2 {

    mapping(address=>uint) public reserveFeesInBps;
    mapping(address=>address) public reserveKNCWallet; //wallet holding knc per reserve. from here burn and send fees.
    mapping(address=>uint) public walletFeesInBps; // wallet that is the source of tx is entitled so some fees.
    mapping(address=>uint) public reserveFeeToBurn;
    mapping(address=>uint) public feePayedPerReserve; // track burned fees and sent wallet fees per reserve.
    mapping(address=>mapping(address=>uint)) public reserveFeeToWallet;
    address public taxWallet;
    uint public taxFeeBps = 0; // burned fees are taxed. % out of burned fees.

    BurnableToken public knc;
    KyberNetworkInterface public kyberNetwork;
    uint public kncPerEthRatePrecision = 600 * PRECISION; //--> 1 ether = 600 knc tokens

    function FeeBurner(
        address _admin,
        BurnableToken _kncToken,
        KyberNetworkInterface _kyberNetwork,
        uint _initialKncToEthRatePrecision
    )
        public
    {
        require(_admin != address(0));
        require(_kncToken != address(0));
        require(_kyberNetwork != address(0));
        require(_initialKncToEthRatePrecision != 0);

        kyberNetwork = _kyberNetwork;
        admin = _admin;
        knc = _kncToken;
        kncPerEthRatePrecision = _initialKncToEthRatePrecision;
    }

    event ReserveDataSet(address reserve, uint feeInBps, address kncWallet);

    function setReserveData(address reserve, uint feesInBps, address kncWallet) public onlyOperator {
        require(feesInBps < 100); // make sure it is always < 1%
        require(kncWallet != address(0));
        reserveFeesInBps[reserve] = feesInBps;
        reserveKNCWallet[reserve] = kncWallet;
        ReserveDataSet(reserve, feesInBps, kncWallet);
    }

    event WalletFeesSet(address wallet, uint feesInBps);

    function setWalletFees(address wallet, uint feesInBps) public onlyAdmin {
        require(feesInBps < 10000); // under 100%
        walletFeesInBps[wallet] = feesInBps;
        WalletFeesSet(wallet, feesInBps);
    }

    event TaxFeesSet(uint feesInBps);

    function setTaxInBps(uint _taxFeeBps) public onlyAdmin {
        require(_taxFeeBps < 10000); // under 100%
        taxFeeBps = _taxFeeBps;
        TaxFeesSet(_taxFeeBps);
    }

    event TaxWalletSet(address taxWallet);

    function setTaxWallet(address _taxWallet) public onlyAdmin {
        require(_taxWallet != address(0));
        taxWallet = _taxWallet;
        TaxWalletSet(_taxWallet);
    }

    event KNCRateSet(uint ethToKncRatePrecision, uint kyberEthKnc, uint kyberKncEth, address updater);

    function setKNCRate() public {
        //query kyber for knc rate sell and buy
        uint kyberEthKncRate;
        uint kyberKncEthRate;
        (kyberEthKncRate, ) = kyberNetwork.getExpectedRate(ETH_TOKEN_ADDRESS, ERC20(knc), (10 ** 18));
        (kyberKncEthRate, ) = kyberNetwork.getExpectedRate(ERC20(knc), ETH_TOKEN_ADDRESS, (10 ** 18));

        //check "reasonable" spread == diff not too big. rate wasn&#39;t tampered.
        require(kyberEthKncRate * kyberKncEthRate < PRECISION ** 2 * 2);
        require(kyberEthKncRate * kyberKncEthRate > PRECISION ** 2 / 2);

        require(kyberEthKncRate <= MAX_RATE);
        kncPerEthRatePrecision = kyberEthKncRate;
        KNCRateSet(kncPerEthRatePrecision, kyberEthKncRate, kyberKncEthRate, msg.sender);
    }

    event AssignFeeToWallet(address reserve, address wallet, uint walletFee);
    event AssignBurnFees(address reserve, uint burnFee);

    function handleFees(uint tradeWeiAmount, address reserve, address wallet) public returns(bool) {
        require(msg.sender == address(kyberNetwork));
        require(tradeWeiAmount <= MAX_QTY);

        uint kncAmount = calcDestAmount(ETH_TOKEN_ADDRESS, ERC20(knc), tradeWeiAmount, kncPerEthRatePrecision);
        uint fee = kncAmount * reserveFeesInBps[reserve] / 10000;

        uint walletFee = fee * walletFeesInBps[wallet] / 10000;
        require(fee >= walletFee);
        uint feeToBurn = fee - walletFee;

        if (walletFee > 0) {
            reserveFeeToWallet[reserve][wallet] += walletFee;
            AssignFeeToWallet(reserve, wallet, walletFee);
        }

        if (feeToBurn > 0) {
            AssignBurnFees(reserve, feeToBurn);
            reserveFeeToBurn[reserve] += feeToBurn;
        }

        return true;
    }

    event BurnAssignedFees(address indexed reserve, address sender, uint quantity);

    event SendTaxFee(address indexed reserve, address sender, address taxWallet, uint quantity);

    // this function is callable by anyone
    function burnReserveFees(address reserve) public {
        uint burnAmount = reserveFeeToBurn[reserve];
        uint taxToSend = 0;
        require(burnAmount > 2);
        reserveFeeToBurn[reserve] = 1; // leave 1 twei to avoid spikes in gas fee
        if (taxWallet != address(0) && taxFeeBps != 0) {
            taxToSend = (burnAmount - 1) * taxFeeBps / 10000;
            require(burnAmount - 1 > taxToSend);
            burnAmount -= taxToSend;
            if (taxToSend > 0) {
                require(knc.transferFrom(reserveKNCWallet[reserve], taxWallet, taxToSend));
                SendTaxFee(reserve, msg.sender, taxWallet, taxToSend);
            }
        }
        require(knc.burnFrom(reserveKNCWallet[reserve], burnAmount - 1));

        //update reserve "payments" so far
        feePayedPerReserve[reserve] += (taxToSend + burnAmount - 1);

        BurnAssignedFees(reserve, msg.sender, (burnAmount - 1));
    }

    event SendWalletFees(address indexed wallet, address reserve, address sender);

    // this function is callable by anyone
    function sendFeeToWallet(address wallet, address reserve) public {
        uint feeAmount = reserveFeeToWallet[reserve][wallet];
        require(feeAmount > 1);
        reserveFeeToWallet[reserve][wallet] = 1; // leave 1 twei to avoid spikes in gas fee
        require(knc.transferFrom(reserveKNCWallet[reserve], wallet, feeAmount - 1));

        feePayedPerReserve[reserve] += (feeAmount - 1);
        SendWalletFees(wallet, reserve, msg.sender);
    }
}

// File: contracts/wrapperContracts/WrapperBase.sol

contract WrapperBase is Withdrawable {

    PermissionGroups public wrappedContract;

    struct DataTracker {
        address [] approveSignatureArray;
        uint lastSetNonce;
    }

    DataTracker[] internal dataInstances;

    function WrapperBase(PermissionGroups _wrappedContract, address _admin, uint _numDataInstances) public {
        require(_wrappedContract != address(0));
        require(_admin != address(0));
        wrappedContract = _wrappedContract;
        admin = _admin;

        for (uint i = 0; i < _numDataInstances; i++){
            addDataInstance();
        }
    }

    function claimWrappedContractAdmin() public onlyOperator {
        wrappedContract.claimAdmin();
    }

    function transferWrappedContractAdmin (address newAdmin) public onlyAdmin {
        wrappedContract.transferAdmin(newAdmin);
    }

    function addDataInstance() internal {
        address[] memory add = new address[](0);
        dataInstances.push(DataTracker(add, 0));
    }

    function setNewData(uint dataIndex) internal {
        require(dataIndex < dataInstances.length);
        dataInstances[dataIndex].lastSetNonce++;
        dataInstances[dataIndex].approveSignatureArray.length = 0;
    }

    function addSignature(uint dataIndex, uint signedNonce, address signer) internal returns(bool allSigned) {
        require(dataIndex < dataInstances.length);
        require(dataInstances[dataIndex].lastSetNonce == signedNonce);

        for(uint i = 0; i < dataInstances[dataIndex].approveSignatureArray.length; i++) {
            if (signer == dataInstances[dataIndex].approveSignatureArray[i]) revert();
        }
        dataInstances[dataIndex].approveSignatureArray.push(signer);

        if (dataInstances[dataIndex].approveSignatureArray.length == operatorsGroup.length) {
            allSigned = true;
        } else {
            allSigned = false;
        }
    }

    function getDataTrackingParameters(uint index) internal view returns (address[], uint) {
        require(index < dataInstances.length);
        return(dataInstances[index].approveSignatureArray, dataInstances[index].lastSetNonce);
    }
}

// File: contracts/wrapperContracts/WrapFeeBurner.sol

contract WrapFeeBurner is WrapperBase {

    FeeBurner public feeBurnerContract;
    address[] internal feeSharingWallets;
    uint public feeSharingBps = 3000; // out of 10000 = 30%

    //add reserve pending data
    struct AddReserveData {
        address reserve;
        uint    feeBps;
        address kncWallet;
    }

    AddReserveData internal addReserve;

    //wallet fee pending parameters
    struct WalletFee {
        address walletAddress;
        uint    feeBps;
    }

    WalletFee internal walletFee;

    //tax pending parameters
    struct TaxData {
        address wallet;
        uint    feeBps;
    }

    TaxData internal taxData;
    
    //data indexes
    uint internal constant ADD_RESERVE_INDEX = 1;
    uint internal constant WALLET_FEE_INDEX = 2;
    uint internal constant TAX_DATA_INDEX = 3;
    uint internal constant LAST_DATA_INDEX = 4;

    //general functions
    function WrapFeeBurner(FeeBurner feeBurner, address _admin) public
        WrapperBase(PermissionGroups(address(feeBurner)), _admin, LAST_DATA_INDEX)
    {
        require(feeBurner != address(0));
        feeBurnerContract = feeBurner;
    }

    //register wallets for fee sharing
    /////////////////////////////////
    function setFeeSharingValue(uint feeBps) public onlyAdmin {
        require(feeBps < 10000);
        feeSharingBps = feeBps;
    }

    function getFeeSharingWallets() public view returns(address[]) {
        return feeSharingWallets;
    }

    event WalletRegisteredForFeeSharing(address sender, address walletAddress);
    function registerWalletForFeeSharing(address walletAddress) public {
        require(feeBurnerContract.walletFeesInBps(walletAddress) == 0);

        // if fee sharing value is 0. means the wallet wasn&#39;t added.
        feeBurnerContract.setWalletFees(walletAddress, feeSharingBps);
        feeSharingWallets.push(walletAddress);
        WalletRegisteredForFeeSharing(msg.sender, walletAddress);
    }

    //set reserve data
    //////////////////
    function setPendingReserveData(address reserve, uint feeBps, address kncWallet) public onlyOperator {
        require(reserve != address(0));
        require(kncWallet != address(0));
        require(feeBps > 0);
        require(feeBps < 10000);

        addReserve.reserve = reserve;
        addReserve.feeBps = feeBps;
        addReserve.kncWallet = kncWallet;
        setNewData(ADD_RESERVE_INDEX);
    }

    function getPendingAddReserveData() public view
        returns(address reserve, uint feeBps, address kncWallet, uint nonce)
    {
        address[] memory signatures;
        (signatures, nonce) = getDataTrackingParameters(ADD_RESERVE_INDEX);
        return(addReserve.reserve, addReserve.feeBps, addReserve.kncWallet, nonce);
    }

    function getAddReserveSignatures() public view returns (address[] signatures) {
        uint nonce;
        (signatures, nonce) = getDataTrackingParameters(ADD_RESERVE_INDEX);
        return(signatures);
    }

    function approveAddReserveData(uint nonce) public onlyOperator {
        if (addSignature(ADD_RESERVE_INDEX, nonce, msg.sender)) {
            // can perform operation.
            feeBurnerContract.setReserveData(addReserve.reserve, addReserve.feeBps, addReserve.kncWallet);
        }
    }

    //wallet fee
    /////////////
    function setPendingWalletFee(address wallet, uint feeBps) public onlyOperator {
        require(wallet != address(0));
        require(feeBps > 0);
        require(feeBps < 10000);

        walletFee.walletAddress = wallet;
        walletFee.feeBps = feeBps;
        setNewData(WALLET_FEE_INDEX);
    }

    function getPendingWalletFeeData() public view returns(address wallet, uint feeBps, uint nonce) {
        address[] memory signatures;
        (signatures, nonce) = getDataTrackingParameters(WALLET_FEE_INDEX);
        return(walletFee.walletAddress, walletFee.feeBps, nonce);
    }

    function getWalletFeeSignatures() public view returns (address[] signatures) {
        uint nonce;
        (signatures, nonce) = getDataTrackingParameters(WALLET_FEE_INDEX);
        return(signatures);
    }

    function approveWalletFeeData(uint nonce) public onlyOperator {
        if (addSignature(WALLET_FEE_INDEX, nonce, msg.sender)) {
            // can perform operation.
            feeBurnerContract.setWalletFees(walletFee.walletAddress, walletFee.feeBps);
        }
    }

    //tax parameters
    ////////////////
    function setPendingTaxParameters(address taxWallet, uint feeBps) public onlyOperator {
        require(taxWallet != address(0));
        require(feeBps > 0);
        require(feeBps < 10000);

        taxData.wallet = taxWallet;
        taxData.feeBps = feeBps;
        setNewData(TAX_DATA_INDEX);
    }

    function getPendingTaxData() public view returns(address wallet, uint feeBps, uint nonce) {
        address[] memory signatures;
        (signatures, nonce) = getDataTrackingParameters(TAX_DATA_INDEX);
        return(taxData.wallet, taxData.feeBps, nonce);
    }

    function getTaxDataSignatures() public view returns (address[] signatures) {
        uint nonce;
        (signatures, nonce) = getDataTrackingParameters(TAX_DATA_INDEX);
        return(signatures);
    }

    function approveTaxData(uint nonce) public onlyOperator {
        if (addSignature(TAX_DATA_INDEX, nonce, msg.sender)) {
            // can perform operation.
            feeBurnerContract.setTaxInBps(taxData.feeBps);
            feeBurnerContract.setTaxWallet(taxData.wallet);
        }
    }
}