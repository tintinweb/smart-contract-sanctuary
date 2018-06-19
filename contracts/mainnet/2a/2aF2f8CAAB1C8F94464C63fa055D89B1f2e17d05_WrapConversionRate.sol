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
        wrappedContract.removeOperator(this);
        wrappedContract.transferAdmin(newAdmin);
    }

    function addSignature(address[] storage existingSignatures) internal returns(bool allSigned) {
        for(uint i = 0; i < existingSignatures.length; i++) {
            if (msg.sender == existingSignatures[i]) revert();
        }
        existingSignatures.push(msg.sender);

        if (existingSignatures.length == operatorsGroup.length) {
            allSigned = true;
            existingSignatures.length = 0;
        } else {
            allSigned = false;
        }
    }
}

// File: contracts/wrapperContracts/WrapConversionRate.sol

contract ConversionRateWrapperInterface {
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

contract WrapConversionRate is WrapperBase {

    ConversionRateWrapperInterface conversionRates;

    //add token parameters
    ERC20 addTokenToken;
    uint addTokenMinimalResolution; // can be roughly 1 cent
    uint addTokenMaxPerBlockImbalance; // in twei resolution
    uint addTokenMaxTotalImbalance;
    address[] addTokenApproveSignatures;
    address[] addTokenResetSignatures;

    //set token control info parameters.
    ERC20[] tokenInfoTokenList;
    uint[]  tokenInfoPerBlockImbalance; // in twei resolution
    uint[]  tokenInfoMaxTotalImbalance;
    bool public tokenInfoParametersReady;
    address[] tokenInfoApproveSignatures;
    address[] tokenInfoResetSignatures;

    //general functions
    function WrapConversionRate(ConversionRateWrapperInterface _conversionRates, address _admin) public
        WrapperBase(PermissionGroups(address(_conversionRates)), _admin)
    {
        require (_conversionRates != address(0));
        conversionRates = _conversionRates;
        tokenInfoParametersReady = false;
    }

    function getWrappedContract() public view returns (ConversionRateWrapperInterface _conversionRates) {
        _conversionRates = conversionRates;
    }

    // add token functions
    //////////////////////
    function setAddTokenData(ERC20 token, uint minimalRecordResolution, uint maxPerBlockImbalance, uint maxTotalImbalance) public onlyOperator {
        require(minimalRecordResolution != 0);
        require(maxPerBlockImbalance != 0);
        require(maxTotalImbalance != 0);
        require(token != address(0));
        //can update only when data is reset
        require(addTokenToken == address(0));

        //reset approve array. we have new parameters
        addTokenApproveSignatures.length = 0;
        addTokenToken = token;
        addTokenMinimalResolution = minimalRecordResolution; // can be roughly 1 cent
        addTokenMaxPerBlockImbalance = maxPerBlockImbalance; // in twei resolution
        addTokenMaxTotalImbalance = maxTotalImbalance;
    }

    function signToApproveAddTokenData() public onlyOperator {
        require(addTokenToken != address(0));

        if(addSignature(addTokenApproveSignatures)) {
            // can perform operation.
            performAddToken();
            resetAddTokenData();
        }
    }

    function signToResetAddTokenData() public onlyOperator() {
        require(addTokenToken != address(0));
        if(addSignature(addTokenResetSignatures)) {
            // can reset data
            resetAddTokenData();
            addTokenApproveSignatures.length = 0;
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

    function resetAddTokenData() internal {
        addTokenToken = ERC20(address(0));
        addTokenMinimalResolution = 0;
        addTokenMaxPerBlockImbalance = 0;
        addTokenMaxTotalImbalance = 0;
    }

    function getAddTokenParameters() public view returns(ERC20 token, uint minimalRecordResolution, uint maxPerBlockImbalance, uint maxTotalImbalance) {
        token = addTokenToken;
        minimalRecordResolution = addTokenMinimalResolution;
        maxPerBlockImbalance = addTokenMaxPerBlockImbalance; // in twei resolution
        maxTotalImbalance = addTokenMaxTotalImbalance;
    }

    function getAddTokenApproveSignatures() public view returns (address[] signatures) {
        signatures = addTokenApproveSignatures;
    }

    function getAddTokenResetSignatures() public view returns (address[] signatures) {
        signatures = addTokenResetSignatures;
    }
    
    //set token control info
    ////////////////////////
    function setTokenInfoTokenList(ERC20 [] tokens) public onlyOperator {
        require(tokenInfoParametersReady == false);
        tokenInfoTokenList = tokens;
    }

    function setTokenInfoMaxPerBlockImbalanceList(uint[] maxPerBlockImbalanceValues) public onlyOperator {
        require(tokenInfoParametersReady == false);
        require(maxPerBlockImbalanceValues.length == tokenInfoTokenList.length);
        tokenInfoPerBlockImbalance = maxPerBlockImbalanceValues;
    }

    function setTokenInfoMaxTotalImbalanceList(uint[] maxTotalImbalanceValues) public onlyOperator {
        require(tokenInfoParametersReady == false);
        require(maxTotalImbalanceValues.length == tokenInfoTokenList.length);
        tokenInfoMaxTotalImbalance = maxTotalImbalanceValues;
    }

    function setTokenInfoParametersReady() {
        require(tokenInfoParametersReady == false);
        tokenInfoParametersReady = true;
    }

    function signToApproveTokenControlInfo() public onlyOperator {
        require(tokenInfoParametersReady == true);
        if (addSignature(tokenInfoApproveSignatures)) {
            // can perform operation.
            performSetTokenControlInfo();
            tokenInfoParametersReady = false;
        }
    }

    function signToResetTokenControlInfo() public onlyOperator {
        require(tokenInfoParametersReady == true);
        if (addSignature(tokenInfoResetSignatures)) {
            // can perform operation.
            tokenInfoParametersReady = false;
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

    function getControlInfoTokenlist() public view returns(ERC20[] tokens) {
        tokens = tokenInfoTokenList;
    }

    function getControlInfoMaxPerBlockImbalanceList() public view returns(uint[] maxPerBlockImbalanceValues) {
        maxPerBlockImbalanceValues = tokenInfoPerBlockImbalance;
    }

    function getControlInfoMaxTotalImbalanceList() public view returns(uint[] maxTotalImbalanceValues) {
        maxTotalImbalanceValues = tokenInfoMaxTotalImbalance;
    }
}