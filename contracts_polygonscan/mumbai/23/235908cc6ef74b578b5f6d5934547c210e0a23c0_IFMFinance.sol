/**
 *Submitted for verification at polygonscan.com on 2022-01-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

   //import "@openzeppelin/contracts/access/Ownable.sol";
   //import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
   //import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
   //import "@openzeppelin/contracts/utils/Context.sol";
   

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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

    mapping(address => mapping(address => uint256)) internal _allowances;

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
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
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
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
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
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }

        _transfer(sender, recipient, amount);

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


contract IFMFinance is ERC20, Ownable{

 uint256 public constant MAX_Supply = 320000000*10**18;
 uint256 public constant Capped_Supply = MAX_Supply;

     function FirstMiner() internal{
     Miners_St1[0x448D82BAcd1B2632886d7508320f75c76A64E640] = true;
     Miners_St2[0x448D82BAcd1B2632886d7508320f75c76A64E640] = true;
     Miners_St3[0x448D82BAcd1B2632886d7508320f75c76A64E640] = true;
     Miners_St4[0x448D82BAcd1B2632886d7508320f75c76A64E640] = true;
     Miners_St5[0x448D82BAcd1B2632886d7508320f75c76A64E640] = true;
   }

    constructor() ERC20("IFM Finance", "IFM") {
        FirstMiner();
        
    }

    address[] internal MinerList1;
    address[] internal MinerList2;
    address[] internal MinerList3;
    address[] internal MinerList4;
    address[] internal MinerList5;
    address internal constant FeeFunds = 0xBD8879ACa470FAed7f4B28a4049969795A9f11Fc;
    address payable FeeWallet = payable(FeeFunds); 
    address public constant BurnAddr = 0x000000000000000000000000000000000000dEaD;
    uint internal StartTime;
    uint internal EndTime;
    uint internal constant MiningFee = 0.02 ether;
    uint public   constant InviteeReward = 0.01 ether;

    event New_St1_miner (address miner, uint256 Miner_Num, address Invitee, string mined);
    event New_St2_miner (address miner, uint256 Miner_Num, address Invitee, string mined);
    event New_St3_miner (address miner, uint256 Miner_Num, address Invitee, string mined);
    event New_St4_miner (address miner, uint256 Miner_Num, address Invitee, string mined);
    event New_St5_miner (address miner, uint256 Miner_Num, address Invitee, string mined);
    event Stage_1_Mining(address token, uint256 miners, uint256 mined, uint256 Burnt);
    event Stage_2_Mining(address token, uint256 miners, uint256 mined, uint256 Burnt);
    event Stage_3_Mining(address token, uint256 miners, uint256 mined, uint256 Burnt);
    event Stage_4_Mining(address token, uint256 miners, uint256 mined, uint256 Burnt);
    event Stage_5_Mining(address token, uint256 miners, uint256 mined, uint256 Burnt);
   
   
    mapping(address => bool) internal Miners_St1;
    mapping(address => bool) internal Miners_St2;
    mapping(address => bool) internal Miners_St3;
    mapping(address => bool) internal Miners_St4;
    mapping(address => bool) internal Miners_St5;

//=================================================================================================================================


    function _mint(address account, uint256 amount) internal virtual override {
        uint256 BurnAmount = amount / 20;
        require( totalSupply() <= MAX_Supply, "IFM Finance cap exceeded");
        super._mint(account, amount - BurnAmount);
        super._mint(BurnAddr, BurnAmount);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool success) {
     uint256 BurnAmount = amount / 20;
     if ( 256000000*10**18 <= balanceOf(BurnAddr)){
      _transfer(msg.sender, recipient, amount);
     }else{
      _transfer(msg.sender, recipient, amount - BurnAmount );
      _transfer(msg.sender, BurnAddr, BurnAmount);
     }
      return true;
    } 

        function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool success) {
        
        uint256 BurnAmount = amount / 20;
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "IFM Token transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

     if ( 256000000*10**18 <= balanceOf(BurnAddr)){
      _transfer(sender, recipient, amount);
     }else{
      _transfer(sender, recipient, amount - BurnAmount );
      _transfer(sender, BurnAddr, BurnAmount);
     }
        return true;
    }


//=================================================================================================================================

            // Army Form Up

//=================================================================================================================================

    function Mine_Stage_1(address payable Invitee_Address) payable public {
          require (msg.sender == tx.origin, "All Miners should be EOA!");
          bool paid = payable(FeeFunds).send(MiningFee);
          require(paid, "Not enough funds!");
        if (!Miners_St1[msg.sender]){
          bool sent = Invitee_Address.send(InviteeReward);
          require(sent, "Not enough funds!");
        } else if (!Miners_St1[Invitee_Address]){
          bool sent = payable(FeeFunds).send(InviteeReward);
          require(sent, "Not enough funds!");
          } else {
          bool sent = payable(FeeFunds).send(InviteeReward);
          require(sent, "Not enough funds!");
        }

        _mint(msg.sender,  5*10**18);
        MinerList1.push(msg.sender);
        Miners_St1[msg.sender] = true;
        emit New_St1_miner(msg.sender,MinerList1.length, Invitee_Address, "5 IFM Finance");

    }

    function St1_Miners() view public returns(uint) {
    return MinerList1.length;
    }
    function Miner_1() public pure returns (address){
        address First_Miner = 0x448D82BAcd1B2632886d7508320f75c76A64E640;
        return First_Miner;
    }
    function Is_St1_Miner(address _Address) public view returns(bool Miner) {
        if ( Miners_St1[_Address]){
            return true;
        }}



//=================================================================================================================================




    function Mine_Stage_2(address payable Invitee_Address) payable public {
        require (msg.sender == tx.origin, "All Miners should be EOA!");
        bool paid = payable(FeeFunds).send(MiningFee);
        require(paid, "Not enough funds!");
        if (!Miners_St2[msg.sender]){
          bool sent = Invitee_Address.send(InviteeReward);
          require(sent, "Not enough funds!");
        } else if (!Miners_St2[Invitee_Address]){
          bool sent = payable(FeeFunds).send(InviteeReward);
          require(sent, "Not enough funds!");
          } else {
          bool sent = payable(FeeFunds).send(InviteeReward);
          require(sent, "Not enough funds!");
        }
        
        _mint(msg.sender,  5*10**18);
        MinerList2.push(msg.sender);
        Miners_St2[msg.sender] = true;
        emit New_St2_miner(msg.sender,MinerList2.length, Invitee_Address, "5 IFM Finance");

    }

    function St2_Miners() view public returns(uint) {
    return MinerList2.length;
    }

    function Is_St2_Miner(address _Address) public view returns(bool Miner) {
        if ( Miners_St2[_Address]){
            return true;
        }}



//=================================================================================================================================




    function Mine_Stage_3(address payable Invitee_Address) payable public {
        require (msg.sender == tx.origin, "All Miners should be EOA!");
        bool paid = payable(FeeFunds).send(MiningFee + 0.01 ether);
        require(paid, "Not enough funds!");
        if (!Miners_St3[msg.sender]){
          bool sent = Invitee_Address.send(InviteeReward);
          require(sent, "Not enough funds!");
        } else if (!Miners_St3[Invitee_Address]){
          bool sent = payable(FeeFunds).send(InviteeReward);
          require(sent, "Not enough funds!");
          } else {
          bool sent = payable(FeeFunds).send(InviteeReward);
          require(sent, "Not enough funds!");
        }
        
        _mint(msg.sender,  2*10**18);
        MinerList3.push(msg.sender);
        Miners_St3[msg.sender] = true;
        emit New_St3_miner(msg.sender,MinerList3.length, Invitee_Address, "2 IFM Finance");

    }

    function St3_Miners() view public returns(uint) {
    return MinerList3.length;
    }

    function Is_St3_Miner(address _Address) public view returns(bool Miner) {
        if ( Miners_St3[_Address]){
            return true;
        }}




//=================================================================================================================================





    function Mine_Stage_4(address payable Invitee_Address) payable public {
        require (msg.sender == tx.origin, "All Miners should be EOA!");
        bool paid = payable(FeeFunds).send(MiningFee + 0.02 ether);
        require(paid, "Not enough funds!");
        if (!Miners_St4[msg.sender]){
          bool sent = Invitee_Address.send(InviteeReward);
          require(sent, "Not enough funds!");
        } else if (!Miners_St4[Invitee_Address]){
          bool sent = payable(FeeFunds).send(InviteeReward);
          require(sent, "Not enough funds!");
          } else {
          bool sent = payable(FeeFunds).send(InviteeReward);
          require(sent, "Not enough funds!");
        }
        
        _mint(msg.sender,  2*10**18);
        MinerList4.push(msg.sender);
        Miners_St4[msg.sender] = true;
        emit New_St4_miner(msg.sender,MinerList4.length, Invitee_Address, "2 IFM Finance");

    }

    function St4_Miners() view public returns(uint) {
    return MinerList4.length;
    }

    function Is_St4_Miner(address _Address) public view returns(bool Miner) {
        if ( Miners_St4[_Address]){
            return true;
        }}




//=================================================================================================================================




     function Mine_Stage_5(address payable Invitee_Address) payable public {
        require (msg.sender == tx.origin, "All Miners should be EOA!");
        bool paid = payable(FeeFunds).send(MiningFee + 0.02 ether);
        require(paid, "Not enough funds!");
        if (!Miners_St5[msg.sender]){
          bool sent = Invitee_Address.send(InviteeReward);
          require(sent, "Not enough funds!");
        } else if (!Miners_St5[Invitee_Address]){
          bool sent = payable(FeeFunds).send(InviteeReward);
          require(sent, "Not enough funds!");
          } else {
          bool sent = payable(FeeFunds).send(InviteeReward);
          require(sent, "Not enough funds!");
        }
        
        _mint(msg.sender,  2*10**18);
        MinerList5.push(msg.sender);
        Miners_St5[msg.sender] = true;
        emit New_St5_miner(msg.sender,MinerList5.length, Invitee_Address, "2 IFM Finance");

    }

    function St5_Miners() view public returns(uint) {
    return MinerList5.length;
    }

    function Is_St5_Miner(address _Address) public view returns(bool Miner) {
        if ( Miners_St5[_Address]){
            return true;
        }}


//=================================================================================================================================

                           // Mining Stages

//=================================================================================================================================

    function Mining_Timer() internal {
         StartTime = block.timestamp;
         EndTime = StartTime + 1 days;
    }
    function Stage1Mining() public {
      require (Miners_St1[msg.sender], "You are not a Stage 1 Miner!");
      require( totalSupply() <=10000000*10**18, "Stage 1 Mining Is Ended!");
      require( block.timestamp >= EndTime, "Timer is not over!");
        for (uint8 i = 1; i < MinerList1.length; i++) {
        _mint(MinerList1[i], 10*10**18);
        }
        Mining_Timer();
        emit Stage_1_Mining(address (this), MinerList1.length, MinerList1.length*10, MinerList1.length*10/20);
    }

    function Stage2Mining() public {
      require (Miners_St2[msg.sender], "You are not a Stage 2 Miner!");
      require( totalSupply() >=9800000*10**18, "Stage 1 Mining is not yet ended!");
      require( block.timestamp >= EndTime, "Timer is not over!");
      require( totalSupply() <=20000000*10**18, "Stage 2 Mining is Ended!");
        for (uint8 i = 1; i < MinerList2.length; i++) {
        _mint(MinerList2[i], 4*10**18);
        }
        Mining_Timer();
        emit Stage_2_Mining(address (this), MinerList2.length, MinerList2.length*4, MinerList1.length*4/20);
    }

    function Stage3Mining() public {
      require (Miners_St3[msg.sender], "You are not a Stage 3 Miner!");
      require( totalSupply() >=19500000*10**18, "Stage 2 Mining is not yet ended!");
      require( block.timestamp >= EndTime, "Timer is not over!");
      require( totalSupply() <=40000000*10**18, "Stage 3 Mining Is Ended!");
        for (uint8 i = 1; i < MinerList3.length; i++) {
        _mint(MinerList3[i], 2*10**18);
        }
        Mining_Timer();
        emit Stage_3_Mining(address (this), MinerList3.length, MinerList3.length*2, MinerList1.length*2/20);
    }

    function Stage4Mining() public {
      require (Miners_St4[msg.sender], "You are not a Stage 4 Miner!");
      require( totalSupply() >=39000000*10**18, "Stage 3 Mining is not yet ended!");
      require( block.timestamp >= EndTime, "Timer is not over!");
      require( totalSupply() <=80000000*10**18, "Stage 4 Mining Is Ended!");
        for (uint8 i = 1; i < MinerList4.length; i++) {
        _mint(MinerList4[i], 1*10**18);
        }
        Mining_Timer();
        emit Stage_4_Mining(address (this), MinerList4.length, MinerList4.length*1, MinerList1.length*1/20);
    }

    function Stage5Mining() public {
      require (Miners_St5[msg.sender], "You are not a Stage 5 Miner!");
      require( totalSupply() >=79000000*10**18, "Stage 4 Mining is not yet ended!");
      require( block.timestamp >= EndTime, "Timer is not over!");
      require( totalSupply() <=160000000*10**18, "Stage 5 Mining Is Ended!");
        for (uint8 i = 1; i < MinerList5.length; i++) {
        _mint(MinerList5[i], 0.5*10**18);
        }
        Mining_Timer();
        emit Stage_5_Mining(address (this), MinerList5.length, MinerList5.length/2, MinerList1.length/2/20);
    }


}