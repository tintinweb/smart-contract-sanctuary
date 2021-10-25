/**
 *Submitted for verification at Etherscan.io on 2021-10-24
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Web3Bounties {
    struct Bounty {
        string title;
        string problemStatement;
        uint256 price;
        address askerAddress;
        bool approved;
        uint solutionsLength;
        bool exists;
    }

    struct Solution {
        string solutionStatement;
        address solverAddress;
        uint approved_state;
        uint timestamp;
        uint bountyId;
        string rejectionReason;
    }

    Bounty[] bounties;
    mapping(uint => Solution[]) solutions;
    mapping(uint => uint) validSolutions;
    uint unsolvedBountiesCount = 0;

    function addBounty(string memory title, string memory problemStatement)
        public
        payable
    {
        Bounty memory bounty =  Bounty(
            title,
            problemStatement,
            msg.value,
            msg.sender,
            false,
            0,
            true
        );
        
        bounties.push(bounty);
        unsolvedBountiesCount++;
    }

    function addSolution(uint256 bountyId, string memory solutionStatement)
        public
    {
        require(bounties[bountyId].exists);
        
        Solution memory solution = Solution(
            solutionStatement,
            msg.sender,
            0,
            block.timestamp,
            bountyId,
            ""
        );
        
        solutions[bountyId].push(solution);
        validSolutions[bountyId]++;
        bounties[bountyId].solutionsLength++;
    }

    function approveSolution(
        uint256 solutionId,
        uint256 bountyId,
        uint256 payment_type
    ) public {
        require(!bounties[bountyId].approved, "Bounty is already solved");
        
        Solution memory solution = solutions[bountyId][solutionId];

        // split payment between solvers
        if (payment_type == 1) {
            require(validSolutions[bountyId] > 0, "No valid solutions exist.");
            
            bool sendToAll;
            
            for (uint i = 0; i < validSolutions[bountyId]; i++) {
                if(solutions[bountyId][i].approved_state == 0 
                && (block.timestamp - solutions[bountyId][i].timestamp) >= 14 days) {
                    sendToAll = true;
                    break;
                } 
            }
            
            if(sendToAll) {
                for (uint i = 0; i < validSolutions[bountyId]; i++) {
                    if(solutions[bountyId][i].approved_state == 0 ) {
                        address payable payTo = payable(solution.solverAddress);
                        payTo.transfer(bounties[bountyId].price / validSolutions[bountyId]);         
                    } 
                }
            }
        } else {
            require(msg.sender == bounties[bountyId].askerAddress);
            require(!bounties[bountyId].approved);
            (bool sent, ) = solution.solverAddress.call{value: bounties[bountyId].price}(
                ""
            );
            require(sent, "Failed to send Ether");

            solution.approved_state = 1;
        }
        
        bounties[bountyId].approved = true;
        unsolvedBountiesCount--;
    }

    function rejectSolution(
        uint256 solutionId,
        uint256 bountyId,
        string calldata rejectionReason
    ) public {
        require(!bounties[bountyId].approved, "Bounty is already solved");

        require(msg.sender == bounties[bountyId].askerAddress);
        require(!bounties[bountyId].approved);

        solutions[bountyId][solutionId].approved_state = 2;
        solutions[bountyId][solutionId].rejectionReason = rejectionReason;
        
        validSolutions[bountyId]--;
    }

    function getBounties() public view returns (Bounty[] memory) {
        return bounties;
    }
    
    function getUnsolvedBounties() public view returns (Bounty[] memory) {
        Bounty[] memory unsolvedBounties = new Bounty[](unsolvedBountiesCount);
        
        for(uint i=0; i < bounties.length; i++) {
            if(!bounties[i].approved) {
                unsolvedBounties[i] = (bounties[i]);
            }
        }
        
        return unsolvedBounties;
    }

    function getSolutions(uint256 bountyId)
        public
        view
        returns (Solution[] memory)
    {
        return solutions[bountyId];
    }
}