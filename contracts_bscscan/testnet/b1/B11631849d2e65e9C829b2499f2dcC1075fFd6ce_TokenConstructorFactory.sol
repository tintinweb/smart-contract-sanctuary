/*

        ░█████╗░██████╗░██╗░░░██╗██████╗░████████╗███████╗██╗░░██╗
        ██╔══██╗██╔══██╗╚██╗░██╔╝██╔══██╗╚══██╔══╝██╔════╝╚██╗██╔╝
        ██║░░╚═╝██████╔╝░╚████╔╝░██████╔╝░░░██║░░░█████╗░░░╚███╔╝░
        ██║░░██╗██╔══██╗░░╚██╔╝░░██╔═══╝░░░░██║░░░██╔══╝░░░██╔██╗░
        ╚█████╔╝██║░░██║░░░██║░░░██║░░░░░░░░██║░░░███████╗██╔╝╚██╗
        ░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░░░░╚═╝░░░╚══════╝╚═╝░░╚═╝

 Factory contract to create ERC20 and RFI tokens.

 • website:                           https://cryptexlock.me
 • medium:                            https://medium.com/cryptex-locker
 • Telegram Announcements Channel:    https://t.me/CryptExAnnouncements
 • Telegram Main Channel:             https://t.me/cryptexlocker
 • Twitter Page:                      https://twitter.com/ExLocker
 • Reddit:                            https://www.reddit.com/r/CryptExLocker/

 SPDX-License-Identifier: UNLICENSED

*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./TokenDeployCode.sol";
import "./RfiTokenDeloyCode.sol";

contract TokenConstructorFactory is Ownable {
    using SafeERC20 for ERC20;
    using SafeERC20 for IERC20;

    enum PaymentType {
        NATIVE,
        CRX
    }

    enum TokenType {
        SIMPLE_ERC20,
        REFLECT_TOKEN
    }

    IERC20 public immutable paymentToken;
    uint256 public simpleErc20TokenPrice;
    uint256 public simpleErc20TokenAuditPrice;
    uint256 public reflectTokenPrice;
    uint256 public reflectTokenAuditPrice;
    uint256 public bnbToCrxRatioBP;

    address private tokenDeployCodeAddress;
    address private rfiTokenDeployCodeAddress;

    event TokenCreated(
        string symbol,
        address indexed tokenAddress,
        address owner,
        TokenType tokenType,
        bool indexed withAudit
    );
    event PaymentReceived(
        address indexed payer,
        uint256 amount,
        PaymentType indexed paymentType
    );
    event PriceUpdated(
        uint256 simpleErc20TokenPrice,
        uint256 simpleErc20TokenAuditPrice,
        uint256 reflectTokenPrice,
        uint256 reflectTokenAuditPrice
    );
    event BnbToCrxRatioUpdated(uint256 bnbToCrxRatioBP);

    constructor(
        IERC20 _paymentToken,
        uint256 _simpleErc20TokenPrice,
        uint256 _simpleErc20TokenAuditPrice,
        uint256 _reflectTokenPrice,
        uint256 _reflectTokenAuditPrice,
        uint256 _bnbToCrxRatioBP
    ) {
        _paymentToken.balanceOf(address(this)); //will fail if wrong token address is passed
        paymentToken = _paymentToken;
        updatePrices(
            _simpleErc20TokenPrice,
            _simpleErc20TokenAuditPrice,
            _reflectTokenPrice,
            _reflectTokenAuditPrice
        );
        setBnbToCrxRatio(_bnbToCrxRatioBP);
    }

    function setDeployCodeAddresses(
        address _tokenDeployCodeAddress,
        address _rfiTokenDeployCodeAddress
    ) external onlyOwner {
        require(tokenDeployCodeAddress == address(0), "only once");
        require(
            _tokenDeployCodeAddress != address(0) &&
                _rfiTokenDeployCodeAddress != address(0),
            "wrong values"
        );

        tokenDeployCodeAddress = _tokenDeployCodeAddress;
        rfiTokenDeployCodeAddress = _rfiTokenDeployCodeAddress;
    }

    /**
	* @notice Takes payment and deploys ERC20 token with chosen parameters
	* @param _name name of the token to be created
    * @param _symbol symbol of the token to be created
    * @param _totalSupply initial token amount in wei
    * @param _issuer distributor of the tokens, receives the _totalSupply
    * @param _decimals decimals parameter of the ERC20, common value is 18
    * @param _paymentType 0 for native payment,
                         1 for payment in CRX tokens
                         check the prices with defaultPaymentAmount() and CRXPaymentAmount()
    * @param _withAudit flag for audit
    * @return address oft the created token
	*/
    function createToken(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        uint8 _decimals,
        address _issuer,
        PaymentType _paymentType,
        bool _withAudit
    ) external payable returns (address) {
        uint256 paymentAmount = getPrice(TokenType.SIMPLE_ERC20, _withAudit);
        _processPayment(_paymentType, paymentAmount);

        address tokenAddress = _createToken(
            _name,
            _symbol,
            _totalSupply,
            _decimals,
            _issuer
        );
        emit TokenCreated(
            _symbol,
            tokenAddress,
            _issuer,
            TokenType.SIMPLE_ERC20,
            _withAudit
        );
        return tokenAddress;
    }

    /**
	* @notice Takes payment and deploys liquify RFI token with chosen parameters
	* @param _name name of the token to be created
    * @param _symbol symbol of the token to be created
    * @param _decimals decimals parameter of the ERC20, common value is 18
    * @param _flags boolean parameters:
                    [0] burning fee on transfers, cannot be updated after creation
                    [1] marketing fee on transfers, cannot be updated after creation
                    [2] referrals fee on transfers, cannot be updated after creation
                    [3] autoLiquify flag, updatable by the owner after creation
    * @param _feesAndLimits uint256 parameters:
                    [0] totalSupply, initial token amount in wei
                    [1] taxFee on transfers, updatable within limits after creation
                    [2] liquidityFee on transfers, updatable within limits after creation
                    [3] burnFee on transfers, only if _flags[0] is set
                    [4] marketingFee on transfers, only if _flags[1] is set
                    [5] referralFee on transfers, only if _flags[2] is set
                    [6] feeLimit of total fees, cannot be updated after creation
                    [7] liquidityThreshold, min amount of tokens to be swapped on transfers
                    [8] txLimit, max amount of transfer for non-privileged users
    * @param _addresses address parameters:
                    [0] owner, receives totalSupply and controls the parameters
                    [1] Uniswap-like router for autoLiquify on transfers, must have WETH() function
                    [2] liquidityAddress to accumulate LP tokens from autoLiquify process
                    [3] marketingAddress, only if _flags[1] is set
    * @param _paymentType 0 for native payment,
                         1 for payment in CRX tokens
                         check the prices with defaultPaymentAmount() and CRXPaymentAmount()
    * @param _withAudit flag for audit
    * @return address of the created token
	*/
    function createRFIToken(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        bool[4] memory _flags,
        uint256[9] memory _feesAndLimits,
        address[4] memory _addresses,
        PaymentType _paymentType,
        bool _withAudit
    ) public payable returns (address) {
        uint256 paymentAmount = getPrice(TokenType.REFLECT_TOKEN, _withAudit);
        _processPayment(_paymentType, paymentAmount);

        (address tokenAddress, address issuer) = _createRFIToken(
            _name,
            _symbol,
            _decimals,
            _flags,
            _feesAndLimits,
            _addresses
        );
        emit TokenCreated(
            _symbol,
            tokenAddress,
            issuer,
            TokenType.REFLECT_TOKEN,
            _withAudit
        );
        return tokenAddress;
    }

    function _createToken(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        uint8 _decimals,
        address issuer
    ) internal returns (address) {
        (bool success, bytes memory data) = tokenDeployCodeAddress.delegatecall(
            abi.encodeWithSelector(
                TokenDeployCode.deployNewToken.selector,
                _name,
                _symbol,
                _totalSupply,
                _decimals,
                issuer
            )
        );
        require(success, "deploy failed");
        return abi.decode(data, (address));
    }

    function _createRFIToken(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        bool[4] memory _flags,
        uint256[9] memory _feesAndLimits,
        address[4] memory _addresses
    ) internal returns (address, address) {
        if (_addresses[0] == address(0)) {
            _addresses[0] = msg.sender;
        }

        (bool success, bytes memory data) = rfiTokenDeployCodeAddress.delegatecall(
            abi.encodeWithSelector(
                RfiTokenDeployCode.deployNewToken.selector,
                _name,
                _symbol,
                _decimals,
                _flags,
                _feesAndLimits,
                _addresses
            )
        );
        require(success, "deploy failed");
        return (abi.decode(data, (address)), _addresses[0]);
    }

    function _processPayment(PaymentType paymentType, uint256 paymentAmount)
        internal
    {
        if (paymentType == PaymentType.NATIVE) {
            require(paymentAmount == msg.value, "insufficient payment amount");
        } else if (paymentType == PaymentType.CRX) {
            require(0 == msg.value, "unacceptable payment");
            paymentToken.safeTransferFrom(
                msg.sender,
                address(this),
                (paymentAmount * bnbToCrxRatioBP) / 1e4
            );
        } else {
            revert("wrong payment type");
        }
        emit PaymentReceived(msg.sender, paymentAmount, paymentType);
    }

    /**
     * @notice Get price in native cryptocurrency for token creation
     * @param _tokenType 0 for simple ERC20 token, 1 for reflect token
     * @param _withAudit true if audit is required
     * @return address of the created token
     */
    function getPrice(TokenType _tokenType, bool _withAudit)
        public
        view
        returns (uint256)
    {
        uint256 price;
        if (_tokenType == TokenType.SIMPLE_ERC20) {
            price = simpleErc20TokenPrice;
            if (_withAudit) {
                price += simpleErc20TokenAuditPrice;
            }
        } else if (_tokenType == TokenType.REFLECT_TOKEN) {
            price = reflectTokenPrice;
            if (_withAudit) {
                price += reflectTokenAuditPrice;
            }
        } else {
            revert("wrong token type");
        }
        return price;
    }

    /**
     * @notice Updates prices in native and CRX and customize the price ration between ERC20 and RFI tokens
     * @param _simpleErc20TokenPrice amount of ETH/BNB to be paid for ERC20 token
     * @param _simpleErc20TokenAuditPrice amount of ETH/BNB to be paid for ERC20 token audit
     * @param _reflectTokenPrice amount of ETH/BNB to be paid for reflect token
     * @param _reflectTokenAuditPrice amount of ETH/BNB to be paid for reflect token audit
     */
    function updatePrices(
        uint256 _simpleErc20TokenPrice,
        uint256 _simpleErc20TokenAuditPrice,
        uint256 _reflectTokenPrice,
        uint256 _reflectTokenAuditPrice
    ) public onlyOwner {
        require(
            _simpleErc20TokenPrice > 0 && _simpleErc20TokenPrice < 1e21,
            "bad price"
        );
        require(
            _simpleErc20TokenAuditPrice > 0 &&
                _simpleErc20TokenAuditPrice < 1e21,
            "bad price"
        );
        require(
            _reflectTokenPrice > 0 && _reflectTokenPrice < 1e21,
            "bad price"
        );
        require(
            _reflectTokenAuditPrice > 0 && _reflectTokenAuditPrice < 1e21,
            "bad price"
        );

        simpleErc20TokenPrice = _simpleErc20TokenPrice;
        simpleErc20TokenAuditPrice = _simpleErc20TokenAuditPrice;
        reflectTokenPrice = _reflectTokenPrice;
        reflectTokenAuditPrice = _reflectTokenAuditPrice;

        emit PriceUpdated(
            _simpleErc20TokenPrice,
            _simpleErc20TokenAuditPrice,
            _reflectTokenPrice,
            _reflectTokenAuditPrice
        );
    }

    /**
     * @notice Set BNB/CRX ratio for payments in CRX calculations
     * @param _bnbToCrxRatioBP BNB to CRX ratio for payments multiplied by 1000, i.e. 1:1 BNB/CRX ratio is _bnbToCrxRatioBP = 1000
     */
    function setBnbToCrxRatio(uint256 _bnbToCrxRatioBP) public onlyOwner {
        bnbToCrxRatioBP = _bnbToCrxRatioBP;
        emit BnbToCrxRatioUpdated(_bnbToCrxRatioBP);
    }

    function collectPayments(address receiver, address token)
        external
        onlyOwner
        returns (uint256 balance)
    {
        require(receiver != address(0), "wrong address");

        if (token == address(0)) {
            balance = address(this).balance;
            (bool success, ) = receiver.call{value: balance}("");
            require(success, "transfer eth failed");
            return balance;
        }

        balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(receiver, balance);
    }
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

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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

