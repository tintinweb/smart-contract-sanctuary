// SPDX-License-Identifier: MIT

// --------------------------------------------
// ----------- COIN CENTRE TOKEN --------------
// --------------------------------------------
// 0xB37C2F0649f23e95161C6B2C3baA9B57C4c1B1De
// 0x1Fa2883Fc9804154154Ca429Ec585a9A8211306B

pragma solidity ^0.8.0;

import "./library.sol";

/**
 * @title CoinCentreToken ERC20 token
 * @dev This is the base token to allow for staking and trading
 */
contract CoinCentreToken is ERC20, AccessControl {
    using SafeMath for uint256; 

    //*
    bytes32 public constant ROLEMINTER = keccak256("ROLEMINTER"); 
      
    //*  
    bytes20 private dDefSpo;
    bytes20 private dTop;
    
    uint16 private dMmbrLis;
    uint16 private dRdrpLis;
    uint16 private dSdrnLis;
    uint16 private dPrslLis;
    uint16 private dMttnLis;
    uint16 private dMtthLis;
    uint16 private dGmtnLis; 
    uint16 private dGmthLis; 
    
    struct Mmbr {
        bytes4 ztyp;
        uint16 zdatid;
        bytes20 zmem;
        bytes20 zspo;
        bytes20 zspo2; 
        bytes20 zspo3; 
        bytes20 zspo4; 
        bytes20 zspo5;  
        bytes32 zdat;
        uint256 zdatreg;
    }   
    mapping(bytes20 => Mmbr[]) mmbrs;
    mapping(uint16 => bytes20) public xammbrs;

    struct Rdrp {
        uint zsta;
        uint16 zdatid;
        bytes20 zmem; 
        uint256 zairtok;
        uint256 zairtokref; 
        uint256 zdatreg;
        uint256 znextimsta;
    }   
    mapping(bytes20 => Rdrp[]) rdrps;
    mapping(uint16 => bytes20) public xardrps;

    struct Sdrn {
        uint zsta;
        uint16 zdatid;
        bytes20 zmem;
        uint256 zseeroutok;
        uint256 zseeroutokref;
        uint256 zseeroucoi;
        uint256 zseeroucoiref;
        uint256 zdatreg;
        uint256 znextimsta;
    }   
    mapping(bytes20 => Sdrn[]) sdrns;
    mapping(uint16 => bytes20) public xasdrns;

    struct Prsl {
        uint zsta;
        uint16 zdatid;
        bytes20 zmem;
        uint256 zprisaltok;
        uint256 zprisaltokref;
        uint256 zprisalcoi;
        uint256 zprisalcoiref; 
        uint256 zdatreg;
        uint256 znextimsta;
    }   
    mapping(bytes20 => Prsl[]) prsls;
    mapping(uint16 => bytes20) public xaprsls;

    struct Mttn {
        uint zsta;
        uint16 zdatid;
        bytes20 zmem;
        uint256 zmat10tok;
        uint256 zmat10tokref;
        uint256 zmat10coi;
        uint256 zmat10coiref;
        uint256 zmat10poinew;
        uint256 zmat10poiold;
        uint256 zdatreg;
        uint256 znextimsta;
    }   
    mapping(bytes20 => Mttn[]) mttns;
    mapping(uint16 => bytes20) public xamttns;

    struct Mtth {
        uint zsta;
        bytes20 zmem;
        uint16 zdatid;
        uint256 zmat30tok;
        uint256 zmat30tokref;
        uint256 zmat30coi;
        uint256 zmat30coiref;
        uint256 zmat30poinew;
        uint256 zmat30poiold;
        uint256 zdatreg;
        uint256 znextimsta;
    }   
    mapping(bytes20 => Mtth[]) mtths;
    mapping(uint16 => bytes20) public xamtths;

    struct Gmtn {
        uint zsta;
        bytes20 zmem; 
        uint16 zdatid;
        uint256 zgamtentok;
        uint256 zgamtentokref;
        uint256 zgamtencoi;
        uint256 zgamtencoiref;
        uint256 zgamtenpoinew;
        uint256 zgamtenpoiold;
        uint256 zdatreg;
        uint256 znextimsta;
    }   
    mapping(bytes20 => Gmtn[]) gmtns;
    mapping(uint16 => bytes20) public xagmtns;

    struct Gmth {
        uint zsta;
        bytes20 zmem; 
        uint16 zdatid;
        uint256 zgamthitok;
        uint256 zgamthitokref;
        uint256 zgamthicoi;
        uint256 zgamthicoiref;
        uint256 zgamthipoinew;
        uint256 zgamthipoiold;
        uint256 zdatreg;
        uint256 znextimsta;
    }   
    mapping(bytes20 => Gmth[]) gmths;
    mapping(uint16 => bytes20) public xagmths;
    
    //* 
    mapping(uint16 => bytes20) public xesm30f;
    mapping(uint16 => bytes20) public xesm30p;
    mapping(uint16 => bytes20) public xesctls;
    mapping(uint16 => bytes20) public xesapo;

    //* 
    uint256 private dTimSta15m; 
    uint256 private dTimSta30m;

    //*  
    uint private dRdrpSta;
        uint256 private dRdrpTokHarCap; 
        uint256 private dRdrpTok;
        uint256 private dRdrpTokRef;
        uint256 private dRdrpCoi;
        uint256 private dRdrpCoiRef;
    uint256 private dRdrpTotTok; 
    uint256 private dRdrpCoiTok;
    
    //*  
    uint private dSdrnSta;
        uint256 private dSdrnTokHarCap;
        uint256 private dSdrnTok;
        uint256 private dSdrnTokRef;
        uint256 private dSdrnCoi;
        uint256 private dSdrnCoiRef;
    uint256 private dSdrnTotTok;
    uint256 private dSdrnCoiTok;

    //*  
    uint private dPrslSta;
        uint256 private dPrslTokHarCap; 
        uint256 private dPrslTok;
        uint256 private dPrslTokRef;
        uint256 private dPrslCoi;
        uint256 private dPrslCoiRef;
    uint256 private dPrslTotTok;  
    uint256 private dPrslCoiTok;  
     
    //*  
    uint private dMttnSta;
        uint256 private dMttnTokHarCap; 
        uint256 private dMttnTok;
        uint256 private dMttnTokRef;
        uint256 private dMttnCoi;
        uint256 private dMttnCoiRef;
    uint256 private dMttnTotTok;  
    uint256 private dMttnCoiTok;  
     
    //*  
    uint private dMtthSta;
        uint256 private dMtthTokHarCap;
        uint256 private dMtthTok;
        uint256 private dMtthTokRef;
        uint256 private dMtthCoi;
        uint256 private dMtthCoiRef;
    uint256 private dMtthTotTok;   
    uint256 private dMtthCoiTok;   
     
    //*  
    uint private dGmtnSta;
        uint256 private dGmtnTokHarCap; 
        uint256 private dGmtnTok;
        uint256 private dGmtnTokRef;
        uint256 private dGmtnCoi;
        uint256 private dGmtnCoiRef;
    uint256 private dGmtnTotTok;
    uint256 private dGmtnCoiTok;
     
    //*  
    uint private dGmthSta;
        uint256 private dGmthTokHarCap; 
        uint256 private dGmthTok;
        uint256 private dGmthTokRef;
        uint256 private dGmthCoi;
        uint256 private dGmthCoiRef;
    uint256 private dGmthTotTok;
    uint256 private dGmthCoiTok;

    constructor() ERC20("CoinCentreToken", "CCTOKEN") {
        _setupRole(ROLEADMIN, _msgSender());
        _setupRole(ROLEMINTER, _msgSender());  
 
        //Init totalSupply
        _mint(_msgSender(), uint256(5000000).mul(uint256(10)**18));


        //*
        dTop = bytes20(_msgSender()); 
        dDefSpo = dTop;  
 
        dMmbrLis ++;
        Mmbr memory vmmbr = Mmbr({ 
            ztyp: '1',
            zdatid: dMmbrLis,
            zmem: dTop,
            zspo: dDefSpo,
            zspo2: dDefSpo,
            zspo3: dDefSpo,
            zspo4: dDefSpo,
            zspo5: dDefSpo, 
            zdat: 'constructor', 
            zdatreg: block.timestamp
        }); 
        mmbrs[dTop].push(vmmbr); 
        xammbrs[dMmbrLis] = dTop; 


        dRdrpLis ++;
        Rdrp memory vrdrp = Rdrp({  
            zsta: 0, 
            zdatid: dRdrpLis,
            zmem: dTop,  
            zairtok: 0,
            zairtokref: 0,
            zdatreg: block.timestamp,
            znextimsta: block.timestamp
        }); 
        rdrps[dTop].push(vrdrp); 
        
        dSdrnLis ++; 
        Sdrn memory vsdrn = Sdrn({  
            zsta: 0,
            zdatid: dSdrnLis,
            zmem: dTop,
            zseeroutok: 0,
            zseeroutokref: 0,
            zseeroucoi: 0,
            zseeroucoiref: 0, 
            zdatreg: block.timestamp,
            znextimsta: block.timestamp
        }); 
        sdrns[dTop].push(vsdrn); 
 
        dPrslLis ++;
        Prsl memory vprsl = Prsl({  
            zsta: 0,  
            zdatid: dPrslLis,
            zmem: dTop,
            zprisaltok: 0,
            zprisaltokref: 0,
            zprisalcoi: 0,
            zprisalcoiref: 0,  
            zdatreg: block.timestamp,
            znextimsta: block.timestamp
        }); 
        prsls[dTop].push(vprsl); 
        
        dMttnLis ++;
        Mttn memory vmttn = Mttn({  
            zsta: 0, 
            zdatid: dMttnLis,
            zmem: dTop,
            zmat10tok: 0,
            zmat10tokref: 0,
            zmat10coi: 0,
            zmat10coiref: 0,
            zmat10poinew: 0,
            zmat10poiold: 0, 
            zdatreg: block.timestamp,
            znextimsta: block.timestamp
        }); 
        mttns[dTop].push(vmttn); 

        dMtthLis ++;
        Mtth memory vmtth = Mtth({  
            zsta: 0, 
            zdatid: dMtthLis,
            zmem: dTop,
            zmat30tok: 0,
            zmat30tokref: 0,
            zmat30coi: 0,
            zmat30coiref: 0,
            zmat30poinew: 0,  
            zmat30poiold: 0, 
            zdatreg: block.timestamp,
            znextimsta: block.timestamp
        }); 
        mtths[dTop].push(vmtth); 
        
        dGmtnLis ++;
        Gmtn memory vgmtn = Gmtn({  
            zsta: 0,
            zmem: dTop,
            zgamtentok: 0,
            zgamtentokref: 0,
            zgamtencoi: 0,
            zgamtencoiref: 0,
            zgamtenpoinew: 0,
            zgamtenpoiold: 0,
            zdatid: dGmtnLis,
            zdatreg: block.timestamp,
            znextimsta: block.timestamp
        }); 
        gmtns[dTop].push(vgmtn);
        
        dGmthLis ++;
        Gmth memory vgmth = Gmth({  
            zsta: 0,
            zmem: dTop,
            zgamthitok: 0,
            zgamthitokref: 0,
            zgamthicoi: 0,
            zgamthicoiref: 0,
            zgamthipoinew: 0,
            zgamthipoiold: 0,
            zdatid: dGmtnLis,
            zdatreg: block.timestamp,
            znextimsta: block.timestamp
        }); 
        gmths[dTop].push(vgmth);
        
        //*
        dRdrpSta = 1; 
        dRdrpTokHarCap = 800000;  
        dRdrpTok = 400; 
        dRdrpTokRef = 100; 
        // dRdrpCoi = 0;
        // dRdrpCoiRef = 0;
        // dRdrpTotTok = 0; 
        // dRdrpCoiTok = 0; 
        
        //* 2000000000000000
        dSdrnSta = 1; 
        dSdrnTokHarCap = 1600000;   
        dSdrnTok = 5000;
        dSdrnTokRef = 100;
        dSdrnCoi = 200000000000000000;
        dSdrnCoiRef = 0;
        // dSdrnTotTok = 0; 
        // dSdrnCoiTok = 0; 
        
        //*
        dMtthSta = 1; 
        dMtthTokHarCap = 0; 
        dMtthTok = 0;
        dMtthTokRef = 0;
        dMtthCoi = 0;
        dMtthCoiRef = 0;
        // dMtthTotTok = 0; 
        // dMtthCoiTok = 0; 
         
    }






    /**
     * @dev Returns W
     */
    function wGetTotPar(uint ycode) public view returns(uint256) { 
        if (ycode == 1) {
            return dMmbrLis;
        } else if (ycode == 2) {
            return dRdrpLis;
        } else if (ycode == 3) {
            return dSdrnLis;
        } else if (ycode == 4) {
            return dPrslLis;
        } else if (ycode == 5) {
            return dMttnLis;
        } else if (ycode == 6) {
            return dMtthLis;
        } else if (ycode == 7) {
            return dGmtnLis;
        } else if (ycode == 8) {
            return dGmthLis; 
        } else {
            return 0;
        }
    }
    function wGetTotTok(uint ycode) public view virtual returns (uint256) {
        if (ycode == 1) {
            return 0;
        } else if (ycode == 2) {
            return dRdrpTotTok;
        } else if (ycode == 3) {
            return dSdrnTotTok;
        } else if (ycode == 4) {
            return dPrslTotTok;
        } else if (ycode == 5) {
            return dMttnTotTok;
        } else if (ycode == 6) {
            return dMtthTotTok;
        } else if (ycode == 7) {
            return dGmtnTotTok;
        } else if (ycode == 8) {
            return dGmthTotTok;
        } else {
            return 0;
        } 
    }
    function wGetAdd(uint16 ykey, uint ycode) public view returns(address) {  
        if (ycode == 1) {
            return address(xammbrs[ykey]);
        } else if (ycode == 2) {
            return address(xardrps[ykey]);
        } else if (ycode == 3) {
            return address(xasdrns[ykey]);
        } else if (ycode == 4) {
            return address(xaprsls[ykey]);
        } else if (ycode == 5) {
            return address(xamttns[ykey]);
        } else if (ycode == 6) {
            return address(xamtths[ykey]);
        } else if (ycode == 7) {
            return address(xagmtns[ykey]);
        } else if (ycode == 8) { 
            return address(xagmths[ykey]);
        } else if (ycode == 101) { 
            return address(xesm30f[ykey]);
        } else if (ycode == 102) { 
            return address(xesm30p[ykey]);
        } else if (ycode == 103) { 
            return address(xesctls[ykey]);
        } else if (ycode == 104) { 
            return address(xesapo[ykey]);
        } else { 
            return address(0);
        }   

    }
    function wGetTop() public view virtual returns (address) {
        return address(dTop);
    } 
    function wGetDefSpo() public view virtual returns (address) {
        return address(dDefSpo);
    }     

    function wMyReg(address ykey, uint ycode) public view virtual returns (uint) { 
        bytes20 xkey = bytes20(ykey);
        if (ycode == 1) {
            return mmbrs[xkey].length;
        } else if (ycode == 2) {
            return rdrps[xkey].length;
        } else if (ycode == 3) {
            return sdrns[xkey].length;
        } else if (ycode == 4) {
            return prsls[xkey].length;
        } else if (ycode == 5) {
            return mttns[xkey].length;
        } else if (ycode == 6) {
            return mtths[xkey].length;
        } else if (ycode == 7) {
            return gmtns[xkey].length;
        } else if (ycode == 8) {
            return gmths[xkey].length;
        } else {
            return 0;
        }
    }
    function wMyTim(address ykey, uint ycode) public view virtual returns (uint) {
        bytes20 xkey = bytes20(ykey);
        uint256 xres;
        uint256 xressta;
        if (ycode == 1) {
            xres = 0;
            xressta = block.timestamp + 1 minutes;
        } else if (ycode == 2) {
            xres = rdrps[xkey].length;
            xressta = rdrps[xkey][0].znextimsta;
        } else if (ycode == 3) {
            xres = sdrns[xkey].length;
            xressta = sdrns[xkey][0].znextimsta;
        } else if (ycode == 4) {
            xres = prsls[xkey].length;
            xressta = prsls[xkey][0].znextimsta;
        } else if (ycode == 5) {
            xres = mttns[xkey].length;
            xressta = mttns[xkey][0].znextimsta;
        } else if (ycode == 6) {
            xres = mtths[xkey].length;
            xressta = mtths[xkey][0].znextimsta;
        } else if (ycode == 7) {
            xres = gmtns[xkey].length;
            xressta = gmtns[xkey][0].znextimsta;
        } else if (ycode == 8) {
            xres = gmths[xkey].length;
            xressta = gmths[xkey][0].znextimsta;
        } else {
            xres = 0;
            xressta = block.timestamp + 1 minutes;
        }   
        if (xres > 0) {
            if (xressta >= block.timestamp) {
                return 0;
            } else {
                return 1;
            }
        } else {
            return 1;
        }
    }
    function wMySloCou(address ykey, uint ycode) public view virtual returns (uint) { 
        bytes20 xkey = bytes20(ykey); 
        if (ycode == 1) {
            return 0; 
        } else if (ycode == 2) {
            return rdrps[xkey][0].zsta;
        } else if (ycode == 3) {
            return sdrns[xkey][0].zsta;
        } else if (ycode == 4) {
            return prsls[xkey][0].zsta;
        } else if (ycode == 5) {
            return mttns[xkey][0].zsta;
        } else if (ycode == 6) {
            return mtths[xkey][0].zsta;
        } else if (ycode == 7) {
            return gmtns[xkey][0].zsta;
        } else if (ycode == 8) {
            return gmths[xkey][0].zsta;
        } else {
            return 0;
        } 
    }
    function wMyTok(address ykey, uint ycode) public view virtual returns (uint256) { 
        bytes20 xkey = bytes20(ykey);
        if (ycode == 1) {
            return 0;
        } else if (ycode == 2) {
            return rdrps[xkey][0].zairtok;
        } else if (ycode == 3) {
            return sdrns[xkey][0].zseeroutok;
        } else if (ycode == 4) {
            return prsls[xkey][0].zprisaltok;
        } else if (ycode == 5) {
            return mttns[xkey][0].zmat10tok;
        } else if (ycode == 6) {
            return mtths[xkey][0].zmat30tok;
        } else if (ycode == 7) {
            return gmtns[xkey][0].zgamtentok;
        } else if (ycode == 8) {
            return gmths[xkey][0].zgamthitok;
        } else {
            return 0;
        } 
    } 
    function wMyTokRef(address ykey, uint ycode) public view virtual returns (uint256) { 
        bytes20 xkey = bytes20(ykey);
        if (ycode == 1) {
            return 0;
        } else if (ycode == 2) {
            return rdrps[xkey][0].zairtokref;
        } else if (ycode == 3) {
            return sdrns[xkey][0].zseeroutokref;
        } else if (ycode == 4) {
            return prsls[xkey][0].zprisaltokref;
        } else if (ycode == 5) {
            return mttns[xkey][0].zmat10tokref;
        } else if (ycode == 6) {
            return mtths[xkey][0].zmat30tokref;
        } else if (ycode == 7) {
            return gmtns[xkey][0].zgamtentokref;
        } else if (ycode == 8) {
            return gmths[xkey][0].zgamthitokref;
        } else {
            return 0;
        }  
    } 
    function wMyCoi(address ykey, uint ycode) public view virtual returns (uint256) { 
        bytes20 xkey = bytes20(ykey);
        if (ycode == 1) {
            return 0;
        } else if (ycode == 2) {
            return 0;
        } else if (ycode == 3) {
            return sdrns[xkey][0].zseeroucoi;
        } else if (ycode == 4) {
            return prsls[xkey][0].zprisalcoi;
        } else if (ycode == 5) {
            return mttns[xkey][0].zmat10coi;
        } else if (ycode == 6) {
            return mtths[xkey][0].zmat30coi;
        } else if (ycode == 7) {
            return gmtns[xkey][0].zgamtencoi;
        } else if (ycode == 8) {
            return gmths[xkey][0].zgamthicoi;
        } else {
            return 0;
        } 
    } 
    function wMyCoiRef(address ykey, uint ycode) public view virtual returns (uint256) { 
        bytes20 xkey = bytes20(ykey);
        if (ycode == 1) {
            return 0;
        } else if (ycode == 2) {
            return 0;
        } else if (ycode == 3) {
            return sdrns[xkey][0].zseeroucoiref;
        } else if (ycode == 4) {
            return prsls[xkey][0].zprisalcoiref;
        } else if (ycode == 5) {
            return mttns[xkey][0].zmat10coiref;
        } else if (ycode == 6) {
            return mtths[xkey][0].zmat30coiref;
        } else if (ycode == 7) {
            return gmtns[xkey][0].zgamtencoiref;
        } else if (ycode == 8) {
            return gmths[xkey][0].zgamthicoiref;
        } else {
            return 0;
        }  
    } 
    function wMySpo(address ykey) public view returns(address) {
        bytes20 xkey = bytes20(ykey);
        return (address(mmbrs[xkey][0].zspo));
    } 
    function wMySpoLev(address ykey, uint ywhat) public view returns(bytes20) {  
        bytes20 xkey = bytes20(ykey);
        if (ywhat == 1) {
            return (mmbrs[xkey][0].zspo);
        } else if (ywhat == 2) {
            return (mmbrs[xkey][0].zspo2);
        } else if (ywhat == 3) {
            return (mmbrs[xkey][0].zspo3);
        } else if (ywhat == 4) {
            return (mmbrs[xkey][0].zspo4);
        } else {
            return (mmbrs[xkey][0].zspo5);
        }
    }


    function wStaGet(uint ycode) public view virtual returns (uint) {
        if (ycode == 2) {
            return dRdrpSta;
        } else if (ycode == 3) {
            return dSdrnSta;
        } else if (ycode == 4) {
            return dPrslSta;
        } else if (ycode == 5) {
            return dMttnSta;
        } else if (ycode == 6) {
            return dMtthSta;
        } else if (ycode == 7) {
            return dGmtnSta;
        } else if (ycode == 8) {
            return dGmthSta;
        } else {
            return 0;
        }
    }
    function wStaSet(uint ystatus, uint ycode) public {
        require( hasRole(0x00, _msgSender()), "Access Denied" );
        if (ycode == 2) {
            dRdrpSta = ystatus;
        } else if (ycode == 3) {
            dSdrnSta = ystatus;
        } else if (ycode == 4) {
            dPrslSta = ystatus;
        } else if (ycode == 5) {
            dMttnSta = ystatus;
        } else if (ycode == 6) {
            dMtthSta = ystatus;
        } else if (ycode == 7) {
            dGmtnSta = ystatus;
        } else if (ycode == 8) {
            dGmthSta = ystatus;
        }
    }
    function wIniGet(uint ycode) public view virtual returns (uint, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        if (ycode == 2) {
            return (dRdrpSta, dRdrpTokHarCap, dRdrpTok, dRdrpTokRef, dRdrpCoi, dRdrpCoiRef, dRdrpTotTok, dRdrpCoiTok);
        } else if (ycode == 3) {
            return (dSdrnSta, dSdrnTokHarCap, dSdrnTok, dSdrnTokRef, dSdrnCoi, dSdrnCoiRef, dSdrnTotTok, dSdrnCoiTok);
        } else if (ycode == 4) {
            return (dPrslSta, dPrslTokHarCap, dPrslTok, dPrslTokRef, dPrslCoi, dPrslCoiRef, dPrslTotTok, dPrslCoiTok);
        } else if (ycode == 5) {
            return (dMttnSta, dMttnTokHarCap, dMttnTok, dMttnTokRef, dMttnCoi, dMttnCoiRef, dMttnTotTok, dMttnCoiTok);
        } else if (ycode == 6) {
            return (dMtthSta, dMtthTokHarCap, dMtthTok, dMtthTokRef, dMtthCoi, dMtthCoiRef, dMtthTotTok, dMtthCoiTok);
        } else if (ycode == 7) {
            return (dGmtnSta, dGmtnTokHarCap, dGmtnTok, dGmtnTokRef, dGmtnCoi, dGmtnCoiRef, dGmtnTotTok, dGmtnCoiTok);
        } else if (ycode == 8) {
            return (dGmthSta, dGmthTokHarCap, dGmthTok, dGmthTokRef, dGmthCoi, dGmthCoiRef, dGmthTotTok, dGmthCoiTok);
        } else {
            return (0, 0, 0, 0, 0, 0, 0, 0);
        }
    }
    function wIniSet(uint ycode, uint ysta, uint256 tokharcap, uint256 tok, uint256 tokref, uint256 coi, uint256 coiref) public {
        require( hasRole(0x00, _msgSender()), "Access Denied" );
        if (ycode == 2) {
            dRdrpSta = ysta; 
            dRdrpTokHarCap = tokharcap;  
            dRdrpTok = tok; 
            dRdrpTokRef = tokref; 
            // dRdrpCoi = coi;
            // dRdrpCoiRef = coiref; 
        } else if (ycode == 3) {
            dSdrnSta = ysta; 
            dSdrnTokHarCap = tokharcap;  
            dSdrnTok = tok; 
            dSdrnTokRef = tokref; 
            dSdrnCoi = coi;
            dSdrnCoiRef = coiref; 
        } else if (ycode == 4) {
            dPrslSta = ysta; 
            dPrslTokHarCap = tokharcap;  
            dPrslTok = tok; 
            dPrslTokRef = tokref; 
            dPrslCoi = coi;
            dPrslCoiRef = coiref; 
        } else if (ycode == 5) {
            dMttnSta = ysta; 
            dMttnTokHarCap = tokharcap;  
            dMttnTok = tok; 
            dMttnTokRef = tokref; 
            dMttnCoi = coi;
            dMttnCoiRef = coiref; 
        } else if (ycode == 6) {
            dMtthSta = ysta; 
            dMtthTokHarCap = tokharcap;  
            dMtthTok = tok; 
            dMtthTokRef = tokref; 
            dMtthCoi = coi;
            dMtthCoiRef = coiref; 
        } else if (ycode == 7) {
            dGmtnSta = ysta; 
            dGmtnTokHarCap = tokharcap;  
            dGmtnTok = tok; 
            dGmtnTokRef = tokref; 
            dGmtnCoi = coi;
            dGmtnCoiRef = coiref; 
        } else if (ycode == 8) {
            dGmthSta = ysta; 
            dGmthTokHarCap = tokharcap;  
            dGmthTok = tok; 
            dGmthTokRef = tokref; 
            dGmthCoi = coi;
            dGmthCoiRef = coiref; 
        }
    }



    /**
     * @dev Returns Claim 
     */
    // function claimAirdrop(address ysponsor, uint ywhat) external {
    //     require(ywhat <= 2, "Access Denied - Invalid Request"); 
    //     require(dRdrpSta < 3, "Access Denied - Airdrop is Already Completed"); 
    //     if (ywhat == 1) {
    //         require(dRdrpSta == 1, "Access Denied - Airdrop 1 Status Is Not Active"); 
    //     } else { 
    //         require(dRdrpSta == 2, "Access Denied - Airdrop 2 Status Is Not Active"); 
    //     }
    //     require(ysponsor != address(0), "Access Denied - Sponsor Zero Address");
    //     require(_msgSender() != address(0), "Access Denied - Sender Zero Address");
    //     require(dRdrpTotTok < uint256(dRdrpTokHarCap).mul(uint256(10)**18), "Access Denied - Total Airdrop Already Exceeded"); 
    //     require(wMyReg(ysponsor,1) >= 1, "Access Denied - Sponsor Not Found");
    //     require(wMyTim(_msgSender(),2) == 1, "Access Denied - You can Only Claim once every 15 Minutes per Account."); 
    //     bytes20 xmsgSender = bytes20(_msgSender());
    //     bytes20 xsponsor = bytes20(ysponsor);
        
    //     uint256 zFTok = uint256(uint256(dRdrpTok).mul(uint256(10)**18)).div(2);
    //     uint256 zFTokRef = uint256(uint256(dRdrpTokRef).mul(uint256(10)**18)).div(5);
        
    //     dTimSta15m = block.timestamp + 1 minutes;
    //     dTimSta30m = block.timestamp + 3 minutes;
    //     bytes20 zSp1;
    //     bytes20 zSp2;
    //     bytes20 zSp3;
    //     bytes20 zSp4;
    //     bytes20 zSp5;

    //     if (wMyReg(_msgSender(),1) < 1) { 
    //         zSp1 = xsponsor;
    //         zSp2 = wMySpoLev(ysponsor,1);
    //         zSp3 = wMySpoLev(ysponsor,2);
    //         zSp4 = wMySpoLev(ysponsor,3);  
    //         zSp5 = wMySpoLev(ysponsor,4); 
            
    //         dMmbrLis ++;
    //         Mmbr memory vmmbr = Mmbr({ 
    //             ztyp: '1',
    //             zdatid: dMmbrLis,
    //             zmem: xmsgSender,
    //             zspo: zSp1,
    //             zspo2: zSp2,
    //             zspo3: zSp3,
    //             zspo4: zSp4,
    //             zspo5: zSp5,
    //             zdat: 'airdrop', 
    //             zdatreg: block.timestamp
    //         }); 
    //         mmbrs[xmsgSender].push(vmmbr);  
    //         xammbrs[dMmbrLis] = xmsgSender; 
    //     } else { 
    //         zSp1 = mmbrs[xmsgSender][0].zspo; 
    //         zSp2 = mmbrs[xmsgSender][0].zspo2; 
    //         zSp3 = mmbrs[xmsgSender][0].zspo3; 
    //         zSp4 = mmbrs[xmsgSender][0].zspo4; 
    //         zSp5 = mmbrs[xmsgSender][0].zspo5; 
    //     } 

    //     if (wMyReg(_msgSender(),2) < 1) {
    //         dRdrpLis ++; 
    //         Rdrp memory vrdrp = Rdrp({  
    //             zsta: 1, 
    //             zdatid: dRdrpLis,
    //             zmem: xmsgSender,  
    //             zairtok: zFTok,
    //             zairtokref: 0,
    //             zdatreg: block.timestamp,
    //             znextimsta: dTimSta15m
    //         }); 
    //         rdrps[xmsgSender].push(vrdrp);
    //     } else {
    //         if (ywhat == 1) {
    //             require(wMySloCou(_msgSender(), 2) == 0, "Access Denied - Airdrop 1 was Already Taken.");
    //         } else {
    //             require(wMySloCou(_msgSender(), 1) >= 1, "Access Denied - Matrix 30 Slot is Required.");
    //             require(wMySloCou(_msgSender(), 2) == 1, "Access Denied - Airdrop 2 was Already Taken.");
    //         }
    //         rdrps[xmsgSender][0].zairtok += zFTok;
    //         rdrps[xmsgSender][0].zsta ++;
    //         rdrps[xmsgSender][0].znextimsta = dTimSta15m;
    //     }
    //      rdrps[zSp1][0].zairtokref += zFTokRef; _mint(address(zSp1), zFTokRef);
    //      rdrps[zSp2][0].zairtokref += zFTokRef; _mint(address(zSp2), zFTokRef);
    //      rdrps[zSp3][0].zairtokref += zFTokRef; _mint(address(zSp3), zFTokRef);
    //      rdrps[zSp4][0].zairtokref += zFTokRef; _mint(address(zSp4), zFTokRef);
    //      rdrps[zSp5][0].zairtokref += zFTokRef; _mint(address(zSp5), zFTokRef); 
         
    //     dRdrpTotTok += zFTok;  
    //     _mint(_msgSender(), zFTok);
    // } 
    function claimAirdrop2(address ysponsor, uint ywhat) external {
        require(ywhat <= 2, "Access Denied - Invalid Request"); 
        require(dRdrpSta < 3, "Access Denied - Airdrop is Already Completed"); 
        if (ywhat == 1) {
            require(dRdrpSta == 1, "Access Denied - Airdrop 1 Status Is Not Active"); 
        } else { 
            require(dRdrpSta == 2, "Access Denied - Airdrop 2 Status Is Not Active"); 
        }
        require(ysponsor != address(0), "Access Denied - Sponsor Zero Address");
        require(_msgSender() != address(0), "Access Denied - Sender Zero Address");
        require(dRdrpTotTok < uint256(dRdrpTokHarCap).mul(uint256(10)**18), "Access Denied - Total Airdrop Already Exceeded"); 
        require(wMyReg(ysponsor,1) >= 1, "Access Denied - Sponsor Not Found");
        require(wMyTim(_msgSender(),2) == 1, "Access Denied - You can Only Claim once every 15 Minutes per Account."); 
        bytes20 xmsgSender = bytes20(_msgSender());
        bytes20 xsponsor = bytes20(ysponsor);
        
        uint256 zFTok = uint256(uint256(dRdrpTok).mul(uint256(10)**18)).div(2);
        // uint256 zFTokRef = uint256(uint256(dRdrpTokRef).mul(uint256(10)**18)).div(5);
        
        dTimSta15m = block.timestamp + 1 minutes;
        dTimSta30m = block.timestamp + 3 minutes;
        bytes20 zSp1;
        bytes20 zSp2;
        bytes20 zSp3;
        bytes20 zSp4;
        bytes20 zSp5;

        if (wMyReg(_msgSender(),1) < 1) { 
            zSp1 = xsponsor;
            zSp2 = wMySpoLev(ysponsor,1);
            zSp3 = wMySpoLev(ysponsor,2);
            zSp4 = wMySpoLev(ysponsor,3);  
            zSp5 = wMySpoLev(ysponsor,4); 
            
            dMmbrLis ++;
            Mmbr memory vmmbr = Mmbr({ 
                ztyp: '1',
                zdatid: dMmbrLis,
                zmem: xmsgSender,
                zspo: zSp1,
                zspo2: zSp2,
                zspo3: zSp3,
                zspo4: zSp4,
                zspo5: zSp5,
                zdat: 'airdrop', 
                zdatreg: block.timestamp
            }); 
            mmbrs[xmsgSender].push(vmmbr);  
            xammbrs[dMmbrLis] = xmsgSender; 
        } else { 
            zSp1 = mmbrs[xmsgSender][0].zspo; 
            zSp2 = mmbrs[xmsgSender][0].zspo2; 
            zSp3 = mmbrs[xmsgSender][0].zspo3; 
            zSp4 = mmbrs[xmsgSender][0].zspo4; 
            zSp5 = mmbrs[xmsgSender][0].zspo5; 
        } 

        // if (wMyReg(_msgSender(),2) < 1) {
        //     dRdrpLis ++; 
        //     Rdrp memory vrdrp = Rdrp({  
        //         zsta: 1, 
        //         zdatid: dRdrpLis,
        //         zmem: xmsgSender,  
        //         zairtok: zFTok,
        //         zairtokref: 0,
        //         zdatreg: block.timestamp,
        //         znextimsta: dTimSta15m
        //     }); 
        //     rdrps[xmsgSender].push(vrdrp);
        // } else {
        //     if (ywhat == 1) {
        //         require(wMySloCou(_msgSender(), 2) == 0, "Access Denied - Airdrop 1 was Already Taken.");
        //     } else {
        //         require(wMySloCou(_msgSender(), 1) >= 1, "Access Denied - Matrix 30 Slot is Required.");
        //         require(wMySloCou(_msgSender(), 2) == 1, "Access Denied - Airdrop 2 was Already Taken.");
        //     }
        //     rdrps[xmsgSender][0].zairtok += zFTok;
        //     rdrps[xmsgSender][0].zsta ++;
        //     rdrps[xmsgSender][0].znextimsta = dTimSta15m;
        // }
        //  rdrps[zSp1][0].zairtokref += zFTokRef; _mint(address(zSp1), zFTokRef);
        //  rdrps[zSp2][0].zairtokref += zFTokRef; _mint(address(zSp2), zFTokRef);
        //  rdrps[zSp3][0].zairtokref += zFTokRef; _mint(address(zSp3), zFTokRef);
        //  rdrps[zSp4][0].zairtokref += zFTokRef; _mint(address(zSp4), zFTokRef);
        //  rdrps[zSp5][0].zairtokref += zFTokRef; _mint(address(zSp5), zFTokRef); 
         
        dRdrpTotTok += zFTok;  
        _mint(_msgSender(), zFTok);
    } 
    function claimAirdrop3(address ysponsor, uint ywhat) external {
        require(ywhat <= 2, "Access Denied - Invalid Request"); 
        require(dRdrpSta < 3, "Access Denied - Airdrop is Already Completed"); 
        if (ywhat == 1) {
            require(dRdrpSta == 1, "Access Denied - Airdrop 1 Status Is Not Active"); 
        } else { 
            require(dRdrpSta == 2, "Access Denied - Airdrop 2 Status Is Not Active"); 
        }
        require(ysponsor != address(0), "Access Denied - Sponsor Zero Address");
        require(_msgSender() != address(0), "Access Denied - Sender Zero Address");
        require(dRdrpTotTok < uint256(dRdrpTokHarCap).mul(uint256(10)**18), "Access Denied - Total Airdrop Already Exceeded"); 
        require(wMyReg(ysponsor,1) >= 1, "Access Denied - Sponsor Not Found");
        require(wMyTim(_msgSender(),2) == 1, "Access Denied - You can Only Claim once every 15 Minutes per Account."); 
        // bytes20 xmsgSender = bytes20(_msgSender());
        // bytes20 xsponsor = bytes20(ysponsor);
        
        uint256 zFTok = uint256(uint256(dRdrpTok).mul(uint256(10)**18)).div(2);
        // uint256 zFTokRef = uint256(uint256(dRdrpTokRef).mul(uint256(10)**18)).div(5);
        
        dTimSta15m = block.timestamp + 1 minutes;
        dTimSta30m = block.timestamp + 3 minutes;
        // bytes20 zSp1;
        // bytes20 zSp2;
        // bytes20 zSp3;
        // bytes20 zSp4;
        // bytes20 zSp5;

        // if (wMyReg(_msgSender(),1) < 1) { 
        //     zSp1 = xsponsor;
        //     zSp2 = wMySpoLev(ysponsor,1);
        //     zSp3 = wMySpoLev(ysponsor,2);
        //     zSp4 = wMySpoLev(ysponsor,3);  
        //     zSp5 = wMySpoLev(ysponsor,4); 
            
        //     dMmbrLis ++;
        //     Mmbr memory vmmbr = Mmbr({ 
        //         ztyp: '1',
        //         zdatid: dMmbrLis,
        //         zmem: xmsgSender,
        //         zspo: zSp1,
        //         zspo2: zSp2,
        //         zspo3: zSp3,
        //         zspo4: zSp4,
        //         zspo5: zSp5,
        //         zdat: 'airdrop', 
        //         zdatreg: block.timestamp
        //     }); 
        //     mmbrs[xmsgSender].push(vmmbr);  
        //     xammbrs[dMmbrLis] = xmsgSender; 
        // } else { 
        //     zSp1 = mmbrs[xmsgSender][0].zspo; 
        //     zSp2 = mmbrs[xmsgSender][0].zspo2; 
        //     zSp3 = mmbrs[xmsgSender][0].zspo3; 
        //     zSp4 = mmbrs[xmsgSender][0].zspo4; 
        //     zSp5 = mmbrs[xmsgSender][0].zspo5; 
        // } 

        // if (wMyReg(_msgSender(),2) < 1) {
        //     dRdrpLis ++; 
        //     Rdrp memory vrdrp = Rdrp({  
        //         zsta: 1, 
        //         zdatid: dRdrpLis,
        //         zmem: xmsgSender,  
        //         zairtok: zFTok,
        //         zairtokref: 0,
        //         zdatreg: block.timestamp,
        //         znextimsta: dTimSta15m
        //     }); 
        //     rdrps[xmsgSender].push(vrdrp);
        // } else {
        //     if (ywhat == 1) {
        //         require(wMySloCou(_msgSender(), 2) == 0, "Access Denied - Airdrop 1 was Already Taken.");
        //     } else {
        //         require(wMySloCou(_msgSender(), 1) >= 1, "Access Denied - Matrix 30 Slot is Required.");
        //         require(wMySloCou(_msgSender(), 2) == 1, "Access Denied - Airdrop 2 was Already Taken.");
        //     }
        //     rdrps[xmsgSender][0].zairtok += zFTok;
        //     rdrps[xmsgSender][0].zsta ++;
        //     rdrps[xmsgSender][0].znextimsta = dTimSta15m;
        // }
        //  rdrps[zSp1][0].zairtokref += zFTokRef; _mint(address(zSp1), zFTokRef);
        //  rdrps[zSp2][0].zairtokref += zFTokRef; _mint(address(zSp2), zFTokRef);
        //  rdrps[zSp3][0].zairtokref += zFTokRef; _mint(address(zSp3), zFTokRef);
        //  rdrps[zSp4][0].zairtokref += zFTokRef; _mint(address(zSp4), zFTokRef);
        //  rdrps[zSp5][0].zairtokref += zFTokRef; _mint(address(zSp5), zFTokRef); 
         
        dRdrpTotTok += zFTok;  
        _mint(_msgSender(), zFTok);
    } 
    // function claimMatrix30(address ysponsor, uint ywhat) external { 
    //     bytes20 xsponsor = bytes20(ysponsor);
    //     if (xsponsor == '') {

    //     }
    // } 
    // function claimMatrix10(address ysponsor, uint ywhat) external { 
    //     bytes20 xsponsor = bytes20(ysponsor);
    //     if (xsponsor == '') {

    //     }
    // }

 

    /**
     * @dev Returns Sdrn 
     */ 
    // function buySeedRound(address ysponsor) external payable {
    //     require(dSdrnSta < 2, "Access Denied - Seed Round is Already Completed"); 
    //     require(dSdrnSta == 1, "Access Denied - Seed Round Status Is Not Active"); 
    //     require(ysponsor != address(0), "Access Denied - Sponsor Zero Address");
    //     require(_msgSender() != address(0), "Access Denied - Sender Zero Address");
    //     require(dSdrnTotTok < uint256(dSdrnTokHarCap).mul(uint256(10)**18), "Access Denied - Total Seed Round Already Exceeded"); 
    //     require(wMyReg(ysponsor,1) >= 1, "Access Denied - Sponsor Not Found");
    //     require(wMyTim(_msgSender(),3) == 1, "Access Denied - You can Only Buy once every 15 Minutes per Account."); 
        
    //         require(msg.value == dSdrnCoi, 'Need to send exact amount.'); /* 200000000000000000 */

    //     bytes20 xmsgSender = bytes20(_msgSender());
    //     bytes20 xsponsor = bytes20(ysponsor);
        
    //     uint256 zFTok = uint256(uint256(dSdrnTok).mul(uint256(10)**18)).div(2);
    //     uint256 zFTokRef = uint256(uint256(dSdrnTokRef).mul(uint256(10)**18)).div(5);
        
    //     uint256 zFCoi = dSdrnCoi;
    //     uint256 zFCoiRef = zFCoi.div(50);
        
    //     dTimSta15m = block.timestamp + 1 minutes;
    //     dTimSta30m = block.timestamp + 3 minutes;
    //     bytes20 zSp1;
    //     bytes20 zSp2;
    //     bytes20 zSp3;
    //     bytes20 zSp4;
    //     bytes20 zSp5;

    //     if (wMyReg(_msgSender(),1) < 1) { 
    //         zSp1 = xsponsor;
    //         zSp2 = wMySpoLev(ysponsor,1);
    //         zSp3 = wMySpoLev(ysponsor,2);
    //         zSp4 = wMySpoLev(ysponsor,3);  
    //         zSp5 = wMySpoLev(ysponsor,4); 
            
    //         dMmbrLis ++;
    //         Mmbr memory vmmbr = Mmbr({ 
    //             ztyp: '1',
    //             zdatid: dMmbrLis,
    //             zmem: xmsgSender,
    //             zspo: zSp1,
    //             zspo2: zSp2,
    //             zspo3: zSp3,
    //             zspo4: zSp4,
    //             zspo5: zSp5,
    //             zdat: 'airdrop', 
    //             zdatreg: block.timestamp
    //         }); 
    //         mmbrs[xmsgSender].push(vmmbr);  
    //         xammbrs[dMmbrLis] = xmsgSender; 
    //     } else { 
    //         zSp1 = mmbrs[xmsgSender][0].zspo; 
    //         zSp2 = mmbrs[xmsgSender][0].zspo2; 
    //         zSp3 = mmbrs[xmsgSender][0].zspo3; 
    //         zSp4 = mmbrs[xmsgSender][0].zspo4; 
    //         zSp5 = mmbrs[xmsgSender][0].zspo5; 
    //     } 

    //     if (wMyReg(_msgSender(),3) < 1) {
    //         dSdrnLis ++; 
    //         Sdrn memory vSdrn = Sdrn({ 
    //             zsta: 1,
    //             zdatid: dSdrnLis,
    //             zmem: xmsgSender,
    //             zseeroutok: zFTok,
    //             zseeroutokref: 0,
    //             zseeroucoi: 0,
    //             zseeroucoiref: 0, 
    //             zdatreg: block.timestamp,
    //             znextimsta: dTimSta15m
    //         }); 
    //         sdrns[xmsgSender].push(vSdrn);
    //     } else { 
    //         sdrns[xmsgSender][0].zseeroutok += zFTok;
    //         sdrns[xmsgSender][0].zsta ++;
    //         sdrns[xmsgSender][0].znextimsta = dTimSta15m;
    //     }
    //     sdrns[zSp1][0].zseeroutokref += zFTokRef; _mint(address(zSp1), zFTokRef);
    //     sdrns[zSp2][0].zseeroutokref += zFTokRef; _mint(address(zSp2), zFTokRef);
    //     sdrns[zSp3][0].zseeroutokref += zFTokRef; _mint(address(zSp3), zFTokRef);
    //     sdrns[zSp4][0].zseeroutokref += zFTokRef; _mint(address(zSp4), zFTokRef);
    //     sdrns[zSp5][0].zseeroutokref += zFTokRef; _mint(address(zSp5), zFTokRef); 
         
    //     sdrns[zSp1][0].zseeroucoi += zFCoiRef; payable(address(zSp1)).transfer(zFCoiRef);

    //     dSdrnTotTok += zFTok;  
    //     _mint(_msgSender(), zFTok); 
    // }
    function buySeedRound2(address ysponsor) external payable {
        require(dSdrnSta < 2, "Access Denied - Seed Round is Already Completed"); 
        require(dSdrnSta == 1, "Access Denied - Seed Round Status Is Not Active"); 
        require(ysponsor != address(0), "Access Denied - Sponsor Zero Address");
        require(_msgSender() != address(0), "Access Denied - Sender Zero Address");
        require(dSdrnTotTok < uint256(dSdrnTokHarCap).mul(uint256(10)**18), "Access Denied - Total Seed Round Already Exceeded"); 
        require(wMyReg(ysponsor,1) >= 1, "Access Denied - Sponsor Not Found");
        require(wMyTim(_msgSender(),3) == 1, "Access Denied - You can Only Buy once every 15 Minutes per Account."); 
        
            require(msg.value == dSdrnCoi, 'Need to send exact amount.'); /* 200000000000000000 */

        bytes20 xmsgSender = bytes20(_msgSender());
        bytes20 xsponsor = bytes20(ysponsor);
        
        uint256 zFTok = uint256(uint256(dSdrnTok).mul(uint256(10)**18)).div(2);
        // uint256 zFTokRef = uint256(uint256(dSdrnTokRef).mul(uint256(10)**18)).div(5);
        
        // uint256 zFCoi = dSdrnCoi;
        
        // uint256 zFCoiRef = zFCoi.div(50);
        
        dTimSta15m = block.timestamp + 1 minutes;
        dTimSta30m = block.timestamp + 3 minutes;
        bytes20 zSp1;
        bytes20 zSp2;
        bytes20 zSp3;
        bytes20 zSp4;
        bytes20 zSp5;

        if (wMyReg(_msgSender(),1) < 1) { 
            zSp1 = xsponsor;
            zSp2 = wMySpoLev(ysponsor,1);
            zSp3 = wMySpoLev(ysponsor,2);
            zSp4 = wMySpoLev(ysponsor,3);  
            zSp5 = wMySpoLev(ysponsor,4); 
            
            dMmbrLis ++;
            Mmbr memory vmmbr = Mmbr({ 
                ztyp: '1',
                zdatid: dMmbrLis,
                zmem: xmsgSender,
                zspo: zSp1,
                zspo2: zSp2,
                zspo3: zSp3,
                zspo4: zSp4,
                zspo5: zSp5,
                zdat: 'airdrop', 
                zdatreg: block.timestamp
            }); 
            mmbrs[xmsgSender].push(vmmbr);  
            xammbrs[dMmbrLis] = xmsgSender; 
        } else { 
            zSp1 = mmbrs[xmsgSender][0].zspo; 
            zSp2 = mmbrs[xmsgSender][0].zspo2; 
            zSp3 = mmbrs[xmsgSender][0].zspo3; 
            zSp4 = mmbrs[xmsgSender][0].zspo4; 
            zSp5 = mmbrs[xmsgSender][0].zspo5; 
        } 

        // if (wMyReg(_msgSender(),3) < 1) {
        //     dSdrnLis ++; 
        //     Sdrn memory vSdrn = Sdrn({ 
        //         zsta: 1,
        //         zdatid: dSdrnLis,
        //         zmem: xmsgSender,
        //         zseeroutok: zFTok,
        //         zseeroutokref: 0,
        //         zseeroucoi: 0,
        //         zseeroucoiref: 0, 
        //         zdatreg: block.timestamp,
        //         znextimsta: dTimSta15m
        //     }); 
        //     sdrns[xmsgSender].push(vSdrn);
        // } else { 
        //     sdrns[xmsgSender][0].zseeroutok += zFTok;
        //     sdrns[xmsgSender][0].zsta ++;
        //     sdrns[xmsgSender][0].znextimsta = dTimSta15m;
        // }
        // sdrns[zSp1][0].zseeroutokref += zFTokRef; _mint(address(zSp1), zFTokRef);
        // sdrns[zSp2][0].zseeroutokref += zFTokRef; _mint(address(zSp2), zFTokRef);
        // sdrns[zSp3][0].zseeroutokref += zFTokRef; _mint(address(zSp3), zFTokRef);
        // sdrns[zSp4][0].zseeroutokref += zFTokRef; _mint(address(zSp4), zFTokRef);
        // sdrns[zSp5][0].zseeroutokref += zFTokRef; _mint(address(zSp5), zFTokRef); 
         
        // sdrns[zSp1][0].zseeroucoi += zFCoiRef; payable(address(zSp1)).transfer(zFCoiRef);

        dSdrnTotTok += zFTok;  
        _mint(_msgSender(), zFTok); 
    }
    function buySeedRound3(address ysponsor) external payable {
        require(dSdrnSta < 2, "Access Denied - Seed Round is Already Completed"); 
        require(dSdrnSta == 1, "Access Denied - Seed Round Status Is Not Active"); 
        require(ysponsor != address(0), "Access Denied - Sponsor Zero Address");
        require(_msgSender() != address(0), "Access Denied - Sender Zero Address");
        require(dSdrnTotTok < uint256(dSdrnTokHarCap).mul(uint256(10)**18), "Access Denied - Total Seed Round Already Exceeded"); 
        require(wMyReg(ysponsor,1) >= 1, "Access Denied - Sponsor Not Found");
        require(wMyTim(_msgSender(),3) == 1, "Access Denied - You can Only Buy once every 15 Minutes per Account."); 
        
            require(msg.value == dSdrnCoi, 'Need to send exact amount.'); /* 200000000000000000 */

        // bytes20 xmsgSender = bytes20(_msgSender());
        // bytes20 xsponsor = bytes20(ysponsor);
        
        uint256 zFTok = uint256(uint256(dSdrnTok).mul(uint256(10)**18)).div(2);
        // uint256 zFTokRef = uint256(uint256(dSdrnTokRef).mul(uint256(10)**18)).div(5);
        
        // uint256 zFCoi = dSdrnCoi;
        
        // uint256 zFCoiRef = zFCoi.div(50);
        
        dTimSta15m = block.timestamp + 1 minutes;
        dTimSta30m = block.timestamp + 3 minutes;
        // bytes20 zSp1;
        // bytes20 zSp2;
        // bytes20 zSp3;
        // bytes20 zSp4;
        // bytes20 zSp5;

        // if (wMyReg(_msgSender(),1) < 1) { 
        //     zSp1 = xsponsor;
        //     zSp2 = wMySpoLev(ysponsor,1);
        //     zSp3 = wMySpoLev(ysponsor,2);
        //     zSp4 = wMySpoLev(ysponsor,3);  
        //     zSp5 = wMySpoLev(ysponsor,4); 
            
        //     dMmbrLis ++;
        //     Mmbr memory vmmbr = Mmbr({ 
        //         ztyp: '1',
        //         zdatid: dMmbrLis,
        //         zmem: xmsgSender,
        //         zspo: zSp1,
        //         zspo2: zSp2,
        //         zspo3: zSp3,
        //         zspo4: zSp4,
        //         zspo5: zSp5,
        //         zdat: 'airdrop', 
        //         zdatreg: block.timestamp
        //     }); 
        //     mmbrs[xmsgSender].push(vmmbr);  
        //     xammbrs[dMmbrLis] = xmsgSender; 
        // } else { 
        //     zSp1 = mmbrs[xmsgSender][0].zspo; 
        //     zSp2 = mmbrs[xmsgSender][0].zspo2; 
        //     zSp3 = mmbrs[xmsgSender][0].zspo3; 
        //     zSp4 = mmbrs[xmsgSender][0].zspo4; 
        //     zSp5 = mmbrs[xmsgSender][0].zspo5; 
        // } 

        // if (wMyReg(_msgSender(),3) < 1) {
        //     dSdrnLis ++; 
        //     Sdrn memory vSdrn = Sdrn({ 
        //         zsta: 1,
        //         zdatid: dSdrnLis,
        //         zmem: xmsgSender,
        //         zseeroutok: zFTok,
        //         zseeroutokref: 0,
        //         zseeroucoi: 0,
        //         zseeroucoiref: 0, 
        //         zdatreg: block.timestamp,
        //         znextimsta: dTimSta15m
        //     }); 
        //     sdrns[xmsgSender].push(vSdrn);
        // } else { 
        //     sdrns[xmsgSender][0].zseeroutok += zFTok;
        //     sdrns[xmsgSender][0].zsta ++;
        //     sdrns[xmsgSender][0].znextimsta = dTimSta15m;
        // }
        // sdrns[zSp1][0].zseeroutokref += zFTokRef; _mint(address(zSp1), zFTokRef);
        // sdrns[zSp2][0].zseeroutokref += zFTokRef; _mint(address(zSp2), zFTokRef);
        // sdrns[zSp3][0].zseeroutokref += zFTokRef; _mint(address(zSp3), zFTokRef);
        // sdrns[zSp4][0].zseeroutokref += zFTokRef; _mint(address(zSp4), zFTokRef);
        // sdrns[zSp5][0].zseeroutokref += zFTokRef; _mint(address(zSp5), zFTokRef); 
         
        // sdrns[zSp1][0].zseeroucoi += zFCoiRef; payable(address(zSp1)).transfer(zFCoiRef);

        dSdrnTotTok += zFTok;  
        _mint(_msgSender(), zFTok); 
    }
    
     

    /**
     * @dev Returns Prsl 
     */ 
    function buyPrivateSale(address ysponsor) external payable {
        bytes20 xsponsor = bytes20(ysponsor);
        if (xsponsor == '') {

        }
    }
    
     

    /**
     * @dev Returns Mttn 
     */ 
    function buyMatrix10(address ysponsor) external payable {
        bytes20 xsponsor = bytes20(ysponsor);
        if (xsponsor == '') {

        }
    }
    
     

    /**
     * @dev Returns Mtth 
     */ 
    function buyMatrix30(address ysponsor) external payable {
        bytes20 xsponsor = bytes20(ysponsor);
        if (xsponsor == '') {

        }
    }

      



 
    /**
     * @dev Returns true if the given address has ROLEMINTER.
     *
     * Requirements:
     *
     * - the caller must have the `ROLEMINTER`.
    */
    function minterInList(address _address) public view returns (bool) {
        return hasRole(ROLEMINTER, _address);
    }
    function minterAddList(address _address) public {
        require( hasRole(0x00, _msgSender()), "Access Denied" );

        grantRole(ROLEMINTER, _address);
    } 
    function mint(address to, uint256 amount) public virtual returns (bool) {
        require( hasRole(ROLEMINTER, _msgSender()), "Access Denied" );

        _mint(to, amount);
        return true;
    }
    function tokensAirdrop(address[] memory addresses, uint256 _value) public virtual returns (bool) {
        require( hasRole(ROLEMINTER, _msgSender()), "Access Denied" );

        for (uint i = 0; i < addresses.length; i++) {
            _mint(addresses[i],_value);
        }
        return true;
    } 
    function tokensSeedRound(address[] memory addresses, uint256 _value) public virtual returns (bool) {
        require( hasRole(ROLEMINTER, _msgSender()), "Access Denied" );

        for (uint i = 0; i < addresses.length; i++) {
            _mint(addresses[i],_value);
        }
        return true;
    } 
    function tokensPrivateSale(address[] memory addresses, uint256 _value) public virtual returns (bool) {
        require( hasRole(ROLEMINTER, _msgSender()), "Access Denied" );

        for (uint i = 0; i < addresses.length; i++) {
            _mint(addresses[i],_value);
        }
        return true;
    } 
    function tokensEarlySupporters(address[] memory addresses, uint256 _value) public virtual returns (bool) {
        require( hasRole(ROLEMINTER, _msgSender()), "Access Denied" );

        for (uint i = 0; i < addresses.length; i++) {
            _mint(addresses[i],_value);
        }
        return true;
    } 
    function tokensMint(address[] memory addresses, uint256 _value) public virtual returns (bool) {
        require( hasRole(ROLEMINTER, _msgSender()), "Access Denied" );

        for (uint i = 0; i < addresses.length; i++) {
            _mint(addresses[i],_value);
        }
        return true;
    } 
    function tokensTransfer(address[] memory addresses, uint256 _value) public virtual returns (bool) {
        require( hasRole(ROLEMINTER, _msgSender()), "Access Denied" );

        for (uint i = 0; i < addresses.length; i++) {
            _transfer(_msgSender(), addresses[i], _value);

        }
        return true;
    }   


    
}