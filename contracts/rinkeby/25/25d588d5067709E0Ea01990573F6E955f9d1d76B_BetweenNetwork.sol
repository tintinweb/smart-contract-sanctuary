// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.8.4;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "./Libraries/AddressArrayUtils.sol";
import "./Libraries/StringLibrary.sol";
import "./BridgeTreasury.sol";

contract BetweenNetwork is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using AddressArrayUtils for address[];

    BridgeTreasury public treasury;
    address public governance;
    address public beneficiary;
    address[] public validators;

    uint256 public homeChainId;
    uint256 public foreignChainId;
    uint256 public depositFee;
    uint256 public withdrawFee;
    uint256 public listingFee;
    uint256 public lastPairIndex;
    uint256 public maxValidatorCount;
    uint256 public requiredValidation;
    uint16 public version;
    uint16 public multiplier;

    string public BRIDGENAME;

    bool public isBridgePaused;
    bool public isTapInPaused;
    bool public isTapOutPaused;

    bool public deprecateV1;

    uint8 public isAllowedToCreateBridgePair; // 0 - Inactive, 1- Active

    mapping(address => bool) public isValidator;

    struct Sig {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct BridgePair {
        uint256 _index;
        address _homeERC20;
        address _foreignERC20;
        uint256 _homeChainId;
        uint256 _foreignChainId;
        address _listedBy;
        uint256 _listedBlock;
        uint256 _suspendedBlock;
        uint8 _isActive; // 0-Suspended, 1-Active
    }
    mapping(address => BridgePair) public bridgePairs;
    address[] BridgePairs;

    struct DepositWallet {
        uint256 _index;
        uint256 _amount;
        uint256 _homeChainId;
        uint256 _foreignChainId;
        address _user;
        address _homeERC20;
        address _foreignERC20;
        uint256 _depositedBlock;
        uint256 _depositedTimeStamp;
        bool _isBanned;
    }
    mapping(address => DepositWallet) public depositWallets;
    address[] DepositWallets;

    struct WithdrawalWallet {
        uint256 _index;
        uint256 _amount;
        uint256 _homeChainId;
        uint256 _foreignChainId;
        address _user;
        address _withdrawERC20;
        address _depositedERC20;
        bytes32 _depositedTxHash;
        bool _withdrawalStatus;
        bool _isBanned;
    }
    WithdrawalWallet[] withdrawalWallet;
    mapping(address => WithdrawalWallet) public withdrawalWallets;
    address[] WithdrawalWallets;
    mapping(bytes32 => bool) public depositedTxHash;

    // Deposit index of Foreign chain => Withdrawal in current chain
    mapping(uint256 => bool) public claimedWithdrawalsByOtherChainDepositId;

    // Deposit index for current chain
    uint256 public lastDepositIndex;

    // Validator array based on withdraw
    mapping(uint256 => address[]) public validatedBy;

    event TapIn(
        address indexed account,
        uint256 amount,
        address homeERC20,
        address foreignERC20,
        uint256 homeChainId,
        uint256 foreignChainId,
        uint256 blocknumber,
        uint256 timestamp,
        uint256 id
    );
    event TapOut(
        address indexed account,
        uint256 amount,
        address withdrawERC20,
        address depositedERC20,
        uint256 id,
        uint256 homeChainId,
        uint256 foreignChainId
    );
    event BridgePairCreated(
        address indexed account,
        address homeERC20,
        uint256 homeChainId,
        address foreignERC20,
        uint256 foreignChainId,
        address listedBy,
        uint256 blocknumber,
        uint256 blockTimestamp,
        uint256 tokenIndex
    );
    event ListingFeeUpdated(uint256 oldListingFee, uint256 newListingFee);
    event DepositFeeUpdated(uint256 oldDepositFee, uint256 newDepositFee);
    event WithdrawFeeUpdated(uint256 oldWithdrawFee, uint256 newWithdrawFee);
    event BeneficiaryUpdated(address oldBeneficiary, address newBeneficiary);
    event ValidatorAddition(address indexed validator);
    event ValidatorRemoval(address indexed validator);
    event RequirementChange(uint256 requiredValidation);
    event SuspendToken(address erc20Token, uint256 timestamp);
    event UnsuspendToken(address erc20Token, uint256 timestamp);
    event PauseBridge(uint256 timestamp);
    event UnPauseBridge(uint256 timestamp);
    event BannedUser(address wallet, uint256 timestamp);
    event UnbannedUser(address wallet, uint256 timestamp);
    event PauseTapIn(uint256 timestamp);
    event UnpauseTapIn(uint256 timestamp);
    event PauseTapOut(uint256 timestamp);
    event UnpauseTapOut(uint256 timestamp);
    event MultiplierRewardsUpdated(uint16 oldMultiplier, uint16 newMultiplier);
    event GovernanceUpdated(address oldGovernance, address newGovernance);
    event BridgeStatusUpdated(address who, uint8 status, uint256 when);

    function initialize(
        address _governance,
        BridgeTreasury _treasury,
        address[] memory _validators,
        uint256 _requiredValidation,
        address _beneficiary,
        uint256 _depositFee,
        uint256 _withdrawFee,
        uint256 _listingFee,
        uint256 _foreignChainId,
        string memory _bridgeName
    ) public initializer {
        require(
            _governance != address(0),
            "initialize:: _governance can not be Zero Address"
        );
        require(
            _beneficiary != address(0),
            "initialize:: _beneficiary can not be Zero Address"
        );
        __Ownable_init_unchained();
        governance = _governance;
        treasury = _treasury;
        beneficiary = _beneficiary;
        maxValidatorCount = 50;
        multiSigWallet(_validators, _requiredValidation);
        homeChainId = block.chainid;
        foreignChainId = _foreignChainId;
        depositFee = _depositFee;
        withdrawFee = _withdrawFee;
        listingFee = _listingFee;
        isBridgePaused = false;
        isTapInPaused = false;
        isTapOutPaused = false;
        deprecateV1 = false;
        requiredValidation = _requiredValidation;
        version = 1;
        multiplier = 1;
        isAllowedToCreateBridgePair = 0;
        BRIDGENAME = _bridgeName;
    }

    modifier noContractsAllowed() {
        require(
            !(address(msg.sender).isContract()) && tx.origin == msg.sender,
            "Access Denied:: Contracts are not allowed!"
        );
        _;
    }

    modifier onlyGovernance() {
        require(
            msg.sender == governance,
            "OnlyGovernance:: Unauthorized Access"
        );
        _;
    }

    modifier validatorDoesNotExist(address _validator) {
        require(
            !isValidator[_validator],
            "ValidatorDoesNotExist:: Invalid Validator"
        );
        _;
    }

    modifier validatorExists(address _validator) {
        require(
            isValidator[_validator],
            "ValidatorExists:: Unauthorized Access"
        );
        _;
    }

    modifier notNull(address _address) {
        require(
            _address != address(0),
            "NotNull:: Address can not be Zero Address"
        );
        _;
    }

    modifier validRequirement(
        uint256 _validatorCount,
        uint256 _requiredValidation
    ) {
        require(
            _validatorCount <= maxValidatorCount &&
                _requiredValidation <= _validatorCount &&
                _requiredValidation != 0 &&
                _validatorCount != 0,
            "ValidRequirement:: Invalid Validator Info"
        );
        _;
    }

    function multiSigWallet(
        address[] memory _validator,
        uint256 _requiredValidation
    ) internal validRequirement(_validator.length, _requiredValidation) {
        uint256 _validatorLength = _validator.length;
        for (uint256 i = 0; i < _validatorLength; i++) {
            require(
                !isValidator[_validator[i]] && _validator[i] != address(0),
                "MultiSigWallet:: Invalid Validator Info"
            );
            isValidator[_validator[i]] = true;
        }
        validators = _validator;
        requiredValidation = _requiredValidation;
    }

    function addValidator(address _validator)
        external
        onlyGovernance
        validatorDoesNotExist(_validator)
        notNull(_validator)
        validRequirement(validators.length + 1, requiredValidation)
    {
        require(
            _validator != address(0),
            "Addvalidator:: validator can not be Zero Address"
        );
        isValidator[_validator] = true;
        validators.push(_validator);
        emit ValidatorAddition(_validator);
    }

    function removeValidator(address _validator)
        external
        onlyGovernance
        validatorExists(_validator)
    {
        require(
            _validator != address(0),
            "RemoveValidator:: validator can not be Zero Address"
        );
        isValidator[_validator] = false;
        uint256 _validatorLength = validators.length;
        for (uint256 i = 0; i < _validatorLength - 1; i++)
            if (validators[i] == _validator) {
                validators[i] = validators[_validatorLength - 1];
                validators.pop();
                break;
            }
        if (requiredValidation > _validatorLength) {
            changeRequirement(_validatorLength);
        }
        emit ValidatorRemoval(_validator);
    }

    function changeRequirement(uint256 _requiredValidation)
        internal
        validRequirement(validators.length, _requiredValidation)
    {
        require(
            _requiredValidation > 0,
            "ChangeRequirement:: _requiredValidation validators can not be Zero"
        );
        requiredValidation = _requiredValidation;
        emit RequirementChange(_requiredValidation);
    }

    function bridgePairAccess(uint8 status) external onlyGovernance {
        require(
            status == 0 || status == 1,
            "OpenBridgePairAccess:: Invalid Status."
        );
        isAllowedToCreateBridgePair = status;
        emit BridgeStatusUpdated(msg.sender, status, block.timestamp);
    }

    function createBridgePair(address _homeERC20, address _foreignERC20)
        external
        payable
        noContractsAllowed
        nonReentrant
    {
        if (msg.sender != governance) {
            require(
                isAllowedToCreateBridgePair == 1,
                "CreateBridgePair:: Unauthorized."
            );
        }
        require(!deprecateV1, "CreateBridgePair:: Deprecated.");
        require(
            !isBridgePaused,
            "CreateBridgePair:: Bridge Paused, can not add new token"
        );
        require(
            _homeERC20 != address(0),
            "CreateBridgePair:: HomeERC20 can not be Zero Address"
        );
        require(
            _foreignERC20 != address(0),
            "CreateBridgePair:: ForeignERC20 can not be Zero Address"
        );
        require(
            bridgePairs[_homeERC20]._homeERC20 != _homeERC20 &&
                bridgePairs[_homeERC20]._foreignERC20 != _foreignERC20,
            "CreateBridgePair:: Duplicate Bridge Pair"
        );
        require(
            bridgePairs[_homeERC20]._suspendedBlock == 0,
            "CreateBridgePair:: _erc20Token is suspended"
        );
        if (msg.sender != governance) {
            if (listingFee > 0) {
                require(
                    msg.value == listingFee,
                    "CreateBridgePair:: Incorrect msg.value"
                );
                (bool success, ) = beneficiary.call{value: msg.value}("");
                require(success, "CreateBridgePair:: Transfer failed");
            }
        }
        lastPairIndex = lastPairIndex.add(1);
        updatePair(lastPairIndex, _homeERC20, _foreignERC20);
        emit BridgePairCreated(
            msg.sender,
            _homeERC20,
            homeChainId,
            _foreignERC20,
            foreignChainId,
            msg.sender,
            block.number,
            block.timestamp,
            lastPairIndex
        );
    }

    function tapIn(address _homeERC20, uint256 _amount)
        external
        payable
        noContractsAllowed
        nonReentrant
    {
        require(!deprecateV1, "TapIn:: Deprecated.");
        require(!isBridgePaused, "TapIn:: Bridge Paused, can not Deposit");
        require(!isTapInPaused, "TapIn:: TapIn Paused, can not Deposit");
        require(
            !depositWallets[msg.sender]._isBanned,
            "TapIn:: Your Wallet Banned"
        );
        require(
            _homeERC20 != address(0),
            "TapIn:: HomeERC20 can not be Zero Address"
        );
        require(
            bridgePairs[_homeERC20]._isActive == 1,
            "TapIn:: _homeERC20 not listed as BridgePair"
        );
        require(
            bridgePairs[_homeERC20]._suspendedBlock == 0,
            "TapIn:: _homeERC20 is suspended"
        );
        require(_amount > 0, "TapIn:: Tokens can not be Zero");
        require(
            IERC20Upgradeable(_homeERC20).balanceOf(msg.sender) >= _amount,
            "TapIn:: Insufficient Balance"
        );
        depositTokensAndPlatformFee(_homeERC20, _amount);
        lastDepositIndex = lastDepositIndex.add(1);
        updateDeposit(
            lastDepositIndex,
            _amount,
            _homeERC20,
            bridgePairs[_homeERC20]._foreignERC20,
            block.number,
            block.timestamp
        );
        emit TapIn(
            msg.sender,
            _amount,
            _homeERC20,
            bridgePairs[_homeERC20]._foreignERC20,
            homeChainId,
            foreignChainId,
            block.number,
            block.timestamp,
            lastDepositIndex
        );
    }

    function tapOut(
        uint256 _amount,
        address _withdrawERC20,
        address _depositedERC20,
        uint256[2] memory _chainID,
        uint256 _nonce,
        bytes32 _txHash,
        Sig[] memory signature,
        address[] memory _validators
    ) external payable noContractsAllowed nonReentrant {
        require(!deprecateV1, "TapOut:: Deprecated.");
        require(!isBridgePaused, "TapOut:: Bridge Paused, can not Withdrawn");
        require(!isTapOutPaused, "TapIn:: TapOut Paused, can not Withdrawn");
        require(
            !withdrawalWallets[msg.sender]._isBanned,
            "TapIn:: Your Wallet Banned"
        );
        require(
            _withdrawERC20 != address(0),
            "TapOut:: WithdrawERC20 can not be Zero Address"
        );
        require(
            _depositedERC20 != address(0),
            "TapOut:: DepositedERC20 can not be Zero Address"
        );
        require(
            bridgePairs[_withdrawERC20]._isActive == 1,
            "TapOut:: _trustedERC20Token not listed as BridgePair"
        );
        require(
            bridgePairs[_withdrawERC20]._suspendedBlock == 0,
            "TapOut:: _trustedERC20Token is suspended"
        );
        require(
            bridgePairs[_withdrawERC20]._foreignERC20 == _depositedERC20,
            "TapOut:: Incorrect Pair"
        );
        require(_amount > 0, "TapOut:: Tokens can not be Zero");
        require(homeChainId == _chainID[0], "TapOut:: Invalid Home chainId!");
        require(
            foreignChainId == _chainID[1],
            "TapOut:: Invalid Foreign chainId!"
        );
        require(
            !claimedWithdrawalsByOtherChainDepositId[_nonce],
            "TapOut:: Already Withdrawn!"
        );
        require(
            _validators.length == signature.length,
            "TapOut: Signature should match with Validators"
        );
        require(
            !(_validators.hasDuplicate()),
            "TapOut:: Duplicate Validator Found"
        );
        uint256 validatorCount = 0;
        uint256 _validatorLength = _validators.length;
        for (uint256 i = 0; i < _validatorLength; i++) {
            bool validationStatus = verifySignature(
                _amount,
                _withdrawERC20,
                _depositedERC20,
                _nonce,
                _txHash,
                signature[i],
                _validators[i]
            );
            if (validationStatus == true) {
                validatorCount = validatorCount + 1;
                validatedBy[_nonce].push(_validators[i]);
            } else {
                validatorCount = validatorCount;
            }
        }
        require(
            validatorCount >= requiredValidation,
            "TapOut:: Validation Failed"
        );
        address _recipient = msg.sender;
        withdrawTokensAndPlatformFee(_withdrawERC20, _recipient, _amount);
        claimedWithdrawalsByOtherChainDepositId[_nonce] = true;
        updateWithdraw(
            _nonce,
            _amount,
            _withdrawERC20,
            _depositedERC20,
            _txHash
        );
        emit TapOut(
            msg.sender,
            _amount,
            _withdrawERC20,
            _depositedERC20,
            _nonce,
            homeChainId,
            foreignChainId
        );
    }

    function depositTokensAndPlatformFee(address _homeERC20, uint256 _amount)
        internal
    {
        if (depositFee > 0) {
            require(msg.value == depositFee, "TapIn:: Incorrect msg.value");
            (bool success, ) = beneficiary.call{value: msg.value}("");
            require(success, "TapIn:: Transfer failed");
        }
        IERC20Upgradeable(_homeERC20).safeTransferFrom(
            msg.sender,
            address(treasury),
            _amount
        );
    }

    function withdrawTokensAndPlatformFee(
        address _withdrawERC20,
        address _recipient,
        uint256 _amount
    ) internal {
        if (withdrawFee > 0) {
            require(msg.value == withdrawFee, "TapOut:: Incorrect msg.value");
            (bool success, ) = beneficiary.call{value: msg.value}("");
            require(success, "TapOut:: Transfer failed");
        }
        treasury.withdraw(_withdrawERC20, _recipient, _amount);
    }

    function updatePair(
        uint256 _index,
        address _homeERC20,
        address _foreignERC20
    ) internal {
        bridgePairs[_homeERC20]._index = _index;
        bridgePairs[_homeERC20]._homeERC20 = _homeERC20;
        bridgePairs[_homeERC20]._foreignERC20 = _foreignERC20;
        bridgePairs[_homeERC20]._homeChainId = homeChainId;
        bridgePairs[_homeERC20]._foreignChainId = foreignChainId;
        bridgePairs[_homeERC20]._listedBy = msg.sender;
        bridgePairs[_homeERC20]._listedBlock = block.number;
        bridgePairs[_homeERC20]._suspendedBlock = 0;
        bridgePairs[_homeERC20]._isActive = 1;
        BridgePairs.push(_homeERC20);
    }

    function updateDeposit(
        uint256 _index,
        uint256 _amount,
        address _homeERC20,
        address _foreignERC20,
        uint256 _depositedBlock,
        uint256 _depositedTimeStamp
    ) internal {
        depositWallets[msg.sender]._index = _index;
        depositWallets[msg.sender]._amount = _amount;
        depositWallets[msg.sender]._homeChainId = homeChainId;
        depositWallets[msg.sender]._foreignChainId = foreignChainId;
        depositWallets[msg.sender]._user = msg.sender;
        depositWallets[msg.sender]._homeERC20 = _homeERC20;
        depositWallets[msg.sender]._foreignERC20 = _foreignERC20;
        depositWallets[msg.sender]._depositedBlock = _depositedBlock;
        depositWallets[msg.sender]._depositedTimeStamp = _depositedTimeStamp;
        DepositWallets.push(msg.sender);
    }

    function updateWithdraw(
        uint256 _nonce,
        uint256 _amount,
        address _withdrawERC20,
        address _depositedERC20,
        bytes32 _txHash
    ) internal {
        withdrawalWallets[msg.sender]._index = _nonce;
        withdrawalWallets[msg.sender]._amount = _amount;
        withdrawalWallets[msg.sender]._homeChainId = homeChainId;
        withdrawalWallets[msg.sender]._foreignChainId = foreignChainId;
        withdrawalWallets[msg.sender]._user = msg.sender;
        withdrawalWallets[msg.sender]._withdrawERC20 = _withdrawERC20;
        withdrawalWallets[msg.sender]._depositedERC20 = _depositedERC20;
        withdrawalWallets[msg.sender]._depositedTxHash = _txHash;
        withdrawalWallets[msg.sender]._withdrawalStatus = true;
        WithdrawalWallets.push(msg.sender);
        depositedTxHash[_txHash] = true;
    }

    function verifySignature(
        uint256 _amount,
        address _withdrawERC20,
        address _depositedERC20,
        uint256 _nonce,
        bytes32 _txHash,
        Sig memory signature,
        address _validator
    ) internal view returns (bool) {
        address msgSigner = StringLibrary.getAddress(
            abi.encodePacked(
                msg.sender,
                _amount,
                _withdrawERC20,
                _depositedERC20,
                homeChainId,
                foreignChainId,
                _nonce,
                _txHash,
                address(this)
            ),
            signature.v,
            signature.r,
            signature.s
        );
        return (isValidator[msgSigner] && _validator == msgSigner);
    }

    function suspendToken(address _erc20Token) external onlyGovernance {
        require(
            _erc20Token != address(0),
            "SuspendToken:: _erc20Token can not be Zero Address"
        );
        bridgePairs[_erc20Token]._isActive = 0;
        bridgePairs[_erc20Token]._suspendedBlock = block.number;
        emit SuspendToken(_erc20Token, block.timestamp);
    }

    function activeSuspendToken(address _erc20Token) external onlyGovernance {
        require(
            _erc20Token != address(0),
            "ActiveSuspendToken:: _erc20Token can not be Zero Address"
        );
        bridgePairs[_erc20Token]._isActive = 1;
        bridgePairs[_erc20Token]._suspendedBlock = 0;
        emit UnsuspendToken(_erc20Token, block.timestamp);
    }

    function bannedUser(address _wallet) external onlyGovernance {
        require(
            _wallet != address(0),
            "BannedUser:: _wallet can not be Zero Address"
        );
        depositWallets[msg.sender]._isBanned = true;
        withdrawalWallets[msg.sender]._isBanned = true;
        emit BannedUser(_wallet, block.timestamp);
    }

    function unbannedUser(address _wallet) external onlyGovernance {
        require(
            _wallet != address(0),
            "UnBanUser:: _wallet can not be Zero Address"
        );
        depositWallets[msg.sender]._isBanned = false;
        withdrawalWallets[msg.sender]._isBanned = false;
        emit UnbannedUser(_wallet, block.timestamp);
    }

    function pauseTapIn() external onlyGovernance {
        require(!isTapInPaused, "PauseTapIn:: TapIn already Paused");
        isTapInPaused = true;
        emit PauseTapIn(block.timestamp);
    }

    function unPauseTapIn() external onlyGovernance {
        require(isTapInPaused, "UnpauseTapIn:: TapIn already UnPaused");
        isTapInPaused = false;
        emit UnpauseTapIn(block.timestamp);
    }

    function pauseTapOut() external onlyGovernance {
        require(!isTapOutPaused, "PauseTapOut:: TapOut already Paused");
        isTapOutPaused = true;
        emit PauseTapOut(block.timestamp);
    }

    function unPauseTapOut() external onlyGovernance {
        require(isTapOutPaused, "UnpauseTapOut:: TapOut already UnPaused");
        isTapOutPaused = false;
        emit UnpauseTapOut(block.timestamp);
    }

    function updateListingFee(uint256 _newListingFee) external onlyGovernance {
        require(
            _newListingFee > 0,
            "UpdateListingFee:: _newListingFee can not be Zero"
        );
        require(
            listingFee != _newListingFee,
            "UpdateListingFee:: New Listing Fee can not be same as Listing Fee"
        );
        uint256 _oldListingFee = listingFee;
        listingFee = _newListingFee;
        emit ListingFeeUpdated(_oldListingFee, _newListingFee);
    }

    function updateDepositFee(uint256 _newDepositFee) external onlyGovernance {
        require(
            _newDepositFee > 0,
            "UpdateDepositFee:: _newDepositFee can not be Zero"
        );
        require(
            depositFee != _newDepositFee,
            "UpdateDepositFee:: New Deposit Fee can not be same as Old Deposit Fee"
        );
        uint256 _oldDepositFee = depositFee;
        depositFee = _newDepositFee;
        emit DepositFeeUpdated(_oldDepositFee, _newDepositFee);
    }

    function updateWithdrawFee(uint256 _newWithdrawFee)
        external
        onlyGovernance
    {
        require(
            _newWithdrawFee > 0,
            "UpdateWithdrawFee:: _newWithdrawFee can not be Zero"
        );
        require(
            withdrawFee != _newWithdrawFee,
            "UpdateWithdrawFee:: New Withdraw Fee can not be same as Old Withdraw Fee"
        );
        uint256 _oldWithdrawFee = withdrawFee;
        withdrawFee = _newWithdrawFee;
        emit WithdrawFeeUpdated(_oldWithdrawFee, _newWithdrawFee);
    }

    function updateBeneficiary(address _newBeneficiary)
        external
        onlyGovernance
    {
        require(
            _newBeneficiary != address(0),
            "UpdateBeneficiary:: New Beneficiary can not be Zero Address"
        );
        address _oldBeneficiary = beneficiary;
        beneficiary = _newBeneficiary;
        emit BeneficiaryUpdated(_oldBeneficiary, _newBeneficiary);
    }

    function pauseBridge() external onlyGovernance {
        require(!isBridgePaused, "PauseBridge:: Bridge is already Paused");
        isBridgePaused = true;
        emit PauseBridge(block.timestamp);
    }

    function unPauseBridge() external onlyGovernance {
        require(isBridgePaused, "UnPauseBridge:: Bridge is already Unpaused");
        isBridgePaused = false;
        emit UnPauseBridge(block.timestamp);
    }

    function updateMultiplierReward(uint16 _newMultiplier)
        external
        onlyGovernance
    {
        require(
            _newMultiplier > 0,
            "updateMultiplierReward:: Multiplier can not be Zero"
        );
        uint16 _oldMultiplier = multiplier;
        multiplier = _newMultiplier;
        emit MultiplierRewardsUpdated(_oldMultiplier, _newMultiplier);
    }

    function updateGovernance(address _newGovernance) external onlyGovernance {
        require(
            _newGovernance != address(0),
            "UpdateGovernance:: New Governance can not be Zero Address"
        );
        address _oldGovernance = governance;
        governance = _newGovernance;
        emit GovernanceUpdated(_oldGovernance, _newGovernance);
    }

    function validatorSignMessage(
        address _userWallet,
        uint256 _amount,
        address _withdrawERC20,
        address _depositedERC20,
        uint256 _nonce,
        bytes32 _txHash
    ) external view returns (bytes memory) {
        return
            abi.encodePacked(
                _userWallet,
                _amount,
                _withdrawERC20,
                _depositedERC20,
                homeChainId,
                foreignChainId,
                _nonce,
                _txHash,
                address(this)
            );
    }

    function tokenPairExist(address _homeERC20, address _foreignERC20)
        external
        view
        returns (bool)
    {
        return
            bridgePairs[_homeERC20]._homeERC20 == _homeERC20 &&
            bridgePairs[_homeERC20]._foreignERC20 == _foreignERC20;
    }

    function getHomePair(address _homeERC20)
        external
        view
        returns (
            address,
            address,
            uint256,
            uint256,
            address,
            uint256,
            uint8
        )
    {
        return (
            bridgePairs[_homeERC20]._homeERC20,
            bridgePairs[_homeERC20]._foreignERC20,
            bridgePairs[_homeERC20]._homeChainId,
            bridgePairs[_homeERC20]._foreignChainId,
            bridgePairs[_homeERC20]._listedBy,
            bridgePairs[_homeERC20]._suspendedBlock,
            bridgePairs[_homeERC20]._isActive
        );
    }

    function isUserBanned(address _wallet) external view returns (bool, bool) {
        return (
            depositWallets[_wallet]._isBanned,
            withdrawalWallets[_wallet]._isBanned
        );
    }

    function isPairSuspended(address _homeERC20, address _foreignERC20)
        external
        view
        returns (uint8, uint256)
    {
        if (
            bridgePairs[_homeERC20]._homeERC20 == _homeERC20 &&
            bridgePairs[_homeERC20]._foreignERC20 == _foreignERC20
        ) {
            return (
                bridgePairs[_homeERC20]._isActive,
                bridgePairs[_homeERC20]._suspendedBlock
            );
        } else {
            return (
                bridgePairs[_homeERC20]._isActive,
                bridgePairs[_homeERC20]._suspendedBlock
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract BridgeTreasury is Context, AccessControl {

    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");
    uint256 public networkId = block.chainid;

    constructor() {
        _setupRole(WITHDRAWER_ROLE, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }
    
    function withdraw(address token, address recipient, uint256 amount) public {
        require(hasRole(WITHDRAWER_ROLE, _msgSender()), "Treasury:: Unauthorized Access, Only Bridge allowed to withdraw");
        IERC20(token).transfer(recipient, amount);
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

library AddressArrayUtils {

  /**
   * Returns whether or not there's a duplicate. Runs in O(n^2).
   * @param A Array to search
   * @return Returns true if duplicate, false otherwise
   */
  function hasDuplicate(address[] memory A) internal pure returns (bool) {
    for (uint256 i = 0; i < A.length - 1; i++) {
      for (uint256 j = i + 1; j < A.length; j++) {
        if (A[i] == A[j]) {
          return true;
        }
      }
    }
    return false;
  }
  
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

library StringLibrary {
    using StringsUpgradeable for uint256;

    function append(string memory _a, string memory _b) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory bab = new bytes(_ba.length + _bb.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
        return string(bab);
    }

    function append(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory bbb = new bytes(_ba.length + _bb.length + _bc.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bbb[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bbb[k++] = _bb[i];
        for (uint i = 0; i < _bc.length; i++) bbb[k++] = _bc[i];
        return string(bbb);
    }

    function recover(string memory message, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        bytes memory msgBytes = bytes(message);
        bytes memory fullMessage = concat(
            bytes("\x19Ethereum Signed Message:\n"),
            bytes(msgBytes.length.toString()),
            msgBytes,
            new bytes(0), new bytes(0), new bytes(0), new bytes(0)
        );
        return ecrecover(keccak256(fullMessage), v, r, s);
    }

    function concat(bytes memory _ba, bytes memory _bb, bytes memory _bc, bytes memory _bd, bytes memory _be, bytes memory _bf, bytes memory _bg) internal pure returns (bytes memory) {
        bytes memory resultBytes = new bytes(_ba.length + _bb.length + _bc.length + _bd.length + _be.length + _bf.length + _bg.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) resultBytes[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) resultBytes[k++] = _bb[i];
        for (uint i = 0; i < _bc.length; i++) resultBytes[k++] = _bc[i];
        for (uint i = 0; i < _bd.length; i++) resultBytes[k++] = _bd[i];
        for (uint i = 0; i < _be.length; i++) resultBytes[k++] = _be[i];
        for (uint i = 0; i < _bf.length; i++) resultBytes[k++] = _bf[i];
        for (uint i = 0; i < _bg.length; i++) resultBytes[k++] = _bg[i];
        return resultBytes;
    }

    function getAddress(bytes memory generatedBytes, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        bytes memory msgBytes = generatedBytes;
        bytes memory fullMessage = concat(
            bytes("\x19Ethereum Signed Message:\n"),
            bytes(msgBytes.length.toString()),
            msgBytes,
            new bytes(0), new bytes(0), new bytes(0), new bytes(0)
        );
        return ecrecover(keccak256(fullMessage), v, r, s);
    }
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}