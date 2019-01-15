pragma solidity ^0.5.0;

contract BlncTreasure {

    address admin;

    string[] allTreasures;

    mapping(bytes32 => string) treasures;

    mapping(bytes32 => string) members;

    event NewTreasureEvent (
        bytes32 md5OfTreasureName,
        string treasureName          
    );

    event DispatchMembersEvent (
        bytes32 md5OfTreasureName,
        string md5OfMembers
    );

    constructor()
        public 
    {
        admin = msg.sender;
    }

    function newTreasure (
        bytes32 md5OfTreasureName,
        string memory treasureName        
    )
        public
        onlyAdmin()
        onlyWriteTreasureOneTime(md5OfTreasureName)
    {
       
        allTreasures.push(treasureName);
        treasures[md5OfTreasureName] = treasureName;
        emit NewTreasureEvent(md5OfTreasureName,treasureName);
    }

    function dispatchMembers (
        bytes32 md5OfTreasureName,
        string memory md5OfMembers
    )
        public 
        onlyAdmin()
        onlyOnceWriteMembersOneTime(md5OfTreasureName)
    {
        members[md5OfTreasureName] = md5OfMembers;
    }

    function isAdmin (
        address admin_
    )
        public
        view
        returns(bool)
    {
        if(admin_ == admin) {
            return true;
        }
        return false;
    }

    function isNotDuplicateTreasure(
        bytes32 md5OfTreasureName
    )
        public
        view
        returns(bool) 
    {
        string memory treasureName = treasures[md5OfTreasureName];
        return isEmptyString(treasureName);
    }

    function isNotDuplicateMembers(
        bytes32 md5OfTreasureName
    )
        public 
        view 
        returns(bool)
    {
        string memory memberHash = members[md5OfTreasureName];
        return isEmptyString(memberHash);
    }

    modifier onlyWriteTreasureOneTime (
        bytes32 signature
    ) {
        require(isNotDuplicateTreasure(signature),"error : duplicate members of the treasure");
        _;
    }

    modifier onlyOnceWriteMembersOneTime (
        bytes32 signature
    ) {
        require(isNotDuplicateMembers(signature),"error : duplicate treasure");
        _;
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender),"only the amdin has the permession");
        _;
    }

    function getTreasures ()
        public
        view
        returns(byte[] memory) 
    {
        return concat(allTreasures,0); 
    }

    function getTreasure (
        bytes32 md5OfTreasureName
    )
        public
        view 
        returns(string memory)
    {
        return treasures[md5OfTreasureName];
    }

    function getMembers (
        bytes32 md5OfTreasureName
    )
        public
        view
	    returns(string memory)
	{
        return members[md5OfTreasureName];
    }

    // 连接字符串数组
    function concat(
        string[] memory arrs,
        uint256 index
    )
      private 
      pure
      returns(byte[] memory)
    {
        uint256 arrSize = arrs.length;
        if(arrs.length == 0) {
            return new byte[](0);
        }
        uint256 total = count(arrs,index);
        byte[] memory result = new byte[](total); 
        uint256 k = 0;
        for(uint256 i = index; i < arrSize; i++) {
            bytes memory arr = bytes(arrs[i]);
            for(uint j = 0; j < arr.length; j++) {
                result[k] = arr[j];
                k++;
            }
        }
        return result;
    }

    // 统计长度
    function count(
        string[] memory arrs,
        uint256 index
    )
        private
        pure
        returns(uint256) 
    {
        uint256 total = 0;    
        uint256 len1 = arrs.length;
        for(uint256 i = index;i < len1; i++) {
            bytes memory arr = bytes(arrs[i]);
            total = total + arr.length;
        }
        return total;
    }

    function compare(
        string memory _a, 
        string memory _b
    ) 
        private
        pure
        returns (int) 
    {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        //@todo unroll the loop into increments of 32 and do full 32 byte comparisons
        for (uint i = 0; i < minLength; i ++) {
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        }  
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }
    
    function equal(
        string memory _a, 
        string memory _b
    ) 
        private
        pure
        returns (bool) 
    {
        return compare(_a, _b) == 0;
    }

    function isEmptyString (
        string memory str
    )
        private 
        pure
        returns(bool)
    {
        bytes memory temp = bytes(str);
        if(temp.length == 0) {
            return true;
        }
        return false;
    }
}