pragma solidity 0.4.24;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function decimals() public view returns (uint);
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract TokenLocker is Ownable {
    
    ERC20 public token = ERC20(0x611171923b84185e9328827CFAaE6630481eCc7a); // STM address
    
    // timestamp when token release is enabled
    uint256 public releaseTimeFund = 1537833600; // 25 сентября 2018
    uint256 public releaseTimeTeamAdvisorsPartners = 1552348800; // 12 марта 2019
    
    address public ReserveFund = 0xC5fed49Be1F6c3949831a06472aC5AB271AF89BD; // 18 600 000
    uint public ReserveFundAmount = 18600000 ether;
    
    address public AdvisorsPartners = 0x5B5521E9D795CA083eF928A58393B8f7FF95e098; // 3 720 000
    uint public AdvisorsPartnersAmount = 3720000 ether;
    
    address public Team = 0x556dB38b73B97954960cA72580EbdAc89327808E; // 4 650 000
    uint public TeamAmount = 4650000 ether;
    
    function unlockFund () public onlyOwner {
        require(releaseTimeFund <= block.timestamp);
        require(ReserveFundAmount > 0);
        uint tokenBalance = token.balanceOf(this);
        require(tokenBalance >= ReserveFundAmount);
        
        if (token.transfer(ReserveFund, ReserveFundAmount)) {
            ReserveFundAmount = 0;
        }
    }
    
    function unlockTeamAdvisorsPartnersTokens () public onlyOwner {
        require(releaseTimeTeamAdvisorsPartners <= block.timestamp);
        require(AdvisorsPartnersAmount > 0);
        require(TeamAmount > 0);
        uint tokenBalance = token.balanceOf(this);
        require(tokenBalance >= AdvisorsPartnersAmount + TeamAmount);
        
        if (token.transfer(AdvisorsPartners, AdvisorsPartnersAmount)) {
            AdvisorsPartnersAmount = 0;
        }
        
        if (token.transfer(Team, TeamAmount)) {
            TeamAmount = 0;
        }
    }
}