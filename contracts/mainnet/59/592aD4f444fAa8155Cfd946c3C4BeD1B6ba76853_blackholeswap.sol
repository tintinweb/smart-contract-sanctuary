/**
 *Submitted for verification at Etherscan.io on 2021-02-24
*/

pragma solidity 0.5.17;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) 
            return 0;
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }

    function sqrt(uint256 x) internal pure returns (uint256) {
        uint256 z = add(x >> 1, 1);
        uint256 y = x;
        while (z < y)
        {
            y = z;
            z = ((add((x / z), z)) / 2);
        }
        return y;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowed;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 internal _totalSupply;

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the balance of.
    * @return A uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param owner address The address which owns the funds.
    * @param spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
    * @dev Transfer token to a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * Beware that changing an allowance with this method brings the risk that someone may use both the old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    * @param spender The address which will spend the funds.
    * @param value The amount of tokens to be spent.
    */
    function approve(address spender, uint256 value) public returns (bool) {
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
    * @dev Transfer tokens from one address to another.
    * Note that while this function emits an Approval event, this is not required as per the specification,
    * and other compliant implementations may not emit the event.
    * @param from address The address which you want to send tokens from
    * @param to address The address which you want to transfer to
    * @param value uint256 the amount of tokens to be transferred
    */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

}

contract ERC20Mintable is ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;

    function _mint(address to, uint256 amount) internal {
        _balances[to] = _balances[to].add(amount);
        _totalSupply = _totalSupply.add(amount);
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        _balances[from] = _balances[from].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(from, address(0), amount);
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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
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

contract blackholeswap is ERC20Mintable {
    using SafeMath for *;
    using SafeERC20 for IERC20;

    /***********************************|
    |        Variables && Events        |
    |__________________________________*/
    IERC20 constant token0 = ERC20(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51); //sUSD
    IERC20 constant token1 = ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F); //DAI

    event Purchases(address indexed buyer, address indexed sell_token, uint256 inputs, address indexed buy_token, uint256 outputs);
    event AddLiquidity(address indexed provider, uint256 share, uint256 token0Amount, uint256 token1Amount);
    event RemoveLiquidity(address indexed provider, uint256 share, uint256 token0Amount, uint256 token1Amount);

    /***********************************|
    |            Constsructor           |
    |__________________________________*/

    constructor() public {
        symbol = "BHS sUSD/DAI";
        name = "BlackHoleSwap sUSD/DAI";
        decimals = 18;
        admin = msg.sender;
        vault = msg.sender;
    }

    /***********************************|
    |        Governmence & Params       |
    |__________________________________*/

    uint256 public fee = 0.99985e18; // 1 - swap fee (numerator, in 1e18 format)
    uint256 public protocolFee = 5;
    uint256 public constant A = 0.75e18;
    uint256 constant BASE = 1e18;

    address private admin;
    address private vault;

    uint256 public kLast;

    function setAdmin(address _admin) external {
        require(msg.sender == admin);
        admin = _admin;
    }

    function setParams(uint256 _fee, uint256 _protocolFee) external {
        require(msg.sender == admin);
        require(_fee < 1e18 && _fee >= 0.99e18); //0 < fee <= 1%
        require(_protocolFee > 0); //protocolFee <= 50% fee
        uint256 token0Reserve = getToken0Balance();
        uint256 token1Reserve = getToken1Balance();
        if(_totalSupply > 0) _mintFee(k(token0Reserve, token1Reserve));
        fee = _fee;
        protocolFee = _protocolFee;
        kLast = k(token0Reserve, token1Reserve);
    }

    function setVault(address _vault) external {
        require(msg.sender == admin);
        vault = _vault;
    }

    /***********************************|
    |         Getter Functions          |
    |__________________________________*/

    function getToken0Balance() public view returns (uint256) {
        return token0.balanceOf(address(this));
    }

    function getToken1Balance() public view returns (uint256) {
        return token1.balanceOf(address(this));
    }

    function k(uint256 x, uint256 y) internal pure returns (uint256 _k) {
        uint256 u = x.add(y.mul(A).div(BASE));
        uint256 v = y.add(x.mul(A).div(BASE));
        _k = u.mul(v);
    }

    function f(uint256 _x, uint256 x, uint256 y) internal pure returns (uint256 _y) {
        uint256 c = k(x, y).mul(BASE).div(A).sub(_x.mul(_x), "INSUFFICIENT_LIQUIDITY");

        uint256 cst = A.add(uint256(1e36).div(A));
        uint256 _b = _x.mul(cst).div(BASE);

        uint256 D = _b.mul(_b).add(c.mul(4)); // b^2 - 4c

        _y = D.sqrt().sub(_b).div(2);
    }

    // Calculate output given exact input
    function getOutExactIn(uint256 input, uint256 x, uint256 y) public view returns (uint256 output) {
        uint256 _x = x.add(input.mul(fee).div(BASE));
        uint256 _y = f(_x, x, y);
        output = y.sub(_y);
    }

    // Calculate input given exact output
    function getInExactOut(uint256 output, uint256 x, uint256 y) public view returns (uint256 input) {
        uint256 _y = y.sub(output);
        uint256 _x = f(_y, y, x);
        input = _x.sub(x).mul(BASE).div(fee);
    }

    /***********************************|
    |        Exchange Functions         |
    |__________________________________*/
    
    function _mintFee(uint256 _k) private {
        uint _kLast = kLast; // gas savings

        if (_kLast != 0) {
            uint rootK = _k.sqrt();
            uint rootKLast = _kLast.sqrt();
            if (rootK > rootKLast) {
                uint numerator = _totalSupply.mul(rootK.sub(rootKLast));
                uint denominator = rootK.mul(protocolFee).add(rootKLast);
                uint liquidity = numerator / denominator;
                if (liquidity > 0) _mint(vault, liquidity);
            }
        }

    }

    function token0In(uint256 input, uint256 min_output, uint256 deadline) external returns (uint256 output) {
        require(block.timestamp <= deadline, "EXPIRED");
        uint256 fromReserve = getToken0Balance();
        uint256 toReserve = getToken1Balance();

        output = getOutExactIn(input, fromReserve, toReserve);
        require(output >= min_output, "SLIPPAGE_DETECTED");
        doTransferIn(token0, msg.sender, input);
        doTransferOut(token1, msg.sender, output);

        emit Purchases(msg.sender, address(token0), input, address(token1), output);
    }
    
    function token1In(uint256 input, uint256 min_output, uint256 deadline) external returns (uint256 output) {
        require(block.timestamp <= deadline, "EXPIRED");
        uint256 fromReserve = getToken1Balance();
        uint256 toReserve = getToken0Balance();

        output = getOutExactIn(input, fromReserve, toReserve);
        require(output >= min_output, "SLIPPAGE_DETECTED");
        doTransferIn(token1, msg.sender, input);
        doTransferOut(token0, msg.sender, output);

        emit Purchases(msg.sender, address(token1), input, address(token0), output);
    }

    function token0Out(uint256 max_input, uint256 output, uint256 deadline) external returns (uint256 input) {
        require(block.timestamp <= deadline, "EXPIRED");
        uint256 fromReserve = getToken0Balance();
        uint256 toReserve = getToken1Balance();

        input = getInExactOut(output, fromReserve, toReserve);
        require(input <= max_input, "SLIPPAGE_DETECTED");
        doTransferIn(token1, msg.sender, input);
        doTransferOut(token0, msg.sender, output);

        emit Purchases(msg.sender, address(token1), input, address(token0), output);
    }
    
    function token1Out(uint256 max_input, uint256 output, uint256 deadline) external returns (uint256 input) {
        require(block.timestamp <= deadline, "EXPIRED");
        uint256 fromReserve = getToken1Balance();
        uint256 toReserve = getToken0Balance();

        input = getInExactOut(output, fromReserve, toReserve);
        require(input <= max_input, "SLIPPAGE_DETECTED");
        doTransferIn(token0, msg.sender, input);
        doTransferOut(token1, msg.sender, output);

        emit Purchases(msg.sender, address(token1), input, address(token0), output);
    }
    
    function doTransferIn(IERC20 token, address from, uint256 amount) internal {
        token.safeTransferFrom(from, address(this), amount);
    }

    function doTransferOut(IERC20 token, address to, uint256 amount) internal {
        token.safeTransfer(to, amount);
    }


    /***********************************|
    |        Liquidity Functions        |
    |__________________________________*/

    function addLiquidity(uint256 share, uint256 token0_max, uint256 token1_max) external returns (uint256 token0_in, uint256 token1_in) {
        require(share >= 1e15, 'INVALID_ARGUMENT'); // 0.001

        if (_totalSupply > 0) {
            uint256 token0Reserve = getToken0Balance();
            uint256 token1Reserve = getToken1Balance();
            _mintFee(k(token0Reserve, token1Reserve));
            token0_in = share.mul(token0Reserve).div(_totalSupply);
            token1_in = share.mul(token1Reserve).div(_totalSupply);
            require(token0_in <= token0_max && token1_in <= token1_max, "SLIPPAGE_DETECTED");
            _mint(msg.sender, share);
            kLast = k(token0Reserve.add(token0_in), token1Reserve.add(token1_in));
        }
        else {
            token0_in = share.div(2);
            token1_in = share.div(2);
            _mint(msg.sender, share);
            kLast = k(token0_in, token1_in);
        }

        doTransferIn(token0, msg.sender, token0_in);
        doTransferIn(token1, msg.sender, token1_in);
        emit AddLiquidity(msg.sender, share, token0_in, token1_in);
    }

    function addLiquidityImbalanced(uint256 token0_in, uint256 token1_in, uint256 share_min) external returns (uint256 share) {
        require(_totalSupply > 0, "INSUFFICIENT_LIQUIDITY");
        uint256 token0Reserve = getToken0Balance();
        uint256 token1Reserve = getToken1Balance();
        uint256 kBefore = k(token0Reserve, token1Reserve);
        // charge fee for imbalanced deposit
        uint256 kAfter = k(token0Reserve.add(token0_in.mul(fee).div(BASE)), token1Reserve.add(token1_in.mul(fee).div(BASE)));
        _mintFee(kBefore);
        // ( sqrt(_k) * totalSupply / sqrt(k) - totalSupply )
        share = kAfter.sqrt().mul(_totalSupply).div(kBefore.sqrt()).sub(_totalSupply);
        require(share >= share_min, "SLIPPAGE_DETECTED");
        _mint(msg.sender, share);

        kLast = kAfter;
        doTransferIn(token0, msg.sender, token0_in);
        doTransferIn(token1, msg.sender, token1_in);
        emit AddLiquidity(msg.sender, share, token0_in, token1_in);
    }

    function removeLiquidity(uint256 share, uint256 token0_min, uint256 token1_min) external returns (uint256 token0_out, uint256 token1_out) {
        require(share > 0, 'INVALID_ARGUMENT');

        uint256 token0Reserve = getToken0Balance();
        uint256 token1Reserve = getToken1Balance();
        _mintFee(k(token0Reserve, token1Reserve));

        token0_out = share.mul(token0Reserve).div(_totalSupply);
        token1_out = share.mul(token1Reserve).div(_totalSupply);
        require(token0_out >= token0_min && token1_out >= token1_min, "SLIPPAGE_DETECTED");

        _burn(msg.sender, share);

        kLast = k(token0Reserve.sub(token0_out), token1Reserve.sub(token1_out));
        doTransferOut(token0, msg.sender, token0_out);
        doTransferOut(token1, msg.sender, token1_out);
        emit RemoveLiquidity(msg.sender, share, token0_out, token1_out);
    }

}