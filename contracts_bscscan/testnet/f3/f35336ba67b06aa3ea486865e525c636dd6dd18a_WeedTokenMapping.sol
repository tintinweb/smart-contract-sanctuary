/**
 *Submitted for verification at BscScan.com on 2021-08-17
*/

contract WeedTokenMapping {
    mapping (address => uint256) public OldUserMap;
    function AddOldUserMap(address[] memory _address, uint256[] memory _amount) public payable{
        
        for(uint i=0; i>= _address.length; i++){
                OldUserMap[_address[i]] = _amount[i];
        }
    }
}