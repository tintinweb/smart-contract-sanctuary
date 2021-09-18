/**
 *Submitted for verification at Etherscan.io on 2021-09-18
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.9.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "add err");
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "sub err");
    return a - b;
  }

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(a == 0 || c / a == b, "mul err");
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "div 0 err");
    uint256 c = a / b;
    require(a == b * c + a % b, "div err"); // There is no case in which this doesn't hold
    return c;
  }

}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
interface ERC20Basic {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function allowance(address owner, address spender) external view returns (uint256);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Ownable {
    address private _owner;

    // event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = msg.sender;
        // emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    // function renounceOwnership() public onlyOwner {
    //     emit OwnershipTransferred(_owner, address(0));
    //     _owner = address(0);
    // }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    // function transferOwnership(address newOwner) public onlyOwner {
    //     _transferOwnership(newOwner);
    // }

    // /**
    //  * @dev Transfers ownership of the contract to a new account (`newOwner`).
    //  */
    // function _transferOwnership(address newOwner) internal {
    //     require(newOwner != address(0), "Ownable: new owner is the zero address");
    //     emit OwnershipTransferred(_owner, newOwner);
    //     _owner = newOwner;
    // }
}

// pragma solidity >=0.5.0;

interface IUniswapV2Factory {
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


// pragma solidity >=0.5.0;

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

// pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WHT() external pure returns (address);

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
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}



// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

contract TxRule is Ownable{
    using SafeMath for uint256;


    uint256 periodUnit = 3600; // main
    // uint256 periodUnit = 60; // test
    uint256 periodMax = 48;
    address public _buyBackAddress;
    address public _teamAddress;
    address public _whiteAddress;
    address public _promoteMiningAddress;

    mapping(address => bool) public txWhiteList;
    mapping(address => bool) public contractWhiteList;
    address public miningContractAddress = 0x0000000000000000000000000000000000000001;
    bool public needGas = false; 
    bool public needSendRed = true;
    uint256 public curLPAmount = 0;
    uint256 public allTotalGas = 0;
    uint256 public sendGasMin = 10000000 * (10**18);
    // uint256 public sendGasMin = 100 * (10**8);
    
    SwapHelp swapHelp;
    address public swapHelpAddress;
    
    address[] public noNeedRedUsers;
    
    function setSwapHelp(address _address) external onlyOwner {
        swapHelpAddress = _address;
        swapHelp = SwapHelp(_address);
        txWhiteList[swapHelpAddress] = true;
        noNeedRedUsers.push(swapHelpAddress);
    }
    
    function updateSendGasMin(uint256 _value) external onlyOwner {
        require(_value>0, "_value is 0");
        sendGasMin = _value;
    }
    function needGasOnOff(bool _bo) external onlyOwner {
        needGas = _bo;
    }
    function needSendRedOnOff(bool _bo) external onlyOwner {
        needSendRed = _bo;
    }
    function updateMiningContractAddress(address _address) external onlyOwner {
        require(_address != address(0x0) && _address != address(0x01), "_address error");
        miningContractAddress = _address;
        contractWhiteList[miningContractAddress] = true;
        noNeedRedUsers.push(miningContractAddress);
    }
    function addContractWhiteList(address _address) external onlyOwner {
        contractWhiteList[_address] = true;
    }
    function subContractWhiteList(address _address) external onlyOwner {
        delete contractWhiteList[_address];
    }
    function addTxWhiteList(address _address) external onlyOwner {
        txWhiteList[_address] = true;
    }
    function subTxWhiteList(address _address) external onlyOwner {
        delete txWhiteList[_address];
    }
    function addNoNeedRedUsers(address _address) external onlyOwner {
        noNeedRedUsers.push(_address);
    }
    function subNoNeedRedUsers(uint256 _index) external onlyOwner {
        delete noNeedRedUsers[_index];
    }
    
  
    /**
     * 分红 
    */ 
    // 总质押
    // uint256 totalDeposit = 0;
    // 总奖励 
    uint256 public allTotalReward = 0;  
    // 上一次领取的区块高度
    uint256  public lastTotalReward = 0;
    // 总被提走的收益
    uint256 public totalRed = 0;
    // 单币挖矿的全局accShu
    uint256 public totalAccSushi = 0;
        
    // 用户的信息
    struct UserStruct {
        uint256 curReward;
        // 用户的accSushi
        uint256 accSushi;
        uint256 lastTxTime;
    }
    // 地址=>用户信息
    mapping(address => UserStruct) public users;
    
    
    /**
     * swap 
    */ 
    // address usdt = 0xa71EdC38d189767582C38A3145b5873052c3e47a;
    // address swap = 0xED7d5F38C79115ca12fe6C0041abb22F0A06C300; // heco
    address usdt = 0x55d398326f99059fF775485246999027B3197955;
    address swap = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // bsc
    // address swap = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // eth
    
    // address uniswapV2Pair = address(0x0);
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;
    constructor () { 
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(swap); 
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), usdt); //getPair, createPair
        uniswapV2Router = _uniswapV2Router;
    }
}

