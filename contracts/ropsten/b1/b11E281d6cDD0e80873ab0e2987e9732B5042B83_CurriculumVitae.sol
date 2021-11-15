// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// just for playcode
contract CurriculumVitae {
    
    string fullName = unicode"Vũ Quang Thịnh";
    string email = "[email protected]";
    
    address myAddress;
    constructor() {
        myAddress = msg.sender;
    }
    
    modifier onlyOwner {
      require(msg.sender == myAddress);
      _;
    }
    
    function updateEmail(string memory _email) public onlyOwner  {
        email = _email;
    }

    
    string[] skills;
    function updateSkill(string memory _skill)  public onlyOwner  {
        skills.push(_skill);
    }
    
    address[] projects;
    function updateProject(address _project) public onlyOwner {
        projects.push(_project);
    }
    
    string[] publications;
    function updatePublication(string memory _title) public onlyOwner  {
        publications.push(_title);
    }
    
    /**
     * You can send amount ETH include a note :))
     */
    function contactMe() public payable {
        (bool sent,) = myAddress.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }
}

