/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

/**
 * SPDX-License-Identifier: Unlicensed
*/

// File: @openzeppelin/contracts/GSN/Context.sol


pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol


pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity ^0.6.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface DLRNFT {
    function newItem(address referrer) external returns (uint256);
    function totalSupply() external view returns (uint256);
    function getRefId(address referrer) external view returns (uint256);
}

interface DLBNFT {
    function newItem(address buyer, uint256 _tickets, uint256 _ticketPaid, uint256 _launchIndex) external returns (uint256);
    function totalSupply() external view returns (uint256);
    function ticketClaimed(uint256 tokenId) external view returns (uint256);
    function ticketPaid(uint256 tokenId) external view returns (uint256);
    function getTicketAmount(address buyer, uint256 _launchIndex) external view returns (uint256,uint256);
    function claimTicket(uint256 tokenId, uint256 n) external;
}

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

contract DLP is Ownable {
    using SafeMath for uint256;
    DLRNFT public dLRNFT;
    DLBNFT public dLBNFT;
    uint256 public softcap = 100;
    uint256 public hardcap = 1000;
    uint256 public maxBuy = 100;
    uint256 public ticketRate = 10000000000000000;
    uint256 public ticketFee = 10;
    uint256 public launchIndex = 0;
    uint256 public phase = 0; // 0=born 1=presale 2=postsale 3=claim time 1 4=claim time 2 5=claim time 3
    uint256 public devFee = 0;
    uint256 public devFeePending = 0;
    address LPAddress;
    address constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    mapping (uint256 => uint256) public RefLastClaim;
    mapping (uint256 => mapping(uint256 => uint256)) public ReferralReward;
    mapping (uint256 => uint256) public Tickets;
    mapping (uint256 => uint256) public TokenPresale;
    mapping (uint256 => uint256) public TokenLaunched;
    mapping (uint256 => address) public Token;
    mapping (uint256 => string) public TokenName;
    event RegRef(address indexed referrer, uint256 refId);
    event Phase(uint256 _phase, uint256 launched);
    event Claimed(address indexed to,uint256 tokenAmount);
    event WdTicket(address indexed to,uint256 tokenAmount);
    constructor(address _lpaddress, address _dlrnft, address _dlbnft) public 
    {
        dLRNFT = DLRNFT(_dlrnft);
        dLBNFT = DLBNFT(_dlbnft);
        LPAddress = _lpaddress;
    }
    
    function buy(uint256 _tickets, uint256 refId) external payable {
        require(phase==1,"presale closed");
        uint256 nextTickets = Tickets[launchIndex] + _tickets;
        require(nextTickets<=hardcap,"hardcap reached");
        (uint256 currentTicketAmount, ) = dLBNFT.getTicketAmount(msg.sender, launchIndex);
        require(currentTicketAmount<=maxBuy,"maxBuy reached");
        uint256 ticketPrice = _tickets * ticketRate;
        uint256 fee = ticketPrice.div(100).mul(ticketFee);
        uint256 ticketPayment = ticketPrice + fee;
        require(msg.value>=ticketPayment,"not enough eth");
        dLBNFT.newItem(msg.sender, _tickets, ticketPayment, launchIndex);
        Tickets[launchIndex] = nextTickets; 
        if(refId>0 && refId<=getRefCount()){
            uint256 refReward = fee.div(100).mul(30);
            fee -= refReward;
            ReferralReward[refId][launchIndex] += refReward;
        }
        devFeePending += fee;
    }
    
    function claimRef() external {
        uint256 refId = dLRNFT.getRefId(msg.sender);
        require(refId>0,"invalid");
        uint256 amount = 0;
        uint256 x = 1;
        if(RefLastClaim[refId]>0) x = RefLastClaim[refId]+1;
        require(x<launchIndex,"invalid launchIndex");
        for(uint256 i=x;i < launchIndex;i++){
            if(TokenLaunched[i]==1 && ReferralReward[refId][i]>0){
                amount += ReferralReward[refId][i];
            }
            RefLastClaim[refId] = i;
        }
        if(amount>0){
            require(address(this).balance>=amount,"not enough eth");
            msg.sender.transfer(amount);
        }
    }
    
    function claim(uint256 _launchIndex) external {
        require( _launchIndex>0 && _launchIndex<=launchIndex,"invalid launchIndex");
        uint256 newClaim = 0;
        if(_launchIndex<launchIndex){
            require(TokenLaunched[_launchIndex]==1,"not launched yet");
        }
        else{
            require(phase>=3,"claim not open yet");
            newClaim = 1;
        }
        IERC20 token = IERC20(Token[_launchIndex]);
        uint256 tokenBalance = token.balanceOf(address(this));
        (uint256 currentTicketAmount, uint256 tokenId) = dLBNFT.getTicketAmount(msg.sender, _launchIndex);
        if(newClaim==0){
            uint256 tokenAmount = TokenPresale[_launchIndex].div(Tickets[_launchIndex]).mul(currentTicketAmount);
            uint256 claimed = dLBNFT.ticketClaimed(tokenId);
            require(tokenBalance>=tokenAmount,"not enough");
            require(claimed<3,"claimed");
            dLBNFT.claimTicket(tokenId,3);
            if(claimed==1){
                tokenAmount = tokenAmount.div(100).mul(50);
            }
            else if(claimed==2){
                tokenAmount = tokenAmount.div(100).mul(25);
            }
            token.transfer(msg.sender, tokenAmount);
            emit Claimed(msg.sender,tokenAmount);
        }
        else{
            uint256 tokenAmount = TokenPresale[_launchIndex].div(Tickets[_launchIndex]).mul(currentTicketAmount);
            uint256 claimed = dLBNFT.ticketClaimed(tokenId);
            if(phase==3){
                require(claimed<1,"claimed");
                tokenAmount = tokenAmount.div(100).mul(50);
                dLBNFT.claimTicket(tokenId,1);                
            }
            else if(phase==4){
                require(claimed<2,"claimed");
                if(claimed==0){
                    tokenAmount = tokenAmount.div(100).mul(75);
                }
                else{
                    tokenAmount = tokenAmount.div(100).mul(25);
                }
                dLBNFT.claimTicket(tokenId,2);
            }
            else if(phase==5){
                require(claimed<3,"claimed");
                if(claimed==1){
                    tokenAmount = tokenAmount.div(100).mul(50);
                }
                else{
                    tokenAmount = tokenAmount.div(100).mul(25);
                }
                dLBNFT.claimTicket(tokenId,3);
            }
            require(tokenBalance>=tokenAmount,"not enough");
            token.transfer(msg.sender, tokenAmount);
            emit Claimed(msg.sender,tokenAmount);
        }
    }
    
    function wdTicket(uint256 _launchIndex) external{
        require( _launchIndex>0 && _launchIndex<=launchIndex,"invalid launchIndex");
        require(TokenLaunched[_launchIndex]==0,"not allowed");
        if(_launchIndex==launchIndex){
            require(phase!=1,"presale mode cannot wd");
        }
        ( , uint256 tokenId) = dLBNFT.getTicketAmount(msg.sender, _launchIndex);
        uint256 claimed = dLBNFT.ticketClaimed(tokenId);
        require(claimed==0,"claimed");
        dLBNFT.claimTicket(tokenId,3);
        uint256 ticketPayment = dLBNFT.ticketPaid(tokenId);
        require(address(this).balance>=ticketPayment,"not enough eth");
        msg.sender.transfer(ticketPayment);
        emit WdTicket(msg.sender,ticketPayment);
    }
    
    function preSale(string memory _tokenName) external onlyOwner {
        require(phase!=1,"already presale");
        phase = 1;
        emit Phase(phase,TokenLaunched[launchIndex]);
        launchIndex++;
        TokenName[launchIndex] = _tokenName;
    }

    function postSale(address _token, uint256 _xpresale, uint256 _xlp, uint256 _xburn) external onlyOwner {
        require(phase!=2,"already postsale");
        uint256 _xtotal = _xpresale + _xlp + _xburn;
        require(_xtotal==100,"invalid x");
        phase = 2;
        if(Tickets[launchIndex]>=softcap){
            IERC20 token = IERC20(_token);
            uint256 tb = token.balanceOf(address(this));
            require(tb>0,"no token");
            TokenPresale[launchIndex] = tb.div(100).mul(_xpresale);
            uint256 tlp = tb.div(100).mul(_xlp);
            uint256 tburn = tb.div(100).mul(_xburn);
            token.transfer(LPAddress, tlp);
            token.transfer(burnAddress,tburn);
            Token[launchIndex] = _token;            
            TokenLaunched[launchIndex] = 1;
            devFee += devFeePending;
            uint256 LPAmount = Tickets[launchIndex] * ticketRate; 
            address payable LPAddr = payable(LPAddress); 
            LPAddr.transfer(LPAmount);
            msg.sender.transfer(devFee);
            devFee = 0;            
        }
        devFeePending = 0; 
        emit Phase(phase,TokenLaunched[launchIndex]);
    }
    
    function setClaim1() external onlyOwner {
        require(phase==2,"postsale first");
        require(Tickets[launchIndex]>=softcap,"softcap didnot reached");
        phase = 3;
        emit Phase(phase,TokenLaunched[launchIndex]);
    }

    function setClaim2() external onlyOwner {
        require(phase==3,"claim1 first");
        phase = 4;
        emit Phase(phase,TokenLaunched[launchIndex]);
    }
    
    function setClaim3() external onlyOwner {
        require(phase==4,"claim2 first");
        phase = 5;
        emit Phase(phase,TokenLaunched[launchIndex]);
    }

    function setLPAddress(address addr) external onlyOwner {
        LPAddress = addr;
    }
    
    function setSoftCap(uint256 _softcap) external onlyOwner {
        softcap = _softcap;
    }
    function setHardCap(uint256 _hardcap) external onlyOwner {
        hardcap = _hardcap;
    }   
    function setMaxBuy(uint256 _maxbuy) external onlyOwner {
        maxBuy = _maxbuy;
    }     
    function regRef() external {
        uint256 refId = dLRNFT.newItem(msg.sender);
        emit RegRef(msg.sender,refId);
    }
    
    function getRefCount() public view returns (uint256){
        return dLRNFT.totalSupply();
    }
    
    function devFeeClaim() external onlyOwner {
        require(devFee>0,"not enough");
        msg.sender.transfer(devFee);
        devFee = 0;
    }
}