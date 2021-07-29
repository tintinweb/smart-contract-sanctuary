/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

pragma solidity ^0.8.4;

library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  function add(Role storage role, address account) internal {
    require(account != address(0));
    role.bearer[account] = true;
  }

  function remove(Role storage role, address account) internal {
    require(account != address(0));
    role.bearer[account] = false;
  }

  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

pragma solidity ^0.8.4;

contract MinterRole {
  using Roles for Roles.Role;

  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);

  Roles.Role private minters;

  constructor() public {
    _addMinter(msg.sender);
  }

  modifier onlyMinter() {
    require(isMinter(msg.sender));
    _;
  }

  function isMinter(address account) public view returns (bool) {
    return minters.has(account);
  }

  function addMinter(address account) public onlyMinter {
    _addMinter(account);
  }

  function _addMinter(address account) internal {
    minters.add(account);
    emit MinterAdded(account);
  }

}

pragma solidity ^0.8.4;

contract ERC20 is MinterRole {
    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint256 public tokensPerBlock;
    uint256 public lastMintedBlockNumber;
    

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    constructor() public {
        totalSupply = 250000;
        name = "Mintable Erc20";
        symbol = "Merc";
        lastMintedBlockNumber = block.number;
        tokensPerBlock = 1;
        balanceOf[msg.sender] = totalSupply;
    }
    
    function mint() external onlyMinter returns (bool success) {
        uint256 currentBlockNumber = block.number;
        uint256 mtoken = tokensPerBlock*(currentBlockNumber - lastMintedBlockNumber);
        totalSupply += mtoken;
        return true;
        
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[msg.sender]);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
 
        return true;
    }
}