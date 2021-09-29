pragma solidity 0.5.8;

import "../TransferManager.sol";
import "../../../libraries/Encoder.sol";
import "../../../libraries/VersionUtils.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/cryptography/ECDSA.sol";
import "./GeneralTransferManagerStorage.sol";

/**
 * @title Transfer Manager module for core transfer validation functionality
 */
contract GeneralTransferManager is GeneralTransferManagerStorage, TransferManager {
    using SafeMath for uint256;
    using ECDSA for bytes32;

    // Emit when Issuance address get changed
    event ChangeIssuanceAddress(address _issuanceAddress);

    // Emit when investor details get modified related to their whitelisting
    event ChangeDefaults(uint64 _defaultCanSendAfter, uint64 _defaultCanReceiveAfter);

    // _canSendAfter is the time from which the _investor can send tokens
    // _canReceiveAfter is the time from which the _investor can receive tokens
    // if allowAllWhitelistIssuances is TRUE, then _canReceiveAfter is ignored when receiving tokens from the issuance address
    // if allowAllWhitelistTransfers is TRUE, then _canReceiveAfter and _canSendAfter is ignored when sending or receiving tokens
    // in any case, any investor sending or receiving tokens, must have a _expiryTime in the future
    event ModifyKYCData(
        address indexed _investor,
        address indexed _addedBy,
        uint64 _canSendAfter,
        uint64 _canReceiveAfter,
        uint64 _expiryTime
    );

    event ModifyInvestorFlag(
        address indexed _investor,
        uint8 indexed _flag,
        bool _value
    );

    event ModifyTransferRequirements(
        TransferType indexed _transferType,
        bool _fromValidKYC,
        bool _toValidKYC,
        bool _fromRestricted,
        bool _toRestricted
    );

    /**
     * @notice Constructor
     * @param _securityToken Address of the security token
     */
    constructor(address _securityToken, address _polyToken)
    public
    Module(_securityToken, _polyToken)
    {

    }

    /**
     * @notice This function returns the signature of configure function
     */
    function getInitFunction() public pure returns(bytes4) {
        return bytes4(0);
    }

    /**
     * @notice Used to change the default times used when canSendAfter / canReceiveAfter are zero
     * @param _defaultCanSendAfter default for zero canSendAfter
     * @param _defaultCanReceiveAfter default for zero canReceiveAfter
     */
    function changeDefaults(uint64 _defaultCanSendAfter, uint64 _defaultCanReceiveAfter) public withPerm(ADMIN) {
        /* 0 values are also allowed as they represent that the Issuer
           does not want a default value for these variables.
           0 is also the default value of these variables */
        defaults.canSendAfter = _defaultCanSendAfter;
        defaults.canReceiveAfter = _defaultCanReceiveAfter;
        emit ChangeDefaults(_defaultCanSendAfter, _defaultCanReceiveAfter);
    }

    /**
     * @notice Used to change the Issuance Address
     * @param _issuanceAddress new address for the issuance
     */
    function changeIssuanceAddress(address _issuanceAddress) public withPerm(ADMIN) {
        // address(0x0) is also a valid value and in most cases, the address that issues tokens is 0x0.
        issuanceAddress = _issuanceAddress;
        emit ChangeIssuanceAddress(_issuanceAddress);
    }

    /**
     * @notice Default implementation of verifyTransfer used by SecurityToken
     * If the transfer request comes from the STO, it only checks that the investor is in the whitelist
     * If the transfer request comes from a token holder, it checks that:
     * a) Both are on the whitelist
     * b) Seller's sale lockup period is over
     * c) Buyer's purchase lockup is over
     * @param _from Address of the sender
     * @param _to Address of the receiver
    */
    function executeTransfer(
        address _from,
        address _to,
        uint256 /*_amount*/,
        bytes calldata _data
    ) external returns(Result) {
        if (_data.length > 32) {
            address target;
            uint256 nonce;
            uint256 validFrom;
            uint256 validTo;
            bytes memory data;
            (target, nonce, validFrom, validTo, data) = abi.decode(_data, (address, uint256, uint256, uint256, bytes));
            if (target == address(this))
                _processTransferSignature(nonce, validFrom, validTo, data);
        }
        (Result success,) = _verifyTransfer(_from, _to);
        return success;
    }

    function _processTransferSignature(uint256 _nonce, uint256 _validFrom, uint256 _validTo, bytes memory _data) internal {
        address[] memory investor;
        uint256[] memory canSendAfter;
        uint256[] memory canReceiveAfter;
        uint256[] memory expiryTime;
        bytes memory signature;
        (investor, canSendAfter, canReceiveAfter, expiryTime, signature) =
            abi.decode(_data, (address[], uint256[], uint256[], uint256[], bytes));
        _modifyKYCDataSignedMulti(investor, canSendAfter, canReceiveAfter, expiryTime, _validFrom, _validTo, _nonce, signature);
    }

    /**
     * @notice Default implementation of verifyTransfer used by SecurityToken
     * @param _from Address of the sender
     * @param _to Address of the receiver
    */
    function verifyTransfer(
        address _from,
        address _to,
        uint256 /*_amount*/,
        bytes memory /* _data */
    )
        public
        view
        returns(Result, bytes32)
    {
        return _verifyTransfer(_from, _to);
    }

    function _verifyTransfer(
        address _from,
        address _to
    )
        internal
        view
        returns(Result, bytes32)
    {
        if (!paused) {
            TransferRequirements memory txReq;
            uint64 canSendAfter;
            uint64 fromExpiry;
            uint64 toExpiry;
            uint64 canReceiveAfter;

            if (_from == issuanceAddress) {
                txReq = transferRequirements[uint8(TransferType.ISSUANCE)];
            } else if (_to == address(0)) {
                txReq = transferRequirements[uint8(TransferType.REDEMPTION)];
            } else {
                txReq = transferRequirements[uint8(TransferType.GENERAL)];
            }

            (canSendAfter, fromExpiry, canReceiveAfter, toExpiry) = _getValuesForTransfer(_from, _to);

            if ((txReq.fromValidKYC && !_validExpiry(fromExpiry)) || (txReq.toValidKYC && !_validExpiry(toExpiry))) {
                return (Result.NA, bytes32(0));
            }

            (canSendAfter, canReceiveAfter) = _adjustTimes(canSendAfter, canReceiveAfter);

            if ((txReq.fromRestricted && !_validLockTime(canSendAfter)) || (txReq.toRestricted && !_validLockTime(canReceiveAfter))) {
                return (Result.NA, bytes32(0));
            }

            return (Result.VALID, getAddressBytes32());
        }
        return (Result.NA, bytes32(0));
    }

    /**
    * @notice Modifies the successful checks required for a transfer to be deemed valid.
    * @param _transferType Type of transfer (0 = General, 1 = Issuance, 2 = Redemption)
    * @param _fromValidKYC Defines if KYC is required for the sender
    * @param _toValidKYC Defines if KYC is required for the receiver
    * @param _fromRestricted Defines if transfer time restriction is checked for the sender
    * @param _toRestricted Defines if transfer time restriction is checked for the receiver
    */
    function modifyTransferRequirements(
        TransferType _transferType,
        bool _fromValidKYC,
        bool _toValidKYC,
        bool _fromRestricted,
        bool _toRestricted
    ) public withPerm(ADMIN) {
        _modifyTransferRequirements(
            _transferType,
            _fromValidKYC,
            _toValidKYC,
            _fromRestricted,
            _toRestricted
        );
    }

    /**
    * @notice Modifies the successful checks required for transfers.
    * @param _transferTypes Types of transfer (0 = General, 1 = Issuance, 2 = Redemption)
    * @param _fromValidKYC Defines if KYC is required for the sender
    * @param _toValidKYC Defines if KYC is required for the receiver
    * @param _fromRestricted Defines if transfer time restriction is checked for the sender
    * @param _toRestricted Defines if transfer time restriction is checked for the receiver
    */
    function modifyTransferRequirementsMulti(
        TransferType[] memory _transferTypes,
        bool[] memory _fromValidKYC,
        bool[] memory _toValidKYC,
        bool[] memory _fromRestricted,
        bool[] memory _toRestricted
    ) public withPerm(ADMIN) {
        require(
            _transferTypes.length == _fromValidKYC.length &&
            _fromValidKYC.length == _toValidKYC.length &&
            _toValidKYC.length == _fromRestricted.length &&
            _fromRestricted.length == _toRestricted.length,
            "Mismatched input lengths"
        );

        for (uint256 i = 0; i <  _transferTypes.length; i++) {
            _modifyTransferRequirements(
                _transferTypes[i],
                _fromValidKYC[i],
                _toValidKYC[i],
                _fromRestricted[i],
                _toRestricted[i]
            );
        }
    }

    function _modifyTransferRequirements(
        TransferType _transferType,
        bool _fromValidKYC,
        bool _toValidKYC,
        bool _fromRestricted,
        bool _toRestricted
    ) internal {
        transferRequirements[uint8(_transferType)] =
            TransferRequirements(
                _fromValidKYC,
                _toValidKYC,
                _fromRestricted,
                _toRestricted
            );

        emit ModifyTransferRequirements(
            _transferType,
            _fromValidKYC,
            _toValidKYC,
            _fromRestricted,
            _toRestricted
        );
    }


    /**
    * @notice Add or remove KYC info of an investor.
    * @param _investor is the address to whitelist
    * @param _canSendAfter is the moment when the sale lockup period ends and the investor can freely sell or transfer their tokens
    * @param _canReceiveAfter is the moment when the purchase lockup period ends and the investor can freely purchase or receive tokens from others
    * @param _expiryTime is the moment till investors KYC will be validated. After that investor need to do re-KYC
    */
    function modifyKYCData(
        address _investor,
        uint64 _canSendAfter,
        uint64 _canReceiveAfter,
        uint64 _expiryTime
    )
        public
        withPerm(ADMIN)
    {
        _modifyKYCData(_investor, _canSendAfter, _canReceiveAfter, _expiryTime);
    }

    function _modifyKYCData(address _investor, uint64 _canSendAfter, uint64 _canReceiveAfter, uint64 _expiryTime) internal {
        require(_investor != address(0), "Invalid investor");
        IDataStore dataStore = getDataStore();
        if (!_isExistingInvestor(_investor, dataStore)) {
           dataStore.insertAddress(INVESTORSKEY, _investor);
        }
        uint256 _data = VersionUtils.packKYC(_canSendAfter, _canReceiveAfter, _expiryTime, uint8(1));
        dataStore.setUint256(_getKey(WHITELIST, _investor), _data);
        emit ModifyKYCData(_investor, msg.sender, _canSendAfter, _canReceiveAfter, _expiryTime);
    }

    /**
    * @notice Add or remove KYC info of an investor.
    * @param _investors is the address to whitelist
    * @param _canSendAfter is the moment when the sale lockup period ends and the investor can freely sell his tokens
    * @param _canReceiveAfter is the moment when the purchase lockup period ends and the investor can freely purchase tokens from others
    * @param _expiryTime is the moment till investors KYC will be validated. After that investor need to do re-KYC
    */
    function modifyKYCDataMulti(
        address[] memory _investors,
        uint64[] memory _canSendAfter,
        uint64[] memory _canReceiveAfter,
        uint64[] memory _expiryTime
    )
        public
        withPerm(ADMIN)
    {
        require(
            _investors.length == _canSendAfter.length &&
            _canSendAfter.length == _canReceiveAfter.length &&
            _canReceiveAfter.length == _expiryTime.length,
            "Mismatched input lengths"
        );
        for (uint256 i = 0; i < _investors.length; i++) {
            _modifyKYCData(_investors[i], _canSendAfter[i], _canReceiveAfter[i], _expiryTime[i]);
        }
    }

    /**
    * @notice Used to modify investor Flag.
    * @dev Flags are properties about investors that can be true or false like isAccredited
    * @param _investor is the address of the investor.
    * @param _flag index of flag to change. flag is used to know specifics about investor like isAccredited.
    * @param _value value of the flag. a flag can be true or false.
    */
    function modifyInvestorFlag(
        address _investor,
        uint8 _flag,
        bool _value
    )
        public
        withPerm(ADMIN)
    {
        _modifyInvestorFlag(_investor, _flag, _value);
    }


    function _modifyInvestorFlag(address _investor, uint8 _flag, bool _value) internal {
        require(_investor != address(0), "Invalid investor");
        IDataStore dataStore = getDataStore();
        if (!_isExistingInvestor(_investor, dataStore)) {
           dataStore.insertAddress(INVESTORSKEY, _investor);
           //KYC data can not be present if _isExistingInvestor is false and hence we can set packed KYC as uint256(1) to set `added` as true
           dataStore.setUint256(_getKey(WHITELIST, _investor), uint256(1));
        }
        //NB Flags are packed together in a uint256 to save gas. We can have a maximum of 256 flags.
        uint256 flags = dataStore.getUint256(_getKey(INVESTORFLAGS, _investor));
        if (_value)
            flags = flags | (ONE << _flag);
        else
            flags = flags & ~(ONE << _flag);
        dataStore.setUint256(_getKey(INVESTORFLAGS, _investor), flags);
        emit ModifyInvestorFlag(_investor, _flag, _value);
    }

    /**
    * @notice Used to modify investor data.
    * @param _investors List of the addresses to modify data about.
    * @param _flag index of flag to change. flag is used to know specifics about investor like isAccredited.
    * @param _value value of the flag. a flag can be true or false.
    */
    function modifyInvestorFlagMulti(
        address[] memory _investors,
        uint8[] memory _flag,
        bool[] memory _value
    )
        public
        withPerm(ADMIN)
    {
        require(
            _investors.length == _flag.length &&
            _flag.length == _value.length,
            "Mismatched input lengths"
        );
        for (uint256 i = 0; i < _investors.length; i++) {
            _modifyInvestorFlag(_investors[i], _flag[i], _value[i]);
        }
    }

    /**
    * @notice Adds or removes addresses from the whitelist - can be called by anyone with a valid signature
    * @param _investor is the address to whitelist
    * @param _canSendAfter is the moment when the sale lockup period ends and the investor can freely sell his tokens
    * @param _canReceiveAfter is the moment when the purchase lockup period ends and the investor can freely purchase tokens from others
    * @param _expiryTime is the moment till investors KYC will be validated. After that investor need to do re-KYC
    * @param _validFrom is the time that this signature is valid from
    * @param _validTo is the time that this signature is valid until
    * @param _nonce nonce of signature (avoid replay attack)
    * @param _signature issuer signature
    */
    function modifyKYCDataSigned(
        address _investor,
        uint256 _canSendAfter,
        uint256 _canReceiveAfter,
        uint256 _expiryTime,
        uint256 _validFrom,
        uint256 _validTo,
        uint256 _nonce,
        bytes memory _signature
    )
        public
    {
        require(
            _modifyKYCDataSigned(_investor, _canSendAfter, _canReceiveAfter, _expiryTime, _validFrom, _validTo, _nonce, _signature),
            "Invalid signature or data"
        );
    }

    function _modifyKYCDataSigned(
        address _investor,
        uint256 _canSendAfter,
        uint256 _canReceiveAfter,
        uint256 _expiryTime,
        uint256 _validFrom,
        uint256 _validTo,
        uint256 _nonce,
        bytes memory _signature
    )
        internal
        returns(bool)
    {
        /*solium-disable-next-line security/no-block-members*/
        if(_validFrom > now || _validTo < now || _investor == address(0))
            return false;
        bytes32 hash = keccak256(
            abi.encodePacked(this, _investor, _canSendAfter, _canReceiveAfter, _expiryTime, _validFrom, _validTo, _nonce)
        );
        if (_checkSig(hash, _signature, _nonce)) {
            require(
                uint64(_canSendAfter) == _canSendAfter &&
                uint64(_canReceiveAfter) == _canReceiveAfter &&
                uint64(_expiryTime) == _expiryTime,
                "uint64 overflow"
            );
            _modifyKYCData(_investor, uint64(_canSendAfter), uint64(_canReceiveAfter), uint64(_expiryTime));
            return true;
        }
        return false;
    }

    /**
    * @notice Adds or removes addresses from the whitelist - can be called by anyone with a valid signature
    * @dev using uint256 for some uint256 variables as web3 wasn;t packing and hashing uint64 arrays properly
    * @param _investor is the address to whitelist
    * @param _canSendAfter is the moment when the sale lockup period ends and the investor can freely sell his tokens
    * @param _canReceiveAfter is the moment when the purchase lockup period ends and the investor can freely purchase tokens from others
    * @param _expiryTime is the moment till investors KYC will be validated. After that investor need to do re-KYC
    * @param _validFrom is the time that this signature is valid from
    * @param _validTo is the time that this signature is valid until
    * @param _nonce nonce of signature (avoid replay attack)
    * @param _signature issuer signature
    */
    function modifyKYCDataSignedMulti(
        address[] memory _investor,
        uint256[] memory _canSendAfter,
        uint256[] memory _canReceiveAfter,
        uint256[] memory _expiryTime,
        uint256 _validFrom,
        uint256 _validTo,
        uint256 _nonce,
        bytes memory _signature
    )
        public
    {
        require(
            _modifyKYCDataSignedMulti(_investor, _canSendAfter, _canReceiveAfter, _expiryTime, _validFrom, _validTo, _nonce, _signature),
            "Invalid signature or data"
        );
    }

    function _modifyKYCDataSignedMulti(
        address[] memory _investor,
        uint256[] memory _canSendAfter,
        uint256[] memory _canReceiveAfter,
        uint256[] memory _expiryTime,
        uint256 _validFrom,
        uint256 _validTo,
        uint256 _nonce,
        bytes memory _signature
    )
        internal
        returns(bool)
    {
        if (_investor.length != _canSendAfter.length ||
            _canSendAfter.length != _canReceiveAfter.length ||
            _canReceiveAfter.length != _expiryTime.length
        ) {
            return false;
        }

        if (_validFrom > now || _validTo < now) {
            return false;
        }

        bytes32 hash = keccak256(
            abi.encodePacked(this, _investor, _canSendAfter, _canReceiveAfter, _expiryTime, _validFrom, _validTo, _nonce)
        );

        if (_checkSig(hash, _signature, _nonce)) {
            for (uint256 i = 0; i < _investor.length; i++) {
                if (uint64(_canSendAfter[i]) == _canSendAfter[i] &&
                    uint64(_canReceiveAfter[i]) == _canReceiveAfter[i] &&
                    uint64(_expiryTime[i]) == _expiryTime[i]
                )
                    _modifyKYCData(_investor[i], uint64(_canSendAfter[i]), uint64(_canReceiveAfter[i]), uint64(_expiryTime[i]));
            }
            return true;
        }
        return false;
    }

    /**
     * @notice Used to verify the signature
     */
    function _checkSig(bytes32 _hash, bytes memory _signature, uint256 _nonce) internal returns(bool) {
        //Check that the signature is valid
        //sig should be signing - _investor, _canSendAfter, _canReceiveAfter & _expiryTime and be signed by the issuer address
        address signer = _hash.toEthSignedMessageHash().recover(_signature);
        if (nonceMap[signer][_nonce] || !_checkPerm(OPERATOR, signer)) {
            return false;
        }
        nonceMap[signer][_nonce] = true;
        return true;
    }

    /**
     * @notice Internal function used to check whether the KYC of investor is valid
     * @param _expiryTime Expiry time of the investor
     */
    function _validExpiry(uint64 _expiryTime) internal view returns(bool valid) {
        if (_expiryTime >= uint64(now)) /*solium-disable-line security/no-block-members*/
            valid = true;
    }

    /**
     * @notice Internal function used to check whether the lock time of investor is valid
     * @param _lockTime Lock time of the investor
     */
    function _validLockTime(uint64 _lockTime) internal view returns(bool valid) {
        if (_lockTime <= uint64(now)) /*solium-disable-line security/no-block-members*/
            valid = true;
    }

    /**
     * @notice Internal function to adjust times using default values
     */
    function _adjustTimes(uint64 _canSendAfter, uint64 _canReceiveAfter) internal view returns(uint64, uint64) {
        if (_canSendAfter == 0) {
            _canSendAfter = defaults.canSendAfter;
        }
        if (_canReceiveAfter == 0) {
            _canReceiveAfter = defaults.canReceiveAfter;
        }
        return (_canSendAfter, _canReceiveAfter);
    }

    function _getKey(bytes32 _key1, address _key2) internal pure returns(bytes32) {
        return bytes32(keccak256(abi.encodePacked(_key1, _key2)));
    }

    function _getKYCValues(address _investor, IDataStore dataStore) internal view returns(
        uint64 canSendAfter,
        uint64 canReceiveAfter,
        uint64 expiryTime,
        uint8 added
    )
    {
        uint256 data = dataStore.getUint256(_getKey(WHITELIST, _investor));
        (canSendAfter, canReceiveAfter, expiryTime, added)  = VersionUtils.unpackKYC(data);
    }

    function _isExistingInvestor(address _investor, IDataStore dataStore) internal view returns(bool) {
        uint256 data = dataStore.getUint256(_getKey(WHITELIST, _investor));
        //extracts `added` from packed `_whitelistData`
        return uint8(data) == 0 ? false : true;
    }

    function _getValuesForTransfer(address _from, address _to) internal view returns(uint64 canSendAfter, uint64 fromExpiry, uint64 canReceiveAfter, uint64 toExpiry) {
        IDataStore dataStore = getDataStore();
        (canSendAfter, , fromExpiry, ) = _getKYCValues(_from, dataStore);
        (, canReceiveAfter, toExpiry, ) = _getKYCValues(_to, dataStore);
    }

    /**
     * @dev Returns list of all investors
     */
    function getAllInvestors() public view returns(address[] memory investors) {
        IDataStore dataStore = getDataStore();
        investors = dataStore.getAddressArray(INVESTORSKEY);
    }

    /**
     * @dev Returns list of investors in a range
     */
    function getInvestors(uint256 _fromIndex, uint256 _toIndex) public view returns(address[] memory investors) {
        IDataStore dataStore = getDataStore();
        investors = dataStore.getAddressArrayElements(INVESTORSKEY, _fromIndex, _toIndex);
    }

    function getAllInvestorFlags() public view returns(address[] memory investors, uint256[] memory flags) {
        investors = getAllInvestors();
        flags = new uint256[](investors.length);
        for (uint256 i = 0; i < investors.length; i++) {
            flags[i] = _getInvestorFlags(investors[i]);
        }
    }

    function getInvestorFlag(address _investor, uint8 _flag) public view returns(bool value) {
        uint256 flag = (_getInvestorFlags(_investor) >> _flag) & ONE;
        value = flag > 0 ? true : false;
    }

    function getInvestorFlags(address _investor) public view returns(uint256 flags) {
        flags = _getInvestorFlags(_investor);
    }

    function _getInvestorFlags(address _investor) internal view returns(uint256 flags) {
        IDataStore dataStore = getDataStore();
        flags = dataStore.getUint256(_getKey(INVESTORFLAGS, _investor));
    }

    /**
     * @dev Returns list of all investors data
     */
    function getAllKYCData() external view returns(
        address[] memory investors,
        uint256[] memory canSendAfters,
        uint256[] memory canReceiveAfters,
        uint256[] memory expiryTimes
    ) {
        investors = getAllInvestors();
        (canSendAfters, canReceiveAfters, expiryTimes) = _kycData(investors);
        return (investors, canSendAfters, canReceiveAfters, expiryTimes);
    }

    /**
     * @dev Returns list of specified investors data
     */
    function getKYCData(address[] calldata _investors) external view returns(
        uint256[] memory,
        uint256[] memory,
        uint256[] memory
    ) {
        return _kycData(_investors);
    }

    function _kycData(address[] memory _investors) internal view returns(
        uint256[] memory,
        uint256[] memory,
        uint256[] memory
    ) {
        uint256[] memory canSendAfters = new uint256[](_investors.length);
        uint256[] memory canReceiveAfters = new uint256[](_investors.length);
        uint256[] memory expiryTimes = new uint256[](_investors.length);
        for (uint256 i = 0; i < _investors.length; i++) {
            (canSendAfters[i], canReceiveAfters[i], expiryTimes[i], ) = _getKYCValues(_investors[i], getDataStore());
        }
        return (canSendAfters, canReceiveAfters, expiryTimes);
    }

    /**
     * @notice Return the permissions flag that are associated with general trnasfer manager
     */
    function getPermissions() public view returns(bytes32[] memory) {
        bytes32[] memory allPermissions = new bytes32[](1);
        allPermissions[0] = ADMIN;
        return allPermissions;
    }

    /**
     * @notice return the amount of tokens for a given user as per the partition
     * @param _partition Identifier
     * @param _tokenHolder Whom token amount need to query
     * @param _additionalBalance It is the `_value` that transfer during transfer/transferFrom function call
     */
    function getTokensByPartition(bytes32 _partition, address _tokenHolder, uint256 _additionalBalance) external view returns(uint256) {
        uint256 currentBalance = (msg.sender == address(securityToken)) ? (securityToken.balanceOf(_tokenHolder)).add(_additionalBalance) : securityToken.balanceOf(_tokenHolder);
        uint256 canSendAfter;
        (canSendAfter,,,) = _getKYCValues(_tokenHolder, getDataStore());
        canSendAfter = (canSendAfter == 0 ? defaults.canSendAfter:  canSendAfter);
        bool unlockedCheck = paused ? _partition == UNLOCKED : (_partition == UNLOCKED && now >= canSendAfter);
        if (((_partition == LOCKED && now < canSendAfter) && !paused) || unlockedCheck)
            return currentBalance;
        else
            return 0;
    }

    function getAddressBytes32() public view returns(bytes32) {
        return bytes32(uint256(address(this)) << 96);
    }

}

