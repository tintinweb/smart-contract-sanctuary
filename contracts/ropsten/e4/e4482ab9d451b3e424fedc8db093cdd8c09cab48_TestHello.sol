pragma solidity ^ 0.4.25;                                                                                                                                                                                     pragma solidity ^ 0.4.15;

contract TestHello {
 event Owner(address indexed _owner);
 event Committed(address indexed pkd, address indexed pko);
    event KeyRevealed(address indexed pko);
     event Deposited(string msg, uint256 val);
         event Execution(
             address indexed transactionId
             );

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
    string public name;
    constructor (string _name) {
        name = _name;
        emit Owner(msg.sender);
        Transfer(msg.sender, msg.sender, 1000);
        // emit Committed(msg.sender, msg.sender);
        // emit KeyRevealed(msg.sender);
        // emit Deposited("Hello", 1000);
        Execution(1);
    }
    function set(string memory _name) public {
        name = _name;
    }
    
    function get() public view returns(TestHello) {
        return this;
    }
    
    function kill()  public {
        selfdestruct(address(msg.sender));
  }
}