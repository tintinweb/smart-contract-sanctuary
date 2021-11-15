// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

import {
    IPangolinRouter
} from "@pangolindex/exchange-contracts/contracts/pangolin-periphery/interfaces/IPangolinRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IExperiPie.sol";
import "../interfaces/IPangolinRebalanceManager.sol";

contract PangolinRebalanceManager is IPangolinRebalanceManager {
    IExperiPie public immutable basket;
    IPangolinRouter public immutable pangolin;
    address public rebalanceManager; 
    IERC20 private immutable nativeToken;

    event Rebalanced(address indexed basket);
    event Swaped(
        address indexed basket,
        address indexed fromToken,
        address indexed toToken,
        uint256 quantity,
        uint256 returnedQuantity
    );
    event RebalanceManagerSet(address indexed rebalanceManager);

    constructor(address _basket, address _pangolin, address _nativeToken) {
        require(_basket != address(0), "INVALID_BASKET");
        require(_pangolin != address(0), "INVALID_PANGOLIN");
        require(_nativeToken != address(0), "INVALID_NATIVE_TOKEN");

        basket = IExperiPie(_basket);
        pangolin = IPangolinRouter(_pangolin);
        rebalanceManager = msg.sender;
        nativeToken = IERC20(_nativeToken);
    }

    modifier onlyRebalanceManager() {
        require(
            msg.sender == rebalanceManager, "NOT_ALLOWED"
        );
        _;
    }

    function setRebalanceManager(address _rebalanceManager) external onlyRebalanceManager {
        rebalanceManager = _rebalanceManager;
        emit RebalanceManagerSet(_rebalanceManager);
    }

    function _swap(
        address fromToken,
        address toToken,
        uint256 quantity,
        uint256 minReturn,
        address recipient,
        uint256 deadline
    ) internal {
        // approve fromToken to pangolin
        // IERC20(fromToken).approve(address(pangolin), uint256(-1));
        if(IERC20(fromToken).allowance(address(basket), address(pangolin)) < quantity){
            basket.singleCall(
                fromToken,
                abi.encodeWithSelector(
                    IERC20(fromToken).approve.selector,
                    address(pangolin),
                    uint256(-1)
                ),
                0
            );
        }

        // Swap on pangolin
        // pangolin.swapExactTokensForTokens(amount, minReturnAmount, path, recipient, deadline);
        address[] memory path = new address[](3);
        path[0] = fromToken;
        path[1] = address(nativeToken);
        path[2] = toToken;
        basket.singleCall(
            address(pangolin),
            abi.encodeWithSelector(
                pangolin.swapExactTokensForTokens.selector,
                quantity,
                minReturn,
                path,
                recipient,
                deadline
            ),
            0
        );

        emit Swaped(address(basket), fromToken, toToken, quantity, minReturn);
    }

    function removeToken(address _token) internal {
        uint256 balance = basket.balance(_token);
        bool inPool = basket.getTokenInPool(_token);
        //if there is a token balance of the token is not in the pool, skip
        if (balance != 0 || !inPool) {
            return;
        }

        // remove token
        basket.singleCall(
            address(basket),
            abi.encodeWithSelector(basket.removeToken.selector, _token),
            0
        );
    }

    function addToken(address _token) internal {
        uint256 balance = basket.balance(_token);
        bool inPool = basket.getTokenInPool(_token);
        // If token has no balance or is already in the pool, skip
        if (balance == 0 || inPool) {
            return;
        }

        // add token
        basket.singleCall(
            address(basket),
            abi.encodeWithSelector(basket.addToken.selector, _token),
            0
        );
    }

    function lockBasketData(uint256 _block)
        internal
        returns (bytes memory data)
    {
        basket.singleCall(
            address(basket),
            abi.encodeWithSelector(basket.setLock.selector, _block),
            0
        );
    }

    /**
        @notice Rebalance underling token
        @param _swaps Swaps to perform
        @param _deadline Unix timestamp after which the transaction will revert.
    */
    function rebalance(SwapStruct[] calldata _swaps, uint256 _deadline)
        external
        override
        onlyRebalanceManager
    {
        lockBasketData(block.number + 30);

        // remove token from array
        for (uint256 i; i < _swaps.length; i++) {
            SwapStruct memory swap = _swaps[i];

            //swap token
            _swap(
                swap.from,
                swap.to,
                swap.quantity,
                swap.minReturn,
                address(basket),
                _deadline
            );

            //add to token if missing
            addToken(swap.to);

            //remove from token if resulting quantity is 0
            removeToken(swap.from);
        }
        emit Rebalanced(address(basket));
    }
}

