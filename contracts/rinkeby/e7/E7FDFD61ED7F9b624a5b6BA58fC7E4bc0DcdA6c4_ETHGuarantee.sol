/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
    constructor () {
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


struct GuarantorInfo {
    string name;
    string telegramId;
    string description;
    uint256 collateral;
    uint256 processingGuaranteeAmount;
}

abstract contract Guarantor is Pausable {
    address public admin;

    enum GuarantorState {notLocked, locked}

    uint256 public guarantorIndex;
    address[] public guarantors;
    mapping(address => uint256) public guarantorIndexOfOwner;
    mapping(uint256 => GuarantorState) public guarantorStates;
    mapping(uint256 => GuarantorInfo) public guarantorInfos;

    constructor() {
        admin = msg.sender;
        guarantors.push(address(0));
        guarantorIndex = 1;
    }

    modifier onlyAdmin(){
        require(msg.sender == admin, "only admin");
        _;
    }

    modifier onlyGuarantorSelf(uint256 _guarantorIndex){
        require(guarantors[_guarantorIndex] == msg.sender, "msg.sender should be the guarantor of guarantorIndex");
        _;
    }

    modifier onlyNotProcessingGuaranteeAmount(uint256 _guarantorIndex){
        require(guarantorInfos[_guarantorIndex].processingGuaranteeAmount == 0, "Only not processing guarantee amount");
        _;
    }
    
    modifier onlyNotRegistered(){
        require(guarantorIndexOfOwner[msg.sender] == 0, "The address of msg.sender is already registered");
        _;
    }

    modifier onlyLocked(uint256 _guarantorIndex){
        require(guarantorStates[_guarantorIndex] == GuarantorState.locked, "The state of guarantor is not locked");
        _;
    }

    modifier onlyNotLocked(uint256 _guarantorIndex){
        require(guarantorStates[_guarantorIndex] == GuarantorState.notLocked, "The state of guarantor is locked");
        _;
    }


    event GuarantorRegister(uint256 indexed guarantorIndex, address guarantor);
    event GuarantorDeposit(uint256 indexed guarantorIndex, address from, uint256 amount);
    event GuarantorWithdraw(uint256 indexed guarantorIndex, address to, uint256 amount);

    // admin 
    event LockGuarantor(uint256 indexed guarantorIndex);
    event UnlockGuarantor(uint256 indexed guarantorIndex);
    event InterveneCollateral(uint256 indexed guarantorIndex, address to, uint256 amount);


    function _processDeposit(uint256 amount) internal virtual;
    function _processWithdraw(address to, uint256 amount) internal virtual;

    function guarantorRegister(uint256 _collateralAmount, string calldata _name, string calldata _telegramId, string calldata _description) external payable whenNotPaused onlyNotRegistered {
        require(_collateralAmount > 0, "Registering amount should not be zero");

        _processDeposit(_collateralAmount);

        guarantors.push(msg.sender);
        guarantorIndexOfOwner[msg.sender] = guarantorIndex;
        guarantorStates[guarantorIndex] = GuarantorState.notLocked;
        
        GuarantorInfo memory newGuarantorInfo = GuarantorInfo({
            name: _name, 
            telegramId: _telegramId, 
            description: _description,
            collateral: _collateralAmount,
            processingGuaranteeAmount: 0
        });

        guarantorInfos[guarantorIndex] = newGuarantorInfo;

        emit GuarantorRegister(guarantorIndex, msg.sender);
        emit GuarantorDeposit(guarantorIndex, msg.sender, _collateralAmount);

        guarantorIndex++;
    }

    function updateInfo(uint256 _guarantorIndex, string calldata _name, string calldata _telegramId, string calldata _description) external whenNotPaused onlyGuarantorSelf(_guarantorIndex) onlyNotLocked(_guarantorIndex) {
        guarantorInfos[_guarantorIndex].name = _name;
        guarantorInfos[_guarantorIndex].telegramId = _telegramId;
        guarantorInfos[_guarantorIndex].description = _description;
    }

    function guarantorDeposit(uint256 _guarantorIndex, uint256 _amount) external payable whenNotPaused {
        _processDeposit(_amount);
        
        guarantorInfos[_guarantorIndex].collateral += _amount;

        emit GuarantorDeposit(_guarantorIndex, msg.sender, _amount);
    }

    function guarantorWithdraw(
        uint256 _guarantorIndex, 
        address _to, 
        uint256 _amount
    ) external whenNotPaused onlyGuarantorSelf(_guarantorIndex) onlyNotProcessingGuaranteeAmount(_guarantorIndex) onlyNotLocked(_guarantorIndex) {
        require(guarantorInfos[_guarantorIndex].collateral >= _amount, "Withdraw amount should be less than guarantor's fund.");

        _processWithdraw(_to, _amount);
        
        guarantorInfos[_guarantorIndex].collateral -= _amount;

        emit GuarantorWithdraw(_guarantorIndex, _to, _amount);
    }


    function lockGuarantor(uint256 _guarantorIndex) external onlyAdmin {
        guarantorStates[_guarantorIndex] = GuarantorState.locked;

        emit LockGuarantor(_guarantorIndex);
    }

    function unlockGuarantor(uint256 _guarantorIndex) external onlyAdmin {
        guarantorStates[_guarantorIndex] = GuarantorState.notLocked;

        emit UnlockGuarantor(_guarantorIndex);
    }

    function collateralIntervene(uint256 _guarantorIndex, address _to, uint256 _amount) external onlyAdmin onlyLocked(_guarantorIndex) {
        require(guarantorInfos[_guarantorIndex].collateral >= _amount, "Withdraw amount should be less than guarantor's fund.");

        _processWithdraw(_to, _amount);
        
        guarantorInfos[_guarantorIndex].collateral -= _amount;

        emit InterveneCollateral(_guarantorIndex, _to, _amount);
    }

    function changeAdmin(address nextAdmin) external onlyAdmin {
        admin = nextAdmin;
    }
    
    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }
}

