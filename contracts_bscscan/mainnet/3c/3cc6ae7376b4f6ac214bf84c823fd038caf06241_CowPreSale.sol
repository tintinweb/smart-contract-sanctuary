/**
 *Submitted for verification at BscScan.com on 2022-01-18
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

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

    function mint(address account, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IStakingHelper {
    function stake( uint _amount, address _recipient, address _inviter ) external;
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IRouter {
    function inviteUser(address invite, address inviter, uint256 _amount, uint inviteType) external payable returns(bool);
}

contract CowPreSale is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    address public pCow;
    address public Busd;
    address public addressToSendBusd;

    uint256 public salePrice;
    uint256 public totalBoughtPCow;
    uint256 public planPCow;
    uint256 public endOfSale;

    uint256 public harvestStarted;
    uint256 public migrateStarted;
    bool public saleStarted;
    address public inviteRouter;
    address public stakingHelper;
    mapping(address => bool) isWhiteListed;
    mapping(address => bool) public isClearing;
    mapping(address => uint256) boughtPCow;
    mapping(address => uint256) public clearingPCow;
    mapping(address => uint256) public pendingCow;
    mapping(address => uint256) public rewarded24Hour;
    uint256 public rewardedCycle = 28800;

    event PurchasePCow(address account, uint256 amountBusd, uint256 purchaseAmount, uint256 totalBoughtPCow, address inviter);
    event HarvestPCow(address account, uint256 amountBusd, uint256 purchaseAmount, uint256 totalBoughtPCow);
    event MigratePCow(address account, uint256 totalBoughtPCow);

    function whiteListBuyers(address[] memory _buyers)
        external
        onlyOwner()
        returns (bool)
    {
  
        for (uint256 i; i < _buyers.length; i++) {
            isWhiteListed[_buyers[i]] = true;
        }

        return true;
    }

    function isWhitList(address _address) view external returns (bool){
        return isWhiteListed[_address];
    }

    function initialize(
        address _addressToSendBusd, // 
        address _busd,              //
        address _router,
        uint256 _salePrice,         // 
        uint256 _saleTime,          // 
        uint256 _planPCow,          // 
        uint256 _harvestStarted,    // 
        uint256 _migrateStarted
    ) external onlyOwner() returns (bool) {

        Busd = _busd;
        salePrice = _salePrice;
        inviteRouter = _router;
        endOfSale = _saleTime.add(block.timestamp);
        saleStarted = true;
        addressToSendBusd = _addressToSendBusd;
        planPCow = _planPCow;
        harvestStarted = _harvestStarted;
        migrateStarted = _migrateStarted;
        return true;
    }

    // buy cow
    function purchase(uint256 _amountBusd, address inviter) external returns(bool) {
        require(saleStarted == true, "Not started");
        require(isWhiteListed[msg.sender] == true, "Not whitelisted");
        require(block.timestamp < endOfSale, "Sale over");
        require(_amountBusd > 0.1*1e18,"too small");
        require(boughtPCow[msg.sender].mul(salePrice).div(1e9).add(_amountBusd) <= 3300e18,"exceeds max amount you can buy");
        uint256 _purchaseAmount = _calculateSaleQuote(_amountBusd);
        IERC20(Busd).safeTransferFrom(msg.sender, addressToSendBusd, _amountBusd);

        boughtPCow[msg.sender] = boughtPCow[msg.sender].add(_purchaseAmount);
        totalBoughtPCow = totalBoughtPCow.add(_purchaseAmount);

        isClearing[msg.sender] == false;

        if(inviteRouter != address(0)){
            IRouter(inviteRouter).inviteUser(msg.sender, inviter, _amountBusd, 1);
        }

        emit PurchasePCow(msg.sender, _amountBusd, _purchaseAmount, totalBoughtPCow, inviter);

        return true;
    }

    function balanceOf() external view returns(uint256) {
        require(block.timestamp >= endOfSale, "Not ended");
        require(isClearing[msg.sender] == true, "please clearing.");

        return clearingPCow[msg.sender];
    }

    function harvestBusd() public returns(uint256) {
        require(block.timestamp > harvestStarted, "not time");
        // finished
        require(isClearing[msg.sender] == false, "alread clearing BUSD.");
        // caculate cow amount
        uint256 cowForUser;
        uint256 busdFallBack;

        if(planPCow < totalBoughtPCow){
            // enough
            cowForUser = planPCow.mul(boughtPCow[msg.sender]).div(totalBoughtPCow);
            busdFallBack = (boughtPCow[msg.sender].sub(cowForUser)).mul(salePrice).div(1e9);
            busdFallBack = busdFallBack.div(1e14).mul(1e14);
            IERC20(Busd).safeTransfer(msg.sender,busdFallBack);
            clearingPCow[msg.sender] = cowForUser;
            isClearing[msg.sender] = true;
            // harvest finish
        }
        emit HarvestPCow(msg.sender, cowForUser, boughtPCow[msg.sender], busdFallBack);
        return cowForUser;
    }

    function migratePCow() public helper() returns(uint256) {
        require(block.timestamp > migrateStarted, "no time");
        require(rewarded24Hour[msg.sender] < block.number,
                "you have already migrated today!"
        );
        if(planPCow < totalBoughtPCow){
            require(isClearing[msg.sender] == true, "please clearing BUSD.");
        }else{
            if(isClearing[msg.sender] == false){
                uint256 cowAmount = boughtPCow[msg.sender];
                clearingPCow[msg.sender] = cowAmount;
                isClearing[msg.sender] = true;
            }
        }
        require(clearingPCow[msg.sender] > 100, "alread clearing.");
        // cow amount
        uint256 cowForUser = clearingPCow[msg.sender];
        uint256 pending = pendingCow[msg.sender];
        if(pending == 0){
            pending = cowForUser.div(5);
            pendingCow[msg.sender] = pending;
        }
        
        // stake 
        IERC20(pCow).approve(stakingHelper, pending);
        IStakingHelper(stakingHelper).stake(pending, msg.sender, address(0));
        // migrate finish
        clearingPCow[msg.sender] = cowForUser.sub(pending);

        rewarded24Hour[msg.sender] = block.number.add(rewardedCycle);

        emit MigratePCow(msg.sender, cowForUser);
        return cowForUser;
    }

    function setCowAddress(address _cow) external onlyOwner() returns (bool) {
        pCow = _cow;
        return true;
    }

    function setRouter(address _router) public onlyOwner() returns (bool){
        inviteRouter = _router;
        return true;
    }

    function setStakingHelper(address _helper) public onlyOwner() returns (bool){
        require(_helper != address(0),"presale : address is zero");
        stakingHelper = _helper;
        return true;
    }

    function setMigrateStartTime(uint256 _time ) public onlyOwner() returns (bool){
        require(block.timestamp > _time,"must greater than currentTime");
        migrateStarted = _time;
        return true;
    }

    function setRewardedCycle(uint256 cycle)
        external
        onlyOwner
        returns (bool)
    {
        rewardedCycle = cycle;
        return true;
    }

    function userPurchaseInfo(address _user)
        external
        view
        returns (uint256, uint256)
    {
        return (boughtPCow[_user], clearingPCow[_user]);
    }

    function purchaseInfo()
        external
        view
        returns (bool, uint256, uint256, uint256, uint256, uint256, uint256, address,address,address)
    {
        return (saleStarted,endOfSale,harvestStarted, migrateStarted,salePrice,planPCow,totalBoughtPCow,pCow,Busd,addressToSendBusd);
    }

    function _calculateSaleQuote(uint256 paymentAmount_)
        internal
        view
        returns (uint256)
    {
        return paymentAmount_.mul(1e9).div(salePrice);
    }

    function sendRemainingBusd(address _sendBusdTo)
        external
        onlyOwner()
        returns (bool)
    {
        require(saleStarted == true, "Not started");
        require(block.timestamp >= endOfSale, "Not ended");

        IERC20(Busd).safeTransfer(
            _sendBusdTo,
            IERC20(Busd).balanceOf(address(this))
        );

        return true;
    }

    // quote price 
    function calculateSaleQuote(uint256 paymentAmount_)
        external
        view
        returns (uint256)
    {
        return _calculateSaleQuote(paymentAmount_);
    }

    modifier helper() {
        require(stakingHelper != address(0), "presale: helper address is zero");
        _;
    }
}