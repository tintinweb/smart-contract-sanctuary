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
        uint time;
    }

    mapping (bytes32 => Good) public goods;

    function setGood(bytes32 _preset, uint _price) onlyOwnerAndtokenContract external {
        goods[_preset] = Good({preset: _preset, price: _price, time: now});
    }
    
    function getGoodPreset(bytes32 _preset) view public returns (bytes32) {
        return goods[_preset].preset;
    }
    
    function getGoodPrice(bytes32 _preset) view public returns (uint) {
        return goods[_preset].price;
    }

    mapping (bytes32 => address) public decisionOf;

    function setDecision(bytes32 _preset, address _address) onlyOwnerAndtokenContract external {
        decisionOf[_preset] = _address;
    }

    function getDecision(bytes32 _preset) view public returns (address) {
        return decisionOf[_preset];
    }
}


contract Token is owned {

    DataContract DC;

    constructor(address _dataContractAddr) public{
        DC = DataContract(_dataContractAddr);
    }
    
    uint _seed = now;

    struct Good {
        bytes32 preset;
        uint price;
        uint time;
    }

    // controll

    event Decision(uint result, address finalAddress, address[] buyers, uint[] amounts);

    function _random() internal returns (uint randomNumber) {
        _seed = uint(keccak256(keccak256(block.blockhash(block.number-100))));
        return _seed ;
    }

    function _stringToBytes32(string memory _source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(_source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(_source, 32))
        }
    }

    // get decision result address
    function _getFinalAddress(uint[] _amounts, address[] _buyers, uint result) internal pure returns (address finalAddress) {
        uint congest = 0;
        address _finalAddress = address(0);
        for (uint j = 0; j < _amounts.length; j++) {
            congest += _amounts[j];
            if (result <= congest && _finalAddress == address(0)) {
                _finalAddress = _buyers[j];
            }
        }
        return _finalAddress;
    }

    function postTrade(bytes32 _preset, uint _price) onlyOwner public {
        require(DC.getGoodPreset(_preset) == "");
        DC.setGood(_preset, _price);
    }

    function decision(bytes32 _preset, string _presetSrc, address[] _buyers, uint[] _amounts) onlyOwner public payable{
        
        // execute it only once
        require(DC.getDecision(_preset) == address(0));

        // preset authenticity
        require(sha256(_presetSrc) == DC.getGoodPreset(_preset));

        // address added, parameter 1
        uint160 allAddress;
        for (uint i = 0; i < _buyers.length; i++) {
            allAddress += uint160(_buyers[i]);
        }
        
        // random, parameter 2
        uint random = _random();

        uint goodPrice = DC.getGoodPrice(_preset);

        // preset is parameter 3, add and take the remainder
        uint result = uint(uint(_stringToBytes32(_presetSrc)) + allAddress + random) % goodPrice;

        address finalAddress = _getFinalAddress(_amounts, _buyers, result);
        // save decision result
        DC.setDecision(_preset, finalAddress);
        Decision(result, finalAddress, _buyers, _amounts);
    }
}