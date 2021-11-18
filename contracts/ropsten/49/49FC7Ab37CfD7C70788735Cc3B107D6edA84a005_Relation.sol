/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

// File: contracts/interface/IRelation.sol


pragma solidity ^0.8.0;

interface IRelation {
    
    struct UserRelation {
        address add1;
        address add2;
        address add3;
        address add4;
        address add5;
        bool isUsed;
    }
    
    function getUserRelation(address user) external view returns(UserRelation memory);   
}


// File: contracts/common/Logger.sol


pragma solidity ^0.8.0;

contract Logger {
    event LogUint(string, uint);
    event LogInt(string, int);
    event LogBytes(string, bytes);
    event LogBytes32(string, bytes32);
    event LogAddress(string, address);
    event LogBool(string, bool);
    event LogString(string, string);

    function log(string memory s , uint x) internal {emit LogUint(s, x);}
    function log(string memory s , int x) internal {emit LogInt(s, x);}
    function log(string memory s , bytes memory x) internal {emit LogBytes(s, x);}
    function log(string memory s , bytes32 x) internal {emit LogBytes32(s, x);}
    function log(string memory s , address x) internal {emit LogAddress(s, x);}
    function log(string memory s , bool x) internal {emit LogBool(s, x);}
    function log(string memory s , string memory x) internal {emit LogString(s, x);}
}

// File: contracts/common/Context.sol


pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/common/Ownable.sol


pragma solidity ^0.8.0;


contract Ownable is Context {
    address private _owner;

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

}

// File: contracts/Relation.sol


pragma solidity ^0.8.0;





contract Relation is Ownable, Logger, IRelation {
    
    address[] users;
    mapping(address => UserRelation) userRelationMap;
    
    address my = address(0xc7df03C8D00490b232d5898B5C1E503Dd04D7500);
    address head = address(0x67092Ea64D40D2eb7DDA5692d566539C9493De31);
    
    event Register(address user, UserRelation userRelation);
    
    function register(address shareAddress) external {
        require(shareAddress != address(0), "shareAddress can not be empty");
        
        address user = _msgSender();
        
        require(!isRegister(user), "user is already registered");
        
        require(user != shareAddress, "can't be yourself");
        
        if (user == head) {
            shareAddress = my;
        } else {
            if (!isRegister(shareAddress)) {
                shareAddress = head;
            }
        }
        
        UserRelation memory shareRelation = userRelationMap[shareAddress];
        
        users.push(user);
        
        UserRelation memory userRelation = 
        UserRelation(shareAddress, shareRelation.add1, shareRelation.add2, shareRelation.add3, shareRelation.add4, true);
        
        userRelationMap[user] = userRelation;
        
        emit Register(user, userRelation);
    }
    
    function isRegister() public view returns(bool){
        return userRelationMap[_msgSender()].isUsed;
    }
    
    function isRegister(address user) public view returns(bool){
        return userRelationMap[user].isUsed;
    }
    
    function getUserRelation() public view returns(UserRelation memory) {
        return userRelationMap[_msgSender()];
    }
    
    function getUserRelation(address user) external view override returns(UserRelation memory) {
        return userRelationMap[user];
    }
    
    function getAllUser() external view returns(address[] memory){
        return users;
    }
    
}