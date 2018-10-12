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


contract CopyrightCenter is Owned {
    using AddressUtils for address;
    using SafeMath for uint256;

    address WHaddress; // WareHouse

    event Shelf(address _maker, string _CRHash);
    event Unshelf(address _maker, string _CRHash);

    // CRhash IS BPhash in CopyrightCenter
    string[] allCRs;
    mapping(string => address) CRmaker; // CRhash => 制造者
    mapping(address => uint256) makedCRsCount;  // 制造者 => 他制造了多少CR
    mapping(address => string[]) makedCRs;  // 制作者 => 他制造的所有CR的CRhash
    mapping(string => uint256) makedCRsIndex;   // CRhash => 该CR在制造者所有CR中(makedCRs)的索引
    mapping(string => uint256) allCRsIndex; // CRhash => 该CR在所有CR中(allCRs)的索引


    constructor()
        public
    {
        owner = msg.sender;
        admins[msg.sender] = true;
    }



    function setWHaddress(address _addr)
        public
        onlyAdmins
    {
        require(_addr.isContract());
        WHaddress = _addr;
    }


    function canShelf(string _CRhash, address _BPmaker)
        public
        view
        returns(bool)
    {
        WareHouse wh = WareHouse(WHaddress);

        if(wh.exists(_CRhash) && wh.makerOf(_CRhash) == _BPmaker && !exists(_CRhash) && !wh.lockState(_CRhash) && !isEmptyString(_CRhash)) {
            return true;
        } else {
            return false;
        }
    }

    function shelf(string _CRhash, address _CRmaker)
        public
        onlyAdmins
    {
        require(canShelf(_CRhash, _CRmaker));
        WareHouse wh = WareHouse(WHaddress);

        wh.setLock(_CRhash, true);


        _mint(_CRhash, _CRmaker);

        
        emit Shelf(_CRmaker, _CRhash);
        
    }

    function _mint(string _CRhash, address maker)
        internal
    {
        require(CRmaker[_CRhash] == address(0));
        
        CRmaker[_CRhash] = maker;
        makedCRsCount[maker] = makedCRsCount[maker].add(1);

        uint256 lengthOfmaked = makedCRs[maker].push(_CRhash);
        makedCRsIndex[_CRhash] = lengthOfmaked.sub(1);

        allCRsIndex[_CRhash] = allCRs.length;        
        allCRs.push(_CRhash);

        require(makedCRsCount[maker] == makedCRs[maker].length);
    }    
    
    function canUnshelf(string _CRhash, address _CRmaker)
        public
        view
        returns(bool)
    {
        WareHouse wh = WareHouse(WHaddress);

        if(exists(_CRhash) && _CRmaker == CRmaker[_CRhash] && wh.lockState(_CRhash)) {
            return true;
        } else {
            return false;
        }
    }


    function unshelf(string _CRhash)
        public
        onlyAdmins
    {
        WareHouse wh = WareHouse(WHaddress);

        address _maker = makerOf(_CRhash);

        require(canUnshelf(_CRhash, _maker));

        _burn(_CRhash, _maker);

        wh.setLock(_CRhash, false);

        emit Unshelf(_maker, _CRhash);

    }

    function _burn(string _CRhash, address _maker)
        internal
    {
        makedCRsCount[_maker] = makedCRsCount[_maker].sub(1);
        delete CRmaker[_CRhash];

        // 维护该用户的CRhash相关数据
        uint256 CRindex = makedCRsIndex[_CRhash];
        uint256 lastCRindex = makedCRs[_maker].length.sub(1);
        string memory lastCR = makedCRs[_maker][lastCRindex];

        makedCRs[_maker][CRindex] = lastCR;
        delete makedCRs[_maker][CRindex];

        makedCRs[_maker].length = makedCRs[_maker].length.sub(1);
        delete makedCRsIndex[_CRhash];
        makedCRsIndex[lastCR] = CRindex;

        require(makedCRsCount[_maker] == makedCRs[_maker].length);


        // 维护全网的CRhash相关数据
        uint256 CRindexInAll = allCRsIndex[_CRhash];
        uint256 lastCRindexInAll = allCRs.length.sub(1);
        string memory lastCRinAll = allCRs[lastCRindexInAll];

        allCRs[CRindexInAll] = lastCRinAll;
        delete allCRs[lastCRindexInAll];

        allCRs.length = allCRs.length.sub(1);
        delete allCRsIndex[_CRhash];
        allCRsIndex[lastCRinAll] = CRindexInAll;

    }    

    function amountOfCRs(address _maker)
        public
        view
        returns(uint256 _balance)
    {
        return makedCRsCount[_maker];
    }

    function makerOf(string CRhash)
        public
        view
        returns(address)
    {
        return CRmaker[CRhash];
    }

    function CRofMakerByIndex(address _maker, uint256 _index)
        public
        view
        returns(string)
    {
        return makedCRs[_maker][_index];
    }


    function haveShelf(string _CRhash)
        public
        view
        returns(bool)
    {
        if(makerOf(_CRhash) != address(0)) {
            return true;
        } else {
            return false;
        }
    }


    function getWHaddress()
        public
        view
        returns(address)
    {
        return WHaddress;
    }

    function isEmptyString(string _string)
        public
        pure
        returns(bool)
    {
        bytes memory bytesOfString = bytes(_string);

        if(bytesOfString.length == 0) {
            return true;
        } else {
            return false;
        }
    }

    function exists(string _CRhash)
        public
        view
        returns(bool)
    {
        address maker = CRmaker[_CRhash];
        return maker != address(0);
    }



}


interface WareHouse {
    function setLock(string BPhash, bool isLock) external;
    function lockState(string BPhash) external view returns(bool);
    function exists(string BPhash) external view returns(bool);
    function makerOf(string BPhash) external view returns(address);
}