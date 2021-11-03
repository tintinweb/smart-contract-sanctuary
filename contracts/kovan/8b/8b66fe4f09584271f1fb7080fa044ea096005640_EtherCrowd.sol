/**
 *Submitted for verification at Etherscan.io on 2021-11-02
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

interface KeeperCompatibleInterface {

  /**
   * @notice checks if the contract requires work to be done.
   * @param checkData data passed to the contract when checking for upkeep.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with,
   * if upkeep is needed.
   */
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );

  /**
   * @notice Performs work on the contract. Executed by the keepers, via the registry.
   * @param performData is the data which was passed back from the checkData
   * simulation.
   */
  function performUpkeep(
    bytes calldata performData
  ) external;
}
contract EtherCrowd is KeeperCompatibleInterface {

    uint private currentId;
    address admin;

    uint public checkInterval;
    uint public lastCheck;

    mapping(uint => Project) private idToProject;
    mapping(uint => mapping( address => uint)) private idToBalanceOfContributors; // crowdsale id,  user address to amount invested by user address TODO: balance of function
    mapping( address => uint[] ) private addressToListOfProjects; // user address to list of crowdsales ids he is invested in

    uint public fee; //TODO: implement change fe function


    constructor(uint _fee, uint _checkInterval) {
        currentId = 0;
        admin = msg.sender;
        fee = _fee;
        checkInterval = _checkInterval;
        lastCheck = 0;
    }

    struct Project{
        bool initialized;

        address owner;
        uint id;

        string title;
        string slogan;
        string description;

        string websiteUrl;
        string thumbnailUrl;
        string videoUrl;

        uint currentAmount;
        uint goalAmount;

        //TODO implement themes

        uint startDate; // TODO: implement
        uint endDate;
        bool isActive; // TODO ENUM: ISACTIVE; WILL BE ACTIVE; IS ENDED

        address[] contributors;
    }

    
    function createProject(
        uint _goalAmount,
        string memory _title,
        string memory _slogan,
        string memory _websiteUrl,
        string memory _videoUrl,
        string memory _thumbnailUrl,
        string memory _description,
        //  no need to specify start date, it is the time at which the user calls the function
        uint _endDate

    ) external payable{
        require(_endDate > 0, "End date has to be after start date");
        //require(idToCrowdsale[currentId].id != 0, "Crowdsale id already exists"); // if two crowdsales are created at the same time and thus get the same id

        // Payment to list on EtherCrowd 
        // Person has to send the exact fee with the function call, otherwise the transaction will be reverted
        if(msg.value != fee){
            revert("Incorrect value");
        }


        address[] memory _contributors; // creating a empty array

        idToProject[currentId] = Project(
                    true, // Crowdsale is initialized
                    msg.sender,
                    currentId, // is it necessary to repead the id here?
                    _title,
                    _slogan,
                    _description,
                    _websiteUrl,
                    _thumbnailUrl,
                    _videoUrl,
                    0, // current amount 0 
                    _goalAmount,
                    block.timestamp, // start date
                    block.timestamp + _endDate,
                    true, // isActive set to true by default, will not be the case later
                    _contributors
                );

        currentId++; // incrementing the current id

        // maybe returning the id of the crowdsale?
    }

    function getProject(uint _id) external view returns(
        address owner
            )
        {
        require(idToProject[_id].initialized == true, "No project with this id");
        Project memory project = idToProject[_id];

        //TODO: add all crowdsale arguments

        return(
            project.owner
            );


    }



    // ChainLink UpKeep part, maybe putting it in another file?

    function checkUpkeep(bytes calldata /*checkData*/) external override view returns (bool upkeepNeeded, bytes memory /*performData*/) {
        // This function will be executed Off chain by the Keeper node, this is why the computation is done here in order to save on gas fees
        upkeepNeeded = (block.timestamp - lastCheck) > checkInterval;
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(bytes calldata  /*performData*/ ) override external {
        lastCheck = block.timestamp;
        checkProjects();

        // We don't use the performData in this example. The performData is generated by the Keeper's call to your checkUpkeep function
    }   

    function checkProjects() private {
        for(uint i=0; i < currentId; i++){
            // looping through all the crowdsales
            Project memory project = idToProject[i];
            if(block.timestamp >= project.endDate){
                // It means the crowdsale has ended
                endProject(project);
            }
        }
    }

    function endProject(Project memory _project) private {
        // TODO: Emit events
        // Project has ended, refund the money or give it to the owner according to the situation
        if(_project.currentAmount >= _project.goalAmount){
            // The crowdsale is successful, we can transfer the money to the owner
            payable(_project.owner).transfer(_project.currentAmount);
            
        }
        else{
            // refunding the investors
            refund(_project);
        }

    }

    function refund(Project memory _project) private {
            for (uint i=0; i< _project.contributors.length ; i++) {
                address contributorAddress = _project.contributors[i];
                uint refundAmount = idToBalanceOfContributors[_project.id][contributorAddress];

                payable(contributorAddress).transfer(refundAmount);
            }

    }



    
    /** 
    Function fund, fund a crowd,
    takes a crowdid in parameter
    */
    function fund(uint _projectId) payable external {
        require(msg.value > 0, "No value sent.");
        require(idToProject[_projectId].initialized, "Project does not exist."); 
        require(idToProject[_projectId].isActive, "Project is not active");

        addressToListOfProjects[msg.sender].push(_projectId);
        idToBalanceOfContributors[_projectId][msg.sender] += msg.value;
    }
    
    function getInvestedFunds(uint _projectId) public view returns (uint) {
        require(idToProject[_projectId].initialized, "Project does not exist.");
        return idToBalanceOfContributors[_projectId][msg.sender];
    }
}