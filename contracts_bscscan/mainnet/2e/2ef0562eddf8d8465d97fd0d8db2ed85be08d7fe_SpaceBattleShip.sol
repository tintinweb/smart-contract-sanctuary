/**
 *Submitted for verification at BscScan.com on 2022-01-08
*/

pragma solidity ^0.8.10;

// SPDX-License-Identifier: MIT
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    constructor() {
        _setOwner(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }
    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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


interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}



interface IERC721 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}





interface IDexFactory {
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



interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}

interface DividendPayingTokenOptionalInterface {
    function withdrawableDividendOf(address _owner)
        external
        view
        returns (uint256);
    function withdrawnDividendOf(address _owner)
        external
        view
        returns (uint256);
    function accumulativeDividendOf(address _owner)
        external
        view
        returns (uint256);
}

interface DividendPayingTokenInterface {
    function dividendOf(address _owner) external view returns (uint256);
    function distributeDividends() external payable;
    function withdrawDividend() external;
    event DividendsDistributed(address indexed from, uint256 weiAmount);
    event DividendWithdrawn(address indexed to, uint256 weiAmount);
}



library SafeMath {
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

library SignedSafeMath {
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}


library SafeCast {
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(
            value <= type(uint224).max,
            "SafeCast: value doesn't fit in 224 bits"
        );
        return uint224(value);
    }
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(
            value <= type(uint128).max,
            "SafeCast: value doesn't fit in 128 bits"
        );
        return uint128(value);
    }
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(
            value <= type(uint96).max,
            "SafeCast: value doesn't fit in 96 bits"
        );
        return uint96(value);
    }
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(
            value <= type(uint64).max,
            "SafeCast: value doesn't fit in 64 bits"
        );
        return uint64(value);
    }
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(
            value <= type(uint32).max,
            "SafeCast: value doesn't fit in 32 bits"
        );
        return uint32(value);
    }
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(
            value <= type(uint16).max,
            "SafeCast: value doesn't fit in 16 bits"
        );
        return uint16(value);
    }
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(
            value <= type(uint8).max,
            "SafeCast: value doesn't fit in 8 bits"
        );
        return uint8(value);
    }
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }
    function toInt128(int256 value) internal pure returns (int128) {
        require(
            value >= type(int128).min && value <= type(int128).max,
            "SafeCast: value doesn't fit in 128 bits"
        );
        return int128(value);
    }
    function toInt64(int256 value) internal pure returns (int64) {
        require(
            value >= type(int64).min && value <= type(int64).max,
            "SafeCast: value doesn't fit in 64 bits"
        );
        return int64(value);
    }
    function toInt32(int256 value) internal pure returns (int32) {
        require(
            value >= type(int32).min && value <= type(int32).max,
            "SafeCast: value doesn't fit in 32 bits"
        );
        return int32(value);
    }
    function toInt16(int256 value) internal pure returns (int16) {
        require(
            value >= type(int16).min && value <= type(int16).max,
            "SafeCast: value doesn't fit in 16 bits"
        );
        return int16(value);
    }
    function toInt8(int256 value) internal pure returns (int8) {
        require(
            value >= type(int8).min && value <= type(int8).max,
            "SafeCast: value doesn't fit in 8 bits"
        );
        return int8(value);
    }
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(
            value <= uint256(type(int256).max),
            "SafeCast: value doesn't fit in an int256"
        );
        return int256(value);
    }
}

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint256) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }
    function get(Map storage map, address key) public view returns (uint256) {
        return map.values[key];
    }
    function getIndexOfKey(Map storage map, address key)
        public
        view
        returns (int256)
    {
        if (!map.inserted[key]) {
            return -1;
        }
        return int256(map.indexOf[key]);
    }
    function getKeyAtIndex(Map storage map, uint256 index)
        public
        view
        returns (address)
    {
        return map.keys[index];
    }
    function size(Map storage map) public view returns (uint256) {
        return map.keys.length;
    }
    function set(
        Map storage map,
        address key,
        uint256 val
    ) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }
    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }
        delete map.inserted[key];
        delete map.values[key];
        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];
        map.indexOf[lastKey] = index;
        delete map.indexOf[key];
        map.keys[index] = lastKey;
        map.keys.pop();
    }
}


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
        return 9;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
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
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
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
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


contract SafeToken is Ownable {
    address payable safeManager;
    constructor() {
        safeManager = payable(msg.sender);
    }
    function setSafeManager(address payable _safeManager) public onlyOwner {
        safeManager = _safeManager;
    }
    function withdraw(address _token, uint256 _amount) external {
        require(msg.sender == safeManager);
        IERC20(_token).transfer(safeManager, _amount);
    }
    function withdrawBNB(uint256 _amount) external {
        require(msg.sender == safeManager);
        safeManager.transfer(_amount);
    }
}


