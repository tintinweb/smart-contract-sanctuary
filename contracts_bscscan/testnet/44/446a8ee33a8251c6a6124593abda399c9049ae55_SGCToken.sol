/**
 *Submitted for verification at BscScan.com on 2021-10-16
*/

// Proyecto SGC 
// VERSION: 1.13

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
// - 1.05 - Actualizacion de errores y fallas de wallet de quemado
// - 1.06 - Se agrego exclusion selectiva de fee de cuentas y sistema anti ballenas
// - 1.07 - Inicio del codigo nuevo de intercambio con packetswap, ahora se evitara el problema de antes
// - 1.08 - Se agrego la libreria libmath para poder hacer subfunciones
// - 1.09 - Revision de fallas en pancketswap, ya casi funciona en su totalidad
// - 1.10 - Ahora pancketswap funciona pero falla al aplicar las ventas por el porcentaje alto, queda probar modificarlo
// - 1.11 - Anexo de intercambio de token a bnb
// - 1.12 - Ahora se detecta los envios excluidos de las billeteras especiales y los holders se envian en bnb y en sgc si se transfieren dentro de la red sin swap
// - 1.13 - Se agrego cambios en la seguridad del token y control de usuarios del equipo

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;


// Este contrato solo es necesario para contratos intermedios similares a bibliotecas.

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an account access to this role
   */
  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));

    role.bearer[account] = true;
  }

  /**
   * @dev remove an account's access to this role
   */
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));

    role.bearer[account] = false;
  }

  /**
   * @dev check if an account has this role
   * @return bool
   */
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}


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

pragma solidity ^0.8.3;

