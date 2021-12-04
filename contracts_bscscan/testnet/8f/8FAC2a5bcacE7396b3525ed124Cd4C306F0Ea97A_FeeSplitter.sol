// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./IGatedERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./TokensRecoverable.sol";

contract FeeSplitter is TokensRecoverable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    
    uint256 devRateMin = 1000;  
    uint256 rootRateMin = 1000;

    address public devAddress;
    address public deployerAddress;

    address public burnAddress;

    mapping (IGatedERC20 => address[]) public feeCollectors;
    mapping (IGatedERC20 => uint256[]) public feeRates;
    mapping (IGatedERC20 => uint256) public burnRates;

    constructor(address _devAddress, address _burnAddress) {
        deployerAddress = msg.sender;
        devAddress = _devAddress;
        burnAddress = _burnAddress;
    }

    function setDevAddress(address _devAddress) public {
        require (msg.sender == deployerAddress || msg.sender == devAddress, "Not a deployer or dev address");
        devAddress = _devAddress;
    }

    function setBurnAddress(address _address) public {
        require (msg.sender == deployerAddress || msg.sender == devAddress, "Not a deployer or dev address");
        burnAddress = _address;
    }

    function setFees(IGatedERC20 token, uint256 burnRate, address[] memory collectors, uint256[] memory rates) public ownerOnly() {
        //require (collectors.length == rates.length && collectors.length > 1, "Fee Collectors and Rates must be the same size and contain at least 2 elements");
        require (collectors[0] == devAddress, "First address must be dev address");
        //require (rates[0] >= devRateMin && rates[1] >= rootRateMin, "First rate must be greater or equal to devRateMin and second rate must be greater or equal to rootRateMin");
        
        uint256 totalRate = burnRate;
        for (uint256 i = 0; i < rates.length; i++) {
            totalRate = totalRate + rates[i];
        }

        require (totalRate == 10000, "Total fee rate must be 100%");
        
        if (token.balanceOf(address(this)) > 0) {
            payFees(token);
        }

        feeCollectors[token] = collectors;
        feeRates[token] = rates;
        burnRates[token] = burnRate;
    }

    function payFees(IGatedERC20 token) public {
        uint256 balance = token.balanceOf(address(this));
        require (balance > 0, "Nothing to pay");

        if (burnRates[token] > 0) {
            uint256 burnAmount = burnRates[token] * balance / 10000;
            token.transfer(burnAddress, burnAmount);
        }

        address[] memory collectors = feeCollectors[token];
        uint256[] memory rates = feeRates[token];

        for (uint256 i = 0; i < collectors.length; i++) {
            address collector = collectors[i];
            uint256 rate = rates[i];

            if (rate > 0) {
                uint256 feeAmount = rate * balance / 10000;
                token.transfer(collector, feeAmount);
            }
        }
    }

    function canRecoverTokens(IERC20 token) internal override view returns (bool) {
        address[] memory collectors = feeCollectors[IGatedERC20(address(token))];
        return address(token) != address(this) && collectors.length == 0; 
    }
}