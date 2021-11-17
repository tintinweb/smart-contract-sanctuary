/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

contract cidManager{
    string[] cids;
    function addCID(string memory cid) public{
        if(cids.length>2){
            cids = [''];
        }
        cids.push(cid);
    }
    function showCID() public view returns(string[] memory){
        return cids;
    }
}