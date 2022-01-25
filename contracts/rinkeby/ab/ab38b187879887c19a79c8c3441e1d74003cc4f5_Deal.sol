/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
pragma experimental ABIEncoderV2;
contract Deal{
    struct DealInformation{
        uint256 job_id;
        address seller;
        address buyer;
        string job_date;
        string job_title;
        string job_description;
        uint256 job_payment;  
    }
   
    mapping(uint256 =>DealInformation) public info_object;
    uint256 [] job_information_array;
    function SetJobDetails(uint256 _job_id, address _seller, address _buyer, string memory _job_date, string memory _job_title,string memory _job_description, uint256 _job_payment) public returns (bool) 
    {
         if( keccak256(abi.encodePacked(info_object[_job_id].job_id)) == keccak256(abi.encodePacked(_job_id)) ) 
        {
            return false;
        }
        else
        {
            if(keccak256(abi.encodePacked(_job_title)) == keccak256(abi.encodePacked("")) )
            {
                return false;
            }
             if(keccak256(abi.encodePacked(_job_description)) == keccak256(abi.encodePacked("")) )
            {
                return false;
            }
             if(keccak256(abi.encodePacked(_job_date)) == keccak256(abi.encodePacked("")) )
            {
                return false;
            }
            require(_seller != address(0) ,"Seller address is not entered!");
            require(_buyer != address(0) ,"Buyer address is not entered!");
            require(_job_id != 0,"Job id is not entered!");
            require(_job_payment != 0,"Job Payment is not entered!");
          
            job_information_array.push(_job_id);
            info_object[_job_id].job_id = _job_id;
            info_object[_job_id].seller = _seller;
            info_object[_job_id].buyer = _buyer;
            info_object[_job_id].job_date = _job_date;
            info_object[_job_id].job_title = _job_title;
            info_object[_job_id].job_description = _job_description;
            info_object[_job_id].job_payment = _job_payment;
            return true;
        }
    }
        function All_Job_Data_array() public view returns(uint256[] memory)
        {
            return job_information_array;
        }
        function GetJobDetails(uint256 _job_id) public view returns(DealInformation memory )
        {
            return info_object[_job_id];
        }
}