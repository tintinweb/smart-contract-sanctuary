// SPDX-License-Identifier: BUSL-1.1
// For further clarification please see https://license.premia.legal

pragma solidity ^0.8.0;

import {OwnableInternal} from "@solidstate/contracts/access/OwnableInternal.sol";
import {IERC20} from "@solidstate/contracts/token/ERC20/IERC20.sol";
import {EnumerableSet} from "@solidstate/contracts/utils/EnumerableSet.sol";
import {IWETH} from "@solidstate/contracts/utils/IWETH.sol";
import {SafeERC20} from "@solidstate/contracts/utils/SafeERC20.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import {PremiaMakerStorage} from "./PremiaMakerStorage.sol";
import {IPremiaMaker} from "./interface/IPremiaMaker.sol";
import {IPoolIO} from "./pool/IPoolIO.sol";
import {IPremiaStaking} from "./staking/IPremiaStaking.sol";

/// @author Premia
/// @title A contract receiving all protocol fees, swapping them for premia
contract PremiaMaker is IPremiaMaker, OwnableInternal {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    // The premia token
    address private immutable PREMIA;
    // The premia staking contract (xPremia)
    address private immutable PREMIA_STAKING;

    // The treasury address which will receive a portion of the protocol fees
    address private immutable TREASURY;
    // The percentage of protocol fees the treasury will get (in basis points)
    uint256 private constant TREASURY_FEE = 2e3; // 20%

    uint256 private constant INVERSE_BASIS_POINT = 1e4;

    //////////////////////////////////////////////////
    //////////////////////////////////////////////////
    //////////////////////////////////////////////////

    // @param premia The premia token
    // @param premiaStaking The premia staking contract (xPremia)
    // @param treasury The treasury address which will receive a portion of the protocol fees
    constructor(
        address premia,
        address premiaStaking,
        address treasury
    ) {
        PREMIA = premia;
        PREMIA_STAKING = premiaStaking;
        TREASURY = treasury;
    }

    //////////////////////////////////////////////////
    //////////////////////////////////////////////////
    //////////////////////////////////////////////////

    receive() external payable {}

    ///////////
    // Admin //
    ///////////

    /// @notice Set a custom swap path for a token
    /// @param token The token
    /// @param path The swap path
    function setCustomPath(address token, address[] memory path)
        external
        onlyOwner
    {
        PremiaMakerStorage.layout().customPath[token] = path;
    }

    /// @notice Add UniswapRouters to the whitelist so that they can be used to swap tokens.
    /// @param accounts The addresses to add to the whitelist
    function addWhitelistedRouters(address[] memory accounts)
        external
        onlyOwner
    {
        PremiaMakerStorage.Layout storage l = PremiaMakerStorage.layout();

        for (uint256 i = 0; i < accounts.length; i++) {
            l.whitelistedRouters.add(accounts[i]);
        }
    }

    /// @notice Remove UniswapRouters from the whitelist so that they cannot be used to swap tokens.
    /// @param accounts The addresses to remove the whitelist
    function removeWhitelistedRouters(address[] memory accounts)
        external
        onlyOwner
    {
        PremiaMakerStorage.Layout storage l = PremiaMakerStorage.layout();

        for (uint256 i = 0; i < accounts.length; i++) {
            l.whitelistedRouters.remove(accounts[i]);
        }
    }

    //////////////////////////

    /// @notice Get a custom swap path for a token
    /// @param token The token
    /// @return The swap path
    function getCustomPath(address token)
        external
        view
        override
        returns (address[] memory)
    {
        return PremiaMakerStorage.layout().customPath[token];
    }

    /// @notice Get the list of whitelisted routers
    /// @return The list of whitelisted routers
    function getWhitelistedRouters()
        external
        view
        override
        returns (address[] memory)
    {
        PremiaMakerStorage.Layout storage l = PremiaMakerStorage.layout();

        uint256 length = l.whitelistedRouters.length();
        address[] memory result = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            result[i] = l.whitelistedRouters.at(i);
        }

        return result;
    }

    /// @notice Withdraw fees from pools, convert tokens into Premia, and send Premia to PremiaStaking contract
    /// @param pool Pool from which to withdraw fees
    /// @param router The UniswapRouter contract to use to perform the swap (Must be whitelisted)
    /// @param tokens The list of tokens to swap to premia
    function withdrawFeesAndConvert(
        address pool,
        address router,
        address[] memory tokens
    ) external override {
        IPoolIO(pool).withdrawFees();

        for (uint256 i = 0; i < tokens.length; i++) {
            convert(router, tokens[i]);
        }
    }

    /// @notice Convert tokens into Premia, and send Premia to PremiaStaking contract
    /// @param router The UniswapRouter contract to use to perform the swap (Must be whitelisted)
    /// @param token The token to swap to premia
    function convert(address router, address token) public override {
        PremiaMakerStorage.Layout storage l = PremiaMakerStorage.layout();

        require(
            l.whitelistedRouters.contains(router),
            "Router not whitelisted"
        );

        uint256 amount = IERC20(token).balanceOf(address(this));
        uint256 fee = (amount * TREASURY_FEE) / INVERSE_BASIS_POINT;
        uint256 amountMinusFee = amount - fee;

        IERC20(token).safeTransfer(TREASURY, fee);

        if (amountMinusFee == 0) return;

        IERC20(token).safeIncreaseAllowance(router, amountMinusFee);

        address weth = IUniswapV2Router02(router).WETH();
        uint256 premiaAmount;

        if (token != PREMIA) {
            address[] memory path;

            if (token != weth) {
                path = l.customPath[token];
                if (path.length == 0) {
                    path = new address[](3);
                    path[0] = token;
                    path[1] = weth;
                    path[2] = PREMIA;
                }
            } else {
                path = new address[](2);
                path[0] = token;
                path[1] = PREMIA;
            }

            uint256[] memory amounts = IUniswapV2Router02(router)
                .swapExactTokensForTokens(
                    amountMinusFee,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );

            premiaAmount = amounts[amounts.length - 1];
        } else {
            premiaAmount = amountMinusFee;

            // Just for the event
            router = address(0);
        }

        if (premiaAmount > 0) {
            IERC20(PREMIA).approve(PREMIA_STAKING, premiaAmount);
            IPremiaStaking(PREMIA_STAKING).addRewards(premiaAmount);

            emit Converted(
                msg.sender,
                router,
                token,
                amountMinusFee,
                premiaAmount
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { OwnableStorage } from './OwnableStorage.sol';

abstract contract OwnableInternal {
    using OwnableStorage for OwnableStorage.Layout;

    modifier onlyOwner() {
        require(
            msg.sender == OwnableStorage.layout().owner,
            'Ownable: sender must be owner'
        );
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20Internal } from './IERC20Internal.sol';

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 is IERC20Internal {
    /**
     * @notice query the total minted token supply
     * @return token supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice query the token balance of given account
     * @param account address to query
     * @return token balance
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice query the allowance granted from given holder to given spender
     * @param holder approver of allowance
     * @param spender recipient of allowance
     * @return token allowance
     */
    function allowance(address holder, address spender)
        external
        view
        returns (uint256);

    /**
     * @notice grant approval to spender to spend tokens
     * @dev prefer ERC20Extended functions to avoid transaction-ordering vulnerability (see https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729)
     * @param spender recipient of allowance
     * @param amount quantity of tokens approved for spending
     * @return success status (always true; otherwise function should revert)
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @notice transfer tokens to given recipient
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @notice transfer tokens to given recipient on behalf of given holder
     * @param holder holder of tokens prior to transfer
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
    struct Set {
        bytes32[] _values;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32Set {
        Set _inner;
    }

    struct AddressSet {
        Set _inner;
    }

    struct UintSet {
        Set _inner;
    }

    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }

    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, value);
    }

    function indexOf(AddressSet storage set, address value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(UintSet storage set, uint256 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(value));
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        require(
            set._values.length > index,
            'EnumerableSet: index out of bounds'
        );
        return set._values[index];
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _indexOf(Set storage set, bytes32 value)
        private
        view
        returns (uint256)
    {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            uint256 index = valueIndex - 1;
            bytes32 last = set._values[set._values.length - 1];

            // move last value to now-vacant index

            set._values[index] = last;
            set._indexes[last] = index + 1;

            // clear last index

            set._values.pop();
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '../token/ERC20/IERC20.sol';
import { IERC20Metadata } from '../token/ERC20/metadata/IERC20Metadata.sol';

/**
 * @title WETH (Wrapped ETH) interface
 */
interface IWETH is IERC20, IERC20Metadata {
    /**
     * @notice convert ETH to WETH
     */
    function deposit() external payable;

    /**
     * @notice convert WETH to ETH
     * @dev if caller is a contract, it should have a fallback or receive function
     * @param amount quantity of WETH to convert, denominated in wei
     */
    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '../token/ERC20/IERC20.sol';
import { AddressUtils } from './AddressUtils.sol';

/**
 * @title Safe ERC20 interaction library
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library SafeERC20 {
    using AddressUtils for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev safeApprove (like approve) should only be called when setting an initial allowance or when resetting it to zero; otherwise prefer safeIncreaseAllowance and safeDecreaseAllowance
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeERC20: approve from non-zero to non-zero allowance'
        );

        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                'SafeERC20: decreased allowance below zero'
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    /**
     * @notice send transaction data and check validity of return value, if present
     * @param token ERC20 token interface
     * @param data transaction data
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            'SafeERC20: low-level call failed'
        );

        if (returndata.length > 0) {
            require(
                abi.decode(returndata, (bool)),
                'SafeERC20: ERC20 operation did not succeed'
            );
        }
    }
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
// For further clarification please see https://license.premia.legal

pragma solidity ^0.8.0;

import {EnumerableSet} from "@solidstate/contracts/utils/EnumerableSet.sol";

library PremiaMakerStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256("premia.contracts.storage.PremiaMaker");

    struct Layout {
        // UniswapRouter contracts which can be used to swap tokens
        EnumerableSet.AddressSet whitelistedRouters;
        // Set a custom swap path for a token
        mapping(address => address[]) customPath;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.0;

interface IPremiaMaker {
    event Converted(
        address indexed account,
        address indexed router,
        address indexed token,
        uint256 tokenAmount,
        uint256 premiaAmount
    );

    function getCustomPath(address _token)
        external
        view
        returns (address[] memory);

    function getWhitelistedRouters() external view returns (address[] memory);

    function convert(address _router, address _token) external;

    function withdrawFeesAndConvert(
        address _pool,
        address _router,
        address[] memory _tokens
    ) external;
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.0;

/**
 * @notice Pool interface for LP position and platform fee management functions
 */
interface IPoolIO {
    /**
     * @notice set timestamp after which reinvestment is disabled
     * @param timestamp timestamp to begin divestment
     * @param isCallPool whether we set divestment timestamp for the call pool or put pool
     */
    function setDivestmentTimestamp(uint64 timestamp, bool isCallPool) external;

    /**
     * @notice deposit underlying currency, underwriting calls of that currency with respect to base currency
     * @param amount quantity of underlying currency to deposit
     * @param isCallPool whether to deposit underlying in the call pool or base in the put pool
     */
    function deposit(uint256 amount, bool isCallPool) external payable;

    /**
     * @notice deposit underlying currency, underwriting calls of that currency with respect to base currency
     * @param amount quantity of underlying currency to deposit
     * @param isCallPool whether to deposit underlying in the call pool or base in the put pool

     * @param amountOut amount out of tokens requested. If 0, we will swap exact amount necessary to pay the quote
     * @param amountInMax amount in max of tokens
     * @param path swap path
     * @param isSushi whether we use sushi or uniV2 for the swap
     */
    function swapAndDeposit(
        uint256 amount,
        bool isCallPool,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        bool isSushi
    ) external payable;

    /**
     * @notice redeem pool share tokens for underlying asset
     * @param amount quantity of share tokens to redeem
     * @param isCallPool whether to deposit underlying in the call pool or base in the put pool
     */
    function withdraw(uint256 amount, bool isCallPool) external;

    /**
     * @notice reassign short position to new underwriter
     * @param tokenId ERC1155 token id (long or short)
     * @param contractSize quantity of option contract tokens to reassign
     * @return baseCost quantity of tokens required to reassign short position
     * @return feeCost quantity of tokens required to pay fees
     * @return amountOut quantity of liquidity freed and transferred to owner
     */
    function reassign(uint256 tokenId, uint256 contractSize)
        external
        returns (
            uint256 baseCost,
            uint256 feeCost,
            uint256 amountOut
        );

    /**
     * @notice reassign set of short position to new underwriter
     * @param tokenIds array of ERC1155 token ids (long or short)
     * @param contractSizes array of quantities of option contract tokens to reassign
     * @return baseCosts quantities of tokens required to reassign each short position
     * @return feeCosts quantities of tokens required to pay fees
     * @return amountOutCall quantity of call pool liquidity freed and transferred to owner
     * @return amountOutPut quantity of put pool liquidity freed and transferred to owner
     */
    function reassignBatch(
        uint256[] calldata tokenIds,
        uint256[] calldata contractSizes
    )
        external
        returns (
            uint256[] memory baseCosts,
            uint256[] memory feeCosts,
            uint256 amountOutCall,
            uint256 amountOutPut
        );

    /**
     * @notice withdraw all free liquidity and reassign set of short position to new underwriter
     * @param isCallPool true for call, false for put
     * @param tokenIds array of ERC1155 token ids (long or short)
     * @param contractSizes array of quantities of option contract tokens to reassign
     * @return baseCosts quantities of tokens required to reassign each short position
     * @return feeCosts quantities of tokens required to pay fees
     * @return amountOutCall quantity of call pool liquidity freed and transferred to owner
     * @return amountOutPut quantity of put pool liquidity freed and transferred to owner
     */
    function withdrawAllAndReassignBatch(
        bool isCallPool,
        uint256[] calldata tokenIds,
        uint256[] calldata contractSizes
    )
        external
        returns (
            uint256[] memory baseCosts,
            uint256[] memory feeCosts,
            uint256 amountOutCall,
            uint256 amountOutPut
        );

    /**
     * @notice transfer accumulated fees to the fee receiver
     * @return amountOutCall quantity of underlying tokens transferred
     * @return amountOutPut quantity of base tokens transferred
     */
    function withdrawFees()
        external
        returns (uint256 amountOutCall, uint256 amountOutPut);

    /**
     * @notice burn corresponding long and short option tokens and withdraw collateral
     * @param tokenId ERC1155 token id (long or short)
     * @param contractSize quantity of option contract tokens to annihilate
     */
    function annihilate(uint256 tokenId, uint256 contractSize) external;

    /**
     * @notice claim earned PREMIA emissions
     * @param isCallPool true for call, false for put
     */
    function claimRewards(bool isCallPool) external;

    /**
     * @notice claim earned PREMIA emissions on behalf of given account
     * @param account account on whose behalf to claim rewards
     * @param isCallPool true for call, false for put
     */
    function claimRewards(address account, bool isCallPool) external;

    /**
     * @notice TODO
     */
    function updateMiningPools() external;
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.0;

import {PremiaStakingStorage} from "./PremiaStakingStorage.sol";

interface IPremiaStaking {
    event Deposit(address indexed user, uint256 amount);
    event StartWithdrawal(
        address indexed user,
        uint256 premiaAmount,
        uint256 startDate
    );
    event Withdrawal(address indexed user, uint256 amount);

    /**
     * @notice add premia tokens as available tokens to be distributed as rewards
     * @param amount amount of premia tokens to add as rewards
     */
    function addRewards(uint256 amount) external;

    /**
     * @notice get amount of tokens that have not yet been distributed as rewards
     * @return amount of tokens not yet distributed as rewards
     */
    function getAvailableRewards() external view returns (uint256);

    /**
     * @notice get pending amount of tokens to be distributed as rewards to stakers
     * @return amount of tokens pending to be distributed as rewards
     */
    function getPendingRewards() external view returns (uint256);

    /**
     * @notice stake PREMIA using IERC2612 permit
     * @param amount quantity of PREMIA to stake
     * @param deadline timestamp after which permit will fail
     * @param v signature "v" value
     * @param r signature "r" value
     * @param s signature "s" value
     */
    function depositWithPermit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice stake PREMIA in exchange for xPremia
     * @param amount quantity of PREMIA to stake
     */
    function deposit(uint256 amount) external;

    /**
     * @notice Initiate the withdrawal process by burning xPremia, starting the delay period
     * @param amount quantity of xPremia to unstake
     */
    function startWithdraw(uint256 amount) external;

    /**
     * @notice withdraw PREMIA after withdrawal delay has passed
     */
    function withdraw() external;

    /**
     * @notice get current withdrawal delay
     * @return withdrawal delay
     */
    function getWithdrawalDelay() external view returns (uint256);

    /**
     * @notice set current withdrawal delay
     * @param delay withdrawal delay
     */
    function setWithdrawalDelay(uint256 delay) external;

    /**
     * @notice get the xPREMIA : PREMIA ratio (with 18 decimals)
     * @return xPREMIA : PREMIA ratio (with 18 decimals)
     */
    function getXPremiaToPremiaRatio() external view returns (uint256);

    /**
     * @notice get pending withdrawal data of a user
     * @return amount pending withdrawal amount
     * @return startDate start timestamp of withdrawal
     * @return unlockDate timestamp at which withdrawal becomes available
     */
    function getPendingWithdrawal(address user)
        external
        view
        returns (
            uint256 amount,
            uint256 startDate,
            uint256 unlockDate
        );

    /**
     * @notice get the amount of PREMIA staked (subtracting all pending withdrawals)
     * @return amount of PREMIA staked
     */
    function getStakedPremiaAmount() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Ownable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setOwner(Layout storage l, address owner) internal {
        l.owner = owner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial ERC20 interface needed by internal functions
 */
interface IERC20Internal {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC20 metadata interface
 */
interface IERC20Metadata {
    /**
     * @notice return token name
     * @return token name
     */
    function name() external view returns (string memory);

    /**
     * @notice return token symbol
     * @return token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @notice return token decimals, generally used only for display purposes
     * @return token decimals
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library AddressUtils {
    function toString(address account) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(account)));
        bytes memory alphabet = '0123456789abcdef';
        bytes memory chars = new bytes(42);

        chars[0] = '0';
        chars[1] = 'x';

        for (uint256 i = 0; i < 20; i++) {
            chars[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            chars[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }

        return string(chars);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        require(success, 'AddressUtils: failed to send value');
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            'AddressUtils: insufficient balance for call'
        );
        return _functionCallWithValue(target, data, value, error);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        require(
            isContract(target),
            'AddressUtils: function call to non-contract'
        );

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
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
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
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
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: BUSL-1.1
// For further clarification please see https://license.premia.legal

pragma solidity ^0.8.0;

library PremiaStakingStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256("premia.contracts.staking.PremiaStaking");

    struct Withdrawal {
        uint256 amount; // Premia amount
        uint256 startDate; // Will unlock at startDate + withdrawalDelay
    }

    struct Layout {
        uint256 pendingWithdrawal;
        uint256 withdrawalDelay;
        mapping(address => Withdrawal) withdrawals;
        uint256 availableRewards;
        uint256 lastRewardUpdate; // Timestamp of last reward distribution update
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}