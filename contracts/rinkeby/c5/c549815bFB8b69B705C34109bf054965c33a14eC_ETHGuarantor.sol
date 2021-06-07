/**
 *Submitted for verification at Etherscan.io on 2021-06-06
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
}


abstract contract Guarantor is Pausable {
    address public admin; 

    enum GuarantorState {notLocked, locked}

    uint256 public guarantorIndex;
    address[] public guarantors;
    mapping(address => bool) public registered;
    mapping(uint256 => GuarantorState) public guarantorStates;
    mapping(uint256 => GuarantorInfo) public guarantorInfos;

    constructor() {
        admin = msg.sender;
        guarantors.push(address(0));
        guarantorIndex = 1;
    }

    modifier onlyAdmin(){
        require(msg.sender == admin, "msg.sender should be admin");
        _;
    }

    modifier onlyGuarantorSelf(uint256 _guarantorIndex){
        require(guarantors[_guarantorIndex] == msg.sender, "msg.sender should be the guarantor of guarantorIndex");
        _;
    }
    
    modifier onlyNotRegistered(){
        require(registered[msg.sender] == false, "The address of msg.sender is already registered");
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

    event Register(uint256 indexed guarantorIndex, address guarantor);
    event Deposit(uint256 indexed guarantorIndex, address from, uint256 amount);
    event Withdraw(uint256 indexed guarantorIndex, address to, uint256 amount);

    // admin 
    event Lock(uint256 indexed guarantorIndex);
    event Unlock(uint256 indexed guarantorIndex);
    event Intervene(uint256 indexed guarantorIndex, address to, uint256 amount);


    function _processDeposit(uint256 amount) internal virtual;
    function _processWithdraw(address to, uint256 amount) internal virtual;

    function register(uint256 _collateralAmount, string calldata _name, string calldata _telegramId, string calldata _description) external payable whenNotPaused onlyNotRegistered {
        require(_collateralAmount > 0, "Registering amount should not be zero");

        _processDeposit(_collateralAmount);

        guarantors.push(msg.sender);
        registered[msg.sender] = true;
        guarantorStates[guarantorIndex] = GuarantorState.notLocked;
        
        GuarantorInfo memory newGuarantorInfo = GuarantorInfo({
            name: _name, 
            telegramId: _telegramId, 
            description: _description,
            collateral: _collateralAmount
        });

        guarantorInfos[guarantorIndex] = newGuarantorInfo;

        emit Register(guarantorIndex, msg.sender);
        emit Deposit(guarantorIndex, msg.sender, _collateralAmount);

        guarantorIndex++;
    }

    function updateInfo(uint256 _guarantorIndex, string calldata _name, string calldata _telegramId, string calldata _description) external whenNotPaused onlyGuarantorSelf(_guarantorIndex) onlyNotLocked(_guarantorIndex) {
        guarantorInfos[_guarantorIndex].name = _name;
        guarantorInfos[_guarantorIndex].telegramId = _telegramId;
        guarantorInfos[_guarantorIndex].description = _description;
    }

    function deposit(uint256 _guarantorIndex, uint256 _amount) external payable whenNotPaused {
        _processDeposit(_amount);
        
        guarantorInfos[_guarantorIndex].collateral += _amount;

        emit Deposit(_guarantorIndex, msg.sender, _amount);
    }

    function withdraw(uint256 _guarantorIndex, address _to, uint256 _amount) external whenNotPaused onlyGuarantorSelf(_guarantorIndex) onlyNotLocked(_guarantorIndex) {
        require(guarantorInfos[_guarantorIndex].collateral >= _amount, "Withdraw amount should be less than guarantor's fund.");

        _processWithdraw(_to, _amount);
        
        guarantorInfos[_guarantorIndex].collateral -= _amount;

        emit Withdraw(_guarantorIndex, _to, _amount);
    }

    function lock(uint256 _guarantorIndex) external onlyAdmin {
        guarantorStates[_guarantorIndex] = GuarantorState.locked;

        emit Lock(_guarantorIndex);
    }

    function unlock(uint256 _guarantorIndex) external onlyAdmin {
        guarantorStates[_guarantorIndex] = GuarantorState.notLocked;

        emit Unlock(_guarantorIndex);
    }

    function intervene(uint256 _guarantorIndex, address _to, uint256 _amount) external onlyAdmin onlyLocked(_guarantorIndex) {
        require(guarantorInfos[_guarantorIndex].collateral >= _amount, "Withdraw amount should be less than guarantor's fund.");

        _processWithdraw(_to, _amount);
        
        guarantorInfos[_guarantorIndex].collateral -= _amount;

        emit Intervene(_guarantorIndex, _to, _amount);
    }

    function changeAdmin(address nextAdmin) external onlyAdmin {
        admin = nextAdmin;
    }

    function guarantorIndexOfOwner(address _owner) external view returns(uint256 _guarantorIndex) {
        for(_guarantorIndex = 1; _guarantorIndex < guarantorIndex; _guarantorIndex++) {
            if(guarantors[_guarantorIndex] == _owner) {
                return _guarantorIndex;
            }
        }
        return 0;
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }
}

contract ETHGuarantor is Guarantor {
    constructor() Guarantor() {
    }

    function _processDeposit(uint256 amount) internal override {
        require(msg.value == amount, "Please send correct denomination ETH along with transaction");
    }

    function _processWithdraw(address to, uint256 amount) internal override {
        payable(to).transfer(amount);
    }
}