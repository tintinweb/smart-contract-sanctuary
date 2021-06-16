/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

/*                                                                                                                
                                                                                                                                                     
                                    .... .                                                                                                      u     
                                   :i:::.EBi                            .r:::.JB.                   ii:::.Rg    :i:i:.QE                     .:.BB:   
                                   .. .  QBQ:                           :::.. bBB:                  i.:...BBB   i::...BBB                  .i:. DBB   
                                  .J::..iBBB                            i:....BBB                  .::.. 7BBQ  .::.. vBBg                :::.:. dBg   
                                   KBBBBBBB2                           .:.:. rBBZ                  ::.:. PBBi  ::... EBB.              .:::.:.. ZBg   
       ..... .         ..... .      rdUSUis        ..:::.:..           i::.. EBB:       ...:::.    i.:...BBB   i.:...BBB   .. .      .BBv..:... PBD   
      .ri:i:.gg       .ri::..BBi  r:.  .B.      ::i::::.:::ii:.       .i:.. .BBB     .iii:::::::: .::.. LBBS  :::.. sQB2.:i:i.jB.      bi.:..   dBD   
       i:::: sQB      i::. .gBBB..::.. XBB7   :i::..     ..:::i7      ::.:. vBBS   .ii::..     .::::.:. ZBB.  ::.:. gBQ. :::...BQ.     ..:.. Sb PBg   
       ::.:..iBB     i:..  ZBQB. ::.:..BBQ  .ii:.. rqgQQZ:..:..:B:    i::.. MBB.  :i:... :YXbP5:..:::..:BQB   i::..:BBB  ::.:..QB:    :::.. sBBBbBB   
       :::::.:BB    :i... bBQB: .i::. rBBD  i:::.:QBBBBBQB:..:. PB.  .i::: :BBQ  i::.. .PBBBBBBBr..:.. uBBJ  :::.. IBBY  i::.. gB7   :i:.. LBBBS :Q   
       .i.:...BB.  :i.:. PBBB:  :::.. dBB: ::::.iBBBB7    .:::. JBB  :i::. uBBY .::::..BBBBP:   .::.:..MBB   i:.:..QBB   i:.:. qB1  .i:.. vBBBK       
        i:::. MBi .i:.. XBBBi   i:.:..QBB .:::..:i.:.  ........ 2BB  i::...QBB  i:::..ZBBB.      i.:..:BBQ  .i::..iBBQ   :::.. 1BZ  i:.. 7BBBb        
        i:::: ZBs r::. 5BBBr   :i:::.vBBI i::::.      .......   RQB  i:::.rBBM .r:::.rBBB       .i::: XBBr  i:::: qQBr   .r:::.vBQ :i:: rBBQZ         
        :r:::.XBb.::. 5BBB7    r:::..gBB  i:::.72uuUUIUIUI1I12sIBBQ :i::..XBBr ii:::.SBBY       ii::..QBQ   ri::.:QBB    .r:::.rQB:::: rBBBM          
        .r:::.SB:.:. uBQBL    .r:::.iBBQ .i:::.EBBBBBBBBBBBQBBBBBBJ i:::..BBB  ii:::.IBB       :i:::.rBBD  .r:::.7BBZ     r:::.iB7..: iBBBR           
         r:::.v7.:. jBBBJ     :i::. 1BBu :i:::.vBB      .:... i    .i:::.7QBd  r::::.iQB      :r:::. PBB:  i:::. EBBi     ::::.iu... iQBBQ            
         i:::.:... LBBB2      r:::..QBB  .r::.:.LE     ....  :BBi  ::::. PBB:  :i:::..rD    .:i::::..BBB   r:::.:BBB      :i:::.... :BBBB             
         :i:::::. vBBB5      .i:.: rBBQ   :r::....:::i::.. .IBBBB  i.:...BBB    ri::.:..:i::.:::.:. 7BBK  .i.:..LBBK      .r::::.: :BBBB              
         .r::::. 7BBBK       :...  5BBv    .7:......... .:5BBBBb  :.... vBBS     ir........ rg: ..  EBB.  i..   gBB.       i:::::.:BBBB               
          i:::..7BQBb        qQq5I1BBB      .EQIri:i:rsqQBBBBB:   YBqS21MBB.      rg2riiivIQBBqb5SU5BBB   EQSS1SBBB        :::::.:QBQB                
         .r::..rBQBE          bBBBBBBR        vBBQBBBQBBBQB1.      sBBBBBBB        .QBBBBBBBBBSPBBBBBBI    QBBBBBBI        i:::..QBBB                 
        .r::. rBQBg                               .rrri:                              .iiri.                              ii::..MBBB                  
     iiii::. 7BBBR          r::.......::i:i:i::..        ...::::i:::.......::::::::::..     ...........:i::........:iii:ii::. :RBBB.                  
     r::.. .1BQBM          :i:::.:.:.:::::::.:::.:.....:.:::::::::::.:::.:::::::::::::.:.:.:::::::.:.:.:::::.:.:.:::::::.... 7BBBB.                   
    ir..::JRBBBP           vi.............................................................................................:7DBBBB                     
    .BBBQBQBBBr            7BBBBQBBBBBQBBBQBQBBBBBBBBBBBBBBBBBBBQBBBQBBBQBQBBBBBBBBBQBBBBBBBQBBBBBBBBBBBBBQBBBBBBBBBBBQBQBBBBBBK                      
      XDbq5Y:               .DZPEPEPdPEPdPdPdPdbEPEbEPEbEPEPdPEPEbdbEdZbZdEdEdEdEbEdZbEdZdZdEbEdZdEbEdZdEbEdZdEdZdEbEdZdZPP5ji                        
                                                                                                                                                    
*/
// File contracts/openzeppelin_contracts/utils/Context.sol

