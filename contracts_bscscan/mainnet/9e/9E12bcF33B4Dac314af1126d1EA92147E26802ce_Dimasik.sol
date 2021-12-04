/**
 *Submitted for verification at BscScan.com on 2021-12-04
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

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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

library SafeERC20 {
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(token.approve(spender, value));
    }
}

contract Dimasik is Owner{
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    string public IdoName;
    uint256 public SaleStart;
    uint256 public SaleEnd;
    uint256 public SaleFcfs;

    uint256 public RegistrationFee;
    
    uint256 public BaseAllocation;
    uint256 public MaxRaise;
    uint256 public TotalSupply;
    
    address public PaymentAddress;
    address public TokenAddress;
    
    IERC20 public ERC20Interface;
    
    struct user{
        bool Whitelist;
        uint256 Amount;
        bool Registered;
    }
    
    mapping(address => user) public UserPurchases;

    
    constructor(
        string memory _name,
        uint256 _saleStart,
        uint256 _saleEnd,
        uint256 _salefcfs,
        uint256 _baseAllocation,
        uint256 _maxRaise,
        uint256 _registrationFee,
        address _paymentAddress,
        address _tokenAddress
    ) public {
        IdoName=_name;
        require(_saleEnd > _saleStart,"Invalid date");
        SaleStart=_saleStart;
        SaleEnd=_saleEnd;
        SaleFcfs=_salefcfs;
        RegistrationFee=_registrationFee;
        require(_baseAllocation > 0, "Need Allocation");
        BaseAllocation=_baseAllocation;
        require(_maxRaise > 0, "Need max Raise");
        MaxRaise=_maxRaise;
        require(_paymentAddress != address(0), "Need payment address");
        PaymentAddress=_paymentAddress;
        require(_tokenAddress != address(0), "Need token address");
        TokenAddress = _tokenAddress;
        ERC20Interface = IERC20(TokenAddress);
    }
    
    function AddWhitelist(address[] memory users) external isOwner{
        for(uint i=0;i<users.length;i++)
        {
            UserPurchases[users[i]].Whitelist=true;
        }
    }
    
    function DelWhitelist(address[] memory users) external isOwner{
        for(uint i=0;i<users.length;i++)
        {
            UserPurchases[users[i]].Whitelist=false;
        }
    }

    function ChangeRegistrationFee(uint256 price) external isOwner{
        RegistrationFee=price;
    }

    function  Registration() public payable
    {
        require(block.timestamp <= SaleEnd, "Sale Ended");
        require(UserPurchases[msg.sender].Registered==false, "You are already registered!");
        require(msg.value>=RegistrationFee, "Incorrect registration fee!");
        address payable receiver = payable(getOwner());
        receiver.transfer(msg.value);
        //address(uint160(_owner)).transfer(msg.value);
        UserPurchases[msg.sender].Registered=true;
    }
    
    function BuyTokens(uint256 amount) external _hasAllowance(msg.sender, amount)
    {
        require(block.timestamp >= SaleStart, "Sale not started!");
        require(block.timestamp <= SaleEnd, "Sale Ended");
        require(UserPurchases[msg.sender].Registered==true, "You are not registred!");
        require(MaxRaise >= TotalSupply.add(amount), "Sale Ended(Max Raise)");
        if(block.timestamp < SaleFcfs)
             require(UserPurchases[msg.sender].Whitelist == true, "No address in the whitelist!!");
        require(UserPurchases[msg.sender].Amount.add(amount) <= BaseAllocation, "Amount greater than base allocation");
        TotalSupply=TotalSupply.add(amount);
        UserPurchases[msg.sender].Amount=UserPurchases[msg.sender].Amount.add(amount);
        ERC20Interface.safeTransferFrom(msg.sender, PaymentAddress, amount);
    }
    
    modifier _hasAllowance(address allower, uint256 amount) {
        uint256 ourAllowance = ERC20Interface.allowance(allower, address(this));
        require(amount <= ourAllowance, "Make sure to add enough allowance");
        _;
    }
}