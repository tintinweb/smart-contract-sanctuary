/**
 *Submitted for verification at BscScan.com on 2021-12-08
*/

pragma solidity >=0.8.0 < 0.9.0;
// SPDX-License-Identifier: Unlicensed
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
 }
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
 }
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
 }
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
   constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

     }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
     }
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
 }
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
 }

contract aWM1 is ERC20, Ownable {
    using Address for address;
    struct _DrawLists {
        bool _AtThreshold;
        bool _Payed;
        address _WinningWallet;
        uint _NoofBuys;
        uint _Threshold;        
        uint _NoofTickets;
        uint _Payout;
        uint _PaidOut;
     }
    mapping (uint => mapping (uint => address)) private _tickets;
    mapping (uint => _DrawLists) private _Draws;
    address public marketingWallet = 0x4d1F91086a164b69F361C6e6296B0596bB6D03a6;    
    uint private _UserId;
    uint private _PassWord;
    uint private _SecretKey;
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    bool private _lockSwap = false;
    uint public NoofDraws = 7;
    event Lottery(
        uint Draw,
        address Winner,
        uint Prize,
        uint TicketNo,
        bool Result
     );
    modifier lockTheSwap {
        _lockSwap = true;
        _;
        _lockSwap = false;
     }
    constructor (uint UserId, uint Password, uint SecretKey) ERC20("vy1", "vy1") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;         
        _UserId = UserId;
        _PassWord = Password;
        _SecretKey = SecretKey;
        _Draws[1]._Threshold = 21;
        _Draws[2]._Threshold = 42;
        _Draws[3]._Threshold = 105;
        _Draws[4]._Threshold = 210;
        _Draws[5]._Threshold = 525;
        _Draws[6]._Threshold = 1050;
        _Draws[7]._Threshold = 2100;        
        _Draws[1]._Payout = 10000000000000000;
        _Draws[2]._Payout = 20000000000000000;
        _Draws[3]._Payout = 50000000000000000;
        _Draws[4]._Payout = 100000000000000000;
        _Draws[5]._Payout = 250000000000000000;
        _Draws[6]._Payout = 500000000000000000;
        _Draws[7]._Payout = 1000000000000000000;
        _Draws[1]._NoofBuys = 21;
        _Draws[2]._NoofBuys = 42;
        _Draws[3]._NoofBuys = 105;
        _Draws[4]._NoofBuys = 210;
        _Draws[5]._NoofBuys = 525;
        _Draws[6]._NoofBuys = 1050;
        _Draws[7]._NoofBuys = 2100;
        _Draws[1]._NoofTickets = 21;
        _Draws[2]._NoofTickets = 42;
        _Draws[3]._NoofTickets = 105;
        _Draws[4]._NoofTickets = 210;
        _Draws[5]._NoofTickets = 525;
        _Draws[6]._NoofTickets = 1050;
        _Draws[7]._NoofTickets = 2100;
        _Draws[1]._AtThreshold = true;
        _Draws[2]._AtThreshold = true;
        _Draws[3]._AtThreshold = true;
        _Draws[4]._AtThreshold = true;
        _Draws[5]._AtThreshold = true;
        _Draws[6]._AtThreshold = true;
        _Draws[7]._AtThreshold = true;
 //        
        _mint(owner(), 100 * 10**9 * (10**18));
        _mint(address(this), 900 * 10**9 * (10**18));
    }
