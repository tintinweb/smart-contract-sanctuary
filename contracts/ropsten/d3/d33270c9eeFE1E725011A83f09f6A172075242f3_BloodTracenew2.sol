/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

pragma solidity >= 0.5.0 < 0.7.0;

contract BloodTracenew2 {
    
    struct Blood {
            uint pcid;
            uint donorid;
            string bloodtype;
            uint plasmaunitcount;
            uint redcellsunitcount;
            uint plateletscount;
    }
    mapping(string => Blood ) public blood;
   
    struct Bloodinfo {
        uint pcid;
        string bloodtype;
        uint totalplasma;
        uint totalredcell;
        uint totalplatelet;
    }
    mapping(string => Bloodinfo) public bloodinfo;
    
    struct Donor{
        uint did;
        string dname;
        string dgender;
        uint dage;
        uint dweight;
        string bloodtype;
        bool donated;
    }
    
    mapping(uint => Donor) donors;
    uint public donorCount;
    
    struct Testresults {
        uint did;
        bool testresultpositive;
        bool donationdiscarded;
    }
    mapping(uint => Testresults) testresults;
    
   struct Bloodprovided {
        uint hid;
        uint pid;
        uint did;
        string bloodtype;
        string component;
        uint quantity;
    }
    mapping(string => Bloodprovided) bloodprovided;
    function addDonor(string memory _dname, string memory _dgender, uint _dage, uint _dweight, string memory _bloodtype) public 
    {
                 
              donorCount ++;
              donors[donorCount]=Donor(donorCount, _dname,  _dgender, _dage, _dweight, _bloodtype,false);
    }
    
    function addTest(uint _did, bool _testresultspositive, bool _donationdiscarded) public 
    {
        
                testresults[_did]=Testresults(_did, _testresultspositive,_donationdiscarded);
            
    }
    
   function update(uint _pcid, uint _did, string memory _bloodtype, uint _plasmaunit, uint _redbloodcell, uint _platelet) public 
   {
       
                blood[_bloodtype]=Blood(_pcid, _did, _bloodtype, _plasmaunit, _redbloodcell, _platelet);
                bloodinfo[_bloodtype].totalplasma += _plasmaunit;
                bloodinfo[_bloodtype].totalredcell += _redbloodcell;
                bloodinfo[_bloodtype].totalplatelet += _platelet;
                bloodinfo[_bloodtype].pcid= _pcid;
            
        
   }
   
   function getinfo(string memory _bloodtype) public view returns(uint, uint, uint, uint)  
   {
        uint _pcid;
        uint _totalplasma;
        uint _totalredcell;
        uint _totalplatelet;
        _pcid=bloodinfo[_bloodtype].pcid;
        _totalplasma=bloodinfo[_bloodtype].totalplasma;
        _totalredcell=bloodinfo[_bloodtype].totalredcell;
        _totalplatelet=bloodinfo[_bloodtype].totalplatelet;
        return(_pcid, _totalplasma, _totalredcell, _totalplatelet);
    }
    
    function hashCompareWithLengthCheck(string memory a, string memory b) internal pure returns (bool) 
    {
        if(bytes(a).length != bytes(b).length) 
        {
             return false;
        } 
        else 
        {
            return keccak256(bytes(a)) == keccak256(bytes(b));
        }
    }
   /* function provideBlood(uint _hid, uint _pid, string memory _bloodtype, string memory _component, uint _quantity) public 
    {
              
                    for(uint8 k = 0; k < donorusers.length; k++)
                    {
                        uint8 j=k+1;
                        if(hashCompareWithLengthCheck(donors[j].bloodtype, _bloodtype))  
                        {
                            bloodprovided[_bloodtype] = Bloodprovided(_hid, _pid, j, _bloodtype, _component, _quantity);
                            donors[j].donated=true;   
                            if(hashCompareWithLengthCheck(_component, "plasma"))
                                bloodinfo[_bloodtype].totalplasma -= _quantity;
                            else if(hashCompareWithLengthCheck(_component,"redcell"))
                                bloodinfo[_bloodtype].totalredcell -= _quantity;
                            else if (hashCompareWithLengthCheck(_component, "platelet"))
                                bloodinfo[_bloodtype].totalplatelet -= _quantity;
                        }
                    }
         }
    */
    function Viewdonorpersonaldetails(uint _did) public view returns( string memory _dname,  string memory _dgender, uint _dage, uint _dweight, string memory _dbloodtype, bool _ddonated)
    {
              _dname=donors[_did].dname;
              _dgender=donors[_did].dgender;
              _dage=donors[_did].dage;
              _dweight=donors[_did].dweight; 
              _dbloodtype=donors[_did].bloodtype;
              _ddonated=donors[_did].donated;
              
    
    }

    function Viewtestresults(uint _did) public view returns(bool, bool)
    { 
        return(testresults[_did].testresultpositive, testresults[_did].donationdiscarded);
            
        
    }
}//end of contract