pragma solidity 0.5.8;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/ISecurityToken.sol";
/**
 * @title Storage for Module contract
 * @notice Contract is abstract
 */
contract ModuleStorage {
    address public factory;

    ISecurityToken public securityToken;

    // Permission flag
    bytes32 public constant ADMIN = "ADMIN";
    bytes32 public constant OPERATOR = "OPERATOR";

    bytes32 internal constant TREASURY = 0xaae8817359f3dcb67d050f44f3e49f982e0359d90ca4b5f18569926304aaece6; // keccak256(abi.encodePacked("TREASURY_WALLET"))

    IERC20 public polyToken;

    /**
     * @notice Constructor
     * @param _securityToken Address of the security token
     * @param _polyAddress Address of the polytoken
     */
    constructor(address _securityToken, address _polyAddress) public {
        securityToken = ISecurityToken(_securityToken);
        factory = msg.sender;
        polyToken = IERC20(_polyAddress);
    }

}

pragma solidity 0.5.8;

import "../Module.sol";
import "../../interfaces/ITransferManager.sol";

/**
 * @title Base abstract contract to be implemented by all Transfer Manager modules
 */
contract TransferManager is ITransferManager, Module {

    bytes32 public constant LOCKED = "LOCKED";
    bytes32 public constant UNLOCKED = "UNLOCKED";

    modifier onlySecurityToken() {
        require(msg.sender == address(securityToken), "Sender is not owner");
        _;
    }

    // Provide default versions of ERC1410 functions that can be overriden

    /**
     * @notice return the amount of tokens for a given user as per the partition
     * @dev returning the balance of token holder against the UNLOCKED partition. 
     * This condition is valid only when the base contract doesn't implement the
     * `getTokensByPartition()` function.  
     */
    function getTokensByPartition(bytes32 _partition, address _tokenHolder, uint256 /*_additionalBalance*/) external view returns(uint256) {
        if (_partition == UNLOCKED)
            return securityToken.balanceOf(_tokenHolder);
        return uint256(0);
    }

}

