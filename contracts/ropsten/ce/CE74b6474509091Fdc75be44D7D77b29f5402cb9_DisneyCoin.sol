/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
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

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
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

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: 01. Proyectos de Aplicacion/04. Sistema de Tokens de Disney/disney.sol


pragma solidity ^0.8.0;


// @dev Desarrollado entre el 23-01-2022 y el 24-01-2022 por @liorabadi basado en 
// Curso Smart Contracts y Blockchain con Solidity de la A a la Z de Udemy.

// Contract Ropstenaddress: 0xCE74b6474509091Fdc75be44D7D77b29f5402cb9


contract DisneyCoin is ERC20  {

    // ---------------------------- DECLARACIONES INICIALES -----------------------------------
    // Direccion de Disney
    address public owner;
    address public contractAdreess = address(this);
    uint public ContractEthBalance = contractAdreess.balance;
    
    constructor(uint _initialSupply) ERC20("DisneyCoin", "DSNYC") {
         owner = msg.sender;
        _mint(address(this), _initialSupply * 10 ** decimals());
    }

    // Estructura de datos para almacenar a los clientes.
    struct cliente{
        uint balance_tokens;
        string[] atracciones_disfrutadas;
    }

    // Mapping para registro de clientes
    mapping(address => cliente) public Clientes;

    
    modifier soloDisney() {
        require(msg.sender == owner, "No sos parte de Disney");
        _;
    }

    // Resign Ownership
    address lastOwner;
    function newOwnership(address _newOwnerAddress) public soloDisney(){
        lastOwner = owner;
        owner = _newOwnerAddress;
    }

    // ---------------------------- GESTION DE TOKENS ----------------------------------------

    // Determinar precio de un token. Tres decimales.
    uint public tokenPrice;
    function setPrecioToken(uint newPrice) public soloDisney(){
       //Conv "ideal" de tokens a ethers. 1 Token = 1 Ether. (Como dijo Carlitos Maul). Se deberia poner newPrice = 100 tal que tokenPrice 1 ether.
        tokenPrice = newPrice * 10**16 wei; 
    }

    // Relacion de precio entre DisneyCoin y Ethers. Output de funcion en WEI.
    function PrecioTokens(uint _numTokens) internal view returns(uint){
        require(tokenPrice != 0, "Disney debe determinar un costo de token.");

        return _numTokens* tokenPrice;        
    }



    // Testeo unidades de Ether de balance de sender --> da 0, ergo, es el balance del ERC20 custom token.
    /* function balanceEth() public view returns(uint){
        return balanceOf(msg.sender);
    }
    */

    /* Testeo unidades de Ether de balance de sender --> da 99999999999995178672, ergo, es el balance en WEI de la wallet que llama la function.
    function balanceEth() public view returns(uint){
    return msg.sender.balance;
    }
    */
      

   
    // Comprar de tokens en Disney (Ether ---> Tokens)
    function compraTokens(uint _numTokens) public payable {
        // Establecer precio de tokens con funcion creada.
        uint coste = PrecioTokens(_numTokens); // Coste en WEI.

        // Evaluar si el que quiere comprar tiene suficientes ethers.
        require ( msg.value >= coste, "Ethers insuficientes para comprar los tokens deseados.");

        // Se debe controlar el balance de tokens disponibles
        uint balanceDisney = balanceOf(address(this));
        require (_numTokens * 10 ** decimals() <= balanceDisney, "Disney no tiene suficientes tokens disponibles.");
        
        // Diferencia entre costo y pago.
        uint returnExcess = msg.value - coste;
        payable(msg.sender).transfer(returnExcess);
        

        // Se tranfiere la cantidad de DisneyTokens al cliente.
        _transfer(address(this), msg.sender, _numTokens * 10 ** decimals());

        // Registro de balance de tokens en sistema interno.
        Clientes[msg.sender].balance_tokens += _numTokens * 10 ** decimals();
    }

    // Ver Numero restante de tokens de un cliente.
    function MisTokens() public view returns (uint){
        return balanceOf(msg.sender);
    }
    
    // Inyectar mas tokens al mercado
    function InyectarTokens(uint _incrementoSupply) public soloDisney() {
        _mint(address(this), _incrementoSupply * 10 ** decimals());
    }

    // Quemar DisneyTokens del contrato
    function QuemarTokens(uint _cantidadQuemar) public soloDisney() {
        _burn(address(this), _cantidadQuemar * 10 ** decimals());
    }

    // ---------------------------- GESTION DE DISNEY ----------------------------------------
    event disfruta_atraccion(string);
    event disfruta_local(string);
    event nueva_atraccion(string);
    event nuevo_local(string);
    event CierreLocal(string);
    event CierreAtraccion(string);
    event AperturaLocal(string);
    event AperturaAtraccion(string);

    // Atracciones
    struct atraccion{
        string nombre_atraccion;
        uint precio_atraccion;
        bool atraccionAbierta;
    }
    // Comida
    struct local{
        string nombre_local;
        uint precio_item;
        bool localAbierto;
    }

    // Relacion de nombre de atraccion con sus datos.
    mapping (string => atraccion) MappingAtracciones;
    mapping (string => local)  MappingLocales;

    // Listado de atracciones y locales.
    string [] Atracciones;
    string [] Locales;

    // Relacion entre direcciones de CLIENTES con las atracciones visitadas y comidas.
    mapping (address => string []) HistorialAtracciones;
    mapping (address => string []) HistorialLocales;

    // Cada atraccion tiene su costo en tokens
    // Space Mountain -- 10 tokens
    // Splash Mountain -- 10 tokens
    // Peter's Pan Flight -- 8 tokens
    // BuzzLightyear -- 5 tokens

    // Cada Local tiene su costo en tokens
    // Gorros -- 3 tokens
    // Paraguas -- 5 tokens
    // Protector Solar -- 8 tokens
    // Globo -- 1 token

    // Dar de alta atracciones en el parque
    function altaAtraccion(string memory _nombre, uint _precio, bool _abierto) public soloDisney(){
                
        MappingAtracciones[_nombre] = atraccion(_nombre, _precio *10**decimals() , _abierto);
        Atracciones.push(_nombre);
        emit nueva_atraccion(_nombre);
    }

        // Dar de alta Locales en el parque
    function altaLocal(string memory _nombreLocal, uint _precio, bool _abierto) public soloDisney(){
                
        MappingLocales[_nombreLocal] = local(_nombreLocal, _precio *10**decimals() , _abierto);
        Locales.push(_nombreLocal);
        emit nuevo_local(_nombreLocal);
    }

        // Cambiar estado de un Local
    function AbrirCerrarLocal(string memory _nombreLocal) public soloDisney(){
        if(MappingLocales[_nombreLocal].localAbierto == false){
            MappingLocales[_nombreLocal].localAbierto = true;
            emit AperturaLocal(_nombreLocal);

        }else{
            MappingLocales[_nombreLocal].localAbierto = false;
            emit CierreLocal(_nombreLocal);
        }
              
    }

    // Cambiar estado de una atraccion
    function AbrirCerrarAtraccion(string memory _nombre) public soloDisney(){
        if(MappingAtracciones[_nombre].atraccionAbierta == false){
            MappingAtracciones[_nombre].atraccionAbierta = true;
            emit AperturaAtraccion(_nombre);

        }else{
            MappingAtracciones[_nombre].atraccionAbierta = false;
            emit CierreAtraccion(_nombre);
        }
              
    }

    // Ver estado de una atraccion
    function estadoAtraccion(string memory _nombre) public view returns(string memory){
        string memory estadoAux;
        if(MappingAtracciones[_nombre].atraccionAbierta == true){
            estadoAux = "La atraccion se encuentra abierta.";
        }else{
            estadoAux = "La atraccion se encuentra cerrada.";
        }
        return estadoAux;
    }

        // Ver estado de un Local
    function estadoLocal(string memory _nombre) public view returns(string memory){
        string memory estadoAux;
        if(MappingLocales[_nombre].localAbierto == true){
            estadoAux = "El local se encuentra abierto.";
        }else{
            estadoAux = "El local se encuentra cerrado.";
        }
        return estadoAux;
    }

    // Ver atracciones     
    function ListadoAtracciones() public view returns(string[] memory){
       return(Atracciones);
    }

    // Ver Locales     
    function ListadoLocales() public view returns(string[] memory){
       return(Locales);
    }

    // Pagar para comprar algo en un local
    function compraLocal(string memory _nombreLocal, uint _cantidad) public returns(string memory, uint){
        local memory localActual = MappingLocales[_nombreLocal];
        
        uint cantTokensTotales = localActual.precio_item * _cantidad;
        
        // Chequear que la atraccion este abierta.
        require(localActual.localAbierto == true, "El local  se encuentra cerrado en este momento.");

        // Mensaje prolijo para informarle que no tiene tokens.
        require( MisTokens() >= cantTokensTotales, "No tenes suficientes tokens para comprar.");

        // Se paga a Disney (contract) por la atraccion. El chequeo del balance disponible lo realiza ERC20 contract.
        _transfer(msg.sender, address(this), cantTokensTotales);

        // Registro de balance de tokens en sistema interno.
        Clientes[msg.sender].balance_tokens -= cantTokensTotales;

        // Registrar atraccion disfrutada.
        HistorialLocales[msg.sender].push(_nombreLocal);

        emit disfruta_local(_nombreLocal);

        return("Que lo disfrutes! Te quedan disponible los siguientes tokens: ", Clientes[msg.sender].balance_tokens);

    }

    // Pagar para subirse a una atraccion
    function subirseAtraccion(string memory _nombreAtraccion, uint _cantidadPersonas) public returns(string memory, uint){
        atraccion memory atraccionActual = MappingAtracciones[_nombreAtraccion];
        uint cantTokensTotales = atraccionActual.precio_atraccion * _cantidadPersonas;
        
        // Chequear que la atraccion este abierta.
        require(atraccionActual.atraccionAbierta == true, "La atraccion se encuentra cerrada en este momento.");

        // Mensaje prolijo para informarle que no tiene tokens.
        require( MisTokens() >= cantTokensTotales, "No tenes suficientes tokens para subir a la atraccion.");

        // Se paga a Disney (contract) por la atraccion. El chequeo del balance disponible lo realiza ERC20 contract.
        _transfer(msg.sender, address(this), cantTokensTotales);

        // Registro de balance de tokens en sistema interno.
        Clientes[msg.sender].balance_tokens -= cantTokensTotales;

        // Registrar atraccion disfrutada.
        HistorialAtracciones[msg.sender].push(_nombreAtraccion);

        emit disfruta_atraccion(_nombreAtraccion);

        return("Disfruta la atraccion. Te quedan disponible los siguientes tokens: ", Clientes[msg.sender].balance_tokens);

    }

    // Ver historial de atracciones de Cliente
    function historialAtracciones() public view returns(string[] memory){
        return (HistorialAtracciones[msg.sender]);
    }

        // Ver historial de Local de Cliente
    function historialLocal() public view returns(string[] memory){
        return (HistorialLocales[msg.sender]);
    }

    // Devolver tokens al visitante cuando se retira del parque (Tokens ---> Ether)
    function devolverTokens(uint _numTokens) public payable returns(string memory){
        require(MisTokens() >= _numTokens *10*decimals(), "No es posible devolver una cantidad mayor a la disponible.");
        require(contractAdreess.balance >= PrecioTokens(_numTokens), "Disney no posee suficientes ETH para devolver lo deseado.");

        //Se realizan la transferencias de tokens.
        _transfer(msg.sender,address(this), _numTokens*10**decimals());
        // Se restituyen los ethers
        payable(msg.sender).transfer(PrecioTokens(_numTokens));        

        return "Se han restituido los ethers correspondientes.";

    }



}