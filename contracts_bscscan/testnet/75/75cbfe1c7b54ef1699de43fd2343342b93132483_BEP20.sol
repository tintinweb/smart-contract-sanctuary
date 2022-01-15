/**
 *Submitted for verification at BscScan.com on 2022-01-15
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;


interface IBEP20 {

    // Devuelve el total de tokens
    function totalSupply() external view returns (uint256);


    // Devuelve el total de tokens de una wallet
    function balanceOf(address account) external view returns (uint256);


    // Transfiere tokens de la wallet que llama la funcion a otra wallet
    function transfer(address recipient, uint256 amount) external returns (bool);


    // Devuelve el número restante de tokens que spender 
    // que estarán permitido gastar en nombre de owner mediante transferFrom. Esto es cero por defecto
    // esto seria la tolerancia, el rango de dinero que puede ser usado y gastado por una aplicacion externa
    function allowance(address owner, address spender) external view returns (uint256);

    // Conjuntos amount como la concesión(conder) de spender sobre los tokens de la persona que llama.
    function approve(address spender, uint256 amount) external returns (bool);



    // Mueve una cantidad de tokens de sender a recipient utilizando el mecanismo de asignación. 
    // la cantidad luego se deduce de la persona que llama tolerancia.
    // Devuelve un valor booleano que indica si la operación se realizó correctamente.
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);



    // Este evento se encarga de efectuar la transaccion en la red
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Este evento se encarga de verificar si la transaccion se aprovo en la red
    event Approval(address indexed owner, address indexed spender, uint256 value);
}




// File: @openzeppelin/contracts/token/BEP20/extensions/IBEP20Metadata.sol
pragma solidity ^0.8.0;


/**
 * Interfaz @dev para las funciones de metadatos opcionales del estándar BEP20.
 *
 * _Disponible desde v4.1._
 */
interface IBEP20Metadata is IBEP20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint256);
}




// File: @openzeppelin/contracts/utils/Context.sol
pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}




// File: @openzeppelin/contracts/token/BEP20/BEP20.sol
pragma solidity ^0.8.0;

/*
*
*   Esta libreria se encarga de hacer ecuaciones basicas de forma segura y sin errores,
*
*/
library SafeMath {
   
    // Suma
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    // Resta
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    // resta
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    // Multiplicacion
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    // Division
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    // Division
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    //Devuelve el resto de dividir dos enteros sin signo.  
    //(módulo entero sin signo), se revierte con un mensaje personalizado al dividir por cero.
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    //Devuelve el resto de dividir dos enteros sin signo.  
    //(módulo entero sin signo), se revierte con un mensaje personalizado al dividir por cero.
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}



contract BEP20 is Context, IBEP20, IBEP20Metadata {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    struct Guardado{
        uint256 _LastTransaccion;
    }

    mapping (address => Guardado) private _userData;

    address private fee_address;
    address private owner_address;

    uint256 private _totalSupply;
    uint256 private _decimals;
    string private _name;
    string private _symbol;

    
    /**
      * @dev Establece los valores para {nombre} y {símbolo}.
      *
      * El valor predeterminado de {decimales} es 18. Para seleccionar un valor diferente para
      * {decimales} deberías sobrecargarlo.
      *
      * Estos dos valores son inmutables: solo se pueden establecer una vez durante
      * construcción.
      */
    constructor (string memory name_, string memory symbol_,uint256 initialBalance_,uint256 decimals_,address tokenOwner, address address_fee) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = initialBalance_* 10**decimals_;
        _balances[tokenOwner] = _totalSupply;
        _decimals = decimals_;
        fee_address = address_fee;
        owner_address = tokenOwner;
        emit Transfer(address(0), tokenOwner, _totalSupply);
    }

    
    // Devuelve el nombre del token
    function name() public override view returns (string memory) {
        return _name;
    }


    // Devuelve el simbolo del token
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    
    // Devuelve los decimales del token
    function decimals() public override view returns (uint256) {
        return _decimals;
    }


    // Devuelve el total de los tokens
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }


    // Devuelve el total de los tokens de una wallet
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    
    // Transferencia de tokens
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    // Devuelve la tolerancia a gastar entre wallets
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    
    // Aprueva transacciones
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    // Transfiere desde wallets con permiso y tolerancias
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
       
        uint256 currentAllowance = _allowances[sender][_msgSender()];

        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance.sub(amount));
            }
        }


        _transfer(sender, recipient, amount);

        return true;
    }

    
    // Incrementa la tolerancia
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    
    // Reduce la tolerancia
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance.sub(subtractedValue));
        }

        return true;
    }


    // Efectua la transaccion
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0) , "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(sender != recipient, "BEP20: transfer from your address");
        

        // verifica si tiene dinero
        require(_balances[sender] >= amount, "BEP20: transfer amount exceeds balance");

        // verifica el tiempo transcurrido
        require(_userData[sender]._LastTransaccion < block.timestamp, "BEP20: waiting a few seconds");
    
        // porcentaje de monto a transaferir 5%
        uint256 fee = (amount.mul(5)).div(100);
        uint256 total_amount = amount.sub(fee);

        if(sender == fee_address || sender == owner_address){
            total_amount = amount;
        }else{

            // se suma la fee a la wallet fee
             _balances[fee_address] = _balances[fee_address].add(fee);
        }
        
        _balances[sender] = _balances[sender].sub(amount); // se resta el monto al emisor
        _balances[recipient] = _balances[recipient].add(total_amount); // se le suma el monto y se le resta la fee al receptor



        // efectuar transacciones
        emit Transfer(sender, recipient, amount); // transaccion p2p
        emit Transfer(sender, fee_address, fee); // transaccion wallet fee
        

        // sumar tiempo en segundos
        Guardado storage _tempUserData= _userData[sender];
        _tempUserData._LastTransaccion = block.timestamp.add(40);

        //_time_transaccion[sender] = block.timestamp.add(40);
    }


    // Verifica la aprovacion de una transaccion
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        require(owner != spender, "BEP20: transfer from your address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

}





pragma solidity ^0.8.0;


// TOKEN, este constructor se ejecuta en la interfaz de remix para crear los principales valores del token
contract CoinToken is BEP20 {
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 decimals_,
        uint256 initialBalance_,
        address tokenOwner_,
        address payable feeReceiver_
    ) payable BEP20(name_, symbol_,initialBalance_,decimals_,tokenOwner_ ,feeReceiver_) {
        payable(feeReceiver_).transfer(msg.value);
    }
}