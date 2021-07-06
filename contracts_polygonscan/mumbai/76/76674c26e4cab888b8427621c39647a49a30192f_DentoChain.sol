/**
 *Submitted for verification at polygonscan.com on 2021-06-27
*/

// SPDX-License-Identifier: GPL-3.0-or-Later
pragma solidity ^0.8.4;

contract DentoChain {

    struct MedicList{
        string[] medics;
    }

    mapping(string => MedicList) reviewGrants;
    address owner;

    event Grant(string patient, string medic);
    event Duplicate(string patient, string medic);
    event Revoke(string patient, string medic);

    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner may call this function"
        );
        _;
    }

    constructor() {
        owner = msg.sender;
    }
    function compare(string memory _a, string memory _b) private pure returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        //@todo unroll the loop into increments of 32 and do full 32 byte comparisons
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }
    /// @dev Compares two strings and returns true iff they are equal.
    function equal(string memory _a, string memory _b) private pure returns (bool) {
        return compare(_a, _b) == 0;
    }
    /// @dev Finds the index of the first occurrence of _needle in _haystack
    function indexOf(string memory _haystack, string memory _needle) private pure returns (int)
    {
    	bytes memory h = bytes(_haystack);
    	bytes memory n = bytes(_needle);
    	if(h.length < 1 || n.length < 1 || (n.length > h.length)) 
    		return -1;
    	else if(h.length > (2**128 -1)) // since we have to be able to return -1 (if the char isn't found or input error), this function must return an "int" type with a max length of (2^128 - 1)
    		return -1;									
    	else
    	{
    		uint subindex = 0;
    		for (uint i = 0; i < h.length; i ++)
    		{
    			if (h[i] == n[0]) // found the first char of b
    			{
    				subindex = 1;
    				while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex]) // search until the chars don't match or until we reach the end of a or b
    				{
    					subindex++;
    				}	
    				if(subindex == n.length)
    					return int(i);
    			}
    		}
    		return -1;
    	}	
    }

    function getMedicsAsString(string memory patient) internal view returns (string memory medics) {
        uint i = 0;
        uint len = reviewGrants[patient].medics.length;

        string memory toReturn = "";

        for (i = 0; i < len; i += 1) {
            string memory currentMedic = reviewGrants[patient].medics[i];
            toReturn = string(abi.encodePacked(toReturn, currentMedic));
            if (i < len - 1) {
                toReturn = string(abi.encodePacked(toReturn, "|"));
            }
        }

        return toReturn;
    }
    function checkDuplicate(string memory patient, string memory medic) private view returns (bool duplicate) {
        uint i = 0;
        uint len = reviewGrants[patient].medics.length;

        for (i = 0; i < len; i+= 1) {
            string memory currentMedic = reviewGrants[patient].medics[i];

            if (equal(currentMedic, medic)) {
                return true;
            }
        }

        return false;
    }

    function grantRights(string memory patient, string memory medic) public onlyOwner returns (string memory currentGrants) {
        if (checkDuplicate(patient, medic)) {
            emit Duplicate(patient, medic);
            return getMedicsAsString(patient);
        }

        MedicList storage currentList = reviewGrants[patient];

        currentList.medics.push(medic);

        reviewGrants[patient] = currentList;

        emit Grant(patient, medic);

        return getMedicsAsString(patient);
    }

    function getRights(string calldata patient) public view onlyOwner returns (string memory currentGrants) {
        return getMedicsAsString(patient);
    }

    function revokeRights(string memory patient, string memory medic) public onlyOwner returns (string memory currentGrants) {
        uint i = 0;
        uint j = 0;
        uint len = reviewGrants[patient].medics.length;

        string[] memory newMedicList = new string[](len - 1);

        for (i = 0; i < len; i += 1) {
            if (equal(medic, reviewGrants[patient].medics[i]) == false) {
                newMedicList[j] = reviewGrants[patient].medics[i];
                j += 1;
            }
        }

        reviewGrants[patient].medics = newMedicList;

        emit Revoke(patient, medic);

        return getMedicsAsString(patient);
    }
}