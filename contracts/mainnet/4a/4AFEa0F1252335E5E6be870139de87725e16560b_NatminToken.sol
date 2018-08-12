pragma solidity ^0.4.22;

//Math operations with safety checks that throw on error

library SafeMath {

    //multiply
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    //divide
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    //subtract
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    //addition
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public contractOwner;

    event TransferredOwnership(address indexed _previousOwner, address indexed _newOwner);

    constructor() public {        
        contractOwner = msg.sender;
    }

    modifier ownerOnly() {
        require(msg.sender == contractOwner);
        _;
    }

    function transferOwnership(address _newOwner) internal ownerOnly {
        require(_newOwner != address(0));
        contractOwner = _newOwner;

        emit TransferredOwnership(contractOwner, _newOwner);
    }

}

// Natmin vesting contract for team members
contract NatminVesting is Ownable {
    struct Vesting {        
        uint256 amount;
        uint256 endTime;
    }
    mapping(address => Vesting) internal vestings;

    function addVesting(address _user, uint256 _amount) public ;
    function getVestedAmount(address _user) public view returns (uint256 _amount);
    function getVestingEndTime(address _user) public view returns (uint256 _endTime);
    function vestingEnded(address _user) public view returns (bool) ;
    function endVesting(address _user) public ;
}

//ERC20 Standard interface specification
contract ERC20Standard {
    function balanceOf(address _user) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

//ERC223 Standard interface specification
contract ERC223Standard {
    function transfer(address _to, uint256 _value, bytes _data) public returns (bool success);
    event Transfer(address indexed _from, address indexed _to, uint _value, bytes _data);
}

//ERC223 function to handle incoming token transfers
contract ERC223ReceivingContract { 
    function tokenFallback(address _from, uint256 _value, bytes _data) public pure {
        _from;
        _value;
        _data;
    }
}

contract BurnToken is Ownable {
    using SafeMath for uint256;
    
    function burn(uint256 _value) public;
    function _burn(address _user, uint256 _value) internal;
    event Burn(address indexed _user, uint256 _value);
}

//NatminToken implements the ERC20, ERC223 standard methods
contract NatminToken is ERC20Standard, ERC223Standard, Ownable, NatminVesting, BurnToken {
    using SafeMath for uint256;

    string _name = "Natmin";
    string _symbol = "NAT";
    string _standard = "ERC20 / ERC223";
    uint256 _decimals = 18; // same value as wei
    uint256 _totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor(uint256 _supply) public {
        require(_supply != 0);
        _totalSupply = _supply * (10 ** 18);
        balances[contractOwner] = _totalSupply;
    }

    // Returns the _name of the token
    function name() public view returns (string) {
        return _name;        
    }

    // Returns the _symbol of the token
    function symbol() public view returns (string) {
        return _symbol;
    }

    // Returns the _standard of the token
    function standard() public view returns (string) {
        return _standard;
    }

    // Returns the _decimals of the token
    function decimals() public view returns (uint256) {
        return _decimals;
    }

    // Function to return the total supply of the token
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // Function to return the balance of a specified address
    function balanceOf(address _user) public view returns (uint256 balance){
        return balances[_user];
    }   

    // Transfer function to be compatable with ERC20 Standard
    function transfer(address _to, uint256 _value) public returns (bool success){
        bytes memory _empty;
        if(isContract(_to)){
            return transferToContract(_to, _value, _empty);
        }else{
            return transferToAddress(_to, _value, _empty);
        }
    }

    // Transfer function to be compatable with ERC223 Standard
    function transfer(address _to, uint256 _value, bytes _data) public returns (bool success) {
        if(isContract(_to)){
            return transferToContract(_to, _value, _data);
        }else{
            return transferToAddress(_to, _value, _data);
        }
    }

    // This function checks if the address is a contract or wallet
    // If the codeLength is greater than 0, it is a contract
    function isContract(address _to) internal view returns (bool) {
        uint256 _codeLength;

        assembly {
            _codeLength := extcodesize(_to)
        }

        return _codeLength > 0;
    }

    // This function to be used if the target is a contract address
    function transferToContract(address _to, uint256 _value, bytes _data) internal returns (bool) {
        require(balances[msg.sender] >= _value);
        require(vestingEnded(msg.sender));
        
        // This will override settings and allow contract owner to send to contract
        if(msg.sender != contractOwner){
            ERC223ReceivingContract _tokenReceiver = ERC223ReceivingContract(_to);
            _tokenReceiver.tokenFallback(msg.sender, _value, _data);
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }

    // This function to be used if the target is a normal eth/wallet address 
    function transferToAddress(address _to, uint256 _value, bytes _data) internal returns (bool) {
        require(balances[msg.sender] >= _value);
        require(vestingEnded(msg.sender));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }

    // ERC20 standard function
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(_value <= allowed[_from][msg.sender]);
        require(_value <= balances[_from]);
        require(vestingEnded(_from));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, _value);

        return true;
    }

    // ERC20 standard function
    function approve(address _spender, uint256 _value) public returns (bool success){
        allowed[msg.sender][_spender] = 0;
        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    // ERC20 standard function
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return allowed[_owner][_spender];
    }

    // Stops any attempt from sending Ether to this contract
    function () public {
        revert();
    }

    // public function to call the _burn function 
    function burn(uint256 _value) public ownerOnly {
        _burn(msg.sender, _value);
    }

    // Burn the specified amount of tokens by the owner
    function _burn(address _user, uint256 _value) internal ownerOnly {
        require(balances[_user] >= _value);

        balances[_user] = balances[_user].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        
        emit Burn(_user, _value);
        emit Transfer(_user, address(0), _value);

        bytes memory _empty;
        emit Transfer(_user, address(0), _value, _empty);
    }

    // Create a vesting entry for the specified user
    function addVesting(address _user, uint256 _amount) public ownerOnly {
        vestings[_user].amount = _amount;
        vestings[_user].endTime = now + 180 days;
    }

    // Returns the vested amount for a specified user
    function getVestedAmount(address _user) public view returns (uint256 _amount) {
        _amount = vestings[_user].amount;
        return _amount;
    }

    // Returns the vested end time for a specified user
    function getVestingEndTime(address _user) public view returns (uint256 _endTime) {
        _endTime = vestings[_user].endTime;
        return _endTime;
    }

    // Checks if the venting period is over for a specified user
    function vestingEnded(address _user) public view returns (bool) {
        if(vestings[_user].endTime <= now) {
            return true;
        }
        else {
            return false;
        }
    }

    // Manual end vested time 
    function endVesting(address _user) public ownerOnly {
        vestings[_user].endTime = now;
    }
}