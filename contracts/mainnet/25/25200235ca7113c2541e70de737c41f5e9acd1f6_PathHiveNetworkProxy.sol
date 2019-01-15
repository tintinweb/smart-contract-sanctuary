pragma solidity ^0.4.25;

contract Ownable {
  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}

contract Role is Ownable {

    struct AdminGroup {
        mapping (address => bool) administers;
        mapping (address => uint) administerListIndex;
        address[] administerList;
        mapping (address => bool) pausers;
        mapping (address => uint) pauserListIndex;
        address[] pauserList;
    }

    AdminGroup private adminGroup;

    modifier administerAndAbove() {
        require(isAdminister(msg.sender) || msg.sender == owner);
        _;
    }

    modifier pauserAndAbove() {
        require(isPauser(msg.sender) || isAdminister(msg.sender) || msg.sender == owner);
        _;
    }

    function isAdminister(address account) public view returns (bool) {
        return adminGroup.administers[account];
    }

    function addAdminister(address account) public onlyOwner {
        require(!isAdminister(account));
        require(!isPauser(account));
        if (account == owner) { revert(); }
        adminGroup.administers[account] = true;
        adminGroup.administerListIndex[account] = adminGroup.administerList.push(account)-1;
        emit AdministerAdded(account);
    }

    function removeAdminister(address account) public onlyOwner {
        require(isAdminister(account));
        require(!isPauser(account));
        if (adminGroup.administerListIndex[account]==0){
            require(adminGroup.administerList[0] == account);
        }

        if (adminGroup.administerListIndex[account] >= adminGroup.administerList.length) return;

        adminGroup.administers[account] = false;

        for (uint i = adminGroup.administerListIndex[account]; i<adminGroup.administerList.length-1; i++){
            adminGroup.administerList[i] = adminGroup.administerList[i+1];
            adminGroup.administerListIndex[adminGroup.administerList[i+1]] = adminGroup.administerListIndex[adminGroup.administerList[i+1]]-1;
        }
        delete adminGroup.administerList[adminGroup.administerList.length-1];
        delete adminGroup.administerListIndex[account];
        adminGroup.administerList.length--;

        emit AdministerRemoved(account);
    }

    function getAdministerList() view public returns(address[]) {
        return adminGroup.administerList;
    }

    function isPauser(address account) public view returns (bool) {
        return adminGroup.pausers[account];
    }

    function addPauser(address account) public onlyOwner {
        require(!isAdminister(account));
        require(!isPauser(account));
        require(account != owner);
        adminGroup.pausers[account] = true;
        adminGroup.pauserListIndex[account] = adminGroup.pauserList.push(account)-1;
        emit PauserAdded(account);
    }

    function removePauser(address account) public onlyOwner{
        require(isPauser(account));
        require(!isAdminister(account));
        if (adminGroup.pauserListIndex[account]==0){
            require(adminGroup.pauserList[0] == account);
        }

        if (adminGroup.pauserListIndex[account] >= adminGroup.pauserList.length) return;

        adminGroup.pausers[account] = false;

        for (uint i = adminGroup.pauserListIndex[account]; i<adminGroup.pauserList.length-1; i++){
            adminGroup.pauserList[i] = adminGroup.pauserList[i+1];
            adminGroup.pauserListIndex[adminGroup.pauserList[i+1]] = adminGroup.pauserListIndex[adminGroup.pauserList[i+1]]-1;
        }
        delete adminGroup.pauserList[adminGroup.pauserList.length-1];
        delete adminGroup.pauserListIndex[account];
        adminGroup.pauserList.length--;

        emit PauserRemoved(account);
    }

    function getPauserList() view public returns(address[]) {
        return adminGroup.pauserList;
    }

    event AdministerAdded(address indexed account);
    event AdministerRemoved(address indexed account);
    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);
}

contract Proxy is Role {

    event Upgraded(address indexed implementation);

    address internal _linkedContractAddress;

    function implementation() public view returns (address) {
        return _linkedContractAddress;
    }

    function upgradeTo(address newContractAddress) public administerAndAbove {
        require(newContractAddress != address(0));
        _linkedContractAddress = newContractAddress;
        emit Upgraded(newContractAddress);
    }

    function () payable public {
        address _implementation = implementation();
        require(_implementation != address(0));
        bytes memory data = msg.data;

        assembly {
            let result := delegatecall(gas, _implementation, add(data, 0x20), mload(data), 0, 0)
            let size := returndatasize
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}

contract PathHiveNetworkProxy is Proxy {
    string public name = "PathHive Network";
    string public symbol = "PHV";
    uint8 public decimals = 18;

    constructor() public {}
}