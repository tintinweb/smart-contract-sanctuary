pragma solidity 0.4.25;

// import "browser/erc20testing.sol";
// interface erc20 {
    
//     function totalSupply() external view returns (uint _totalsupply); 
//     function balanceOf(address owner)external view returns (uint balance);
//     function transfer(address _to, uint _value)external  returns (bool success);
//     function allowance(address _owner, address _spender) external view returns (uint remaining);
//     function transferFrom(address _from, address _to, uint _value) external view returns (bool success);
//     function approve(address _spender, uint _value) external view returns (bool success);
//     event Approval(address indexed _owner, address indexed _spender, uint _value);
//      event Transfer(address indexed _from, address indexed _to, uint _value);
// }
library SafeMathlib {
    // function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    //     if (a == 0) {
    //         return 0;
    //     }
    //     uint256 c = a * b;
    //     assert(c / a == b);
    //     return c;
    // }

    // function div(uint256 a, uint256 b) internal pure returns (uint256) {
    //     // assert(b > 0); // Solidity automatically throws when dividing by 0
    //     uint256 c = a / b;
    //     // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    //     return c;
    // }

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

contract Owned {
    address public owner;
    // address public newOwner;
    // event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    // function transferOwnership(address _newOwner) public onlyOwner {
    //     newOwner = _newOwner;
    // }
    // function acceptOwnership() public {
    //     require(msg.sender == newOwner);
    //     emit OwnershipTransferred(owner, newOwner);
    //     owner = newOwner;
    //     newOwner = address(0);
    // }
}



//Dont use Token keyword while creating the contract otherwise exception will be thrown
contract myfirst is Owned{
    using  SafeMathlib for uint256;
    
    string public  symbol;
    string public  name;
    uint256 public  decimals;
    uint256 public  totalsupply;
    address public owner;
    mapping (address => uint) public __balanceof;    
    mapping (address => mapping (address => uint256)) public allowed;
    
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    
    constructor() public {
        symbol = "MFT";
        name = "My First Token";
        decimals  = 18;
        totalsupply = 10000000000000000000; 
        __balanceof[msg.sender] = totalsupply; 
        owner = msg.sender;
    }
    
    function totalSupply() public view returns (uint256){
        uint256 _totalsupply;
        _totalsupply = totalsupply;
        return _totalsupply;
    }
    
    function balanceOf(address _owner)public view returns (uint256 balance){
      require(_owner == msg.sender);
        return __balanceof[_owner];
    }
    
    function transfer(address _to, uint _value) public returns(bool success){
        require(_value > 0 && _value <= balanceOf(msg.sender));
        __balanceof[msg.sender] = __balanceof[msg.sender].sub(_value);
         __balanceof[_to] = __balanceof[_to].add(_value);
         return true;
    }
    
     function approve(address _spender, uint256 _value) public returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender,_spender,_value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require (allowed[_from][msg.sender] > 0 
            && _value > 0 
            && allowed[_from][msg.sender] >= _value &&
            __balanceof[_from] >= _value );
            __balanceof[_from] = __balanceof[_from].sub(_value);
            __balanceof[_to] = __balanceof[_to].add(_value);
            allowed[_from][msg.sender] =allowed[_from][msg.sender].sub(_value);
            return true;
    }
    function allowance(address _owner, address _spender) public view returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
        
    }
   
}