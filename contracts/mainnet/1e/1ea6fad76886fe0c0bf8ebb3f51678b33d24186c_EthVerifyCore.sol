pragma solidity ^0.4.18; // solhint-disable-line

contract EthVerifyCore{
    address public ceoAddress;
    mapping(address=>bool) public admins;
    mapping(address=>bool) public approvedContracts;
    mapping (address => bool) private verifiedUsers;
    
  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }
  modifier onlyAdmin() {
    require(admins[msg.sender]);
    _;
  }
    
    function EthVerifyCore() public{
        ceoAddress=msg.sender;
        admins[ceoAddress]=true;
    }
    function setCEO(address newCEO) public onlyCEO{
        ceoAddress=newCEO;
    }
    function addAdmin(address admin) public onlyCEO{
        admins[admin]=true;
    }
    function removeAdmin(address admin) public onlyCEO{
        admins[admin]=false;
    }
    function approveUser(address user) public onlyAdmin{
        verifiedUsers[user]=true;
    }
    function approveUsers(address[] addresses) public onlyAdmin{
        for(uint i = 0; i<addresses.length; i++){
            verifiedUsers[addresses[i]]=true;
        }
    }
    function disApproveUsers(address[] addresses) public onlyAdmin{
        for(uint i = 0; i<addresses.length; i++){
            verifiedUsers[addresses[i]]=false;
        }
    }
    function getUserStatus(address user) public view onlyAdmin returns(bool){
        return verifiedUsers[user];
    }
}