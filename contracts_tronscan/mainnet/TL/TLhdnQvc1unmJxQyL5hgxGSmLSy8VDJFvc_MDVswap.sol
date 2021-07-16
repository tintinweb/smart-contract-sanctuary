//SourceUnit: modifiedContract_May14.sol

pragma solidity 0.5.15;

library SafeMath {

     /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
}

 interface TRC20{
    
    function balanceOf(address _owner) external view returns (uint256 balance);
    function totalSupply() external view returns (uint256);
    function transfer(address _to, uint256 _value)external  returns(bool);
    function approve(address _spender,uint _value)external  returns(bool);
    function transferFrom(address _from,address _to,uint256 _value)external  returns(bool);
    function allowance(address _owner, address _spender)external  view returns(uint256);
    event Transfer(address indexed _from,address indexed _to,uint256 _value);
    event Approval(address indexed _owner,address indexed _spender,uint256 _value);
    
}


contract MDVswap {
    
    using SafeMath for uint256;
    
    TRC20 public  USDT;
    TRC20 public MDV;
    address public owner;
    
    address public feeTo;
    uint public fee;
    uint public feeCollected;
    uint256 public initialPrice; // permdv in 6 decimals
    
    mapping(address => mapping(address => bool)) public pairStatus;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }
    
    event PairUpdation(address USDTAddr, address MDVAddr, uint256 Initial, uint256 Time);
    event OwnerTransaction(uint8 Flag, address TokenAddress, uint256 Time); // 1 = deposit, 2 = withdraw 
    event SwapToken(address User, address InToken, uint256 InAmount, address OutToken, uint256 OutAmount, uint256 Time);
    
    /**
     * @param _usdt usdt contract address
     * @param _mdv MDV contract address
     * @param _initial Price of MDV in USDT. 2000 => 0.02
     * @param _feeTo Fee will be sent to this address
     * @param _fee fee 2 means 0.02 percentage
     * 
     */ 
    constructor(address _usdt, address _mdv, uint256 _initial, address _feeTo, uint _fee) public {
        owner = msg.sender;
        USDT = TRC20(_usdt);
        MDV = TRC20(_mdv);
        initialPrice = _initial;
        feeTo = _feeTo;
        fee = _fee;
        
        pairStatus[_usdt][_mdv] = true;
        pairStatus[_mdv][_usdt] = true;
        
        emit PairUpdation(_usdt, _mdv, _initial, block.timestamp);
    }
    
    function getBalance(address _token) public view returns (uint) {
      return TRC20(_token).balanceOf(address(this));
    }
    
    function getPoolUsdtBlance() public view returns (uint) {
      return TRC20(USDT).balanceOf(address(this));
    }
    
    function getPoolMDVBlance() public view returns (uint) {
      return TRC20(MDV).balanceOf(address(this));
    }
   
    function depositToken(address _token, uint256 _amount) public onlyOwner returns(bool) {
        TRC20(_token).transferFrom(owner, address(this), _amount);
        emit OwnerTransaction(1, _token, block.timestamp);
        return true;
    }
    
    function withdrawFee() external returns(bool) {
        require(msg.sender == feeTo, "UnAuthorized");
        USDT.transfer(feeTo, feeCollected);
        feeCollected = 0;
        return true;
    }
    
    function swap(address fromToken, address toToken, uint256 inAmount) external returns(bool) {
        require(pairStatus[fromToken][toToken], "Invalid Pair");
        
        uint256 outAmount;
        
        if(address(USDT) == fromToken)  {
            //1 usdt = 50 mdv
            //TODO add minimum value check
            require(inAmount >= 1000000, "Minimum inAmount");
            outAmount = (inAmount.div(initialPrice)).mul(10 ** 18); 
            uint perc = inAmount.div(1000000).mul(fee.mul(100));
            feeCollected = feeCollected.add(perc);
        } else {
            //1 mdv = 0.02 usdt
            // initialPrice = 20000
            
            //TODO add minimum value check
            outAmount = (inAmount.mul(initialPrice)); 
            outAmount = outAmount.div(10 ** 18);
            
            require(outAmount <= TRC20(toToken).balanceOf(address(this)).sub(feeCollected), "Not Enough Liquidity");
        }
            
        
        require(outAmount <= TRC20(toToken).balanceOf(address(this)), "Insufficient Balance in Contract");
        TRC20(fromToken).transferFrom(msg.sender, address(this), inAmount);
        TRC20(toToken).transfer(msg.sender, outAmount);
        emit SwapToken(msg.sender, fromToken, inAmount, toToken, outAmount, block.timestamp);
        return true;
    }
    
    function updatePairDetails(address _usdt, address _mdv, uint256 _initial) external onlyOwner returns(bool) {
        require(_usdt != _mdv, "Invalid Address");
        
        pairStatus[address(USDT)][address(MDV)] = false;
        pairStatus[address(MDV)][address(USDT)] = false;
        
        USDT = TRC20(_usdt);
        MDV = TRC20(_mdv);
        initialPrice = _initial;
        
        pairStatus[_usdt][_mdv] = true;
        pairStatus[_mdv][_usdt] = true;
        
        emit PairUpdation(_usdt, _mdv, _initial, block.timestamp);
        return true;
    }
    
    function setFee(address _feeTo, uint _fee) external onlyOwner {
        feeTo = _feeTo;
        fee = _fee;
    }
    
}