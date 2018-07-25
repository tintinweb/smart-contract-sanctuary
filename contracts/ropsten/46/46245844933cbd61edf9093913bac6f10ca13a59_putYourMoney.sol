pragma solidity^0.4.24;

//authors:dcipher.io
//july-2018
//dcipher.io - &quot;put your money where you mouth is&quot; - escrow solution


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}  

contract putYourMoney is Ownable{
   using SafeMath for uint256;  
   
   
       //add new client into array list
    function addClient(string _fName, string _lName, string _email, string _company, uint _mobile, uint _creationTime, uint8 _step2valid, uint8 _step3valid) public  payable fixAmmount(1000000000000000000){
        _creationTime = now;     //get the current timestamp when a new client register
        _step2valid = 1;         //default value (acting as a false value for step2), if _step2valid = 2 it&#39;s acting as true
        _step3valid = 1;        //default value (acting as a false value for step3), if _step3valid = 2 it&#39;s acting as true
        address owner = msg.sender;      //set an address for each client
        uint id = clients.push(Client(_fName, _lName, _email, _company,  _mobile, _creationTime, _step2valid, _step3valid));  //set an id and push all the info into it
        clientAddress[owner] = id;       //save in id your client structure
        
        emit addedClient(owner, id, _fName, _lName, _email, _company, _mobile,  _creationTime, _step2valid, _step3valid);   //fire the events to call them in js, without emit is deprecated
        
        //balances[msg.sender] += msg.value;  //balance of each sender(client)
        balances[msg.sender] = balances[msg.sender].add(msg.value);  //balance of each sender(client) using SafeMath
    }
   
    // modifier = a check if the value equal to n ether before the function is executed
    modifier fixAmmount(uint value){
        // msg.value should be exactly n ether, else it will throw error
        require(msg.value == value);
            _; //continue to execute the funciton
    }
    
    //client structure, all the clients info
    struct Client{
        string fName;
        string lName;
        string email;
        string company;
        uint   mobile;
        uint   creationTime;
        uint8  step2valid;
        uint8  step3valid;
    }
    
    //store the client structure into clients array
    Client[] clients; 
    //specify an address to a client
    mapping (address => uint) clientAddress;

    //event to get fired when someone add a new client
    event addedClient(address owner, uint clientId, string fName, string lName, string email, string company, uint mobile, uint creationTime, uint8 step2valid, uint8 step3valid);
    

    
    /*
    //view clients with all details
    function getClients(uint _id) view returns (string, string, string, string, uint, uint) {
      return (clients[_id].fName,clients[_id].lName,clients[_id].email, clients[_id].company, clients[_id].mobile, clients[_id].creationTime);
        }
    */
    
    //count how many clients are registered
    function countNoClients() view public returns (uint){
        return clients.length;
    }    
        
    
    //just the owner can see his details
    function getOwnerClientDetails() view returns (string, string, string, string, uint, uint, uint, uint)  {
        address owner = msg.sender;
        uint id = clientAddress[owner];
      return (clients[id-1].fName,clients[id-1].lName,clients[id-1].email, clients[id-1].company, clients[id-1].mobile, clients[id-1].creationTime, clients[id-1].step2valid, clients[id-1].step3valid);
        }
    
    //set the owner of the contract  
    constructor () public {
         owner = msg.sender;
        } 
    
    //view the balance in contract
    function getContractBalance()  public constant returns(uint){
        return address(this).balance;
    }
    
    
    //Set the default steps fee hardcoded   
        uint step1 = 1000000000000000000 wei;
        uint step2 = 500000000000000000 wei;
        uint step3 = 500000000000000000 wei;
        
    //after deploying the contract, owner can define all the steps fee together
        function setAllSteps(uint _step1, uint _step2, uint _step3) public onlyOwner{
            step1 = _step1;
            step2 = _step2;
            step3 = _step3;
        }
        
    //after deploying the contract, owner can define just the value of step1
        function setValueStep1(uint _step1) public onlyOwner{
            step1 = _step1;
        }
        //after deploying the contract, owner can define just the value of step2
        function setValueStep2(uint _step2) public onlyOwner{
            step2 = _step2;
        }
    //after deploying the contract, owner can define just the value of step3
        function setValueStep3(uint _step3) public onlyOwner{
            step3 = _step3;
        }
        
        
    //view all steps     
    function getAllSteps() public view returns (uint, uint, uint) {
        return (step1,step2,step3);
        }
    
    mapping (address => uint256) public balances;
    //similar to withdraw but ether is sent to specified address, not the caller
    /*
    function transfer(address to, uint value) returns(bool success)  {
        if(balances[msg.sender] < value) throw;
        balances[msg.sender] -= value;
        to.transfer(value);
        return true;
    }
    */
    
    //client transfer his first part, 0.5 eth
    //can transfer them after 1 day
    //can transfer them only once, after that step2valid became 2
    //using SafeMath library
    function transferStep2(address to) returns(bool)  {
        uint id = clientAddress[msg.sender];
        require (clients[id-1].step2valid == 1);
        require (now >= clients[id-1].creationTime + 1 days);
        if(balances[msg.sender] <= step2) throw;
            //balances[msg.sender] -= step2;
            balances[msg.sender] = balances[msg.sender].sub(step2);
            to.transfer(step2);
            clients[id-1].step2valid = 2;
        return true;
    }
    
    //client transfer his second part, 0.5 eth
    //can transfer them after 1 day
    //can transfer them only once, after that step3valid became 2
    //using SafeMath library
    function transferStep3(address to) returns(bool)  {
        uint id = clientAddress[msg.sender];
        require (clients[id-1].step3valid == 1);
        require (now >= clients[id-1].creationTime + 7 days);
        if (balances[msg.sender] <= step3) throw;
            //balances[msg.sender] -= step3;
            balances[msg.sender] = balances[msg.sender].sub(step3);
            to.transfer(step3);
            clients[id-1].step3valid = 2;
        return true;
    }

    //safe withdraw the remaining eth from contract if the client don&#39;t claim them
    function safeWithdrawEther() external onlyOwner {
    owner.transfer(address(this).balance);
    }
    
    //kill the contract
    function kill() public onlyOwner{
        if(msg.sender == owner)
            selfdestruct(owner);
    }
   

}