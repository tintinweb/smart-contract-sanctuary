/**
 *Submitted for verification at Etherscan.io on 2021-11-10
*/

pragma solidity ^0.5.0;
interface ERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}
contract NiranaMeta{
    address public owner;
    address public MNUerc20;
    modifier onlyOwner() {
        require(owner==msg.sender, "Not an administrator");
        _;
    }
    struct user{
        uint256 total;
        uint256 releaseAmount;
        uint256 release;
        uint256 time;
    }
    mapping(address=>user)public users;
    constructor(address addr)public{
         owner=msg.sender;
         MNUerc20=addr;
     }
     function setRelease(address _addr,uint256 _total,uint256 _release)onlyOwner public{
         user storage _user=users[_addr];
         _user.total=_total;
         _user.release=_total*_release/100;
         //_user.time=block.timestamp;
         _user.time=1639832437;//2021-12-18 21:00:37
     }
    function withdrawMNU()public {
       user storage _user=users[msg.sender];
        require(_user.total>_user.releaseAmount,"All released");
        require(block.timestamp>_user.time,"It's not time yet");
        _user.releaseAmount+=_user.release;
        _user.time=block.timestamp+604800;
        ERC20(MNUerc20).transfer(msg.sender,_user.release);
    }
    function getUser(address addr)public view returns(uint256,uint256,uint256,uint256,uint256){
        user storage _user=users[addr];
        return (_user.total,_user.release,_user.releaseAmount,_user.total-_user.releaseAmount,_user.time);
    }
}