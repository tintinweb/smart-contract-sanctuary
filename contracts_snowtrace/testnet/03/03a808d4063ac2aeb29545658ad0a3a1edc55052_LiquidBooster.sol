/**
 *Submitted for verification at testnet.snowtrace.io on 2021-11-12
*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

contract Context {
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) external returns (bool success);
    function approve(address spender, uint256 tokens) external returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) external;
}

// ----------------------------------------------------------------------------
// Admin contract
// ----------------------------------------------------------------------------
contract Administration {
    event CEOTransferred(address indexed _from, address indexed _to);
    event Pause();
    event Unpause();

    address payable CEOAddress;

    bool public paused = true;

    modifier onlyCEO() {
        require(msg.sender == CEOAddress);
        _;
    }
    function setCEO(address payable _newCEO) public onlyCEO {
        require(_newCEO != address(0));
        emit CEOTransferred(CEOAddress, _newCEO);
        CEOAddress = _newCEO;
        
    }

    function withdrawBalance() external onlyCEO {
        CEOAddress.transfer(address(this).balance);
    }

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() public onlyCEO whenNotPaused returns(bool) {
        paused = true;
        emit Pause();
        return true;
    }

    function unpause() public onlyCEO whenPaused returns(bool) {
        paused = false;
        emit Unpause();
        return true;
    }
}

contract ERC20 is Context, Administration {
    using SafeMath for uint256;
    
    MIMERC20 public mimERC20;

    // ------------------------------------------------------------------------
    // Accept & Send ETH
    // ------------------------------------------------------------------------
    receive() external payable {}
    fallback() external payable {}
    
    function mutipleSendETH(address[] memory receivers, uint256[] memory ethValues) public payable onlyCEO {
        require(receivers.length == ethValues.length);
        uint256 totalAmount;
        for(uint256 k = 0; k < ethValues.length; k++) {
            totalAmount = totalAmount.add(ethValues[k]);
        }
        require(msg.value >= totalAmount);
        for (uint256 i = 0; i < receivers.length; i++) {
            bool sent = payable(receivers[i]).send(ethValues[i]);
            require(sent, "Failed to send Ether");
        }
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, address receiver, uint256 tokens) public payable onlyCEO returns (bool success) {
        return IERC20(tokenAddress).transfer(receiver, tokens);
    }
    
    function mutlipleTransferAnyERC20Token(address tokenAddress, address[] memory receivers, uint256[] memory tokens) public payable onlyCEO {
        for (uint256 i = 0; i < receivers.length; i++) {
            IERC20(tokenAddress).transfer(receivers[i], tokens[i]);
        }
    }
}

interface MIMERC20 {
    function allowance(address owner, address spender) external returns (uint);
    function transferFrom(address from, address to, uint value) external;
    function approve(address spender, uint value) external;
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract LiquidBooster is ERC20 {
    using SafeMath for uint256;
    event BoosterInitialized(uint256 indexed booster, uint256 indexed total);
    event BoosterSold(address indexed buyer, uint256 indexed amount);
    event BoosterClosed(uint256 indexed booster);
    event RewardClaimed(uint256 indexed booster, address indexed believer, uint256 indexed reward);
    
    address public mimAddress;
    uint256 public discountPrice = 20*10**18;
    uint256 public vestingTerm = 432000; //5 days
    
    mapping(uint256=>mapping(address=>uint256)) public boosterLists;
    mapping(uint256=>uint256) public totalBooster;
    mapping(uint256=>uint256) public totalBoosterLeft;
    mapping(uint256=>bool) public ifBoosterStart;
    mapping(uint256=>bool) public ifBoosterEnd;
    mapping(uint256=>uint256) public BoosterRelease;
    
    mapping(uint256=>mapping(address=>uint256)) public rewardClaimer;
    
    constructor(address _MIMaddress) public payable{
        CEOAddress = msg.sender;
        
        mimAddress = _MIMaddress;
        MIMERC20 candidateContract = MIMERC20(_MIMaddress);
        mimERC20 = candidateContract;
    }
    
    function setMIMAddress(address _address) external onlyCEO {
        MIMERC20 candidateContract = MIMERC20(_address);
        mimERC20 = candidateContract;
    }
    
    function setDiscount(uint256 _amount) public onlyCEO {
        require(_amount > 0);
        discountPrice = _amount;
    }
    
    function adjustVesting(uint256 _vesting) public onlyCEO {
        
    }
    
    function initializeBooster(uint256 _boosterNum, uint256 _total) public onlyCEO {
        if(_boosterNum > 0) {
            require(ifBoosterStart[_boosterNum-1], "This Booster index is not ready");
            require(ifBoosterEnd[_boosterNum-1], "Last Booster is not end yet");
        }
        require(!ifBoosterStart[_boosterNum], "Booster is opened already");
        totalBooster[_boosterNum] = _total;
        totalBoosterLeft[_boosterNum] = _total;
        ifBoosterStart[_boosterNum] = true;
        
        emit BoosterInitialized(_boosterNum, _total);
    }
    
    function buyBooster(uint256 _boosterNum, uint256 _amount) public whenNotPaused returns(uint256) {
        require(ifBoosterStart[_boosterNum], "Booster is not started yet");
        require(!ifBoosterEnd[_boosterNum], "Booster is over!");
        require(totalBoosterLeft[_boosterNum] >= _amount, "Not enough quota left");
        require(mimERC20.allowance(msg.sender, address(this)) >= discountPrice.mul(_amount).div(10**9), "Insuffcient approved MIM");
        mimERC20.transferFrom(msg.sender, address(this), discountPrice.mul(_amount).div(10**9));
        
        boosterLists[_boosterNum][msg.sender] = boosterLists[_boosterNum][msg.sender].add(_amount);
        totalBoosterLeft[_boosterNum] = totalBoosterLeft[_boosterNum].sub(_amount);
        
        emit BoosterSold(msg.sender, _amount);
    }
    
    function closeBooster(uint256 _boosterNum) public onlyCEO {
        require(ifBoosterStart[_boosterNum] && !ifBoosterEnd[_boosterNum], "Booster is invaild to close");
        ifBoosterEnd[_boosterNum] = true;
        BoosterRelease[_boosterNum] = now;
        
        emit BoosterClosed(_boosterNum);
    }
    
    function rewardTimeLeft(uint256 _boosterNum) public view returns(uint256) {
        return vestingTerm.sub(BoosterRelease[_boosterNum]);
    }
    
    function amountPending(uint256 _boosterNum) public view returns(uint256) {
        uint256 timeGap = now.sub(BoosterRelease[_boosterNum]);
        uint256 released = boosterLists[_boosterNum][msg.sender].mul(timeGap).div(vestingTerm);
        return released;
    }
    
    function amountCanClaim(uint256 _boosterNum) public view returns(uint256) {
        uint256 released = amountPending(_boosterNum);
        return released.sub(rewardClaimer[_boosterNum][msg.sender]);
    }
    
    function claimReward(uint256 _boosterNum) public whenNotPaused {
        require(ifBoosterEnd[_boosterNum], "Reward is not ready!");
        require(boosterLists[_boosterNum][msg.sender] > 0, "You are not believer!");
        uint256 claimable = amountCanClaim(_boosterNum);
        require(claimable > 0, 'Nothing to claim now');
        IERC20(mimAddress).transfer(msg.sender, claimable);
        rewardClaimer[_boosterNum][msg.sender] = rewardClaimer[_boosterNum][msg.sender].add(claimable);
        
        emit RewardClaimed(_boosterNum, msg.sender, claimable);
    }
    
}