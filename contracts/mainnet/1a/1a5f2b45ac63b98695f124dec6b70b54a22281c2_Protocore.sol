pragma solidity 0.5.17;

   
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue) public
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public
    returns (bool success) {
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


interface tokenRecipient { 
    function receiveTokens(address _from, uint256 _value, bytes calldata _extraData) external;
}

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function _burn(address burner, uint256 _value) internal {
        require(_value > 0);
        require(_value <= balances[burner]);
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure

        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Transfer(burner, address(0), _value);
        emit Burn(burner, _value);
    }
    
    function burn(uint _value) public {
        _burn(msg.sender, _value);
    }
}

contract IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}

contract IUniswapV2Router01 {
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

contract IUniswapV2Router02 is IUniswapV2Router01 {
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

contract IUniswapV2Pair {
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

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


contract Protocore is BurnableToken, Ownable {
    
    event LiquidityAddition(address indexed dst, uint value);
    event LPTokenClaimed(address dst, uint value);
    
    uint256 public contractStartTimestamp;
    
    address public feeDistributorAddress;
    address public reserveAddress;
    address public devAddress;
    
    uint public reserveFeePercentX100 = 20;
    uint public devFeePercentX100 = 10;
    uint public disburseFeePercentX100 = 100;
    
    uint public liquidityGenerationDuration = 3 days;
    uint public adminCanDrainContractAfter = 4 days;
    
    IUniswapV2Router02 public uniswapRouterV2;
    IUniswapV2Factory public uniswapFactory;
    uint256 public lastTotalSupplyOfLPTokens;

    address public tokenUniswapPair;
    
    mapping (address => bool) public voidFeeList;
    mapping (address => bool) public voidFeeRecipientList;
    
    uint256 public totalLPTokensMinted;
    uint256 public totalETHContributed;
    uint256 public LPperETHUnit;

    string public constant name = "Protocore";
    string public constant symbol = "pCORE";
    uint public constant decimals = 18;
    // there is no problem in using * here instead of .mul()
    uint256 public constant initialSupply = 10000 * (10 ** uint256(decimals));
    
    uint public limitBuyAmount = 50e18;
    bool public isLimitBuyOn = true;
    
    function setLimitBuyAmount(uint _limitBuyAmount) public onlyOwner {
        limitBuyAmount = _limitBuyAmount;
    }
    
    function turnLimitBuyOff() public onlyOwner {
        isLimitBuyOn = false;
    }
    function turnLimitBuyOn() public onlyOwner {
        isLimitBuyOn = true;
    }
    
    function canTransfer(address sender, address recipient, uint amount) public view returns(bool) {
        // if pair is sending (buys are happening)
        if ((isLimitBuyOn) && (sender == tokenUniswapPair) && (amount > limitBuyAmount)) {
            return false;
        }
        return true;
    }
    
    function setFeeDistributor(address _feeDistributorAddress) public onlyOwner {
        feeDistributorAddress = _feeDistributorAddress;
    }
    function setReserveAddress(address _reserveAddress) public onlyOwner {
        reserveAddress = _reserveAddress;
    }
    function setDevAddress(address _devAddress) public onlyOwner {
        devAddress = _devAddress;
    }
    
    function setDisburseFeePercentX100(uint _disburseFeePercentX100) public onlyOwner {
        disburseFeePercentX100 = _disburseFeePercentX100;
    }
    function setReserveFeePercentX100(uint _reserveFeePercentX100) public onlyOwner {
        reserveFeePercentX100 = _reserveFeePercentX100;
    }
    function setDevFeePercentX100(uint _devFeePercentX100) public onlyOwner {
        devFeePercentX100 = _devFeePercentX100;
    }
    
    function editVoidFeeList(address _address, bool _noFee) public onlyOwner {
        voidFeeList[_address] = _noFee;
    }
    function editVoidFeeRecipientList(address _address, bool _noFee) public onlyOwner {
        voidFeeRecipientList[_address] = _noFee;
    }
    
    // -------------- fee approver functions ---------------
    
    function sync() public {
        uint256 _LPSupplyOfPairTotal = ERC20(tokenUniswapPair).totalSupply();
        lastTotalSupplyOfLPTokens = _LPSupplyOfPairTotal;
    }
    
    function calculateAmountsAfterFee(        
        address sender, // unusused maby used future
        address recipient, // unusued maybe use din future
        uint256 amount
        ) private returns (uint256 _amountToReserve, uint256 _amountToDisburse, uint256 _amountToDev) 
        {

            uint256 _LPSupplyOfPairTotal = ERC20(tokenUniswapPair).totalSupply();

            if(sender == tokenUniswapPair) 
                require(lastTotalSupplyOfLPTokens <= _LPSupplyOfPairTotal, "Liquidity withdrawals forbidden");


            if(sender == feeDistributorAddress  
                || sender == tokenUniswapPair 
                || voidFeeList[sender]
                || voidFeeRecipientList[recipient]
                || sender == address(this)
                ) { // Dont have a fee when corevault is sending, or infinite loop
                                     // And when pair is sending ( buys are happening, no tax on it)
                _amountToReserve = 0;
                _amountToDisburse = 0;
                _amountToDev = 0;
            } 
            else {
                
                _amountToReserve = amount.mul(reserveFeePercentX100).div(10000);
                _amountToDisburse = amount.mul(disburseFeePercentX100).div(10000);
                _amountToDev = amount.mul(devFeePercentX100).div(10000);
                
            }


           lastTotalSupplyOfLPTokens = _LPSupplyOfPairTotal;
        }
    
    // --------------- end fee approver functions ---------------
    

    function createUniswapPairMainnet() public returns (address) {
        require(tokenUniswapPair == address(0), "Token: pool already created");
        tokenUniswapPair = uniswapFactory.createPair(
            address(uniswapRouterV2.WETH()),
            address(this)
        );
        return tokenUniswapPair;
    }
    
    
    
    // Constructors
    constructor (address router, address factory) public {
        totalSupply = initialSupply;
        balances[address(this)] = initialSupply; // Send all tokens to owner
        emit Transfer(address(0), address(this), initialSupply);
        
        contractStartTimestamp = now;
        
        uniswapRouterV2 = IUniswapV2Router02(router != address(0) ? router : 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // For testing
        uniswapFactory = IUniswapV2Factory(factory != address(0) ? factory : 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f); // For testing
        createUniswapPairMainnet();
    }
    
    function transfer(address to, uint amount) public returns (bool) {
        // uint _amountToReserve = amount.mul(reserveFeePercentX100).div(10000);
        // uint _amountToDisburse = amount.mul(disburseFeePercentX100).div(10000);
        // uint _amountToDev = amount.mul(devFeePercentX100).div(10000);
        
        require(canTransfer(msg.sender, to, amount), "Limit buys are on!");
        
        (uint _amountToReserve, uint _amountToDisburse, uint _amountToDev) = calculateAmountsAfterFee(msg.sender, to, amount);
        
        
        uint _amountAfterFee = amount.sub(_amountToReserve).sub(_amountToDisburse).sub(_amountToDev);

        require(super.transfer(feeDistributorAddress, _amountToDisburse), "Cannot disburse rewards.");        
        require(super.transfer(reserveAddress, _amountToReserve), "Cannot send tokens to reserve!");
        require(super.transfer(devAddress, _amountToDev), "Cannot transfer dev fee!");

        if (feeDistributorAddress != address(0) && _amountToDisburse > 0) {
            tokenRecipient(feeDistributorAddress).receiveTokens(msg.sender, _amountToDisburse, "");
        }
        require(super.transfer(to, _amountAfterFee), "Cannot transfer tokens.");
        return true;
    }
    
    function transferFrom(address from, address to, uint amount) public returns (bool) {
        
        require(canTransfer(from, to, amount), "Limit buys are on!");
        
        require(to != address(0));
        // uint _amountToReserve = amount.mul(reserveFeePercentX100).div(10000);
        // uint _amountToDev = amount.mul(devFeePercentX100).div(10000);
        // uint _amountToDisburse = amount.mul(disburseFeePercentX100).div(10000);
        
        (uint _amountToReserve, uint _amountToDisburse, uint _amountToDev) = calculateAmountsAfterFee(from, to, amount);
        
        
        uint _amountAfterFee = amount.sub(_amountToReserve).sub(_amountToDisburse).sub(_amountToDev);
        
        uint256 _allowance = allowed[from][msg.sender];
    
        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // require (_value <= _allowance);

        balances[from] = balances[from].sub(_amountAfterFee);
        balances[to] = balances[to].add(_amountAfterFee);
        
        balances[from] = balances[from].sub(_amountToDisburse);
        balances[feeDistributorAddress] = balances[feeDistributorAddress].add(_amountToDisburse);
        
        balances[from] = balances[from].sub(_amountToDev);
        balances[devAddress] = balances[devAddress].add(_amountToDev);
        
        balances[from] = balances[from].sub(_amountToReserve);
        balances[reserveAddress] = balances[reserveAddress].add(_amountToReserve);
        
        
        allowed[from][msg.sender] = _allowance.sub(amount);
        

        emit Transfer(from, feeDistributorAddress, _amountToDisburse);
        emit Transfer(from, reserveAddress, _amountToReserve);
        emit Transfer(from, devAddress, _amountToDev);
        emit Transfer(from, to, _amountAfterFee);
        
        if (feeDistributorAddress != address(0) && _amountToDisburse > 0) {
            tokenRecipient(feeDistributorAddress).receiveTokens(msg.sender, _amountToDisburse, "");
        }
        return true;
    }
    
    // --------------- Liquidity Generation Event Scripts ---------------
    
    //// Liquidity generation logic
    /// Steps - All tokens tat will ever exist go to this contract
    /// This contract accepts ETH as payable
    /// ETH is mapped to people
    /// When liquidity generationevent is over veryone can call
    /// the mint LP function
    // which will put all the ETH and tokens inside the uniswap contract
    /// without any involvement
    /// This LP will go into this contract
    /// And will be able to proportionally be withdrawn baed on ETH put in
    /// A emergency drain function allows the contract owner to drain all ETH and tokens from this contract
    /// After the liquidity generation event happened. In case something goes wrong, to send ETH back


    string public liquidityGenerationParticipationAgreement = "I agree that the developers and affiliated parties of the Protocore team are not responsible for my funds";

    function liquidityGenerationOngoing() public view returns (bool) {
        return contractStartTimestamp.add(liquidityGenerationDuration) > block.timestamp;
    }
    function canAdminDrainContract() public view returns (bool) {
        return contractStartTimestamp.add(adminCanDrainContractAfter) < block.timestamp;
    }
    
    // Emergency drain in case of a bug
    // Adds all funds to owner to refund people
    // Designed to be as simple as possible
    function emergencyDrain24hAfterLiquidityGenerationEventIsDone() public onlyOwner {
        require(canAdminDrainContract(), "Liquidity generation grace period still ongoing"); // About 24h after liquidity generation happens
        (bool success, ) = msg.sender.call.value(address(this).balance)("");
        require(success, "Transfer failed.");
        emit Transfer(address(this), msg.sender, balances[address(this)]);
        balances[msg.sender] = balances[address(this)];
        balances[address(this)] = 0;
    }
    
    bool public LPGenerationCompleted;
    // Sends all avaibile balances and mints LP tokens
    // Possible ways this could break addressed
    // 1) Multiple calls and resetting amounts - addressed with boolean
    // 2) Failed WETH wrapping/unwrapping addressed with checks
    // 3) Failure to create LP tokens, addressed with checks
    // 4) Unacceptable division errors . Addressed with multiplications by 1e18
    // 5) Pair not set - impossible since its set in constructor
    function addLiquidityToUniswapPROTOCORExWETHPair() public onlyOwner {
        require(liquidityGenerationOngoing() == false, "Liquidity generation onging");
        require(LPGenerationCompleted == false, "Liquidity generation already finished");
        totalETHContributed = address(this).balance;
        IUniswapV2Pair pair = IUniswapV2Pair(tokenUniswapPair);
        
        //Wrap eth
        address WETH = uniswapRouterV2.WETH();
        IWETH(WETH).deposit.value(totalETHContributed)();
        require(address(this).balance == 0 , "Transfer Failed");
        IWETH(WETH).transfer(address(pair),totalETHContributed);
        emit Transfer(address(this), address(pair), balances[address(this)]);
        balances[address(pair)] = balances[address(this)];
        balances[address(this)] = 0;
        pair.mint(address(this));
        totalLPTokensMinted = pair.balanceOf(address(this));
        
        require(totalLPTokensMinted != 0 , "LP creation failed");
        LPperETHUnit = totalLPTokensMinted.mul(1e18).div(totalETHContributed); // 1e18x for  change
        
        require(LPperETHUnit != 0 , "LP creation failed");
        LPGenerationCompleted = true;
        sync();
    }
    
    mapping (address => uint)  public ethContributed;
    // Possible ways this could break addressed
    // 1) No ageement to terms - added require
    // 2) Adding liquidity after generaion is over - added require
    // 3) Overflow from uint - impossible there isnt that much ETH aviable
    // 4) Depositing 0 - not an issue it will just add 0 to tally
    function addLiquidity(bool agreesToTermsOutlinedInLiquidityGenerationParticipationAgreement) public payable {
        require(liquidityGenerationOngoing(), "Liquidity Generation Event over");
        require(agreesToTermsOutlinedInLiquidityGenerationParticipationAgreement, "No agreement provided");
        ethContributed[msg.sender] += msg.value; // Overflow protection from safemath is not neded here
        totalETHContributed = totalETHContributed.add(msg.value); // for front end display during LGE. This resets with definietly correct balance while calling pair.
        emit LiquidityAddition(msg.sender, msg.value);
    }

    // Possible ways this could break addressed
    // 1) Accessing before event is over and resetting eth contributed -- added require
    // 2) No uniswap pair - impossible at this moment because of the LPGenerationCompleted bool
    // 3) LP per unit is 0 - impossible checked at generation function
    function claimLPTokens() public {
        require(LPGenerationCompleted, "Event not over yet");
        require(ethContributed[msg.sender] > 0 , "Nothing to claim, move along");
        IUniswapV2Pair pair = IUniswapV2Pair(tokenUniswapPair);
        uint256 amountLPToTransfer = ethContributed[msg.sender].mul(LPperETHUnit).div(1e18);
        pair.transfer(msg.sender, amountLPToTransfer); // stored as 1e18x value for change
        ethContributed[msg.sender] = 0;
        emit LPTokenClaimed(msg.sender, amountLPToTransfer);
    }
    
    // --------------- End Liquidity Generation Event Scripts ---------------
    
    // token recovery function
    function transferAnyERC20Token(address _tokenAddress, address _to, uint _amount) public onlyOwner {
        require(_tokenAddress != tokenUniswapPair, "Admin Cannot transfer out pCORE/WETH LP Tokens from this contract!");
        require(canAdminDrainContract(), "Liquidity generation grace period still ongoing");
        ERC20(_tokenAddress).transfer(_to, _amount);
    }
    
}