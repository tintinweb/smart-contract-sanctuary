// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25 <0.7.0;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@openzeppelin/contracts-upgradeable/proxy/Initializable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './interfaces/IStaking.sol';
import './abstracts/Migrateable.sol';
import './abstracts/Manageable.sol';

/** Launch
    Roles Needed -
    Staking Contract: External Staker Role (redo in v3)
    Token Contract: Burner (AKA Minter)
 */

contract Accelerator is Initializable, Migrateable, Manageable {
    event AcceleratorToken(
        address indexed from,
        address indexed tokenIn,
        uint256 indexed currentDay,
        address token,
        uint8[3] splitAmounts,
        uint256 axionBought,
        uint256 tokenBought,
        uint256 stakeDays,
        uint256 payout
    );
    event AcceleratorEth(
        address indexed from,
        address indexed token,
        uint256 indexed currentDay,
        uint8[3] splitAmounts,
        uint256 axionBought,
        uint256 tokenBought,
        uint256 stakeDays,
        uint256 payout
    );
    /** Additional Roles */
    bytes32 public constant GIVE_AWAY_ROLE = keccak256('GIVE_AWAY_ROLE');

    /** Public */
    address public staking; // Staking Address
    address public axion; // Axion Address
    address public vcauction; // Used in v3
    address public token; // Token to buy other then aixon
    address payable public uniswap; // Uniswap Adress
    address payable public recipient; // Recipient Address
    uint256 public minStakeDays; // Minimum length of stake from contract
    uint256 public start; // Start of Contract in seconds
    uint256 public secondsInDay; // 86400
    uint256 public maxBoughtPerDay; // Amount bought before bonus is removed
    mapping(uint256 => uint256) public bought; // Total bought for the day
    uint16 bonusStartDays; // # of days to stake before bonus starts
    uint8 bonusStartPercent; // Start percent of bonus 5 - 20, 10 - 25 etc.
    uint8 baseBonus; // Base bonus unrequired by baseStartDays
    uint8[3] public splitAmounts; // 0 axion, 1 btc, 2 recipient
    mapping(address => bool) public allowedTokens; // Tokens allowed to be used for stakeWithToken
    /** Private */
    bool private _paused; // Contract paused

    // -------------------- Modifiers ------------------------

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), 'AUTOSTAKER: paused');
        _;
    }

    // -------------------- Functions ------------------------

    /** @dev stake with token
        Description: Sell a token buy axion and then stake it for # of days
        @param _amountOut {uint256}
        @param _amountTokenOut {uint256}
        @param _deadline {uint256}
        @param _days {uint256}
     */
    function axionBuyAndStakeEth(
        uint256 _amountOut,
        uint256 _amountTokenOut,
        uint256 _deadline,
        uint256 _days
    )
        external
        payable
        whenNotPaused
        returns (uint256 axionBought, uint256 tokenBought)
    {
        require(_days >= minStakeDays, 'AUTOSTAKER: Minimum stake days');
        uint256 currentDay = getCurrentDay();
        //** Get Amounts */
        (uint256 _axionAmount, uint256 _tokenAmount, uint256 _recipientAmount) =
            dividedAmounts(msg.value);

        //** Swap tokens */
        axionBought = swapEthForTokens(
            axion,
            staking,
            _axionAmount,
            _amountOut,
            _deadline
        );
        tokenBought = swapEthForTokens(
            token,
            staking,
            _tokenAmount,
            _amountTokenOut,
            _deadline
        );

        // Call sendAndBurn
        uint256 payout =
            sendAndBurn(axionBought, tokenBought, _days, currentDay);

        //** Transfer any eithereum in contract to recipient address */
        recipient.transfer(_recipientAmount);

        //** Emit Event  */
        emit AcceleratorEth(
            msg.sender,
            token,
            currentDay,
            splitAmounts,
            axionBought,
            tokenBought,
            _days,
            payout
        );

        /** Return amounts for the frontend */
        return (axionBought, tokenBought);
    }

    /** @dev Swap tokens for tokens
        Description: Use uniswap to swap the token in for axion.
        @param _tokenOutAddress {address}
        @param _to {address}
        @param _amountIn {uint256}
        @param _amountOutMin {uint256}
        @param _deadline {uint256}

        @return {uint256}
     */
    function swapEthForTokens(
        address _tokenOutAddress,
        address _to,
        uint256 _amountIn,
        uint256 _amountOutMin,
        uint256 _deadline
    ) internal returns (uint256) {
        /** Path through WETH */
        address[] memory path = new address[](2);
        path[0] = IUniswapV2Router02(uniswap).WETH();
        path[1] = _tokenOutAddress;

        /** Swap for tokens */
        return
            IUniswapV2Router02(uniswap).swapExactETHForTokens{value: _amountIn}(
                _amountOutMin,
                path,
                _to,
                _deadline
            )[1];
    }

    /** @dev stake with ethereum
        Description: Sell a token buy axion and then stake it for # of days
        @param _token {address}
        @param _amount {uint256}
        @param _amountOut {uint256}
        @param _deadline {uint256}
        @param _days {uint256}
     */
    function axionBuyAndStake(
        address _token,
        uint256 _amount,
        uint256 _amountOut,
        uint256 _amountTokenOut,
        uint256 _deadline,
        uint256 _days
    )
        external
        whenNotPaused
        returns (uint256 axionBought, uint256 tokenBought)
    {
        require(_days >= minStakeDays, 'AUTOSTAKER: Minimum stake days');
        require(
            allowedTokens[_token] == true,
            'AUTOSTAKER: This token is not allowed to be used on this contract'
        );
        uint256 currentDay = getCurrentDay();

        //** Get Amounts */
        (uint256 _axionAmount, uint256 _tokenAmount, uint256 _recipientAmount) =
            dividedAmounts(_amount);

        /** Transfer tokens to contract */
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        //** Swap tokens */
        axionBought = swapTokensForTokens(
            _token,
            axion,
            staking,
            _axionAmount,
            _amountOut,
            _deadline
        );

        if (_token != token) {
            tokenBought = swapTokensForTokens(
                _token,
                token,
                staking,
                _tokenAmount,
                _amountTokenOut,
                _deadline
            );
        } else {
            tokenBought = _tokenAmount;
            IERC20(token).transfer(staking, tokenBought);
        }

        // Call sendAndBurn
        uint256 payout =
            sendAndBurn(axionBought, tokenBought, _days, currentDay);

        //** Transfer tokens to Manager */
        IERC20(_token).transfer(recipient, _recipientAmount);

        //* Emit Event */
        emit AcceleratorToken(
            msg.sender,
            _token,
            currentDay,
            token,
            splitAmounts,
            axionBought,
            tokenBought,
            _days,
            payout
        );

        /** Return amounts for the frontend */
        return (axionBought, tokenBought);
    }

    /** @dev Swap tokens for tokens
        Description: Use uniswap to swap the token in for axion.
        @param _tokenInAddress {address}
        @param _tokenOutAddress {address}
        @param _to {address}
        @param _amountIn {uint256}
        @param _amountOutMin {uint256}
        @param _deadline {uint256}

        @return amounts {uint256[]} [TokenIn, ETH, AXN]
     */
    function swapTokensForTokens(
        address _tokenInAddress,
        address _tokenOutAddress,
        address _to,
        uint256 _amountIn,
        uint256 _amountOutMin,
        uint256 _deadline
    ) internal returns (uint256) {
        /** Path through WETH */
        address[] memory path = new address[](3);
        path[0] = _tokenInAddress;
        path[1] = IUniswapV2Router02(uniswap).WETH();
        path[2] = _tokenOutAddress;

        /** Check allowance */
        if (
            IERC20(_tokenInAddress).allowance(address(this), uniswap) < 2**255
        ) {
            IERC20(_tokenInAddress).approve(uniswap, 2**255);
        }

        /** Swap for tokens */
        return
            IUniswapV2Router02(uniswap).swapExactTokensForTokens(
                _amountIn,
                _amountOutMin,
                path,
                _to,
                _deadline
            )[2];
    }

    /** @dev sendAndBurn
        Description: Burns axion, transfers btc to staking, and creates the stake
        @param _axionBought {uint256}
        @param _tokenBought {uint256}
        @param _days {uint256}
        @param _currentDay {uint256}

        @return payout uint256 
     */
    function sendAndBurn(
        uint256 _axionBought,
        uint256 _tokenBought,
        uint256 _days,
        uint256 _currentDay
    ) internal returns (uint256) {
        // uint256 tokensAfterSplit =
        //     _tokenBought - (_tokenBought / splitAmounts[1]);
        //** Transfer BTC, Axion is transferred to staking immediately for burn */
        // IERC20(token).transfer(staking, _tokenBought);
        IStaking(staking).updateTokenPricePerShare(
            msg.sender,
            recipient,
            token,
            _tokenBought
        );

        /** Add additional axion if stake length is greater then 1year */
        uint256 payout = (100 * _axionBought) / splitAmounts[0];
        payout = payout + (payout * baseBonus) / 100;
        if (_days >= bonusStartDays && bought[_currentDay] < maxBoughtPerDay) {
            // Get amount for sale left
            uint256 payoutWithBonus = maxBoughtPerDay - bought[_currentDay];
            // Add to payout
            bought[_currentDay] += payout;
            if (payout > payoutWithBonus) {
                uint256 payoutWithoutBonus = payout - payoutWithBonus;

                payout =
                    (payoutWithBonus +
                        (payoutWithBonus *
                            ((_days / bonusStartDays) + bonusStartPercent)) /
                        100) +
                    payoutWithoutBonus;
            } else {
                payout =
                    payout +
                    (payout * ((_days / bonusStartDays) + bonusStartPercent)) /
                    100; // multiply by percent divide by 100
            }
        } else {
            //** If not returned above add to bought and return payout. */
            bought[_currentDay] += payout;
        }

        //** Stake the burned tokens */
        IStaking(staking).externalStake(payout, _days, msg.sender);
        //** Return amounts for the frontend */
        return payout;
    }

    /** Utility Functions */
    /** @dev currentDay
        Description: Get the current day since start of contract
     */
    function getCurrentDay() public view returns (uint256) {
        return (now - start) / secondsInDay;
    }

    /** @dev splitAmounts */
    function getSplitAmounts() public view returns (uint8[3] memory) {
        uint8[3] memory _splitAmounts;
        for (uint256 i = 0; i < splitAmounts.length; i++) {
            _splitAmounts[i] = splitAmounts[i];
        }
        return _splitAmounts;
    }

    /** @dev dividedAmounts
        Description: Uses Split amounts to return amountIN should be each
        @param _amountIn {uint256}
     */
    function dividedAmounts(uint256 _amountIn)
        internal
        view
        returns (
            uint256 _axionAmount,
            uint256 _tokenAmount,
            uint256 _recipientAmount
        )
    {
        _axionAmount = (_amountIn * splitAmounts[0]) / 100;
        _tokenAmount = (_amountIn * splitAmounts[1]) / 100;
        _recipientAmount = (_amountIn * splitAmounts[2]) / 100;
    }

    // -------------------- Setter Functions ------------------------
    /** @dev setAllowedToken
        Description: Allow tokens can be swapped for axion.
        @param _token {address}
        @param _allowed {bool}
     */
    function setAllowedToken(address _token, bool _allowed)
        external
        onlyManager
    {
        allowedTokens[_token] = _allowed;
    }

    /** @dev setAllowedTokens
        Description: Allow tokens can be swapped for axion.
        @param _tokens {address}
        @param _allowed {bool}
     */
    function setAllowedTokens(
        address[] calldata _tokens,
        bool[] calldata _allowed
    ) external onlyManager {
        for (uint256 i = 0; i < _tokens.length; i++) {
            allowedTokens[_tokens[i]] = _allowed[i];
        }
    }

    /** @dev setPaused
        @param _p {bool}
     */
    function setPaused(bool _p) external onlyManager {
        _paused = _p;
    }

    /** @dev setFee
        @param _days {uint256}
     */
    function setMinStakeDays(uint256 _days) external onlyManager {
        minStakeDays = _days;
    }

    /** @dev splitAmounts
        @param _splitAmounts {uint256[]}
     */
    function setSplitAmounts(uint8[3] calldata _splitAmounts)
        external
        onlyManager
    {
        uint8 total = _splitAmounts[0] + _splitAmounts[1] + _splitAmounts[2];
        require(total == 100, 'ACCELERATOR: Split Amounts must == 100');

        splitAmounts = _splitAmounts;
    }

    /** @dev maxBoughtPerDay
        @param _amount uint256 
    */
    function setMaxBoughtPerDay(uint256 _amount) external onlyManager {
        maxBoughtPerDay = _amount;
    }

    /** @dev setBaseBonus
        @param _amount uint256 
    */
    function setBaseBonus(uint8 _amount) external onlyManager {
        baseBonus = _amount;
    }

    /** @dev setBonusStart%
        @param _amount uint8 
    */
    function setBonusStartPercent(uint8 _amount) external onlyManager {
        bonusStartPercent = _amount;
    }

    /** @dev setBonusStartDays
        @param _amount uint8 
    */
    function setBonusStartDays(uint16 _amount) external onlyManager {
        bonusStartDays = _amount;
    }

    /** @dev setRecipient
        @param _recipient uint8 
    */
    function setRecipient(address payable _recipient) external onlyManager {
        recipient = _recipient;
    }

    /** @dev setStart
        @param _start uint8 
    */
    function setStart(uint256 _start) external onlyManager {
        start = _start;
    }

    /** @dev setToken
        @param _token {address} 
    */
    function setToken(address _token) external onlyManager {
        token = _token;
        IStaking(staking).addDivToken(_token);
    }

    /** @dev setVC
        @param _vcauction {address} 
    */
    function setVCAuction(address _vcauction) external onlyManager {
        vcauction = _vcauction;
    }

    /** @dev setVC
        @param _staking {address} 
    */
    function setStaking(address _staking) external onlyManager {
        staking = _staking;
    }

    // -------------------- Getter Functions ------------------------
    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /** @dev initialize
        Description: Initialize contract
        @param _migrator {address}
        @param _manager {address}
     */
    function initialize(address _migrator, address _manager)
        external
        initializer
    {
        /** Setup roles and addresses */
        _setupRole(MIGRATOR_ROLE, _migrator);
        _setupRole(MANAGER_ROLE, _manager);
    }

    function startAddresses(
        address _staking,
        address _axion,
        address _token,
        address payable _uniswap,
        address payable _recipient
    ) external onlyMigrator {
        staking = _staking;
        axion = _axion;
        token = _token;
        uniswap = _uniswap;
        recipient = _recipient;
    }

    function startVariables(
        uint256 _minStakeDays,
        uint256 _start,
        uint256 _secondsInDay,
        uint256 _maxBoughtPerDay,
        uint8 _bonusStartPercent,
        uint16 _bonusStartDays,
        uint8 _baseBonus,
        uint8[3] calldata _splitAmounts
    ) external onlyMigrator {
        uint8 total = _splitAmounts[0] + _splitAmounts[1] + _splitAmounts[2];
        require(total == 100, 'ACCELERATOR: Split Amounts must == 100');

        minStakeDays = _minStakeDays;
        start = _start;
        secondsInDay = _secondsInDay;
        maxBoughtPerDay = _maxBoughtPerDay;
        bonusStartPercent = _bonusStartPercent;
        bonusStartDays = _bonusStartDays;
        baseBonus = _baseBonus;
        splitAmounts = _splitAmounts;
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

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IStaking {
    function externalStake(
        uint256 amount,
        uint256 stakingDays,
        address staker
    ) external;

    function updateTokenPricePerShare(
        address payable bidderAddress,
        address payable originAddress,
        address tokenAddress,
        uint256 amountBought
    ) external payable;

    function addDivToken(address tokenAddress) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.25 <0.7.0;

import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';

abstract contract Migrateable is AccessControlUpgradeable {
    bytes32 public constant MIGRATOR_ROLE = keccak256('MIGRATOR_ROLE');

    modifier onlyMigrator() {
        require(hasRole(MIGRATOR_ROLE, msg.sender), 'Caller is not a migrator');
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.25 <0.7.0;

import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';

abstract contract Manageable is AccessControlUpgradeable {
    bytes32 public constant MANAGER_ROLE = keccak256('MANAGER_ROLE');

    modifier onlyManager() {
        require(hasRole(MANAGER_ROLE, msg.sender), 'Caller is not a manager');
        _;
    }

    /** Roles management - only for multi sig address */
    function setupRole(bytes32 role, address account) external onlyManager {
        _setupRole(role, account);
    }

    function isManager(address account) external view returns (bool) {
        return hasRole(MANAGER_ROLE, account);
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSetUpgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

