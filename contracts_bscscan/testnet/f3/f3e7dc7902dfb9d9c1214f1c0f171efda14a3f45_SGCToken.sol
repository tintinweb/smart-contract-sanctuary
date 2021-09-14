/**
 *Submitted for verification at BscScan.com on 2021-09-13
*/

// Proyecto SGC 
// VERSION: 1.01

// LOG:

// - 0.71 - Se re escribio todo el contrato
// - 0.80 - Se incluyo las feed de intercambio
// - 0.81 - Porcentajes arreglados y se incluyo una billetera central
// - 0.82 - Se ordeno el codigo y se incluyo los headers para evitar fallas de compilacion
// - 0.85 - Se borro parte del codigo antiguo y se permite usar modulos extras
// - 0.89 - Se agrego la funcion de destrucción del contrato y frenado del mismo
// - 0.90 - Agregado las billeteras para deposito de juegos, y marketing con sus fees 
// - 0.91 - Agregado el lapso temporal de 30 - 60 - 90 dias de inversion
// - 0.92 - Se modifico las tasas, antes se retenia todo el tiempo ahora se hace por los porcentajes
//          y el valor retenido va a la liquidez
// - 0.93 - Se hicieron cambios en las funciones de carga 
// - 0.94 - Modificacion del codigo y optimizacion de todo el codigo fuente, se reparo los fallos de
//          las comisiones que se presentaban
// - 0.95 - Inicio del sistema nuevo temporal de tasas con configuracion de activacion y desactivacion
// - 0.96 - Estructura temporal terminada
// - 0.97 - Agregado variables para modificar en vivo las tasas
// - 0.98 - Re ordenado el codigo para mejor optimizacion del mismo, aun hay algunos conflictos.
// - 0.99 - Funcion burn agregada y cambios en los porcentajes de comisiones y tax que se cobran
// - 1.00 - Se elimino las funciones transferfrom y se anexo una lista blanca
// - 1.01 - Optimizacion del codigo, solucion de varias fallas

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


// Este contrato solo es necesario para contratos intermedios similares a bibliotecas.
 
abstract contract Context 
{
    function _msgSender() internal view virtual returns (address) 
    {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) 
    {
        this; 
        return msg.data;
    }
}

pragma solidity ^0.8.0;

/*
 *
 * Este módulo se usa por herencia, en el cual estara disponible el modificador
 * `onlyOwner`, que se puede aplicar a sus funciones para restringir su uso a
 * el propietario.
 */

