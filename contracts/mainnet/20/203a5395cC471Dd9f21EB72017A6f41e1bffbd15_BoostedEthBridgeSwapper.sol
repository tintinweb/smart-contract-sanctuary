//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "./ZkSyncBridgeSwapper.sol";
import "./interfaces/ILido.sol";
import "./interfaces/ICurvePool.sol";
import "./interfaces/IYearnVault.sol";

/**
* @notice Exchanges Eth for the "Yearn vault Curve pool staked Eth" token.
* Indexes:
* 0: Eth
* 1: yvCrvStEth
*/
contract BoostedEthBridgeSwapper is ZkSyncBridgeSwapper {

    address public immutable stEth;
    address public immutable crvStEth;
    address public immutable yvCrvStEth;

    ICurvePool public immutable stEthPool;
    address public immutable lidoReferral;
    address[2] public tokens;

    constructor(
        address _zkSync,
        address _l2Account,
        address _yvCrvStEth,
        address _stEthPool,
        address _lidoReferral
    )
        ZkSyncBridgeSwapper(_zkSync, _l2Account)
    {
        require(_yvCrvStEth != address(0), "null _yvCrvStEth");
        yvCrvStEth = _yvCrvStEth;
        address _crvStEth = IYearnVault(_yvCrvStEth).token();
        require(_crvStEth != address(0), "null crvStEth");

        require(_stEthPool != address(0), "null _stEthPool");

        require(_crvStEth == ICurvePool(_stEthPool).lp_token(), "crvStEth mismatch");
        crvStEth = _crvStEth;
        stEth = ICurvePool(_stEthPool).coins(1);
        stEthPool = ICurvePool(_stEthPool);
        lidoReferral = _lidoReferral;
        tokens = [ETH_TOKEN, _yvCrvStEth];
    }

    function exchange(uint256 _indexIn, uint256 _indexOut, uint256 _amountIn) external override returns (uint256 amountOut) {
        require(_indexIn + _indexOut == 1, "invalid indexes");

        if (_indexIn == 0) {
            transferFromZkSync(ETH_TOKEN);
            amountOut = swapEthForYvCrv(_amountIn);
            transferToZkSync(yvCrvStEth, amountOut);
            emit Swapped(ETH_TOKEN, _amountIn, yvCrvStEth, amountOut);
        } else {
            transferFromZkSync(yvCrvStEth);
            amountOut = swapYvCrvForEth(_amountIn);
            transferToZkSync(ETH_TOKEN, amountOut);
            emit Swapped(yvCrvStEth, _amountIn, ETH_TOKEN, amountOut);
        }
    }

    function swapEthForYvCrv(uint256 _amountIn) public payable returns (uint256) {
        // ETH -> crvStETH
        uint256 minLpAmount = getMinAmountOut((1 ether * _amountIn) / stEthPool.get_virtual_price());
        uint256 crvStEthAmount = stEthPool.add_liquidity{value: _amountIn}([_amountIn, 0], minLpAmount);

        // crvStETH -> yvCrvStETH
        IERC20(crvStEth).approve(yvCrvStEth, crvStEthAmount);
        return IYearnVault(yvCrvStEth).deposit(crvStEthAmount);
    }

    function swapYvCrvForEth(uint256 _amountIn) public returns (uint256) {
        // yvCrvStETH -> crvStETH
        uint256 crvStEthAmount = IYearnVault(yvCrvStEth).withdraw(_amountIn);

        // crvStETH -> ETH
        uint256 minAmountOut = getMinAmountOut((crvStEthAmount * stEthPool.get_virtual_price()) / 1 ether);
        return stEthPool.remove_liquidity_one_coin(crvStEthAmount, 0, minAmountOut);
    }

    function ethPerYvCrvStEth() public view returns (uint256) {
        return IYearnVault(yvCrvStEth).pricePerShare() * stEthPool.get_virtual_price() / 1 ether;
    }

    function yvCrvStEthPerEth() public view returns (uint256) {
        return (1 ether ** 2) / ethPerYvCrvStEth();
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "./interfaces/IZkSync.sol";
import "./interfaces/IBridgeSwapper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract ZkSyncBridgeSwapper is IBridgeSwapper {

    // The owner of the contract
    address public owner;
    // The max slippage accepted for swapping. Defaults to 1% with 6 decimals.
    uint256 public slippagePercent = 1e6;

    // The ZkSync bridge contract
    address public immutable zkSync;
    // The L2 market maker account
    address public immutable l2Account;

    address constant internal ETH_TOKEN = address(0);

    event OwnerChanged(address _owner, address _newOwner);
    event SlippageChanged(uint256 _slippagePercent);

    modifier onlyOwner {
        require(msg.sender == owner, "unauthorised");
        _;
    }

    constructor(address _zkSync, address _l2Account) {
        zkSync = _zkSync;
        l2Account = _l2Account;
        owner = msg.sender;
    }

    function changeOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "invalid input");
        owner = _newOwner;
        emit OwnerChanged(owner, _newOwner);
    }

    function changeSlippage(uint256 _slippagePercent) external onlyOwner {
        require(_slippagePercent != slippagePercent && _slippagePercent <= 100e6, "invalid slippage");
        slippagePercent = _slippagePercent;
        emit SlippageChanged(slippagePercent);
    }

    /**
    * @dev Check if there is a pending balance to withdraw in zkSync and withdraw it if applicable.
    * @param _token The token to withdraw.
    */
    function transferFromZkSync(address _token) internal {
        uint128 pendingBalance = IZkSync(zkSync).getPendingBalance(address(this), _token);
        if (pendingBalance > 0) {
            IZkSync(zkSync).withdrawPendingBalance(payable(address(this)), _token, pendingBalance);
        }
    }

    /**
    * @dev Deposit the ETH or ERC20 token to zkSync.
    * @param _outputToken The token that was given.
    * @param _amountOut The amount of given token.
    */
    function transferToZkSync(address _outputToken, uint256 _amountOut) internal {
        if (_outputToken == ETH_TOKEN) {
            // deposit Eth to L2 bridge
            IZkSync(zkSync).depositETH{value: _amountOut}(l2Account);
        } else {
            // approve the zkSync bridge to take the output token
            IERC20(_outputToken).approve(zkSync, _amountOut);
            // deposit the output token to the L2 bridge
            IZkSync(zkSync).depositERC20(IERC20(_outputToken), toUint104(_amountOut), l2Account);
        }
    }

    /**
    * @dev Safety method to recover ETH or ERC20 tokens that are sent to the contract by error.
    * @param _token The token to recover.
    */
    function recoverToken(address _token) external returns (uint256 balance) {
        bool success;
        if (_token == ETH_TOKEN) {
            balance = address(this).balance;
            (success, ) = owner.call{value: balance}("");
        } else {
            balance = IERC20(_token).balanceOf(address(this));
            success = IERC20(_token).transfer(owner, balance);
        }
        require(success, "failed to recover");
    }

    /**
     * @dev fallback method to make sure we can receive ETH
     */
    receive() external payable {
        
    }

    /**
     * @dev Returns the minimum accepted out amount.
     */
    function getMinAmountOut(uint256 _amountIn) internal view returns (uint256) {
        return _amountIn * (100e6 - slippagePercent) / 100e6;
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

interface ILido {
    function submit(address _referral) external payable returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

interface ICurvePool {
    function coins(uint256 _i) external view returns (address);
    function lp_token() external view returns (address);
    function get_virtual_price() external view returns (uint256);

    function exchange(int128 _i, int128 _j, uint256 _dx, uint256 _minDy) external returns (uint256);
    function add_liquidity(uint256[2] calldata _amounts, uint256 _minMintAmount) external payable returns (uint256);
    function remove_liquidity_one_coin(uint256 _amount, int128 _i, uint256 _minAmount) external payable returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

interface IYearnVault {
    function token() external view returns (address);
    function pricePerShare() external view returns (uint256);

    function deposit(uint256 _amount) external returns (uint256);
    function withdraw(uint256 _maxShares) external returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IZkSync {
    function getPendingBalance(address _address, address _token) external view returns (uint128);
    function withdrawPendingBalance(address payable _owner, address _token, uint128 _amount) external;
    function depositETH(address _zkSyncAddress) external payable;
    function depositERC20(IERC20 _token, uint104 _amount, address _zkSyncAddress) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

interface IBridgeSwapper {
    event Swapped(address _inputToken, uint256 _amountIn, address _outputToken, uint256 _amountOut);

    /**
    * @notice Perform an exchange between two tokens
    * @dev Index values can usually be found via the constructor arguments (if not hardcoded)
    * @param _indexIn Index value for the token to send
    * @param _indexOut Index valie of the token to receive
    * @param _amountIn Amount of `_indexIn` being exchanged
    * @return Actual amount of `_indexOut` received
    */
    function exchange(uint256 _indexIn, uint256 _indexOut, uint256 _amountIn) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}