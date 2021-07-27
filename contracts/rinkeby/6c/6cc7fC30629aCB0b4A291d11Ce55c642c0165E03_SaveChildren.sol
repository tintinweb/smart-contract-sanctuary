/**
 *Submitted for verification at Etherscan.io on 2021-07-27
*/

pragma solidity ^0.8.0;

contract SaveChildren{

    struct Campaign{
        string name;
        string description;
        string email;
        string imageUrl;
        address payable owner;
        uint256 timeCreated;
        uint256 blockDeadline;
        uint256 goal;
        uint256 raised;
        uint256 id;
        bool isFinished;
    }

    struct Donation{
        address payable from;
        uint256 amount;
    }

    //----------------------------FIELDS----------------

    address private owner = msg.sender;

    Campaign[] public campaigns;

    mapping(address => bool) public admins;

    mapping(uint256 => string[]) public mails;

    //map of all donors of a certain campaign
    mapping(uint256 => Donation[]) public donors;


    //----------------------------MODIFIERS----------------



    //----------------------------METHODS----------------

    fallback() external{
        revert();
    }

    function createCampaign(string memory _name, string memory _description, address _owner, uint256  _blockDeadline, uint256  _goal, string memory _email, string memory _url) public returns(bool){

        Campaign memory newCamp;
        newCamp.name = _name;
        newCamp.description = _description;
        newCamp.owner = payable(_owner);
        newCamp.timeCreated = block.timestamp;
        newCamp.blockDeadline = _blockDeadline;
        newCamp.goal = _goal;
        newCamp.isFinished = false;
        newCamp.email = _email;
        newCamp.imageUrl = _url;
        newCamp.id = campaigns.length;
        campaigns.push(newCamp);



        return true;
    }
    // payable funkcija - iz adrese u contract
    // payable adresa - contract salje na adresu

    function donate(uint256 id, string memory _email) external payable{

        require(!campaigns[id].isFinished, "The donation has finished");

        if(block.timestamp > campaigns[id].blockDeadline){
            campaigns[id].isFinished = true;
            emit CampaignFinished(id);
            revert();
        }

        address payable donor = payable(msg.sender);

        campaigns[id].owner.transfer(msg.value);
        campaigns[id].raised+=msg.value;

        Donation memory newDon;
        newDon.from = donor;
        newDon.amount = msg.value;

        donors[id].push(newDon);
        mails[id].push(_email);

//        if(campaigns[id].raised > campaigns[id].goal){
//            campaigns[id].isFinished = true;
//            emit CampaignFinished(id);
//        }

        emit DonationEvent(donor, msg.value, id);
    }

    function getDonorsLength(uint256 id) public view returns(uint256){
        return donors[id].length;
    }

    function getDonors(uint256 id) public view returns(Donation[] memory){
        return donors[id];
    }

    function getCampaignsLength() public view returns(uint256){
        return campaigns.length;
    }

    function getCampaigns() public view returns(Campaign[] memory){
        return campaigns;
    }
    
    function getMailsById(uint256 id) public view returns(string[] memory){
        return mails[id];
    }

    //----------------------------EVENTS----------------
    event DonationEvent(address payable from, uint256 amount, uint256 campId);

    event CampaignFinished(uint256 campId);
}