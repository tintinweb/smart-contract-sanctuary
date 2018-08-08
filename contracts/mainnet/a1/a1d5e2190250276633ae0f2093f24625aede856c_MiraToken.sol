pragma solidity ^0.4.24;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

  
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }


    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

interface ERC223Receiver {

    function tokenFallback(address _from, uint256 _value, bytes _data) external;

}


contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
    public view returns (uint256);

    function transferFrom(address from, address to, uint256 value)
    public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

}


contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);

        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
}


contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
  public
  returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(
    address _owner,
    address _spender
  )
  public
  view
  returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
  public
  returns (bool)
  {
    allowed[msg.sender][_spender] = (
    allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
  public
  returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


/**
 * MiraToken ERC223 token contract
 *
 * Designed and developed by BlockSoft.biz
 */

contract MiraToken is StandardToken, BurnableToken, Ownable {
    using SafeMath for uint256;

    event Release();
    event AddressLocked(address indexed _address, uint256 _time);
    event TokensReverted(address indexed _address, uint256 _amount);
    event AddressLockedByKYC(address indexed _address);
    event KYCVerified(address indexed _address);
    event TokensRevertedByKYC(address indexed _address, uint256 _amount);
    event SetTechAccount(address indexed _address);

    string public constant name = "MIRA Token";

    string public constant symbol = "MIRA";

    string public constant standard = "ERC223";

    uint256 public constant decimals = 8;

    bool public released = false;

    address public tokensWallet;
    address public techAccount;

    mapping(address => uint) public lockedAddresses;
    mapping(address => bool) public verifiedKYCAddresses;

    modifier isReleased() {
        require(released || msg.sender == tokensWallet || msg.sender == owner || msg.sender == techAccount);
        require(lockedAddresses[msg.sender] <= now);
        require(verifiedKYCAddresses[msg.sender]);
        _;
    }

    modifier hasAddressLockupPermission() {
        require(msg.sender == owner || msg.sender == techAccount);
        _;
    }

    constructor() public {
        owner = 0x635c8F19795Db0330a5b7465DF0BD2eeD1A5758e;
        tokensWallet = owner;
        verifiedKYCAddresses[owner] = true;

        techAccount = 0x41D621De050A551F5f0eBb83D1332C75339B61E4;
        verifiedKYCAddresses[techAccount] = true;
        emit SetTechAccount(techAccount);

        totalSupply_ = 30770000 * (10 ** decimals);
        balances[tokensWallet] = totalSupply_;
        emit Transfer(0x0, tokensWallet, totalSupply_);
    }

    function lockAddress(address _address, uint256 _time) public hasAddressLockupPermission returns (bool) {
        require(_address != owner && _address != tokensWallet && _address != techAccount);
        require(balances[_address] == 0 && lockedAddresses[_address] == 0 && _time > now);
        lockedAddresses[_address] = _time;

        emit AddressLocked(_address, _time);
        return true;
    }

    function revertTokens(address _address) public hasAddressLockupPermission returns (bool) {
        require(lockedAddresses[_address] > now && balances[_address] > 0);

        uint256 amount = balances[_address];
        balances[tokensWallet] = balances[tokensWallet].add(amount);
        balances[_address] = 0;

        emit Transfer(_address, tokensWallet, amount);
        emit TokensReverted(_address, amount);

        return true;
    }

    function lockAddressByKYC(address _address) public hasAddressLockupPermission returns (bool) {
        require(released);
        require(balances[_address] == 0 && verifiedKYCAddresses[_address]);

        verifiedKYCAddresses[_address] = false;
        emit AddressLockedByKYC(_address);

        return true;
    }

    function verifyKYC(address _address) public hasAddressLockupPermission returns (bool) {
        verifiedKYCAddresses[_address] = true;
        emit KYCVerified(_address);

        return true;
    }

    function revertTokensByKYC(address _address) public hasAddressLockupPermission returns (bool) {
        require(!verifiedKYCAddresses[_address] && balances[_address] > 0);

        uint256 amount = balances[_address];
        balances[tokensWallet] = balances[tokensWallet].add(amount);
        balances[_address] = 0;

        emit Transfer(_address, tokensWallet, amount);
        emit TokensRevertedByKYC(_address, amount);

        return true;
    }

    function release() public onlyOwner returns (bool) {
        require(!released);
        released = true;
        emit Release();
        return true;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function transfer(address _to, uint256 _value) public isReleased returns (bool) {
        if (released) {
            verifiedKYCAddresses[_to] = true;
        }

        if (super.transfer(_to, _value)) {
            uint codeLength;
            assembly {
                codeLength := extcodesize(_to)
            }
            if (codeLength > 0) {
                ERC223Receiver receiver = ERC223Receiver(_to);
                receiver.tokenFallback(msg.sender, _value, msg.data);
            }

            return true;
        }

        return false;
    }

    function transferFrom(address _from, address _to, uint256 _value) public isReleased returns (bool) {
        if (released) {
            verifiedKYCAddresses[_to] = true;
        }

        if (super.transferFrom(_from, _to, _value)) {
            uint codeLength;
            assembly {
                codeLength := extcodesize(_to)
            }
            if (codeLength > 0) {
                ERC223Receiver receiver = ERC223Receiver(_to);
                receiver.tokenFallback(_from, _value, msg.data);
            }

            return true;
        }

        return false;
    }

    function approve(address _spender, uint256 _value) public isReleased returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public isReleased returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public isReleased returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != owner);
        require(lockedAddresses[newOwner] < now);
        address oldOwner = owner;
        super.transferOwnership(newOwner);

        if (oldOwner != tokensWallet) {
            allowed[tokensWallet][oldOwner] = 0;
            emit Approval(tokensWallet, oldOwner, 0);
        }

        if (owner != tokensWallet) {
            allowed[tokensWallet][owner] = balances[tokensWallet];
            emit Approval(tokensWallet, owner, balances[tokensWallet]);
        }

        verifiedKYCAddresses[newOwner] = true;
        emit KYCVerified(newOwner);
    }

    function changeTechAccountAddress(address _address) public onlyOwner {
        require(_address != address(0) && _address != techAccount);
        require(lockedAddresses[_address] < now);

        techAccount = _address;
        emit SetTechAccount(techAccount);

        verifiedKYCAddresses[_address] = true;
        emit KYCVerified(_address);
    }

}