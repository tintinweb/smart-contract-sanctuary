pragma solidity >=0.4.22 <0.6.0;


contract RepositoryName {
    address public owner;
    string public repositoryName;
    mapping(address => bool) public authedAccounts;
    address[] public authedAccountList;
    uint256 public authedAccountSize = uint256(0);
    string public repositoryAddress;
    constructor(string memory _repositoryName) public {
        owner = msg.sender;
        repositoryName = _repositoryName;
    }
    
    function updateRepositoryAddress(string memory _oldRepositoryAddress, string memory _newRepositoryAddress) public returns(bool) {
        require(msg.sender == owner || authedAccounts[msg.sender] == true);
        require(bytes(_newRepositoryAddress).length > 0);
        if(bytes(_oldRepositoryAddress).length == 0){
            if(bytes(repositoryAddress).length == 0){
                repositoryAddress = _newRepositoryAddress;
                return true;
            }
        }else{
            repositoryAddress = _newRepositoryAddress;
                return true;
        }
        return false;
    }
    
    function addTeamMember(address _member) public returns(bool) {
        require(msg.sender == owner && _member != address(0) && authedAccounts[_member] != true);
        authedAccounts[_member] = true;
        authedAccountList.push(_member);
        authedAccountSize = authedAccountSize + 1;
        return true;
    }
    
    function removeTeamMember(address _member) public returns(bool) {
        require(msg.sender == owner && _member != address(0) && authedAccounts[_member] == true);
        delete authedAccounts[_member];
        for (uint i=0; i<authedAccountList.length; i++) {
            if(authedAccountList[i] == _member){
                delete authedAccountList[i];
                break;
            }
        }
        authedAccountSize = authedAccountSize - 1;
        return true;
    }
    
    function hasTeamMember(address _member) public view returns (bool) {
        return authedAccounts[_member];
    }
    
    function teamMemberAtIndex(uint256 _index) public view returns (address) {
        require(_index < authedAccountList.length);
        return authedAccountList[_index];
    }
}