contract DividendPayingToken is
    ERC20,
    DividendPayingTokenInterface,
    DividendPayingTokenOptionalInterface
{
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using SafeCast for uint256;
    using SafeCast for int256;
    uint256 internal constant magnitude = 2**128;
    uint256 internal magnifiedDividendPerShare;
    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;
    uint256 public totalDividendsDistributed;
    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {}
    receive() external payable {
        distributeDividends();
    }
    function distributeDividends() public payable override {
        require(totalSupply() > 0, "total suppy must be greater than zero");

        if (msg.value > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare.add(
                (msg.value).mul(magnitude) / totalSupply()
            );
            emit DividendsDistributed(msg.sender, msg.value);

            totalDividendsDistributed = totalDividendsDistributed.add(
                msg.value
            );
        }
    }
    function withdrawDividend() public virtual override {
        _withdrawDividendOfUser(payable(msg.sender));
    }
    function _withdrawDividendOfUser(address payable user)
        internal
        returns (uint256)
    {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] = withdrawnDividends[user].add(
                _withdrawableDividend
            );
            emit DividendWithdrawn(user, _withdrawableDividend);
            (bool success, ) = user.call{
                value: _withdrawableDividend,
                gas: 3000
            }("");
            if (!success) {
                withdrawnDividends[user] = withdrawnDividends[user].sub(
                    _withdrawableDividend
                );
                return 0;
            }
            return _withdrawableDividend;
        }
        return 0;
    }
    function dividendOf(address _owner) public view override returns (uint256) {
        return withdrawableDividendOf(_owner);
    }
    function withdrawableDividendOf(address _owner)
        public
        view
        override
        returns (uint256)
    {
        return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
    }
    function withdrawnDividendOf(address _owner)
        public
        view
        override
        returns (uint256)
    {
        return withdrawnDividends[_owner];
    }
    function accumulativeDividendOf(address _owner)
        public
        view
        override
        returns (uint256)
    {
        return
            magnifiedDividendPerShare
                .mul(balanceOf(_owner))
                .toInt256()
                .add(magnifiedDividendCorrections[_owner])
                .toUint256() / magnitude;
    }
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual override {
        require(false);
        int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256();
        magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from]
            .add(_magCorrection);
        magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(
            _magCorrection
        );
    }
    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);
        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[
            account
        ].sub((magnifiedDividendPerShare.mul(value)).toInt256());
    }
    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);
        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[
            account
        ].add((magnifiedDividendPerShare.mul(value)).toInt256());
    }
    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = balanceOf(account);
        if (newBalance > currentBalance) {
            uint256 mintAmount = newBalance.sub(currentBalance);
            _mint(account, mintAmount);
        } else if (newBalance < currentBalance) {
            uint256 burnAmount = currentBalance.sub(newBalance);
            _burn(account, burnAmount);
        }
    }
}




contract StarBattleShipDividendTracker is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using IterableMapping for IterableMapping.Map;
    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;
    mapping(address => bool) public excludedFromDividends;
    mapping(address => uint256) public lastClaimTimes;
    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;
    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event Claim(
        address indexed account,
        uint256 amount,
        bool indexed automatic
    );
    constructor()
        DividendPayingToken("StarBattleShip_Dividend_Tracker","StarBattleShip_Dividend_Tracker")
    {
        claimWait = 14400;
        minimumTokenBalanceForDividends = 10000 * (10**9);
    }

    function _transfer(
        address,
        address,
        uint256
    ) internal pure override {
        require(false, "StarBattleShip_Dividend_Tracker: No transfers allowed");
    }
    function _minimumTokenBalanceForReward(uint256 amount) public onlyOwner {
        minimumTokenBalanceForDividends = amount;
    }
    function withdrawDividend() public pure override {
        require(false,"StarBattleShip_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main StarBattleShip contract.");
    }
    function excludeFromDividends(address account) external onlyOwner {
        require(!excludedFromDividends[account],"cant be excluded from dividends");
        excludedFromDividends[account] = true;
        _setBalance(account, 0);
        tokenHoldersMap.remove(account);
        emit ExcludeFromDividends(account);
    }
    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400,"StarBattleShip_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait,"StarBattleShip_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }
    function getLastProcessedIndex() external view returns (uint256) {
        return lastProcessedIndex;
    }
    function getNumberOfTokenHolders() external view returns (uint256) {
        return tokenHoldersMap.keys.length;
    }
    function getAccount(address _account) public view returns (address account,int256 index,int256 iterationsUntilProcessed,uint256 withdrawableDividends,uint256 totalDividends,uint256 lastClaimTime,uint256 nextClaimTime,uint256 secondsUntilAutoClaimAvailable)
    {
        account = _account;
        index = tokenHoldersMap.getIndexOfKey(account);
        iterationsUntilProcessed = -1;
        if (index >= 0) {if (uint256(index) > lastProcessedIndex) {iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
        } 
        else {uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length >lastProcessedIndex? tokenHoldersMap.keys.length.sub(lastProcessedIndex): 0;
        iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
        }
        }
        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);
        lastClaimTime = lastClaimTimes[account];
        nextClaimTime = lastClaimTime > 0 ? lastClaimTime.add(claimWait) : 0;
        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp? nextClaimTime.sub(block.timestamp): 0;
    }
    function getAccountAtIndex(uint256 index) public view returns (address,int256,int256,uint256,uint256,uint256,uint256,uint256)
    {
        if (index >= tokenHoldersMap.size()) {return (0x0000000000000000000000000000000000000000,-1,-1,0,0,0,0,0);
        }
        address account = tokenHoldersMap.getKeyAtIndex(index);
        return getAccount(account);
    }
    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if (lastClaimTime > block.timestamp) {return false;
        }
        return block.timestamp.sub(lastClaimTime) >= claimWait;
    }
    function setBalance(address payable account, uint256 newBalance) external onlyOwner{
        if (excludedFromDividends[account]) {return;}
        if (newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);tokenHoldersMap.set(account, newBalance);
        } else {_setBalance(account, 0);tokenHoldersMap.remove(account);
        } processAccount(account, true);
    }
    function process(uint256 gas) public returns (uint256,uint256,uint256)
    {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;
        if (numberOfTokenHolders == 0) {return (0, 0, lastProcessedIndex);
        }
        uint256 _lastProcessedIndex = lastProcessedIndex;
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;
        uint256 claims = 0;
        while (gasUsed < gas && iterations < numberOfTokenHolders) {_lastProcessedIndex++;
        if (_lastProcessedIndex >= tokenHoldersMap.keys.length) {_lastProcessedIndex = 0;
        }
        address account = tokenHoldersMap.keys[_lastProcessedIndex];
        if (canAutoClaim(lastClaimTimes[account])) {
            if (processAccount(payable(account), true)) {claims++;
            }
            }
            iterations++;
            uint256 newGasLeft = gasleft();
            if (gasLeft > newGasLeft) {gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }
            gasLeft = newGasLeft;
        }
        lastProcessedIndex = _lastProcessedIndex;
        return (iterations, claims, lastProcessedIndex);
    }
    function processAccount(address payable account, bool automatic) public
        onlyOwner returns (bool)
    {
        uint256 amount = _withdrawDividendOfUser(account);
        if (amount > 0) {lastClaimTimes[account] = block.timestamp;
        emit Claim(account, amount, automatic);
        return true;
        }
        return false;
    }
}


