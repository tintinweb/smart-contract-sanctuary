// SPDX-License-Identifier: MIT

pragma solidity 0.7.3;

interface IL1StandardBridge {
function depositETHTo(
        address _to,
        uint32 _l2Gas,
        bytes calldata _data
    ) external payable;
}

contract TeleportrDeposit {
    address public owner;
    address public l2DepositorAddress;
    address public l1StandardBridge;
    uint256 public maxDepositAmount;
    uint256 public minDepositAmount;
    uint256 public maxBalance;
    bool public canReceiveDeposit;

    constructor(
        uint256 _maxDepositAmount,
        uint256 _minDepositAmount,
        uint256 _maxBalance,
        bool _canReceiveDeposit,
        address _l2DepositorAddress,
        address _l1StandardBridge
    ) {
        require(_maxDepositAmount > _minDepositAmount, "maxDeposit amount should be greater than minDeposit amount");
        owner = msg.sender;
        maxDepositAmount = _maxDepositAmount;
        minDepositAmount = _minDepositAmount;
        maxBalance = _maxBalance;
        canReceiveDeposit = _canReceiveDeposit;
        l2DepositorAddress = _l2DepositorAddress;
        l1StandardBridge = _l1StandardBridge;
        emit OwnerSet(address(0), msg.sender);
        emit MaxDepositAmountSet(0, _maxDepositAmount);
        emit MinDepositAmountSet(0, _minDepositAmount);
        emit MaxBalanceSet(0, _maxBalance);
        emit CanReceiveDepositSet(_canReceiveDeposit);
        emit l2DepositorAddressSet(address(0), _l2DepositorAddress);
        emit L1StandardBridgeSet(address(0), _l1StandardBridge);
    }

    // Bridge the ETH to Optimism
    function bridgeBalance(uint32 _l2Gas, bytes calldata _data) public {
        uint256 amount = address(this).balance;
        IL1StandardBridge(l1StandardBridge).depositETHTo(l2DepositorAddress, _l2Gas, _data);
        emit BalanceBridged(l2DepositorAddress, amount);
    }

    function _withdrawBalance(address payable _to) internal {
        uint256 amount = address(this).balance;
        _to.transfer(amount);
        emit BalanceWithdrawn(_to, amount);
    }

    // Send the contract balance to the owner
    function withdrawBalance() public isOwner {
        _withdrawBalance(payable(owner));
    }

    // Send the contract balance to a specified address
    function withdrawBalanceTo(address payable _to) public isOwner {
        require(_to != address(0), "Destination address cannot be null");
        _withdrawBalance(_to);
    }

    function destroy() public isOwner {
        emit Destructed(owner, address(this).balance);
        selfdestruct(payable(owner));
    }

    // Receive function which reverts if amount > maxDepositAmount or if amount < minDepositAmount and canReceiveDeposit = false
    receive() external payable isCorrectDepositAmount canReceive isLowerThanMaxBalance {
        emit EtherReceived(msg.sender, msg.value);
    }

    function setMaxAmount(uint256 _maxDepositAmount) public isOwner {
        require(_maxDepositAmount > minDepositAmount, "maxDeposit amount should be greater than minDeposit amount");
        emit MaxDepositAmountSet(maxDepositAmount, _maxDepositAmount);
        maxDepositAmount = _maxDepositAmount;
    }

    function setMinAmount(uint256 _minDepositAmount) public isOwner {
        require(maxDepositAmount > _minDepositAmount, "maxDeposit amount should be greater than minDeposit amount");
        emit MinDepositAmountSet(minDepositAmount, _minDepositAmount);
        minDepositAmount = _minDepositAmount;
    }

    function setOwner(address _newOwner) public isOwner {
        emit OwnerSet(owner, _newOwner);
        owner = _newOwner;
    }

    function setCanReceiveDeposit(bool _canReceiveDeposit) public isOwner {
        emit CanReceiveDepositSet(_canReceiveDeposit);
        canReceiveDeposit = _canReceiveDeposit;
    }

    function setMaxBalance(uint256 _maxBalance) public isOwner {
        emit MaxBalanceSet(maxBalance, _maxBalance);
        maxBalance = _maxBalance;
    }

    function setL2DepositorAddress(address _depositor) public isOwner {
        emit l2DepositorAddressSet(l2DepositorAddress, _depositor);
        l2DepositorAddress = _depositor;
    }

    function setL1StandardBridge(address _bridge) public isOwner {
        emit L1StandardBridgeSet(l1StandardBridge, _bridge);
        l1StandardBridge = _bridge;
    }

    modifier isCorrectDepositAmount() {
        require(msg.value <= maxDepositAmount && msg.value >= minDepositAmount, "Wrong deposit amount");
        _;
    }

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    modifier canReceive() {
        require(canReceiveDeposit == true, "Contract is not allowed to receive ether");
        _;
    }

    modifier isLowerThanMaxBalance() {
        require(address(this).balance <= maxBalance, "Contract reached the max balance allowed");
        _;
    }

    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    event MaxDepositAmountSet(uint256 previousAmount, uint256 newAmount);
    event MinDepositAmountSet(uint256 previousAmount, uint256 newAmount);
    event CanReceiveDepositSet(bool canReceiveDeposit);
    event MaxBalanceSet(uint256 previousBalance, uint256 newBalance);
    event BalanceWithdrawn(address indexed to, uint256 balance);
    event EtherReceived(address indexed emitter, uint256 amount);
    event BalanceBridged(address indexed to, uint256 amount);
    event Destructed(address indexed owner, uint256 amount);
    event l2DepositorAddressSet(address previousAddress, address newAddress);
    event L1StandardBridgeSet(address previousAddress, address newAddress);
}