struct GuaranteeInfo {
    uint256 guarantorIndex;
    address demandA;
    address demandB;
    uint256 fund;
    uint32 feePercentLimit;
    string content;
}

abstract contract Guarantee is Guarantor {
    uint256 public guaranteeIndex;
    GuaranteeInfo[] public guarantees;

    constructor() Guarantor() {
        guaranteeIndex = 1;
        guarantees.push(GuaranteeInfo({
            guarantorIndex: 0, 
            demandA: address(0),
            demandB: address(0),
            fund: 0,
            feePercentLimit: 0,
            content: ""
        }));
    }
    
    event GuaranteeRegister(uint256 indexed guaranteeIndex, uint256 guarantorIndex, address demandA, address demandB, uint32 feePercentLimit, string content);
    event GuaranteeDeposit(uint256 indexed guaranteeIndex, address from, uint256 amount);
    event GuaranteeWithdraw(uint256 indexed guaranteeIndex, uint256 amountToA, uint256 amountToB, uint32 feePercent, string info);
    event InterveneGuarantee(uint256 indexed guaranteeIndex, uint256 amountToA, uint256 amountToB, uint32 feePercent, string info);

    function guaranteeRegister(
        uint256 _guarantorIndex, 
        address _demandA,
        address _demandB, 
        uint32 _feePercentLimit, 
        string calldata _content
    ) external payable whenNotPaused onlyGuarantorSelf(_guarantorIndex) onlyNotLocked(_guarantorIndex) {
        require(_feePercentLimit > 0 && _feePercentLimit < 100, "Invalid fee percent limit");

        guarantees.push(GuaranteeInfo({
            guarantorIndex: _guarantorIndex, 
            demandA: _demandA,
            demandB: _demandB,
            fund: 0,
            feePercentLimit: _feePercentLimit,
            content: _content
        }));

        emit GuaranteeRegister(guaranteeIndex, _guarantorIndex, _demandA, _demandB, _feePercentLimit, _content);

        guaranteeIndex++;
    }

    function guaranteeDeposit(uint256 _guaranteeIndex, uint256 _amount) external payable whenNotPaused {
        require(_guaranteeIndex < guaranteeIndex, "Invalid guarantee index");

        guarantees[_guaranteeIndex].fund += _amount;
        guarantorInfos[guarantees[_guaranteeIndex].guarantorIndex].processingGuaranteeAmount += _amount;

        _processDeposit(_amount);
        
        emit GuaranteeDeposit(_guaranteeIndex, msg.sender, _amount);
    }

    function guaranteeWithdraw(
        uint256 _guaranteeIndex,
        uint256 _guarantorIndex,
        uint256 _amountToA,
        uint256 _amountToB,
        uint32 _feePercent,
        string calldata _info
    ) external whenNotPaused onlyGuarantorSelf(_guarantorIndex) onlyNotLocked(_guarantorIndex) {
        require(guarantees[_guaranteeIndex].guarantorIndex == _guarantorIndex, "Invalid guarantor index");
        require(_amountToA + _amountToB <= guarantees[_guaranteeIndex].fund, "Insufficient fund");
        require(_feePercent <= guarantees[_guaranteeIndex].feePercentLimit, "Invalid fee percent");


        uint256 processingAmount = _amountToA + _amountToB;
        guarantees[_guaranteeIndex].fund -= processingAmount;

        uint256 feeA = _amountToA  * uint256(_feePercent) / 100;
        uint256 feeB = _amountToB  * uint256(_feePercent) / 100;   

        guarantorInfos[_guarantorIndex].processingGuaranteeAmount -= processingAmount;

        _processWithdraw(guarantees[_guaranteeIndex].demandA, _amountToA - feeA);
        _processWithdraw(guarantees[_guaranteeIndex].demandB, _amountToB - feeB);
        _processWithdraw(msg.sender, feeA + feeB);

        emit GuaranteeWithdraw(_guaranteeIndex, _amountToA, _amountToB, _feePercent, _info);
    }

    function interveneGuarantee(
        uint256 _guaranteeIndex,
        uint256 _amountToA,
        uint256 _amountToB,
        uint32 _feePercent,
        string calldata _info
    ) external onlyAdmin {
        require(_guaranteeIndex < guaranteeIndex, "Invalid guarantee index");
        require(_amountToA + _amountToB <= guarantees[_guaranteeIndex].fund, "Insufficient fund");
        require(_feePercent <= guarantees[_guaranteeIndex].feePercentLimit, "Invalid fee percent");

        uint256 processingAmount = _amountToA + _amountToB;
        guarantees[_guaranteeIndex].fund -= processingAmount;

        uint256 feeA = _amountToA  * uint256(_feePercent) / 100;
        uint256 feeB = _amountToB  * uint256(_feePercent) / 100;
        
        guarantorInfos[guarantees[_guaranteeIndex].guarantorIndex].processingGuaranteeAmount -= processingAmount;

        _processWithdraw(guarantees[_guaranteeIndex].demandA, _amountToA - feeA);
        _processWithdraw(guarantees[_guaranteeIndex].demandB, _amountToB - feeB);
        _processWithdraw(msg.sender, feeA + feeB);

        emit InterveneGuarantee(_guaranteeIndex, _amountToA, _amountToB, _feePercent, _info);
    }

    function guaranteeIndexesOfDemand(address _demand) external view returns(uint256[] memory guaranteeIndexes) {
        uint256 guaranteeCount = 0;
        for(uint256 _guaranteeIndex = 1; _guaranteeIndex < guaranteeIndex; _guaranteeIndex++) {
            if(guarantees[_guaranteeIndex].demandA == _demand || guarantees[_guaranteeIndex].demandB == _demand){
                guaranteeCount++;
            }
        }
        uint256[] memory result = new uint256[](guaranteeCount);
        guaranteeCount = 0;
        for(uint256 _guaranteeIndex = 1; _guaranteeIndex < guaranteeIndex; _guaranteeIndex++) {
            if(guarantees[_guaranteeIndex].demandA == _demand || guarantees[_guaranteeIndex].demandB == _demand){
                result[guaranteeCount++] = _guaranteeIndex;
            }
        }
        return result;
    }

    function guaranteeIndexesOfGuarantor(uint256 _guarantorIndex) external view returns(uint256[] memory guaranteeIndexes) {
        uint256 guaranteeCount = 0;
        for(uint256 _guaranteeIndex = 1; _guaranteeIndex < guaranteeIndex; _guaranteeIndex++) {
            if(guarantees[_guaranteeIndex].guarantorIndex == _guarantorIndex){
                guaranteeCount++;
            }
        }
        uint256[] memory result = new uint256[](guaranteeCount);
        guaranteeCount = 0;
        for(uint256 _guaranteeIndex = 1; _guaranteeIndex < guaranteeIndex; _guaranteeIndex++) {
            if(guarantees[_guaranteeIndex].guarantorIndex == _guarantorIndex){
                result[guaranteeCount++] = _guaranteeIndex;
            }
        }
        return result;
    }
}

contract ETHGuarantee is Guarantee {
    constructor() Guarantee() {
    }

    function _processDeposit(uint256 amount) internal override {
        require(msg.value == amount, "Please send correct denomination ETH along with transaction");
    }

    function _processWithdraw(address to, uint256 amount) internal override {
        payable(to).transfer(amount);
    }
}