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
    function setQtyStepFunction(ERC20 token, int[] xBuy, int[] yBuy, int[] xSell, int[] ySell) public;
    function setImbalanceStepFunction(ERC20 token, int[] xBuy, int[] yBuy, int[] xSell, int[] ySell) public;
    function claimAdmin() public;
    function addOperator(address newOperator) public;
    function transferAdmin(address newAdmin) public;
    function addToken(ERC20 token) public;
    function setTokenControlInfo(
        ERC20 token,
        uint minimalRecordResolution,
        uint maxPerBlockImbalance,
        uint maxTotalImbalance
    ) public;
    function enableTokenTrade(ERC20 token) public;
    function getTokenControlInfo(ERC20 token) public view returns(uint, uint, uint);
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

// File: contracts/wrapperContracts/WrapperBase.sol

contract WrapperBase is Withdrawable {

    PermissionGroups wrappedContract;

    struct DataTracker {
        address [] approveSignatureArray;
        uint lastSetNonce;
    }

    DataTracker[] internal dataInstances;

    function WrapperBase(PermissionGroups _wrappedContract, address _admin) public {
        require(_wrappedContract != address(0));
        require(_admin != address(0));
        wrappedContract = _wrappedContract;
        admin = _admin;
    }

    function claimWrappedContractAdmin() public onlyAdmin {
        wrappedContract.claimAdmin();
    }

    function transferWrappedContractAdmin (address newAdmin) public onlyAdmin {
        wrappedContract.transferAdmin(newAdmin);
    }

    function addDataInstance() internal returns (uint) {
        address[] memory add = new address[](0);
        dataInstances.push(DataTracker(add, 0));
        return(dataInstances.length - 1);
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

// File: contracts/wrapperContracts/WrapConversionRate.sol

contract WrapConversionRate is WrapperBase {

    ConversionRatesInterface conversionRates;

    //add token parameters
    ERC20     addTokenToken;
    uint      addTokenMinimalResolution; // can be roughly 1 cent
    uint      addTokenMaxPerBlockImbalance; // in twei resolution
    uint      addTokenMaxTotalImbalance;
    uint      addTokenDataIndex;

    //set token control info parameters.
    ERC20[]     tokenInfoTokenList;
    uint[]      tokenInfoPerBlockImbalance; // in twei resolution
    uint[]      tokenInfoMaxTotalImbalance;
    uint        tokenInfoDataIndex;

    //general functions
    function WrapConversionRate(ConversionRatesInterface _conversionRates, address _admin) public
        WrapperBase(PermissionGroups(address(_conversionRates)), _admin)
    {
        require (_conversionRates != address(0));
        conversionRates = _conversionRates;
        addTokenDataIndex = addDataInstance();
        tokenInfoDataIndex = addDataInstance();
    }

    function getWrappedContract() public view returns (ConversionRatesInterface _conversionRates) {
        _conversionRates = conversionRates;
    }

    // add token functions
    //////////////////////
    function setAddTokenData(ERC20 token, uint minimalRecordResolution, uint maxPerBlockImbalance, uint maxTotalImbalance) public onlyOperator {
        require(minimalRecordResolution != 0);
        require(maxPerBlockImbalance != 0);
        require(maxTotalImbalance != 0);

        //update data tracking
        setNewData(addTokenDataIndex);

        addTokenToken = token;
        addTokenMinimalResolution = minimalRecordResolution; // can be roughly 1 cent
        addTokenMaxPerBlockImbalance = maxPerBlockImbalance; // in twei resolution
        addTokenMaxTotalImbalance = maxTotalImbalance;
    }

    function signToApproveAddTokenData(uint nonce) public onlyOperator {
        if(addSignature(addTokenDataIndex, nonce, msg.sender)) {
            // can perform operation.
            performAddToken();
        }
    }

    function performAddToken() internal {
        conversionRates.addToken(addTokenToken);

        //token control info
        conversionRates.setTokenControlInfo(
            addTokenToken,
            addTokenMinimalResolution,
            addTokenMaxPerBlockImbalance,
            addTokenMaxTotalImbalance
        );

        //step functions
        int[] memory zeroArr = new int[](1);
        zeroArr[0] = 0;

        conversionRates.setQtyStepFunction(addTokenToken, zeroArr, zeroArr, zeroArr, zeroArr);
        conversionRates.setImbalanceStepFunction(addTokenToken, zeroArr, zeroArr, zeroArr, zeroArr);

        conversionRates.enableTokenTrade(addTokenToken);
    }

    function getAddTokenParameters() public view
        returns(ERC20 token, uint minimalRecordResolution, uint maxPerBlockImbalance, uint maxTotalImbalance)
    {
        token = addTokenToken;
        minimalRecordResolution = addTokenMinimalResolution;
        maxPerBlockImbalance = addTokenMaxPerBlockImbalance; // in twei resolution
        maxTotalImbalance = addTokenMaxTotalImbalance;
    }

    function getAddTokenDataTracking() public view returns (address[] signatures, uint nonce) {
        (signatures, nonce) = getDataTrackingParameters(addTokenDataIndex);
        return(signatures, nonce);
    }

    //set token control info
    ////////////////////////
    function setTokenInfoData(ERC20 [] tokens, uint[] maxPerBlockImbalanceValues, uint[] maxTotalImbalanceValues)
        public
        onlyOperator
    {
        require(maxPerBlockImbalanceValues.length == tokens.length);
        require(maxTotalImbalanceValues.length == tokens.length);

        //update data tracking
        setNewData(tokenInfoDataIndex);

        tokenInfoTokenList = tokens;
        tokenInfoPerBlockImbalance = maxPerBlockImbalanceValues;
        tokenInfoMaxTotalImbalance = maxTotalImbalanceValues;
    }

    function signToApproveTokenControlInfo(uint nonce) public onlyOperator {
        if(addSignature(tokenInfoDataIndex, nonce, msg.sender)) {
            // can perform operation.
            performSetTokenControlInfo();
        }
    }

    function performSetTokenControlInfo() internal {
        require(tokenInfoTokenList.length == tokenInfoPerBlockImbalance.length);
        require(tokenInfoTokenList.length == tokenInfoMaxTotalImbalance.length);

        uint minimalRecordResolution;
        uint rxMaxPerBlockImbalance;
        uint rxMaxTotalImbalance;

        for (uint i = 0; i < tokenInfoTokenList.length; i++) {
            (minimalRecordResolution, rxMaxPerBlockImbalance, rxMaxTotalImbalance) =
                conversionRates.getTokenControlInfo(tokenInfoTokenList[i]);
            require(minimalRecordResolution != 0);

            conversionRates.setTokenControlInfo(tokenInfoTokenList[i],
                                                minimalRecordResolution,
                                                tokenInfoPerBlockImbalance[i],
                                                tokenInfoMaxTotalImbalance[i]);
        }
    }

    function getControlInfoPerToken (uint index) public view returns(ERC20 token, uint _maxPerBlockImbalance, uint _maxTotalImbalance) {
        require (tokenInfoTokenList.length > index);
        require (tokenInfoPerBlockImbalance.length > index);
        require (tokenInfoMaxTotalImbalance.length > index);

        return(tokenInfoTokenList[index], tokenInfoPerBlockImbalance[index], tokenInfoMaxTotalImbalance[index]);
    }

    function getTokenInfoData() public view returns(ERC20[], uint[], uint[]) {
        return(tokenInfoTokenList, tokenInfoPerBlockImbalance, tokenInfoMaxTotalImbalance);
    }

    function getTokenInfoTokenList() public view returns(ERC20[] tokens) {
        return(tokenInfoTokenList);
    }

    function getTokenInfoMaxPerBlockImbalanceList() public view returns(uint[] maxPerBlockImbalanceValues) {
        return (tokenInfoPerBlockImbalance);
    }

    function getTokenInfoMaxTotalImbalanceList() public view returns(uint[] maxTotalImbalanceValues) {
        return(tokenInfoMaxTotalImbalance);
    }

    function getTokenInfoDataTracking() public view returns (address[] signatures, uint nonce) {
        (signatures, nonce) = getDataTrackingParameters(tokenInfoDataIndex);
        return(signatures, nonce);
    }
}