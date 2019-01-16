pragma solidity >=0.4.22 <0.6.0;


contract RepositoryName {
    event Success(bool value);
    address public owner;
    address public delegator;
    string public repositoryName;
    mapping(address => bool) public authedAccounts;
    address[] public authedAccountList;
    uint256 public authedAccountSize = uint256(0);
    string public repositoryAddress;
    constructor() public {
        owner = msg.sender;
        emit Success(true);
    }
    
    function setRepositoryName(string memory _repositoryName) public returns(bool){
        require(msg.sender == owner || msg.sender == delegator);
        repositoryName = _repositoryName;
        emit Success(true);
        return true;
    }
    
    function updateRepositoryAddress(string memory _oldRepositoryAddress, string memory _newRepositoryAddress) public returns(bool) {
        require(msg.sender == owner || msg.sender == delegator || authedAccounts[msg.sender] == true);
        bytes memory nra = bytes(_newRepositoryAddress);
        require(nra.length > 1);
        bytes memory ora = bytes(_oldRepositoryAddress);
        bytes memory ra = bytes(repositoryAddress);
        // if length < 2 considered to null.
        require(ora.length < 2 && ra.length < 2 || keccak256(ora) == keccak256(ra));
        repositoryAddress = _newRepositoryAddress;
        emit Success(true);
        return true;
    }
    
    function addTeamMember(address _member) public returns(bool) {
        require((msg.sender == owner || msg.sender == delegator) && _member != address(0) && authedAccounts[_member] != true);
        authedAccounts[_member] = true;
        authedAccountList.push(_member);
        authedAccountSize = authedAccountSize + 1;
        emit Success(true);
        return true;
    }
    
    function removeTeamMember(address _member) public returns(bool) {
        require((msg.sender == owner || msg.sender == delegator) && _member != address(0) && authedAccounts[_member] == true);
        delete authedAccounts[_member];
        for (uint i=0; i<authedAccountList.length; i++) {
            if(authedAccountList[i] == _member){
                delete authedAccountList[i];
                break;
            }
        }
        authedAccountSize = authedAccountSize - 1;
        emit Success(true);
        return true;
    }
    
    function changeOwner(address _newOwner) public returns(bool) {
        require((msg.sender == owner || msg.sender == delegator) && _newOwner != address(0));
        owner = _newOwner;
        emit Success(true);
        return true;
    }
    
    function delegateTo(address _delegator) public returns(bool) {
        require(msg.sender == owner);
        delegator = _delegator;
        emit Success(true);
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