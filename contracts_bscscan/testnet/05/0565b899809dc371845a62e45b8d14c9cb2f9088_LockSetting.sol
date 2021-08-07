// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./IERC20.sol";

contract LockSetting is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private WHITELIST_FEE_TOKEN;
    mapping(address => uint256) public WHITELIST_FEE_MAP;
    EnumerableSet.AddressSet private WHITELIST_FEE_ADDRESS;

    event UpdateWhitelistAddress(address oldAddress, bool status);

    struct SettingStruct {
        uint256 BASE_FEE;
        uint256 TOKEN_FEE;
        address payable ADDRESS_FEE;
    }

    SettingStruct public SETTING;

    constructor() {
        SETTING.BASE_FEE = 0.005 ether;
        SETTING.TOKEN_FEE = 20;
        SETTING.ADDRESS_FEE = payable(msg.sender);
    }

    function getBaseFee() external view returns (uint256) {
        return SETTING.BASE_FEE;
    }

    function getTokenFee() external view returns (uint256) {
        return SETTING.TOKEN_FEE;
    }

    function getAddressFee() external view returns (address payable) {
        return SETTING.ADDRESS_FEE;
    }

    function setFee(uint256 _baseFee, uint256 _tokenFee, address payable _addressFee) external onlyOwner {
        SETTING.BASE_FEE = _baseFee;
        SETTING.TOKEN_FEE = _tokenFee;
        SETTING.ADDRESS_FEE = _addressFee;
    }

    function setFeeAddresses(address payable _addressFee) external onlyOwner {
        SETTING.ADDRESS_FEE = _addressFee;
    }

    function setBaseFee(uint256 _baseFee) external onlyOwner {
        SETTING.BASE_FEE = _baseFee;
    }

    function setTokenFee(uint256 _tokenFee) external onlyOwner {
        SETTING.TOKEN_FEE = _tokenFee;
    }

    function setWhitelistFeeToken(address _token, uint256 _holdAmount, bool _allow) external onlyOwner {
        if (_allow) {
            WHITELIST_FEE_TOKEN.add(_token);
        } else {
            WHITELIST_FEE_TOKEN.remove(_token);
        }
        WHITELIST_FEE_MAP[_token] = _holdAmount;
    }

    function getWhitelistFeeTokenAtIndex(uint256 _index) public view returns (address, uint256) {
        address tokenAddress = WHITELIST_FEE_TOKEN.at(_index);
        return (tokenAddress, WHITELIST_FEE_MAP[tokenAddress]);
    }

    function getWhitelistFeeTokenLength() public view returns (uint256) {
        return WHITELIST_FEE_TOKEN.length();
    }

    // Remember to manage number of whitelist token due to gas cost
    function userHoldSufficientWhitelistToken(address _user) external view returns (bool) {
        uint256 whitelistFeeTokenLength = getWhitelistFeeTokenLength();
        if (whitelistFeeTokenLength == 0) {
            return true;
        }
        for (uint i = 0; i < whitelistFeeTokenLength; i++) {
            (address tokenAddress, uint256 amountRequire) = getWhitelistFeeTokenAtIndex(i);
            if (IERC20(tokenAddress).balanceOf(_user) >= amountRequire) {
                return true;
            }
        }
        return false;
    }

    /* Update address in whitelist */
    function updateFeeWhitelist(address _user, bool _status) public onlyOwner {
        if (_status) {
            WHITELIST_FEE_ADDRESS.add(_user);
        } else {
            WHITELIST_FEE_ADDRESS.remove(_user);
        }
        emit UpdateWhitelistAddress(_user, _status);
    }

    /* Get whitelist length */
    function getWhitelistAddressLength() external view returns (uint256) {
        return WHITELIST_FEE_ADDRESS.length();
    }

    /* Get whitelist At Index */
    function getWhitelistAddressAtIndex(uint256 _index) external view returns (address) {
        return WHITELIST_FEE_ADDRESS.at(_index);
    }

    /* Check whitelist Status */
    function getWhitelistAddressStatus(address _user) external view returns (bool) {
        return WHITELIST_FEE_ADDRESS.contains(_user);
    }

}