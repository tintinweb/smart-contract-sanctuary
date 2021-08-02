/**
 *Submitted for verification at BscScan.com on 2021-08-02
*/

// SPDX-License-Identifier: MIT

/**
https://t.me/easyflytoken

13.08.2021

- >> Stake para Holders 
    << - 4% de todas as transações são redistribuídas para todos os holdes EasyFly Isso significa que 
        você pode ganhar uma renda passiva simplesmente segurando EasyFly em sua carteira:
        Taxa de 4% de cada transação distribuída automaticamente a todos os hodlers existentes
- >> LP 
    << - 7% de cada negociação contribui para a geração automática de mais liquidez para a comunidade EasyFly:
        Taxa de 7% de cada transação adicionada automaticamente ao LP (Liquidity Pool)
- >> AntiBot - Compra e venda rápida do AntiBot 
    << - O valor máximo de qualquer transação (Compra, Venda e Transferencia) é 0,3% (3.000.000) do fornecimento total,
        atraso de 60 segundos entre as transações (com AllowList e BlockList)
- >> AntiWhale 
    << - A quantidade máxima de tokens em qualquer carteira (endereço) é 0,7% (7.000.000 ) do 
        fornecimento total (com AllowList e BlockList)
*/

pragma solidity ^0.8.0;

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

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
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

library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: saldo insuficiente");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: incapaz de enviar valor, o destinatario pode ter revertido");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: falha na chamada de baixo nivel");
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
        return functionCallWithValue(target, data, value, "Address: falha na chamada de baixo nivel com valor");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: saldo insuficiente para chamada");
        require(isContract(target), "Address: chamada para nao-contrato");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: falha na chamada estatica de baixo nivel");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: chamada estatica para nao-contrato");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: falha na chamada de delegado de baixo nivel");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegar chamada para nao-contrato");

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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: o endereco nao e o dono");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: novo dono e o endereco zero");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

