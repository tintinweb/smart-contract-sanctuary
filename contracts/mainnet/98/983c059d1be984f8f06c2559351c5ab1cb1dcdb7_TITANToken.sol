/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface ITITANVault {
    function balanceOf(address account) external view returns (uint256);

    function addTaxFee(uint256 amount) external returns (bool);
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * TITAN contract
 *
 * Name        : TITAN TOKEN
 * Symbol      : TITAN
 * Total supply: 1,300,000
 * Decimals    : 18
 *
 * ERC20 Token, with the Burnable, Pausable and Ownable from OpenZeppelin
 */
contract TITANToken is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint16 public _taxFee;
    address public _vault;
    address private _tokenOwner;

    uint8 private _initialMaxTransfers;
    uint256 private _initialMaxTransferAmount;

    modifier onlyVault() {
        require(_vault == _msgSender(), "Ownable: caller is not vault");
        _;
    }

    event ChangedTaxFee(address indexed owner, uint16 fee);
    event ChangedVault(
        address indexed owner,
        address indexed oldAddress,
        address indexed newAddress
    );
    event ChangedInitialMaxTransfers(address indexed owner, uint8 count);

    constructor(address tokenOwner) {
        _name = "Titan Token";
        _symbol = "TITAN";
        _decimals = 18;

        _tokenOwner = tokenOwner;

        // set initial tax fee(transfer) fee as 2%
        // It is allow 2 digits under point
        _taxFee = 200;
        _initialMaxTransfers = 50;
        _initialMaxTransferAmount = 1000e18; // initial around  0.1 eth(1000 TITAN)

        _mint(_tokenOwner, 1300e21);
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

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        if (_checkWithoutFee()) {
            _transfer(_msgSender(), recipient, amount);
        } else {
            uint256 taxAmount = amount.mul(uint256(_taxFee)).div(10000);
            uint256 leftAmount = amount.sub(taxAmount);
            _transfer(_msgSender(), _vault, taxAmount);
            _transfer(_msgSender(), recipient, leftAmount);

            ITITANVault(_vault).addTaxFee(taxAmount);
        }

        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        if (_checkWithoutFee()) {
            _transfer(sender, recipient, amount);
        } else {
            uint256 feeAmount = amount.mul(uint256(_taxFee)).div(10000);
            uint256 leftAmount = amount.sub(feeAmount);

            _transfer(sender, _vault, feeAmount);
            _transfer(sender, recipient, leftAmount);
            ITITANVault(_vault).addTaxFee(feeAmount);
        }
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );

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
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function setTaxFee(uint16 fee) external onlyOwner {
        _taxFee = fee;
        emit ChangedTaxFee(_msgSender(), fee);
    }

    function setVault(address vault) external onlyOwner {
        require(vault != address(0), "Invalid vault contract address");
        address oldAddress = _vault;
        _vault = vault;
        emit ChangedVault(_msgSender(), oldAddress, _vault);
    }

    function setInitialMaxTransfers(uint8 count) external onlyOwner {
        _initialMaxTransfers = count;
        emit ChangedInitialMaxTransfers(_msgSender(), count);
    }

    function burnFromVault(uint256 amount) external onlyVault returns (bool) {
        _burn(_vault, amount);
        return true;
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if (recipient != _vault) {
            // for anti-bot
            if (sender != _vault && sender != _tokenOwner) {
                if (_initialMaxTransfers != 0) {
                    require(
                        amount <= _initialMaxTransferAmount,
                        "Can't transfer more than 1000 TITAN for initial 50 times."
                    );
                    _initialMaxTransfers--;
                }
            }
        }

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

    function _checkWithoutFee() internal view returns (bool) {
        if (_msgSender() == _vault || _msgSender() == _tokenOwner) {
            return true;
        } else {
            return false;
        }
    }
}