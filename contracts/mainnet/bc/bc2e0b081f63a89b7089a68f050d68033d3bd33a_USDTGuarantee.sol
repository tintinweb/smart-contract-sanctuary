/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

pragma solidity ^0.8.0;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }


    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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


library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { 
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

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


    event GuarantorRegister(uint256 indexed guarantorIndex, address guarantor, uint256 timestamp);
    event GuarantorDeposit(uint256 indexed guarantorIndex, address from, uint256 amount, uint256 timestamp);
    event GuarantorWithdraw(uint256 indexed guarantorIndex, address to, uint256 amount, uint256 timestamp);

    // admin 
    event LockGuarantor(uint256 indexed guarantorIndex, uint256 timestamp);
    event UnlockGuarantor(uint256 indexed guarantorIndex, uint256 timestamp);
    event InterveneCollateral(uint256 indexed guarantorIndex, address to, uint256 amount, uint256 timestamp);


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

        emit GuarantorRegister(guarantorIndex, msg.sender, block.timestamp);
        emit GuarantorDeposit(guarantorIndex, msg.sender, _collateralAmount, block.timestamp);

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

        emit GuarantorDeposit(_guarantorIndex, msg.sender, _amount, block.timestamp);
    }

    function guarantorWithdraw(
        uint256 _guarantorIndex, 
        address _to, 
        uint256 _amount
    ) external whenNotPaused onlyGuarantorSelf(_guarantorIndex) onlyNotProcessingGuaranteeAmount(_guarantorIndex) onlyNotLocked(_guarantorIndex) {
        require(guarantorInfos[_guarantorIndex].collateral >= _amount, "Withdraw amount should be less than guarantor's fund.");

        _processWithdraw(_to, _amount);
        
        guarantorInfos[_guarantorIndex].collateral -= _amount;

        emit GuarantorWithdraw(_guarantorIndex, _to, _amount, block.timestamp);
    }


    function lockGuarantor(uint256 _guarantorIndex) external onlyAdmin {
        guarantorStates[_guarantorIndex] = GuarantorState.locked;

        emit LockGuarantor(_guarantorIndex, block.timestamp);
    }

    function unlockGuarantor(uint256 _guarantorIndex) external onlyAdmin {
        guarantorStates[_guarantorIndex] = GuarantorState.notLocked;

        emit UnlockGuarantor(_guarantorIndex, block.timestamp);
    }

    function collateralIntervene(uint256 _guarantorIndex, address _to, uint256 _amount) external onlyAdmin onlyLocked(_guarantorIndex) {
        require(guarantorInfos[_guarantorIndex].collateral >= _amount, "Withdraw amount should be less than guarantor's fund.");

        _processWithdraw(_to, _amount);
        
        guarantorInfos[_guarantorIndex].collateral -= _amount;

        emit InterveneCollateral(_guarantorIndex, _to, _amount, block.timestamp);
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
    
    event GuaranteeRegister(uint256 indexed guaranteeIndex, uint256 guarantorIndex, address demandA, address demandB, uint32 feePercentLimit, string content, uint256 timestamp);
    event GuaranteeDeposit(uint256 indexed guaranteeIndex, address from, uint256 amount, uint256 timestamp);
    event GuaranteeWithdraw(uint256 indexed guaranteeIndex, uint256 amountToA, uint256 amountToB, uint32 feePercent, string info, uint256 timestamp);
    event InterveneGuarantee(uint256 indexed guaranteeIndex, uint256 amountToA, uint256 amountToB, uint32 feePercent, string info, uint256 timestamp);

    function guaranteeRegister(
        uint256 _guarantorIndex, 
        address _demandA,
        address _demandB, 
        uint32 _feePercentLimit, 
        string calldata _content
    ) external whenNotPaused onlyGuarantorSelf(_guarantorIndex) onlyNotLocked(_guarantorIndex) {
        require(_feePercentLimit > 0 && _feePercentLimit < 100, "Invalid fee percent limit");

        guarantees.push(GuaranteeInfo({
            guarantorIndex: _guarantorIndex, 
            demandA: _demandA,
            demandB: _demandB,
            fund: 0,
            feePercentLimit: _feePercentLimit,
            content: _content
        }));

        emit GuaranteeRegister(guaranteeIndex, _guarantorIndex, _demandA, _demandB, _feePercentLimit, _content, block.timestamp);

        guaranteeIndex++;
    }

    function guaranteeDeposit(uint256 _guaranteeIndex, uint256 _amount) external payable whenNotPaused {
        require(_guaranteeIndex < guaranteeIndex, "Invalid guarantee index");

        guarantees[_guaranteeIndex].fund += _amount;
        guarantorInfos[guarantees[_guaranteeIndex].guarantorIndex].processingGuaranteeAmount += _amount;

        _processDeposit(_amount);
        
        emit GuaranteeDeposit(_guaranteeIndex, msg.sender, _amount, block.timestamp);
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

        emit GuaranteeWithdraw(_guaranteeIndex, _amountToA, _amountToB, _feePercent, _info, block.timestamp);
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

        emit InterveneGuarantee(_guaranteeIndex, _amountToA, _amountToB, _feePercent, _info, block.timestamp);
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

contract USDTGuarantee is Guarantee {
    using SafeERC20 for IERC20;
    IERC20 public token;

    constructor() Guarantee() {
        token = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    }

    function _processDeposit(uint256 amount) internal override {
        require(msg.value == 0, "ETH value is supposed to be 0 for ERC20 instance");
        token.safeTransferFrom(msg.sender, address(this), amount);
    }

    function _processWithdraw(address to, uint256 amount) internal override {
        token.safeTransfer(to, amount);
    }
}