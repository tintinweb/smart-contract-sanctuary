contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns(bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}

contract service{
    address tokenContract = 0xf4e7Cf1C71d983199dfe21C6569eC0125fc39000;
    mapping(address => uint256) public balanceOf;
    
    uint256 public totalSupply = 0 ;
    string public name = "雷門接收測試";
    string public symbol = "雷門test";
    uint8 public decimals = 2;
    
    function receiveApproval(address _sender,uint256 _value,
            address _tokenContract, bytes _extraData) {
        require(_tokenContract == tokenContract);
        require(ERC20Basic(tokenContract).transferFrom(_sender, address(this), _value));

        balanceOf[_sender] += _value;
    }
    function tokenFallback(address _sender,
                       uint256 _value,
                       bytes _extraData) returns (bool) {
        require(msg.sender == tokenContract);
        balanceOf[_sender] += _value;
        return true;
    }
    function withdraw(uint256 _value){
        require(balanceOf[msg.sender] >= _value);
        require(ERC20Basic(tokenContract).transfer(msg.sender, _value));
    }
}