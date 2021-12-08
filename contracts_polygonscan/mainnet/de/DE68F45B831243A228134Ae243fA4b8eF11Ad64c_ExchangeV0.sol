/**
 *Submitted for verification at polygonscan.com on 2021-12-08
*/

pragma solidity >=0.5.0;
interface IV2Factory {
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
pragma solidity >=0.5.0;

interface IV2Pair {
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
pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

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
pragma solidity ^0.6.0;
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }  
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b > 0, errorMessage);
        uint c = a / b;
        return c;
    }
    function mod(uint a, uint b) internal pure returns (uint) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b != 0, errorMessage);
        return a % b;
    }                             
}
pragma solidity ^0.6.0;
contract Ownable  {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
pragma solidity =0.6.6;
contract ExchangeV0 is Ownable {
    using SafeMath for uint;
    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }           
    mapping (address=>uint) private _feeBalances;
    event DepositFee(address indexed a, uint amount,uint total);
    event WithdrawFee(address indexed a, uint total);
    uint public swapFee=500000000000000000;//0.5MATIC
    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'ETH_TRANSFER_FAILED');
    } 
    function setExchangeFee(uint _swapFee) external onlyOwner {
        swapFee = _swapFee;
    }    
    function depositFee() external payable  {
        uint amount=msg.value;
        _feeBalances[msg.sender]=_feeBalances[msg.sender]+amount;
        emit DepositFee(msg.sender,amount,_feeBalances[msg.sender]);
    }
    function withdrawFee() external{
        uint amount=_feeBalances[msg.sender];        
        safeTransferETH(msg.sender,amount);
        emit WithdrawFee(msg.sender,_feeBalances[msg.sender]);
        _feeBalances[msg.sender]=0;
    }
    function _swap(uint[] memory amount01Outs, address[] memory pairs, address _to) internal virtual {
        for (uint i=0; i < pairs.length; i++) {
            address to = (i < pairs.length - 1) ? pairs[i] : _to;
            IV2Pair(pairs[i]).swap(amount01Outs[2*i], amount01Outs[2*i+1], to, new bytes(0));
        }
    }     
    function swapExactTokensForTokens(
        address tokenIn,
        uint amountIn, 
        uint[] calldata amountOuts,
        address[] calldata pairs,
        address recipient,
        uint deadline        
        ) external ensure(deadline){
            require(_feeBalances[msg.sender]>=swapFee, "Fee Exchange don't enough");
           IERC20(tokenIn).transferFrom(recipient,pairs[0],amountIn); 
           _swap(amountOuts,pairs,recipient) ;
           safeTransferETH(owner(),swapFee);
    }
    function swapExactTokensForTokensFree(
        address tokenIn,
        uint amountIn, 
        uint[] calldata amountOuts,
        address[] calldata pairs,
        address recipient,
        uint deadline        
        ) external ensure(deadline) onlyOwner{
           IERC20(tokenIn).transferFrom(recipient,pairs[0],amountIn); 
           _swap(amountOuts,pairs,recipient) ;
    }


}