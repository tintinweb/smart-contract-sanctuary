// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// just for playcode
contract CurriculumVitae {
    
    string private _fullName = unicode"Vũ Quang Thịnh";
    string _email = "[email protected]";
    
    address myAddress;
    constructor() {
        myAddress = msg.sender;
    }
    
    modifier onlyOwner {
      require(msg.sender == myAddress);
      _;
    }

    function fullName() public view virtual returns (string memory) {
        return _fullName;
    }
    
    function updateEmail(string memory email_) public onlyOwner  {
        _email = email_;
    }

    function email() public view virtual returns (string memory) {
        return _email;
    }
    
    string[] private _skills;
    function updateSkill(string memory _skill)  public onlyOwner  {
        _skills.push(_skill);
    }

    function skills() public view virtual returns (string[] memory) {
        return _skills;
    }

    address[] private _projects;
    function updateProject(address _project) public onlyOwner {
        _projects.push(_project);
    }
    function projects() public view virtual returns (address[] memory) {
        return _projects;
    }
    
    string[] private _publications;
    function updatePublication(string memory _title) public onlyOwner  {
        _publications.push(_title);
    }
    function publications() public view virtual returns (string[] memory) {
        return _publications;
    }
    
    /**
     * You can send amount ETH include a note :))
     */
    function contactMe() public payable {
        (bool sent,) = myAddress.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}