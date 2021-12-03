pragma solidity ^ 0.8.4;
// SPDX-License-Identifier: Unlicensed
                                                                              
//                                                   %(                           
//                        ..                           %%%%%                      
//                     .                 #%%%%%          %%%%%#                   
//                  ..               %%%*      /%%%.       %%%%%%.                
//                ..               .%%            %%%       %%%%%% .              
//              ..                 %%     %%%%%%   %%#       %%%%%%  .            
//            ...                  %%    %%  %%%   %%%       %%%%%%   .           
//           /..                   %%(   %%       %%%       *%%%%%%    .          
//          %..                    ,%%%   %%%%%%%%%         %%%%%%%     .         
//         #...          .%%%%%      %%%#                 %%%%%%%#      .*        
//        .%...          .%%%%%       #%%%%%           %%%%%%%%%        ...       
//       .%/..%%%%%%%                    %%%%%%%%%%%%%%%%%%%#           ..%.      
//       .%,..%%%%%%%                         *%%%%%%%#                 ..%.      
//       #%#...*%%%#                 %%%%                               ..%.      
//      .%%%....                    %%%%%%                             ...%,.     
//      .*%%,....                    #%%*       (%%%%%                ...%%..     
//      ..%%%.....                               %%%%.               ...,%%..     
//      ..(%%%.....                                                 ....%%..      
//       ..%%%%,.....      /%%%%%#                                ....%%%,..      
//        ..(%%%%......   %%%%%%%%%                            ......%%%...       
//        ....%%%%%.......%%%%%%%%%             %%%%%#      .......%%%%...        
//         .....%%%%%.......,%%%,              %%%%%%%% ........*%%%%....         
//           .....%%%%%%..............          %%%%%%.......*%%%%%.....          
//            ......,%%%%%%%.............................*%%%%%%......            
//              ........%%%%%%%%%%/................#%%%%%%%%#........             
//                 ..........%%%%%%%%%%%%%%%%%%%%%%%%%%(..........                
//                   ..................,/(#(/,.................                   
//                       ...................................                      
//                            ........................                            
                                                                             
																			  
interface IBEP20 {
    function totalSupply() external view returns(uint256);

    function decimals() external view returns(uint8);

    function symbol() external view returns(string memory);

    function name() external view returns(string memory);

    function getOwner() external view returns(address);

    function balanceOf(address account) external view returns(uint256);

    function transfer(address recipient, uint256 amount) external returns(bool);

    function allowance(address _owner, address spender) external view returns(uint256);

