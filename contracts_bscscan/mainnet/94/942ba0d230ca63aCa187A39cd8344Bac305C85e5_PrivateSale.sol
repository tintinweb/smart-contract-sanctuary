// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SaleBase.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract PrivateSale is SaleBase {
    using SafeMath for uint256;

    mapping(address=>bool) private _whiteLists;
    uint256 private _minUserCap;
    uint256 private _maxUserCap;

    constructor(
        uint256 rateNumerator,
        uint256 rateDenominator,
        IERC20 token,
        IERC20 paymentToken,
        address tokenWallet,
        uint256 cap,
        uint256 minUserCap,
        uint256 maxUserCap,
        uint256 openingTime,
        uint256 closingTime,
        uint256 holdPeriod
    ) public SaleBase(rateNumerator, rateDenominator, token, paymentToken, tokenWallet, cap, openingTime, closingTime, holdPeriod){
        require(minUserCap > 0, "usercap is 0");
        require(minUserCap <= maxUserCap, "min user cap great than max user cap");
        _minUserCap = minUserCap;
        _maxUserCap = maxUserCap;
    }

    function setUserCap(uint minUserCap, uint maxUserCap) external onlyOwner{
        _minUserCap = minUserCap;
        _maxUserCap = maxUserCap;
    }

    function minUserCap() public view returns(uint){
        return _minUserCap;
    }

    function maxUserCap() public view returns(uint){
        return _maxUserCap;
    }

    function setWhiteLists(address[] memory whiteLists) public onlyOwner(){
        for(uint i=0; i< whiteLists.length; i++){
            _whiteLists[whiteLists[i]] = true;
        }
    }

    function isInWhiteList(address account) public view returns(bool){
        return _whiteLists[account];
    }

    function _toBusd(uint tokenAmount) private view returns(uint){
        return tokenAmount.mul(rateNumerator()).div(rateDenominator());
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) override internal view {
        super._preValidatePurchase(beneficiary, weiAmount);
        require(_whiteLists[_msgSender()], "Address not in whitelist");
        uint busdAmount = _toBusd(balanceOf(beneficiary));
        require(busdAmount.add(weiAmount) <= _maxUserCap, "beneficiary's cap exceeded");
        require(busdAmount.add(weiAmount) >= _minUserCap, "beneficiary's cap minimal required");
    }
}