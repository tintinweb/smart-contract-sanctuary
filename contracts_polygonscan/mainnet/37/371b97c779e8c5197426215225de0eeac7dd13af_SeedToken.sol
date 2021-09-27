/**
 *Submitted for verification at polygonscan.com on 2021-09-27
*/

// File: contracts/erc20/ERC20TokenInterface.sol

pragma solidity ^0.4.24;

contract ERC20TokenInterface {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    function balanceOf(address owner) public constant returns (uint256 balance);
    function transfer(address to, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);
    function allowance(address owner, address spender) public constant returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/erc20/ERC20.sol

pragma solidity ^0.4.24;


contract ERC20 is ERC20TokenInterface {
    uint256 constant MAX_UINT256 = 2**256 - 1;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    constructor(string _name, string _symbol, uint8 _decimals) internal {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = 0;
    }

    function balanceOf(address _owner) public constant returns (uint256) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_from] -= _value;
        balances[_to] += _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return allowed[_owner][_spender];
    }

    function _mint(address _to, uint256 _value) internal {
        balances[_to] += _value;
        totalSupply += _value;
        emit Transfer(address(0), _to, _value);
    }

    function _burn(address _from, uint256 _value) internal {
        require(_value <= balances[_from]);
        balances[_from] -= _value;
        totalSupply -= _value;
        emit Transfer(_from, address(0), _value);
    }
}

// File: contracts/erc20/ERC20Multisend.sol

pragma solidity ^0.4.24;


contract ERC20Multisend is ERC20 {
    function multisend(address[] _to, uint256[] _values) external {
        for (uint256 i = 0; i < _to.length; i++) {
            super.transfer(_to[i], _values[i]);
        }
    }
}

// File: contracts/privileged/Privileged.sol

pragma solidity ^0.4.24;

/**
 * Library to support managing and checking per-address privileges.
 */
contract Privileged {
  mapping (address => uint8) public privileges;
  uint8 internal rootPrivilege;

  constructor(uint8 _rootPrivilege) internal {
    rootPrivilege = _rootPrivilege;
    privileges[msg.sender] = rootPrivilege;
  }

  function grantPrivileges(address _target, uint8 _privileges) public requirePrivileges(rootPrivilege) {
    privileges[_target] |= _privileges;
  }

  function removePrivileges(address _target, uint8 _privileges) public requirePrivileges(rootPrivilege) {
    // May not remove privileges from self.
    require(_target != msg.sender);
    privileges[_target] &= ~_privileges;
  }

  modifier requirePrivileges(uint8 _mask) {
    require((privileges[msg.sender] & _mask) == _mask);
    _;
  }
}

// File: contracts/tokenretriever/TokenRetriever.sol

pragma solidity ^0.4.24;



/**
 * Used to retrieve ERC20 tokens that were accidentally sent to our contracts.
 */
contract TokenRetriever is Privileged {
  uint8 internal retrieveTokensFromContractPrivilege;

  constructor(uint8 _retrieveTokensFromContractPrivilege) internal {
    retrieveTokensFromContractPrivilege = _retrieveTokensFromContractPrivilege;
  }

  function invokeErc20Transfer(address _tokenContract, address _destination, uint256 _amount) external requirePrivileges(retrieveTokensFromContractPrivilege) {
      ERC20TokenInterface(_tokenContract).transfer(_destination, _amount);
  }
}

// File: contracts/seed/SeedToken.sol

pragma solidity ^0.4.24;





/**
 * 84cd5d54a21df1c1fe5129e6989381be057d26a4994f1bfc26593c1f8dd19f4b
 */

contract SeedToken is ERC20, ERC20Multisend, Privileged, TokenRetriever {
    // Privileges
    uint8 constant PRIV_ROOT = 1;

    constructor() public ERC20("SeedToken", "SEED", 0) Privileged(PRIV_ROOT) TokenRetriever(PRIV_ROOT) {
    }

    function mint(address _to, uint256 _value) external requirePrivileges(PRIV_ROOT) {
        _mint(_to, _value);
    }
}