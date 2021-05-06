/**
 *Submitted for verification at Etherscan.io on 2021-05-05
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
    
    bool    public hasAllocated         = false;
    uint256 public decimals             = 18;
    
    address public owner;
    uint256 public numAirdroppers;
    ERC20   public token;
    address public dgfAddress;
    uint256 public reward;
    
    mapping(address => bool) public eligableAirdroppers;
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
        Function:   setDGFAddress()
        Args:       address _dgf the address of DGF token.
        Returns:    None
        Notes:      Used for trasnferring tokens.
    ***********************************************************************/
    
    function setDGFAddress(address _dgf) public onlyOwnerOrAdmin {
        dgfAddress = _dgf;
        token = ERC20(dgfAddress);
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
        Function:   setAirdropReward()
        Args:       uint256 _reward the reward to send to each address.
        Returns:    None
        Notes:      Used to set the airdrop amount.
    ***********************************************************************/
    
    function setAirdropReward(uint256 _reward) public onlyOwnerOrAdmin {
        reward = _reward;
    }
    
    /***********************************************************************
        Function:   setAirdropAllocation()
        Args:       address[] memory _recipients the qualified addresses.
        Returns:    None
        Notes:      Used to allocate funds to be redeemed at a later time by
                        the calling wallet.
    ***********************************************************************/
    
    function setAirdropAllocation(address[] memory _recipients) public onlyOwnerOrAdmin {
        //require(!hasAllocated);
        //hasAllocated = true;
        
        // uint256 test_reward = 250 * 10**decimals;
        // reward = test_reward.div(_recipients.length);
        // TODO: UNCOMMENT BEFORE PROD DEPLOYMENT!!!
        // reward = token.balanceOf(address(this)).div(_recipients.length);
        
        for(uint256 i = 0; i < _recipients.length; i++) {
            eligableAirdroppers[_recipients[i]] = true;
        }
    }
    
    /***********************************************************************
        Function:   redeemAirdrop()
        Args:       None
        Returns:    None
        Notes:      Used to redeem your airdop.
    ***********************************************************************/
    
    function redeemAirdrop() public {
        require(eligableAirdroppers[msg.sender], "There are no tokens left to redeem.");
        token.transfer(msg.sender, reward);
        eligableAirdroppers[msg.sender] = false;
    }
    
    /***********************************************************************
        Function:   redeemAirdrop()
        Args:       address _other, the user you are redeeming for.
        Returns:    None
        Notes:      Used to redeem the airdrop for another user. 
    ***********************************************************************/
    
    function redeemAirdrop(address _other) public {
        require(eligableAirdroppers[_other], "There are no tokens left to redeem.");
        token.transfer(_other, reward);
        eligableAirdroppers[_other] = false;
    }
    
    /***********************************************************************
        Function:   checkReward()
        Args:       None
        Returns:    None
        Notes:      Used to determine if the calling address has a reward.
    ***********************************************************************/
    
    function checkReward() public view returns (uint256 _reward) {
        if (eligableAirdroppers[msg.sender]) return reward;
        else return 0;
    }
    
    /***********************************************************************
        Function:   checkRewardOfAddress()
        Args:       address _check the user you are checking for
        Returns:    None
        Notes:      Used to determine if the passed address has a reward.
    ***********************************************************************/
    
    function checkReward(address _check) public view returns (uint256 _reward) {
        if (eligableAirdroppers[_check]) return reward;
        else return 0;
    }
}