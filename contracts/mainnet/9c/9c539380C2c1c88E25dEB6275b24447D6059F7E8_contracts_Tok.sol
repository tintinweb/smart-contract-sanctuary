// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";


contract Tok is IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;
    mapping(address => uint256) public votet;
    mapping(address => address) public votedad;
    mapping(address => uint256) public voted;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private immutable _decimals;
    uint256 public burnedSupply;
    address public treasuryDAO;

    event NewTreasury(address indexed treasuryad);

    /**
     * @dev values for {name} {symbol}, initializes {decimals}
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(address ad) public {
        _name = "Sprout";
        _symbol = "Seed";
        _decimals = 18;
        treasuryDAO = ad;
        _totalSupply = 1e25; // 10000000 * 1e18
        _balances[msg.sender] = 1e25;
        emit Transfer(address(0), msg.sender, 1e25);
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`.
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
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}. Uses burn abstraction for balance updates without gas and universally.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return
            (_balances[account] * _totalSupply) / (_totalSupply - burnedSupply);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        override
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero ress.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    /**
     * @dev Update treasury with majority.
     */
    function setNewTDao(address treasury) public returns (bool) {
        require(
            votet[treasury] > uint256((_totalSupply * 51) / 100),
            "Sprout: setNewTDao requires majority approval"
        );
        require(msg.sender==tx.origin, "Sprout: setNewTDao requires non contract");
        treasuryDAO = treasury;
        emit NewTreasury(treasury);
        return true;
    }

    /**
     * @dev Update votes. Votedad voted address by sender. Votet treasury address votes. Voted sender vote amount.
     */
    function updateVote(address treasury) public returns (bool) {
        votet[votedad[msg.sender]] -= voted[msg.sender];
        votet[treasury] += uint256(balanceOf(msg.sender));
        votedad[msg.sender] = treasury;
        voted[msg.sender] = uint256(balanceOf(msg.sender));
        return true;
    } //

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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
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
     * - `sender`must have a balance of at least `amount`.
     */
    

    function _transfer(
        address sender,
        address recipient,
        uint256 amountt
    ) internal {
        uint256 amount;
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        amount = uint256(
            (amountt * (_totalSupply - burnedSupply)) / _totalSupply
        );
        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(
            uint256((amount * 99) / 100)
        );

        if (voted[sender] > 0) {
            if (voted[sender] > amountt) {
                votet[votedad[sender]] = votet[votedad[sender]] - amountt;
                voted[sender] = voted[sender] - amountt;
            } else {
                votet[votedad[sender]] -= voted[sender];
                voted[sender] = 0;
            }
        }
        _balances[treasuryDAO] = _balances[treasuryDAO].add(
            uint256(amount / 200)
        );
        _burn(uint256(amount / 200));
        emit Transfer(sender, recipient, amountt);
    }

       event Memo(address indexed from, address indexed to, uint256 indexed value, string memo);

       function transferx(address[] memory to, uint[] memory tokens, string[] memory memo) public returns (bool success) {
         require(to.length == tokens.length && tokens.length == memo.length); 
         for (uint i = 0; i < to.length; i++) {
         require(transfer(to[i], tokens[i]));
         emit Memo(msg.sender, to[i], tokens[i], memo[i]);
       }
       return true;
       } 
    

    /**
     * @dev Destroys `amount` tokens from `account`, reducing 
     * and updating burnd tokens for abstraction
     *
     */
    function _burn(uint256 amount) internal {
        burnedSupply = burnedSupply + amount;
    }
function burnt(uint256 amountt) public returns (bool success) {
        address sender=msg.sender;
        uint256 amount;
        require(sender != address(0), "ERC20: transfer from the zero address");
        amount = uint256(
            (amountt * (_totalSupply - burnedSupply)) / _totalSupply
        );
        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        if (voted[sender] > 0) {
            if (voted[sender] > amountt) {
                votet[votedad[sender]] = votet[votedad[sender]] - amountt;
                voted[sender] = voted[sender] - amountt;
            } else {
                votet[votedad[sender]] -= voted[sender];
                voted[sender] = 0;
            }
        }
        _balances[treasuryDAO] = _balances[treasuryDAO].add(
            uint256(amount / 200)
        );
_burn(uint256(amount * 99) / 100);
        _burn(uint256(amount / 200));
        emit Transfer(sender, address(0), amount);
return true;
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

}
