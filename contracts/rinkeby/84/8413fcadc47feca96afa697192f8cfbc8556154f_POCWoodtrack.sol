/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.11;

contract POCWoodtrack{

      
    struct Woodtrack {
      
        bytes32    SP;
        bytes32    SKSHHK;
        uint256 Volume; // m3
        bytes32    Petak;
        bytes32    AsalKayu;
        bytes32 Certificate;
        bytes32 Debark;
        bytes32 Tran;
        uint256   bulanTebang;
        uint256 tahunTebang;
        bytes32 JenisKayu;    
        uint index;
    }


    mapping(bytes32 => Woodtrack  ) public woodtracks;
    bytes32[] private WoodtrackIndex;

    bytes32[] public WoodTypes;
    bytes32[] public TranTypes;
    bytes32[]  public DebarkTypes;
    bytes32[]  public CertificateTypes;

    event LogRegister(Woodtrack  wt);

    mapping(address=>bool) public Owners;
    address public Owner;
    

    modifier onlyOwner() {
        require(
            Owners[msg.sender]==true,
            "Only owner can call this function."
        );
        _;
    }



    constructor() {
        Owners[msg.sender]=true;
    }

    function isShshhk(bytes32 shshhk)  public view returns(bool isIndeed) 
    {
      //  if(WoodtrackIndex.length == 0) return false;
        if  (woodtracks[shshhk].SKSHHK==shshhk) return true;
        return false;
        //return (WoodtrackIndex[woodtracks[shshhk].index] == shshhk);
    }

    function isCertificateType(bytes32 data)  public view returns(bool isIndeed) 
    {
        if(CertificateTypes.length == 0) return false;
        for (uint j = 0; j < CertificateTypes.length; j++) {
            if (CertificateTypes[j]==data)
            {
                return true;
                
            }
        }
       
    }

    function isDebarkType(bytes32 data)  public view returns(bool isIndeed) 
    {
        if(DebarkTypes.length == 0) return false;
        for (uint j = 0; j < DebarkTypes.length; j++) {
            if (DebarkTypes[j]==data)
            {
                return true;
                
            }
        }
       
    }
   
    function isTranType(bytes32 data)  public view returns(bool isIndeed) 
    {
        if(TranTypes.length == 0) return false;
        for (uint j = 0; j < TranTypes.length; j++) {
            if (TranTypes[j]==data)
            {
                return true;
                
            }
        }
       
    }

     function isWoodType(bytes32 data)  public view returns(bool isIndeed) 
    {
        if(WoodTypes.length == 0) return false;
       
        for (uint j = 0; j < WoodTypes.length; j++) {
            if (WoodTypes[j]==data)
            {
                return true;
                
            }
        }
       
    }


    function AddCertificateType(bytes32 CertificateType) external onlyOwner  returns(uint)
    {
       require(!isCertificateType(CertificateType),"Data Already Exist !") ;
       
       CertificateTypes.push(CertificateType);
       return  CertificateTypes.length-1;

    }

    function GetCountCertificateType() public view returns( uint )
    {
        return  CertificateTypes.length;

    }

    function GetCertificateTypeAtIndex(uint index) public view returns( bytes32 )
    {
        require(
             CertificateTypes.length > index ,
            "Invalid Data."
        );

        return  CertificateTypes[index];

    }

    function AddDebarkType(bytes32 DebarkType) external onlyOwner returns(uint)
    {
       require(!isDebarkType(DebarkType),"Data Already Exist !") ;
       
       DebarkTypes.push(DebarkType);
       return  DebarkTypes.length-1;

    }

    function GetCountDebarkType() public view returns( uint )
    {
       return  DebarkTypes.length;

    }

    function GetDebarkTypeAtIndex(uint index) public view returns( bytes32 )
    {
         require(
             DebarkTypes.length > index ,
            "Invalid Data."
        );
        return  DebarkTypes[index];

    }

    function AddTranType(bytes32 TranType) external onlyOwner returns(uint)
    {
         require(!isTranType(TranType),"Data Already Exist !") ;

         TranTypes.push(TranType);
       return  TranTypes.length-1;

    }

    function GetCountTranType() public view returns( uint )
    {
       return  TranTypes.length;

    }

    function GetTranTypeAtIndex(uint index) public view returns( bytes32 )
    {
           require(
             TranTypes.length > index ,
            "Invalid Data."
        );
        return  TranTypes[index];

    }

    function AddWoodType(bytes32 WoodType) external onlyOwner returns(uint)
    {
       require(!isWoodType(WoodType),"Data Already Exist !") ;

        WoodTypes.push(WoodType);
       return  WoodTypes.length-1;
    }

     function GetCountWoodType() public view returns( uint )
    {
       return  WoodTypes.length;

    }

    function GetWoodTypeAtIndex(uint index) public view returns( bytes32 )
    {
        require(
             WoodTypes.length > index ,
            "Invalid Data."
        );
        return  WoodTypes[index];

    }
    function AddOwner(address add) external onlyOwner
    {
        Owners[add]=true;
    }
    
    function AddSkshhk(Woodtrack calldata wt ) external onlyOwner returns(uint index) {
        require(!isShshhk(wt.SKSHHK),"Data Already Exist !") ;
        require(isWoodType(wt.JenisKayu),"Wood Type not  Exist !") ;
        require(isWoodType(wt.Certificate),"Certificate not  Exist !") ;
        require(isWoodType(wt.Debark),"Debark not  Exist !") ;
         require(isWoodType(wt.Tran),"Tran not  Exist !") ;

        WoodtrackIndex.push(wt.SKSHHK);

        woodtracks[wt.SKSHHK].SP=wt.SP;
        woodtracks[wt.SKSHHK].SKSHHK=wt.SKSHHK;
        woodtracks[wt.SKSHHK].Volume=wt.Volume;
        woodtracks[wt.SKSHHK].AsalKayu=wt.AsalKayu;
        woodtracks[wt.SKSHHK].Petak=wt.Petak;

        woodtracks[wt.SKSHHK].Certificate=wt.Certificate;
        woodtracks[wt.SKSHHK].Debark=wt.Debark;
        woodtracks[wt.SKSHHK].Tran=wt.Tran;
        woodtracks[wt.SKSHHK].bulanTebang=wt.bulanTebang;
        woodtracks[wt.SKSHHK].tahunTebang=wt.tahunTebang;

        woodtracks[wt.SKSHHK].JenisKayu=wt.JenisKayu;
        woodtracks[wt.SKSHHK].index     = WoodtrackIndex.length-1;
          
        emit LogRegister(woodtracks[wt.SKSHHK]);
        return WoodtrackIndex.length-1;

    }

    function GetSkshhk(bytes32 sKSHHK) public view returns( Woodtrack memory) {
        return (
            
            woodtracks[sKSHHK]
            
        );
    }

     function GetCountSkshhk() public view returns( uint )
    {
       return WoodtrackIndex.length ;

    }

    function GetSkshhkAtIndex(uint index) public view returns( bytes32 )
    {
       return WoodtrackIndex[index] ;

    }
    //function searchAdal(string memory AsalKayu)
    

   
   
}