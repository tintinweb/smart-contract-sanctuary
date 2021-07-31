/**
 *Submitted for verification at Etherscan.io on 2021-07-30
*/

pragma solidity 0.8.6;
contract ergdfged {

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
contract trhfthrhrgt {

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
contract sesfsefdfgd {

    struct Qinter {
    
        string  Qinter_Name;
        string  Qinter_Description;
        uint    Qinter_ID;
        
        string  Response_Name;
        string  Response_Comment;
        uint    Response_ID;
        
        string  Linked_Response_Name;
        string  Linked_Response_Comment;
        uint    Linked_Response_ID;
        string  Linkage_Reason;
        uint    Linkage_ID;
        
    }
    
    struct Qinter_Details {
    
        uint    Qinter_ID;
        address Qinter_Writer;
        
        uint    Total_Filled;
        uint    Response_Total_Filled;
        
        string[]    ALL_Responses_byName_for_Qinter_ARRAY;
        uint[]      ALL_Responses_byID_for_Qinter_ARRAY;
        
        uint[]  ALL_Responses_byID_LinkedTo_Qinter_ARRAY;
        uint[]  ALL_Linkages_byID_for_FromQinter_ARRAY;
        uint[]  ALL_Linkages_byID_for_ToQinter_ARRAY;
        uint[]  ALL_Fillings_byID_for_Qinter_ARRAY;
        
    }
    
    uint public ja_TOTAL_Qinters;
    
    mapping(uint    => Qinter)         public fa_QINTER_byID;
    
    mapping(uint    => Qinter_Details) public fb_QINTER_Details;
    
    mapping(string  => Qinter)         public ea_QINTER_byName;

    mapping(string  => uint[])          public ff_ALL_QINTERS_byID_for_QINTER_byName;
    
    mapping(uint    => uint)            QINTER_TOP100_Total_Filled;
    
    mapping(uint    => Qinter)         public ec_QINTER_byName_byTop100Position;
    
}
contract wseshbhohjjgf {

    struct Response {
    
        string  Qinter_Name;
        uint    Qinter_ID;
        
        string  Response_Name;
        string  Response_Comment;
        uint    Response_ID;
        
        string  Name_of_Qinter_LinkedTo;
        string  Description_of_Qinter_LinkedTo;
        uint    ID_of_Qinter_LinkedTo;
        string  Linkage_Reason;
        uint    Linkage_ID;
        
    }
    
    struct Response_Details {
    
        uint    Response_ID;
        address Response_Writer;
        
        uint    Total_Filled;
        
        uint[]  ALL_Qinters_byID_LinkedTo_Response_ARRAY;
        uint[]  ALL_Linkages_byID_for_Response_ARRAY;
        uint[]  ALL_Fillings_byID_for_Response_ARRAY;
        
    }
    
    uint public jb_TOTAL_Responses;
    
    mapping(uint    => Response)            public ga_RESPONSE_byID;
    
    mapping(uint    => Response_Details)    public gb_RESPONSE_Details;
    
    mapping(string  => Response)            public eb_RESPONSE_byName;

    mapping(string  => uint[])              public gc_ALL_RESPONSES_byID_for_RESPONSE_byName;
    
    mapping(uint    => uint)                RESPONSE_TOP100_Total_Filled;
    
    mapping(uint    => Response)            public ed_RESPONSE_byName_byTop100Position;
    
}
contract sdsdgdfgrtghhggff {
    
    struct Linkage {
        
        uint    Linkage_ID;
        
        string  Qinter_Name_LinkedFrom;
        uint    Qinter_ID_LinkedFrom;
        
        string  Response_Name;
        uint    Response_ID;
        
        string  Qinter_Name_LinkedTo;
        uint    Qinter_ID_LinkedTo;
        
        string  Linkage_Reason;
        address Linker;
        
        uint    Total_Filled;
        
        uint[]  ALL_Fillings_byID_for_Linkage_ARRAY;
        
    }
    
    uint public jc_TOTAL_Linkages;
    
    mapping(uint => Linkage) public ha_LINKAGE_byID;
    
}
contract hmmnbnmbghfdsefff {

    struct Filling {
    
        uint    Filling_ID;
        
        string  Qinter_Name;
        uint    Qinter_ID;
        
        string  Response_Name;
        uint    Response_ID;
        
        uint    Linkage_ID;
        
        address Investor;
        
        uint    Filling_Amount;
        
    }
    
    uint public jd_TOTAL_Fillings;
    
    mapping(uint => Filling) public ia_FILLING_byID;
    
}
contract sdfttjkvdhrgdfgfs is trhfthrhrgt, sesfsefdfgd, wseshbhohjjgf, sdsdgdfgrtghhggff, hmmnbnmbghfdsefff {

    function aa_NEW_Qinter(string memory Name, string memory Description) public {
    
        require(bytes(Name)         .length<17,     "Title's limit is 16 characters");
        require(bytes(Description)  .length<1024,   "Description's limit is 1023 characters");
        
        checkCaps(Name);
        
        ja_TOTAL_Qinters++;
        uint[] storage allIDs = ff_ALL_QINTERS_byID_for_QINTER_byName[Name];
        allIDs.push(ja_TOTAL_Qinters);
        
        Qinter storage qinter = fa_QINTER_byID[ja_TOTAL_Qinters];
        qinter.Qinter_Name              = Name;
        qinter.Qinter_Description       = Description;
        qinter.Qinter_ID                = ja_TOTAL_Qinters;
        
        Qinter_Details storage qinterDetails = fb_QINTER_Details[ja_TOTAL_Qinters];
        qinterDetails.Qinter_ID         = ja_TOTAL_Qinters;
        qinterDetails.Qinter_Writer     = msg.sender;
        
        Qinter storage         _qinter        = ea_QINTER_byName [qinter.Qinter_Name];
        // Qinter_Details storage _qinterDetails = fb_QINTER_Details[_qinter.Qinter_ID];
        
        if (qinterDetails.Total_Filled==0) {
        
            _qinter.Qinter_Name         = Name;
            _qinter.Qinter_Description  = Description;
            _qinter.Qinter_ID           = ja_TOTAL_Qinters;
            
        }
        
        emit ID(ja_TOTAL_Qinters);
        
    }
    
    function ba_FILL_Qinter(uint Qinter_ID) public payable {
    
        require(Qinter_ID!=0 && Qinter_ID<=ja_TOTAL_Qinters, "Qinter ID not valid");
        
        jd_TOTAL_Fillings++;
        
        Qinter storage             qinter         = fa_QINTER_byID    [Qinter_ID];
        Qinter_Details storage     qinterDetails  = fb_QINTER_Details [Qinter_ID];
        // Response storage            response        = ga_RESPONSE_byID   [qinter.Response_ID];
        
        qinterDetails.Total_Filled                         = qinterDetails.Total_Filled+msg.value;
        qinterDetails.ALL_Fillings_byID_for_Qinter_ARRAY  .push(jd_TOTAL_Fillings);
        
        Filling storage filling = ia_FILLING_byID[jd_TOTAL_Fillings];
        filling.Filling_ID      = jd_TOTAL_Fillings;
        filling.Qinter_Name   = qinter.Qinter_Name;
        filling.Qinter_ID     = Qinter_ID;
        filling.Investor        = msg.sender;
        filling.Filling_Amount  = msg.value;
        
        uint T_weis;
        T_weis = T_weis+msg.value;
        
        for (uint i=1; i<=jd_TOTAL_Fillings; i++) {
        
            Filling storage _filling = ia_FILLING_byID[i];
            
            if (_filling.Qinter_ID==Qinter_ID) {
            
                T_weis = T_weis+_filling.Filling_Amount;
                
            }
            
        }
        
        // for (uint i=1; i<=jd_TOTAL_Fillings; i++) {
        
        //     Filling storage _filling = ia_FILLING_byID[i];
            
        //     if (_filling.Investor!=msg.sender && _filling.Qinter_ID==Qinter_ID) {
            
        //         payable(address(_filling.Investor))         .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
        //     }
            
        //     Linkage storage linkage = ha_LINKAGE_byID[qinter.Linkage_ID];
            
        //     if (linkage.Qinter_ID_LinkedFrom==response.Qinter_ID && response.Qinter_ID!=0) {
            
        //         payable(address(linkage.Linker))            .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
        //     }
            
        //     Linkage storage _linkage = ha_LINKAGE_byID[qinter.Linkage_ID];
            
        //     if (_linkage.Qinter_ID_LinkedTo==Qinter_ID) {
            
        //         payable(address(_linkage.Linker))           .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
        //     }
            
        //     Response storage            _response           = ga_RESPONSE_byID       [_filling.Response_ID];
        //     Response_Details storage    _responseDetails    = gb_RESPONSE_Details    [_response.Response_ID];
            
        //     if (_response.Qinter_ID==Qinter_ID) {
            
        //         payable(address(_responseDetails.Response_Writer))     .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
        //     }
            
        //     Qinter storage         _qinter        = fa_QINTER_byID    [_filling.Qinter_ID];
        //     Qinter_Details storage _qinterDetails = fb_QINTER_Details [_qinter.Qinter_ID];
            
        //     if (_qinter.Qinter_ID==Qinter_ID) {
            
        //         payable(address(_qinterDetails.Qinter_Writer))    .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
        //     }
            
        // }
        
        uint weis;
        
        for (uint i=1; i<=ja_TOTAL_Qinters; i++) {
        
            Qinter storage         _qinter        = fa_QINTER_byID    [i];
            Qinter_Details storage _qinterDetails = fb_QINTER_Details [_qinter.Qinter_ID];
            
            if (keccak256(abi.encodePacked(_qinter.Qinter_Name))==keccak256(abi.encodePacked(qinter.Qinter_Name)) && weis<_qinterDetails.Total_Filled) {
            
                Qinter storage __qinter = ea_QINTER_byName[qinter.Qinter_Name];
                __qinter.Qinter_Name          = _qinter.Qinter_Name;
                __qinter.Qinter_Description   = _qinter.Qinter_Description;
                __qinter.Qinter_ID            = _qinter.Qinter_ID;
                
                weis = qinterDetails.Total_Filled;
                
            }
            
        }
        
        for (uint i=2; i<=100; i++) {
        
            for (uint j=1; j<=ja_TOTAL_Qinters; j++) {
            
                Qinter storage         _qinter        = fa_QINTER_byID    [j];
                Qinter_Details storage _qinterDetails = fb_QINTER_Details [_qinter.Qinter_ID];
                Qinter storage         __qinter       = ea_QINTER_byName  [_qinter.Qinter_Name];
                
                if (QINTER_TOP100_Total_Filled[1]<_qinterDetails.Total_Filled) {
                
                    ec_QINTER_byName_byTop100Position[1]   = __qinter;
                    QINTER_TOP100_Total_Filled[1]          = _qinterDetails.Total_Filled;
                    
                }
                
            }
            
            for (uint j=1; j<=ja_TOTAL_Qinters; j++) {
            
                Qinter storage         _qinter        = fa_QINTER_byID    [j];
                Qinter_Details storage _qinterDetails = fb_QINTER_Details [_qinter.Qinter_ID];
                Qinter storage         __qinter       = ea_QINTER_byName  [_qinter.Qinter_Name];
                
                if (_qinterDetails.Total_Filled<QINTER_TOP100_Total_Filled[i-1] && QINTER_TOP100_Total_Filled[i]<_qinterDetails.Total_Filled) {
                
                    ec_QINTER_byName_byTop100Position[i]   = __qinter;
                    QINTER_TOP100_Total_Filled[i]          = _qinterDetails.Total_Filled;
                    
                }
                
            }
            
        }
        
        emit ID(jd_TOTAL_Fillings);
        
    }
    
}
contract asasgjhoywgbhejhgsd is trhfthrhrgt, sesfsefdfgd, wseshbhohjjgf, sdsdgdfgrtghhggff, hmmnbnmbghfdsefff {

    function ab_NEW_Response(uint Qinter_ID, string memory Name, string memory Comment) public {
    
        require(Qinter_ID!=0 && Qinter_ID<=ja_TOTAL_Qinters,  "Qinter ID not valid");
        require(bytes(Name)     .length<17,                         "Title's limit is 16 characters");
        require(bytes(Comment)  .length<1024,                       "Comment's limit is 1023 characters");
        
        checkCaps(Name);
        
        jb_TOTAL_Responses++;
        uint[] storage allIDs = gc_ALL_RESPONSES_byID_for_RESPONSE_byName[Name];
        allIDs.push(jb_TOTAL_Responses);
        
        Qinter storage qinter                 = fa_QINTER_byID    [Qinter_ID];
        Qinter_Details storage qinterDetails  = fb_QINTER_Details [Qinter_ID];
        qinterDetails.ALL_Responses_byID_for_Qinter_ARRAY.push(jb_TOTAL_Responses);
        
        if (qinterDetails.Response_Total_Filled==0) {
        
            qinter.Response_Name      = Name;
            qinter.Response_Comment   = Comment;
            qinter.Response_ID        = jb_TOTAL_Responses;
            
        }
        
        Qinter storage _qinter = ea_QINTER_byName[qinter.Qinter_Name];
        
        if (qinterDetails.Response_Total_Filled==0) {
        
            _qinter.Response_Name     = Name;
            _qinter.Response_Comment  = Comment;
            _qinter.Response_ID       = jb_TOTAL_Responses;
            
        }
        
        Response storage            response        = ga_RESPONSE_byID       [jb_TOTAL_Responses];
        Response_Details storage    responseDetails = gb_RESPONSE_Details    [jb_TOTAL_Responses];
        response.Qinter_Name          = qinter.Qinter_Name;
        response.Qinter_ID            = Qinter_ID;
        response.Response_Name          = Name;
        response.Response_Comment       = Comment;
        response.Response_ID            = jb_TOTAL_Responses;
        responseDetails.Response_ID     = jb_TOTAL_Responses;
        responseDetails.Response_Writer = msg.sender;
        
        Response storage            _response           = eb_RESPONSE_byName    [response.Response_Name];
        // Response_Details storage    _responseDetails    = gb_RESPONSE_Details   [_response.Response_ID];
        
        if (responseDetails.Total_Filled==0) {
        
            _response.Qinter_Name     = qinter.Qinter_Name;
            _response.Qinter_ID       = Qinter_ID;
            _response.Response_Name     = Name;
            _response.Response_Comment  = Comment;
            _response.Response_ID       = jb_TOTAL_Responses;
            
        }

        bool R_alreadyAdded;
        
        for (uint i=1; i<=qinterDetails.ALL_Responses_byName_for_Qinter_ARRAY.length; i++) {
        
            if (keccak256(abi.encodePacked(qinterDetails.ALL_Responses_byName_for_Qinter_ARRAY[i-1]))==keccak256(abi.encodePacked(Name))) {
            
                R_alreadyAdded = true;
                break;
                
            }
            
        }
        
        if (R_alreadyAdded==false) {
        
            qinterDetails.ALL_Responses_byName_for_Qinter_ARRAY.push(Name);
            
        }
        
        emit ID(jb_TOTAL_Responses);
        
    }
    
    function bb_FILL_Response(uint Response_ID) public payable {
    
        require(Response_ID!=0 && Response_ID<=jb_TOTAL_Responses, "Qinter ID not valid");
        
        jd_TOTAL_Fillings++;
        
        Response storage            response        = ga_RESPONSE_byID      [Response_ID];
        Response_Details storage    responseDetails = gb_RESPONSE_Details   [Response_ID];
        // Qinter storage             qinter         = fa_QINTER_byID        [response.Qinter_ID];
        Qinter_Details storage     qinterDetails  = fb_QINTER_Details    [response.Qinter_ID];
        
        responseDetails.Total_Filled                            = responseDetails.Total_Filled+msg.value;
        responseDetails.ALL_Fillings_byID_for_Response_ARRAY    .push(jd_TOTAL_Fillings);
        qinterDetails.Response_Total_Filled                   = responseDetails.Total_Filled;
        
        Filling storage filling = ia_FILLING_byID[jd_TOTAL_Fillings];
        filling.Filling_ID      = jd_TOTAL_Fillings;
        filling.Qinter_Name   = response.Qinter_Name;
        filling.Qinter_ID     = response.Qinter_ID;
        filling.Response_Name   = response.Response_Name;
        filling.Response_ID     = Response_ID;
        filling.Investor        = msg.sender;
        filling.Filling_Amount  = msg.value;
        
        uint T_weis;
        T_weis = T_weis+msg.value;
        
        for (uint i=1; i<=jd_TOTAL_Fillings; i++) {
        
            Filling storage _filling = ia_FILLING_byID[i];
            
            if (_filling.Response_ID==Response_ID) {
            
                T_weis = T_weis+_filling.Filling_Amount;
                
            }
            
        }
        
        // for (uint i=1; i<=jd_TOTAL_Fillings; i++) {
        
        //     Filling storage _filling = ia_FILLING_byID[i];
            
        //     if (_filling.Investor!=msg.sender && _filling.Response_ID==Response_ID) {
            
        //         payable(address(_filling.Investor))         .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
        //     }
            
        //     Linkage storage linkage = ha_LINKAGE_byID[response.Linkage_ID];
            
        //     if (linkage.Qinter_ID_LinkedFrom==response.Qinter_ID) {
            
        //         payable(address(linkage.Linker))            .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
        //     }
            
        //     Linkage storage _linkage = ha_LINKAGE_byID[response.Linkage_ID];
            
        //     if (_linkage.Qinter_ID_LinkedTo==response.ID_of_Qinter_LinkedTo) {
            
        //         payable(address(_linkage.Linker))           .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
        //     }
            
        //     Response storage            _response           = ga_RESPONSE_byID       [_filling.Response_ID];
        //     Response_Details storage    _responseDetails    = gb_RESPONSE_Details    [_response.Response_ID];
            
        //     if (_response.Qinter_ID==qinter.Qinter_ID) {
            
        //         payable(address(_responseDetails.Response_Writer))   .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
        //     }
            
        //     Qinter storage         _qinter        = fa_QINTER_byID    [_filling.Qinter_ID];
        //     Qinter_Details storage _qinterDetails = fb_QINTER_Details [_qinter.Qinter_ID];
            
        //     if (_qinter.Qinter_ID==response.Qinter_ID) {
            
        //         payable(address(_qinterDetails.Qinter_Writer))   .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
        //     }
            
        // }
        
        uint weis;
        
        for (uint i=1; i<=jb_TOTAL_Responses; i++) {
        
            Response storage            _response           = ga_RESPONSE_byID       [i];
            Response_Details storage    _responseDetails    = gb_RESPONSE_Details    [_response.Response_ID];
            
            if (keccak256(abi.encodePacked(_response.Response_Name))==keccak256(abi.encodePacked(response.Response_Name)) && weis<_responseDetails.Total_Filled) {
            
                Qinter storage _qinter    = fa_QINTER_byID    [_response.Qinter_ID];
                Qinter storage __qinter   = ea_QINTER_byName  [_qinter.Qinter_Name];
                _qinter   .Response_Name      = response  .Response_Name;
                _qinter   .Response_Comment   = response  .Response_Comment;
                _qinter   .Response_ID        = response  .Response_ID;
                __qinter  .Response_Name      = _response .Response_Name;
                __qinter  .Response_Comment   = _response .Response_Comment;
                __qinter  .Response_ID        = _response .Response_ID;
                
                weis = _responseDetails.Total_Filled;
                
            }
            
        }
        
        for (uint i=2; i<=100; i++) {
        
            for (uint j=1; j<=jb_TOTAL_Responses; j++) {
            
                Response storage            _response           = ga_RESPONSE_byID       [j];
                Response_Details storage    _responseDetails    = gb_RESPONSE_Details    [_response.Response_ID];
                Response storage            __response          = eb_RESPONSE_byName     [_response.Response_Name];
                
                if (RESPONSE_TOP100_Total_Filled[1]<_responseDetails.Total_Filled) {
                
                    ed_RESPONSE_byName_byTop100Position[1]  = __response;
                    RESPONSE_TOP100_Total_Filled[1]         = _responseDetails.Total_Filled;
                    
                }
                
            }
            
            for (uint j=1; j<=jb_TOTAL_Responses; j++) {
            
                Response storage            _response           = ga_RESPONSE_byID       [j];
                Response_Details storage    _responseDetails    = gb_RESPONSE_Details    [_response.Response_ID];
                Response storage            __response          = eb_RESPONSE_byName     [_response.Response_Name];
                
                if (_responseDetails.Total_Filled<RESPONSE_TOP100_Total_Filled[i-1] && RESPONSE_TOP100_Total_Filled[i]<_responseDetails.Total_Filled) {
                
                    ed_RESPONSE_byName_byTop100Position[i]  = __response;
                    RESPONSE_TOP100_Total_Filled[i]         = _responseDetails.Total_Filled;
                    
                }
                
            }
            
        }
        
        emit ID(jd_TOTAL_Fillings);
        
    }
    
}
contract asaswewererffhgtdfge is trhfthrhrgt, sesfsefdfgd, wseshbhohjjgf, sdsdgdfgrtghhggff, hmmnbnmbghfdsefff {

    function ac_LINK_Response(uint Response_ID, uint to_Qinter_ID, string memory Linkage_Reason) public {
    
        require(Response_ID     !=0 && Response_ID      <=jb_TOTAL_Responses,   "Response ID not valid");
        require(to_Qinter_ID  !=0 && to_Qinter_ID   <=ja_TOTAL_Qinters,   "Qinter ID not valid");
        
        jc_TOTAL_Linkages++;
        
        Linkage             storage linkage                 = ha_LINKAGE_byID       [jc_TOTAL_Linkages];
        Response            storage response                = ga_RESPONSE_byID      [Response_ID];
        Response_Details    storage responseDetails         = gb_RESPONSE_Details   [Response_ID];
        Response            storage _response               = eb_RESPONSE_byName    [response.Response_Name];
        Qinter             storage toQinter             = fa_QINTER_byID      [to_Qinter_ID];
        Qinter_Details     storage toQinterDetails      = fb_QINTER_Details   [to_Qinter_ID];
        Qinter_Details     storage fromQinterDetails    = fb_QINTER_Details   [response.Qinter_ID];
        Qinter             storage _toQinter            = ea_QINTER_byName    [toQinter.Qinter_Name];
        linkage     .Linkage_ID                         = jc_TOTAL_Linkages;
        linkage     .Response_Name                      = response.Response_Name;
        linkage     .Response_ID                        = Response_ID;
        linkage     .Qinter_Name_LinkedFrom           = response.Qinter_Name;
        linkage     .Qinter_ID_LinkedFrom             = response.Qinter_ID;
        linkage     .Qinter_Name_LinkedTo             = toQinter.Qinter_Name;
        linkage     .Qinter_ID_LinkedTo               = to_Qinter_ID;
        linkage     .Linker                             = msg.sender;
        linkage     .Linkage_Reason                     = Linkage_Reason;
        response    .Name_of_Qinter_LinkedTo          = toQinter.Qinter_Name;
        response    .Description_of_Qinter_LinkedTo   = toQinter.Qinter_Description;
        response    .ID_of_Qinter_LinkedTo            = to_Qinter_ID;
        response    .Linkage_Reason                     = Linkage_Reason;
        response    .Linkage_ID                         = jc_TOTAL_Linkages;
        _response   .Name_of_Qinter_LinkedTo          = toQinter.Qinter_Name;
        _response   .Description_of_Qinter_LinkedTo   = toQinter.Qinter_Description;
        _response   .ID_of_Qinter_LinkedTo            = to_Qinter_ID;
        _response   .Linkage_Reason                     = Linkage_Reason;
        _response   .Linkage_ID                         = jc_TOTAL_Linkages;
        toQinter  .Linked_Response_Name               = response.Response_Name;
        toQinter  .Linked_Response_Comment            = response.Response_Comment;
        toQinter  .Linked_Response_ID                 = Response_ID;
        toQinter  .Linkage_Reason                     = Linkage_Reason;
        toQinter  .Linkage_ID                         = jc_TOTAL_Linkages;
        _toQinter .Linked_Response_Name               = response.Response_Name;
        _toQinter .Linked_Response_Comment            = response.Response_Comment;
        _toQinter .Linked_Response_ID                 = Response_ID;
        _toQinter .Linkage_Reason                     = Linkage_Reason;
        _toQinter .Linkage_ID                         = jc_TOTAL_Linkages;
        
        responseDetails     .ALL_Linkages_byID_for_Response_ARRAY       .push(jc_TOTAL_Linkages);
        fromQinterDetails .ALL_Linkages_byID_for_FromQinter_ARRAY   .push(jc_TOTAL_Linkages);
        toQinterDetails   .ALL_Linkages_byID_for_ToQinter_ARRAY     .push(jc_TOTAL_Linkages);
        
        bool P_alreadyLinked;
        bool R_alreadyAdded;
        
        for (uint i=1; i<=responseDetails.ALL_Qinters_byID_LinkedTo_Response_ARRAY.length; i++) {
        
            if (responseDetails.ALL_Qinters_byID_LinkedTo_Response_ARRAY[i-1]==to_Qinter_ID) {
            
                P_alreadyLinked = true;
                break;
                
            }
            
        }
        
        for (uint i=1; i<=toQinterDetails.ALL_Responses_byID_LinkedTo_Qinter_ARRAY.length; i++) {
        
            if (toQinterDetails.ALL_Responses_byID_LinkedTo_Qinter_ARRAY[i-1]==Response_ID) {
            
                R_alreadyAdded = true;
                break;
                
            }
            
        }
        
        if (P_alreadyLinked==false) {
        
            responseDetails.ALL_Qinters_byID_LinkedTo_Response_ARRAY.push(to_Qinter_ID);
            
        }
        
        if (R_alreadyAdded==false) {
        
            toQinterDetails.ALL_Responses_byID_LinkedTo_Qinter_ARRAY.push(Response_ID);
            
        }
        
        emit ID(jc_TOTAL_Linkages);
        
    }
    
    function bc_FILL_Linkage(uint Linkage_ID) public payable {
    
        require(Linkage_ID!=0 && Linkage_ID<=jc_TOTAL_Linkages, "Linkage ID not valid");
        
        jd_TOTAL_Fillings++;
        
        Linkage storage     linkage     = ha_LINKAGE_byID   [Linkage_ID];
        // Response storage    response    = ga_RESPONSE_byID  [linkage.Response_ID];
        // Qinter storage     qinter     = fa_QINTER_byID   [response.Qinter_ID];
        
        linkage.Total_Filled                        = linkage.Total_Filled+msg.value;
        linkage.ALL_Fillings_byID_for_Linkage_ARRAY .push(jd_TOTAL_Fillings);
        
        Filling storage filling = ia_FILLING_byID[jd_TOTAL_Fillings];
        filling.Filling_ID      = jd_TOTAL_Fillings;
        filling.Qinter_Name    = linkage.Qinter_Name_LinkedFrom;
        filling.Qinter_ID      = linkage.Qinter_ID_LinkedFrom;
        filling.Response_Name   = linkage.Response_Name;
        filling.Response_ID     = linkage.Response_ID;
        filling.Linkage_ID      = Linkage_ID;
        filling.Investor        = msg.sender;
        filling.Filling_Amount  = msg.value;
        
        uint T_weis;
        T_weis = T_weis+msg.value;
        
        for (uint i=1; i<=jd_TOTAL_Fillings; i++) {
        
            Filling storage _filling = ia_FILLING_byID[i];
            
            if (_filling.Linkage_ID==Linkage_ID) {
            
                T_weis = T_weis+_filling.Filling_Amount;
                
            }
            
        }
        
        // for (uint i=1; i<=jd_TOTAL_Fillings; i++) {
        
        //     Filling storage _filling = ia_FILLING_byID[i];
            
        //     if (_filling.Investor!=msg.sender && _filling.Linkage_ID==Linkage_ID) {
            
        //         payable(address(_filling.Investor))         .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
        //     }
            
        //     Linkage storage _linkage = ha_LINKAGE_byID[_filling.Linkage_ID];
            
        //     if (_linkage.Qinter_ID_LinkedFrom==linkage.Qinter_ID_LinkedFrom) {
            
        //         payable(address(_linkage.Linker))           .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
        //     }
            
        //     Linkage storage __linkage = ha_LINKAGE_byID[_filling.Linkage_ID];
            
        //     if (__linkage.Qinter_ID_LinkedTo==linkage.Qinter_ID_LinkedTo) {
            
        //         payable(address(__linkage.Linker))          .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
        //     }
            
        //     Response storage            _response           = ga_RESPONSE_byID       [_filling.Response_ID];
        //     Response_Details storage    _responseDetails    = gb_RESPONSE_Details    [_response.Response_ID];
            
        //     if (_response.Qinter_ID==qinter.Qinter_ID) {
            
        //         payable(address(_responseDetails.Response_Writer))   .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
        //     }
            
        //     Qinter storage         _qinter        = fa_QINTER_byID    [_filling.Qinter_ID];
        //     Qinter_Details storage _qinterDetails = fb_QINTER_Details [_qinter.Qinter_ID];
            
        //     if (_qinter.Qinter_ID==response.Qinter_ID) {
            
        //         payable(address(_qinterDetails.Qinter_Writer))   .transfer((_filling.Filling_Amount*(_filling.Filling_Amount*1000000000000000000000000000000000000)/T_weis)/1000000000000000000000000000000000000);
                
        //     }
            
        // }
        
        uint weis;
        
        for (uint i=1; i<=jc_TOTAL_Linkages; i++) {
        
            Linkage storage             _linkage            = ha_LINKAGE_byID       [i];
            Response storage            _response           = ga_RESPONSE_byID      [_linkage.Response_ID];
            Response_Details storage    _responseDetails    = gb_RESPONSE_Details   [_linkage.Response_ID];
            
            if (keccak256(abi.encodePacked(_linkage.Response_Name))==keccak256(abi.encodePacked(linkage.Response_Name)) && weis<_responseDetails.Total_Filled) {
            
                Qinter storage _qinter  = ea_QINTER_byName  [_linkage.Qinter_Name_LinkedTo];
                Qinter storage __qinter = fa_QINTER_byID    [_linkage.Qinter_ID_LinkedTo];
                _qinter   .Linked_Response_Name      = linkage    .Response_Name;
                _qinter   .Linked_Response_Comment   = _response  .Response_Comment;
                _qinter   .Linked_Response_ID         = linkage   .Response_ID;
                _qinter   .Linkage_Reason             = linkage   .Linkage_Reason;
                _qinter   .Linkage_ID                 = linkage   .Linkage_ID;
                __qinter  .Linked_Response_Name       = linkage   .Response_Name;
                __qinter  .Linked_Response_Comment    = _response .Response_Comment;
                __qinter  .Linked_Response_ID         = linkage   .Response_ID;
                __qinter  .Linkage_Reason             = linkage   .Linkage_Reason;
                __qinter  .Linkage_ID                 = linkage   .Linkage_ID;
                
                weis = _responseDetails.Total_Filled;
                
            }
            
        }
        
        emit ID(jd_TOTAL_Fillings);
        
    }
    
}
contract aaaaaaaaaa is ergdfged, sdfttjkvdhrgdfgfs, asasgjhoywgbhejhgsd, asaswewererffhgtdfge {

    constructor() {
    
        owner = msg.sender;
        
        Qinter_Details storage    qinterDetails = fb_QINTER_Details   [0];
        Response_Details storage    responseDetails = gb_RESPONSE_Details   [0];
        Linkage storage             linkage         = ha_LINKAGE_byID       [0];
        qinterDetails     .ALL_Responses_byName_for_Qinter_ARRAY        .push("zeroth");
        qinterDetails     .ALL_Responses_byID_for_Qinter_ARRAY          .push(0);
        qinterDetails     .ALL_Responses_byID_LinkedTo_Qinter_ARRAY     .push(0);
        qinterDetails     .ALL_Linkages_byID_for_FromQinter_ARRAY       .push(0);
        qinterDetails     .ALL_Linkages_byID_for_ToQinter_ARRAY         .push(0);
        qinterDetails     .ALL_Fillings_byID_for_Qinter_ARRAY           .push(0);
        responseDetails     .ALL_Qinters_byID_LinkedTo_Response_ARRAY     .push(0);
        responseDetails     .ALL_Linkages_byID_for_Response_ARRAY           .push(0);
        responseDetails     .ALL_Fillings_byID_for_Response_ARRAY           .push(0);
        linkage             .ALL_Fillings_byID_for_Linkage_ARRAY            .push(0);
        
        
    }
    
    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
        
    }
    fallback() external payable {}
    
    
    
    function fc_ALL_RESPONSES_byName_for_QINTER_byName    (string memory Name)    public view returns (string[] memory) {
    
        Qinter storage         qinter         = ea_QINTER_byName  [Name];
        Qinter_Details storage qinterDetails  = fb_QINTER_Details [qinter.Qinter_ID];
        return qinterDetails.ALL_Responses_byName_for_Qinter_ARRAY;
        
    }
    
    function fd_ALL_RESPONSES_byID_for_QINTER_byName      (string memory Name)    public view returns (uint[] memory) {
    
        Qinter storage         qinter         = ea_QINTER_byName  [Name];
        Qinter_Details storage qinterDetails  = fb_QINTER_Details [qinter.Qinter_ID];
        return qinterDetails.ALL_Responses_byID_for_Qinter_ARRAY;
        
    }
    
    function fe_ALL_RESPONSES_byID_for_QINTER_byID        (uint Qinter_ID)      public view returns (uint[] memory) {
    
        Qinter_Details storage qinterDetails = fb_QINTER_Details[Qinter_ID];
        return qinterDetails.ALL_Responses_byID_for_Qinter_ARRAY;
        
    }
    
    function fg_ALL_RESPONSES_byID_LinkedTo_QINTER_byName (string memory Name)    public view returns (uint[] memory) {
    
        Qinter storage         qinter         = ea_QINTER_byName  [Name];
        Qinter_Details storage qinterDetails  = fb_QINTER_Details [qinter.Qinter_ID];
        return qinterDetails.ALL_Responses_byID_LinkedTo_Qinter_ARRAY;
        
    }
    
    function fh_ALL_RESPONSES_byID_LinkedTo_QINTER_byID   (uint Qinter_ID)      public view returns (uint[] memory) {
    
        Qinter_Details storage qinterDetails  = fb_QINTER_Details[Qinter_ID];
        return qinterDetails.ALL_Responses_byID_LinkedTo_Qinter_ARRAY;
        
    }
    
    function fi_ALL_LINKAGES_byID_for_FromQINTER_byID     (uint FromQinter_ID)  public view returns (uint[] memory) {
    
        Qinter_Details storage qinter_Details = fb_QINTER_Details[FromQinter_ID];
        return qinter_Details.ALL_Linkages_byID_for_FromQinter_ARRAY;
        
    }
    
    function fj_ALL_LINKAGES_byID_for_ToQINTER_byID       (uint ToQinter_ID)    public view returns (uint[] memory) {
    
        Qinter_Details storage qinter_Details = fb_QINTER_Details[ToQinter_ID];
        return qinter_Details.ALL_Linkages_byID_for_ToQinter_ARRAY;
        
    }
    
    function fk_ALL_FILLINGS_byID_for_QINTER_byID         (uint Qinter_ID)      public view returns (uint[] memory) {
    
        Qinter_Details storage qinter_Details = fb_QINTER_Details[Qinter_ID];
        return qinter_Details.ALL_Fillings_byID_for_Qinter_ARRAY;
        
    }
    
    
    
    function gd_ALL_QINTERS_byID_LinkedTo_RESPONSE_byName (string memory Name)    public view returns (uint[] memory) {
    
        Response storage            response        = eb_RESPONSE_byName     [Name];
        Response_Details storage    responseDetails = gb_RESPONSE_Details    [response.Response_ID];
        return responseDetails.ALL_Qinters_byID_LinkedTo_Response_ARRAY;
        
    }
    
    function ge_ALL_QINTERS_byID_LinkedTo_RESPONSE_byID   (uint Response_ID)      public view returns (uint[] memory) {
    
        Response_Details storage responseDetails = gb_RESPONSE_Details[Response_ID];
        return responseDetails.ALL_Qinters_byID_LinkedTo_Response_ARRAY;
        
    }
    
    function gf_ALL_LINKAGES_byID_for_RESPONSE_byID         (uint Response_ID)      public view returns (uint[] memory) {
    
        Response_Details storage responseDetails = gb_RESPONSE_Details[Response_ID];
        return responseDetails.ALL_Linkages_byID_for_Response_ARRAY;
        
    }
    
    function gg_ALL_FILLINGS_byID_for_RESPONSE_byID         (uint Response_ID)      public view returns (uint[] memory) {
    
        Response_Details storage responseDetails = gb_RESPONSE_Details[Response_ID];
        return responseDetails.ALL_Fillings_byID_for_Response_ARRAY;
        
    }
    
    
    
    function hb_ALL_FILLINGS_byID_for_LINKAGE_byID          (uint Linkage_ID)       public view returns (uint[] memory) {
    
        Linkage storage linkage = ha_LINKAGE_byID[Linkage_ID];
        return linkage.ALL_Fillings_byID_for_Linkage_ARRAY;
        
    }
    
}