/*

        ░█████╗░██████╗░██╗░░░██╗██████╗░████████╗███████╗██╗░░██╗
        ██╔══██╗██╔══██╗╚██╗░██╔╝██╔══██╗╚══██╔══╝██╔════╝╚██╗██╔╝
        ██║░░╚═╝██████╔╝░╚████╔╝░██████╔╝░░░██║░░░█████╗░░░╚███╔╝░
        ██║░░██╗██╔══██╗░░╚██╔╝░░██╔═══╝░░░░██║░░░██╔══╝░░░██╔██╗░
        ╚█████╔╝██║░░██║░░░██║░░░██║░░░░░░░░██║░░░███████╗██╔╝╚██╗
        ░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░░░░╚═╝░░░╚══════╝╚═╝░░╚═╝

 Factory to deploy ERC20 tokens

 • website:                           https://cryptexlock.me
 • medium:                            https://medium.com/cryptex-locker
 • Telegram Announcements Channel:    https://t.me/CryptExAnnouncements
 • Telegram Main Channel:             https://t.me/cryptexlocker
 • Twitter Page:                      https://twitter.com/ExLocker
 • Reddit:                            https://www.reddit.com/r/CryptExLocker/

 SPDX-License-Identifier: UNLICENSED

*/

pragma solidity 0.8.4;

