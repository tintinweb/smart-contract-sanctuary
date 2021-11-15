// SPDX-License-Identifier: MIT
pragma solidity ^0.5.8;
pragma experimental ABIEncoderV2;

import "./Registry.sol";
import "./interfaces/IUserRegistry.sol";
import "./ERC1643/IERC1643.sol";
import "./ERC1644/IERC1644.sol";
// import "./Claimer.sol";

contract UserRegistry is Registry, IUserRegistry,IERC1643, IERC1644 {
    uint256 public constant REDEMPTION_ADDRESS_COUNT = 0x100000;
    bytes32 public constant IS_BLOCKLISTED = "IS_BLOCKLISTED";
    bytes32 public constant KYC_AML_VERIFIED = "KYC_AML_VERIFIED";
    bytes32 public constant CAN_BURN = "CAN_BURN";
    bytes32 public constant USER_REDEEM_ADDRESS = "USER_REDEEM_ADDRESS";
    bytes32 public constant REDEEM_ADDRESS_USER = "REDEEM_ADDRESS_USER";

    address public token;

    bool public iskycEnabled = true;

    mapping(address => string) private usersId;
    mapping(string => address) private usersById;

    uint256 private redemptionAddressCount;

    uint256 public minBurnBound;
    uint256 public maxBurnBound;

    struct User {
        address account;
        string id;
        address redeemAddress;
        bool blocked;
        bool KYC; // solhint-disable-line var-name-mixedcase
        bool canBurn;
    }

    struct Document {
        bytes32 docHash; // Hash of the document
        uint256 lastModified; // Timestamp at which document details was last modified
        string uri; // URI of the document that exist off-chain
    }

    // mapping to store the documents details in the document
    mapping(bytes32 => Document) internal _documents;
    // mapping to store the document name indexes
    mapping(bytes32 => uint256) internal _docIndexes;
    event DocumentUpdated(bytes32 indexed _name, string _uri, bytes32 _documentHash);
    // Array use to store all the document name present in the contracts
    bytes32[] _docNames;

    // Address of the controller which is a delegated entity
    // set by the issuer/owner of the token
    address public controller;

    // Event emitted when controller features will no longer in use
    event FinalizedControllerFeature();

    // Modifier to check whether the msg.sender is authorised or not 
    modifier onlyController() {
        require(msg.sender == controller, "Not Authorised");
        _;
    }

    event RegisterNewUser(
        address indexed account,
        address indexed redeemAddress
    );

    event UserKycVerified(address indexed account);

    event UserKycUnverified(address indexed account);

    event EnableRedeemAddress(address indexed account);

    event DisableRedeemAddress(address indexed account);

    event BlockAccount(address indexed account);

    event UnblockAccount(address indexed account);

    event MinBurnBound(uint256 minBurn);

    event MaxBurnBound(uint256 minBurn);

    constructor(
        address _token,
        uint256 _minBurnBound,
        uint256 _maxBurnBound
    ) public {
        require(_minBurnBound <= _maxBurnBound, "min bigger than max");
        token = _token;
        minBurnBound = _minBurnBound;
        maxBurnBound = _maxBurnBound;
    }

    function setToken(address _token) public onlyOwner {
        token = _token;
    }

    function setKyc(bool _kycEnable) public onlyOwner {
        iskycEnabled = _kycEnable;
    }

    function setMinBurnBound(uint256 _minBurnBound) public onlyOwner {
        require(_minBurnBound <= maxBurnBound, "min bigger than max");
        minBurnBound = _minBurnBound;

        emit MinBurnBound(_minBurnBound);
    }

    function setMaxBurnBound(uint256 _maxBurnBound) public onlyOwner {
        require(minBurnBound <= _maxBurnBound, "min bigger than max");
        maxBurnBound = _maxBurnBound;

        emit MaxBurnBound(_maxBurnBound);
    }

    /**
     * @dev Adds a new user in the registry.
     *      Sets {REDEEM_ADDRESS_USER} attribute for redeemAddress as `_account`.
     *      Sets {USER_REDEEM_ADDRESS} attribute for `_account` as redeemAddress.
     *
     * Emits a {RegisterNewUser} event.
     *
     * Requirements:
     *
     * - `_account` should not be a registered as user.
     * - number of redeem address should not be greater than max availables.
     */
    function registerNewUser(address _account, string memory _id)
        public
        onlyOwner
    {
        require(!_isUser(_account), "user exist");
        require(usersById[_id] == address(0), "id already taken");

        redemptionAddressCount++;
        require(
            REDEMPTION_ADDRESS_COUNT > redemptionAddressCount,
            "max allowed users"
        );

        setAttribute(
            address(uint160(uint256(redemptionAddressCount))),
            REDEEM_ADDRESS_USER,
            uint256(uint160(_account))
        );

        setAttribute(_account, USER_REDEEM_ADDRESS, redemptionAddressCount);

        usersId[_account] = _id;
        usersById[_id] = _account;

        emit RegisterNewUser(_account, address(uint160(uint256(redemptionAddressCount))));
    }

    /**
     * @dev Gets user's data.
     *
     * Requirements:
     *
     * - the caller should be the owner.
     */
    function getUser(address _account)
        public
        view
        onlyOwner
        returns (User memory user)
    {
        user.account = _account;
        user.id = usersId[_account];
        user.redeemAddress = getRedeemAddress(_account);
        user.blocked = _isBlocked(_account);
        user.KYC = _isKyced(_account);
        user.canBurn =
            getAttributeValue(getRedeemAddress(_account), CAN_BURN) == 1;
    }

    /**
     * @dev Gets user by its id.
     *
     * Requirements:
     *
     * - the caller should be the owner.
     */
    function getUserById(string memory _id)
        public
        view
        onlyOwner
        returns (User memory user)
    {
        return getUser(usersById[_id]);
    }

    /**
     * @dev Sets user id.
     *
     * Requirements:
     *
     * - the caller should be the owner.
     * - `_account` should be a registered as user.
     * - `_id` should not be taken.
     */
    function setUserId(address _account, string memory _id) public onlyOwner {
        require(_isUser(_account), "not a user");
        require(usersById[_id] == address(0), "id already taken");
        string memory prevId = usersId[_account];
        usersId[_account] = _id;
        usersById[_id] = _account;
        delete usersById[prevId];
    }

    /**
     * @dev Sets user as KYC verified.
     *
     * Emits a {UserKycVerified} event.
     *
     * Requirements:
     *
     * - `_account` should be a registered as user.
     */
    function userKycVerified(address _account) public onlyOwner {
        require(_isUser(_account), "not a user");

        setAttribute(_account, KYC_AML_VERIFIED, 1);

        emit UserKycVerified(_account);
    }

    /**
     * @dev Sets user as KYC un-verified.
     *
     * Emits a {UserKycVerified} event.
     *
     * Requirements:
     *
     * - `_account` should be a registered as user.
     */
    function userKycUnverified(address _account) public onlyOwner {
        require(_isUser(_account), "not a user");

        setAttribute(_account, KYC_AML_VERIFIED, 0);

        emit UserKycUnverified(_account);
    }

    /**
     * @dev Enables `_account` redeem address to burn.
     *
     * Emits a {EnableUserRedeemAddress} event.
     *
     * Requirements:
     *
     * - `_account` should be a registered as user.
     * - `_account` should be KYC verified.
     */
    function enableRedeemAddress(address _account) public onlyOwner {
        require(_isUser(_account), "not a user");
        require(_isKyced(_account), "user has not KYC");

        setAttribute(getRedeemAddress(_account), CAN_BURN, 1);

        emit EnableRedeemAddress(_account);
    }

    /**
     * @dev Disables `_account` redeem address to burn.
     *
     * Emits a {DisableRedeemAddress} event.
     *
     * Requirements:
     *
     * - `_account` should be a registered as user.
     */
    function disableRedeemAddress(address _account) public onlyOwner {
        require(_isUser(_account), "not a user");

        setAttribute(getRedeemAddress(_account), CAN_BURN, 0);

        emit DisableRedeemAddress(_account);
    }

    /**
     * @dev Sets user as KYC verified.
     *      Enables `_account` redeem address to burn.
     *
     * Emits a {UserKycVerified} event.
     * Emits a {EnableUserRedeemAddress} event.
     *
     * Requirements:
     *
     * - `_account` should be a registered as user.
     */
    function verifyKycEnableRedeem(address _account) public onlyOwner {
        require(_isUser(_account), "not a user");

        setAttribute(_account, KYC_AML_VERIFIED, 1);
        setAttribute(getRedeemAddress(_account), CAN_BURN, 1);

        emit UserKycVerified(_account);
        emit EnableRedeemAddress(getRedeemAddress(_account));
    }

    /**
     * @dev Sets user as KYC un-verified.
     *      Disables `_account` redeem address to burn.
     *
     * Emits a {UserKycVerified} event.
     * Emits a {v} event.
     *
     * Requirements:
     *
     * - `_account` should be a registered as user.
     */
    function unverifyKycDisableRedeem(address _account) public onlyOwner {
        require(_isUser(_account), "not a user");

        setAttribute(_account, KYC_AML_VERIFIED, 0);
        setAttribute(getRedeemAddress(_account), CAN_BURN, 0);

        emit UserKycUnverified(_account);
        emit DisableRedeemAddress(getRedeemAddress(_account));
    }

    /**
     * @dev Registers `_account` as blocked.
     *
     * Emits a {BlockAccount} event.
     *
     * Requirements:
     *
     * - `_account` should not be already blocked.
     */
    function blockAccount(address _account) public onlyOwner {
        require(!_isBlocked(_account), "user already blocked");
        setAttribute(_account, IS_BLOCKLISTED, 1);

        emit BlockAccount(_account);
    }

    /**
     * @dev Registers `_account` as un-blocked.
     *
     * Emits a {UnblockAccount} event.
     *
     * Requirements:
     *
     * - `_account` should be blocked.
     */
    function unblockAccount(address _account) public onlyOwner {
        require(_isBlocked(_account), "user not blocked");
        setAttribute(_account, IS_BLOCKLISTED, 0);

        emit UnblockAccount(_account);
    }

    /**
     * @dev Gets user's account associated to a given `_redeemAddress`.
     */
    function getUserByRedeemAddress(address _redeemAddress)
        public
        view
        returns (address)
    {
        return address(uint160(uint256(getAttributeValue(_redeemAddress, REDEEM_ADDRESS_USER))));
    }

    /**
     * @dev Gets redeem address associated to a given `_account`
     */
    function getRedeemAddress(address _account) public view returns (address) {
        return address(uint160(uint256(getAttributeValue(_account, USER_REDEEM_ADDRESS))));
    }

    /**
     * @dev Checks if the given `_account` is a registered user.
     */
    function _isUser(address _account) internal view returns (bool) {
        return getAttributeValue(_account, USER_REDEEM_ADDRESS) != 0;
    }

    /**
     * @dev Checks if the given `_account` is blocked.
     */
    function _isBlocked(address _account) internal view returns (bool) {
        return getAttributeValue(_account, IS_BLOCKLISTED) == 1;
    }

    /**
     * @dev Checks if the given `_account` is KYC verified.
     */
    function _isKyced(address _account) internal view returns (bool) {
        return getAttributeValue(_account, KYC_AML_VERIFIED) != 0;
    }

    /**
     * @dev Checks if the given `_account` is a redeeming address.
     */
    function _isRedemptionAddress(address _account)
        internal
        pure
        returns (bool)
    {
        return uint256(uint160(_account)) < REDEMPTION_ADDRESS_COUNT;
    }

    /**
     * @dev Determines if it is redeeming.
     */
    function isRedeem(address, address _recipient)
        external
        view
        onlyToken
        returns (bool)
    {
        return _isRedemptionAddress(_recipient);
    }

    /**
     * @dev Determines if it is redeeming from.
     */
    function isRedeemFrom(
        address,
        address,
        address _recipient
    ) external view  onlyToken returns (bool) {
        return _isRedemptionAddress(_recipient);
    }

    /**
     * @dev Throws if any of `_from` or `_to` is blocklisted.
     */
    function canTransfer(address _from, uint256 balanceOfFrom, address _to, uint256 _value, bytes calldata _data)
        external
        view
        onlyToken
        returns (bool, byte, bytes32)
    {
        require(!_isBlocked(_from), "blocklisted");
        require(!_isBlocked(_to), "blocklisted");
        if (iskycEnabled){
            require(_isKyced(_from), "From has not KYC");
            require(_isKyced(_to), "To has not KYC");
        }
        if (balanceOfFrom < _value)
            return (false, 0x52, bytes32(0));

        else if (_to == address(0))
            return (false, 0x57, bytes32(0));

        // else if (!KindMath.checkAdd(token._balances[_to], _value))
        //     return (false, 0x50, bytes32(0));
        return (true, 0x51, bytes32(0));
    }

    /**
     * @dev Throws if any of `_spender`, `_from` or `_to` is blocklisted.
     */
    function canTransferFrom(
        address _from,
        uint256 balanceOfFrom,
        uint256 _value, 
        bytes calldata _data,
        address _to,
        uint256 balanceOfTo
    ) external view onlyToken 
    returns (bool, byte, bytes32){
        // require(!_isBlocked(_spender), "blocklisted");
        require(!_isBlocked(_from), "blocklisted");
        require(!_isBlocked(_to), "blocklisted");
        if (iskycEnabled){
            require(_isKyced(_from), "From has not KYC");
            require(_isKyced(_to), "To has not KYC");
        }
        if (balanceOfFrom < _value)
            return (false, 0x52, bytes32(0));

        else if (_to == address(0))
            return (false, 0x57, bytes32(0));

        // else if (!KindMath.checkAdd(balanceOfTo, _value))
        //     return (false, 0x50, bytes32(0));
        return (true, 0x51, bytes32(0));
    }

    /**
     * @dev Throws if any of `_to` is not KYC verified or blocklisted.
     */
    function canMint(address _to) external view onlyToken {
        require(_isKyced(_to), "user has not KYC");
        require(!_isBlocked(_to), "blocklisted");
    }

    /**
     * @dev Throws if any of `_from` is not enabled to burn or `_amount` lower than minBurnBound.
     */
    function canBurn(address _from, uint256 _amount)
        external
        view
        onlyToken
    {
        require(getAttributeValue(_from, CAN_BURN) != 0, "can not burn");
        require(_amount >= minBurnBound, "below min bound");
        require(_amount <= maxBurnBound, "above max bound");
    }

    /**
     * @dev Throws if any of `_account` is not blocked.
     */
    function canWipe(address _account) external view onlyToken {
        require(_isBlocked(_account), "can not wipe");
    }

    /**
     * @dev Throws if called by any address other than the token.
     */
    modifier onlyToken() {
        require(msg.sender == token, "only Token");
        _;
    }

    function setDocument(bytes32 _name, string calldata _uri, bytes32 _documentHash) external onlyOwner
        {
        require(_name != bytes32(0), "Zero value is not allowed");
        require(bytes(_uri).length > 0, "Should not be a empty uri");
        if (_documents[_name].lastModified == uint256(0)) {
            _docNames.push(_name);
            _docIndexes[_name] = _docNames.length;
        }
        _documents[_name] = Document(_documentHash, now, _uri);
        emit DocumentUpdated(_name, _uri, _documentHash);
        }

    /**
     * @notice Used to remove an existing document from the contract by giving the name of the document.
     * @dev Can only be executed by the owner of the contract.
     * @param _name Name of the document. It should be unique always
     */
    function removeDocument(bytes32 _name) external onlyOwner {
        // TokenLib.removeDocument(_name);
        require(_documents[_name].lastModified != uint256(0), "Document should be existed");
        uint256 index = _docIndexes[_name] - 1;
        if (index != _docNames.length - 1) {
            _docNames[index] = _docNames[_docNames.length - 1];
            _docIndexes[_docNames[index]] = index + 1; 
        }
        _docNames.length--;
        emit DocumentRemoved(_name, _documents[_name].uri, _documents[_name].docHash);
        delete _documents[_name];
    }

    /**
     * @notice Used to return the details of a document with a known name (`bytes32`).
     * @param _name Name of the document
     * @return string The URI associated with the document.
     * @return bytes32 The hash (of the contents) of the document.
     * @return uint256 the timestamp at which the document was last modified.
     */
    function getDocument(bytes32 _name) external view returns (string memory, bytes32, uint256) {
        return (
            _documents[_name].uri,
            _documents[_name].docHash,
            _documents[_name].lastModified
        );
    }

    /**
     * @notice Used to retrieve a full list of documents attached to the smart contract.
     * @return bytes32 List of all documents names present in the contract.
     */
    function getAllDocuments() external view returns (bytes32[] memory) {
        return _docNames;
    }

    /**
     * @notice In order to provide transparency over whether `controllerTransfer` / `controllerRedeem` are useable
     * or not `isControllable` function will be used.
     * @dev If `isControllable` returns `false` then it always return `false` and
     * `controllerTransfer` / `controllerRedeem` will always revert.
     * @return bool `true` when controller address is non-zero otherwise return `false`.
     */
    function isControllable() external view returns (bool) {
        return _isControllable();
    }

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
    function controllerTransfer(address _from, address _to, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external onlyController {
        // _transfer(_from, _to, _value);
        emit ControllerTransfer(msg.sender, _from, _to, _value, _data, _operatorData);
    }

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
    function controllerRedeem(address _tokenHolder, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external onlyController {
        // _burn(_tokenHolder, _value);
        emit ControllerRedemption(msg.sender, _tokenHolder, _value, _data, _operatorData);
    }

    /**
     * @notice It is used to end the controller feature from the token
     * @dev It only be called by the `owner/issuer` of the token
     */
    function finalizeControllable() external onlyOwner {
        require(controller != address(0), "Already finalized");
        controller = address(0);
        emit FinalizedControllerFeature();
    }

    /**
     * @notice Internal function to know whether the controller functionality
     * allowed or not.
     * @return bool `true` when controller address is non-zero otherwise return `false`.
     */
    function _isControllable() internal view returns (bool) {
        if (controller == address(0))
            return false;
        else
            return true;
    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.8;

/**
 * @dev Interface of the Registry contract.
 */
interface IUserRegistry {
    function canTransfer(address _from, uint256 balanceOfFrom, address _to, uint256 _value, bytes calldata _data) external view returns (bool, byte, bytes32);

    function canTransferFrom(address _from, uint256 balanceOfFrom, uint256 _value, bytes calldata _data,address _to, uint256 balanceOfTo) external view returns (bool, byte, bytes32);

    function canMint(address _to) external view;

    function canBurn(address _from, uint256 _amount) external view;

    function canWipe(address _account) external view;

    function isRedeem(address _sender, address _recipient)
        external
        view
        returns (bool);

    function isRedeemFrom(
        address _caller,
        address _sender,
        address _recipient
    ) external view returns (bool);

    function controllerTransfer(address _from, address _to, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external;
    
    function controllerRedeem(address _tokenHolder, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.8;
pragma experimental ABIEncoderV2;
import "./Ownable.sol";
// import "./Claimer.sol";

contract Registry is Ownable {
    struct AttributeData {
        uint256 value;
        address updatedBy;
        uint256 timestamp;
    }

    mapping(address => mapping(bytes32 => AttributeData)) public attributes;

    event SetAttribute(
        address indexed who,
        bytes32 attribute,
        uint256 value,
        address indexed updatedBy
    );

    function setAttribute(
        address _who,
        bytes32 _attribute,
        uint256 _value
    ) public onlyOwner {
        attributes[_who][_attribute] = AttributeData(
            _value,
            msg.sender,
            block.timestamp
        );
        emit SetAttribute(_who, _attribute, _value, msg.sender);
    }

    function hasAttribute(address _who, bytes32 _attribute)
        public
        view
        returns (bool)
    {
        return attributes[_who][_attribute].value != 0;
    }

    function getAttribute(address _who, bytes32 _attribute)
        public
        view
        returns (AttributeData memory data)
    {
        data = attributes[_who][_attribute];
    }

    function getAttributeValue(address _who, bytes32 _attribute)
        public
        view
        returns (uint256)
    {
        return attributes[_who][_attribute].value;
    }
}

pragma solidity ^0.5.8;

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
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
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

pragma solidity ^0.5.8;

interface IERC1644 {

    // Controller Operation
    function isControllable() external view returns (bool);
    function controllerTransfer(address _from, address _to, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external;
    function controllerRedeem(address _tokenHolder, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external;

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

}

pragma solidity ^0.5.8;

// @title IERC1643 Document Management (part of the ERC1400 Security Token Standards)
/// @dev See https://github.com/SecurityTokenStandard/EIP-Spec

interface IERC1643 {

    // Document Management
    function getDocument(bytes32 _name) external view returns (string memory, bytes32, uint256);
    function setDocument(bytes32 _name, string calldata _uri, bytes32 _documentHash) external;
    function removeDocument(bytes32 _name) external;
    function getAllDocuments() external view returns (bytes32[] memory);

    // Document Events
    event DocumentRemoved(bytes32 indexed _name, string _uri, bytes32 _documentHash);
    event DocumentUpdated(bytes32 indexed _name, string _uri, bytes32 _documentHash);

}

