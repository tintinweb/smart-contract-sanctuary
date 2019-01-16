pragma solidity ^0.4.0;


interface IERC20 {
    function totalSupply() external returns (uint256);
    function balanceOf(address who) external returns (uint256);
    function allowance(address owner, address spender) external returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value)external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner,address indexed spender, uint256 value);
}



contract Stopit is IERC20 {

    using SafeMath for uint256;
    
    uint256 public totalSupply = 0;
    uint256 public stage1      = 90000000;
    uint256 public stage2      = 75000000;
    uint256 public stage3      = 85000000;
    
    string public constant name = "StopIt Coin";
    string public constant symbol = "STP";
    uint public constant decimals = 4;
    
   
    uint256 public rate = 100000;//real_rate*10000  
    
    address public owner;
    address public project;
    address public team;
    address public ICO;
    address public rewards;
    
    
    mapping (address => uint256) public balances;
    mapping (address => bool) public activeAddress;
    mapping (uint256 => address) public addressId;
    uint256 public usersCount = 0;
        
    
    mapping (address => mapping(address => uint256)) allowed;


    address[] adr;
    uint256[] tok;

    
    constructor() public {
        owner = msg.sender;
        //balances[project] = 100000000;
        //balances[team]    = 90000000;
        //balances[ICO]     = 60000000;
        //balances[rewards] = 10000000;
        
        if(!activeAddress[msg.sender]){//for testing
            activeAddress[msg.sender] = true;
            usersCount++;
            addressId[usersCount]=msg.sender;
        }
        balances[msg.sender] = 1200000;
    }
    
    function setRate(uint256 newRate)public returns (bool){
        require(msg.sender == owner);
        rate = newRate;
        return true;
    }
    
    function setRate(uint256 _etherPrice, uint256 _tokenPrice)public returns (bool){
        require(msg.sender == owner);
        rate = _etherPrice.div(_tokenPrice);
        return true;
    }
    
    function () public payable{
        buyTokens();
    }
    
    
    function buyTokens() public payable  returns (uint256) {
        uint256 tokens = msg.value.mul(rate);//set token value respect to ether
        tokens = tokens.div(1000000000000000000);//truncate ether decimals
        require(tokens > 0
        && totalSupply >=tokens);
        
        owner.transfer(msg.value);
        if(!activeAddress[msg.sender]){
            activeAddress[msg.sender] = true;
            usersCount++;
            addressId[usersCount]=msg.sender;
        }
        balances[msg.sender] = balances[msg.sender].add(tokens);
        totalSupply = totalSupply.sub(tokens);
     return tokens;   
    }

    function totalSupply() public view returns (uint256){
        return totalSupply;
    }
    function balanceOf(address _who) public view returns (uint256){
        return balances[_who];
    }
    function allowance(address _owner, address _spender) public view returns (uint256){
        return allowed[_owner][_spender];
    }
    
    function getBalances()public constant returns (address[] , uint256[]){
        require(msg.sender == owner);
        address[] memory ad       = new address[](usersCount);
        uint256[] memory tokens   = new uint256[](usersCount);
        for(uint i=1; i<=usersCount; i++){
            address tempAddress = addressId[i];
            ad[i]     = tempAddress;
            tokens[i] = balances[tempAddress];
        }
        return (ad, tokens);
    }
    
    function getBalances1()public returns (address[] , uint256[]){
        require(msg.sender == owner);

        for(uint i=1; i<=usersCount; i++){
            address tempAddress = addressId[i];
            adr.push(tempAddress);
            tok.push(balances[tempAddress]);
        }
        return (adr, tok);
    }
    
    function getusersCount()public view returns (uint256){
        require(msg.sender == owner);
        return (usersCount);
    }
    
    function getBalanceOf(uint256 _id)public view returns (address , uint256){
        require(msg.sender == owner);
        address tempAddress = addressId[_id];

        return (tempAddress, balances[tempAddress]);
    }
    
    function transfer(address _to, uint256 _value) public returns (bool){
        require(
            balances[msg.sender] >= _value
            && _value > 0
            );
        if(!activeAddress[_to]){
            activeAddress[_to] = true;
            usersCount++;
            addressId[usersCount]=_to;
        }
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address from, address _to, uint256 _value) external returns (bool){
        require(
            allowed[from][msg.sender] >= _value
            && balances[from]  >= _value
            && _value > 0
            );
        if(!activeAddress[_to]){
            activeAddress[_to] = true;
            usersCount++;
            addressId[usersCount]=_to;
        }
        balances[from] = balances[from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) external returns (bool){
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    
    function addTokens(uint256 _tokens)public returns(bool){
        require(msg.sender == owner);
        totalSupply = totalSupply.add(_tokens);
        return true;
    } 

    function setStage1()public returns(bool){
        require(msg.sender == owner);
        if (totalSupply > 0){
            stage3 = totalSupply;
        }
        totalSupply = stage1;
        return true;
    } 
    function setStage2()public returns(bool){
        require(msg.sender == owner);
        stage1 = totalSupply;
        totalSupply = stage2;
        return true;
    }
    function setStage3()public returns(bool){
        require(msg.sender == owner);
        stage2 = totalSupply;
        totalSupply = stage3;
        return true;
    }

    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner,address indexed spender, uint256 value);
    
    
    
    
}


library SafeMath {



  /**

  * @dev Multiplies two numbers, reverts on overflow.

  */

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {

    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the

    // benefit is lost if &#39;b&#39; is also tested.

    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522

    if (a == 0) {

      return 0;

    }



    uint256 c = a * b;

    require(c / a == b);



    return c;

  }



  /**

  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.

  */

  function div(uint256 a, uint256 b) internal pure returns (uint256) {

    require(b > 0); // Solidity only automatically asserts when dividing by 0

    uint256 c = a / b;

    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold



    return c;

  }



  /**

  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).

  */

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {

    require(b <= a);

    uint256 c = a - b;



    return c;

  }



  /**

  * @dev Adds two numbers, reverts on overflow.

  */

  function add(uint256 a, uint256 b) internal pure returns (uint256) {

    uint256 c = a + b;

    require(c >= a);



    return c;

  }



  /**

  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),

  * reverts when dividing by zero.

  */

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {

    require(b != 0);

    return a % b;

  }

}