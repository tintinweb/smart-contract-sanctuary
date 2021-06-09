/**
 *Submitted for verification at Etherscan.io on 2021-06-09
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
 * @dev Interface of the Ownable modifier handling contract ownership
 */
abstract contract Ownable is Context {
    /**
    * @dev The owner of the contract
    */
    address payable internal _owner;
    
    /**
    * @dev The new owner of the contract (for ownership swap)
    */
    address payable internal _potentialNewOwner;
 
    /**
     * @dev Emitted when ownership of the contract has been transferred and is set by 
     * a call to {AcceptOwnership}.
    */
    event OwnershipTransferred(address payable indexed from, address payable indexed to, uint date);
 
    /**
     * @dev Sets the owner upon contract creation
     **/
    constructor() {
      _owner = payable(_msgSender());
    }
  
    modifier onlyOwner() {
      require(_msgSender() == _owner);
      _;
    }
  
    function transferOwnership(address payable newOwner) external onlyOwner {
      _potentialNewOwner = newOwner;
    }
  
    function acceptOwnership() external {
      require(_msgSender() == _potentialNewOwner);
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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    
   /**
    * @dev Holds gas related data used to determine fee
    **/
    struct GasData {
        uint256 gas;
        uint256 gasPrice;
    }
    
   /**
    * @dev Holds blockchain data for tokens to move between
    * 
    * The 'exists' is used to determine if the blockchain exists
    * The 'gasData' is used to generate a fee
    * The 'priceFeed' is also used to generate fee (gets current price of [this tokens network]:[other tokens network])
    * The 'exchangeFeePercent' is taken to cover cross chain movement fees from external crosslink (% 0-100)
    **/
    struct BlockChain {
        bool exists;
        GasData gasData;
        AggregatorV3Interface priceFeed;
        uint256 exchangeFeePercent;
    }
    
    /**
     * @dev Returns the amount of tokens in existence.
     * 
     * Returns an integer that represents the total supply of this token
     */
    function totalSupply() external view returns (uint256);
    
    /**
     * @dev Gets a blockchain by name
     * 
     * Returns a blockchain that matches the 'chain' specified (if exists)
    */
    function getBlockchain(string memory chain) external view returns (BlockChain memory);
    
    /**
     * @dev Add a blockchain to exchgange with
     * 
     * Returns if the blockchain has been added successfully
    */
    function addBlockchain(string memory chain, uint256 gasLimit, uint256 gasPrice, address contractAddress, uint256 exchangeFee) external returns (bool);
    
    /**
    * @dev Gets a fee for the movememnt to another chain
    * 
    * Returns the fee required for the crosschain link
    */
    function getFee(string memory chain, uint256 valueToMove) external view returns(uint256);
    
    /**
     * @dev Sets the current chain
     */
    function setCurrentChain(string memory currentChain) external;

    /**
     * @dev Returns the amount of tokens owned by `account`.
     * 
     * Returns the balance of the account
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
     * @dev Takes fee and burns amount of tokens from caller.
     * 
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {MovedToken} event.
     */
    function moveToken(uint256 amount, string memory toChain, string memory addressTo) external payable returns (bool);
    
    /**
     * @dev Redeems tokens from another chain and adds them to this chain (mint)
     * 
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {RedeemedToken} event.
    */ 
    function redeemToken(uint256 movedTokenId, string memory fromChain, address addressTo, uint256 amount) external returns (bool);

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
    event MovedToken(uint256 id, string fromChain, string toChain, address indexed owner, string addressTo, uint256 fee, uint256 amount);
    
    /**
     * @dev Emitted when the user wants to redeem tokens from another chain is set by 
     * a call to {RedeemToken}.
     */
    event RedeemedToken(uint256 movedTokenid, string chain, address indexed addressTo, uint256 amount);
    
    /**
     * @dev Emitted when the owner recovers tokens from this contract and is set by 
     * a call to {RecoverAllTokens} or {RecoverTokens}.
    */
    event RecoveredTokens(address token, address owner, uint256 tokens);
    
    /**
     * @dev Emitted when the owner recovers eth from this contract and is set by 
     * a call to {Withdraw}.
     */
    event WithdrawLog(uint256 balanceBefore, uint256 amount, uint256 balanceAfter, address addressTo);
}

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

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-ERC20-supply-mechanisms/226[How
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
contract ERC20 is Context, IERC20, IERC20Metadata, Ownable {
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (string => BlockChain) private _blockChains;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    string private _currentChain;
    uint256 private _movedTokenId;
    
    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_, string memory chain_) {
        _name = name_;
        _symbol = symbol_;
        _currentChain = chain_;
    }
    
    /**
     * @dev Sets the current chain
     */
    function setCurrentChain(string memory currentChain) public override onlyOwner {
        _currentChain = currentChain;
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
     * @dev Gets a blockchain if it is supported
     * 
     * Returns a blockchain
    */
    function getBlockchain(string memory chain) public override view returns (BlockChain memory){
        return _blockChains[chain];
    }

    /**
     * @dev See {IERC20-balanceOf}.
     * 
     * Returns the token balance of an address
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    
    /**
    * @dev Checks if a fee supplied is valid
    * 
    * Returns true if the fee supplied is valid for the chain provided
    */
    function isFeeValid(string memory chain, uint256 value) public view returns(bool){
        // Get fee
        uint256 fee = uint(getFee(chain, value));
        
        // Check fee is less than or equal to amount supplied
        return fee <= value;
    }
    
    /**
     * @dev Add a blockchain to exchgange with
     * 
     * Returns true if the blockchain has been successfully added
     * 
     * Requirements: 
     *
     * - `exchangeFeePercent` must be must be between 0 and 100.
    */
    function addBlockchain(string memory chain, uint256 gasLimit, uint256 gasPrice, address contractAddress, uint256 exchangeFeePercent) public virtual override onlyOwner returns (bool) {
        // Ensure that the exchange percent is within the bounds we require
        require(exchangeFeePercent < 100, "Exchange fee percent must be between 0 and 100");
        
        // Create the gas data
        GasData memory gasData = GasData(gasLimit, gasPrice);
        
        // Setup the price feed
        AggregatorV3Interface priceFeed = AggregatorV3Interface(contractAddress);
        
        // Create the blockchain and address
        _blockChains[chain] = BlockChain(true, gasData, priceFeed, exchangeFeePercent);
        
        return true;
    }
    
    /**
    * @dev Gets a fee for the movememnt to another chain
    * 
    * Returns the fee required for the movement between chains
    */
    function getFee(string memory chain, uint256 valueToMove) public view override returns(uint256){
        // Get the gas data to estimate price with
        BlockChain memory blockchain = _blockChains[chain];
        
        // Check the chain is supported
        require(blockchain.exists, "Blockchain not supported");
        
        // Get the price of contract to other chain
        uint256 price = uint(getLivePrice(chain));
        
        // Calculate amount to cover fee
        uint256 fee = price * blockchain.gasData.gas * blockchain.gasData.gasPrice;
        
        // Add on exchange fee (x% of value)
        fee += ((valueToMove / 100) * blockchain.exchangeFeePercent);
        
        return fee;
    }
    
    /**
    * @dev Gets a price from price feed (chainlink)
    * 
    * Returns the live price for a pair ([this]:[chain])
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
     * 
     * Requirements: 
     *
     * - `chain` must be supported.
     * - The fee must be valid for the specified `chain` (check first by calling {GetFee}).
     * - The balance must be more than the 'amount' specified
    */ 
    function moveToken(uint256 amount, string memory toChain, string memory addressTo) public virtual payable override returns (bool){
        // Check the chain is supported
        BlockChain memory blockchain = _blockChains[toChain];
        require(blockchain.gasData.gas == 0, "Chain is not supported");
        
        // Check the fee has been sent
        require(isFeeValid(toChain, msg.value), "Fee has not been met");
        
        // Check the user has enough to send the amount of moveToken
        require(_balances[_msgSender()] >= amount, "Not enough tokens to commit to movement");
        
        // Burn the value
        require(_burn(_msgSender(), amount), "The burn failed");
        
        // Kick off the event
        emit MovedToken(_getMovedTokenId(), _currentChain, toChain, _msgSender(), addressTo, msg.value, amount);

        return true;
    }
    
    /**
     * @dev Redeems tokens from another chain and adds them to this chain
     * 
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {RedeemedToken} event.
    */ 
    function redeemToken(uint256 movedTokenId, string memory fromChain, address addressTo, uint256 amount) public virtual onlyOwner override returns (bool){
        // Mint the tokens being redeemed
        require(_mint(addressTo, amount), "The mint failed");
        
        // Kick off the event
        emit RedeemedToken(movedTokenId, fromChain, addressTo, amount);
        
        return true;
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
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
     * @dev Withdraw ETH from the contract
     *
     * Emits an {WithdrawLog} event indicating the withdrawal of ETH.
     *
     * Requirements:
     *
     * - `amount` must be less than the amount held by the contract
     * - `msg.sender` must be the owner of the contract
     */
    function withdraw(uint256 amount, address payable toAddress) virtual public onlyOwner returns(bool){
        // Ensure that there is enough to withdraw
    	require(amount <= address(this).balance, "Not enough balance");
    	
    	// Transfer to specified address
        toAddress.transfer(amount);
        
        // Emit the withdraw event
    	emit WithdrawLog(address(this).balance + amount, amount, address(this).balance, toAddress);
    	
    	// Indicate success
        return true;
    }
    
     /**
     * @dev Recover all of a token from the contract
     *
     * Emits an {RecoveredTokens} event indicating the recovery of all of a token 
     * from the contract
     *
     * Requirements:
     *
     * - `msg.sender` must be the owner of the contract
     */
    function recoverAllTokens(IERC20 token) public onlyOwner {
        uint256 tokens = tokensToBeReturned(token);
        require(token.transfer(_owner, tokens) == true, "Failed to transfer tokens");
        
        emit RecoveredTokens(address(token), _owner, tokens);
    }
  
     /**
     * @dev Recover some (or all) of a token from the contract to the owner
     *
     * Emits an {RecoveredTokens} event indicating the recovery of an amount of a token 
     * from the contract
     *
     * Requirements:
     *
     * - `msg.sender` must be the owner of the contract
     */
    function recoverTokens(IERC20 token, uint256 amount) public onlyOwner {
        require(token.transfer(_owner, amount) == true, "Failed to transfer tokens");
        
        emit RecoveredTokens(address(token), _owner, amount);
    }
  
    /**
     * @dev Recover some (or all) of a token from the contract to an address
     *
     * Emits an {RecoveredTokens} event indicating the recovery of an amount of a token 
     * from the contract
     *
     * Requirements:
     *
     * - `msg.sender` must be the owner of the contract
     */
    function recoverTokens(IERC20 token, uint256 amount, address addressTo) public onlyOwner {
        require(token.transfer(addressTo, amount) == true, "Failed to transfer tokens");
        
        emit RecoveredTokens(address(token), addressTo, amount);
    }
  
     /**
     * @dev Gets how many tokens can be recovered from contract
     *
     * Returns the number of tokens held by contract (if any)
     */
    function tokensToBeReturned(IERC20 token) public view returns (uint256) {
        return token.balanceOf(address(this));
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
        require(account != address(0), "ERC20: mint to the zero address");

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
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
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
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    /**
     * @dev gets a new unique ID for a moved token call
     * 
     * Returns a new integer (increments between calls)
     */
    function _getMovedTokenId() internal returns(uint256){
        return _movedTokenId++;
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