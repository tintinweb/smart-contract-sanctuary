pragma solidity 0.5.17;

import './safeMath.sol';
import './normalizer.sol';

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Context {
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint;

    mapping (address => uint) private _balances;

    mapping (address => mapping (address => uint)) private _allowances;

    uint private _totalSupply;
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }
    function transfer(address recipient, uint amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeERC20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;
    function mul(int256 a, int256 b) internal pure returns (int256) {
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
    function sqrt(int256 x) internal pure returns (int256) {
        int256 z = add(x / 2, 1);
        int256 y = x;
        while (z < y)
        {
            y = z;
            z = ((add((x / z), z)) / 2);
        }
        return y;
    }
}

contract CreamY is ERC20, ERC20Detailed {

    event LOG_SWAP(
        address indexed caller,
        address indexed tokenIn,
        address indexed tokenOut,
        uint            tokenAmountIn,
        uint            tokenAmountOut
    );

    event LOG_JOIN(
        address indexed caller,
        address indexed tokenIn,
        uint            tokenAmountIn
    );

    event LOG_EXIT(
        address indexed caller,
        address indexed tokenOut,
        uint            tokenAmountOut
    );

    using SafeMath for uint;
    using SignedSafeMath for int256;
    using SafeERC20 for IERC20;

    mapping(address => bool) public coins;
    mapping(address => bool) public pause;
    IERC20[] public allCoins;
    Normalizer public normalizer;
    address public governance;
    address public reservePool;

    constructor(address _normalizer, address _reservePool) public ERC20Detailed("CreamY USD", "cyUSD", 18) {
        governance = msg.sender;
        normalizer = Normalizer(_normalizer);
        reservePool = _reservePool;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setNormalizer(address _normalizer) external {
        require(msg.sender == governance, "!governance");
        normalizer = Normalizer(_normalizer);
    }

    function setReservePool(address _reservePool) external {
        require(msg.sender == governance, "!governance");
        require(_reservePool != address(0), "invalid reserve pool");
        reservePool = _reservePool;
    }

    function setFees(uint _fee, uint _reserveRatio) external {
        require(msg.sender == governance, '!governance');
        require(_fee < 1e18 && _fee >= 0.99e18, 'Invalid fee'); // 0 < fee <= 1%
        if (_reserveRatio > 0) {
            require(_reserveRatio <= 1e18, 'Invalid reserve ratio'); // reserve ratio <= 100% fee
        }
        fee = _fee;
        reserveRatio = _reserveRatio;
    }

    function approveCoins(address _coin) external {
        require(msg.sender == governance, "!governance");
        require(coins[_coin] == false, "Already approved");
        coins[_coin] = true;
        allCoins.push(IERC20(_coin));
    }

    function setPause(address _coin, bool _pause) external {
        require(msg.sender == governance, "!governance");
        pause[_coin] = _pause;
    }

    function setA(uint _A) external {
        require(msg.sender == governance, "!governance");
        require(_A > 0 && _A <= 1e18, "Invalid A");
        // When A is close to 1, it becomes the fixed price model (x + y = k).
        // When A is close to 0, it degenerates to Uniswap (x * y = k).
        // However, A couldn't be exactly 0 since it will break the f function.
        A = _A;
    }

    function seize(IERC20 token, uint amount) external {
        require(msg.sender == governance, "!governance");
        require(!tokens[address(token)], "can't seize liquidity");

        uint bal = token.balanceOf(address(this));
        require(amount <= bal);

        token.safeTransfer(reservePool, amount);
    }

    uint public fee = 0.99965e18;
    uint public reserveRatio = 1e18;
    uint public constant BASE = 1e18;

    uint public A = 0.7e18;
    uint public count = 0;
    mapping(address => bool) tokens;

    function f(int256 _x, int256 x, int256 y) internal view returns (int256 _y) {
        int256 k;
        int256 c;
        {
            int256 u = x.add(y.mul(int256(A)).div(1e18));
            int256 v = y.add(x.mul(int256(A)).div(1e18));
            k = u.mul(v);
            c = _x.mul(_x).sub(k.mul(1e18).div(int256(A)));
        }

        int256 cst = int256(A).add(int256(1e36).div(int256(A)));
        int256 _b = _x.mul(cst).div(1e18);

        int256 D = _b.mul(_b).sub(c.mul(4));

        require(D >= 0, "!root");

        _y = (-_b).add(D.sqrt()).div(2);
    }

    function collectReserve(IERC20 from, uint input) internal {
        if (reserveRatio > 0) {
            uint _fee = input.mul(BASE.sub(fee)).div(BASE);
            uint _reserve = _fee.mul(reserveRatio).div(BASE);
            from.safeTransfer(reservePool, _reserve);
        }
    }

    // Get all support coins
    function getAllCoins() public view returns (IERC20[] memory) {
        return allCoins;
    }

    // Calculate total pool value in USD
    function calcTotalValue() public view returns (uint value) {
        uint totalValue = uint(0);
        for (uint i = 0; i < allCoins.length; i++) {
            totalValue = totalValue.add(balance(allCoins[i]));
        }
        return totalValue;
    }

    // Calculate _x given x, y, _y
    function getX(int256 output, int256 x, int256 y) internal view returns (int256 input) {
        int256 _y = y.sub(output);
        int256 _x = f(_y, y, x);
        input = _x.sub(x);
    }

    // Calculate _y given x, y, _x
    function getY(int256 input, int256 x, int256 y) internal view returns (int256 output) {
        int256 _x = x.add(input);
        int256 _y = f(_x, x, y);
        output = y.sub(_y);
    }

    // Calculate output given exact input
    function getOutExactIn(IERC20 from, IERC20 to, uint input, int256 x, int256 y) public view returns (uint output) {
        uint inputInUsd = normalize1e18(from, input).mul(normalizer.getPrice(address(from))).div(1e18);
        uint inputAfterFeeInUsd = inputInUsd.mul(fee).div(BASE);

        uint outputInUsd = uint(getY(i(inputAfterFeeInUsd), x, y));

        output = normalize(to, outputInUsd.mul(1e18).div(normalizer.getPrice(address(to))));
    }

    // Calculate input given exact output
    function getInExactOut(IERC20 from, IERC20 to, uint output, int256 x, int256 y) public view returns (uint input) {
        uint outputInUsd = normalize1e18(to, output).mul(normalizer.getPrice(address(to))).div(1e18);

        uint inputBeforeFeeInUsd = uint(getX(i(outputInUsd), x, y));
        uint inputInUsd = inputBeforeFeeInUsd.mul(BASE).div(fee);

        input = normalize(from, inputInUsd.mul(1e18).div(normalizer.getPrice(address(from))));
    }

    // Normalize coin to 1e18
    function normalize1e18(IERC20 token, uint _amount) internal view returns (uint) {
        uint _decimals = ERC20Detailed(address(token)).decimals();
        if (_decimals == uint(18)) {
            return _amount;
        } else {
            return _amount.mul(1e18).div(uint(10)**_decimals);
        }
    }

    // Normalize coin to original decimals
    function normalize(IERC20 token, uint _amount) internal view returns (uint) {
        uint _decimals = ERC20Detailed(address(token)).decimals();
        if (_decimals == uint(18)) {
            return _amount;
        } else {
            return _amount.mul(uint(10)**_decimals).div(1e18);
        }
    }

    // Contract balance of coin normalized to 1e18
    function balance(IERC20 token) public view returns (uint) {
        address _token = address(token);
        uint _balance = IERC20(_token).balanceOf(address(this));
        uint _balanceInUsd = _balance.mul(normalizer.getPrice(_token)).div(1e18);
        return normalize1e18(token, _balanceInUsd);
    }

    // Converter helper to int256
    function i(uint x) public pure returns (int256) {
        int256 value = int256(x);
        require(value >= 0, 'overflow');
        return value;
    }

    function swapExactAmountIn(IERC20 from, IERC20 to, uint input, uint minOutput, uint deadline) external returns (uint output) {
        require(coins[address(from)] == true, "!coin");
        require(pause[address(from)] == false, "pause");
        require(coins[address(to)] == true, "!coin");
        require(pause[address(to)] == false, "pause");
        require(normalizer.getPrice(address(from)) > 0, "zero price");
        require(normalizer.getPrice(address(to)) > 0, "zero price");

        require(block.timestamp <= deadline, "expired");

        output = getOutExactIn(from, to, input, i(balance(from)), i(balance(to)));

        require(balance(to) >= output, "insufficient output liquidity");
        require(output >= minOutput, "slippage");

        emit LOG_SWAP(msg.sender, address(from), address(to), input, output);

        from.safeTransferFrom(msg.sender, address(this), input);
        to.safeTransfer(msg.sender, output);
        collectReserve(from, input);
        return output;
    }

    function swapExactAmountOut(IERC20 from, IERC20 to, uint maxInput, uint output, uint deadline) external returns (uint input) {
        require(coins[address(from)] == true, "!coin");
        require(pause[address(from)] == false, "pause");
        require(coins[address(to)] == true, "!coin");
        require(pause[address(to)] == false, "pause");
        require(normalizer.getPrice(address(from)) > 0, "zero price");
        require(normalizer.getPrice(address(to)) > 0, "zero price");

        require(block.timestamp <= deadline, "expired");
        require(balance(to) >= output, "insufficient output liquidity");

        input = getInExactOut(from, to, output, i(balance(from)), i(balance(to)));

        require(input <= maxInput, "slippage");

        emit LOG_SWAP(msg.sender, address(from), address(to), input, output);

        from.safeTransferFrom(msg.sender, address(this), input);
        to.safeTransfer(msg.sender, output);
        collectReserve(from, input);
        return input;
    }

    function addLiquidityExactIn(IERC20 from, uint input, uint minOutput, uint deadline) external returns (uint output) {
        require(coins[address(from)] == true, "!coin");
        require(pause[address(from)] == false, "pause");
        require(block.timestamp <= deadline, "expired");
        require(input > 0, "zero input");
        require(normalizer.getPrice(address(from)) > 0, "zero price");
        require(normalizer.getPrice(address(this)) > 0, "zero price");

        if (totalSupply() == 0) {
            uint inputAfterFee = input.mul(fee).div(BASE);
            output = normalize1e18(from, inputAfterFee.mul(normalizer.getPrice(address(from))).div(1e18));
        } else {
            output = getOutExactIn(from, this, input, i(balance(from)), i(totalSupply().div(count)));
        }

        require(output >= minOutput, "slippage");

        emit LOG_JOIN(msg.sender, address(from), output);

        from.safeTransferFrom(msg.sender, address(this), input);
        _mint(msg.sender, output);

        if (!tokens[address(from)] && balance(from) > 0) {
            tokens[address(from)] = true;
            count = count.add(1);
        }
    }

    function addLiquidityExactOut(IERC20 from, uint maxInput, uint output, uint deadline) external returns (uint input) {
        require(coins[address(from)] == true, "!coin");
        require(pause[address(from)] == false, "pause");
        require(block.timestamp <= deadline, "expired");
        require(output > 0, "zero output");
        require(normalizer.getPrice(address(from)) > 0, "zero price");
        require(normalizer.getPrice(address(this)) > 0, "zero price");

        if (totalSupply() == 0) {
            uint inputAfterFee = normalize(from, output.mul(1e18).div(normalizer.getPrice(address(from))));
            input = inputAfterFee.mul(BASE).divCeil(fee);
        } else {
            input = getInExactOut(from, this, output, i(balance(from)), i(totalSupply().div(count)));
        }

        require(input <= maxInput, "slippage");

        emit LOG_JOIN(msg.sender, address(from), output);

        from.safeTransferFrom(msg.sender, address(this), input);
        _mint(msg.sender, output);

        if (!tokens[address(from)] && balance(from) > 0) {
            tokens[address(from)] = true;
            count = count.add(1);
        }
    }

    function removeLiquidityExactIn(IERC20 to, uint input, uint minOutput, uint deadline) external returns (uint output) {
        require(block.timestamp <= deadline, "expired");
        require(coins[address(to)] == true, "!coin");
        require(input > 0, "zero input");
        require(normalizer.getPrice(address(this)) > 0, "zero price");
        require(normalizer.getPrice(address(to)) > 0, "zero price");

        output = getOutExactIn(this, to, input, i(totalSupply().div(count)), i(balance(to)));

        require(output >= minOutput, "slippage");

        emit LOG_EXIT(msg.sender, address(to), output);

        _burn(msg.sender, input);
        to.safeTransfer(msg.sender, output);

        if (balance(to) == 0) {
            tokens[address(to)] = false;
            count = count.sub(1);
        }
    }

    function removeLiquidityExactOut(IERC20 to, uint maxInput, uint output, uint deadline) external returns (uint input) {
        require(block.timestamp <= deadline, "expired");
        require(coins[address(to)] == true, "!coin");
        require(output > 0, "zero output");
        require(normalizer.getPrice(address(this)) > 0, "zero price");
        require(normalizer.getPrice(address(to)) > 0, "zero price");

        input = getInExactOut(this, to, output, i(totalSupply().div(count)), i(balance(to)));

        require(input <= maxInput, "slippage");

        emit LOG_EXIT(msg.sender, address(to), output);

        _burn(msg.sender, input);
        to.safeTransfer(msg.sender, output);

        if (balance(to) == 0) {
            tokens[address(to)] = false;
            count = count.sub(1);
        }
    }
}
