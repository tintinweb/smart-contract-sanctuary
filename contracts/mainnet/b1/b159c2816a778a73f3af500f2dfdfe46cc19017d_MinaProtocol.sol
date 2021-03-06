/**
 *Submitted for verification at Etherscan.io on 2021-03-06
*/

pragma solidity 0.5.10;

/**
 * MINA PROTOCOL - Smart-Contract
 * 
 * 
 * The world's lightest blockchain, powered by participants.
 * 
 * By design, the entire Mina blockchain is and will always be about 22kb - the size of a couple of tweets. 
 * So anyone with a smartphone will be able to sync and verify the network in seconds.
 * 
 * About the Tech: https://minaprotocol.com/tech
 * Knowledge Base: https://minaprotocol.com/get-started#knowledge-base
 * 
 * Technical Whitepaper: https://minaprotocol.com/static/pdf/technicalWhitepaper.pdf
 * Economics Whitepaper: https://minaprotocol.com/static/pdf/economicsWhitepaper.pdf
 * 
 * Mina Protocol-media
 * Official Website: https://minaprotocol.com
 * Github: https://github.com/MinaProtocol/mina
 * Twitter: https://twitter.com/minaprotocol
 * Telegram: https://t.me/minaprotocol
 * Forums: https://forums.minaprotocol.com/t/mina-protocol-chinese-resources/200
 * Discord: https://discord.com/invite/RDQc43H
 * Facebook: https://www.facebook.com/Mina-Protocol-108885454193665
 * Reddit: https://www.reddit.com/r/MinaProtocol
 * Wiki: https://minawiki.com/Main_Page
 */


