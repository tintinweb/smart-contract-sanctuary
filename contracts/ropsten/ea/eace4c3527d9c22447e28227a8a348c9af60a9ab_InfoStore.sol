pragma solidity ^0.4.23;

contract InfoStore {
    address public owner; 
    string[] public thisownerfiles;
    string[] public allIPFileName;
    string[] public allIPFileHash;
    // uint256 ticket = 1 ether;
    // uint public len;
    mapping (string => string) HashtoFileName;
    mapping (string => string[]) ownfiles;
    mapping (bytes32 => bool ) public usersRight;
    mapping (string => bool )  UsersID;
    mapping (string => Author)  fileNametoAuthor ;
    mapping (string => File) fileNametoFile ;
    
    Author public thisAuthor;
    File  public thisFile;
    
    struct Author{
        string authorName;
        string emailAddress;
        uint256 blocknumber;
        address ETHWalletAddress;
    }
    
    struct File{
        string fileName;
        string submitTime;
        string fileAddress;
        string keywords;
        uint256  money;
        
    }
    
    constructor() payable public {
        owner= msg.sender;
        
    }
    
   
    
//   function giveArraywords(string str)  public returns(uint) {
       
//       thisownerfiles.push(str);
//       len = thisownerfiles.length;
//       return len;
       
//   }
    
    // function getA(string filehash) view public returns (address ){
    //   return searchfilehash[filehash];
    // }
    
    function setAuthor(string name, string Email, address account, uint256 blocknumber) public {
      thisAuthor = Author(name, Email,blocknumber, account  );
    }
    function setFile(string name, string Time, uint256 money, string Address, string keyWords) public {
      thisFile = File(name, Time, Address, keyWords,money );
    }
    
    function ownFiles(string userSign, string newstring) public {
      thisownerfiles = ownfiles[userSign];
      thisownerfiles.push(newstring);
      ownfiles[userSign] = thisownerfiles;
    }
    //zu cheng mei yi ge user de yong you de file


    
    // function getName(string name, string Email, address account) view public returns (string){
    //     setAuthor(name, Email, account);
    //     return thisAuthor.authorName;
    // }
    
    function checkStoredFile (string Address) view public returns(bool){
       
        for(uint i = 0; i < allIPFileHash.length; i++){
	    if( keccak256(abi.encodePacked(Address)) == keccak256(abi.encodePacked(allIPFileHash[i]))){
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
    
    function SetIPR (string authorName, string Email, address account, string fileName, string Time, uint256 money, string Address, string keyWords,string UserID) payable public returns(bool){
        
        if(!(checkStoredFile(Address)||checkStoredFileName(fileName))){
        setAuthor(authorName, Email, account,block.number);
        setFile(fileName,Time,money,Address,keyWords);
        fileNametoAuthor[fileName]=thisAuthor;
        fileNametoFile[fileName]=thisFile;
        HashtoFileName[Address]=fileName;
        allIPFileHash.push(Address);
        allIPFileName.push(fileName);
        creatUserPurchase( UserID, fileName);
            return true;
        }
        else{return false;}
        
    }
    function HashToFileName(string hash)view public returns(string){
        return HashtoFileName[hash];
    }
    
     function SearchTimeBlocknumber(string fileName) view public returns(uint,string) {
        Author memory A = fileNametoAuthor[fileName];
         File memory F = fileNametoFile[fileName];
        return (A.blocknumber,F.submitTime);
    }
    
     function SearchIPR(string fileName, string searcherID)view public returns (string authorName,string emailAddress,address ETHWalletAddress, string FileName, string SubmitTime,string FileAddress,uint256 Money,string keyWords){
         
         Author memory A = fileNametoAuthor[fileName];
         File memory F = fileNametoFile[fileName];
         if(SearchUserPurchase(searcherID,F.fileName)){
         return (A.authorName,A.emailAddress,A.ETHWalletAddress,F.fileName,F.submitTime,F.fileAddress,F.money,F.keywords);
         }
         else{
            return (A.authorName,A.emailAddress,A.ETHWalletAddress,F.fileName,F.submitTime,&#39;null&#39;,F.money,F.keywords);
         }
    }
    
    function SearchUserPurchase(string accountID, string fileName) view public returns(bool){
        bytes32 B= keccak256(abi.encodePacked(accountID,fileName));
        return usersRight[B];
    }
    
    function creatUserPurchase(string accountID, string fileName)  public{
        require(!SearchUserPurchase(accountID,fileName));
         bytes32 A= keccak256(abi.encodePacked(accountID, fileName));
         usersRight[A]=true;
         ownFiles(accountID,fileName);
    }
    
    function SearchMyFiles(string accountID) view public returns(string){
        string[] storage c=ownfiles[accountID];
        string memory d ;
        for(uint32 i=0; i<c.length-1; i++){
            d=string(abi.encodePacked(d,c[i],&#39;,&#39;));
        }
        d=string(abi.encodePacked(d,c[c.length-1]));
        return d;
    }
    
    function creatUserID(string accountID)  public{
    
        UsersID[accountID]=true;
        
    }
    
     function SearchUserID(string accountID) view public returns(bool){
          return UsersID[accountID];
     }
    
    function SearchALLFileLength()view public returns (uint256){
        return allIPFileName.length;
    }

    
}