pragma solidity ^0.5.17;

import "../../lib/token/ERC20Detailed.sol";
import "../../lib/token/ERC20Mintable.sol";


contract ERC20Custom is ERC20Detailed, ERC20Mintable {
  constructor () ERC20Detailed("ERC20", "E20", 18)
    public
  {}
}

pragma solidity ^0.5.17;


interface IERC20Detailed {
    function name() external view returns (string memory _name);
    function symbol() external view returns (string memory _symbol);
    function decimals() external view returns (uint8 _decimals);
}

pragma solidity ^0.5.17;


interface IERC20 {
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  function totalSupply() external view returns (uint256 _supply);
  function balanceOf(address _owner) external view returns (uint256 _balance);

  function approve(address _spender, uint256 _value) external returns (bool _success);
  function allowance(address _owner, address _spender) external view returns (uint256 _value);

  function transfer(address _to, uint256 _value) external returns (bool _success);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool _success);
}

pragma solidity ^0.5.17;


import "./ERC20.sol";
import "../access/HasMinters.sol";

contract ERC20Mintable is HasMinters, ERC20 {
    function mint(address _to, uint256 _value) public onlyMinter returns (bool _success) {
        return _mint(_to, _value);
    }

    function _mint(address _to, uint256 _value) internal returns (bool success) {
        totalSupply = totalSupply.add(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(address(0), _to, _value);
        return true;
    }
}

pragma solidity ^0.5.17;

import "./ERC20.sol";
import "./IERC20Detailed.sol";

contract ERC20Detailed is ERC20, IERC20Detailed {
    string public name;
    string public symbol;
    uint8 public decimals;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
}

pragma solidity ^0.5.17;


import "./IERC20.sol";
import "../math/SafeMath.sol";

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    function approve(address _spender, uint256 _value) public returns (bool _success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool _success) {
        require(_to != address(0));
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool _success) {
        require(_to != address(0));
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
}

pragma solidity ^0.5.17;


library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    require(c >= a);
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
    require(b <= a);
    return a - b;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }

    c = a * b;
    require(c / a == b);
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Since Solidity automatically asserts when dividing by 0,
    // but we only need it to revert.
    require(b > 0);
    return a / b;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Same reason as `div`.
    require(b > 0);
    return a % b;
  }

  function ceilingDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
    return add(div(a, b), mod(a, b) > 0 ? 1 : 0);
  }

  function subU64(uint64 a, uint64 b) internal pure returns (uint64 c) {
    require(b <= a);
    return a - b;
  }

  function addU8(uint8 a, uint8 b) internal pure returns (uint8 c) {
    c = a + b;
    require(c >= a);
  }
}

pragma solidity ^0.5.17;

import "./HasAdmin.sol";

contract HasMinters is HasAdmin {
    event MinterAdded(address indexed _minter);
    event MinterRemoved(address indexed _minter);

    address[] public minters;
    mapping (address => bool) public minter;

    modifier onlyMinter {
        require(minter[msg.sender], "HasMinters: not minter");
        _;
    }

    function addMinters(address[] memory _addedMinters) public onlyAdmin {
        address _minter;

        for (uint256 i = 0; i < _addedMinters.length; i++) {
            _minter = _addedMinters[i];

            if (!minter[_minter]) {
                minters.push(_minter);
                minter[_minter] = true;
                emit MinterAdded(_minter);
            }
        }
    }

    function removeMinters(address[] memory _removedMinters) public onlyAdmin {
        address _minter;

        for (uint256 i = 0; i < _removedMinters.length; i++) {
            _minter = _removedMinters[i];

            if (minter[_minter]) {
                minter[_minter] = false;
                emit MinterRemoved(_minter);
            }
        }

        uint256 i = 0;

        while (i < minters.length) {
            _minter = minters[i];

            if (!minter[_minter]) {
                minters[i] = minters[minters.length - 1];
                delete minters[minters.length - 1];
                minters.length--;
            } else {
                i++;
            }
        }
    }

    function isMinter(address _addr) public view returns (bool) {
        return minter[_addr];
    }
}

pragma solidity ^0.5.17;


contract HasAdmin {
  event AdminChanged(address indexed _oldAdmin, address indexed _newAdmin);
  event AdminRemoved(address indexed _oldAdmin);

  address public admin;

  modifier onlyAdmin {
    require(msg.sender == admin, "only admin");
    _;
  }

  constructor() internal {
    admin = msg.sender;
    emit AdminChanged(address(0), admin);
  }

  function changeAdmin(address _newAdmin) external onlyAdmin {
    require(_newAdmin != address(0));
    emit AdminChanged(admin, _newAdmin);
    admin = _newAdmin;
  }

  function removeAdmin() external onlyAdmin {
    emit AdminRemoved(admin);
    admin = address(0);
  }
}