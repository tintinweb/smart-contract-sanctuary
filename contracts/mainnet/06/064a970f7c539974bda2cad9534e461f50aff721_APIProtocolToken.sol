// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "./IERC20.sol";
import "./Pausable.sol";
import "./SafeMath.sol";

contract APIProtocolToken is IERC20, Pausable {
  using SafeMath for uint256;

  mapping (address => uint256)  private balances;
  mapping (address => mapping (address => uint256))  private allowed;

  string public symbol;
  string public  name;
  uint256 public decimals;
  uint256 _totalSupply;

  constructor()  {
    symbol = "API";
    name = "APIProtocol Token";
    decimals = 18;

    _totalSupply = 10*(10**26);
    balances[owner] = _totalSupply;
    emit Transfer(address(0), owner, _totalSupply);
  }

  function totalSupply()   external view  override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address _owner)  external view override returns (uint256) {
    return balances[_owner];
  }

  function allowance(address _owner, address _spender)  external whenNotPaused view override returns (uint256) {
    return allowed[_owner][_spender];
  }

  function transfer(address _to, uint256 _value) public whenNotPaused override returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }


    function approve(address spender, uint256 amount) public  whenNotPaused virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

  

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused override returns (bool){
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  
}