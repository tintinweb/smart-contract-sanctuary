/**
 *Submitted for verification at BscScan.com on 2021-12-24
*/

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Owner {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() public view returns (address) {
        return owner;
    }
}



library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract DimasikAir is Owner{
    
    using SafeMath for uint256;
    string public IdoName;
    uint256 public SaleStart;
    uint256 public SaleEnd;
    uint256 public TotalSupply;

    
    mapping(address => bool) public Users;

    
    constructor(string memory _name,uint256 _saleStart,uint256 _saleEnd) public 
    {
        IdoName=_name;
        require(_saleEnd > _saleStart,"Invalid date");
        SaleStart=_saleStart;
        SaleEnd=_saleEnd;
    }
    
    function ChangeDates(uint256 start,uint256 end) external isOwner
    {
        SaleStart=start;
        SaleEnd=end;
    }

    function  Registration() public
    {
        require(block.timestamp <= SaleEnd, "Sale ended!");
        require(block.timestamp >= SaleStart, "Sale has not started!");
        require(Users[msg.sender]==false, "You are already registered!");
        TotalSupply=TotalSupply.add(1);
        Users[msg.sender]=true;
    }
}