    function approve(address spender, uint256 amount) external returns(bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns(address);

    function feeToSetter() external view returns(address);

    function getPair(address tokenA, address tokenB) external view returns(address pair);

    function allPairs(uint) external view returns(address pair);

    function allPairsLength() external view returns(uint);

    function createPair(address tokenA, address tokenB) external returns(address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns(string memory);

    function symbol() external pure returns(string memory);

    function decimals() external pure returns(uint8);

    function totalSupply() external view returns(uint);

    function balanceOf(address owner) external view returns(uint);

    function allowance(address owner, address spender) external view returns(uint);

    function approve(address spender, uint value) external returns(bool);

    function transfer(address to, uint value) external returns(bool);

    function transferFrom(address from, address to, uint value) external returns(bool);

    function DOMAIN_SEPARATOR() external view returns(bytes32);

    function PERMIT_TYPEHASH() external pure returns(bytes32);

    function nonces(address owner) external view returns(uint);

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

    function MINIMUM_LIQUIDITY() external pure returns(uint);

    function factory() external view returns(address);

    function token0() external view returns(address);

    function token1() external view returns(address);

    function getReserves() external view returns(uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns(uint);

    function price1CumulativeLast() external view returns(uint);

    function kLast() external view returns(uint);

    function mint(address to) external returns(uint liquidity);

    function burn(address to) external returns(uint amount0, uint amount1);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns(address);

    function WETH() external pure returns(address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns(uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns(uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns(uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns(uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns(uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns(uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns(uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns(uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns(uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns(uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns(uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns(uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns(uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns(uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns(uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns(uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns(uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns(uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns(uint amountETH);

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

contract Context {
    constructor() {}

    function _msgSender() internal view returns(address) {
        return msg.sender;
    }

    function _msgData() internal view returns(bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns(address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Manageable is Ownable {
    address private _manager;

    event ManagmentTransferred(address indexed previousManager, address indexed newManager);

    constructor() {
        address msgSender = _msgSender();
        _manager = msgSender;
        emit ManagmentTransferred(address(0), msgSender);
    }

    function manager() public view returns(address) {
        return _manager;
    }

    modifier onlyManager() {
        require(_manager == _msgSender(), "caller is not the manager");
        _;
    }

    function transferManagment(address newManager) public onlyManager {
        emit ManagmentTransferred(_manager, newManager);
        _manager = newManager;
    }
}

contract BEP20Token is IBEP20, Manageable {
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensIntoLiqudity);

    mapping(address => uint256) private _bep20Balances;
    mapping(address => mapping(address => uint256)) private _bep20Allowances;
	
	struct PrepareTransfer {
		uint256 amount;
		string transferData;
	}
	
	struct TrackedTransfer {
		uint256 time;
		uint256 amount;
		string transferData;
	}

	address[] private _trackedAddresses;
	mapping (address => bool) private _trackedAddressesExists;
	
	mapping (address => address[]) private _trackedAddressesSenders;
	mapping (address => mapping (address => bool)) private _trackedAddressesSendersExists;	
	
	mapping (address => mapping (address => PrepareTransfer)) private  _trackedAddressesPrepareTransfers;	
	mapping (address => mapping (address => TrackedTransfer[])) private  _trackedAddressesTransfers;
	
    uint8 private constant _decimals = 12;
    string private _symbol = "SconeCoin";
    string private _name = "SconeCoin.com";
    uint256 private constant _targetSupply = 1024 * 1024 * 1024 * 32 * (10 ** uint256(_decimals));
    uint256 private constant _initialSupply = _targetSupply * 32;
    uint256 private _totalSupply;
	
	uint256 private _maxWalletTotalSupplyRatio = 0; /* 150 = 1.5%, 0 = No Limitation */
	
    uint256 private constant _burnRateLimit = 650; /* 650 = 6.5% */
    uint256 private _burnRate = 125; /* 550 = 5.5% */

    uint256 private constant _devRateLimit = 350; /* 350 = 3.5% */
    uint256 private _devRate = 275; /* 250 = 2.5% */

    uint256 private constant _managerWalletRateLimit = 495; /* 495 = 4.95% */

    IUniswapV2Router02 private _uniswapV2Router;
    IUniswapV2Pair public _uniswapV2Pair;
	
	/*"This contract is managed by the development team. The burn rate, the max wallet ratio and the communication and development fee rate may change during the life of the contract to adapt to present conditions. The management of the contract is different from the ownership of the contract. Under no circumstances can the manager manipulate transfers or the number of units outstanding. This can be verified by examining the contract code." */

    constructor() {
        _totalSupply = _initialSupply;
        _bep20Balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
	
    function getOwner() external view returns(address) {
        return owner();
    }

    function decimals() external pure returns(uint8) {
        return _decimals;
    }

    function symbol() external view returns(string memory) {
        return _symbol;
    }

	event SymbolUpdated(string previousValue, string newValue);
    function setSymbol(string memory newSymbol) public onlyManager() {
		emit SymbolUpdated(_symbol, newSymbol) ;
        _symbol = newSymbol;
    }
	
    function name() external view returns(string memory) {
        return _name;
    }

	event NameUpdated(string previousValue, string newValue);
    function setName(string memory newName) public onlyManager() {
		emit NameUpdated(_name, newName) ;
        _name = newName;
    }
	
    function totalSupply() external view returns(uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns(uint256) {
        return _bep20Balances[account];
    }

	// _burnRate
	
    function burnRate() external view returns(uint256) {
        return _burnRate;
    }

    event BurnRateUpdated(uint256 previousValue, uint256 newValue);
    function setBurnRate(uint256 newRate) public onlyManager() {
        require(newRate <= _burnRateLimit, "burn rate > limit");
        emit BurnRateUpdated(_burnRate, newRate);
        _burnRate = newRate;
    }
	
	// _maxWalletTotalSupplyRatio
		
    function maxWalletTotalSupplyRatio() external view returns(uint256) {
        return _maxWalletTotalSupplyRatio;
    }
	
    event MaxWalletTotalSupplyRatioUpdated(uint256 previousValue, uint256 newValue);	
    function setMaxWalletTotalSupplyRatio(uint256 newRate) public onlyManager() {
		require(newRate <= 1000, "newRate > 10%");
		 emit MaxWalletTotalSupplyRatioUpdated(_devRate, newRate);
        _maxWalletTotalSupplyRatio = newRate;
    }
	
	// _devRate
	
    function devRate() external view returns(uint256) {
        return _devRate;
    }

    event DevRateUpdated(uint256 previousValue, uint256 newValue);
    function setDevRate(uint256 newRate) public onlyManager() {
        require(newRate <= _devRateLimit, "dev rate > limit");
        emit DevRateUpdated(_devRate, newRate);
        _devRate = newRate;
    }

    function prepareTransferData(address expectedTransferSender, uint256 amount, string memory transferData) external returns(bool) {
		require(amount > 0, "amount must be > 0");
		require(_msgSender() != address(0), "prepare the 0x0");	
		require(expectedTransferSender != address(0), "prepare the 0x0");	
		PrepareTransfer storage prepareTransfer =  _trackedAddressesPrepareTransfers[_msgSender()][expectedTransferSender];
		prepareTransfer.amount = amount;
		prepareTransfer.transferData = transferData;
		_trackedAddressesPrepareTransfers[_msgSender()][expectedTransferSender] = prepareTransfer;
        return true;
    }
	
    function transfer(address recipient, uint256 amount) external returns(bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
	
    function allowance(address owner, address spender) external view returns(uint256) {
        return _bep20Allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns(bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _bep20Allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
	
        return true;
    }
	
	function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
		_approve(_msgSender(), spender, _bep20Allowances[_msgSender()][spender] + addedValue);
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {	
        uint256 currentAllowance = _bep20Allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);	
		return true;
	}

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(amount > 0, "amount must be > 0");
        require(amount <= _totalSupply, "amount must be < total supply");
        require(sender != address(0), "transfer from the 0x0");
        require(recipient != address(0), "transfer to the 0x0");		
		require(sender != recipient, "loop transfer");
		uint256 senderBalance = _bep20Balances[sender];
		require(senderBalance >= amount, "amount exceeds balance");
		
        uint256 transferAmount = amount;

		if ((sender != address(this)) && (recipient != address(this))) {
			address manager = manager();	
			
			if ((manager != sender) && (manager != recipient) || (manager == address(0))) {
				if ((_burnRate > 0) && (_totalSupply > _targetSupply)) {		
					uint256 burnedAmount = amount * _burnRate / 10000;
					if ( (burnedAmount > 0) && (burnedAmount <= transferAmount) ) {
						if (_totalSupply - burnedAmount < _targetSupply) {
							burnedAmount = _totalSupply - _targetSupply;
						}
						transferAmount = transferAmount - burnedAmount;
						_totalSupply = _totalSupply - burnedAmount;
					}
				}
			}

			if ((_devRate > 0) && (manager != address(0)) && (manager != sender) && (manager != recipient)) {
				uint256 managerWalletAmount = _bep20Balances[manager];
				uint256 managerWalletAmountLimit = _totalSupply * _managerWalletRateLimit / 10000;
				if (managerWalletAmount < managerWalletAmountLimit) {
					uint256 devAmount = amount * _devRate / 10000;
					if ( (devAmount > 0) && (devAmount <= transferAmount) ) {
						transferAmount = transferAmount - devAmount;
						_bep20Balances[manager] = _bep20Balances[manager] + devAmount;
						emit Transfer(sender, manager, devAmount);
					}
				}
			}

			if (_maxWalletTotalSupplyRatio > 0) {
				if ((recipient != address(this)) && (recipient != address(_uniswapV2Pair)) && (recipient != manager) && (recipient != owner())) {
					uint256 newRecipientWalletRatio = 10000 * (_bep20Balances[recipient] + transferAmount) / _totalSupply ;
					require(newRecipientWalletRatio <= _maxWalletTotalSupplyRatio, "max wallet size exceeded");
				}
			}
		}
		
        _bep20Balances[sender] = _bep20Balances[sender] - amount;
        _bep20Balances[recipient] = _bep20Balances[recipient] + transferAmount;

        emit Transfer(sender, recipient, transferAmount);
		
		if(_trackedAddressesExists[recipient]) {
			if (!_trackedAddressesSendersExists[recipient][sender]) {
				_trackedAddressesSenders[recipient].push(sender) ;
				_trackedAddressesSendersExists[recipient][sender] = true;
			}
		 		
			TrackedTransfer[] storage trackedTransfers =  _trackedAddressesTransfers[recipient][sender];
			trackedTransfers.push();
			uint id = trackedTransfers.length - 1;
			trackedTransfers[id].time = block.timestamp;
			trackedTransfers[id].amount = transferAmount;
			
		 	PrepareTransfer storage prepareTransfer =  _trackedAddressesPrepareTransfers[recipient][sender];
			
			if (prepareTransfer.amount == amount) {				
				trackedTransfers[id].transferData = prepareTransfer.transferData;				
				prepareTransfer.amount = 0;
				prepareTransfer.transferData = "";
				_trackedAddressesPrepareTransfers[recipient][sender] = prepareTransfer;	
			}

			_trackedAddressesTransfers[recipient][sender] = trackedTransfers;
		}
    }

	event Burned(uint256 amount);
    function burn(uint256 burnedAmount) public onlyManager() {
		require(_totalSupply - burnedAmount >= _targetSupply, "Total supply cant'be < Target supply");
		address manager = manager();	
		uint256 managerBalance = _bep20Balances[manager];
		require(managerBalance >= burnedAmount, "amount exceeds balance");		
		emit Burned(burnedAmount) ;
		_bep20Balances[manager] = _bep20Balances[manager] - burnedAmount;
        _totalSupply = _totalSupply - burnedAmount;
    }
	
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "approve from the 0x0");
        require(spender != address(0), "approve to the 0x0");
		require(amount <= _totalSupply, "amount must be < total supply");

        _bep20Allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function initUniswapV2(address uniswapV2Router) public onlyOwner {
        require(uniswapV2Router != address(0), "init from the 0x0");	
        if (address(_uniswapV2Pair) == address(0)) {
			// Uniswap V2 router
			_uniswapV2Router = IUniswapV2Router02(uniswapV2Router);
			// Create a uniswap pair for this new token
			_uniswapV2Pair = IUniswapV2Pair(IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH()));
		}
    }

	function trackMe() public {
		address sender = _msgSender();
		require(_bep20Balances[sender] > 0, "your balance is 0");
        if(_trackedAddressesExists[sender])
            return;
        _trackedAddressesExists[sender] = true;
        _trackedAddresses.push(sender);
    }

	function getSenders() external view returns (address[] memory) {
		address sender = _msgSender();	
		require(sender != address(0), "0x0 is not tracked");
		require(_trackedAddressesExists[sender], "this address is not tracked");
		require(_bep20Balances[sender] > 0, "your balance is 0");		
        return  _trackedAddressesSenders[sender] ;
    }
	
	function getTransfersSentToMe(address transferSender) external view returns (TrackedTransfer[] memory) {
		require(transferSender != address(0), "transferSender is 0x0");
		address sender = _msgSender();	
		require(sender != address(0), "0x0 is not tracked");
		require(_trackedAddressesExists[sender], "this address is not tracked");
		require(_bep20Balances[sender] > 0, "your balance is 0");
        return  _trackedAddressesTransfers[sender][transferSender] ;
    }
}