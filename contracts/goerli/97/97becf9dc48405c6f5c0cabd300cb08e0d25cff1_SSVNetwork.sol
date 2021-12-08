// File: contracts/SSVNetwork.sol
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.2;

import "./ISSVNetwork.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract SSVNetwork is Initializable, OwnableUpgradeable, ISSVNetwork {
    struct OperatorData {
        uint256 blockNumber;
        uint256 activeValidatorCount;
        uint256 earnings;
        uint256 index;
        uint256 indexBlockNumber;
        uint256 lastFeeUpdate;
    }

    struct OwnerData {
        uint256 deposited;
        uint256 withdrawn;
        uint256 earned;
        uint256 used;
        uint256 networkFee;
        uint256 networkFeeIndex;
        uint256 activeValidatorCount;
        bool validatorsDisabled;
    }

    struct OperatorInUse {
        uint256 index;
        uint256 validatorCount;
        uint256 used;
        bool exists;
        uint256 indexInArray;
    }

    ISSVRegistry private _ssvRegistryContract;
    IERC20 private _token;
    uint256 private _minimumBlocksBeforeLiquidation;
    uint256 private _operatorMaxFeeIncrease;

    uint256 private _networkFee;
    uint256 private _networkFeeIndex;
    uint256 private _networkFeeIndexBlockNumber;
    uint256 private _networkEarnings;
    uint256 private _networkEarningsBlockNumber;
    uint256 private _withdrawnFromTreasury;

    mapping(bytes => OperatorData) private _operatorDatas;
    mapping(address => OwnerData) private _owners;
    mapping(address => mapping(bytes => OperatorInUse)) private _operatorsInUseByAddress;
    mapping(address => bytes[]) private _operatorsInUseList;
    mapping(bytes => uint256) private _lastOperatorUpdateNetworkFeeRun;

    function initialize(
        ISSVRegistry registryAddress,
        IERC20 token,
        uint256 minimumBlocksBeforeLiquidation,
        uint256 operatorMaxFeeIncrease
    ) external initializer override {
        __SSVNetwork_init(registryAddress, token, minimumBlocksBeforeLiquidation, operatorMaxFeeIncrease);
    }

    function __SSVNetwork_init(
        ISSVRegistry registryAddress,
        IERC20 token,
        uint256 minimumBlocksBeforeLiquidation,
        uint256 operatorMaxFeeIncrease
    ) internal initializer {
        __Ownable_init_unchained();
        __SSVNetwork_init_unchained(registryAddress, token, minimumBlocksBeforeLiquidation, operatorMaxFeeIncrease);
    }

    function __SSVNetwork_init_unchained(
        ISSVRegistry registryAddress,
        IERC20 token,
        uint256 minimumBlocksBeforeLiquidation,
        uint256 operatorMaxFeeIncrease
    ) internal initializer {
        _ssvRegistryContract = registryAddress;
        _token = token;
        _minimumBlocksBeforeLiquidation = minimumBlocksBeforeLiquidation;
        _operatorMaxFeeIncrease = operatorMaxFeeIncrease;
        _ssvRegistryContract.initialize();
    }

    modifier onlyValidatorOwner(bytes calldata publicKey) {
        address owner = _ssvRegistryContract.getValidatorOwner(publicKey);
        require(
            owner != address(0),
            "validator with public key does not exist"
        );
        require(msg.sender == owner, "caller is not validator owner");
        _;
    }

    modifier onlyOperatorOwner(bytes calldata publicKey) {
        address owner = _ssvRegistryContract.getOperatorOwner(publicKey);
        require(
            owner != address(0),
            "operator with public key does not exist"
        );
        require(msg.sender == owner, "caller is not operator owner");
        _;
    }

    /**
     * @dev See {ISSVNetwork-registerOperator}.
     */
    function registerOperator(
        string calldata name,
        bytes calldata publicKey,
        uint256 fee
    ) external override {
        _ssvRegistryContract.registerOperator(
            name,
            msg.sender,
            publicKey,
            fee
        );

        _operatorDatas[publicKey] = OperatorData(block.number, 0, 0, 0, block.number, block.timestamp);

        emit OperatorAdded(name, msg.sender, publicKey);
    }

    /**
     * @dev See {ISSVNetwork-deleteOperator}.
     */
    function deleteOperator(bytes calldata publicKey) onlyOperatorOwner(publicKey) external override {
        require(_operatorDatas[publicKey].activeValidatorCount == 0, "operator has validators");
        address owner = _ssvRegistryContract.getOperatorOwner(publicKey);
        _owners[owner].earned += _operatorDatas[publicKey].earnings;
        delete _operatorDatas[publicKey];
        _ssvRegistryContract.deleteOperator(publicKey);

        emit OperatorDeleted(owner, publicKey);
    }

    function activateOperator(bytes calldata publicKey) onlyOperatorOwner(publicKey) external override {
        _ssvRegistryContract.activateOperator(publicKey);
        _updateAddressNetworkFee(msg.sender);

        emit OperatorActivated(msg.sender, publicKey);
    }

    function deactivateOperator(bytes calldata publicKey) onlyOperatorOwner(publicKey) external override {
        require(_operatorDatas[publicKey].activeValidatorCount == 0, "operator has validators");

        _ssvRegistryContract.deactivateOperator(publicKey);

        emit OperatorDeactivated(msg.sender, publicKey);
    }

    function updateOperatorFee(bytes calldata publicKey, uint256 fee) onlyOperatorOwner(publicKey) external override {
        require(block.timestamp - _operatorDatas[publicKey].lastFeeUpdate > 72 hours , "fee updated in last 72 hours");
        require(fee <= _ssvRegistryContract.getOperatorCurrentFee(publicKey) * (100 + _operatorMaxFeeIncrease) / 100, "fee exceeds increase limit");
        _updateOperatorIndex(publicKey);
        _operatorDatas[publicKey].indexBlockNumber = block.number;
        _updateOperatorBalance(publicKey);
        _ssvRegistryContract.updateOperatorFee(publicKey, fee);
        _operatorDatas[publicKey].lastFeeUpdate = block.timestamp;

        emit OperatorFeeUpdated(msg.sender, publicKey, block.number, fee);
    }

    function updateOperatorScore(bytes calldata publicKey, uint256 score) onlyOwner external override {
        _ssvRegistryContract.updateOperatorScore(publicKey, score);

        emit OperatorScoreUpdated(msg.sender, publicKey, block.number, score);
    }

    /**
     * @dev See {ISSVNetwork-registerValidator}.
     */
    function registerValidator(
        bytes calldata publicKey,
        bytes[] calldata operatorPublicKeys,
        bytes[] calldata sharesPublicKeys,
        bytes[] calldata encryptedKeys,
        uint256 tokenAmount
    ) external override {
        _updateNetworkEarnings();

        _ssvRegistryContract.registerValidator(
            msg.sender,
            publicKey,
            operatorPublicKeys,
            sharesPublicKeys,
            encryptedKeys
        );

        _updateAddressNetworkFee(msg.sender);

        if (!_owners[msg.sender].validatorsDisabled) {
            ++_owners[msg.sender].activeValidatorCount;
        }

        for (uint256 index = 0; index < operatorPublicKeys.length; ++index) {
            bytes calldata operatorPublicKey = operatorPublicKeys[index];
            _updateOperatorBalance(operatorPublicKey);

            if (!_owners[msg.sender].validatorsDisabled) {
                ++_operatorDatas[operatorPublicKey].activeValidatorCount;
            }

            _useOperatorByOwner(msg.sender, operatorPublicKey);
        }

        if (tokenAmount > 0) {
            _deposit(tokenAmount);
        }

        require(!_liquidatable(msg.sender), "not enough balance");

        emit ValidatorAdded(msg.sender, publicKey, operatorPublicKeys, sharesPublicKeys, encryptedKeys);
    }

    /**
     * @dev See {ISSVNetwork-updateValidator}.
     */
    function updateValidator(
        bytes calldata publicKey,
        bytes[] calldata operatorPublicKeys,
        bytes[] calldata sharesPublicKeys,
        bytes[] calldata encryptedKeys,
        uint256 tokenAmount
    ) onlyValidatorOwner(publicKey) external override {
        bytes[] memory currentOperatorPublicKeys = _ssvRegistryContract.getOperatorsByValidator(publicKey);
        address owner = _ssvRegistryContract.getValidatorOwner(publicKey);
        // calculate balances for current operators in use
        for (uint256 index = 0; index < currentOperatorPublicKeys.length; ++index) {
            bytes memory operatorPublicKey = currentOperatorPublicKeys[index];
            _updateOperatorBalance(operatorPublicKey);

            if (!_owners[msg.sender].validatorsDisabled) {
                --_operatorDatas[operatorPublicKey].activeValidatorCount;
            }

            _stopUsingOperatorByOwner(owner, operatorPublicKey);
        }

        // calculate balances for new operators in use
        for (uint256 index = 0; index < operatorPublicKeys.length; ++index) {
            bytes memory operatorPublicKey = operatorPublicKeys[index];
            _updateOperatorBalance(operatorPublicKey);

            if (!_owners[msg.sender].validatorsDisabled) {
                ++_operatorDatas[operatorPublicKey].activeValidatorCount;
            }

            _useOperatorByOwner(owner, operatorPublicKey);
        }

        _ssvRegistryContract.updateValidator(
            publicKey,
            operatorPublicKeys,
            sharesPublicKeys,
            encryptedKeys
        );

        if (tokenAmount > 0) {
            _deposit(tokenAmount);
        }

        require(!_liquidatable(msg.sender), "not enough balance");

        emit ValidatorUpdated(msg.sender, publicKey, operatorPublicKeys, sharesPublicKeys, encryptedKeys);
    }

    /**
     * @dev See {ISSVNetwork-deleteValidator}.
     */
    function deleteValidator(bytes calldata publicKey) onlyValidatorOwner(publicKey) external override {
        _updateNetworkEarnings();
        _unregisterValidator(publicKey);
        address owner = _ssvRegistryContract.getValidatorOwner(publicKey);
        _totalBalanceOf(owner); // For assertion
        _ssvRegistryContract.deleteValidator(publicKey);
        _updateAddressNetworkFee(msg.sender);

        if (!_owners[msg.sender].validatorsDisabled) {
            --_owners[msg.sender].activeValidatorCount;
        }

        emit ValidatorDeleted(msg.sender, publicKey);
    }

    function activateValidator(bytes calldata publicKey, uint256 tokenAmount) onlyValidatorOwner(publicKey) external override {
        _updateNetworkEarnings();
        address owner = _ssvRegistryContract.getValidatorOwner(publicKey);
        // calculate balances for current operators in use and update their balances
        bytes[] memory currentOperatorPublicKeys = _ssvRegistryContract.getOperatorsByValidator(publicKey);
        for (uint256 index = 0; index < currentOperatorPublicKeys.length; ++index) {
            bytes memory operatorPublicKey = currentOperatorPublicKeys[index];
            _updateOperatorBalance(operatorPublicKey);

            if (!_owners[msg.sender].validatorsDisabled) {
                ++_operatorDatas[operatorPublicKey].activeValidatorCount;
            }

            _useOperatorByOwner(owner, operatorPublicKey);
        }

        _ssvRegistryContract.activateValidator(publicKey);

        if (tokenAmount > 0) {
            _deposit(tokenAmount);
        }

        require(!_liquidatable(msg.sender), "not enough balance");

        emit ValidatorActivated(msg.sender, publicKey);
    }

    function deactivateValidator(bytes calldata publicKey) onlyValidatorOwner(publicKey) external override {
        _deactivateValidatorUnsafe(publicKey, msg.sender);

        emit ValidatorDeactivated(msg.sender, publicKey);
    }

    function deposit(uint256 tokenAmount) external override {
        _deposit(tokenAmount);
    }

    function withdraw(uint256 tokenAmount) external override {
        require(_totalBalanceOf(msg.sender) >= tokenAmount, "not enough balance");

        _withdrawUnsafe(tokenAmount);

        require(!_liquidatable(msg.sender), "not enough balance");
    }

    function withdrawAll() external override {
        if (_burnRate(msg.sender) > 0) {
            _disableOwnerValidatorsUnsafe(msg.sender);
        }

        _withdrawUnsafe(_totalBalanceOf(msg.sender));
    }

    function liquidate(address ownerAddress) external override {
        require(_liquidatable(ownerAddress), "owner is not liquidatable");

        _liquidateUnsafe(ownerAddress);
    }

    function liquidateAll(address[] calldata ownerAddresses) external override {
        for (uint256 index = 0; index < ownerAddresses.length; ++index) {
            if (_liquidatable(ownerAddresses[index])) {
                _liquidateUnsafe(ownerAddresses[index]);
            }
        }
    }

    function enableAccount(uint256 tokenAmount) external override {
        require(_owners[msg.sender].validatorsDisabled, "account already enabled");

        _deposit(tokenAmount);

        _enableOwnerValidatorsUnsafe(msg.sender);

        require(!_liquidatable(msg.sender), "not enough balance");
    }

    function updateMinimumBlocksBeforeLiquidation(uint256 minimumBlocksBeforeLiquidation) external onlyOwner override {
        _minimumBlocksBeforeLiquidation = minimumBlocksBeforeLiquidation;
    }

    function updateOperatorMaxFeeIncrease(uint256 operatorMaxFeeIncrease) external onlyOwner override {
        _operatorMaxFeeIncrease = operatorMaxFeeIncrease;
    }

    /**
     * @dev See {ISSVNetwork-updateNetworkFee}.
     */
    function updateNetworkFee(uint256 fee) external onlyOwner override {
        emit NetworkFeeUpdated(_networkFee, fee);
        _updateNetworkEarnings();
        _updateNetworkFeeIndex();
        _networkFee = fee;
    }

    function withdrawNetworkFees(uint256 amount) external onlyOwner override {
        require(amount <= _getNetworkTreasury(), "not enough balance");
        _withdrawnFromTreasury += amount;
        _token.transfer(msg.sender, amount);

        emit NetworkFeesWithdrawn(amount, msg.sender);
    }

    function totalEarningsOf(address ownerAddress) external override view returns (uint256) {
        return _totalEarningsOf(ownerAddress);
    }

    function totalBalanceOf(address ownerAddress) external override view returns (uint256) {
        return _totalBalanceOf(ownerAddress);
    }

    function isOwnerValidatorsDisabled(address ownerAddress) external view override returns (bool) {
        return _owners[ownerAddress].validatorsDisabled;
    }

    /**
     * @dev See {ISSVNetwork-operators}.
     */
    function operators(bytes calldata publicKey) external view override returns (string memory, address, bytes memory, uint256, bool, uint256) {
        return _ssvRegistryContract.operators(publicKey);
    }

    /**
     * @dev See {ISSVNetwork-getOperatorCurrentFee}.
     */
    function getOperatorCurrentFee(bytes calldata operatorPublicKey) external view override returns (uint256) {
        return _ssvRegistryContract.getOperatorCurrentFee(operatorPublicKey);
    }

    /**
     * @dev See {ISSVNetwork-operatorEarningsOf}.
     */
    function operatorEarningsOf(bytes memory publicKey) external view override returns (uint256) {
        return _operatorEarningsOf(publicKey);
    }

    /**
     * @dev See {ISSVNetwork-getOperatorsByOwnerAddress}.
     */
    function getOperatorsByOwnerAddress(address ownerAddress) external view override returns (bytes[] memory) {
        return _ssvRegistryContract.getOperatorsByOwnerAddress(ownerAddress);
    }

    /**
     * @dev See {ISSVNetwork-getOperatorsByValidator}.
     */
    function getOperatorsByValidator(bytes memory publicKey) external view override returns (bytes[] memory) {
        return _ssvRegistryContract.getOperatorsByValidator(publicKey);
    }

    /**
     * @dev See {ISSVNetwork-getValidatorsByAddress}.
     */
    function getValidatorsByOwnerAddress(address ownerAddress) external view override returns (bytes[] memory) {
        return _ssvRegistryContract.getValidatorsByAddress(ownerAddress);
    }

    /**
     * @dev See {ISSVNetwork-addressNetworkFee}.
     */
    function addressNetworkFee(address ownerAddress) external view override returns (uint256) {
        return _addressNetworkFee(ownerAddress);
    }


    function burnRate(address ownerAddress) external view override returns (uint256) {
        return _burnRate(ownerAddress);
    }

    function liquidatable(address ownerAddress) external view override returns (bool) {
        return _liquidatable(ownerAddress);
    }

    function networkFee() external view override returns (uint256) {
        return _networkFee;
    }

    function getNetworkTreasury() external view override returns (uint256) {
        return _getNetworkTreasury();
    }

    function minimumBlocksBeforeLiquidation() external view override returns (uint256) {
        return _minimumBlocksBeforeLiquidation;
    }

    function operatorMaxFeeIncrease() external view override returns (uint256) {
        return _operatorMaxFeeIncrease;
    }

    function _deposit(uint256 tokenAmount) private {
        _token.transferFrom(msg.sender, address(this), tokenAmount);
        _owners[msg.sender].deposited += tokenAmount;

        emit FundsDeposited(tokenAmount, msg.sender);
    }

    function _withdrawUnsafe(uint256 tokenAmount) private {
        _owners[msg.sender].withdrawn += tokenAmount;
        _token.transfer(msg.sender, tokenAmount);

        emit FundsWithdrawn(tokenAmount, msg.sender);
    }

    /**
     * @dev Update network fee for the address.
     * @param ownerAddress Owner address.
     */
    function _updateAddressNetworkFee(address ownerAddress) private {
        _owners[ownerAddress].networkFee = _addressNetworkFee(ownerAddress);
        _owners[ownerAddress].networkFeeIndex = _currentNetworkFeeIndex();
    }

    function _updateOperatorIndex(bytes calldata publicKey) private {
        _operatorDatas[publicKey].index = _operatorIndexOf(publicKey);
    }

    /**
     * @dev Updates operators's balance.
     * @param publicKey The operators's public key.
     */
    function _updateOperatorBalance(bytes memory publicKey) private {
        OperatorData storage operatorData = _operatorDatas[publicKey];
        operatorData.earnings = _operatorEarningsOf(publicKey);
        operatorData.blockNumber = block.number;
    }

    function _liquidateUnsafe(address ownerAddress) private {
        _disableOwnerValidatorsUnsafe(ownerAddress);

        uint256 balanceToTransfer = _totalBalanceOf(ownerAddress);

        _owners[ownerAddress].used += balanceToTransfer;
        _owners[msg.sender].earned += balanceToTransfer;
    }

    function _updateNetworkEarnings() private {
        _networkEarnings = _getNetworkEarnings();
        _networkEarningsBlockNumber = block.number;
    }

    function _updateNetworkFeeIndex() private {
        _networkFeeIndex = _currentNetworkFeeIndex();
        _networkFeeIndexBlockNumber = block.number;
    }

    function _deactivateValidatorUnsafe(bytes memory publicKey, address ownerAddress) private {
        _updateNetworkEarnings();
        _unregisterValidator(publicKey);
        _updateAddressNetworkFee(ownerAddress);

        _ssvRegistryContract.deactivateValidator(publicKey);

        if (!_owners[ownerAddress].validatorsDisabled) {
            --_owners[ownerAddress].activeValidatorCount;
        }
    }

    function _unregisterValidator(bytes memory publicKey) private {
        address ownerAddress = _ssvRegistryContract.getValidatorOwner(publicKey);

        // calculate balances for current operators in use and update their balances
        bytes[] memory currentOperatorPublicKeys = _ssvRegistryContract.getOperatorsByValidator(publicKey);
        for (uint256 index = 0; index < currentOperatorPublicKeys.length; ++index) {
            bytes memory operatorPublicKey = currentOperatorPublicKeys[index];
            _updateOperatorBalance(operatorPublicKey);

            if (!_owners[msg.sender].validatorsDisabled) {
                --_operatorDatas[operatorPublicKey].activeValidatorCount;
            }

            _stopUsingOperatorByOwner(ownerAddress, operatorPublicKey);
        }
    }

    function _useOperatorByOwner(address ownerAddress, bytes memory operatorPublicKey) private {
        _updateUsingOperatorByOwner(ownerAddress, operatorPublicKey, true);
    }

    function _stopUsingOperatorByOwner(address ownerAddress, bytes memory operatorPublicKey) private {
        _updateUsingOperatorByOwner(ownerAddress, operatorPublicKey, false);
    }

    /**
     * @dev Updates the relation between operator and owner
     * @param ownerAddress Owner address.
     * @param operatorPublicKey The operator's public key.
     * @param increase Change value for validators amount.
     */
    function _updateUsingOperatorByOwner(address ownerAddress, bytes memory operatorPublicKey, bool increase) private {
        OperatorInUse storage operatorInUseData = _operatorsInUseByAddress[ownerAddress][operatorPublicKey];

        if (operatorInUseData.exists) {
            _updateOperatorUsageByOwner(operatorInUseData, ownerAddress, operatorPublicKey);

            if (increase) {
                ++operatorInUseData.validatorCount;
            } else {
                if (--operatorInUseData.validatorCount == 0) {
                    _owners[ownerAddress].used += operatorInUseData.used;

                    // remove from mapping and list;

                    _operatorsInUseList[ownerAddress][operatorInUseData.indexInArray] = _operatorsInUseList[ownerAddress][_operatorsInUseList[ownerAddress].length - 1];
                    _operatorsInUseByAddress[ownerAddress][_operatorsInUseList[ownerAddress][operatorInUseData.indexInArray]].indexInArray = operatorInUseData.indexInArray;
                    _operatorsInUseList[ownerAddress].pop();

                    delete _operatorsInUseByAddress[ownerAddress][operatorPublicKey];
                }
            }
        } else {
            _operatorsInUseByAddress[ownerAddress][operatorPublicKey] = OperatorInUse(_operatorIndexOf(operatorPublicKey), 1, 0, true, _operatorsInUseList[ownerAddress].length);
            _operatorsInUseList[ownerAddress].push(operatorPublicKey);
        }
    }

    function _disableOwnerValidatorsUnsafe(address ownerAddress) private {
        _updateNetworkEarnings();
        _updateAddressNetworkFee(ownerAddress);

        for (uint256 index = 0; index < _operatorsInUseList[ownerAddress].length; ++index) {
            bytes memory operatorPublicKey = _operatorsInUseList[ownerAddress][index];
            _updateOperatorBalance(operatorPublicKey);
            OperatorInUse storage operatorInUseData = _operatorsInUseByAddress[ownerAddress][operatorPublicKey];
            _updateOperatorUsageByOwner(operatorInUseData, ownerAddress, operatorPublicKey);
            _operatorDatas[operatorPublicKey].activeValidatorCount -= operatorInUseData.validatorCount;
        }

        _ssvRegistryContract.disableOwnerValidators(ownerAddress);

        _owners[ownerAddress].validatorsDisabled = true;
    }

    function _enableOwnerValidatorsUnsafe(address ownerAddress) private {
        _updateNetworkEarnings();
        _updateAddressNetworkFee(ownerAddress);

        for (uint256 index = 0; index < _operatorsInUseList[ownerAddress].length; ++index) {
            bytes memory operatorPublicKey = _operatorsInUseList[ownerAddress][index];
            _updateOperatorBalance(operatorPublicKey);
            OperatorInUse storage operatorInUseData = _operatorsInUseByAddress[ownerAddress][operatorPublicKey];
            _updateOperatorUsageByOwner(operatorInUseData, ownerAddress, operatorPublicKey);
            _operatorDatas[operatorPublicKey].activeValidatorCount += operatorInUseData.validatorCount;
        }

        _ssvRegistryContract.enableOwnerValidators(ownerAddress);

        _owners[ownerAddress].validatorsDisabled = false;
    }

    function _updateOperatorUsageByOwner(OperatorInUse storage operatorInUseData, address ownerAddress, bytes memory operatorPublicKey) private {
        operatorInUseData.used = _operatorInUseUsageOf(operatorInUseData, ownerAddress, operatorPublicKey);
        operatorInUseData.index = _operatorIndexOf(operatorPublicKey);
    }

    function _expensesOf(address ownerAddress) private view returns(uint256) {
        uint256 usage =  _owners[ownerAddress].used + _addressNetworkFee(ownerAddress);
        for (uint256 index = 0; index < _operatorsInUseList[ownerAddress].length; ++index) {
            OperatorInUse storage operatorInUseData = _operatorsInUseByAddress[ownerAddress][_operatorsInUseList[ownerAddress][index]];
            usage += _operatorInUseUsageOf(operatorInUseData, ownerAddress, _operatorsInUseList[ownerAddress][index]);
        }

        return usage;
    }

    function _totalEarningsOf(address ownerAddress) private view returns (uint256) {
        uint256 balance = _owners[ownerAddress].earned;

        bytes[] memory operators = _ssvRegistryContract.getOperatorsByOwnerAddress(ownerAddress);
        for (uint256 index = 0; index < operators.length; ++index) {
            balance += _operatorEarningsOf(operators[index]);
        }

        return balance;
    }

    function _totalBalanceOf(address ownerAddress) private view returns (uint256) {
        uint256 balance = _owners[ownerAddress].deposited + _totalEarningsOf(ownerAddress);

        uint256 usage = _owners[ownerAddress].withdrawn + _expensesOf(ownerAddress);

        require(balance >= usage, "negative balance");

        return balance - usage;
    }

    function _operatorEarnRate(bytes memory publicKey) private view returns (uint256) {
        return _ssvRegistryContract.getOperatorCurrentFee(publicKey) * _operatorDatas[publicKey].activeValidatorCount;
    }

    /**
     * @dev See {ISSVNetwork-operatorEarningsOf}.
     */
    function _operatorEarningsOf(bytes memory publicKey) private view returns (uint256) {
        return _operatorDatas[publicKey].earnings +
               (block.number - _operatorDatas[publicKey].blockNumber) *
               _operatorEarnRate(publicKey);
    }

    function _addressNetworkFee(address ownerAddress) private view returns (uint256) {
        return _owners[ownerAddress].networkFee +
              (_currentNetworkFeeIndex() - _owners[ownerAddress].networkFeeIndex) *
              _owners[ownerAddress].activeValidatorCount;
    }

    function _burnRate(address ownerAddress) private view returns (uint256 burnRate) {
        if (_owners[ownerAddress].validatorsDisabled) {
            return 0;
        }

        for (uint256 index = 0; index < _operatorsInUseList[ownerAddress].length; ++index) {
            burnRate += _operatorInUseBurnRateWithNetworkFeeUnsafe(ownerAddress, _operatorsInUseList[ownerAddress][index]);
        }

        bytes[] memory operators = _ssvRegistryContract.getOperatorsByOwnerAddress(ownerAddress);

        for (uint256 index = 0; index < operators.length; ++index) {
            if (burnRate <= _operatorEarnRate(operators[index])) {
                return 0;
            } else {
                burnRate -= _operatorEarnRate(operators[index]);
            }
        }
    }

    function _liquidatable(address ownerAddress) private view returns (bool) {
        return !_owners[msg.sender].validatorsDisabled && _totalBalanceOf(ownerAddress) < _minimumBlocksBeforeLiquidation * _burnRate(ownerAddress);
    }

    function _getNetworkEarnings() private view returns (uint256) {
        return _networkEarnings + (block.number - _networkEarningsBlockNumber) * _networkFee * _ssvRegistryContract.activeValidatorCount();
    }

    function _getNetworkTreasury() private view returns (uint256) {
        return  _getNetworkEarnings() - _withdrawnFromTreasury;
    }

    /**
     * @dev Get operator index by address.
     * @param publicKey Operator's public Key.
     */
    function _operatorIndexOf(bytes memory publicKey) private view returns (uint256) {
        return _operatorDatas[publicKey].index +
               _ssvRegistryContract.getOperatorCurrentFee(publicKey) *
               (block.number - _operatorDatas[publicKey].indexBlockNumber);
    }

    function test_operatorIndexOf(bytes memory publicKey) public view returns (uint256) {
        return _operatorIndexOf(publicKey);
    }

    function _operatorInUseUsageOf(OperatorInUse storage operatorInUseData, address ownerAddress, bytes memory operatorPublicKey) private view returns (uint256) {
        return operatorInUseData.used + (
                _owners[ownerAddress].validatorsDisabled ? 0 :
                (_operatorIndexOf(operatorPublicKey) - operatorInUseData.index) * operatorInUseData.validatorCount
               );
    }

    function _operatorInUseBurnRateWithNetworkFeeUnsafe(address ownerAddress, bytes memory operatorPublicKey) private view returns (uint256) {
        OperatorInUse storage operatorInUseData = _operatorsInUseByAddress[ownerAddress][operatorPublicKey];
        return (_ssvRegistryContract.getOperatorCurrentFee(operatorPublicKey) + _networkFee) * operatorInUseData.validatorCount;
    }

    /**
     * @dev Returns the current network fee index
     */
    function _currentNetworkFeeIndex() private view returns(uint256) {
        return _networkFeeIndex + (block.number - _networkFeeIndexBlockNumber) * _networkFee;
    }
}

