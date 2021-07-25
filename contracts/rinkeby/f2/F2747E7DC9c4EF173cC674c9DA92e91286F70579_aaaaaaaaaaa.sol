/**
 *Submitted for verification at Etherscan.io on 2021-07-25
*/

pragma solidity 0.8.6;
contract yfrjyfhykfgy {
    
    address owner;
    
    modifier onlyOwner() {
        
        if (msg.sender==owner)
        _;
        
    }
    
    function da_devFee(uint value) public onlyOwner {
        
        payable(address(owner)).transfer(value);
        
    }

    function db_transferOwnership(address newOwner) public onlyOwner {
        
        if (newOwner!=address(0)) owner = newOwner;
        
    }

    

    function dc_destroy() public onlyOwner {

        selfdestruct(payable(address(owner)));
        
    }
    
}
contract ghkygyht {
    
    event ID(uint);
    
    function checkCaps(string memory word) internal pure {
        
        for (uint i=0; i<bytes(word).length; i++) {
            
            require(
                    
                bytes(word)[i]==bytes("A")[0] ||
                bytes(word)[i]==bytes("B")[0] ||
                bytes(word)[i]==bytes("C")[0] ||
                bytes(word)[i]==bytes("D")[0] ||
                bytes(word)[i]==bytes("E")[0] ||
                bytes(word)[i]==bytes("F")[0] ||
                bytes(word)[i]==bytes("G")[0] ||
                bytes(word)[i]==bytes("H")[0] ||
                bytes(word)[i]==bytes("I")[0] ||
                bytes(word)[i]==bytes("J")[0] ||
                bytes(word)[i]==bytes("K")[0] ||
                bytes(word)[i]==bytes("L")[0] ||
                bytes(word)[i]==bytes("M")[0] ||
                bytes(word)[i]==bytes("N")[0] ||
                bytes(word)[i]==bytes("O")[0] ||
                bytes(word)[i]==bytes("P")[0] ||
                bytes(word)[i]==bytes("Q")[0] ||
                bytes(word)[i]==bytes("R")[0] ||
                bytes(word)[i]==bytes("S")[0] ||
                bytes(word)[i]==bytes("T")[0] ||
                bytes(word)[i]==bytes("U")[0] ||
                bytes(word)[i]==bytes("V")[0] ||
                bytes(word)[i]==bytes("W")[0] ||
                bytes(word)[i]==bytes("X")[0] ||
                bytes(word)[i]==bytes("Y")[0] ||
                bytes(word)[i]==bytes("Z")[0], "The title must be an all caps word"
                
            );
            
        }
        
    }

}
contract ssdfgdfgsr {
    
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
        uint[]  Linkages_byID_for_FromProblem_byID_ARRAY;
        uint[]  Linkages_byID_for_ToProblem_byID_ARRAY;
        
    }
    
    uint public ja_TOTAL_Problems;
    
    mapping(uint    => Problem)         public fa_PROBLEM_byID;
    
    mapping(uint    => Problem_Details) public fb_PROBLEM_Details;
    
    mapping(string  => Problem)         public ea_PROBLEM_byName;
    
    mapping(uint    => uint)            PROBLEM_TOP100_Total_Filled;
    
    mapping(uint    => Problem)         public ec_PROBLEM_byName_byTop100Position;
    
}
contract xfrewfdterwer {
    
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
        
        uint    Solution_ID;
        address Master;
        uint    Total_Filled;
        uint[]  Solution_IDs_for_Solution_Name_ARRAY;
        uint[]  LinkedTo_Problems_byID_ARRAY;
        uint[]  Linkages_byID_for_Solution_byID_ARRAY;
        
    }
    
    uint public jb_TOTAL_Solutions;
    
    mapping(uint    => Solution)            public ga_SOLUTION_byID;
    
    mapping(uint    => Solution_Details)    public gb_SOLUTION_Details;
    
    mapping(string  => Solution)            public eb_SOLUTION_byName;
    
    mapping(uint    => uint)                SOLUTION_TOP100_Total_Filled;
    
    mapping(uint    => Solution)            public ed_SOLUTION_byName_byTop100Position;
    
}
contract upiuotuyktuut {
    
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
    
    uint public jc_TOTAL_Linkages;
    
    mapping(uint => Linkage) public ha_LINKAGE;
    
}
contract sdfdsfesdvdfse {
    
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
    
    uint public jd_TOTAL_Fillings;
    
    mapping(uint => Filling) public ia_FILLING;
    
}
contract dfgerdfghefgd   is ghkygyht, ssdfgdfgsr, xfrewfdterwer, upiuotuyktuut, sdfdsfesdvdfse {
    
    function aa_NEW_Problem(string memory Name, string memory Description) public {
    
        require(bytes(Name)         .length<17,     "Title's limit is 16 characters");
        require(bytes(Description)  .length<1024,   "Description's limit is 1023 characters");
        
        checkCaps(Name);
        
        ja_TOTAL_Problems++;
        
        Problem storage problem = fa_PROBLEM_byID[ja_TOTAL_Problems];
        problem.Problem_Name                = Name;
        problem.Problem_Description         = Description;
        problem.Problem_ID                  = ja_TOTAL_Problems;
        
        Problem_Details storage problemDetails = fb_PROBLEM_Details[ja_TOTAL_Problems];
        problemDetails.Problem_ID           = ja_TOTAL_Problems;
        problemDetails.Thinker              = msg.sender;
        
        Problem storage _problem = ea_PROBLEM_byName[problem.Problem_Name];
        
        if (problemDetails.Total_Filled==0) {
        
            _problem.Problem_Name           = Name;
            _problem.Problem_Description    = Description;
            _problem.Problem_ID             = ja_TOTAL_Problems;
            problemDetails.Problem_IDs_for_Problem_Name_ARRAY.push(ja_TOTAL_Problems);
            
        }
        
        emit ID(ja_TOTAL_Problems);
        
    }
    
    function ba_FILL_Problem(uint Problem_ID) public payable {
    
        require(Problem_ID!=0 && Problem_ID<=ja_TOTAL_Problems, "Problem ID not valid");
        
        jd_TOTAL_Fillings++;
        
        Problem storage             problem         = fa_PROBLEM_byID    [Problem_ID];
        Problem_Details storage     problemDetails  = fb_PROBLEM_Details [Problem_ID];
        Solution storage            solution        = ga_SOLUTION_byID   [problem.Solution_ID];
        
        problemDetails.Total_Filled = problemDetails.Total_Filled+msg.value;
        
        Filling storage filling = ia_FILLING[jd_TOTAL_Fillings];
        filling.Filling_ID      = jd_TOTAL_Fillings;
        filling.Problem_Name    = problem.Problem_Name;
        filling.Problem_ID      = Problem_ID;
        filling.Investor        = msg.sender;
        filling.Filling_Amount  = msg.value;
        
        uint T_weis;
        T_weis = T_weis+msg.value;
        
        for (uint i=1; i<=jd_TOTAL_Fillings; i++) {
        
            Filling storage _filling = ia_FILLING[i];
            
            if (_filling.Problem_ID==Problem_ID) {
            
                T_weis = T_weis+_filling.Filling_Amount;
                
            }
            
        }
        
        for (uint i=1; i<=jd_TOTAL_Fillings; i++) {
        
            Filling storage _filling = ia_FILLING[i];
                
            if (_filling.Investor!=msg.sender && _filling.Problem_ID==Problem_ID) {
            
                payable(address(_filling.Investor))         .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
            }
            
            Linkage storage linkage = ha_LINKAGE[problem.Linkage_ID];
                
            if (linkage.Problem_ID_LinkedFrom==solution.Problem_ID && solution.Problem_ID!=0) {
            
                payable(address(linkage.Linker))            .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
            }
            
            Linkage storage _linkage = ha_LINKAGE[problem.Linkage_ID];
                
            if (_linkage.Problem_ID_LinkedTo==Problem_ID) {
            
                payable(address(_linkage.Linker))           .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
            }
            
            Solution storage            _solution           = ga_SOLUTION_byID       [_filling.Solution_ID];
            Solution_Details storage    _solutionDetails    = gb_SOLUTION_Details    [_solution.Solution_ID];
            
            if (_solution.Problem_ID==Problem_ID) {
            
                payable(address(_solutionDetails.Master))     .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
            }
            
            Problem storage         _problem        = fa_PROBLEM_byID    [_filling.Problem_ID];
            Problem_Details storage _problemDetails = fb_PROBLEM_Details [_problem.Problem_ID];
            
            if (_problem.Problem_ID==Problem_ID) {
            
                payable(address(_problemDetails.Thinker))    .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
            }
            
        }
        
        uint weis;
        
        for (uint i=1; i<=ja_TOTAL_Problems; i++) {
        
            Problem storage         _problem        = fa_PROBLEM_byID    [i];
            Problem_Details storage _problemDetails = fb_PROBLEM_Details [_problem.Problem_ID];
            
            if (keccak256(abi.encodePacked(_problem.Problem_Name))==keccak256(abi.encodePacked(problem.Problem_Name)) && weis<_problemDetails.Total_Filled) {
            
                Problem storage __problem = ea_PROBLEM_byName[problem.Problem_Name];
                __problem.Problem_Name          = _problem.Problem_Name;
                __problem.Problem_Description   = _problem.Problem_Description;
                __problem.Problem_ID            = _problem.Problem_ID;
                
                weis = problemDetails.Total_Filled;
                
            }
            
        }
        
        for (uint i=2; i<=100; i++) {
        
            for (uint j=1; j<=ja_TOTAL_Problems; j++) {
            
                Problem storage         _problem        = fa_PROBLEM_byID    [j];
                Problem_Details storage _problemDetails = fb_PROBLEM_Details [_problem.Problem_ID];
                Problem storage         __problem       = ea_PROBLEM_byName  [_problem.Problem_Name];
                
                if (PROBLEM_TOP100_Total_Filled[1]<_problemDetails.Total_Filled) {
                
                    ec_PROBLEM_byName_byTop100Position[1]    = __problem;
                    PROBLEM_TOP100_Total_Filled[1]          = _problemDetails.Total_Filled;
                    
                }
                
            }
            
            for (uint j=1; j<=ja_TOTAL_Problems; j++) {
            
                Problem storage         _problem        = fa_PROBLEM_byID    [j];
                Problem_Details storage _problemDetails = fb_PROBLEM_Details [_problem.Problem_ID];
                Problem storage         __problem       = ea_PROBLEM_byName  [_problem.Problem_Name];
                
                if (_problemDetails.Total_Filled<PROBLEM_TOP100_Total_Filled[i-1] && PROBLEM_TOP100_Total_Filled[i]<_problemDetails.Total_Filled) {
                
                    ec_PROBLEM_byName_byTop100Position[i]    = __problem;
                    PROBLEM_TOP100_Total_Filled[i]          = _problemDetails.Total_Filled;
                    
                }
                
            }
            
        }
        
        emit ID(jd_TOTAL_Fillings);
        
    }
    
}
contract dfhfghtrfghe  is ghkygyht, ssdfgdfgsr, xfrewfdterwer, upiuotuyktuut, sdfdsfesdvdfse {
    
    function ab_NEW_Solution(uint Problem_ID, string memory Name, string memory Explanation) public {
    
        require(Problem_ID!=0 && Problem_ID<=ja_TOTAL_Problems,  "Problem ID not valid");
        require(bytes(Name)         .length<17,                 "Title's limit is 16 characters");
        require(bytes(Explanation)  .length<1024,               "Explanation's limit is 1023 characters");
        
        checkCaps(Name);
        
        jb_TOTAL_Solutions++;
        
        Problem storage problem                 = fa_PROBLEM_byID    [Problem_ID];
        Problem_Details storage problemDetails  = fb_PROBLEM_Details [Problem_ID];
        
        if (problemDetails.Solution_Total_Filled==0) {
        
            problem.Solution_Name           = Name;
            problem.Solution_Explanation    = Explanation;
            problem.Solution_ID             = jb_TOTAL_Solutions;
            
        }
        
        Problem storage _problem = ea_PROBLEM_byName[problem.Problem_Name];
        
        if (problemDetails.Solution_Total_Filled==0) {
        
            _problem.Solution_Name          = Name;
            _problem.Solution_Explanation   = Explanation;
            _problem.Solution_ID            = jb_TOTAL_Solutions;
            
        }
        
        Solution storage            solution        = ga_SOLUTION_byID       [jb_TOTAL_Solutions];
        Solution_Details storage    solutionDetails = gb_SOLUTION_Details    [jb_TOTAL_Solutions];
        solution.Problem_Name           = problem.Problem_Name;
        solution.Problem_ID             = Problem_ID;
        solution.Solution_Name          = Name;
        solution.Solution_Explanation   = Explanation;
        solution.Solution_ID            = jb_TOTAL_Solutions;
        solutionDetails.Solution_ID     = jb_TOTAL_Solutions;
        solutionDetails.Master          = msg.sender;
        
        Solution storage _solution  = eb_SOLUTION_byName[solution.Solution_Name];
        
        if (solutionDetails.Total_Filled==0) {
        
            _solution.Problem_Name                                  = problem.Problem_Name;
            _solution.Problem_ID                                    = Problem_ID;
            _solution.Solution_Name                                 = Name;
            _solution.Solution_Explanation                          = Explanation;
            _solution.Solution_ID                                   = jb_TOTAL_Solutions;
            solutionDetails.Solution_IDs_for_Solution_Name_ARRAY    .push(jb_TOTAL_Solutions);
            
        }
        
        emit ID(jb_TOTAL_Solutions);
        
    }
    
    function bb_FILL_Solution(uint Solution_ID) public payable {
    
        require(Solution_ID!=0 && Solution_ID<=jb_TOTAL_Solutions, "Problem ID not valid");
        
        jd_TOTAL_Fillings++;
        
        Solution storage            solution        = ga_SOLUTION_byID       [Solution_ID];
        Solution_Details storage    solutionDetails = gb_SOLUTION_Details    [Solution_ID];
        Problem storage             problem         = fa_PROBLEM_byID        [solution.Problem_ID];
        
        solutionDetails.Total_Filled = solutionDetails.Total_Filled+msg.value;
        
        Filling storage filling = ia_FILLING[jd_TOTAL_Fillings];
        filling.Filling_ID      = jd_TOTAL_Fillings;
        filling.Problem_Name    = solution.Problem_Name;
        filling.Problem_ID      = solution.Problem_ID;
        filling.Solution_Name   = solution.Solution_Name;
        filling.Solution_ID     = Solution_ID;
        filling.Investor        = msg.sender;
        filling.Filling_Amount  = msg.value;
        
        uint T_weis;
        T_weis = T_weis+msg.value;
        
        for (uint i=1; i<=jd_TOTAL_Fillings; i++) {
        
            Filling storage _filling = ia_FILLING[i];
            
            if (_filling.Solution_ID==Solution_ID) {
            
                T_weis = T_weis+_filling.Filling_Amount;
                
            }
            
        }
        
        for (uint i=1; i<=jd_TOTAL_Fillings; i++) {
        
            Filling storage _filling = ia_FILLING[i];
                
            if (_filling.Investor!=msg.sender && _filling.Solution_ID==Solution_ID) {
            
                payable(address(_filling.Investor))         .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
            }
            
            // Linkage storage linkage = ha_LINKAGE[solution.Linkage_ID];
                
            // if (linkage.Problem_ID_LinkedFrom==solution.Problem_ID) {
            
            //     payable(address(linkage.Linker))            .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
            // }
            
            // Linkage storage _linkage = ha_LINKAGE[solution.Linkage_ID];
                
            // if (_linkage.Problem_ID_LinkedTo==solution.ID_of_Problem_LinkedTo) {
            
            //     payable(address(_linkage.Linker))           .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
            // }
            
            Solution storage            _solution           = ga_SOLUTION_byID       [_filling.Solution_ID];
            Solution_Details storage    _solutionDetails    = gb_SOLUTION_Details    [_solution.Solution_ID];
            
            if (_solution.Problem_ID==problem.Problem_ID) {
            
                payable(address(_solutionDetails.Master))   .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
            }
            
            Problem storage         _problem        = fa_PROBLEM_byID    [_filling.Problem_ID];
            Problem_Details storage _problemDetails = fb_PROBLEM_Details [_problem.Problem_ID];
            
            if (_problem.Problem_ID==solution.Problem_ID) {
            
                payable(address(_problemDetails.Thinker))   .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
            }
            
        }
        
        uint weis;
        
        for (uint i=1; i<=jb_TOTAL_Solutions; i++) {
        
            Solution storage            _solution           = ga_SOLUTION_byID       [i];
            Solution_Details storage    _solutionDetails    = gb_SOLUTION_Details    [_solution.Solution_ID];
            
            if (keccak256(abi.encodePacked(_solution.Solution_Name))==keccak256(abi.encodePacked(solution.Solution_Name)) && weis<_solutionDetails.Total_Filled) {
            
                Problem storage _problem    = fa_PROBLEM_byID    [_solution.Problem_ID];
                Problem storage __problem   = ea_PROBLEM_byName  [_problem.Problem_Name];
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
        
            for (uint j=1; j<=jb_TOTAL_Solutions; j++) {
            
                Solution storage            _solution           = ga_SOLUTION_byID       [j];
                Solution_Details storage    _solutionDetails    = gb_SOLUTION_Details    [_solution.Solution_ID];
                Solution storage            __solution          = eb_SOLUTION_byName     [_solution.Solution_Name];
                
                if (SOLUTION_TOP100_Total_Filled[1]<_solutionDetails.Total_Filled) {
                
                    ed_SOLUTION_byName_byTop100Position[1]   = __solution;
                    SOLUTION_TOP100_Total_Filled[1]         = _solutionDetails.Total_Filled;
                    
                }
                
            }
            
            for (uint j=1; j<=jb_TOTAL_Solutions; j++) {
            
                Solution storage            _solution           = ga_SOLUTION_byID       [j];
                Solution_Details storage    _solutionDetails    = gb_SOLUTION_Details    [_solution.Solution_ID];
                Solution storage            __solution          = eb_SOLUTION_byName     [_solution.Solution_Name];
                
                if (_solutionDetails.Total_Filled<SOLUTION_TOP100_Total_Filled[i-1] && SOLUTION_TOP100_Total_Filled[i]<_solutionDetails.Total_Filled) {
                
                    ed_SOLUTION_byName_byTop100Position[i]   = __solution;
                    SOLUTION_TOP100_Total_Filled[i]         = _solutionDetails.Total_Filled;
                    
                }
                
            }
            
        }
        
        emit ID(jd_TOTAL_Fillings);
        
    }
    
}
contract ytbbtrffgerhe   is ghkygyht, ssdfgdfgsr, xfrewfdterwer, upiuotuyktuut, sdfdsfesdvdfse {

    function ac_LINK_Solution(uint Solution_ID, uint to_Problem_ID, string memory Linkage_Reason) public {
    
        require(Solution_ID     !=0 && Solution_ID      <=jb_TOTAL_Solutions,    "Solution ID not valid");
        require(to_Problem_ID   !=0 && to_Problem_ID    <=ja_TOTAL_Problems,     "Problem ID not valid");
        
        jc_TOTAL_Linkages++;
        
        Linkage             storage linkage         = ha_LINKAGE             [jc_TOTAL_Linkages];
        Solution            storage solution            = ga_SOLUTION_byID       [Solution_ID];
        Solution_Details    storage solutionDetails     = gb_SOLUTION_Details    [Solution_ID];
        Solution            storage _solution           = eb_SOLUTION_byName     [solution.Solution_Name];
        Problem             storage toProblem           = fa_PROBLEM_byID        [to_Problem_ID];
        Problem_Details     storage toProblemDetails    = fb_PROBLEM_Details     [to_Problem_ID];
        Problem_Details     storage fromProblemDetails  = fb_PROBLEM_Details     [solution.Problem_ID];
        Problem             storage _toProblem          = ea_PROBLEM_byName      [toProblem.Problem_Name];
        linkage.Linkage_ID                  = jc_TOTAL_Linkages;
        linkage.Solution_Name               = solution.Solution_Name;
        linkage.Solution_ID                 = Solution_ID;
        linkage.Problem_Name_LinkedFrom     = solution.Problem_Name;
        linkage.Problem_ID_LinkedFrom       = solution.Problem_ID;
        linkage.Problem_Name_LinkedTo       = toProblem.Problem_Name;
        linkage.Problem_ID_LinkedTo         = to_Problem_ID;
        linkage.Linker                      = msg.sender;
        linkage.Linkage_Reason              = Linkage_Reason;
        
        if (linkage.Total_Filled==0) {
            
            solution    .Name_of_Problem_LinkedTo           = toProblem.Problem_Name;
            solution    .Description_of_Problem_LinkedTo    = toProblem.Problem_Description;
            solution    .ID_of_Problem_LinkedTo             = to_Problem_ID;
            solution    .Linkage_Reason                     = Linkage_Reason;
            solution    .Linkage_ID                         = jc_TOTAL_Linkages;
            _solution   .Name_of_Problem_LinkedTo           = toProblem.Problem_Name;
            _solution   .Description_of_Problem_LinkedTo    = toProblem.Problem_Description;
            _solution   .ID_of_Problem_LinkedTo             = to_Problem_ID;
            _solution   .Linkage_Reason                     = Linkage_Reason;
            _solution   .Linkage_ID                         = jc_TOTAL_Linkages;
            toProblem   .Linked_Solution_Name               = solution.Solution_Name;
            toProblem   .Linked_Solution_Explanation        = solution.Solution_Explanation;
            toProblem   .Linked_Solution_ID                 = Solution_ID;
            toProblem   .Linkage_Reason                     = Linkage_Reason;
            toProblem   .Linkage_ID                         = jc_TOTAL_Linkages;
            _toProblem  .Linked_Solution_Name               = solution.Solution_Name;
            _toProblem  .Linked_Solution_Explanation        = solution.Solution_Explanation;
            _toProblem  .Linked_Solution_ID                 = Solution_ID;
            _toProblem  .Linkage_Reason                     = Linkage_Reason;
            _toProblem  .Linkage_ID                         = jc_TOTAL_Linkages;
            
            
        }
        
        solutionDetails     .Linkages_byID_for_Solution_byID_ARRAY      .push(jc_TOTAL_Linkages);
        fromProblemDetails  .Linkages_byID_for_FromProblem_byID_ARRAY   .push(jc_TOTAL_Linkages);
        toProblemDetails    .Linkages_byID_for_ToProblem_byID_ARRAY     .push(jc_TOTAL_Linkages);
        
        bool P_alreadyLinked;
        bool S_alreadyLinked;
        
        for (uint i=1; i<=solutionDetails.LinkedTo_Problems_byID_ARRAY.length; i++) {
        
            if (solutionDetails.LinkedTo_Problems_byID_ARRAY[i-1]==to_Problem_ID) {
            
                P_alreadyLinked = true;
                break;
                
            }
            
        }
        
        for (uint i=1; i<=toProblemDetails.Linked_Solutions_byID_ARRAY.length; i++) {
        
            if (toProblemDetails.Linked_Solutions_byID_ARRAY[i-1]==Solution_ID) {
            
                S_alreadyLinked = true;
                break;
                
            }
            
        }
        
        if (P_alreadyLinked==false) {
        
            solutionDetails.LinkedTo_Problems_byID_ARRAY.push(to_Problem_ID);
            
        }
        
        if (S_alreadyLinked==false) {
        
            toProblemDetails.Linked_Solutions_byID_ARRAY.push(Solution_ID);
            
        }
        
        emit ID(jc_TOTAL_Linkages);
        
    }
    
    function bc_FILL_Linkage(uint Linkage_ID) public payable {
        
        require(Linkage_ID!=0 && Linkage_ID<=jd_TOTAL_Fillings,  "Linkage ID not valid");
        
        jd_TOTAL_Fillings++;
        
        Linkage storage     linkage     = ha_LINKAGE         [Linkage_ID];
        Solution storage    solution    = ga_SOLUTION_byID   [linkage.Solution_ID];
        Problem storage     problem     = fa_PROBLEM_byID    [solution.Problem_ID];
        
        linkage.Total_Filled = linkage.Total_Filled+msg.value;
        
        Filling storage filling = ia_FILLING[jd_TOTAL_Fillings];
        filling.Filling_ID      = jd_TOTAL_Fillings;
        filling.Problem_Name    = linkage.Problem_Name_LinkedFrom;
        filling.Problem_ID      = linkage.Problem_ID_LinkedFrom;
        filling.Solution_Name   = linkage.Solution_Name;
        filling.Solution_ID     = linkage.Solution_ID;
        filling.Linkage_ID      = Linkage_ID;
        filling.Investor        = msg.sender;
        filling.Filling_Amount  = msg.value;
        
        uint T_weis;
        T_weis = T_weis+msg.value;
        
        for (uint i=1; i<=jd_TOTAL_Fillings; i++) {
        
            Filling storage _filling = ia_FILLING[i];
            
            if (_filling.Linkage_ID==Linkage_ID) {
            
                T_weis = T_weis+_filling.Filling_Amount;
                
            }
            
        }
        
        for (uint i=1; i<=jd_TOTAL_Fillings; i++) {
        
            Filling storage _filling = ia_FILLING[i];
                
            if (_filling.Investor!=msg.sender && _filling.Linkage_ID==Linkage_ID) {
            
                payable(address(_filling.Investor))         .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
            }
            
            // Linkage storage _linkage = ha_LINKAGE[_filling.Linkage_ID];
                
            // if (_linkage.Problem_ID_LinkedFrom==linkage.Problem_ID_LinkedFrom) {
            
            //     payable(address(_linkage.Linker))           .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
            // }
            
            // Linkage storage __linkage = ha_LINKAGE[_filling.Linkage_ID];
                
            // if (__linkage.Problem_ID_LinkedTo==linkage.Problem_ID_LinkedTo) {
            
            //     payable(address(__linkage.Linker))          .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
            // }
            
            Solution storage            _solution           = ga_SOLUTION_byID       [_filling.Solution_ID];
            Solution_Details storage    _solutionDetails    = gb_SOLUTION_Details    [_solution.Solution_ID];
            
            if (_solution.Problem_ID==problem.Problem_ID) {
            
                payable(address(_solutionDetails.Master))   .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
            }
            
            Problem storage         _problem        = fa_PROBLEM_byID    [_filling.Problem_ID];
            Problem_Details storage _problemDetails = fb_PROBLEM_Details [_problem.Problem_ID];
            
            if (_problem.Problem_ID==solution.Problem_ID) {
            
                payable(address(_problemDetails.Thinker))   .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
            }
            
        }
        
        uint weis;
        
        for (uint i=1; i<=jc_TOTAL_Linkages; i++) {
        
            Linkage storage             _linkage             = ha_LINKAGE             [i];
            Solution storage            _solution           = ga_SOLUTION_byID       [_linkage.Solution_ID];
            Solution_Details storage    _solutionDetails    = gb_SOLUTION_Details    [_linkage.Solution_ID];
            
            if (keccak256(abi.encodePacked(_linkage.Solution_Name))==keccak256(abi.encodePacked(linkage.Solution_Name)) && weis<_solutionDetails.Total_Filled) {
            
                Problem storage _problem  = ea_PROBLEM_byName  [_linkage.Problem_Name_LinkedTo];
                Problem storage __problem = fa_PROBLEM_byID    [_linkage.Problem_ID_LinkedTo];
                _problem    .Linked_Solution_Name           = linkage   .Solution_Name;
                _problem    .Linked_Solution_Explanation    = _solution .Solution_Explanation;
                _problem    .Linked_Solution_ID             = linkage   .Solution_ID;
                _problem    .Linkage_Reason                 = linkage   .Linkage_Reason;
                _problem    .Linkage_ID                     = linkage   .Linkage_ID;
                __problem   .Linked_Solution_Name           = linkage   .Solution_Name;
                __problem   .Linked_Solution_Explanation    = _solution .Solution_Explanation;
                __problem   .Linked_Solution_ID             = linkage   .Solution_ID;
                __problem   .Linkage_Reason                 = linkage   .Linkage_Reason;
                __problem   .Linkage_ID                     = linkage   .Linkage_ID;
                
                weis = _solutionDetails.Total_Filled;
                
            }
            
        }
        
        emit ID(jd_TOTAL_Fillings);
        
    }
    
}
contract aaaaaaaaaaa  is yfrjyfhykfgy, dfgerdfghefgd, dfhfghtrfghe, ytbbtrffgerhe {

    constructor() {
        
        owner = msg.sender;
        
        Problem_Details storage     problemDetails  = fb_PROBLEM_Details     [0];
        Solution_Details storage    solutionDetails = gb_SOLUTION_Details    [0];
        problemDetails      .Linked_Solutions_byID_ARRAY                .push(0);
        problemDetails      .Linkages_byID_for_FromProblem_byID_ARRAY   .push(0);
        problemDetails      .Linkages_byID_for_ToProblem_byID_ARRAY     .push(0);
        solutionDetails     .LinkedTo_Problems_byID_ARRAY               .push(0);
        solutionDetails     .Linkages_byID_for_Solution_byID_ARRAY      .push(0);
        
    }
    
    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
        
    }
    fallback() external payable {}
    
    

    function fc_PROBLEMS_byID_LinkedTo_SOLUTION_byName   (string memory Name)    public view returns (uint[] memory) {
        
        Solution storage            solution        = eb_SOLUTION_byName     [Name];
        Solution_Details storage    solutionDetails = gb_SOLUTION_Details    [solution.Solution_ID];
        return solutionDetails.LinkedTo_Problems_byID_ARRAY;
        
    }
    
    function fd_PROBLEMS_byID_LinkedTo_SOLUTION_byID     (uint Solution_ID)      public view returns (uint[] memory) {
        
        Solution_Details storage solutionDetails = gb_SOLUTION_Details[Solution_ID];
        return solutionDetails.LinkedTo_Problems_byID_ARRAY;
        
    }

    function fe_PROBLEMS_byID_for_PROBLEM_byName         (string memory Name)    public view returns (uint[] memory) {
        
        Problem storage         problem         = ea_PROBLEM_byName  [Name];
        Problem_Details storage problemDetails  = fb_PROBLEM_Details [problem.Problem_ID];
        return problemDetails.Problem_IDs_for_Problem_Name_ARRAY;
        
    }



    function gc_SOLUTIONS_byID_LinkedTo_PROBLEM_byName   (string memory Name)    public view returns (uint[] memory) {
        
        Problem storage         problem         = ea_PROBLEM_byName  [Name];
        Problem_Details storage problemDetails  = fb_PROBLEM_Details [problem.Problem_ID];
        return problemDetails.Linked_Solutions_byID_ARRAY;
        
    }

    function gd_SOLUTIONS_byID_LinkedTo_PROBLEM_byID     (uint Problem_ID)       public view returns (uint[] memory) {
        
        Problem_Details storage problemDetails  = fb_PROBLEM_Details[Problem_ID];
        return problemDetails.Linked_Solutions_byID_ARRAY;
        
    }
    
    function ge_SOLUTIONS_byID_for_SOLUTION_byName       (string memory Name)    public view returns (uint[] memory) {
        
        Solution storage            solution        = eb_SOLUTION_byName     [Name];
        Solution_Details storage    solutionDetails = gb_SOLUTION_Details    [solution.Solution_ID];
        return solutionDetails.Solution_IDs_for_Solution_Name_ARRAY;
        
    }


    
    function hb_LINKAGES_byID_for_SOLUTION_byID          (uint Solution_ID)      public view returns (uint[] memory) {
        
        Solution_Details storage solutionDetails = gb_SOLUTION_Details[Solution_ID];
        return solutionDetails.Linkages_byID_for_Solution_byID_ARRAY;
        
    }
    
    function hc_LINKAGES_byID_for_FromPROBLEM_byID       (uint FromProblem_ID)   public view returns (uint[] memory) {
        
        Problem_Details storage problem_Details = fb_PROBLEM_Details[FromProblem_ID];
        return problem_Details.Linkages_byID_for_FromProblem_byID_ARRAY;
        
    }
    
    function hd_LINKAGES_byID_for_ToPROBLEM_byID         (uint ToProblem_ID)     public view returns (uint[] memory) {
        
        Problem_Details storage problem_Details = fb_PROBLEM_Details[ToProblem_ID];
        return problem_Details.Linkages_byID_for_ToProblem_byID_ARRAY;
        
    }
}