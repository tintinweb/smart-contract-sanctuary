// SPDX-License-Identifier: MIT

/**
 * @title Lock Forwarder of EnergyFi launchpad enviroment
 * @dev This contract checks if a pancake pair for the launchpad tokens exists
 * and locks liquidity by creating a LP on pancakeswap and forwards the LP token
 * to the pancakeLocker contract. The LP tokens will be locked in pancakeLocker.
 */

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/pancake/IPancakeFactory.sol";
import "../interfaces/pancake/IPancakePair.sol";
import "../interfaces/ILaunchpadFactory.sol";
import "../interfaces/IPancakeLocker.sol";
import "../interfaces/ILaunchpadLockForwarder.sol";

import "./TransferHelper.sol";

contract LaunchpadLockForwarder is ILaunchpadLockForwarder {
    ILaunchpadFactory public immutable LAUNCHPAD_FACTORY;
    IPancakeLocker public immutable PANCAKE_LOCKER;
    IPancakeFactory public immutable PANCAKE_FACTORY;

    /**
     * @dev sets initially contract dependend addresses
     * @param _launchpadFactory address of the launchpad factory
     * @param _pancakeFactory address of the pancake factory
     * @param _pancakeLocker address of the pancake locker contract
     */
    constructor(
        address _launchpadFactory,
        address _pancakeFactory,
        address _pancakeLocker
    ) public {
        require(
            _launchpadFactory != address(0) &&
                _pancakeFactory != address(0) &&
                _pancakeLocker != address(0),
            "ZERO ADDRESS"
        );
        LAUNCHPAD_FACTORY = ILaunchpadFactory(_launchpadFactory);
        PANCAKE_FACTORY = IPancakeFactory(_pancakeFactory);
        PANCAKE_LOCKER = IPancakeLocker(_pancakeLocker);
    }

    /**
     * @notice checks if a pancake pair with liquidity exists on pancakeswap for the given tokens
     * @param _token0 one address of the pancake pair base tokens
     * @param _token1 the other address of the pancake pair base tokens
     */
    function pancakeswapPairIsInitialised(address _token0, address _token1)
        external
        view
        override
        returns (bool)
    {
        // check for pancake pair
        address pairAddress = PANCAKE_FACTORY.getPair(_token0, _token1);
        if (pairAddress == address(0)) {
            return false;
        }

        // check for liquidity inside pair
        uint256 balance = IERC20(_token0).balanceOf(pairAddress);
        if (balance > 0) {
            return true;
        }
        return false;
    }

    /**
     * @notice locks iquidity by creating a liquidity pair (LP) with base and sale token,
     * sending liquidity amount of both tokens to the LP and locks the minted LP token
     * with PancakeLocker contract.
     * @param _baseToken token received for sold launchpad token
     * @param _saleToken token sold in launchpad
     * @param _baseAmount amount of base tokens to be locked
     * @param _saleAmount amount of sale tokens to be locked
     * @param _unlockDate timestamp to unlock the locked lp token
     * @param _withdrawer address allowed to withdraw token after unlock date
     */
    function lockLiquidity(
        IERC20Meta _baseToken,
        IERC20 _saleToken,
        uint256 _baseAmount,
        uint256 _saleAmount,
        uint256 _unlockDate,
        address payable _withdrawer
    ) external override {
        require(
            LAUNCHPAD_FACTORY.launchpadIsRegistered(msg.sender),
            "LAUNCHPAD NOT REGISTERED"
        );
        // get pancake pair if exists
        address pair = PANCAKE_FACTORY.getPair(
            address(_baseToken),
            address(_saleToken)
        );

        // create pancake pair if not exists
        if (pair == address(0)) {
            PANCAKE_FACTORY.createPair(
                address(_baseToken),
                address(_saleToken)
            );
            pair = PANCAKE_FACTORY.getPair(
                address(_baseToken),
                address(_saleToken)
            );
        }

        // transfer base token amount to pancake pair
        TransferHelper.safeTransferFrom(
            address(_baseToken),
            msg.sender,
            address(pair),
            _baseAmount
        );

        // transfer sale token amount to pancake pair
        TransferHelper.safeTransferFrom(
            address(_saleToken),
            msg.sender,
            address(pair),
            _saleAmount
        );

        // mint LP tokens
        IPancakePair(pair).mint(address(this));
        uint256 totalLPTokensMinted = IPancakePair(pair).balanceOf(
            address(this)
        );
        require(totalLPTokensMinted != 0, "LP creation failed");

        // approve locker contract with LP tokens
        TransferHelper.safeApprove(
            pair,
            address(PANCAKE_LOCKER),
            totalLPTokensMinted
        );

        // ensure max lock date
        uint256 unlock_date = _unlockDate > 9999999999
            ? 9999999999
            : _unlockDate;

        // lock the LP token with pancake locker contract
        PANCAKE_LOCKER.lockLPToken(
            pair,
            totalLPTokensMinted,
            unlock_date,
            address(0),
            true,
            _withdrawer
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 *@title Interface of Pancake pair
 *@notice This is an interface of the PancakeSwap pair
 *@dev A parital interface of the pancake pair to get token and factory addresses. The original code can be found on
 *https://github.com/pancakeswap/pancake-swap-core/blob/master/contracts/interfaces/IPancakePair.sol
 */
interface IPancakePair {
    /**
     *@notice Returns the address of the pairs pancake factory
     *@return address of the related pancake factory
     */
    function factory() external view returns (address);

    /**
     *@notice Returns the address of the first token of the pair
     *@dev The order of the tokens may switch on pair creation. TokenA on creation has not to be token0
     *inside the pair contract.
     *@return address of the first token of the pair (token0)
     */
    function token0() external view returns (address);

    /**
     *@notice Returns the address of the second token of the pair
     *@dev The order of the tokens may switch on pair creation. TokenB on creation has not to be token1
     *inside the pair contract.
     *@return address of the second token of the pair (token1)
     */
    function token1() external view returns (address);

    /**
     *@notice Mints an amount of token to the given address
     *@dev This low-level function should be called from a contract which performs important safety checks
     *@param to address to mint the tokens to
     *@return the minted liquidity amount of tokens
     */
    function mint(address to) external returns (uint256);

    /**
     *@dev Returns the amount of tokens owned by `owner`.
     *@param owner the address off the account owning tokens
     */
    function balanceOf(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 *@title Interface of Pancake factory
 *@notice This is an interface of the PancakeSwap factory
 *@dev A parital interface of the pancake factory. The original code can be found on
 *https://github.com/pancakeswap/pancake-swap-core/blob/master/contracts/interfaces/IPancakeFactory.sol
 */
interface IPancakeFactory {
    /**
     *@notice Creates a new pair of two tokens known as liquidity pool
     *@param tokenA The first token of the pair
     *@param tokenB The second token of the pair
     *@return pair address of the created pair
     */
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    /**
     *@notice Returns the pair address of two given tokens
     *@param tokenA The first token of the pair
     *@param tokenB The second token of the pair
     *@return pair address of the created pair
     */
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

// SPDX-License-Identifier: MIT

/**
 * @title Locker Interface of EnergyFi launchpad enviroment
 * @dev This Interface holds a function to lock LP token with the PancakeLocker contract.
 * This function is called from LaunchpadLockForwarder to lock LP tokens.
 */
pragma solidity 0.6.12;

interface IPancakeLocker {
    /**
     * @notice locks specific amount of LP tokens for a given period of time
     * @dev fees are calculated if caller is not whitelisted
     * @param _lpToken address of the LP token to be locked
     * @param _amount total amount of LP tokens to be locked
     * @param _unlockDate unix timestamp when withdrawer is allowed to unlock LP tokens
     * @param _referral address of referrer for token locking
     * @param _feeInBnb bool indicating if base token is BNB
     * @param _withdrawer address which is allowed to unlock lock LP tokens after unlock date
     */
    function lockLPToken(
        address _lpToken,
        uint256 _amount,
        uint256 _unlockDate,
        address payable _referral,
        bool _feeInBnb,
        address payable _withdrawer
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @title LockForwarder Interface of the EnergyFi launchpad enviroment
 * @dev This interface describes the LaunchpadLockForwarder. It holds functions for interacting
 * with the pancakeswap factory for getting LP information and creating a LP on locking liquidity.
 * The locked liquidity amount is forwarded to PancakeLocker contract.
 */

import "./IERC20Meta.sol";

interface ILaunchpadLockForwarder {
    /**
     * @notice locks iquidity by creating a liquidity pair (LP) with base and sale token,
     * sending liquidity amount of both tokens to the LP and locks the minted LP token
     * with PancakeLocker contract.
     * @param _baseToken token received for sold launchpad token
     * @param _saleToken token sold in launchpad
     * @param _baseAmount amount of base tokens to be locked
     * @param _saleAmount amount of sale tokens to be locked
     * @param _unlockDate timestamp to unlock the locked lp token
     * @param _withdrawer address allowed to withdraw token after unlock date
     */
    function lockLiquidity(
        IERC20Meta _baseToken,
        IERC20 _saleToken,
        uint256 _baseAmount,
        uint256 _saleAmount,
        uint256 _unlockDate,
        address payable _withdrawer
    ) external;

    /**
     * @notice checks if a pancake pair with liquidity exists on pancakeswap for the given tokens
     * @param _token0 one address of the pancake pair base tokens
     * @param _token1 the other address of the pancake pair base tokens
     */
    function pancakeswapPairIsInitialised(address _token0, address _token1)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT

/**
 * @title Factory interface of EnergyFi launchpad enviroment
 * @dev This interface holds functions for registering launchpads and get information about
 * registered launchpads and launchpad generators.
 */

pragma solidity 0.6.12;

interface ILaunchpadFactory {
    /**
     * @notice adds a launchpad to factory by generator
     * @param _launchpadAddress address of the launchpad to be added
     */
    function registerLaunchpad(address _launchpadAddress) external;

    /**
     * @notice returns the address of a launchpad at a given index
     * @param _index index of the launchpads address set
     */
    function launchpadAtIndex(uint256 _index) external view returns (address);

    /**
     * @notice returns the address of a launchpad generator at a given index
     * @param _index index of the launchpad generator address set
     */
    function launchpadGeneratorAtIndex(uint256 _index)
        external
        view
        returns (address);

    /**
     * @notice returns the total number of registered launchpad generators
     */
    function launchpadGeneratorsLength() external view returns (uint256);

    /**
     * @notice returns if a given address is registered as a launchpad
     * @param _launchpadAddress address of the lauchpad to be checked
     */
    function launchpadIsRegistered(address _launchpadAddress)
        external
        view
        returns (bool);

    /**
     * @notice returns the total number of registered launchpads
     */
    function launchpadsLength() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 *@title Interface of a burnable ERC20 token
 *@dev This interface describes a burnable ERC20 token providing a burn function.
 */
interface IERC20Meta is IERC20 {
    /**
     * @dev Returns the number of decimals of an ERC20 token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

/**
 * @title TransferHelper of EnergyFi launchpad enviroment
 * @dev This library holds function to transfer tokens safely. It allows safe transfer
 * for BNB as well as ERC20 tokens from a sender to a receiver. The ERC20 token functions
 * are used with low level call function.
 */

pragma solidity 0.6.12;

library TransferHelper {
    /**
     * @notice calls the aprove function of a given token in a safe way
     * @dev uses low level call and reverts on fail
     * @param token address of the base token to be transferred
     * @param to address of token spender (allowed to call transferFrom)
     * @param value amount of tokens to transfer
     */
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    /**
     * @notice calls the transfer function of a given token in a safe way
     * @dev uses low level call and reverts on fail
     * @param token address of the base token to be transferred
     * @param to address of token receiver
     * @param value amount of tokens to transfer
     */
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    /**
     * @notice calls the transferFrom function of a given token in a safe way
     * @dev transfers needs to be approved first. uses low level call and reverts on fail
     * @param token address of the base token to be transferred
     * @param from address of token sender
     * @param to address of token receiver
     * @param value amount of tokens to transfer
     */
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    /**
     * @notice calls the transfer function of a given token in a safe way or transfers BNB
     * if base token is not a ERC20 token
     * @dev uses low level call and reverts on fail
     * @param token address of the base token to be transferred
     * @param to address of the token receiver
     * @param value amount of tokens to transfer
     * @param isERC20 bool to indicate if the base token in BNB (=false) or ERC20 token (=true)
     */
    function safeTransferBaseToken(
        address token,
        address payable to,
        uint256 value,
        bool isERC20
    ) internal {
        if (!isERC20) {
            to.transfer(value);
        } else {
            (bool success, bytes memory data) = token.call(
                abi.encodeWithSelector(0xa9059cbb, to, value)
            );
            require(
                success && (data.length == 0 || abi.decode(data, (bool))),
                "TransferHelper: TRANSFER_FAILED"
            );
        }
    }
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