// File: contracts/ISSVNetwork.sol
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.2;

import "./ISSVRegistry.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISSVNetwork {
    /**
     * @dev Emitted when the operator has been added.
     * @param name Operator's display name.
     * @param ownerAddress Operator's ethereum address that can collect fees.
     * @param publicKey Operator's public key. Will be used to encrypt secret shares of validators keys.
     */
    event OperatorAdded(string name, address indexed ownerAddress, bytes publicKey);

    /**
     * @dev Emitted when the operator has been deleted.
     * @param ownerAddress Operator's owner.
     * @param publicKey Operator's public key.
     */
    event OperatorDeleted(address indexed ownerAddress, bytes publicKey);

    /**
     * @dev Emitted when the operator has been activated.
     * @param ownerAddress Operator's owner.
     * @param publicKey Operator's public key.
     */
    event OperatorActivated(address indexed ownerAddress, bytes publicKey);

    /**
     * @dev Emitted when the operator has been deactivated.
     * @param ownerAddress Operator's owner.
     * @param publicKey Operator's public key.
     */
    event OperatorDeactivated(address indexed ownerAddress, bytes publicKey);

    /**
     * @dev Emitted when an operator's fee is updated.
     * @param ownerAddress Operator's owner.
     * @param publicKey Operator's public key.
     * @param blockNumber from which block number.
     * @param fee updated fee value.
     */
    event OperatorFeeUpdated(
        address indexed ownerAddress,
        bytes publicKey,
        uint256 blockNumber,
        uint256 fee
    );

    /**
     * @dev Emitted when an operator's score is updated.
     * @param ownerAddress Operator's owner.
     * @param publicKey Operator's public key.
     * @param blockNumber from which block number.
     * @param score updated score value.
     */
    event OperatorScoreUpdated(
        address indexed ownerAddress,
        bytes publicKey,
        uint256 blockNumber,
        uint256 score
    );

    /**
     * @dev Emitted when the validator has been added.
     * @param ownerAddress The user's ethereum address that is the owner of the validator.
     * @param publicKey The public key of a validator.
     * @param operatorPublicKeys The operators public keys list for this validator.
     * @param sharesPublicKeys The shared publick keys list for this validator.
     * @param encryptedKeys The encrypted keys list for this validator.
     */
    event ValidatorAdded(
        address ownerAddress,
        bytes publicKey,
        bytes[] operatorPublicKeys,
        bytes[] sharesPublicKeys,
        bytes[] encryptedKeys
    );

    /**
     * @dev Emitted when the validator has been updated.
     * @param ownerAddress The user's ethereum address that is the owner of the validator.
     * @param publicKey The public key of a validator.
     * @param operatorPublicKeys The operators public keys list for this validator.
     * @param sharesPublicKeys The shared publick keys list for this validator.
     * @param encryptedKeys The encrypted keys list for this validator.
     */
    event ValidatorUpdated(
        address ownerAddress,
        bytes publicKey,
        bytes[] operatorPublicKeys,
        bytes[] sharesPublicKeys,
        bytes[] encryptedKeys
    );

    /**
     * @dev Emitted when the validator is deleted.
     * @param ownerAddress Validator's owner.
     * @param publicKey The public key of a validator.
     */
    event ValidatorDeleted(address ownerAddress, bytes publicKey);

    /**
     * @dev Emitted when the validator is activated.
     * @param ownerAddress Validator's owner.
     * @param publicKey The public key of a validator.
     */
    event ValidatorActivated(address ownerAddress, bytes publicKey);

    /**
     * @dev Emitted when the validator is deactivated.
     * @param ownerAddress Validator's owner.
     * @param publicKey The public key of a validator.
     */
    event ValidatorDeactivated(address ownerAddress, bytes publicKey);

    /**
     * @dev Emitted when an owner deposits funds.
     * @param value Amount of tokens.
     * @param ownerAddress Owner's address.
     */
    event FundsDeposited(uint256 value, address ownerAddress);

    /**
     * @dev Emitted when an owner withdraws funds.
     * @param value Amount of tokens.
     * @param ownerAddress Owner's address.
     */
    event FundsWithdrawn(uint256 value, address ownerAddress);

    /**
     * @dev Emitted when the network fee is updated.
     * @param oldFee The old fee
     * @param newFee The new fee
     */
    event NetworkFeeUpdated(uint256 oldFee, uint256 newFee);

    /**
     * @dev Emitted when transfer fees are withdrawn.
     * @param value The amount of tokens withdrawn.
     * @param recipient The recipient address.
     */
    event NetworkFeesWithdrawn(uint256 value, address recipient);

    /**
     * @dev Initializes the contract.
     * @param registryAddress The registry address.
     * @param token The network token.
     * @param minimumBlocksBeforeLiquidation The minimum blocks before liquidation.
     */
    function initialize(
        ISSVRegistry registryAddress,
        IERC20 token,
        uint256 minimumBlocksBeforeLiquidation,
        uint256 operatorMaxFeeIncrease
    ) external;

    /**
     * @dev Registers a new operator.
     * @param name Operator's display name.
     * @param publicKey Operator's public key. Used to encrypt secret shares of validators keys.
     */
    function registerOperator(
        string calldata name,
        bytes calldata publicKey,
        uint256 fee
    ) external;

    /**
     * @dev Deletes an operator.
     * @param publicKey Operator's public key.
     */
    function deleteOperator(bytes calldata publicKey) external;

    /**
     * @dev Activates an operator.
     * @param publicKey Operator's public key.
     */
    function activateOperator(bytes calldata publicKey) external;

    /**
     * @dev Deactivates an operator.
     * @param publicKey Operator's public key.
     */
    function deactivateOperator(bytes calldata publicKey) external;

    /**
     * @dev Updates operator's fee by public key.
     * @param publicKey Operator's public Key.
     * @param fee The operators's updated fee.
     */
    function updateOperatorFee(bytes calldata publicKey, uint256 fee) external;

    /**
     * @dev Updates operator's score by public key.
     * @param publicKey Operator's public Key.
     * @param score The operators's updated score.
     */
    function updateOperatorScore(bytes calldata publicKey, uint256 score) external;

    /**
     * @dev Registers a new validator.
     * @param publicKey Validator public key.
     * @param operatorPublicKeys Operator public keys.
     * @param sharesPublicKeys Shares public keys.
     * @param encryptedKeys Encrypted private keys.
     */
    function registerValidator(
        bytes calldata publicKey,
        bytes[] calldata operatorPublicKeys,
        bytes[] calldata sharesPublicKeys,
        bytes[] calldata encryptedKeys,
        uint256 tokenAmount
    ) external;

    /**
     * @dev Updates a validator.
     * @param publicKey Validator public key.
     * @param operatorPublicKeys Operator public keys.
     * @param sharesPublicKeys Shares public keys.
     * @param encryptedKeys Encrypted private keys.
     */
    function updateValidator(
        bytes calldata publicKey,
        bytes[] calldata operatorPublicKeys,
        bytes[] calldata sharesPublicKeys,
        bytes[] calldata encryptedKeys,
        uint256 tokenAmount
    ) external;

    /**
     * @dev Deletes a validator.
     * @param publicKey Validator's public key.
     */
    function deleteValidator(bytes calldata publicKey) external;

    /**
     * @dev Activates a validator.
     * @param publicKey Validator's public key.
     */
    function activateValidator(bytes calldata publicKey, uint256 tokenAmount) external;

    /**
     * @dev Deactivates a validator.
     * @param publicKey Validator's public key.
     */
    function deactivateValidator(bytes calldata publicKey) external;
    /**
     * @dev Deposits tokens for the sender.
     * @param tokenAmount Tokens amount.
     */
    function deposit(uint256 tokenAmount) external;

    /**
     * @dev Withdraw tokens for the sender.
     * @param tokenAmount Tokens amount.
     */
    function withdraw(uint256 tokenAmount) external;

    /**
     * @dev Withdraw total balance to the sender, deactivating their validators if necessary.
     */
    function withdrawAll() external;

    /**
     * @dev Liquidates an operator.
     * @param ownerAddress Owner's address.
     */
    function liquidate(address ownerAddress) external;

    /**
     * @dev Liquidates multiple owners.
     * @param ownerAddresses Owners' addresses.
     */
    function liquidateAll(address[] calldata ownerAddresses) external;

    function enableAccount(uint256 tokenAmount) external;

    /**
     * @dev Updates the number of blocks left for an owner before they can be liquidated.
     * @param minimumBlocksBeforeLiquidation The new value.
     */
    function updateMinimumBlocksBeforeLiquidation(uint256 minimumBlocksBeforeLiquidation) external;

    /**
     * @dev Updates the maximum fee increase in pecentage.
     * @param operatorMaxFeeIncrease The new value.
     */
    function updateOperatorMaxFeeIncrease(uint256 operatorMaxFeeIncrease) external;

    /**
     * @dev Updates the network fee.
     * @param fee the new fee
     */
    function updateNetworkFee(uint256 fee) external;

    /**
     * @dev Withdraws network fees.
     * @param amount Amount to withdraw
     */
    function withdrawNetworkFees(uint256 amount) external;

    /**
     * @dev Gets total earnings for an owner
     * @param ownerAddress Owner's address.
     */
    function totalEarningsOf(address ownerAddress) external view returns (uint256);

    /**
     * @dev Gets total balance for an owner.
     * @param ownerAddress Owner's address.
     */
    function totalBalanceOf(address ownerAddress) external view returns (uint256);

    function isOwnerValidatorsDisabled(address ownerAddress) external view returns (bool);

    /**
     * @dev Gets an operator by public key.
     * @param publicKey Operator's public key.
     */
    function operators(bytes calldata publicKey)
        external view
        returns (
            string memory,
            address,
            bytes memory,
            uint256,
            bool,
            uint256
        );

    /**
     * @dev Gets a validator public keys by owner's address.
     * @param ownerAddress Owner's Address.
     */
    function getValidatorsByOwnerAddress(address ownerAddress)
        external view
        returns (bytes[] memory);

    /**
     * @dev Returns operators for owner.
     * @param ownerAddress Owner's address.
     */
    function getOperatorsByOwnerAddress(address ownerAddress)
        external view
        returns (bytes[] memory);

    /**
     * @dev Gets operators list which are in use by validator.
     * @param validatorPublicKey Validator's public key.
     */
    function getOperatorsByValidator(bytes calldata validatorPublicKey)
        external view
        returns (bytes[] memory);

    /**
     * @dev Gets operator current fee.
     * @param publicKey Operator's public key.
     */
    function getOperatorCurrentFee(bytes calldata publicKey) external view returns (uint256);

    /**
     * @dev Gets operator earnings.
     * @param publicKey Operator's public key.
     */
    function operatorEarningsOf(bytes memory publicKey) external view returns (uint256);

    /**
     * @dev Gets the network fee for an address.
     * @param ownerAddress Owner's address.
     */
    function addressNetworkFee(address ownerAddress) external view returns (uint256);

    /**
     * @dev Returns the burn rate of an owner, returns 0 if negative.
     * @param ownerAddress Owner's address.
     */
    function burnRate(address ownerAddress) external view returns (uint256);

    /**
     * @dev Check if an owner is liquidatable.
     * @param ownerAddress Owner's address.
     */
    function liquidatable(address ownerAddress) external view returns (bool);

    /**
     * @dev Returns the network fee.
     */
    function networkFee() external view returns (uint256);

    /**
     * @dev Gets the network treasury
     */
    function getNetworkTreasury() external view returns (uint256);

    /**
     * @dev Returns the number of blocks left for an owner before they can be liquidated.
     */
    function minimumBlocksBeforeLiquidation() external view returns (uint256);

    /**
     * @dev Returns the maximum fee increase in pecentage
     */
     function operatorMaxFeeIncrease() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// File: contracts/ISSVRegistry.sol
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.2;

