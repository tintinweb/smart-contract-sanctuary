pragma solidity ^0.4.21;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        assert(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);

        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);

        return c;
    }
}
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
contract StandardToken is ERC20, BasicToken {
    mapping(address => mapping (address => uint256)) internal allowed;

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
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

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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



contract Ownable {
    address public owner;
    address public ownerCandidate;
    address[4] public admins;
    uint256 public ownershipTransferCounter;

    constructor(address _owner, address[4] _admins) public {
        owner = _owner;
        admins[0] = _admins[0];
        admins[1] = _admins[1];
        admins[2] = _admins[2];
        admins[3] = _admins[3];
    }

    function changeAdmin(address _oldAdmin, address _newAdmin, bytes32[3] _rs, bytes32[3] _ss, uint8[3] _vs) external returns (bool) {
        bytes32 prefixedMessage = prefixedHash(transferAdminMessage(_oldAdmin, _newAdmin));
        address[3] memory signers;

        for (uint8 i = 0; i < 3; i++) {
            signers[i] = ecrecover(prefixedMessage, _vs[i], _rs[i], _ss[i]);
        }

        require (isQuorum(signers));

        return replaceAdmin(_oldAdmin, _newAdmin);
    }

    function transferOwnership(address _newOwner, bytes32[3] _rs, bytes32[3] _ss, uint8[3] _vs) external returns (bool) {
        bytes32 prefixedMessage = prefixedHash(transferOwnershipMessage(_newOwner));
        address[3] memory signers;

        for (uint8 i = 0; i < 3; i++) {
            signers[i] = ecrecover(prefixedMessage, _vs[i], _rs[i], _ss[i]);
        }

        require (isQuorum(signers));

        ownerCandidate = _newOwner;
        ownershipTransferCounter += 1;

        return true;
    }

    function confirmOwnership() external returns (bool) {
        require (msg.sender == ownerCandidate);

        owner = ownerCandidate;

        return true;
    }

    function transferOwnershipMessage(address _candidate) public view returns (bytes32) {
        return keccak256(address(this), _candidate, ownershipTransferCounter);
    }

    function transferAdminMessage(address _oldAdmin, address _newAdmin) public view returns (bytes32) {
        return keccak256(address(this), _oldAdmin, _newAdmin);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function prefixedHash(bytes32 hash) pure public returns (bytes32) {
        return keccak256("\x19Ethereum Signed Message:\n32", hash);
    }

    function replaceAdmin (address _old, address _new) internal returns (bool) {
        require (_new != address(0));
        require (!isAdmin(_new));

        for (uint8 i = 0; i < admins.length; i++) {
            if (admins[i] == _old) {
                admins[i] = _new;

                return true;
            }
        }

        require (false);
    }

    function isAdmin (address _a) public view returns (bool) {
        for (uint8 i = 0; i < admins.length; i++) {
            if (admins[i] == _a) {
                return true;
            }
        }

        return false;
    }

    function isQuorum(address[3] signers) public view returns (bool) {
        if (signers[0] == signers[1] || signers[0] == signers[2] || signers[1] == signers[2])
        {
            return false;
        }

        for (uint8 i = 0; i < signers.length; i++) {
            if (signers[i] == address(0)) {
                return false;
            }

            if (!isAdmin(signers[i])) {
                return false;
            }
        }

        return true;
    }
}
contract OwnedToken is StandardToken, Ownable {
    constructor (address _owner, address[4] _admins) public Ownable(_owner, _admins) {
    }

    function confirmOwnership () external returns (bool) {
        require (msg.sender == ownerCandidate);

        balances[ownerCandidate] += balances[owner];

        delete balances[owner];

        owner = ownerCandidate;

        return true;
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

contract PausableToken is StandardToken, Pausable {
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

contract CollectableToken is PausableToken {
    mapping(address => uint256) nextNonce;

    event Collected(address indexed from, address indexed to, address indexed collector, uint256 value);

    function collectMessage(address _from, address _to, uint256 _value) public view returns (bytes32) {
        return keccak256(address(this), _from, _to, _value, nextNonce[_from]);
    }

    function isCollectSignatureCorrect(address _from, address _to, uint256 _value, bytes32 _r, bytes32 _s, uint8 _v) public view returns (bool) {
        return _from == ecrecover(
            prefixedHash(collectMessage(_from, _to, _value)),
            _v, _r, _s
        );
    }

    function collect(address _from, address _to, uint256 _value, bytes32 _r, bytes32 _s, uint8 _v) public whenNotPaused returns (bool success) {
        require (_value > 0);
        require (_from != _to);
        require (_to != address(0));
        require (isCollectSignatureCorrect(_from, _to, _value, _r, _s, _v));

        nextNonce[_from] += 1;
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(_from, _to, _value);
        emit Collected(_from, _to, msg.sender, _value);

        return true;
    }
}
contract BixtrimToken is CollectableToken, OwnedToken {
    string public constant name = "BixtrimToken";
    string public constant symbol = "BXM";
    uint256 public constant decimals = 0;

    constructor (uint256 _total, address _owner, address[4] _admins) public OwnedToken(_owner, _admins) {
        totalSupply_ = _total;
        balances[_owner] = _total;
    }
}