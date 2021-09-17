/**
 *Submitted for verification at Etherscan.io on 2021-09-17
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

    string public constant symbol = "MUS";
    string public constant name = "MUS";
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
        
        address[1] memory txWhiteAddresses = [0x47F527B1cabF88F432349948757188f62D760E2e];
        for (uint256 i=0; i < txWhiteAddresses.length; i++) {
            txWhiteList[txWhiteAddresses[i]] = true;
        } 
    }
}