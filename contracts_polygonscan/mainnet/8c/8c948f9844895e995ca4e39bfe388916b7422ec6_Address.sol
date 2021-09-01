/**
 *Submitted for verification at polygonscan.com on 2021-09-01
*/

/*
    Time Locker Factory V1
    
     ad8888888888ba
     dP'         `"8b,
     8  ,aaa,       "Y888a     ,aaaa,     ,aaa,  ,aa,
     8  8' `8           "8baaaad""""baaaad""""baad""8b
     8  8   8              """"      """"      ""    8b
     8  8, ,8         ,aaaaaaaaaaaaaaaaaaaaaaaaddddd88P
     8  `"""'       ,d8""
     Yb,         ,ad8"    Created by Murciano207
      "Y8888888888P"
    
    Contract Timelock, fee: 100 SPP
    Address Spooky Pumpkins (SPP): 0x260f29358c0453914e8dcf12bd2cf964d6f8a81b
    http://spookfinance.tk
    Spook Finance® Copyright 2021 - All Rights Reserved
    
    SPDX-License-Identifier: Apache-2.0

*/
pragma solidity ^0.5.0;
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
pragma solidity ^0.5.0;
contract Context {
    
    constructor () internal { }
    
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}
pragma solidity ^0.5.0;
contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner(), "");
        _;
    }
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
pragma solidity ^0.5.0;
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
pragma solidity ^0.5.5;
library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "");
        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "");
    }
}
pragma solidity ^0.5.0;
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            ""
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "");
        if (returndata.length > 0) { 
            require(abi.decode(returndata, (bool)), "");
        }
    }
}
pragma solidity 0.5.15;
contract LockFactorybySpookFinance is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    enum Status { _, OPEN, CLOSED }
    enum TokenStatus {_, ACTIVE, INACTIVE }
    struct Token {
        address tokenAddress;
        uint256 minAmount;
        bool emergencyUnlock;
        TokenStatus status;
        uint256[] tierAmounts;
        uint256[] tierFees;
    }
    Token[] private _tokens;
    IERC20 private _lockToken;
    uint256 private _lockTokenFee;
    mapping(address => uint256) private _tokenVsIndex;
    address payable private _wallet;
    address constant private ETH_ADDRESS = address(
        0xC941f4db4AfAfb1A2422792efbebbfc668950684
    );
    struct LockedAsset {
        address token;
        uint256 amount;
        uint256 startDate;
        uint256 endDate;
        uint256 lastLocked;
        uint256 amountThreshold;
        address payable beneficiary;
        Status status;
    }
    struct Airdrop {
        address destToken;
        uint256 numerator;
        uint256 denominator;
        uint256 date;
    }
    mapping(address => Airdrop[]) private _baseTokenVsAirdrops;
    uint256 private _lockId;
    mapping(address => uint256[]) private _userVsLockIds;
    mapping(uint256 => LockedAsset) private _idVsLockedAsset;
    bool private _paused;
    event TokenAdded(address indexed token);
    event TokenInactivated(address indexed token);
    event TokenActivated(address indexed token);
    event WalletChanged(address indexed wallet);
    event AssetLocked(
        address indexed token,
        address indexed sender,
        address indexed beneficiary,
        uint256 id,
        uint256 amount,
        uint256 startDate,
        uint256 endDate,
        bool lockTokenFee,
        uint256 fee
    );
    event TokenUpdated(
        uint256 indexed id,
        address indexed token,
        uint256 minAmount,
        bool emergencyUnlock,
        uint256[] tierAmounts,
        uint256[] tierFees
    );
    event Paused();
    event Unpaused();
    event AssetClaimed(
        uint256 indexed id,
        address indexed beneficiary,
        address indexed token
    );
    event AirdropAdded(
        address indexed baseToken,
        address indexed destToken,
        uint256 index,
        uint256 airdropDate,
        uint256 numerator,
        uint256 denominator
    );
    event AirdropUpdated(
        address indexed baseToken,
        address indexed destToken,
        uint256 index,
        uint256 airdropDate,
        uint256 numerator,
        uint256 denominator
    );
    event TokensAirdropped(
        address indexed destToken,
        uint256 amount
    );
    event LockTokenUpdated(address indexed lockTokenAddress);
    event LockTokenFeeUpdated(uint256 fee);
    event AmountAdded(address indexed beneficiary, uint256 id, uint256 amount);
    modifier tokenExist(address token) {
        require(_tokenVsIndex[token] > 0, "");
        _;
    }
    modifier tokenDoesNotExist(address token) {
        require(_tokenVsIndex[token] == 0, "");
        _;
    }
    modifier canLockAsset(address token) {
        uint256 index = _tokenVsIndex[token];
        require(index > 0, "");
        require(
            _tokens[index.sub(1)].status == TokenStatus.ACTIVE,
            ""
        );
        require(
            !_tokens[index.sub(1)].emergencyUnlock,
            ""
        );
        _;
    }
    modifier canClaim(uint256 id) {
        require(claimable(id), "");
        require(
            _idVsLockedAsset[id].beneficiary == msg.sender,
            ""
        );
        _;
    }
    modifier whenNotPaused() {
        require(!_paused, "");
        _;
    }
    modifier whenPaused() {
        require(_paused, "");
        _;
    }
    constructor(
        address payable wallet,
        address lockTokenAddress,
        uint256 lockTokenFee
    )
        public
    {
        require(
            wallet != address(0),
            ""
        );
        require(
            lockTokenAddress != address(0),
            ""
        );
        _lockToken = IERC20(lockTokenAddress);
        _wallet = wallet;
        _lockTokenFee = lockTokenFee;
    }
    function paused() external view returns (bool) {
        return _paused;
    }
    function getWallet() external view returns(address) {
        return _wallet;
    }
    function getTokenCount() external view returns(uint256) {
        return _tokens.length;
    }
    function getLockToken() external view returns(address) {
        return address(_lockToken);
    }
    function getLockTokenFee() external view returns(uint256) {
        return _lockTokenFee;
    }
    function getTokens(uint256 start, uint256 length) external view returns(
        address[] memory tokenAddresses,
        uint256[] memory minAmounts,
        bool[] memory emergencyUnlocks,
        TokenStatus[] memory statuses
    )
    {
        tokenAddresses = new address[](length);
        minAmounts = new uint256[](length);
        emergencyUnlocks = new bool[](length);
        statuses = new TokenStatus[](length);

        require(start.add(length) <= _tokens.length, "");
        require(length > 0 && length <= 15, "");
        uint256 count = 0;
        for(uint256 i = start; i < start.add(length); i++) {
            tokenAddresses[count] = _tokens[i].tokenAddress;
            minAmounts[count] = _tokens[i].minAmount;
            emergencyUnlocks[count] = _tokens[i].emergencyUnlock;
            statuses[count] = _tokens[i].status;
            count = count.add(1);
        }
        return(
            tokenAddresses,
            minAmounts,
            emergencyUnlocks,
            statuses
        );
    }
    function getTokenInfo(address tokenAddress) external view returns(
        uint256 minAmount,
        bool emergencyUnlock,
        TokenStatus status,
        uint256[] memory tierAmounts,
        uint256[] memory tierFees
    )
    {
        uint256 index = _tokenVsIndex[tokenAddress];
        if(index > 0){
            index = index.sub(1);
            Token memory token = _tokens[index];
            return (
                token.minAmount,
                token.emergencyUnlock,
                token.status,
                token.tierAmounts,
                token.tierFees
            );
        }
    }
    function getLockedAsset(uint256 id) external view returns(
        address token,
        uint256 amount,
        uint256 startDate,
        uint256 endDate,
        uint256 lastLocked,
        address beneficiary,
        Status status,
        uint256 amountThreshold
    )
    {
        LockedAsset memory asset = _idVsLockedAsset[id];
        token = asset.token;
        amount = asset.amount;
        startDate = asset.startDate;
        endDate = asset.endDate;
        beneficiary = asset.beneficiary;
        status = asset.status;
        amountThreshold = asset.amountThreshold;
        lastLocked = asset.lastLocked;
        return(
            token,
            amount,
            startDate,
            endDate,
            lastLocked,
            beneficiary,
            status,
            amountThreshold
        );
    }
    function getAssetIds(
        address user
    )
        external
        view
        returns (uint256[] memory ids)
    {
        return _userVsLockIds[user];
    }
    function getAirdrops(address token) external view returns(
        address[] memory destTokens,
        uint256[] memory numerators,
        uint256[] memory denominators,
        uint256[] memory dates
    )
    {
        uint256 length = _baseTokenVsAirdrops[token].length;
        destTokens = new address[](length);
        numerators = new uint256[](length);
        denominators = new uint256[](length);
        dates = new uint256[](length);
        for(uint256 i = 0; i < length; i++){
            Airdrop memory airdrop = _baseTokenVsAirdrops[token][i];
            destTokens[i] = airdrop.destToken;
            numerators[i] = airdrop.numerator;
            denominators[i] = airdrop.denominator;
            dates[i] = airdrop.date;
        }
        return (
            destTokens,
            numerators,
            denominators,
            dates
        );
    }
    function getAirdrop(address token, uint256 index) external view returns(
        address destToken,
        uint256 numerator,
        uint256 denominator,
        uint256 date
    )
    {
        return (
            _baseTokenVsAirdrops[token][index].destToken,
            _baseTokenVsAirdrops[token][index].numerator,
            _baseTokenVsAirdrops[token][index].denominator,
            _baseTokenVsAirdrops[token][index].date
        );
    }
    function pause() external onlyOwner whenNotPaused {
        _paused = true;
        emit Paused();
    }
    function unpause() external onlyOwner whenPaused {
        _paused = false;
        emit Unpaused();
    }
    function setAirdrop(
        address baseToken,
        address destToken,
        uint256 numerator,
        uint256 denominator,
        uint256 date
    )
        external
        onlyOwner
        tokenExist(baseToken)
    {
        require(destToken != address(0), "");
        require(numerator > 0, "");
        require(denominator > 0, "");
        require(isActive(baseToken), "");
        _baseTokenVsAirdrops[baseToken].push(Airdrop({
            destToken: destToken,
            numerator: numerator,
            denominator: denominator,
            date: date
        }));
        emit AirdropAdded(
            baseToken,
            destToken,
            _baseTokenVsAirdrops[baseToken].length.sub(1),
            date,
            numerator,
            denominator
        );
    }
    function updateLockToken(address lockTokenAddress) external onlyOwner {
        require(
            lockTokenAddress != address(0),
            ""
        );
        _lockToken = IERC20(lockTokenAddress);
        emit LockTokenUpdated(lockTokenAddress);
    }
    function updateLockTokenFee(uint256 lockTokenFee) external onlyOwner {
        _lockTokenFee = lockTokenFee;
        emit LockTokenFeeUpdated(lockTokenFee);
    }
    function updateAirdrop(
        address baseToken,
        uint256 numerator,
        uint256 denominator,
        uint256 date,
        uint256 index
    )
        external
        onlyOwner
    {
        require(
            _baseTokenVsAirdrops[baseToken].length > index,
            ""
        );
        require(numerator > 0, "");
        require(denominator > 0, "");
        Airdrop storage airdrop = _baseTokenVsAirdrops[baseToken][index];
        airdrop.numerator = numerator;
        airdrop.denominator = denominator;
        airdrop.date = date;
        emit AirdropUpdated(
            baseToken,
            airdrop.destToken,
            index,
            date,
            numerator,
            denominator
        );
    }
    function setWallet(address payable wallet) external onlyOwner {
        require(
            wallet != address(0),
            ""
        );
        _wallet = wallet;

        emit WalletChanged(wallet);
    }
    function updateToken(
        address tokenAddress,
        uint256 minAmount,
        bool emergencyUnlock,
        uint256[] calldata tierAmounts,
        uint256[] calldata tierFees
    )
        external
        onlyOwner
        tokenExist(tokenAddress)
    {
        require(
            tierAmounts.length == tierFees.length,
            ""
        );
        uint256 index = _tokenVsIndex[tokenAddress].sub(1);
        Token storage token = _tokens[index];
        token.minAmount = minAmount;
        token.emergencyUnlock = emergencyUnlock;
        token.tierAmounts = tierAmounts;
        token.tierFees = tierFees;
        emit TokenUpdated(
            index,
            tokenAddress,
            minAmount,
            emergencyUnlock,
            tierAmounts,
            tierFees
        );
    }
    function addToken(
        address token,
        uint256 minAmount,
        uint256[] calldata tierAmounts,
        uint256[] calldata tierFees
    )
        external
        onlyOwner
        tokenDoesNotExist(token)
    {
        require(
            tierAmounts.length == tierFees.length,
            ""
        );
        _tokens.push(Token({
            tokenAddress: token,
            minAmount: minAmount,
            emergencyUnlock: false,
            status: TokenStatus.ACTIVE,
            tierAmounts: tierAmounts,
            tierFees: tierFees
        }));
        _tokenVsIndex[token] = _tokens.length;
        emit TokenAdded(token);
    }
    function inactivateToken(
        address token
    )
        external
        onlyOwner
        tokenExist(token)
    {
        uint256 index = _tokenVsIndex[token].sub(1);
        require(
            _tokens[index].status == TokenStatus.ACTIVE,
            ""
        );
        _tokens[index].status = TokenStatus.INACTIVE;
        emit TokenInactivated(token);
    }
    function activateToken(
        address token
    )
        external
        onlyOwner
        tokenExist(token)
    {
        uint256 index = _tokenVsIndex[token].sub(1);
        require(
            _tokens[index].status == TokenStatus.INACTIVE,
            ""
        );
        _tokens[index].status = TokenStatus.ACTIVE;
        emit TokenActivated(token);
    }
    function lock(
        address tokenAddress,
        uint256 amount,
        uint256 duration,
        address payable beneficiary,
        uint256 amountThreshold,
        bool lockFee
    )
        external
        payable
        whenNotPaused
        canLockAsset(tokenAddress)
    {
        uint256 remValue = _lock(
            tokenAddress,
            amount,
            duration,
            beneficiary,
            amountThreshold,
            msg.value,
            lockFee
        );
        require(
            remValue < 10000000000,
            ""
        );
    }
    function bulkLock(
        address tokenAddress,
        uint256[] calldata amounts,
        uint256[] calldata durations,
        address payable[] calldata beneficiaries,
        uint256[] calldata amountThresholds,
        bool lockFee
    )
        external
        payable
        whenNotPaused
        canLockAsset(tokenAddress)
    {
        uint256 remValue = msg.value;
        require(amounts.length == durations.length, "");
        require(amounts.length == beneficiaries.length, "");
        require(
            amounts.length == amountThresholds.length,
            ""
        );
        for(uint256 i = 0; i < amounts.length; i++){
            remValue = _lock(
                tokenAddress,
                amounts[i],
                durations[i],
                beneficiaries[i],
                amountThresholds[i],
                remValue,
                lockFee
            );
        }
        require(
            remValue < 10000000000,
            ""
        );
    }
    function claim(uint256 id) external canClaim(id) {
        LockedAsset memory lockedAsset = _idVsLockedAsset[id];
        if(ETH_ADDRESS == lockedAsset.token) {
            _claimMatic(
                id
            );
        }
        else {
            _claimERC20(
                id
            );
        }
        emit AssetClaimed(
            id,
            lockedAsset.beneficiary,
            lockedAsset.token
        );
    }
    function addAmount(
        uint256 id,
        uint256 amount,
        bool lockFee
    )
        external
        payable
        whenNotPaused
    {
        LockedAsset storage lockedAsset = _idVsLockedAsset[id];
        require(lockedAsset.status == Status.OPEN, "");
        Token memory token = _tokens[_tokenVsIndex[lockedAsset.token].sub(1)];
        _claimAirdroppedTokens(
            lockedAsset.token,
            lockedAsset.lastLocked,
            lockedAsset.amount
        );
        uint256 fee = 0;
        uint256 newAmount = 0;
        (fee, newAmount) = _calculateFee(amount, lockFee, token);
        if(lockFee) {
            _lockToken.safeTransferFrom(msg.sender, _wallet, _lockTokenFee);
        }
        if(ETH_ADDRESS == lockedAsset.token) {
            require(amount == msg.value, "");

            if(!lockFee) {
                (bool success,) = _wallet.call.value(fee)("");
                require(success, "");
            }
        }
        else {
            if(!lockFee){
                IERC20(lockedAsset.token).safeTransferFrom(msg.sender, _wallet, fee);
            }
            IERC20(lockedAsset.token).safeTransferFrom(msg.sender, address(this), newAmount);
        }
        lockedAsset.amount = lockedAsset.amount.add(newAmount);
        lockedAsset.lastLocked = block.timestamp;
        emit AmountAdded(lockedAsset.beneficiary, id, newAmount);
    }
    function claimable(uint256 id) public view returns(bool){
        LockedAsset memory asset = _idVsLockedAsset[id];
        if(
            asset.status == Status.OPEN &&
            (
                asset.endDate <= block.timestamp ||
                _tokens[_tokenVsIndex[asset.token].sub(1)].emergencyUnlock ||
                (asset.amountThreshold > 0 && asset.amount >= asset.amountThreshold)
            )
        )
        {
            return true;
        }
        return false;
    }
    function isActive(address token) public view returns(bool) {
        uint256 index = _tokenVsIndex[token];
        if(index > 0){
            return (_tokens[index.sub(1)].status == TokenStatus.ACTIVE);
        }
        return false;
    }
    function _lock(
        address tokenAddress,
        uint256 amount,
        uint256 duration,
        address payable beneficiary,
        uint256 amountThreshold,
        uint256 value,
        bool lockFee
    )
        private
        returns(uint256)
    {
        require(
            beneficiary != address(0),
            ""
        );
        Token memory token = _tokens[_tokenVsIndex[tokenAddress].sub(1)];
        require(
            amount >= token.minAmount,
            ""
        );
        uint256 endDate = block.timestamp.add(duration);
        uint256 fee = 0;
        uint256 newAmount = 0;
        (fee, newAmount) = _calculateFee(amount, lockFee, token);
        uint256 remValue = value;
        if(ETH_ADDRESS == tokenAddress) {
            _lockMatic(
                newAmount,
                fee,
                endDate,
                beneficiary,
                amountThreshold,
                value,
                lockFee
            );
            remValue = remValue.sub(amount);
        }
        else {
            _lockERC20(
                tokenAddress,
                newAmount,
                fee,
                endDate,
                beneficiary,
                amountThreshold,
                lockFee
            );
        }
        emit AssetLocked(
            tokenAddress,
            msg.sender,
            beneficiary,
            _lockId,
            newAmount,
            block.timestamp,
            endDate,
            lockFee,
            fee
        );
        return remValue;
    }
    function _lockMatic(
        uint256 amount,
        uint256 fee,
        uint256 endDate,
        address payable beneficiary,
        uint256 amountThreshold,
        uint256 value,
        bool lockFee
    )
        private
    {
        if(lockFee){
	    require(value >= amount, "");
            _lockToken.safeTransferFrom(msg.sender, _wallet, fee);
        }
        else {
            require(value >= amount.add(fee), "");
            (bool success,) = _wallet.call.value(fee)("");
            require(success, "");
        }
        _lockId = _lockId.add(1);
        _idVsLockedAsset[_lockId] = LockedAsset({
            token: ETH_ADDRESS,
            amount: amount,
            startDate: block.timestamp,
            endDate: endDate,
            lastLocked: block.timestamp,
            beneficiary: beneficiary,
            status: Status.OPEN,
            amountThreshold: amountThreshold
        });
        _userVsLockIds[beneficiary].push(_lockId);
    }
    function _lockERC20(
        address token,
        uint256 amount,
        uint256 fee,
        uint256 endDate,
        address payable beneficiary,
        uint256 amountThreshold,
        bool lockFee
    )
        private
    {
        if(lockFee){
            _lockToken.safeTransferFrom(msg.sender, _wallet, fee);
        }
        else {
            IERC20(token).safeTransferFrom(msg.sender, _wallet, fee);
        }
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        _lockId = _lockId.add(1);
        _idVsLockedAsset[_lockId] = LockedAsset({
            token: token,
            amount: amount,
            startDate: block.timestamp,
            endDate: endDate,
            lastLocked: block.timestamp,
            beneficiary: beneficiary,
            status: Status.OPEN,
            amountThreshold: amountThreshold
        });
        _userVsLockIds[beneficiary].push(_lockId);
    }
    function _claimMatic(uint256 id) private {
        LockedAsset storage asset = _idVsLockedAsset[id];
        asset.status = Status.CLOSED;
        (bool success,) = msg.sender.call.value(asset.amount)("");
        require(success, "");
        _claimAirdroppedTokens(
            asset.token,
            asset.lastLocked,
            asset.amount
        );
    }
    function _claimERC20(uint256 id) private {
        LockedAsset storage asset = _idVsLockedAsset[id];
        asset.status = Status.CLOSED;
        IERC20(asset.token).safeTransfer(msg.sender, asset.amount);
        _claimAirdroppedTokens(
            asset.token,
            asset.lastLocked,
            asset.amount
        );
    }
    function _claimAirdroppedTokens(
        address baseToken,
        uint256 lastLocked,
        uint256 amount
    )
        private
    {
        for(uint256 i = 0; i < _baseTokenVsAirdrops[baseToken].length; i++) {
            Airdrop memory airdrop = _baseTokenVsAirdrops[baseToken][i];
            if(airdrop.date > lastLocked && airdrop.date < block.timestamp) {
                uint256 airdropAmount = amount.mul(airdrop.numerator).div(airdrop.denominator);
                IERC20(airdrop.destToken).safeTransfer(msg.sender, airdropAmount);
                emit TokensAirdropped(airdrop.destToken, airdropAmount);
            }
        }
    }
    function _calculateFee(
        uint256 amount,
        bool lockFee,
        Token memory token
    )
        private
        view
        returns(uint256 fee, uint256 newAmount)
    {
        newAmount = amount;
        if(lockFee){
            fee = _lockTokenFee;
        }
        else{
            uint256 tempAmount = amount;
            for(
            uint256 i = 0; (i < token.tierAmounts.length - 1 && tempAmount > 0); i++
            )
            {
                if(tempAmount >= token.tierAmounts[i]){
                    tempAmount = tempAmount.sub(token.tierAmounts[i]);
                    fee = fee.add(token.tierAmounts[i].mul(token.tierFees[i]).div(10000));
                }
                else{
                    fee = fee.add(tempAmount.mul(token.tierFees[i]).div(10000));
                    tempAmount = 0;
                }
            }
            fee = fee.add(
                tempAmount.mul(token.tierFees[token.tierAmounts.length - 1])
                .div(10000)
            );
            newAmount = amount.sub(fee);
        }
        return(fee, newAmount);
    }
}