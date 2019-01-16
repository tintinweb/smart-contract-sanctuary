pragma solidity ^0.4.22;
contract Ownable {
  address public owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev 可拥有的构造函数将合同的原始“所有者”设置为发送者
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev 如果由所有者以外的任何帐户调用，则抛出
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev 允许当前所有者将合同的控制转移给新所有者.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev 将合同的控制权移交给新所有者.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

/**
 * 许愿Id 、许愿签名、许愿内容、许愿时间
 */ 
contract vow is Ownable {
    
    //tokenid属性 
  struct VowInfo {
      bytes32 tokenId;//Id
      string sign;//签名 
      string content;//内容 
      string time;//时间
  }
  mapping(bytes32 =>VowInfo) vowInfoToken;
  bytes32[] vowInfos;
    /**
    * 添加许愿 
   */
    event NewMerchant(address sender,bool isScuccess,string message);
    function addVowInfo(bytes32 _tokenId,string sign,string content,string time) onlyOwner{
        if(vowInfoToken[_tokenId].tokenId != _tokenId){
             vowInfoToken[_tokenId].tokenId = _tokenId;
              vowInfoToken[_tokenId].sign = sign;
              vowInfoToken[_tokenId].content = content;
              vowInfoToken[_tokenId].time = time;
              vowInfos.push(_tokenId);
              NewMerchant(msg.sender, true,"添加成功");
            return;
        }else{
             NewMerchant(msg.sender, false,"许愿ID已经存在");
            return;
        }
    }
     /**
    * 返回 tokenId属性 
   */
    function getVowInfo(bytes32 _tokenId)public view returns(string tokenId,string sign,string content,string time){
                
         VowInfo memory vow = vowInfoToken[_tokenId];
        string memory vowId = bytes32ToString(vow.tokenId);
        return (vowId,vow.sign,vow.content,vow.time);
    }
    
    function bytes32ToString(bytes32 x) constant internal returns(string){
        bytes memory bytesString = new bytes(32);
        uint charCount = 0 ;
        for(uint j = 0 ; j<32;j++){
            byte char = byte(bytes32(uint(x) *2 **(8*j)));
            if(char !=0){
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for(j=0;j<charCount;j++){
            bytesStringTrimmed[j]=bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
}