interface ISSVRegistry {
    struct Oess {
        bytes operatorPublicKey;
        bytes sharedPublicKey;
        bytes encryptedKey;
    }

    /**
     * @dev Emitted when the operator has been added.
     * @param name Operator's display name.
     * @param ownerAddress Operator's ethereum address that can collect fees.
     * @param publicKey Operator's public key. Will be used to encrypt secret shares of validators keys.
     */
    event OperatorAdded(string name, address indexed ownerAddress, bytes publicKey);

    /**
     * @dev Emitted when the operator has been deleted.
     * @param ownerAddress Operator's owner.
     * @param publicKey Operator's public key.
     */
    event OperatorDeleted(address indexed ownerAddress, bytes publicKey);

    /**
     * @dev Emitted when the operator has been activated.
     * @param ownerAddress Operator's owner.
     * @param publicKey Operator's public key.
     */
    event OperatorActivated(address indexed ownerAddress, bytes publicKey);

    /**
     * @dev Emitted when the operator has been deactivated.
     * @param ownerAddress Operator's owner.
     * @param publicKey Operator's public key.
     */
    event OperatorDeactivated(address indexed ownerAddress, bytes publicKey);

    /**
     * @dev Emitted when an operator's fee is updated.
     * @param ownerAddress Operator's owner.
     * @param publicKey Operator's public key.
     * @param blockNumber from which block number.
     * @param fee updated fee value.
     */
    event OperatorFeeUpdated(
        address indexed ownerAddress,
        bytes publicKey,
        uint256 blockNumber,
        uint256 fee
    );

