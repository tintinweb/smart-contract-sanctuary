pragma solidity ^0.4.1;

// File: contracts/OwnerValidator.sol

contract TokenContract {
    function totalSupply() constant returns (uint256 supply);
    function decimals() constant returns(uint8 units);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, address _msgSender, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, address _msgSender, uint256 _value) returns (bool success);
    function transferFromSender(address _to, uint256 _value) returns (bool success);
    function approve(address _spender, address _msgSender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
}
contract OwnerValidator {
    function validate(address addr) constant returns (bool);
}

contract Owned {
    function ownerValidate(address addr) constant returns (bool);
    bool public isWorking;

    function Owned() {
        isWorking = true;
    }

    modifier onlyOwner {
        if (!ownerValidate(msg.sender)) throw;
        _;
    }

    modifier onlyWorking {
        if (!isWorking) throw;
        _;
    }

    modifier onlyNotWorking {
        if (isWorking) throw;
        _;
    }

    function setWorking(bool _isWorking) onlyOwner {
        isWorking = _isWorking;
    }
}

contract OwnerValidatorImpl is OwnerValidator, Owned {

    address[] public owners;


    TokenContract public tokenContract;

    function OwnerValidatorImpl() {
        owners.push(msg.sender);
    }


    function indexOfOwners(address _address) private constant returns (uint pos) {
        pos = 0;
        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] == _address) {
                pos = i + 1;
                break;
            }
        }
        return pos;                
    }

    function validate(address addr) constant returns (bool) {
        return (indexOfOwners(addr) != 0);
    }
        
    function getOwners() constant returns (address[]) {
        return owners;
    } 

    function addOwner(address addr) onlyWorking {
        if (validate(msg.sender)) {
            if (!validate(addr)) {
                owners.push(addr);
            }
        }
    }

    function removeOwner(address addr) onlyWorking {
        if (validate(msg.sender)) {
            uint pos = indexOfOwners(addr);
            if (pos > 0) {
                owners[pos - 1] = 0x0;
            }
        }
    }

    function setTokenContract(address _tokenContract) onlyWorking {
        if (validate(msg.sender)) {
            tokenContract = TokenContract(_tokenContract);
        }
    }

    function ownerValidate(address addr) constant returns (bool) {
        return validate(addr);
    }

    function transferFromSender(address _to, uint256 _value) returns (bool success) {
        if (!validate(msg.sender)) throw;
        return tokenContract.transferFromSender(_to, _value);
    }

    function sendFromOwn(address _to, uint256 _value) returns (bool success) {
        if (!validate(msg.sender)) throw;
        if (!_to.send(_value)) throw;
        return true;
    }
}

// File: contracts/OffChainManager.sol

contract OffChainManager {
    function isToOffChainAddress(address addr) constant returns (bool);
    function getOffChainRootAddress() constant returns (address);
}

