// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "./interfaces/AggregatorInterface.sol";
import "./interfaces/swaps/IUniswapV2Factory.sol";
import "./interfaces/swaps/IUniswapV2Pair.sol";
import "./interfaces/swaps/IStableswap.sol";
import "./lib/Governable.sol";

/// @title Price Oracle
/// @author Chainvisions
/// @notice A price oracle for quickly fetching prices on-chain.

contract PriceOracle is Governable {
    enum AssetType {
        Token,
        LPToken,
        StableswapLP
    }

    /// @notice A list of "keepers" who have permission to modify state variables on the contract.
    mapping(address => bool) public keepers;

    /// @notice A list of known tokens, allowing for token type check to be skipped. Vital for tokens like WMATIC which
    /// cause a reversion when the check is performed on them.
    mapping(address => bool) public knownTokens;

    /// @notice Chainlink price feeds for tokens that Chainlink supports.
    mapping(address => address) public tokenPriceOracle;

    /// @notice Optimal pair for price calculations, overrides fetching the largest
    /// pair when fetching the price of a token using AMMs.
    mapping(address => address) public optimalTokenPair;

    /// @notice Common base tokens to check the pools of for the largest pair.
    address[] public commonBaseTokens;

    /// @notice Factory contracts used for finding AMM pools for fetching price from.
    address[] public factoryContracts;

    /// @notice Emitted when a keeper is added to the list of keepers.
    event KeeperAdded(address keeper);

    /// @notice Emitted when a token is added to the list of known tokens.
    event KnownTokenAdded(address knownToken);

    /// @notice Emitted when a base token is added to `commonBaseTokens`.
    event BaseTokenAdded(address baseToken);

    /// @notice Emitted when a factory contract is added to `factoryContracts`.
    event FactoryAdded(address factory);

    /// @notice Emitted when a base token is removed from `commonBaseTokens`.
    event BaseTokenRemoved(address baseToken);

    /// @notice Emitted when a factory contract is removed from `factoryContracts`.
    event FactoryRemoved(address factory);

    /// @notice Emitted when a keeper is removed from the list of keepers.
    event KeeperRemoved(address keeper);

    /// @notice Emitted when a token is removed from the list of known tokens.
    event KnownTokenRemoved(address knownToken);

    modifier permissioned {
        require(
            msg.sender == governance() 
            || 
            keepers[msg.sender], 
            "PriceOracle: Caller not governance or keeper"
        );
        _;
    }

    constructor(address _storage) Governable(_storage) {
        // Add msg.sender as an initial keeper.
        keepers[msg.sender] = true;
        emit KeeperAdded(msg.sender);
    }

    /// @notice Adds keepers to the list of keepers on the contract.
    /// @param _keepers Keepers to add.
    function addKeepers(address[] memory _keepers) public onlyGovernance {
        for(uint256 i = 0; i < _keepers.length; i++) {
            keepers[_keepers[i]] = true;
            emit KeeperAdded(_keepers[i]);
        }
    }

    /// @notice Adds tokens to the list of known tokens on the contract.
    /// @param _knownTokens Tokens to add to the list.
    function addKnownTokens(address[] memory _knownTokens) public permissioned {
        for(uint256 i = 0; i < _knownTokens.length; i++) {
            knownTokens[_knownTokens[i]] = true;
            emit KnownTokenAdded(_knownTokens[i]);
        }
    }

    /// @notice Sets the price oracle for `_asset`.
    /// @param _asset Asset to set the price oracle of.
    /// @param _oracle Chainlink price oracle for the asset.
    function setTokenPriceOracle(address _asset, address _oracle) public permissioned {
        tokenPriceOracle[_asset] = _oracle;
    }

    /// @notice Adds common base tokens to `commonBaseTokens`.
    /// @param _tokens Common base tokens to add to the array.
    function addCommonBaseTokens(address[] memory _tokens) public permissioned {
        for(uint256 i = 0; i < _tokens.length; i++) {
            commonBaseTokens.push(_tokens[i]);
            emit BaseTokenAdded(_tokens[i]);
        }
    }

    /// @notice Adds factory contracts to `factoryContracts`.
    function addFactoryContracts(address[] memory _factories) public permissioned {
        for(uint256 i = 0; i < _factories.length; i++) {
            factoryContracts.push(_factories[i]);
            emit FactoryAdded(_factories[i]);
        }
    }

    /// @notice Sets the optimal pair for `_asset`.
    /// @param _asset Asset to set the optimal pair of.
    /// @param _optimalPair Optimal pair to set for `_asset`.
    function setOptimalPair(address _asset, address _optimalPair) public permissioned {
        optimalTokenPair[_asset] = _optimalPair;
    }

    /// @notice Removes common base tokens from `commonBaseTokens`.
    /// @param _tokens Tokens to remove from `commonBaseTokens`.
    function removeCommonBaseTokens(address[] memory _tokens) public permissioned {
        for(uint256 i = 0; i < _tokens.length; i++) {
            // Find index of the token.
            uint256 index = findArrayIndex(commonBaseTokens, _tokens[i]);

            // Using the index, remove the token from the array.
            commonBaseTokens[index] = commonBaseTokens[commonBaseTokens.length - 1];
            commonBaseTokens.pop();
            
            emit BaseTokenRemoved(_tokens[i]);
        }
    }

    /// @notice Removes factory contracts from `factoryContracts`.
    /// @param _factories Factory contracts to remove.
    function removeFactoryContracts(address[] memory _factories) public permissioned {
        for(uint256 i = 0; i < _factories.length; i++) {
            // Find the index of the factory.
            uint256 index = findArrayIndex(factoryContracts, _factories[i]);

            // Using the index, remove the factory from the array.
            factoryContracts[index] = factoryContracts[factoryContracts.length - 1];
            factoryContracts.pop();

            emit FactoryRemoved(_factories[i]);
        }
    }

    /// @notice Removes keepers from the list of keepers.
    /// @param _keepers Keepers to remove from the list.
    function removeKeepers(address[] memory _keepers) public onlyGovernance {
        for(uint256 i = 0; i < _keepers.length; i++) {
            keepers[_keepers[i]] = false;
            emit KeeperRemoved(_keepers[i]);
        }
    }

    /// @notice Removes a list of tokens from `knownTokens`.
    /// @param _knownTokens Tokens to remove from the list.
    function removeKnownTokens(address[] memory _knownTokens) public onlyGovernance {
        for(uint256 i = 0; i < _knownTokens.length; i++) {
            knownTokens[_knownTokens[i]] = false;
            emit KnownTokenRemoved(_knownTokens[i]);
        }
    }

    /// @notice Calculates the price of a specified asset.
    /// @param _asset Asset to calculate the price of.
    /// @return The price of the asset in 1e18 format.
    function calculateAssetPrice(address _asset) public view returns (uint256) {
        // First we need to fetch the token type the asset is.
        AssetType tokenType;
        if(!knownTokens[_asset]) {
            tokenType = determineTokenTypeOf(_asset);
        } else {
            tokenType = AssetType.Token;
        }
        // Now we can begin our calculations.
        if(tokenType == AssetType.Token) {
            // If the asset type is a token, we first need to check if it has a Chainlink oracle.
            if(tokenPriceOracle[_asset] != address(0)) {
                // Since the asset has a Chainlink oracle, we can simply fetch the price straight
                // from the oracle and return it as the price of the asset.
                return uint256(AggregatorInterface(tokenPriceOracle[_asset]).latestAnswer()) * 1e10;
            } else if(optimalTokenPair[_asset] != address(0)) {
                // If no Chainlink oracle is present, but there is an optimal pair for the token,
                // we can use that pair to fetch the xy=k value of the token, simplifying price fetching.
                (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(optimalTokenPair[_asset]).getReserves();
                address token0 = IUniswapV2Pair(optimalTokenPair[_asset]).token0();
                address token1 = IUniswapV2Pair(optimalTokenPair[_asset]).token1();

                // Determine if `_asset` is token0 or token1.
                uint8 assetReserve = _asset == token0 ? 0 : 1;

                if(assetReserve == 0) {
                    return (reserve1 * calculateAssetPrice(token1)) / reserve0;
                } else {
                    return (reserve0 * calculateAssetPrice(token0)) / reserve1;
                }
            } else {
                // In the case of no optimal pair, we need to find the largest pool out of all
                // AMMs specified in `factoryContracts`.
                uint256 largestSize;
                address largestPool;
                for(uint256 i = 0; i < commonBaseTokens.length; i++) {
                    for(uint256 j = 0; j < factoryContracts.length; j++) {
                        // Fetch the pair address of the LP.
                        address pair = IUniswapV2Factory(factoryContracts[j]).getPair(commonBaseTokens[i], _asset);

                        // Continue with fetching the LP size if the pair exists.
                        if(pair == address(0)) {
                            continue;
                        }

                        // Fetch the reserves.
                        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pair).getReserves();

                        // Calculate the LP size.
                        address reserveToken0 = IUniswapV2Pair(pair).token0();
                        uint256 lpSize = _asset == reserveToken0 ? reserve0 : reserve1;

                        if(lpSize > largestSize) {
                            largestSize = lpSize;
                            largestPool = pair;
                        }
                    }
                }

                // Now that we have found the largest pool, we can fetch the price of the token from it.
                (uint256 lpReserve0, uint256 lpReserve1, ) = IUniswapV2Pair(largestPool).getReserves();
                address token0 = IUniswapV2Pair(largestPool).token0();
                address token1 = IUniswapV2Pair(largestPool).token1();

                // Determine if `_asset` is `token0` or `token1`.
                uint8 assetReserve = _asset == token0 ? 0 : 1;

                if(assetReserve == 0) {
                    return (lpReserve1 * calculateAssetPrice(token1)) / lpReserve0;
                } else {
                    return (lpReserve0 * calculateAssetPrice(token0)) / lpReserve1;
                }
            }
        } else if(tokenType == AssetType.LPToken) {
            // If the asset type is an LP token, we need to fetch the value of each underlying
            // token in the LP, then use those values to calculate the value of 1 LP token.
            address token0 = IUniswapV2Pair(_asset).token0();
            address token1 = IUniswapV2Pair(_asset).token1();

            // We can simply use this function to fetch the value of token0 and token1.
            uint256 token0Value = calculateAssetPrice(token0);
            uint256 token1Value = calculateAssetPrice(token1);

            // Now we need to fetch the total supply of the LP token and the reserves to calculate the value.
            (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(_asset).getReserves();
            uint256 lpSupply = IUniswapV2Pair(_asset).totalSupply();

            // We can now calculate the price of LP.
            return ((reserve0 * token0Value) + (reserve1 * token1Value)) / lpSupply;
        } else if(tokenType == AssetType.StableswapLP) {
            // If the asset type is a stableswap LP, we can simply fetch the virtual price of
            // the pool as the assets in the stableswap pool are closely pegged, simplifying calculations.
            return IStableswap(_asset).getVirtualPrice();
        }
        return 0;
    }

    /// @notice Determines the asset type of a specified token.
    /// @param _token Token to determine the type of.
    /// @return The asset type the token is.
    function determineTokenTypeOf(address _token) public view returns (AssetType) {
        // First we determine if the token is an LP token.
        bool isLPToken;
        try IUniswapV2Pair(_token).factory() {
            isLPToken = true;
        } catch {
            isLPToken = false;
        }
        if(!isLPToken) {
            // If `_token` is not an LP token, we move on and check if it is a stableswap LP.
            bool isStableswapLP;
            try IStableswap(_token).getVirtualPrice() {
                isStableswapLP = true;
            } catch {
                isStableswapLP = false;
            }
            if(isStableswapLP) {
                // If it is a stableswap LP, return `AssetType.StableswapLP`.
                return AssetType.StableswapLP;
            } {
                return AssetType.Token;
            }
        } else {
            return AssetType.LPToken;
        }
    }

    /// @notice Allows for the full `commonBaseTokens` array to be viewed.
    /// @return The array of common base tokens.
    function commonBases() public view returns (address[] memory) {
        return (commonBaseTokens);
    }

    /// @notice Allows for the full `factoryContracts` array to be viewed.
    /// @return The array of factory contracts.
    function factories() public view returns (address[] memory) {
        return (factoryContracts);
    }

    function findArrayIndex(address[] memory _array, address _value) private pure returns (uint256) {
        for(uint256 i = 0; i < _array.length; i++) {
            if(_array[i] == _value) {
                return i;
            }
        }

        revert("PriceOracle: Could not find this item on the array");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IStableswap {
    // pool data view functions
    function getA() external view returns (uint256);

    function getToken(uint8 index) external view returns (IERC20);

    function getTokenIndex(address tokenAddress) external view returns (uint8);

    function getTokenBalance(uint8 index) external view returns (uint256);

    function getVirtualPrice() external view returns (uint256);

    function isGuarded() external view returns (bool);

    // min return calculation functions
    function calculateSwap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256);

    function calculateTokenAmount(uint256[] calldata amounts, bool deposit)
        external
        view
        returns (uint256);

    function calculateRemoveLiquidity(uint256 amount)
        external
        view
        returns (uint256[] memory);

    function calculateRemoveLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex
    ) external view returns (uint256 availableTokenAmount);

    // state modifying functions
    function initialize(
        IERC20[] memory pooledTokens,
        uint8[] memory decimals,
        string memory lpTokenName,
        string memory lpTokenSymbol,
        uint256 a,
        uint256 fee,
        uint256 adminFee,
        address lpTokenTargetAddress
    ) external;

    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256);

    function addLiquidity(
        uint256[] calldata amounts,
        uint256 minToMint,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidity(
        uint256 amount,
        uint256[] calldata minAmounts,
        uint256 deadline
    ) external returns (uint256[] memory);

    function removeLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex,
        uint256 minAmount,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidityImbalance(
        uint256[] calldata amounts,
        uint256 maxBurnAmount,
        uint256 deadline
    ) external returns (uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../Storage.sol";

/**
 * @dev Contract for access control where the governance address specified
 * in the Storage contract can be granted access to specific functions
 * on a contract that inherits this contract.
 */

contract Governable {

  Storage public store;

  constructor(address _store) {
    require(_store != address(0), "Governable: New storage shouldn't be empty");
    store = Storage(_store);
  }

  modifier onlyGovernance() {
    require(store.isGovernance(msg.sender), "Governable: Not governance");
    _;
  }

  function setStorage(address _store) public onlyGovernance {
    require(_store != address(0), "Governable: New storage shouldn't be empty");
    store = Storage(_store);
  }

  function governance() public view returns (address) {
    return store.governance();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Storage {

  address public governance;
  address public controller;

  constructor() {
    governance = msg.sender;
  }

  modifier onlyGovernance() {
    require(isGovernance(msg.sender), "Storage: Not governance");
    _;
  }

  function setGovernance(address _governance) public onlyGovernance {
    require(_governance != address(0), "Storage: New governance shouldn't be empty");
    governance = _governance;
  }

  function setController(address _controller) public onlyGovernance {
    require(_controller != address(0), "Storage: New controller shouldn't be empty");
    controller = _controller;
  }

  function isGovernance(address account) public view returns (bool) {
    return account == governance;
  }

  function isController(address account) public view returns (bool) {
    return account == controller;
  }
}

