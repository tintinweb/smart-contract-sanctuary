/**
 *Submitted for verification at BscScan.com on 2022-01-04
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.6.0;

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
        (bool success, ) = recipient.call.value(amount)("");
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
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
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
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
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
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
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

contract Crowdsale is Context, ReentrancyGuard, Owned {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    IBEP20 private _token;
    uint256 public startBlock;
    uint256 public endBlock;
    uint256 public _rate;
    uint256 public divider;
    uint256 public softCap;
    uint256 public hardCap;
    uint256 public _weiRaised;
    uint256 public tokensSold;
    uint256 public minAmount;
    uint256 public maxAmount;
    mapping(address => bool) public whiteList;
    mapping(address => uint256) public tokenPurchase;
    bool public isClosed;
    bool public enableWhitelist;

    event TokensPurchased(address indexed purchaser, uint256 value);

    constructor (uint256 rate, IBEP20 token, uint256 _startBlock, uint256 _endBlock, uint256 min, uint256 max, uint256 _softCap, uint256 _hardCap, uint256 _divider) public {
        require(rate > 0, "Crowdsale: rate is 0");
        require(address(token) != address(0), "Crowdsale: token is the zero address");
        require(_startBlock >= block.number && _endBlock > block.number,"Invalid block number");
        require(min > 0 && max > 0 && max > min,"Check min-max requirement");
        require(_softCap > 0 && _hardCap > 0 && _softCap < _hardCap,"Check caps");

        _rate = rate;
        _token = token;
        startBlock = _startBlock;
        endBlock = _endBlock;
        minAmount = min;
        maxAmount = max;
        softCap = _softCap;
        hardCap = _hardCap;
        divider = _divider;
        
    }

    receive() external payable {
        buyTokens();
    }

    function token() public view returns (IBEP20) {
        return _token;
    }


    function rate() public view returns (uint256) {
        return _rate;
    }

    function totalRaised() public view returns (uint256) {
        return _weiRaised;
    }
    
    function totalSoldToken() public view returns (uint256) {
        return tokensSold;
    }

    function buyTokens() public nonReentrant payable {
        require(block.number >= startBlock && block.number < endBlock && !isClosed,"Time period expired");
        if(enableWhitelist){
            require(whiteList[msg.sender],"Not whitelisted!");
        }
        uint256 weiAmount = msg.value;
        _preValidatePurchase(msg.sender, weiAmount);
        
        _weiRaised = _weiRaised.add(weiAmount);
        tokenPurchase[msg.sender] = tokenPurchase[msg.sender].add(weiAmount);

        if(_weiRaised > hardCap){
            isClosed = true;
        }
        
        emit TokensPurchased(_msgSender(), weiAmount);

    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(weiAmount >= minAmount && weiAmount <= maxAmount, "Invalid deposit amount");
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    function _deliverTokens() public nonReentrant{
        uint256 tokenAmount =  _getTokenAmount(tokenPurchase[msg.sender]);
        require(tokenAmount != 0,"Zero tokens to claim");
        _token.safeTransfer(msg.sender, tokenAmount);
        tokensSold = tokensSold.add(tokenAmount);
        tokenPurchase[msg.sender] = 0;
    }


    function _getTokenAmount(uint256 weiAmount) public view returns (uint256) {
        return (weiAmount.mul(_rate)).div(divider);
    }
    
    function refundBNB() external payable nonReentrant{
        require((isClosed || (_weiRaised < softCap)) && block.number >= endBlock,"ICO still active");
        require(tokenPurchase[msg.sender] > 0,"Zero amount");
        msg.sender.transfer(tokenPurchase[msg.sender]);
        tokenPurchase[msg.sender] = 0;
        
    }
    
    function claimBNB(address payable addr) external onlyOwner{
        require(_weiRaised >= softCap || isClosed,"Softcap not reached");
        addr.transfer(address(this).balance);
    }
    
    function closeICO() external onlyOwner {
        isClosed = true;    
    }
    
    function refundToken(address recepient, uint256 amount) public nonReentrant onlyOwner{
        require(block.number >= endBlock || isClosed,"You cannot withdraw token now");
        _token.safeTransfer(recepient, amount);
    }
    
    function setWhiteList(address[] calldata addr) external onlyOwner{
        for(uint i = 0; i < addr.length; i++){
            whiteList[addr[i]] = true;
        }
    }
    
    function enableWhite(bool value) external onlyOwner {
        enableWhitelist = value;
    }
    
}