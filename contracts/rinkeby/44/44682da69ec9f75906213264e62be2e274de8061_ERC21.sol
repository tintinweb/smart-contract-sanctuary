/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

//import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
//https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Interface of the ERC21 standard as defined in the EIP.
 */
interface IERC21 {
    
    struct GasData {
        int gasLimit;
        int gasPrice;
    }
    
    struct BlockChain {
        GasData gasData;
        AggregatorV3Interface priceFeed;
        int exchangeFee;
    }
    
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
    
    /**
     * @dev Gets a blockchain by name
    */
    function getBlockchain(string memory chain) external view returns (BlockChain memory);
    
    /**
     * @dev Add a blockchain to exchgange with
    */
    function addBlockchain(string memory chain, int gasLimit, int gasPrice, address contractAddress, int exchangeFee) external returns (bool);
    
    /*
    * @dev Gets a fee for the movememnt to another chain
    */
    function getFee(string memory chain) external view returns(int);

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
     * @dev Moves `gasFee` ETH from the callers allowance to '_exchangeAddress` (if enough)
     * Then Moves `amount` tokens from `sender` to this contract, 'amount` is then deducted from the caller's allowance.
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {MovedToken} event.
     */
    function moveToken(uint256 amount, string memory chain) external payable returns (bool);
    
    /**
     * @dev Redeems tokens from another chain and adds them to this chain
     * 
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {RedeemedToken} event.
    */ 
    function redeemToken(string memory fromChain, address addressTo, uint256 amount) external returns (bool);

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
    
    /**
     * @dev Emitted when the user wants to move mo to another chain is set by 
     * a call to {MoveToken}.
     */
    event MovedToken(int id, string chain, address indexed owner, uint256 fee, uint256 amount);
    
    /**
     * @dev Emitted when the user wants to redeem tokens from another chain is set by 
     * a call to {RedeemToken}.
     */
    event RedeemedToken(int id, string chain, address indexed addressTo, uint256 amount);
}

/**
 * @dev Interface of the Ownable modifier handling contract ownership
 */
abstract contract Ownable {
    /**
    * @dev The owner of the contract
    */
    address payable internal _owner;
    
    /**
    * @dev The new owner of the contract (for ownership swap)
    */
    address payable internal _potentialNewOwner;
 
    /**
     * @dev Emitted when the user wants to move mo to another chain is set by 
     * a call to {MoveToken}.
    */
    event OwnershipTransferred(address payable indexed from, address payable indexed to, uint date);
 
  constructor() {
    _owner = payable(msg.sender);
  }
  
  modifier onlyOwner() {
    require(msg.sender == _owner);
    _;
  }
  
  function transferOwnership(address payable newOwner) external onlyOwner {
    _potentialNewOwner = newOwner;
  }
  
  function acceptOwnership() external {
    require(msg.sender == _potentialNewOwner);
    emit OwnershipTransferred(_owner, _potentialNewOwner, block.timestamp);
    _owner = _potentialNewOwner;
  }
  
  function getOwner() view external returns(address){
      return _owner;
  }
  
  function getPotentialNewOwner() view external returns(address){
      return _potentialNewOwner;
  }
}

abstract contract RecoverableToken is IERC21, Ownable {
    
  event RecoveredTokens(address token, address owner, uint256 tokens);
  
  function recoverAllTokens(IERC21 token) public onlyOwner {
    uint256 tokens = tokensToBeReturned(token);
    require(token.transfer(_owner, tokens) == true, "Failed to transfer tokens");
    emit RecoveredTokens(address(token), _owner, tokens);
  }
  
  function recoverTokens(IERC21 token, uint256 amount) public onlyOwner {
    require(token.transfer(_owner, amount) == true, "Failed to transfer tokens");
    emit RecoveredTokens(address(token), _owner, amount);
  }
  
  function recoverTokens(IERC21 token, uint256 amount, address addressTo) public onlyOwner {
    require(token.transfer(addressTo, amount) == true, "Failed to transfer tokens");
    emit RecoveredTokens(address(token), addressTo, amount);
  }
  
  function tokensToBeReturned(IERC21 token) public view returns (uint256) {
    return token.balanceOf(address(this));
  }
}

// An extension that allows the ERC21 owner to withdraw all ETH from the contract
abstract contract WithdrawableToken is IERC21, Ownable {
  
  event WithdrawLog(uint256 balanceBefore, uint256 amount, uint256 balanceAfter, address addressTo);
  
  function withdraw(uint256 amount, address payable toAddress) virtual public onlyOwner returns(bool){
	require(amount <= address(this).balance);
    toAddress.transfer(amount);
	emit WithdrawLog(address(this).balance + amount, amount, address(this).balance, toAddress);
    return true;
  } 
}

/**
 * @dev Interface for the optional metadata functions from the ERC21 standard.
 *
 * _Available since v4.1._
 */
