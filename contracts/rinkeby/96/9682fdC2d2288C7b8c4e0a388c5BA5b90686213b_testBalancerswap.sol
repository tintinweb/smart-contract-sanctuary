// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './interface/IbalancerV2.sol';
import './interface/IERC20.sol';
import './interface/IAsset.sol';
//pragma experimental ABIEncoderV2;

contract testBalancerswap{
    
    address private constant balancerVault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    event BeeSwap(address sender, address tokenIn, address tokenOut, uint256 tokenInAmount, uint256 tokenOutAmount, uint256 timeStamp);
    function usesingleSwap(
        Ibal.SingleSwap calldata singleSwap,
        Ibal.FundManagement calldata funds,
        uint256 limit,
        uint256 deadline) external payable returns (uint256 amountCalculated) 
        {
            address sender = msg.sender;
            address TokenInAdd = address(singleSwap.assetIn);
            address TokenOutAdd = address(singleSwap.assetOut);
            IERC20(TokenInAdd).transferFrom(sender, address(this), singleSwap.amount); 
            IERC20(TokenInAdd).approve(balancerVault,  singleSwap.amount);
            amountCalculated = Ibal(balancerVault).swap { value: msg.value }(singleSwap , funds, limit, deadline);
            //address tokenoutadd = singleSwap.assetOut;
            uint amountout = IERC20(TokenOutAdd).balanceOf(address(this));
            IERC20(TokenOutAdd).transfer(sender, amountout);
            emit BeeSwap(sender,TokenInAdd, TokenOutAdd, singleSwap.amount, amountout, block.timestamp);
        }


   //function useBatchswap(
   //     //address TokenInAdd,
   //     //address TokenOutAdd,
   //     //uint32 TokenIn, 
   //     Ibal.SwapKind kind,
   //     Ibal.BatchSwapStep[] calldata swaps,
   //     IAsset[] calldata assets,
   //     Ibal.FundManagement calldata funds,
   //     int256[] calldata limits,
   //     uint256 deadline
   //     ) external payable returns (int256[] memory assetDeltas) 
   //     {
   //         //TokenIn = swaps[]
   //         address sender = msg.sender;
   //         uint256 contractBalanceBefore = IERC20(TokenOutAdd).balanceOf(address(this));
   //         
   //         
   //         IERC20(TokenInAdd).transferFrom(sender, address(this),  TokenIn);
   //         IERC20(TokenInAdd).approve(balancerVault,  TokenIn);
   //         assetDeltas = Ibal(balancerVault).batchSwap{ value: msg.value }(kind, swaps, assets, funds, limits, deadline);
   //         uint256 amountout = IERC20(TokenOutAdd).balanceOf(address(this)) - contractBalanceBefore; 
   //         IERC20(TokenOutAdd).transfer(sender, amountout);
   //         emit BeeSwap(sender, TokenInAdd, TokenOutAdd, TokenIn, amountout, block.timestamp);
   //         return assetDeltas;
   //     }
   //       
//
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0 || ^0.6.6;
pragma experimental ABIEncoderV2;
import "./IAsset.sol";
interface Ibal{
   enum SwapKind { GIVEN_IN, GIVEN_OUT }

   struct SingleSwap{
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement{
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountCalculated);

    struct BatchSwapStep{
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }
    function setRelayerApproval(
        address send,
        address cont,
        bool approved
    )
    external returns(bool approv);    

    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] calldata swaps,
        IAsset[] calldata assets,
        FundManagement calldata funds,
        int256[] calldata limits,
        uint256 deadline
    )
        external
        payable
        returns (int256[] memory assetDeltas);
    

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function name() external view returns (string memory) ;

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view  returns (string memory) ;

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view  returns (uint8);
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

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >0.6.0;

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {
    // solhint-disable-previous-line no-empty-blocks

}