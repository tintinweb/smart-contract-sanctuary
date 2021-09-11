/**
 *Submitted for verification at BscScan.com on 2021-09-11
*/

pragma solidity >=0.4.23 <0.6.0;

library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    if (a == 0) {
      return 0;
    }
    uint c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20 {
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId, string side, uint months, uint256 amount);
    event DirectPayout(uint indexed userId, uint indexed fromId, uint256 amount);
    event Invest(uint indexed userId, uint months, uint256 amount);
}

contract StandardToken is ERC20 {
    using SafeMath for uint;
    uint public totalSupply;
    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;

    function getSupply() public view returns (uint) {
        return totalSupply;
    }
    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }
    function transfer(address _to, uint _value) public returns (bool success) {
        require(balances[msg.sender] >= _value && _value > 0,"No Balance");
        require(_to != address(0));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0);
        require(_to != address(0));
        require(_from != address(0));
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        
        return true;
    }
    function approve(address _spender, uint _value) public returns (bool success) {
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) {
            revert();
        }
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }
}
contract EURT is StandardToken {
    using SafeMath for *;
    uint8 public decimals;
    string public constant name = "Euro One";
    string public constant symbol = "EURT";

    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        Deposit[] deposits;
    }
    struct Deposit {
		uint256 amount;
		uint256 start;
	}
    
    
    mapping(address => User) public users;
    mapping(uint => address) public userIds;
    
    uint public lastUserId = 2;
    uint256 public directBonusPer = 8;

    address public owner;
    address public deployer;
    address public implementation;

    modifier onlyDeployer() {
        require(msg.sender == deployer, "Only Deployer");
        _;
    }

    constructor(uint8 _decimals, uint _totalSupply, address ownerAddress) public {

        decimals = _decimals;
        totalSupply = _totalSupply * 10 ** uint(decimals);
        balances[ownerAddress] = balances[ownerAddress].add(totalSupply);

        emit Transfer(address(0), ownerAddress, totalSupply);

        owner = ownerAddress;
        deployer = msg.sender;

        User storage user = users[ownerAddress];
        
        user.id = 1;
        user.referrer = address(0);
        user.partnersCount = 0;

        userIds[1] = ownerAddress;
    }
    function () payable external {
        address impl = implementation;
        require(impl != address(0));
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)
            
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
    
    function upgradeTo(address _newImplementation) 
        external onlyDeployer 
    {
        require(implementation != _newImplementation);
        _setImplementation(_newImplementation);
    }
    function _setImplementation(address _newImp) internal {
        implementation = _newImp;
    }
    function getInvesments(address _addr) view external returns(uint256[] memory, uint[] memory) {
        uint256[] memory deposit_amount_i = new uint256[] (users[_addr].deposits.length);
        uint[] memory deposit_time_i = new uint256[] (users[_addr].deposits.length);

        for(uint8 i = 0; i < users[_addr].deposits.length; i++) {
            deposit_amount_i[i] = users[_addr].deposits[i].amount;
            deposit_time_i[i] = users[_addr].deposits[i].start;
        }

        return(deposit_amount_i, deposit_time_i);
    }
    
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}