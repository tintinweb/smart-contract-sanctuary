/**
 *Submitted for verification at polygonscan.com on 2021-08-28
*/

contract SendMatic {
    function sendMatic(address payable[] memory _users, uint[] memory _amounts) public payable {
        for(uint i=0;i<_users.length;i++) {
            (_users[i]).transfer(_amounts[i]);
        }
        
    }
}