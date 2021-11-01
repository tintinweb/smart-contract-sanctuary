/**
 *Submitted for verification at Etherscan.io on 2021-11-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

    mapping(uint => Crowdsale) private idToCrowdsale;
    mapping(uint => mapping( address => uint)) private idToBalanceOfContributors; // crowdsale id,  user address to amount invested by user address TODO: balance of function
    mapping( address => uint[] ) private addressToListOfCrowdsales; // user address to list of crowdsales ids he is invested in

    uint public fee; //TODO: implement change fe function


    constructor(uint _fee, uint _checkInterval) {
        currentId = 0;
        admin = msg.sender;
        fee = _fee;
        checkInterval = _checkInterval;
        lastCheck = 0;
    }


 
    struct Crowdsale{
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

    
    function createCrowdsale(
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

        idToCrowdsale[currentId] = Crowdsale(
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

    function getCrowdsale(uint _id) external view returns(
        address owner
            )
        {
        require(idToCrowdsale[_id].initialized == true, "No crowdsale with this id");
        Crowdsale memory crowdsale = idToCrowdsale[_id];

        //TODO: add all crowdsale arguments

        return(
            crowdsale.owner
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
        checkCrowdsales();

        // We don't use the performData in this example. The performData is generated by the Keeper's call to your checkUpkeep function
    }   

    function checkCrowdsales() private {
        for(uint i=0; i < currentId; i++){
            // looping through all the crowdsales
            Crowdsale memory crowdsale = idToCrowdsale[i];
            if(block.timestamp >= crowdsale.endDate){
                // It means the crowdsale has ended
                endCrowdsale(crowdsale);
            }
        }
    }

    function endCrowdsale(Crowdsale memory _crowdsale) private {
        // TODO: Emit events
        // Crowdsale has ended, refund the money or give it to the owner according to the situation
        if(_crowdsale.currentAmount >= _crowdsale.goalAmount){
            // The crowdsale is successful, we can transfer the money to the owner
            payable(_crowdsale.owner).transfer(_crowdsale.currentAmount);
            
        }
        else{
            // refunding the investors
            for (uint i=0; i< _crowdsale.contributors.length ; i++) {
                address contributor = _crowdsale.contributors[i];
                uint refundAmount = idToBalanceOfContributors[_crowdsale.id][contributor];

                payable(contributor).transfer(refundAmount);
            }
        }

    }



}