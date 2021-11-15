// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";


interface Erc20 {
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
}

interface CEth {
    function mint() external payable;

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);
}

interface CErc20 {
    function mint(uint256) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);
}



contract Paytr{
    event MyLog(string, uint256);
    event MyOwnLog(string, uint);
    event PaymentInfo(address sender, uint256 amount, bytes paymentReference, address supplier, uint256 tokenAddress ); //To be added for Request: address to, invoice amount, payment reference, supplier, interest amount
    event PaymentInfoErc20(address tokenAddress, address supplier, uint256 amount, bytes indexed paymentReference);
    event PaymentInfoErc20WithFee(address tokenAddress, address supplier, uint256 amount, bytes indexed paymentReference, uint256 feeAmount, address feeAddress);
    event PayOutInfoErc20(address sender, uint256 amount, bytes indexed paymentReference, uint dueDate, address supplier, address tokenAddress);
    


    Erc20 daitoken;
    Erc20 USDCtoken;

    
    address sender;
    uint transactionDate;
    uint public transactionID;
    uint intrest;
    address tokenAddress;
    address addressPaytr = address(this);
    uint supplyRate;
    
    
    struct Invoice {
        uint amount;
        address sender;
        address supplier;
        uint transactionDate;
        uint dueDate;
        bytes paymentReference;
    }

    struct InvoiceErc20 {
        uint amount;
        address sender;
        address supplier;
        uint transactionDate;
        uint dueDate;
        bytes paymentReference;
        address tokenAddress;
    }
  
    struct dueInvoice {
        uint amount;
        address sender;
        address supplier;
        uint transactionDate;
        uint dueDate;
        bytes paymentReference;
    }
    
    struct dueInvoiceErc20 {
        uint amount;
        address sender;
        address supplier;
        uint transactionDate;
        uint dueDate;
        bytes paymentReference;
        address tokenAddress;
    }
   

   mapping(uint => Invoice) public userInvoices;
   Invoice[] public invoices;
   dueInvoice[] public dueInvoices;

   mapping (uint => InvoiceErc20) public userInvoicesErc20;
   InvoiceErc20[] public invoicesErc20;
   dueInvoiceErc20[] public dueInvoicesErc20;

   constructor() public {
        transactionID = 0;
        daitoken = Erc20(0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa); //Rinkeby DAI contract address
        USDCtoken = Erc20(0x4DBCdF9B62e891a7cec5A2568C3F4FAF9E8Abe2b); //Rinkeby USDC contract address
        }

     

    function supplyEthToCompound(address payable _cEtherContract, uint amount, address supplier, uint dueDate, bytes memory paymentReference)
        public
        payable
        returns (bool)
    {
        // Create a reference to the corresponding cToken contract
        CEth cToken = CEth(_cEtherContract);

        // Amount of current exchange rate from cToken to underlying
        uint256 exchangeRateMantissa = cToken.exchangeRateCurrent();
        emit MyLog("Exchange Rate (scaled up by 1e18): ", exchangeRateMantissa);

        // Amount added to you supply balance this block
        // uint256 supplyRateMantissa = cToken.supplyRatePerBlock();
        uint256 supplyBlockNumber = block.number;
        emit MyLog("Block number while supplying is: ", supplyBlockNumber);

        transactionDate = block.timestamp;
        sender = msg.sender;
        dueDate = block.timestamp + (dueDate * 1 seconds);
        userInvoices[transactionID] = Invoice(amount, sender, supplier, transactionDate, dueDate, paymentReference);
        transactionID ++;
        Invoice memory invoiceData = Invoice(amount, sender, supplier, transactionDate, dueDate, paymentReference);
        invoices.push(invoiceData);

        cToken.mint{value:msg.value,gas:250000}();
        return true;

        

                
    }

  
    function supplyErc20ToCompound(
        address _erc20Contract,
        address _cErc20Contract,
        uint256 amount,
        address supplier,
        uint dueDate,
        bytes memory paymentReference
        ) public returns (uint) {
    
        // Create a reference to the underlying asset contract, like DAI.
        Erc20 underlying = Erc20(_erc20Contract);

        // Create a reference to the corresponding cToken contract, like cDAI
        CErc20 cToken = CErc20(_cErc20Contract);

        // Approve transfer on the ERC20 contract
        underlying.approve(_cErc20Contract, amount);

        transactionDate = block.timestamp;
        sender = msg.sender;
        dueDate = block.timestamp + (dueDate * 1 seconds);
        tokenAddress = _erc20Contract;
        userInvoicesErc20[transactionID] = InvoiceErc20(amount, sender, supplier, transactionDate, dueDate, paymentReference, tokenAddress );
        transactionID ++;
        InvoiceErc20 memory invoiceDataErc20 = InvoiceErc20(amount, sender, supplier, transactionDate, dueDate, paymentReference, tokenAddress);
        invoicesErc20.push(invoiceDataErc20);
        //address sender, uint256 amount, bytes paymentReference, address supplier, address tokenAddress);
        emit PaymentInfoErc20(tokenAddress, supplier, amount, paymentReference);

        // Mint cTokens
        uint mintResult = cToken.mint(amount);
        return mintResult;
    }

    function supplyErc20ToCompoundWithFee(
        address _erc20Contract,
        address _cErc20Contract,
        uint256 amount,
        address supplier,
        uint dueDate,
        bytes memory paymentReference,
        uint256 feeAmount,
        address feeReceiver
        ) public returns (uint) {
    
        // Create a reference to the underlying asset contract, like DAI.
        Erc20 underlying = Erc20(_erc20Contract);

        // Create a reference to the corresponding cToken contract, like cDAI
        CErc20 cToken = CErc20(_cErc20Contract);

        // Approve transfer on the ERC20 contract
        underlying.approve(_cErc20Contract, amount);

        transactionDate = block.timestamp;
        sender = msg.sender;
        dueDate = block.timestamp + (dueDate * 1 seconds);
        tokenAddress = _erc20Contract;
        feeAmount = (amount /1000 * 5);
        feeReceiver = 0xF4255c5e53a08f72b0573D1b8905C5a50aA9c2De;
        address payable feeAddress = payable (feeReceiver);
        userInvoicesErc20[transactionID] = InvoiceErc20(amount, sender, supplier, transactionDate, dueDate, paymentReference, tokenAddress );
        transactionID ++;
        InvoiceErc20 memory invoiceDataErc20 = InvoiceErc20(amount, sender, supplier, transactionDate, dueDate, paymentReference, tokenAddress);
        invoicesErc20.push(invoiceDataErc20);
        feeAddress.transfer(feeAmount);
        //address sender, uint256 amount, bytes paymentReference, address supplier, address tokenAddress);
        emit PaymentInfoErc20WithFee(tokenAddress, supplier, amount, paymentReference, feeAmount, feeAddress );

        // Mint cTokens
        uint mintResult = cToken.mint(amount);
        return mintResult;
    }

    function createDueListAndPay() public payable {
        //build the list of due invoices:
        for (uint i = 0; i < invoices.length; i++) {
            
             if (block.timestamp >= invoices[i].dueDate) {
                uint amount = invoices[i].amount;
                address sender = invoices[i].sender;
                address supplier = invoices[i].supplier;
                uint transactionDate = invoices[i].transactionDate;
                uint dueDate = invoices[i].dueDate;
                bytes memory paymentReference = invoices[i].paymentReference;
                
                dueInvoice memory dueList = dueInvoice(amount, sender, supplier, transactionDate, dueDate, paymentReference);
                dueInvoices.push(dueList);
                delete invoices[i];
                
            }
        
        }
        //loop the array of due invoices and pay everyone:
        uint myfee = 0.000000005 ether;
        uint interest = 0.00001 ether;
        
        
        for (uint i = 0; i < dueInvoices.length; i++) {
            if (dueInvoices[i].supplier != 0x0000000000000000000000000000000000000000) {
                address payable supplierToPay = payable(dueInvoices[i].supplier);
                address payable senderToPay = payable(dueInvoices[i].sender);
                supplierToPay.transfer(dueInvoices[i].amount);
                senderToPay.transfer(interest - myfee);
                //address sender, invoice amount, payment reference, supplier, interest amount
                emit PaymentInfo(dueInvoices[i].sender, dueInvoices[i].amount, dueInvoices[i].paymentReference, dueInvoices[i].supplier, interest );
                delete dueInvoices[i];
            }
            
            
        }
        
            
        
        
        
    }

    function createDueListAndPayErc20() public payable {
        //build the list of due invoices:
        for (uint i = 0; i < invoicesErc20.length; i++) {
            
             if (block.timestamp >= invoicesErc20[i].dueDate) {
                uint amount = invoicesErc20[i].amount;
                address sender = invoicesErc20[i].sender;
                address supplier = invoicesErc20[i].supplier;
                uint transactionDate = invoicesErc20[i].transactionDate;
                uint dueDate = invoicesErc20[i].dueDate;
                bytes memory paymentReference = invoicesErc20[i].paymentReference;
                address tokenAddress = invoicesErc20[i].tokenAddress;
                
                dueInvoiceErc20 memory dueListErc20 = dueInvoiceErc20(amount, sender, supplier, transactionDate, dueDate, paymentReference, tokenAddress);
                dueInvoicesErc20.push(dueListErc20);
                delete invoicesErc20[i];
                
            }
        
        }
        //loop the array of due invoices and pay everyone:
        // uint myfee = (amount / 10);
        // uint interest = 0.05;
        
        
        for (uint i = 0; i < dueInvoicesErc20.length; i++) {
            
            if (dueInvoicesErc20[i].supplier != 0x0000000000000000000000000000000000000000) {
                
                address payable supplierToPay = payable(dueInvoicesErc20[i].supplier);
                address payable senderToPay = payable(dueInvoicesErc20[i].sender);
                address payable erc20TokenAddress = payable (dueInvoicesErc20[i].tokenAddress);

                

                (Erc20(dueInvoicesErc20[i].tokenAddress)).transfer(supplierToPay, dueInvoicesErc20[i].amount);
                (Erc20(dueInvoicesErc20[i].tokenAddress)).transfer(senderToPay, (dueInvoicesErc20[i].amount/1000*5) - (dueInvoicesErc20[i].amount/10000*9));
                // supplierToPay.transfer(dueInvoicesErc20[i].amount);
                // senderToPay.transfer((dueInvoicesErc20[i].amount/1000*5) - (dueInvoicesErc20[i].amount/10000*9));
                //address sender, invoice amount, payment reference, supplier, interest amount
                emit PaymentInfoErc20(erc20TokenAddress, dueInvoicesErc20[i].supplier, dueInvoicesErc20[i].amount, dueInvoicesErc20[i].paymentReference);
                delete dueInvoicesErc20[i];
            }
            
            
        }
        
            
        
        
        
    }

    function returnInvoices() public view returns(Invoice[] memory) {
        return invoices;
    }

      function returnDueInvoices() public view returns(dueInvoice[] memory) {
        return dueInvoices;
    }

    function returnInvoicesErc20() public view returns(InvoiceErc20[] memory) {
        return invoicesErc20;
    }

    
      function returnDueInvoicesErc20() public view returns(dueInvoiceErc20[] memory) {
        return dueInvoicesErc20;
    }

    
    function balanceOf() external pure returns (uint256 balance) {
        return balance;
    }

    function redeemCEth(
        // address _suppliersAddress,
        uint256 amount,
        bool redeemType,
        address _cEtherContract
    ) public returns (bool) {
        // Create a reference to the corresponding cToken contract
        CEth cToken = CEth(_cEtherContract);

        // `amount` is scaled up by 1e18 to avoid decimals

        uint256 redeemResult;

        if (redeemType == true) {
            // Retrieve your asset based on a cToken amount
            redeemResult = cToken.redeem(amount);
           
        } else {
            // Retrieve your asset based on an amount of the asset
            redeemResult = cToken.redeemUnderlying(amount);
        }

        uint256 redeemedEth;

        if (redeemType == true) {
            uint exchangeRateMantissa = cToken.exchangeRateCurrent();
            redeemedEth =(amount * exchangeRateMantissa);
        }

        // Error codes are listed here:
        // https://compound.finance/docs/ctokens#ctoken-error-codes
        emit MyOwnLog("ETH redeemed :", redeemedEth);
        

        return true;
    }

    // This is needed to receive ETH when calling `redeemCEth`
    receive() external payable {}

    
    
    function redeemCErc20Tokens(
        uint256 amount,
        bool redeemType,
        address _cErc20Contract
    ) public returns (bool) {
        // Create a reference to the corresponding cToken contract, like cDAI
        CErc20 cToken = CErc20(_cErc20Contract);

        // `amount` is scaled up, see decimal table here:
        // https://compound.finance/docs#protocol-math

        uint256 redeemResult;

        if (redeemType == true) {
            // Retrieve your asset based on a cToken amount
            redeemResult = cToken.redeem(amount);
        } else {
            // Retrieve your asset based on an amount of the asset
            redeemResult = cToken.redeemUnderlying(amount);
        }

        // Error codes are listed here:
        // https://compound.finance/developers/ctokens#ctoken-error-codes
        emit MyLog("If this is not 0, there was an error", redeemResult);

        return true;
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