    /**
     * @dev Emitted when an operator's score is updated.
     * @param ownerAddress Operator's owner.
     * @param publicKey Operator's public key.
     * @param blockNumber from which block number.
     * @param score updated score value.
     */
    event OperatorScoreUpdated(
        address indexed ownerAddress,
        bytes publicKey,
        uint256 blockNumber,
        uint256 score
    );

    /**
     * @dev Emitted when the validator has been added.
     * @param ownerAddress The user's ethereum address that is the owner of the validator.
     * @param publicKey The public key of a validator.
     * @param oessList The OESS list for this validator.
     */
    event ValidatorAdded(
        address ownerAddress,
        bytes publicKey,
        Oess[] oessList
    );

    /**
     * @dev Emitted when the validator has been updated.
     * @param ownerAddress The user's ethereum address that is the owner of the validator.
     * @param publicKey The public key of a validator.
     * @param oessList The OESS list for this validator.
     */
    event ValidatorUpdated(
        address ownerAddress,
        bytes publicKey,
        Oess[] oessList
    );

    /**
     * @dev Emitted when the validator is deleted.
     * @param ownerAddress Validator's owner.
     * @param publicKey The public key of a validator.
     */
    event ValidatorDeleted(address ownerAddress, bytes publicKey);

    /**
     * @dev Emitted when the validator is activated.
     * @param ownerAddress Validator's owner.
     * @param publicKey The public key of a validator.
     */
    event ValidatorActivated(address ownerAddress, bytes publicKey);

