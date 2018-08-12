pragma solidity ^0.4.20;

contract owned {
    address public owner;
    address public tokenContract;
    constructor() public{
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyOwnerAndtokenContract {
        require(msg.sender == owner || msg.sender == tokenContract);
        _;
    }


    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    
    function transfertokenContract(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            tokenContract = newOwner;
        }
    }
}

contract DataContract is owned {
    struct Good {
        bytes32 preset;
        uint price;
        uint decision;
        uint time;
    }

    mapping (bytes32 => Good) public goods;

    function setGood(bytes32 _preset, uint _price,uint _decision) onlyOwnerAndtokenContract external {
        goods[_preset] = Good({preset: _preset, price: _price, decision:_decision, time: now});
    }

    function getGoodPreset(bytes32 _preset) view public returns (bytes32) {
        return goods[_preset].preset;
    }
    function getGoodDecision(bytes32 _preset) view public returns (uint) {
        return goods[_preset].decision;
    }
    function getGoodPrice(bytes32 _preset) view public returns (uint) {
        return goods[_preset].price;
    }
}


contract Token is owned {

    DataContract DC;

    constructor(address _dataContractAddr) public{
        DC = DataContract(_dataContractAddr);
    }

    event Decision(uint decision,bytes32 preset);

    function postGood(bytes32 _preset, uint _price) onlyOwner public {
        require(DC.getGoodPreset(_preset) == "");
        uint _decision = uint(keccak256(keccak256(blockhash(block.number),_preset),now))%(_price);
        DC.setGood(_preset, _price, _decision);
        Decision(_decision, _preset);
    }
}