contract CabareDOGE is Context, IERC20, Ownable {

	using SafeMath for uint256;
	using Address for address;

	mapping (address => uint256) private _rOwned;
	mapping (address => uint256) private _tOwned;
	mapping (address => mapping (address => uint256)) private _allowances;

	mapping (address => bool) private _isExcludedFromFee;

	mapping (address => bool) private _isExcludedFromReward;
	address[] private _excludedFromReward;

	mapping (address => bool) private _isExcludedFromTransactionLock;

	mapping (address => bool) private _isAllowList;
	address[] private _allowList;

	mapping (address => bool) private _isBlockList;
	address[] private _blockList;

	mapping (address => uint256) private _transactionLockTimestamp;

	uint256 private constant MAX = ~uint256(0);
	uint256 private _tTotal = 51000000 * 10**9;
	uint256 private _rTotal = (MAX - (MAX % _tTotal));
	uint256 private _tFeeTotal;

	string private _name = "CabareDOGE";
	string private _symbol = "CU";

// >> Símbolos após o ponto (.) No token:
	uint8 private _decimals = 9;

// >> Taxa de holders de qualquer transação: 2%
	uint256 public _taxFee = 4;
	uint256 private _previousTaxFee = _taxFee;

// >> Taxa de liquidez de qualquer transação: 7%
	uint256 public _liquidityFee = 7;
	uint256 private _previousLiquidityFee = _liquidityFee;

// >> Taxa de Markenting de qualquer transação: 4%
	uint256 public _burnFee = 4;
	uint256 private _previousBurnFee = _burnFee;
	address public constant _burnAddress = 0xc866b7CcfFB5388AC9e7fD480B285a0CA6FD5871;

// >>Quantidade máxima de qualquer carteira / endereço (do estoque total): 0,5%
	uint256 public _maxWalletAmount = 255000 * 10**9;

// >> Montante máximo de qualquer transação (do fornecimento total): 0.25%
	uint256 public _maxTxAmount = 127500 * 10**9;

// >> Quantidade mínima de tokens em saldo a partir da qual a taxa de liquidez calculada: 0.05%
	uint256 private _numTokensSellToAddToLiquidity = 25500 * 10**9;

// >> Bloquear a última transação por algum tempo: 60 seconds
	uint256 public _transactionLockTime = 60;

// >> Uniswap router address (Pancake v2):
// >> Fix for Pancake v2 (changed router address): https://forum.openzeppelin.com/t/how-to-fix-pancakeswaps-router-address-in-safemoon/8113/20 <<
	// MINET
//	address public constant _swapRouterAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;  
	
	// TESTNET
	address public constant _swapRouterAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;

	bool public _swapAndLiquifyEnabled = true;
	bool private _inSwapAndLiquify;
	IUniswapV2Router02 public _uniswapV2Router;
	address public _uniswapV2Pair;
	event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
	event SwapAndLiquifyEnabledUpdated(bool enabled);
	event SwapAndLiquify(
		uint256 tokensSwapped,
		uint256 bnbReceived,
		uint256 tokensIntoLiqudity
	);

	modifier transactionLock(){
		require(block.timestamp - _transactionLockTimestamp[_msgSender()] >= _transactionLockTime || _isExcludedFromTransactionLock[_msgSender()] || _isAllowList[_msgSender()], "ERROR: Sender address is not allowed to make transaction at this time. Plaese wait some time before make another transaction.");
		_;
	}

	modifier lockTheSwap {
		_inSwapAndLiquify = true;
		_;
		_inSwapAndLiquify = false;
	}

	constructor () {
		_rOwned[_msgSender()] = _rTotal;
		IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(_swapRouterAddress);
		_uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
		_uniswapV2Router = uniswapV2Router;

// Exclua o proprietário, este contrato da taxa:
		_isExcludedFromFee[owner()] = true;
		_isExcludedFromFee[address(this)] = true;
		_isExcludedFromFee[_burnAddress] = true;

// Excluir endereço do tempo de bloqueio da transação:
		_isExcludedFromTransactionLock[owner()] = true;
		_isExcludedFromTransactionLock[address(this)] = true;
		_isExcludedFromTransactionLock[_burnAddress] = true;
		_isExcludedFromTransactionLock[_uniswapV2Pair] = true;
		_isExcludedFromTransactionLock[address(_uniswapV2Router)] = true;
		emit Transfer(address(0), _msgSender(), _tTotal);
	}

	function name() public view returns (string memory) {
		return _name;
	}

	function symbol() public view returns (string memory) {
		return _symbol;
	}

	function decimals() public view returns (uint8) {
		return _decimals;
	}

	function totalSupply() public view override returns (uint256) {
		return _tTotal;
	}

	function balanceOf(address account) public view override returns (uint256) {
		if (_isExcludedFromReward[account]) return _tOwned[account];
		return tokenFromReflection(_rOwned[account]);
	}

	function transfer(address recipient, uint256 amount) public override returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	function allowance(address owner, address spender) public view override returns (uint256) {
		return _allowances[owner][spender];
	}

	function approve(address spender, uint256 amount) public override returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}

	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
		_transfer(sender, recipient, amount);
		_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: o valor da transferencia excede a permissao."));
		return true;
	}

	function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: reducao da provisao abaixo de zero."));
		return true;
	}

	function isExcludedFromFee(address account) public view returns(bool) {
		return _isExcludedFromFee[account];
	}

	function isExcludedFromReward(address account) public view returns (bool) {
		return _isExcludedFromReward[account];
	}

	function isAllowList(address account) public view returns (bool) {
		return _isAllowList[account];
	}

	function isBlockList(address account) public view returns (bool) {
		return _isBlockList[account];
	}

	function totalFees() public view returns (uint256) {
		return _tFeeTotal;
	}

	function deliver(uint256 tAmount) public {
		address sender = _msgSender();
		require(!_isExcludedFromReward[sender], "ERRO: Os enderecos excluidos nao podem chamar esta funcao.");
		(uint256 rAmount,,,,,) = _getValues(tAmount);
		_rOwned[sender] = _rOwned[sender].sub(rAmount);
		_rTotal = _rTotal.sub(rAmount);
		_tFeeTotal = _tFeeTotal.add(tAmount);
	}

	function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
		require(tAmount <= _tTotal, "ERRO: A quantidade deve ser menor que a oferta.");
		if (!deductTransferFee) {
			(uint256 rAmount,,,,,) = _getValues(tAmount);
			return rAmount;
		} else {
			(,uint256 rTransferAmount,,,,) = _getValues(tAmount);
			return rTransferAmount;
		}
	}

	function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
		require(rAmount <= _rTotal, "ERRO: A quantidade deve ser menor que as reflexoes totais.");
		uint256 currentRate = _getRate();
		return rAmount.div(currentRate);
	}

	function includeInFee(address account) public onlyOwner {
		_isExcludedFromFee[account] = false;
	}

	function excludeFromFee(address account) public onlyOwner {
		_isExcludedFromFee[account] = true;
	}

	function includeInReward(address account) public onlyOwner() {
		require(_isExcludedFromReward[account], "ERRO: A conta nao e excluida das recompensas.");
		for (uint256 i = 0; i < _excludedFromReward.length; i++) {
			if (_excludedFromReward[i] == account) {
				_excludedFromReward[i] = _excludedFromReward[_excludedFromReward.length - 1];
				_tOwned[account] = 0;
				_isExcludedFromReward[account] = false;
				_excludedFromReward.pop();
				break;
			}
		}
	}

	function excludeFromReward(address account) public onlyOwner() {
		require(account != _swapRouterAddress, "ERRO: Nao podemos excluir do endereco de recompensas do roteador de troca.");
		require(!_isExcludedFromReward[account], "ERRO: A conta ja foi excluida das recompensas.");
		if (_rOwned[account] > 0) {
			_tOwned[account] = tokenFromReflection(_rOwned[account]);
		}
		_isExcludedFromReward[account] = true;
		_excludedFromReward.push(account);
	}

	function includeInAllowList(address account) public onlyOwner() {
		require(!_isAllowList[account], "ERRO: A conta ja esta na lista de permissoes.");
		_isAllowList[account] = true;
		_allowList.push(account);
	}

	function excludeFromAllowList(address account) public onlyOwner() {
		require(_isAllowList[account], "ERRO: A conta nao esta na lista de permissoes.");
		for (uint256 i = 0; i < _allowList.length; i++) {
			if (_allowList[i] == account) {
				_allowList[i] = _allowList[_allowList.length - 1];
				_isAllowList[account] = false;
				_allowList.pop();
				break;
			}
		}
	}

	function includeInBlockList(address account) public onlyOwner() {
		require(account != _swapRouterAddress, "ERROR: Nao podemos adicionar a Lista de Bloqueios o endereco do roteador de troca.");
		require(account != _burnAddress, "ERROR: Nao podemos adicionar a Lista de Bloqueios o endereco do Markenting.");
		require(!_isBlockList[account], "ERRO: A conta ja esta na lista de bloqueio.");
		_isBlockList[account] = true;
		_blockList.push(account);
	}

	function excludeFromBlockList(address account) public onlyOwner() {
		require(_isBlockList[account], "ERRO: A conta nao esta na lista de bloqueio.");
		for (uint256 i = 0; i < _blockList.length; i++) {
			if (_blockList[i] == account) {
				_blockList[i] = _blockList[_blockList.length - 1];
				_isBlockList[account] = false;
				_blockList.pop();
				break;
			}
		}
	}

	function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
		_taxFee = taxFee;
	}

	function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
		_liquidityFee = liquidityFee;
	}

	function setBurnFeePercent(uint256 burnFee) external onlyOwner() {
		_burnFee = burnFee;
	}

	function setMaxWalletPercent(uint256 maxWalletPercent) external onlyOwner() {
		_maxWalletAmount = _tTotal.mul(maxWalletPercent).div(
			10**2
		);
	}

	function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
		_maxTxAmount = _tTotal.mul(maxTxPercent).div(
			10**2
		);
	}

	function setTransactionLockTime(uint256 transactionLockTime) external onlyOwner() {
		_transactionLockTime = transactionLockTime;
	}

	function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
		_swapAndLiquifyEnabled = _enabled;
		emit SwapAndLiquifyEnabledUpdated(_enabled);
	}

