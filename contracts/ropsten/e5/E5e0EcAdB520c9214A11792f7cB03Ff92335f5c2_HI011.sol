/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;


contract HI011 {
    
    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
        
    }
    fallback() external payable {}
    
    event ID(uint);
    
    struct Problem {

        string  Title;
        string  Description;
        uint    ID;
        address Posted_By;
        uint    Weis;
        string  Solution;
        uint  Solution_ID;

    }
    
    mapping(string => Problem) public PROBLEM;
    
    mapping(uint => Problem) public PROBLEM_AllByID;
    
    uint public TOTAL_Problems;
    
    struct P_Filler {
        
        address addr;
        
    }
    
    mapping(address => P_Filler) P_FILLER;
    
    function NEW_Problem(string memory Title, string memory Description) public {

        TOTAL_Problems++;

        Problem storage problem = PROBLEM_AllByID[TOTAL_Problems];
        problem.Title         = Title;
        problem.Description   = Description;
        problem.ID            = TOTAL_Problems;
        problem.Posted_By     = msg.sender;
        
        emit ID(TOTAL_Problems);
        
    }
    
    function FILL_Problem(uint Problem_ID) payable public {
        
        Problem storage problem = PROBLEM_AllByID[Problem_ID];
        string memory title = string(problem.Title);
        
        require(0<Problem_ID&&Problem_ID<=TOTAL_Problems);
        
        payable(address(this)).transfer(msg.value);
        problem.Weis = problem.Weis + msg.value;
        
        P_Filler storage p_filler = P_FILLER[msg.sender];
        p_filler.addr = msg.sender;
        
        uint i;
        uint weis;
        
        for (i=1; i<=TOTAL_Problems; i++) {
            
            Problem storage _problem = PROBLEM_AllByID[i];
        
            if (keccak256(abi.encodePacked(_problem.Title)) == keccak256(abi.encodePacked(problem.Title)) && weis < _problem.Weis) {
                
                Problem storage __problem = PROBLEM[title];
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
        
        uint    Problem_ID;
        string  Description;
        uint    ID;
        address Posted_By;
        uint    Weis;
        
    }
    
    mapping(uint => Solution) public SOLUTION_AllByID;
    
    uint public TOTAL_Solutions;
    
    struct S_Filler {
        
        address addr;
        
    }
    
    mapping(address => S_Filler) S_FILLER;
    
    function NEW_Solution(uint Problem_ID, string memory Description) public {
        
        TOTAL_Solutions++;
        
        Solution storage solution = SOLUTION_AllByID[TOTAL_Solutions];
        solution.Problem_ID     = Problem_ID;
        solution.Description    = Description;
        solution.ID             = TOTAL_Solutions;
        solution.Posted_By      = msg.sender;

        Problem storage problem = PROBLEM_AllByID[Problem_ID];
        problem.Solution    = Description;
        problem.Solution_ID = TOTAL_Solutions;
        
        emit ID(TOTAL_Solutions);
        
    }
    
    function FILL_Solution(uint Solution_ID) payable public {
        
        Solution storage solution = SOLUTION_AllByID[Solution_ID];
        
        require(0<Solution_ID&&Solution_ID<=TOTAL_Solutions);
        
        payable(address(this)).transfer(msg.value);
        solution.Weis = solution.Weis + msg.value;
        
        S_Filler storage s_filler = S_FILLER[msg.sender];
        s_filler.addr = msg.sender;
        
        uint i;
        uint weis;
        
        for (i=1; i<=TOTAL_Solutions; i++) {
            
            Solution storage _solution = SOLUTION_AllByID[i];
        
            if (keccak256(abi.encodePacked(_solution.ID)) == keccak256(abi.encodePacked(Solution_ID)) && weis < _solution.Weis) {
                
                Problem storage problem = PROBLEM_AllByID[_solution.Problem_ID];
                Problem storage _problem = PROBLEM[problem.Title];
                _problem.Solution = _solution.Description;
                _problem.Solution_ID = _solution.ID;
                
                weis = solution.Weis;
            }
                    
        }
                
    }
    
    // TESTING  -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   
    
    function balance() view public returns (uint){
        return address(this).balance;
    }
    
    function GET_ETHERS(uint amount) public {
        payable(address(msg.sender)).transfer(amount);
    }

}