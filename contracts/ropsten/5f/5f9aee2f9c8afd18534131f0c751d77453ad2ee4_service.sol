contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns(bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}

contract service{
    address tokenContract = 0x2693FeC782aAa59E9604f4fD3BbbA3CeF8146061;
    mapping(address => uint256) public info;
    mapping(address => uint256) public balance;
    
    function receiveApproval(address _sender,uint256 _value,
            address _tokenContract, bytes _extraData) {
        require(_tokenContract == tokenContract);
        require(ERC20Basic(tokenContract).transferFrom(_sender, address(this), _value));
        uint256 payloadSize;
        uint256 payload;
        assembly {
            payloadSize := mload(_extraData)
            payload := mload(add(_extraData, 0x20))
        }
        payload = payload >> 8*(32 - payloadSize);
        info[_sender] = payload;
        balance[_sender] += _value;
    }
    function tokenFallback(address _sender,
                       uint256 _value,
                       bytes _extraData) returns (bool) {
        require(msg.sender == tokenContract);
        uint256 payloadSize;
        uint256 payload;
        assembly {
            payloadSize := mload(_extraData)
            payload := mload(add(_extraData, 0x20))
        }
        payload = payload >> 8*(32 - payloadSize);
        info[_sender] = payload;
        balance[_sender] += _value;
        return true;
    }
}