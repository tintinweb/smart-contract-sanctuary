/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;


contract HI {
    
    struct Problem {

        string  Title;
        string  Description;
        uint    ID;
        address Posted_By;
        uint    Weis;

    }
    
    mapping(uint => Problem) public PROBLEM_AllByID;
    
    mapping(string => Problem) public PROBLEM_Popular;
    
    uint public TOTAL_Problems;
    
    function NEW_Problem(string memory Title, string memory Description) public {

        TOTAL_Problems++;

        Problem storage problem = PROBLEM_AllByID[TOTAL_Problems];
        problem.Title         = Title;
        problem.Description   = Description;
        problem.ID            = TOTAL_Problems;
        problem.Posted_By     = msg.sender;
        
    }
    
    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
        
    }
    fallback() external payable {}
    
    function FILL_Problem(uint _ID) payable public {
        
        Problem storage problem = PROBLEM_AllByID[_ID];
        string memory title = string(problem.Title);
        
        require(0<_ID&&_ID<=TOTAL_Problems);
        
        payable(address(this)).transfer(msg.value);
        problem.Weis = problem.Weis + msg.value;
        
        uint i;
        uint weis;
        
        for (i=1; i<=TOTAL_Problems; i++) {
            
            Problem storage _problem = PROBLEM_AllByID[i];
        
            if (keccak256(abi.encodePacked(_problem.Title)) == keccak256(abi.encodePacked(problem.Title)) && weis < _problem.Weis) {
                
                Problem storage __problem = PROBLEM_Popular[title];
                __problem.Title        = _problem.Title;
                __problem.Description  = _problem.Description;
                __problem.ID           = _problem.ID;
                __problem.Posted_By    = _problem.Posted_By;
                __problem.Weis         = _problem.Weis;
                
                weis = _problem.Weis;
            }
                    
        }
                
    }
    
    struct Solution {
        
        string  Title;
        string  Description;
        uint    ID;
        address Posted_By;
        uint    Weis;
        
    }
    
    // TESTING  -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   
    
    function balance() view public returns (uint){
        return address(this).balance;
    }
    
    function GET_ETHERS(uint amount) public {
        payable(address(msg.sender)).transfer(amount);
    }

}