abstract contract Ownable is Context 
{
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    
     // Inicializa el contrato estableciendo al implementador como propietario inicial.
    
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }


     // Devuelve la dirección del propietario actual.

    function owner() public view virtual returns (address) 
    {
        return _owner;
    }


     // Se lanza si lo llama una cuenta que no sea el propietario.

    modifier onlyOwner() 
    {
        require(owner() == _msgSender(), "SGC: La persona que esta activando el contrato no es el propietario");
        _;
    }


    // Permite dejar el contrato sin dueño, lo renuncia en el caso que se decida desactivar el token.

    function renounceOwnership() public virtual onlyOwner 
    {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    
    // Transfiere el contrato a una nueva persona, en el caso de ceder derechos a un tercero
    
    function transferOwnership(address newOwner) public virtual onlyOwner 
    {
        require(
            newOwner != address(0),
            "SGC: El nuevo propietario es la direccion 0."
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// Contrato modular (recargamos los derechos)
pragma solidity ^0.8.0;

 // Interface BEP20

interface IBEP20 
{
   
     // Retorna el nombre del token
  
    function name() external view returns (string memory);

     // Retorna el simbolo del token
     
    function symbol() external view returns (string memory);

     // Retorna el numero de decimales
   
    function decimals() external view returns (uint8);

     // Retorna el numero de tokens actualmente
 
    function totalSupply() external view returns (uint256);

     // Retorna el numero de tokens que tiene la cuenta
  
    function balanceOf(address account) external view returns (uint256);

     // Retorna el nombre del propietario
    
    function getOwner() external view returns (address);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);


    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    
    event Burn(address indexed burner, uint256 value);
    
}

// -------------------------------- CODIGO ANTIGUO ZEPPELLING -----------------------------------------

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// parte del primer código que hicimos

interface IUniswapV2Pair 
{
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

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
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}
// ------------------------------------ FIN DEL CODIGO ----------------------------------------



pragma solidity ^0.8.0;

// Inicio del contrato de tipo BEP20

contract SGCToken is Ownable, IBEP20 
{

    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) public _allowances;

    uint256 public _totalSupply;
    uint256 public _timeToken = 1;

    string public _name;
    string public _symbol;
    uint8 public _decimals;
    uint256 public _totalHolders;
    
    // Tasas que se aplican en compra y venta
    
    uint256 public GameFee_Buy = 2;
    uint256 public MarketingFee_Buy = 2;
    uint256 public HolderBNBFee_Buy = 2;
    uint256 public LiquidezFee_Buy = 4;
    uint256 public GameFee_Sell = 3;
    uint256 public MarketingFee_Sell = 3;
    uint256 public HolderBNBFee_Sell = 3;
    uint256 public LiquidezFee_Sell = 5;
    uint256 public QuemaToken = 1;

    // Tasas que se aplican por dias de venta
    
    uint256 public Fee30dias = 50;
    uint256 public Fee60dias = 30;
    uint256 public Fee90dias = 20;
    //uint256 public Fee120dias = 15;
    
    // El numero de horas de cada deadline
    uint256 public d30dias = 30*24;
    uint256 public d60dias = 60*24;
    uint256 public d90dias = 90*24;
    

    int minima_compra; // A futuro la idea es crear una variable de compra minima
    uint maxima_compra;
    address[] public holders;
    uint256 private _start_timestamp = block.timestamp; // Funcion de calculo de tiempo

    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;

    // Wallet del operador principal, debe cambiarse antes de compilar
    address funds = 0x6093fDD4eC6BAdb67e20323AA05478048B35a5aF;
    
    // Wallet de recaudacion para el desarrollo de juegos
    address gamers = 0x68f5C74A063BAf8D081196a43aEE4ef506E13265;

    // Wallet de recaudacion para publicidad
    address market = 0x1b41f17A63a3c55AfBA63D19fdD677a9Cea62230;

    address routerAddress = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; // Ruta para pruebas en testnet con pancakeswap
    
    address burnAddress = 0x000000000000000000000000000000000000dEaD; //DEAD wallet de la BSC

    //address routerAddress = 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F; // Direccion de uso con la red real 


    constructor() 
    {
        _name = "Safe Game Cash"; // Descripcion de la moneda
        _symbol = "SGC"; // Simbolo de la moneda
        _decimals = 9; // Decimales
        _totalSupply = 2 * 10 ** 15 * 10 ** 9; // Primera parte 24 ceros, y 18 ceros de Decimales
        _totalHolders = 0; // Inicialmente cuantos holders hay para calcular

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerAddress); // Router de uniswap

        // Crea un par uniswap para este nuevo token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()) // Ruta de uniswap para hacer exchange
        .createPair(address(this), _uniswapV2Router.WETH()); // Creacion de pares si se usa de intercambio

        // Establecer el resto de las variables del contrato
        uniswapV2Router = _uniswapV2Router; // Creamos un enrutamiento de variables

        _balances[msg.sender] = _totalSupply; // Mandamos el valor de los balances al supply
        emit Transfer(address(0), _msgSender(), _totalSupply); // Transferencia sin valores
    }

     // Devuelve el nombre del token

    function name() public view override returns (string memory) 
    {
        return _name;
    }

     // Devuelve el simbolo del token 

    function symbol() public view override returns (string memory) 
    {
        return _symbol;
    }
    
    // Devuelve el numero de decimales del token    

    function decimals() public view override returns (uint8) 
    {
        return _decimals;
    }
    
    // Total del supply circulante

    function totalSupply() public view override returns (uint256) 
    {
        return _totalSupply;
    }
    
    // Obtiene el balance

    function balanceOf(address account) public view override returns (uint256) 
    {
        return _balances[account];
    }
    
    // Quien es el titular

    function getOwner() public view override returns (address) 
    {
        return owner();
    }
    
    function timeSinceDeploymentHours() public view returns (uint256) 
    {
        return (block.timestamp - _start_timestamp)/(60*60);
    }
    
    function timeSinceDeploymentSeconds() public view returns (uint256) 
    {
        return block.timestamp - _start_timestamp;
    }
    
    // Activa o desactiva las tasas por tiempo
    
    function timeTask(uint256 tiempo) public virtual
    {
        //tiempo = _timeToken;
        _timeToken = tiempo;
    }
   
    // Fee de juegos en compra
    
    function BUY_FEE_GAMES(uint256 variable) public virtual
    {
        //variable = GameFee_Buy;
        GameFee_Buy = variable;
        
    }
    
    // Fee de marketing en compra
    
    function BUY_FEE_MARKTING(uint256 variable) public virtual
    {
        //variable = MarketingFee_Buy;
        MarketingFee_Buy = variable;
    }
    
    // Fee de holders BNB en compra
    
    function BUY_FEE_BNBHOLDERS(uint256 variable) public virtual
    {
        //variable = HolderBNBFee_Buy ;
        HolderBNBFee_Buy = variable;
    }
    
    // Fee para liquidez en compra
    
    function BUY_FEE_LIQUIDEZ(uint256 variable) public virtual
    {
        //variable = LiquidezFee_Buy;
        LiquidezFee_Buy = variable;
    }

    // Fee de juegos en venta
    
    function SELL_FEE_GAMES(uint256 variable) public virtual
    {
        //variable = GameFee_Sell;
        GameFee_Sell = variable;
    }
    
    // Fee de marketing en venta
    
    function SELL_FEE_MARKTING(uint256 variable) public virtual
    {
        //variable = MarketingFee_Sell;
        MarketingFee_Sell = variable;
    }
    
    // Fee de holders BNB en venta
    
    function SELL_FEE_BNBHOLDERS(uint256 variable) public virtual
    {
        //variable = HolderBNBFee_Sell;
        HolderBNBFee_Sell = variable;
    }
    
    // Fee para liquidez en venta
    
    function SELL_FEE_LIQUIDEZ(uint256 variable) public virtual
    {
        //variable = LiquidezFee_Sell;
        LiquidezFee_Sell = variable;
    }

    // Fee de 30 dias
    
    function FEE_30(uint256 variable) public virtual
    {
        //variable = Fee30dias;
        Fee30dias = variable;
    }
    
    // Fee de 60 dias
    
    function FEE_60(uint256 variable) public virtual
    {
        //variable = Fee60dias;
        Fee60dias = variable;
    }
    
    // Fee de 90 dias
    
    function FEE_90(uint256 f90) public virtual
    {
        //f90 = Fee90dias;
        Fee90dias = f90;
    }
    
    // Establece el porcentaje de quema de tokens
    
    function Quema_de_token(uint256 quemando) public virtual
    {
        //quemando = QuemaToken;
        QuemaToken = quemando;
    }
    
    function setDeadline1(uint256 variable) public virtual
    {
        d30dias = variable;
        //variable = d30dias;
    }
    
    function setDeadline2(uint256 variable) public virtual
    {
        d60dias = variable;
        //variable = d60dias;
    }
    
    function setDeadline3(uint256 variable) public virtual
    {
        d90dias = variable;
        //variable = d90dias;
    }
    
    // Funcion de transferencia de tokens (venta)

    function transfer(address recipient, uint256 amount) public virtual override returns (bool)
    {
        // Agrega las direcciones de los holders para calcular el precio
        uint8 flag = 0;

        // Variables temporales de hora y tiempo
        uint256 time_start = block.timestamp - _start_timestamp;
        uint256 hour = 60 * 60;

        for (uint256 i = 0; i < _totalHolders; i++)
        {
            if (holders[i] == recipient) 
            {
                flag = 1;
            }
        }

        if (flag == 0) 
        {
            holders.push(recipient);
            _totalHolders = _totalHolders + 1;
        }
        
        if (msg.sender == gamers || msg.sender == owner() || msg.sender == market) // envio desde la billetera principal
        {
          _transfer(msg.sender, recipient, amount);
          return true;
        }
        
        if ( _timeToken == 1) // Si esta activo el sistema temporal aplica las tasas
        {
        // Inicio de codigo de venta dentro de pancakeswap para aplicar las tasas cuando se compra y vende 

         if (msg.sender == routerAddress) // Compra
         {
           send_holders(msg.sender, amount * HolderBNBFee_Buy / 100); //  holders bnb
           _transfer(msg.sender, funds, (amount * LiquidezFee_Buy) / 100); // liquidez
	       _transfer(msg.sender, gamers, (amount * GameFee_Buy) / 100); // juegos
           _transfer(msg.sender, market, (amount * MarketingFee_Buy) / 100); // marketing
           _burn(msg.sender, (amount * QuemaToken) / 100); // Quema tokens
           _transfer(msg.sender, recipient, (amount * (100 - LiquidezFee_Buy - GameFee_Buy - MarketingFee_Buy - HolderBNBFee_Buy - QuemaToken)) / 100);

         } 
         else if (recipient == routerAddress) // Venta
         {
             
          // Venta dentro de pancketswap
             
          if (time_start < d30dias * hour) // 30 dias
          {
           send_holders(msg.sender, amount * HolderBNBFee_Sell / 100); //  holders bnb
           _transfer(msg.sender, funds, (amount * LiquidezFee_Sell) / 100); // liquidez
	       _transfer(msg.sender, gamers, (amount * (Fee30dias - LiquidezFee_Sell - HolderBNBFee_Sell - QuemaToken) ) / 200); // juegos
           _transfer(msg.sender, market, (amount * (Fee30dias - LiquidezFee_Sell - HolderBNBFee_Sell - QuemaToken) ) / 200); // marketing
           _burn(msg.sender, (amount * QuemaToken) / 100); // Quema tokens
           
           // Y el 50% será enviado al destinatario si no pasarosn 30 dias
 		   _transfer(msg.sender, recipient, (amount * (100-Fee30dias)) / 100); // 50% de liquidez
          } 
          else if (time_start < d60dias * hour) // 60 dias
          {
           send_holders(msg.sender, amount * HolderBNBFee_Sell / 100); //  holders bnb
           _transfer(msg.sender, funds, (amount * LiquidezFee_Sell) / 100); // liquidez
	       _transfer(msg.sender, gamers, (amount * (Fee60dias - LiquidezFee_Sell - HolderBNBFee_Sell - QuemaToken) ) / 200); // juegos
           _transfer(msg.sender, market, (amount * (Fee60dias - LiquidezFee_Sell - HolderBNBFee_Sell - QuemaToken) ) / 200); // marketing
           _burn(msg.sender, (amount * QuemaToken) / 100); // Quema tokens
  
     	   // Y el 70% será enviado al destinatario
           _transfer(msg.sender, recipient, (amount * (100-Fee60dias)) / 100 ); // 70% de liquidez
          } 
          else if (time_start < d90dias * hour) // 90 dias
          {
           send_holders(msg.sender, amount * HolderBNBFee_Sell / 100); //  holders bnb
           _transfer(msg.sender, funds, (amount * LiquidezFee_Sell) / 100); // liquidez
	       _transfer(msg.sender, gamers, (amount * (Fee90dias - LiquidezFee_Sell - HolderBNBFee_Sell - QuemaToken) ) / 200); // juegos
           _transfer(msg.sender, market, (amount * (Fee90dias - LiquidezFee_Sell - HolderBNBFee_Sell - QuemaToken) ) / 200); // marketing
           _burn(msg.sender, (amount * QuemaToken) / 100); // Quema tokens
              
           // Y el 75% será enviado al destinatario
           _transfer(msg.sender, recipient, (amount * (100-Fee90dias)) / 100 ); // 75% de liquidez
          } 
          else // despues de 90 dias
          {
           // Si el usuario intercambia SGC dentro del pancakeswap, el 10% se enviará al inversor
           send_holders(msg.sender, amount * HolderBNBFee_Sell / 100); //  holders bnb
           _transfer(msg.sender, funds, (amount * LiquidezFee_Sell) / 100); // liquidez
	       _transfer(msg.sender, gamers, (amount * GameFee_Sell) / 100); // juegos
           _transfer(msg.sender, market, (amount * MarketingFee_Sell) / 100); // marketing
           _burn(msg.sender, (amount * QuemaToken) / 100); // Quema tokens
           _transfer(msg.sender, recipient, (amount * (100 - LiquidezFee_Sell - GameFee_Sell - MarketingFee_Sell - HolderBNBFee_Sell - QuemaToken)) / 100);
          }
         }
        
        else { //intercambio de SGC entre holders
            
         // Como ya no se vende, se aplican tasas cuando se intercambia entre usuarios, solo se aplicara
         // el codigo de compra, ya que no se podra aplicar venta en intercambio de envio (ya que no 
         // intercambia dinero fiat)
         
          send_holders(msg.sender, amount * HolderBNBFee_Buy / 100); //  holders bnb
          _transfer(_msgSender(), funds, (amount * LiquidezFee_Buy) / 100); // liquidez
	      _transfer(_msgSender(), gamers, (amount * GameFee_Buy) / 100); // juegos
          _transfer(_msgSender(), market, (amount * MarketingFee_Buy) / 100); // marketing
          _burn(_msgSender(), (amount * QuemaToken) / 100); // Quema tokens
          _transfer(_msgSender(), recipient, (amount * (100 - LiquidezFee_Buy - GameFee_Buy - MarketingFee_Buy - HolderBNBFee_Buy - QuemaToken)) / 100);

        }
         return true;
        }
        
        // En el caso que se desactive las tasas temporales se aplica el codigo libre de tasas temporales
        
        else if ( _timeToken == 0)
        {
         // Compra dentro de pancketswap

         if (msg.sender == routerAddress) // Compra
         {
          // Si el usuario intercambia SGC dentro del pancketswap
          send_holders(msg.sender, amount * HolderBNBFee_Buy / 100); //  holders bnb
          _transfer(msg.sender, funds, (amount * LiquidezFee_Buy) / 100); // liquidez
	      _transfer(msg.sender, gamers, (amount * GameFee_Buy) / 100); // juegos
          _transfer(msg.sender, market, (amount * MarketingFee_Buy) / 100); // marketing
          _burn(msg.sender, (amount * QuemaToken) / 100); // Quema tokens
          _transfer(msg.sender, recipient, (amount * (100 - LiquidezFee_Buy - GameFee_Buy - MarketingFee_Buy - HolderBNBFee_Buy - QuemaToken)) / 100);
          

         } 
         else if (recipient == routerAddress) // Venta
         {
             
         // Venta dentro de pancketswap

          // Si la usuario envía / recibe fuera de panqueque
         // El 2% se enviará a los titulares para obtener una recompensa.
         send_holders(msg.sender, amount * HolderBNBFee_Sell / 100); // para holders bnb
         _transfer(msg.sender, funds, amount * LiquidezFee_Sell / 100); // liquidez
         _transfer(msg.sender, gamers, amount * GameFee_Sell / 100); // juegos
         _transfer(msg.sender, market, amount * MarketingFee_Sell / 100); // marketing
         _burn(msg.sender, (amount * QuemaToken) / 100); // Quema tokens
         _transfer(msg.sender, recipient, (amount * (100 - LiquidezFee_Sell - GameFee_Sell - MarketingFee_Sell - HolderBNBFee_Sell - QuemaToken)) / 100);
         
         }
         
         else { //intercambio de SGC entre holders
         
         // Ahora en el caso que no se venda o compre en pancketswap se aplica solo la tarifa de compra,
         // no es posible identificar otro tipo de movimiento.

         send_holders(msg.sender, amount * HolderBNBFee_Buy / 100); //  holders bnb
         _transfer(_msgSender(), funds, (amount * LiquidezFee_Buy) / 100); // liquidez
	     _transfer(_msgSender(), gamers, (amount * GameFee_Buy) / 100); // juegos
         _transfer(_msgSender(), market, (amount * MarketingFee_Buy) / 100); // marketing
         _burn(_msgSender(), (amount * QuemaToken) / 100); // Quema tokens
         _transfer(_msgSender(), recipient, (amount * (100 - LiquidezFee_Buy - GameFee_Buy - MarketingFee_Buy - HolderBNBFee_Buy - QuemaToken)) / 100);

         }
        return true;
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private 
    {
        // genera la ruta del par uniswap del token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // hace el swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // acepta cualquier cantidad de ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256)
    {
        return _allowances[owner][spender];
    }

     // Aumenta atómicamente la asignación otorgada al "gastador" por la persona que llama. 

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool)
    {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

     // Disminuye atómicamente la asignación otorgada al "gastador" por la persona que llama.

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "SGC: transferencia desde la direccion cero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

     // Mueve tokens desde "cantidad" de "remitente" a "destinatario".

    function _transfer(address sender, address recipient, uint256 amount) internal virtual 
    {
        require(sender != address(0), "SGC: transferencia desde la direccion cero");
        require(recipient != address(0), "SGC: transferir a la direccion cero");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "SGC: el monto de la transferencia excede el saldo");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    // Crea tokens de `cantidad` y los asigna a la` cuenta`, aumentando
    // el suministro total, en el caso que la quema supere a la creacion.

    function _mint(address account, uint256 amount) internal virtual 
    {
        require(account != address(0), "SGC: crear desde la direccion cero");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
     }

     // Destruye tokens de `cantidad` de la` cuenta`, reduciendo la
     // oferta total, de esta forma se equilibra el precio.
/*
    function _burn(address account, uint256 amount) internal virtual 
    {
        require(account != address(0), "SGC: quemar desde la direccion cero");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "SGC: la cantidad quemada excede el saldo");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
     }*/
     
    function _burn(address _who, uint256 _value) internal virtual {
        require(_value <= _balances[_who], "SGC: la cantidad a quemar excede el saldo");
        _balances[_who] -= _value;
        _totalSupply -= _value;
        emit Burn(_who, _value);
        emit Transfer(_who, burnAddress, _value);
     }
     
    function burnFromFunds(uint256 _value) public virtual returns (bool){
        require(_value <= _balances[funds], "SGC: la cantidad a quemar excede el saldo");
        _balances[funds] -= _value;
        _totalSupply -= _value;
        emit Burn(funds, _value);
        emit Transfer(funds, burnAddress, _value);
        return true;
     }
     
    function burnFromOwner(uint256 _value) public virtual returns (bool){
        require(_value <= _balances[owner()], "SGC: la cantidad a quemar excede el saldo");
        _balances[owner()] -= _value;
        _totalSupply -= _value;
        emit Burn(owner(), _value);
        emit Transfer(owner(), burnAddress, _value);
        return true;
     }

   
     // Establece la "cantidad" como la asignación de "gastado" sobre los tokens del "propietario".

    function _approve(address owner, address spender, uint256 amount) internal virtual 
    {
        require(owner != address(0),"SGC: aprobado desde la direccion cero");
        require(spender != address(0),"SGC: aprobado a la direccion cero");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


     // Establece {decimales} en un valor

    function _setupDecimals(uint8 decimals_) internal 
    {
        _decimals = decimals_;
    }

    /*
     * Hook que se llama antes de cualquier transferencia de tokens. Esto incluye
     * acuñación y quema.
     */

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual 
    {
        // por ahora sin ninguna accion
    }

    // Agrega liquidez
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) public 
    {
        // Aprueba la transferencia de tokens para cubrir todos los escenarios posibles
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Agrega liquidez
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, 
            0, // El deslizamiento es inevitable por la volatidad
            _msgSender(),
            block.timestamp
        );
    }

    // Recompensa a todos los titulares
    function send_holders(address sender, uint256 tokenAmount) internal
    {   
        uint256 totalReward = tokenAmount;
        uint256 reward = totalReward/(_totalHolders-1);
        bool flag2 = false;
        
        _balances[sender] -= totalReward;

        for (uint256 i = 0; i < _totalHolders; i++) 
        {
            //reward = (totalReward * _balances[holders[i]]) / _totalSupply;
            if(sender == holders[i] && flag2 == false){
                flag2 = true;
            }
            else{
                _balances[holders[i]] += reward;
                //emit Transfer(_msgSender(), holders[i], reward);
            }
        }
        
    }
    
    function send_holders_from_me(uint256 tokenAmount) external returns (bool)
    {
        require(tokenAmount <= _balances[msg.sender], "SGC: la cantidad a regalar excede el saldo");
        uint256 totalReward = tokenAmount;
        uint256 reward = totalReward/(_totalHolders-1);
        bool flag2 = false;
        
        _balances[msg.sender] -= totalReward;

        for (uint256 i = 0; i < _totalHolders; i++) 
        {
            //reward = (totalReward * _balances[holders[i]]) / _totalSupply;
            if(msg.sender == holders[i] && flag2 == false){
                flag2 = true;
            }
            else{
                _balances[holders[i]] += reward;
                //emit Transfer(_msgSender(), holders[i], reward);
            }
        }
        
        return true;
    }
    
    
}