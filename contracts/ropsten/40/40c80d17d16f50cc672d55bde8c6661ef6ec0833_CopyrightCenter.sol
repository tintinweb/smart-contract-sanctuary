pragma solidity ^0.4.24;

/**
 * @title Owned
 */
contract Owned {
    address public owner;
    address public newOwner;
    mapping (address => bool) public admins;

    event OwnershipTransferred(
        address indexed _from, 
        address indexed _to
    );

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAdmins {
        require(admins[msg.sender]);
        _;
    }

    function transferOwnership(address _newOwner) 
        public 
        onlyOwner 
    {
        newOwner = _newOwner;
    }

    function acceptOwnership() 
        public 
    {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }

    function addAdmin(address _admin) 
        onlyOwner 
        public 
    {
        admins[_admin] = true;
    }

    function removeAdmin(address _admin) 
        onlyOwner 
        public 
    {
        delete admins[_admin];
    }

}

/**
 * @title SafeMath v0.1.9
 * @dev Math operations with safety checks that throw on error
 * change notes:  original SafeMath library from OpenZeppelin modified by Inventor
 * - added sqrt
 * - added sq
 * - added pwr 
 * - changed asserts to requires with error log outputs
 * - removed div, its useless
 */
library SafeMath {
    
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }
    
    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c) 
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
    
    /**
     * @dev gives square root of given x.
     */
    function sqrt(uint256 x)
        internal
        pure
        returns (uint256 y) 
    {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y) 
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }
    
    /**
     * @dev gives square. multiplies x by x
     */
    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }
    
    /**
     * @dev x to the power of y 
     */
    function pwr(uint256 x, uint256 y)
        internal 
        pure 
        returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else 
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }
}

/**
 * @title AddressUtils
 * @dev Utility library of inline functions on addresses
 */
