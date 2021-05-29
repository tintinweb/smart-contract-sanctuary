/**
 *Submitted for verification at Etherscan.io on 2021-05-29
*/

pragma solidity ^0.5.1;

contract MeatLoveAnimal {
    address farmer;
    address transporterFromFarmerToSlaughterer;
    address slaughterer;
    address distributer;

    /**
     * Weight of the whole animal in gram before slaughtering.
     */
    uint256 weight;
        
    /**
     * List of all content IDs of health report stored in an external database (IPFS).
     */
    string[] healthReports;
    
    modifier onlySlaugtherer() {
        require(msg.sender == slaughterer);
        _;
    }
     
    function recordFarmer (address _farmer) public {
        farmer = _farmer;
    }
    
    function recordTransporterFromFarmerToSlaughterer (address _transporterFromFarmerToSlaughterer) public {
        transporterFromFarmerToSlaughterer = _transporterFromFarmerToSlaughterer;
    }
    
    function recordSlaughterer (address _slaughterer) public {
        slaughterer = _slaughterer;
    }
    
    function recordDistributer (address _distributer) public {
        distributer = _distributer;
    }
    
    function addHealthReport (string memory cid) public {
        healthReports.push(cid);
    }
    
    function recordWeight (uint256 _weight) public onlySlaugtherer {
        weight = _weight;
    }
    
    function createNewPieceOfMeat (uint256 weightOfPieceOfMeat) public onlySlaugtherer {
        new MeatLovePieceOfMeat(weightOfPieceOfMeat);
    } 
    
}

contract MeatLovePieceOfMeat {
    /**
     * Weight of the piece of meat in gram.
     */
    uint256 weight;
    
    address transporterFromDistributorToButcher;
        
    constructor (uint256 weightOfPieceOfMeat) public {
        weight = weightOfPieceOfMeat;
    }
    
    function recordTransporterFromDistributorToButcher (address _transporterFromDistributorToButcher) public {
        transporterFromDistributorToButcher = _transporterFromDistributorToButcher;
    }
}