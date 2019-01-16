contract Fmms {
    
    struct userData{
        bytes32 dataHash;
        uint256 dataType;
        uint256 blockNumber;
    }
    mapping(address => userData) private userDetails;
    
    function saveData(bytes32 _dataHash, uint256 _dataType) external returns(bool) {
        userDetails[msg.sender].dataHash = _dataHash;
        userDetails[msg.sender].dataType = _dataType;
        userDetails[msg.sender].blockNumber = block.number;
        return true;
    }
    
    function getUserDetails(address user)public view returns(bytes32,uint256,uint256) {
        return (userDetails[user].dataHash,userDetails[user].blockNumber,userDetails[user].dataType);
    }
    
}