// To recieve BNB from uniswapV2Router when swaping:
	receive() external payable {}

	function _reflectFee(uint256 rFee, uint256 tFee) private {
		_rTotal = _rTotal.sub(rFee);
		_tFeeTotal = _tFeeTotal.add(tFee);
	}

	function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
		(uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
		(uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
		return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
	}

	function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
		uint256 tFee = calculateTaxFee(tAmount);
		uint256 tLiquidity = calculateLiquidityFee(tAmount);
		uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
		return (tTransferAmount, tFee, tLiquidity);
	}

	function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
		uint256 rAmount = tAmount.mul(currentRate);
		uint256 rFee = tFee.mul(currentRate);
		uint256 rLiquidity = tLiquidity.mul(currentRate);
		uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
		return (rAmount, rTransferAmount, rFee);
	}

	function _getRate() private view returns(uint256) {
		(uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
		return rSupply.div(tSupply);
	}

	function _getCurrentSupply() private view returns(uint256, uint256) {
		uint256 rSupply = _rTotal;
		uint256 tSupply = _tTotal;		
		for (uint256 i = 0; i < _excludedFromReward.length; i++) {
			if (_rOwned[_excludedFromReward[i]] > rSupply || _tOwned[_excludedFromReward[i]] > tSupply) return (_rTotal, _tTotal);
			rSupply = rSupply.sub(_rOwned[_excludedFromReward[i]]);
			tSupply = tSupply.sub(_tOwned[_excludedFromReward[i]]);
		}
		if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
		return (rSupply, tSupply);
	}

	function _takeLiquidity(uint256 tLiquidity) private {
		uint256 currentRate =  _getRate();
		uint256 rLiquidity = tLiquidity.mul(currentRate);
		_rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
		if (_isExcludedFromReward[address(this)]) {
			_tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
		}
	}

	function calculateTaxFee(uint256 _amount) private view returns (uint256) {
		return _amount.mul(_taxFee).div(
			10**2
		);
	}

	function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
		return _amount.mul(_liquidityFee).div(
			10**2
		);
	}

	function calculateBurnFee(uint256 _amount) private view returns (uint256) {
		return _amount.mul(_burnFee).div(
			10**2
		);
	}

	function removeAllFee() private {
		if (_taxFee == 0 && _liquidityFee == 0 && _burnFee == 0) return;
		_previousTaxFee = _taxFee;
		_previousLiquidityFee = _liquidityFee;
		_previousBurnFee = _burnFee;
		_taxFee = 0;
		_liquidityFee = 0;
		_burnFee = 0;
	}

	function restoreAllFee() private {
		_taxFee = _previousTaxFee;
		_liquidityFee = _previousLiquidityFee;
		_burnFee = _previousBurnFee;
	}

	function _approve(address owner, address spender, uint256 amount) private {
		require(owner != address(0), "BEP20: aprovar do endereco zero.");
		require(spender != address(0), "BEP20: aprove para o endereco zero.");
		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	function _transfer(
		address sender,
		address recipient,
		uint256 amount
	) private transactionLock {
		require(sender != address(0), "BEP20: transferencia do endereco zero.");
		require(recipient != address(0), "BEP20: transferir para o endereco zero.");
		require(amount > 0, "ERRO: O valor da transferencia deve ser maior que zero.");
		if (recipient == _burnAddress) {
			removeAllFee();
			_transferBurn(sender, amount);
			restoreAllFee();
			return;
		}

		uint256 contractTokenBalance = balanceOf(address(this));

// Se o remetente ou destinatário não existir em uma AllowList, faça uma verificação adicional (para BlockList, _maxWalletAmount e _maxTxAmount):
		if (!_isAllowList[sender] && !_isAllowList[recipient]) {
			require(!_isBlockList[sender], "ERROR: O endereco do remetente esta na lista de bloqueio.");
			require(!_isBlockList[recipient], "ERRO: O endereco do destinatario esta na Lista de Bloqueios.");
			require(!_isBlockList[tx.origin], "ERRO: O endereco de origem da cadeia de transacoes esta na Lista de Bloqueios.");
			if (sender != owner() && recipient != owner()) {
				if (recipient != _uniswapV2Pair && recipient != address(_uniswapV2Router)) {
					require(balanceOf(recipient) < _maxWalletAmount, "ERRO: O endereco do destinatario ja comprou o valor maximo permitido.");
					require(balanceOf(recipient).add(amount) <= _maxWalletAmount, "ERRO: O valor da transferencia excede o valor maximo permitido para armazenamento no endereco do destinatario.");
				}
				require(amount <= _maxTxAmount, "ERRO: O valor da transferencia excede o valor maximo permitido.");
			}
			if (contractTokenBalance >= _maxTxAmount) {
				contractTokenBalance = _maxTxAmount;
			}
		}
		bool isOverMinTokenBalance = contractTokenBalance >= _numTokensSellToAddToLiquidity;
		if (
			isOverMinTokenBalance &&
			!_inSwapAndLiquify &&
			sender != _uniswapV2Pair &&
			sender != address(_uniswapV2Router) &&
			_swapAndLiquifyEnabled
		) {
			contractTokenBalance = _numTokensSellToAddToLiquidity;
// Adicione liquidez:
			swapAndLiquify(contractTokenBalance);
		}

// Indica se a taxa deve ser deduzida da transferência:
		bool takeFee = true;

// Se alguma conta pertencer à conta _isExcludedFromFee, remova a taxa:
		if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
			takeFee = false;
		}

// Adicione um valor de carimbo de data / hora à matriz de tempo de bloqueio da transação de endereço:
		_transactionLockTimestamp[_msgSender()] = block.timestamp;

// Transferir o valor, vai cobrar Taxa, Markenting e liquidez:
		_tokenTransfer(sender, recipient, amount, takeFee);
	}

	function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
		uint256 firstHalf = contractTokenBalance.div(2);
		uint256 secondHalf = contractTokenBalance.sub(firstHalf);
		uint256 initialBalance = address(this).balance;
		swapTokensForBnb(firstHalf); // <- this breaks the BNB -> HATE swap when swap+liquify is triggered
		uint256 newBalance = address(this).balance.sub(initialBalance);
		addLiquidity(secondHalf, newBalance);
		emit SwapAndLiquify(firstHalf, newBalance, secondHalf);
	}

	function swapTokensForBnb(uint256 tokenAmount) private {
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = _uniswapV2Router.WETH();
		_approve(address(this), address(_uniswapV2Router), tokenAmount);
		_uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
			tokenAmount,
			0,
			path,
			address(this),
			block.timestamp
		);
	}

	function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
		_approve(address(this), address(_uniswapV2Router), tokenAmount);
		_uniswapV2Router.addLiquidityETH{value: bnbAmount}(
			address(this),
			tokenAmount,
			0,
			0,
			owner(),
			block.timestamp
		);
	}

	function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
		if (!takeFee) removeAllFee();
		uint256 burnAmt = calculateBurnFee(amount);
		if (_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
			_transferFromExcluded(sender, recipient, (amount.sub(burnAmt)));
		} else if (!_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
			_transferToExcluded(sender, recipient, (amount.sub(burnAmt)));
		} else if (!_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
			_transferStandard(sender, recipient, (amount.sub(burnAmt)));
		} else if (_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
			_transferBothExcluded(sender, recipient, (amount.sub(burnAmt)));
		} else {
			_transferStandard(sender, recipient, (amount.sub(burnAmt)));
		}
		if (!takeFee) restoreAllFee();
		removeAllFee();
		_transferBurn(sender, burnAmt);
		restoreAllFee();
	}

	function _transferStandard(address sender, address recipient, uint256 tAmount) private {
		(uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
		_rOwned[sender] = _rOwned[sender].sub(rAmount);
		_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
		_takeLiquidity(tLiquidity);
		_reflectFee(rFee, tFee);
		emit Transfer(sender, recipient, tTransferAmount);
	}

	function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
		(uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
		_rOwned[sender] = _rOwned[sender].sub(rAmount);
		_tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
		_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);			
		_takeLiquidity(tLiquidity);
		_reflectFee(rFee, tFee);
		emit Transfer(sender, recipient, tTransferAmount);
	}

	function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
		(uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
		_tOwned[sender] = _tOwned[sender].sub(tAmount);
		_rOwned[sender] = _rOwned[sender].sub(rAmount);
		_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);	
		_takeLiquidity(tLiquidity);
		_reflectFee(rFee, tFee);
		emit Transfer(sender, recipient, tTransferAmount);
	}

	function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
		(uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
		_tOwned[sender] = _tOwned[sender].sub(tAmount);
		_rOwned[sender] = _rOwned[sender].sub(rAmount);
		_tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
		_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);		
		_takeLiquidity(tLiquidity);
		_reflectFee(rFee, tFee);
		emit Transfer(sender, recipient, tTransferAmount);
	}

	function _transferBurn(address sender, uint256 rAmount) private {
		uint256 rAccountBalance = _rOwned[sender];
		uint256 tAccountBalance = _tOwned[sender];
		uint256 tAmount = tAccountBalance.mul(rAmount).div(rAccountBalance);
		require(rAccountBalance >= rAmount, "BEP20: a quantidade queimada excede o equilibrio.");
		_rOwned[sender] = rAccountBalance.sub(rAmount);
		_tOwned[sender] = tAccountBalance.sub(tAmount);
		_tTotal = _tTotal.sub(tAmount);
		_rTotal = _rTotal.sub(rAmount);
		emit Transfer(sender, _burnAddress, rAmount);
	}

}