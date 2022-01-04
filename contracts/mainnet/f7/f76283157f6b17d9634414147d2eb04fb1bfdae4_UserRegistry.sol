// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import "./Registry.sol";
//import "./interfaces/IUserRegistry.sol";
import "./Claimer.sol";

contract UserRegistry is Registry, IUserRegistry {
    uint256 public constant REDEMPTION_ADDRESS_COUNT = 0x100000;
    bytes32 public constant IS_BLOCKLISTED = "IS_BLOCKLISTED";
    bytes32 public constant KYC_AML_VERIFIED = "KYC_AML_VERIFIED";
    bytes32 public constant CAN_BURN = "CAN_BURN";
    bytes32 public constant USER_REDEEM_ADDRESS = "USER_REDEEM_ADDRESS";
    bytes32 public constant REDEEM_ADDRESS_USER = "REDEEM_ADDRESS_USER";

    //address public token;

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
        //address _token,
        uint256 _minBurnBound,
        uint256 _maxBurnBound
    ) public {
        require(_minBurnBound <= _maxBurnBound, "min bigger than max");
        //token = _token;
        minBurnBound = _minBurnBound;
        maxBurnBound = _maxBurnBound;
    }

    // function setToken(address _token) public onlyOwner {
    //     token = _token;
    // }

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
    function registerNewUser(address _account, string calldata _id)
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

        emit RegisterNewUser(
            _account,
            address(uint160(uint256(redemptionAddressCount)))
        );
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
    function getUserById(string calldata _id)
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
    function setUserId(address _account, string calldata _id) public onlyOwner {
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
        return
            address(
                uint160(
                    uint256(
                        getAttributeValue(_redeemAddress, REDEEM_ADDRESS_USER)
                    )
                )
            );
    }

    /**
     * @dev Gets redeem address associated to a given `_account`
     */
    function getRedeemAddress(address _account) public view returns (address) {
        return
            address(
                uint160(
                    uint256(getAttributeValue(_account, USER_REDEEM_ADDRESS))
                )
            );
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
        override
        
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
    ) external view override  returns (bool) {
        return _isRedemptionAddress(_recipient);
    }

    /**
     * @dev Throws if any of `_from` or `_to` is blocklisted.
     */
    function canTransfer(address _from, address _to)
        external
        view
        override
        
    {
        require(!_isBlocked(_from), "blocklisted");
        require(!_isBlocked(_to), "blocklisted");
    }

    /**
     * @dev Throws if any of `_spender`, `_from` or `_to` is blocklisted.
     */
    function canTransferFrom(
        address _spender,
        address _from,
        address _to
    ) external view override  {
        require(!_isBlocked(_spender), "blocklisted");
        require(!_isBlocked(_from), "blocklisted");
        require(!_isBlocked(_to), "blocklisted");
    }

    /**
     * @dev Throws if any of `_to` is not KYC verified or blocklisted.
     */
    function canMint(address _to) external view override  {
        require(_isKyced(_to), "user has not KYC");
        require(!_isBlocked(_to), "blocklisted");
    }

    /**
     * @dev Throws if any of `_from` is not enabled to burn or `_amount` lower than minBurnBound.
     */
    function canBurn(address _from, uint256 _amount)
        external
        view
        override
        
    {
        require(getAttributeValue(_from, CAN_BURN) != 0, "can not burn");
        require(_amount >= minBurnBound, "below min bound");
        require(_amount <= maxBurnBound, "above max bound");
    }

    /**
     * @dev Throws if any of `_account` is not blocked.
     */
    function canWipe(address _account) external view override  {
        require(_isBlocked(_account), "can not wipe");
    }

    /**
     * @dev Throws if called by any address other than the token.
     */
   
}