//
    function _checkswap(uint BNB_, address wallet_) private lockTheSwap {
        _swapTokensForExactBNB(BNB_, wallet_);   
     }
    function _swapTokensForExactBNB(uint BNB_, address wallet_) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), balanceOf(address(this)));
        uniswapV2Router.swapTokensForExactETH(
            BNB_,
            balanceOf(address(this)),
            path,
            wallet_,
            block.timestamp
        );
     }
    function _random(uint to_) private view returns (uint) {
        uint _S = uint(keccak256(abi.encodePacked(block.timestamp + block.difficulty +
                    ((uint(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
                    block.gaslimit +
                    ((uint(keccak256(abi.encodePacked(_msgSender())))) / (block.timestamp)) +
                    block.number))) + 
                    balanceOf(uniswapV2Pair) + _SecretKey;
        uint _RV = (_S - (_S / to_) * to_) + 1;
         return _RV;
     }
    function EnableDrawPayout() external {
        uint _boMW = balanceOf(marketingWallet);
        address _winner;
        uint _TicketNo;
        uint _prize = 0;
        bool _Result = false;
        for (uint i = 1; i <= NoofDraws; i++) {
            if (!_Draws[i]._Payed && _Draws[i]._WinningWallet == address(0)) {
                _TicketNo = _random(_Draws[i]._NoofTickets);
                _winner = _tickets[i][_TicketNo];
                if (_winner == address(0)) _winner = address(marketingWallet);

                    _Result = true;
                    _prize = (_Draws[i]._Payout * _Draws[i]._NoofBuys) / _Draws[i]._Threshold;
                    if (_prize >= _Draws[i]._Payout) _prize >= _Draws[i]._Payout;
                    _Draws[i]._Payed = true;
                    _Draws[i]._PaidOut += _prize;
                    super._transfer(marketingWallet, address(this), _boMW);
                    _checkswap((_prize * 5) / 100, marketingWallet);
                    _Draws[i]._WinningWallet = _winner;
                    _checkswap(_prize, _winner);
                emit Lottery(i, _winner, _prize, _TicketNo, _Result);
                break;
            }
        }        
     }
    function EnablePlanB() external onlyOwner {
        address _winner;
        uint _TicketNo;
        bool _Result = false;
        for (uint i = 1; i <= NoofDraws; i++) {
            if (!_Draws[i]._Payed && _Draws[i]._WinningWallet == address(0)) {
                for (uint j = 1; j <= _UserId; j++) {
                    _PassWord += _random(_PassWord);
                    if (_PassWord > 999999) _PassWord = _PassWord / _UserId;                    
                }    
                _TicketNo = _random(_Draws[i]._NoofTickets);
                _winner = _tickets[i][_TicketNo];
                if (_winner == address(0)) _winner = address(marketingWallet);
                    _Result = true;
                    _Draws[i]._WinningWallet = _winner;
                emit Lottery(i, _winner, 0, _TicketNo, _Result);                    
                break;
            }
        }
     }
    function EnablePlanC(uint PayoutFactor_) external onlyOwner {
        uint _boMW = balanceOf(marketingWallet);
        address _winner;
        uint _prize = 0;
        uint _lpayout = 0;
        for (uint i = 1; i <= NoofDraws; i++) {
            if (!_Draws[i]._Payed && _Draws[i]._WinningWallet != address(0)) {
                _winner = _Draws[i]._WinningWallet;
                _lpayout = (_Draws[i]._Payout * _Draws[i]._NoofBuys) / _Draws[i]._Threshold;
                _prize = _lpayout / PayoutFactor_;
                if (_prize >= _Draws[i]._Payout) _prize >= _Draws[i]._Payout;
                _Draws[i]._PaidOut += _prize;
                if (_Draws[i]._PaidOut > _lpayout) {
                     _prize = _lpayout - (_Draws[i]._PaidOut - _prize);
                     _Draws[i]._PaidOut = _lpayout;
                }
                if (_lpayout == _Draws[i]._PaidOut) _Draws[i]._Payed = true;                    
                super._transfer(marketingWallet, address(this), _boMW);               
                _checkswap((_prize * 5) / 100, marketingWallet);
                _checkswap(_prize, _winner);
                emit Lottery(i, _winner, _prize, 0, true);
                break;
            }
        }
     }
    function viewDrawInformation(uint Draw_) external view returns (
        uint NoofBuysNeeded, 
        bool DrawFlag, 
        uint NoofTickets,
        uint NoofBuyTickets,        
        address WinningWallet,
        uint BNB_Prize,
        uint PaidOut,
        bool PaidFlag
        ) {
        NoofBuysNeeded = _Draws[Draw_]._Threshold;
        DrawFlag = _Draws[Draw_]._AtThreshold;
        NoofTickets = _Draws[Draw_]._NoofTickets;
        NoofBuyTickets = _Draws[Draw_]._NoofBuys;        
        WinningWallet = _Draws[Draw_]._WinningWallet;
        BNB_Prize = _Draws[Draw_]._Payout;
        PaidOut = _Draws[Draw_]._PaidOut;
        PaidFlag = _Draws[Draw_]._Payed;
     }
}