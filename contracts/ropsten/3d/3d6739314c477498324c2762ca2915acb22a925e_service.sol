contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns(bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}

contract service{
    address tokenContract = 0xc4bfa60850704b323e8af5c7e9e81502cc599e2b;
    mapping(address => uint256) public balance;
    
    function receiveApproval(address _sender,uint256 _value,
            address _tokenContract, bytes _extraData) {
        require(_tokenContract == tokenContract);
        require(ERC20Basic(tokenContract).transferFrom(_sender, address(this), _value));

        balance[_sender] += _value;
    }
    function tokenFallback(address _sender,
                       uint256 _value,
                       bytes _extraData) returns (bool) {
        require(msg.sender == tokenContract);
        balance[_sender] += _value;
        return true;
    }
}