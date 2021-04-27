/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

pragma solidity >=0.4.22 <0.7.0;


//import "https://github.com/smartcontractkit/chainlink/blob/master/evm-contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";


contract BidChain_owner {

    address payable public owner_address;
    int public ETH_USD;
    bool solicit_ended;
    
    constructor () public{
        // place in paranthese address _PriceConsumerV3_address
      //  PriceConsumerV3 ETHPrice=PriceConsumerV3(_PriceConsumerV3_address);
      //  ETH_USD=ETHPrice.getLatestPrice();
        owner_address=msg.sender;
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
        int  deposit_requierement;
        uint  GC_submitedBidsNo;
        placed_Gbid [] placed_Gbids;
        winner [] GSolicit_winner;
    }
    
    
    solicit_info Gsolicit;
    

    struct SubSolicit_info{
       address payable  GCOwner_address ;
       string  Sjob_description;
       string  Sjob_location;
       address  SDocuments_swarmRef;
       string  SubSolicit_No;
       uint  Spublication_date;
       uint  Sclosing_date;
       placed_Sbid [] placed_Sbids;
       winner [] SSolicit_winners;
    }
    
    struct registered_GC{
        string GC_org;
        string GC_registrationNo;
        address payable GC_address;
        mapping (string=>SubSolicit_info) SubSolicits;
    }
 
     struct registered_SC{
        string SC_org;
        string SC_registrationNo;
        address  SC_address;
    }
    
    struct placed_Gbid{
        address Gbidder_address;
        string Gbidder_org;
        string Gbidder_registrationNo;
        uint Gbid_date;
        string Gbid_swarmRef;
    }

 
    struct placed_Sbid{
        address Sbidder_address;
        string Sbidder_org;
        string Sbidder_registrationNo;
        uint Sbid_date;
        string Sbid_swarmRef;
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
        int _deposit_requierement
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
            Gsolicit.deposit_requierement=_deposit_requierement;
            Gsolicit.GC_submitedBidsNo=0;
        
    
            
            //Gsolicit=solicit_info(_solicitation_type,_solicication_no,_issuing_org,_owner_org,_project_title,_project_description,_location,_job_location,
           // now,now+_biddingTime,_contact_informaiton,_documents_swarmRef,_buyer_requires,_deposit_requierement,0, [] , [] );
    }


  
  
   
   function register_GC(
       string memory _GC_org,
       string memory _GC_registrationNo,
       address payable  _GC_address
       ) public onlyOwner{
           registered_GCs[_GC_address].GC_org=_GC_org;
           registered_GCs[_GC_address].GC_registrationNo=_GC_registrationNo;
           registered_GCs[_GC_address].GC_address=_GC_address;
    }
  
  
    function register_SC(
       string memory _SC_org,
       string memory _SC_registrationNo,
       address  _SC_address) public onlyGC{
           registered_SCs[_SC_address]=registered_SC(_SC_org,_SC_registrationNo,_SC_address);
    }
   
   
   function invite_SSolicit(
       string memory _Sjob_description,
       string memory _Sjob_location,
       address  _SDocuments_swarmRef,
       string memory _SubSolicit_No,
       uint _SBidding_time) public onlyGC{
           
        registered_GCs[msg.sender].SubSolicits[_SubSolicit_No].GCOwner_address=msg.sender;
        registered_GCs[msg.sender].SubSolicits[_SubSolicit_No].Sjob_description=_Sjob_description;
        registered_GCs[msg.sender].SubSolicits[_SubSolicit_No].Sjob_location=_Sjob_location;
        registered_GCs[msg.sender].SubSolicits[_SubSolicit_No].SDocuments_swarmRef=_SDocuments_swarmRef;
        registered_GCs[msg.sender].SubSolicits[_SubSolicit_No].SubSolicit_No=_SubSolicit_No;
        registered_GCs[msg.sender].SubSolicits[_SubSolicit_No].Spublication_date=now;
        registered_GCs[msg.sender].SubSolicits[_SubSolicit_No].Sclosing_date=now+_SBidding_time;
           
      // registered_GCs[msg.sender].SubSolicits[_SubSolicit_No]= SubSolicit_info(msg.sender,_Sjob_description,_Sjob_location,
       //_SDocuments_swarmRef,_SubSolicit_No,now,now+_SBidding_time,[]); 
    }
   


    function SC_placeBid(
       address _SbidFor_GCAddress,
       string memory _SC_registrationNo,
       string memory _Sbidder_org,
       string memory  _SbifFor_SSolicitNo,
       string memory _Sbid_swarmRef) public{
          uint Ssolicit_deadline=registered_GCs[_SbidFor_GCAddress].SubSolicits[_SbifFor_SSolicitNo].Sclosing_date;
          require(now<=Ssolicit_deadline);
        registered_GCs[_SbidFor_GCAddress].SubSolicits[_SbifFor_SSolicitNo].placed_Sbids.push(placed_Sbid(msg.sender,_Sbidder_org,_SC_registrationNo,now,_Sbid_swarmRef));   
       }
   
   
   function Announce_SCWinner(
       address _sWinner_address,
       string memory _SwRegistration_No, 
       string memory _winning_SsolicitNo) onlyGC public{
           registered_GCs[msg.sender].SubSolicits[_winning_SsolicitNo].SSolicit_winners.push(winner(_sWinner_address,_SwRegistration_No,_winning_SsolicitNo,msg.sender));
    }

   
    function GC_PlaceBid (
        string memory _Gbidder_org,
        string memory _Gbidder_registrationNo,
        string memory _Gbid_swarmRef) payable onlyGC public {
        require(!solicit_ended);
        require(int(msg.value)>=((Gsolicit.deposit_requierement*100000000/ETH_USD))*10**18);
        require(now<=Gsolicit.closing_date);
        Gsolicit.GC_submitedBidsNo++;
        Gsolicit.placed_Gbids.push(placed_Gbid(msg.sender,_Gbidder_org,_Gbidder_registrationNo,now,_Gbid_swarmRef));
    }


   function Announce_GCWinner(
       address _gWinner_address,
       string memory _GwRegistration_No, 
       string memory _winning_GsolicitNo) onlyOwner public{
           Gsolicit.GSolicit_winner.push(winner(_gWinner_address,_GwRegistration_No,_winning_GsolicitNo,msg.sender));
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