library SafeMath 
{

  function add(uint256 a, uint256 b) internal pure returns (uint256) 
  {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }


  function sub(uint256 a, uint256 b) internal pure returns (uint256) 
  {
    return sub(a, b, "SafeMath: subtraction overflow");
  }


  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
  {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }


  function mul(uint256 a, uint256 b) internal pure returns (uint256) 
  {

    if (a == 0) 
    {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) 
  {
    return div(a, b, "SafeMath: division by zero");
  }


  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
  {
    require(b > 0, errorMessage);
    uint256 c = a / b;

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) 
  {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
  {
    require(b != 0, errorMessage);
    return a % b;
  }
}




/*
 *
 * Este módulo se usa por herencia, en el cual estara disponible el modificador
 * `onlyOwner`, que se puede aplicar a sus funciones para restringir su uso a
 * el propietario.
 */

abstract contract Ownable is Context 
{
    using SafeMath for uint256;
    using Roles for Roles.Role;
    
    Roles.Role internal CEO;
    Roles.Role internal coreTeam;
    
    bool public ceoSign = false;
    bool public coreMemberSign = false;
    
    modifier onlyCEOandSign(){
        require(CEO.has(msg.sender) == true, 'Must have CEO role');
        require (coreMemberSign, "Must have Ceo and core member sign");
        ceoSign = false;
        coreMemberSign = false;
        _;
    }
    
    modifier CEOandCoreTeamAndSign(){
        require(coreTeam.has(msg.sender) == true || CEO.has(msg.sender) == true, 'Must have CEO or coreTeam role');
        require (ceoSign && coreMemberSign, "Must have Ceo and core member sign");
        ceoSign = false;
        coreMemberSign = false;
        _; 
    }
    
    modifier CEOandCoreTeam(){
        require(coreTeam.has(msg.sender) == true || CEO.has(msg.sender) == true, 'Must have CEO or coreTeam role');
        _; 
    }
    
    modifier onlyCEO(){
        require(CEO.has(msg.sender) == true, 'Must have CEO role');
        _;
    }
    
    modifier onlyCoreTeam(){
        require(coreTeam.has(msg.sender) == true, 'Must have coreTeam role');
        _; 
    }
    
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

    // Permite dejar el contrato sin dueño, lo renuncia en el caso que se decida desactivar el token.

    function renounceOwnership() public virtual onlyCEO() 
    {
        emit OwnershipTransferred(_owner, address(0));
        CEO.remove(_owner);
        _owner = address(0);
        
    }

    
    // Transfiere el contrato a una nueva persona, en el caso de ceder derechos a un tercero
    
    function transferOwnership(address newOwner) public virtual onlyCEO()
    {
        require(
            newOwner != address(0),
            "SGC: El nuevo propietario es la direccion 0."
        );
        emit OwnershipTransferred(_owner, newOwner);
        CEO.remove(_owner);
        CEO.add(newOwner);
        _owner = newOwner;
    }
}

// Contrato modular (recargamos los derechos)
pragma solidity ^0.8.3;

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
    
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

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



pragma solidity ^0.8.3;

// Inicio del contrato de tipo BEP20

contract SGCToken is Ownable, IBEP20 
{
    using SafeMath for uint256;
    using Roles for Roles.Role;
    
    // Mapeo de balances y tiempo de intercambio
    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) public _allowances;
    
    // Capa de usuarios
    mapping(address => bool) private _sinfee;
    
    // Capa anti bots 
    mapping(address => uint256) public _frecuencia_tiempo; // capa de calculo de frecuencia de compra y venta en tiempo
    mapping(address => uint256) public _frecuencia_venta; // calculo para frecuencia de venta

    // Variables de tokens y capa temporal
    uint256 public _totalSupply;
    uint256 public _timeToken = 1;

    // Variables de datos del token (nombre y demas)
    string public _name;
    string public _symbol;
    uint8 public _decimals;
    uint256 public _totalHolders;
    
    // Tasas que se aplican en compra y venta
    
    uint256 public DevelopmentFee_Buy = 2; //DevelopmentFee_Buy
    uint256 public MarketingFee_Buy = 2;
    uint256 public HolderRewardFee_Buy = 2; //HolderRewardFee_Buy
    uint256 public LiquidezFee_Buy = 4; 
    uint256 public DevelopmentFee_Sell = 3; //DevelopmentFee_Sell
    uint256 public MarketingFee_Sell = 3;
    uint256 public HolderRewardFee_Sell = 3; //HolderRewardFee_Sell
    uint256 public LiquidezFee_Sell = 5;
    uint256 public BurnTokenFee = 1; //BurnTokenFee

    // Tasas que se aplican por dias de venta
    
    uint256 public Fee30dias = 33;
    uint256 public Fee60dias = 30;
    uint256 public Fee90dias = 20;
    //uint256 public Fee120dias = 15;
    
    // El numero de horas de cada deadline
    uint256 public d30dias = 30*24;
    uint256 public d60dias = 60*24;
    uint256 public d90dias = 90*24;
    
    address burnAddress = 0x000000000000000000000000000000000000dEaD;   // DEAD wallet de la BSC
    address routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3; // Ruta de https://pancake.kiemtienonline360.com/#/swap <= esto hay que cambiarlo!!!!!!!!!!!!!!!
    //address routerAddress = 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F; // Direccion de uso con la red real 
    address mcaddress = 0xE4E50e91A6E6e7c161277e27d6D476579C586920;
    
    // Cantidad de maximas de compras y ventas en intercambio
    uint public maxima_compra = 1 * 10 ** 15 * (10**9); // Especificamos el maximo de compra para evitar ballenas
    uint public maxima_venta = 5 * 10 ** 12 * (10**9);  // Especificamos un maximo de venta tambien para evitar balleneas

    // Direcciones publicas
    address[] public holders;
    address public _cuenta;
    uint256 private _start_timestamp = block.timestamp; // Funcion de calculo de tiempo
        
    // Declaraciones para intercambio de SGC a BNB
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;

    // Direcciones excluidas de los fee
    mapping (address => bool) private DireccionExcluida;

    
    /* ############################################################### */
    /* ############################################################### */
                            /* to change */
    
    // Wallet del operador principal, debe cambiarse antes de compilar
    address funds = 0x6093fDD4eC6BAdb67e20323AA05478048B35a5aF; 
    
    // Wallet de recaudacion para el desarrollo de juegos
    address gamers = 0x68f5C74A063BAf8D081196a43aEE4ef506E13265;

    // Wallet de recaudacion para publicidad
    address market = 0x1b41f17A63a3c55AfBA63D19fdD677a9Cea62230;
    
    // Miembros del Core team
    address CEOAddress = 0xCd4bA9C5Dc8875d4A2D318A081BBe50553A902d1;
    address coreTeamAddress1 = 0x10A04121Bc5a183C71b9FD4dc024422de9d09BfE; 
    address coreTeamAddress2 = 0x34931A227553a010FfDcd6baB7a75EBd5E9408d6; 
    address coreTeamAddress3 = 0x0d5925F9fd1A9e797Cd7F2fdF6B030EAa89F1260; 
    address coreTeamAddress4 = 0x18E6002108cf86EBB4b83De85e87Aa9eE3911dc6;
    
    /* ############################################################### */
    /* ############################################################### */

    constructor() 
    {
        _name = "Safe Game Cash"; // Descripcion de la moneda
        _symbol = "SGC"; // Simbolo de la moneda
        _decimals = 9; // Decimales
        _totalSupply = 2 * 10 ** 15 * 10 ** 9; // Primera parte 24 ceros, y 18 ceros de Decimales
        _totalHolders = 0; // Inicialmente cuantos holders hay para calcular
        
        CEO.add(msg.sender);
        coreTeam.add(coreTeamAddress1);
        coreTeam.add(coreTeamAddress2);
        coreTeam.add(coreTeamAddress3);
        coreTeam.add(coreTeamAddress4);
        
        // excluye las cuentas que se especifiquen de las fees
        withoutFee(owner(), true);
        withoutFee(address(this), true);
        withoutFee(mcaddress, true);
        withoutFee(CEOAddress, true);
        withoutFee(coreTeamAddress1, true);
        withoutFee(coreTeamAddress2, true);
        withoutFee(coreTeamAddress3, true);
        withoutFee(coreTeamAddress4, true);
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerAddress); // Router de uniswap

        // Crea un par uniswap para este nuevo token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()) // Ruta de uniswap para hacer exchange
        .createPair(address(this), _uniswapV2Router.WETH()); // Creacion de pares si se usa de intercambio
        
        // Establecer el resto de las variables del contrato
        uniswapV2Router = _uniswapV2Router; // Creamos un enrutamiento de variables

        _balances[CEOAddress] = _totalSupply/100;
        _balances[coreTeamAddress1] = _totalSupply/100;
        _balances[coreTeamAddress2] = _totalSupply/100;
        _balances[coreTeamAddress3] = _totalSupply/100;
        _balances[coreTeamAddress4] = _totalSupply/100;
        _balances[msg.sender] += _totalSupply - (_totalSupply/100)*5; // Mandamos el valor de los balances al supply
        emit Transfer(address(0), _msgSender(), _balances[msg.sender]); // Transferencia sin valores
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
    
    // Firma como CEO
    function signAsCEO() public virtual onlyCEO() {
        ceoSign = true;
    }
    
    // Firma como Miembro del CoreTeam
    function signAsCoreMember() public virtual onlyCoreTeam() {
        coreMemberSign = true;
    }
    
    // Activa o desactiva las tasas por tiempo
    
    function timeTask(uint256 tiempo) public virtual onlyCEOandSign()
    {
        _timeToken = tiempo;
    }
    
    // Tasas al comprar o transferir SGC
    function setBuyFee(uint256 _BNBRewardsFeeOnBuy, uint256 _liquidityFeeOnBuy, uint256 _marketingFeeOnBuy, uint256 _gameFeeOnBuy) public onlyCEOandSign() {
        HolderRewardFee_Buy = _BNBRewardsFeeOnBuy;
        LiquidezFee_Buy = _liquidityFeeOnBuy;
        MarketingFee_Buy = _marketingFeeOnBuy;
        DevelopmentFee_Buy = _gameFeeOnBuy;
    }
    
    //tasas al vender SGC
    function setSellFee(uint256 _BNBRewardsFeeOnSell, uint256 _liquidityFeeOnSell, uint256 _marketingFeeOnSell, uint256 _gameFeeOnSell) public onlyCEOandSign() {
        HolderRewardFee_Sell = _BNBRewardsFeeOnSell;
        LiquidezFee_Sell = _liquidityFeeOnSell;
        MarketingFee_Sell = _marketingFeeOnSell;
        DevelopmentFee_Sell = _gameFeeOnSell;
    }
   
    // Establece el porcentaje de quema de tokens
    
    function burn_Fee(uint256 quemado) public virtual onlyCEOandSign()
    {
        BurnTokenFee = quemado;
    }

    // Fee de 30 dias
    
    function FEE_30(uint256 variable) public virtual onlyCEOandSign()
    {
        Fee30dias = variable;
    }
    
    // Fee de 60 dias
    
    function FEE_60(uint256 variable) public virtual onlyCEOandSign()
    {
        Fee60dias = variable;
    }
    
    // Fee de 90 dias
    
    function FEE_90(uint256 variable) public virtual onlyCEOandSign()
    {
        Fee90dias = variable;
    }
    
    // Valor maximo de venta
    
    function setMaxSellAmount(uint256 amount) public virtual CEOandCoreTeamAndSign()
    {
        maxima_venta = amount * 10 ** 9;
    }
    
    // Valor maximo de compra
    
    function setMaxBuyAmount(uint256 amount) public virtual CEOandCoreTeamAndSign()
    {
        maxima_compra = amount * 10 ** 9;
    }

    // Intento de crear una pequeña asignacion de billeteras sin fee

    function withoutFee(address cuenta, bool excluida) public virtual CEOandCoreTeam()
    {
        require(DireccionExcluida[cuenta] != excluida, " Billetera 'excluida' ya excluida.");
        DireccionExcluida[cuenta] = excluida;
    }
    
    // Funcion de transferencia de tokens entre usuarios

    function transfer(address recipient, uint256 amount) public override returns (bool)
    {
        // Agrega las direcciones de los holders para calcular el precio
        uint8 flag = 0;

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
        
        if (msg.sender == funds ||  msg.sender == gamers || msg.sender == owner() || msg.sender == market ||  DireccionExcluida[msg.sender] == true || recipient == funds ||  recipient == gamers || recipient == owner() || recipient == market ||  DireccionExcluida[recipient] == true) // envios sin comisiones entre billeteras
        {
          _transfer(msg.sender, recipient, amount); // se envia sin comision, se debe especificar la billetera principal y la del ceo, el owner porque puede cambiarse todo
          return true;
        }
        
        //intercambio de SGC entre holders
         
        // Ahora en el caso que no se venda o compre en pancketswap se aplica solo la tarifa de compra,
        // no es posible identificar otro tipo de movimiento.

        send_normal_holders(_msgSender(), amount * HolderRewardFee_Buy / 100); //  holders bnb
        _transfer(_msgSender(), funds, (amount * LiquidezFee_Buy) / 100); // liquidez
	    _transfer(_msgSender(), gamers, (amount * DevelopmentFee_Buy) / 100); // juegos
        _transfer(_msgSender(), market, (amount * MarketingFee_Buy) / 100); // marketing
        _burn(_msgSender(), (amount * BurnTokenFee) / 100); // Quema tokens
        _transfer(_msgSender(), recipient, (amount * (100 - LiquidezFee_Buy - DevelopmentFee_Buy - MarketingFee_Buy - HolderRewardFee_Buy - BurnTokenFee)) / 100);         
        
        return true;
        
    }

    // Funcion de intercambio en exchange de tokens

    function transferSwap(address sender, address recipient, uint256 amount) public returns (bool)
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
        
        if (sender == funds ||  sender == gamers || sender == owner() || sender == market ||  DireccionExcluida[sender] == true) // envios sin comisiones entre billeteras
        {
          _transfer(sender, recipient, amount); // se envia sin comision, se debe especificar la billetera principal y la del ceo, el owner porque puede cambiarse todo
          return true;
        }
        
        if ( _timeToken == 1) // Si esta activo el sistema temporal aplica las tasas
        {
        // Inicio de codigo de venta dentro de pancakeswap para aplicar las tasas cuando se compra y vende 

         if (sender == routerAddress) // Compra
         {
           require(amount <= maxima_compra, "SGC: Se excede el monto maximo permitido de compra"); // Si el monto es mayor al configurado se cancela la compra
           send_holders(sender, amount * HolderRewardFee_Buy / 100); //  holders bnb
           _transfer(sender, funds, (amount * LiquidezFee_Buy) / 100); // liquidez
	       _transfer(sender, gamers, (amount * DevelopmentFee_Buy) / 100); // juegos
           _transfer(sender, market, (amount * MarketingFee_Buy) / 100); // marketing
           _burn(sender, (amount * BurnTokenFee) / 100); // Quema tokens
           _transfer(sender, recipient, (amount * (100 - LiquidezFee_Buy - DevelopmentFee_Buy - MarketingFee_Buy - HolderRewardFee_Buy - BurnTokenFee)) / 100);

         } 
         else if (recipient == routerAddress) // Venta
         {
             
          // Venta dentro de pancketswap
          require(amount <= maxima_venta, "SGC: Se excede el monto maximo permitido de venta"); // Si el monto es mayor al configurado se cancela la venta
             
          if (time_start < d30dias * hour) // 30 dias
          {
           send_holders(sender, amount * HolderRewardFee_Sell / 100); //  holders bnb
           _transfer(sender, funds, (amount * LiquidezFee_Sell) / 100); // liquidez
	       _transfer(sender, gamers, (amount * (Fee30dias - LiquidezFee_Sell - HolderRewardFee_Sell - BurnTokenFee) ) / 200); // juegos
           _transfer(sender, market, (amount * (Fee30dias - LiquidezFee_Sell - HolderRewardFee_Sell - BurnTokenFee) ) / 200); // marketing
           _burn(sender, (amount * BurnTokenFee) / 100); // Quema tokens           
           // Y el 50% será enviado al destinatario si no pasaron 30 dias
           _transfer(sender, recipient, (amount * (100-Fee30dias)) / 100); // 50% de liquidez
          } 
          else if (time_start < d60dias * hour) // 60 dias
          {
           send_holders(sender, amount * HolderRewardFee_Sell / 100); //  holders bnb
           _transfer(sender, funds, (amount * LiquidezFee_Sell) / 100); // liquidez
	       _transfer(sender, gamers, (amount * (Fee60dias - LiquidezFee_Sell - HolderRewardFee_Sell - BurnTokenFee) ) / 200); // juegos
           _transfer(sender, market, (amount * (Fee60dias - LiquidezFee_Sell - HolderRewardFee_Sell - BurnTokenFee) ) / 200); // marketing
           _burn(sender, (amount * BurnTokenFee) / 100); // Quema tokens  
     	   // Y el 70% será enviado al destinatario
           _transfer(msg.sender, recipient, (amount * (100-Fee60dias)) / 100 ); // 70% de liquidez
          } 
          else if (time_start < d90dias * hour) // 90 dias
          {
           send_holders(sender, amount * HolderRewardFee_Sell / 100); //  holders bnb
           _transfer(sender, funds, (amount * LiquidezFee_Sell) / 100); // liquidez
	       _transfer(sender, gamers, (amount * (Fee90dias - LiquidezFee_Sell - HolderRewardFee_Sell - BurnTokenFee) ) / 200); // juegos
           _transfer(sender, market, (amount * (Fee90dias - LiquidezFee_Sell - HolderRewardFee_Sell - BurnTokenFee) ) / 200); // marketing
           _burn(sender, (amount * BurnTokenFee) / 100); // Quema tokens              
           // Y el 75% será enviado al destinatario
           _transfer(sender, recipient, (amount * (100-Fee90dias)) / 100 ); // 75% de liquidez
          } 
          else // despues de 90 dias
          {
           // Si el usuario intercambia SGC dentro del pancakeswap, el 10% se enviará al inversor
           send_holders(sender, amount * HolderRewardFee_Sell / 100); //  holders bnb
           _transfer(sender, funds, (amount * LiquidezFee_Sell) / 100); // liquidez
	       _transfer(sender, gamers, (amount * DevelopmentFee_Sell) / 100); // juegos
           _transfer(sender, market, (amount * MarketingFee_Sell) / 100); // marketing
           _burn(sender, (amount * BurnTokenFee) / 100); // Quema tokens
           _transfer(sender, recipient, (amount * (100 - LiquidezFee_Sell - DevelopmentFee_Sell - MarketingFee_Sell - HolderRewardFee_Sell - BurnTokenFee)) / 100);
          }
         }
         return true;
        }
        
        // En el caso que se desactive las tasas temporales se aplica el codigo libre de tasas temporales
        
        else if ( _timeToken == 0)
        {
         // Compra dentro de pancketswap
         if (sender == routerAddress) // Compra
         {
          // Si el usuario intercambia SGC dentro del pancketswap
          require(amount <= maxima_compra, "SGC: Se excede el monto maximo permitido de compra"); // Si el monto es mayor al configurado se cancela el envio
          send_holders(sender, amount * HolderRewardFee_Buy / 100); //  holders bnb
          _transfer(sender, funds, (amount * LiquidezFee_Buy) / 100); // liquidez
	      _transfer(sender, gamers, (amount * DevelopmentFee_Buy) / 100); // juegos
          _transfer(sender, market, (amount * MarketingFee_Buy) / 100); // marketing
          _burn(sender, (amount * BurnTokenFee) / 100); // Quema tokens
          _transfer(sender, recipient, (amount * (100 - LiquidezFee_Buy - DevelopmentFee_Buy - MarketingFee_Buy - HolderRewardFee_Buy - BurnTokenFee)) / 100);          
         } 
         else if (recipient == routerAddress) // Venta
         {             
         // Venta dentro de pancketswap
         // Si la usuario envía / recibe fuera de panqueque
         // El 2% se enviará a los titulares para obtener una recompensa.
         require(amount <= maxima_venta, "SGC: Se excede el monto maximo permitido de venta"); // Si el monto es mayor al configurado se cancela la venta
         send_holders(sender, amount * HolderRewardFee_Sell / 100); // para holders bnb
         _transfer(sender, funds, amount * LiquidezFee_Sell / 100); // liquidez
         _transfer(sender, gamers, amount * DevelopmentFee_Sell / 100); // juegos
         _transfer(sender, market, amount * MarketingFee_Sell / 100); // marketing
         _burn(sender, (amount * BurnTokenFee) / 100); // Quema tokens
         _transfer(sender, recipient, (amount * (100 - LiquidezFee_Sell - DevelopmentFee_Sell - MarketingFee_Sell - HolderRewardFee_Sell - BurnTokenFee)) / 100);         
         }         
        }
     return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    // Swap de SGC a BNB
    
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

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) 
    {   
        /*if(sender == gamers || sender == market){
            require(coreTeam.has(msg.sender) == true || CEO.has(msg.sender) == true, 'Must have CEO or coreTeam role');
        }*/
        transferSwap(sender, recipient, amount); // se envia sin comision, solo se aplica para dar liquidez
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: la transferencia el excede el limite disponible")); // <====== 
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

     // Mueve "cantidad" tokens desde "remitente" a "destinatario".

    function _transfer(address sender, address recipient, uint256 amount) internal virtual 
    {
     require(sender != address(0), "SGC: transferencia desde la direccion cero");
     require(recipient != address(0), "SGC: transferir a la direccion cero");
     
     if (sender == gamers || sender == market){
        require(coreTeam.has(msg.sender) == true || CEO.has(msg.sender) == true, 'Must have CEO or coreTeam role');
        require (ceoSign && coreMemberSign, "Must have Ceo and core member sign to spend from Dev or Marketing wallet!");
        ceoSign = false;
        coreMemberSign = false;
     }

     _balances[sender] = _balances[sender].sub(amount, "BEP20: la transferencia el excede el limite disponible");
     _balances[recipient] = _balances[recipient].add(amount);
     emit Transfer(sender, recipient, amount);
    }

    // Crea tokens de `cantidad` y los asigna a la` cuenta`, aumentando
    // el suministro total, en el caso que la quema supere a la creacion.
    
    function _mint(address account, uint256 amount) internal virtual 
    {
        require(account != address(0), "SGC: crear desde la direccion cero");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
     }

     // Destruye tokens de `cantidad` de la` cuenta`, reduciendo la
     // oferta total, de esta forma se equilibra el precio.
     
    function _burn(address _who, uint256 _value) internal virtual 
    {
        require(_value <= _balances[_who], "SGC: la cantidad a quemar excede el saldo");
        _balances[_who] -= _value;
        _totalSupply -= _value;
        emit Burn(_who, _value);
        emit Transfer(_who, burnAddress, _value);
     }
     
    function burnFromFunds(uint256 _value) public virtual onlyCEOandSign() returns (bool) 
    {
        require(_value <= _balances[funds], "SGC: la cantidad a quemar excede el saldo");
        _balances[funds] -= _value;
        _totalSupply -= _value;
        emit Burn(funds, _value);
        emit Transfer(funds, burnAddress, _value);
        return true;
     }
     
    function burnFromOwner(uint256 _value) public virtual onlyCEOandSign() returns (bool)
    {
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

    // Recompensa a todos los titulares
    function send_holders(address sender, uint256 tokenAmount) internal
    {   
        uint256 totalReward = tokenAmount;
        uint256 reward = totalReward/(_totalHolders-1);
        bool flag2 = false;
        
        _balances[sender] -= totalReward;

        for (uint256 i = 0; i < _totalHolders; i++) 
        {
            if(sender == holders[i] && flag2 == false)
            {
                flag2 = true;
            }
            else
            {
                _balances[holders[i]] += reward;
                swapTokensForEth(reward);
            }
        }
        
    }
    
    
     // Recompensa a todos los titulares
    function send_normal_holders(address sender, uint256 tokenAmount) internal
    {   
        uint256 totalReward = tokenAmount;
        uint256 reward = totalReward/(_totalHolders-1);
        bool flag2 = false;
        
        _balances[sender] -= totalReward;

        for (uint256 i = 0; i < _totalHolders; i++) 
        {
            if(sender == holders[i] && flag2 == false)
            {
                flag2 = true;
            }
            else
            {
                _balances[holders[i]] += reward;
            }
        }
        
    }
}