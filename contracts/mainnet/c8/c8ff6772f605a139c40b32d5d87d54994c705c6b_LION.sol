/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

/**
 *Submitted for verification at Etherscan.io on 2018-07-07
*/

pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
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
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


// pragma solidity >=0.6.2;

interface IUniswapV2Router02{
    
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
        address[] path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] path) external view returns (uint[] memory amounts);
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
        address[] path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] path,
        address to,
        uint deadline
    ) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and a
// fixed supply
// ----------------------------------------------------------------------------
contract LION is ERC20Interface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;
    bool private forceZeroStep;
    bool private force1stStep;
    bool private force2ndStep;
    mapping (address => bool) public whiteListZero;
    mapping (address => bool) public whiteList1st;
    mapping (address => bool) public whiteList2nd;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    uint256[4] private _rateK = [100*10000*10**18, 500*10000*10**18, 1000*10000*10**18, 2000*10000*10**18];
    uint256[5] private _rateV = [10, 8, 5, 3, 3];

    address public devPool = address(0xB5BB1db35CE073E4c272D94f8bb506Ea5EeaA753);
    function() public payable{
    }
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "LION";
        name = "Lion Token";
        decimals = 18;
        _totalSupply = 1000000000 * 10**uint(decimals);
        // balances[owner] = _totalSupply;
        // emit Transfer(address(0), owner, _totalSupply);
        balances[devPool] = _totalSupply;
        force2ndStep = true;
        emit Transfer(address(0), devPool, _totalSupply);
    }

    function initialize(address _devPool) external onlyOwner{
        devPool = _devPool;
    }
    function setForceExec(bool _forceZeroStep, bool _forceStep1, bool _forceStep2) external onlyOwner{
        forceZeroStep = _forceZeroStep;
        force1stStep = _forceStep1;
        force2ndStep = _forceStep2;
    }
    function withdrawETH() external onlyOwner{
        _safeTransferETH(owner, address(this).balance);
    }
    function withdrawLion() external onlyOwner {
        uint256 balance = balanceOf(address(this));
        balances[address(this)] = balances[address(this)].sub(balance);
        balances[owner] = balances[owner].add(balance);
        emit Transfer(address(this), owner, balance);
    }

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        uint toBlackHole;
        uint toLiquidity;
        uint toUser;
        uint rate = _calRate(tokens);
        address  blackHole = 0x0000000000000000000000000000000000000000;
        if(forceZeroStep || _inZeroWhiteList(msg.sender, to)){
            balances[msg.sender] = balances[msg.sender].sub(tokens);
            balances[to] = balances[to].add(tokens);
            emit Transfer(msg.sender, to, tokens);
            return true;
        }
        if(force1stStep || _in1stWhiteList(msg.sender, to)){
            balances[msg.sender] = balances[msg.sender].sub(tokens);
            toBlackHole = tokens.div(1000);
            balances[blackHole] = balances[blackHole].add(toBlackHole);
            balances[to] = balances[to].add(tokens.sub(toBlackHole));
            emit Transfer(msg.sender, blackHole, toBlackHole);
            emit Transfer(msg.sender, to, tokens.sub(toBlackHole));
            return true;
        }
        if(force2ndStep || _in2ndWhiteList(msg.sender, to)){
            toBlackHole = tokens.div(1000);
            toLiquidity = tokens.mul(rate).div(100);
            toUser = tokens.sub(toBlackHole).sub(toLiquidity);
            balances[msg.sender] = balances[msg.sender].sub(tokens);
            balances[devPool] = balances[devPool].add(toLiquidity);
            balances[blackHole] = balances[blackHole].add(toBlackHole);
            balances[to] = balances[to].add(toUser);
            emit Transfer(msg.sender, blackHole, toBlackHole);
            emit Transfer(msg.sender, devPool, toLiquidity);
            emit Transfer(msg.sender, to, toUser);
            return true;
        }
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        uint toBlackHole;
        uint toLiquidity;
        uint toUser;
        uint rate = _calRate(tokens);
        address  blackHole = 0x0000000000000000000000000000000000000000;
        if(forceZeroStep || _inZeroWhiteList(from, to)){
            balances[from] = balances[from].sub(tokens);
            allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
            balances[to] = balances[to].add(tokens);
            emit Transfer(from, to, tokens);
            return true;
        }
        if(force1stStep || _in1stWhiteList(from, to)){
            balances[from] = balances[from].sub(tokens);
            allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
            toBlackHole = tokens.div(1000);
            balances[blackHole] = balances[blackHole].add(toBlackHole);
            balances[to] = balances[to].add(tokens.sub(toBlackHole));
            emit Transfer(from, blackHole, toBlackHole);
            emit Transfer(from, to, tokens.sub(toBlackHole));
            return true;
        }
        if(force2ndStep || _in2ndWhiteList(from, to)){
            toBlackHole = tokens.div(1000);
            toLiquidity = tokens.mul(rate).div(100);
            toUser = tokens.sub(toBlackHole).sub(toLiquidity);
            balances[from] = balances[from].sub(tokens);
            allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
            balances[devPool] = balances[devPool].add(toLiquidity);
            balances[blackHole] = balances[blackHole].add(toBlackHole);
            balances[to] = balances[to].add(toUser);
            emit Transfer(from, blackHole, toBlackHole);
            emit Transfer(from, devPool, toLiquidity);
            emit Transfer(from, to, toUser);
            return true;
        }
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
    function _calRate(uint256 amount) internal view returns(uint256 rate){
        if(amount <= _rateK[0]/*100 * 10000 * 10**18*/){
            rate = _rateV[0]/*10*/;
        }else if(amount <= _rateK[1]/*500 * 10000 * 10**18*/){
            rate = _rateV[1]/*8*/;
        }else if(amount <= _rateK[2]/*1000* 10000 * 10**18*/){
            rate = _rateV[2]/*5*/;
        }else if(amount <= _rateK[3]/*2000* 10000 * 10**18*/){
            rate = _rateV[3]/*5*/;
        }else{
            rate = _rateV[4];
        }
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    function _safeTransferETH(address to, uint value) internal {
        (bool success) = to.call.value(value)(new bytes(0));
        require(success, 'Lion Transfer: ETH_TRANSFER_FAILED');
    }
    function addZeroWhiteList(address _minter) external onlyOwner {
        whiteListZero[_minter] = true;
    }
    function add1stWhiteList(address _minter) external onlyOwner {
        whiteList1st[_minter] = true;
    }
    function add2ndWhiteList(address _minter) external onlyOwner {
        whiteList2nd[_minter] = true;
    }
    function removeZeroWhiteList(address _minter) external onlyOwner {
        whiteListZero[_minter] = false;
    }
    function remove1stWhiteList(address _minter) external onlyOwner {
        whiteList1st[_minter] = false;
    }
    function remove2ndWhiteList(address _minter) external onlyOwner {
        whiteList2nd[_minter] = false;
    }
    function _inZeroWhiteList(address _from, address _to) internal view returns(bool){
        return whiteListZero[_from] || whiteListZero[_to];
    }
    function _in1stWhiteList(address _from, address _to) internal view returns(bool){
        return whiteList1st[_from] || whiteList1st[_to];
    }
    function _in2ndWhiteList(address _from, address _to) internal view returns(bool){
        return whiteList2nd[_from] || whiteList2nd[_to];
    }
    function setRate(uint256 i, uint256 k, uint256 v) external onlyOwner {
        if(i<=3) _rateK[i] = k;
        _rateV[i] = v;
    }
    function getRateK(uint256 i) public view returns(uint256){
        return _rateK[i];
    }
    function getRateV(uint256 i) public view returns(uint256){
        return _rateV[i];
    }

}