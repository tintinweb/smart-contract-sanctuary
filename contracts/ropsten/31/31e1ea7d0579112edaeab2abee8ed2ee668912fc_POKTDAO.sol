// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";


/**
 * Pocket DAO Vote Token.
 *
 * @dev This implementation is based on the Open Zeppelin ERC20 implementation, with some modifications.
 * The POKT DAO Vote Token is a non transferable token that holders use to vote by signing messages.
 *
 * Every voter can receive exactly 1 token
 * Once granted a vote can not be taken away
 * The token is distributed through authorized accounts.
 */
contract POKTDAO is Context, IERC20 {
    using SafeMath for uint256;

    modifier onlyAdmin{
        require(admin == msg.sender,"Must be admin account");
        _;
    }

    mapping (address => bool) private _hasVote;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name = "Pocket DAO Vote";
    string private _symbol = "POKTDAO";
    uint8 private _decimals = 0;


    address public admin;
    mapping (address=>uint) TransfersAuthorized;

    function grantTransferAuthorization(address transferer,uint amount) public onlyAdmin{
        TransfersAuthorized[transferer]=amount;
    }

    function revokeTransferAuthorization(address transferer) public onlyAdmin{
        TransfersAuthorized[transferer]=0;
    }

    function changeAdmin(address newAdmin) public onlyAdmin{
        admin = newAdmin;
    }

    constructor() public {
        admin = msg.sender;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     * Returns 1 if account has a vote
     * Returns 0 if account does not have a vote
     */
    function balanceOf(address account) public view override returns (uint256) {
        if(_hasVote[account]==true){
            return(1);
        } else {
            return(0);
        }
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _mint(msg.sender,recipient, amount);
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
     * - `recipient` cannot be the zero address.
     * - `sender` have at least 1 authorized transfer
     * - the caller must have allowance for ``sender``'s tokens of at least 1.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _mint(sender,recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }


    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Increases _totalSupply by 1
     * Sets _hasVote[account] to true
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `amount` must be equal to 1
     * - account must not have a vote
     */
    function _mint(address AuthorizedMinter, address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(AuthorizedMinter, account,amount);

        _totalSupply = _totalSupply.add(amount);
        _hasVote[account] = true;
        emit Transfer(address(0), account, amount);
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
     * `from` must be have at least one transfer authorized
     * `amount` must be equal to 1
     * `to` must not already have a vote
     * Transfer
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {
      require(TransfersAuthorized[from]>0,"Transfers not authorized from this account");
      require(amount==1, "Transfer amount must be 1");
      require(_hasVote[to]==false,"Account already has a Pocket Dao Vote");

      TransfersAuthorized[from] = TransfersAuthorized[from].sub(amount);
     }
}