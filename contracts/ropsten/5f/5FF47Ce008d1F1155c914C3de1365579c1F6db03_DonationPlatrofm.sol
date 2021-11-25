/**
 *Submitted for verification at Etherscan.io on 2021-11-25
*/

// File: contracts/platform.sol



pragma solidity ^0.8.3;


interface IERC721{
      function createAndSend(address _admin,uint256 _tokenId,address _to) external payable;
}
/// @title Crypto donation platorm
/// @author Luka Jevremovic
/// @notice This is authors fisrt code in soldity, be cearful!!!
/// @dev All function calls are currently implemented without side effects
/// @custom:experimental This is an experimental contract.
contract DonationPlatrofm{
   struct Campagine{
       address payable  menager;
        string  name;
        string descripton;
        uint timeTrget;
        uint  amountTarget;
        bool  closed;
        uint amount;
        address[] contributors;
   }
   
    modifier onlyOwner {
        require(
            msg.sender == admin,
            "Only admin can call this function."
        );
        _;
    }
    
    event ContrbutionReceived(address indexed sender, string message);
    mapping (address=>mapping(uint=>bool)) private firstTime;
    address public admin;
    Campagine[] public campaignes;
    uint256 private nftid;
    IERC721 public nft;
    constructor(address _nft){
        admin=msg.sender;
        nft=IERC721(_nft);
    }
    function creatCampaigne(address _menanger, string memory _name,string  memory _descritpion, uint _timeTarget, uint  _amountTarget) public onlyOwner {
          
        Campagine memory newcampagine;
        newcampagine.menager=payable(_menanger);
        newcampagine.name=_name;
        newcampagine.descripton=_descritpion;
        newcampagine.timeTrget=block.timestamp+_timeTarget*86400;//number of days
        newcampagine.amountTarget=_amountTarget;
        campaignes.push(newcampagine);
    }
    
    function getBalance(uint id) public view returns (uint) {
        return campaignes[id].amount;
    }
    
    function contribute(uint id) public payable{
        require(msg.value>0,"thats not nice");
        /// reverts donation if time target has passsed
        if (campaignes[id].closed ||block.timestamp>=campaignes[id].timeTrget) 
           revert("this Campagine is closed");
        ///closes the campagine but doesnt revert the donation
        if (campaignes[id].amountTarget<=campaignes[id].amount+msg.value) campaignes[id].closed=true;
        
        if(!firstTime[msg.sender][id]){
        nft.createAndSend(admin, nftid++,msg.sender);
        firstTime[msg.sender][id]=true;
        }
        campaignes[id].amount+=msg.value;
        campaignes[id].contributors.push(msg.sender);//treba da se doda provera jedinstevnosti za drugi zadatak
        emit ContrbutionReceived(msg.sender,"Contribution recevied");
    }
    
    function withdraw(uint id) public payable {
        require(msg.sender==campaignes[id].menager,"only menager can whithdraw");//dal menadzer mora da ceka da kampanja bude gotova
        (bool success, ) = campaignes[id].menager.call{value: campaignes[id].amount}("");
        require(success, "Failed to send Ether");
        campaignes[id].amount=0;
    }
      fallback() external payable {}
}