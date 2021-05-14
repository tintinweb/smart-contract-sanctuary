/**
 *Submitted for verification at Etherscan.io on 2021-05-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;


contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IBEP20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call{value:amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IBEP20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeBEP20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(IBEP20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeBEP20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeBEP20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        _notEntered = true;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}



// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address payable public owner;
    // address payable public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


}

contract MomentsPrivateSale is Context, ReentrancyGuard, Owned {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    
    struct Stage {
        uint256 date;
        uint256 tokensUnlockedPercentage;
    }
    
    struct User{
        uint256 initialBalance;
        uint256 lockedAmount;
        uint256 totalWithdrawn;
    }

    Stage[] public stages;

    // The token being sold
    IBEP20 private _token;

    // Address where funds are collected
    address payable private _wallet;
    
    

    // How many token units a buyer gets per wei.
    // The rate is the conversion between wei and the smallest and indivisible token unit.
    // So, if you are using a rate of 1 with a BEP20Detailed token with 3 decimals called TOK
    // 1 wei will give you 1 unit, or 0.001 TOK.
    uint256 private _rate;
    
    // To adjust the rate. If you put a divider of 10, 1 ether will give 0.1 token 
    uint256 private _divider;
    // Amount of wei raised
    uint256 private _weiRaised;
    
    //Indicates Sale is active or NOT
    bool public isActive = false;
    
    mapping(address => User) public users;
    
    //Total token balance of contract. Must be updated after token deposit
    uint256 public totalBalance;
    
    //For storing amount of unsold tokens
    uint256 public remainingBalance;
    
    //Token lock start period
    uint256 public StartTimestamp = 1529398800;

    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event Withdraw(uint256 tokensToSend,uint256 now);
    constructor (uint256 rate, address payable wallet, IBEP20 token, uint256 divider) public {
        require(rate > 0, "Crowdsale: rate is 0");
        require(wallet != address(0), "Crowdsale: wallet is the zero address");
        require(address(token) != address(0), "Crowdsale: token is the zero address");

        _rate = rate;
        _wallet = wallet;
        _token = token;
        _divider = divider;
    }

    receive() external payable {
        buyTokens(_msgSender());
    }

    function token() public view returns (IBEP20) {
        return _token;
    }

    function wallet() public view returns (address payable) {
        return _wallet;
    }

    function rate() public view returns (uint256) {
        return _rate;
    }
    
    function divider() public view returns (uint256) {
        return _divider;
    }

    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    function buyTokens(address beneficiary) public nonReentrant payable {
        require(isActive,"Sale already ended! / Not started yet");
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        // update state
        _weiRaised = _weiRaised.add(weiAmount);

        _processPurchase(beneficiary, tokens);
        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);
        _forwardFunds();

    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        users[beneficiary].lockedAmount = users[beneficiary].lockedAmount.add(tokenAmount);
        users[beneficiary].initialBalance = users[beneficiary].initialBalance.add(tokenAmount);
        remainingBalance = remainingBalance.sub(tokenAmount);
    }

    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }

    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(_rate).div(_divider);
    }

    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
    }
    
    // Owner only function to withdraw any unsold token and stop sale
    function withdrawRemainingTokenForOwner() public nonReentrant{
        require(msg.sender == owner,"Not owner");
        isActive = false;
        _deliverTokens(owner, remainingBalance);
        initStages();
    }
    
    //Function to be called to start sale
    function updateTokenBalance() external {
        require(!isActive,"Buy is already active");
        require(msg.sender == owner,"Not owner");
        totalBalance = _token.balanceOf(address(this));
        remainingBalance = totalBalance;
        isActive = true;
    }

    function withdrawTokens () public {
        uint256 tokensToSend = getTokensUnlocked(msg.sender);
        if (tokensToSend > 0) {
            // Updating tokens sent counter
            users[msg.sender].totalWithdrawn = users[msg.sender].totalWithdrawn.add(tokensToSend);
            users[msg.sender].lockedAmount = users[msg.sender].lockedAmount.sub(tokensToSend);
            // Sending allowed tokens amount
            _token.transfer(msg.sender, tokensToSend);
            // Raising event
            emit Withdraw(tokensToSend, now);
        }
    }

    function getTokensUnlocked(address addr) public view returns(uint256 tokensToSend) {
        uint256 allowedPercent;
        // Getting unlocked percentage
        for (uint8 i = 0; i < stages.length; i++) {
            if (now >= stages[i].date) {
                allowedPercent = stages[i].tokensUnlockedPercentage;
            }
        }
        if (allowedPercent >= 100) {
            tokensToSend = users[addr].lockedAmount;
        } else {
            uint256 totalTokensAllowedToWithdraw = users[addr].initialBalance.mul(allowedPercent).div(100);
            tokensToSend = totalTokensAllowedToWithdraw.sub(users[addr].totalWithdrawn);
            return tokensToSend;
        }
    }
    
    function initStages () internal {
        uint256 month = 30 days;
        stages[0].date = StartTimestamp;
        stages[1].date = StartTimestamp + (1 * month);
        stages[2].date = StartTimestamp + (2 * month);
        stages[3].date = StartTimestamp + (3 * month);
        stages[4].date = StartTimestamp + (4 * month);
        stages[5].date = StartTimestamp + (5 * month);
        stages[6].date = StartTimestamp + (6 * month);
        

        stages[0].tokensUnlockedPercentage = 25;
        stages[1].tokensUnlockedPercentage = 50;
        stages[2].tokensUnlockedPercentage = 75;
        stages[3].tokensUnlockedPercentage = 88;
        stages[4].tokensUnlockedPercentage = 100;
    }
    
}