/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

pragma solidity 0.8.3;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract ERC20 {
    function totalSupply() external virtual view returns (uint256);
    function balanceOf(address account) external virtual view returns (uint256);
    function transfer(address recipient, uint256 amount) external virtual returns (bool);
    function allowance(address owner, address spender) external virtual view returns (uint256);
    function approve(address spender, uint256 amount) external virtual returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external virtual returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// CONTRACT FOR UNISWAP-STYLE AIRDROPS

contract Airdrop {
    using SafeMath for uint256;
    
    address private constant dgfAddress = address(0x0);
    
    ERC20   public token                = ERC20(dgfAddress); // Digifox Token
    bool    public hasAllocated         = false;
    
    address public owner;
    uint256 private reward;
    
    mapping(address => uint256) public eligableAirdroppers;
    mapping(address => bool) public airdropAdmins;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner may use this function.");
        _;
    }
    
    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner || airdropAdmins[msg.sender], "Only the owner or admins may use this function.");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /***********************************************************************
        Function:   resetAirdrop()
        Args:       None
        Returns:    None
        Notes:      Used by the owner to reset an airdrop incase of error.
    ***********************************************************************/
    
    function resetAirdrop() public onlyOwnerOrAdmin {
        hasAllocated = false;
    }
    
    /***********************************************************************
        Function:   addAdmin()
        Args:       address _admin a new admin.
        Returns:    None
        Notes:      Used by the owner to add an admin for easy airdrop 
                        functionality maintenance.
    ***********************************************************************/
    
    function addAdmin(address _admin) public onlyOwner {
        airdropAdmins[_admin] = true;
    }
    
    /***********************************************************************
        Function:   revokeAdmin()
        Args:       address _admin of a previous admin.
        Returns:    None
        Notes:      Used by the owner to remove an admin for easy airdrop 
                        functionality maintenance.
    ***********************************************************************/
    
    function revokeAdmin(address _admin) public onlyOwnerOrAdmin {
        airdropAdmins[_admin] = false;
    }
    
    /***********************************************************************
        Function:   setAirdropAllocation()
        Args:       address[] memory _recipients the qualified addresses.
        Returns:    None
        Notes:      Used to allocate funds to be redeemed at a later time by
                        the calling wallet.
    ***********************************************************************/
    
    function setAirdropAllocation(address[] memory _recipients) public onlyOwnerOrAdmin {
        require(!hasAllocated);
        hasAllocated = true;
        
        uint256 test_reward = 2500;
        reward = test_reward.div(_recipients.length);
        // TODO: UNCOMMENT BEFORE PROD DEPLOYMENT!!!
        // reward = token.balanceOf(address(this)).div(_recipients.length);
        
        for(uint256 i = 0; i < _recipients.length; i++) {
            eligableAirdroppers[_recipients[i]] = reward;
        }
    }
    
    /***********************************************************************
        Function:   redeemAirdrop()
        Args:       None
        Returns:    None
        Notes:      Used to redeem your airdop.
    ***********************************************************************/
    
    function redeemAirdrop() public {
        require(eligableAirdroppers[msg.sender] > 0, "There are no tokens left to redeem.");
        token.transfer(msg.sender, eligableAirdroppers[msg.sender]);
        eligableAirdroppers[msg.sender] = 0;
    }
    
    /***********************************************************************
        Function:   redeemAirdropForAnother()
        Args:       address _other, the user you are redeeming for.
        Returns:    None
        Notes:      Used to redeem the airdrop for another user. Only admins
                        or the owner may use this function.
    ***********************************************************************/
    
    function redeemAirdropForAnother(address _other) public onlyOwnerOrAdmin {
        require(eligableAirdroppers[_other] > 0, "There are no tokens left to redeem.");
        token.transfer(_other, eligableAirdroppers[_other]);
        eligableAirdroppers[_other] = 0;
    }
    
    /***********************************************************************
        Function:   checkReward()
        Args:       None
        Returns:    None
        Notes:      Used to determine if the calling address has a reward.
    ***********************************************************************/
    
    function checkReward() public view returns (uint256 _reward) {
        return eligableAirdroppers[msg.sender];
    }
    
    /***********************************************************************
        Function:   checkRewardOfAddress()
        Args:       address _check the user you are checking for
        Returns:    None
        Notes:      Used to determine if the calling address has a reward. 
                        Only admins or the owner may use this function.
    ***********************************************************************/
    
    function checkRewardOfAddress(address _check) public view onlyOwnerOrAdmin returns (uint256 _reward) {
        return eligableAirdroppers[_check];
    }
    
    
    function test_SETREWARDOFADDRESS(address _set, uint256 _amount) public onlyOwnerOrAdmin {
        eligableAirdroppers[_set] = _amount;
    }
}