/**
 * @notice NFT is a contract who is ment to be inherited by the BattleShip contract to add NFT functionalities
 */
contract NFT is Ownable{
 
    IERC721Enumerable internal NFTcontract;
    address private admin;

    /**
     * @notice
     * Every NFT Type will have a modifier
     * This modifier will be devided by 100 and applied to the resp. rate
     */
    uint8 internal basicModifierInPercent;
    uint8 internal rareModifierInPercent;
    uint256 internal limitedModifierInPercent;

    /**
     * @notice
     * Every NFT Type will have a cap
     * E.g. a user can max get a bonus of 10 * 2% from basic NFTS
     * So basic cap will be 10
     */
    uint256 internal basicCap;
    uint256 internal rareCapInPercent;
    uint256 internal limitedCapInPercent;

    /**
     * @notice
     * Every NFT will be a mapping from the NFT ID to the NFT object
     * 0 is basic
     * 1 is rare
     * 2 is limited
     */
    mapping(uint256 => uint8) internal NFTs;

    /**
     * @notice
     * Every NFT will be a mapping from the NFT ID to the NFT object
     */
    uint256[] limitedNFTList;

    constructor() {
        limitedNFTList = [3500,3501,3502,3503,3504,3505,3506,3507,3508,3509];
        NFTcontract = IERC721Enumerable(0x7cF5aaAd9F42fDF6CeD657B5D5182Fc9f6BbD844);
    }

    /**
     * @notice
     * A stake struct is used to represent the way we store stakes,
     * A Stake will contain the users address, the amount staked and a timestamp,
     * Since which is when the stake was made
     */
    struct BasicNFT {
        uint256 id;
        address addressInContract;
        uint256 since;
        uint256 claimable;
    }

    /**
     * @notice calculate Staking rate
     * @dev
     * First get amount of token holding on
     * add total percent variable
     * add amountOfBasicTokens variable
     * add amountOfRareTokens variable
     * For every nft check if nft is in our mapping (string.lengths is 0)
     * Check for type (basic / rare)
     * add + to amountOfX variable
     * now check if amountOfRare or Basic is bigger than cap
     * @param staker account of a user
     * @return Total amount percentage that the user can claim
     */
    function calculateExtraStakingRate(address staker) public view returns (uint256)
    {
        uint256 amountOfToken = NFTcontract.balanceOf(staker);
        if (amountOfToken == 0) {return 0;
        }
        uint8 totalPercent = 0;
        uint8 amountOfBasicTokens = 0;
        uint8 amountOfRareTokens = 0;

        for (uint256 index = 0; index < amountOfToken; index++) {
            uint256 tokenId = NFTcontract.tokenOfOwnerByIndex(staker, index);
            uint8 nftType = NFTs[tokenId];
            if (nftType == 1) {
                amountOfBasicTokens += 1;
            } else if (nftType == 2) {
                amountOfRareTokens += 1;
            }
        }

        totalPercent =
            (amountOfBasicTokens * basicModifierInPercent) +
            (amountOfRareTokens * rareModifierInPercent);

        return totalPercent;
    }

function setNFTContractAdmin(address _admin) external onlyOwner{
        admin = _admin;
    }

    function setNFTContractAddress(address nftContract) external onlyOwner{
        NFTcontract = IERC721Enumerable(nftContract);
    }

    /**
     *  @notice get a list of holders of the limited NFTs that qualify for marketing bonus
     *  @dev The amount of people that qualify for the bonus and the amount of NFTs are both 10
     *       That way we can basically iterate over limitedNFTList, get the token IDs and see who is the owner
     *       For that we can call the ffc Token (specified in construcor) with the ownerOf function
     *  @return List(10) of address that hold
     */
    function _getMarketingPayoutContracts()
        internal view returns (address[] memory)
    {
        address[] memory bonusAddresses = new address[](10);

        for (uint256 i = 0; i < 10; i++) {
            uint256 tokenId = limitedNFTList[i];
            bonusAddresses[i] = NFTcontract.ownerOf(tokenId);
        }

        return bonusAddresses;
    }


    /// @param _nftId Id of the NFT from the ffc token contract
    /// @param _nftType NFT type. 0 = basic, 1 = rare, limited not listed here;
    function addNFT(uint256 _nftId, uint8 _nftType) external {

        NFTs[_nftId] = _nftType;
    }

    /**
     * @notice Returns type of NFT
     * @param _nftId Id of the NFT from the ffc token contract
     * @return NFT type. 0 = not found, 1 = basic, 2 = rare,  limited not listed here;
     */
    function getNFT(uint256 _nftId) external view returns (uint8) {
        return NFTs[_nftId];
    }

    /**
     * @notice Returns list of limited NFTs
     * @return  List of ten limited nfts
     */
    function getLimitedNFTs() external view returns (uint256[] memory) {
        return limitedNFTList;
    }
}


