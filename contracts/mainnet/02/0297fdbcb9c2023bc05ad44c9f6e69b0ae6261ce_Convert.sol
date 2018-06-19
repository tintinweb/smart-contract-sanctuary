pragma solidity ^0.4.21;

contract Convert {
    
    address owner;
    address public fromContractAddr;
    address public toContractAddr;
    
    mapping (uint => bool) public isConvert;
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function Convert() public {
        owner = msg.sender;
    }
    
    function setFromContractAddr(address _addr) public onlyOwner {
        fromContractAddr = _addr;
    }
    
    function setToContractAddr(address _addr) public onlyOwner {
        toContractAddr = _addr;
    }
    
    function getNewToken(uint _tokenId) public {
        IFrom ifrom = IFrom(fromContractAddr);
        require(ifrom.ownerOf(_tokenId) == msg.sender);
        require(isConvert[_tokenId] == false);
        
        isConvert[_tokenId] = true;
        
        ITo ito = ITo(toContractAddr);
        ito.issueTokenAndTransfer(1, msg.sender);
    }
    
    /* only read */
    
}

interface IFrom {
    function ownerOf (uint256 _itemId) public view returns (address _owner);
}

interface ITo {
    function issueTokenAndTransfer(uint256 _count, address to) public;
}