    /**
     * @dev Emitted when the validator is deactivated.
     * @param ownerAddress Validator's owner.
     * @param publicKey The public key of a validator.
     */
    event ValidatorDeactivated(address ownerAddress, bytes publicKey);

    event OwnerValidatorsDisabled(address ownerAddress);

    event OwnerValidatorsEnabled(address ownerAddress);

    /**
     * @dev Initializes the contract
     */
    function initialize() external;

    /**
     * @dev Registers a new operator.
     * @param name Operator's display name.
     * @param ownerAddress Operator's ethereum address that can collect fees.
     * @param publicKey Operator's public key. Will be used to encrypt secret shares of validators keys.
     * @param fee The fee which the operator charges for each block.
     */
    function registerOperator(string calldata name, address ownerAddress, bytes calldata publicKey, uint256 fee) external;

    /**
     * @dev Deletes an operator.
     * @param publicKey Operator public key.
     */
    function deleteOperator(bytes calldata publicKey) external;

    /**
     * @dev Activates an operator.
     * @param publicKey Operator public key.
     */
    function activateOperator(bytes calldata publicKey) external;

    /**
     * @dev Deactivates an operator.
     * @param publicKey Operator public key.
     */
    function deactivateOperator(bytes calldata publicKey) external;

    /**
     * @dev Updates an operator fee.
     * @param publicKey Operator's public key.
     * @param fee new operator fee.
     */
    function updateOperatorFee(
        bytes calldata publicKey,
        uint256 fee
    ) external;

