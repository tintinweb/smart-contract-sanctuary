/**
 *Submitted for verification at BscScan.com on 2021-07-15
*/

pragma solidity ^0.5.16;

/**
 * Una gran idea para las pools de staking seria que por cada pool, hay un contrato diferente
 * por ejemplo, creo la pool de BES/BNB, el contrato tendria una funcion que mira si la 
 * direccion del contrato del LP BES/BNB es igual a la que yo espero que sea, por ejemplo
 * si es igual al contrato de pancake o de Ape o de Kebab. Si lo dicho anteriormente se cumple,
 * a dicho usuario se le añade "allowance" mediante la funcion increaseAllowance, siendo la 
 * direccion "_from" = owner. para poder hacer esto hay que ejecutar primero la funcion 
 * increaseAllowance, en la cual se debera invertir algo de BNB para poder hacer esa allowance.
 * La funcion increaseAllowance sera llamada por otra dentro del contrato de la pool de ese LP,
 * por ejemplo increaseAllowanceLPBESBNB, en la que se creara una allowance entre yo, el owner y
 * aquel usuario que desea meterse en la pool.
 */

library SafeMath {
    /**
     * Function to plus 2 numbers
     * return de result of the plus of both numbers 
     */
    function add(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    
    /**
     * Function to substract 2 numbers
     * returns the result of substracting both numbers
     * B needs to be minor that A
     */
    function sub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    
    /**
     * Function to multiply 2 numbers
     * returns the result of the operation
     */
    function mul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    /**
     * Function to divide 2 numbers
     * B needs to be major than A
     * returns the result
     */
    function div(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () internal { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

contract IBEP20 {
    
    /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor () internal {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract BeSports is Ownable, IBEP20 {
    //we going to use SafeMath lib for uint's
    using SafeMath for uint256;
    
    //contract vars
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint private _totalSupply;
    uint private _circulationTokens;
    
    /**
     * balances of all BES holders
     */
    mapping(address => uint) private _balances;
    
    /**
     * allowed tokens of an address "to", from an owner of the token
     */
    mapping(address => mapping(address => uint)) private _allowed;
    
    /**
     * constructor of BES token
     */
    constructor() public {
        _name = "BeSports";
        _symbol = "BES";
        _decimals = 18;
        _totalSupply = 10 ** 10 * 10 ** 18;
        _balances[owner()] = _totalSupply;
        _circulationTokens = _totalSupply.sub(_balances[owner()]);
        emit Transfer(address(0),owner(),_totalSupply);
    }
    
    /**
     * function that returns the owner of the contract
     */
    function getOwner() external view returns (address){
        return owner();
    }
    
    /**
     * function that returns the symbol of the contract
     */
    function symbol() external view returns (string memory){
        return _symbol;
    }
    
    /**
     * function that returns the name of the token
     */
    function name() external view returns (string memory){
        return _name;
    }
    
    /**
     * function that returns the decimals of the token
     */
    function decimals() external view returns (uint8){
        return _decimals;
    }
    
    /**
     * function that returns the totalSupply
     * the function substract the tokens burned
     */
    function totalSupply() public view returns (uint256){
        return _totalSupply;
    }
    
    /**
     * function that returns the balance of BES of an address "owner"
     */
    function balanceOf(address _owner) public view returns (uint256 balance){
        return _balances[_owner];
    }
    
    /**
     * function that calls _transfer to transfer tokens to an
     * address "_to" from "msg.sender"
     */
    function transfer(address _to, uint256 _value) public returns (bool success){
        _transfer(msg.sender,_to,_value);
        emit Transfer(msg.sender,_to,_value);
        return true;
    }
    
    /**
     * function that make the transference of "_value" tokens from and address "_from"
     * to an address "_to"
     * both addresses needs to be different of the 0 address and
     * the balance of "_from" must be more than "_value" or equal 
     */
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0));
        require(_from != address(0));
        require(_balances[_from] >= _value);
        _balances[_from] = _balances[_from].sub(_value);
        _balances[_to] = _balances[_to].add(_value);
    }
    
    /**
     * function that an BES holder can use to let "_spender" take "_value" of his tokens
     */
    function approve(address _spender, uint256 _value) public returns (bool success){
        _approve(msg.sender, _spender, _value);
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    /**
     * the private function that approve calls
     */
    function _approve(address _from,address _spender, uint256 _value) internal {
        _allowed[_from][_spender] = _value;
    }
    
    /**
     * function that return the quantity of tokens that "_spender" can take from "_owner"
     */
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        require((msg.sender == _owner ) || (msg.sender == _spender));
        return _allowed[_owner][_spender];
    }
    
    /**
     * function that the address "_to" can use to get a quantity of "_value" of his allowed tokens from "_from"
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require((msg.sender == _to) && (_balances[msg.sender] >= _value) && (_allowed[_from][_to] >= _value));
        _allowed[_from][_to] = _allowed[_from][_to].sub(_value);
        _transfer(_from,_to,_value);
        emit Transfer(_from,_to,_value);
        return true;
    }
    
    /**
     * function to burn tokens, but only the owner can do it
     */
    function burn(uint _tokens) public onlyOwner returns (bool success){
        _transfer(owner(),address(0),_tokens);
        _totalSupply = _totalSupply.sub(_tokens);
        emit Transfer(owner(),address(0),_tokens);
        return true;
    }
    
    /**
     * function to increase allowance between the "msg.sender" and "_to"
     * saying how much tokens is going to increase the allowance
     * and run Approval event
     */
    function increaseAllowance(address _to, uint _value) public returns (bool success){
        require((_balances[msg.sender] >= _value) && (_allowed[msg.sender][_to] > 0));
        _allowed[msg.sender][_to] = _allowed[msg.sender][_to].add(_value);
        emit Approval(msg.sender,_to,_value);
        return true;
    }
    
    /**
     * function to increase allowance between the "msg.sender" and "_to"
     * saying how much tokens are going to decreace the allowance
     * and run Approval event 
     */
    function decreaceAllowance(address _to, uint _value) public returns (bool success){
        require((_balances[msg.sender] >= _value) && (_allowed[msg.sender][_to] > 0));
        _allowed[msg.sender][_to] = _allowed[msg.sender][_to].sub(_value);
        emit Approval(msg.sender,_to,_value);
        return true;
    }
    
    /**
     * function to create new tokens, that increase the totalSupply calling _mint
     * and emit Transfer event
     */
    function mint(uint _value) public onlyOwner returns (bool success) {
        _mint(_value);
        emit Transfer(address(0),owner(),_value);
        return true;
    }
    
    /**
     * the function which calls mint
     */
    function _mint(uint _value) internal {
        _balances[owner()] = _balances[owner()].add(_value);
        _totalSupply = _totalSupply.add(_value);
    }
    
    
}

contract StakeBESBNBpancake is BeSports {
    
}