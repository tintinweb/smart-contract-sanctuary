// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../interfaces/Ownable.sol";

contract AlchemicaToken is IERC20, Ownable {
  string public name; // Returns the name of the token - e.g. "Generic ERC20".
  string public symbol; // Returns the symbol of the token. E.g. GEN20.
  uint8 public decimals; // Returns the number of decimals the token uses - e.g. 8, means to divide the token amount by 100000000 to get its user representation.

  uint256 public maxSupply;
  uint256 public override totalSupply; //Returns the total token supply.
  mapping(address => uint256) public override balanceOf; //Returns the account balance of another account with address _owner.
  mapping(address => mapping(address => uint256)) internal individualAllowance; // Mapping of allowance per owner/spender

  address public owner;

  modifier onlyOwner() {
    require(msg.sender == owner, "No access");
    _;
  }

  /// @notice Constructor
  /// @dev Please change the values in here if you want more specific values, or make the constructor takes arguments
  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _maxSupply,
    address _realmDiamond
  ) {
    name = _name;
    symbol = _symbol;
    maxSupply = _maxSupply;
    decimals = 18;
    owner = _realmDiamond;
  }

  /// @notice Transfer a _value amount of ERC token from msg.sender to _to
  /// Throw if msg.sender doesn't have enough tokens
  /// @param _to The address of the recipient
  /// @param _value The amount of token to send
  /// @return success true if success, throw if failed
  function transfer(address _to, uint256 _value) public override returns (bool success) {
    require(balanceOf[msg.sender] >= _value, "transfer: msg.sender balance is too low");
    balanceOf[msg.sender] = balanceOf[msg.sender] - _value;
    balanceOf[_to] = balanceOf[_to] + _value;
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /// @notice Transfer a _value amount of ERC token from _drom to _to.
  /// Only work if msg.sender == from or if msg.sender allowance < value
  /// Throw if _from doesn't have enough tokens
  /// @param _from The address of the account being removed tokens
  /// @param _to The address of the account being given tokens
  /// @param _value The amount of token to send
  /// @return success true if success, throw if failed
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) public override returns (bool success) {
    require(balanceOf[_from] >= _value, "transferFrom: _from balance is too low");
    require(individualAllowance[_from][msg.sender] >= _value || msg.sender == _from, "transferFrom: msg.sender allowance with _from is too low");
    if (msg.sender != _from) {
      individualAllowance[_from][msg.sender] = individualAllowance[_from][msg.sender] - _value;
    }
    balanceOf[_from] = balanceOf[_from] - _value;
    balanceOf[_to] = balanceOf[_to] + _value;
    emit Transfer(_from, _to, _value);
    return true;
  }

  /// @notice Approve an amount of token _spender can spend on behalf of msg.sender
  /// @param _spender The address of the account being approved for tokens
  /// @param _value The amount of token to be spent in total
  /// @return success true if success
  function approve(address _spender, uint256 _value) public override returns (bool success) {
    individualAllowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /// @notice get the approved amount of token _spender can spend on behalf of _owner
  /// @param _owner The address of the account being approved for tokens
  /// @param _spender The amount of token to be spent in total
  /// @return remaining the allowance of _spender on behalf of _owner
  function allowance(address _owner, address _spender) public view override returns (uint256 remaining) {
    return individualAllowance[_owner][_spender];
  }

  /// @notice Mint _value tokens for msg.sender
  /// @param _value Amount of tokens to mint
  function mint(uint256 _value) public onlyOwner {
    //For alchemica tokens the owner will be RealmDiamond
    balanceOf[msg.sender] = balanceOf[msg.sender] + _value;
    totalSupply += _value;
  }

  function transferOwnership(address _newOwner) external onlyOwner {
    owner = _newOwner;
  }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/// @title ERC20 interface
/// @dev https://github.com/ethereum/EIPs/issues/20
interface IERC20 {
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);

	function totalSupply() external view returns (uint256);
	function balanceOf(address who) external view returns (uint256);
	function allowance(address owner, address spender) external view returns (uint256);
	function transfer(address to, uint256 value) external returns (bool);
	function approve(address spender, uint256 value) external returns (bool);
	function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

interface Ownable {
    function owner() external returns(address); 
}