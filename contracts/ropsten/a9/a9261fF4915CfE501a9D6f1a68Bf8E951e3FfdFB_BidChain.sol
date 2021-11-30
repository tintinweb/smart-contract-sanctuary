/**
 *Submitted for verification at Etherscan.io on 2021-11-29
*/

// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.7; //^0.4.17 >=0.4.17 <0.8.7

contract BidChain {
    
    address  public owner_ethereum_public_address;
    contract_info contract_details;
    mapping (address => registered_contractor) registered_contractors;
    mapping (address=>mapping(address=>registered_subcontractor)) registered_subcontractors;
    mapping (address=>mapping(string=>subcontract_details)) subcontracts;
    mapping (address=>submitted_bid []) submitted_bids;//
    //string solicitIPFS;//
    mapping (address=>string)OpenPGPCertificates_IPFS;
    bid_submission_tracker bid_submission_tracker_details;

    constructor () {
        owner_ethereum_public_address=msg.sender;
        contract_details.tender_closed=false;
      
    }
    
    struct bid_submission_tracker{
        uint number_of_submitted_bid;
        address [] array_of_bidders;
        mapping(address=>bool) bidder_exist;
    }

    struct contract_info{
        string  contract_type;
        string  contract_number;
        string  owner_organization_name;
        string  contract_description; 
        string  location;
        uint  tender_advertise_date;
        uint  bid_closing_date;
        string  documents_IPFS_address;
        string  requirements; 
        bool tender_closed;
        address awarded_to;
    }   
  
    struct registered_contractor{
        string contractor_organization_name;
        address  contractor_ethereum_public_address;
        string contractor_GPG_public_address;
    }
 
    struct registered_subcontractor{

        string subcontractor_organization_name;
        address  subcontractor_ethereum_public_address;
        string subcontractor_GPG_public_address;
        address regsitered_for;
    }
    
    struct subcontract_bid_submission_tracker{
        uint number_of_subcontract_submitted_bid;
        address [] array_of_subcontract_bidders;
        mapping(address=>bool) subcontract_bidder_exist;
    }    
    
    
    struct subcontract_details{
        string subcontract_type;
        string subcontract_number;
        address subcontract_of;
        string subcontract_description;
        string subcontract_location;
        uint subcontract_advertise_date;
        uint subcontract_closing_date;
        string subcontract_documents_IPFS_address;
        string subcontract_requirements;
        address subcontract_awarded_to;
        bool subcontract_closed;
        subcontract_bid_submission_tracker subcontract_bid_submission_tracker_details;
        mapping (address=>submitted_subcontract_bid []) submitted_subcontract_bids;//
    }

    struct submitted_subcontract_bid{
        uint subcontract_bid_submission_time;
        string subcontract_bid_IPFS_address;
    }
    
    struct submitted_bid {
        uint bid_submission_time;
        string bid_IPFS_adress;
        uint bid_price;
    }
    
    modifier onlyOwner{
        require (owner_ethereum_public_address==msg.sender, "Access is Restricted to Only the Owner");
        _;
    }
    
    modifier only_regsitered_contractor{
        require (registered_contractors[msg.sender].contractor_ethereum_public_address==msg.sender, "Access is Restricted to Only Registered Contractors");
        _;
    }

    modifier only_regsitered_subcontractor (address _by_contractor) {
        require (registered_subcontractors[msg.sender][_by_contractor].subcontractor_ethereum_public_address==msg.sender,"Access is Restricted to Only Reggistered subcontractors");
        _;
    }  

    function intiate_tendering_process (
        string memory  _contract_type,
        string memory  _contract_number,
        string memory _owner_organization_name,
        string memory _contract_description,
        string memory _location,
        uint _bid_closing_date,    
        string memory _documents_IPFS_address,
        string memory _requirements) public onlyOwner{
            require( contract_details.tender_closed=false,"The contract is Already awarded to the Winner");
            contract_details=contract_info(_contract_type,_contract_number,_owner_organization_name,_contract_description,_location,block.timestamp,
            _bid_closing_date,_documents_IPFS_address,_requirements,false,0x0000000000000000000000000000000000000000);
    }

   function register_contractor(
       string memory _contractor_organization_name,
       address _contractor_ethereum_public_address,
       string memory _contractor_GPG_public_address) public onlyOwner {
           registered_contractors[_contractor_ethereum_public_address]=registered_contractor(_contractor_organization_name,_contractor_ethereum_public_address,_contractor_GPG_public_address);
           OpenPGPCertificates_IPFS[_contractor_ethereum_public_address]=_contractor_GPG_public_address;
    }
    

    function register_subcontractor(
       string memory _subcontractor_organization_name,
       address subcontractor_ethereum_public_address,
       string memory _subcontractor_GPG_public_address,
       address _regsitered_for) public only_regsitered_contractor {
           registered_subcontractors[subcontractor_ethereum_public_address][_regsitered_for]=registered_subcontractor(_subcontractor_organization_name,subcontractor_ethereum_public_address,
            _subcontractor_GPG_public_address,_regsitered_for);
           OpenPGPCertificates_IPFS[subcontractor_ethereum_public_address]=_subcontractor_GPG_public_address;
    }
    
    
    function initiate_subcontract_bidding(
        string memory  _subcontract_type,
        string memory  _subcontract_number,
        address  _subcontract_of,
        string memory _subcontract_description,
        string memory _subcontract_location,
        uint  _subcontract_closing_date,
        string memory _subcontract_documents_IPFS_address,
        string memory _subcontract_requirements) public only_regsitered_contractor{
            require(msg.sender==_subcontract_of);
            subcontracts[msg.sender][_subcontract_number].subcontract_type=_subcontract_type;
            subcontracts[msg.sender][_subcontract_number].subcontract_number=_subcontract_number;
            subcontracts[msg.sender][_subcontract_number].subcontract_of=_subcontract_of;
            subcontracts[msg.sender][_subcontract_number].subcontract_description=_subcontract_description;
            subcontracts[msg.sender][_subcontract_number].subcontract_location=_subcontract_location;
            subcontracts[msg.sender][_subcontract_number].subcontract_advertise_date=block.timestamp;
            subcontracts[msg.sender][_subcontract_number].subcontract_closing_date=_subcontract_closing_date;
            subcontracts[msg.sender][_subcontract_number].subcontract_documents_IPFS_address=_subcontract_documents_IPFS_address;
            subcontracts[msg.sender][_subcontract_number].subcontract_requirements=_subcontract_requirements;
            subcontracts[msg.sender][_subcontract_number].subcontract_awarded_to=0x0000000000000000000000000000000000000000;
            subcontracts[msg.sender][_subcontract_number].subcontract_closed=false;   
    }
    
    function submit_subcontract_bid(
        string memory _subcontract_bid_IPFS_address,
        address _for_contractor,
        string memory _for_subcontract_number)public only_regsitered_subcontractor (_for_contractor){
            require(subcontracts[_for_contractor][_for_subcontract_number].subcontract_closed==false,"Bid submission Deadline has Passed and Awarded subcontractor is Announced");
            require(subcontracts[_for_contractor][_for_subcontract_number].subcontract_closing_date>block.timestamp,"The Bid submission Deadline has Passed");
            if (!subcontracts[_for_contractor][_for_subcontract_number].subcontract_bid_submission_tracker_details.subcontract_bidder_exist[msg.sender]){
               subcontracts[_for_contractor][_for_subcontract_number].subcontract_bid_submission_tracker_details.number_of_subcontract_submitted_bid +=1;
                subcontracts[_for_contractor][_for_subcontract_number].subcontract_bid_submission_tracker_details.array_of_subcontract_bidders.push(msg.sender);
                subcontracts[_for_contractor][_for_subcontract_number].subcontract_bid_submission_tracker_details.subcontract_bidder_exist[msg.sender]=true;
            }
            subcontracts[_for_contractor][_for_subcontract_number].submitted_subcontract_bids[msg.sender].push(submitted_subcontract_bid(block.timestamp,_subcontract_bid_IPFS_address));
        
    }
    

   function announce_subcontract_winner(
       address _awarded_subcontractor_address,
       string memory _awarded_subcontract_number) only_regsitered_contractor public{
           bool _subBidderExist; 
           _subBidderExist = subcontracts[msg.sender][_awarded_subcontract_number].subcontract_bid_submission_tracker_details.subcontract_bidder_exist[_awarded_subcontractor_address];
           require(_subBidderExist==true, "There is No Record for This Subontractor");
           require(subcontracts[msg.sender][_awarded_subcontract_number].subcontract_closing_date<block.timestamp, "Bid submission is still Open");
           subcontracts[msg.sender][_awarded_subcontract_number].subcontract_awarded_to=_awarded_subcontractor_address;
           subcontracts[msg.sender][_awarded_subcontract_number].subcontract_closed=true;
    }

    function submit_bid (
        string memory _bid_IPFS_adress) only_regsitered_contractor public {
        require(!contract_details.tender_closed, "Bid submission Deadline has Passed and Awarded Contractor is Announced");
        require(block.timestamp<contract_details.bid_closing_date,"The Bid submission Deadline has Passed");
        require(registered_contractors[msg.sender].contractor_ethereum_public_address!=0x0000000000000000000000000000000000000000,"General Contractor is not Regeistered");
        if (!bid_submission_tracker_details.bidder_exist[msg.sender]){
            bid_submission_tracker_details.number_of_submitted_bid +=1;
            bid_submission_tracker_details.array_of_bidders.push(msg.sender);
            bid_submission_tracker_details.bidder_exist[msg.sender]=true;
        }
        submitted_bids[msg.sender].push(submitted_bid(block.timestamp,_bid_IPFS_adress,0));
    }


   function announce_winner(
       address _awarded_contractor_address) onlyOwner public{
           require(contract_details.tender_closed==false,"Awarded Contractor is Already Announced");
           require(contract_details.bid_closing_date<block.timestamp, "Bid submission is still Open");
           contract_details.awarded_to=_awarded_contractor_address;
           contract_details.tender_closed=true;
    }
   function publish_bid_prices(
       address _contractor_address, uint _bid_price) onlyOwner public{
           uint length=submitted_bids[_contractor_address].length;
           submitted_bids[_contractor_address][length-1].bid_price=_bid_price;

    }    
    
    function publish_owner_GPS_certificate_address(
       string memory _owner_GPG_certificate_address) onlyOwner public{
           OpenPGPCertificates_IPFS[msg.sender]=_owner_GPG_certificate_address;


    }    

    function return_submitted_bids () public view returns(address[] memory){
        return bid_submission_tracker_details.array_of_bidders;

    }
    
    
    function return_subcontract_submitted_bids (address _contractor, string memory _subcontract_n) public view returns(address[] memory){
       return subcontracts[_contractor][_subcontract_n].subcontract_bid_submission_tracker_details.array_of_subcontract_bidders;
     
    }  
    
    
    function return_winner () public view returns(address){
      return contract_details.awarded_to;
    } 
   
    function return_subcontract_winner (address _contractor, string memory _subcontract_n) public view returns(address){
      return subcontracts[_contractor][_subcontract_n].subcontract_awarded_to;
    }    
    
   function return_contractor_bid(address _contractor) public view returns(uint, string memory){
           
           uint length=submitted_bids[_contractor].length;
           require (length!=0, "There is no BId Record for this Contractor");
           uint submitted_bid_price=submitted_bids[_contractor][length-1].bid_price;
           string memory submitted_bid_IPFS = submitted_bids[_contractor][length-1].bid_IPFS_adress;
           return (submitted_bid_price,submitted_bid_IPFS);
   }
    
   function return_subcontractor_bid(address _contractor, string memory _subcontract_n, address _subcontractor) public view returns(string memory){ 
           uint length=subcontracts[_contractor][_subcontract_n].submitted_subcontract_bids[_subcontractor].length;
           require (length!=0,"There is no BId Record for this Contractor");
           string memory submitted_Subcontract_bid_IPFS = subcontracts[_contractor][_subcontract_n].submitted_subcontract_bids[_subcontractor][length-1].subcontract_bid_IPFS_address;
           return (submitted_Subcontract_bid_IPFS);
   }

   function return_OpenPGP_Certificates_IPFS(address _user_address) public view returns(string memory){
           string memory certificate_address= OpenPGPCertificates_IPFS[_user_address];
           return  certificate_address;
   }

    
}