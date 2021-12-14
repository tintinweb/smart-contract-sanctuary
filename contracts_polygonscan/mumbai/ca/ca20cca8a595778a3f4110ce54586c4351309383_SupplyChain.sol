/**
 *Submitted for verification at polygonscan.com on 2021-12-13
*/

pragma solidity ^0.8.0;

contract SupplyChain {
    address public maintainer;

    struct MedicalData {
        string name;
        uint256 date;
        string IPFSHash;
        uint256 verifycount;
    }

    struct Distributors {
        string position;
        bool verified;
    }

    struct Retailer {
        string position;
        bool verified;
    }

    struct VerifyData {
        string position;
        address verifier;
        uint256 date;
        bool vote;
    }

    mapping(uint256 => MedicalData) public batch;
    mapping(address => Distributors) public distributors;
    mapping(address => Retailer) public retailer;
    mapping(uint256 => mapping(uint256 => VerifyData)) public verifydata;

    modifier onlymaintainer() {
        if (msg.sender == maintainer) {
            _;
        }
    }

    constructor() public {
        maintainer = msg.sender;
    }

    function addDistOrReta(address _address, uint256 _type, string memory _poistion) public onlymaintainer {
        if (_type == 1) {
            distributors[_address] = Distributors(_poistion, true);
        } else {
            retailer[_address] = Retailer(_poistion, true);
        }
    }

    function medialdata( uint256 _batchcode, string memory _name, string memory _IPFSHash) public onlymaintainer {
        require(batch[_batchcode].date == 0, "Already Batch Data Exist");
        batch[_batchcode] = MedicalData(_name, block.timestamp, _IPFSHash, 0);
    }

    function getVotersdata() public view returns (string memory, uint256) {
        if (distributors[msg.sender].verified == true) {
            return (distributors[msg.sender].position, 1);
        } else if (retailer[msg.sender].verified == true) {
            return (retailer[msg.sender].position, 2);
        }
    }

    function verifythedata(uint256 _batchcode, bool _vote) public {
        require(batch[_batchcode].date > 0, "NO Data Exist");
        require(distributors[msg.sender].verified == true || retailer[msg.sender].verified == true,"The Voter is not verified");
        if (distributors[msg.sender].verified == true) {
            verifydata[_batchcode][batch[_batchcode].verifycount++] = VerifyData(distributors[msg.sender].position,msg.sender,block.timestamp,_vote);
        } else if (retailer[msg.sender].verified == true) {
            verifydata[_batchcode][batch[_batchcode].verifycount++] = VerifyData(retailer[msg.sender].position,msg.sender,block.timestamp,_vote);
        }
    }

    function viewverifiedData(uint256 _batchcode, uint256 _verifierID) public view returns(string memory, address, uint256, bool){
        return (verifydata[_batchcode][_verifierID].position, verifydata[_batchcode][_verifierID].verifier, verifydata[_batchcode][_verifierID].date, verifydata[_batchcode][_verifierID].vote);
    }
    
    function getMedicineData(uint256 _batchcode) public view returns(string memory, uint256, string memory, uint256){
        return(batch[_batchcode].name, batch[_batchcode].date, batch[_batchcode].IPFSHash, batch[_batchcode].verifycount);
    }
    
    function getMedicineDoc(uint256 _batchcode) public view returns(string memory){
        return(batch[_batchcode].IPFSHash);
    }
    function checkMaintainer() public view returns (bool) {
        if (msg.sender == maintainer) {
            return true;
        }
        return false;
    }
}