pragma solidity 0.5.8;

/**
 * @title Transfer Manager module for core transfer validation functionality
 */
contract GeneralTransferManagerStorage {

    bytes32 public constant WHITELIST = "WHITELIST";
    bytes32 public constant INVESTORSKEY = 0xdf3a8dd24acdd05addfc6aeffef7574d2de3f844535ec91e8e0f3e45dba96731; //keccak256(abi.encodePacked("INVESTORS"))
    bytes32 public constant INVESTORFLAGS = "INVESTORFLAGS";
    uint256 internal constant ONE = uint256(1);

    enum TransferType { GENERAL, ISSUANCE, REDEMPTION }

    //Address from which issuances come
    address public issuanceAddress;

    // Allows all TimeRestrictions to be offset
    struct Defaults {
        uint64 canSendAfter;
        uint64 canReceiveAfter;
    }

    // Offset to be applied to all timings (except KYC expiry)
    Defaults public defaults;

    // Map of used nonces by customer
    mapping(address => mapping(uint256 => bool)) public nonceMap;

    struct TransferRequirements {
        bool fromValidKYC;
        bool toValidKYC;
        bool fromRestricted;
        bool toRestricted;
    }

    mapping(uint8 => TransferRequirements) public transferRequirements;
    // General = 0, Issuance = 1, Redemption = 2
}

