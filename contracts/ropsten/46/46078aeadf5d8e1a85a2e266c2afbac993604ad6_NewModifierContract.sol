/**
 *Submitted for verification at Etherscan.io on 2021-11-25
*/

pragma solidity >0.4.22  < 0.7.0; 

contract NewModifierContract {
    struct PersonInfo{
        string name;
        uint age; 
        bool isMan;
        string region;
        address walletAddress;
    }

    PersonInfo[] public userInfo;

    event logUserInfo(string  _name, uint _age, bool _isMan, string  _region, address _walletAddress);

    function getuserInfoLength() public view returns(uint){
        return userInfo.length;
    }

    function setUserInformation(string memory _name, uint _age, bool _isMan, string memory _region, address _walletAddress) public {
         userInfo.push(PersonInfo({name: _name , age: _age , isMan : _isMan , region:_region , walletAddress : _walletAddress}));
        // userInfo.push( _name , _age ,_isMan ,_region, _walletAddress);
        uint idxNew = userInfo.length -1;
        

        for( uint i = 0 ; i< userInfo.length; i++ ){
            emit logUserInfo(userInfo[i].name,userInfo[i].age,userInfo[i].isMan,userInfo[i].region,userInfo[i].walletAddress);
        }
    }
}