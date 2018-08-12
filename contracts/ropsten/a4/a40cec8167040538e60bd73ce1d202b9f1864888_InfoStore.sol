pragma solidity ^0.4.23;

contract InfoStore {
    address public owner; 
    string[] public thisownerfiles;
    string[] public allIPFileName;
    address[] public allIPFileHash;
    uint256 ticket = 1 ether;
    uint public len;
      // mapping (string => address) searchfilehash;
    mapping (address => string[]) public ownfiles;
    mapping (bytes32 => bool ) public usersRight;
    mapping (string => Author)  fileNametoAuthor ;
    mapping (string => File) fileNametoFile ;
    
    Author public thisAuthor;
    File  public thisFile;
    
    struct Author{
        string authorName;
        string emailAddress;
        address ETHWalletAddress;
    }
    
    struct File{
        string fileName;
        string submitTime;
        address fileAddress;
        uint256  money;
    }
    
    constructor() payable public {
        owner= msg.sender;
        
    }
    
    function payMoneytoOwner() payable public returns (bool){
        require(msg.value <= msg.sender.balance);
        owner.transfer(msg.value);
        return true;
    }
    
    function payMoneytoAuthor(address a) payable public returns (bool){
        require(msg.value <= msg.sender.balance);
        a.transfer(msg.value);
        return true;
    }
    
//   function giveArraywords(string str)  public returns(uint) {
       
//       thisownerfiles.push(str);
//       len = thisownerfiles.length;
//       return len;
       
//   }
    
    // function getA(string filehash) view public returns (address ){
    //   return searchfilehash[filehash];
    // }
    
    function setAuthor(string name, string Email, address account) public {
      thisAuthor = Author(name, Email, account );
    }
    function setFile(string name, string Time, uint256 money, address Address) public {
      thisFile = File(name, Time, Address, money );
    }
    
    function ownFiles(address userhash, string newstring) public {
      thisownerfiles = ownfiles[userhash];
      thisownerfiles.push(newstring);
      ownfiles[userhash] = thisownerfiles;
    }
    //zu cheng mei yi ge user de yong you de file


    
    // function getName(string name, string Email, address account) view public returns (string){
    //     setAuthor(name, Email, account);
    //     return thisAuthor.authorName;
    // }
    
    function checkStoredFile (address Address) view public returns(bool){
       
        for(uint i = 0; i < allIPFileHash.length; i++){
	    if( Address == allIPFileHash[i]){
	    	return true;
	        }
	    }
	    return false;
        
    }
    
    function checkStoredFileName (string fileName) view public returns(bool){
        for(uint i = 0; i < allIPFileName.length; i++){
            if(keccak256(abi.encodePacked(fileName)) == keccak256(abi.encodePacked(allIPFileName[i]))){
            return true;    
            }
        }
        return false;
    }
    
    function SetIPR (string authorName, string Email, address account, string fileName, string Time, uint256 money, address Address) payable public returns(bool){
        
        if(!(checkStoredFile(Address)||checkStoredFileName(fileName))&& payMoneytoOwner()){
        setAuthor(authorName, Email, account);
        setFile(fileName,Time,money,Address);
        fileNametoAuthor[fileName]=thisAuthor;
        fileNametoFile[fileName]=thisFile;
        allIPFileHash.push(Address);
            return true;
        }
        else{return false;}
        
    }
     function SearchIPR(string fileName)view public returns (string authorName,string emailAddress, string submitTime ){
         Author memory A = fileNametoAuthor[fileName];
         File memory F = fileNametoFile[fileName];
         return (A.authorName,A.emailAddress, F.submitTime);
     }
    
    
    function creatUserPurchase(string a, string b)  public pure returns (bytes32){
         return keccak256(abi.encodePacked(a, b));
    }

    
}