    /**
     * @dev Updates an operator fee.
     * @param publicKey Operator's public key.
     * @param score New score.
     */
    function updateOperatorScore(
        bytes calldata publicKey,
        uint256 score
    ) external;

    /**
     * @dev Registers a new validator.
     * @param ownerAddress The user's ethereum address that is the owner of the validator.
     * @param publicKey Validator public key.
     * @param operatorPublicKeys Operator public keys.
     * @param sharesPublicKeys Shares public keys.
     * @param encryptedKeys Encrypted private keys.
     */
    function registerValidator(
        address ownerAddress,
        bytes calldata publicKey,
        bytes[] calldata operatorPublicKeys,
        bytes[] calldata sharesPublicKeys,
        bytes[] calldata encryptedKeys
    ) external;

    /**
     * @dev Updates a validator.
     * @param publicKey Validator public key.
     * @param operatorPublicKeys Operator public keys.
     * @param sharesPublicKeys Shares public keys.
     * @param encryptedKeys Encrypted private keys.
     */
    function updateValidator(
        bytes calldata publicKey,
        bytes[] calldata operatorPublicKeys,
        bytes[] calldata sharesPublicKeys,
        bytes[] calldata encryptedKeys
    ) external;

    /**
     * @dev Deletes a validator.
     * @param publicKey Validator's public key.
     */
    function deleteValidator(bytes calldata publicKey) external;

