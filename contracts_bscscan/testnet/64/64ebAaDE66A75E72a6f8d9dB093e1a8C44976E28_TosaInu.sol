// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Factory.sol";

import "./Blacklist.sol";

enum Entity {
    Seller,
    Buyer
}

contract TosaInu is IERC20, IERC20Metadata, Pausable, Ownable, BlackList {
    //***************************************** Events *****************************************
    event LogLiquidityEvent(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    event LogLiquidityEventState(bool state);

    //***************************************** State Variables *****************************************

    //***************************************** Public *****************************************

    mapping(address => bool) public isWhitelisted;

    IUniswapV2Router02 public uniswapV2Router;

    address public uniswapV2WETHPair;

    address public marketingFund;

    address public presaleContract;

    uint256 public totalFees;

    uint256 public buyerReflectionTax;

    uint256 public buyerLiquidityTax;

    uint256 public buyerMarketingTax;

    uint256 public sellerReflectionTax = 1; // 1%

    uint256 public sellerLiquidityTax = 3; // 3%

    uint256 public sellerMarketingTax = 2; // 2%

    bool public liquidityEventInProgress;

    bool public liquidityEventState;

    //@dev 0.5% of total supply a wallet can have
    uint256 public maxWalletAmount = 5 * 10**6 * 10**18;

    //@dev 0.2% of total supply can be transferred at once
    uint256 public maxTxAmount = 2 * 10**6 * 10**18;

    //***************************************** Private *****************************************

    string private _name = "Tosa Inu";

    string private _symbol = "TOSA";

    uint8 private _decimals = 18;

    uint256 private constant MAX_INT_VALUE = type(uint256).max;

    uint256 private _totalSupply = 10**9 * 10**18;

    uint256 private _reflectionSupply =
        MAX_INT_VALUE - (MAX_INT_VALUE % _totalSupply);

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => uint256) private _reflectionBalance;

    uint256 private _deadBlocks;

    uint256 private _launchedAt;

    //@dev once the contract holds 0.5% it will trigger a liquidity event
    uint256 private constant _numberTokensSellToAddToLiquidity =
        5 * 10**6 * 10**18;

    constructor(address _router, address _marketingFund) {
        //@notice Give all supply to owner
        _reflectionBalance[_msgSender()] = _reflectionSupply;

        //@notice Tells solidity this address is the router
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);

        //@dev creates the market for WBNB/TOSA
        uniswapV2WETHPair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        //@notice Assign PCS V2 router
        uniswapV2Router = _uniswapV2Router;

        marketingFund = _marketingFund;

        isWhitelisted[_msgSender()] = true;
        isWhitelisted[address(this)] = true;
        isWhitelisted[_marketingFund] = true;

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    //***************************************** modifiers *****************************************
    //@dev security prevents swapping during a liquidity event
    modifier lockSwap() {
        liquidityEventInProgress = true;
        _;
        liquidityEventInProgress = false;
    }

    //***************************************** private functions *****************************************

    //@dev returns the convetion rate between reflection to token
    function _getRate() private view returns (uint256) {
        return _reflectionSupply / _totalSupply;
    }

    //@dev converts an amount of token to reflections
    function _getReflectionsFromTokens(uint256 _amount)
        private
        view
        returns (uint256)
    {
        require(_totalSupply >= _amount, "TOSA: convert less tokens");
        return _amount * _getRate();
    }

    //@dev converts an amount of reflections to tokens
    function _getTokensFromReflections(uint256 _amount)
        private
        view
        returns (uint256)
    {
        require(_reflectionSupply >= _amount, "TOSA: convert less reflections");
        return _amount / _getRate();
    }

    //@dev assumes that _tax = 5 means 5%
    function _calculateTax(uint256 _amount, uint256 _tax)
        private
        pure
        returns (uint256)
    {
        return (_amount * _tax) / 100;
    }

    //@dev buys ETH with tokens stored in this contract
    function _swapTokensForEth(uint256 _amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), _amount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    //@dev Adds equal amount of eth and tokens to the ETH liquidity pool
    function _addLiquidity(uint256 _tokenAmount, uint256 _ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), _tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: _ethAmount}(
            address(this),
            _tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function _swapAndLiquefy() private lockSwap {
        // split the contract token balance into halves
        uint256 half = _numberTokensSellToAddToLiquidity / 2;
        uint256 otherHalf = _numberTokensSellToAddToLiquidity - half;

        uint256 initialETHContractBalance = address(this).balance;

        // Buys ETH at current token price
        _swapTokensForEth(half);

        // This is to make sure we are only using ETH derived from the liquidity fee
        uint256 ethBought = address(this).balance - initialETHContractBalance;

        // Add liquidity to the pool
        _addLiquidity(otherHalf, ethBought);

        emit LogLiquidityEvent(half, ethBought, otherHalf);
    }

    function _approve(
        address _owner,
        address _beneficiary,
        uint256 _amount
    ) private {
        require(
            _beneficiary != address(0),
            "The burn address is not allowed to receive approval for allowances."
        );
        require(
            _owner != address(0),
            "The burn address is not allowed to approve allowances."
        );

        _allowances[_owner][_beneficiary] = _amount;
        emit Approval(_owner, _beneficiary, _amount);
    }

    function _send(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private {
        uint256 rAmount = _getReflectionsFromTokens(_amount);

        _reflectionBalance[_sender] -= rAmount;

        _reflectionBalance[_recipient] += rAmount;

        emit Transfer(_sender, _recipient, _amount);
    }

    function _whitelistSend(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private whenNotPaused {
        _send(_sender, _recipient, _amount);
    }

    function _sendWithTax(
        address _sender,
        address _recipient,
        uint256 _amount,
        // These are percentages
        uint256 _reflectionTax,
        uint256 _liquidityTax,
        uint256 _marketingTax
    ) private whenNotPaused {
        uint256 rAmount = _getReflectionsFromTokens(_amount);

        if (_recipient != uniswapV2WETHPair) {
            require(
                _getTokensFromReflections(
                    _reflectionBalance[_recipient] + rAmount
                ) <= maxWalletAmount,
                "TOSA: there is a max wallet limit"
            );
        }

        _reflectionBalance[_sender] -= rAmount;

        //@dev convert the % to the nominal amount
        uint256 liquidityTax = _calculateTax(_amount, _liquidityTax);
        //@dev convert from tokens to reflections to update balances
        uint256 rLiquidityTax = _getReflectionsFromTokens(liquidityTax);

        uint256 marketingTax = _calculateTax(_amount, _marketingTax);
        uint256 rMarketingTax = _getReflectionsFromTokens(marketingTax);

        uint256 reflectionTax = _calculateTax(_amount, _reflectionTax);
        uint256 rReflectionTax = _getReflectionsFromTokens(reflectionTax);

        _reflectionBalance[_recipient] +=
            rAmount -
            rLiquidityTax -
            rMarketingTax -
            rReflectionTax;

        _reflectionBalance[marketingFund] += rMarketingTax;

        _reflectionBalance[address(this)] += rLiquidityTax;

        _reflectionSupply -= rReflectionTax;

        totalFees += liquidityTax + marketingTax + reflectionTax;

        uint256 finalAmount = _amount -
            reflectionTax -
            marketingTax -
            liquidityTax;

        emit Transfer(_sender, _recipient, finalAmount);
    }

    function _sell(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private {
        _sendWithTax(
            _sender,
            _recipient,
            _amount,
            sellerReflectionTax,
            //@dev blacklisted seller will be punished with most of his tokens going to the liquidity
            isBlacklisted(_sender) ? 95 : sellerLiquidityTax,
            sellerMarketingTax
        );
    }

    function _buy(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private {
        _sendWithTax(
            _sender,
            _recipient,
            _amount,
            buyerReflectionTax,
            buyerLiquidityTax,
            buyerMarketingTax
        );
    }

    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private {
        require(
            _sender != address(0),
            "TOSA: Sender cannot be the zero address"
        );
        require(
            _recipient != address(0),
            "TOSA: Recipient cannot be the zero address"
        );
        require(_amount > 0, "TOSA: amount cannot be zero");

        if (!isWhitelisted[_sender]) {
            require(_amount <= maxTxAmount, "TOSA: amount exceeds the limit");
        }

        // Condition 1: Make sure the contract has the enough tokens to liquefy
        // Condition 2: We are not in a liquefication event
        // Condition 3: Liquification is enabled
        // Condition 4: It is not the uniswapPair that is sending tokens

        if (
            balanceOf(address(this)) >= _numberTokensSellToAddToLiquidity &&
            !liquidityEventInProgress &&
            liquidityEventState &&
            _sender != uniswapV2WETHPair
        ) _swapAndLiquefy();

        //@dev presaleContract can send tokens even when the contract is paused
        if (_sender == presaleContract || _recipient == presaleContract) {
            _send(_sender, _recipient, _amount);
            return;
        }

        //@dev whitelisted addresses can transfer without fees and no limit on their hold (marketingFund/Owner)
        if (isWhitelisted[_sender] || isWhitelisted[_recipient]) {
            _whitelistSend(_sender, _recipient, _amount);
            return;
        }

        //@dev snipers will be caught on buying and punished on selling
        if (block.number <= _launchedAt + _deadBlocks) {
            _addToBlacklist(_recipient);
        }

        //@dev if tokens are being sent to PCS pair it represents a sell swap
        if (_recipient == address(uniswapV2WETHPair)) {
            _sell(_sender, _recipient, _amount);
        } else {
            _buy(_sender, _recipient, _amount);
        }
    }

    //***************************************** public functions *****************************************

    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     *@dev It returns the symbol of the token.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     *@dev It returns the decimal of the token.
     */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    //@dev It is necessary to convert from reflections to tokens to display the proper balance
    function balanceOf(address _account)
        public
        view
        override
        returns (uint256)
    {
        return _getTokensFromReflections(_reflectionBalance[_account]);
    }

    function approve(address _beneficiary, uint256 _amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), _beneficiary, _amount);
        return true;
    }

    function transfer(address _recipient, uint256 _amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), _recipient, _amount);
        return true;
    }

    function allowance(address _owner, address _beneficiary)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[_owner][_beneficiary];
    }

    function increaseAllowance(address _beneficiary, uint256 _amount)
        external
        returns (bool)
    {
        _approve(
            _msgSender(),
            _beneficiary,
            _allowances[_msgSender()][_beneficiary] + _amount
        );
        return true;
    }

    function decreaseAllowance(address _beneficiary, uint256 _amount)
        external
        returns (bool)
    {
        _approve(
            _msgSender(),
            _beneficiary,
            _allowances[_msgSender()][_beneficiary] - _amount
        );
        return true;
    }

    function transferFrom(
        address _provider,
        address _beneficiary,
        uint256 _amount
    ) public override returns (bool) {
        _transfer(_provider, _beneficiary, _amount);
        _approve(
            _provider,
            _msgSender(),
            _allowances[_provider][_msgSender()] - _amount
        );
        return true;
    }

    //***************************************** Owner only functions *****************************************

    function launch(uint256 _amount) external onlyOwner {
        require(_launchedAt == 0, "TOSA: already launched");
        _launchedAt = block.number;
        _deadBlocks = _amount;
        liquidityEventState = true;
        _unpause();
    }

    function addToBlacklist(address _account) external onlyOwner {
        require(_account != address(0), "TOSA: zero address");
        _addToBlacklist(_account);
    }

    function removeFromBlacklist(address _account) external onlyOwner {
        require(_account != address(0), "TOSA: zero address");
        _removeFromBlacklist(_account);
    }

    function setPresaleContract(address _account) external onlyOwner {
        require(presaleContract == address(0), "TOSA: already set!");
        presaleContract = _account;
    }

    function toggleLiquidityEventState() external onlyOwner {
        liquidityEventState = !liquidityEventState;
        emit LogLiquidityEventState(liquidityEventState);
    }

    function withdrawETH() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "TOSA: failed to send ETH");
    }

    function setMaxTxAmount(uint256 _amount) external onlyOwner {
        maxTxAmount = _amount;
    }

    function setMaxWalletAmount(uint256 _amount) external onlyOwner {
        maxWalletAmount = _amount;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function addToWhiteList(address _account) external onlyOwner {
        isWhitelisted[_account] = true;
    }

    function removeFromWhitelist(address _account) external onlyOwner {
        isWhitelisted[_account] = false;
    }

    function setTax(
        Entity _entity,
        uint256 _liquidityTax,
        uint256 _marketingTax,
        uint256 _reflectionTax
    ) external onlyOwner {
        if (_entity == Entity.Buyer) {
            buyerLiquidityTax = _liquidityTax;
            buyerMarketingTax = _marketingTax;
            buyerReflectionTax = _reflectionTax;
        } else {
            sellerLiquidityTax = _liquidityTax;
            sellerMarketingTax = _marketingTax;
            sellerReflectionTax = _reflectionTax;
        }
    }

    function updateRouter(address _router) external onlyOwner {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);

        address pair = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(
            address(this),
            _uniswapV2Router.WETH()
        );

        if (pair == address(0)) {
            pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
                address(this),
                _uniswapV2Router.WETH()
            );
        }

        uniswapV2WETHPair = pair;
        uniswapV2Router = _uniswapV2Router;
    }

    function setMarketingFund(address _account) external onlyOwner {
        marketingFund = _account;
    }

    function withdrawERC20(address _token, address _to)
        external
        onlyOwner
        returns (bool)
    {
        require(
            _token != address(this),
            "You cannot withdraw this contract tokens."
        );
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        require(
            IERC20(_token).transfer(_to, _contractBalance),
            "TOSA: failed to send ERC20"
        );
        return true;
    }

    //@dev receive ETHER from the PCS
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract BlackList {
    mapping(address => bool) private _isBlacklisted;

    constructor() {
        _isBlacklisted[0xE4882975f933A199C92b5A925C9A8fE65d599Aa8] = true;
        _isBlacklisted[0x86C70C4a3BC775FB4030448c9fdb73Dc09dd8444] = true;
        _isBlacklisted[0xa4A25AdcFCA938aa030191C297321323C57148Bd] = true;
        _isBlacklisted[0x20C00AFf15Bb04cC631DB07ee9ce361ae91D12f8] = true;
        _isBlacklisted[0x0538856b6d0383cde1709c6531B9a0437185462b] = true;
        _isBlacklisted[0x6e44DdAb5c29c9557F275C9DB6D12d670125FE17] = true;
        _isBlacklisted[0x90484Bb9bc05fD3B5FF1fe412A492676cd81790C] = true;
        _isBlacklisted[0xA62c5bA4D3C95b3dDb247EAbAa2C8E56BAC9D6dA] = true;
        _isBlacklisted[0xA94E56EFc384088717bb6edCccEc289A72Ec2381] = true;
        _isBlacklisted[0x3066Cc1523dE539D36f94597e233719727599693] = true;
        _isBlacklisted[0xf13FFadd3682feD42183AF8F3f0b409A9A0fdE31] = true;
        _isBlacklisted[0x376a6EFE8E98f3ae2af230B3D45B8Cc5e962bC27] = true;
        _isBlacklisted[0x0538856b6d0383cde1709c6531B9a0437185462b] = true;
        _isBlacklisted[0x90484Bb9bc05fD3B5FF1fe412A492676cd81790C] = true;
        _isBlacklisted[0xA62c5bA4D3C95b3dDb247EAbAa2C8E56BAC9D6dA] = true;
        _isBlacklisted[0xA94E56EFc384088717bb6edCccEc289A72Ec2381] = true;
        _isBlacklisted[0x3066Cc1523dE539D36f94597e233719727599693] = true;
        _isBlacklisted[0xf13FFadd3682feD42183AF8F3f0b409A9A0fdE31] = true;
        _isBlacklisted[0x376a6EFE8E98f3ae2af230B3D45B8Cc5e962bC27] = true;
        _isBlacklisted[0x201044fa39866E6dD3552D922CDa815899F63f20] = true;
        _isBlacklisted[0x6F3aC41265916DD06165b750D88AB93baF1a11F8] = true;
        _isBlacklisted[0x27C71ef1B1bb5a9C9Ee0CfeCEf4072AbAc686ba6] = true;
        _isBlacklisted[0xDEF441C00B5Ca72De73b322aA4e5FE2b21D2D593] = true;
        _isBlacklisted[0x5668e6e8f3C31D140CC0bE918Ab8bB5C5B593418] = true;
        _isBlacklisted[0x4b9BDDFB48fB1529125C14f7730346fe0E8b5b40] = true;
        _isBlacklisted[0x7e2b3808cFD46fF740fBd35C584D67292A407b95] = true;
        _isBlacklisted[0xe89C7309595E3e720D8B316F065ecB2730e34757] = true;
        _isBlacklisted[0x725AD056625326B490B128E02759007BA5E4eBF1] = true;
    }

    function _addToBlacklist(address _account) internal {
        _isBlacklisted[_account] = true;
    }

    function _removeFromBlacklist(address _account) internal {
        _isBlacklisted[_account] = false;
    }

    function isBlacklisted(address _account) public view returns (bool) {
        return _isBlacklisted[_account];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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

pragma solidity 0.8.9;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}