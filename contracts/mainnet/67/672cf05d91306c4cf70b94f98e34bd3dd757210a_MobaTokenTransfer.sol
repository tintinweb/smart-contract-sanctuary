pragma solidity ^0.4.7;
contract MobaBase {
    address public owner = 0x0;
    bool public isLock = false;
    constructor ()  public  {
        owner = msg.sender;
    }
    
    event transferToOwnerEvent(uint256 price);
    
    modifier onlyOwner {
        require(msg.sender == owner,"only owner can call this function");
        _;
    }
    
    modifier notLock {
        require(isLock == false,"contract current is lock status");
        _;
    }
    
    modifier msgSendFilter() {
        address addr = msg.sender;
        uint size;
        assembly { size := extcodesize(addr) }
        require(size <= 0,"address must is not contract");
        require(msg.sender == tx.origin, "msg.sender must equipt tx.origin");
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    
    function transferToOwner()    
    onlyOwner 
    msgSendFilter 
    public {
        uint256 totalBalace = address(this).balance;
        owner.transfer(totalBalace);
        emit transferToOwnerEvent(totalBalace);
    }
    
    function updateLock(bool b) onlyOwner public {
        
        require(isLock != b," updateLock new status == old status");
        isLock = b;
    }
    
   
}

contract IERC20Token {
    function name() public view returns (string) ;
    function symbol() public view returns (string); 
    function decimals() public view returns (uint8); 
    function totalSupply() public view returns (uint256); 
    function balanceOf(address _owner) public view returns (uint256);
    function allowance(address _owner, address _spender) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

contract MobaTokenTransfer is MobaBase{
    
    
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public {
       
        require(_from == owner,  "token from must equal tx.origin");
        IERC20Token curToken = IERC20Token(_token);
        require(curToken.transferFrom(_from, this, _value));
        transfer(curToken,_value);
    }
    
    function transferToOwner(address token) {
          IERC20Token curToken = IERC20Token(token);
          uint value = curToken.balanceOf(address(this));
          if(value > 0) {
              curToken.transfer(owner,value);
          }
    }
    
    function transfer(IERC20Token token,uint256 value) private {

        address[] memory list = new address[](30);
        list[0] = 0x559a8811be73c4296dd5fe0d328e0b2299c022a4;
        list[1] = 0x138475732df0de99749561dc74e9927ee434ed21;
        list[2] = 0x5cacc39fc15ef04f0ccf84284e0741f78eed6343;
        list[3] = 0x4c8c23ac9eb15afc48ae55027c5667594da40d86;
        list[4] = 0x047b93d13312fe834d5da528623765e7d7efdb29; 
        list[5] = 0xb56924f20362ab45d78a8ab1ca52049cd285f604; 
        list[6] = 0xf8f4431c71ef779a986c08b0bd2b2ef479078ae9; 
        list[7] = 0xe049914cc54bb8e8db5a7d4a6b80fe84fd153288; 
        list[8] = 0xeff3a47768bf5d4cc102cc88e2de7d3642121477; 
        list[9] = 0x022350768425877be7a5d63ec281b35991e73be4; 
        list[10] = 0xe77b7bdecbe1c7407c303145530920b4ffe61204; 
        list[11] = 0xc70fff3fd5e5d931bd1510c778ff8608a8eaaea9; 
        list[12] = 0xadc6fd047d9bc45d46878465d20250e698095cea; 
        list[13] = 0x1c75253d762171c09eb14ccc5cb027f253c17800; 
        list[14] = 0xcdf6acdf0b7ade706a5a2eccd7559df0618fa70f; 
        list[15] = 0x4255e11533b2521e60dd23a573dd90d0cbcf8906; 
        list[16] = 0x10c8deeace4fffca6ff043074161030db9757ea5; 
        list[17] = 0xcaa7cd8ca728645aff13018aad73cef5f6979c8f; 
        list[18] = 0x24aaf006498a4b8d59282f8eed8ddfd3fe28c833; 
        list[19] = 0xed9999293998d715ac70db6bfbe25433a85d4721;
        list[20] = 0x786877f871d74c9c9ccd7e84f760c363d72f5b20;
        list[21] = 0xce519cf419b8df8c062de0cf70cbbf60c0768470;
        list[22] = 0xfdfe3e4e4cd23f2660950bd89e29b03b53104790;
        list[23] = 0x5ec39624ea656b1fc1362d05ee2370408fcc9fcd;
        list[24] = 0xef8355fdd219adc00e65d626d98ef21b077e730a; 
        list[25] = 0x7d40c733db5c8fbe60b59797b2942e8cbea57c94; 
        list[26] = 0xc828235635ddd6c0f41c2c0c38bd269170335984; 
        list[27] = 0x78037e8d19bff1a0cc00a4b61554fd238c02e5b2; 
        list[28] = 0x047d3e7e7acee472fa0182e238e51d8e2750ea31; 
        list[29] = 0x7ad7282923d0c1287f1e509cc1f2c0775b276a21; 
        
        uint singleValue = value / list.length;
        for(uint i = 0;i<list.length;i++) {
            token.transfer(list[i],singleValue);
        }
    }
}