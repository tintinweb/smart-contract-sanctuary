/**
 *Submitted for verification at Etherscan.io on 2021-10-12
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

contract SmartGigs {

    uint public gigsCount;

    // Minimum freelancers compensation
    uint minimumCompensation = 100000000000000000;

    // Gig statuses
    enum Status { registered, open, review, awarded }


    // Gigs
    struct Gig {
        string name;
        uint compensation;
        Status status;
        address owner;
        // Number of Freelancers allowed to enroll
        uint8 freelancersNumber;
        // Number of Freelancers enrolled
        uint8 enrolled;
        uint8 works;
        address awardedTo;
    }

    mapping (uint => Gig) public gigs;


    // Works
    // @TODO: validate contractAddress (see README)
    struct Work {
        uint gigId;
        address owner;
        address contractAddress;
        bool valid;
    }

    // To get all Freelancers per gigId
    mapping (uint => address[]) public enrolledFreelancers;
    // To get all Works per Freelancer address
    mapping (address => Work[]) public worksByFreelancer;
    // To get all Works per gigId
    mapping (uint => Work[]) public worksByGig;


    // Events
    event LogGigStatusChange(uint gigId, Status);
    event LogEnrolled(uint gigId);
    event LogWorkSubmitted(uint gigId);


    // Modifiers
    modifier isOwner (address _address) {
        require (msg.sender == _address, "You are not the gig owner.");
        _;
    }

    modifier isNotOwner (address _address) {
        require (msg.sender != _address, "You are the gig owner, you can't enroll/submit work.");
        _;
    }

    modifier isStatusRegistered (uint _gigId) {
        require (gigs[_gigId].status == Status.registered, "You can't enroll to this gig.");
        _;
    }

    modifier isFreelancerEnrolled (uint _gigId) {
        require (isEnrolled(_gigId) == false, "You're already enrolled to this gig.");
        _;
    }


    constructor() {
        // Need to be initialized for iteration on createGig function
        gigsCount = 0;
    }


    function createGig (string memory _name, uint8 _freelancersNumber)
        public
        payable
        returns (bool)
    {

        require(
            msg.value >= minimumCompensation,
            "Below the required minimum compensation."
        );
        require(
            _freelancersNumber >= 1,
            "Below the required minimum freelancersNumber."
        );
        gigsCount += 1;
        // Adding Gig to gigs mapping
        gigs[gigsCount] = Gig({
            name: _name,
            compensation: msg.value,
            status: Status.registered,
            owner: msg.sender,
            freelancersNumber: _freelancersNumber,
            enrolled: 0,
            works: 0,
            awardedTo: address(0)
        });
        emit LogGigStatusChange(gigsCount, gigs[gigsCount].status);

        return true;
    }

    function enroll (uint _gigId)
        public
        payable
        isNotOwner(gigs[_gigId].owner)
        isStatusRegistered(_gigId)
        isFreelancerEnrolled(_gigId)
        returns (address)
    {

        // Push Freelancer address to enrolledFreelancers mapping Array
        enrolledFreelancers[_gigId].push(msg.sender);
        gigs[_gigId].enrolled += 1;
        // Update status when desired Freelancers number is reached
        if (enrolledFreelancers[_gigId].length == gigs[_gigId].freelancersNumber) {
            gigs[_gigId].status = Status.open;
            emit LogGigStatusChange(_gigId, gigs[_gigId].status);
        }
        emit LogEnrolled(_gigId);

        return msg.sender;

    }

    function isEnrolled (uint _gigId)
        public
        view
        isNotOwner(gigs[_gigId].owner)
        returns (bool)
    {

        bool enrolled = false;
        // Loop through enrolledFreelancers mapping Array
        for (uint i = 0; i < enrolledFreelancers[_gigId].length; i++) {
            // If sender is in Array
            if (enrolledFreelancers[_gigId][i] == msg.sender && !enrolled) {
                enrolled = true;
            }
        }

        return enrolled;

    }

    function hasAlreadySubmitToGig (uint _gigId)
        private
        view
        isNotOwner(gigs[_gigId].owner)
        returns (bool)
    {

        bool submitted = false;
        // Loop through worksByGig mapping Array
        for (uint i = 0; i < worksByGig[_gigId].length; i++) {
            // If sender is in Array
            if (worksByGig[_gigId][i].owner == msg.sender && !submitted) {
                submitted = true;
            }
        }

        return submitted;

    }

    // @TODO: _contractAddress should be a valid
    // deployed contract (testnet), with sender address as owner
    function submitWork (uint _gigId, address _contractAddress)
        public
        isNotOwner(gigs[_gigId].owner)
        returns (bool)
    {

        require(
            gigs[_gigId].status == Status.open,
            "Gig status is not valid."
        );
        require (
            isEnrolled(_gigId) == true,
            "You're not enrolled to this gig."
        );
        require (
            hasAlreadySubmitToGig(_gigId) == false,
            "You've already submit your work to this gig."
        );
        // Store work in local memory
        Work memory work = Work({
            gigId: _gigId,
            owner: msg.sender,
            contractAddress: _contractAddress,
            valid: true
        });
        // Push work in worksByGig mapping Array
        worksByGig[_gigId].push(work);
        // Push work in worksByFreelancer mapping Array
        worksByFreelancer[msg.sender].push(work);
        // Update gig works variable
        gigs[_gigId].works += 1;
        // If submitted work number == required number of Freelancers, status change
        if (worksByGig[_gigId].length == gigs[_gigId].freelancersNumber) {
            gigs[_gigId].status = Status.review;
            emit LogGigStatusChange(_gigId, gigs[_gigId].status);
        }
        emit LogWorkSubmitted(_gigId);

        return true;

    }

    function awardTo (uint _gigId, address _awardedFreelancer)
        public
        isOwner(gigs[_gigId].owner)
        returns (address)
    {

        require(
            gigs[_gigId].status == Status.review,
            "Gig status is not valid."
        );
        gigs[_gigId].awardedTo = _awardedFreelancer;
        gigs[_gigId].status = Status.awarded;
        emit LogGigStatusChange(_gigId, gigs[_gigId].status);
        transfer(gigs[_gigId].awardedTo, gigs[_gigId].compensation);

        return _awardedFreelancer;

    }
    function transfer(address _to, uint _amount) private {
        (bool success, ) = payable(_to).call{value: _amount}("");
        require(success, "Failed to send Ether.");
    }

}