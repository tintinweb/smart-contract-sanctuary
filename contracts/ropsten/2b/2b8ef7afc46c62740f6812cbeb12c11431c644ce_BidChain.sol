pragma solidity ^0.4.17 ; //>=0.4.17 <0.8.4


//import "https://github.com/smartcontractkit/chainlink/blob/master/evm-contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

import "./TetherToken.sol";

contract BidChain {

//  string logoHash;

//  function setHash (string memory _logoHash) public{
//    logoHash=_logoHash;
//  }
  
//  function getHash() public view returns (string memory){
//    return logoHash;
//  }




    address  public owner_address;//payable
    int public ETH_USD;
    bool solicit_ended;
    TetherToken public tether = TetherToken(0x45ba8f3088E2C35948e67Ad9c61Cce943CF7ebb4);
    
    constructor () public{
        // place in paranthese address _PriceConsumerV3_address
      //  PriceConsumerV3 ETHPrice=PriceConsumerV3(_PriceConsumerV3_address);
      //  ETH_USD=ETHPrice.getLatestPrice();
        owner_address=msg.sender;
        solicit_ended==false;
    }

    struct solicit_info{
        string  solicitation_type;
        string  solicitation_no;
        string  issuing_org;
        string  owner_org;
        string  project_title;
        string  project_description; 
        string  location;
        string  job_location;
        uint  publication_date;
        uint  closing_date;
        string  contact_information;
        string  documents_swarmRef;
        string  buyer_requires; 
        uint  GbidBond_asked;
        uint  GC_submitedBidsNo;
        placed_Gbid [] placed_Gbids;
        registered_GC [] GSolicit_winner;
    }
  
    
    solicit_info Gsolicit;
    

    struct SubSolicit_info{
       address   GCOwner_address ;//payable
       string  Sjob_description;
       string  Sjob_location;
       address  SDocuments_swarmRef;
       string  SubSolicit_No;
       uint  Spublication_date;
       uint  Sclosing_date;
       uint SbidBond_asked;
       mapping (address => placed_Sbid  ) placed_Sbids; //  placed_Sbid [] placed_Sbids;
       registered_SC [] SSolicit_winners;
    }
    
    struct registered_GC{
        string GC_org;
        string GC_registrationNo;
        address  GC_address;//payable
        string GC_PublicAddress;
        mapping (string=>SubSolicit_info) SubSolicits;
    }
 
     struct registered_SC{
        string SC_org;
        string SC_registrationNo;
        address  SC_address;
        string SC_PublicAddress;
    }
    
    struct placed_Gbid{
        //address Gbidder_address;
        //string Gbidder_org;
        //string Gbidder_registrationNo;
        uint Gbid_date;
        string Gbid_swarmRef;
        uint GbidBond_placed;
        registered_GC GC_info;
    }

 
    struct placed_Sbid{
        //address Sbidder_address;
        //string Sbidder_org;
        //string Sbidder_registrationNo;
        uint Sbid_date;
        string Sbid_swarmRef;
        uint SbidBond_placed;
        registered_SC SC_info;
    } 
    
    
    struct winner{
        address winner_address;
        string registration_No;
        string winning_solicitNo;
        address awarder_address;
    }
    
    mapping (address=>registered_GC) registered_GCs;
    mapping (address=>registered_SC) registered_SCs;
   // registered_SC [] registered_SCs;
    
    
    modifier onlyOwner{
        require (owner_address==msg.sender);
        _;
    }
    
    
    modifier notOwner{
        require (owner_address!=msg.sender);
        _;
    }
    
    
    modifier onlyGC{
        bool isGC;
        if (registered_GCs[msg.sender].GC_address==msg.sender){
            isGC =true;
        }
        require (isGC);
        _;
    }
    

    function intiate_solicitation (
        string memory  _solicitation_type,
        string memory  _solicication_no,
        string memory _issuing_org,
        string memory _owner_org,
        string memory _project_title,
        string memory _project_description,
        string memory _location,
        string memory _job_location,
        uint  _biddingTime,
        string memory _contact_informaiton,
        string memory _documents_swarmRef,
        string memory _buyer_requires,
        uint _GbidBond_asked
        ) public onlyOwner{
            
            
            
            
            Gsolicit.solicitation_type=_solicitation_type;
            Gsolicit.solicitation_no=_solicication_no;
            Gsolicit.issuing_org=_issuing_org;
            Gsolicit.owner_org=_owner_org;
            Gsolicit.project_title=_project_title;
            Gsolicit.project_description=_project_description;
            Gsolicit.location=_location;
            Gsolicit.job_location=_job_location;
            Gsolicit.publication_date=now;
            Gsolicit.closing_date=now+_biddingTime;
            Gsolicit.contact_information=_contact_informaiton;
            Gsolicit.documents_swarmRef=_documents_swarmRef;
            Gsolicit.buyer_requires=_buyer_requires;
            Gsolicit.GbidBond_asked=_GbidBond_asked;
            Gsolicit.GC_submitedBidsNo=0;
        
    
            
            //Gsolicit=solicit_info(_solicitation_type,_solicication_no,_issuing_org,_owner_org,_project_title,_project_description,_location,_job_location,
           // now,now+_biddingTime,_contact_informaiton,_documents_swarmRef,_buyer_requires,_deposit_requierement,0, [] , [] );
    }


  
  
   
   function register_GC(
       string memory _GC_org,
       string memory _GC_registrationNo,
       address   _GC_address //payable
       ) public onlyOwner{
           registered_GCs[_GC_address].GC_org=_GC_org;
           registered_GCs[_GC_address].GC_registrationNo=_GC_registrationNo;
           registered_GCs[_GC_address].GC_address=_GC_address;
    }
  
  
    function register_SC(
       string memory _SC_org,
       string memory _SC_registrationNo,
       address  _SC_address,
       string memory _SC_PublicAddress) public onlyGC{
           registered_SCs[_SC_address]=registered_SC(_SC_org,_SC_registrationNo,_SC_address,_SC_PublicAddress);
    }
   
   
   function invite_SSolicit(
       string memory _Sjob_description,
       string memory _Sjob_location,
       address  _SDocuments_swarmRef,
       string memory _SubSolicit_No,
       uint _SBidding_time,
       uint _SbidBond_asked) public onlyGC{
           
        registered_GCs[msg.sender].SubSolicits[_SubSolicit_No].GCOwner_address=msg.sender;
        registered_GCs[msg.sender].SubSolicits[_SubSolicit_No].Sjob_description=_Sjob_description;
        registered_GCs[msg.sender].SubSolicits[_SubSolicit_No].Sjob_location=_Sjob_location;
        registered_GCs[msg.sender].SubSolicits[_SubSolicit_No].SDocuments_swarmRef=_SDocuments_swarmRef;
        registered_GCs[msg.sender].SubSolicits[_SubSolicit_No].SubSolicit_No=_SubSolicit_No;
        registered_GCs[msg.sender].SubSolicits[_SubSolicit_No].Spublication_date=now;
        registered_GCs[msg.sender].SubSolicits[_SubSolicit_No].Sclosing_date=now+_SBidding_time;
        registered_GCs[msg.sender].SubSolicits[_SubSolicit_No].SbidBond_asked=_SbidBond_asked;
           
      // registered_GCs[msg.sender].SubSolicits[_SubSolicit_No]= SubSolicit_info(msg.sender,_Sjob_description,_Sjob_location,
       //_SDocuments_swarmRef,_SubSolicit_No,now,now+_SBidding_time,[]); 
    }
   
  

    function SC_placeBid(
       address _SbidFor_GCAddress,
       string memory _SC_registrationNo,
       //string memory _Sbidder_org,
       string memory  _SbifFor_SSolicitNo,
       string memory _Sbid_swarmRef,
       uint _SbidBond_placed) public{
          uint Ssolicit_deadline=registered_GCs[_SbidFor_GCAddress].SubSolicits[_SbifFor_SSolicitNo].Sclosing_date;
          uint _SbidBond_asked=registered_GCs[_SbidFor_GCAddress].SubSolicits[_SbifFor_SSolicitNo].SbidBond_asked;
          require(now<=Ssolicit_deadline);
          require(keccak256(bytes(registered_SCs[msg.sender].SC_registrationNo)) ==keccak256(bytes(_SC_registrationNo)));
          require(_SbidBond_placed>=_SbidBond_asked, "LOW BOND AMOUNT" );
          require(tether.balanceOf(msg.sender)>=_SbidBond_placed, "INSUFFICIENT FUND");
          tether.transfer(this, _SbidBond_placed);
        registered_GCs[_SbidFor_GCAddress].SubSolicits[_SbifFor_SSolicitNo].placed_Sbids[msg.sender]=placed_Sbid(now,_Sbid_swarmRef,_SbidBond_placed,registered_SCs[msg.sender]);   
       }
   
   
   function Announce_SCWinner(
       address _sWinner_address,
       string memory _SwRegistration_No, 
       string memory _winning_SsolicitNo) onlyGC public{
           require(keccak256(bytes(registered_SCs[_sWinner_address].SC_registrationNo)) ==keccak256(bytes(_SwRegistration_No)));
           registered_GCs[msg.sender].SubSolicits[_winning_SsolicitNo].SSolicit_winners.push(registered_SCs[_sWinner_address]);

         
    }


    function GC_PlaceBid (
        string memory _Gbidder_registrationNo,
        string memory _Gbid_swarmRef,
        uint _GbidBond_placed) payable onlyGC public {
        require(keccak256(bytes(registered_GCs[msg.sender].GC_registrationNo)) ==keccak256(bytes(_Gbidder_registrationNo)));
        require(!solicit_ended);
        //require(int(msg.value)>=((Gsolicit.deposit_requierement*100000000/ETH_USD))*10**18);
        require(tether.balanceOf(msg.sender)>=_GbidBond_placed, "INSUFFICIENT FUND");
        require(_GbidBond_placed>=Gsolicit.GbidBond_asked, "LOW BOND AMOUNT");
        
        require(now<=Gsolicit.closing_date);
        Gsolicit.GC_submitedBidsNo++;
        Gsolicit.placed_Gbids.push(placed_Gbid(now,_Gbid_swarmRef,_GbidBond_placed,registered_GCs[msg.sender])); //msg.sender,_Gbidder_org,_Gbidder_registrationNo,
        tether.transfer(this, _GbidBond_placed);
    }


   function Announce_GCWinner(
       address _gWinner_address,
       string memory _GwRegistration_No,
       string _winning_GsolicitNo) onlyOwner public{
           require(keccak256(bytes(registered_GCs[_gWinner_address].GC_registrationNo)) ==keccak256(bytes(_GwRegistration_No)));
           require(keccak256(bytes(Gsolicit.solicitation_no))==keccak256(bytes(_winning_GsolicitNo)));
           Gsolicit.GSolicit_winner.push(registered_GCs[_gWinner_address]);
           solicit_ended==true;
            // Gsolicit.GSolicit_winner.push(registered_GCs())
    }
    
    function endBidding() onlyOwner public {
        require(solicit_ended);
        for (uint i=0; i<Gsolicit.placed_Gbids.length ;i++){
            if (Gsolicit.GSolicit_winner[0].GC_address!=Gsolicit.placed_Gbids[i].GC_info.GC_address){
              tether.transferFrom(this,Gsolicit.placed_Gbids[i].GC_info.GC_address, Gsolicit.placed_Gbids[i].GbidBond_placed);  
            }
        }
        
    }
    
    
}    




   
 
   
   
   
   
    
    


//contract PriceConsumerV3 {
//    AggregatorV3Interface internal priceFeed;
    /**
     * Network: Kovan
     * Aggregator: ETH/USD
     * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
     */
//    constructor() public {
//        priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
//    }
    /**
     * Returns the latest price
     */
//    function getLatestPrice() public view returns (int) {
 //       (
//            uint80 roundID, 
//            int price,
//            uint startedAt,
 //           uint timeStamp,
//            uint80 answeredInRound
//        ) = priceFeed.latestRoundData();
//        return price;
//    }
//}