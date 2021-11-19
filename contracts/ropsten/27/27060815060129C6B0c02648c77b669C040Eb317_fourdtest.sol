/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

pragma solidity 0.8.0;


contract fourdtest {
    uint256[] fourDList;
    uint256[] fourDListDate;
    uint256 nonce = 0;
    uint256 number = 0;
    
    function get_4DList() public view returns (uint256[] memory result){
        return fourDList;
    }
    
    function get_4DListDate() public view returns (uint256[] memory result){
        return fourDListDate;
    }
    
    function get_last4Dresult() public view returns (uint256 result){
        uint last = fourDList.length - 1;
        return fourDList[last];
    }
    
    function get_last4DresultDate() public view returns (uint256 result){
        uint last = fourDListDate.length - 1;
        return fourDListDate[last];
    }
    
    function set_4DList() public payable returns (uint256[] memory result){
        nonce++;
        uint256 datetime = block.timestamp;
        uint256 random = uint256(keccak256(abi.encodePacked(datetime, msg.sender, nonce))) % 10000; 
        fourDList.push(random);
        fourDListDate.push(datetime);
        return fourDList;
    }
    
    function getSlice(uint256 begin, uint256 end, string memory text) public pure returns (string memory) {
        bytes memory a = new bytes(end-begin+1);
        for(uint i=0;i<=end-begin;i++){
            a[i] = bytes(text)[i+begin-1];
        }
        return string(a);    
    }
    
    function append(string memory a, string memory b) internal pure returns (string memory) {
    
        return string(abi.encodePacked(a, b));
    
    }
}