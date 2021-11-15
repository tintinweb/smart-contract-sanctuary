// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import './modules/Configable.sol';
import './modules/Initializable.sol';
import './interfaces/IERC20.sol';
import './interfaces/ISwitchAcross.sol';


struct Order {
    uint sn;
    address user;
    uint chainId; 
    address tokenIn;
    address tokenOut;
    uint amountIn;
    uint amountOut;
    uint mode; // 1: auto process, 2: user process
    uint nonce;
    uint slide;
    uint fee;
}

interface _IAcross {
    function inOrders(address _user, uint _nonce) external view returns (Order memory);
    function outOrders(address _user, uint _nonce) external view returns (Order memory);
    function getInOrder(uint _sn) external view returns (Order memory);
    function getOutOrder(uint _sn) external view returns (Order memory);
}

interface ISwapPair {
    function totalSupply() external view returns(uint);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface ISwapFactory {
    function getPair(address _token0, address _token1) external view returns (address);
}

contract SwitchQuery is Configable, Initializable{

    struct Token {
        uint8 decimals;
        uint totalSupply;
        uint balance;
        uint allowance;
        string name;
        string symbol;
    }

    function initialize() public initializer {
        owner = msg.sender;
    }
    
    function queryTokenInfo(address _token, address _user, address _spender) public view returns(Token memory data){
        data.decimals = IERC20(_token).decimals();
        data.totalSupply = IERC20(_token).totalSupply();
        data.balance = IERC20(_token).balanceOf(_user);
        data.allowance = IERC20(_token).allowance(_user, _spender);
        data.name = IERC20(_token).name();
        data.symbol = IERC20(_token).symbol();
        return data;
    }
    
    function queryTokenList(address _user, address _spender, address[] memory _tokens) public view returns (Token[] memory data) {
        uint count = _tokens.length;
        data = new Token[](count);
        for(uint i = 0;i < count;i++) {
            data[i] = queryTokenInfo(_tokens[i], _user, _spender);
        }
        return data;
    }

    function getSwapPairReserve(address _pair) public view returns (address token0, address token1, uint decimals0, uint decimals1, uint reserve0, uint reserve1, uint totalSupply) {
        totalSupply = ISwapPair(_pair).totalSupply();
        token0 = ISwapPair(_pair).token0();
        token1 = ISwapPair(_pair).token1();
        decimals0 = IERC20(token0).decimals();
        decimals1 = IERC20(token1).decimals();
        (reserve0, reserve1, ) = ISwapPair(_pair).getReserves();
        return (token0, token1, decimals0, decimals1, reserve0, reserve1, totalSupply);
    }

    function getSwapPairReserveByTokens(address _factory, address _token0, address _token1) public view returns (address token0, address token1, uint decimals0, uint decimals1, uint reserve0, uint reserve1, uint totalSupply) {
        address pair = ISwapFactory(_factory).getPair(_token0, _token1);
        return getSwapPairReserve(pair);
    }

    // _tokenB is base token
    function getLpValueByFactory(address _factory, address _tokenA, address _tokenB, uint _amount) public view returns (uint, uint) {
        address pair = ISwapFactory(_factory).getPair(_tokenA, _tokenB);
        (, address token1, uint decimals0, uint decimals1, uint reserve0, uint reserve1, uint totalSupply) = getSwapPairReserve(pair);
        if(_amount == 0 || totalSupply == 0) {
            return (0, 0);
        }
        uint decimals = decimals0;
        uint total = reserve0 * 2;
        if(_tokenB == token1) {
            total = reserve1 * 2;
            decimals = decimals1;
        }
        return (_amount*total/totalSupply, decimals);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

interface IConfig {
    function dev() external view returns (address);
    function admin() external view returns (address);
}

contract Configable {
    address public config;
    address public owner;

    event ConfigChanged(address indexed _user, address indexed _old, address indexed _new);
    event OwnerChanged(address indexed _user, address indexed _old, address indexed _new);
 
    function setupConfig(address _config) external onlyOwner {
        emit ConfigChanged(msg.sender, config, _config);
        config = _config;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'OWNER FORBIDDEN');
        _;
    }

    function admin() public view returns(address) {
        if(config != address(0)) {
            return IConfig(config).admin();
        }
        return owner;
    }

    function dev() public view returns(address) {
        if(config != address(0)) {
            return IConfig(config).dev();
        }
        return owner;
    }

    function changeOwner(address _user) external onlyOwner {
        require(owner != _user, 'Owner: NO CHANGE');
        emit OwnerChanged(msg.sender, owner, _user);
        owner = _user;
    }
    
    modifier onlyDev() {
        require(msg.sender == dev() || msg.sender == owner, 'dev FORBIDDEN');
        _;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin(), 'admin FORBIDDEN');
        _;
    }
  
    modifier onlyManager() {
        require(msg.sender == dev() || msg.sender == admin() || msg.sender == owner, 'manager FORBIDDEN');
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface ISwitchAcross {
    function feeWallet() external view returns (address);
    function totalSlideOfToken(address _token) external view returns (uint);
    function collectSlide(address _token) external returns (uint amount);
    function inSn() external view returns (uint);
    function outSn() external view returns (uint);
    function transferIn(address _to, address[] memory _tokens, uint[] memory _values) external payable;
    function transferOut(address _from, address[] memory _tokens, uint[] memory _values, bytes memory _signature) external;
    function queryWithdraw(address _token, uint _value) external view returns (uint);
}

