// SPDX-License-Identifier: MIT

// --------------------------------------------
// ----------- COIN CENTRE TOKEN --------------
// --------------------------------------------
// final 0x97EF06e5A662433B0665aDA4B5DaD6a48BA96ec8
// final2 0x5aCDc7AcBBE99C7C003A6bfdb3e376421ADD9A85
// final3 0xE1D22E5b9611704F0d0011074be8341fe6bc954b
// airdrop,seedround,privatesale
/**
10001 = Access Denied - Need to Send Exact Amount
10002 = Access Denied - Invalid Request
10003 = Access Denied - Zero Address
10004 = Access Denied - Is Zero Address

20001 = Access Denied - Already Completed
20002 = Access Denied - Already Exceeded
20003 = Access Denied - Sponsor Not Found
20004 = Access Denied - Only 1 Transaction is allowed every 15 Minutes per Account
20005 = Access Denied - Was Already Taken
*/

pragma solidity ^0.8.3;
 
import "./fin-lib-v003.sol";

/**
 * @title CoinCentreToken ERC20 token
 * @dev This is the base token to allow for staking and trading
 */
contract CoinCentreToken is ERC20, Ownable, ReentrancyGuard {
    using SafeMath for uint256; 
      
    //*  
    bytes20 private xDefTop;
    bytes20 private xDefSpo;
 
    uint16 private xLisMmbr;
    uint16 private xLisRdrp;
    uint16 private xLisSdrn;
    uint16 private xLisPrsl;
    uint16 private xLisCnt1;
    uint16 private xLisSlt1;
    // a
     
    struct Mmbr {
        bytes4 ztyp;
        uint16 znum;
        bytes20 znam;
        bytes20 zmem;
        bytes20 zspo;   
        bytes32 zdat; 
        uint256 zdatreg;
    }   
    mapping(bytes20 => Mmbr[]) mmbrs; 
    mapping(uint16 => bytes20) public xmmbr; 
    mapping(bytes20 => bytes20) public nmmbr; 
 
    struct Testdata {
        uint zsta;
        uint16 znum;
        bytes20 zmem; 
        uint256 ztok;
        uint256 ztokref; 
        uint256 zcoi;
        uint256 zcoiref; 
        uint256 zpoi;
        uint256 zpoiref; 
        uint256 zdatreg;
        uint256 znextimsta;
    }   
    mapping(bytes8 => mapping(bytes20 => Testdata[])) public testdatas; 
    mapping(uint16 => bytes20) public xrdrp; 
    mapping(uint16 => bytes20) public xsdrn; 
    mapping(uint16 => bytes20) public xprsl; 
    mapping(uint16 => bytes20) public xcnt1; 
    mapping(uint16 => bytes20) public xslt1; 
    // a

    struct Slot {
        uint zsta;
        uint16 znum;
        bytes20 zmem; 
        bytes20 znam; 
        bytes20 zpla; 
        bytes20 zpos; 
        uint256 ztok;
        uint256 ztokref; 
        uint256 zcoi;
        uint256 zcoiref; 
        uint256 zpoi;
        uint256 zpoiref; 
        uint256 zdatreg;
        uint256 znextimsta;
    }   
    mapping(bytes20 => mapping(bytes20 => Testdata[])) public slots;  

    //*  
    struct Cnfg {
        uint dSta;
        uint256 dTokMax;
        uint256 dTok;
        uint256 dTokRef;
        uint256 dCoi;
        uint256 dCoiRef;
        uint256 dPoi;
        uint256 dPoiTak;
        uint256 dTotTok;
        uint256 dTotCoi;
        uint256 dTotPoi;
    }   
    mapping(bytes8 => Cnfg[]) cnfgs;


    //*  
    constructor() ERC20("CoinCentreToken", "CCTOKEN") { 
 
        //Init totalSupply
        _mint(_msgSender(), uint256(5000000).mul(uint256(10)**18));


        //*
        xDefTop = bytes20(_msgSender()); 
        xDefSpo = xDefTop;  
 
        xLisMmbr ++;
            Mmbr memory vmmbr = Mmbr({ 
                ztyp: '1',
                znum: xLisMmbr,
                znam: bytes20('owner'),
                zmem: xDefTop,
                zspo: xDefTop,
                zdat: 'constructor',  
                zdatreg: block.timestamp
            }); 
            mmbrs[xDefTop].push(vmmbr); 
            xmmbr[xLisMmbr] = xDefTop; 
            nmmbr[bytes20('owner')] = xDefTop; 
              

        xLisRdrp ++;
            Testdata memory vxLisRdrp = Testdata({  
                zsta: 0, 
                znum: xLisRdrp,
                zmem: xDefTop,
                ztok: 0,
                ztokref: 0,
                zcoi: 0,
                zcoiref: 0,
                zpoi: 0,
                zpoiref: 0,
                zdatreg: block.timestamp,
                znextimsta: block.timestamp
            }); 
            testdatas[bytes8('rdrp')][xDefTop].push(vxLisRdrp);  
            xrdrp[xLisRdrp] = xDefTop; 
        xLisSdrn ++;
            Testdata memory vxLisSdrn = Testdata({  
                zsta: 0, 
                znum: xLisSdrn,
                zmem: xDefTop,
                ztok: 0,
                ztokref: 0,
                zcoi: 0,
                zcoiref: 0,
                zpoi: 0,
                zpoiref: 0,
                zdatreg: block.timestamp,
                znextimsta: block.timestamp
            }); 
            testdatas[bytes8('sdrn')][xDefTop].push(vxLisSdrn);  
            xsdrn[xLisSdrn] = xDefTop; 
        xLisPrsl ++;
            Testdata memory vxLisPrsl = Testdata({  
                zsta: 0, 
                znum: xLisPrsl,
                zmem: xDefTop,
                ztok: 0,
                ztokref: 0,
                zcoi: 0,
                zcoiref: 0,
                zpoi: 0,
                zpoiref: 0,
                zdatreg: block.timestamp,
                znextimsta: block.timestamp
            }); 
            testdatas[bytes8('prsl')][xDefTop].push(vxLisPrsl);  
            xprsl[xLisPrsl] = xDefTop; 
        xLisCnt1 ++;
            Testdata memory vxLisCnt1 = Testdata({  
                zsta: 0, 
                znum: xLisCnt1,
                zmem: xDefTop,
                ztok: 0,
                ztokref: 0,
                zcoi: 0,
                zcoiref: 0,
                zpoi: 0,
                zpoiref: 0,
                zdatreg: block.timestamp,
                znextimsta: block.timestamp
            }); 
            testdatas[bytes8('cnt1')][xDefTop].push(vxLisCnt1);  
            xcnt1[xLisCnt1] = xDefTop; 
        xLisSlt1 ++;
            Testdata memory vxLisSlt1 = Testdata({  
                zsta: 0, 
                znum: xLisSlt1,
                zmem: xDefTop,
                ztok: 0,
                ztokref: 0,
                zcoi: 0,
                zcoiref: 0,
                zpoi: 0,
                zpoiref: 0,
                zdatreg: block.timestamp,
                znextimsta: block.timestamp
            }); 
            testdatas[bytes8('slt1')][xDefTop].push(vxLisSlt1);  
            xslt1[xLisSlt1] = xDefTop; 
        // a
          
        Cnfg memory vcnfgrdrp = Cnfg({   
                dSta: 1,
                dTokMax: 800000,
                dTok: 400,
                dTokRef: 100,
                dCoi: 0, 
                dCoiRef: 0, 
                dPoi: 0, 
                dPoiTak: 0, 
                dTotTok: 0, 
                dTotCoi: 0, 
                dTotPoi: 0
            });  
            cnfgs[bytes8('rdrp')].push(vcnfgrdrp);   
        Cnfg memory vcnfgsdrn = Cnfg({   
                dSta: 1,
                dTokMax: 1600000,
                dTok: 5000,
                dTokRef: 50,
                dCoi: 20000000000000000, 
                dCoiRef: 200000000000000, 
                dPoi: 0, 
                dPoiTak: 0, 
                dTotTok: 0, 
                dTotCoi: 0, 
                dTotPoi: 0
            });  
            cnfgs[bytes8('sdrn')].push(vcnfgsdrn);
        Cnfg memory vcnfgprsl = Cnfg({   
                dSta: 1,
                dTokMax: 1600000,
                dTok: 5000,
                dTokRef: 50,
                dCoi: 20000000000000000, 
                dCoiRef: 200000000000000, 
                dPoi: 0, 
                dPoiTak: 0, 
                dTotTok: 0, 
                dTotCoi: 0, 
                dTotPoi: 0
            });  
            cnfgs[bytes8('prsl')].push(vcnfgprsl);
        Cnfg memory vcnfgcnt1 = Cnfg({   
                dSta: 1,
                dTokMax: 0,
                dTok: 0,
                dTokRef: 0,
                dCoi: 20000000000000000, 
                dCoiRef: 200000000000000, 
                dPoi: 0, 
                dPoiTak: 0, 
                dTotTok: 0, 
                dTotCoi: 0, 
                dTotPoi: 0
            });  
            cnfgs[bytes8('cnt1')].push(vcnfgcnt1);
        Cnfg memory vcnfgslt1 = Cnfg({   
                dSta: 1,
                dTokMax: 0,
                dTok: 0,
                dTokRef: 0,
                dCoi: 20000000000000000, 
                dCoiRef: 200000000000000, 
                dPoi: 0, 
                dPoiTak: 0, 
                dTotTok: 0, 
                dTotCoi: 0, 
                dTotPoi: 0
            });  
            cnfgs[bytes8('slt1')].push(vcnfgslt1);
        // a

    }


    function hash(string memory _text, uint16 _num, address _addr) public pure returns (bytes32) {
        return keccak256(abi.encode(_text, _num, _addr));
    }

    /**
     * @dev Returns Pblc 
     */
    function wGetCod(uint16 ynumber) internal view virtual returns (bytes8) { 
        if (ynumber == 2) {
            return bytes8('rdrp');
        } else if (ynumber == 3) {
            return bytes8('sdrn');
        } else if (ynumber == 4) {
            return bytes8('prsl');
        } else if (ynumber == 5) {
            return bytes8('cnt1');
        } else if (ynumber == 6) {
            return bytes8('slt1');
        } else {
            return bytes8('zzzz');
        }
        // a
    }
    function wTotPar(uint16 ynumber) public view returns(uint256) { 
        if (ynumber == 1) {
            return xLisMmbr;
        } else if (ynumber == 2) {
            return xLisRdrp;
        } else if (ynumber == 3) {
            return xLisSdrn;
        } else if (ynumber == 4) {
            return xLisPrsl; 
        } else if (ynumber == 5) {
            return xLisCnt1; 
        } else if (ynumber == 6) {
            return xLisSlt1; 
        } else {
            return 0;
        }
        // a
    }
    function wTotTok(uint16 ynumber) public view virtual returns (uint256) {
        bytes8 xcode = wGetCod(ynumber); 
            return cnfgs[xcode][0].dTotTok; 
        // a
    }
    function wTotCoi(uint16 ynumber) public view virtual returns (uint256) {
        bytes8 xcode = wGetCod(ynumber); 
            return cnfgs[xcode][0].dTotCoi; 
        // a
    }
    function wTotPoi(uint16 ynumber) public view virtual returns (uint256) {
        bytes8 xcode = wGetCod(ynumber); 
            return cnfgs[xcode][0].dTotPoi; 
        // a
    }
    function wMyReg(address ykey, uint16 ynumber) public view virtual returns (uint) { 
        bytes8 xcode = wGetCod(ynumber); 
        bytes20 xkey = bytes20(ykey); 
        if (ynumber == 1) {
            return mmbrs[xkey].length;
        } else {
            return testdatas[xcode][xkey].length;
        }
        // a
    }
    function wMySta(address ykey, uint16 ynumber) public view virtual returns (uint) { 
        bytes8 xcode = wGetCod(ynumber); 
        bytes20 xkey = bytes20(ykey); 
            return testdatas[xcode][xkey][0].zsta;
        // a
    }
    function wMyTok(address ykey, uint16 ynumber) public view virtual returns (uint256) { 
        bytes8 xcode = wGetCod(ynumber); 
        bytes20 xkey = bytes20(ykey);
            return testdatas[xcode][xkey][0].ztok; 
        // a
    } 
    function wMyTokRef(address ykey, uint16 ynumber) public view virtual returns (uint256) { 
        bytes8 xcode = wGetCod(ynumber); 
        bytes20 xkey = bytes20(ykey);
            return testdatas[xcode][xkey][0].ztokref;  
        // a  
    } 
    function wMyCoi(address ykey, uint16 ynumber) public view virtual returns (uint256) {  
        bytes8 xcode = wGetCod(ynumber); 
        bytes20 xkey = bytes20(ykey);
            return testdatas[xcode][xkey][0].zcoi; 
        // a
    } 
    function wMyCoiRef(address ykey, uint16 ynumber) public view virtual returns (uint256) { 
        bytes8 xcode = wGetCod(ynumber); 
        bytes20 xkey = bytes20(ykey);
            return testdatas[xcode][xkey][0].zcoiref; 
        // a
    } 
    function wMyPoi(address ykey, uint16 ynumber) public view virtual returns (uint256) {  
        bytes8 xcode = wGetCod(ynumber); 
        bytes20 xkey = bytes20(ykey);
            return testdatas[xcode][xkey][0].zpoi; 
        // a
    } 
    function wMyTim(address ykey, uint16 ynumber) internal view virtual returns (uint) {
        bytes8 xcode = wGetCod(ynumber); 
        bytes20 xkey = bytes20(ykey); 
            if (testdatas[xcode][xkey][0].znextimsta >= block.timestamp) { return 0; } else { return 1; } 
        // a
    }
    function xCnfgStaGet(uint16 ynumber) public view virtual returns (uint) {
        bytes8 xcode = wGetCod(ynumber); 
        return cnfgs[xcode][0].dSta; 
    }
    function xCnfgStaSet(uint16 ynumber, uint ystatus) public onlyOwner {
        bytes8 xcode = wGetCod(ynumber);  
        cnfgs[xcode][0].dSta = ystatus;
    } 
    function xCnfgAmoGet(uint16 ynumber, uint ywhat) public view virtual returns (uint256) {
        bytes8 xcode = wGetCod(ynumber);  
        if (ywhat == 1) {
            return cnfgs[xcode][0].dTokMax; 
        } else if (ywhat == 2) {
            return cnfgs[xcode][0].dTok; 
        } else if (ywhat == 3) {
            return cnfgs[xcode][0].dTokRef; 
        } else if (ywhat == 4) {
            return cnfgs[xcode][0].dCoi; 
        } else if (ywhat == 5) {
            return cnfgs[xcode][0].dCoiRef; 
        } else if (ywhat == 6) {
            return cnfgs[xcode][0].dPoi; 
        } else if (ywhat == 7) {
            return cnfgs[xcode][0].dPoiTak; 
        } else {
            return 0;
        }
    }
    function xCnfgAmoSet(uint16 ynumber, uint yamount, uint ywhat) public onlyOwner {
        bytes8 xcode = wGetCod(ynumber); 
        if (ywhat == 1) { 
            cnfgs[xcode][0].dTokMax = yamount;
        } else if (ywhat == 2) {
            cnfgs[xcode][0].dTok = yamount; 
        } else if (ywhat == 3) {
            cnfgs[xcode][0].dTokRef = yamount; 
        } else if (ywhat == 4) {
            cnfgs[xcode][0].dCoi = yamount; 
        } else if (ywhat == 5) {
            cnfgs[xcode][0].dCoiRef = yamount; 
        } else if (ywhat == 6) {
            cnfgs[xcode][0].dPoi = yamount; 
        } else if (ywhat == 7) {
            cnfgs[xcode][0].dPoiTak = yamount; 
        }
    } 

        
        

    /*
     * @dev Get 
     */
    function airdropClaim(address ysponsor, uint ywhat) public { 
        if (ywhat == 1) {
            new1reg(ysponsor, 1, 2);
        } else if (ywhat == 2) {
            new1reg(ysponsor, 2, 2);
        } else {
            require(ywhat == 1, "Error: 10002"); 
        }
    }
    function new1reg(address ysponsor, uint ywhat, uint16 ynumber) private { 
        bytes8 xcode = wGetCod(ynumber); 
        
        require(cnfgs[xcode][0].dSta != 888, "Error: 20001"); 
        require(ysponsor != address(0), "Error: 10003");
        require(_msgSender() != address(0), "Error: 10003");
        if (uint256(cnfgs[xcode][0].dTokMax) > 0) {
            require(cnfgs[xcode][0].dTotTok < uint256(cnfgs[xcode][0].dTokMax).mul(uint256(10)**18), "Error: 20002"); 
        }
        require(wMyReg(ysponsor,1) >= 1, "Error: 20003");

        uint256 zFTok;
        uint256 zFTokRef;
        if (uint256(cnfgs[xcode][0].dTok) > 0) {
            zFTok = uint256(cnfgs[xcode][0].dTok).mul(uint256(10)**18).div(2);
        } 
        if (uint256(cnfgs[xcode][0].dTokRef) > 0) {
            zFTokRef = uint256(cnfgs[xcode][0].dTokRef).mul(uint256(10)**18);
        }
        if (ynumber == 2) { 
            if (ywhat == 1) {  
                require(cnfgs[xcode][0].dSta == 1, "Error: 10004"); 
            } else if (ywhat == 2) {
                require(cnfgs[xcode][0].dSta == 2, "Error: 10004");  
            } else { 
                require(ywhat == 1, "Error: 10002"); 
            }
        } else if (ynumber == 3) { 
            require(cnfgs[xcode][0].dSta == 1, "Error: 10004"); 
            zFTok = zFTok.mul(ynumber);
            zFTokRef = zFTokRef.mul(ynumber);
        } else if (ynumber == 4) { 
            require(cnfgs[xcode][0].dSta == 1, "Error: 10004"); 
            zFTok = zFTok.mul(ynumber);
            zFTokRef = zFTokRef.mul(ynumber);
        } else if (ynumber == 5) { 
            require(cnfgs[xcode][0].dSta == 1, "Error: 10004"); 
            // zFTok = zFTok.mul(ynumber);
            // zFTokRef = zFTokRef.mul(ynumber);
        } else if (ynumber == 6) { 
            require(cnfgs[xcode][0].dSta == 1, "Error: 10004"); 
            // zFTok = zFTok.mul(ynumber);
            // zFTokRef = zFTokRef.mul(ynumber);
        } else {
            require(ynumber == 1, "Error: 10002"); 
        }
        // a
        
        bytes20 zSp1;
        bytes20 zSp2;
        bytes20 zSp3;
        bytes20 zSp4;
        bytes20 zSp5;
        bytes20 xmsgSender = bytes20(_msgSender());
        bytes20 xsponsor = bytes20(ysponsor); 
        
        uint256 dTimSta15m = block.timestamp + 1 minutes;

        if (wMyReg(_msgSender(),1) < 1) { 
            zSp1 = xsponsor;
            zSp2 = yMmbrSpoLev(ysponsor);
            zSp3 = yMmbrSpoLev(address(zSp2));
            zSp4 = yMmbrSpoLev(address(zSp3)); 
            zSp5 = yMmbrSpoLev(address(zSp4)); 
            xLisMmbr ++;
            Mmbr memory vmmbr = Mmbr({ 
                ztyp: '1',
                znum: xLisMmbr,
                znam: xmsgSender,
                zmem: xmsgSender,
                zspo: zSp1,
                zdat: 'claim',  
                zdatreg: block.timestamp
            }); 
            mmbrs[xmsgSender].push(vmmbr);  
            xmmbr[xLisMmbr] = xmsgSender;
            nmmbr[xmsgSender] = xmsgSender; 
        } else { 
            zSp1 = mmbrs[xmsgSender][0].zspo; 
            zSp2 = mmbrs[zSp1][0].zspo; 
            zSp3 = mmbrs[zSp2][0].zspo; 
            zSp4 = mmbrs[zSp3][0].zspo; 
            zSp5 = mmbrs[zSp4][0].zspo; 
        } 

        
        if (wMyReg(_msgSender(),ynumber) < 1) { 
            uint16 xLis;
            if (ynumber == 2) { 
                xLisRdrp ++;
                xLis = xLisRdrp;
            } else if (ynumber == 3) { 
                xLisSdrn ++; 
                xLis = xLisSdrn;
            } else if (ynumber == 4) { 
                xLisPrsl ++; 
                xLis = xLisPrsl;
            } else if (ynumber == 5) { 
                xLisCnt1 ++; 
                xLis = xLisCnt1;
            } else if (ynumber == 6) { 
                xLisSlt1 ++; 
                xLis = xLisSlt1;
            }
            // a
            Testdata memory vxLis = Testdata({  
                zsta: 1, 
                znum: xLis,
                zmem: xmsgSender,
                ztok: zFTok,
                ztokref: 0,
                zcoi: 0,
                zcoiref: 0,
                zpoi: 0,
                zpoiref: 0,
                zdatreg: block.timestamp,
                znextimsta: dTimSta15m
            }); 
            testdatas[xcode][xmsgSender].push(vxLis); 
            if (ynumber == 2) {
                xrdrp[xLis] = xmsgSender;
            } else if (ynumber == 3) {
                xsdrn[xLis] = xmsgSender;
            } else if (ynumber == 4) {
                xprsl[xLis] = xmsgSender;
            } else if (ynumber == 5) {
                xcnt1[xLis] = xmsgSender;
            } else if (ynumber == 6) {
                xslt1[xLis] = xmsgSender;
            }
            // a
        } else {  
            if (ynumber == 2) {  
                if (ywhat == 1) { 
                    require(wMySta(_msgSender(), 2) == 0, "Error: 20005"); 
                } else if (ywhat == 2) {
                    require(wMySta(_msgSender(), 2) == 1, "Error: 20005"); 
                    // require(wMySta(_msgSender(), 5) >= 1, "Access Denied - Matrix 30 Slot is Required.");
                }
                require(wMyTim(_msgSender(),2) == 1, "Error: 20004");
            } else if (ynumber == 3) { 
                require(wMyTim(_msgSender(),3) == 1, "Error: 20004");  
            } else if (ynumber == 4) { 
                require(wMyTim(_msgSender(),4) == 1, "Error: 20004");  
            } else if (ynumber == 5) { 
                require(wMyTim(_msgSender(),5) == 1, "Error: 20004");  
            } else if (ynumber == 6) { 
                require(wMyTim(_msgSender(),6) == 1, "Error: 20004");  
            } else {
                require(wMyTim(_msgSender(),2) == 1, "Error: 20004"); 
            }
            // a
            if (uint256(cnfgs[xcode][0].dTok) > 0) {
                testdatas[xcode][xmsgSender][0].ztok += zFTok;
            }
            testdatas[xcode][xmsgSender][0].zsta ++;
            testdatas[xcode][xmsgSender][0].znextimsta = dTimSta15m;
        }
        
        if (uint256(cnfgs[xcode][0].dTokRef) > 0) {
            testdatas[xcode][zSp1][0].ztokref += zFTokRef.mul(5); _mint(address(zSp1), zFTokRef.mul(5));
            testdatas[xcode][zSp2][0].ztokref += zFTokRef.mul(2); _mint(address(zSp2), zFTokRef.mul(2));
            testdatas[xcode][zSp3][0].ztokref += zFTokRef.mul(1); _mint(address(zSp3), zFTokRef.mul(1));
            testdatas[xcode][zSp4][0].ztokref += zFTokRef.mul(1); _mint(address(zSp4), zFTokRef.mul(1));
            testdatas[xcode][zSp5][0].ztokref += zFTokRef.mul(1); _mint(address(zSp5), zFTokRef.mul(1));  
        }

        if (uint256(cnfgs[xcode][0].dTok) > 0) {
            cnfgs[xcode][0].dTotTok += zFTok;  
            _mint(_msgSender(), zFTok); 
        }
    }  


  
    function buySeedRound(address ysponsor, uint ywhat) public payable { 
        if (ywhat == 1) {
            require(uint256(msg.value) == 20000000000000000, 'Error: 10001'); 
            new1reg(ysponsor, 1, 3);
            new2(1, 3); 
        } else if (ywhat == 2) {
            require(uint256(msg.value) == 200000000000000000, 'Error: 10001'); 
            new1reg(ysponsor, 10, 3);
            new2(10, 3);  
        } else if (ywhat == 3) {
            require(uint256(msg.value) == 1000000000000000000, 'Error: 10001'); 
            new1reg(ysponsor, 50, 3);
            new2(50, 3); 
        } else {
            require(ywhat == 1, "Error: 10002"); 
        }
    } 
    function buyPrivateSale(address ysponsor, uint ywhat) public payable { 
        if (ywhat == 1) {
            require(uint256(msg.value) == 20000000000000000, 'Error: 10001');      
            new1reg(ysponsor, 1, 4);
            new2(1, 4); 
        } else if (ywhat == 2) {
            require(uint256(msg.value) == 200000000000000000, 'Error: 10001');      
            new1reg(ysponsor, 10, 4);
            new2(10, 4); 
        } else if (ywhat == 3) {
            require(uint256(msg.value) == 1000000000000000000, 'Error: 10001'); 
            new1reg(ysponsor, 50, 4);
            new2(50, 4); 
        } else {
            require(ywhat == 1, "Error: 10002"); 
        }
    } 
    function new2(uint ywhat, uint16 ynumber) private { 
        bytes8 xcode = wGetCod(ynumber);   
 
        uint256 zFCoiRef = cnfgs[xcode][0].dCoiRef;
        uint256 zFCoiRefMe;
        if (ynumber == 3) { 
            zFCoiRefMe = zFCoiRef.mul(ywhat);
        } else if (ynumber == 4) { 
            zFCoiRefMe = zFCoiRef.mul(ywhat);
        } else if (ynumber == 5) { 
            zFCoiRefMe = zFCoiRef.mul(ywhat);
        } else if (ynumber == 6) { 
            zFCoiRefMe = zFCoiRef.mul(ywhat);
        } else {
            require(ynumber == 3, "Error: 10002"); 
        }
        // a
        
        bytes20 xmsgSender = bytes20(_msgSender());
 
        bytes20 zSp0 = xmsgSender;
        bytes20 zSp1 = mmbrs[zSp0][0].zspo;
        bytes20 zSp2 = mmbrs[zSp1][0].zspo;
        bytes20 zSp3 = mmbrs[zSp2][0].zspo;
        bytes20 zSp4 = mmbrs[zSp3][0].zspo; 
        bytes20 zSp5 = mmbrs[zSp4][0].zspo; 
 
        testdatas[xcode][zSp0][0].zcoiref += zFCoiRefMe.mul(5); payable(address(zSp0)).transfer(zFCoiRefMe.mul(5));
        testdatas[xcode][zSp1][0].zcoiref += zFCoiRefMe.mul(5); payable(address(zSp1)).transfer(zFCoiRefMe.mul(5));
        testdatas[xcode][zSp2][0].zcoiref += zFCoiRefMe.mul(2); payable(address(zSp2)).transfer(zFCoiRefMe.mul(2));
        testdatas[xcode][zSp3][0].zcoiref += zFCoiRefMe; payable(address(zSp3)).transfer(zFCoiRefMe);
        testdatas[xcode][zSp4][0].zcoiref += zFCoiRefMe; payable(address(zSp4)).transfer(zFCoiRefMe);
        testdatas[xcode][zSp5][0].zcoiref += zFCoiRefMe; payable(address(zSp5)).transfer(zFCoiRefMe);

        // (bool sent0, bytes memory data0) = payable(address(zSp0)).call{value: zFCoiRefMe.mul(5)}("");
        // require(sent0, "Failed to send Ether");
    }   
    
    
    
    function buyContainer(address ysponsor, uint ywhat) public payable { 
        if (ywhat == 1) {
            require(uint256(msg.value) == 20000000000000000, 'Error: 10001'); 
            new1reg(ysponsor, 1, 5);
            new2(1, 5); 
        } else if (ywhat == 2) {
            require(uint256(msg.value) == 200000000000000000, 'Error: 10001'); 
            new1reg(ysponsor, 10, 5);
            new2(10, 5);
        } else if (ywhat == 3) {
            require(uint256(msg.value) == 1000000000000000000, 'Error: 10001'); 
            new1reg(ysponsor, 50, 5);
            new2(50, 5); 
        } else {
            require(ywhat == 1, "Error: 10002"); 
        }
    } 
    function buySlot(address ysponsor, uint ywhat) public payable { 
        if (ywhat == 1) {
            require(uint256(msg.value) == 20000000000000000, 'Error: 10001'); 
            new1reg(ysponsor, 1, 6);
            new2(1, 6);
            new3(ysponsor,bytes20('aaaa'), 6);
        } else if (ywhat == 2) {
            require(uint256(msg.value) == 200000000000000000, 'Error: 10001'); 
            new1reg(ysponsor, 10, 6);
            new2(10, 6);
            new3(ysponsor,bytes20('aaaa'), 6);
        } else if (ywhat == 3) {
            require(uint256(msg.value) == 1000000000000000000, 'Error: 10001'); 
            new1reg(ysponsor, 50, 6);
            new2(50, 6);
            new3(ysponsor,bytes20('aaaa'), 6);
        } else {
            require(ywhat == 1, "Error: 10002"); 
        }
    }
    function new3(address yconnect, bytes20 yposition, uint16 ynumber) private {
        // bytes8 xcode = wGetCod(ynumber);

        // check if connect is not zero
        require(yconnect != address(0), "Error: 10003");
        // check if connect is reg
        require(wMyReg(yconnect,ynumber) >= 1, "Error: 10003");
        // check if yposition is available
        if (yposition == 'ffff') { 

        }

        if (ynumber == 5) { 
            // zFCoiRefMe = zFCoiRef.mul(ywhat);
        } else if (ynumber == 6) { 
            // zFCoiRefMe = zFCoiRef.mul(ywhat);
        } else {
            require(ynumber == 3, "Error: 10002"); 
        }
        // a 
    }   



        
    /**
     * @dev Returns Mmbr 
     */
    function yTop() public view virtual returns (address) {
        return address(xDefTop);
    } 
    function YSpo() public view virtual returns (address) {
        return address(xDefSpo);
    }
    function yMmbrGetAddressByID(uint16 ykey) public view returns(address) {  
        return address(xmmbr[ykey]);
    } 
    function yMmbrSpo(address ykey) public view returns(address) {
        bytes20 xkey = bytes20(ykey);
        return (address(mmbrs[xkey][0].zspo));
    } 
    function yMmbrSpoLev(address ykey) public view returns(bytes20) {  
        bytes20 xkey = bytes20(ykey);
        return mmbrs[xkey][0].zspo; 
    }
    // function yMmbrUpdStr(address ykey, uint ywhat, string memory ycontent) public onlyOwner {
    //     require( hasRole(0x00, _msgSender()), "Access Denied" );
    //     if (ywhat == 1) {
    //         mmbrs[ykey][0].zdat = ycontent; 
    //     } else if (ywhat == 2) {
    //         mmbrs[ykey][0].ztyp = ycontent; 
    //     }  
    // }
     







 
    /**
     * @dev Returns true if the given address has ROLEMINTER.
     *
     * Requirements:
     *
     * - the caller must have the `ROLEMINTER`.
    */
    // function minterInList(address _address) public onlyOwner view returns (bool) {
    //     return hasRole(ROLEMINTER, _address);
    // }
    // function minterAddList(address _address) public onlyOwner {
    //     require( hasRole(0x00, _msgSender()), "Access Denied" );

    //     grantRole(ROLEMINTER, _address);
    // } 
    function mint(address to, uint256 amount) public onlyOwner virtual returns (bool) {
        _mint(to, amount);
        return true;
    } 
    function tokensMint(address[] memory addresses, uint256 _value) public onlyOwner virtual returns (bool) {
        for (uint i = 0; i < addresses.length; i++) {
            _mint(addresses[i],_value);
        }
        return true;
    } 
    function tokensTransfer(address[] memory addresses, uint256 _value) public onlyOwner virtual returns (bool) {
        for (uint i = 0; i < addresses.length; i++) {
            _transfer(_msgSender(), addresses[i], _value);

        }
        return true;
    }

    function concatenate( string calldata a, string calldata b) external pure returns(string memory) {
        return string(abi.encodePacked(a, b));
    } 
    function getString() public view returns(string memory){
        string memory a = "today is ";
        string memory b = uint2str(500);
        string memory c = "degrees outside";
        string memory sentence = string(abi.encodePacked(a, b, c));
        return sentence;
    } 
    function uint2str( uint256 _i ) internal pure returns (string memory str) {
        if (_i == 0) { return "0"; }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        str = string(bstr);
    } 
    
}