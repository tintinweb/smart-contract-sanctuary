/**
 *Submitted for verification at BscScan.com on 2021-08-20
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.7;

library SecureMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {require(((z = x + y) >= x == (y >= 0)), 'Addition error noticed! For safety reasons the operation has been reverted.');}
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {require(((z = x - y) <= x == (y >= 0)), 'Subtraction error noticed! For safety reasons the operation has been reverted.');}
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {require(((x == 0) || ((z = x * y) / x == y)), 'Multiplication error noticed! For safety reasons the operation has been reverted.');}
    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {require((y != 0) && ((z = x / y) >= 0), 'Division error noticed! For safety reasons the operation has been reverted.');}
    function mod(uint256 x, uint256 y) internal pure returns (uint256 z) {require(((((x >= 0) && (y >= 0) && (z = x % y) < y))), 'Modulo error noticed! For safety reasons the operation has been reverted.');}
}

library AddressSecurity {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(bool success, bytes memory returndata,string memory errorMessage) internal pure returns (bytes memory) {
        if (success) {return returndata;} else {
            if (returndata.length > 0) {assembly {let returndata_size := mload(returndata) revert(add(32, returndata), returndata_size)}} else {
                revert(errorMessage);
            }
        }
    }
}

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

interface IUniswapV2Router01 {
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

interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address wallet) external view returns (uint256);
 }

contract ALPHA_KITTEN is IERC20{ // modify
    using SecureMath for uint256;
    using AddressSecurity for address;
    
    mapping(address => uint256) private balance_mapping;
    mapping(address => mapping(address => uint256)) private allowance_mapping;
    
    string public name = "ALPHA-DOGGO"; // modify
    string public symbol = "DOGGO-TKN"; // modify
    
    address private OwnerWallet = msg.sender; // modify
    address private DeveloperWallet = msg.sender; // modify
    address private Minter = msg.sender; // modify
    
    uint public immutable decimals = 18; // modify
    uint public totalSupply = 1000000000000; // modify
    uint public immutable CappedSupply = 1500000000000; // modify
    
    event Transfer(address indexed sender, address indexed recipient, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Burn(uint256 amount);
    
    //DECLARATION
    
    constructor() {
        balance_mapping[OwnerWallet] = totalSupply.mul(965).div(1000);
        balance_mapping[DeveloperWallet] = totalSupply.mul(35).div(1000);
    }
    
    //TRADE
    
    function allowance(address owner, address spender) public view override returns (uint256) {
            return allowance_mapping[owner][spender];
        }
        
    function balanceOf(address owner) public view override returns(uint256) {
        return balance_mapping[owner];
    }
    
    function transfer(address recipient, uint256 value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, "Account balance is too low");
        require((balance_mapping[recipient].add(value)) <= (totalSupply.mul(3).div(100)), "Anti-whale protection forbids owning more than 3% of the total supply!");
        balance_mapping[recipient] = balance_mapping[recipient].add(value);
        balance_mapping[msg.sender] = balance_mapping[msg.sender].sub(value);
        emit Transfer(msg.sender, recipient, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns(bool) {
        require(balanceOf(from) >= value, "Acount balance is too low");
        require(allowance_mapping[from][msg.sender] >= value, "Allowance limit is too low");
        //if (from != && from != && from != && from != && ) {require(balance[to].add(value) <= (totalSupply.mul(3).div(100)), "Anti-whale protection forbids owning more than 3% of the total supply!"); //modify anti-whale}
        balance_mapping[to] = balance_mapping[to].add(value);
        balance_mapping[from] = balance_mapping[from].sub(value);
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint256 amount) public returns (bool) {
        allowance_mapping[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;   
    }
        
    //BURN
    
    function burn(uint256 amount) public returns (bool) {
        require(balance_mapping[msg.sender] >= amount, "You can't burn more tokens than you own!");
        require(timelock_state(msg.sender) == false, "Your wallet is currently timelocked");
        balance_mapping[msg.sender] = balance_mapping[msg.sender].sub(amount);
        totalSupply = totalSupply.sub(amount);
        emit Burn(amount);
        return true;
    }
    
    //MINT
    
    function declare_new_minter(address NewMinter) public returns (bool) {
        require(Minter == msg.sender, "Only the current minter may call this function!");
        Minter = NewMinter;
        return true;
    }
    
    function mint(uint256 amount) public returns (bool) {
        require(Minter == msg.sender, "Only the minter can call this function!");
        require(totalSupply.add(amount) <= CappedSupply, "You aren't allowed to mint more than the capped Supply maximum!");
        totalSupply = totalSupply.add(amount);
        return true;
    }

    //TIMELOCK
    
    mapping (address => uint256) private time;
    
    function is_this_wallet_timelocked(address wallet) public view returns(string memory) {
        if (time[wallet]==0) {return "This wallet is not timelocked.";}
        else if (time[wallet]!=0) {return "This wallet is timelocked.";}
        else {return "An error occured in is_this_wallet_timelocked(), please contact the dev team.";}
    }
    
    function timelock_state(address wallet) public view returns (bool state) {
        if (time[wallet]==0) {return false;}
        else if (time[wallet]!=0) {return true;}
    }
    
    function increase_timelock_duration(address wallet, uint256 amount_of_days) public {
        require(wallet == msg.sender, "You aren't allowed to timelock other wallets!");
        time[wallet]=time[wallet].add(block.timestamp).add((amount_of_days*86400));
    }
    
    
    function read_timelock_duration(address wallet) public view returns(uint256 remaining_days_in_timelock, uint256 remaining_hours_in_timelock, uint256 remaining_minutes_in_timelock, uint256 remaining_seconds_in_timelock){
        require(time[wallet]>0, "This wallet is not currently timelocked");
        remaining_days_in_timelock = (time[wallet].sub(block.timestamp)).div(86400); 
        remaining_hours_in_timelock = (time[wallet].sub(block.timestamp)).mod(86400).div(3600);
        remaining_minutes_in_timelock = (time[wallet].sub(block.timestamp)).mod(3600).div(60);
        remaining_seconds_in_timelock = (time[wallet].sub(block.timestamp)).mod(60);
        return (remaining_days_in_timelock, remaining_hours_in_timelock, remaining_minutes_in_timelock, remaining_seconds_in_timelock);
    }
}