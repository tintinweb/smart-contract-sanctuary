// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

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

interface IBrokerbot {
  
  function base() external view returns (address);
  
  function settings() external view returns (uint256);

  function processIncoming(address token_, address from, uint256 amount, bytes calldata ref) external payable returns (uint256);

}

// SPDX-License-Identifier: MIT
// https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/interfaces/IQuoter.sol
pragma solidity ^0.8.0;

interface IQuoter {
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
    
    // solhint-disable-next-line func-name-mixedcase
    function WETH9() external view returns (address);
}

interface ISwapRouter {
    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);
    
    function refundETH() external payable;
}

/**
* SPDX-License-Identifier: LicenseRef-Aktionariat
*
* MIT License with Automated License Fee Payments
*
* Copyright (c) 2021 Aktionariat AG (aktionariat.com)
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

import "../utils/Address.sol";
import "../ERC20/IERC20.sol";
import "./IUniswapV3.sol";
import "../utils/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./IBrokerbot.sol";

/**
 * A hub for payments. This allows tokens that do not support ERC 677 to enjoy similar functionality,
 * namely interacting with a token-handling smart contract in one transaction, without having to set an allowance first.
 * Instead, an allowance needs to be set only once, namely for this contract.
 * Further, it supports automatic conversion from Ether to the payment currency through Uniswap or the reception of Ether
 * using the current exchange rate as found in the chainlink oracle.
 */
