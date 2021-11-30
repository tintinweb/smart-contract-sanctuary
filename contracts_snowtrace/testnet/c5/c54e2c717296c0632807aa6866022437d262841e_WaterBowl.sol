/**
 *Submitted for verification at testnet.snowtrace.io on 2021-11-29
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.0;

library Address {

    function isContract(address account) internal view returns (bool) {

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {

        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) - value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IFetch is IERC20 {
    function breed(address to, uint256 amount) external;
    function maxSupply() external view returns (uint256);
}

// We come to the water bowl to lap up liquidity. Mmmmmm.
// Max payout and capacity decrease as supply gets closer to max.
// FETCH is paid at the time of deposit.
contract WaterBowl {

    using SafeERC20 for IERC20;
    using SafeERC20 for IFetch;

    IFetch public immutable fetch;
    IERC20 public immutable lp;
    address public immutable kibble;

    uint256 public immutable DECAY = 600_000; // one week
    uint256 public immutable openPrice = 5e7; // floor price to break - 20b FETCH / gOHM

    uint256 public totalDebt; // Total value of outstanding bonds
    uint256 public lastDecay; // Last deposit

    constructor ( 
        address _fetch,
        address _lp,
        address _kibble
    ) {
        require( _fetch != address(0) );
        fetch = IFetch(_fetch);
        require( _lp != address(0) );
        lp = IERC20(_lp);
        require( _kibble != address(0) );
        kibble = _kibble;
    }

    /**
        @notice deposit bond
        @param amount uint
        @param maxPrice uint
        @return uint
     */
    function deposit( 
        uint amount, 
        uint maxPrice
    ) external returns ( uint ) {
        decayDebt();

        uint price = bondPrice();

        require(maxPrice >= price, "Slippage limit: more than max price");

        uint payout = payoutFor(amount);
        require(payout <= maxPayout(), "Bond too large");

        lp.safeTransferFrom(msg.sender, address(this), amount);
        fetch.breed(msg.sender, payout);

        totalDebt += payout; // increase total debt
        return payout;
    }

    /**
     *  @notice reduce total debt
     */
    function decayDebt() internal {
        totalDebt = totalDebt - debtDecay();
        lastDecay = block.timestamp;
    }

    /**
     *  @notice amount to decay total debt by
     *  @return decay_ uint
     */
    function debtDecay() public view returns ( uint decay_ ) {
        uint secondsSinceLast = block.timestamp - lastDecay;
        decay_ = totalDebt * secondsSinceLast / DECAY;
        if ( decay_ > totalDebt ) {
            decay_ = totalDebt;
        }
    }

    /**
     *  @notice calculate debt factoring in decay
     *  @return uint
     */
    function currentDebt() public view returns ( uint ) {
        return totalDebt - debtDecay();
    }

    /**
        @notice calculate payout due for new bond
        @param amount uint
        @return uint256
     */
    function payoutFor(uint amount) public view returns (uint256) {
        return amount * 1e18 / bondPrice();
    }

    /**
        @notice calculate current bond price
        @return price_ uint256
     */
    function bondPrice() public view returns (uint256 price_) { 
        if (controlVariable() >= debtRatio()) {
            price_ = openPrice;
        } else {
            price_ = debtRatio() / controlVariable();
            if (price_ < openPrice) {
                price_ = openPrice;
            }
        }
    }

    /**
        @notice calculate current debt ratio
        @return uint256
     */
    function debtRatio() public view returns (uint256) {
        return currentDebt() * 1e18 / circulatingSupply(); 
    }

    /**
        @notice determine maximum bond size
        @return uint
     */
    function maxPayout() public view returns (uint256) {
        uint256 supply = circulatingSupply();
        uint256 maxSupply = fetch.maxSupply();
        uint256 max;
        if (supply < maxSupply / 10) {
            max = 100;
        } else if (supply < maxSupply / 5) {
            max = 50;
        } else if (supply < maxSupply / 3) {
            max = 25;
        } else if (supply < maxSupply / 2) {
            max = 10;
        } else {
            max = 5;
        }
        return supply * max / 10_000;
    }

    /**
     * @notice determine speed
     * @return uint256
     */
    function controlVariable() public view returns (uint256) {
        uint256 supply = circulatingSupply();
        uint256 maxSupply = fetch.maxSupply();
        if (supply < maxSupply / 10) {
            return 1e12;
        } else if (supply < maxSupply / 5) {
            return 1e11;
        } else if (supply < maxSupply / 3) {
            return 5e10;
        } else if (supply < maxSupply / 2) {
            return 2e10;
        } else {
            return 1e10;
        }
    }

    function circulatingSupply() public view returns (uint256) {
        return fetch.totalSupply() - fetch.balanceOf(kibble);
    }

    /**
        @notice allow anyone to send lost tokens (excluding LP or OHM) to the DAO
     */
    function recoverLostToken(address token_) external {
        require(token_ != address(fetch), "woof");
        require(token_ != address(lp), "woof");
        IERC20(token_).safeTransfer(msg.sender, IERC20(token_).balanceOf( address(this)));
    }
}