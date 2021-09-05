/**
 *Submitted for verification at BscScan.com on 2021-09-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

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

contract Bank {
    // Variables 
    string  public name = "Bank"; // Nombre del contrato.
    address public owner; // Dirección del dueño del contrato.
    IERC20 public tokenV1; // Contrato del TokenV1.
    IERC20 public tokenV2; // Contrato del TokenV2.
    uint public rate; // % de cuantos TokensV2 equivalen a 1 TokenV1.
    uint public supplyLimit = 200; // % del límite de supply de los TokensV2 para limitar al usuario. 
    uint public cooldownTime = 1 minutes; // Tiempo de cooldown que va a tener el claim.
    mapping(address => uint) public claimReady; // Guarda el tiempo en el que el usuario podrá hacer su próximo claim.
    mapping(address => uint) public balanceV2; // Balance de los TokenV2 retirables en la DApp.
    mapping(address => uint) public tokensSwapped; // Balance de los TokensV2 que se intercambiaron.
    mapping(address => bool) public whitelist; // Control de whitelist.
    bool private swapping = false; // Revisa si ya está haciendo swap antes de poder volver a hacer otro.
    bool private claiming = false;// Revisa si ya está claimeando antes de poder volver a hacer claim otra vez.

    // Constructor
    constructor(IERC20 _tokenV1, IERC20 _tokenV2, uint _rate) {
        tokenV1 = _tokenV1;
        tokenV2 = _tokenV2;
        rate = _rate;
        owner = msg.sender;
    }

    // Modificadores
    modifier onlyOwner() {
        require(msg.sender == owner, 'Tienes que ser el owner del contrato para ejecutar esta funcion.');
        _;
    }

    // Funciones
    /**
     * @notice Función que activa el cooldown para poder hacer el claim.
     * @param _investor Dirección del inversor.
     */
    function _triggerCooldown(address _investor) internal {
        claimReady[_investor] = block.timestamp + cooldownTime;
    }

    /**
     * @notice Función que nos permite modificar los tokens.
     * @param _tokenV1 Dirección del TokenV1.
     * @param _tokenV2 Dirección del TokenV2.
     */
    function setTokens(IERC20 _tokenV1, IERC20 _tokenV2) public onlyOwner {
        tokenV1 = _tokenV1;
        tokenV2 = _tokenV2;
    }

    /**
     * @notice Función que nos permite modificar el rate.
     * @param _rate % de cuantos TokenV2 equivalen a 1 TokenV1.
     */
    function setRate(uint _rate) public onlyOwner {
        rate = _rate;
    }

    /**
     * @notice Función que nos permite modificar el tiempo de cooldown.
     * @param _cooldownTime Tiempo de cooldown que va a tener el claim.
     */
    function setCooldownTime(uint _cooldownTime) public onlyOwner {
        cooldownTime = _cooldownTime;
    }

    /**
     * @notice Calculate x * y / scale rounding down.
     * @param x TokenV1.
     * @param y TokenV2.
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
     * @notice Función que permite hacer swap entre las versiones de los tokens.
     * @param _amount Cantidad de tokens que el usuario envía para el swap.
     */
    function swapVersions(uint _amount) public {
        require(_amount > 0, 'La cantidad para hacer el swap debe ser mayor a 0');
        address _investor = msg.sender;
        require(whitelist[_investor] == true, 'El inversor debe estar dentro de la whitelist.');
        require(swapping == false, 'Ya estas haciendo swap.');

        swapping = true;

        uint balanceBefore = tokenV1.balanceOf(address(this));
        tokenV1.transferFrom(_investor, address(this), _amount); // Envía los TokensV1 desde la cuenta del usuario a la del contrato.
        uint balanceAfter = tokenV1.balanceOf(address(this));
        require(balanceAfter > balanceBefore, 'No has enviado ningun token'); // Comprueba que el balance del contrato ha aumentado.

        // _triggerCooldown(_investor); // Se inicializa el cooldown.

        uint _tokenV2_2percent = mulScale(tokenV2.totalSupply(), supplyLimit, 10000); // Cálcular el x% del total supply del TokenV2
        uint _investorV1Supply = mulScale(tokenV1.balanceOf(_investor), rate, 100); // Calcula el supply de la V2 que tiene en TokensV1.
        uint _investorSupplyBalance = tokenV2.balanceOf(_investor) + balanceV2[_investor] + _investorV1Supply; // Balance del inversor de TokensV2.
        uint _amountToMigrate;
        if(_investorSupplyBalance >= _tokenV2_2percent) {
            _amountToMigrate = mulScale(_amount, supplyLimit, 10000); // La cantidad a devolver con el swap será del x% del total supply.
        } else {
            _amountToMigrate = mulScale(_amount, rate, 100); // Calcula el monto con el rate.
        }

        // Añade los TokensV2 al balance de la dirección del inversor dentro de la DApp.
        balanceV2[_investor] += _amountToMigrate;
        tokensSwapped[_investor] = balanceV2[_investor];
        
        swapping = false;
    }

    /**
     * @notice Función que permite hacer claim de los tokens swapeados. Solo permite claimear el
     * 25% de los tokens swapeados 1 vez a la semana.
     */
    function releaseTokens() public {
        address _investor = msg.sender;
        require(whitelist[_investor] == true, 'El inversor debe estar dentro de la whitelist.');
        require(claimReady[_investor] <= block.timestamp, 'Debes esperar 1 semana desde la ultima vez que hiciste claim.');
        require(tokensSwapped[_investor] > 0, 'Debes tener tokens disponibles para retirar.');
        require(tokenV2.balanceOf(address(this)) >= balanceV2[_investor], 'No quedan suficientes TokensV2 en esta cuenta');
        require(claiming == false, 'Ya estas haciendo claim.');

        claiming = true;

        if(balanceV2[_investor] > 0) {
            uint withdrawableBalance = mulScale(tokensSwapped[_investor], 2500, 10000); // 2500 basis points = 25%.

            _triggerCooldown(_investor); // Se vuelve a inicializar el cooldown.

            tokenV2.transfer(_investor, withdrawableBalance); // Envía los TokensV2 desde la cuenta del contrato a la del usuario.

            balanceV2[_investor] -= withdrawableBalance;  // Actualiza el balance disponible para retirar del inversor.
        } else {
            tokensSwapped[_investor] = 0; // Resetea el balance del inversor a 0.
        }

        claiming = false;
    }

    /**
     * @notice Función que permite al dueño del contrato hacer el claim de todos los TokensV1 que hay dentro del contrato.
     */
    function claimV1() public onlyOwner {
        uint _v1amount = tokenV1.balanceOf(address(this));
        require(_v1amount > 0, 'No hay suficiente liquidez.');
        tokenV1.transfer(owner, _v1amount);
    }

    /**
     * @notice Función que permite al dueño del contrato hacer el claim de todos los TokensV2 que hay dentro del contrato.
     */
    function claimV2() public onlyOwner {
        uint _v2amount = tokenV2.balanceOf(address(this));
        require(_v2amount > 0, 'No hay suficiente liquidez.');
        tokenV1.transfer(owner, _v2amount);
    }

    /**
     * @notice Función que permite cambiar el dueño del contrato.
     * @param _owner Dirección del nuevo dueño.
     */
    function setOwner(address _owner) public onlyOwner {
        require(_owner != address(0), 'Debes introducir una direccion correcta.');
        owner = _owner;
    }

    /**
     * @notice Función que permite añadir inversores a la whitelist.
     * @param _investor Direcciones de los inversores que entran en la whitelist.
     */
    function addToWhitelist(address[] memory _investor) public onlyOwner {
        for (uint _i = 0; _i < _investor.length; _i++) {
            require(_investor[_i] != address(0), 'Debes introducir una direccion correcta.');
            address _investorAddress = _investor[_i];
            whitelist[_investorAddress] = true;
        }
    }

    /**
     * @notice Función que permite eliminar inversores de la whitelist.
     * @param _investor Direcciones de los inversores que salen de la whitelist.
     */
    function deleteFromWhitelist(address[] memory _investor) public onlyOwner {
        for (uint _i = 0; _i < _investor.length; _i++) {
            require(_investor[_i] != address(0), 'Debes introducir una direccion correcta.');
            address _investorAddress = _investor[_i];
            whitelist[_investorAddress] = false;
        }
    }

    /**
     * @notice Función que permite cambiar el supplyLimit.
     * @param _supplyLimit % del límite de supply de los TokensV2 para limitar al usuario.
     */
    function setSupplyLimit(uint _supplyLimit) public onlyOwner {
        supplyLimit = _supplyLimit;
    }
}