contract Stakeable is Ownable, NFT {
    /**
     * @notice start at stakeholders[1] so we can use 0 for error in the mapping
     */
    constructor() NFT() {
        // This push is needed so we avoid index 0 causing bug of index-1
        stakeholders.push();
        currentApy10days = 250;
        currentApy30days = 500;
        currentApy60days = 550;
        currentApy90days = 650;
    }

    /**
     * @notice APYs
     * This will give users 0.1% reward for each staked token / H
     */

    uint256 currentApy10days;
    uint256 currentApy30days;
    uint256 currentApy60days;
    uint256 currentApy90days;

    /**
     * @notice
     * A stake struct is used to represent the way we store stakes,
     * A Stake will contain the users address, the amount staked and a timestamp,
     * Since which is when the stake was made
     */
    struct Stake {
        address user;
        uint256 amount;
        uint256 stakedDays;
        uint256 since;
        uint256 dueDate;
        uint256 baseRate;
        uint256 claimableReward;
    }

    /**
     * @notice Stakeholder is a staker that has active stakes
     */
    struct Stakeholder {
        address user;
        Stake[] address_stakes;
    }

    /**
     * @notice
     * StakingSummary is a struct that is used to contain all stakes performed by a certain account
     */
    struct StakingSummary {
        uint256 total_amount;
        Stake[] stakes;
    }

    /**
     * @notice
     *   This is a array where we store all Stakes that are performed on the Contract
     *   The stakes for each address are stored at a certain index, the index can be found using the stakes mapping
     */
    Stakeholder[] internal stakeholders;
    /**
     * @notice
     * stakes is used to keep track of the INDEX for the stakers in the stakes array
     */
    mapping(address => uint256) internal stakes;
    /**
     * @notice Staked event is triggered whenever a user stakes tokens, address is indexed to make it filterable
     */
    event Staked(
        address indexed user,
        uint256 amount,
        uint256 stakedDays,
        uint256 index,
        uint256 timestamp,
        uint256 dueDate,
        uint256 baseRate
    );

    /**
     * @notice _addStakeholder takes care of adding a stakeholder to the stakeholders array
     */
    function _addStakeholder(address staker) internal returns (uint256) {
        // Push a empty item to the Array to make space for our new stakeholder
        stakeholders.push();
        // Calculate the index of the last item in the array by Len-1
        uint256 userIndex = stakeholders.length - 1;
        // Assign the address to the new index
        stakeholders[userIndex].user = staker;
        // Add index to the stakeHolders
        stakes[staker] = userIndex;
        return userIndex;
    }

    /// @notice Calculates the earliest point in time when user can claim the takes
    /// @param _days Number of days in the time period
    /// @return Timestamp of point in time after time period
    function _calculateDueDate(uint256 _days) internal view returns (uint256) {
        return block.timestamp + (_days * 1 days);
    }

    /**
     * @notice
     * _Stake is used to make a stake for an sender. It will remove the amount staked from the stakers account and place those tokens inside a stake container
     * StakeID
     */
    function _stake(uint256 _amount, uint256 _days) internal {
        // Simple check so that user does not stake 0
        require(_amount > 0, "Cannot stake nothing");
        require(
            _days == 10 || _days == 30 || _days == 60 || _days == 90,
            "Variable _days must be 30, 60 or 90");

        uint256 _apy;

        if (_days == 10) {
            _apy = currentApy10days;
        } else if (_days == 30) {
            _apy = currentApy30days;
        } else if (_days == 60) {
            _apy = currentApy60days;
        } else if (_days == 90) {
            _apy = currentApy90days;
        }

        uint256 extraStakingRate = calculateExtraStakingRate(msg.sender);

        uint256 stakingRateTotal = extraStakingRate + _apy;

        // Calculates the earliest point in time when user can claim the takes
        uint256 dueDate = _calculateDueDate(_days);

        // Mappings in solidity creates all values, but empty, so we can just check the address
        uint256 index = stakes[msg.sender];
        // block.timestamp = timestamp of the current block in seconds since the epoch
        uint256 timestamp = block.timestamp;
        // See if the staker already has a staked index or if its the first time
        if (index == 0) {
            // This stakeholder stakes for the first time
            // We need to add him to the stakeHolders and also map it into the Index of the stakes
            // The index returned will be the index of the stakeholder in the stakeholders array
            index = _addStakeholder(msg.sender);
        }

        // Use the index to push a new Stake
        // push a newly created Stake with the current block timestamp.
        stakeholders[index].address_stakes.push(
            // user; amount; since; dueDate; baseRate; claimableReward;
            Stake(msg.sender, _amount, _days, timestamp, dueDate, stakingRateTotal, 0));

        // Emit an event that the stake has occurred
        emit Staked(msg.sender, _amount, _days, index, timestamp, dueDate, _apy);
    }

    /**
     * @notice
     * calculateStakeReward is used to calculate how much a user should be rewarded for their stakes
     * and the duration the stake has been active
     * @dev
     * Example:
     * Stake calculation is:
     * (days / 356) * token * rate / 100
     * block.timestamp = 1670872603 // Mon Dec 12 2022 19:16:43
     * _current_stake.since = 1639336603 // Mon Dec 12 2021 19:16:43
     * _current_stake.amount = 1000
     * _current_stake.baseRate = 500%
     * So block.timestamp - _current_stake.since) / 365 days =>
     *  1670872603 - 1639336603 / 365 * 86400 => 1
     * Also 1 * 1000 * 500 / 100
     * Der reward wäre dann dementsprechend bei 5000
     */
    function calculateStakeReward(Stake memory _current_stake)
        internal view returns (uint256)
    {
        return
            (((block.timestamp - _current_stake.since) *
                _current_stake.amount) * _current_stake.baseRate) /
            (365 days * 100);
    }

    /**
     * @notice
     * withdrawStake takes in an amount and a index of the stake and will remove tokens from that stake
     * Notice index of the stake is the users stake counter, starting at 0 for the first stake
     * Will return the amount to MINT onto the account
     * Will also calculateStakeReward and reset timer
     */
    function _withdrawStake(uint256 amount, uint256 index)
        internal returns (uint256, uint256)
    {
        // Grab user_index which is the index to use to grab the Stake[]
        uint256 user_index = stakes[msg.sender];
        Stake memory current_stake = stakeholders[user_index].address_stakes[
            index
        ];
        require(
            current_stake.dueDate < block.timestamp,
            "Staking: Stake can not be claimed yet");
        require(
            current_stake.amount >= amount,
            "Staking: Cannot withdraw more than you have staked");

        // Calculate available Reward first before we start modifying data
        uint256 reward = calculateStakeReward(current_stake);
        // Remove by subtracting the money unstaked
        current_stake.amount = current_stake.amount - amount;
        // If stake is empty, 0, then remove it from the array of stakes
        if (current_stake.amount == 0) {
            delete stakeholders[user_index].address_stakes[index];
        } else {
            // If not empty then replace the value of it
            stakeholders[user_index]
                .address_stakes[index]
                .amount = current_stake.amount;
            // Reset timer of stake
            stakeholders[user_index].address_stakes[index].since = block
                .timestamp;
        }

        return (amount, reward);
    }

    /**
     * @notice
     * hasStake is used to check if a account has stakes and the total amount along with all the separate stakes
     */
    function hasStake(address _staker) public view returns (StakingSummary memory)
    {
        // totalStakeAmount is used to count total staked amount of the address
        uint256 totalStakeAmount;
        // Keep a summary in memory since we need to calculate this
        StakingSummary memory summary = StakingSummary(
            0,
            stakeholders[stakes[_staker]].address_stakes);
        // Iterate all stakes and grab amount of stakes
        for (uint256 s = 0; s < summary.stakes.length; s += 1) {
            uint256 availableReward = calculateStakeReward(summary.stakes[s]);
            summary.stakes[s].claimableReward = availableReward;
            totalStakeAmount = totalStakeAmount + summary.stakes[s].amount;
        }
        // Assign calculate amount to summary
        summary.total_amount = totalStakeAmount;
        return summary;
    }

    /** @notice Set APY
     * @dev Set the APY according to days
     * currentApy10days = 10 days
     * currentApy30days = 30 days
     * currentApy60days = 60 days
     * currentApy90days = 90 days
     * The percentage has to be set in place
     * @param _days selects for which duration the apy should be set
     * @param _apy sets the apy in percent
     */
    function setApy(uint256 _days, uint256 _apy) external onlyOwner {
        require(
            _days == 10 || _days == 30 || _days == 60 || _days == 90,
            "Variable _days must be 10, 30, 60 or 90");
        if (_days == 10) {
            currentApy10days = _apy;
        } else if (_days == 30) {
            currentApy30days = _apy;
        } else if (_days == 60) {
            currentApy60days = _apy;
        } else if (_days == 90) {
            currentApy90days = _apy;
        }
    }

    /**
     * @notice
     * getApy returns the current APY for given days
     * @param _days selects for which duration the apy should return
     */
    function getApy(uint256 _days) public view returns (uint256) {
        require(
            _days == 10 || _days == 30 || _days == 60 || _days == 90,
            "Variable _days must be 10, 30, 60 or 90");
        if (_days == 10) {
            return currentApy10days;
        } else if (_days == 30) {
            return currentApy30days;
        } else if (_days == 60) {
            return currentApy60days;
        } else if (_days == 90) {
            return currentApy90days;
        } else {
            return 0;
        }
    }

}