// SPDX-License-Identifier: BUSL-1.1

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File contracts/openzeppelin_contracts/access/Ownable.sol


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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        revert("Cannot renounceOwnership with this contract");
        //not possible for these contracts
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File contracts/openzeppelin_contracts/token/ERC20/IERC20.sol


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


// File contracts/openzeppelin_contracts/token/ERC20/ERC20.sol


pragma solidity ^0.8.0;


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
contract ERC20 is Context, IERC20 {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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


// File contracts/Vault.sol

pragma solidity 0.8.4;


contract Vault is Ownable {
    address private dispatcherAddress;
    address private multiSigAddress;
    address[] private tokens;

    struct supportedToken {
        ERC20 token;
        bool active;
    }

    mapping(address => supportedToken) private tokensStore;

    constructor(address _multiSigAddress) Ownable() {
        require(_multiSigAddress != address(0), "Cannot set address to 0");
        multiSigAddress = _multiSigAddress;
    }

    /*****************  Getters **************** */

    function getDispatcherAddress() public view returns (address) {
        return dispatcherAddress;
    }

    function getMultiSigAddress() public view returns (address) {
        return multiSigAddress;
    }

    function getTokenAddresses() public view returns (address[] memory) {
        return tokens;
    }

    /***************** Calls **************** */
    function transferFunds(address _tokenAddress, address _recipient, uint256 _amount) external onlyDispatcher {
        require(tokensStore[_tokenAddress].active == true, "Token not supported");
        require(_amount > 0, "Cannot transfer 0 tokens");
        ERC20(_tokenAddress).transfer(_recipient, _amount);
        emit ReleasedFundsEvent(_recipient, _amount);
    }

    function newMultiSig(address _multiSigAddress) external onlyMultiSig {
        require(_multiSigAddress != address(0), "Cannot set address to 0");
        multiSigAddress = _multiSigAddress;
        emit NewMultiSigEvent(_multiSigAddress);
    }

    function newDispatcher(address _dispatcherAddress) external onlyMultiSig {
        require(_dispatcherAddress != address(0), "Can't set address to 0");
        dispatcherAddress = _dispatcherAddress;
        emit NewDispatcherEvent(dispatcherAddress);
    }

    function addToken(address _tokenAddress) external onlyMultiSig {
        require(tokensStore[_tokenAddress].active != true, "Token already supported");
        tokensStore[_tokenAddress].token = ERC20(_tokenAddress);
        tokensStore[_tokenAddress].active = true;
        tokens.push(_tokenAddress);
        emit AddTokenEvent(_tokenAddress);
    }

    function removeToken(address _tokenAddress) external onlyMultiSig {
        require(tokensStore[_tokenAddress].active == true, "Token not supported already");
        tokensStore[_tokenAddress].active = false;
        popTokenArray(_tokenAddress);
        emit RemoveTokenEvent(_tokenAddress);
    }

    /*****************  Internal **************** */

    function popTokenArray(address _tokenAddress) private {
        for(uint256 i = 0; i <= tokens.length; i++)
        {
            if(_tokenAddress == tokens[i])
            {
                tokens[i] = tokens[tokens.length - 1];
                tokens.pop();
                break;
            }
        }
    }

    /*****************  Modifiers **************** */

    modifier onlyDispatcher() {
        require(dispatcherAddress == msg.sender, "Not the disptacher");
        _;
    }

    modifier onlyMultiSig() {
        require(multiSigAddress == msg.sender, "Not the multisig");
        _;
    }

    /*****************  Events **************** */
    event NewMultiSigEvent(address newMultiSigAddress);
    event AddTokenEvent(address newTokenAddress);
    event RemoveTokenEvent(address removedTokenAddress);
    event NewDispatcherEvent(address newdDspatcherAddress);
    event ReleasedFundsEvent(address indexed recipient, uint256 amount);
}


// File contracts/Dispatcher.sol

pragma solidity 0.8.4;



contract Dispatcher is Ownable {

    Vault private vault;

    address private multiSigAddress;
    address private bridgeControllerAddress;
    address[] private validators;

    uint256 private valThreshold = 1;
    uint256 private uuid = 0;

    uint256[] private outstandingTransferProposalsIndex;

    struct transferProposal {
        address recipientAddress;
        uint256 amount;
        address tokenAddress;
        address[] signatures;
        string note;
        bool signed;
    }
    mapping(uint256 => transferProposal) private transferProposalStore;

    mapping(string => string) private transactions;

    constructor(address _vaultAddress, address _multiSigAddress) Ownable() {
        require(_multiSigAddress != address(0), "Cannot set address to 0");
        multiSigAddress = _multiSigAddress;
        vault = Vault(_vaultAddress);
        bridgeControllerAddress = msg.sender;
    }

    /*****************  Getters **************** */
    function getBridgeController() public view returns (address) 
    {
        return bridgeControllerAddress;
    }

    function getValidators() public view returns (address[] memory) 
    {
        return validators;
    }

    function getVaultAddress() public view returns (Vault) 
    {
        return vault;
    }

    function getMultiSig() public view returns (address) 
    {
        return multiSigAddress;
    }
    
    function getOutstandingTransferProposals() public view returns (uint256[] memory) {
        return outstandingTransferProposalsIndex;
    }

    function getValThreshold() public view returns (uint256) 
    {
        return valThreshold;
    }
    function getCreatedTransanction(string memory txID) public view returns (string memory)
    {
        return transactions[txID];
    }

    function getUUID() public view returns (uint256)
    {
        return uuid;
    }

    /*****************  Setters **************** */
    function newThreshold(uint256 _threshold) external onlyMultiSig {
        require(_threshold <= validators.length, "Validation threshold cannot exceed amount of validators");
        require(_threshold > 0, "Threshold must be greater than 0");
        valThreshold = _threshold;
        emit NewThresholdEvent(_threshold);
    }

    function newMultiSig(address _multiSigAddress) external onlyMultiSig {
        require(_multiSigAddress != address(0), "Cannot set address to 0");
        multiSigAddress = _multiSigAddress;
        emit NewMultiSigEvent(_multiSigAddress);
    }


    function newVault(address _vaultAddress) external onlyMultiSig {
        require(_vaultAddress != address(0), "Vault address cannot be 0");
        vault = Vault(_vaultAddress);
        emit NewVault(_vaultAddress);
    }

    function newBridgeController(address _bridgeControllerAddress) external onlyMultiSig {
        require(_bridgeControllerAddress != address(0), "Bridge controller address cannot be 0");
        bridgeControllerAddress = _bridgeControllerAddress;
        emit NewBridgeController(_bridgeControllerAddress);
    }

    function addNewValidator(address _validatorAddress) external onlyMultiSig {
        require(_validatorAddress != address(0), "Validator cannot be 0");
        validators.push(_validatorAddress);
        emit AddedNewValidator(_validatorAddress);
    }

    function removeValidator(address _validatorAddress) external onlyMultiSig {
        //Remove a validator threshold count in order to avoid not having enough validators
        for(uint256 i = 0; i <= validators.length; i++)
        {
            if(validators[i] == _validatorAddress)
            {
                validators[i] = validators[validators.length - 1];
                validators.pop();
                if(valThreshold > 1)
                {
                    valThreshold = valThreshold - 1;
                }
                break;
            }
        }
        emit RemovedValidator(_validatorAddress);
    }


    /***************** Calls **************** */

    function proposeNewTxn(address _userAddress, address _tokenAddress, uint256 _amount, string memory _note) external onlyBridgeController{
        transferProposalStore[uuid].recipientAddress = _userAddress;
        transferProposalStore[uuid].amount = _amount;
        transferProposalStore[uuid].tokenAddress = _tokenAddress;
        transferProposalStore[uuid].note = _note;
        if(valThreshold == 1)
        {
            vault.transferFunds(transferProposalStore[uuid].tokenAddress, transferProposalStore[uuid].recipientAddress, transferProposalStore[uuid].amount);
            emit ApprovedTransaction(transferProposalStore[uuid].recipientAddress, transferProposalStore[uuid].amount, uuid);
            emit proposalCreated(uuid);
            transferProposalStore[uuid].signed = true;
        }
        else
        {
            transferProposalStore[uuid].signatures.push(msg.sender);
            outstandingTransferProposalsIndex.push(uuid);
            emit proposalCreated(uuid);
        }
        uuid += 1;
    }

    function approveTxn(uint256 _proposal) external onlyValidators oneVoteTransfer(_proposal){
        require(transferProposalStore[_proposal].signed == false, "Already Signed");

        transferProposalStore[_proposal].signatures.push(msg.sender);

        if (transferProposalStore[_proposal].signatures.length >= valThreshold) {
            vault.transferFunds(transferProposalStore[_proposal].tokenAddress, transferProposalStore[_proposal].recipientAddress, transferProposalStore[_proposal].amount);
            popTransferProposal(_proposal);
            emit ApprovedTransaction(transferProposalStore[_proposal].recipientAddress, transferProposalStore[_proposal].amount, _proposal);
        }
    }

    function createTxn(
    string memory _id, 
    string memory _note,
    address _tokenAddress,
    uint256 _calculatedFee,
    uint256 _amount
    ) external payable{
        require(_amount > 0, "Must send an amount");
        require(msg.value == _calculatedFee, "Calculated fee sent wrong");
        require(bytes(transactions[_id]).length == 0, "Must be a new transaction");
        transactions[_id] = _note;
        ERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
        payable(bridgeControllerAddress).transfer(msg.value);
        emit NewTransactionCreated(msg.sender, _tokenAddress, _amount);
    }


    /*****************  Internal **************** */

    function popTransferProposal(uint256 _uuid) private {
        for(uint256 i = 0; i <= outstandingTransferProposalsIndex.length; i++)
        {
            if(outstandingTransferProposalsIndex[i] == _uuid)
            {
                outstandingTransferProposalsIndex[i] = outstandingTransferProposalsIndex[outstandingTransferProposalsIndex.length - 1];
                outstandingTransferProposalsIndex.pop();
                break;
            }
        }
    }

    /*****************  Modifiers **************** */
    modifier onlyBridgeController() {
        require(bridgeControllerAddress == msg.sender, "Only the controller can create new transactions");
        _;
    }
    
    modifier onlyMultiSig() {
        require(multiSigAddress == msg.sender, "Not the multisig");
        _;
    }

    modifier onlyValidators() {
        for (uint256 i = 0; i < validators.length; i++) {
            if (validators[i] == msg.sender) {
                _;
            }
        }
    }

    modifier oneVoteTransfer (uint256 _proposal) {
        for(uint256 i = 0; i < transferProposalStore[_proposal].signatures.length; i++){
            require(transferProposalStore[_proposal].signatures[i] != msg.sender, "You have already voted");
        }

        _;
    }

        /*****************  Events **************** */
    event NewVault(address newAddress); 
    event NewMultiSigEvent(address newMultiSigAddress);
    event AddedNewValidator(address newValidator);
    event RemovedValidator(address oldValidator);
    event NewBridgeController(address newBridgeController);
    event NewThresholdEvent(uint256 newThreshold);
    event proposalCreated(uint256 UUID);
    event ApprovedTransaction(address indexed recipient, uint256 amount, uint256 UUID);
    event NewTransactionCreated(address indexed sender, address tokenAddress, uint256 amount);
    event ReleasedFunds(address indexed recipient, uint256 amount);
}


// File contracts/DispatcherMultiSig.sol

pragma solidity 0.8.4;



contract DispatcherMultiSig is Ownable {
    Dispatcher private dispatcher;

    address[] private signatories;
    uint256[] private outstandingAddressProposalsIndex;
    uint256[] private outstandingThresholdProposalsIndex;
    uint256 private threshold = 1;

    uint256 private uuid = 0;

    /*Proposal types
        0 = approveSignatory for multisig
        1 = removeSignatory for multisig
        2 = approveNewOwner for multisig
        3 = approveNewMultiSig for dispatcher
        4 = approveNewVault for dispatcher
        5 = approveNewDispatcher for multisig
    */

    struct addressProposal {
        uint256 proposalType;
        address proposal;
        address[] signatures;
        bool signed;
        uint256 timeStamp;
    }
    mapping(uint256 => addressProposal) private addressProposalStore;

    struct thresholdProposal {
        uint256 proposal;
        address[] signatures;
        bool signed;
        uint256 timeStamp;
    }
    mapping(uint256 => thresholdProposal) private thresholdProposalStore;

    constructor() Ownable() {
        signatories.push(msg.sender);
    }

    /*****************  Getters **************** */
    function getSignatories() public view returns (address[] memory) {
        return signatories;
    }

    function getProposal(uint256 _index) public view returns (addressProposal memory) {
        return addressProposalStore[_index];
    }

    function getThresholdProposal(uint256 _index) public view returns (thresholdProposal memory)
    {
        return thresholdProposalStore[_index];
    }

    function getOutstandingAddressProposals() public view returns (uint256[] memory) {
        return outstandingAddressProposalsIndex;
    }

    function getOutstandingThresholdProposals() public view returns (uint256[] memory) {
        return outstandingThresholdProposalsIndex;
    }

    function getDispatcher() public view returns (Dispatcher){
        return dispatcher;
    }

    function getAddressProposal(uint256 i)
        public
        view
        returns (addressProposal memory)
    {
        return addressProposalStore[i];
    }

    function getThreshold() public view returns (uint256) {
        return threshold;
    }

    /*****************  Proposers **************** */
    function proposeAddress(address _address, uint256 _index) external onlyOwner {
        addressProposalStore[uuid].proposal = _address;
        addressProposalStore[uuid].proposalType = _index;
        addressProposalStore[uuid].timeStamp = block.timestamp;
        outstandingAddressProposalsIndex.push(uuid);
        uuid += 1;
        emit ProposeAddress(_address, _index);
    }

    function proposeNewOwner(address _address) external onlySignatories {
        addressProposalStore[uuid].proposal = _address;
        addressProposalStore[uuid].proposalType = 2;
        addressProposalStore[uuid].timeStamp = block.timestamp;
        outstandingAddressProposalsIndex.push(uuid);
        uuid += 1;
        emit ProposeNewOwner(_address);
    }

    function proposeNewThreshold(uint256 _threshold) external onlyOwner {
        thresholdProposalStore[uuid].proposal = _threshold;
        thresholdProposalStore[uuid].timeStamp = block.timestamp;
        outstandingThresholdProposalsIndex.push(uuid);
        uuid += 1;
        emit ProposeNewThreshold(_threshold);
    }
    /***************** Approvers **************** */

    function approveSignatory(uint256 _proposal) external onlySignatories oneVoteAddress(_proposal){
        require(addressProposalStore[_proposal].proposalType == 0, "Not the right proposal type");
        require(addressProposalStore[_proposal].signed == false, "Already Signed");

        addressProposalStore[_proposal].signatures.push(msg.sender);

        if (addressProposalStore[_proposal].signatures.length >= threshold) {
            addressProposalStore[_proposal].signed = true;
            signatories.push(addressProposalStore[_proposal].proposal);
            popAddressProposal(_proposal);
            emit ApprovedSignatory(addressProposalStore[_proposal].proposal);
        }
    }

    function removeSignatory(uint256 _proposal) external onlySignatories oneVoteAddress(_proposal){
        require(addressProposalStore[_proposal].proposalType == 1, "Not the right proposal type");
        require(addressProposalStore[_proposal].signed == false, "Already Signed");

        addressProposalStore[_proposal].signatures.push(msg.sender);

        if (addressProposalStore[_proposal].signatures.length >= threshold) {
            addressProposalStore[_proposal].signed = true;
            //Remove a threshold count in order to avoid not having enough signatories
            if(threshold > 1)
            {
                threshold = threshold - 1;
            }
            removeSignatory(addressProposalStore[_proposal].proposal);
            popAddressProposal(_proposal);
            emit RemovedSignatory(addressProposalStore[_proposal].proposal);
        }
    }
    
    function approveNewOwner(uint256 _proposal) external onlySignatories oneVoteAddress(_proposal){
        require(addressProposalStore[_proposal].proposalType == 2, "Not the right proposal type");
        require(addressProposalStore[_proposal].signed == false, "Already Signed");

        addressProposalStore[_proposal].signatures.push(msg.sender);

        if (addressProposalStore[_proposal].signatures.length >= threshold) {
            addressProposalStore[_proposal].signed = true;

            transferOwnership(addressProposalStore[_proposal].proposal);
            popAddressProposal(_proposal);
            emit ApprovedNewOwner(addressProposalStore[_proposal].proposal);
        }
    }

    function approveNewMultiSig(uint256 _proposal) external onlySignatories oneVoteAddress(_proposal){
        require(addressProposalStore[_proposal].proposalType == 3, "Not the right proposal type");
        require(addressProposalStore[_proposal].signed == false, "Already Signed");

        addressProposalStore[_proposal].signatures.push(msg.sender);

        if (addressProposalStore[_proposal].signatures.length >= threshold) {
            addressProposalStore[_proposal].signed = true;

            dispatcher.newMultiSig(addressProposalStore[_proposal].proposal);
            popAddressProposal(_proposal);
            emit ApprovedNewMultiSig(addressProposalStore[_proposal].proposal);
        }
    }

    function approveNewVault(uint256 _proposal) external onlySignatories oneVoteAddress(_proposal){
        require(addressProposalStore[_proposal].proposalType == 4, "Not the right proposal type");
        require(addressProposalStore[_proposal].signed == false, "Already Signed");

        addressProposalStore[_proposal].signatures.push(msg.sender);

        if (addressProposalStore[_proposal].signatures.length >= threshold) {
            addressProposalStore[_proposal].signed = true;

            dispatcher.newVault(addressProposalStore[_proposal].proposal);
            popAddressProposal(_proposal);
            emit ApprovedNewVault(addressProposalStore[_proposal].proposal);
        }
    }

    function approveNewDispatcher(uint256 _proposal) external onlySignatories oneVoteAddress(_proposal) {
        require(addressProposalStore[_proposal].proposalType == 5, "Not the right proposal type");
        require(addressProposalStore[_proposal].signed == false, "Already Signed");

        addressProposalStore[_proposal].signatures.push(msg.sender);

        if (addressProposalStore[_proposal].signatures.length >= threshold) {
            addressProposalStore[_proposal].signed = true;

            dispatcher = Dispatcher(addressProposalStore[_proposal].proposal);
            popAddressProposal(_proposal);
            emit ApprovedDispatcher(addressProposalStore[_proposal].proposal);
        }
    }
    
    function approveNewThreshold(uint256 _proposal) external onlySignatories oneVoteThreshold(_proposal){
        require(thresholdProposalStore[_proposal].signed == false, "Already Signed");
        require(thresholdProposalStore[_proposal].proposal <= signatories.length, "Can't be less signatories than threshold");
        thresholdProposalStore[_proposal].signatures.push(msg.sender);

        if (thresholdProposalStore[_proposal].signatures.length >= threshold) {
            threshold = thresholdProposalStore[_proposal].proposal;
            popThresholdProposal(_proposal);
            emit ApprovedNewThreshold(thresholdProposalStore[_proposal].proposal);
        }
    }

    /*****************  Internal **************** */

    function popAddressProposal(uint256 _uuid) private {
        for(uint256 i = 0; i <= outstandingAddressProposalsIndex.length; i++)
        {
            if(outstandingAddressProposalsIndex[i] == _uuid)
            {
                outstandingAddressProposalsIndex[i] = outstandingAddressProposalsIndex[outstandingAddressProposalsIndex.length - 1];
                outstandingAddressProposalsIndex.pop();
                break;
            }
        }
    }

    function popThresholdProposal(uint256 _uuid) private {
        for(uint256 i = 0; i <= outstandingThresholdProposalsIndex.length; i++)
        {
            if(outstandingThresholdProposalsIndex[i] == _uuid)
            {
                outstandingThresholdProposalsIndex[i] = outstandingThresholdProposalsIndex[outstandingThresholdProposalsIndex.length - 1];
                outstandingThresholdProposalsIndex.pop();
                break;
            }
        }
    }

    function removeSignatory(address _signatory) private {
        for(uint256 i = 0; i <= signatories.length; i++)
        {
            if(signatories[i] == _signatory)
            {
                signatories[i] = signatories[signatories.length - 1];
                signatories.pop();
                break;
            }
        }
    }

    /*****************  Modifiers **************** */
    modifier onlySignatories() {
        for (uint256 i = 0; i < signatories.length; i++) {
            if (signatories[i] == msg.sender) {
                _;
            }
        }
    }

    modifier oneVoteAddress (uint256 _proposal) {
        for(uint256 i = 0; i < addressProposalStore[_proposal].signatures.length; i++){
            require(addressProposalStore[_proposal].signatures[i] != msg.sender, "You have already voted");
        }

        _;
    }

    modifier oneVoteThreshold (uint256 _proposal) {
        for(uint256 i = 0; i < thresholdProposalStore[_proposal].signatures.length; i++){
            require(thresholdProposalStore[_proposal].signatures[i] != msg.sender, "You have already voted");
        }

        _;
    }
    /*****************  Events **************** */
    event ApprovedSignatory(address newSignatory);
    event RemovedSignatory(address removedSignatory);
    event ApprovedNewOwner(address newOwner);
    event ApprovedNewMultiSig(address newMultiSig);
    event ApprovedNewVault(address newVault);
    event ApprovedDispatcher(address newDispatcher);
    event ApprovedNewThreshold(uint256 newThreshold);
    event ProposeAddress(address proposedAddress, uint256 index);
    event ProposeNewOwner(address newOwner);
    event ProposeNewThreshold(uint256 threshold);
}