/**
 *Submitted for verification at BscScan.com on 2021-11-13
*/

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.3;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract Lockable {
    bool private _notEntered;

    constructor() {
        _notEntered = true;
    }

    modifier nonReentrant() {
        _preEntranceCheck();
        _preEntranceSet();
        _;
        _postEntranceReset();
    }

    modifier nonReentrantView() {
        _preEntranceCheck();
        _;
    }

    function _preEntranceCheck() internal view {
        require(_notEntered, "ReentrancyGuard: reentrant call");
    }

    function _preEntranceSet() internal {
        _notEntered = false;
    }

    function _postEntranceReset() internal {
        _notEntered = true;
    }
}

interface IPubliclist {
    function addToPubliclist(address newElement) external;

    function removeFromPubliclist(address newElement) external;

    function isOnPubliclist(address newElement) external view returns (bool);

    function getPubliclist() external view returns (address[] memory);
}

interface IMarketCalculator {
    function principleAmount(
        uint256 _amount, 
        uint256 _marketPrice, 
        uint256 _decimals
    ) external pure returns(uint256);
}

contract PublicMarket is Ownable, Lockable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public pToken;
    IERC20 public principle;
    IMarketCalculator public calculator;
    IPubliclist public publiclist;
    uint256 public marketPrice;

    address public treasury;

    uint256 public exchangeEndBlock;
    uint256 public withdrawEndBlock;
    uint256 public redeemEndBlock;
    bool private canExchange = false;
    bool private canWithdraw = false;
    bool private canRedeem = false;
    bool private canReclaim = false;

    bool public isInitialized;

    mapping(address => uint256) private senderInfo;
    mapping(address => uint256) private buyInfo; // only record exchange and withdraw info, to set limit when migration
    
    event Initialize(        
        address _pToken,
        address _principle,
        address _calculator,
        address _publiclist
        );
    event OpenExchange(uint256 _exchangeDuration);
    event OpenWithdraw(uint256 _withdrawDuration);
    event OpenRedeem(uint256 _redeemDuration);
    event OpenReclaim();
    event ResetEndBlock();
    event Reclaim(address _treasury, uint256 _prinAmount);

    modifier onlyInitialized() {
        require(isInitialized, "not initialized");
        _;
    }
    
    modifier notInitialized() {
        require( !isInitialized, "already initialized" );
        _;
    }

    modifier onlyPubliclist(address _public) {
        require(publiclist.isOnPubliclist(_public), "user is not public");
        _;
    }

    constructor(address _treasury) {
        treasury = _treasury;
    }

    function initialize (
        address _pToken,
        address _principle,
        address _calculator,
        address _publiclist
    ) external onlyOwner() notInitialized() {
        pToken = IERC20(_pToken);
        principle = IERC20(_principle);
        calculator = IMarketCalculator(_calculator);
        publiclist = IPubliclist(_publiclist);
        marketPrice = 10 ** principle.decimals();
        
        isInitialized = true;

        emit Initialize(_pToken, _principle, _calculator, _publiclist);
    }

    function openExchange(uint256 _exchangeDuration) external onlyOwner() {
        exchangeEndBlock = block.number.add(_exchangeDuration);
        canExchange = !canExchange;

        emit OpenExchange(_exchangeDuration);
    }

    function exchange(uint256 _amount) external 
    nonReentrant() 
    onlyInitialized() 
    {
        require(canExchange, "exchange not open");
        require(block.number < exchangeEndBlock, "exchanging has ended");

        uint256 _prinAmount = calculator.principleAmount(_amount, marketPrice, pToken.decimals());
        require(principle.balanceOf(msg.sender) >= _prinAmount, "principle amount above user balance");

        principle.safeTransferFrom(msg.sender, address(this), _prinAmount);
        senderInfo[msg.sender] = senderInfo[msg.sender].add(_amount);
        buyInfo[msg.sender] = buyInfo[msg.sender].add(_amount);

        if (!publiclist.isOnPubliclist(msg.sender)) {
            publiclist.addToPubliclist(msg.sender);
        }
    }
    
    function exchangeable() public view returns (bool) {
        return canExchange && block.number < exchangeEndBlock;
    }

    function openWithdraw(uint256 _withdrawDuration) external onlyOwner() {
        withdrawEndBlock = exchangeEndBlock.add(_withdrawDuration);
        canWithdraw = !canWithdraw;

        emit OpenWithdraw(_withdrawDuration);
    }

    // withdraw all 
    function withdraw() external 
    nonReentrant() 
    onlyInitialized()
    onlyPubliclist(msg.sender)
    {
        require(canWithdraw, "withdraw not open");
        require(block.number < withdrawEndBlock, "withdraw has ended");
 
        uint256 _amount = senderInfo[msg.sender];
        require( _amount > 0, "user have no pToken to withdraw");

        uint256 _prinAmount = calculator.principleAmount(_amount, marketPrice, pToken.decimals());
        senderInfo[msg.sender] = 0;
        buyInfo[msg.sender] = 0;
        principle.safeTransfer(msg.sender, _prinAmount);
        publiclist.removeFromPubliclist(msg.sender);
    }

    function withdrawable() public view returns (bool) {
        return canWithdraw && block.number < withdrawEndBlock;
    }

    function openRedeem(uint256 _redeemDuration) external onlyOwner() {
        require(!exchangeable()&&!withdrawable(), "withdraw is not end");

        redeemEndBlock = block.number.add(_redeemDuration);
        canRedeem = !canRedeem;

        emit OpenRedeem(_redeemDuration);
    }

    function redeem() external 
    nonReentrant() 
    onlyInitialized() 
    onlyPubliclist(msg.sender) {
        require(canRedeem, "redeem not open");
        require(block.number < redeemEndBlock, "redeem has ended");

        uint256 _amount = senderInfo[msg.sender];
        require(_amount > 0, "user balance is zero");

        pToken.safeTransfer(msg.sender, _amount);
        senderInfo[msg.sender] = 0;
    }

    function redeemable() public view returns (bool) {
        return canRedeem && block.number < redeemEndBlock;
    }

    function openReclaim() external onlyOwner() {
        require(!exchangeable()&&!withdrawable()&&!redeemable(), "redeem is not end");
        
        canReclaim = !canReclaim;

        emit OpenReclaim();
    }

    function reclaim() external onlyOwner() {
        require(canReclaim, "reclaim not open");
        require(address(treasury)!=address(0), "treasury address is zero");

        uint256 ptokenAmount = pToken.balanceOf(address(this));
        uint256 prinAmount = principle.balanceOf(address(this));

        pToken.safeTransfer(address(treasury), ptokenAmount);
        principle.safeTransfer(address(treasury), prinAmount);

        emit Reclaim(address(treasury), prinAmount);
    }

    function reclaimable() public view returns (bool) {
        return canReclaim;
    }

    function getSenderInfo(address _addr) public view 
    onlyInitialized() 
    returns (uint256) {
        return senderInfo[_addr];
    }

    function getBuyInfo(address _addr) public view 
    onlyInitialized() 
    returns (uint256) {
        return buyInfo[_addr];
    }

    function totalFunds() public view returns (uint256) {
        uint256 _funds = principle.balanceOf(address(this));
        return  _funds;
    }

    function resetEndBlock() external onlyOwner() {
        canExchange = false;
        canWithdraw = false;
        canRedeem = false;
        canReclaim = false;

        emit ResetEndBlock();
    }
}