pragma solidity ^0.4.13;

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract IInvestorList {
    string public constant ROLE_REGD = "regd";
    string public constant ROLE_REGCF = "regcf";
    string public constant ROLE_REGS = "regs";
    string public constant ROLE_UNKNOWN = "unknown";

    function inList(address addr) public view returns (bool);
    function addAddress(address addr, string role) public;
    function getRole(address addr) public view returns (string);
    function hasRole(address addr, string role) public view returns (bool);
}

contract Ownable {
    address public owner;
    address public newOwner;

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Starts the 2-step process of changing ownership. The new owner
     * must then call `acceptOwnership()`.
     */
    function changeOwner(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    /**
     * @dev Completes the process of transferring ownership to a new owner.
     */
    function acceptOwnership() public {
        if (msg.sender == newOwner) {
            owner = newOwner;
            newOwner = 0;
        }
    }

}

contract InvestorList is Ownable, IInvestorList {
    event AddressAdded(address addr, string role);
    event AddressRemoved(address addr, string role);

    mapping (address => string) internal investorList;

    /**
     * @dev Throws if called by any account that&#39;s not investorListed.
     * @param role string
     */
    modifier validRole(string role) {
        require(
            keccak256(bytes(role)) == keccak256(bytes(ROLE_REGD)) ||
            keccak256(bytes(role)) == keccak256(bytes(ROLE_REGCF)) ||
            keccak256(bytes(role)) == keccak256(bytes(ROLE_REGS)) ||
            keccak256(bytes(role)) == keccak256(bytes(ROLE_UNKNOWN))
        );
        _;
    }

    /**
     * @dev Getter to determine if address is in investorList.
     * @param addr address
     * @return true if the address was added to the investorList, false if the address was already in the investorList
     */
    function inList(address addr)
        public
        view
        returns (bool)
    {
        if (bytes(investorList[addr]).length != 0) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Getter for address role if address is in list.
     * @param addr address
     * @return string for address role
     */
    function getRole(address addr)
        public
        view
        returns (string)
    {
        require(inList(addr));
        return investorList[addr];
    }

    /**
     * @dev Returns a boolean indicating if the given address is in the list
     *      with the given role.
     * @param addr address to check
     * @param role role to check
     * @ return boolean for whether the address is in the list with the role
     */
    function hasRole(address addr, string role)
        public
        view
        returns (bool)
    {
        return keccak256(bytes(role)) == keccak256(bytes(investorList[addr]));
    }

    /**
     * @dev Add single address to the investorList.
     * @param addr address
     * @param role string
     */
    function addAddress(address addr, string role)
        onlyOwner
        validRole(role)
        public
    {
        investorList[addr] = role;
        emit AddressAdded(addr, role);
    }

    /**
     * @dev Add multiple addresses to the investorList.
     * @param addrs addresses
     * @param role string
     */
    function addAddresses(address[] addrs, string role)
        onlyOwner
        validRole(role)
        public
    {
        for (uint256 i = 0; i < addrs.length; i++) {
            addAddress(addrs[i], role);
        }
    }

    /**
     * @dev Remove single address from the investorList.
     * @param addr address
     */
    function removeAddress(address addr)
        onlyOwner
        public
    {
        // removeRole(addr, ROLE_WHITELISTED);
        require(inList(addr));
        string memory role = investorList[addr];
        investorList[addr] = "";
        emit AddressRemoved(addr, role);
    }

    /**
     * @dev Remove multiple addresses from the investorList.
     * @param addrs addresses
     */
    function removeAddresses(address[] addrs)
        onlyOwner
        public
    {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (inList(addrs[i])) {
                removeAddress(addrs[i]);
            }
        }
    }

}

interface ISecuritySale {
    function setLive(bool newLiveness) external;
    function setInvestorList(address _investorList) external;
}

contract SecuritySale is Ownable {

    bool public live;        // sale is live right now
    IInvestorList public investorList; // approved contributors

    event SaleLive(bool liveness);
    event EtherIn(address from, uint amount);
    event StartSale();
    event EndSale();

    constructor() public {
        live = false;
    }

    function setInvestorList(address _investorList) public onlyOwner {
        investorList = IInvestorList(_investorList);
    }

    function () public payable {
        require(live);
        require(investorList.inList(msg.sender));
        emit EtherIn(msg.sender, msg.value);
    }

    // set liveness
    function setLive(bool newLiveness) public onlyOwner {
        if(live && !newLiveness) {
            live = false;
            emit EndSale();
        }
        else if(!live && newLiveness) {
            live = true;
            emit StartSale();
        }
    }

    // withdraw all of the Ether to owner
    function withdraw() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    // withdraw some of the Ether to owner
    function withdrawSome(uint value) public onlyOwner {
        require(value <= address(this).balance);
        msg.sender.transfer(value);
    }

    // withdraw tokens to owner
    function withdrawTokens(address token) public onlyOwner {
        ERC20Basic t = ERC20Basic(token);
        require(t.transfer(msg.sender, t.balanceOf(this)));
    }

    // send received tokens to anyone
    function sendReceivedTokens(address token, address sender, uint amount) public onlyOwner {
        ERC20Basic t = ERC20Basic(token);
        require(t.transfer(sender, amount));
    }
}