contract PaymentHub {

    address public immutable weth;
    
    IQuoter private constant UNISWAP_QUOTER = IQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);
    ISwapRouter private constant UNISWAP_ROUTER = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    AggregatorV3Interface internal immutable priceFeedCHFUSD;
    AggregatorV3Interface internal immutable priceFeedETHUSD;


    constructor(address _aggregatorCHFUSD, address _aggregatorETHUSD) {
        weth = UNISWAP_QUOTER.WETH9();
        priceFeedCHFUSD = AggregatorV3Interface(_aggregatorCHFUSD);
        priceFeedETHUSD = AggregatorV3Interface(_aggregatorETHUSD);
    }

    /**
     * Get price in Ether depding on brokerbot setting.
     * If keep ETH is set price is from oracle.
     * This is the method that the Brokerbot widget should use to quote the price to the user.
     */
    function getPriceInEther(uint256 amountInBase, address brokerBot) public returns (uint256) {
        if ((brokerBot != address(0)) && hasSettingKeepEther(brokerBot)) {
            return getPriceInEtherFromOracle(amountInBase, IBrokerbot(brokerBot).base());
        } else {
            return UNISWAP_QUOTER.quoteExactOutputSingle(weth, IBrokerbot(brokerBot).base(), 3000, amountInBase, 0);
        }
    }

    /**
     * Price in ETH with 18 decimals
     */
    function getPriceInEtherFromOracle(uint256 amountInBase, address base) public view returns (uint256) {
        if(isBaseCurrencyCHF(base)) {
            return getPriceInUSD(amountInBase) * 10**8 / uint256(getLatestPriceETHUSD());
        }
        return amountInBase * 10**8 / uint256(getLatestPriceETHUSD());
    }

    /**
     * Price in USD with 18 decimals
     */
    function getPriceInUSD(uint256 amountInBase) public view returns (uint256) {
        return (uint256(getLatestPriceCHFUSD()) * amountInBase) / 10**8;
    }

    /**
     * Returns the latest price of eth/usd pair from chainlink with 8 decimals
     */
    function getLatestPriceETHUSD() public view returns (int256) {
        (, int256 price, , , ) = priceFeedETHUSD.latestRoundData();
        return price;
    }

    /**
     * Returns the latest price of chf/usd pair from chainlink with 8 decimals
     */
    function getLatestPriceCHFUSD() public view returns (int) {
        (, int price, , , ) = priceFeedCHFUSD.latestRoundData();
        return price;
    }

    /**
     * Convenience method to swap ether into currency and pay a target address
     */
    function payFromEther(address recipient, uint256 amountInBase, address base) public payable {
        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams(
            // rely on time stamp is ok, no exact time stamp needed
            // solhint-disable-next-line not-rely-on-time
            weth, base, 3000, recipient, block.timestamp, amountInBase, msg.value, 0);

        // Executes the swap returning the amountIn needed to spend to receive the desired amountOut.
        uint256 amountIn = UNISWAP_ROUTER.exactOutputSingle{value: msg.value}(params);

        // For exact output swaps, the amountInMaximum may not have all been spent.
        // If the actual amount spent (amountIn) is less than the specified maximum amount, we must refund the msg.sender and approve the swapRouter to spend 0.
        if (amountIn < msg.value) {
            UNISWAP_ROUTER.refundETH();
            payable(msg.sender).transfer(msg.value - amountIn); // return change
        }
    }

    function multiPay(address token, address[] calldata recipients, uint256[] calldata amounts) public {
        for (uint i=0; i<recipients.length; i++) {
            IERC20(token).transferFrom(msg.sender, recipients[i], amounts[i]);
        }
    }

    /**
     * Can (at least in theory) save some gas as the sender balance only is touched in one transaction.
     */
    function multiPayAndNotify(address token, address[] calldata recipients, uint256[] calldata amounts, bytes calldata ref) external {
        for (uint i=0; i<recipients.length; i++) {
            payAndNotify(token, recipients[i], amounts[i], ref);
        }
    }

    // Allows to make a payment from the sender to an address given an allowance to this contract
    // Equivalent to xchf.transferAndCall(recipient, amountInBase)
    function payAndNotify(address recipient, uint256 amountInBase, bytes calldata ref) external {
        payAndNotify(IBrokerbot(recipient).base(), recipient, amountInBase, ref);
    }

    function payAndNotify(address token, address recipient, uint256 amount, bytes calldata ref) public {
        IERC20(token).transferFrom(msg.sender, recipient, amount);
        IBrokerbot(recipient).processIncoming(token, msg.sender, amount, ref);
    }

    function payFromEtherAndNotify(address recipient, uint256 amountInBase, bytes calldata ref) external payable {
        address base = IBrokerbot(recipient).base();
        // Check if the brokerbot has setting to keep ETH
        if (hasSettingKeepEther(recipient)) {
            uint256 priceInEther = getPriceInEtherFromOracle(amountInBase, base);
            IBrokerbot(recipient).processIncoming{value: priceInEther}(base, msg.sender, amountInBase, ref);

            // Pay back ETH that was overpaid
            if (priceInEther < msg.value) {
                payable(msg.sender).transfer(msg.value - priceInEther); // return change
            }

        } else {
            payFromEther(recipient, amountInBase, base);
            IBrokerbot(recipient).processIncoming(base, msg.sender, amountInBase, ref);
        }
    }

    /**
     * Checks if the recipient(brokerbot) has setting enabled to keep ether
     */
    function hasSettingKeepEther(address recipient) public view returns (bool) {
        return IBrokerbot(recipient).settings() & 0x4 == 0x4;
    }

    function isBaseCurrencyCHF(address base) private pure returns (bool) {
        if (base == address(0xB4272071eCAdd69d933AdcD19cA99fe80664fc08)) {
            return true;
        }
        return false;
    }

    /**
     * In case tokens have been accidentally sent directly to this contract.
     * Make sure to be fast as anyone can call this!
     */
    function recover(address ercAddress, address to, uint256 amount) external {
        IERC20(ercAddress).transfer(to, amount);
    }

    // Important to receive ETH refund from Uniswap
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// Copied from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
// and modified it.

pragma solidity ^0.8.0;

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 weiValue) internal returns (bytes memory) {
        require(data.length == 0 || isContract(target), "transfer or contract");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // TODO: I think this does not lead to correct error messages.
            revert(string(returndata));
        }
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