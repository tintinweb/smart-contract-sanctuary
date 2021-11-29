/**
* SPDX-License-Identifier: MIT
*
* Copyright (c) 2016-2019 zOS Global Limited
*
*/
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */

interface IERC20 {

    // Optional functions
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    event NameChanged(string name, string symbol);

    function decimals() external view returns (uint8);

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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC677Receiver {
    
    function onTokenTransfer(address from, uint256 amount, bytes calldata data) external returns (bool);

}

// SPDX-License-Identifier: MIT
// Copied from https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/UniswapV2Router02.sol
pragma solidity ^0.8.0;

interface ITokenReceiver {

    function onTokenTransfer(address token, address from, uint256 amount, bytes calldata data) external;

}

/**
* SPDX-License-Identifier: LicenseRef-Aktionariat
*
* MIT License with Automated License Fee Payments
*
* Copyright (c) 2020 Aktionariat AG (aktionariat.com)
*
* Permission is hereby granted to any person obtaining a copy of this software
* and associated documentation files (the "Software"), to deal in the Software
* without restriction, including without limitation the rights to use, copy,
* modify, merge, publish, distribute, sublicense, and/or sell copies of the
* Software, and to permit persons to whom the Software is furnished to do so,
* subject to the following conditions:
*
* - The above copyright notice and this permission notice shall be included in
*   all copies or substantial portions of the Software.
* - All automated license fee payments integrated into this and related Software
*   are preserved.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/
pragma solidity ^0.8.0;

import "../utils/Ownable.sol";
import "../ERC20/IERC20.sol";
import "../interfaces/ITokenReceiver.sol";
import "../interfaces/IERC677Receiver.sol";

contract Brokerbot is Ownable {

    address public paymenthub;

    address public immutable base;  // ERC-20 currency
    address public immutable token; // ERC-20 share token

    address public constant copyright = 0x29Fe8914e76da5cE2d90De98a64d0055f199d06D; // Aktionariat AG

    uint256 private price; // current offer price, without drift
    uint256 public increment; // increment

    uint256 public driftStart;
    uint256 public timeToDrift; // seconds until drift pushes price by one drift increment
    int256 public driftIncrement;

    uint8 private constant licenseFeeBps = 90;

    uint8 private constant BUYING_ENABLED = 0x1;
    uint8 private constant SELLING_ENABLED = 0x2;
    uint8 private constant VERSION = 0x1;

    // more bits to be used by payment hub
    uint256 public settings = BUYING_ENABLED | SELLING_ENABLED | (VERSION<<248);

    event Trade(address indexed token, address who, bytes ref, int amount, address base, uint totPrice, uint fee, uint newprice);

    constructor(
        address _shareToken,
        uint256 _price,
        uint256 _increment,
        address _baseCurrency,
        address _owner
    )
        Ownable(_owner)
    {
        base = _baseCurrency;
        token = _shareToken;
        price = _price;
        increment = _increment;
        paymenthub = address(0x3eABee781f6569328143C610700A99E9ceE82cba);
    }

    function setPrice(uint256 newPrice, uint256 newIncrement) external onlyOwner {
        anchorPrice(newPrice);
        increment = newIncrement;
    }

    function hasDrift() public view returns (bool) {
        return timeToDrift != 0;
    }

    // secondsPerStep should be negative for downwards drift
    function setDrift(uint256 secondsPerStep, int256 newDriftIncrement) external onlyOwner {
        anchorPrice(getPrice());
        timeToDrift = secondsPerStep;
        driftIncrement = newDriftIncrement;
    }

    function anchorPrice(uint256 currentPrice) private {
        price = currentPrice;
        driftStart = block.timestamp;
    }

    function getPrice() public view returns (uint256) {
        return getPriceAtTime(block.timestamp);
    }

    function getPriceAtTime(uint256 timestamp) public view returns (uint256) {
        if (hasDrift()){
            uint256 passed = timestamp - driftStart;
            int256 drifted = int256(passed / timeToDrift) * driftIncrement;
            int256 driftedPrice = int256(price) + drifted;
            if (driftedPrice < 0){
                return 0;
            } else {
                return uint256(driftedPrice);
            }
        } else {
            return price;
        }
    }

    function buy(address from, uint256 paid, bytes calldata ref) internal returns (uint256) {
        uint shares = getShares(paid);
        uint costs = notifyTraded(from, shares, ref);
        if (costs < paid){
            IERC20(base).transfer(from, paid - costs);
        }
        IERC20(token).transfer(from, shares);
        return shares;
    }

    function notifyTraded(address from, uint256 shares, bytes calldata ref) internal returns (uint256) {
        require(hasSetting(BUYING_ENABLED));
        uint costs = getBuyPrice(shares);
        price = price + (shares * increment);
        emit Trade(token, from, ref, int256(shares), base, costs, 0, getPrice());
        return costs;
    }

    function notifyTrade(address buyer, uint256 shares, bytes calldata ref) external onlyOwner {
        notifyTraded(buyer, shares, ref);
    }

    function notifyTradeAndTransfer(address buyer, uint256 shares, bytes calldata ref) public onlyOwner {
        notifyTraded(buyer, shares, ref);
        IERC20(token).transfer(buyer, shares);
    }

    function notifyTrades(address[] calldata buyers, uint256[] calldata shares, bytes[] calldata ref) external onlyOwner {
        for (uint i = 0; i < buyers.length; i++) {
            notifyTraded(buyers[i], shares[i], ref[i]);
        }
    }

    function notifyTradesAndTransfer(address[] calldata buyers, uint256[] calldata shares, bytes[] calldata ref) external onlyOwner {
        for (uint i = 0; i < buyers.length; i++) {
            notifyTradeAndTransfer(buyers[i], shares[i], ref[i]);
        }
    }

    /**
     * Payment hub might actually have sent another accepted token, including Ether.
     */
    function processIncoming(address token_, address from, uint256 amount, bytes calldata ref) public payable returns (uint256) {
        require(msg.sender == token_ || msg.sender == base || msg.sender == paymenthub);
        if (token_ == token){
            return sell(from, amount, ref);
        } else if (token_ == base){
            return buy(from, amount, ref);
        } else {
            require(false);
            return 0;
        }
    }