pragma solidity 0.5.8;

import "../interfaces/IModule.sol";
import "../Pausable.sol";
import "../interfaces/IModuleFactory.sol";
import "../interfaces/IDataStore.sol";
import "../interfaces/ISecurityToken.sol";
import "../interfaces/ICheckPermission.sol";
import "../storage/modules/ModuleStorage.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

/**
 * @title Interface that any module contract should implement
 * @notice Contract is abstract
 */
contract Module is IModule, ModuleStorage, Pausable {
    /**
     * @notice Constructor
     * @param _securityToken Address of the security token
     */
    constructor (address _securityToken, address _polyAddress) public
    ModuleStorage(_securityToken, _polyAddress)
    {
    }

    //Allows owner, factory or permissioned delegate
    modifier withPerm(bytes32 _perm) {
        require(_checkPerm(_perm, msg.sender), "Invalid permission");
        _;
    }

    function _checkPerm(bytes32 _perm, address _caller) internal view returns (bool) {
        bool isOwner = _caller == Ownable(address(securityToken)).owner();
        bool isFactory = _caller == factory;
        return isOwner || isFactory || ICheckPermission(address(securityToken)).checkPermission(_caller, address(this), _perm);
    }

    function _onlySecurityTokenOwner() internal view {
        require(msg.sender == Ownable(address(securityToken)).owner(), "Sender is not owner");
    }

    modifier onlyFactory() {
        require(msg.sender == factory, "Sender is not factory");
        _;
    }

    /**
     * @notice Pause (overridden function)
     */
    function pause() public {
        _onlySecurityTokenOwner();
        super._pause();
    }

    /**
     * @notice Unpause (overridden function)
     */
    function unpause() public {
        _onlySecurityTokenOwner();
        super._unpause();
    }

    /**
     * @notice used to return the data store address of securityToken
     */
    function getDataStore() public view returns(IDataStore) {
        return IDataStore(securityToken.dataStore());
    }

    /**
    * @notice Reclaims ERC20Basic compatible tokens
    * @dev We duplicate here due to the overriden owner & onlyOwner
    * @param _tokenContract The address of the token contract
    */
    function reclaimERC20(address _tokenContract) external {
        _onlySecurityTokenOwner();
        require(_tokenContract != address(0), "Invalid address");
        IERC20 token = IERC20(_tokenContract);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(msg.sender, balance), "Transfer failed");
    }

   /**
    * @notice Reclaims ETH
    * @dev We duplicate here due to the overriden owner & onlyOwner
    */
    function reclaimETH() external {
        _onlySecurityTokenOwner();
        msg.sender.transfer(address(this).balance);
    }
}

pragma solidity 0.5.8;

/**
 * @title Helper library use to compare or validate the semantic versions
 */

library VersionUtils {

    function lessThanOrEqual(uint8[] memory _current, uint8[] memory _new) internal pure returns(bool) {
        require(_current.length == 3);
        require(_new.length == 3);
        uint8 i = 0;
        for (i = 0; i < _current.length; i++) {
            if (_current[i] == _new[i]) continue;
            if (_current[i] < _new[i]) return true;
            if (_current[i] > _new[i]) return false;
        }
        return true;
    }

    function greaterThanOrEqual(uint8[] memory _current, uint8[] memory _new) internal pure returns(bool) {
        require(_current.length == 3);
        require(_new.length == 3);
        uint8 i = 0;
        for (i = 0; i < _current.length; i++) {
            if (_current[i] == _new[i]) continue;
            if (_current[i] > _new[i]) return true;
            if (_current[i] < _new[i]) return false;
        }
        return true;
    }

    /**
     * @notice Used to pack the uint8[] array data into uint24 value
     * @param _major Major version
     * @param _minor Minor version
     * @param _patch Patch version
     */
    function pack(uint8 _major, uint8 _minor, uint8 _patch) internal pure returns(uint24) {
        return (uint24(_major) << 16) | (uint24(_minor) << 8) | uint24(_patch);
    }

    /**
     * @notice Used to convert packed data into uint8 array
     * @param _packedVersion Packed data
     */
    function unpack(uint24 _packedVersion) internal pure returns(uint8[] memory) {
        uint8[] memory _unpackVersion = new uint8[](3);
        _unpackVersion[0] = uint8(_packedVersion >> 16);
        _unpackVersion[1] = uint8(_packedVersion >> 8);
        _unpackVersion[2] = uint8(_packedVersion);
        return _unpackVersion;
    }


    /**
     * @notice Used to packed the KYC data
     */
    function packKYC(uint64 _a, uint64 _b, uint64 _c, uint8 _d) internal pure returns(uint256) {
        // this function packs 3 uint64 and a uint8 together in a uint256 to save storage cost
        // a is rotated left by 136 bits, b is rotated left by 72 bits and c is rotated left by 8 bits.
        // rotation pads empty bits with zeroes so now we can safely do a bitwise OR operation to pack
        // all the variables together.
        return (uint256(_a) << 136) | (uint256(_b) << 72) | (uint256(_c) << 8) | uint256(_d);
    }

    /**
     * @notice Used to convert packed data into KYC data
     * @param _packedVersion Packed data
     */
    function unpackKYC(uint256 _packedVersion) internal pure returns(uint64 canSendAfter, uint64 canReceiveAfter, uint64 expiryTime, uint8 added) {
        canSendAfter = uint64(_packedVersion >> 136);
        canReceiveAfter = uint64(_packedVersion >> 72);
        expiryTime = uint64(_packedVersion >> 8);
        added = uint8(_packedVersion);
    }
}

pragma solidity 0.5.8;

library Encoder {
    function getKey(string memory _key) internal pure returns(bytes32) {
        return bytes32(keccak256(abi.encodePacked(_key)));
    }

    function getKey(string memory _key1, address _key2) internal pure returns(bytes32) {
        return bytes32(keccak256(abi.encodePacked(_key1, _key2)));
    }

    function getKey(string memory _key1, string memory _key2) internal pure returns(bytes32) {
        return bytes32(keccak256(abi.encodePacked(_key1, _key2)));
    }

    function getKey(string memory _key1, uint256 _key2) internal pure returns(bytes32) {
        return bytes32(keccak256(abi.encodePacked(_key1, _key2)));
    }

    function getKey(string memory _key1, bytes32 _key2) internal pure returns(bytes32) {
        return bytes32(keccak256(abi.encodePacked(_key1, _key2)));
    }

    function getKey(string memory _key1, bool _key2) internal pure returns(bytes32) {
        return bytes32(keccak256(abi.encodePacked(_key1, _key2)));
    }

}

pragma solidity 0.5.8;

/**
 * @title Interface to be implemented by all Transfer Manager modules
 */
interface ITransferManager {
    //  If verifyTransfer returns:
    //  FORCE_VALID, the transaction will always be valid, regardless of other TM results
    //  INVALID, then the transfer should not be allowed regardless of other TM results
    //  VALID, then the transfer is valid for this TM
    //  NA, then the result from this TM is ignored
    enum Result {INVALID, NA, VALID, FORCE_VALID}

    /**
     * @notice Determines if the transfer between these two accounts can happen
     */
    function executeTransfer(address _from, address _to, uint256 _amount, bytes calldata _data) external returns(Result result);

    function verifyTransfer(address _from, address _to, uint256 _amount, bytes calldata _data) external view returns(Result result, bytes32 partition);

    /**
     * @notice return the amount of tokens for a given user as per the partition
     * @param _partition Identifier
     * @param _tokenHolder Whom token amount need to query
     * @param _additionalBalance It is the `_value` that transfer during transfer/transferFrom function call
     */
    function getTokensByPartition(bytes32 _partition, address _tokenHolder, uint256 _additionalBalance) external view returns(uint256 amount);

}

pragma solidity 0.5.8;

/**
 * @title Interface for all security tokens
 */
