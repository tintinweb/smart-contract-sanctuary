/**
 *Submitted for verification at Etherscan.io on 2021-10-08
*/

contract WhiteListDragon {
    
    mapping(uint256 => address) _whiteList;
    uint256 _size_whitelist;
    
    
    function addWhiteList(address[] memory owners) public {
        _size_whitelist = owners.length;
        for (uint32 i = 0 ; i < _size_whitelist ; i ++) {
            _whiteList[i] = owners[i];
        }
    }
    
    function readWhiteList() public view returns(address[] memory) {
        address[] memory result;
        for (uint256 i = 0 ; i < _size_whitelist ; i ++) {
            result[i] = _whiteList[i];
        }
        return result;
    }
}