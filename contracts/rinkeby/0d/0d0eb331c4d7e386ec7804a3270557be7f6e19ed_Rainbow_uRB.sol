pragma solidity 0.6.0;
import './ERC20.sol';
import './SafeMath.sol';
import './RoleManageContract.sol';

contract Rainbow_uRB is ERC20,RoleManageContract{

    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string  public  constant _name = "uRB-USDT";
    string  public  constant _symbol = "uRB";
    uint256 public  constant _decimals = 18; 

    //Automatic mint of reward module
    address public mintAddress;

    event Burn(address indexed _burner, uint256 _value);

    constructor() public {
        _balances[msg.sender] = 0;
        _totalSupply = 0;
        _owner = msg.sender;
        emit Transfer(address(0x0), msg.sender, 0);
    }

    /**
     * @dev See {ERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }


  function transfer(address _to, uint256 _value) public override returns (bool) {
    _balances[msg.sender] = _balances[msg.sender].sub(_value);
    _balances[_to] = _balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

    /**
     * @dev See {ERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

  function transferFrom(address _from, address _to, uint256 _value) public virtual override returns (bool) {
    uint256 allowance = _allowances[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    // KYBER-NOTE! code changed to comply with ERC20 standard
    _balances[_from] = _balances[_from].sub(_value);
    _balances[_to] = _balances[_to].add(_value);
    //balances[_from] = balances[_from].sub(_value); // this was removed
    _allowances[_from][msg.sender] = allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public virtual override returns (bool) {

    require((_value == 0) || (_allowances[msg.sender][_spender] == 0));

    _allowances[msg.sender][_spender] = _value;

    emit Approval(msg.sender, _spender, _value);
    return true;
  }



  function allowance(address _owner, address _spender) public view virtual override returns (uint256 remaining) {
    return _allowances[_owner][_spender];
  }
  
  
  /** @dev Creates `addedValue` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     */
    function mintTokenAmount(uint256 addedValue,address to) public onlyMint {
        require(addedValue > 0,"addedValue error !"); 
        require(to != address(0),"mintTokenAmount:to error !");
        _totalSupply = _totalSupply.add(addedValue);
        _balances[to] = _balances[to].add(addedValue);
        emit Transfer(address(0), to, addedValue);
    }

    //burn Toekn.
    function burnTokenAmount(uint256 burnValue,address from) public onlyMint {
      require(burnValue > 0,"burnTokenAmount:burnValue error !");
      require(_balances[from] >= burnValue,"burnTokenAmount:Insufficient balance !");
      _balances[from] = _balances[from].sub(burnValue, "burnTokenAmount:burn sub error !");
      _totalSupply = _totalSupply.sub(burnValue);
      emit Transfer(from, address(0), burnValue);
      emit Burn(from, burnValue);
    }

  
     /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
     
    function decimals() public pure returns (uint256) {
        return _decimals;
    }
  
     /**
     * @dev Returns the name of the token.
     */
     
    function name() public pure returns (string memory) {
        return _name;
    }

    /*
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
  
}