/**
 *Submitted for verification at Etherscan.io on 2021-07-20
*/

pragma solidity 0.8.6;
contract rweger {
    
    address owner;
    
    modifier onlyOwner() {
        
        if (msg.sender==owner)
        _;
        
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        
        if (newOwner!=address(0)) owner = newOwner;
        
    }
    
}
contract drhdf {
    
    event ID(uint);
    
    function checkCaps(string memory hfweg) internal pure {
        
        for (uint i=0; i<bytes(hfweg).length; i++) {
            
            require(
                    
                bytes(hfweg)[i]==bytes("A")[0] ||
                bytes(hfweg)[i]==bytes("B")[0] ||
                bytes(hfweg)[i]==bytes("C")[0] ||
                bytes(hfweg)[i]==bytes("D")[0] ||
                bytes(hfweg)[i]==bytes("E")[0] ||
                bytes(hfweg)[i]==bytes("F")[0] ||
                bytes(hfweg)[i]==bytes("G")[0] ||
                bytes(hfweg)[i]==bytes("H")[0] ||
                bytes(hfweg)[i]==bytes("I")[0] ||
                bytes(hfweg)[i]==bytes("J")[0] ||
                bytes(hfweg)[i]==bytes("K")[0] ||
                bytes(hfweg)[i]==bytes("L")[0] ||
                bytes(hfweg)[i]==bytes("M")[0] ||
                bytes(hfweg)[i]==bytes("N")[0] ||
                bytes(hfweg)[i]==bytes("O")[0] ||
                bytes(hfweg)[i]==bytes("P")[0] ||
                bytes(hfweg)[i]==bytes("Q")[0] ||
                bytes(hfweg)[i]==bytes("R")[0] ||
                bytes(hfweg)[i]==bytes("S")[0] ||
                bytes(hfweg)[i]==bytes("T")[0] ||
                bytes(hfweg)[i]==bytes("U")[0] ||
                bytes(hfweg)[i]==bytes("V")[0] ||
                bytes(hfweg)[i]==bytes("W")[0] ||
                bytes(hfweg)[i]==bytes("X")[0] ||
                bytes(hfweg)[i]==bytes("Y")[0] ||
                bytes(hfweg)[i]==bytes("Z")[0], "The title must be an all caps hfweg"
                
            );
            
        }
        
    }
    
}
contract ipukkuth {
    
    struct Problem {

        string  Problem_Name;
        string  Problem_Description;
        uint    Problem_ID;
        
        string  Solution_Name;
        string  Solution_Explanation;
        uint    Solution_ID;
        
        string  Linked_Solution_Name;
        string  Linked_Solution_Explanation;
        uint    Linked_Solution_ID;
        string  Linkage_Reason;
        uint    Linkage_ID;

    }
    
    struct Problem_Details {
        
        uint    Problem_ID;
        address Thinker;
        uint    Total_Filled;
        uint    Solution_Total_Filled;
        uint[]  Problem_IDs_for_Problem_Name_ARRAY;
        uint[]  Linked_Solutions_byID_ARRAY; 
        
    }
    
    uint public TOTAL_Problems;
    
    mapping(uint    => Problem)         public PROBLEM_byID;
    
    mapping(uint    => Problem_Details) public PROBLEM_Details;
    
    mapping(string  => Problem)         public PROBLEM_byName;
    
    mapping(uint    => uint)            lrfveoutvd;
    
    mapping(uint    => Problem)         public PROBLEM_byName_byTop100Position;
    
}
contract fdfthdfs {
    
    struct Solution {
        
        string  Problem_Name;
        uint    Problem_ID;
        string  Solution_Name;
        string  Solution_Explanation;
        uint    Solution_ID;
        
        string  Name_of_Problem_LinkedTo;
        string  Description_of_Problem_LinkedTo;
        uint    ID_of_Problem_LinkedTo;
        string  Linkage_Reason;
        uint    Linkage_ID;
        
    }
    
    struct Solution_Details {
        
        address Master;
        uint    Total_Filled;
        uint[]  Solution_IDs_for_Solution_Name_ARRAY;
        uint[]  LinkedTo_Problems_ARRAY; 
        
    }
    
    uint public TOTAL_Solutions;
    
    mapping(uint    => Solution)            public SOLUTION_byID;
    
    mapping(uint    => Solution_Details)    public SOLUTION_Details;
    
    mapping(string  => Solution)            public SOLUTION_byName;
    
    mapping(uint    => uint)                ncbgwkzerlth;
    
    mapping(uint    => Solution)            public SOLUTION_byName_byTop100Position;
    
}
contract qwedcdsd {
    
    struct Linkage {
        
        uint    Linkage_ID;
        string  Solution_Name;
        uint    Solution_ID;
        string  Problem_Name_LinkedFrom;
        uint    Problem_ID_LinkedFrom;
        string  Problem_Name_LinkedTo;
        uint    Problem_ID_LinkedTo;
        string  Linkage_Reason;
        address Linker;
        uint    Total_Filled;
        
    }
    
    uint public TOTAL_Linkages;
    
    mapping(uint    => Linkage)        public LINKAGE;
    
}
contract rettrevbd {
    
    struct Filling {
        
        uint    Filling_ID;
        string  Problem_Name;
        uint    Problem_ID;
        string  Solution_Name;
        uint    Solution_ID;
        uint    Linkage_ID;
        address Investor;
        uint    Filling_Amount;
        
    }
    
    uint public TOTAL_Fillings;
    
    mapping(uint    => Filling)     public FILLING;
    
}
contract lpqfsenf is ipukkuth, fdfthdfs, drhdf, rettrevbd {
    
    function NEW_Problem(string memory Name, string memory Description) public {
    
        require(bytes(Name)         .length<17,     "Title's limit is 16 characters");
        require(bytes(Description)  .length<1024,   "Description's limit is 1023 characters");
        
        checkCaps(Name);
        
        TOTAL_Problems++;
        
        Problem storage         problem         = PROBLEM_byID[TOTAL_Problems];
        problem.Problem_Name                = Name;
        problem.Problem_Description         = Description;
        problem.Problem_ID                  = TOTAL_Problems;
        
        Problem_Details storage problemDetails  = PROBLEM_Details[TOTAL_Problems];
        problemDetails.Problem_ID           = TOTAL_Problems;
        problemDetails.Thinker              = msg.sender;
        
        Problem storage         _problem        = PROBLEM_byName[problem.Problem_Name];
        
        if (problemDetails.Total_Filled==0) {
        
            _problem.Problem_Name           = Name;
            _problem.Problem_Description    = Description;
            _problem.Problem_ID             = TOTAL_Problems;
            problemDetails.Problem_IDs_for_Problem_Name_ARRAY.push(TOTAL_Problems);
            
        }
        
        emit ID(TOTAL_Problems);
        
    }
    
    function FILL_Problem(uint Problem_ID) public payable {
    
        require(Problem_ID!=0 && Problem_ID<=TOTAL_Problems, "Problem ID not valid");
        
        TOTAL_Fillings++;
        
        Problem storage             problem         = PROBLEM_byID[Problem_ID];
        Problem_Details storage     problemDetails  = PROBLEM_Details[problem.Problem_ID];
        
        problemDetails.Total_Filled = problemDetails.Total_Filled+msg.value;
        
        Filling storage filling = FILLING[TOTAL_Fillings];
        filling.Filling_ID      = TOTAL_Fillings;
        filling.Problem_Name    = problem.Problem_Name;
        filling.Problem_ID      = Problem_ID;
        filling.Investor        = msg.sender;
        filling.Filling_Amount  = msg.value;
        
        uint T_weis;
        T_weis = T_weis+msg.value;
        
        for (uint i=1; i<=TOTAL_Fillings; i++) {
        
            Filling storage _filling = FILLING[i];
            
            if (_filling.Problem_ID==Problem_ID) {
            
                T_weis = T_weis+_filling.Filling_Amount;
                
            }
            
        }
        
        for (uint i=1; i<=TOTAL_Fillings; i++) {
        
            Filling storage _filling = FILLING[i];
                
            if (_filling.Investor!=msg.sender) {
            
                payable(address(_filling.Investor))         .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
            }
            
            Solution storage            solution            = SOLUTION_byID     [_filling.Solution_ID];
            Solution_Details storage    _solutionDetails    = SOLUTION_Details  [solution.Solution_ID];
            
            if (solution.Problem_ID==Problem_ID) {
            
                payable(address(_solutionDetails.Master))     .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
            }
            
            Problem storage         _problem        = PROBLEM_byID      [_filling.Problem_ID];
            Problem_Details storage _problemDetails = PROBLEM_Details   [_problem.Problem_ID];
            
            if (_problem.Problem_ID==Problem_ID) {
            
                payable(address(_problemDetails.Thinker))    .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
            }
            
        }
        
        uint weis;
        
        for (uint i=1; i<=TOTAL_Problems; i++) {
        
            Problem storage         _problem        = PROBLEM_byID      [i];
            Problem_Details storage _problemDetails = PROBLEM_Details   [_problem.Problem_ID];
            
            if (keccak256(abi.encodePacked(_problem.Problem_Name))==keccak256(abi.encodePacked(problem.Problem_Name)) && weis<_problemDetails.Total_Filled) {
            
                Problem storage __problem = PROBLEM_byName[problem.Problem_Name];
                __problem.Problem_Name          = _problem.Problem_Name;
                __problem.Problem_Description   = _problem.Problem_Description;
                __problem.Problem_ID            = _problem.Problem_ID;
                
                weis = problemDetails.Total_Filled;
                
            }
            
        }
        
        for (uint i=2; i<=100; i++) {
        
            for (uint j=1; j<=TOTAL_Problems; j++) {
            
                Problem storage         _problem        = PROBLEM_byID      [j];
                Problem_Details storage _problemDetails = PROBLEM_Details   [_problem.Problem_ID];
                Problem storage         __problem       = PROBLEM_byName    [_problem.Problem_Name];
                
                if (lrfveoutvd[1]<_problemDetails.Total_Filled) {
                
                    PROBLEM_byName_byTop100Position[1]  = __problem;
                    lrfveoutvd[1]      = _problemDetails.Total_Filled;
                    
                }
                
            }
            
            for (uint j=1; j<=TOTAL_Problems; j++) {
            
                Problem storage         _problem        = PROBLEM_byID      [j];
                Problem_Details storage _problemDetails = PROBLEM_Details   [_problem.Problem_ID];
                Problem storage         __problem       = PROBLEM_byName    [_problem.Problem_Name];
                
                if (_problemDetails.Total_Filled<lrfveoutvd[i-1] && lrfveoutvd[i]<_problemDetails.Total_Filled) {
                
                    PROBLEM_byName_byTop100Position[i]  = __problem;
                    lrfveoutvd[i]      = _problemDetails.Total_Filled;
                    
                }
                
            }
            
        }
        
        emit ID(TOTAL_Fillings);
        
    }
    
}
contract dzmrhvbgw is ipukkuth, fdfthdfs, drhdf, rettrevbd {
    
    function NEW_Solution(uint Problem_ID, string memory Name, string memory Explanation) public {
    
        require(Problem_ID!=0 && Problem_ID<=TOTAL_Problems,    "Problem ID not valid");
        require(bytes(Name)         .length<17,                 "Title's limit is 16 characters");
        require(bytes(Explanation)  .length<1024,               "Explanation's limit is 1023 characters");
        
        checkCaps(Name);
        
        TOTAL_Solutions++;
        
        Problem storage problem                 = PROBLEM_byID[Problem_ID];
        Problem_Details storage problemDetails  = PROBLEM_Details[problem.Problem_ID];
        
        if (problemDetails.Solution_Total_Filled==0) {
        
            problem.Solution_Name                           = Name;
            problem.Solution_Explanation                    = Explanation;
            problem.Solution_ID                             = TOTAL_Solutions;
            
        }
        
        Problem storage _problem = PROBLEM_byName[problem.Problem_Name];
        
        if (problemDetails.Solution_Total_Filled==0) {
        
            _problem.Solution_Name                          = Name;
            _problem.Solution_Explanation                   = Explanation;
            _problem.Solution_ID                            = TOTAL_Solutions;
            
        }
        
        Solution storage            solution        = SOLUTION_byID     [TOTAL_Solutions];
        Solution_Details storage    solutionDetails = SOLUTION_Details  [solution.Solution_ID];
        solution.Problem_Name                               = problem.Problem_Name;
        solution.Problem_ID                                 = Problem_ID;
        solution.Solution_Name                              = Name;
        solution.Solution_Explanation                       = Explanation;
        solution.Solution_ID                                = TOTAL_Solutions;
        solutionDetails.Master                              = msg.sender;
        
        Solution storage _solution  = SOLUTION_byName[solution.Solution_Name];
        
        if (solutionDetails.Total_Filled==0) {
        
            _solution.Problem_Name                              = problem.Problem_Name;
            _solution.Problem_ID                                    = Problem_ID;
            _solution.Solution_Name                                 = Name;
            _solution.Solution_Explanation                          = Explanation;
            _solution.Solution_ID                                   = TOTAL_Solutions;
            solutionDetails.Solution_IDs_for_Solution_Name_ARRAY    .push(TOTAL_Solutions);
            
        }
        
        emit ID(TOTAL_Solutions);
        
    }
    
    function FILL_Solution(uint Solution_ID) public payable {
    
        require(Solution_ID!=0 && Solution_ID<=TOTAL_Solutions, "Problem ID not valid");
        
        TOTAL_Fillings++;
        
        Solution storage            solution        = SOLUTION_byID     [Solution_ID];
        Solution_Details storage    solutionDetails = SOLUTION_Details  [solution.Solution_ID];
        Problem storage             problem         = PROBLEM_byID      [solution.Problem_ID];
        
        solutionDetails.Total_Filled = solutionDetails.Total_Filled+msg.value;
        
        Filling storage filling = FILLING[TOTAL_Fillings];
        filling.Filling_ID      = TOTAL_Fillings;
        filling.Problem_Name    = solution.Problem_Name;
        filling.Problem_ID      = solution.Problem_ID;
        filling.Solution_Name   = solution.Solution_Name;
        filling.Solution_ID     = Solution_ID;
        filling.Investor        = msg.sender;
        filling.Filling_Amount  = msg.value;
        
        uint T_weis;
        T_weis = T_weis+msg.value;
        
        for (uint i=1; i<=TOTAL_Fillings; i++) {
        
            Filling storage _filling = FILLING[i];
            
            if (_filling.Solution_ID==Solution_ID) {
            
                T_weis = T_weis+_filling.Filling_Amount;
                
            }
            
        }
        
        for (uint i=1; i<=TOTAL_Fillings; i++) {
        
            Filling storage _filling = FILLING[i];
                
            if (_filling.Investor!=msg.sender) {
            
                payable(address(_filling.Investor))         .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
            }
            
            Solution storage            _solution           = SOLUTION_byID     [_filling.Solution_ID];
            Solution_Details storage    _solutionDetails    = SOLUTION_Details  [_solution.Solution_ID];
            
            if (_solution.Problem_ID==problem.Problem_ID) {
            
                payable(address(_solutionDetails.Master))   .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
            }
            
            Problem storage         _problem        = PROBLEM_byID      [_filling.Problem_ID];
            Problem_Details storage _problemDetails = PROBLEM_Details   [_problem.Problem_ID];
            
            if (_problem.Problem_ID==solution.Problem_ID) {
            
                payable(address(_problemDetails.Thinker))   .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
            }
            
        }
        
        uint weis;
        
        for (uint i=1; i<=TOTAL_Solutions; i++) {
        
            Solution storage            _solution           = SOLUTION_byID     [i];
            Solution_Details storage    _solutionDetails    = SOLUTION_Details  [_solution.Solution_ID];
            
            if (keccak256(abi.encodePacked(_solution.Solution_ID))==keccak256(abi.encodePacked(Solution_ID)) && weis<_solutionDetails.Total_Filled) {
            
                Problem storage _problem    = PROBLEM_byID[_solution.Problem_ID];
                Problem storage __problem   = PROBLEM_byName[_problem.Problem_Name];
                _problem    .Solution_Name          = solution  .Solution_Name;
                _problem    .Solution_Explanation   = solution  .Solution_Explanation;
                _problem    .Solution_ID            = solution  .Solution_ID;
                __problem   .Solution_Name          = _solution .Solution_Name;
                __problem   .Solution_Explanation   = _solution .Solution_Explanation;
                __problem   .Solution_ID            = _solution .Solution_ID;
                
                weis = _solutionDetails.Total_Filled;
                
            }
            
        }
        
        for (uint i=2; i<=100; i++) {
        
            for (uint j=1; j<=TOTAL_Solutions; j++) {
            
                Solution storage            _solution           = SOLUTION_byID     [j];
                Solution_Details storage    _solutionDetails    = SOLUTION_Details  [_solution.Solution_ID];
                Solution storage            __solution          = SOLUTION_byName   [_solution.Solution_Name];
                
                if (ncbgwkzerlth[1]<_solutionDetails.Total_Filled) {
                
                    SOLUTION_byName_byTop100Position[1] = __solution;
                    ncbgwkzerlth[1]     = _solutionDetails.Total_Filled;
                    
                }
                
            }
            
            for (uint j=1; j<=TOTAL_Solutions; j++) {
            
                Solution storage            _solution           = SOLUTION_byID     [j];
                Solution_Details storage    _solutionDetails    = SOLUTION_Details  [_solution.Solution_ID];
                Solution storage            __solution          = SOLUTION_byName   [_solution.Solution_Name];
                
                if (_solutionDetails.Total_Filled<ncbgwkzerlth[i-1] && ncbgwkzerlth[i]<_solutionDetails.Total_Filled) {
                
                    SOLUTION_byName_byTop100Position[i] = __solution;
                    ncbgwkzerlth[i]     = _solutionDetails.Total_Filled;
                    
                }
                
            }
            
        }
        
        emit ID(TOTAL_Fillings);
        
    }
    
}
contract sglehvbyh is qwedcdsd, ipukkuth, fdfthdfs, drhdf, rettrevbd {
    
    function LINK_Solution(uint Solution_ID, uint to_Problem_ID, string memory Linkage_Reason) public {
        
        require(Solution_ID     !=0 && Solution_ID      <=TOTAL_Solutions,  "Solution ID not valid");
        require(to_Problem_ID   !=0 && to_Problem_ID    <=TOTAL_Problems,   "Problem ID not valid");
        
        TOTAL_Linkages++;
        
        Linkage             storage linkage         = LINKAGE           [TOTAL_Linkages];
        Solution            storage solution        = SOLUTION_byID     [Solution_ID];
        Solution_Details    storage solutionDetails = SOLUTION_Details  [Solution_ID];
        Solution            storage _solution       = SOLUTION_byName   [solution.Solution_Name];
        Problem             storage problem         = PROBLEM_byID      [to_Problem_ID];
        Problem_Details     storage problemDetails  = PROBLEM_Details   [to_Problem_ID];
        Problem             storage _problem        = PROBLEM_byName    [problem.Problem_Name];
        linkage.Linkage_ID                      = TOTAL_Linkages;
        linkage.Solution_Name                   = solution.Solution_Name;
        linkage.Solution_ID                     = Solution_ID;
        linkage.Problem_Name_LinkedFrom         = solution.Problem_Name;
        linkage.Problem_ID_LinkedFrom           = solution.Problem_ID;
        linkage.Problem_Name_LinkedTo           = problem.Problem_Name;
        linkage.Problem_ID_LinkedTo             = to_Problem_ID;
        linkage.Linker                          = msg.sender;
        linkage.Linkage_Reason                  = Linkage_Reason;
        
        if (linkage.Total_Filled==0) {
            
            solution    .Name_of_Problem_LinkedTo           = problem.Problem_Name;
            solution    .Description_of_Problem_LinkedTo    = problem.Problem_Description;
            solution    .ID_of_Problem_LinkedTo             = to_Problem_ID;
            _solution   .Name_of_Problem_LinkedTo           = problem.Problem_Name;
            _solution   .Description_of_Problem_LinkedTo    = problem.Problem_Description;
            _solution   .ID_of_Problem_LinkedTo             = to_Problem_ID;
            problem     .Linked_Solution_Name               = solution.Solution_Name;
            problem     .Linked_Solution_Explanation        = solution.Solution_Explanation;
            problem     .Linked_Solution_ID                 = Solution_ID;
            _problem    .Linked_Solution_Name               = solution.Solution_Name;
            _problem    .Linked_Solution_Explanation        = solution.Solution_Explanation;
            _problem    .Linked_Solution_ID                 = Solution_ID;
            
        }
        
        bool alreadyLinkageed_1;
        
        for (uint i=1; i<=solutionDetails.LinkedTo_Problems_ARRAY.length; i++) {
            
            if (solutionDetails.LinkedTo_Problems_ARRAY[i]==to_Problem_ID) {
            
                alreadyLinkageed_1 = true;
                
            }
            
        }
        
        if (alreadyLinkageed_1==false) {
            
            solutionDetails.LinkedTo_Problems_ARRAY.push(to_Problem_ID);
                
        }
        
        bool alreadyLinkageed_2;
        
        for (uint i=1; i<=solutionDetails.LinkedTo_Problems_ARRAY.length; i++) {
            
            if (solutionDetails.LinkedTo_Problems_ARRAY[i]==to_Problem_ID) {
            
                alreadyLinkageed_2 = true;
                
            }
            
        }
        
        if (alreadyLinkageed_2==false) {
            
            solutionDetails.LinkedTo_Problems_ARRAY.push(to_Problem_ID);
                
        }
        
        bool alreadyLinkageed_3;
        
        for (uint i=1; i<=problemDetails.Linked_Solutions_byID_ARRAY.length; i++) {
            
            if (problemDetails.Linked_Solutions_byID_ARRAY[i]==Solution_ID) {
            
                alreadyLinkageed_3 = true;
                
            }
            
        }
        
        if (alreadyLinkageed_3==false) {
            
            problemDetails.Linked_Solutions_byID_ARRAY.push(Solution_ID);
                
        }
        
        bool alreadyLinkageed_4;
        
        for (uint i=1; i<=problemDetails.Linked_Solutions_byID_ARRAY.length; i++) {
            
            if (problemDetails.Linked_Solutions_byID_ARRAY[i]==Solution_ID) {
            
                alreadyLinkageed_4 = true;
                
            }
            
        }
        
        if (alreadyLinkageed_4==false) {
            
            problemDetails.Linked_Solutions_byID_ARRAY.push(Solution_ID);
                
        }
        
        emit ID(TOTAL_Linkages);
        
    }
    
    function FILL_Linkage(uint Linkage_ID) public payable {
        
        require(Linkage_ID!=0 && Linkage_ID<=TOTAL_Fillings,  "Linkage ID not valid");
        
        TOTAL_Fillings++;
        
        Linkage storage linkage   = LINKAGE[Linkage_ID];
        Solution storage solution   = SOLUTION_byID[linkage.Solution_ID];
        Problem storage problem     = PROBLEM_byID[solution.Problem_ID];
        
        linkage.Total_Filled = linkage.Total_Filled+msg.value;
        
        Filling storage filling = FILLING[TOTAL_Fillings];
        filling.Filling_ID      = TOTAL_Fillings;
        filling.Problem_Name    = linkage.Problem_Name_LinkedFrom;
        filling.Problem_ID      = linkage.Problem_ID_LinkedFrom;
        filling.Solution_Name   = linkage.Solution_Name;
        filling.Solution_ID     = linkage.Solution_ID;
        filling.Linkage_ID      = Linkage_ID;
        filling.Investor        = msg.sender;
        filling.Filling_Amount  = msg.value;
        
        uint T_weis;
        T_weis = T_weis+msg.value;
        
        for (uint i=1; i<=TOTAL_Fillings; i++) {
        
            Filling storage _filling = FILLING[i];
            
            if (_filling.Linkage_ID==Linkage_ID) {
            
                T_weis = T_weis+_filling.Filling_Amount;
                
            }
            
        }
        
        for (uint i=1; i<=TOTAL_Fillings; i++) {
        
            Filling storage _filling = FILLING[i];
                
            if (_filling.Investor!=msg.sender) {
            
                payable(address(_filling.Investor))         .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
            }
            
            Solution storage            _solution           = SOLUTION_byID     [_filling.Solution_ID];
            Solution_Details storage    _solutionDetails    = SOLUTION_Details  [_solution.Solution_ID];
            
            if (_solution.Problem_ID==problem.Problem_ID) {
            
                payable(address(_solutionDetails.Master))   .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
            }
            
            Problem storage         _problem        = PROBLEM_byID      [_filling.Problem_ID];
            Problem_Details storage _problemDetails = PROBLEM_Details   [_problem.Problem_ID];
            
            if (_problem.Problem_ID==solution.Problem_ID) {
            
                payable(address(_problemDetails.Thinker))   .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
            }
            
        }
        
        
        
        emit ID(TOTAL_Fillings);
        
    }
    
}
contract Huintsphe is rweger, lpqfsenf, dzmrhvbgw, sglehvbyh {

    constructor() {
        
        owner = msg.sender;
        
        Problem_Details storage     problemDetails  = PROBLEM_Details   [0];
        Solution_Details storage    solutionDetails = SOLUTION_Details  [0];
        problemDetails      .Linked_Solutions_byID_ARRAY    .push(0);
        solutionDetails     .LinkedTo_Problems_ARRAY        .push(0);
        
    }
    
    function destroy() public onlyOwner {

        selfdestruct(payable(address(owner)));
        
    }
    
    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
        
    }
    fallback() external payable {}
    
    function devFee(uint value) public onlyOwner {
        
        payable(address(owner)).transfer(value);
        
    }
    
    
    
    function SOLUTIONS_LinkageedTo_PROBLEM_byTitle (string memory Name)    public view returns (uint[] memory) {
        
        Problem storage         problem         = PROBLEM_byName    [Name];
        Problem_Details storage problemDetails  = PROBLEM_Details   [problem.Problem_ID];
        return problemDetails.Linked_Solutions_byID_ARRAY;
        
    }
    
    function SOLUTIONS_LinkageedTo_PROBLEM_byID    (uint Problem_ID)       public view returns (uint[] memory) {
        
        Problem_Details storage problemDetails  = PROBLEM_Details[Problem_ID];
        return problemDetails.Linked_Solutions_byID_ARRAY;
        
    }
    
    function PROBLEMS_byIDs_for_Problem_Title   (string memory Name)    public view returns (uint[] memory) {
        
        Problem storage         problem         = PROBLEM_byName    [Name];
        Problem_Details storage problemDetails  = PROBLEM_Details   [problem.Problem_ID];
        return problemDetails.Problem_IDs_for_Problem_Name_ARRAY;
        
    }
    
    function PROBLEMS_byID_LinkageedTo_SOLUTION    (uint Solution_ID)      public view returns (uint[] memory) {
        
        Solution_Details storage solutionDetails = SOLUTION_Details[Solution_ID];
        return solutionDetails.LinkedTo_Problems_ARRAY;
        
    }
    
    function SOLUTIONS_byIDs_for_Solution_Title (string memory Name)    public view returns (uint[] memory) {
        
        Solution storage            solution        = SOLUTION_byName   [Name];
        Solution_Details storage    solutionDetails = SOLUTION_Details  [solution.Solution_ID];
        return solutionDetails.Solution_IDs_for_Solution_Name_ARRAY;
        
    }
    
}