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

contract WareHouse is Owned {
    using AddressUtils for address;
    
    mapping(address => mapping(uint256 => uint256)) depositOf; // 玩家在这个合约里面质押了多少ERC20

    // 代表AB种类的合约地址；
    address[] public addressOf;
    address public BPaddress;

    event AddABaddress(uint256 indexed _indexed, address _ABaddress);
    event DelABaddress(uint256 indexed _indexed, address _BeforeAddress, address _nowAddress, uint256 _length);
    event ChangeBPaddress(address _before, address _now);
    event Compose(uint256 _BPindex);
    event GetAB(address _ABaddress, address _toAddress, uint256 _amount);

    constructor() 
        public 
    {
        owner = msg.sender;
        admins[msg.sender] = true;
    }

    function addABaddress(address _ABaddress)
        public
        onlyAdmins
    {
        require(_ABaddress.isContract());
        addressOf.push(_ABaddress);

        emit AddABaddress(addressOf.length - 1, _ABaddress);
    }

    // 地址不要轻易改动，因为Oracle服务器是按照AB种类返回的且depositOf也是根据这个
    function delABaddress(uint256 _index, address _ABaddress)
        public
        onlyAdmins
    {
        require(addressOf[_index] == _ABaddress);
        addressOf[_index] = addressOf[addressOf.length - 1];
        delete addressOf[addressOf.length - 1];
        addressOf.length--;

        emit DelABaddress(_index, _ABaddress, addressOf[_index], addressOf.length);
    }

    function changeBPaddress(address _new)
        public
        onlyAdmins
    {
        require(_new.isContract());
        address _before = BPaddress;
        BPaddress = _new;
    
        emit ChangeBPaddress(_before, BPaddress);
    }

    function compose(string BPhash)
        public 
    {
        uint256[] memory arr = estimate(BPhash);

        require(checkBalance(arr));
        
        // 假设返回的不同AB使用数量和addressOf保存的AB地址是对应的
        for (uint256 i = 0; i < arr.length; i++) {
            ERC20 AB = ERC20(addressOf[i]);
            if(AB.transfer(this, arr[i])) {
                depositOf[msg.sender][i] = arr[i];
            }         
        }

        ERC721 BP = ERC721(BPaddress);
        uint256 _totalSupply = BP.totalSupply();
        uint256 _index = _totalSupply - 1;

        if(!BP.exists(_index)) {
            BP.mint(msg.sender, _index);
        }

        emit Compose(_index);

    }

    // oracle
    function estimate(string BPhash)
        internal
        view
        returns(uint256[])
    {
        uint256[] memory a;
        for (uint256 i = 0; i < 5; i++) {
            a[i] = ((i+1) * 1 ether);
        }

        return a;
    }

    function checkBalance(uint256[] _array)
        internal
        view
        returns(bool)
    {
        for(uint256 i = 0; i < _array.length; i++) {
            ERC20 AB = ERC20(addressOf[i]);
            if (AB.balanceOf(msg.sender) < _array[i]) {
                return false;
            } 
        }

        return true;
    }

    function getABsort() 
        public
        view
        returns(uint256)
    {
        return addressOf.length - 1;
    }

    function getERC20(address _ABaddress, address _toAddress, uint256 _amount)
        public
        onlyAdmins
    {
        ERC20 AB = ERC20(_ABaddress);
        AB.transfer(_toAddress, _amount);

        emit GetAB(_ABaddress, _toAddress, _amount);
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

interface ERC721 {
    function mint(address _to, uint256 _tokenId) external;
    function totalSupply() external view returns (uint256);
    function exists(uint256 _tokenId) external view returns (bool _exists);    
}