pragma solidity >=0.6.2;

interface IPangolinRouter {
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityAVAX(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountAVAX);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityAVAXWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountAVAX);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactAVAXForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactAVAX(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForAVAX(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapAVAXForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external returns (uint amountAVAX);
    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@pie-dao/diamond/contracts/interfaces/IERC173.sol";
import "@pie-dao/diamond/contracts/interfaces/IDiamondLoupe.sol";
import "@pie-dao/diamond/contracts/interfaces/IDiamondCut.sol";
import "./IBasketFacet.sol";
import "./IERC20Facet.sol";
import "./ICallFacet.sol";

/**
    @title ExperiPie Interface
    @dev Combines all ExperiPie facet interfaces into one
*/
interface IExperiPie is
    IERC20,
    IBasketFacet,
    IERC20Facet,
    IERC173,
    ICallFacet,
    IDiamondLoupe,
    IDiamondCut
{

}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

import {
    IPangolinRouter
} from "@pangolindex/exchange-contracts/contracts/pangolin-periphery/interfaces/IPangolinRouter.sol";
import "./IExperiPie.sol";

interface IPangolinRebalanceManager {
    struct SwapStruct {
        address from; //Token to sell
        address to; //Token to buy
        uint256 quantity; //Quantity to sell
        uint256 minReturn; //Minimum quantity to buy //todo change to price for safty
    }

    /**
        @notice Rebalance underling token
        @param _swaps Swaps to perform
        @param _deadline Unix timestamp after which the transaction will revert.
    */
    function rebalance(SwapStruct[] calldata _swaps, uint256 _deadline)
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

interface IBasketFacet {
    event TokenAdded(address indexed _token);
    event TokenRemoved(address indexed _token);
    event EntryFeeSet(uint256 fee);
    event ExitFeeSet(uint256 fee);
    event AnnualizedFeeSet(uint256 fee);
    event FeeBeneficiarySet(address indexed beneficiary);
    event EntryFeeBeneficiaryShareSet(uint256 share);
    event ExitFeeBeneficiaryShareSet(uint256 share);

    event PoolJoined(address indexed who, uint256 amount, uint16 _referral);
    event PoolExited(address indexed who, uint256 amount, uint16 _referral);
    event FeeCharged(uint256 amount);
    event LockSet(uint256 lockBlock);
    event CapSet(uint256 cap);

    /**
        @notice Sets entry fee paid when minting
        @param _fee Amount of fee. 1e18 == 100%, capped at 10%
    */
    function setEntryFee(uint256 _fee) external;

    /**
        @notice Get the entry fee
        @return Current entry fee
    */
    function getEntryFee() external view returns (uint256);

    /**
        @notice Set the exit fee paid when exiting
        @param _fee Amount of fee. 1e18 == 100%, capped at 10%
    */
    function setExitFee(uint256 _fee) external;

    /**
        @notice Get the exit fee
        @return Current exit fee
    */
    function getExitFee() external view returns (uint256);

    /**
        @notice Set the annualized fee. Often referred to as streaming fee
        @param _fee Amount of fee. 1e18 == 100%, capped at 10%
    */
    function setAnnualizedFee(uint256 _fee) external;

    /**
        @notice Get the annualized fee.
        @return Current annualized fee.
    */
    function getAnnualizedFee() external view returns (uint256);

    /**
        @notice Set the address receiving the fees.
    */
    function setFeeBeneficiary(address _beneficiary) external;

    /**
        @notice Get the fee benificiary
        @return The current fee beneficiary
    */
    function getFeeBeneficiary() external view returns (address);

    /**
        @notice Set the fee beneficiaries share of the entry fee
        @notice _share Share of the fee. 1e18 == 100%. Capped at 100%
    */
    function setEntryFeeBeneficiaryShare(uint256 _share) external;

    /**
        @notice Get the entry fee beneficiary share
        @return Feeshare amount
    */
    function getEntryFeeBeneficiaryShare() external view returns (uint256);

    /**
        @notice Set the fee beneficiaries share of the exit fee
        @notice _share Share of the fee. 1e18 == 100%. Capped at 100%
    */
    function setExitFeeBeneficiaryShare(uint256 _share) external;

    /**
        @notice Get the exit fee beneficiary share
        @return Feeshare amount
    */
    function getExitFeeBeneficiaryShare() external view returns (uint256);

    /**
        @notice Calculate the oustanding annualized fee
        @return Amount of pool tokens to be minted to charge the annualized fee
    */
    function calcOutStandingAnnualizedFee() external view returns (uint256);

    /**
        @notice Charges the annualized fee
    */
    function chargeOutstandingAnnualizedFee() external;

    /**
        @notice Pulls underlying from caller and mints the pool token
        @param _amount Amount of pool tokens to mint
        @param _referral Partners may receive rewards with their referral code
    */
    function joinPool(uint256 _amount, uint16 _referral) external;

    /**
        @notice Burns pool tokens from the caller and returns underlying assets
    */
    function exitPool(uint256 _amount, uint16 _referral) external;

    /**
        @notice Get if the pool is locked or not. (not accepting exit and entry)
        @return Boolean indicating if the pool is locked
    */
    function getLock() external view returns (bool);

    /**
        @notice Get the block until which the pool is locked
        @return The lock block
    */
    function getLockBlock() external view returns (uint256);

    /**
        @notice Set the lock block
        @param _lock Block height of the lock
    */
    function setLock(uint256 _lock) external;

    /**
        @notice Get the maximum of pool tokens that can be minted
        @return Cap
    */
    function getCap() external view returns (uint256);

    /**
        @notice Set the maximum of pool tokens that can be minted
        @param _maxCap Max cap
    */
    function setCap(uint256 _maxCap) external;

    /**
        @notice Get the amount of tokens owned by the pool
        @param _token Addres of the token
        @return Amount owned by the contract
    */
    function balance(address _token) external view returns (uint256);

    /**
        @notice Get the tokens in the pool
        @return Array of tokens in the pool
    */
    function getTokens() external view returns (address[] memory);

    /**
        @notice Add a token to the pool. Should have at least a balance of 10**6
        @param _token Address of the token to add
    */
    function addToken(address _token) external;

    /**
        @notice Removes a token from the pool
        @param _token Address of the token to remove
    */
    function removeToken(address _token) external;

    /**
        @notice Checks if a token was added to the pool
        @param _token address of the token
        @return If token is in the pool or not
    */
    function getTokenInPool(address _token) external view returns (bool);

    /**
        @notice Calculate the amounts of underlying needed to mint that pool amount.
        @param _amount Amount of pool tokens to mint
        @return tokens Tokens needed
        @return amounts Amounts of underlying needed
    */
    function calcTokensForAmount(uint256 _amount)
        external
        view
        returns (address[] memory tokens, uint256[] memory amounts);

    /**
        @notice Calculate the amounts of underlying to receive when burning that pool amount
        @param _amount Amount of pool tokens to burn
        @return tokens Tokens returned
        @return amounts Amounts of underlying returned
    */
    function calcTokensForAmountExit(uint256 _amount)
        external
        view
        returns (address[] memory tokens, uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

interface IERC20Facet {
    /**
        @notice Get the token name
        @return The token name
    */
    function name() external view returns (string memory);

    /**
        @notice Get the token symbol
        @return The token symbol 
    */
    function symbol() external view returns (string memory);

    /**
        @notice Get the amount of decimals
        @return Amount of decimals
    */
    function decimals() external view returns (uint8);

    /**
        @notice Mints tokens. Can only be called by the contract owner or the contract itself
        @param _receiver Address receiving the tokens
        @param _amount Amount to mint
    */
    function mint(address _receiver, uint256 _amount) external;

    /**
        @notice Burns tokens. Can only be called by the contract owner or the contract itself
        @param _from Address to burn from
        @param _amount Amount to burn
    */
    function burn(address _from, uint256 _amount) external;

    /**
        @notice Sets up the metadata and initial supply. Can be called by the contract owner
        @param _initialSupply Initial supply of the token
        @param _name Name of the token
        @param _symbol Symbol of the token
    */
    function initialize(
        uint256 _initialSupply,
        string memory _name,
        string memory _symbol
    ) external;

    /**
        @notice Set the token name of the contract. Can only be called by the contract owner or the contract itself
        @param _name New token name
    */
    function setName(string calldata _name) external;

    /**
        @notice Set the token symbol of the contract. Can only be called by the contract owner or the contract itself
        @param _symbol New token symbol
    */
    function setSymbol(string calldata _symbol) external;

    /**
        @notice Increase the amount of tokens another address can spend
        @param _spender Spender
        @param _amount Amount to increase by
    */
    function increaseApproval(address _spender, uint256 _amount)
        external
        returns (bool);

    /**
        @notice Decrease the amount of tokens another address can spend
        @param _spender Spender
        @param _amount Amount to decrease by
    */
    function decreaseApproval(address _spender, uint256 _amount)
        external
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

interface ICallFacet {
    event CallerAdded(address indexed caller);
    event CallerRemoved(address indexed caller);
    event Call(
        address indexed caller,
        address indexed target,
        bytes data,
        uint256 value
    );

    /**
        @notice Lets whitelisted callers execute a batch of arbitrary calls from the pool. Reverts if one of the calls fails
        @param _targets Array of addresses of targets to call
        @param _calldata Array of calldata for each call
        @param _values Array of amounts of ETH to send with the call
    */
    function call(
        address[] memory _targets,
        bytes[] memory _calldata,
        uint256[] memory _values
    ) external;

    /**
        @notice Lets whitelisted callers execute a batch of arbitrary calls from the pool without sending any Ether. Reverts if one of the calls fail
        @param _targets Array of addresses of targets to call
        @param _calldata Array of calldata for each call
    */
    function callNoValue(address[] memory _targets, bytes[] memory _calldata)
        external;

    /**
        @notice Lets whitelisted callers execute a single arbitrary call from the pool. Reverts if the call fails
        @param _target Address of the target to call
        @param _calldata Calldata of the call
        @param _value Amount of ETH to send with the call
    */
    function singleCall(
        address _target,
        bytes calldata _calldata,
        uint256 _value
    ) external;

    /**
        @notice Add a whitelisted caller. Can only be called by the contract owner
        @param _caller Caller to add
    */
    function addCaller(address _caller) external;

    /**
        @notice Remove a whitelisted caller. Can only be called by the contract owner
    */
    function removeCaller(address _caller) external;

    /**
        @notice Checks if an address is a whitelisted caller
        @param _caller Address to check
        @return If the address is whitelisted
    */
    function canCall(address _caller) external view returns (bool);

    /**
        @notice Get all whitelisted callers
        @return Array of whitelisted callers
    */
    function getCallers() external view returns (address[] memory);
}