library AddressUtils {

    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param addr address to check
     * @return whether the target address is a contract
     */
    function isContract(address addr) 
        internal 
        view 
        returns (bool) 
    {
        uint256 size;
        /// @dev XXX Currently there is no better way to check if there is 
        // a contract in an address than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solium-disable-next-line security/no-inline-assembly
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

contract CopyrightCenter is Owned {
    using AddressUtils for address;
    using SafeMath for uint256;

    address BPaddress; // BP, ERC721
    address WHaddress; // WareHouse
    address CRaddress; // Copyright用户注册好版权的地方。cr,代码和BP一样，存储数据不同。

    mapping(string => uint256) indexOfCRhash;
    mapping(address => mapping(uint256 => string)) CRhashOfCRTokenId;

    uint256 tokenId;


    event Shelf(address _maker, uint256 indexed _tokenIdOfBP, uint256 indexed _tokenIdOfCR, string _BPHash);
    event Unshelf(address _maker, uint256 indexed _tokenIdOfBP, uint256 indexed _tokenIdOfCR, string _BPHash);

    constructor()
        public
    {
        owner = msg.sender;
        admins[msg.sender] = true;
        tokenId = 1;
    }

    function setBPAddress(address _addr)
        public
        onlyAdmins
    {
        require(_addr.isContract());
        BPaddress = _addr;
    }

    function setWHaddress(address _addr)
        public
        onlyAdmins
    {
        require(_addr.isContract());
        WHaddress = _addr;
    }

    function setCRaddress(address _addr)
        public
        onlyAdmins
    {
        require(_addr.isContract());
        CRaddress = _addr;
    }

    function canShelf(string BPHash, address BPmaker)
        public
        view
        returns(bool)
    {
        BP bp = BP(BPaddress);
        BP cr = BP(BPaddress);
        WareHouse wh = WareHouse(WHaddress);
        uint256 _indexOfBP = wh.getTokenIdFrombBPhash(BPHash);
        uint256 _indexOfCR = indexOfCRhash[BPHash];

        if(bp.exists(_indexOfBP) && bp.makerOf(_indexOfBP) == BPmaker && !cr.exists(_indexOfCR) && !wh.lockState(BPHash)) {
            return true;
        } else {
            return false;
        }
    }

    function shelf(string BPHash, address _maker)
        public
        onlyAdmins
    {
        require(canShelf(BPHash, _maker));
        BP cr = BP(CRaddress);
        WareHouse wh = WareHouse(WHaddress);
        
        // tokenId 不能为0
        uint256 _tokenIdOfCR = tokenId;

        uint256 _tokenIdOfBP = wh.getTokenIdFrombBPhash(BPHash);


        cr.mint(msg.sender, _tokenIdOfCR , _maker);
        wh.setLock(BPHash, true);

        indexOfCRhash[BPHash] = _tokenIdOfCR;
        CRhashOfCRTokenId[_maker][_tokenIdOfCR] = BPHash;

        
        tokenId = tokenId.add(1);
        emit Shelf(_maker, _tokenIdOfBP, _tokenIdOfCR, BPHash);
        
    }
    
    function canUnshelf(string BPHash)
        public
        view
        returns(bool)
    {
        BP cr = BP(CRaddress);
        WareHouse wh = WareHouse(WHaddress);
        uint256 _tokenId = indexOfCRhash[BPHash];
        address _maker = cr.makerOf(_tokenId);

        if(cr.exists(_tokenId) && msg.sender == _maker && wh.lockState(BPHash)) {
            return true;
        } else {
            return false;
        }
    }


    function unshelf(string BPHash)
        public
        onlyAdmins
    {
        BP cr = BP(CRaddress);
        WareHouse wh = WareHouse(WHaddress);

        uint256 _tokenIdOfCR = indexOfCRhash[BPHash];
        uint256 _tokenIdOfBP = wh.getTokenIdFrombBPhash(BPHash);

        require(canUnshelf(BPHash));
        address _owner = cr.ownerOf(_tokenIdOfCR);
        address _maker = cr.makerOf(_tokenIdOfCR);

        cr.burn(_owner, _tokenIdOfCR, _maker);
        delete indexOfCRhash[BPHash];
        delete CRhashOfCRTokenId[_maker][_tokenIdOfCR];

        wh.setLock(BPHash, false);

        emit Unshelf(_maker, _tokenIdOfBP, _tokenIdOfCR, BPHash);

    }


    // 如果以后换合约可能用到，要保证k，大于k以后的整数都没有被用作tokenId
    function setTokenId(uint256 k)
        public
        onlyAdmins
    {
        tokenId = k;
    }


    function haveShelf(string BPHash)
        public
        view
        returns(bool)
    {
        BP cr = BP(CRaddress);
        uint256 _tokenIdOfCR = indexOfCRhash[BPHash];
        if(cr.makerOf(_tokenIdOfCR) != address(0)) {
            return true;
        } else {
            return false;
        }
    }

    function getTokenIdOfCR(string BPHash)
        public
        view
        returns(uint256)
    {
        return indexOfCRhash[BPHash];    
    }

    function getCRhashOfCRTokenId(address _addr, uint256 _tokenId)
        public
        view
        returns(string)
    {
        return CRhashOfCRTokenId[_addr][_tokenId];    
    }    
   

    function getBPaddress()
        public
        view
        returns(address)
    {
        return BPaddress;
    }

    function getWHaddress()
        public
        view
        returns(address)
    {
        return WHaddress;
    }

    function getCRaddress()
        public
        view
        returns(address)
    {
        return CRaddress;
    }

    function getTokenId() 
        public
        view
        returns(uint256)
    {
        return tokenId;
    }

}

interface BP {
    function mint(address _to, uint256 _tokenId, address _maker) external;
    function burn(address _owner, uint256 _tokenId, address _maker) external;
    function totalSupply() external view returns (uint256);
    function exists(uint256 _tokenId) external view returns (bool _exists);    
    function makerOf(uint256 _tokenId) external view returns (address);
    function ownerOf(uint256 _tokenId) external view returns (address);
}

interface WareHouse {
    function getTokenIdFrombBPhash(string BPhash) external view returns(uint256);
    function setLock(string BPhash, bool isLock) external;
    function lockState(string BPhash) external view returns(bool);
}