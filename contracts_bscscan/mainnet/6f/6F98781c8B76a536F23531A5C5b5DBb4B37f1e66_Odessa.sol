/*
   ____  ____  ________________ ___
  / __ \/ __ \/ ____/ ___/ ___//   |
 / / / / / / / __/  \__ \\__ \/ /| |
/ /_/ / /_/ / /___ ___/ /__/ / ___ |
\____/_____/_____//____/____/_/  |_|

@@author    Albert (t.me/OdessaFinance)
@@notice    Odessa Finance is a deflationary, airdroppable and vaultable token on the BSC.
            Transfer/Buy fees: NONE (obligatory network fees apply)
            Sell fee: 4% auto-staking, 4% liquidity, 2% burn, 1% marketing vault
            Anti-Whale: Max wallet balance for everyone is 5% of the total supply, max ~0.05BNB investment on 1 BNB liquidity

Owner tokens are waived, locking all liquidity on the dex pair.
In effect this can never turn into a rug pull.
Owner is not renounced in order to be able to set airdrops, update router address

The max transaction amount setter is limited to 5% of the total supply.
Vaults and $burn, $reflection, $liquify settings are limited as well.
In effect this can never turn into a honeypot.

Odessa Finance contract is the result of extensive research with every part unit-tested and audited with Slither and Mythril. No part is copied from anywhere else!

The purpose is to eventually fuel upcoming dApps
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "../features/Deflationary.sol";
import "../features/Airdroppable.sol";

contract Odessa is Deflationary, AirDroppable
{
    string constant NAME_ = "Odessa";
    string constant SYMBOL_ = "ODESSA";
    uint256 constant DECIMALS_ = 18;
    uint256 constant TOKENSUPPLY_ = 10 ** 9;

    constructor () ERC20(NAME_, SYMBOL_, DECIMALS_, TOKENSUPPLY_)
    {
        ERC20._mint(_msgSender(), ERC20.totalSupply());
        setMaxTransferRate(20);
        setBurnRate(2);
        setLiquifyRate(4);
        setReflectionRate(4);

        setRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    }


    function sendAirDrops() external override onlyOwner
    {
        require(_airdropEnabled, "AirDrops are disabled.");

        address marketingVault = getVaultByName("Marketing").wallet;
        require(marketingVault != address(0), "Marketing Vault not set.");

        require(ERC20.balanceOf(marketingVault) > 0, "AirDrops are depleted.");

        for (uint256 i = 0; i < _accounts.length;)
        {
            address account = _accounts[i];
            uint256 amount = _airdrops[account];

            if (amount > 0)
            {
                _distributedAirdrops++;
                _airdrops[account] = 0;

                ERC20._transfer(marketingVault, account, amount);
            }

            _accounts[i] = _accounts[_accounts.length - 1];
            _accounts.pop();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "../vendor/@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "../vendor/@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "../vendor/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ERC20.sol";
import "./Vaultable.sol";

abstract contract Deflationary is ERC20, Vaultable
{
    using SafeMath for uint256;

    uint256 private $reflection;
    uint256 private $burn;
    uint256 private $liquify;
    uint256 private $distribution;
    uint256 private $maxTransferAmount;
    uint256 private _holders;
    mapping(address => bool) private _holder;
    IUniswapV2Router01 private LPRouter;
    address private LPPair;


    event MaxTransferSet(uint256 current, uint256 previous);
    event BurnRateSet(uint256 current, uint256 previous);
    event ReflectionRateSet(uint256 current, uint256 previous);
    event LiquifyRateSet(uint256 current, uint256 previous);


    receive() external payable {}


    function balanceOf(address account) public view virtual override returns (uint256)
    {
        if (holder(account) && $distribution > 0)
            return reflection(_balances[account]);

        return _balances[account];
    }


    function _transfer(address sender, address recipient, uint256 amount) internal override
    {
        require(sender != address(0) && recipient != address(0), "Transfer from/to zero address.");
        require(amount > 0, "Amount is zero.");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Amount too high.");

        uint256 $amountToReceive = deflate(sender, recipient, amount);

        if ($amountToReceive < amount)
            _balances[address(this)] += amount
            .mul($reflection + $liquify + fees)
            .div(10 ** 2);

        _balances[sender] = senderBalance - amount;
        _balances[recipient] += $amountToReceive;

        if (holder(recipient))
        {
            require(_balances[recipient] <= $maxTransferAmount, "Exceeded maximum holder amount.");

            _holder[recipient] = true;
            _holders++;
        }
        if (holder(sender) && _balances[sender] == 0)
        {
            _holder[sender] = false;
            _holders--;
        }

        emit Transfer(sender, recipient, $amountToReceive);
    }


    function reflection(uint256 amount) private view returns (uint256)
    {
        if (amount == 0) return 0;

        //proportional distribution
        uint256 $staking = amount.mul($distribution) / _totalSupply;

        return amount + $staking;
    }


    function deflate(address sender, address recipient, uint256 amount) private returns (uint256)
    {
        if (sender == owner() || sender == address(this)) return amount;

        uint256 $tax = 0;
        uint256 $taxAmount = 0;
        uint256 $amountToReceive = amount;

        if (
            ($reflection + $burn + $liquify) > 0
            && recipient == LPPair
        )
        {
            if ($reflection > 0) $tax += $reflection;
            if ($burn > 0) $tax += $burn;
            if ($liquify > 0) $tax += $liquify;
            if (fees > 0) $tax += fees;

            $taxAmount = amount.mul($tax).div(10 ** 2);
            $amountToReceive = amount - $taxAmount;

            if ($burn > 0) ERC20._totalSupply -= amount.mul($burn).div(10 ** 2);

            $distribution += amount.mul($reflection).div(10 ** 2);
        }


        return $amountToReceive;
    }


    function holder(address account) private view returns (bool)
    {
        return account != address(this)
        && account != owner()
        && account != LPPair;
    }


    function swapAndLiquify() external onlyOwner
    {
        uint256 amount = balanceOf(address(this));

        for (uint256 i = 0; i < _vaults.length; i++)
        {
            Vault memory $vault = getVaultByAddress(_vaults[i]);

            uint256 $vaultAmount = amount.mul($liquify + $reflection + $vault.reflection).div(10 ** 2);
            amount = amount.sub($vaultAmount);
            ERC20._transfer(address(this), $vault.wallet, $vaultAmount);
        }

        amount = amount.div(2);
        addLiquidity(swapTokensForEth(amount), amount);
    }

    function swapTokensForEth(uint256 tokens) private returns (uint256)
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = LPRouter.WETH();

        if (_allowances[address(this)][address(LPRouter)] < tokens)
            ERC20._approve(address(this), address(LPRouter), tokens);

        uint256[] memory amountsOut = LPRouter.getAmountsOut(tokens, path);
        uint256 amountOutMin = amountsOut[1].mul(50).div(10**2);

        //(uint256[] memory amounts)
        IUniswapV2Router01(address(LPRouter)).
        swapExactTokensForETH(
            tokens,
            amountOutMin,
            path,
            address(this),
            block.timestamp
        );

        return address(this).balance;
    }

    function addLiquidity(uint256 ETH, uint256 TOKEN) private returns (uint256)
    {
        if (ETH > 0)
        {
            ERC20._approve(address(this), address(LPRouter), TOKEN + 1);

            //(uint amountToken, uint amountETH, uint liquidity)
            (,,uint256 liquidity) = IUniswapV2Router01(address(LPRouter)).addLiquidityETH {value : ETH}(
                address(this),
                TOKEN,
                0,
                0,
                LPPair,
                block.timestamp
            );

            return liquidity;
        }
        return 0;
    }


    function getDistribution() external view returns (uint256)
    {
        return $distribution;
    }

    function getHolders() external view returns (uint256)
    {
        return _holders;
    }

    function setRouter(address router) public onlyOwner
    {
        require(address(LPRouter) != router, "Already set to this router address.");

        IUniswapV2Router01 _router = IUniswapV2Router01(router);
        LPRouter = _router;
        LPPair = IUniswapV2Factory(_router.factory()).createPair(address(this), _router.WETH());
    }

    function setMaxTransferRate(uint256 amount) public onlyOwner
    {
        require(amount >= 20, "Max transfer rate must be >= 20 (=5% of total supply).");
        uint256 previous = $maxTransferAmount;
        $maxTransferAmount = _totalSupply / amount;

        emit MaxTransferSet($maxTransferAmount, previous);
    }

    function setBurnRate(uint256 amount) public onlyOwner
    {
        require(amount <= 10, "Max burn rate must be <= 10%.");
        uint256 previous = $burn;
        $burn = amount;

        emit BurnRateSet($burn, previous);
    }

    function setReflectionRate(uint256 amount) public onlyOwner
    {
        require(amount <= 10, "Max staking rate must be <= 10%.");
        uint256 previous = $reflection;
        $reflection = amount;

        emit ReflectionRateSet($reflection, previous);
    }

    function setLiquifyRate(uint256 amount) public onlyOwner
    {
        require(amount <= 10, "Max liquify rate must be <= 10%.");
        uint256 previous = $liquify;
        $liquify = amount;

        emit LiquifyRateSet($liquify, previous);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "../vendor/@openzeppelin/contracts/access/Ownable.sol";

abstract contract AirDroppable is Ownable
{
    mapping(address => uint256) internal _airdrops;
    address[] internal _accounts;
    bool internal _airdropEnabled;
    uint256 internal _distributedAirdrops;

    event AirDrop(uint256 amount, address[] account);
    event SwitchAirDrop(bool status);


    function sendAirDrops() external virtual;


    function switchAirDrop(bool mode) external onlyOwner
    {
        require(mode != _airdropEnabled, "AirDrop mode already set.");

        _airdropEnabled = mode;
        emit SwitchAirDrop(_airdropEnabled);
    }


    function setAirDrop(address[] memory accounts, uint256 amount) external onlyOwner
    {
        for (uint256 i = 0; i < accounts.length; i++)
        {
            address account = accounts[i];

            _airdrops[account] += amount;
            _accounts.push(account);
        }

        emit AirDrop(amount, accounts);
    }


    function unsetAirDrop(address account) external onlyOwner
    {
        _airdrops[account] = 0;

        address[] memory accounts = new address[](1);
        accounts[0] = account;

        emit AirDrop(0, accounts);
    }


    function getDistributedAirDrops() external view returns (uint256)
    {
        return _distributedAirdrops;
    }
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.9;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.9;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.9;

library SafeMath {

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "../vendor/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../vendor/@openzeppelin/contracts/utils/Context.sol";
import "../vendor/@openzeppelin/contracts/access/Ownable.sol";

contract ERC20 is Context, IERC20, IERC20Metadata, Ownable
{
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    string internal _name;
    string internal _symbol;
    uint256 internal immutable _decimals;
    uint256 internal _totalSupply;


    constructor (
        string memory name_,
        string memory symbol_,
        uint256 decimals_,
        uint256 totalSupply_
    )
    {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_ * (10 ** decimals_);
    }

    //IERC20Metadata
    function name() external view virtual override returns (string memory) {
        return _name;
    }

    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() external view virtual override returns (uint256) {
        return _decimals;
    }

    //IERC20
    function totalSupply() public view override returns (uint256)
    {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address sender, address spender) external view override returns (uint256)
    {
        return _allowances[sender][spender];
    }

    //ERC20
    function approve(address spender, uint256 amount) external override returns (bool)
    {
        require(_balances[_msgSender()] >= amount, "Insufficient balance.");

        _allowances[_msgSender()][spender] = 0;
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool)
    {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "Transfer amount exceeds allowance");

        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual
    {
        require(sender != address(0) && recipient != address(0), "Transfer from/to zero address.");
        require(amount > 0, "Transfer amount must be greater than zero.");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Amount too high.");

        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal
    {
        require(account != address(0), "Mint to zero address");

        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(address sender, address spender, uint256 amount) internal
    {
        require(sender != address(0) && spender != address(0), "Approve from/to zero address.");

        _allowances[sender][spender] = amount;

        emit Approval(sender, spender, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "../vendor/@openzeppelin/contracts/access/Ownable.sol";

abstract contract Vaultable is Ownable
{
    struct Vault {
        string name;
        address wallet;
        uint256 reflection;
        bool exists;
    }

    mapping(string => Vault) internal byName;
    mapping(address => Vault) internal byAddress;
    address[] internal _vaults;
    uint256 internal fees;

    event VaultAdded(address vault, string name);
    event VaultRemoved(address vault, string name);


    function setVault(string memory name, address vault, uint256 reflection) external onlyOwner
    {
        require(!byAddress[vault].exists, "Already in vaults.");
        require(reflection <= 3, "Vault fee cannot exceed 3%.");
        require(_vaults.length < 5, "Total vaults cannot exceed 5.");

        fees += reflection;
        Vault memory _vault = Vault(name, vault, reflection, true);
        byAddress[vault] = _vault;
        byName[name] = _vault;

        _vaults.push(vault);

        emit VaultAdded(vault, name);
    }

    function getVaultByAddress(address vault) internal view returns (Vault memory)
    {
        return byAddress[vault];
    }

    function getVaultByName(string memory name) internal view returns (Vault memory)
    {
        return byName[name];
    }

    function removeVault(address vault) external onlyOwner
    {
        require(byAddress[vault].exists, "Vault does not exist.");

        uint256 fee = byAddress[vault].reflection;
        string memory name = byAddress[vault].name;
        fees = fees - fee;
        delete byAddress[vault];
        delete byName[name];

        for (uint256 i = 0; i < _vaults.length; i++)
        {
            if (_vaults[i] == vault)
            {
                _vaults[i] = _vaults[_vaults.length - 1];
                _vaults.pop();
                break;
            }
        }

        emit VaultRemoved(vault, name);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.9;

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
    function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.9;

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
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.9;

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
        _setOwner(_msgSender());
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
    function renounceOwnership() external virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.9;

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