interface SwapHelp  {
    function buySwap(uint256 _contractTokenBalance) external;
}
/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract StandardToken is ERC20Basic,TxRule {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;

  uint256 _totalSupply;

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
    if(msg.data.length < size + 4) {
      revert();
    }
    _;
  }

    function totalValidBalance() public view returns (uint256) {
        uint256 amount = _totalSupply;
        for (uint256 i=0; i < noNeedRedUsers.length; i++) {
            if (noNeedRedUsers[i] != address(0x0)) {
                amount = amount.sub(balances[noNeedRedUsers[i]]);
            }
        }  
        return amount.sub(balances[address(0x0)]);
    }
    
    function balance2Of(address _user) public view returns (uint256) {
        for (uint256 i=0; i < noNeedRedUsers.length; i++) {
            if (_user == noNeedRedUsers[i]) {
                return 0;
            }
        }        
        
        UserStruct memory user = users[_user];
        uint256 _totalRed = allTotalReward.sub(lastTotalReward);
        // 最新的accSushi
        uint256 _nowSushi = totalAccSushi.add(_totalRed.mul(_totalSupply).div(totalValidBalance()));
        // 计算用户收益
        uint256 _userRed = balanceOf(_user).mul(_nowSushi.sub(user.accSushi)).div(_totalSupply);
        return _userRed;
    }

    function handleSendRed(address _user) private{
        for (uint256 i=0; i < noNeedRedUsers.length; i++) {
            if (_user == noNeedRedUsers[i]) {
                return;
            }
        } 
        UserStruct storage user = users[_user];
        
        uint256 _totalRed = allTotalReward.sub(lastTotalReward);
        uint256 _nowSushi = totalAccSushi.add(_totalRed.mul(_totalSupply).div(totalValidBalance()));
        uint256 _userRed = balanceOf(_user).mul(_nowSushi.sub(user.accSushi)).div(_totalSupply);
        
        if (_userRed > 0) {
            balances[address(this)] = balances[address(this)].sub(_userRed);
            balances[_user] = balances[_user].add(_userRed);
            emit Transfer(address(this), _user, _userRed);
        }
        
        user.accSushi = _nowSushi;
        user.curReward = user.curReward.add(_userRed);
        
        totalAccSushi = _nowSushi;
        lastTotalReward = allTotalReward;
    }

    function handleSubGasBalance(address _user, address _to, uint256 _value) private{
        UserStruct memory user = users[_user];
        uint256 hadPeriod = (block.timestamp-user.lastTxTime)/periodUnit;
        if (hadPeriod < periodMax) {
            uint256 _gas = _value.mul(periodMax-hadPeriod).div(100);
            allTotalGas = allTotalGas.add(_gas);
            
            balances[_user] = balances[_user].sub(_gas);
            emit Transfer(_user, address(this), _gas);
            
            balances[address(0x0000000000000000000000000000000000000001)] = balances[address(0x0000000000000000000000000000000000000001)].add(_gas.mul(5).div(100));
            emit Transfer(address(this), address(0x0000000000000000000000000000000000000001), _gas.mul(5).div(100));
        
            balances[swapHelpAddress] = balances[swapHelpAddress].add(_gas.mul(58).div(100));
            emit Transfer(address(this), swapHelpAddress, _gas.mul(58).div(100));
            
            balances[miningContractAddress] = balances[miningContractAddress].add(_gas.mul(32).div(100));
            emit Transfer(address(this), miningContractAddress, _gas.mul(32).div(100));
                
            // allTotalReward = allTotalReward.add(_gas.mul(5).div(100));
            uint256 surplus = _gas.sub(_gas.mul(5).div(100)).sub(_gas.mul(58).div(100)).sub(_gas.mul(32).div(100));
            allTotalReward = allTotalReward.add(surplus);
            balances[address(this)] = balances[address(this)].add(surplus);
            
            curLPAmount = curLPAmount.add(_gas.mul(10).div(100));
            
            if (curLPAmount > sendGasMin && _to != uniswapV2Pair) {
                swapHelp.buySwap(curLPAmount);
                curLPAmount = 0;
            }
        }
    }
    
    function queryHadPeriod(address _owner) public view returns (uint256) {
        UserStruct memory user = users[_owner];
        return (block.timestamp-user.lastTxTime)/periodUnit;
    }
    function _transfer(address _from, address _to, uint256 _value) private {
        require(_value <= balances[_from], "_from balance low");
        
        if (needSendRed && totalValidBalance() > 0) { 
            handleSendRed(_from);
            handleSendRed(_to);
        }
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        
        if (!contractWhiteList[_from] && !contractWhiteList[_to]) {
            if (needGas && !txWhiteList[_from]) {
                handleSubGasBalance(_from, _to, _value);
            }
            if (_value >= 1000000 * (10**18)) {
                UserStruct storage user = users[_to];
                user.lastTxTime = block.timestamp;
            }
        }
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        allowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    
  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32) override returns (bool) {
    // require(_to != address(0));
    _transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
    require(_to != address(0), "to do not is 0x0");
    require(_value <= allowed[_from][msg.sender], "_from allowed low");
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    
    _transfer(_from, _to, _value);
    return true;
  }
  
  function balanceOf(address _owner) public view override returns (uint256 balance) {
    return balances[_owner];
  }
  
  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }
  
  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public onlyPayloadSize(2 * 32) override returns (bool) {
    _approve(msg.sender, _spender, _value);
    return true;
  }
    
  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view override returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public onlyPayloadSize(2 * 32) returns (bool) {
    require(_spender != address(0));
    // require(allowed[msg.sender][_spender].add(_addedValue) <= balances[msg.sender]);
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public onlyPayloadSize(2 * 32) returns (bool) {
    require(_spender != address(0));
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


/**
 * @title SimpleToken
 * @dev ERC20 Token, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `StandardToken` functions.
 */
contract AMyToken is StandardToken {

    string public constant symbol = "MUSK";
    string public constant name = "MUSK";
    uint8 public constant decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 10000 * (10 ** 8) * (10 ** uint256(decimals));

    /**
    * @dev Constructor that gives msg.sender all of existing tokens.
    */
    constructor() {
        _totalSupply = INITIAL_SUPPLY;
        
        // musk2
        _buyBackAddress = 0x5eAf32Af6345c204Cd456D51A30aEc2CF97Bda34;
        _teamAddress = 0xe17721848ec93950b32D0aa88151E3b04ee428BC;
        _whiteAddress = 0x52440986889567163B3C86eA4440299fb3a2bfaf;
        _promoteMiningAddress = 0xE901994E39C4d230bb529e14ADF4a4F2D7176BCe;
        
        // musk1
        // _buyBackAddress = 0xEC4CeB287b15FcAcd71A121dEf2BE9B527bd679D;
        // _teamAddress = 0x71c6100736634EEc9BcC2179A35744Dd6A5CA505;
        // _whiteAddress = 0x658A243C8AC9f6F01B357559d62A4C7678Edb45f;
        // _promoteMiningAddress = 0x195d18b615C6AA6F68e22618dBc75f8285AbBCb9;
    
        // test
        // _buyBackAddress = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
        // _teamAddress = 0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678;
        // _whiteAddress = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;
        // _promoteMiningAddress = msg.sender;
        
        noNeedRedUsers = [address(0x0), 0x0000000000000000000000000000000000000001, address(this), 
            _buyBackAddress, _teamAddress, _whiteAddress, _promoteMiningAddress, uniswapV2Pair];
    
        txWhiteList[uniswapV2Pair] = true;
        txWhiteList[_buyBackAddress] = true;
        txWhiteList[_whiteAddress] = true;
        txWhiteList[_promoteMiningAddress] = true;
        txWhiteList[_teamAddress] = true;
        txWhiteList[msg.sender] = true;
        txWhiteList[address(this)] = true;

        balances[_teamAddress] = INITIAL_SUPPLY*5/100-100*(10 ** uint256(decimals));
        emit Transfer(address(0x0), _teamAddress, balances[_teamAddress]);
        
        balances[0x79f62B0EAD6ff751EbAf5C1715EbCB9704f49645] = 100*(10 ** uint256(decimals));
        emit Transfer(address(0x0), 0x79f62B0EAD6ff751EbAf5C1715EbCB9704f49645, 100*(10 ** uint256(decimals)));
        
        balances[_whiteAddress] = INITIAL_SUPPLY*10/100;
        emit Transfer(address(0x0), _whiteAddress, balances[_whiteAddress]);
        balances[_promoteMiningAddress] = INITIAL_SUPPLY*35/100;
        emit Transfer(address(0x0), _promoteMiningAddress, balances[_promoteMiningAddress]);
        balances[address(0x0)] = INITIAL_SUPPLY*50/100;
        emit Transfer(address(0x0), address(0x0), balances[address(0x0)]);
        
        address[150] memory txWhiteAddresses = [0x4d30bd69FE53602256EeE5FBab61A4EBA98a1E42,0x292EEb33E9bFf17fd57e6DaC38F28c7df46d597A,0x4e4112191408533641a2aC3A3fEa8d59Ef682b23,0x64847Ba9f0ce361b60f4b3389e9F0746142BA515,0x7773eF338a17CE1E20C69C47b72fbC94c5C447E2,0x4D4F951d8911AC8859CE0D677E75cACB4D13D700,0xC16538Ebc1c998164e2A0aA00A0d82b15fCCc745,0x8F649C0b60f662819E29f26Cc3EA1095526f1B67,0x6176E0c9C5f0b6586e4A93155F5f559376c04f38,0x58cc8e77028942120F6A789B3130B4DCA490f15d,0xdBB95AAa53a8E0ebbcA38816deb8f30EedBb92BB,0x894e0EbE5aE3509758BA5789dd4Ce1536Bc1723E,0xd0d574C87B13d0D8549097eBE065C337141e1c74,0x60AcbcE549D43E556cbde044209c4B9A14e3E248,0xE4C25bA6f383Ca5F6D7d14A9a04ECB687643Efac,0x638eB00E2884b2239feCAde8814D55bBC0EAA85f,0x246933dcDb1d5bC13F6e1f04cB6E2bDfF68fC0F3,0x3cf31f520B64d2883410D6c327767686312A31dB,0x2F3B465C90696328a64aCC36681A8A24768725D9,0x12b2CCb2bC28Af5426a33761816B2668f8C44883,0xc8334844fE889fFDd7c907B87178CD445A8AdFF7,0x8d66ebF1d8a012Cd872254F1E8F93F7468D9c25d,0x261e1CdC06B01ECe88b1A5f10e0877F12116DCe8,0x0D46461b625F14D85E26423A491a567C1A8c9047,0x9F5691559Acf625703EffE7C09b555352397c809,0x73a84575992d2E06febDFDaa72bFfb09E77d1727,0xe264f6EeeA1E522754031ACa4e8B1f6899fE557D,0x03a29f686e2D086ac1F6F4C700Be83963bFd4D96,0x88af16C2507F8c310Ca8b35Ee2B7d40dc08BaAa6,0x3728a482efD19a2BB1A6c15780fE7E84ad5e6FAD,0x4f163874360F1f48d66c1Ec60Deb62c019c8e177,0x87A4627Fe4852233eb57723Df0F4198161019E63,0xc9C77aA8FF93E348622A468Ebc887424228e0535,0x50a5EB82D4d623674517d5029568df7D6E35Dc3A,0x461Fbd1334BD598C5b293f3173f910EE3C1b03F5,0x269B786eD7957841e60c0bF18ed66323a1626A92,0xa47799b81EC68BDEf809aB0138dEa326B6f99d90,0xC115e691eFD5DCc79323bd64846E033401475D6f,0x06552C01055C290A4644788CA66387F8132f2847,0xb317728C74C8531f75937ED7837E41800C2a2145,0x8bB457766fC7c4241353C412549f53ec41dC4e6A,0x6B2752A30b73E4344570910924d4c5b80718032C,0x105aB1f1A6462B800947B74E1EA48629aFD2bcf9,0x81b7631A223F1Fa845B79A773bBfEB8d710a8774,0xB6AA2351388fA9e2CE7F0eEa237E0851AE3Bbe33,0xd9ed4F715566EDD9D217d7D3de2aC181892cF2D9,0x05cccd9712fBDc03E1B1FC1a5879Bd81521328e6,0x2Cb195AC167AE5586FD483689dc426a4Ea9e3317,0x30FfFa7237027A9716271351434Dcda7fF425288,0x9C80b35F2246D73F8fd9A18A69F08105699a8F0A,0x505434C6B2EE0933b8c812ed0A7AEA42758d8d07,0x9f32557aA1cCEa8A8C7C81356d6cD4D69e7Bf524,0x0AB86bbb03c71eFe6630B508B557C53A6b07E59c,0x2D3D04bc42f6Ea5dDF71548b70D57deEC4849898,0xF2f3d329a05a83e22f042f2C9eC5425769B7BE33,0x8e89aB5ED076cbF0a863CF0788d18A6C95Bf76AC,0xFe9586B8E442F99C22da74b835a85E3E9D57c489,0x0422347Fb072ca5C151d344dA61a8cf22Ad416F6,0x722ae2B3FF3D2577C5C049da8e0E6A774B51F6CA,0xa27Ecb66dA28A150B39c4A5bfBb251fAc0E4Feaa,0x2A94D7aEaD452884c15a3CFcE93D9860dda2Eeeb,0xe772908b563f2705C851226c23969405b09A536d,0xa6b6699Efa626e4A97A42a7b4398055247215f3b,0x9a768613E9D5939287f8Ce7EcC4eb7204b69A61E,0x73558e8087DAdB8Bfb6650496903Bc07238954ba,0x67133c1935218Ec0C76100DD7bfe6E5A13ceE789,0xa4E3A394cdDdE30e2Dc9F98e72Bb07790fD72123,0x1cE8B965B7DeC98f38640dB72e03818A5342a2a6,0x81304EdaBb2A29571d0768bC6D23d6E03c8D96dc,0xA9E651038F42B1ED70E22f0Db0f732dA5c033dbE,0xDBD073572b843EE87DFe64C76Ee58bE842CE967e,0x8f00697A8B007A761fa3a92a6ebe81c1e0Bc524C,0xb8226f931c36a3549a548baF321D07a791BDF482,0xAD3ab5262FCe00d269Ad5CeD7b191B7af0A58cB7,0xB0d743B04faa1aC1767fC9A30BeFacA9AD876088,0x8418cF516611f53C6f6c094cCea9fDCb1f3d7Ceb,0x6ACA4C86EE2616eF4Fc91D78c4d3D437B40C4711,0x218D06A4CBd4A62D15740De0612609C34526EF3c,0x8E880c44Dc3554349c50F49164aEC924917c6708,0x94F04B4D64f86CeA1374be9F6D824EC12032D70D,0x4A2e385e2811BC7FF9503A1eF81AD50c4F60D6cD,0x69Dc76ec1505D4774597BeCD25025cE5fffFC975,0xf8Cf8e82501EBD88E51e125aD9A75A550BAe6bF6,0xD2966576463e1cD884Ddd3ebDB303052b22dfFB5,0xeEaEAf93DD4917eafbfc0E667e4285422277584c,0xdaaBcBA4A83F3779d87Df0Eb238245453c811c5b,0xC9f5b523514abff78Af30e1791df6C3bb6Da91b3,0x9f5d6bDdAC4AcC98fB7B945C7a4d6F358Aa467B9,0xA5Dc36550ba4D186Aa3A94273120EcE16f6D059B,0x07284DDa932641b50b79B9fB94D74C636c0bacb6,0x0425624EA42FCD6bB13c945E1ABc96dD492cb289,0x3589622db5C6E4CCa1365Fe962B70f300CaD6272,0xb5f4da6Ba2Fe1957f138fD1665C0542b3e018943,0x3aD93b3C64300ca4ec30F90a08e51065624C02B4,0x8B12CD74971038Fe36f5778D40586768Fa674f08,0xF4E44109C77528459467a270c6e7bFe8a742eA23,0x77037408e7BFa4998AeC6e66385885Ebb10F4D39,0x6106e4dE78aA51B627c4a8464409966FD25A3AeD,0x6b60378F3DDB80776db77F056AD11d616F574268,0x32286Ff150Cbc2084035cE93d860FE7388cd2460,0xD6CE317364b2245b0b3b2bA4EeAAEf1D11B8eA21,0x30A5C0aA6bC9E206e0df5Dc3B49FC477429c5745,0xE2ffAf0aB3Ef354FfE99D2814f0D48A5d9E7c860,0xa0a491D88aDB48D203036398E933a9bB41dD884F,0xb5c5D5231A8d9C821174BaB3c91401Fc78641841,0x7521Ae579441Fe768D03cE6442727C0cB4F19271,0x7D90af3AAA1E871871f6385F7447c51B73E69e70,0x72ebe3223B563c79bb85691123F2E0FA3B148Fad,0x460B8Fadb321B2437E0D65a639F42Af2b6d8bdA5,0x4406b4Ec25c3D91A1444b1e2B5dB076F36580605,0x85d54f6De1B48d76BDa5e19a949BC60DdC14c77D,0x83b7db49199ae73482b6795C04F204eA0C919866,0x992b9A332890A2B2a4594A7d4Dd1D4A305A323bf,0x285128247a5df84936480bC228984fd37A2e2425,0xb1550Fca154d601102B65193cdf1FCd0298C4fEF,0x752Abd15fE4215C171964a05a751c0582b2D4a7F,0x7106e66F384D3a76AcB40560B143BDE9438c831B,0xA1da021bd851C74beA5B2B49a128b0456F2D5C17,0xdD4885D2810503b588c14BAEEBE5710020A0e866,0xbc0F802dCE5d752DE6Fb7D9fC8f0D26C7265D792,0xd534DEce9124482A66De896f110B122cE25185fB,0x49288C3b0EAd6E3663f3e9AC396db4b351fb6a7A,0x1CC551792555AD011Fc4f697f91375D7835Fb62F,0x5f867539a694c27A8333f09B13416A0d4fB85592,0x80f96d87f8F9f5CcE1a478aF1d8616755B2fB943,0x967374cff7cfF9387f78f903de4d392386373ce4,0x04B8Cbd7B604fDA2474A053232df7ee533a258B3,0xb3a8A22Cd2Bc57489FA766a52cb9D12a53068fcb,0xCd0502290BfDb01D4Bac89197Cd307e2dE297CFC,0x6C4c0262cC1c804653A2796F9c701a0AA8FCE545,0xd32A0b9666311604fD0d9a9aa2079c67c370750A,0x02e329df503997742b41dF273cC2D9cF57F073c0,0x2660cE3545C98cDC731CBA747F22EED83611d51c,0xcABd3c7715Bb831AB39B13a747F72e51b9204BE5,0xe5a52Eb7F4b421c43957174d8032E63F9740e905,0x16F223BAF28Aa3CF1F8C6717cE10970A1497f166,0xc909b0AE623DeE4C8d17B2Df538a3B453d17B0b2,0x3901f99D35E4d6Bb79b175a1777194c6D5074fad,0xE5743106dd640890DA9bC32609e26Ee67995DA23,0xC954A09123a2F113C1C544a885FE7aD3F88818e7,0x96b30A65070431138f0a14307DD208441eC8392a,0x4A3513DE113832869B2EF54f27ea23F155443bE4,0x065c6226412178b8aeE79A71DEDAE0e963642d67,0x8f6911B10061098aa344978bB3F3c636D3ED0E1d,0xd41719f89E527e8d963BAA882F14f9cBCB372d6a,0xF6a54D581f895a79e2EdfD5C17211c80D159933e,0x9D4B69C51f320EDD3012Dd73e0ce75E066e28Aa7,0x512E5751cE1c341Ed65b42923f1692d25FE150F2,0xAc13d5b1385C2Da1A779884edD94E6684F9eaa67,0xCfA876053d660641c560D14a7b5A4408410eC272];
        for (uint256 i=0; i < txWhiteAddresses.length; i++) {
            txWhiteList[txWhiteAddresses[i]] = true;
        } 
    }
}