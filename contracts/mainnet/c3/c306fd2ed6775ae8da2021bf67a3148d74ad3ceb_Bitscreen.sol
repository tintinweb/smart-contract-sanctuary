pragma solidity ^0.4.0;
contract Bitscreen {
    struct IPFSHash {
    bytes32 hash;
    uint8 hashFunction;
    uint8 size;
    }
    event ImageChange(bytes32 _hash,uint8 _hashFunction,uint8 _size);

    struct ScreenData {
    uint currLargestAmount;
    uint256 totalRaised;
    address currHolder;
    uint8 heightRatio;
    uint8 widthRatio;
    string country;
    }
    
    struct ContentRules {
        bool sexual;
        bool violent;
        bool political;
        bool controversial;
        bool illegal;
    }
    event RuleChange(bool _sexual,bool _violent,bool _political,bool _controversial,bool _illegal);
    address public owner;
    
    IPFSHash public currPicHash;
    
    ScreenData public screenstate;
    ContentRules public rules;
    address[] private badAddresses;

    function Bitscreen(bytes32 _ipfsHash, uint8 _ipfsHashFunc, uint8 _ipfsHashSize, uint8 _heightRatio, uint8 _widthRatio, string _country) public {
        owner = msg.sender;
        currPicHash = IPFSHash(_ipfsHash,_ipfsHashFunc,_ipfsHashSize);
        screenstate = ScreenData(0,0, msg.sender,_heightRatio,_widthRatio,_country);
        rules = ContentRules(false,false,false,false,false);
    }
    
    function remove() public {
        if(msg.sender == owner) {
        selfdestruct(owner);
        }
    }
    
    function withdraw() external{
        if(msg.sender == owner) {
            uint256 withdrawAmount = screenstate.totalRaised;
            screenstate.totalRaised=0;
            screenstate.currLargestAmount=0;
            msg.sender.transfer(withdrawAmount);
        }else{
            revert();
        }
    }

    function getBadAddresses() external constant returns (address[]) {
        if(msg.sender == owner) {
            return badAddresses;
        }else{
            revert();
        }
    }


    function changeRules(bool _sexual,bool _violent, bool _political, bool _controversial, bool _illegal) public {
                if(msg.sender == owner) {
                rules.sexual=_sexual;
                rules.violent=_violent;
                rules.political=_political;
                rules.controversial=_controversial;
                rules.illegal=_illegal;
                
                RuleChange(_sexual,_violent,_political,_controversial,_illegal);
                
                }else{
                revert();
                }
    }


    function changeBid(bytes32 _ipfsHash, uint8 _ipfsHashFunc, uint8 _ipfsHashSize) payable external {
            if(msg.value>screenstate.currLargestAmount) {
                screenstate.currLargestAmount=msg.value;
                screenstate.currHolder=msg.sender;
                screenstate.totalRaised+=msg.value;
                
                currPicHash.hash=_ipfsHash;
                currPicHash.hashFunction=_ipfsHashFunc;
                currPicHash.size=_ipfsHashSize;
                
                ImageChange(_ipfsHash,_ipfsHashFunc,_ipfsHashSize);
                
            }else {
                revert();
            }
    }
    
    function emergencyOverwrite(bytes32 _ipfsHash, uint8 _ipfsHashFunc, uint8 _ipfsHashSize) external {
        if(msg.sender == owner) { 
            badAddresses.push(screenstate.currHolder);
            currPicHash.hash=_ipfsHash;
            currPicHash.hashFunction=_ipfsHashFunc;
            currPicHash.size=_ipfsHashSize;
            screenstate.currHolder=msg.sender;
            ImageChange(_ipfsHash,_ipfsHashFunc,_ipfsHashSize);
        }else{
            revert();
        }
    }
    
    function () payable public {}

}