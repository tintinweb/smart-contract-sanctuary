// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Context.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./IMyNFT.sol";


contract ERC20 is Context, IERC20, Ownable {
    using Address for address;

    struct Vesting {
        uint256 amount;
        uint256 deadline;
    }

    mapping (address => Vesting) public vestings;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint8 private _decimals = 18;
    string private _name;
    string private _symbol;

    MyNFT private _mainContract;


    address public _IDOWallet = 0xf23EA396D1Ee6eCB82677CDF820e4e3C23350a67;
    uint256 private _IDOAmount;
    uint256 public _treasuryBalance;
    uint256 public _liquidityBalance;
    uint256 public _vestingBalance;

    event ItemBought(address indexed buyer, uint256 _nftID, uint256 _amount);

    constructor(address cOwner) Ownable (cOwner) {
        _name = "TestERC20";
        _symbol = "TERC20";
        _totalSupply = 20000000 * 10 ** _decimals;
        _treasuryBalance = 1000 * 10 ** _decimals;
        _liquidityBalance = 1000 * 10 ** _decimals;
        _vestingBalance = 1000 * 10 ** _decimals;
        _IDOAmount = 100 * 10 ** _decimals;
        _balances[_IDOWallet] = _IDOAmount;
        emit Transfer(address(0), _IDOWallet, _IDOAmount);
        _balances[address(this)] = _totalSupply -_IDOAmount;
        emit Transfer(address(0), address(this), _totalSupply -_IDOAmount);
        addVesting(0x3FC1807c4C49cE0823be783FC45950239Db35c7d, 300 * 10 ** _decimals, block.timestamp + 1000);
        addVesting(0x882592060E67686B1314d23D1F5BDB1a052851C1, 300 * 10 ** _decimals, block.timestamp + 2000);
        addVesting(0x4E458d6b5b1a6B5a0593A5D84572f9F6185893eB, 400 * 10 ** _decimals, block.timestamp + 3000);
    }


    function setMainNFT(address _contract) external onlyOwner {
        require(_contract != address(0), "Zero address for NFT contract is not acceptable");
        _mainContract = MyNFT(_contract);

    }


    function addVesting(address _wallet, uint256 _amount, uint256 _deadline) internal {

        Vesting memory vst = Vesting({
                                    amount: _amount,
                                    deadline: _deadline
                                });
        vestings[_wallet] = vst;
    }


    function claimVesting(uint256 amount) external {
        require(amount > 0, "Claimed amount cannot be zero");
        require(vestings[_msgSender()].amount >= amount, "Insufficient token amount to claim");
        require(vestings[_msgSender()].deadline > block.timestamp, "Your vesting release time was not reached");
        _balances[address(this)] = _balances[address(this)] - amount;
        _balances[_msgSender()] = _balances[_msgSender()] + amount;
        _vestingBalance -= amount;
        vestings[_msgSender()].amount -= amount;
        emit Transfer(address(this), _msgSender(), amount);
    }


    function claim(uint256 _amount, uint8 _mode) external {
        require((_mode == 1 || _mode == 2), "Invalid mode. Use '1' for treasury claim and '2' for liquidity claim");
        if (_mode == 1 ) {
            require(_treasuryBalance >= _amount, "Insufficient amount to claim");
            _balances[address(this)] = _balances[address(this)] - _amount;
            _balances[_msgSender()] = _balances[_msgSender()] + _amount;
            _treasuryBalance -= _amount;
            emit Transfer(address(this), _msgSender(), _amount);
        } else {
            require(_liquidityBalance >= _amount, "Insufficient amount to claim");
            _balances[address(this)] = _balances[address(this)] - _amount;
            _balances[_msgSender()] = _balances[_msgSender()] + _amount;
            _liquidityBalance -= _amount;
            emit Transfer(address(this), _msgSender(), _amount);
        }
    }


    function buyItem(uint256 _amount, uint256 _category, bool  _mode) external {
        require(_amount > 0, "Token amount cannot be zero");
        require(_balances[_msgSender()] >= _amount, "Insufficient token balance to buy item");
        _balances[_msgSender()] = _balances[_msgSender()] - _amount;
        _balances[address(this)] = _balances[address(this)] + _amount;
        _treasuryBalance += _amount;
        emit Transfer(_msgSender(), address(this), _amount);
        if (!_mode) {
            uint256 result = _mainContract.createFromERC20(_msgSender(), _category);
            emit ItemBought(_msgSender(), result, _amount);
        } else {
            emit ItemBought(_msgSender(), 0, _amount);

        }

    }


    function name() public view virtual override returns (string memory) {
        return _name;
    }


    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }


    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }


    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
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


        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

    }


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

}