contract OffChainManagerImpl is OffChainManager, Owned {
    address public rootAddress;
    address[] public offChainAddreses;

    mapping (address => uint256) refOffChainAddresses; 

    OwnerValidator public ownerValidator;

    TokenContract public tokenContract;

    function OffChainManagerImpl(
        address _rootAddress,
        address _ownerValidator
    ) {
        rootAddress = _rootAddress;
        ownerValidator = OwnerValidator(_ownerValidator);
    }

    function setRootAddress(address _address) onlyWorking {
        if (ownerValidator.validate(msg.sender)) {
            rootAddress = _address;
        }
    }

    function setOwnerValidatorAddress(address _ownerValidator) onlyWorking {
        if (ownerValidator.validate(msg.sender)) {
            ownerValidator = OwnerValidator(_ownerValidator);
        }
    }

    function setTokenContract(address _tokenContract) {
        if (ownerValidator.validate(msg.sender)) {
            tokenContract = TokenContract(_tokenContract);
        }
    }

    function offChainAddresesValidCount() constant returns (uint) {
        uint cnt = 0;
        for (uint i = 0; i < offChainAddreses.length; i++) {
            if (offChainAddreses[i] != 0) {
                cnt++;
            }
        }
        return cnt;
    }

    function addOffChainAddress(address _address) private {
        if (!isToOffChainAddress(_address)) {
            offChainAddreses.push(_address);
            refOffChainAddresses[_address] = offChainAddreses.length;
        }
    }

    function removeOffChainAddress(address _address) private {
        uint pos = refOffChainAddresses[_address];
        if (pos > 0) {
            offChainAddreses[pos - 1] = 0;
            refOffChainAddresses[_address] = 0x0;
        }
    }

    function addOffChainAddresses(address[] _addresses) onlyWorking {
        if (ownerValidator.validate(msg.sender)) {
            for (uint i = 0; i < _addresses.length; i++) {
                addOffChainAddress(_addresses[i]);
            }
        }
    }

    function removeOffChainAddresses(address[] _addresses) onlyWorking {
        if (ownerValidator.validate(msg.sender)) {
            for (uint i = 0; i < _addresses.length; i++) {
                removeOffChainAddress(_addresses[i]);
            }
        }
    }

    function ownerValidate(address addr) constant returns (bool) {
        return ownerValidator.validate(addr);
    }

    function transferFromSender(address _to, uint256 _value) returns (bool success) {
        if (!ownerValidator.validate(msg.sender)) throw;
        return tokenContract.transferFromSender(_to, _value);
    }

    function sendFromOwn(address _to, uint256 _value) returns (bool success) {
        if (!ownerValidator.validate(msg.sender)) throw; 
        if (!_to.send(_value)) throw;
        return true;
    }

    function isToOffChainAddress(address addr) constant returns (bool) {
        return refOffChainAddresses[addr] > 0;
    }

    function getOffChainRootAddress() constant returns (address) {
        return rootAddress;
    }

    function getOffChainAddresses() constant returns (address[]) {
        return offChainAddreses;
    } 

    function isToOffChainAddresses(address[] _addresses) constant returns (bool) {
        for (uint i = 0; i < _addresses.length; i++) {
            if (!isToOffChainAddress(_addresses[i])) {
                return false;
            }
        }
        return true;
    }
}

// File: contracts/TokenContract.sol

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
// assert(b > 0);
    uint256 c = a / b;