    /**
     * @dev Activates a validator.
     * @param publicKey Validator's public key.
     */
    function activateValidator(bytes calldata publicKey) external;

    /**
     * @dev Deactivates a validator.
     * @param publicKey Validator's public key.
     */
    function deactivateValidator(bytes calldata publicKey) external;

    function enableOwnerValidators(address ownerAddress) external;

    function disableOwnerValidators(address ownerAddress) external;

    function isOwnerValidatorsDisabled(address ownerAddress) external view returns (bool);

    /**
     * @dev Returns the operator count.
     */
    function operatorCount() external view returns (uint256);

    /**
     * @dev Gets an operator by public key.
     * @param publicKey Operator's public key.
     */
    function operators(bytes calldata publicKey)
        external view
        returns (
            string memory,
            address,
            bytes memory,
            uint256,
            bool,
            uint256
        );

    /**
     * @dev Returns operators for owner.
     * @param ownerAddress Owner's address.
     */
    function getOperatorsByOwnerAddress(address ownerAddress)
        external view
        returns (bytes[] memory);

    /**
     * @dev Gets operators list which are in use by validator.
     * @param validatorPublicKey Validator's public key.
     */
    function getOperatorsByValidator(bytes calldata validatorPublicKey)
        external view
        returns (bytes[] memory);

    /**
     * @dev Gets operator's owner.
     * @param publicKey Operator's public key.
     */
    function getOperatorOwner(bytes calldata publicKey) external view returns (address);

    /**
     * @dev Gets operator current fee.
     * @param publicKey Operator's public key.
     */
    function getOperatorCurrentFee(bytes calldata publicKey)
        external view
        returns (uint256);

    /**
     * @dev Gets validator count.
     */
    function validatorCount() external view returns (uint256);

    /**
     * @dev Gets active validator count.
     */
    function activeValidatorCount() external view returns (uint256);

    /**
     * @dev Gets an validator by public key.
     * @param publicKey Validator's public key.
     */
    function validators(bytes calldata publicKey)
        external view
        returns (
            address,
            bytes memory,
            bool,
            uint256
        );

    /**
     * @dev Gets a validator public keys by owner's address.
     * @param ownerAddress Owner's Address.
     */
    function getValidatorsByAddress(address ownerAddress)
        external view
        returns (bytes[] memory);

    /**
     * @dev Get validator's owner.
     * @param publicKey Validator's public key.
     */
    function getValidatorOwner(bytes calldata publicKey) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}