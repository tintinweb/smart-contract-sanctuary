pragma solidity 0.4.25;
 
library SafeMathLib {
    // function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    //     if (a == 0) {
    //         return 0;
    //     }
    //     uint256 c = a * b;
    //     assert(c / a == b);
    //     return c;
    // }

    // function div(uint256 a, uint256 b) internal pure returns (uint256) {
    //     uint256 c = a / b;
    //     //assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    //     return c;
    // }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a >= b, "the result of the subtraction is negative");
        return(a - b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c>=a && c>=b);
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
    //     require(!(owner ==_newOwner));
    //     newOwner = _newOwner;
    // }
    // function acceptOwnership() public {
    //     require(msg.sender == newOwner);
    //     emit OwnershipTransferred(owner, newOwner);
    //     owner = newOwner;
    //     newOwner = address(0);
    // }
}


contract MyTocken is Owned{
    using SafeMathLib for uint256; 
   
   
    mapping (address => uint) public finaladdressof;
    mapping (address => mapping(address => uint)) public allowed;
    string public name;
    uint public decimal;
    string public symbol;
    uint public finalsupply;
   
    
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    
    constructor() public{
        name = "My First Tocken";
        decimal = 18;
        symbol = "Tocken";
        finalsupply = 1000000000000000000;
        finaladdressof[msg.sender]=finalsupply;
    }
    
     function totalSupply()public view returns (uint theTotalSupply){
         theTotalSupply = finalsupply;
         return theTotalSupply;
     }
    
    function balanceOf(address _owner)public view returns (uint balance){
        return finaladdressof[_owner];
    }
    
    function transfer(address _to, uint _value)public returns(bool success){
        require(_value>0 && _value<=balanceOf(msg.sender));
        
        finaladdressof[msg.sender]=finaladdressof[msg.sender].sub(_value);
        finaladdressof[_to]=finaladdressof[_to].add(_value);
        return true;
    }
    
    
    function approve(address _spender, uint _value)public returns (bool success){
        // require(_value >=0); 
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
   
    }
    
    function transferFrom(address _from, address _to,uint256 _value)public returns (bool success){
     
       require(allowed[_from][msg.sender] > 0 
            && _value > 0 
            && allowed[_from][msg.sender] >= _value 
            && finaladdressof[_from] >= _value);
            finaladdressof[_from]=finaladdressof[_from].sub(_value);
            finaladdressof[_to]=finaladdressof[_to].add(_value);
            
            //  finaladdressof[_from] -= _value;
            //  finaladdressof[_to] += _value;
            // Missed from the video
            allowed[_from][msg.sender] -= _value;
            return true;
    }
    
     
   function allowance(address _owner, address _spender)public view returns (uint remaining){
       return allowed[_owner][_spender];
   }
}