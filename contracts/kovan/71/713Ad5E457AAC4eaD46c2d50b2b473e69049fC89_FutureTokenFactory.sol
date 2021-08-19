pragma solidity ^0.8.0;
import "./interfaces/IERC20.sol";
import "./interfaces/IERC20Metadata.sol";
import "./Ownable.sol";

contract ERC20 is IERC20, Ownable {
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
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = allowance[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {_approve(sender, msg.sender, currentAllowance - amount);}

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

abstract contract Ownable is IOwnable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
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

import "./interfaces/IFutureContract.sol";
import "../common/interfaces/IERC20.sol";
import "../common/Ownable.sol";

contract FutureContract is IFutureContract, Ownable {
    
    address public override token0;
    address public override token1;
    uint256 public override expiryDate;
    
    constructor(address _token0, address _token1, uint _expiryDate, address approval) {
        require(_expiryDate > block.timestamp, "Future Contract: EXPIRY_DATE_BEFORE_NOW");
        (token0, token1) = (_token0, _token1);
        expiryDate = _expiryDate;
        IERC20(token0).approve(approval, type(uint256).max);
        IERC20(token1).approve(approval, type(uint256).max);
    }
}

pragma solidity ^0.8.0;

import "./interfaces/IFutureToken.sol";
import "../common/ERC20.sol";

contract FutureToken is IFutureToken, ERC20 {

    constructor() ERC20("FutureToken", "", 18) { }
    
    function initialize(string memory _symbol) external override {
        symbol = _symbol;
    }

    function mint(address to, uint256 amount) external override onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) external override onlyOwner {
        _burn(msg.sender, amount);
    }
}

pragma solidity ^0.8.0;

import "./FutureToken.sol";
import "./FutureContract.sol";
import "./interfaces/IFutureTokenFactory.sol";
import "../common/Ownable.sol";
import "../common/interfaces/IERC20.sol";

contract FutureTokenFactory is IFutureTokenFactory, Ownable {
    
    mapping(address => mapping(address => mapping(uint256 => address))) futureContract;

    address public override exchange;

    modifier onlyExchange() {
        require(msg.sender == exchange, "Future Token Factory: NOT_FROM_EXCHANGE");
        _;
    }
    
    function getFutureContract(address tokenA, address tokenB, uint256 expiryDate) public override view returns(address) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        return futureContract[token0][token1][expiryDate];
    }
    
    function getFutureToken(address tokenIn, address tokenOut, uint256 expiryDate) public override view returns(address) {
        address futureContractAddress = getFutureContract(tokenIn, tokenOut, expiryDate);
        if (futureContractAddress != address(0)) {
           return futureTokenAddress(tokenIn, tokenOut, expiryDate);
        }
        return address(0);
    }
    
    function futureTokenAddress(address tokenIn, address tokenOut, uint256 expiryDate) internal view returns(address) {
        bytes memory bytecode = type(FutureToken).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(tokenIn, tokenOut, expiryDate));
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(bytecode)
            )
        );
        return address(uint160(uint256(hash)));
    }

    function createFuture(
        address tokenA, 
        address tokenB, 
        uint256 expiryDate, 
        string memory expirySymbol
    ) external override onlyExchange returns (address future) {
        require(tokenA != tokenB, "Future Token Factory: TOKENS_IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "Future Token Factory: TOKEN_ZERO_ADDRESS");
        require(futureContract[token0][token1][expiryDate] == address(0), "Future Token Factory: FUTURE_TOKEN_EXISTED");
    
        future = address(new FutureContract(token0, token1, expiryDate, exchange));
        createFutureToken(token0, token1, expiryDate, expirySymbol);
        createFutureToken(token1, token0, expiryDate, expirySymbol);
        futureContract[token0][token1][expiryDate] = future;
    }
    
    function createFutureToken(
        address tokenIn, 
        address tokenOut, 
        uint256 expiryDate, 
        string memory expirySymbol
    ) internal returns (address futureTokenAddress) {
        bytes memory bytecode = type(FutureToken).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(tokenIn, tokenOut, expiryDate));
        assembly {
            futureTokenAddress := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        FutureToken(futureTokenAddress).initialize(string(
            abi.encodePacked(
                IERC20(tokenIn).symbol(), "-",
                IERC20(tokenOut).symbol(), "-",
                expirySymbol
            )
        ));
    }

    function setExchange(address _exchange) external onlyOwner {
        exchange = _exchange;
    }

    function mintFuture(address tokenIn, address tokenOut, uint expiryDate, address to, uint amount) external override onlyExchange {
        address futureTokenAddress = getFutureToken(tokenIn, tokenOut, expiryDate);
        require(futureTokenAddress != address(0), "Future Token: INVALID");
        FutureToken(futureTokenAddress).mint(to, amount);
    }

    function burnFuture(address tokenIn, address tokenOut, uint expiryDate, uint256 amount) external override onlyExchange {
        address futureTokenAddress = getFutureToken(tokenIn, tokenOut, expiryDate);
        require(futureTokenAddress != address(0), "Future Token: INVALID");
        FutureToken(futureTokenAddress).burn(amount);
    }
}

pragma solidity ^0.8.0;

interface IFutureContract {
    
    function token0() external view returns (address);
    
    function token1() external view returns (address);
    
    function expiryDate() external view returns (uint256);
}

pragma solidity ^0.8.0;

interface IFutureToken {
    
    function initialize(string memory symbol) external;
    
    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;
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
    
    function getFutureContract(address tokenA, address tokenB, uint expiryDate) external view returns (address);

    function getFutureToken(address tokenIn, address tokenOut, uint expiryDate) external view returns (address);

    function createFuture(address tokenA, address tokenB, uint expiryDate, string memory symbol) external returns (address);

    function mintFuture(address tokenIn, address tokenOut, uint expiryDate, address to, uint amount) external;

    function burnFuture(address tokenIn, address tokenOut, uint expiryDate, uint amount) external;
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}