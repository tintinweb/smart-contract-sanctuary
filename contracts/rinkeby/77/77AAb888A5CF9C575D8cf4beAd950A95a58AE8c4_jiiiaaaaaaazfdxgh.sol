/**
 *Submitted for verification at Etherscan.io on 2021-09-04
*/

pragma solidity 0.8.7;
library Rshbuvh {
    


    struct      Ownership {
        
        address     Owner_Address;
        
        string[]    Phisphers_byName;
        uint[]      Phisphers_byID;
        
        string[]    Responses_byName;
        uint[]      Responses_byID;
        
        uint[]      Fillings_byID;
        
        uint[]      Linkages_byID;
        
    }
    
    
    
    struct      Phispher {
        
        string  Phispher_Name;
        string  Phispher_Description;
        uint    Phispher_ID;
        
        string  Response_Name;
        string  Response_Comment;
        uint    Response_ID;
        
        string  Linked_Response_Name;
        string  Linked_Response_Comment;
        uint    Linked_Response_ID;
        string  Linkage_Reason;
        uint    Linkage_ID;
        
    }
    
    struct      Phispher_Details {
    
        uint        Phispher_ID;
        address     Phispher_Owner;
        uint        Selling_Price;
        
        uint        Total_Filled;
        uint        Response_Total_Filled;
        
        string[]    ALL_Responses_byName_for_Phispher_ARRAY;
        uint[]      ALL_Responses_byID_for_Phispher_ARRAY;
        
        uint[]      ALL_Responses_byID_LinkedTo_Phispher_ARRAY;
        uint[]      ALL_Linkages_byID_for_FromPhispher_ARRAY;
        uint[]      ALL_Linkages_byID_for_ToPhispher_ARRAY;
        uint[]      ALL_Fillings_byID_for_Phispher_ARRAY;
        
    }
    
    
    
    struct      Response {
        
        string  Phispher_Name;
        uint    Phispher_ID;
        
        string  Response_Name;
        string  Response_Comment;
        uint    Response_ID;
        
        string  Name_of_Phispher_LinkedTo;
        string  Description_of_Phispher_LinkedTo;
        uint    ID_of_Phispher_LinkedTo;
        string  Linkage_Reason;
        uint    Linkage_ID;
        
    }
    
    struct      Response_Details {
    
        uint    Response_ID;
        address Response_Owner;
        uint    Selling_Price;
        
        uint    Total_Filled;
        
        uint[]  ALL_Phisphers_byID_LinkedTo_Response_ARRAY;
        uint[]  ALL_Linkages_byID_for_Response_ARRAY;
        uint[]  ALL_Fillings_byID_for_Response_ARRAY;
        
    }
    
    
    
    struct      Linkage {
        
        string  Phispher_Name_LinkedFrom;
        uint    Phispher_ID_LinkedFrom;
        
        string  Response_Name;
        uint    Response_ID;
        
        string  Phispher_Name_LinkedTo;
        uint    Phispher_ID_LinkedTo;
        
        string  Linkage_Reason;
        uint    Linkage_ID;
        
    }
    
    struct      Linkage_Details {
        
        uint    Linkage_ID;
        address Linkage_Owner;
        uint    Selling_Price;
        
        uint    Total_Filled;
        
        uint[]  ALL_Fillings_byID_for_Linkage_ARRAY;
        
    }
    
    
    
    struct      Filling {
    
        uint    Filling_ID;
        
        string  Phispher_Name;
        uint    Phispher_ID;
        
        string  Response_Name;
        uint    Response_ID;
        
        uint    Linkage_ID;
        
        address Investor;
        
        uint    Filling_Amount;
        
    }
    
    
    
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
                bytes(word)[i]==bytes("Z")[0] ||
                bytes(word)[i]==bytes(" ")[0], "Only all-cap characters and spaces are allowed"
                
            );
            
        }
        
    }
    


}
contract kjmf {

    address dev;
    
    modifier onlydev() {
    
        if (msg.sender==dev)
        _;
        
    }
    
    
    
    function da_devFee(uint amount) public onlydev {
    
        payable(address(dev)).transfer(amount);
        
    }
    
    function db_changeDev(address newdev) public onlydev {
    
        if (newdev!=address(0)) dev = newdev;
        
    }
    
    function dc_destroy() public onlydev {
    
        selfdestruct(payable(address(dev)));
        
    }
    
}
contract lgdsggvy {

    
    
    uint public Top_Index = 10;
    
    
    
    uint public ja_TOTAL_Phisphers;
    
    uint public jb_TOTAL_Responses;
    
    uint public jc_TOTAL_Linkages;
    
    
    uint public jd_TOTAL_Fillings;
    
    
    
    mapping(address  => Rshbuvh.Ownership)          public OWNERSHIP_byAddress;
    
    
    
    mapping(uint    => Rshbuvh.Phispher)            public fa_PHISPHER_byID;
    
    mapping(uint    => Rshbuvh.Phispher_Details)    public fb_PHISPHER_Details;
    
    mapping(string  => Rshbuvh.Phispher)            public ea_PHISPHER_byName;
    
    mapping(string  => uint[])                      ALL_PHISPHERS_byID_for_PHISPHER_byName;
    
    // mapping(uint    => uint)                        PHISPHER_TopIndex_byTotalFilled;
    
    // mapping(uint    => Rshbuvh.Phispher)            public ec_PHISPHER_byName_byTopPosition;
    
    
    
    mapping(uint    => Rshbuvh.Response)            public ga_RESPONSE_byID;
    
    mapping(uint    => Rshbuvh.Response_Details)    public gb_RESPONSE_Details;
    
    mapping(string  => Rshbuvh.Response)            public eb_RESPONSE_byName;
    
    mapping(string  => uint[])                      ALL_RESPONSES_byID_for_RESPONSE_byName;
    
    // mapping(uint    => uint)                        RESPONSE_TopIndex_byTotalFilled;
    
    // mapping(uint    => Rshbuvh.Response)            public ed_RESPONSE_byName_byTopPosition;
    
    
    
    mapping(uint    => Rshbuvh.Linkage)             public ha_LINKAGE_byID;
    
    mapping(uint    => Rshbuvh.Linkage_Details)     public LINKAGE_Details;
    
    // mapping(uint    => uint)                        LINKAGE_TopIndex_byTotalFilled;
    
    // mapping(uint    => Rshbuvh.Linkage)             public LINKAGE_byID_byTopPosition;
    
    
    
    mapping(uint    => Rshbuvh.Filling)             public ia_FILLING_byID;
    
    
    
}
contract kjfhghjg is lgdsggvy {

    function aa_NEW_Phispher(string memory Name, string memory Description)     public {
    
        require(bytes(Name)         .length<17,     "Title's limit is 16 characters");
        require(bytes(Description)  .length<1024,   "Description's limit is 1023 characters");
        
        Rshbuvh.checkCaps(Name);
        
        ja_TOTAL_Phisphers++;
        ALL_PHISPHERS_byID_for_PHISPHER_byName[Name].push(ja_TOTAL_Phisphers);
        
        Rshbuvh.Phispher storage phispher = fa_PHISPHER_byID[ja_TOTAL_Phisphers];
        phispher.Phispher_Name              = Name;
        phispher.Phispher_Description       = Description;
        phispher.Phispher_ID                = ja_TOTAL_Phisphers;
        
        Rshbuvh.Phispher_Details storage phispherDetails = fb_PHISPHER_Details[ja_TOTAL_Phisphers];
        phispherDetails.Phispher_ID         = ja_TOTAL_Phisphers;
        phispherDetails.Phispher_Owner      = msg.sender;
        
        Rshbuvh.Phispher storage _phispher = ea_PHISPHER_byName[phispher.Phispher_Name];
        
        if (phispherDetails.Total_Filled==0) {
        
            _phispher.Phispher_Name         = Name;
            _phispher.Phispher_Description  = Description;
            _phispher.Phispher_ID           = ja_TOTAL_Phisphers;
            
        }
        
        Rshbuvh.Ownership storage ownership = OWNERSHIP_byAddress[msg.sender];
        ownership.Owner_Address     = msg.sender;
        ownership.Phisphers_byName  .push(Name);
        ownership.Phisphers_byID    .push(ja_TOTAL_Phisphers);
        
        emit Rshbuvh.ID(ja_TOTAL_Phisphers);
        
    }
    
    function ba_FILL_Phispher(uint Phispher_ID)                                 public payable {
    
        require(Phispher_ID!=0 && Phispher_ID<=ja_TOTAL_Phisphers, "Phispher ID not valid");
        
        jd_TOTAL_Fillings++;
        
        Rshbuvh.Phispher storage            phispher            = fa_PHISPHER_byID      [Phispher_ID];
        Rshbuvh.Phispher_Details storage    phispherDetails     = fb_PHISPHER_Details   [Phispher_ID];
        phispherDetails.Total_Filled                            = phispherDetails.Total_Filled+msg.value;
        phispherDetails.ALL_Fillings_byID_for_Phispher_ARRAY    .push(jd_TOTAL_Fillings);
        
        Rshbuvh.Filling storage filling = ia_FILLING_byID[jd_TOTAL_Fillings];
        filling.Filling_ID      = jd_TOTAL_Fillings;
        filling.Phispher_Name   = phispher.Phispher_Name;
        filling.Phispher_ID     = Phispher_ID;
        filling.Investor        = msg.sender;
        filling.Filling_Amount  = msg.value;
        
        Rshbuvh.Response storage response = ga_RESPONSE_byID[phispher.Response_ID];
        
        uint T_weis;
        T_weis = T_weis+msg.value;
        
        for (uint i=1; i<=jd_TOTAL_Fillings; i++) {
        
            Rshbuvh.Filling storage _filling = ia_FILLING_byID[i];
            
            if (_filling.Phispher_ID==Phispher_ID) {
            
                T_weis = T_weis+_filling.Filling_Amount;
                
            }
            
        }
        
        for (uint i=1; i<=jd_TOTAL_Fillings; i++) {
        
            Rshbuvh.Filling storage _filling = ia_FILLING_byID[i];
            
            if (_filling.Investor!=msg.sender && _filling.Phispher_ID==Phispher_ID) {
            
                payable(address(_filling.Investor))                 .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
            }
            
            Rshbuvh.Linkage storage         linkage         = ha_LINKAGE_byID[phispher.Linkage_ID];
            Rshbuvh.Linkage_Details storage linkageDetails  = LINKAGE_Details[phispher.Linkage_ID];
            
            if (linkage.Phispher_ID_LinkedFrom==response.Phispher_ID && response.Phispher_ID!=0) {
            
                payable(address(linkageDetails.Linkage_Owner))      .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
            }
            
            Rshbuvh.Linkage storage         _linkage        = ha_LINKAGE_byID[phispher.Linkage_ID];
            Rshbuvh.Linkage_Details storage _linkageDetails = LINKAGE_Details[phispher.Linkage_ID];
            
            if (_linkage.Phispher_ID_LinkedTo==Phispher_ID) {
            
                payable(address(_linkageDetails.Linkage_Owner))     .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
            }
            
            Rshbuvh.Response storage            _response           = ga_RESPONSE_byID       [_filling.Response_ID];
            Rshbuvh.Response_Details storage    _responseDetails    = gb_RESPONSE_Details    [_response.Response_ID];
            
            if (_response.Phispher_ID==Phispher_ID) {
            
                payable(address(_responseDetails.Response_Owner))   .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
            }
            
            Rshbuvh.Phispher storage         _phispher        = fa_PHISPHER_byID    [_filling.Phispher_ID];
            Rshbuvh.Phispher_Details storage _phispherDetails = fb_PHISPHER_Details [_phispher.Phispher_ID];
            
            if (_phispher.Phispher_ID==Phispher_ID) {
            
                payable(address(_phispherDetails.Phispher_Owner))   .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
            }
            
        }
        
        uint weis;
        
        for (uint i=1; i<=ja_TOTAL_Phisphers; i++) {
        
            Rshbuvh.Phispher storage         _phispher        = fa_PHISPHER_byID    [i];
            Rshbuvh.Phispher_Details storage _phispherDetails = fb_PHISPHER_Details [_phispher.Phispher_ID];
            
            if (keccak256(abi.encodePacked(_phispher.Phispher_Name))==keccak256(abi.encodePacked(phispher.Phispher_Name)) && weis<_phispherDetails.Total_Filled) {
            
                Rshbuvh.Phispher storage __phispher = ea_PHISPHER_byName[phispher.Phispher_Name];
                __phispher.Phispher_Name          = _phispher.Phispher_Name;
                __phispher.Phispher_Description   = _phispher.Phispher_Description;
                __phispher.Phispher_ID            = _phispher.Phispher_ID;
                
                weis = phispherDetails.Total_Filled;
                
            }
            
        }
        
        // for (uint i=2; i<=Top_Index; i++) {
        
        //     for (uint j=1; j<=ja_TOTAL_Phisphers; j++) {
            
        //         Rshbuvh.Phispher storage         _phispher        = fa_PHISPHER_byID    [j];
        //         Rshbuvh.Phispher_Details storage _phispherDetails = fb_PHISPHER_Details [_phispher.Phispher_ID];
        //         Rshbuvh.Phispher storage         __phispher       = ea_PHISPHER_byName  [_phispher.Phispher_Name];
                
        //         if (PHISPHER_TopIndex_byTotalFilled[1]<_phispherDetails.Total_Filled) {
                
        //             ec_PHISPHER_byName_byTopPosition[1] = __phispher;
        //             PHISPHER_TopIndex_byTotalFilled[1]  = _phispherDetails.Total_Filled;
                    
        //         }
                
        //     }
            
        //     for (uint j=1; j<=ja_TOTAL_Phisphers; j++) {
            
        //         Rshbuvh.Phispher storage         _phispher        = fa_PHISPHER_byID    [j];
        //         Rshbuvh.Phispher_Details storage _phispherDetails = fb_PHISPHER_Details [_phispher.Phispher_ID];
        //         Rshbuvh.Phispher storage         __phispher       = ea_PHISPHER_byName  [_phispher.Phispher_Name];
                
        //         if (_phispherDetails.Total_Filled<PHISPHER_TopIndex_byTotalFilled[i-1] && PHISPHER_TopIndex_byTotalFilled[i]<_phispherDetails.Total_Filled) {
                
        //             ec_PHISPHER_byName_byTopPosition[i] = __phispher;
        //             PHISPHER_TopIndex_byTotalFilled[i]  = _phispherDetails.Total_Filled;
                    
        //         }
                
        //     }
            
        // }
        
        Rshbuvh.Ownership storage ownership = OWNERSHIP_byAddress[msg.sender];
        ownership.Owner_Address = msg.sender;
        ownership.Fillings_byID .push(jd_TOTAL_Fillings);
        
        emit Rshbuvh.ID(jd_TOTAL_Fillings);
        
    }
    
    function SELL_Phispher(uint Phispher_ID, uint price)                        public {
        
        Rshbuvh.Phispher_Details storage phispherDetails = fb_PHISPHER_Details[Phispher_ID];
        
        require(phispherDetails.Phispher_Owner ==msg.sender,            "You are not the owner");
        require(Phispher_ID !=0 && Phispher_ID <=ja_TOTAL_Phisphers,    "Phispher ID not valid");
        require(price       !=0,                                        "Price cannot be zero");
        
        phispherDetails.Selling_Price = price;
        
    }
    
    function CANCEL_Phispher_Sale(uint Phispher_ID)                             public {
        
        Rshbuvh.Phispher_Details storage phispherDetails = fb_PHISPHER_Details[Phispher_ID];
        
        require(phispherDetails.Phispher_Owner ==msg.sender,    "You are not the owner");
        require(phispherDetails.Selling_Price !=0,              "Phispher is not for sale");
        
        phispherDetails.Selling_Price = 0;
        
    }
    
    function BUY_Phispher(uint Phispher_ID)                                     public payable {
        
        Rshbuvh.Phispher storage            phispher        = fa_PHISPHER_byID      [Phispher_ID];
        Rshbuvh.Phispher_Details storage    phispherDetails = fb_PHISPHER_Details   [Phispher_ID];
        
        require(Phispher_ID !=0 && Phispher_ID <=ja_TOTAL_Phisphers,    "Phispher ID not valid");
        require(phispherDetails.Selling_Price !=0,                      "Phispher is not for sale");
        
        payable(address(phispherDetails.Phispher_Owner)).transfer(phispherDetails.Selling_Price);
        
        phispherDetails.Phispher_Owner = msg.sender;
        
        phispherDetails.Selling_Price = 0;
        
        Rshbuvh.Ownership storage ownership = OWNERSHIP_byAddress[msg.sender];
        ownership.Owner_Address     = msg.sender;
        ownership.Phisphers_byName  .push(phispher.Phispher_Name);
        ownership.Phisphers_byID    .push(Phispher_ID);
        
        Rshbuvh.Ownership storage _ownership = OWNERSHIP_byAddress[phispherDetails.Phispher_Owner];
        
        for (uint i=1; i<=_ownership.Phisphers_byName.length; i++) {
            
            if (keccak256(abi.encodePacked(_ownership.Phisphers_byName[i]))==keccak256(abi.encodePacked(phispher.Phispher_Name))) {
                
                delete _ownership.Phisphers_byName[i];
                
            }
            
        }
        
        for (uint i=1; i<=_ownership.Phisphers_byID.length; i++) {
            
            if (_ownership.Phisphers_byID[i]==Phispher_ID) {
                
                delete _ownership.Phisphers_byID[i];
                
            }
            
        }
        
    }
    
}
contract laylllo is lgdsggvy {

    function ab_NEW_Response(uint Phispher_ID, string memory Name, string memory Comment)   public {
    
        require(Phispher_ID!=0 && Phispher_ID<=ja_TOTAL_Phisphers,  "Phispher ID not valid");
        require(bytes(Name)     .length<17,                         "Title's limit is 16 characters");
        require(bytes(Comment)  .length<1024,                       "Comment's limit is 1023 characters");
        
        Rshbuvh.checkCaps(Name);
        
        jb_TOTAL_Responses++;
        ALL_RESPONSES_byID_for_RESPONSE_byName[Name].push(jb_TOTAL_Responses);
        
        Rshbuvh.Phispher storage phispher                               = fa_PHISPHER_byID    [Phispher_ID];
        Rshbuvh.Phispher_Details storage phispherDetails                = fb_PHISPHER_Details [Phispher_ID];
        phispherDetails.ALL_Responses_byID_for_Phispher_ARRAY   .push(jb_TOTAL_Responses);
        
        if (phispherDetails.Response_Total_Filled==0) {
        
            phispher.Response_Name      = Name;
            phispher.Response_Comment   = Comment;
            phispher.Response_ID        = jb_TOTAL_Responses;
            
        }
        
        Rshbuvh.Phispher storage _phispher = ea_PHISPHER_byName[phispher.Phispher_Name];
        
        if (phispherDetails.Response_Total_Filled==0) {
        
            _phispher.Response_Name     = Name;
            _phispher.Response_Comment  = Comment;
            _phispher.Response_ID       = jb_TOTAL_Responses;
            
        }
        
        Rshbuvh.Response storage            response        = ga_RESPONSE_byID       [jb_TOTAL_Responses];
        Rshbuvh.Response_Details storage    responseDetails = gb_RESPONSE_Details    [jb_TOTAL_Responses];
        response.Phispher_Name          = phispher.Phispher_Name;
        response.Phispher_ID            = Phispher_ID;
        response.Response_Name          = Name;
        response.Response_Comment       = Comment;
        response.Response_ID            = jb_TOTAL_Responses;
        responseDetails.Response_ID     = jb_TOTAL_Responses;
        responseDetails.Response_Owner  = msg.sender;
        
        Rshbuvh.Response storage _response = eb_RESPONSE_byName[response.Response_Name];
        
        if (responseDetails.Total_Filled==0) {
        
            _response.Phispher_Name     = phispher.Phispher_Name;
            _response.Phispher_ID       = Phispher_ID;
            _response.Response_Name     = Name;
            _response.Response_Comment  = Comment;
            _response.Response_ID       = jb_TOTAL_Responses;
            
        }

        bool R_alreadyAdded;
        
        for (uint i=1; i<=phispherDetails.ALL_Responses_byName_for_Phispher_ARRAY.length; i++) {
        
            if (keccak256(abi.encodePacked(phispherDetails.ALL_Responses_byName_for_Phispher_ARRAY[i-1]))==keccak256(abi.encodePacked(Name))) {
            
                R_alreadyAdded = true;
                break;
                
            }
            
        }
        
        if (R_alreadyAdded==false) {
        
            phispherDetails.ALL_Responses_byName_for_Phispher_ARRAY.push(Name);
            
        }
        
        Rshbuvh.Ownership storage ownership = OWNERSHIP_byAddress[msg.sender];
        ownership.Owner_Address     = msg.sender;
        ownership.Responses_byName  .push(Name);
        ownership.Responses_byID    .push(jb_TOTAL_Responses);
        
        emit Rshbuvh.ID(jb_TOTAL_Responses);
        
    }
    
    function bb_FILL_Response(uint Response_ID)                                             public payable {
    
        require(Response_ID!=0 && Response_ID<=jb_TOTAL_Responses, "Phispher ID not valid");
        
        jd_TOTAL_Fillings++;
        
        Rshbuvh.Response storage            response            = ga_RESPONSE_byID      [Response_ID];
        Rshbuvh.Response_Details storage    responseDetails     = gb_RESPONSE_Details   [Response_ID];
        responseDetails.Total_Filled                            = responseDetails.Total_Filled+msg.value;
        responseDetails.ALL_Fillings_byID_for_Response_ARRAY    .push(jd_TOTAL_Fillings);
        
        Rshbuvh.Phispher storage            phispher            = fa_PHISPHER_byID      [response.Phispher_ID];
        Rshbuvh.Phispher_Details storage    phispherDetails     = fb_PHISPHER_Details   [response.Phispher_ID];
        phispherDetails.Response_Total_Filled                   = responseDetails.Total_Filled;
        
        Rshbuvh.Filling storage filling = ia_FILLING_byID[jd_TOTAL_Fillings];
        filling.Filling_ID      = jd_TOTAL_Fillings;
        filling.Phispher_Name   = response.Phispher_Name;
        filling.Phispher_ID     = response.Phispher_ID;
        filling.Response_Name   = response.Response_Name;
        filling.Response_ID     = Response_ID;
        filling.Investor        = msg.sender;
        filling.Filling_Amount  = msg.value;
        
        uint T_weis;
        T_weis = T_weis+msg.value;
        
        for (uint i=1; i<=jd_TOTAL_Fillings; i++) {
        
            Rshbuvh.Filling storage _filling = ia_FILLING_byID[i];
            
            if (_filling.Response_ID==Response_ID) {
            
                T_weis = T_weis+_filling.Filling_Amount;
                
            }
            
        }
        
        for (uint i=1; i<=jd_TOTAL_Fillings; i++) {
        
            Rshbuvh.Filling storage _filling = ia_FILLING_byID[i];
            
            if (_filling.Investor!=msg.sender && _filling.Response_ID==Response_ID) {
            
                payable(address(_filling.Investor))                 .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
            }
            
            Rshbuvh.Linkage storage         linkage         = ha_LINKAGE_byID[response.Linkage_ID];
            Rshbuvh.Linkage_Details storage linkageDetails  = LINKAGE_Details[response.Linkage_ID];
            
            if (linkage.Phispher_ID_LinkedFrom==response.Phispher_ID) {
            
                payable(address(linkageDetails.Linkage_Owner))      .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
            }
            
            Rshbuvh.Linkage storage         _linkage         = ha_LINKAGE_byID[response.Linkage_ID];
            Rshbuvh.Linkage_Details storage _linkageDetails  = LINKAGE_Details[response.Linkage_ID];
            
            if (_linkage.Phispher_ID_LinkedTo==response.ID_of_Phispher_LinkedTo) {
            
                payable(address(_linkageDetails.Linkage_Owner))     .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
            }
            
            Rshbuvh.Response storage            _response           = ga_RESPONSE_byID       [_filling.Response_ID];
            Rshbuvh.Response_Details storage    _responseDetails    = gb_RESPONSE_Details    [_response.Response_ID];
            
            if (_response.Phispher_ID==phispher.Phispher_ID) {
            
                payable(address(_responseDetails.Response_Owner))   .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
            }
            
            Rshbuvh.Phispher storage         _phispher        = fa_PHISPHER_byID    [_filling.Phispher_ID];
            Rshbuvh.Phispher_Details storage _phispherDetails = fb_PHISPHER_Details [_phispher.Phispher_ID];
            
            if (_phispher.Phispher_ID==response.Phispher_ID) {
            
                payable(address(_phispherDetails.Phispher_Owner))   .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
            }
            
        }
        
        uint weis;
        
        for (uint i=1; i<=jb_TOTAL_Responses; i++) {
        
            Rshbuvh.Response storage            _response           = ga_RESPONSE_byID       [i];
            Rshbuvh.Response_Details storage    _responseDetails    = gb_RESPONSE_Details    [_response.Response_ID];
            
            if (keccak256(abi.encodePacked(_response.Response_Name))==keccak256(abi.encodePacked(response.Response_Name)) && weis<_responseDetails.Total_Filled) {
            
                Rshbuvh.Phispher storage _phispher  = fa_PHISPHER_byID      [_response.Phispher_ID];
                Rshbuvh.Phispher storage __phispher = ea_PHISPHER_byName    [_phispher.Phispher_Name];
                _phispher   .Response_Name      = response  .Response_Name;
                _phispher   .Response_Comment   = response  .Response_Comment;
                _phispher   .Response_ID        = response  .Response_ID;
                __phispher  .Response_Name      = _response .Response_Name;
                __phispher  .Response_Comment   = _response .Response_Comment;
                __phispher  .Response_ID        = _response .Response_ID;
                
                weis = _responseDetails.Total_Filled;
                
            }
            
        }
        
        // for (uint i=2; i<=Top_Index; i++) {
        
        //     for (uint j=1; j<=jb_TOTAL_Responses; j++) {
            
        //         Rshbuvh.Response storage            _response           = ga_RESPONSE_byID       [j];
        //         Rshbuvh.Response_Details storage    _responseDetails    = gb_RESPONSE_Details    [_response.Response_ID];
        //         Rshbuvh.Response storage            __response          = eb_RESPONSE_byName     [_response.Response_Name];
                
        //         if (RESPONSE_TopIndex_byTotalFilled[1]<_responseDetails.Total_Filled) {
                
        //             ed_RESPONSE_byName_byTopPosition[1] = __response;
        //             RESPONSE_TopIndex_byTotalFilled[1]  = _responseDetails.Total_Filled;
                    
        //         }
                
        //     }
            
        //     for (uint j=1; j<=jb_TOTAL_Responses; j++) {
            
        //         Rshbuvh.Response storage            _response           = ga_RESPONSE_byID       [j];
        //         Rshbuvh.Response_Details storage    _responseDetails    = gb_RESPONSE_Details    [_response.Response_ID];
        //         Rshbuvh.Response storage            __response          = eb_RESPONSE_byName     [_response.Response_Name];
                
        //         if (_responseDetails.Total_Filled<RESPONSE_TopIndex_byTotalFilled[i-1] && RESPONSE_TopIndex_byTotalFilled[i]<_responseDetails.Total_Filled) {
                
        //             ed_RESPONSE_byName_byTopPosition[i] = __response;
        //             RESPONSE_TopIndex_byTotalFilled[i]  = _responseDetails.Total_Filled;
                    
        //         }
                
        //     }
            
        // }
        
        Rshbuvh.Ownership storage ownership = OWNERSHIP_byAddress[msg.sender];
        ownership.Owner_Address = msg.sender;
        ownership.Fillings_byID .push(jd_TOTAL_Fillings);
        
        emit Rshbuvh.ID(jd_TOTAL_Fillings);
        
    }
    
    function SELL_Response(uint Response_ID, uint price)                                    public {
    
        Rshbuvh.Response_Details storage responseDetails = gb_RESPONSE_Details[Response_ID];
        
        require(responseDetails.Response_Owner ==msg.sender,            "You are not the owner");
        require(Response_ID !=0 && Response_ID <=jb_TOTAL_Responses,    "Response ID not valid");
        require(price       !=0,                                        "Price cannot be zero");
        
        responseDetails.Selling_Price = price;
        
    }
    
    function CANCEL_Response_Sale(uint Response_ID)                                         public {
        
        Rshbuvh.Response_Details storage responseDetails = gb_RESPONSE_Details[Response_ID];
        
        require(responseDetails.Response_Owner ==msg.sender,    "You are not the owner");
        require(responseDetails.Selling_Price !=0,              "Response is not for sale");
        
        responseDetails.Selling_Price = 0;
        
    }
    
    function BUY_Response(uint Response_ID)                                                 public payable {
        
        Rshbuvh.Response storage            response        = ga_RESPONSE_byID      [Response_ID];
        Rshbuvh.Response_Details storage    responseDetails = gb_RESPONSE_Details   [Response_ID];
        
        require(Response_ID !=0 && Response_ID <=jb_TOTAL_Responses,    "Response ID not valid");
        require(responseDetails.Selling_Price !=0,                      "Response is not for sale");
        
        payable(address(responseDetails.Response_Owner)).transfer(responseDetails.Selling_Price);
        
        responseDetails.Response_Owner = msg.sender;
        
        responseDetails.Selling_Price = 0;
        
        Rshbuvh.Ownership storage ownership = OWNERSHIP_byAddress[msg.sender];
        ownership.Owner_Address     = msg.sender;
        ownership.Responses_byName  .push(response.Response_Name);
        ownership.Responses_byID    .push(Response_ID);
        
        Rshbuvh.Ownership storage _ownership = OWNERSHIP_byAddress[responseDetails.Response_Owner];
        
        for (uint i=1; i<=_ownership.Responses_byName.length; i++) {
            
            if (keccak256(abi.encodePacked(_ownership.Responses_byName[i]))==keccak256(abi.encodePacked(response.Response_Name))) {
                
                delete _ownership.Responses_byName[i];
                
            }
            
        }
        
        for (uint i=1; i<=_ownership.Responses_byName.length; i++) {
            
            if (_ownership.Responses_byID[i]==Response_ID) {
                
                delete _ownership.Responses_byID[i];
                
            }
            
        }
        
    }
    
}
contract pppppoufvv is lgdsggvy {

    function ac_LINK_Response(uint Response_ID, uint to_Phispher_ID, string memory Linkage_Reason)  public {
    
        require(Response_ID     !=0 && Response_ID      <=jb_TOTAL_Responses,   "Response ID not valid");
        require(to_Phispher_ID  !=0 && to_Phispher_ID   <=ja_TOTAL_Phisphers,   "Phispher ID not valid");
        require(bytes(Linkage_Reason)                   .length<1024,           "Reason's limit is 1023 characters");
        
        jc_TOTAL_Linkages++;
        
        Rshbuvh.Linkage             storage linkage             = ha_LINKAGE_byID       [jc_TOTAL_Linkages];
        Rshbuvh.Linkage_Details     storage linkageDetails      = LINKAGE_Details       [jc_TOTAL_Linkages];
        Rshbuvh.Response            storage response            = ga_RESPONSE_byID      [Response_ID];
        Rshbuvh.Response_Details    storage responseDetails     = gb_RESPONSE_Details   [Response_ID];
        Rshbuvh.Response            storage _response           = eb_RESPONSE_byName    [response.Response_Name];
        Rshbuvh.Phispher            storage toPhispher          = fa_PHISPHER_byID      [to_Phispher_ID];
        Rshbuvh.Phispher_Details    storage toPhispherDetails   = fb_PHISPHER_Details   [to_Phispher_ID];
        Rshbuvh.Phispher_Details    storage fromPhispherDetails = fb_PHISPHER_Details   [response.Phispher_ID];
        Rshbuvh.Phispher            storage _toPhispher         = ea_PHISPHER_byName    [toPhispher.Phispher_Name];
        linkage         .Linkage_ID                         = jc_TOTAL_Linkages;
        linkage         .Response_Name                      = response.Response_Name;
        linkage         .Response_ID                        = Response_ID;
        linkage         .Phispher_Name_LinkedFrom           = response.Phispher_Name;
        linkage         .Phispher_ID_LinkedFrom             = response.Phispher_ID;
        linkage         .Phispher_Name_LinkedTo             = toPhispher.Phispher_Name;
        linkage         .Phispher_ID_LinkedTo               = to_Phispher_ID;
        linkageDetails  .Linkage_Owner                      = msg.sender;
        linkage         .Linkage_Reason                     = Linkage_Reason;
        response        .Name_of_Phispher_LinkedTo          = toPhispher.Phispher_Name;
        response        .Description_of_Phispher_LinkedTo   = toPhispher.Phispher_Description;
        response        .ID_of_Phispher_LinkedTo            = to_Phispher_ID;
        response        .Linkage_Reason                     = Linkage_Reason;
        response        .Linkage_ID                         = jc_TOTAL_Linkages;
        _response       .Name_of_Phispher_LinkedTo          = toPhispher.Phispher_Name;
        _response       .Description_of_Phispher_LinkedTo   = toPhispher.Phispher_Description;
        _response       .ID_of_Phispher_LinkedTo            = to_Phispher_ID;
        _response       .Linkage_Reason                     = Linkage_Reason;
        _response       .Linkage_ID                         = jc_TOTAL_Linkages;
        toPhispher      .Linked_Response_Name               = response.Response_Name;
        toPhispher      .Linked_Response_Comment            = response.Response_Comment;
        toPhispher      .Linked_Response_ID                 = Response_ID;
        toPhispher      .Linkage_Reason                     = Linkage_Reason;
        toPhispher      .Linkage_ID                         = jc_TOTAL_Linkages;
        _toPhispher     .Linked_Response_Name               = response.Response_Name;
        _toPhispher     .Linked_Response_Comment            = response.Response_Comment;
        _toPhispher     .Linked_Response_ID                 = Response_ID;
        _toPhispher     .Linkage_Reason                     = Linkage_Reason;
        _toPhispher     .Linkage_ID                         = jc_TOTAL_Linkages;
        
        responseDetails     .ALL_Linkages_byID_for_Response_ARRAY       .push(jc_TOTAL_Linkages);
        fromPhispherDetails .ALL_Linkages_byID_for_FromPhispher_ARRAY   .push(jc_TOTAL_Linkages);
        toPhispherDetails   .ALL_Linkages_byID_for_ToPhispher_ARRAY     .push(jc_TOTAL_Linkages);
        
        bool P_alreadyLinked;
        bool R_alreadyAdded;
        
        for (uint i=1; i<=responseDetails.ALL_Phisphers_byID_LinkedTo_Response_ARRAY.length; i++) {
        
            if (responseDetails.ALL_Phisphers_byID_LinkedTo_Response_ARRAY[i-1]==to_Phispher_ID) {
            
                P_alreadyLinked = true;
                break;
                
            }
            
        }
        
        for (uint i=1; i<=toPhispherDetails.ALL_Responses_byID_LinkedTo_Phispher_ARRAY.length; i++) {
        
            if (toPhispherDetails.ALL_Responses_byID_LinkedTo_Phispher_ARRAY[i-1]==Response_ID) {
            
                R_alreadyAdded = true;
                break;
                
            }
            
        }
        
        if (P_alreadyLinked==false) {
        
            responseDetails.ALL_Phisphers_byID_LinkedTo_Response_ARRAY.push(to_Phispher_ID);
            
        }
        
        if (R_alreadyAdded==false) {
        
            toPhispherDetails.ALL_Responses_byID_LinkedTo_Phispher_ARRAY.push(Response_ID);
            
        }
        
        Rshbuvh.Ownership storage ownership = OWNERSHIP_byAddress[msg.sender];
        ownership.Owner_Address = msg.sender;
        ownership.Linkages_byID .push(jc_TOTAL_Linkages);
        
        emit Rshbuvh.ID(jc_TOTAL_Linkages);
        
    }
    
    function bc_FILL_Linkage(uint Linkage_ID)                                                       public payable {
    
        require(Linkage_ID!=0 && Linkage_ID<=jc_TOTAL_Linkages, "Linkage ID not valid");
        
        jd_TOTAL_Fillings++;
        
        Rshbuvh.Linkage storage         linkage         = ha_LINKAGE_byID[Linkage_ID];
        Rshbuvh.Linkage_Details storage linkageDetails  = LINKAGE_Details[Linkage_ID];
        linkageDetails.Total_Filled                         = linkageDetails.Total_Filled+msg.value;
        linkageDetails.ALL_Fillings_byID_for_Linkage_ARRAY  .push(jd_TOTAL_Fillings);
        
        Rshbuvh.Filling storage filling = ia_FILLING_byID[jd_TOTAL_Fillings];
        filling.Filling_ID      = jd_TOTAL_Fillings;
        filling.Phispher_Name   = linkage.Phispher_Name_LinkedFrom;
        filling.Phispher_ID     = linkage.Phispher_ID_LinkedFrom;
        filling.Response_Name   = linkage.Response_Name;
        filling.Response_ID     = linkage.Response_ID;
        filling.Linkage_ID      = Linkage_ID;
        filling.Investor        = msg.sender;
        filling.Filling_Amount  = msg.value;
        
        Rshbuvh.Response storage response = ga_RESPONSE_byID[linkage.Response_ID];
        Rshbuvh.Phispher storage phispher = fa_PHISPHER_byID[response.Phispher_ID];
        
        uint T_weis;
        T_weis = T_weis+msg.value;
        
        for (uint i=1; i<=jd_TOTAL_Fillings; i++) {
        
            Rshbuvh.Filling storage _filling = ia_FILLING_byID[i];
            
            if (_filling.Linkage_ID==Linkage_ID) {
            
                T_weis = T_weis+_filling.Filling_Amount;
                
            }
            
        }
        
        for (uint i=1; i<=jd_TOTAL_Fillings; i++) {
        
            Rshbuvh.Filling storage _filling = ia_FILLING_byID[i];
            
            if (_filling.Investor!=msg.sender && _filling.Linkage_ID==Linkage_ID) {
            
                payable(address(_filling.Investor))                 .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
            }
            
            Rshbuvh.Linkage storage         _linkage        = ha_LINKAGE_byID[_filling.Linkage_ID];
            Rshbuvh.Linkage_Details storage _linkageDetails = LINKAGE_Details[_filling.Linkage_ID];
            
            if (_linkage.Phispher_ID_LinkedFrom==linkage.Phispher_ID_LinkedFrom) {
            
                payable(address(_linkageDetails.Linkage_Owner))     .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
            }
            
            Rshbuvh.Linkage storage         __linkage           = ha_LINKAGE_byID[_filling.Linkage_ID];
            Rshbuvh.Linkage_Details storage __linkageDetails    = LINKAGE_Details[_filling.Linkage_ID];
            
            if (__linkage.Phispher_ID_LinkedTo==linkage.Phispher_ID_LinkedTo) {
            
                payable(address(__linkageDetails.Linkage_Owner))    .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
            }
            
            Rshbuvh.Response storage            _response           = ga_RESPONSE_byID       [_filling.Response_ID];
            Rshbuvh.Response_Details storage    _responseDetails    = gb_RESPONSE_Details    [_response.Response_ID];
            
            if (_response.Phispher_ID==phispher.Phispher_ID) {
            
                payable(address(_responseDetails.Response_Owner))   .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
            }
            
            Rshbuvh.Phispher storage         _phispher        = fa_PHISPHER_byID    [_filling.Phispher_ID];
            Rshbuvh.Phispher_Details storage _phispherDetails = fb_PHISPHER_Details [_phispher.Phispher_ID];
            
            if (_phispher.Phispher_ID==response.Phispher_ID) {
            
                payable(address(_phispherDetails.Phispher_Owner))   .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
            }
            
        }
        
        uint weis;
        
        for (uint i=1; i<=jc_TOTAL_Linkages; i++) {
        
            Rshbuvh.Linkage storage             _linkage            = ha_LINKAGE_byID       [i];
            Rshbuvh.Response storage            _response           = ga_RESPONSE_byID      [_linkage.Response_ID];
            Rshbuvh.Response_Details storage    _responseDetails    = gb_RESPONSE_Details   [_linkage.Response_ID];
            
            if (keccak256(abi.encodePacked(_linkage.Response_Name))==keccak256(abi.encodePacked(linkage.Response_Name)) && weis<_responseDetails.Total_Filled) {
            
                Rshbuvh.Phispher storage _phispher  = ea_PHISPHER_byName  [_linkage.Phispher_Name_LinkedTo];
                Rshbuvh.Phispher storage __phispher = fa_PHISPHER_byID    [_linkage.Phispher_ID_LinkedTo];
                _phispher   .Linked_Response_Name       = linkage    .Response_Name;
                _phispher   .Linked_Response_Comment    = _response  .Response_Comment;
                _phispher   .Linked_Response_ID         = linkage   .Response_ID;
                _phispher   .Linkage_Reason             = linkage   .Linkage_Reason;
                _phispher   .Linkage_ID                 = linkage   .Linkage_ID;
                __phispher  .Linked_Response_Name       = linkage   .Response_Name;
                __phispher  .Linked_Response_Comment    = _response .Response_Comment;
                __phispher  .Linked_Response_ID         = linkage   .Response_ID;
                __phispher  .Linkage_Reason             = linkage   .Linkage_Reason;
                __phispher  .Linkage_ID                 = linkage   .Linkage_ID;
                
                weis = _responseDetails.Total_Filled;
                
            }
            
        }
        
        // for (uint i=2; i<=Top_Index; i++) {
        
        //     for (uint j=1; j<=jc_TOTAL_Linkages; j++) {
            
        //         Rshbuvh.Linkage storage         _linkage        = ha_LINKAGE_byID[j];
        //         Rshbuvh.Linkage_Details storage _linkageDetails = LINKAGE_Details[_linkage.Linkage_ID];
                
        //         if (LINKAGE_TopIndex_byTotalFilled[1]<_linkageDetails.Total_Filled) {
                
        //             LINKAGE_byID_byTopPosition[1]       = _linkage;
        //             LINKAGE_TopIndex_byTotalFilled[1]   = _linkageDetails.Total_Filled;
                    
        //         }
                
        //     }
            
        //     for (uint j=1; j<=jc_TOTAL_Linkages; j++) {
            
        //         Rshbuvh.Linkage storage         _linkage        = ha_LINKAGE_byID[j];
        //         Rshbuvh.Linkage_Details storage _linkageDetails = LINKAGE_Details[_linkage.Linkage_ID];
                
        //         if (_linkageDetails.Total_Filled<LINKAGE_TopIndex_byTotalFilled[i-1] && LINKAGE_TopIndex_byTotalFilled[i]<_linkageDetails.Total_Filled) {
                
        //             LINKAGE_byID_byTopPosition[i]       = _linkage;
        //             LINKAGE_TopIndex_byTotalFilled[i]   = _linkageDetails.Total_Filled;
                    
        //         }
                
        //     }
            
        // }

        Rshbuvh.Ownership storage ownership = OWNERSHIP_byAddress[msg.sender];
        ownership.Owner_Address = msg.sender;
        ownership.Fillings_byID .push(jd_TOTAL_Fillings);
        
        emit Rshbuvh.ID(jd_TOTAL_Fillings);
        
    }
    
    function SELL_Linkage(uint Linkage_ID, uint price)                                              public {
        
        Rshbuvh.Linkage_Details storage linkageDetails  = LINKAGE_Details[Linkage_ID];
        
        require(linkageDetails.Linkage_Owner ==msg.sender,          "You are not the owner");
        require(Linkage_ID  !=0 && Linkage_ID <=jc_TOTAL_Linkages,  "Linkage ID not valid");
        require(price       !=0,                                    "Price cannot be zero");
        
        linkageDetails.Selling_Price = price;
        
    }
    
    function CANCEL_Linkage_Sale(uint Linkage_ID)                                                   public {
        
        Rshbuvh.Linkage_Details storage linkageDetails  = LINKAGE_Details[Linkage_ID];
        
        require(linkageDetails.Linkage_Owner ==msg.sender,  "You are not the owner");
        require(linkageDetails.Selling_Price !=0,           "Linkage is not for sale");
        
        linkageDetails.Selling_Price = 0;
        
    }
    
    function BUY_Linkage(uint Linkage_ID)                                                           public payable {
        
        Rshbuvh.Linkage_Details storage linkageDetails  = LINKAGE_Details[Linkage_ID];
        
        require(Linkage_ID  !=0 && Linkage_ID <=jc_TOTAL_Linkages,  "Linkage ID not valid");
        require(linkageDetails.Selling_Price !=0,                   "Linkage is not for sale");
        
        payable(address(linkageDetails.Linkage_Owner)).transfer(linkageDetails.Selling_Price);
        
        linkageDetails.Linkage_Owner = msg.sender;
        
        linkageDetails.Selling_Price = 0;
        
        Rshbuvh.Ownership storage ownership = OWNERSHIP_byAddress[msg.sender];
        ownership.Owner_Address     = msg.sender;
        ownership.Linkages_byID     .push(Linkage_ID);
        
        Rshbuvh.Ownership storage _ownership = OWNERSHIP_byAddress[linkageDetails.Linkage_Owner];
        
        for (uint i=1; i<=_ownership.Linkages_byID.length; i++) {
            
            if (_ownership.Linkages_byID[i]==Linkage_ID) {
                
                delete _ownership.Linkages_byID[i];
                
            }
            
        }
        
    }
    
}
contract nnnnnyhyhy is lgdsggvy {

    // function PHISPHER_by_TopPosition                        (uint position)         public view returns (Rshbuvh.Phispher memory) {
        
    //     return ec_PHISPHER_byName_byTopPosition[position];
        
    // }
    
    function fc_ALL_RESPONSES_byName_for_PHISPHER_byName    (string memory Name)    public view returns (string[] memory) {
    
        Rshbuvh.Phispher storage         phispher         = ea_PHISPHER_byName  [Name];
        Rshbuvh.Phispher_Details storage phispherDetails  = fb_PHISPHER_Details [phispher.Phispher_ID];
        return phispherDetails.ALL_Responses_byName_for_Phispher_ARRAY;
        
    }
    
    function fd_ALL_RESPONSES_byID_for_PHISPHER_byName      (string memory Name)    public view returns (uint[] memory) {
    
        Rshbuvh.Phispher storage         phispher           = ea_PHISPHER_byName  [Name];
        Rshbuvh.Phispher_Details storage phispherDetails    = fb_PHISPHER_Details [phispher.Phispher_ID];
        return phispherDetails.ALL_Responses_byID_for_Phispher_ARRAY;
        
    }
    
    function fe_ALL_RESPONSES_byID_for_PHISPHER_byID        (uint Phispher_ID)      public view returns (uint[] memory) {
    
        Rshbuvh.Phispher_Details storage phispherDetails = fb_PHISPHER_Details[Phispher_ID];
        return phispherDetails.ALL_Responses_byID_for_Phispher_ARRAY;
        
    }
    
    function ff_ALL_PHISPHERS_byID_for_PHISPHER_byName      (string memory Name)    public view returns (uint[] memory) {
    
        return ALL_PHISPHERS_byID_for_PHISPHER_byName[Name];
        
    }
    
    function fg_ALL_RESPONSES_byID_LinkedTo_PHISPHER_byName (string memory Name)    public view returns (uint[] memory) {
    
        Rshbuvh.Phispher storage         phispher           = ea_PHISPHER_byName  [Name];
        Rshbuvh.Phispher_Details storage phispherDetails    = fb_PHISPHER_Details [phispher.Phispher_ID];
        return phispherDetails.ALL_Responses_byID_LinkedTo_Phispher_ARRAY;
        
    }
    
    function fh_ALL_RESPONSES_byID_LinkedTo_PHISPHER_byID   (uint Phispher_ID)      public view returns (uint[] memory) {
    
        Rshbuvh.Phispher_Details storage phispherDetails  = fb_PHISPHER_Details[Phispher_ID];
        return phispherDetails.ALL_Responses_byID_LinkedTo_Phispher_ARRAY;
        
    }
    
    function fi_ALL_LINKAGES_byID_for_FromPHISPHER_byID     (uint FromPhispher_ID)  public view returns (uint[] memory) {
    
        Rshbuvh.Phispher_Details storage phispher_Details = fb_PHISPHER_Details[FromPhispher_ID];
        return phispher_Details.ALL_Linkages_byID_for_FromPhispher_ARRAY;
        
    }
    
    function fj_ALL_LINKAGES_byID_for_ToPHISPHER_byID       (uint ToPhispher_ID)    public view returns (uint[] memory) {
    
        Rshbuvh.Phispher_Details storage phispher_Details = fb_PHISPHER_Details[ToPhispher_ID];
        return phispher_Details.ALL_Linkages_byID_for_ToPhispher_ARRAY;
        
    }
    
    function fk_ALL_FILLINGS_byID_for_PHISPHER_byID         (uint Phispher_ID)      public view returns (uint[] memory) {
    
        Rshbuvh.Phispher_Details storage phispher_Details = fb_PHISPHER_Details[Phispher_ID];
        return phispher_Details.ALL_Fillings_byID_for_Phispher_ARRAY;
        
    }
    
    
    
    // function RESPONSE_by_TopPosition                        (uint position)         public view returns (Rshbuvh.Response memory) {
        
    //     return ed_RESPONSE_byName_byTopPosition[position];
        
    // }
    
    function gc_ALL_RESPONSES_byID_for_RESPONSE_byName      (string memory Name)    public view returns (uint[] memory) {
    
        return ALL_RESPONSES_byID_for_RESPONSE_byName[Name];
        
    }
    
    function gd_ALL_PHISPHERS_byID_LinkedTo_RESPONSE_byName (string memory Name)    public view returns (uint[] memory) {
    
        Rshbuvh.Response storage            response        = eb_RESPONSE_byName     [Name];
        Rshbuvh.Response_Details storage    responseDetails = gb_RESPONSE_Details    [response.Response_ID];
        return responseDetails.ALL_Phisphers_byID_LinkedTo_Response_ARRAY;
        
    }
    
    function ge_ALL_PHISPHERS_byID_LinkedTo_RESPONSE_byID   (uint Response_ID)      public view returns (uint[] memory) {
    
        Rshbuvh.Response_Details storage responseDetails = gb_RESPONSE_Details[Response_ID];
        return responseDetails.ALL_Phisphers_byID_LinkedTo_Response_ARRAY;
        
    }
    
    function gf_ALL_LINKAGES_byID_for_RESPONSE_byID         (uint Response_ID)      public view returns (uint[] memory) {
    
        Rshbuvh.Response_Details storage responseDetails = gb_RESPONSE_Details[Response_ID];
        return responseDetails.ALL_Linkages_byID_for_Response_ARRAY;
        
    }
    
    function gg_ALL_FILLINGS_byID_for_RESPONSE_byID         (uint Response_ID)      public view returns (uint[] memory) {
    
        Rshbuvh.Response_Details storage responseDetails = gb_RESPONSE_Details[Response_ID];
        return responseDetails.ALL_Fillings_byID_for_Response_ARRAY;
        
    }
    
    
    
    // function LINKAGE_by_TopPosition                         (uint position)         public view returns (Rshbuvh.Linkage memory) {
        
    //     return LINKAGE_byID_byTopPosition[position];
        
    // }
    
    function hb_ALL_FILLINGS_byID_for_LINKAGE_byID          (uint Linkage_ID)       public view returns (uint[] memory) {
    
        Rshbuvh.Linkage_Details storage linkageDetails = LINKAGE_Details[Linkage_ID];
        return linkageDetails.ALL_Fillings_byID_for_Linkage_ARRAY;
        
    }
    
}
contract jiiiaaaaaaazfdxgh is kjmf, kjfhghjg, laylllo, pppppoufvv, nnnnnyhyhy {

    constructor() {
    
        dev = msg.sender;
        
        Rshbuvh.Phispher_Details    storage phispherDetails = fb_PHISPHER_Details   [0];
        Rshbuvh.Response_Details    storage responseDetails = gb_RESPONSE_Details   [0];
        Rshbuvh.Linkage_Details     storage linkageDetails  = LINKAGE_Details       [0];
        phispherDetails     .ALL_Responses_byName_for_Phispher_ARRAY        .push("zeroth");
        phispherDetails     .ALL_Responses_byID_for_Phispher_ARRAY          .push(0);
        phispherDetails     .ALL_Responses_byID_LinkedTo_Phispher_ARRAY     .push(0);
        phispherDetails     .ALL_Linkages_byID_for_FromPhispher_ARRAY       .push(0);
        phispherDetails     .ALL_Linkages_byID_for_ToPhispher_ARRAY         .push(0);
        phispherDetails     .ALL_Fillings_byID_for_Phispher_ARRAY           .push(0);
        responseDetails     .ALL_Phisphers_byID_LinkedTo_Response_ARRAY     .push(0);
        responseDetails     .ALL_Linkages_byID_for_Response_ARRAY           .push(0);
        responseDetails     .ALL_Fillings_byID_for_Response_ARRAY           .push(0);
        linkageDetails      .ALL_Fillings_byID_for_Linkage_ARRAY            .push(0);
        
        
    }
    
    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
        
    }
    fallback() external payable {}
    
    function changeTopIndex(uint index) public onlydev {
        
        Top_Index = index;
        
    }
    
}