// assert(a == b * c + a % b);
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract TokenContractImpl is TokenContract, Owned {
    using SafeMath for uint256;
    string public standard = "Token 0.1";
    uint256 _totalSupply;
    uint8 _decimals;
    address public _mainAddress;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    OwnerValidator public ownerValidator;
    OffChainManager public offChainManager;

    bool public isRedenominated;
    uint256 public redenomiValue;
    mapping (address => uint256) public redenominatedBalances;
    mapping (address => mapping (address => uint256)) public redenominatedAllowed;

    function TokenContractImpl(
        uint256 initialSupply,
        uint8 decimals,
        address _ownerValidator,
        address _offChainManager
    ){
        balances[msg.sender] = initialSupply;
        _totalSupply = initialSupply;
        _decimals = decimals;
        ownerValidator = OwnerValidator(_ownerValidator);
        offChainManager = OffChainManager(_offChainManager);
    }

    function totalSupply() constant returns (uint256 totalSupply) {
        if (isRedenominated) {
            return redenominatedValue(_totalSupply);
        }
        return _totalSupply;
    }

    function decimals() constant returns (uint8 decimals) {
        return _decimals;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        if (isRedenominated) {
            if (redenominatedBalances[_owner] > 0) {
                return redenominatedBalances[_owner];
            }
            return redenominatedValue(balances[_owner]);
        }
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) constant returns (uint remaining) {
        if (isRedenominated) {
            if (redenominatedAllowed[_owner][_spender] > 0) {
                return redenominatedAllowed[_owner][_spender];
            }
            return redenominatedValue(allowed[_owner][_spender]);
        }
        return allowed[_owner][_spender];
    }

    function redenominatedValue(uint256 _value) private returns (uint256) {
        return _value.mul(redenomiValue);
    }

    function ownerValidate(address addr) constant returns (bool) {
        return ownerValidator.validate(addr);
    }


    function redenominate(uint256 _redenomiValue) {
        if (isRedenominated) throw;
        if (ownerValidator.validate(msg.sender)) {
            redenomiValue = _redenomiValue;
            Redenominate(msg.sender, isRedenominated, redenomiValue);
        }
    }   


    function applyRedenomination() onlyNotWorking {
        if (isRedenominated) throw;
        if (redenomiValue == 0) throw;
        if (ownerValidator.validate(msg.sender)) {
            isRedenominated = true;
            ApplyRedenomination(msg.sender, isRedenominated, redenomiValue);
        }
    }   

    function setOwnerValidatorAddress(address _ownerValidator) onlyWorking {
        if (ownerValidator.validate(msg.sender)) {
            ownerValidator = OwnerValidator(_ownerValidator);
        }
    }

    function setOffChainManagerAddress(address _offChainManager) onlyWorking {
        if (ownerValidator.validate(msg.sender)) {
            offChainManager = OffChainManager(_offChainManager);
        }
    }

    function transfer(address _to, address _msgSender, uint256 _value) onlyWorking returns (bool success) {
        if (msg.sender != _mainAddress) throw; 
        return transferProcess(_msgSender, _to, _value);
    }

    function transferProcess(address _from, address _to, uint256 _value) private returns (bool success) {
        if (balanceOf(_from) < _value) throw;
        subtractBalance(_from, _value);
        if (offChainManager.isToOffChainAddress(_to)) {
            addBalance(offChainManager.getOffChainRootAddress(), _value);
            ToOffChainTransfer(_from, _to, _to, _value);
        } else {
            addBalance(_to, _value);
        }
        return true;        
    }

    function addBalance(address _address, uint256 _value) private {
        if (isRedenominated) {
            if (redenominatedBalances[_address] == 0) {
                if (balances[_address] > 0) {
                    redenominatedBalances[_address] = redenominatedValue(balances[_address]);
                    balances[_address] = 0;
                }
            }
            redenominatedBalances[_address] = redenominatedBalances[_address].add(_value);
        } else {
            balances[_address] = balances[_address].add(_value);
        }
    }

    function subtractBalance(address _address, uint256 _value) private {
        if (isRedenominated) {
            if (redenominatedBalances[_address] == 0) {
                if (balances[_address] > 0) {
                    redenominatedBalances[_address] = redenominatedValue(balances[_address]);
                    balances[_address] = 0;
                }
            }
            redenominatedBalances[_address] = redenominatedBalances[_address].sub(_value);
        } else {
            balances[_address] = balances[_address].sub(_value);
        }
    }

    function transferFrom(address _from, address _to, address _msgSender, uint256 _value) onlyWorking returns (bool success) {
        if (msg.sender != _mainAddress) throw; 
        if (balanceOf(_from) < _value) throw;
        if (balanceOf(_to).add(_value) < balanceOf(_to)) throw;
        if (_value > allowance(_from, _msgSender)) throw;
        subtractBalance(_from, _value);
        if (offChainManager.isToOffChainAddress(_to)) {
            addBalance(offChainManager.getOffChainRootAddress(), _value);
            ToOffChainTransfer(_msgSender, _to, _to, _value);
        } else {
            addBalance(_to, _value);
        }
        subtractAllowed(_from, _msgSender, _value);
        return true;
    }


    function transferFromSender(address _to, uint256 _value) onlyWorking returns (bool success) {
        if (!transferProcess(msg.sender, _to, _value)) throw;
        TransferFromSender(msg.sender, _to, _value);
        return true;
    }


    function transferFromOwn(address _to, uint256 _value) onlyWorking returns (bool success) {
        if (!ownerValidator.validate(msg.sender)) throw;
        if (!transferProcess(this, _to, _value)) throw;
        TransferFromSender(this, _to, _value);    
        return true;
    }

    function sendFromOwn(address _to, uint256 _value) returns (bool success) {
        if (!ownerValidator.validate(msg.sender)) throw; 
        if (!_to.send(_value)) throw;
        return true;
    }

    function approve(address _spender, address _msgSender, uint256 _value) onlyWorking returns (bool success) {
        if (msg.sender != _mainAddress) throw; 
        setAllowed(_msgSender, _spender, _value);
        return true;
    }

    function subtractAllowed(address _from, address _spender, uint256 _value) private {
        if (isRedenominated) {
            if (redenominatedAllowed[_from][_spender] == 0) {
                if (allowed[_from][_spender] > 0) {
                    redenominatedAllowed[_from][_spender] = redenominatedValue(allowed[_from][_spender]);
                    allowed[_from][_spender] = 0;
                }
            }
            redenominatedAllowed[_from][_spender] = redenominatedAllowed[_from][_spender].sub(_value);
        } else {
            allowed[_from][_spender] = allowed[_from][_spender].sub(_value);
        }
    }

    function setAllowed(address _owner, address _spender, uint256 _value) private {
        if (isRedenominated) {
            redenominatedAllowed[_owner][_spender] = _value;
        } else {
            allowed[_owner][_spender] = _value;
        }
    }

    function setMainAddress(address _address) onlyOwner {
        _mainAddress = _address;
    }

    event TransferFromSender(address indexed _from, address indexed _to, uint256 _value);
    event ToOffChainTransfer(address indexed _from, address indexed _toKey, address _to, uint256 _value);
    event Redenominate(address _owner, bool _isRedenominated, uint256 _redenomiVakye);
    event ApplyRedenomination(address _owner, bool _isRedenominated, uint256 _redenomiVakye);
}