    // ERC-677 recipient
    function onTokenTransfer(address from, uint256 amount, bytes calldata ref) external returns (bool) {
        processIncoming(msg.sender, from, amount, ref);
        return true;
    }

    // ITokenReceiver
    function onTokenTransfer(address token_, address from, uint256 amount, bytes calldata ref) external {
        processIncoming(token_, from, amount, ref);
    }

    function buyingEnabled() external view returns (bool){
        return hasSetting(BUYING_ENABLED);
    }

    function sellingEnabled() external view returns (bool){
        return hasSetting(SELLING_ENABLED);
    }

    function hasSetting(uint256 setting) private view returns (bool) {
        return settings & setting == setting;
    }

    function isDirectSale(bytes calldata ref) internal pure returns (bool) {
        if (ref.length == 0 || ref.length == 20) {
            return true; // old format
        } else {
            if (ref[0] == bytes1(0x01)){
                return true;
            } else if (ref[0] == bytes1(0x02)) {
                return false;
            } else {
                require(false, "unknown ref");
                return true;
            }
        }
    }


    function sell(address recipient, uint256 amount, bytes calldata ref) internal returns (uint256) {
        require(hasSetting(SELLING_ENABLED));
        uint256 totPrice = getSellPrice(amount);
        IERC20 baseToken = IERC20(base);
        uint256 fee = getLicenseFee(totPrice);
        if (fee > 0){
            baseToken.transfer(copyright, fee);
        }
        if (isDirectSale(ref)){
            baseToken.transfer(recipient, totPrice - fee);
        }
        price -= amount * increment;
        emit Trade(token, recipient, ref, -int256(amount), base, totPrice, fee, getPrice());
        return totPrice;
    }

    function getLicenseFee(uint256 totPrice) public pure returns (uint256) {
        return totPrice * licenseFeeBps / 10000;
    }

    function getSellPrice(uint256 shares) public view returns (uint256) {
        return getPrice(getPrice() - (shares * increment), shares);
    }

    function getBuyPrice(uint256 shares) public view returns (uint256) {
        return getPrice(getPrice(), shares);
    }

    function getPrice(uint256 lowest, uint256 shares) internal view returns (uint256){
        if (shares == 0) {
            return 0;
        } else {
            uint256 highest = lowest + (shares - 1) * increment;
            return ((lowest + highest) / 2) * shares;
        }
    }

    function getShares(uint256 money) public view returns (uint256) {
        uint256 currentPrice = getPrice();
        uint256 min = 0;
        uint256 max = money / currentPrice;
        while (min < max){
            uint256 middle = (min + max)/2;
            uint256 totalPrice = getPrice(currentPrice, middle);
            if (money > totalPrice){
                min = middle + 1;
            } else {
                max = middle;
            }
        }
        return min;
    }

    function withdrawEther(uint256 amount) external ownerOrHub() {
        payable(msg.sender).transfer(amount); // return change
    }

    function approve(address erc20, address who, uint256 amount) external onlyOwner() {
        IERC20(erc20).approve(who, amount);
    }

    function withdraw(address ercAddress, address to, uint256 amount) external ownerOrHub() {
        IERC20(ercAddress).transfer(to, amount);
    }

    function setPaymentHub(address hub) external onlyOwner() {
        paymenthub = hub;
    }

    function setSettings(uint256 settings_) external onlyOwner() {
        settings = settings_;
    }

    function setEnabled(bool newBuyingEnabled, bool newSellingEnabled) external onlyOwner() {
        if (newBuyingEnabled != hasSetting(BUYING_ENABLED)){
            settings ^= BUYING_ENABLED;
        }
        if (newSellingEnabled != hasSetting(SELLING_ENABLED)){
            settings ^= SELLING_ENABLED;
        }
    }
    
    modifier ownerOrHub() {
        require(owner == msg.sender || paymenthub == msg.sender, "not owner");
        _;
    }
}

// SPDX-License-Identifier: MIT
//
// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
//
// Modifications:
// - Replaced Context._msgSender() with msg.sender
// - Made leaner
// - Extracted interface

pragma solidity ^0.8.0;

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
contract Ownable {

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor (address initialOwner) {
        owner = initialOwner;
        emit OwnershipTransferred(address(0), owner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "not owner");
        _;
    }
}