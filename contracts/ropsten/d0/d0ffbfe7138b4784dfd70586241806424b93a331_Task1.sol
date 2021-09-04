/**
 *Submitted for verification at Etherscan.io on 2021-09-04
*/

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
    
    function totalSupply() external view returns (uint256);
    function transfer(address _to, uint256 _value)external  returns(bool);
    function approve(address _spender,uint _value)external  returns(bool);
    function transferFrom(address _from,address _to,uint256 _value)external  returns(bool);
    function allowance(address _owner, address _spender)external  view returns(uint256);
    event Transfer(address indexed _from,address indexed _to,uint256 _value);
    event Approval(address indexed _owner,address indexed _spender,uint256 _value);
    
}


contract Task1 {
    
    using SafeMath for uint256;
    
    TRC20 public  USDT;
    TRC20 public SHAMLA;
    address public owner;
    
    uint256 initialPrice; // pershamla in 6 decimals
    
    mapping(address => mapping(address => bool)) public pairStatus;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }
    
    event InitialPriceUpdation(uint256 Initial, uint256 Time);
    event OwnerTransaction(uint8 Flag, address TokenAddress, uint256 Time); // 1 = deposit, 2 = withdraw 
    event SwapToken(address User, address InToken, uint256 InAmount, address OutToken, uint256 OutAmount, uint256 Time);
    
    constructor(address _usdt, address _shamla, uint256 _initial) public {
        owner = msg.sender;
        USDT = TRC20(_usdt);
        SHAMLA = TRC20(_shamla);
        initialPrice = _initial;
        
        pairStatus[_usdt][_shamla] = true;
        pairStatus[_shamla][_usdt] = true;
        
        emit InitialPriceUpdation(_initial, block.timestamp);
    }
    
    function updateInitialPrice(uint256 _initial) public onlyOwner returns(bool) {
        initialPrice = _initial;
        emit InitialPriceUpdation(_initial, block.timestamp);
        return true;
        
    }
    
    function depositToken(address _token, uint256 _amount) public onlyOwner returns(bool) {
        TRC20(_token).transferFrom(owner, address(this), _amount);
        emit OwnerTransaction(1, _token, block.timestamp);
        return true;
    }
    
    function withdrawToken(address _token, uint256 _amount) public onlyOwner returns(bool) {
        TRC20(_token).transfer(owner, _amount);
        emit OwnerTransaction(2, _token, block.timestamp);
        return true;
    }
    
    
    function swap(address fromToken, address toToken, uint256 inAmount) external returns(bool) {
        require(pairStatus[fromToken][toToken], "Invalid Pair");
        
        uint256 outAmount;
        
        if(address(USDT) == fromToken) 
            outAmount = (inAmount.mul(10 ** 6)).div(initialPrice);
        else 
            outAmount = (inAmount.mul(initialPrice)).div(10**6);
            
        TRC20(fromToken).transferFrom(msg.sender, address(this), inAmount);
        TRC20(toToken).transfer(msg.sender, outAmount);
        emit SwapToken(msg.sender, fromToken, inAmount, toToken, outAmount, block.timestamp);
        return true;
    }
    
}