// File: contracts/MainContract.sol

contract MainContract {
    string public standard = "Token 0.1";
    string public name;
    string public symbol;

    OwnerValidator public ownerValidator;
    TokenContract public tokenContract;

    function MainContract(
        string _tokenName,
        address _ownerValidator,
        address _tokenContract,
        string _symbol
    ) {
        ownerValidator = OwnerValidator(_ownerValidator);
        tokenContract = TokenContract(_tokenContract);
        name = _tokenName;
        symbol = _symbol;
    }

    function totalSupply() constant returns(uint256 totalSupply) {
        return tokenContract.totalSupply();
    }

    function decimals() constant returns(uint8 decimals) {
        return tokenContract.decimals();
    }

    function setOwnerValidateAddress(address _ownerValidator) {
        if (ownerValidator.validate(msg.sender)) {
            ownerValidator = OwnerValidator(_ownerValidator);
        }
    }

    function setTokenContract(address _tokenContract) {
        if (ownerValidator.validate(msg.sender)) {
            tokenContract = TokenContract(_tokenContract);
        }
    }

    function transferFromSender(address _to, uint256 _value) returns (bool success) {
        if (!ownerValidator.validate(msg.sender)) throw;
        return tokenContract.transferFromSender(_to, _value);
    }

    function sendFromOwn(address _to, uint256 _value) returns (bool success) {
        if (!ownerValidator.validate(msg.sender)) throw; 
        if (!_to.send(_value)) throw;
        return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return uint256(tokenContract.balanceOf(_owner));
    }

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (tokenContract.transfer(_to, msg.sender, _value)) {
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            throw;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (tokenContract.transferFrom(_from, _to, msg.sender, _value)) {
            Transfer(_from, _to, _value);
            return true;
        } else {
            throw;
        }
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        if (tokenContract.approve(_spender,msg.sender,_value)) {
            Approval(msg.sender,_spender,_value);
            return true;
        } else {
            throw;
        }
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return tokenContract.allowance(_owner,_spender);
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}