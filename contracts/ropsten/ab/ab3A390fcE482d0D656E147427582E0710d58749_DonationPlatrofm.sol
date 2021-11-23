/**
 *Submitted for verification at Etherscan.io on 2021-11-23
*/

// File: contracts/wold.sol



pragma solidity ^0.8.3;

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
    
    address public admin;
    Campagine[] public campaignes;
    constructor(){
        admin=msg.sender;
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
        
        /// reverts donation if time target has passsed
        if (campaignes[id].closed ||block.timestamp>=campaignes[id].timeTrget) 
           revert("this Campagine is closed");
        
        ///closes the campagine but doesnt revert the donation
        if (campaignes[id].amountTarget<=campaignes[id].amount) campaignes[id].closed=true;
            
        campaignes[id].contributors.push(msg.sender);//treba da se doda provera jedinstevnosti za drugi zadatak
        emit ContrbutionReceived(msg.sender,"Contribution recevied");
    }
    
    function withdraw(uint id) public payable {
        require(msg.sender==campaignes[id].menager,"only menager can whithdraw");//dal menadzer mora da ceka da kampanja bude gotova
        (bool success, ) = campaignes[id].menager.call{value: campaignes[id].amount}("");
        require(success, "Failed to send Ether");
    }
}