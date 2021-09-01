/**
 *Submitted for verification at BscScan.com on 2021-09-01
*/

pragma solidity >=0.8.4;

contract SMBLicense{
    address owner;
    address [] allUsers;
    
    
    constructor(){
        owner =msg.sender;
        allUsers.push(msg.sender);
    }
    
    modifier onlyOwner(){
        require(msg.sender == owner , "only Admin");
        _;
    }
    
    function changeOwner(address _newOwner) external onlyOwner(){
        owner=_newOwner;
    }
    
    
    
    function addNewUser(address _newUserAddress) external onlyOwner(){
        allUsers.push(_newUserAddress);
    }
    
    function addMultipleUser(address [] calldata usersArray)external onlyOwner(){
        for (uint i =0; i < usersArray.length; i++ ){
            allUsers.push(usersArray[i]);
        }
    }
    
    
    
    function removeUser(address _walletAddress) external onlyOwner(){
        for (uint i =0; i < allUsers.length; i++ ){
            if (allUsers[i]==_walletAddress){
                for (uint j=i; j<allUsers.length-1; j++){
                    allUsers[j]=allUsers[j+1];
                }
                allUsers.pop();
                break;
            }
        }
    }
    
    
    function removeAllUsers()external onlyOwner(){
        while (allUsers.length != 0){
            allUsers.pop();
        }
    }
    
    
    function getAllUsers() external view onlyOwner() returns (address[] memory){
        return  allUsers;
    }
     
    function isUser(address userWalletAddress) external view returns (bool){
        
        bool isUserValid=false;
        
        for (uint i =0; i < allUsers.length; i++ ){
            if (allUsers[i] == userWalletAddress){
                isUserValid = true;
                break;
            }
        }
        return isUserValid;
    }
    
    function changeWallet(address _newWalletAddress) external returns (string memory, address){
        bool isUserValid=false;

        for (uint i =0; i < allUsers.length; i++ ){
            if (allUsers[i] == msg.sender){
                isUserValid = true;
                break;
            }
        }
        require (isUserValid == true || msg.sender == owner);
       
        //Remove
        for (uint i =0; i < allUsers.length; i++ ){
            if (allUsers[i]==msg.sender){
                for (uint j=i; j<allUsers.length-1; j++){
                    allUsers[j]=allUsers[j+1];
                }
                allUsers.pop();
                break;
            }
        }
       
        //Add
        allUsers.push(_newWalletAddress);
        return ("Changed to new Wallet address : ", _newWalletAddress);
    }
}