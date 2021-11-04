/**
 *Submitted for verification at Etherscan.io on 2021-11-04
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol



pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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

// File: colourstoken.sol


pragma solidity ^0.8.9;





contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply - balanceOf(0x000000000000000000000000000000000000dEaD);
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
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

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

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

    function _approve(address owner, address spender,uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract ColoursGold is ERC20, Ownable {
    constructor() ERC20("ColoursGold", "CGLD") {
        _mint(msg.sender, 5000*1e18);
    }
    
    // 21,000 tokens maximum.
    uint256 constant maxSupply = 21000*1e18;
    
    // Unit of Account
    address public address_cents = 0x0000000000000000000000000000000000000000;  
    
    // Medium of Exchange
    address public address_tokens = 0x0000000000000000000000000000000000000000;        
    
    // Store of Value
    address public address_gold = address(this);             
    
    // Burn Address
    address public constant address_burn = 0x000000000000000000000000000000000000dEaD;      
    
    // Assets: 1 cent, 2 token, 3 gold
    event MintTokens(uint256 amountMinted, uint256 amountBurned, uint8 mintedAsset, uint8 burnedAsset, uint256 timestamp);
    
    // Declare cents address.
    IERC20 cents = IERC20(address_cents);
    function setAddressCents(address centsAddress) public onlyOwner {
        require(address_cents == 0x0000000000000000000000000000000000000000, "ColoursGold: Cents address already set.");
        address_cents = centsAddress;
    }
    
    // Declare tokens address.
    IERC20 tokens = IERC20(address_tokens);
    function setAddressTokens(address tokensAddress) public onlyOwner {
        require(address_tokens == 0x0000000000000000000000000000000000000000, "ColoursGold: Tokens address already set.");
        address_tokens = tokensAddress;
    }
    
    function mintGoldWithCents(uint256 _mintAmount) public onlyOwner {
        // Require number to be > 0.
        require(_mintAmount > 0, "ColoursGold: Can't mint 0.");
        
        // Require total supply of all to be under or equal to max supply.
        require(totalSupplyAll() <= maxSupply, "ColoursGold: Mint amount exceeds max supply.");    
        
        // Check if wallet has enough to burn.
        uint256 _burnAmount = _mintAmount * 1e11;                                         
        require(_burnAmount > 0, "ColoursGold: Burn amount is 0.");
        require(cents.balanceOf(msg.sender) >= _burnAmount, "ColoursGold: Not enough cents to burn.");             
        
        // Initial cents balance before burn.
        uint256 initialCentsBalance = cents.balanceOf(msg.sender);
        
        // Burn the cents.
        cents.transferFrom(msg.sender, address_burn, _burnAmount);       
        
        // New cents balance.
        uint256 newCentsBalance = cents.balanceOf(msg.sender);
        
        // Make sure cents were burned.
        require(newCentsBalance == initialCentsBalance - _burnAmount, "Burn not completed successfully, can't mint.");
        
        //Mint the new tokens.
        _mint(msg.sender, _mintAmount);                                                                             
        
        emit MintTokens(_mintAmount, _burnAmount, 3, 1, block.timestamp);                                           
    }
    
    function mintGoldWithTokens(uint256 _mintAmount) public onlyOwner {
        // Require number to be > 0.
        require(_mintAmount > 0, "ColoursGold: Can't mint 0.");
        
        // Require total supply of all to be under or equal to max supply.
        require(totalSupplyAll() <= maxSupply, "ColoursGold: Mint amount exceeds max supply.");    
        
        // Check if wallet has enough to burn.
        uint256 _burnAmount = _mintAmount * 1e5;                                         
        require(_burnAmount > 0, "ColoursGold: Burn amount is 0.");
        require(tokens.balanceOf(msg.sender) >= _burnAmount, "ColoursGold: Not enough tokens to burn.");             
        
        // Initial gold balance before burn.
        uint256 initialTokensBalance = tokens.balanceOf(msg.sender);
        
        // Burn the gold.
        tokens.transferFrom(msg.sender, address_burn, _burnAmount);       
        
        // New gold balance.
        uint256 newTokensBalance = tokens.balanceOf(msg.sender);
        
        // Make sure gold were burned.
        require(newTokensBalance == initialTokensBalance - _burnAmount, "Burn not completed successfully, can't mint.");
        
        //Mint the new tokens.
        _mint(msg.sender, _mintAmount);                                                                             
        
        emit MintTokens(_mintAmount, _burnAmount, 3, 2, block.timestamp);                                           
    }
    
    function totalSupplyCents() public view virtual returns (uint256) {
        return cents.totalSupply();
    }
    
    function totalSupplyTokens() public view virtual returns (uint256) {
        return tokens.totalSupply();
    }
    
    function totalSupplyAll() public view virtual returns (uint256) {
        return (totalSupplyCents()/1e11) + (totalSupplyTokens()/1e5) + totalSupply();
    }
}