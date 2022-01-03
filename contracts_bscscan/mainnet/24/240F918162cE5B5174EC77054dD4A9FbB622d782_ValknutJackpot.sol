/**
 *Submitted for verification at BscScan.com on 2022-01-03
*/

// SPDX-License-Identifier: MIT
//
//  /$$    /$$          /$$ /$$                             /$$        /$$$$$                     /$$                             /$$    
// | $$   | $$         | $$| $$                            | $$       |__  $$                    | $$                            | $$    
// | $$   | $$ /$$$$$$ | $$| $$   /$$ /$$$$$$$  /$$   /$$ /$$$$$$        | $$  /$$$$$$   /$$$$$$$| $$   /$$  /$$$$$$   /$$$$$$  /$$$$$$  
// |  $$ / $$/|____  $$| $$| $$  /$$/| $$__  $$| $$  | $$|_  $$_/        | $$ |____  $$ /$$_____/| $$  /$$/ /$$__  $$ /$$__  $$|_  $$_/  
//  \  $$ $$/  /$$$$$$$| $$| $$$$$$/ | $$  \ $$| $$  | $$  | $$     /$$  | $$  /$$$$$$$| $$      | $$$$$$/ | $$  \ $$| $$  \ $$  | $$    
//   \  $$$/  /$$__  $$| $$| $$_  $$ | $$  | $$| $$  | $$  | $$ /$$| $$  | $$ /$$__  $$| $$      | $$_  $$ | $$  | $$| $$  | $$  | $$ /$$
//    \  $/  |  $$$$$$$| $$| $$ \  $$| $$  | $$|  $$$$$$/  |  $$$$/|  $$$$$$/|  $$$$$$$|  $$$$$$$| $$ \  $$| $$$$$$$/|  $$$$$$/  |  $$$$/
//     \_/    \_______/|__/|__/  \__/|__/  |__/ \______/    \___/   \______/  \_______/ \_______/|__/  \__/| $$____/  \______/    \___/  
//                                                                                                         | $$                          
//                                                                                                         | $$                          
//                                                                                                         |__/                          

pragma solidity >=0.7.0 <0.8.0;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256); //Renamed _ownerAddress => owner
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0)
            return 0;

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
   
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract AdminContract is Context {
    address payable internal _ownerAddress = payable(address(0));
    address payable internal _lastOwnerAddress = payable(address(0));

    address payable internal _lastDevAddress = payable(address(0));
    address payable internal _devAddress = payable(address(0));

    event OwnerAddressTransferEvent(address indexed previousOwner, address indexed newOwner);
    event DevAddressTransferEvent(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(_ownerAddress == _msgSender(), "Ownable: caller is not the _ownerAddress");
        _;
    }

    modifier onlyOwnerOrDev() {
        require(_ownerAddress == _msgSender() || _devAddress == _msgSender(), "Ownable: caller is not the _ownerAddress or _devAddress");
        _;
    }

    function transferOwnerAddress(address payable newAddress) external onlyOwner {
        require(newAddress != address(0), "Ownable: newAddress is the zero address");
        emit OwnerAddressTransferEvent(_ownerAddress, newAddress);
        _lastOwnerAddress = _ownerAddress;
        _ownerAddress = newAddress;
    }

    function recoverLastOwnerAddress() external { 
        require(_lastOwnerAddress == _msgSender(), "Sender != _lastOwnerAddress");
        emit OwnerAddressTransferEvent(_lastOwnerAddress, _ownerAddress);
        _ownerAddress = _lastOwnerAddress;
    }

    function renounceOwnerAddress() external onlyOwner { 
        _ownerAddress = address(0);
        _lastOwnerAddress = address(0);
    }

    function renounceDevAddress() external onlyOwner { 
        _devAddress = address(0);
        _lastDevAddress = address(0);
    }

    function transferDevAddress(address payable newAddress) external onlyOwnerOrDev {
        require(newAddress != address(0), "Ownable: newAddress is the zero address");
        emit DevAddressTransferEvent(_devAddress, newAddress);
        _lastDevAddress = _devAddress;
        _devAddress = newAddress;
    }

    function recoverLastDevAddress() external { 
        require(_lastDevAddress == _msgSender() || _ownerAddress == _msgSender(), "Sender != _lastDevAddress || _ownerAddress");
        emit DevAddressTransferEvent(_devAddress, _lastDevAddress);
        _devAddress = _lastDevAddress;
    }
}

