pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;
import "./interfaces/IERC20.sol";
import "./interfaces/IERC20Metadata.sol";
import "./Context.sol";
import "./Ownable.sol";

contract ERC20 is Context, IERC20, Ownable {
    string public override name;
    string public override symbol;
    uint8 public override decimals;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;
    uint256 public override totalSupply;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = allowance[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "Error: transfer from the zero address");
        require(recipient != address(0), "Error: transfer to the zero address");

        uint256 senderBalance = balanceOf[sender];
        require(senderBalance >= amount, "Error: transfer amount exceeds balance");
        unchecked {balanceOf[sender] = senderBalance - amount;}
        balanceOf[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "Error: mint to the zero address");

        totalSupply += amount;
        balanceOf[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "Error: burn from the zero address");

        uint256 accountBalance = balanceOf[account];
        require(accountBalance >= amount, "Error: burn amount exceeds balance");
        unchecked {balanceOf[account] = accountBalance - amount;}
        totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "Error: approve from the zero address");
        require(spender != address(0), "Error: approve to the zero address");

        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

pragma solidity ^0.8.0;

import "./interfaces/IOwnable.sol";
import "./Context.sol";

abstract contract Ownable is IOwnable, Context {
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

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.8.0;
import "./IERC20Metadata.sol";

interface IERC20 is IERC20Metadata {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.0;

interface IERC20Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.0;

interface IOwnable {
    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;
}

pragma solidity ^0.8.0;
import "./interfaces/IFutureToken.sol";
import "../common/ERC20.sol";

contract FutureToken is IFutureToken, ERC20 {
    uint256 public override expiryDate;
    address public override token0;
    address public override token1;

    constructor(
        address tokenA,
        address tokenB,
        uint256 expiryDate_
    ) ERC20("FutureToken", "FUT", 18) {
        ERC20 TokenA = ERC20(tokenA);
        ERC20 TokenB = ERC20(tokenB);
        symbol = string(
            abi.encodePacked(
                TokenA.symbol(),
                "-",
                TokenB.symbol(),
                "-",
                uint2str(expiryDate_)
            )
        );
        expiryDate = expiryDate_;

        (token0, token1) = (tokenA, tokenB);

        TokenA.approve(msg.sender, type(uint256).max);
        TokenB.approve(msg.sender, type(uint256).max);
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    modifier canMint() {
        require(block.timestamp < expiryDate, "Future Token: CANNOT MINT AFTER EXPIRED");
        _;
    }

    modifier canBurn() {
        require(block.timestamp >= expiryDate, "Future Token: CANNOT BURN BEFORE EXPIRED");
        _;
    }

    function mint(address to, uint256 amount) external override onlyOwner canMint {
        _mint(to, amount);
    }

    function burn(uint256 amount) external override onlyOwner canBurn {
        _burn(msg.sender, amount);
    }

    function getReserves()
        external
        view
        override
        returns (uint256 reserve0, uint256 reserve1)
    {
        reserve0 = ERC20(token0).balanceOf(address(this));
        reserve1 = ERC20(token1).balanceOf(address(this));
    }
}

pragma solidity ^0.8.0;

import "./FutureToken.sol";
import "./interfaces/IFutureTokenFactory.sol";
import "../common/Ownable.sol";
import "../common/interfaces/IERC20.sol";

contract FutureTokenFactory is IFutureTokenFactory, Ownable {
    mapping(address => mapping(address => mapping(uint256 => address))) public override getFutureToken;
    address[] public override allFutureTokens;

    address public override exchange;
    
    address public bestBuyToken;
    address public bestSellToken;

    event FutureTokenCreated(
        address indexed token0,
        address indexed token1,
        address futureTokenAddress,
        uint256 i
    );

    modifier onlyExchange() {
        require(msg.sender == exchange, "Future Factory: NOT CALL FROM EXCHANGE ROUTER");
        _;
    }

    function getFutureTokenLength() external view returns (uint256) {
        return allFutureTokens.length;
    }

    function createFutureToken(
        address tokenA,
        address tokenB,
        uint256 deadline
    ) external override onlyExchange returns (address) {
        require(tokenA != tokenB, "PrecogV2: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "PrecogV2: ZERO_ADDRESS");
        require(
            getFutureToken[token0][token1][deadline] == address(0),
            "PrecogV2: FUTURETOKEN_EXISTS"
        );

        FutureToken token = new FutureToken(token0, token1, deadline);

        address futureTokenAddress = address(token);

        getFutureToken[token0][token1][deadline] = futureTokenAddress;
        getFutureToken[token1][token0][deadline] = futureTokenAddress;
        allFutureTokens.push(futureTokenAddress);

        emit FutureTokenCreated(
            token0,
            token1,
            futureTokenAddress,
            allFutureTokens.length
        );

        return futureTokenAddress;
    }

    function setExchange(address _exchange) external onlyOwner {
        exchange = _exchange;
    }

    function mintFuture(address futureToken, address to, uint256 amount) external override onlyExchange {
        FutureToken(futureToken).mint(to, amount);
    }

    function burnFuture(address futureToken, uint256 amount) external override onlyExchange {
        FutureToken(futureToken).burn(amount);
    }

    function transferFromFuture(address token, address from, address to, uint256 amount) external override onlyExchange {
        IERC20(token).transferFrom(from, to, amount);
    }
}

pragma solidity ^0.8.0;

interface IFutureToken {
    function token0() external view returns (address);
    
    function token1() external view returns (address);
    
    function expiryDate() external view returns (uint256);
    
    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function getReserves() external view returns (uint256 reserve0, uint256 reserve1);
}

pragma solidity ^0.8.0;

interface IFutureTokenFactory {
    function exchange() external view returns (address);
    
    event futureTokenCreated(
        address indexed token0,
        address indexed token1,
        address futureTokenAddress,
        uint256 i
    );

    function getFutureToken(address tokenA, address tokenB, uint256 deadline) external view returns (address);

    function allFutureTokens(uint256 index) external view returns (address);

    function createFutureToken(address tokenA, address tokenB, uint256 deadline) external returns (address);

    function mintFuture(address futureToken, address to, uint256 amount) external;

    function burnFuture(address futureToken, uint256 amount) external;

    function transferFromFuture(address token, address from, address to, uint256 amount) external;
}

