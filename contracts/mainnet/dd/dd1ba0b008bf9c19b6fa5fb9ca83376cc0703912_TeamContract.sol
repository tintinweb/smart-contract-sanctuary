pragma solidity ^0.4.4;


contract TeamContract {

  address   contractOwner;
//sssss
  struct Team {
    //internal fields
    uint      index;
    address   owner;
    uint      lastUpdated;
    bool initialized;
    //generated fields
    string team; 
string lead; 
string size; 
string description; 
string github; 



  }

  mapping(bytes32 => Team) public teamMap;
  bytes32[] public teamArray;

  function TeamContract() public {
    contractOwner = msg.sender;
  }

  // Creates Team
  function createTeam(bytes32 id,
        //generated fields
        string team, string lead, string size, string description, string github)
        public returns (bool) {

    //team already exists
     require (teamMap[id].owner == address(0));

    //create new team
    //internal fields
    teamMap[id].index = teamArray.length;
    teamArray.push(id);
    teamMap[id].owner = msg.sender;
    teamMap[id].lastUpdated = now;
    //generated fields
    teamMap[id].team=team;
 teamMap[id].lead=lead;
 teamMap[id].size=size;
 teamMap[id].description=description;
 teamMap[id].github=github;
    TeamCreated(id,
        //generated fields - only param 1???
        team, lead, size, description, github);
    return true;
  }

  // Returns an Team by id
  function  readTeam(bytes32 id) constant public returns (address,uint,
      //generated fields
      string, string, string, string, string) {
    return (teamMap[id].owner, teamMap[id].lastUpdated,
      //generated fields
            teamMap[id].team, teamMap[id].lead, teamMap[id].size, teamMap[id].description, teamMap[id].github);
  }

  // Returns an Team by index
  function  readTeamByIndex(uint index) constant public returns (address,uint,
      //generated fields
        string, string, string, string, string) {
    require(index < teamArray.length);
    bytes32 id = teamArray[index];
    return (teamMap[id].owner, teamMap[id].lastUpdated,
      //generated fields
            teamMap[id].team, teamMap[id].lead, teamMap[id].size, teamMap[id].description, teamMap[id].github);
  }
 // Updates Team
  function updateTeam(bytes32 id,
        //generated fields
        string team, string lead, string size, string description, string github)
        public  returns (bool) {
    //team should exist
    require (teamMap[id].owner != address(0));
    require (teamMap[id].owner == msg.sender || contractOwner == msg.sender); //only team owner or contract owner can update

    teamMap[id].lastUpdated = now;
    //generated fields
    teamMap[id].team=team;
 teamMap[id].lead=lead;
 teamMap[id].size=size;
 teamMap[id].description=description;
 teamMap[id].github=github;
    TeamUpdated(id,
        //generated fields - only param 1???
        team, lead, size, description, github);
    return true;
  }

  // Deletes Team
  function deleteTeam  (bytes32 id) public  returns (bool) {
    //team should  exist
    require (teamMap[id].owner != address(0));
    require (teamMap[id].owner == msg.sender || contractOwner == msg.sender); //only team owner or contract owner can update

    var i = teamMap[id].index;
    var lastTeam = teamArray[teamArray.length-1];
    teamMap[lastTeam].index = i;
    teamArray[i] = lastTeam;
    teamArray.length--;


    TeamDeleted(id,
        //generated fields - only param 1???
        teamMap[id].team, teamMap[id].lead, teamMap[id].size, teamMap[id].description, teamMap[id].github );
    delete(teamMap[id]);
    return true;
  }

  // Returns teamCount
  function  countTeam() constant public returns (uint) {
    return teamArray.length;
  }


  event TeamCreated(bytes32 indexed _id,
        string team, string lead, string size, string description, string github);
  event TeamUpdated(bytes32 indexed _id,
        string team, string lead, string size, string description, string github);
  event TeamDeleted(bytes32 indexed _id,
        string team, string lead, string size, string description, string github);

}