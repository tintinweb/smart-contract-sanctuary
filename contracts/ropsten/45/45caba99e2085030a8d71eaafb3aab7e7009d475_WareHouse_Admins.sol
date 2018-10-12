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

contract WareHouse_Admins is Owned {
    using AddressUtils for address;
    using SafeMath for uint256;

    mapping(address => mapping(address => uint256)) depositOf; // 玩家在这个合约里面质押了多少ERC20
    mapping(address => mapping(string => mapping(address => uint256))) usedOf; // 某个玩家在某个BP上花费某种AB的数量

    mapping(string => bool) isLock; // 当BP上了版权中心的时候

    mapping(string => address) addressOf; // 代表AB种类的合约地址；
    string[] ABname;    // 要提供getAllOf


    string[] allBPs;
    mapping(string => address) BPmaker; // BPhash => 制造者
    mapping(address => uint256) makedBPsCount;  // 制造者 => 他制造了多少BP
    mapping(address => string[]) makedBPs;  // 制作者 => 他制造的所有BP的BPhash
    mapping(string => uint256) makedBPsIndex;   // BPhash => 该BP在制造者所有BP中(makedBPs)的索引
    mapping(string => uint256) allBPsIndex; // BPhash => 该BP在所有BP中(allBPs)的索引


    event AddABaddress(uint256 indexed _totalOfABsorts, address _ABaddress, string _ABname);
    event DelABaddress(uint256 indexed _indexed, address _delAddress, string _delName, uint256 _totalOfABsorts);
    event ChangeABaddress(string _ABname, address _beforeAddress, address _newAddress);


    event ChangeBPaddress(address _before, address _now);
    event Compose(address _BPmaker, string _BPhash);
    event DeCompose(address _BPmaker, string _BPhash);
    
    event WithdrawAB(address _ABaddress, address _toAddress, uint256 _amount);

    constructor() 
        public 
    {
        owner = msg.sender;
        admins[msg.sender] = true;
    }

    function addABaddress(address _ABaddress,string _ABname)
        public
        onlyAdmins
    {
        require(_ABaddress.isContract());
        require(addressOf[_ABname] == address(0));

        addressOf[_ABname] = _ABaddress;
        ABname.push(_ABname);
        

        emit AddABaddress(ABname.length, _ABaddress, _ABname);
    }

    function delABaddress(string _ABname)
        public
        onlyAdmins
    {
        uint256 _length = ABname.length;

        // length < 100， 遍历是可以接受的
        for(uint256 i = 0; i < _length; i++) {
            if(keccak256(abi.encodePacked(ABname[i])) == keccak256(abi.encodePacked(_ABname))) {
                ABname[i] = ABname[_length-1];
                delete ABname[_length-1];
                ABname.length = _length.sub(1);

                address _addr = addressOf[_ABname];             
                delete addressOf[_ABname];

                emit DelABaddress(i, _addr, _ABname, ABname.length);
                
                break;
            }
        }
    }

    function changeABaddress(string _ABname, address _newAddress)
        public
        onlyAdmins
    {
        require(_newAddress.isContract());
        address _addr = addressOf[_ABname];
        require(_addr != address(0));

        addressOf[_ABname] = _newAddress;

        emit ChangeABaddress(_ABname, _addr, _newAddress);
    }

    function getABsort() 
        public
        view
        returns(uint256)
    {
        return ABname.length;
    }    

    function getABaddressByName(string _ABname)
        public
        view
        returns(address)
    {
        return addressOf[_ABname];
    }


    function getABname(uint256 _index)
        public
        view
        returns(string)
    {
        return ABname[_index];
    }

    function getABaddressByIndex(uint256 _index)
        public
        view
        returns(address)
    {
        string memory _addr = getABname(_index);
        return getABaddressByName(_addr);
    }    

    function getAllABaddress()
        public
        view
        returns(address[])
    {
        address[] memory addresses;
        string memory _tempName;
        for(uint256 i = 0; i < ABname.length; i++) {
            _tempName = ABname[i];
            addresses[i] = addressOf[_tempName];
        }

        return addresses;
    }


    // 要求输入的cost元素的顺序和ABname里面的AB是一一对应的
    function compose(string BPhash, address maker, uint256[] cost)
        public
        onlyAdmins
    {
        require(!isEmptyString(BPhash));
        require(maker != address(0));

        uint256[] memory arr = cost;

        require(canCompose(BPhash, cost, maker));

        address _tempAddress;
            
        // 假设返回的不同AB使用数量和addressOf保存的AB地址是对应的。因此arr的长度肯定和addressOf长度一致。
        for (uint256 i = 0; i < arr.length; i++) {
            _tempAddress = getABaddressByIndex(i);
            require(_tempAddress.isContract());

            ERC20 AB = ERC20(_tempAddress);
            AB.transferFrom(maker,this, arr[i]);
            depositOf[maker][_tempAddress] = depositOf[maker][_tempAddress].add(arr[i]);
            usedOf[maker][BPhash][_tempAddress] = usedOf[maker][BPhash][_tempAddress].add(arr[i]);
        }

        _mint(BPhash, maker);

        emit Compose(maker, BPhash);
    }

    function _mint(string BPhash, address maker)
        internal
    {
        require(BPmaker[BPhash] == address(0));
        
        BPmaker[BPhash] = maker;
        makedBPsCount[maker] = makedBPsCount[maker].add(1);

        uint256 lengthOfmaked = makedBPs[maker].push(BPhash);
        makedBPsIndex[BPhash] = lengthOfmaked.sub(1);

        allBPsIndex[BPhash] = allBPs.length;        
        allBPs.push(BPhash);

        require(makedBPsCount[maker] == makedBPs[maker].length);
    }

    function canCompose(string BPhash, uint256[] cost, address maker)
        public
        view
        returns(bool)
    {
        if(checkBalance(cost, maker) && !isEmptyString(BPhash) && !exists(BPhash) && cost.length == ABname.length) {
            return true;
        } else {
            return false;
        }        
    }

    function deCompose(string BPhash)
        public
    {
        require(canDeCompose(BPhash));

        address _tempAddress;

        for (uint256 i = 0; i < ABname.length; i++) {
            _tempAddress = getABaddressByIndex(i);
            require(_tempAddress.isContract());

            ERC20 AB = ERC20(_tempAddress);
            AB.transfer(msg.sender, usedOf[msg.sender][BPhash][_tempAddress]);
            depositOf[msg.sender][_tempAddress] = depositOf[msg.sender][_tempAddress].sub(usedOf[msg.sender][BPhash][_tempAddress]);
            usedOf[msg.sender][BPhash][_tempAddress] = 0;
        }


        _burn(BPhash, msg.sender);

        emit DeCompose(msg.sender, BPhash);     
    }

    function _burn(string BPhash, address _maker)
        internal
    {
        makedBPsCount[_maker] = makedBPsCount[_maker].sub(1);
        delete BPmaker[BPhash];

        // 维护该用户的BPhash相关数据
        uint256 BPindex = makedBPsIndex[BPhash];
        uint256 lastBPindex = makedBPs[_maker].length.sub(1);
        string memory lastBP = makedBPs[_maker][lastBPindex];

        makedBPs[_maker][BPindex] = lastBP;
        delete makedBPs[_maker][BPindex];

        makedBPs[_maker].length = makedBPs[_maker].length.sub(1);
        delete makedBPsIndex[BPhash];
        makedBPsIndex[lastBP] = BPindex;

        require(makedBPsCount[_maker] == makedBPs[_maker].length);


        // 维护全网的BPhash相关数据
        uint256 BPindexInAll = allBPsIndex[BPhash];
        uint256 lastBPindexInAll = allBPs.length.sub(1);
        string memory lastBPinAll = allBPs[lastBPindexInAll];

        allBPs[BPindexInAll] = lastBPinAll;
        delete allBPs[lastBPindexInAll];

        allBPs.length = allBPs.length.sub(1);
        delete allBPsIndex[BPhash];
        allBPsIndex[lastBPinAll] = BPindexInAll;

    }

    function getERC20(address _ABaddress, address _toAddress, uint256 _amount)
        public
        onlyAdmins
    {
        ERC20 AB = ERC20(_ABaddress);
        AB.transfer(_toAddress, _amount);

        emit WithdrawAB(_ABaddress, _toAddress, _amount);
    }

    function setLock(string BPhash, bool lock)
        public
        onlyAdmins
    {
        isLock[BPhash] = lock;
    }
        

    function canDeCompose(string BPhash)
        public
        view
        returns(bool)
    {
        if(exists(BPhash) && msg.sender == BPmaker[BPhash] && !isLock[BPhash]) {
            return true;
        } else {
            return false;
        }
    }

    function lockState(string BPhash)
        public
        view
        returns(bool)
    {
        return isLock[BPhash];    
    }


    function checkBalance(uint256[] _array, address maker)
        public
        view
        returns(bool)
    {
        address _tempAddress;
        for(uint256 i = 0; i < _array.length; i++) {
            _tempAddress = getABaddressByIndex(i);
            require(_tempAddress.isContract());

            ERC20 AB = ERC20(_tempAddress);
            if (AB.balanceOf(maker) < _array[i]) {
                return false;
            } 
        }
        return true;
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

    function exists(string BPhash)
        public
        view
        returns(bool)
    {
        address maker = BPmaker[BPhash];
        return maker != address(0);
    }

    function amountOfBPs(address _maker)
        public
        view
        returns(uint256 _balance)
    {
        return makedBPsCount[_maker];
    }

    function makerOf(string BPhash)
        public
        view
        returns(address)
    {
        return BPmaker[BPhash];
    }

    function BPofMakerByIndex(address _maker, uint256 _index)
        public
        view
        returns(string)
    {
        return makedBPs[_maker][_index];
    }

}

interface  ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) external returns (bool success);
    function approve(address spender, uint256 tokens) external returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}