contract ValknutJackpot is IBEP20, AdminContract  {
    using SafeMath for uint256;
    using Address for address;

    event BuyTicketEvent(address indexed buyer, uint256 quantityOfTickets);
    event ReceivedEvent(address, uint);
    event JackpotWinnerEvent(address indexed winner, uint amount);


    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) internal _allowances;
    uint256 private constant _totalSupply = 100000000 * (10 ** 18);
    uint8 private constant _decimals = 18;
    string private constant _symbol = "VNJP";
    string private constant _name = "Valknut Jackpot";


    uint256 public _developmentTax; // Default : 4
    uint256 public _jackpotTax; //Default : 4
    uint256 public _burnTax; //Default : 4
    address public constant _burnAddress = 0x000000000000000000000000000000000000dEaD;
    address public constant _jackpotAddress = 0x7770000000000000000000000000000000000777;


    address public constant _routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E; //MainNet
    //address private constant _routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3; //Testnet
    IUniswapV2Router02 public immutable _uniswapV2Router;
    address public immutable _uniswapV2Pair;
    bool _isSwapInProgress;


    struct jackpotWinnerStruct {
        address _address;
        uint256 _timestamp;
        uint256 _jackpotIndex;
        uint256 _jackpotAmount;
    }
    address[] private _currentJackpotTickets = new address[](0);
    mapping (uint256 => jackpotWinnerStruct) private _jackpotWinners;
    mapping (uint256 => mapping(address => uint)) private _ticketBalances;
    uint256 public _currentJackpotIndex = 0;
    uint256 public _lastJackpotTimestamp = 0;
    uint256 public _nextjackpotTimestamp = 0;
    uint256 public _jackpotInterval = 0;
    uint256 private _jackpotSalt = 0;
    uint256[25] private _recentTransactions;
    uint256[10] private _recentTicketPrices;
    uint256 private _recentTransactionsIndex = 0;
    uint256 private _recentTicketPricesIndex = 0;

    constructor (address constructorOwner) {
        address payable sender = payable(constructorOwner);

        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(_routerAddress);
        _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        _uniswapV2Router = uniswapV2Router;

        _developmentTax = 4;
        _jackpotTax = 4;
        _burnTax = 4;

        _jackpotInterval = 5 days;
        setNextJackpotTimestamp();

        _ownerAddress = sender;
        _lastOwnerAddress = sender;
        emit OwnerAddressTransferEvent(address(0), sender);

        _devAddress = sender;
        _lastDevAddress = sender;
        emit DevAddressTransferEvent(address(0), sender);

        _balances[sender] = _totalSupply;
        emit Transfer(address(0), sender, _totalSupply);
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////// StandarBEP20 ////////////////////////////////////////
    receive() external payable {
        emit ReceivedEvent(_msgSender(), msg.value);
    }

    function decimals() override external pure returns (uint8) {
        return _decimals;
    }

    function symbol() override external pure returns (string memory) {
        return _symbol;
    }

    function name() override external pure returns (string memory) {
        return _name;
    }

    function totalSupply() override external pure returns (uint256) {
        return _totalSupply;
    }

    function getCirculatingSupply() external view returns (uint256) {
        return _totalSupply.sub(_balances[_burnAddress]);
    }

    function getBurnedAmount() external view returns (uint256){
        return _balances[_burnAddress];
    }

    function balanceOf(address account) override external view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) override external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) override external returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool) {
        _approve(_msgSender(), _spender, _allowances[_msgSender()][_spender].add(_addedValue));
        return true;
    }

    function decreaseAllowance(address _spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), _spender, _allowances[_msgSender()][_spender].sub(subtractedValue));
        return true;
    }

    function _approve(address addressValue, address _spender, uint256 amount) internal {
        require(addressValue != address(0), "BEP20: approve from the zero address");
        require(_spender != address(0), "BEP20: approve to the zero address");

        _allowances[addressValue][_spender] = amount;
        emit Approval(addressValue, _spender, amount);
    }

    function getOwner() override external view returns (address) {
        return _ownerAddress;
    }

    function getDev() external view returns (address) {
        return _devAddress;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        _balances[sender] = _balances[sender].sub(amount);
        if(sender == _uniswapV2Pair) { 
            _recentTransactions[_recentTransactionsIndex] = amount;
            nextIterationRecentTransactionsIndex();
        }

        if(sender != _ownerAddress && recipient != _ownerAddress && sender != _devAddress && recipient != _devAddress && sender != address(this) && recipient != address(this)) {
            uint256 initialAmount = amount;

            // JACKPOT_TAX
            if(_jackpotTax > 0) {
                uint256 prizeTaxAmount = initialAmount.mul(_jackpotTax).div(uint(100));
                _balances[_jackpotAddress] = _balances[_jackpotAddress].add(prizeTaxAmount);
                amount = amount.sub(prizeTaxAmount);
                emit Transfer(sender, _jackpotAddress, prizeTaxAmount);

                // BUY_TICKET
                if(sender == _uniswapV2Pair) {
                    uint256 ticketPrice = getTicketPrice();
                    if(prizeTaxAmount >= ticketPrice) { 
                        uint256 ticketsQuantity = prizeTaxAmount.div(ticketPrice);
                        ticketsQuantity = ticketsQuantity >= uint256(5) ? uint256(5) : ticketsQuantity;
                        if(ticketsQuantity > 0) {
                            _recentTicketPrices[_recentTicketPricesIndex] = ticketPrice;
                            nextIterationRecentTicketPricesIndex();

                            for(uint256 i = 0; i < ticketsQuantity; i++) 
                                _currentJackpotTickets.push(recipient);

                            _ticketBalances[_currentJackpotIndex][recipient] = _ticketBalances[_currentJackpotIndex][recipient].add(ticketsQuantity);
                            emit BuyTicketEvent(recipient, ticketsQuantity);
                        }
                    }
                }
            }

            // BURN_TAX
            if(_burnTax > 0) {
                uint256 burnTaxAmount = initialAmount.mul(_burnTax).div(uint(100));
                _balances[_burnAddress] = _balances[_burnAddress].add(burnTaxAmount);
                amount = amount.sub(burnTaxAmount);
                emit Transfer(sender, _burnAddress, burnTaxAmount);
            }

            // DEV_TAX
            if(_developmentTax > 0) {
                uint256 developmentTaxAmount = initialAmount.mul(_developmentTax).div(uint(100));
                _balances[address(this)] = _balances[address(this)].add(developmentTaxAmount);
                amount = amount.sub(developmentTaxAmount);
                emit Transfer(sender, address(this), developmentTaxAmount);
            }
        }

        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);

        if(isJackpotAvailable() == true)
            claimJackpot();
    }
    //////////////////////////////////////// StandarBEP20 ////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////// Owner/Dev Functions /////////////////////////////////////
    function setDevelopmentTax(uint256 value) external onlyOwner {
        require(value.add(_burnTax).add(_jackpotTax) <= 12, "Taxes must be less than 12%.");
        _developmentTax = value;
    }

    function setBurnTax(uint256 value) external onlyOwner {
        require(value.add(_developmentTax).add(_jackpotTax) <= 12, "Taxes must be less than 12%.");
        _burnTax = value;
    }

    function setJackpotTax(uint256 value) external onlyOwner {
        require(value.add(_burnTax).add(_developmentTax) <= 12, "Taxes must be less than 12%.");
        _jackpotTax = value;
    }
    
    function sendBNBToDeveloper() external onlyOwnerOrDev {
        require(_isSwapInProgress == false, "Swap in progress");
        
        _isSwapInProgress = true;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        uint256 tokenAmount = _balances[address(this)];
        _approve(address(this), address(_uniswapV2Router), tokenAmount);
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            payable(address(this)),
            block.timestamp.add(300)
        );

        (bool sent, ) = _devAddress.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");

        _isSwapInProgress = false;
    }

    function sendBNBToDeveloperPorcentage(uint256 porcentage) external onlyOwnerOrDev {
        require(_isSwapInProgress == false, "Swap in progress");
        require(porcentage > 0 && porcentage <= uint(100), "No valid porcentage");
        
        _isSwapInProgress = true;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        uint256 tokenAmount = _balances[address(this)].mul(porcentage).div(uint(100));
        _approve(address(this), address(_uniswapV2Router), tokenAmount);
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            payable(address(this)),
            block.timestamp.add(300)
        );

        (bool sent, ) = _devAddress.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");

        _isSwapInProgress = false;
    }

    function sendTokensToDeveloper() external onlyOwnerOrDev {
        require(_balances[address(this)] > 0, "the contract balance must be greater than 0");

        uint256 contractBalance = _balances[address(this)];
        _balances[address(this)] = 0;
        _balances[_devAddress] = _balances[_devAddress].add(contractBalance);

        emit Transfer(address(this), _devAddress, contractBalance);
    }


    function setJackpotInterval(uint cooldown) external onlyOwner {
        require(cooldown >= 1 days, "Intervals must be greater than 24 hours");
        require(cooldown <= 7 days, "Intervals must be less than 7 days");
        _jackpotInterval = cooldown;
    }
    //////////////////////////////////// Owner/Dev Functions /////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////

    // Internal/private Jackpot
    function getRandomTicketIndex() private returns (uint256 ticketIndex) {
        require(_currentJackpotTickets.length > 0, "Tickets length == 0");

        _jackpotSalt = _jackpotSalt.add(1);
        return uint256(keccak256(abi.encodePacked(
            block.difficulty, 
            block.number, 
            block.coinbase, 
            block.timestamp, 
            _msgSender(), 
            uint256(_currentJackpotTickets.length), 
            _jackpotSalt))
        ) % _currentJackpotTickets.length;
    }

    function setNextJackpotTimestamp() private {
        _lastJackpotTimestamp = block.timestamp;
        _nextjackpotTimestamp = block.timestamp + _jackpotInterval;
    }

    function nextIterationRecentTicketPricesIndex() private { 
        _recentTicketPricesIndex = _recentTicketPricesIndex + 1 >= _recentTicketPrices.length ? 0 : _recentTicketPricesIndex + 1;
    }

    function nextIterationRecentTransactionsIndex() private { 
        _recentTransactionsIndex = _recentTransactionsIndex + 1 >= _recentTransactions.length ? 0 : _recentTransactionsIndex + 1;
    }

    function isJackpotAvailable() private view returns(bool) {
        return !(getRemainingTimestampToNextJackpot() > 0);
    }

    function getAverageLast25TransactionsAmount() private view returns (uint256 averageTransactionAmount){ 
        uint256 amount = 0;
        uint256 validTransactions = 0;

        for(uint256 i = 0; i < _recentTransactions.length; i++) { 
            if(_recentTransactions[i] > 0) {
                amount = amount.add(_recentTransactions[i]);
                validTransactions++;
            }
        }

        return (validTransactions == 0 || amount == 0) ? uint256(10000 * (10 ** 18)) : amount.div(validTransactions);
    }

    function getAverageLast10TicketPrice() private view returns (uint256 averageTicketPrice){ 
        uint256 amount = 0;
        uint256 validTickets = 0;
        for(uint256 i = 0; i < _recentTicketPrices.length; i++) { 
            if(_recentTicketPrices[i] > 0) {
                amount = amount.add(_recentTicketPrices[i]);
                validTickets++;
            }
        }

        return (validTickets == 0 || amount == 0) ? uint256(10000 * (10 ** 18)) : amount.div(validTickets);
    }


    function claimJackpot() private { 
        require(isJackpotAvailable() == true, "Remaining Time to Next jackpot > 0");
        if(_currentJackpotTickets.length == 0) { 
            setNextJackpotTimestamp();
            return;
        }

        address winnerAddress = _currentJackpotTickets[getRandomTicketIndex()];
        uint256 jackpotAmount = _balances[_jackpotAddress];

        _balances[_jackpotAddress] = 0;
        _balances[winnerAddress] = _balances[winnerAddress].add(jackpotAmount);

        _jackpotWinners[_currentJackpotIndex] = jackpotWinnerStruct(winnerAddress, block.timestamp, _currentJackpotIndex, jackpotAmount);
        _currentJackpotIndex = _currentJackpotIndex.add(1);

        _currentJackpotTickets = new address[](0);
        _recentTicketPrices = [getAverageLast25TransactionsAmount().div(uint(50)), 0, 0, 0, 0, 0, 0 ,0 , 0, 0];
        _recentTicketPricesIndex = 1;
        setNextJackpotTimestamp();

        emit Transfer(_jackpotAddress, winnerAddress, jackpotAmount);
        emit JackpotWinnerEvent(winnerAddress, jackpotAmount);
    }

    function buyTicket(uint ticketsQuantity) external { 
        require(ticketsQuantity > 0, "Tickets Quantity Must be > 0");
        require(ticketsQuantity <= 30, "You can't purchase more than 30 Tickets in the same transaction");

        address sender = _msgSender();
        uint256 ticketPrice = getTicketPrice();
        uint256 totalAmount = ticketPrice.mul(ticketsQuantity);
        
        require(_balances[sender] >= totalAmount, "Balance < TicketsPriceAmount");

        _recentTicketPrices[_recentTicketPricesIndex] = ticketPrice;
        nextIterationRecentTicketPricesIndex();

        uint256 burnAmount = totalAmount.div(uint256(10));
        uint256 jackpotAmount = totalAmount.mul(uint256(9)).div(uint256(10));

        _balances[sender] = _balances[sender].sub(totalAmount);
        _balances[_burnAddress] = _balances[_burnAddress].add(burnAmount);
        _balances[_jackpotAddress] = _balances[_jackpotAddress].add(jackpotAmount);

        for(uint i = 0; i < ticketsQuantity; i++)
            _currentJackpotTickets.push(sender);

        _ticketBalances[_currentJackpotIndex][sender] = _ticketBalances[_currentJackpotIndex][sender].add(ticketsQuantity);

        if(isJackpotAvailable() == true)
            claimJackpot();

        emit Transfer(sender, _burnAddress, burnAmount);
        emit Transfer(sender, _jackpotAddress, jackpotAmount);
        emit BuyTicketEvent(sender, ticketsQuantity);
    }

    function getTicketPrice() public view returns (uint256 ticketPrice) { 
        uint256 averageTransactionAmount = getAverageLast25TransactionsAmount().div(uint256(50));
        uint256 averageTicketPrice = getAverageLast10TicketPrice();
        uint256 CeilPrice = averageTicketPrice.mul(uint256(11)).div(uint256(10));

        if(averageTransactionAmount >= CeilPrice) { 
            return CeilPrice;
        }

        if(averageTransactionAmount <= averageTicketPrice) {
            return averageTicketPrice; 
        }

        return averageTransactionAmount;
    }

    function getRemainingTimestampToNextJackpot() public view returns (uint256 remainingTimeToNextJackpot) {
        uint256 blockTimestamp = block.timestamp;
        uint256 nextJackpotTitemsap = _nextjackpotTimestamp;
        return (blockTimestamp <= nextJackpotTitemsap) ? nextJackpotTitemsap.sub(blockTimestamp) : 0;
    }

    function getJackpotAmount() external view returns (uint256){
        return _balances[_jackpotAddress];
    }

    function getCurrentJackpotTickets() external view returns (uint256)  { 
        return _currentJackpotTickets.length;
    }

    function getLastJackpotWinner() external view returns(address winnerAddress, uint256 timestamp, uint256 jackpotIndex, uint256 jackpotAmount) { 
        jackpotWinnerStruct memory localJackpotWinnerStruct = _jackpotWinners[_currentJackpotIndex > 0 ? _currentJackpotIndex.sub(1) : 0];
        return (localJackpotWinnerStruct._address, localJackpotWinnerStruct._timestamp, localJackpotWinnerStruct._jackpotIndex, localJackpotWinnerStruct._jackpotAmount);
    }

    function getTicketBalance() external view returns(uint256 ticketBalance) {
        return _ticketBalances[_currentJackpotIndex][_msgSender()];
    }

    function getTicketBalance(address _address) external view returns (uint256 ticketBalance) {
        return _ticketBalances[_currentJackpotIndex][_address];
    }

    function getTicketBalance(uint256 jackpotIndex, address addressOwner) external view returns (uint256 ticketBalance) {
        return _ticketBalances[jackpotIndex][addressOwner];
    }
}