interface ISecurityToken {
    // Standard ERC20 interface
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns(uint8);
    function totalSupply() external view returns(uint256);
    function balanceOf(address owner) external view returns(uint256);
    function allowance(address owner, address spender) external view returns(uint256);
    function transfer(address to, uint256 value) external returns(bool);
    function transferFrom(address from, address to, uint256 value) external returns(bool);
    function approve(address spender, uint256 value) external returns(bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @notice Transfers of securities may fail for a number of reasons. So this function will used to understand the
     * cause of failure by getting the byte value. Which will be the ESC that follows the EIP 1066. ESC can be mapped
     * with a reson string to understand the failure cause, table of Ethereum status code will always reside off-chain
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     * @param _data The `bytes _data` allows arbitrary data to be submitted alongside the transfer.
     * @return byte Ethereum status code (ESC)
     * @return bytes32 Application specific reason code
     */
    function canTransfer(address _to, uint256 _value, bytes calldata _data) external view returns (byte statusCode, bytes32 reasonCode);

    // Emit at the time when module get added
    event ModuleAdded(
        uint8[] _types,
        bytes32 indexed _name,
        address indexed _moduleFactory,
        address _module,
        uint256 _moduleCost,
        uint256 _budget,
        bytes32 _label,
        bool _archived
    );

    // Emit when the token details get updated
    event UpdateTokenDetails(string _oldDetails, string _newDetails);
    // Emit when the token name get updated
    event UpdateTokenName(string _oldName, string _newName);
    // Emit when the granularity get changed
    event GranularityChanged(uint256 _oldGranularity, uint256 _newGranularity);
    // Emit when is permanently frozen by the issuer
    event FreezeIssuance();
    // Emit when transfers are frozen or unfrozen
    event FreezeTransfers(bool _status);
    // Emit when new checkpoint created
    event CheckpointCreated(uint256 indexed _checkpointId, uint256 _investorLength);
    // Events to log controller actions
    event SetController(address indexed _oldController, address indexed _newController);
    //Event emit when the global treasury wallet address get changed
    event TreasuryWalletChanged(address _oldTreasuryWallet, address _newTreasuryWallet);
    event DisableController();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TokenUpgraded(uint8 _major, uint8 _minor, uint8 _patch);

    // Emit when Module get archived from the securityToken
    event ModuleArchived(uint8[] _types, address _module); //Event emitted by the tokenLib.
    // Emit when Module get unarchived from the securityToken
    event ModuleUnarchived(uint8[] _types, address _module); //Event emitted by the tokenLib.
    // Emit when Module get removed from the securityToken
    event ModuleRemoved(uint8[] _types, address _module); //Event emitted by the tokenLib.
    // Emit when the budget allocated to a module is changed
    event ModuleBudgetChanged(uint8[] _moduleTypes, address _module, uint256 _oldBudget, uint256 _budget); //Event emitted by the tokenLib.

    // Transfer Events
    event TransferByPartition(
        bytes32 indexed _fromPartition,
        address _operator,
        address indexed _from,
        address indexed _to,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

    // Operator Events
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
    event RevokedOperator(address indexed operator, address indexed tokenHolder);
    event AuthorizedOperatorByPartition(bytes32 indexed partition, address indexed operator, address indexed tokenHolder);
    event RevokedOperatorByPartition(bytes32 indexed partition, address indexed operator, address indexed tokenHolder);

    // Issuance / Redemption Events
    event IssuedByPartition(bytes32 indexed partition, address indexed to, uint256 value, bytes data);
    event RedeemedByPartition(bytes32 indexed partition, address indexed operator, address indexed from, uint256 value, bytes data, bytes operatorData);

    // Document Events
    event DocumentRemoved(bytes32 indexed _name, string _uri, bytes32 _documentHash);
    event DocumentUpdated(bytes32 indexed _name, string _uri, bytes32 _documentHash);

    // Controller Events
    event ControllerTransfer(
        address _controller,
        address indexed _from,
        address indexed _to,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

    event ControllerRedemption(
        address _controller,
        address indexed _tokenHolder,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

    // Issuance / Redemption Events
    event Issued(address indexed _operator, address indexed _to, uint256 _value, bytes _data);
    event Redeemed(address indexed _operator, address indexed _from, uint256 _value, bytes _data);

    /**
     * @notice Initialization function
     * @dev Expected to be called atomically with the proxy being created, by the owner of the token
     * @dev Can only be called once
     */
    function initialize(address _getterDelegate) external;

    /**
     * @notice The standard provides an on-chain function to determine whether a transfer will succeed,
     * and return details indicating the reason if the transfer is not valid.
     * @param _from The address from whom the tokens get transferred.
     * @param _to The address to which to transfer tokens to.
     * @param _partition The partition from which to transfer tokens
     * @param _value The amount of tokens to transfer from `_partition`
     * @param _data Additional data attached to the transfer of tokens
     * @return ESC (Ethereum Status Code) following the EIP-1066 standard
     * @return Application specific reason codes with additional details
     * @return The partition to which the transferred tokens were allocated for the _to address
     */
    function canTransferByPartition(
        address _from,
        address _to,
        bytes32 _partition,
        uint256 _value,
        bytes calldata _data
    )
        external
        view
        returns (byte statusCode, bytes32 reasonCode, bytes32 partition);

    /**
     * @notice Transfers of securities may fail for a number of reasons. So this function will used to understand the
     * cause of failure by getting the byte value. Which will be the ESC that follows the EIP 1066. ESC can be mapped
     * with a reson string to understand the failure cause, table of Ethereum status code will always reside off-chain
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     * @param _data The `bytes _data` allows arbitrary data to be submitted alongside the transfer.
     * @return byte Ethereum status code (ESC)
     * @return bytes32 Application specific reason code
     */
    function canTransferFrom(address _from, address _to, uint256 _value, bytes calldata _data) external view returns (byte statusCode, bytes32 reasonCode);

    /**
     * @notice Used to attach a new document to the contract, or update the URI or hash of an existing attached document
     * @dev Can only be executed by the owner of the contract.
     * @param _name Name of the document. It should be unique always
     * @param _uri Off-chain uri of the document from where it is accessible to investors/advisors to read.
     * @param _documentHash hash (of the contents) of the document.
     */
    function setDocument(bytes32 _name, string calldata _uri, bytes32 _documentHash) external;

    /**
     * @notice Used to remove an existing document from the contract by giving the name of the document.
     * @dev Can only be executed by the owner of the contract.
     * @param _name Name of the document. It should be unique always
     */
    function removeDocument(bytes32 _name) external;

    /**
     * @notice Used to return the details of a document with a known name (`bytes32`).
     * @param _name Name of the document
     * @return string The URI associated with the document.
     * @return bytes32 The hash (of the contents) of the document.
     * @return uint256 the timestamp at which the document was last modified.
     */
    function getDocument(bytes32 _name) external view returns (string memory documentUri, bytes32 documentHash, uint256 documentTime);

    /**
     * @notice Used to retrieve a full list of documents attached to the smart contract.
     * @return bytes32 List of all documents names present in the contract.
     */
    function getAllDocuments() external view returns (bytes32[] memory documentNames);

    /**
     * @notice In order to provide transparency over whether `controllerTransfer` / `controllerRedeem` are useable
     * or not `isControllable` function will be used.
     * @dev If `isControllable` returns `false` then it always return `false` and
     * `controllerTransfer` / `controllerRedeem` will always revert.
     * @return bool `true` when controller address is non-zero otherwise return `false`.
     */
    function isControllable() external view returns (bool controlled);

    /**
     * @notice Checks if an address is a module of certain type
     * @param _module Address to check
     * @param _type type to check against
     */
    function isModule(address _module, uint8 _type) external view returns(bool isValid);

    /**
     * @notice This function must be called to increase the total supply (Corresponds to mint function of ERC20).
     * @dev It only be called by the token issuer or the operator defined by the issuer. ERC1594 doesn't have
     * have the any logic related to operator but its superset ERC1400 have the operator logic and this function
     * is allowed to call by the operator.
     * @param _tokenHolder The account that will receive the created tokens (account should be whitelisted or KYCed).
     * @param _value The amount of tokens need to be issued
     * @param _data The `bytes _data` allows arbitrary data to be submitted alongside the transfer.
     */
    function issue(address _tokenHolder, uint256 _value, bytes calldata _data) external;

    /**
     * @notice issue new tokens and assigns them to the target _tokenHolder.
     * @dev Can only be called by the issuer or STO attached to the token.
     * @param _tokenHolders A list of addresses to whom the minted tokens will be dilivered
     * @param _values A list of number of tokens get minted and transfer to corresponding address of the investor from _tokenHolders[] list
     * @return success
     */
    function issueMulti(address[] calldata _tokenHolders, uint256[] calldata _values) external;

    /**
     * @notice Increases totalSupply and the corresponding amount of the specified owners partition
     * @param _partition The partition to allocate the increase in balance
     * @param _tokenHolder The token holder whose balance should be increased
     * @param _value The amount by which to increase the balance
     * @param _data Additional data attached to the minting of tokens
     */
    function issueByPartition(bytes32 _partition, address _tokenHolder, uint256 _value, bytes calldata _data) external;

    /**
     * @notice Decreases totalSupply and the corresponding amount of the specified partition of msg.sender
     * @param _partition The partition to allocate the decrease in balance
     * @param _value The amount by which to decrease the balance
     * @param _data Additional data attached to the burning of tokens
     */
    function redeemByPartition(bytes32 _partition, uint256 _value, bytes calldata _data) external;

    /**
     * @notice This function redeem an amount of the token of a msg.sender. For doing so msg.sender may incentivize
     * using different ways that could be implemented with in the `redeem` function definition. But those implementations
     * are out of the scope of the ERC1594.
     * @param _value The amount of tokens need to be redeemed
     * @param _data The `bytes _data` it can be used in the token contract to authenticate the redemption.
     */
    function redeem(uint256 _value, bytes calldata _data) external;

    /**
     * @notice This function redeem an amount of the token of a msg.sender. For doing so msg.sender may incentivize
     * using different ways that could be implemented with in the `redeem` function definition. But those implementations
     * are out of the scope of the ERC1594.
     * @dev It is analogy to `transferFrom`
     * @param _tokenHolder The account whose tokens gets redeemed.
     * @param _value The amount of tokens need to be redeemed
     * @param _data The `bytes _data` it can be used in the token contract to authenticate the redemption.
     */
    function redeemFrom(address _tokenHolder, uint256 _value, bytes calldata _data) external;

    /**
     * @notice Decreases totalSupply and the corresponding amount of the specified partition of tokenHolder
     * @dev This function can only be called by the authorised operator.
     * @param _partition The partition to allocate the decrease in balance.
     * @param _tokenHolder The token holder whose balance should be decreased
     * @param _value The amount by which to decrease the balance
     * @param _data Additional data attached to the burning of tokens
     * @param _operatorData Additional data attached to the transfer of tokens by the operator
     */
    function operatorRedeemByPartition(
        bytes32 _partition,
        address _tokenHolder,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _operatorData
    ) external;

    /**
     * @notice Validate permissions with PermissionManager if it exists, If no Permission return false
     * @dev Note that IModule withPerm will allow ST owner all permissions anyway
     * @dev this allows individual modules to override this logic if needed (to not allow ST owner all permissions)
     * @param _delegate address of delegate
     * @param _module address of PermissionManager module
     * @param _perm the permissions
     * @return success
     */
    function checkPermission(address _delegate, address _module, bytes32 _perm) external view returns(bool hasPermission);

    /**
     * @notice Returns module list for a module type
     * @param _module Address of the module
     * @return bytes32 Name
     * @return address Module address
     * @return address Module factory address
     * @return bool Module archived
     * @return uint8 Array of module types
     * @return bytes32 Module label
     */
    function getModule(address _module) external view returns (bytes32 moduleName, address moduleAddress, address factoryAddress, bool isArchived, uint8[] memory moduleTypes, bytes32 moduleLabel);

    /**
     * @notice Returns module list for a module name
     * @param _name Name of the module
     * @return address[] List of modules with this name
     */
    function getModulesByName(bytes32 _name) external view returns(address[] memory modules);

    /**
     * @notice Returns module list for a module type
     * @param _type Type of the module
     * @return address[] List of modules with this type
     */
    function getModulesByType(uint8 _type) external view returns(address[] memory modules);

    /**
     * @notice use to return the global treasury wallet
     */
    function getTreasuryWallet() external view returns(address treasuryWallet);

    /**
     * @notice Queries totalSupply at a specified checkpoint
     * @param _checkpointId Checkpoint ID to query as of
     */
    function totalSupplyAt(uint256 _checkpointId) external view returns(uint256 supply);

    /**
     * @notice Queries balance at a specified checkpoint
     * @param _investor Investor to query balance for
     * @param _checkpointId Checkpoint ID to query as of
     */
    function balanceOfAt(address _investor, uint256 _checkpointId) external view returns(uint256 balance);

    /**
     * @notice Creates a checkpoint that can be used to query historical balances / totalSuppy
     */
    function createCheckpoint() external returns(uint256 checkpointId);

    /**
     * @notice Gets list of times that checkpoints were created
     * @return List of checkpoint times
     */
    function getCheckpointTimes() external view returns(uint256[] memory checkpointTimes);

    /**
     * @notice returns an array of investors
     * NB - this length may differ from investorCount as it contains all investors that ever held tokens
     * @return list of addresses
     */
    function getInvestors() external view returns(address[] memory investors);

    /**
     * @notice returns an array of investors at a given checkpoint
     * NB - this length may differ from investorCount as it contains all investors that ever held tokens
     * @param _checkpointId Checkpoint id at which investor list is to be populated
     * @return list of investors
     */
    function getInvestorsAt(uint256 _checkpointId) external view returns(address[] memory investors);

    /**
     * @notice returns an array of investors with non zero balance at a given checkpoint
     * @param _checkpointId Checkpoint id at which investor list is to be populated
     * @param _start Position of investor to start iteration from
     * @param _end Position of investor to stop iteration at
     * @return list of investors
     */
    function getInvestorsSubsetAt(uint256 _checkpointId, uint256 _start, uint256 _end) external view returns(address[] memory investors);

    /**
     * @notice generates subset of investors
     * NB - can be used in batches if investor list is large
     * @param _start Position of investor to start iteration from
     * @param _end Position of investor to stop iteration at
     * @return list of investors
     */
    function iterateInvestors(uint256 _start, uint256 _end) external view returns(address[] memory investors);

    /**
     * @notice Gets current checkpoint ID
     * @return Id
     */
    function currentCheckpointId() external view returns(uint256 checkpointId);

    /**
     * @notice Determines whether `_operator` is an operator for all partitions of `_tokenHolder`
     * @param _operator The operator to check
     * @param _tokenHolder The token holder to check
     * @return Whether the `_operator` is an operator for all partitions of `_tokenHolder`
     */
    function isOperator(address _operator, address _tokenHolder) external view returns (bool isValid);

    /**
     * @notice Determines whether `_operator` is an operator for a specified partition of `_tokenHolder`
     * @param _partition The partition to check
     * @param _operator The operator to check
     * @param _tokenHolder The token holder to check
     * @return Whether the `_operator` is an operator for a specified partition of `_tokenHolder`
     */
    function isOperatorForPartition(bytes32 _partition, address _operator, address _tokenHolder) external view returns (bool isValid);

    /**
     * @notice Return all partitions
     * @param _tokenHolder Whom balance need to queried
     * @return List of partitions
     */
    function partitionsOf(address _tokenHolder) external view returns (bytes32[] memory partitions);

    /**
     * @notice Gets data store address
     * @return data store address
     */
    function dataStore() external view returns (address dataStoreAddress);

    /**
    * @notice Allows owner to change data store
    * @param _dataStore Address of the token data store
    */
    function changeDataStore(address _dataStore) external;


    /**
     * @notice Allows to change the treasury wallet address
     * @param _wallet Ethereum address of the treasury wallet
     */
    function changeTreasuryWallet(address _wallet) external;

    /**
     * @notice Allows the owner to withdraw unspent POLY stored by them on the ST or any ERC20 token.
     * @dev Owner can transfer POLY to the ST which will be used to pay for modules that require a POLY fee.
     * @param _tokenContract Address of the ERC20Basic compliance token
     * @param _value Amount of POLY to withdraw
     */
    function withdrawERC20(address _tokenContract, uint256 _value) external;

    /**
    * @notice Allows owner to increase/decrease POLY approval of one of the modules
    * @param _module Module address
    * @param _change Change in allowance
    * @param _increase True if budget has to be increased, false if decrease
    */
    function changeModuleBudget(address _module, uint256 _change, bool _increase) external;

    /**
     * @notice Changes the tokenDetails
     * @param _newTokenDetails New token details
     */
    function updateTokenDetails(string calldata _newTokenDetails) external;

    /**
    * @notice Allows owner to change token name
    * @param _name new name of the token
    */
    function changeName(string calldata _name) external;

    /**
    * @notice Allows the owner to change token granularity
    * @param _granularity Granularity level of the token
    */
    function changeGranularity(uint256 _granularity) external;

    /**
     * @notice Freezes all the transfers
     */
    function freezeTransfers() external;

    /**
     * @notice Un-freezes all the transfers
     */
    function unfreezeTransfers() external;

    /**
     * @notice Permanently freeze issuance of this security token.
     * @dev It MUST NOT be possible to increase `totalSuppy` after this function is called.
     */
    function freezeIssuance(bytes calldata _signature) external;

    /**
      * @notice Attachs a module to the SecurityToken
      * @dev  E.G.: On deployment (through the STR) ST gets a TransferManager module attached to it
      * @dev to control restrictions on transfers.
      * @param _moduleFactory is the address of the module factory to be added
      * @param _data is data packed into bytes used to further configure the module (See STO usage)
      * @param _maxCost max amount of POLY willing to pay to the module.
      * @param _budget max amount of ongoing POLY willing to assign to the module.
      * @param _label custom module label.
      * @param _archived whether to add the module as an archived module
      */
    function addModuleWithLabel(
        address _moduleFactory,
        bytes calldata _data,
        uint256 _maxCost,
        uint256 _budget,
        bytes32 _label,
        bool _archived
    ) external;

    /**
     * @notice Function used to attach a module to the security token
     * @dev  E.G.: On deployment (through the STR) ST gets a TransferManager module attached to it
     * @dev to control restrictions on transfers.
     * @dev You are allowed to add a new moduleType if:
     * @dev - there is no existing module of that type yet added
     * @dev - the last member of the module list is replacable
     * @param _moduleFactory is the address of the module factory to be added
     * @param _data is data packed into bytes used to further configure the module (See STO usage)
     * @param _maxCost max amount of POLY willing to pay to module. (WIP)
     * @param _budget max amount of ongoing POLY willing to assign to the module.
     * @param _archived whether to add the module as an archived module
     */
    function addModule(address _moduleFactory, bytes calldata _data, uint256 _maxCost, uint256 _budget, bool _archived) external;

    /**
    * @notice Archives a module attached to the SecurityToken
    * @param _module address of module to archive
    */
    function archiveModule(address _module) external;

    /**
    * @notice Unarchives a module attached to the SecurityToken
    * @param _module address of module to unarchive
    */
    function unarchiveModule(address _module) external;

    /**
    * @notice Removes a module attached to the SecurityToken
    * @param _module address of module to archive
    */
    function removeModule(address _module) external;

    /**
     * @notice Used by the issuer to set the controller addresses
     * @param _controller address of the controller
     */
    function setController(address _controller) external;

    /**
     * @notice This function allows an authorised address to transfer tokens between any two token holders.
     * The transfer must still respect the balances of the token holders (so the transfer must be for at most
     * `balanceOf(_from)` tokens) and potentially also need to respect other transfer restrictions.
     * @dev This function can only be executed by the `controller` address.
     * @param _from Address The address which you want to send tokens from
     * @param _to Address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     * @param _data data to validate the transfer. (It is not used in this reference implementation
     * because use of `_data` parameter is implementation specific).
     * @param _operatorData data attached to the transfer by controller to emit in event. (It is more like a reason string
     * for calling this function (aka force transfer) which provides the transparency on-chain).
     */
    function controllerTransfer(address _from, address _to, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external;

    /**
     * @notice This function allows an authorised address to redeem tokens for any token holder.
     * The redemption must still respect the balances of the token holder (so the redemption must be for at most
     * `balanceOf(_tokenHolder)` tokens) and potentially also need to respect other transfer restrictions.
     * @dev This function can only be executed by the `controller` address.
     * @param _tokenHolder The account whose tokens will be redeemed.
     * @param _value uint256 the amount of tokens need to be redeemed.
     * @param _data data to validate the transfer. (It is not used in this reference implementation
     * because use of `_data` parameter is implementation specific).
     * @param _operatorData data attached to the transfer by controller to emit in event. (It is more like a reason string
     * for calling this function (aka force transfer) which provides the transparency on-chain).
     */
    function controllerRedeem(address _tokenHolder, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external;

    /**
     * @notice Used by the issuer to permanently disable controller functionality
     * @dev enabled via feature switch "disableControllerAllowed"
     */
    function disableController(bytes calldata _signature) external;

    /**
     * @notice Used to get the version of the securityToken
     */
    function getVersion() external view returns(uint8[] memory version);

    /**
     * @notice Gets the investor count
     */
    function getInvestorCount() external view returns(uint256 investorCount);

    /**
     * @notice Gets the holder count (investors with non zero balance)
     */
    function holderCount() external view returns(uint256 count);

    /**
      * @notice Overloaded version of the transfer function
      * @param _to receiver of transfer
      * @param _value value of transfer
      * @param _data data to indicate validation
      * @return bool success
      */
    function transferWithData(address _to, uint256 _value, bytes calldata _data) external;

    /**
      * @notice Overloaded version of the transferFrom function
      * @param _from sender of transfer
      * @param _to receiver of transfer
      * @param _value value of transfer
      * @param _data data to indicate validation
      * @return bool success
      */
    function transferFromWithData(address _from, address _to, uint256 _value, bytes calldata _data) external;

    /**
     * @notice Transfers the ownership of tokens from a specified partition from one address to another address
     * @param _partition The partition from which to transfer tokens
     * @param _to The address to which to transfer tokens to
     * @param _value The amount of tokens to transfer from `_partition`
     * @param _data Additional data attached to the transfer of tokens
     * @return The partition to which the transferred tokens were allocated for the _to address
     */
    function transferByPartition(bytes32 _partition, address _to, uint256 _value, bytes calldata _data) external returns (bytes32 partition);

    /**
     * @notice Get the balance according to the provided partitions
     * @param _partition Partition which differentiate the tokens.
     * @param _tokenHolder Whom balance need to queried
     * @return Amount of tokens as per the given partitions
     */
    function balanceOfByPartition(bytes32 _partition, address _tokenHolder) external view returns(uint256 balance);

    /**
      * @notice Provides the granularity of the token
      * @return uint256
      */
    function granularity() external view returns(uint256 granularityAmount);

    /**
      * @notice Provides the address of the polymathRegistry
      * @return address
      */
    function polymathRegistry() external view returns(address registryAddress);

    /**
    * @notice Upgrades a module attached to the SecurityToken
    * @param _module address of module to archive
    */
    function upgradeModule(address _module) external;

    /**
    * @notice Upgrades security token
    */
    function upgradeToken() external;

    /**
     * @notice A security token issuer can specify that issuance has finished for the token
     * (i.e. no new tokens can be minted or issued).
     * @dev If a token returns FALSE for `isIssuable()` then it MUST always return FALSE in the future.
     * If a token returns FALSE for `isIssuable()` then it MUST never allow additional tokens to be issued.
     * @return bool `true` signifies the minting is allowed. While `false` denotes the end of minting
     */
    function isIssuable() external view returns (bool issuable);

    /**
     * @notice Authorises an operator for all partitions of `msg.sender`.
     * NB - Allowing investors to authorize an investor to be an operator of all partitions
     * but it doesn't mean we operator is allowed to transfer the LOCKED partition values.
     * Logic for this restriction is written in `operatorTransferByPartition()` function.
     * @param _operator An address which is being authorised.
     */
    function authorizeOperator(address _operator) external;

    /**
     * @notice Revokes authorisation of an operator previously given for all partitions of `msg.sender`.
     * NB - Allowing investors to authorize an investor to be an operator of all partitions
     * but it doesn't mean we operator is allowed to transfer the LOCKED partition values.
     * Logic for this restriction is written in `operatorTransferByPartition()` function.
     * @param _operator An address which is being de-authorised
     */
    function revokeOperator(address _operator) external;

    /**
     * @notice Authorises an operator for a given partition of `msg.sender`
     * @param _partition The partition to which the operator is authorised
     * @param _operator An address which is being authorised
     */
    function authorizeOperatorByPartition(bytes32 _partition, address _operator) external;

    /**
     * @notice Revokes authorisation of an operator previously given for a specified partition of `msg.sender`
     * @param _partition The partition to which the operator is de-authorised
     * @param _operator An address which is being de-authorised
     */
    function revokeOperatorByPartition(bytes32 _partition, address _operator) external;

    /**
     * @notice Transfers the ownership of tokens from a specified partition from one address to another address
     * @param _partition The partition from which to transfer tokens.
     * @param _from The address from which to transfer tokens from
     * @param _to The address to which to transfer tokens to
     * @param _value The amount of tokens to transfer from `_partition`
     * @param _data Additional data attached to the transfer of tokens
     * @param _operatorData Additional data attached to the transfer of tokens by the operator
     * @return The partition to which the transferred tokens were allocated for the _to address
     */
    function operatorTransferByPartition(
        bytes32 _partition,
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _operatorData
    )
        external
        returns (bytes32 partition);

    /*
    * @notice Returns if transfers are currently frozen or not
    */
    function transfersFrozen() external view returns (bool isFrozen);

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) external;

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() external view returns (bool);

    /**
     * @return the address of the owner.
     */
    function owner() external view returns (address ownerAddress);

    function controller() external view returns(address controllerAddress);

    function moduleRegistry() external view returns(address moduleRegistryAddress);

    function securityTokenRegistry() external view returns(address securityTokenRegistryAddress);

    function polyToken() external view returns(address polyTokenAddress);

    function tokenFactory() external view returns(address tokenFactoryAddress);

    function getterDelegate() external view returns(address delegate);

    function controllerDisabled() external view returns(bool isDisabled);

    function initialized() external view returns(bool isInitialized);

    function tokenDetails() external view returns(string memory details);

    function updateFromRegistry() external;

}

pragma solidity 0.5.8;

/**
 * @title Interface that every module factory contract should implement
 */
interface IModuleFactory {
    event ChangeSetupCost(uint256 _oldSetupCost, uint256 _newSetupCost);
    event ChangeCostType(bool _isOldCostInPoly, bool _isNewCostInPoly);
    event GenerateModuleFromFactory(
        address _module,
        bytes32 indexed _moduleName,
        address indexed _moduleFactory,
        address _creator,
        uint256 _setupCost,
        uint256 _setupCostInPoly
    );
    event ChangeSTVersionBound(string _boundType, uint8 _major, uint8 _minor, uint8 _patch);

    //Should create an instance of the Module, or throw
    function deploy(bytes calldata _data) external returns(address moduleAddress);

    /**
     * @notice Get the tags related to the module factory
     */
    function version() external view returns(string memory moduleVersion);

    /**
     * @notice Get the tags related to the module factory
     */
    function name() external view returns(bytes32 moduleName);

    /**
     * @notice Returns the title associated with the module
     */
    function title() external view returns(string memory moduleTitle);

    /**
     * @notice Returns the description associated with the module
     */
    function description() external view returns(string memory moduleDescription);

    /**
     * @notice Get the setup cost of the module in USD
     */
    function setupCost() external returns(uint256 usdSetupCost);

    /**
     * @notice Type of the Module factory
     */
    function getTypes() external view returns(uint8[] memory moduleTypes);

    /**
     * @notice Get the tags related to the module factory
     */
    function getTags() external view returns(bytes32[] memory moduleTags);

    /**
     * @notice Used to change the setup fee
     * @param _newSetupCost New setup fee
     */
    function changeSetupCost(uint256 _newSetupCost) external;

    /**
     * @notice Used to change the currency and amount setup cost
     * @param _setupCost new setup cost
     * @param _isCostInPoly new setup cost currency. USD or POLY
     */
    function changeCostAndType(uint256 _setupCost, bool _isCostInPoly) external;

    /**
     * @notice Function use to change the lower and upper bound of the compatible version st
     * @param _boundType Type of bound
     * @param _newVersion New version array
     */
    function changeSTVersionBounds(string calldata _boundType, uint8[] calldata _newVersion) external;

    /**
     * @notice Get the setup cost of the module
     */
    function setupCostInPoly() external returns (uint256 polySetupCost);

    /**
     * @notice Used to get the lower bound
     * @return Lower bound
     */
    function getLowerSTVersionBounds() external view returns(uint8[] memory lowerBounds);

    /**
     * @notice Used to get the upper bound
     * @return Upper bound
     */
    function getUpperSTVersionBounds() external view returns(uint8[] memory upperBounds);

    /**
     * @notice Updates the tags of the ModuleFactory
     * @param _tagsData New list of tags
     */
    function changeTags(bytes32[] calldata _tagsData) external;

    /**
     * @notice Updates the name of the ModuleFactory
     * @param _name New name that will replace the old one.
     */
    function changeName(bytes32 _name) external;

    /**
     * @notice Updates the description of the ModuleFactory
     * @param _description New description that will replace the old one.
     */
    function changeDescription(string calldata _description) external;

    /**
     * @notice Updates the title of the ModuleFactory
     * @param _title New Title that will replace the old one.
     */
    function changeTitle(string calldata _title) external;

}

pragma solidity 0.5.8;

/**
 * @title Interface that every module contract should implement
 */
interface IModule {
    /**
     * @notice This function returns the signature of configure function
     */
    function getInitFunction() external pure returns(bytes4 initFunction);

    /**
     * @notice Return the permission flags that are associated with a module
     */
    function getPermissions() external view returns(bytes32[] memory permissions);

}

pragma solidity 0.5.8;

interface IDataStore {
    /**
     * @dev Changes security token atatched to this data store
     * @param _securityToken address of the security token
     */
    function setSecurityToken(address _securityToken) external;

    /**
     * @dev Stores a uint256 data against a key
     * @param _key Unique key to identify the data
     * @param _data Data to be stored against the key
     */
    function setUint256(bytes32 _key, uint256 _data) external;

    function setBytes32(bytes32 _key, bytes32 _data) external;

    function setAddress(bytes32 _key, address _data) external;

    function setString(bytes32 _key, string calldata _data) external;

    function setBytes(bytes32 _key, bytes calldata _data) external;

    function setBool(bytes32 _key, bool _data) external;

    /**
     * @dev Stores a uint256 array against a key
     * @param _key Unique key to identify the array
     * @param _data Array to be stored against the key
     */
    function setUint256Array(bytes32 _key, uint256[] calldata _data) external;

    function setBytes32Array(bytes32 _key, bytes32[] calldata _data) external ;

    function setAddressArray(bytes32 _key, address[] calldata _data) external;

    function setBoolArray(bytes32 _key, bool[] calldata _data) external;

    /**
     * @dev Inserts a uint256 element to the array identified by the key
     * @param _key Unique key to identify the array
     * @param _data Element to push into the array
     */
    function insertUint256(bytes32 _key, uint256 _data) external;

    function insertBytes32(bytes32 _key, bytes32 _data) external;

    function insertAddress(bytes32 _key, address _data) external;

    function insertBool(bytes32 _key, bool _data) external;

    /**
     * @dev Deletes an element from the array identified by the key.
     * When an element is deleted from an Array, last element of that array is moved to the index of deleted element.
     * @param _key Unique key to identify the array
     * @param _index Index of the element to delete
     */
    function deleteUint256(bytes32 _key, uint256 _index) external;

    function deleteBytes32(bytes32 _key, uint256 _index) external;

    function deleteAddress(bytes32 _key, uint256 _index) external;

    function deleteBool(bytes32 _key, uint256 _index) external;

    /**
     * @dev Stores multiple uint256 data against respective keys
     * @param _keys Array of keys to identify the data
     * @param _data Array of data to be stored against the respective keys
     */
    function setUint256Multi(bytes32[] calldata _keys, uint256[] calldata _data) external;

    function setBytes32Multi(bytes32[] calldata _keys, bytes32[] calldata _data) external;

    function setAddressMulti(bytes32[] calldata _keys, address[] calldata _data) external;

    function setBoolMulti(bytes32[] calldata _keys, bool[] calldata _data) external;

    /**
     * @dev Inserts multiple uint256 elements to the array identified by the respective keys
     * @param _keys Array of keys to identify the data
     * @param _data Array of data to be inserted in arrays of the respective keys
     */
    function insertUint256Multi(bytes32[] calldata _keys, uint256[] calldata _data) external;

    function insertBytes32Multi(bytes32[] calldata _keys, bytes32[] calldata _data) external;

    function insertAddressMulti(bytes32[] calldata _keys, address[] calldata _data) external;

    function insertBoolMulti(bytes32[] calldata _keys, bool[] calldata _data) external;

    function getUint256(bytes32 _key) external view returns(uint256);

    function getBytes32(bytes32 _key) external view returns(bytes32);

    function getAddress(bytes32 _key) external view returns(address);

    function getString(bytes32 _key) external view returns(string memory);

    function getBytes(bytes32 _key) external view returns(bytes memory);

    function getBool(bytes32 _key) external view returns(bool);

    function getUint256Array(bytes32 _key) external view returns(uint256[] memory);

    function getBytes32Array(bytes32 _key) external view returns(bytes32[] memory);

    function getAddressArray(bytes32 _key) external view returns(address[] memory);

    function getBoolArray(bytes32 _key) external view returns(bool[] memory);

    function getUint256ArrayLength(bytes32 _key) external view returns(uint256);

    function getBytes32ArrayLength(bytes32 _key) external view returns(uint256);

    function getAddressArrayLength(bytes32 _key) external view returns(uint256);

    function getBoolArrayLength(bytes32 _key) external view returns(uint256);

    function getUint256ArrayElement(bytes32 _key, uint256 _index) external view returns(uint256);

    function getBytes32ArrayElement(bytes32 _key, uint256 _index) external view returns(bytes32);

    function getAddressArrayElement(bytes32 _key, uint256 _index) external view returns(address);

    function getBoolArrayElement(bytes32 _key, uint256 _index) external view returns(bool);

    function getUint256ArrayElements(bytes32 _key, uint256 _startIndex, uint256 _endIndex) external view returns(uint256[] memory);

    function getBytes32ArrayElements(bytes32 _key, uint256 _startIndex, uint256 _endIndex) external view returns(bytes32[] memory);

    function getAddressArrayElements(bytes32 _key, uint256 _startIndex, uint256 _endIndex) external view returns(address[] memory);

    function getBoolArrayElements(bytes32 _key, uint256 _startIndex, uint256 _endIndex) external view returns(bool[] memory);
}

pragma solidity 0.5.8;

interface ICheckPermission {
    /**
     * @notice Validate permissions with PermissionManager if it exists, If no Permission return false
     * @dev Note that IModule withPerm will allow ST owner all permissions anyway
     * @dev this allows individual modules to override this logic if needed (to not allow ST owner all permissions)
     * @param _delegate address of delegate
     * @param _module address of PermissionManager module
     * @param _perm the permissions
     * @return success
     */
    function checkPermission(address _delegate, address _module, bytes32 _perm) external view returns(bool hasPerm);
}

pragma solidity 0.5.8;

/**
 * @title Utility contract to allow pausing and unpausing of certain functions
 */
contract Pausable {
    event Pause(address account);
    event Unpause(address account);

    bool public paused = false;

    /**
    * @notice Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    /**
    * @notice Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    /**
    * @notice Called by the owner to pause, triggers stopped state
    */
    function _pause() internal whenNotPaused {
        paused = true;
        /*solium-disable-next-line security/no-block-members*/
        emit Pause(msg.sender);
    }

    /**
    * @notice Called by the owner to unpause, returns to normal state
    */
    function _unpause() internal whenPaused {
        paused = false;
        /*solium-disable-next-line security/no-block-members*/
        emit Unpause(msg.sender);
    }

}

pragma solidity ^0.5.2;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.5.2;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.2;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

pragma solidity ^0.5.2;

/**
 * @title Elliptic curve signature operations
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
 * TODO Remove this library once solidity supports passing a signature to ecrecover.
 * See https://github.com/ethereum/solidity/issues/864
 */

library ECDSA {
    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param signature bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

        // If the signature is valid (and not malleable), return the signer address
        return ecrecover(hash, v, r, s);
    }

    /**
     * toEthSignedMessageHash
     * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
     * and hash the result
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "byzantium",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}