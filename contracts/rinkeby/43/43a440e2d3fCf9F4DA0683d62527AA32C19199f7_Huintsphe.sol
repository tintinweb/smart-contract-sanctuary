/**
 *Submitted for verification at Etherscan.io on 2021-07-12
*/

pragma solidity 0.8.6;
contract drgreer {
    address owner;
    modifier onlyOwner() { 
        if (msg.sender==owner)
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner { 
        if (newOwner!=address(0))owner=newOwner;
    }
}
contract rgdgdrg {
    event ID(uint);
    function checkCaps(string memory word) internal pure {
        for (uint i=0; i<bytes(word).length; i++) {
            require(bytes(word)[i]==bytes("A")[0] || bytes(word)[i]==bytes("B")[0] || bytes(word)[i]==bytes("C")[0] || bytes(word)[i]==bytes("D")[0] || bytes(word)[i]==bytes("E")[0] || bytes(word)[i]==bytes("F")[0] || bytes(word)[i]==bytes("G")[0] || bytes(word)[i]==bytes("H")[0] || bytes(word)[i]==bytes("I")[0] || bytes(word)[i]==bytes("J")[0] || bytes(word)[i]==bytes("K")[0] || bytes(word)[i]==bytes("L")[0] || bytes(word)[i]==bytes("M")[0] || bytes(word)[i]==bytes("N")[0] || bytes(word)[i]==bytes("O")[0] || bytes(word)[i]==bytes("P")[0] || bytes(word)[i]==bytes("Q")[0] || bytes(word)[i]==bytes("R")[0] || bytes(word)[i]==bytes("S")[0] || bytes(word)[i]==bytes("T")[0] || bytes(word)[i]==bytes("U")[0] || bytes(word)[i]==bytes("V")[0] || bytes(word)[i]==bytes("W")[0] || bytes(word)[i]==bytes("X")[0] || bytes(word)[i]==bytes("Y")[0] || bytes(word)[i]==bytes("Z")[0], "The title must be an all caps word");
        }
    }
}
contract ygukgh {
    struct ERYDDT {
        string Problem_Title;
        uint Problem_ID;
        string Problem_Description;
        address Thinker;
        uint Total_Weis;
        uint[] Problem_IDs_for_Problem_Title_ARRAY;
        string Solution_Title;
        uint Solution_ID;
        string Solution_Description;
        uint Solution_Total_Weis;
        uint Linked_Solution_ID;
        string Linked_Solution_Description;
        uint[] Linked_solutions_ARRAY;
    }
    mapping(string => ERYDDT) public PROBLEM_byTitle;
    mapping(uint => ERYDDT) public PROBLEM_byID;
    uint public TOTAL_Problems;
    mapping(uint => ERYDDT) public PROBLEM_byTitle_byTop100Position;
    mapping(uint => uint) YFDHSDFDTFH;
}
contract fdshddfh {
    struct RSRTYRDH {
        string Problem_Title;
        uint Problem_ID;
        string Solution_Title;
        uint Solution_ID;
        string Solution_Description;
        address Master;
        uint Total_Weis;
        uint[] Solution_IDs_for_Solution_Title_ARRAY;
        string Title_of_Problem_LinkedTo;
        uint ID_of_Problem_LinkedTo;
        string Description_of_Problem_LinkedTo;
        uint[] LinkedTo_Problems_ARRAY;
    }
    mapping(string => RSRTYRDH) public SOLUTION_byTitle;
    mapping(uint => RSRTYRDH) public SOLUTION_byID;
    uint public TOTAL_Solutions;
    mapping(uint => RSRTYRDH) public SOLUTION_byTitle_byTop100Position;
    mapping(uint => uint) DFHDHFDGHF;
}
// contract gfyutyf {
//     struct SAEFS {
//         uint Link_ID;
//         string Solution_Title;
//         uint Solution_ID;
//         string Problem_Title_LinkedFrom;
//         uint Problem_ID_LinkedFrom;
//         string Problem_Title_LinkedTo;
//         uint Problem_ID_LinkedTo;
//         address Linker;
//         uint Total_Weis;
//     }
//     mapping(uint => SAEFS) public LINK;
//     uint public TOTAL_Links;
// }
contract fghtffgh {
    struct EFFDRGDF {
        uint Filling_ID;
        string Problem_Title;
        uint Problem_ID;
        string Solution_Title;
        uint Solution_ID;
        uint Link_ID;
        address Investor;
        uint Filling_Weis;
    }
    mapping(uint => EFFDRGDF) public FILLING;
    uint public TOTAL_Fillings;
}
contract puptptpu is ygukgh, fdshddfh, rgdgdrg, fghtffgh {
    function NEW_Problem(string memory Title, string memory Description) public {
        require(bytes(Title).length<17, "Title's limit is 16 characters");
        require(bytes(Description).length<1024, "Description's limit is 1023 characters");
        checkCaps(Title);
        TOTAL_Problems++;
        ERYDDT storage dfhhgfhd=PROBLEM_byID[TOTAL_Problems];
        dfhhgfhd.Problem_Title=Title;
        dfhhgfhd.Problem_ID=TOTAL_Problems;
        dfhhgfhd.Problem_Description=Description;
        dfhhgfhd.Thinker=msg.sender;
        ERYDDT storage ucthcrt=PROBLEM_byTitle[dfhhgfhd.Problem_Title];
        if (ucthcrt.Total_Weis==0) {
            ucthcrt.Problem_Title=Title;
            ucthcrt.Problem_ID=TOTAL_Problems;
            ucthcrt.Problem_Description=Description;
            ucthcrt.Thinker=msg.sender;
            ucthcrt.Problem_IDs_for_Problem_Title_ARRAY.push(TOTAL_Problems);
        }
        emit ID(TOTAL_Problems);
    }
    
    function FILL_Problem(uint Problem_ID) public payable {
        require(Problem_ID!=0&&Problem_ID<=TOTAL_Problems, "Problem ID not valid");
        TOTAL_Fillings++;
        ERYDDT storage sdgdgfd=PROBLEM_byID[Problem_ID];
        sdgdgfd.Total_Weis=sdgdgfd.Total_Weis+msg.value;
        EFFDRGDF storage fgdgfdgf=FILLING[TOTAL_Fillings];
        fgdgfdgf.Filling_ID=TOTAL_Fillings;
        fgdgfdgf.Problem_Title=sdgdgfd.Problem_Title;
        fgdgfdgf.Problem_ID=Problem_ID;
        fgdgfdgf.Investor=msg.sender;
        fgdgfdgf.Filling_Weis=msg.value;
        uint T_weis;
        T_weis=T_weis+msg.value;
        for (uint i=1;i<=TOTAL_Fillings;i++) {
            EFFDRGDF storage dfhdffd=FILLING[i];
            if (dfhdffd.Problem_ID==Problem_ID) {
                T_weis=T_weis+dfhdffd.Filling_Weis;
            }
        }
        for (uint i=1;i<=TOTAL_Fillings;i++) {
            EFFDRGDF storage zddscdx=FILLING[i];
            if (zddscdx.Investor!=msg.sender) {
                payable(address(zddscdx.Investor)).transfer(zddscdx.Filling_Weis*((zddscdx.Filling_Weis*100)/T_weis)/100);
            }
            RSRTYRDH storage sdgdfhd=SOLUTION_byID[zddscdx.Solution_ID];
            if (sdgdfhd.Problem_ID==Problem_ID) {
                payable(address(sdgdfhd.Master)).transfer(zddscdx.Filling_Weis*((zddscdx.Filling_Weis*100)/T_weis)/100);
            }
            ERYDDT storage szfxzswwz=PROBLEM_byID[zddscdx.Problem_ID];
            if (szfxzswwz.Problem_ID==Problem_ID) {
                payable(address(szfxzswwz.Thinker)).transfer(zddscdx.Filling_Weis*((zddscdx.Filling_Weis*100)/T_weis)/100);
            }
        }
        uint weis;
        string memory title=string(sdgdgfd.Problem_Title);
        for (uint i=1;i<=TOTAL_Problems;i++) {
            ERYDDT storage rdfhfg=PROBLEM_byID[i];
            if (keccak256(abi.encodePacked(rdfhfg.Problem_Title))==keccak256(abi.encodePacked(sdgdgfd.Problem_Title))&&weis<rdfhfg.Total_Weis) {
                ERYDDT storage fccxvcxc=PROBLEM_byTitle[title];
                fccxvcxc.Problem_Title=rdfhfg.Problem_Title;
                fccxvcxc.Problem_ID=rdfhfg.Problem_ID;
                fccxvcxc.Problem_Description=rdfhfg.Problem_Description;
                fccxvcxc.Thinker=rdfhfg.Thinker;
                fccxvcxc.Total_Weis=rdfhfg.Total_Weis;
                weis=rdfhfg.Total_Weis;
            }
        }
        for (uint i=2;i<=100;i++) {
            for (uint j=1;j<=TOTAL_Problems;j++) {
                ERYDDT storage szdxfxdfd=PROBLEM_byID[j];
                ERYDDT storage xdgdrcgrd=PROBLEM_byTitle[szdxfxdfd.Problem_Title];
                if (YFDHSDFDTFH[1]<xdgdrcgrd.Total_Weis) {
                    PROBLEM_byTitle_byTop100Position[1]=xdgdrcgrd;
                    YFDHSDFDTFH[1]=xdgdrcgrd.Total_Weis;
                }
            }
            for (uint j=1;j<=TOTAL_Problems;j++) {
                ERYDDT storage dsfdsgxf=PROBLEM_byID[j];
                ERYDDT storage xgxfgfc=PROBLEM_byTitle[dsfdsgxf.Problem_Title];
                if (xgxfgfc.Total_Weis<YFDHSDFDTFH[i-1] && YFDHSDFDTFH[i]<xgxfgfc.Total_Weis) {
                    PROBLEM_byTitle_byTop100Position[i]=xgxfgfc;
                    YFDHSDFDTFH[i]=xgxfgfc.Total_Weis;
                }
            }
        }
        emit ID(TOTAL_Fillings);
    }
}
// contract yyyyggff is ygukgh, fdshddfh, rgdgdrg, fghtffgh {
//     function NEW_Solution(uint Problem_ID, string memory Title, string memory Description) public {
//         require(Problem_ID!=0&&Problem_ID<=TOTAL_Problems, "Problem ID not valid");
//         require(bytes(Title).length<17, "Title's limit is 16 characters");
//         require(bytes(Description).length<1024, "Description's limit is 1023 characters");
//         checkCaps(Title);
//         TOTAL_Solutions++;
//         ERYDDT storage dxdgcfhcf=PROBLEM_byID[Problem_ID];
//         if (dxdgcfhcf.Solution_Total_Weis==0) {
//             dxdgcfhcf.Solution_Title=Title;
//             dxdgcfhcf.Solution_ID=TOTAL_Solutions;
//             dxdgcfhcf.Solution_Description=Description;
//         }
//         ERYDDT storage dfcxfxdf=PROBLEM_byTitle[dxdgcfhcf.Problem_Title];
//         if (dfcxfxdf.Solution_Total_Weis==0) {
//             dfcxfxdf.Solution_Title=Title;
//             dfcxfxdf.Solution_ID=TOTAL_Solutions;
//             dfcxfxdf.Solution_Description=Description;
//         }
//         RSRTYRDH storage xdfxdgdr=SOLUTION_byID[TOTAL_Solutions];
//         xdfxdgdr.Problem_Title=dxdgcfhcf.Problem_Title;
//         xdfxdgdr.Problem_ID=Problem_ID;
//         xdfxdgdr.Solution_Title=Title;
//         xdfxdgdr.Solution_ID=TOTAL_Solutions;
//         xdfxdgdr.Solution_Description=Description;
//         xdfxdgdr.Master=msg.sender;
//         RSRTYRDH storage cvgfgdfsd=SOLUTION_byTitle[xdfxdgdr.Solution_Title];
//         if (cvgfgdfsd.Total_Weis==0) {
//             cvgfgdfsd.Problem_ID=Problem_ID;
//             cvgfgdfsd.Solution_Title=Title;
//             cvgfgdfsd.Solution_ID=TOTAL_Solutions;
//             cvgfgdfsd.Solution_Description=Description;
//             cvgfgdfsd.Master=msg.sender;
//             cvgfgdfsd.Solution_IDs_for_Solution_Title_ARRAY.push(TOTAL_Solutions);
//         }
//         emit ID(TOTAL_Solutions);
//     }
//     function FILL_Solution(uint Solution_ID) public payable {
//         require(Solution_ID!=0&&Solution_ID<=TOTAL_Solutions, "Problem ID not valid");
//         TOTAL_Fillings++;
//         RSRTYRDH storage xdvzvxdfx=SOLUTION_byID[Solution_ID];
//         ERYDDT storage xdzfxdgf=PROBLEM_byID[xdvzvxdfx.Problem_ID];
//         xdvzvxdfx.Total_Weis=xdvzvxdfx.Total_Weis+msg.value;
//         EFFDRGDF storage zszsfdxfx=FILLING[TOTAL_Fillings];
//         zszsfdxfx.Filling_ID=TOTAL_Fillings;
//         zszsfdxfx.Problem_Title =xdvzvxdfx.Problem_Title;
//         zszsfdxfx.Problem_ID=xdvzvxdfx.Problem_ID;
//         zszsfdxfx.Solution_Title=xdvzvxdfx.Solution_Title;
//         zszsfdxfx.Solution_ID=Solution_ID;
//         zszsfdxfx.Investor=msg.sender;
//         zszsfdxfx.Filling_Weis=msg.value;
//         uint T_weis;
//         T_weis=T_weis+msg.value;
//         for (uint i=1;i<=TOTAL_Fillings;i++) {
//             EFFDRGDF storage zsddfx=FILLING[i];
//             if (zsddfx.Solution_ID==Solution_ID) {
//                 T_weis=T_weis+zsddfx.Filling_Weis;
//             }
//         }
//         for (uint i=1;i<=TOTAL_Fillings;i++) {
//             EFFDRGDF storage zzdfd=FILLING[i];
//             if (zzdfd.Investor!=msg.sender) {
//                 payable(address(zzdfd.Investor)).transfer(((zzdfd.Filling_Weis*((zzdfd.Filling_Weis*1000000000000000000000000000000000000)/(T_weis*1000000000000000000000000000000000000)))/1000000000000000000000000000000000000)/1000000000000000000000000000000000000);
//             }
//             RSRTYRDH storage ffjgjgf=SOLUTION_byID[zzdfd.Solution_ID];
//             if (ffjgjgf.Problem_ID==xdzfxdgf.Problem_ID) {
//                 payable(address(xdvzvxdfx.Master)).transfer(((zzdfd.Filling_Weis*((zzdfd.Filling_Weis*1000000000000000000000000000000000000)/(T_weis*1000000000000000000000000000000000000)))/1000000000000000000000000000000000000)/1000000000000000000000000000000000000);
//             }
//             ERYDDT storage xdxyyr=PROBLEM_byID[zzdfd.Problem_ID];
//             if (xdxyyr.Problem_ID==xdvzvxdfx.Problem_ID) {
//                 payable(address(xdxyyr.Thinker)).transfer(((zzdfd.Filling_Weis*((zzdfd.Filling_Weis*1000000000000000000000000000000000000)/(T_weis*1000000000000000000000000000000000000)))/1000000000000000000000000000000000000)/1000000000000000000000000000000000000);
//             }
//         }
//         uint weis;
//         for (uint i=1;i<=TOTAL_Solutions;i++) {
//             RSRTYRDH storage fchfghgcffhd=SOLUTION_byID[i];
//             if (keccak256(abi.encodePacked(fchfghgcffhd.Solution_ID))==keccak256(abi.encodePacked(Solution_ID))&&weis<fchfghgcffhd.Total_Weis) {
//                 ERYDDT storage fxfgfhfggh=PROBLEM_byID[fchfghgcffhd.Problem_ID];
//                 ERYDDT storage dfgfdfgh=PROBLEM_byTitle[fxfgfhfggh.Problem_Title];
//                 fxfgfhfggh.Solution_Title=xdvzvxdfx.Solution_Title;
//                 fxfgfhfggh.Solution_ID=xdvzvxdfx.Solution_ID;
//                 fxfgfhfggh.Solution_Description=xdvzvxdfx.Solution_Description;
//                 fxfgfhfggh.Solution_Total_Weis=xdvzvxdfx.Total_Weis;
//                 dfgfdfgh.Solution_Title=fchfghgcffhd.Solution_Title;
//                 dfgfdfgh.Solution_ID=fchfghgcffhd.Solution_ID;
//                 dfgfdfgh.Solution_Description=fchfghgcffhd.Solution_Description;
//                 dfgfdfgh.Solution_Total_Weis=fchfghgcffhd.Total_Weis;
//                 RSRTYRDH storage khfhhjfh=SOLUTION_byTitle[fchfghgcffhd.Solution_Title];
//                 khfhhjfh.Total_Weis=fchfghgcffhd.Total_Weis;
//                 weis=xdvzvxdfx.Total_Weis;
//             }
//         }
//         for (uint i=2;i<=100;i++) {
//             for (uint j=1;j<=TOTAL_Solutions;j++) {
//                 RSRTYRDH storage tdhgrdfgd=SOLUTION_byID[j];
//                 RSRTYRDH storage dfcgdr=SOLUTION_byTitle[tdhgrdfgd.Problem_Title];
//                 if (DFHDHFDGHF[1]<dfcgdr.Total_Weis) {
//                     SOLUTION_byTitle_byTop100Position[1]=dfcgdr;
//                     DFHDHFDGHF[1]=dfcgdr.Total_Weis;
//                 }
//             }
//             for (uint j=1;j<=TOTAL_Solutions;j++) {
//                 RSRTYRDH storage dgrerer =SOLUTION_byID[j];
//                 RSRTYRDH storage dcgsdfs=SOLUTION_byTitle[dgrerer.Problem_Title];
//                 if (dcgsdfs.Total_Weis<DFHDHFDGHF[i-1]&&DFHDHFDGHF[i]<dcgsdfs.Total_Weis) {
//                     SOLUTION_byTitle_byTop100Position[i]=dcgsdfs;
//                     DFHDHFDGHF[i]=dcgsdfs.Total_Weis;
//                 }
//             }
//         }
//         emit ID(TOTAL_Fillings);
//     }
// }
// contract dsgdsd is gfyutyf, ygukgh, fdshddfh, rgdgdrg, fghtffgh {
//     function LINK_Solution(uint Solution_ID, uint to_Problem_ID) public {
//         require(Solution_ID!=0&&Solution_ID<=TOTAL_Solutions, "Solution ID not valid");
//         require(to_Problem_ID!=0&&to_Problem_ID<=TOTAL_Problems, "Problem ID not valid");
//         TOTAL_Links++;
//         RSRTYRDH storage fdgdrs=SOLUTION_byID[Solution_ID];
//         ERYDDT storage edrdfdf=PROBLEM_byID[to_Problem_ID];
//         fdgdrs.Title_of_Problem_LinkedTo=edrdfdf.Problem_Title;
//         fdgdrs.ID_of_Problem_LinkedTo=to_Problem_ID;
//         fdgdrs.Description_of_Problem_LinkedTo=edrdfdf.Problem_Description;
//         bool alreadyLinked_1;
//         for (uint i=1;i<=fdgdrs.LinkedTo_Problems_ARRAY.length-1;i++) {
//             if (fdgdrs.LinkedTo_Problems_ARRAY[i]==Solution_ID) {
//                 alreadyLinked_1=true;
//             }
//         }
//         if (alreadyLinked_1==false) {
//             fdgdrs.LinkedTo_Problems_ARRAY.push(to_Problem_ID); 
//         }
//         edrdfdf.Linked_Solution_ID=Solution_ID;
//         edrdfdf.Linked_Solution_Description=fdgdrs.Solution_Description;
//         bool alreadyLinked_2;
//         for (uint i=1;i<=edrdfdf.Linked_solutions_ARRAY.length-1;i++) {
//             if (edrdfdf.Linked_solutions_ARRAY[i]==Solution_ID) {
//                 alreadyLinked_2=true;
//             }
//         }
//         if (alreadyLinked_2==false) {
//             edrdfdf.Linked_solutions_ARRAY.push(Solution_ID);
//         }
//         ERYDDT storage hgghg=PROBLEM_byTitle[edrdfdf.Problem_Title];
//         hgghg.Linked_Solution_ID=Solution_ID;
//         hgghg.Linked_Solution_Description=fdgdrs.Solution_Description;
//         bool alreadyLinked_3;
//         for (uint i=1;i<=hgghg.Linked_solutions_ARRAY.length-1;i++) {
//             if (hgghg.Linked_solutions_ARRAY[i]==Solution_ID) {
//                 alreadyLinked_3=true;
//             }
//         }
//         if (alreadyLinked_3==false) {
//             hgghg.Linked_solutions_ARRAY.push(Solution_ID);
//         }
//         SAEFS storage xfdgd=LINK[TOTAL_Links];
//         xfdgd.Link_ID=TOTAL_Links;
//         xfdgd.Solution_Title=fdgdrs.Solution_Title;
//         xfdgd.Solution_ID=Solution_ID;
//         xfdgd.Problem_Title_LinkedFrom=fdgdrs.Problem_Title;
//         xfdgd.Problem_ID_LinkedFrom=fdgdrs.Problem_ID;
//         xfdgd.Problem_Title_LinkedTo=edrdfdf.Problem_Title;
//         xfdgd.Problem_ID_LinkedTo=to_Problem_ID;
//         xfdgd.Linker=msg.sender;
//         emit ID(TOTAL_Links);
//     }
//     function FILL_Link(uint Link_ID) public payable {
//         require(Link_ID!=0&&Link_ID<=TOTAL_Fillings, "Link ID not valid");
//         TOTAL_Fillings++;
//         SAEFS storage vxddg=LINK[Link_ID];
//         RSRTYRDH storage nyngngyf=SOLUTION_byID[vxddg.Solution_ID];
//         ERYDDT storage mjgmgg=PROBLEM_byID[nyngngyf.Problem_ID];
//         vxddg.Total_Weis=vxddg.Total_Weis+msg.value;
//         EFFDRGDF storage fcbcfgdf=FILLING[TOTAL_Fillings];
//         fcbcfgdf.Filling_ID=TOTAL_Fillings;
//         fcbcfgdf.Problem_Title=vxddg.Problem_Title_LinkedFrom;
//         fcbcfgdf.Problem_ID=vxddg.Problem_ID_LinkedFrom;
//         fcbcfgdf.Solution_Title=vxddg.Solution_Title;
//         fcbcfgdf.Solution_ID=vxddg.Solution_ID;
//         fcbcfgdf.Link_ID=Link_ID;
//         fcbcfgdf.Investor=msg.sender;
//         fcbcfgdf.Filling_Weis=msg.value;
//         uint T_weis;
//         T_weis=T_weis+msg.value;
//         for (uint i=1;i<=TOTAL_Fillings;i++) {
//             EFFDRGDF storage gfbdfgf=FILLING[i];
//             if (gfbdfgf.Link_ID==Link_ID) {
//                 T_weis=T_weis+gfbdfgf.Filling_Weis;
//             }
//         }
//         for (uint i=1;i<=TOTAL_Fillings;i++) {
//             EFFDRGDF storage cfbdfsdf=FILLING[i];
//             if (cfbdfsdf.Investor!=msg.sender) {
//                 payable(address(cfbdfsdf.Investor)).transfer(((cfbdfsdf.Filling_Weis*((cfbdfsdf.Filling_Weis*1000000000000000000000000000000000000)/(T_weis*1000000000000000000000000000000000000)))/1000000000000000000000000000000000000)/1000000000000000000000000000000000000);
//             }
//             RSRTYRDH storage xdsdsd=SOLUTION_byID[cfbdfsdf.Solution_ID];
//             if (xdsdsd.Problem_ID==mjgmgg.Problem_ID) {
//                 payable(address(nyngngyf.Master)).transfer(((cfbdfsdf.Filling_Weis*((cfbdfsdf.Filling_Weis*1000000000000000000000000000000000000)/(T_weis*1000000000000000000000000000000000000)))/1000000000000000000000000000000000000)/1000000000000000000000000000000000000);
//             }
//             ERYDDT storage vgbdfgd=PROBLEM_byID[cfbdfsdf.Problem_ID];
//             if (vgbdfgd.Problem_ID==nyngngyf.Problem_ID) {
//                 payable(address(vgbdfgd.Thinker)).transfer(((cfbdfsdf.Filling_Weis*((cfbdfsdf.Filling_Weis*1000000000000000000000000000000000000)/(T_weis*1000000000000000000000000000000000000)))/1000000000000000000000000000000000000)/1000000000000000000000000000000000000);
//             }
//         }
//         emit ID(TOTAL_Fillings);
//     }
// }
contract Huintsphe is drgreer, puptptpu {
    constructor() {
        owner=msg.sender;
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
    // function SOLUTIONS_linkedTo_PROBLEM_byTitle (string memory Title) public view returns (uint[] memory) {  
    //     ERYDDT storage dffbdf=PROBLEM_byTitle[Title];
    //     return dffbdf.Linked_solutions_ARRAY;
    // }
    // function SOLUTIONS_linkedTo_PROBLEM_byID (uint Problem_ID) public view returns (uint[] memory) {
    //     ERYDDT storage fggfghh = PROBLEM_byID[Problem_ID];
    //     return fggfghh.Linked_solutions_ARRAY;
    // }
    // function PROBLEMS_byIDs_for_Problem_Title (string memory Title) public view returns (uint[] memory) {
    //     ERYDDT storage mmhjh=PROBLEM_byTitle[Title];
    //     return mmhjh.Problem_IDs_for_Problem_Title_ARRAY;
    // }
    // function PROBLEMS_byID_linkedTo_SOLUTION    (uint Solution_ID) public view returns (uint[] memory) {
    //     RSRTYRDH storage solution=SOLUTION_byID[Solution_ID];
    //     return solution.LinkedTo_Problems_ARRAY;
    // }
    // function SOLUTIONS_byIDs_for_Solution_Title (string memory Title) public view returns (uint[] memory) {
    //     RSRTYRDH storage gnhgjty=SOLUTION_byTitle[Title];
    //     return gnhgjty.Solution_IDs_for_Solution_Title_ARRAY;
    // }
}