/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error.
 */
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) internal {
        require(initialOwner != address(0));
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 */
contract ReentrancyGuard {
    uint256 private _guardCounter;

    constructor () internal {
        _guardCounter = 1;
    }

    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

/**
 * @title BonusMina interface
 */
 interface BonusMina {
     function sendBonus(address account, uint256 amount) external;
     function RS_changeInterval(uint256 newInterval) external;
     function RS_newTicket() external;
     function RS_addReferrer(address referrer) external;
     function RS_ticketsOf(address player) external view returns(uint256);
     function RS_referrerOf(address player) external view returns(address);
     function RS_interval() external view returns(uint256);
 }

/**
 * @title Invest contract.
 */
contract MinaProtocol is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    // The token being sold
    IERC20 private _token;

    // BonusMina contract
    BonusMina private _MPBS;

    // Address where funds are collected
    address payable private _wallet;

    // Amount of wei raised
    uint256 private _weiRaised;

    // Amount of reserved tokens
    uint256 private _reserve;

    // How many token units a buyer gets per 1 ether
    uint256 private _rate = 2e15;

    // Minimum amount of wei to invest
    uint256 private _minimum = 0.5 ether;

    // Token amount set as share
    uint256 private _share = 1000000000000000;

    // Ref Bonus per share
    uint256 private _bonusPerShare = 50000000000000;

    // Delay period (UNIX time)
    uint256 private _delay;

    // User data
    mapping (address => User) users;
    struct User {
        Deposit[] deposits;
        uint256 checkpoint;
        uint256 reserved;
    }
    struct Deposit {
        uint256 amount;
        uint256 endtime;
        uint256 delay;
    }

    // Pause of recieving new deposits
    bool public paused;

    modifier notPaused() {
        require(!paused);
        _;
    }

    // Requiring of being referrer (more than 100 tickets)
    bool public refRequired;

    // Enable of referral programm
    enum ReferrerSystem {OFF, ON}
    ReferrerSystem public RS = ReferrerSystem.OFF;

    // Sending bonus to referral
    bool public referralMode;

    // Events
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount, uint256 delay);
    event Withdrawn(address indexed account, uint256 amount);

    /**
     * @param rate Number of token units a buyer gets per wei
     * @param wallet Address where collected funds will be forwarded to
     * @param token Address of the token being sold
     */
    constructor(uint256 rate, address payable wallet, IERC20 token, address initialOwner, address MPBSAddr) public Ownable(initialOwner) {
        require(rate != 0, "Rate is 0");
        require(wallet != address(0), "Wallet is the zero address");
        require(address(token) != address(0), "Token is the zero address");
        require(MPBSAddr != address(0), "MPBSAddr is the zero address");

        _rate = rate;
        _wallet = wallet;
        _token = token;
        _MPBS = BonusMina(MPBSAddr);
    }

    /**
     * @dev fallback function
     */
    function() external payable {
        if (msg.value > 0) {
            buyTokens(msg.sender);
        } else {
            withdraw();
        }
    }

    /**
     * @dev token purchase
     * This function has a non-reentrancy guard
     * @param beneficiary Recipient of the token purchase
     */
    function buyTokens(address beneficiary) public notPaused nonReentrant payable {
        require(beneficiary != address(0), "Beneficiary is the zero address");
        require(msg.value >= _minimum, "Wei amount is less than minimum");
        if (refRequired) {
            require(_MPBS.RS_ticketsOf(msg.sender) >= _MPBS.RS_interval());
        }

        uint256 weiAmount = msg.value;

        uint256 tokens = getTokenAmount(weiAmount);
        require(tokens <=  availableTokens(), "Not enough available tokens");

        _weiRaised = _weiRaised.add(weiAmount);

        _wallet.transfer(weiAmount);

        if (_delay == 0) {
            _token.transfer(beneficiary, tokens);
        } else {
            createDeposit(beneficiary, tokens);
        }

        if (_MPBS.RS_referrerOf(beneficiary) != address(0)) {
            if (RS == ReferrerSystem.ON) {
                _MPBS.sendBonus(_MPBS.RS_referrerOf(beneficiary), tokens.div(_share).mul(_bonusPerShare));
                if (referralMode) {
                    _MPBS.sendBonus(beneficiary, tokens.div(_share).mul(_bonusPerShare));
                }
            }
        } else if (msg.data.length == 20) {
            addReferrer();
        }

        emit TokensPurchased(msg.sender, beneficiary, weiAmount, tokens, _delay);
    }

    /**
     * @dev internal invest function
     * @param account address of users
     * @param amount amount of tokens to deposit
     */
    function createDeposit(address account, uint256 amount) internal {
        if (getDividends(account) > 0) {
            users[account].reserved += getDividends(account);
        }
        users[account].checkpoint = block.timestamp;
        users[account].deposits.push(Deposit(amount, block.timestamp.add(_delay), _delay));

        _reserve = _reserve.add(amount);
    }

    /**
     * @dev withdraw available dividens
     */
    function withdraw() public {
        uint256 payout = getDividends(msg.sender);
        if (users[msg.sender].reserved > 0) {
            users[msg.sender].reserved = 0;
        }

        require(payout > 0);

        users[msg.sender].checkpoint = block.timestamp;
        _token.transfer(msg.sender, payout);

        _reserve = _reserve.sub(payout);
        emit Withdrawn(msg.sender, payout);

    }

    /**
     * @dev internal addReferrer function
     */
    function addReferrer() internal {
        address referrer = bytesToAddress(bytes(msg.data));
        if (referrer != msg.sender) {
            uint256 interval = _MPBS.RS_interval();
            _MPBS.RS_changeInterval(0);
            _MPBS.RS_addReferrer(referrer);
            _MPBS.RS_changeInterval(interval);
        }
    }

    /**
     * @dev internal function to convert bytes type to address
     */
    function bytesToAddress(bytes memory source) internal pure returns(address parsedReferrer) {
        assembly {
            parsedReferrer := mload(add(source,0x14))
        }
    }

    /**
     * @dev Calculate amount of tokens to recieve for a given amount of wei
     * @param weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function getTokenAmount(uint256 weiAmount) public view returns(uint256) {
        return weiAmount.mul(_rate).div(1e18);
    }

    /**
     * @dev Calculate amount of tokens to recieve for a given account at current time
     * @param account Address of user
     * @return Number of tokens that can be withdrawn
     */
    function getDividends(address account) public view returns(uint256) {
        uint256 payout = users[account].reserved;
        for (uint256 i = 0; i < users[account].deposits.length; i++) {
            if (block.timestamp < users[account].deposits[i].endtime) {
                payout += (users[account].deposits[i].amount).mul(block.timestamp.sub(users[account].checkpoint)).div(users[account].deposits[i].delay);
            } else if (users[account].checkpoint < users[account].deposits[i].endtime) {
                payout += (users[account].deposits[i].amount).mul(users[account].deposits[i].endtime.sub(users[account].checkpoint)).div(users[account].deposits[i].delay);
            }
        }
        return payout;
    }

    /**
     * @dev Function to change the rate.
     * Available only to the owner.
     * @param newRate new value.
     */
    function setRate(uint256 newRate) external onlyOwner {
        require(newRate != 0, "New rate is 0");

        _rate = newRate;
    }

    /**
     * @dev Function to change the share value
     * Available only to the owner.
     * @param newShare new value.
     */
    function setShare(uint256 newShare) external onlyOwner {
        require(newShare != 0, "New share value is 0");

        _share = newShare;
    }

    /**
     * @dev Function to change the bonusPerShare value
     * Available only to the owner.
     * @param newBonus new value.
     */
    function setBonus(uint256 newBonus) external onlyOwner {
        require(newBonus != 0, "New bonus value is 0");

        _bonusPerShare = newBonus;
    }

    /**
     * @dev Function to change the address to receive ether.
     * Available only to the owner.
     * @param newWallet new address.
     */
    function setWallet(address payable newWallet) external onlyOwner {
        require(newWallet != address(0), "New wallet is the zero address");

        _wallet = newWallet;
    }

    /**
     * @dev Function to change the delay period of recieving tokens.
     * Available only to the owner.
     * @param newDelay new value (UNIX time).
     */
    function setDelayPeriod(uint256 newDelay) external onlyOwner {

        _delay = newDelay;
    }

    /**
     * @dev Function to change the minimum amount (wei).
     * Available only to the owner.
     * @param newMinimum new minimum value (wei).
     */
    function setMinimum(uint256 newMinimum) external onlyOwner {
        require(newMinimum != 0, "New parameter value is 0");

        _minimum = newMinimum;
    }

    /**
     * @dev Function to pause recieving of deposits.
     * Available only to the owner.
     */
    function pause() external onlyOwner {
        require(!paused);

        paused = true;
    }

    /**
     * @dev Function to unpause recieving of deposits.
     * Available only to the owner.
     */
    function unpause() external onlyOwner {
        require(paused);

        paused = false;
    }

    /**
     * @dev Function to switch if referrer is required.
     * Available only to the owner.
     */
    function switchRefSys() external onlyOwner {

        if (RS == ReferrerSystem.ON) {
            RS = ReferrerSystem.OFF;
        } else {
            RS = ReferrerSystem.ON;
        }
    }

    /**
     * @dev Function to switch the requiring of being referrer
     * Available only to the owner.
     */
    function switchRequiringOfRef() external onlyOwner {

        if (refRequired == true) {
            refRequired = false;
        } else {
            refRequired = true;
        }
    }

    /**
     * @dev Function to switch if referral gets bonus
     * Available only to the owner.
     */
    function switchReferralMode() external onlyOwner {

        if (referralMode == true) {
            referralMode = false;
        } else {
            referralMode = true;
        }
    }

    /**
    * @dev Allows to withdraw needed ERC20 token from this contract (promo or bounties for example).
    * Available only to the owner.
    * @param ERC20Token Address of ERC20 token.
    * @param recipient Account to receive tokens.
    */
    function withdrawERC20(address ERC20Token, address recipient) external onlyOwner {

        uint256 amount = IERC20(ERC20Token).balanceOf(address(this));
        IERC20(ERC20Token).transfer(recipient, amount);

    }

    /**
     * @return the token being sold.
     */
    function token() public view returns (IERC20) {
        return _token;
    }

    /**
     * @return address of BonusMina.
     */
    function MPBS() public view returns (BonusMina) {
        return _MPBS;
    }

    /**
     * @return the address where funds are collected.
     */
    function wallet() public view returns (address payable) {
        return _wallet;
    }

    /**
     * @return the number of token units a buyer gets per wei.
     */
    function rate() public view returns (uint256) {
        return _rate;
    }

    /**
     * @return the number of token set as share.
     */
    function share() public view returns (uint256) {
        return _share;
    }

    /**
     * @return the number of token units a referrer gets per share.
     */
    function bonusPerShare() public view returns (uint256) {
        return _bonusPerShare;
    }

    /**
     * @return minimum amount of wei to invest.
     */
    function minimum() public view returns (uint256) {
        return _minimum;
    }

    /**
     * @return the amount of wei raised.
     */
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    /**
     * @return the amount of reserved tokens.
     */
    function availableTokens() public view returns (uint256) {
        if (_token.balanceOf(address(this)) > _reserve) {
            return _token.balanceOf(address(this)).sub(_reserve);
        } else {
            return 0;
        }
    }

    /**
     * @return the amount of reserved tokens.
     */
    function reserved() public view returns (uint256) {
        return _reserve;
    }

    /**
     * @return delay time (UNIX time).
     */
    function delay() public view returns (uint256) {
        return _delay;
    }

}