/**
    Modified from https://github.com/bugduino/idle-contracts/blob/master/contracts/mocks/cDAIMock.sol
    at commit b85dafa8e55e053cb2d403fc4b28cfe86f2116d4

    Original license:
    Copyright 2020 Idle Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
 */

pragma solidity 0.5.17;

// interfaces
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";


contract CERC20Mock is ERC20, ERC20Detailed {
    address public dai;

    uint256 internal _supplyRate;
    uint256 internal _exchangeRate;

    constructor(address _dai) public ERC20Detailed("cDAI", "cDAI", 8) {
        dai = _dai;
        uint256 daiDecimals = ERC20Detailed(_dai).decimals();
        _exchangeRate = 2 * (10**(daiDecimals + 8)); // 1 cDAI = 0.02 DAI
        _supplyRate = 45290900000; // 10% supply rate per year
    }

    function mint(uint256 amount) external returns (uint256) {
        require(
            ERC20(dai).transferFrom(msg.sender, address(this), amount),
            "Error during transferFrom"
        ); // 1 DAI
        _mint(msg.sender, (amount * 10**18) / _exchangeRate);
        return 0;
    }

    function redeemUnderlying(uint256 amount) external returns (uint256) {
        _burn(msg.sender, (amount * 10**18) / _exchangeRate);
        require(
            ERC20(dai).transfer(msg.sender, amount),
            "Error during transfer"
        ); // 1 DAI
        return 0;
    }

    function exchangeRateStored() external view returns (uint256) {
        return _exchangeRate;
    }

    function exchangeRateCurrent() external view returns (uint256) {
        return _exchangeRate;
    }

    function _setExchangeRateStored(uint256 _rate) external returns (uint256) {
        _exchangeRate = _rate;
    }

    function supplyRatePerBlock() external view returns (uint256) {
        return _supplyRate;
    }

    function _setSupplyRatePerBlock(uint256 _rate) external {
        _supplyRate = _rate;
    }
}
