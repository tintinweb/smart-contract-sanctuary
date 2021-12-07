/**
 *Submitted for verification at BscScan.com on 2021-12-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
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

        (bool success, bytes memory returndata) = target.call(data);
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

interface IBEP20 {
    
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom( address sender, address recipient, uint256 amount) external returns (bool);
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
    
    constructor()  {}

    function _msgSender() internal view returns (address ) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract FundRaise is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    
    uint256 public PoolID;
    uint256 public creatorReward = 990;
    uint256 public ownerReward = 10;

    uint256 public poolCreationFee;
    uint256 public userFee;
    uint256 public transferFee;
    address public wallet;
    
    //PoolInfo for store the pool details.
    struct PoolInfo {
        address poolCreator;
        uint256 poolID;
        IBEP20 depositToken;
        uint256 userLimit;
        uint256 minDeposit;
        uint256 maxDeposit;
        uint256 startBlock;
        uint256 endBlock;
        uint256 tokenLimit;
    }
    
    struct PoolReward{
        uint256 depositTokens;
        uint256 members;
        bool claimed;
    }
    
    //UserInfo for store the user details.
    struct UserInfo {
        uint256 amount;
        uint256 lastDeposit;
        bool active;
    }
    
    PoolInfo[] public poolInfo;         //PoolInfo[] for view the pool details
    mapping(address => mapping(uint256 => UserInfo)) public userInfo; //view the user details
    mapping(uint256 => PoolReward) public rewards;
    
    event CreatePool(address indexed creator, uint256 PoolID, uint256 poolFee);
    event updatePool(address indexed account, uint256  poolID, uint256 maxUsers, uint256 indexed minDeposit, uint256 indexed maxDeposit);
    event Deposit(address indexed user, uint256 indexed poolID, uint256 indexed amount, uint256 feeAmount);
    event Withdraw(address indexed user, uint256 indexed poolID, uint256 indexed amount);
    event AdminDeposit(address indexed creator, uint256 poolID, uint256 indexed amount, address indexed rewardToken);
    event UpdateReward(address indexed owner, uint256 indexed AdminReward, uint256 indexed CreatorReward);
    event NewDepositor(address indexed depositor, uint256 indexed PoolID);
    event CreatorClaim(address indexed creator, uint256 indexed tokenAmount, uint256 indexed claimTime);
    event EmergencySafe(address indexed receiver, address indexed tokenAddress, uint256 indexed tokenAmount);
    event SetUserFee(address indexed owner, uint256 indexed newFee);
    event SetCreatorFee(address indexed owner, uint256 indexed newFee);
    event SetWalletAddress(address indexed owner, address indexed newWallet );
    event SetTransferFee(address indexed owner, uint256 newTransferFee);
    
    constructor(uint256 _poolCreationFee, uint256 _userFee,uint256 _transferFee, address _wallet){
        poolCreationFee = _poolCreationFee;
        userFee = _userFee;
        transferFee = _transferFee;
        wallet = _wallet;
    }

    function updateUserFee(uint256 newFee) external onlyOwner {
        userFee = newFee;
        emit SetUserFee(msg.sender, newFee);
    }

    function updateTransferFee(uint256 _transferFee) external onlyOwner {
        transferFee = _transferFee;
        emit SetTransferFee(msg.sender, _transferFee);
    }

    function updatePoolCreationFee(uint256 newFee) external onlyOwner {
        poolCreationFee = newFee;
        emit SetCreatorFee(msg.sender, newFee);
    }

    function updateWallet(address _walletAddress) external onlyOwner {
        require(_walletAddress != address(0x0),"wallet must not zero-address");
        wallet = _walletAddress;
        emit SetWalletAddress(msg.sender, _walletAddress);
    }
    
    function updateRewarPercentage(uint256 _AdminReward, uint256 _CreaterReward) external onlyOwner {
        require( _AdminReward.add(_CreaterReward) == 1000,"Invalid reward percentage");
        ownerReward = _AdminReward;
        creatorReward = _CreaterReward;
        
        emit UpdateReward(msg.sender, _AdminReward, _CreaterReward);
    }
    
    function createPool( PoolInfo memory _poolDetails) external payable {
        require(poolCreationFee <= msg.value,"bad fee amount");
        poolInfo.push(PoolInfo({
            poolCreator : msg.sender,
            poolID : PoolID,
            depositToken : _poolDetails.depositToken,
            userLimit: _poolDetails.userLimit,
            minDeposit: _poolDetails.minDeposit,
            maxDeposit: _poolDetails.maxDeposit,
            startBlock: _poolDetails.startBlock,
            endBlock: _poolDetails.endBlock,
            tokenLimit: _poolDetails.tokenLimit
            }));
        emit CreatePool(msg.sender, PoolID, msg.value);
        PoolID++;
        require(payable(wallet).send(poolCreationFee),"wallet fee failed");
    }
    
    function setPool(uint256 _poolID, uint256 _maxUsers, uint256 _minDeposit, uint256 _maxDeposit) external {
        PoolInfo storage pool = poolInfo[_poolID];
        require((pool.poolCreator == msg.sender) || (msg.sender == owner()),"SetPool :: Caller is un authonticator");
        pool.userLimit = _maxUsers;
        pool.minDeposit = _minDeposit;
        pool.maxDeposit = _maxDeposit;
        
        emit updatePool(msg.sender, _poolID, _maxUsers, _minDeposit, _maxDeposit);
    }
    
    function deposit(uint256 _poolID, uint256 _amount) external payable {
        PoolInfo storage pool = poolInfo[_poolID];
        UserInfo storage user = userInfo[msg.sender][_poolID];
        require(pool.tokenLimit >= rewards[_poolID].depositTokens.add(_amount),"Deposit :: deposit amount reached" );
        require(pool.userLimit >= rewards[_poolID].members,"Deposit :: pool depositor reached");
        require((pool.startBlock <= block.number) && (pool.endBlock >= block.number),"Deposit block exceed");
        require(((pool.minDeposit <= _amount) && (pool.maxDeposit >= _amount)) || ((pool.minDeposit <= msg.value) && (pool.maxDeposit >= msg.value)),"Invalid amounts to deposit");
        require(msg.value >= userFee,"bad fee amount");

        if(address(pool.depositToken) == address(0x0)){
            user.amount = user.amount.add(msg.value.sub(userFee,"invalid amount"));
            rewards[_poolID].depositTokens += msg.value.sub(userFee);
            emit Deposit(msg.sender, _poolID, msg.value.sub(userFee), userFee);
        } else {
            user.amount = user.amount.add(_amount);
            user.lastDeposit = block.timestamp;
            rewards[_poolID].depositTokens += _amount;
            
            pool.depositToken.transferFrom(msg.sender, address(this), _amount);
            emit Deposit(msg.sender, _poolID, _amount, msg.value);
        }
        if(!user.active){ 
            rewards[_poolID].members++;
            user.active = true;
            
            emit NewDepositor(msg.sender, _poolID);
        }
        require(payable(wallet).send(userFee),"wallet fee failed");
    }
    
    function withdraw(uint256 _poolID, uint256 _amount) external payable nonReentrant {
        PoolInfo storage pool = poolInfo[_poolID];
        UserInfo storage user = userInfo[msg.sender][_poolID];
        require(user.active,"Withdraw :: user is not active");
        require(pool.endBlock >= block.number ,"pool endBlock reached");
        require(msg.value >= userFee,"bad fee amount");
            if(address(pool.depositToken) == address(0x0)){
                user.amount = user.amount.sub(_amount,"Withdraw :: exceed Withdraw value");
                rewards[_poolID].depositTokens = rewards[_poolID].depositTokens.sub(_amount,"");
                require(payable(msg.sender).send(_amount),"Withdraw :: Transaction failed");
            } else {
                user.amount = user.amount.sub(_amount,"Withdraw :: exceed Withdraw value");
                rewards[_poolID].depositTokens = rewards[_poolID].depositTokens.sub(_amount,"");
                
                pool.depositToken.transfer(msg.sender, _amount);
            }
            require(payable(wallet).send(userFee),"wallet fee failed");
        if(user.amount == 0 && !rewards[_poolID].claimed){ 
            rewards[_poolID].members--;
            user.active = false;
        }
        emit Withdraw(msg.sender, _poolID, _amount);
    }
    
    function claim(uint256 _poolID) external  nonReentrant {
        PoolInfo storage pool = poolInfo[_poolID];
        require(!rewards[_poolID].claimed,"Claim :: pool tokens already claimed");
        require(pool.poolCreator == msg.sender,"Caller is not a pool creator");
        require(pool.endBlock < block.number ,"pool endBlock reached");
        uint256 tokens = rewards[_poolID].depositTokens;
        uint256 ownerTokens = tokens.mul(ownerReward).div(1000);
        if(address(pool.depositToken) == address(0x0)){
            require(payable(owner()).send(ownerTokens),"transfer to owner failed");
            require(payable(msg.sender).send(tokens.sub(ownerTokens)),"transfer to pool creator failed");
        } else {
            pool.depositToken.transfer(owner(), ownerTokens);
            pool.depositToken.transfer(msg.sender, tokens.sub(ownerTokens));
        }
        rewards[_poolID].claimed = true;
        rewards[_poolID].depositTokens = 0;
        emit CreatorClaim(msg.sender, tokens.sub(ownerTokens), block.timestamp);
    }
    
    function transferToHolders(uint256 _poolID,IBEP20 _token, address[] calldata recipients, uint256[] calldata amounts, bool isPool) external payable nonReentrant {
        require(msg.value >= transferFee,"invalid transfer fee");
        if(isPool){
            PoolInfo storage pool = poolInfo[_poolID];
            require(pool.endBlock <= block.number ,"pool endBlock reached");
            require(pool.poolCreator == msg.sender,"Caller is not a pool creator");
            require(!rewards[_poolID].claimed,"pool already distributed");
            rewards[_poolID].claimed = true;
        }

        require(recipients.length == amounts.length,"given details are invalid.");
        bytes[] memory calls = new bytes[](recipients.length);
        for (uint256 i = 0; i < recipients.length; i++) {
            calls[i] = abi.encodeWithSignature("transferFrom(address,address,uint256)",msg.sender, recipients[i], amounts[i]);
        }
        require(payable(wallet).send(msg.value),"wallet fee failed");
        bytes[] memory results = multicall(address(_token), calls);
        for (uint256 i = 0; i < results.length; i++) {
            require(abi.decode(results[i], (bool)));
        }
    }
    
    function multicall(address token,bytes[] memory data) internal returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(token,data[i]);
        }
        return results;
    }
    
    function emergency(address _tokenAddress,address _to, uint256 _tokenAmount) external onlyOwner {
        if(_tokenAddress == address(0x0)){
            require(payable(_to).send(_tokenAmount),"emergency :: transaction failed");
        }else{
            IBEP20(_tokenAddress).transfer(_to, _tokenAmount);
        }
        emit EmergencySafe(_to, _tokenAddress, _tokenAmount);
    }
}