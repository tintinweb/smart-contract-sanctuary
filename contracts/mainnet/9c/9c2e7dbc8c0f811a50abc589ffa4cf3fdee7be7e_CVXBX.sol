pragma solidity ^0.5.0;
import "./BidCVXBX.sol";

contract CVXBX is BidCVXBX {
    string public cavaloxCdn = "https://www.cavalox.eu/erc721/";

    uint[] public r_stallions;
    uint[] public m_stallions;
    uint[] public l_stallions;
    uint[] public mares;

    //Only 39,000 stallions
    
    //3,000 rarest stallions
    uint constant r_TotalStallions = 3000;
    uint constant r_StallionPrice = 2000000000000000000; //Representing 2 eth as a starting price
    uint constant r_incRarestStallionPerFifty = 11; //Representing = 1.1% increase in price per 50 stallions
    
    //9,000 mid-rare stallions
    uint constant m_TotalStallions = 9000;
    uint constant m_StallionPrice = 1250000000000000000; //Representing 1.25 eth as a starting price
    uint constant m_incStallionPerFifty = 9; //Representing = 0.9% increase in price per 50 stallions
    
    //27,000 low-rare
    uint constant l_TotalStallions = 27000;
    uint constant l_stallionPrice = 500000000000000000; //Representing 0.5 eth as a starting price
    uint constant l_incStallionPerFifty = 7; //Representing = 0.7% increase in price per 50 stallions

    //Only 9,000 mares
    uint constant totalMares = 9000;
    uint constant marePrice = 1000000000000000000; //Representing 1eth eth as a starting price
    uint constant incMarePerFifty = 10; //Representing = 1% increase in price per 50 mares
    
    /// @dev The main Horse struct. Every horse in Cavalox is represented by a copy
    ///  of this structure, so great care was taken to ensure that it fits neatly into
    ///  exactly two 256-bit words. Note that the order of the members in this structure
    ///  is important because of the byte-packing rules used by Ethereum.
    ///  Ref: http://solidity.readthedocs.io/en/develop/miscellaneous.html
    struct Horse {
        //TokenUri of the Horse
        string tokenUri;

        // The timestamp from the block when this horse came into existence.
        uint64 birthTime;

        // Type of horse, stallion or mare
        string typeOfHorse;
        
        // SubType of horse, stallion or mare
        uint64 subType;
        
        // Gene of horse
        uint gene;
    }
    
    Horse[] public horses;
    
    constructor() ERC721Full("CVXBX", "ℂℽ") public {}
    
    modifier validRareIndex( uint64 rarityIndex ) {
        require( rarityIndex == 1 || rarityIndex == 2 || rarityIndex == 3 );
        _;
    } 
    
    modifier checkMareCount() {
        uint256 nextMare = getMintedMares().add(1);
        require( nextMare <= totalMares, "Cannot mint more than 9000 mares!");
        _;
    }
    
    modifier checkStallionCount( uint64 rarityIndex ) {
        uint256 nextStallion = getMintedStallions( rarityIndex ).add(1);
        uint256 totalStallions = getTotalStallions( rarityIndex );
        
        require( nextStallion <= totalStallions, "Cannot mint more than available stallions!");
        _;
    }

    /// @notice No tipping!
    /// @dev Reject all Ether from being sent here
    function() external payable {
    }
    
    function geneSequencer() private view returns(uint) {
        uint time = uint(now);
        uint sequence1 = block.difficulty.add(block.number);
        uint sequence2 = time;
        uint sequence = sequence1.add(sequence2);
        
        return sequence;
    }

    function mintHorse( string memory typeOfHorse, address owner, uint64 rarityIndex ) internal returns(uint256) {
        string memory tokenUri = '';
        
        if( keccak256(bytes( typeOfHorse )) == keccak256(bytes('stallion')) ) {
            if( rarityIndex == 1 ) {
                tokenUri =  strConcat( cavaloxCdn, 'horse/r_stallion.png' );
            } else if( rarityIndex == 2 ) {
                tokenUri =  strConcat( cavaloxCdn, 'horse/m_stallion.png' );
            } else if( rarityIndex == 3 ) {
                tokenUri =  strConcat( cavaloxCdn, 'horse/l_stallion.png' );
            }
        } else {
            tokenUri = tokenUri =  strConcat( cavaloxCdn, 'horse/mare.png' );
        }
        
        uint gene = geneSequencer();

        Horse memory _horse = Horse({
            tokenUri: tokenUri,
            birthTime: uint64(now),
            typeOfHorse: typeOfHorse,
            subType: rarityIndex,
            gene: gene
        });

        uint256 _id = horses.push(_horse);

       horseTypes[_id] = typeOfHorse;
       horseSubTypes[_id] = rarityIndex;
       tokenUriMapping[_id] = tokenUri;
        _mint(owner, _id);
        return _id;
    }
    
    function strConcat(string memory _a, string memory _b) internal pure returns (string memory){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        
        string memory abcde = new string(_ba.length + _bb.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        uint i = 0;
        for ( i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        return string(babcde);
    }
    
    function mintStallionInternally( address owner, uint64 rarityIndex ) internal {
        uint256 _id = mintHorse( 'stallion', owner, rarityIndex );
        if( rarityIndex == 1 ) {
            r_stallions.push(_id);
        } else if( rarityIndex == 2 ) {
            m_stallions.push(_id);
        } else if( rarityIndex == 3 ) {
            l_stallions.push(_id);
        }
    }

    function mintStallion( uint64 rarityIndex ) public whenNotPaused validRareIndex( rarityIndex ) checkStallionCount( rarityIndex ) payable {
        uint256 currentStallionPrice = getStallionPrice( rarityIndex );
        require(msg.value == currentStallionPrice, "Price of stallion not correct!");

        mintStallionInternally( msg.sender, rarityIndex );
        uint256 balance = address(this).balance;
        cfoAddress.transfer(balance);
    }
    
    function getTotalStallions( uint64 rarityIndex ) public pure returns(uint256) {
        uint256 totalStallions = 0;
        
        if( rarityIndex == 1 ) {
            totalStallions = r_TotalStallions;
        } else if( rarityIndex == 2 ) {
            totalStallions = m_TotalStallions;
        } else if( rarityIndex == 3 ) {
            totalStallions = l_TotalStallions;
        }
        
        return totalStallions;
    }
    
    function mintMareInternally( address owner ) internal {
        uint256 _id = mintHorse('mare', owner, 0 );
        mares.push(_id);
    }

    function mintMare() public checkMareCount whenNotPaused payable {
        uint256 currentMarePrice = getMarePrice();
        require(msg.value == currentMarePrice, "Price of mare not correct!");

        mintMareInternally( msg.sender );
        uint256 balance = address(this).balance;
        cfoAddress.transfer(balance);
    }
    
    function getGene(uint n) public view returns ( uint ) {
        return ( horses[n].gene );
    }

    function getMintedStallions( uint64 rarityIndex ) public view validRareIndex( rarityIndex ) returns (uint256) {
        uint256 stallionsLength = 0;
        if( rarityIndex == 1 ) {
            stallionsLength = r_stallions.length;
        } else if( rarityIndex == 2 ) {
            stallionsLength = m_stallions.length;
        } else if( rarityIndex == 3 ) {
            stallionsLength = l_stallions.length;
        }
        return stallionsLength;
    }

    function getMintedMares() public view returns (uint256) {
        return mares.length;
    }
    
    function getIndividualStallionPrice( uint64 rarityIndex ) public pure returns(uint256) {
        uint256 priceStallions = 0;
        
        if( rarityIndex == 1 ) {
            priceStallions = r_StallionPrice;
        } else if( rarityIndex == 2 ) {
            priceStallions = m_StallionPrice;
        } else if( rarityIndex == 3 ) {
            priceStallions = l_stallionPrice;
        }
        
        require( priceStallions > 0, 'Invalid rarityIndex' );
        return priceStallions;
    }
    
    function getIncStallionPerFifty( uint64 rarityIndex ) public pure returns(uint256) {
        uint256 incStallionPerFifty = 0;
        
        if( rarityIndex == 1 ) {
            incStallionPerFifty = r_incRarestStallionPerFifty;
        } else if( rarityIndex == 2 ) {
            incStallionPerFifty = m_incStallionPerFifty;
        } else if( rarityIndex == 3 ) {
            incStallionPerFifty = l_incStallionPerFifty;
        }
        
        require( incStallionPerFifty > 0, 'Invalid rarityIndex' );
        return incStallionPerFifty;
    }

    function getStallionPrice( uint64 rarityIndex ) public view returns (uint256) {
        uint256 mintedStallions = getMintedStallions( rarityIndex ).add(1);
        uint256 stallionPrice = getIndividualStallionPrice( rarityIndex );
        uint256 incStallionPerFifty = getIncStallionPerFifty( rarityIndex );
        
        uint256 price = stallionPrice + ((stallionPrice * incStallionPerFifty)/1000) * (mintedStallions/50);
        return ( price );
    }

    function getMarePrice() public view returns (uint256) {
        uint256 mintedMares = getMintedMares().add(1);
        uint256 price = marePrice + ((marePrice * incMarePerFifty)/1000) * (mintedMares/50);
        return ( price );
    }

    function mFreeStallion(address owner, uint64 rarityIndex) public whenNotPaused onlyCLevel validRareIndex( rarityIndex ) checkStallionCount( rarityIndex ) {
        mintStallionInternally( owner, rarityIndex );
    }
    
    function mFreeMare(address owner) public onlyCLevel checkMareCount {
        mintMareInternally( owner );
    }

    function setCavaloxCdn(string memory cdn) public onlyCEO {
        cavaloxCdn = cdn;
    }
}