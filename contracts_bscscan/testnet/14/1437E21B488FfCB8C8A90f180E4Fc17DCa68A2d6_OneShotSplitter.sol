// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity 0.7.4;

import './SafeMath.sol';
import './IERC20.sol';

import './Ownable.sol';

contract OneShotSplitter is Ownable {
    using SafeMath for uint256;

    IERC20 public baseToken;

    address devAddress1; // The Don
    address devAddress2; // KingCozz
    address teamAddress; // Team Splitter Contract
    address promoAddress; // Promo/Marketing Splitter Contract

    modifier onlyAuthorised() {
        require(_authorised[msg.sender] || msg.sender == owner(), "NOT_AUTHORISED");
        _;
    }

    mapping (address => bool) _authorised;

    constructor (address _devAddress1, address _devAddress2, address _teamAddress, address _promoAddress) Ownable() {
        devAddress1 = _devAddress1;
        devAddress2 = _devAddress2;
        teamAddress = _teamAddress;
        promoAddress = _promoAddress;

        _authorised[msg.sender] = true;
        _authorised[devAddress1] = true;
        _authorised[devAddress2] = true;
        _authorised[teamAddress] = true;
        _authorised[promoAddress] = true;
    }

    function transferTokens(address _recipient, address _token, uint256 _amount) onlyAuthorised() public returns (bool _success) {
        baseToken = IERC20(_token);

        require(baseToken.balanceOf(address(this)) > 0, "NO_BALANCE");

        baseToken.transfer(_recipient, _amount);

        return true;
    }

    // If tokens need to be broken per-proportion
    function splitPayment(address _token) onlyAuthorised() public returns (bool _success) {
        baseToken = IERC20(_token);

        uint256 totalBase = baseToken.balanceOf(address(this));
        require(totalBase > 0, "NOTHING_TO_DISTRIBUTE");

        uint256 onePiece = (totalBase.div(15));

        uint256 _forSideKick = (2 * onePiece);
        uint256 _forTheDon   = (6 * onePiece);
        uint256 _forTheOGs   = (2 * onePiece);
        uint256 _promoFunds  = (5 * onePiece);

        baseToken.transfer(devAddress1, _forSideKick);
        baseToken.transfer(devAddress2, _forTheDon);
        baseToken.transfer(teamAddress, _forTheOGs);
        baseToken.transfer(promoAddress, _promoFunds);
        
        return true;
    }
}