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
pragma solidity >=0.8;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IUniswapV2.sol";

contract Market is Ownable {

    address public base;  // ERC-20 currency
    address public token; // ERC-20 share token

    address public copyright;
    uint8 public licenseFeeBps; // only charged on sales, max 1% i.e. 100

    uint256 private price; // current offer price, without drift
    uint256 public increment; // increment

    uint256 public driftStart;
    uint256 public timeToDrift; // seconds until drift pushes price by one drift increment
    int256 public driftIncrement;

    bool public buyingEnabled = true;
    bool public sellingEnabled = true;

    IUniswapV2 constant uniswap = IUniswapV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public weth;

    event Trade(address indexed token, address who, bytes ref, int amount, address base, uint totPrice, uint fee, uint newprice);

    constructor(address shareToken, uint256 price_, address baseCurrency, address owner) {
        base = baseCurrency;
        token = shareToken;
        price = price_;
        weth = uniswap.WETH();
        copyright = 0x29Fe8914e76da5cE2d90De98a64d0055f199d06D; // Aktionariat AG
        driftStart = block.timestamp;
        transferOwnership(owner);
    }

    function setPrice(uint256 newPrice, uint256 newIncrement) public onlyOwner {
        anchorPrice(newPrice);
        increment = newIncrement;
    }

    function hasDrift() public view returns (bool) {
        return timeToDrift != 0;
    }

    // secondsPerStep should be negative for downwards drift
    function setDrift(uint256 secondsPerStep, int256 newDriftIncrement) public onlyOwner {
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

    function getPriceInEther(uint256 shares) public view returns (uint256) {
        uint256 totPrice = getBuyPrice(shares);
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = base;
        return uniswap.getAmountsIn(totPrice, path)[0];
    }

    function buyWithEther(uint256 shares, bytes calldata ref) public payable returns (uint256) {
        require(buyingEnabled);
        uint256 totPrice = getBuyPrice(shares);
        uint256 totPriceEth = getPriceInEther(shares);
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = base;
        uint256[] memory amounts = uniswap.swapETHForExactTokens{value: totPriceEth}(totPrice, path, address(this), block.timestamp);
        assert(totPrice == amounts[1]);
        _buy(msg.sender, msg.sender, shares, amounts[1], ref);
        if (address(this).balance > 0){
            payable(msg.sender).transfer(address(this).balance);
        }
        return amounts[0];
    }

    function buy(uint256 numberOfSharesToBuy, bytes calldata ref) public returns (uint256) {
        require(buyingEnabled);
        return buy(msg.sender, numberOfSharesToBuy, ref);
    }

    function buy(address recipient, uint256 numberOfSharesToBuy, bytes calldata ref) public returns (uint256) {
        require(buyingEnabled);
        return _buy(msg.sender, recipient, numberOfSharesToBuy, 0, ref);
    }

    function _buy(address paying, address recipient, uint256 shares, uint256 alreadyPaid, bytes calldata ref) internal returns (uint256) {
        uint256 totPrice = getBuyPrice(shares);
        IERC20 baseToken = IERC20(base);
        if (totPrice > alreadyPaid){
            require(baseToken.transferFrom(paying, address(this), totPrice - alreadyPaid));
        } else if (totPrice < alreadyPaid){
            // caller paid to much, return excess amount
            require(baseToken.transfer(paying, alreadyPaid - totPrice));
        }
        IERC20 shareToken = IERC20(token);
        require(shareToken.transfer(recipient, shares));
        price = price + (shares * increment);
        emit Trade(token, paying, ref, int256(shares), base, totPrice, 0, getPrice());
        return totPrice;
    }

    function _notifyMoneyReceived(address from, uint256 amount, bytes calldata ref) internal {
        uint shares = getShares(amount);
        _buy(from, from, shares, amount, ref);
    }

    function sell(uint256 tokens, bytes calldata ref) public returns (uint256){
        require(sellingEnabled);
        return sell(msg.sender, tokens, ref);
    }

    function sell(address recipient, uint256 tokens, bytes calldata ref) public returns (uint256){
        require(sellingEnabled);
        return _sell(msg.sender, recipient, tokens, ref);
    }

    function _sell(address seller, address recipient, uint256 shares, bytes calldata ref) internal returns (uint256) {
        IERC20 shareToken = IERC20(token);
        require(shareToken.transferFrom(seller, address(this), shares));
        return _notifyTokensReceived(recipient, shares, ref);
    }

    // ERC-677 recipient
    function onTokenTransfer(address from, uint256 amount, bytes calldata ref) public returns (bool success) {
        require(msg.sender == token || msg.sender == base);
        if (msg.sender == token){
            require(sellingEnabled);
            _notifyTokensReceived(from, amount, ref);
        } else if (msg.sender == base){
            require(buyingEnabled);
            _notifyMoneyReceived(from, amount, ref);
        } else {
            require(false);
        }
        return true;
    }

    function _notifyTokensReceived(address recipient, uint256 amount, bytes calldata ref) internal returns (uint256) {
        uint256 totPrice = getSellPrice(amount);
        IERC20 baseToken = IERC20(base);
        uint256 fee = getSaleFee(totPrice);
        if (fee > 0){
            require(baseToken.transfer(copyright, fee));
        }
        require(baseToken.transfer(recipient, totPrice - fee));
        price -= amount * increment;
        emit Trade(token, recipient, ref, -int256(amount), base, totPrice, fee, getPrice());
        return totPrice;
    }

    function getSaleFee(uint256 totalPrice) public view returns (uint256) {
        return totalPrice * licenseFeeBps / 10000;
    }

    function getSaleProceeds(uint256 shares) public view returns (uint256) {
        uint256 total = getSellPrice(shares);
        return total - getSaleFee(total);
    }

    function getSellPrice(uint256 shares) public view returns (uint256) {
        return getPrice(getPrice() - (shares * increment), shares);
    }

    function getBuyPrice(uint256 shares) public view returns (uint256) {
        return getPrice(getPrice(), shares);
    }

    function getPrice(uint256 lowest, uint256 shares) internal view returns (uint256){
        if (shares == 0){
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
        while (min + 1 < max){
            uint256 middle = (min + max)/2;
            uint256 totalPrice = getPrice(currentPrice, middle);
            if (totalPrice > money){
                max = middle;
            } else {
                min = middle;
            }
        }
        return min;
    }

    function setCopyright(address newOwner) public {
        require(msg.sender == copyright);
        copyright = newOwner;
    }

    function setLicenseFee(uint8 bps) public {
        require(msg.sender == copyright);
        require(bps <= 100);
        licenseFeeBps = bps;
    }

    function withdraw(address ercAddress, address to, uint256 amount) public onlyOwner() {
        IERC20 erc20 = IERC20(ercAddress);
        require(erc20.transfer(to, amount), "Transfer failed");
    }

    function setEnabled(bool newBuyingEnabled, bool newSellingEnabled) public onlyOwner() {
        buyingEnabled = newBuyingEnabled;
        sellingEnabled = newSellingEnabled;
    }
}