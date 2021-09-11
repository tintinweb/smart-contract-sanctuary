/**
 *Submitted for verification at Etherscan.io on 2021-09-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Charity {
    struct Request {
        address requester;
        uint256 amount_requested;
        string proof;
    }

    struct ReturnedRequestData {
        address requester;
        uint256 amount_requested;
        string proof;
        uint256 votes;
    }

    address[] public donors; // entire history of donators
    mapping(address => uint256) public donatedAmount; // donor to donated amount mapping
    uint256 public lastVoteEndTime;
    address[] public requesters; // entire history of requestors
    mapping(address => Request) public requests; // requestor to request mapping
    mapping(address => address) public donorVote; // donor to request mapping
    mapping(address => address[]) public requestorDonors; // requestor to donors mapping

    constructor() {
        lastVoteEndTime = block.timestamp;
    }

    function donate() external payable checkForStaleRequest {
        require(
            msg.value > 0.01 ether,
            "you have to donate more than 0.01 ETH!"
        );
        donors.push(msg.sender);
        donatedAmount[msg.sender] = msg.value;
    }

    modifier checkForStaleRequest() {
        _;
        if (block.timestamp - lastVoteEndTime > 7 minutes) {
            purgeRequest(getWinningRequestAddress());
            purgeDonors(getWinningRequestAddress());
            lastVoteEndTime = block.timestamp;
        }
    }

    function getNumberOfRequests() public view returns (uint256) {
        return requesters.length;
    }

    function purgeRequest(address requester) private {
        delete requests[requester];
        delete requestorDonors[requester];
    }

    function purgeDonors(address requester) private {
        address[] memory currentDonors = requestorDonors[requester];
        if (currentDonors.length > 0) {
            for (uint256 i = 0; i < currentDonors.length; i++) {
                delete donatedAmount[currentDonors[i]];
                delete donorVote[currentDonors[i]];
            }
        }
        delete requestorDonors[requester];
    }

    function new_request(uint256 requested_amount, string memory _proof)
        external
        checkForStaleRequest
    {
        require(
            requests[msg.sender].amount_requested == 0,
            "You already have a submitted request!"
        ); // the person should not have put up a request before
        Request memory request = Request({
            requester: msg.sender,
            amount_requested: requested_amount,
            proof: _proof
        });
        requests[msg.sender] = request;
        requesters.push(msg.sender);
        // if (!requestMapping[msg.sender]) {
        //     requestMapping[msg.sender] = request;
        //     requesters.push(msg.sender);
        // }
    }

    function voteForRequest(address requester_addr)
        external
        checkForStaleRequest
    {
        require(
            requests[requester_addr].amount_requested != 0,
            "request does not exist"
        ); // ensure that request for the corresponding requestor exists
        require(donorVote[msg.sender] == address(0), "you have already voted"); // check that donor has not voted for anyone yet
        donorVote[msg.sender] = requester_addr; // add voting for donor
        requestorDonors[requester_addr].push(msg.sender); // add donor to the requestors map
    }

    function getRequestVoteCount(address requester)
        public
        view
        returns (uint256)
    {
        return requestorDonors[requester].length;
    }

    function getLastVoteEndTime() public view returns (uint256) {
        return lastVoteEndTime;
    }

    // Todo remove duplicate requestors fom the map i.e keep track of repeated reqs and dont show. Had to be unique
    function getRequests() public view returns (ReturnedRequestData[] memory) {
        uint256 n = getNumberOfRequests();
        Request[] memory reqs = new Request[](n);
        uint256 x = 0;
        for (uint256 i = 0; i < n; i++) {
            bool isFound = false;
            for (uint256 j = 0; j < reqs.length; j++) {
                if (reqs[j].requester == requests[requesters[i]].requester) {
                    isFound = true;
                    break;
                }
            }
            if (!isFound) {
                reqs[x] = requests[requesters[i]];
                x += 1;
            }
        }

        ReturnedRequestData[] memory ret = new ReturnedRequestData[](
            reqs.length
        );
        for (uint256 i = 0; i < reqs.length; i++) {
            ret[i].requester = reqs[i].requester;
            ret[i].amount_requested = reqs[i].amount_requested;
            ret[i].proof = reqs[i].proof;
            ret[i].votes = requestorDonors[reqs[i].requester].length;
        }

        return ret;
    }

    function getRequestDetails(address requester)
        public
        view
        returns (uint256, string memory)
    {
        Request memory request = requests[requester];
        return (request.amount_requested, request.proof);
    }

    function getWinningRequest() public view returns (Request memory) {
        return requests[getWinningRequestAddress()];
    }

    function getWinningRequestAddress() public view returns (address) {
        uint256 highestVotes = 0;
        address winningRequestAddr;
        for (uint256 i = 0; i < requesters.length; i++) {
            address[] memory requestDonors = requestorDonors[requesters[i]];
            if (requestDonors.length > highestVotes) {
                highestVotes = requestDonors.length;
                winningRequestAddr = requesters[i];
            }
        }
        require(winningRequestAddr != address(0));
        return winningRequestAddr;
    }

    function withdraw() external {
        require(
            block.timestamp - lastVoteEndTime > 5 minutes,
            "the round has not ended yet!"
        );
        address winningAddress = getWinningRequestAddress();
        require(
            getWinningRequestAddress() == msg.sender,
            "You do not have the most votes this round :("
        );
        uint256 requestedAmount = requests[winningAddress].amount_requested;
        if (address(this).balance > requestedAmount) {
            payable(msg.sender).transfer(requestedAmount);
        } else {
            payable(msg.sender).transfer(address(this).balance);
        }
        purgeRequest(winningAddress);
        purgeDonors(winningAddress);
        lastVoteEndTime += 5 minutes;
    }
}