interface IERC21Metadata is IERC21 {
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

/**
 * @dev Implementation of the {IERC21} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC21PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-ERC21-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC21 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC21-approve}.
 */
contract ERC21 is Context, IERC21, IERC21Metadata, Ownable, RecoverableToken, WithdrawableToken {
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (string => BlockChain) private _blockChains;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    int private _movedTokenId;
    int private _redeemedTokenId;
    
    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
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
     * Ether and Wei. This is the value {ERC21} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC21-balanceOf} and {IERC21-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC21-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    
    /**
     * @dev Gets gas limit
    */
    function getBlockchain(string memory chain) public override view returns (BlockChain memory){
        return _blockChains[chain];
    }

    /**
     * @dev See {IERC21-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    
    /*
    * @dev Checks if a fee supplied is valid
    */
    function isFeeValid(string memory chain, uint256 value) public view returns(bool){
        // Get fee
        int fee = getFee(chain);
        
        // Check fee is less than or equal to amount supplied
        return fee <= int(value);
    }
    
    /**
     * @dev Add a blockchain to exchgange with
    */
    function addBlockchain(string memory chain, int gasLimit, int gasPrice, address contractAddress, int exchangeFee) public virtual override onlyOwner returns (bool) {
        // Create the gas data
        GasData memory gasData = GasData(gasLimit, gasPrice);
        
        // Setup the price feed
        AggregatorV3Interface priceFeed = AggregatorV3Interface(contractAddress);
        
        // Create the blockchain and address
        _blockChains[chain] = BlockChain(gasData, priceFeed, exchangeFee);
        
        return true;
    }
    
    /*
    * @dev Gets a fee for the movememnt to another chain
    */
    function getFee(string memory chain) public view override returns(int){
        // Get the price of contract to other chain
        int price = getLivePrice(chain);
        
        // Get the gas data to estimate price with
        BlockChain memory blockchain = _blockChains[chain];
        
        // Calculate amount to cover fee
        int fee = price * blockchain.gasData.gasLimit * blockchain.gasData.gasPrice;
        
        // Add on exchange fee
        fee += int(blockchain.exchangeFee);
        
        return fee;
    }
    
    /*
    * @dev Gets a price from price feed
    */
    function getLivePrice(string memory chain) public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = _blockChains[chain].priceFeed.latestRoundData();
        
        return price;
    }
    
    /**
     * @dev Moves any ETH sent with the request (msg.Value) from the callers allowance to '_exchangeAddress`
     * Then Moves `amount` tokens from `sender` to this contract, 'amount` is then deducted from the caller's allowance.
     * 
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {MovedToken} event.
    */ 
    function moveToken(uint256 amount, string memory chain) public virtual payable override returns (bool){
        // Check the chain is supported
        BlockChain memory blockchain = _blockChains[chain];
        require(blockchain.gasData.gasLimit == 0, "Chain is not supported");
        
        // Check the fee has been sent
        require(isFeeValid(chain, msg.value), "Fee has not been met");
        
        // Check that the user has enough to make fee
        require(address(_msgSender()).balance > msg.value, "Not enough ETH to commit to 'gasFee'");
        
        // Check the user has enough to send the amount of moveToken
        require(_balances[_msgSender()] >= amount, "Not enough tokens to commit to movement");
        
        // Burn the value
        require(_burn(_msgSender(), amount), "The burn failed");
        
        // Kick off the event
        emit MovedToken(_getMovedTokenId(), chain, _msgSender(), msg.value, amount);

        return true;
    }
    
    /**
     * @dev Redeems tokens from another chain and adds them to this chain
     * 
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {RedeemedToken} event.
    */ 
    function redeemToken(string memory fromChain, address addressTo, uint256 amount) public virtual onlyOwner override returns (bool){
        // Mint the tokens being redeemed
        require(_mint(addressTo, amount), "The mint failed");
        
        // Kick off the event
        emit RedeemedToken(_getRedeemedTokenId(), fromChain, addressTo, amount);
        
        return true;
    }

    /**
     * @dev See {IERC21-transfer}.
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
     * @dev See {IERC21-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    /**
     * @dev See {IERC21-approve}.
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
     * @dev See {IERC21-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC21}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC21: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC21-approve}.
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
     * problems described in {IERC21-approve}.
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
        require(currentAllowance >= subtractedValue, "ERC21: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual returns(bool){
        require(sender != address(0), "ERC21: transfer from the zero address");
        require(recipient != address(0), "ERC21: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC21: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
        
        return true;
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
    function _mint(address account, uint256 amount) internal virtual returns (bool) {
        require(account != address(0), "ERC21: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        
        emit Transfer(address(0), account, amount);
        
        return true;
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
    function _burn(address account, uint256 amount) internal virtual returns (bool) {
        require(account != address(0), "ERC21: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC21: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
        
        return true;
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC21: approve from the zero address");
        require(spender != address(0), "ERC21: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    /**
     * @dev gets a new unique ID for a moved token call
     */
    function _getMovedTokenId() internal returns(int){
        return _movedTokenId++;
    }
    
    /**
     * @dev gets a new unique ID for a moved token call
     */
    function _getRedeemedTokenId() internal returns(int){
        return _redeemedTokenId++;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}