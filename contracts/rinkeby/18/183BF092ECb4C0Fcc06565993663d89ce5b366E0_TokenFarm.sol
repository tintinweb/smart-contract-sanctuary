/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

pragma solidity ^0.5.0;

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

contract ERC20 {
    function totalSupply() public returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract TokenFarm {
    using SafeMath for uint256;
    string public name = "JelloSwap Farm";
    address payable public owner;
    uint256 public priceOfOnePFAN;
    uint256 public dividerForPrice;
    ERC20 public PFANToken;

    address[] public stakers;
    mapping(address => uint) public stakingBalance;
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public isStaking;

    constructor() public {
        //ToDo: set an array to save the multiple erc20 addresses. 
        //address(0xE0ea38B84b976ee9159833467aC41C0FA713f141); 
        //address PFANToken_local_address = 0x00a92ae31fb891BA4Fa9e372Fa5159D6DCBD5259;
        //address PFANToken_ropsten_address = address(0x053C6586A846510b5ABe3dfC6d1Ff046d8897fDf);
        address PFANToken_main_address = address(0xd842e7C127DB4CE5F9A37769Fd898CF3bFF61BF9);

        PFANToken = ERC20(PFANToken_main_address);
        owner = msg.sender;
        priceOfOnePFAN = uint256(14);
        dividerForPrice = uint256(1000000);
    }

    function getPFANLeftInExchange() public view returns(uint count) {
        return PFANToken.balanceOf(address(this));
    }

    function getOwnerAddress() public view returns(address theAddress) {
        return owner;
    }

    function updateTokenPrice(uint _pricePerToken) public {
        require(msg.sender == owner, "caller must be the owner");

        // Require amount greater than 0
        require(_pricePerToken > uint256(12), "amount must be over uint256(14)");

        priceOfOnePFAN = uint256(_pricePerToken);
    }

    function stakeTokens(uint _amount) public {
        require(msg.sender == owner, "caller must be the owner");

        // Require amount greater than 0
        require(_amount > 0, "amount cannot be 0");

        // Trasnfer Mock Dai tokens to this contract for staking
        PFANToken.transferFrom(msg.sender, address(this), _amount);

        // Update staking balance
        stakingBalance[msg.sender] = stakingBalance[msg.sender] + _amount;

        // Add user to stakers array *only* if they haven't staked already
        if(!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
        }

        // Update staking status
        isStaking[msg.sender] = true;
        hasStaked[msg.sender] = true;
    }

    // Unstaking Tokens (Withdraw)
    function unstakeTokens() public {
        require(msg.sender == owner, "caller must be the owner");
        // Fetch staking balance
        uint balance = PFANToken.balanceOf(address(this));

        // Require amount greater than 0
        require(balance > 0, "staking balance cannot be 0");

        // Transfer tokens to this contract for staking
        PFANToken.transfer(msg.sender, balance);

        // Reset staking balance
        stakingBalance[msg.sender] = 0;

        // Update staking status
        isStaking[msg.sender] = false;
    }

    function purchasePFANTokenWithEth () public payable {
        require(PFANToken.balanceOf(address(this)) > 0, "token amount cannot be 0");
        require(msg.value > 0, "msg.value cannot be 0");
        // Transfer depending on price
        // Todo: use safe math

        uint256 amountPFANbought = dividerForPrice.mul(msg.value.div(priceOfOnePFAN));
        require(amountPFANbought < PFANToken.balanceOf(address(this)), "amountPFANbought must be smaller than balance");

        //  Transfer PFAN token to the sender
        PFANToken.transfer(msg.sender, amountPFANbought);

        // Transfer
        owner.transfer(msg.value);
    }
}