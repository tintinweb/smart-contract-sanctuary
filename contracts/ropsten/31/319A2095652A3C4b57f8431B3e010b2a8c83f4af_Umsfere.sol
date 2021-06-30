/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

contract Ownable {
    
    address owner;
    
    modifier onlyOwner() {
        
        if (msg.sender == owner)
        _;
        
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        
        if (newOwner != address(0)) owner = newOwner;
        
    }
    
}

contract SafeMath {
    
  function safeMul  ( uint a, uint b ) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv  ( uint a, uint b ) internal pure returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub  ( uint a, uint b ) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd  ( uint a, uint b ) internal pure returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
  
}

contract Umsfere is Ownable, SafeMath {
    
    constructor() {
        
        owner = msg.sender;
        
    }

    function destroy() public onlyOwner {

        selfdestruct(payable(address(owner)));
        
    }
    
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
        uint    Total_Weis;
        string  Solution;
        uint    Solution_ID;

    }
    
    struct Solution {
        
        uint    Problem_ID;
        string  Description;
        uint    ID;
        address Posted_By;
        uint    Total_Weis;
        
    }
    
    mapping(string => Problem)  public PROBLEM;
    
    mapping(uint => Problem)    public PROBLEM_AllByID;
    mapping(uint => Solution)   public SOLUTION_AllByID;
    
    uint public TOTAL_Problems;
    uint public TOTAL_Solutions;
    
    struct P_Filling {
        
        uint ID;
        uint Problem_ID;
        uint Weis;
        
    }
    
    struct S_Filling {
        
        uint ID;
        uint Problem_ID;
        uint Solution_ID;
        uint Weis;
        
    }
    
    mapping(uint => P_Filling) P_FILLING;
    mapping(uint => S_Filling) S_FILLING;
    
    uint TOTAL_P_Fillings;
    uint TOTAL_S_Fillings;
    
    struct P_Filler {
        
        address Filler;
        uint    Total_Filled;
        
    }
    struct S_Filler {
        
        address Filler;
        uint    Total_Filled;
        
    }
    
    mapping(address => P_Filler) P_FILLER;
    mapping(address => S_Filler) S_FILLER;
    
    struct Posted_By {
        
        address addr;
        uint    Total_Weis;
        
    }
    
    mapping(address => Posted_By) POSTED_BY;
    
    function NEW_Problem(string memory Title, string memory Description) public {

        TOTAL_Problems++;

        Problem storage problem = PROBLEM_AllByID[TOTAL_Problems];
        problem.Title         = Title;
        problem.Description   = Description;
        problem.ID            = TOTAL_Problems;
        problem.Posted_By     = msg.sender;
        
        emit ID(TOTAL_Problems);
        
        Posted_By storage posted_by = POSTED_BY[msg.sender];
        posted_by.addr  = msg.sender;
        
    }
    
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
        
        Posted_By storage posted_by = POSTED_BY[msg.sender];
        posted_by.addr  = msg.sender;
        
    }
    
    function FILL_Problem(uint Problem_ID) payable public {
        
        require(100000<msg.value && Problem_ID!=0 && Problem_ID<=TOTAL_Problems);
        
        TOTAL_P_Fillings++;
        
        Problem storage problem = PROBLEM_AllByID[Problem_ID];
        
        problem.Total_Weis = safeAdd(problem.Total_Weis, msg.value);
        
        P_Filling storage p_filling = P_FILLING[TOTAL_P_Fillings];
        p_filling.ID            = TOTAL_P_Fillings;
        p_filling.Problem_ID    = Problem_ID;
        p_filling.Weis          = msg.value;
        
        uint i;
        uint j;
        uint PS_weis;
        PS_weis = safeAdd(PS_weis, msg.value);
        
        if (TOTAL_S_Fillings != 0) {
        
            for (i=1; i<=TOTAL_S_Fillings; i++) {
            
                S_Filling storage s_filling = S_FILLING[i];
            
                if (s_filling.Problem_ID == Problem_ID) {
                
                    PS_weis = safeAdd(PS_weis, s_filling.Weis);
                    
                }
                
            }
        
            for (j=1; j<=TOTAL_S_Fillings; j++) {
            
                S_Filling storage s_filling = S_FILLING[j];
                Solution storage solution = SOLUTION_AllByID[s_filling.Solution_ID];
                
                if (solution.Problem_ID == Problem_ID) {
                    
                    payable(address(solution.Posted_By)).transfer(safeDiv((safeMul(s_filling.Weis, (safeDiv((safeMul(s_filling.Weis, 1000000000000000000000000000000000000)), PS_weis)))), 1000000000000000000000000000000000000));
                    
                }
                
            }
            
        }
        
        payable(address(problem.Posted_By)).transfer(safeDiv((safeMul(msg.value, (safeDiv((safeMul(msg.value, 1000000000000000000000000000000000000)), PS_weis)))), 1000000000000000000000000000000000000));
        
        P_Filler storage p_filler = P_FILLER[msg.sender];
        p_filler.Filler        = msg.sender;
        p_filler.Total_Filled  = safeAdd(p_filler.Total_Filled, msg.value);
        
        Posted_By storage posted_by = POSTED_BY[problem.Posted_By];
        posted_by.Total_Weis  = safeAdd(posted_by.Total_Weis, msg.value);
        
        uint k;
        uint weis;
        string memory title = string(problem.Title);
        
        for (k=1; k<=TOTAL_Problems; k++) {
            
            Problem storage _problem = PROBLEM_AllByID[k];
        
            if (keccak256(abi.encodePacked(_problem.Title)) == keccak256(abi.encodePacked(problem.Title)) && weis < _problem.Total_Weis) {
                
                Problem storage __problem = PROBLEM[title];
                __problem.Title         = _problem.Title;
                __problem.Description   = _problem.Description;
                __problem.ID            = _problem.ID;
                __problem.Posted_By     = _problem.Posted_By;
                __problem.Total_Weis    = _problem.Total_Weis;
                
                weis = _problem.Total_Weis;
                
            }
                    
        }
        
    }
    
    function FILL_Solution(uint Solution_ID) payable public {
        
        require(100000<msg.value && Solution_ID!=0 && Solution_ID<=TOTAL_Solutions);
        
        TOTAL_S_Fillings++;
        
        Solution storage solution = SOLUTION_AllByID[Solution_ID];
        Problem storage problem = PROBLEM_AllByID[solution.Problem_ID];
        
        payable(address(this)).transfer(msg.value);
        solution.Total_Weis = solution.Total_Weis + msg.value;
        
        S_Filling storage s_filling = S_FILLING[TOTAL_S_Fillings];
        s_filling.ID            = TOTAL_S_Fillings;
        s_filling.Problem_ID    = solution.Problem_ID;
        s_filling.Solution_ID   = Solution_ID;
        s_filling.Weis          = msg.value;
        
        uint i;
        uint j;
        uint PS_weis;
        PS_weis = safeAdd(PS_weis, msg.value);
        
        if (TOTAL_S_Fillings != 0) {
        
            for (i=1; i<=TOTAL_S_Fillings; i++) {
                
                S_Filling storage _s_filling = S_FILLING[i];
            
                if (_s_filling.Problem_ID == problem.ID) {
                
                    PS_weis = safeAdd(PS_weis, _s_filling.Weis);
                    
                }
                
            }
        
            for (j=1; j<=TOTAL_S_Fillings; j++) {
            
                S_Filling storage __s_filling = S_FILLING[j];
                Solution storage _solution = SOLUTION_AllByID[__s_filling.Solution_ID];
                
                if (_solution.Problem_ID == problem.ID) {
                    
                    payable(address(solution.Posted_By)).transfer(safeDiv((safeMul(s_filling.Weis, (safeDiv((safeMul(s_filling.Weis, 1000000000000000000000000000000000000)), PS_weis)))), 1000000000000000000000000000000000000));
                    
                }
                
            }
            
        }
        
        payable(address(problem.Posted_By)) .transfer(safeDiv((safeMul(msg.value, (safeDiv((safeMul(msg.value, 500000000000000000000000000000000000)), PS_weis)))), 1000000000000000000000000000000000000));
        payable(address(solution.Posted_By)).transfer(safeDiv((safeMul(msg.value, (safeDiv((safeMul(msg.value, 500000000000000000000000000000000000)), PS_weis)))), 1000000000000000000000000000000000000));
        
        S_Filler storage s_filler = S_FILLER[msg.sender];
        s_filler.Filler        = msg.sender;
        s_filler.Total_Filled  = safeAdd(s_filler.Total_Filled, msg.value);
        
        Posted_By storage posted_by = POSTED_BY[solution.Posted_By];
        posted_by.Total_Weis  = safeAdd(posted_by.Total_Weis, msg.value);
        
        uint k;
        uint weis;
        
        for (k=1; k<=TOTAL_Solutions; k++) {
            
            Solution storage _solution = SOLUTION_AllByID[k];
        
            if (keccak256(abi.encodePacked(_solution.ID)) == keccak256(abi.encodePacked(Solution_ID)) && weis < _solution.Total_Weis) {
                
                Problem storage _problem    = PROBLEM_AllByID[_solution.Problem_ID];
                Problem storage __problem   = PROBLEM[_problem.Title];
                __problem.Solution      = _solution.Description;
                __problem.Solution_ID   = _solution.ID;
                
                weis = solution.Total_Weis;
            }
                    
        }
        
    }
    
    function devFee(uint value) public {
        
        payable(address(owner)).transfer(value);
        
    }
    
}