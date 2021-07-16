//SourceUnit: CPLUS Smart Contract.sol

pragma solidity ^0.4.25;


// ----------------------------------------------------------------------------
// 'CPLUS' token contract
//
// Name        : CPLUS TOKEN
// Symbol      : CPLUS
// Total supply: 180000000
// Decimals    : 8
//
// ----------------------------------------------------------------------------

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
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c>=a && c>=b);
        return c;
    }
}


contract Ownable {
    
    address public owner;
    
     constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
}


contract CPLUS is Ownable{

    using SafeMath for uint;
    string public name;     
    string public symbol;
    uint8 public decimals;  
    uint private _totalSupply;
    uint public basisPointsRate = 0;
    uint public minimumFee = 0;
    uint public maximumFee = 0;

    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );
    
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    
    event Params(
        uint feeBasisPoints,
        uint maximumFee,
        uint minimumFee
    );
    
    event Issue(
        uint amount
    );

    event Redeem(
        uint amount
    );
    

    constructor () public {
        name = 'CPLUS TOKEN'; 
        symbol = 'CPLUS'; 
        decimals = 8; 
        _totalSupply = 180000000 * 10**uint(decimals); 
        balances[msg.sender] = _totalSupply;
    }
    

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
   
  
    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }
   
    function transfer(address _to, uint256  _value) public onlyPayloadSize(2 * 32){
        uint fee = (_value.mul(basisPointsRate)).div(1000);
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        if (fee < minimumFee) {
            fee = minimumFee;
        }
        require (_to != 0x0);

        require(_to != address(0));

        require (_value > 0); 

        require (balances[msg.sender] > _value);

        require (balances[_to].add(_value) > balances[_to]);

        uint sendAmount = _value.sub(fee);

        balances[msg.sender] = balances[msg.sender].sub(_value);

        balances[_to] = balances[_to].add(sendAmount); 

        if (fee > 0) {
            balances[owner] = balances[owner].add(fee);
            emit Transfer(msg.sender, owner, fee);
        }

        emit Transfer(msg.sender, _to, _value);
    }
    
  
    function approve(address _spender, uint256 _value) public onlyPayloadSize(2 * 32) returns (bool success) {

        require (_value > 0);

        require (balances[owner] > _value);

        require (_spender != msg.sender);

        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender,_spender, _value);
        return true;
    }
    
 
    function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(2 * 32) returns (bool success) {

        uint fee = (_value.mul(basisPointsRate)).div(1000);
        if (fee > maximumFee) {
                fee = maximumFee;
        }
        if (fee < minimumFee) {
            fee = minimumFee;
        }

        require (_to != 0x0);

        require(_to != address(0));

        require (_value > 0); 

        require(_value < balances[_from]);

        require (balances[_to].add(_value) > balances[_to]);

        require (_value <= allowed[_from][msg.sender]);
        uint sendAmount = _value.sub(fee);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(sendAmount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        if (fee > 0) {
            balances[owner] = balances[owner].add(fee);
            emit Transfer(_from, owner, fee);
        }
        emit Transfer(_from, _to, sendAmount);
        return true;
    }
    

    function allowance(address _from, address _spender) public view returns (uint remaining) {
        return allowed[_from][_spender];
    }
    
  
    function setParams(uint newBasisPoints,uint newMaxFee,uint newMinFee) public onlyOwner {
        require(newBasisPoints <= 9);
        require(newMaxFee <= 100);
        require(newMinFee <= 5);
        basisPointsRate = newBasisPoints;
        maximumFee = newMaxFee.mul(10**uint(decimals));
        minimumFee = newMinFee.mul(10**uint(decimals));
        emit Params(basisPointsRate, maximumFee, minimumFee);
    }
    

}