import "./Token.sol";

contract TokenDeployCode {
    address public immutable factory;

    constructor(address _factory) {
        factory = _factory;
    }

    function deployNewToken(
        string calldata name,
        string calldata symbol,
        uint256 totalSupply,
        uint8 decimals,
        address issuer
    ) external returns(address) {
        //require(address(this) == factory, "only factory allowed");

        return address(new DefaultToken(
            name,
            symbol,
            totalSupply,
            decimals,
            issuer
        ));
    }
}

/*

        ░█████╗░██████╗░██╗░░░██╗██████╗░████████╗███████╗██╗░░██╗
        ██╔══██╗██╔══██╗╚██╗░██╔╝██╔══██╗╚══██╔══╝██╔════╝╚██╗██╔╝
        ██║░░╚═╝██████╔╝░╚████╔╝░██████╔╝░░░██║░░░█████╗░░░╚███╔╝░
        ██║░░██╗██╔══██╗░░╚██╔╝░░██╔═══╝░░░░██║░░░██╔══╝░░░██╔██╗░
        ╚█████╔╝██║░░██║░░░██║░░░██║░░░░░░░░██║░░░███████╗██╔╝╚██╗
        ░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░░░░╚═╝░░░╚══════╝╚═╝░░╚═╝

 Factory to deploy RFI tokens

 • website:                           https://cryptexlock.me
 • medium:                            https://medium.com/cryptex-locker
 • Telegram Announcements Channel:    https://t.me/CryptExAnnouncements
 • Telegram Main Channel:             https://t.me/cryptexlocker
 • Twitter Page:                      https://twitter.com/ExLocker
 • Reddit:                            https://www.reddit.com/r/CryptExLocker/

 SPDX-License-Identifier: UNLICENSED

*/

