// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

// Imports
import "./ReentrancyGuard.sol";

// Interfaces
interface IERC20 {
    function decimals() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDEXRouter {
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

/**
 * @dev No uso la librería SafeMath de Openzeppelin porque a partir de la versión 0.8.0 de Solidity
 *      revierte automaticamente en caso de overflow.
 */
contract Swap is ReentrancyGuard {
    // Variables
    IERC20 public xxt; // Contrato del token XXT.
    address public owner; // Dueño del contrato.
    address public deadWallet = 0x000000000000000000000000000000000000dEaD; // Wallet de quemado.
    IDEXRouter router; // Router del swap que elijas.
    address public BUSD = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;

    // Constructor
    constructor(IERC20 _xxt) {
        xxt = _xxt;
        owner = msg.sender;
        router = IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
    }

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, 'Tienes que ser el owner del contrato para ejecutar esta funcion.');
        _;
    }

    // Funciones
    /**
     * @notice Calcula el % de un número.
     * @param x Número.
     * @param y % del número.
     * @param scale División.
     */
    function mulScale (uint x, uint y, uint128 scale) internal pure returns (uint) {
        uint a = x / scale;
        uint b = x % scale;
        uint c = y / scale;
        uint d = y % scale;

        return a * c * scale + a * d + b * c + b * d / scale;
    }

    /**
     * @notice Función que permite al usuario obtener XXT.
     */
    function swapTokens() public payable nonReentrant {
        require(msg.value > 0, "Debes enviar BNB.");
        
        uint _tokensPerBNB = 89; // 89 XXT/1BNB
        uint _withdrawableTokens = msg.value * _tokensPerBNB; // Tokens que se enviarán al usuario.

        require(_withdrawableTokens <= xxt.balanceOf(address(this)), "Balance insuficiente en el Swap.");

        uint _BNBFees = mulScale(msg.value, 50, 10000); // 50 basis points = 0.50%
        uint _withdrawableBNB = msg.value - _BNBFees; // BNBs que se enviarán al usuario.
        uint _devFees = mulScale(_BNBFees, 8000, 10000); // 8000 basis points = 80%
        uint _burnAmount = _BNBFees - _devFees; // Cantidad que va a ser quemada (20%).

        xxt.transfer(msg.sender, _withdrawableTokens); // Envía los tokens al usuario.
        // payable(msg.sender).transfer(_withdrawableBNB); // Envía los BNB menos el 0.50% al usuario.
        payable(owner).transfer(_devFees); // Envía el 80% del 0.50% de comisión de los BNB al owner.
        payable(deadWallet).transfer(_burnAmount); // Quema el 20% del 0.50% de comisión de los BNB.

        // Hace el swap de los BNB disponibles para enviar a BUSD y los envía al usuario.
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = BUSD;

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: _withdrawableBNB}(
            0,
            path,
            address(msg.sender),
            block.timestamp
        );
    }

    /**
     * @notice Función que permite retirar todos los tokens XXT y BNBs que se queden en el contrato 
               (por si algún día deja de usarse el contrato y se necesita recuperar todo lo que se quedó dentro).
     */
    function withdrawTokens() public onlyOwner {
        payable(owner).transfer(address(this).balance);
        uint _tokensAmount = xxt.balanceOf(address(this));
        xxt.transfer(owner, _tokensAmount);
    }

    /**
     * @notice Función que permite cambiar el owner del contrato.
     */
    function setOwner(address _owner) public onlyOwner {
        require(_owner != address(0));
        owner = _owner;
    }

    /**
     * @notice Función para que el contrato pueda recibir BNBs/ETHs/etc.. en caso de que manden directamente las monedas al contrato
     *         por error (suele ocurrir mucho).
     */
    receive() external payable {}
}