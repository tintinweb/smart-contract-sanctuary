pragma solidity ^0.4.24;
contract Ballot {
    address[] public pendingUserlists;
    function giveRightToVote(address toVoter) public {
        uint j = 0;
        for(uint i = 0; i < pendingUserlists.length; i++) {
            if(pendingUserlists[i] == toVoter)
                j++;
        }
        if (j == 0)
            pendingUserlists.push(toVoter);
    }

    function winningProposal() public view returns (address[]) {
        return pendingUserlists;
    }
}