pragma solidity 0.8.4;

import "./reflect/ReflectToken.sol";

contract RfiTokenDeployCode {
    address public immutable factory;

    constructor(address _factory) {
        factory = _factory;
    }

    function deployNewToken(
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        bool[4] calldata flags,
        uint256[9] calldata feesAndLimits,
        address[4] calldata addresses
    ) external returns(address) {
        //require(address(this) == factory, "only factory allowed");

        return address(new ReflectToken(
            name,
            symbol,
            decimals,
            flags,
            feesAndLimits,
            addresses
        ));
    }
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

/*

        ░█████╗░██████╗░██╗░░░██╗██████╗░████████╗███████╗██╗░░██╗
        ██╔══██╗██╔══██╗╚██╗░██╔╝██╔══██╗╚══██╔══╝██╔════╝╚██╗██╔╝
        ██║░░╚═╝██████╔╝░╚████╔╝░██████╔╝░░░██║░░░█████╗░░░╚███╔╝░
        ██║░░██╗██╔══██╗░░╚██╔╝░░██╔═══╝░░░░██║░░░██╔══╝░░░██╔██╗░
        ╚█████╔╝██║░░██║░░░██║░░░██║░░░░░░░░██║░░░███████╗██╔╝╚██╗
        ░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░░░░╚═╝░░░╚══════╝╚═╝░░╚═╝

 Token is created with CryptEx token constructor.

 • website:                           https://cryptexlock.me
 • medium:                            https://medium.com/cryptex-locker
 • Telegram Announcements Channel:    https://t.me/CryptExAnnouncements
 • Telegram Main Channel:             https://t.me/cryptexlocker
 • Twitter Page:                      https://twitter.com/ExLocker
 • Reddit:                            https://www.reddit.com/r/CryptExLocker/

 SPDX-License-Identifier: UNLICENSED

*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DefaultToken is ERC20 {
    uint8 private _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_,
        address _receiver
    ) ERC20(name_, symbol_) {
        _decimals = decimals_;
        _mint(_receiver, totalSupply_);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}

/*

        ░█████╗░██████╗░██╗░░░██╗██████╗░████████╗███████╗██╗░░██╗
        ██╔══██╗██╔══██╗╚██╗░██╔╝██╔══██╗╚══██╔══╝██╔════╝╚██╗██╔╝
        ██║░░╚═╝██████╔╝░╚████╔╝░██████╔╝░░░██║░░░█████╗░░░╚███╔╝░
        ██║░░██╗██╔══██╗░░╚██╔╝░░██╔═══╝░░░░██║░░░██╔══╝░░░██╔██╗░
        ╚█████╔╝██║░░██║░░░██║░░░██║░░░░░░░░██║░░░███████╗██╔╝╚██╗
        ░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░░░░╚═╝░░░╚══════╝╚═╝░░╚═╝

 Token is created with CryptEx token constructor, uses Reflect.finance model.

 • website:                           https://cryptexlock.me
 • medium:                            https://medium.com/cryptex-locker
 • Telegram Announcements Channel:    https://t.me/CryptExAnnouncements
 • Telegram Main Channel:             https://t.me/cryptexlocker
 • Twitter Page:                      https://twitter.com/ExLocker
 • Reddit:                            https://www.reddit.com/r/CryptExLocker/

 SPDX-License-Identifier: UNLICENSED

*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract ReflectToken is IERC20, Ownable {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping(address => uint256) private _reflections;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public excludedFromFee;
    mapping(address => bool) public excludedFromReward;
    uint256 private _totalRatedBalance;
    uint256 private _totalRatedReflection;

    uint256 public totalFees;
    uint256 private _totalSupply;
    uint256 private _totalReflection;

    bool public immutable BRN_ENABLED;
    bool public immutable MRK_ENABLED;
    bool public immutable REF_ENABLED;

    uint256 public taxFee;
    uint256 public liqFee;
    uint256 public brnFee;
    uint256 public mrkFee;
    uint256 public refFee;
    uint256 private immutable feeLimit; // up to FLOAT_FACTOR / 2
    uint256 private constant TX_FACTOR = 1e3; // txLimit <= totalSupply / TX_FACTOR
    uint256 private constant FLOAT_FACTOR = 1e4;
    uint256 private constant MAX = type(uint256).max;

    IUniswapV2Router02 public swapRouter;
    mapping(address => bool) public swapPairs;
    address private swapWETH;

    bool private _liqInProgress;
    bool public liqStatus;
    uint256 private liqThreshold;
    uint256 public txLimit;
    address public liquidityAddress;
    address public marketingAddress;
    mapping(address => address) private referrals;

    event UpdateFees(
        uint256 newTaxFee,
        uint256 newLiqFee,
        uint256 newBrnFee,
        uint256 newMrkFee,
        uint256 newRefFee
    );
    event UpdateTxLimit(uint256 newTxLimit);
    event UpdateLiqThreshold(uint256 newLiqThreshold);
    event UpdateLiqStatus(bool newLiqStatus);
    event UpdateLiquidityAddress(address newLiquidityAddress);
    event UpdateMarketingAddress(address newMarketingkAddress);
    event UpdateSwapRouter(address newRouter, address newPair);
    event LiquidityAdded(
        uint256 indexed tokensToLiqudity,
        uint256 indexed bnbToLiquidity
    );
    event ReferralSet(address indexed referrer, address referee);
    event SwapPairUpdated(address indexed pair, bool isMarketPair);

    modifier lockTheSwap() {
        _liqInProgress = true;
        _;
        _liqInProgress = false;
    }

    /**
    * @param flags_ boolean parameters:
                    [0] burning fee on transfers, cannot be updated after creation
                    [1] marketing fee on transfers, cannot be updated after creation
                    [2] referrals fee on transfers, cannot be updated after creation
                    [3] autoLiquify flag, updatable by the owner after creation
    * @param feesAndLimits_ uint256 parameters:
                    [0] totalSupply, initial token amount in wei
                    [1] taxFee on transfers, updatable within limits after creation
                    [2] liquidityFee on transfers, updatable within limits after creation
                    [3] burnFee on transfers, only if _flags[0] is set
                    [4] marketingFee on transfers, only if _flags[1] is set
                    [5] referralFee on transfers, only if _flags[2] is set
                    [6] feeLimit of total fees, cannot be updated after creation
                    [7] liquidityThreshold, min amount of tokens to be swapped on transfers
                    [8] txLimit, max amount of transfer for non-privileged users
    * @param addresses_ address parameters:
                    [0] owner, receives totalSupply and controls the parameters
                    [1] Uniswap-like router for autoLiquify on transfers, must have WETH() function
                    [2] liquidityAddress to accumulate LP tokens from autoLiquify process
                    [3] marketingAddress, only if _flags[1] is set
    */
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        bool[4] memory flags_,
        uint256[9] memory feesAndLimits_,
        address[4] memory addresses_
    ) {
        require(bytes(name_).length != 0, "Empty name");
        require(bytes(symbol_).length != 0, "Empty symbol");
        require(feesAndLimits_[0] != 0, "Zero total supply");
        require(addresses_[1] != address(0), "Zero Router address");

        require(feesAndLimits_[6] <= FLOAT_FACTOR / 2, "Wrong limit");
        require(
            feesAndLimits_[1] +
                feesAndLimits_[2] +
                feesAndLimits_[3] +
                feesAndLimits_[4] +
                feesAndLimits_[5] <=
                feesAndLimits_[6],
            "Fee's too high"
        );

        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;

        _totalSupply = feesAndLimits_[0];
        _totalReflection = MAX - (MAX % feesAndLimits_[0]);
        _totalRatedBalance = feesAndLimits_[0];
        _totalRatedReflection = MAX - (MAX % feesAndLimits_[0]);
        _reflections[addresses_[0]] = _totalReflection;

        BRN_ENABLED = flags_[0];
        MRK_ENABLED = flags_[1];
        REF_ENABLED = flags_[2];

        taxFee = feesAndLimits_[1];
        liqFee = feesAndLimits_[2];
        liquidityAddress = addresses_[2];
        liqStatus = flags_[3];
        feeLimit = feesAndLimits_[6];

        if (flags_[0]) {
            brnFee = feesAndLimits_[3];
        }
        if (flags_[1]) {
            mrkFee = feesAndLimits_[4];
            marketingAddress = addresses_[3];
        }
        if (flags_[2]) {
            refFee = feesAndLimits_[5];
            if (!flags_[1]) marketingAddress = addresses_[3];
        }

        require(
            feesAndLimits_[8] <= feesAndLimits_[0] / TX_FACTOR,
            "txLimit is too high"
        );
        require(
            feesAndLimits_[7] <= feesAndLimits_[8],
            "liqThreshold is too high"
        );
        txLimit = feesAndLimits_[8];
        liqThreshold = feesAndLimits_[7];

        swapWETH = IUniswapV2Router02(addresses_[1]).WETH();
        require(swapWETH != address(0), "Wrong router");
        address _swapPair = IUniswapV2Factory(
            IUniswapV2Router02(addresses_[1]).factory()
        ).createPair(address(this), swapWETH);
        _updateSwapPair(_swapPair, true);
        swapRouter = IUniswapV2Router02(addresses_[1]);
        excludeFromReward(_swapPair);
        excludeFromFee(addresses_[0]);

        transferOwnership(addresses_[0]);
        emit Transfer(address(0), addresses_[0], feesAndLimits_[0]);
        emit UpdateFees(
            feesAndLimits_[1],
            feesAndLimits_[2],
            feesAndLimits_[3],
            feesAndLimits_[4],
            feesAndLimits_[5]
        );
        emit UpdateTxLimit(feesAndLimits_[8]);
        emit UpdateLiqThreshold(feesAndLimits_[7]);
        emit UpdateLiqStatus(flags_[3]);
        emit UpdateLiquidityAddress(addresses_[2]);
        emit UpdateMarketingAddress(addresses_[3]);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function getOwner() public view returns (address) {
        return owner();
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (excludedFromReward[account]) return _balances[account];
        return _reflections[account] / _getRate();
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner_, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner_][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(
        address owner_,
        address spender,
        uint256 amount
    ) private {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function distribute(uint256 amount) external {
        require(!excludedFromReward[msg.sender], "Not for excluded");
        uint256 rAmount = amount * _getRate();
        _reflections[msg.sender] -= amount;
        _totalReflection -= rAmount;
        totalFees += amount;
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!excludedFromReward[account], "Already excluded");

        uint256 currentReflection = _reflections[account];
        if (currentReflection > 0) {
            uint256 currentBalance = currentReflection / _getRate();
            _balances[account] = currentBalance;
            _totalRatedBalance -= currentBalance;
            _totalRatedReflection -= currentReflection;

            _reflections[account] = 0;
        }

        excludedFromReward[account] = true;
    }

    function includeInReward(address account) external onlyOwner {
        require(excludedFromReward[account], "Not excluded");

        uint256 currentBalance = _balances[account];
        if (currentBalance > 0) {
            uint256 currentReflection = currentBalance * _getRate();

            _totalRatedBalance += currentBalance;
            _totalRatedReflection += currentReflection;
            _reflections[account] = currentReflection;

            _balances[account] = 0;
        }

        excludedFromReward[account] = false;
    }

    function excludeFromFee(address account) public onlyOwner {
        require(!swapPairs[account], "Not for Pair address");
        excludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner {
        delete excludedFromFee[account];
    }

    function setFee(
        uint256 newTaxFee,
        uint256 newLiqFee,
        uint256 newBrnFee,
        uint256 newMrkFee,
        uint256 newRefFee
    ) external onlyOwner {
        require(
            newTaxFee + newLiqFee + newBrnFee + newMrkFee + newRefFee <=
                feeLimit,
            "Fee's too high"
        );
        taxFee = newTaxFee;
        liqFee = newLiqFee;

        if (BRN_ENABLED) {
            brnFee = newBrnFee;
        }
        if (MRK_ENABLED) {
            mrkFee = newMrkFee;
        }
        if (REF_ENABLED) {
            refFee = newRefFee;
        }

        emit UpdateFees(taxFee, liqFee, brnFee, mrkFee, refFee);
    }

    function setLiquifyStatus(bool newStatus) external onlyOwner {
        liqStatus = newStatus;

        emit UpdateLiqStatus(newStatus);
    }

    function setLiquifyThreshold(uint256 newThreshold) external onlyOwner {
        require(newThreshold <= txLimit, "Threshold exceeds txLimit");
        liqThreshold = newThreshold;

        emit UpdateLiqThreshold(newThreshold);
    }

    function setLiquidyAddress(address newLiquidityAddress) external onlyOwner {
        liquidityAddress = newLiquidityAddress;

        emit UpdateLiquidityAddress(newLiquidityAddress);
    }

    function setMarketingAddress(address newMarketingAddress)
        external
        onlyOwner
    {
        require(MRK_ENABLED, "Denied");
        require(newMarketingAddress != address(0), "Zero address");
        marketingAddress = newMarketingAddress;

        emit UpdateMarketingAddress(newMarketingAddress);
    }

    function setReferral(address referralAddress) external {
        require(REF_ENABLED, "Denied");
        referrals[msg.sender] = referralAddress;

        emit ReferralSet(referralAddress, msg.sender);
    }

    function setTxLimit(uint256 newTxLimit) external onlyOwner {
        require(newTxLimit >= liqThreshold, "txLimit is below liqThreshold");
        require(newTxLimit <= _totalSupply / TX_FACTOR, "txLimit is too high");
        txLimit = newTxLimit;

        emit UpdateTxLimit(newTxLimit);
    }

    function setSwapRouter(IUniswapV2Router02 newRouter) external onlyOwner {
        address newPair = IUniswapV2Factory(newRouter.factory()).getPair(
            address(this),
            newRouter.WETH()
        );
        require(newPair != address(0), "Pair doesn't exist");
        swapRouter = newRouter;
        _updateSwapPair(newPair, true);
        swapWETH = newRouter.WETH();
        require(swapWETH != address(0), "Wrong router");
        excludeFromReward(newPair);

        emit UpdateSwapRouter(address(newRouter), newPair);
    }

    function updateSwapPair(address pair, bool isPair) external onlyOwner {
        _updateSwapPair(pair, isPair);
    }

    function _updateSwapPair(address pair, bool isPair) internal {
        require(swapPairs[pair] != isPair, "Pair already set");
        swapPairs[pair] = isPair;

        emit SwapPairUpdated(pair, isPair);
    }

    function _getRate() public view returns (uint256) {
        uint256 totalRatedBalance_ = _totalRatedBalance;

        if (totalRatedBalance_ == 0) return (_totalReflection / _totalSupply);
        return (_totalRatedReflection / totalRatedBalance_);
    }

    function _takeLiquidity(uint256 amount, uint256 rate) private {
        uint256 rAmount = amount * rate;

        if (excludedFromReward[address(this)]) {
            _balances[address(this)] += amount;
            _totalRatedBalance -= amount;
            _totalRatedReflection -= rAmount;
            return;
        }
        _reflections[address(this)] += rAmount;
    }

    function _getFeeValues(uint256 amount, bool takeFee)
        private
        view
        returns (
            uint256 _tax,
            uint256 _liq,
            uint256 _brn,
            uint256 _mrk,
            uint256 _ref
        )
    {
        if (takeFee) {
            _tax = (amount * taxFee) / FLOAT_FACTOR;
            _liq = (amount * liqFee) / FLOAT_FACTOR;
            if (BRN_ENABLED) _brn = (amount * brnFee) / FLOAT_FACTOR;
            if (MRK_ENABLED) _mrk = (amount * mrkFee) / FLOAT_FACTOR;
            if (REF_ENABLED) _ref = (amount * refFee) / FLOAT_FACTOR;
        }
    }

    function _reflectFee(
        uint256 amount,
        uint256 rate,
        bool takeFee
    ) private returns (uint256, uint256) {
        (
            uint256 tax,
            uint256 liq,
            uint256 brn,
            uint256 mrk,
            uint256 ref
        ) = _getFeeValues(amount, takeFee);
        _totalReflection -= tax * rate;
        totalFees += tax;

        if (BRN_ENABLED) {
            _totalSupply -= brn;
            _totalReflection -= brn * rate;
        }
        if (REF_ENABLED) {
            uint256 mrk_;
            if (MRK_ENABLED) mrk_ = mrk;
            address referralAddress = referrals[msg.sender];
            if (referralAddress == address(0)) {
                _takeFee(marketingAddress, mrk_ + ref, rate);
            } else {
                _takeFee(marketingAddress, mrk_, rate);
                _takeFee(msg.sender, ref / 2, rate);
                _takeFee(referralAddress, ref - ref / 2, rate);
            }
        } else if (MRK_ENABLED) {
            _takeFee(marketingAddress, mrk, rate);
        }

        return ((tax + liq + brn + mrk + ref), liq);
    }

    function _takeFee(
        address recipient,
        uint256 amount,
        uint256 rate
    ) private {
        if (amount == 0) return;
        uint256 rAmount = amount * rate;

        if (excludedFromReward[recipient]) {
            _balances[recipient] += amount;
            _totalRatedBalance -= amount;
            _totalRatedReflection -= rAmount;
            return;
        }
        _reflections[recipient] += rAmount;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(to != address(0), "ERC20: transfer to the zero address");
        address owner_ = owner();
        if (from != owner_ && to != owner_)
            require(amount <= txLimit, "txLimit exceeded");

        uint256 _liqThreshold = liqThreshold;
        bool liquifyReady = (balanceOf(address(this)) >= _liqThreshold &&
            !_liqInProgress &&
            liqStatus &&
            !swapPairs[from]);
        if (liquifyReady) _swapAndLiquify(_liqThreshold);

        uint256 rate = _getRate();
        bool takeFee = !(excludedFromFee[from] || excludedFromFee[to]);
        (uint256 feesAmount, uint256 liqAmount) = _reflectFee(
            amount,
            rate,
            takeFee
        );
        _takeLiquidity(liqAmount, rate);
        _updateBalances(from, to, amount, rate, feesAmount);
    }

    function _updateBalances(
        address from,
        address to,
        uint256 amount,
        uint256 rate,
        uint256 fees
    ) private {
        uint256 rAmount = amount * rate;
        uint256 transferAmount = amount - fees;
        uint256 rTransferAmount = rAmount - fees * rate;

        if (excludedFromReward[from]) {
            _balances[from] -= amount;
            _totalRatedBalance += amount;
            _totalRatedReflection += rAmount;
        } else {
            _reflections[from] -= rAmount;
        }
        if (excludedFromReward[to]) {
            _balances[to] += transferAmount;
            _totalRatedBalance -= transferAmount;
            _totalRatedReflection -= rTransferAmount;
        } else {
            _reflections[to] += rTransferAmount;
        }
    }

    function _swapAndLiquify(uint256 amount) internal lockTheSwap {
        uint256 half = amount / 2;
        amount -= half;

        uint256 balance = address(this).balance;
        _swapTokensForBNB(half);

        emit LiquidityAdded(amount, balance);
    }

    function _swapTokensForBNB(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swapWETH;

        _approve(address(this), address(swapRouter), tokenAmount);
        swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(swapRouter), tokenAmount);
        swapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            liquidityAddress,
            block.timestamp
        );
    }

    receive() external payable {
        require(_liqInProgress, "Only for swaps");
    }

    function recoverLockedTokens(address receiver, address token)
        external
        onlyOwner
        returns (uint256 balance)
    {
        require(token != address(this), "Only 3rd party");
        if (token == address(0)) {
            balance = address(this).balance;
            payable(receiver).transfer(balance);
            return balance;
        }
        balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(receiver, balance);
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

