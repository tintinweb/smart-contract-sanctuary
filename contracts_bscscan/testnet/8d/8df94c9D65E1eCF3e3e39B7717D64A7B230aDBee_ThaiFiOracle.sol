// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorInterface {

        function getReferenceData(string calldata _bases , string calldata _quotes) external view returns (
        uint256 rate,
        uint256 lastUpdatedBase,
        uint256 lastUpdatedQuote
        );
}


contract ThaiFiOracle is AggregatorInterface {
    address public maintainer;
    address private owner;
    uint256 private priceusd;
    uint256 private creationTime;
    uint256 private lastupdate;
    
    constructor (address  _maintainer) public {
        maintainer = _maintainer;
        owner = msg.sender;
        creationTime = block.timestamp;
    }
    
    modifier isOwner() {
        require(msg.sender == owner );
        _;
    }

    modifier isMaintainer() {
        require( msg.sender == owner || msg.sender == maintainer );
        _;
    }    
    function changeOwner(address newOwner) public isOwner {
        owner = newOwner;
    }

    function changeMaintainer(address newMaintainer) public isOwner {
        maintainer = newMaintainer;
    }    

    function getReferenceData(string calldata _bases , string calldata _quotes) external view override returns (
        uint256 rate,
        uint256 lastUpdatedBase,
        uint256 lastUpdatedQuote
        ) {
        return (priceusd, creationTime, lastupdate);
    }
    
    function updatePrice(uint256 price) external isMaintainer {
        priceusd = price;
        lastupdate = block.timestamp;
    }
}

