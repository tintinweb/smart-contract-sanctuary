pragma solidity >=0.4.22 <0.6.0;
//Current version:0.5.2+commit.1df8f40c.Emscripten.clang
contract AnonymousWALL {
    
    address payable manager;
    struct messageDetails {
      uint time;
      string headline ;
      string message;
    }
    mapping (address => messageDetails) journal;
    address[] private listofjournalists;
    
    constructor() public {
      manager = msg.sender;
    }
    
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
    
    function enteranews(string memory uHeadline, string memory uMessage) public payable {
        require(msg.value >= .001 ether,"This contrat works with minimum 0.001 ether");
        require(journal[msg.sender].time == 0,"An account can only be used once.");
        manager.transfer(msg.value);
        journal[msg.sender].time = now;
        journal[msg.sender].headline = uHeadline;
        journal[msg.sender].message = uMessage;
        listofjournalists.push(msg.sender) -1;
    }
    
    function getjournalists() view public returns(address[] memory) {
      return listofjournalists;
    }
    
    function numberofnews() view public returns (uint) {
      return listofjournalists.length;
    }
    
    function gamessage(address _address) view public returns (string memory, string memory, string memory,string memory) {
        if(journal[_address].time == 0){
            return ("0", "0", "0", "This address hasnt sent any messages before.");
        } else {
            return (uint2str(journal[_address].time), journal[_address].headline, journal[_address].message, "We reached your message successfully.");
        }
    }
}