/**
 *
 *                    `. ___
 *                   __,' __`.                _..----....____
 *       __...--.'``;.   ,.   ;``--..__     .'    ,-._    _.-'
 * _..-''-------'   `'   `'   `'     O ``-''._   (,;') _,'
 *'________________            Planet         \`-._`-','
 *`._              ```````````-Express-.___   '-.._'-:
 *   ```--.._      ,.           SBS       ````--...__\-.
 *           `.--. `-`                       ____    |  |`
 *             `. `.                       ,'`````.  ;  ;`
 *               `._`.        __________   `.      \'__/`
 *                  `-:._____/______/___/____`.     \  `
 *                              |       `._    `.    \
 *                              `._________`-.   `.   `.___
 *                                            SSt  `------'`
 */
contract SpaceBattleShip is Ownable, Stakeable, ERC20, SafeToken {
    IDexRouter public router;
    StarBattleShipDividendTracker public dividendTracker;
    



    uint256 private calculatedTotalSupply = 100000000 * (10**9);
    uint256 private _maxTxAmountBuy = calculatedTotalSupply;
    uint256 private _maxTxAmountSell = calculatedTotalSupply / 100;
	uint256 private _maxWalletAmount = calculatedTotalSupply;

    uint256 public bnbRewardFee = 30;
    uint256 public liquidityFee = 20;
    uint256 public marketingFee = 40;
    uint256 public totalFees = bnbRewardFee + liquidityFee + marketingFee;
    uint256 public extraFeeOnSell = 90;
    uint256 public feeDenominator = 1000;
    bool public feeOnNonTrade = false;
    bool private isSell = false;

    // Fee for selling on website
    uint256 public websiteSellFee = totalFees + extraFeeOnSell - 10;
    uint256 private fractionOfFeeAsTokens = 4;
    // Fee for buying on website
    uint256 public websiteBuyFee = totalFees - 10;
    address pcs2BNBPair;
    address[] public pairs;
	bool public swapEnabled = true;
    uint256 public swapThreshold = calculatedTotalSupply / 20000;
    uint256 public maxSwapAmount = calculatedTotalSupply / 200;
    bool inSwap;
    modifier swapping() {
		inSwap = true;
		_;
		inSwap = false;
	}

    address payable public marketingWallet = payable(0xABfDD057B0705F824C023Ea7002148A9FBe936de);
    address payable private devWallet = payable(0xe6497e1F2C5418978D5fC2cD32AA23315E7a41Fb);
    uint256 private devSalaryBlocks = 86400;
    uint256 private percentToDev = 10;
    uint256 private percentToLimitedNFT = 0;

    

    address private _parking = address(this);
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    // Variables for launch
    uint256 public launchedAt = 0;
    uint256 public blocksSinceLaunch = 0;

    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;

    // exlcude from fees and max transaction amount
    //mapping(address => bool) private _isExcludedFromFees;
   // mapping(address => bool) private isTxLimitExempt;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;



    /**
     * Setting all the Events
     */


    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event GasForProcessingUpdated(
        uint256 indexed newValue,
        uint256 indexed oldValue
    );

    event SwapAndLiquifyEnabledUpdated(bool enabled);

    event SwapAndLiquify(uint256 tokensIntoLiqudity, uint256 ethReceived);

    event SendDividends(uint256 tokensSwapped, uint256 amount);

    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );



    constructor() ERC20("SpaceBattleShipTestNeu2", "SBSTest3") Stakeable() {
        dividendTracker = new StarBattleShipDividendTracker();

        router = IDexRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pcs2BNBPair = IDexFactory(router.factory()).createPair(router.WETH(), address(this));
        pairs.push(pcs2BNBPair);
        _allowances[address(this)][address(router)] = type(uint256).max;
		isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
		isTxLimitExempt[msg.sender] = true;
		isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[ZERO] = true;

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(msg.sender);
        dividendTracker.excludeFromDividends(address(router));
        dividendTracker.excludeFromDividends(DEAD);
        dividendTracker.excludeFromDividends(ZERO);

        // exclude from paying fees or having max transaction amount
        isFeeExempt[msg.sender] = true;
        isFeeExempt[marketingWallet] = true;
        isFeeExempt[address(this)] = true;

        // exclude from max tx
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[marketingWallet] = true;

        /*
            _mint is an internal function in IERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 100000000 * (10**9));
        
    }
	receive() external payable {}

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "IERC20: transfer from the zero address");
        require(to != address(0), "IERC20: transfer to the zero address");
        blocksSinceLaunch = block.number - launchedAt;
        
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        checkTxLimit(from, to, amount);

        if (shouldSwapBack()) {
            liquify();
        }

        if (!launched() && to == pcs2BNBPair) {
            require(isTxLimitExempt[from] == true, "Only someone without txlimit can be the first to add liquidity.");
            launch();
        }

        uint256 amountReceived = shouldTakeFee(from, to) ? takeFee(from, amount) : amount;
        
        super._transfer(from, to, amountReceived);

        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if (!inSwap) {
            uint256 gas = gasForProcessing;

            try dividendTracker.process(gas) returns (
                uint256 iterations,
                uint256 claims,
                uint256 lastProcessedIndex
            ) {
                emit ProcessedDividendTracker(
                    iterations,
                    claims,
                    lastProcessedIndex,
                    true,
                    gas,
                    tx.origin
                );
            } catch {}
        }
    }


function checkTxLimit(address sender, address recipient, uint256 amount) view internal {
        require(amount <= _maxTxAmountBuy || isTxLimitExempt[sender] || isTxLimitExempt[recipient] && sender == pcs2BNBPair, "TX Limit Exceeded");
        // Max wallet check.
		if (sender != owner()
            && recipient != owner()
            && !isTxLimitExempt[recipient]
            && recipient != ZERO 
            && recipient != DEAD 
            && recipient != pcs2BNBPair 
            && recipient != address(this)
        ) {
            uint256 newBalance = balanceOf(recipient) + amount;
            require(newBalance <= _maxWalletAmount, "Exceeds max Wallet");
        }
        
        // Max sell check
        if (sender != owner()
            && recipient != owner()
            && !isTxLimitExempt[sender]
            && sender != pcs2BNBPair 
            && recipient != address(this)
        ) { 
            require(amount <= _maxWalletAmount, "Exceeds max sell.");
        }
}

	function shouldTakeFee(address sender, address recipient) internal returns (bool) {
        if (isFeeExempt[sender] || isFeeExempt[recipient] || !launched()) {
            return false;
		}
        
        address[] memory liqPairs = pairs;
        for (uint256 i = 0; i < liqPairs.length; i++) {
            if (sender == liqPairs[i] ) {
                isSell = false;
                return true;
			}
        }
        for (uint256 i = 0; i < liqPairs.length; i++) {
            if (recipient == liqPairs[i]) {
                isSell = true;
				return true;
			}
        }
        return feeOnNonTrade;
    }

	function takeFee(address sender, uint256 amount) internal returns (uint256) {
		if (!launched()) {
			return amount;
		}
		uint256 tokensfortaxes = 0;
            
        if(blocksSinceLaunch < 100000){
            setExtraSellFeesAtLaunch();
        }

		if(totalFees > 0){
        tokensfortaxes = amount * totalFees / feeDenominator;
        }    

        if(isSell && extraFeeOnSell > 0){
            tokensfortaxes += amount * extraFeeOnSell / feeDenominator;
        }
        super._transfer(sender, address(this), tokensfortaxes);
        return amount - tokensfortaxes;
    }

    function setExtraSellFeesAtLaunch() internal {
            if(blocksSinceLaunch < 1200){
                extraFeeOnSell = 410;
            }
            if(blocksSinceLaunch < 28800 && blocksSinceLaunch > 1199){
                extraFeeOnSell = 410 - (320 * (blocksSinceLaunch - 1200) / 27600);
            }
            if(blocksSinceLaunch < 86400 && blocksSinceLaunch > 28799){
                extraFeeOnSell = 90 - (90 * (blocksSinceLaunch - 28800) / 57600);
            }
            if(blocksSinceLaunch > 86401){
                extraFeeOnSell = 0;
            }
        websiteSellFee = totalFees + extraFeeOnSell - 10;
    }

    function shouldSwapBack() internal view returns (bool) {
        return launched()
			&& msg.sender != pcs2BNBPair
            && !inSwap
            && swapEnabled
            && balanceOf(address(this)) >= swapThreshold;
    }


	function liquify() internal swapping {
        uint256 contractBalance = balanceOf(address(this));
        if(contractBalance > maxSwapAmount){
            contractBalance = maxSwapAmount;
        }
        uint256 amountToLiquidity = contractBalance * liquidityFee / totalFees / 2 ;
        uint256 amountToSwapForBNB = contractBalance - amountToLiquidity;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwapForBNB,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amountBNB = address(this).balance;
        uint256 onePercentOfTax = amountBNB / (totalFees - (liquidityFee/2));
        uint256 marketingBNB = onePercentOfTax * marketingFee;
        uint256 BNBpaidToBeneficiaries = 0;
        
        if(blocksSinceLaunch < devSalaryBlocks + 1){
            payable(devWallet).transfer(marketingBNB * percentToDev / 100);
            BNBpaidToBeneficiaries += marketingBNB * percentToDev / 100;
        }

        if(percentToLimitedNFT > 0){
            address[] memory bonusAddresses = _getMarketingPayoutContracts();
            for (uint256 index = 0; index < bonusAddresses.length; index++) {
            payable(bonusAddresses[index]).transfer(marketingBNB * percentToLimitedNFT / 100);
            BNBpaidToBeneficiaries += marketingBNB * percentToLimitedNFT / 100;
            }
        }

        payable(marketingWallet).transfer(marketingBNB - BNBpaidToBeneficiaries);    

        uint256 amountBNBLiquidity = address(this).balance;
		router.addLiquidityETH{value: amountBNBLiquidity}(
			address(this),
			amountToLiquidity,
			0,
			0,
			address(owner()),
			block.timestamp
		);
        uint256 dividends = address(this).balance;
        address(dividendTracker).call{value: dividends};

    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
    }

    function addPair(address pair) external onlyOwner {
        pairs.push(pair);
        dividendTracker.excludeFromDividends(pair);
    }
    
    function removeLastPair() external onlyOwner {
        pairs.pop();
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }



    function websiteSwapTokensForBnb(uint256 _tokenAmount) public {
        super._transfer(msg.sender, address(this), _tokenAmount);
        super._transfer(address(this), marketingWallet, _tokenAmount * (websiteSellFee/fractionOfFeeAsTokens) / 100);
        uint256 tokensToSwapWebsite = _tokenAmount - (_tokenAmount * (websiteSellFee/fractionOfFeeAsTokens) / 100);
        uint256 BNBbeforeSwap = address(this).balance;
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokensToSwapWebsite,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 receivedBNB = address(this).balance - BNBbeforeSwap;
        uint256 bnbToSend = receivedBNB * (100-websiteSellFee) / (100-(websiteSellFee/fractionOfFeeAsTokens));
        payable(msg.sender).transfer(bnbToSend);

        uint256 marketingBNB = address(this).balance - BNBbeforeSwap;
        uint256 BNBpaidToBeneficiaries = 0;
        
        if(blocksSinceLaunch < devSalaryBlocks + 1){
            payable(devWallet).transfer(marketingBNB * percentToDev / 100);
            BNBpaidToBeneficiaries += marketingBNB * percentToDev / 100;
        }

        if(percentToLimitedNFT > 0){
            address[] memory bonusAddresses = _getMarketingPayoutContracts();
            for (uint256 index = 0; index < bonusAddresses.length; index++) {
            payable(bonusAddresses[index]).transfer(marketingBNB * percentToLimitedNFT / 100);
            BNBpaidToBeneficiaries += marketingBNB * percentToLimitedNFT / 100;
            }
        }
        marketingBNB = address(this).balance - BNBbeforeSwap;
        payable(marketingWallet).transfer(marketingBNB);

        
    }

    function websiteSwapBnbForTokens() public payable{
        uint256 bnbAmount = msg.value * (100-websiteBuyFee) / 100;
        uint256 contractTokens = balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(address(this));

        // make the swap
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: bnbAmount}(
            0, 
            path,
            address(this),
            block.timestamp
        );
        uint256 tokensToSend = balanceOf(address(this)) - contractTokens;
        super._transfer(address(this), msg.sender, tokensToSend);
        uint256 marketingBNB = address(this).balance;
        uint256 BNBpaidToBeneficiaries = 0;
        
        if(blocksSinceLaunch < devSalaryBlocks + 1){
            payable(devWallet).transfer(marketingBNB * percentToDev / 100);
            BNBpaidToBeneficiaries += marketingBNB * percentToDev / 100;
        }

        if(percentToLimitedNFT > 0){
            address[] memory bonusAddresses = _getMarketingPayoutContracts();
            for (uint256 index = 0; index < bonusAddresses.length; index++) {
            payable(bonusAddresses[index]).transfer(marketingBNB * percentToLimitedNFT / 100);
            BNBpaidToBeneficiaries += marketingBNB * percentToLimitedNFT / 100;
            }
        }
        payable(marketingWallet).transfer(address(this).balance);
    }

    

    function getClaimWait() external view returns (uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return isFeeExempt[account];
    }

    function isExcludedFromMaxTx(address account) public view returns (bool) {
        return isTxLimitExempt[account];
    }

    function withdrawableDividendOf(address account) public view returns (uint256)
    {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(address account) public view returns (uint256)
    {
        return dividendTracker.balanceOf(account);
    }

    function getAccountDividendsInfo(address account) external view returns (address,int256,int256,uint256,uint256,uint256,uint256,uint256)
    {
        return dividendTracker.getAccount(account);
    }

    function getAccountDividendsInfoAtIndex(uint256 index) external view returns (address,int256,int256,uint256,uint256,uint256,uint256,uint256)
    {
        return dividendTracker.getAccountAtIndex(index);
    }

    function processDividendTracker(uint256 gas) external {
        (uint256 iterations,uint256 claims,uint256 lastProcessedIndex) = dividendTracker.process(gas);
        emit ProcessedDividendTracker(iterations,claims,lastProcessedIndex,false,gas,tx.origin);
    }

    function claim() external {
        dividendTracker.processAccount(payable(msg.sender), false);
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns (uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }


    function excludeFromDividends(address account) external onlyOwner {
        dividendTracker.excludeFromDividends(account);
    }


// Recover any BNB sent to the contract by mistake.
	function rescue() external onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }
    function rescueToken(address tokenAddress) public onlyOwner returns (bool success) {
        uint256 tokenAmount = IERC20(tokenAddress).balanceOf(address(this));
        return IERC20(tokenAddress).transfer(msg.sender, tokenAmount);
    }


function setFees(
        uint256 _bnbRewardFee,
        uint256 _liquidityFee,
        uint256 _marketingFee,
        uint256 _fractionInTokens, 
        bool walletToWalletTax
    ) public onlyOwner {
        bnbRewardFee = _bnbRewardFee;
        liquidityFee = _liquidityFee;
        marketingFee = _marketingFee;
        fractionOfFeeAsTokens = _fractionInTokens;
        totalFees = bnbRewardFee + liquidityFee + marketingFee;
        websiteSellFee = totalFees + extraFeeOnSell - 10;
        websiteBuyFee = totalFees - 10;
        feeOnNonTrade = walletToWalletTax;
        require(totalFees < 11, "Maximum buy fees are 10%");
    }


    function setExtraFeeOnSell(uint256 _extraFeeOnSell) public onlyOwner {
        extraFeeOnSell = _extraFeeOnSell; // extra fee on sell
        websiteSellFee = totalFees + extraFeeOnSell - 10;
        require(extraFeeOnSell + totalFees < 21,"Maximum sell fees are 20%");
    }

    function setSwapSettings(bool set, uint256 minimumSwap, uint256 maximumSwap) external onlyOwner {
		swapEnabled = set;
        maxSwapAmount = calculatedTotalSupply /  100000000 * maximumSwap;
        swapThreshold = calculatedTotalSupply / 100000000 * minimumSwap;
	}

    function setMaxSellTx(uint256 _maxSellTxAmount) public onlyOwner {
        _maxTxAmountSell = _maxSellTxAmount * (10**9);
        require(_maxTxAmountSell > 99999, "MaxSellTx has to be more than 0.1%");
    }

    function setMarketingWallet(address payable _newmarketingWallet) public onlyOwner {
        marketingWallet = _newmarketingWallet;
    }



    /**
     * Add functionality like burn to the _stake afunction
     *
     */
    function stake(uint256 _amount, uint256 _days) public {
        // Make sure staker actually is good for it
        require(
            _amount < balanceOf(msg.sender),
            "SpaceBattleShip: Cannot stake more than you own");

        require(
            _days == 10 || _days == 30 || _days == 60 || _days == 90,
            "Variable _days must be 30, 60 or 90");

        _stake(_amount, _days);
        // Burn the amount of tokens on the sender
        _transfer(msg.sender, _parking, _amount);
    }

    /**
     * @notice withdrawStake is used to withdraw stakes from the account holder
     */
    function withdrawStake(uint256 amount, uint256 stake_index) public {
        uint256 amount_to_transfer;
        uint256 amount_to_mint;

        (amount_to_transfer, amount_to_mint) = _withdrawStake(
            amount,
            stake_index);
        // Return staked tokens to user
        _transfer(_parking, msg.sender, amount_to_transfer);
        _transfer(_parking, msg.sender, amount_to_mint);
    }

function setExcludeFromMaxTx(address _address, bool value) public onlyOwner{
        isTxLimitExempt[_address] = value;
    }

    function setExcludeFromAll(address _address) public onlyOwner {
        isTxLimitExempt[_address] = true;
        isFeeExempt[_address] = true;
        dividendTracker.excludeFromDividends(_address);
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(
            newValue >= 100000 && newValue <= 5000000,
            "StarBattleShip: gasForProcessing must be between 200,000 and 500,000");
        require(
            newValue != gasForProcessing,
            "StarBattleShip: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

}