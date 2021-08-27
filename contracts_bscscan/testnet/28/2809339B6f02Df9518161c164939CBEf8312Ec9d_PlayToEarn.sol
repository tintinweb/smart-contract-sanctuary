/**
 *Submitted for verification at BscScan.com on 2021-08-27
*/

// Buy Earn 
// Login 

// Claim Reward 
// Admin set claim

// Unlock BIRD token
// Withdraw BIRD, lock 3 days

// Lock Token 
// Unlock Token 
// Withdraw token DEB 1 days

pragma solidity ^0.8.0;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) { return functionCall(target, data, "Address: low-level call failed"); }
    function functionCall( address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) { return functionCallWithValue(target, data, 0, errorMessage); }
    function functionCallWithValue( address target, bytes memory data, uint256 value ) internal returns (bytes memory) { return functionCallWithValue( target, data, value, "Address: low-level call with value failed");}
    function functionCallWithValue( address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value,"Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) { return functionStaticCall( target, data, "Address: low-level static call failed"); }
    function functionStaticCall( address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) { return functionDelegateCall( target, data, "Address: low-level delegate call failed" ); }
    function functionDelegateCall( address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult( bool success, bytes memory returndata, string memory errorMessage ) private pure returns (bytes memory) {
        if (success) { return returndata;} else {
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) { return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) { return interfaceId == type(IERC165).interfaceId; }
}
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }
    mapping(bytes32 => RoleData) private _roles;
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool){
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    function hasRole(bytes32 role, address account) public view override returns (bool) { return _roles[role].members[account]; }
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) { return _roles[role].adminRole; }
    function grantRole(bytes32 role, address account) public virtual override { 
        require( hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to grant");
        _grantRole(role, account);
    }
    function revokeRole(bytes32 role, address account) public virtual override {
        require( hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to revoke");
        _revokeRole(role, account);
    }
    function renounceRole(bytes32 role, address account) public virtual override
    {
        require( account == _msgSender(), "AccessControl: can only renounce roles for self" );
        _revokeRole(role, account);
    }
    function _setupRole(bytes32 role, address account) internal virtual { _grantRole(role, account); }
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }
    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }
    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}
library Counters {
    struct Counter {
        uint256 _value;
    }
    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }
    function increment(Counter storage counter) internal {
        counter._value += 1;
    }
    function decrement(Counter storage counter) internal {
        counter._value = counter._value - 1;
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
    function sub(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
library SafeERC20 {
    using Address for address;
    function safeTransfer(IERC20 token,address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom( IERC20 token,address from,address to,uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(IERC20 token,address spender,uint256 value) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance( IERC20 token,address spender,uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
interface BirdMask {
    function mint(address _to, uint256 _tokenId, string calldata _tokenURI ) external returns (bool);
}
interface Bird {
    function mintBird(address _to, uint256 _amount ) external returns (bool);
}
contract PlayToEarn is AccessControl {
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    bytes32 public constant CREATOR_ADMIN = keccak256("CREATOR_ADMIN");
    IERC20 public tokenDebird;
    Bird public tokenBird;
    IERC20 public tokenUsdt;
    BirdMask public birdMask;
    uint256 public totalEgg = 10000;
    uint256 public currentEgg;
    uint256 public priceEgg = 2000000000000000000000; // 2,000 DEB
    address public receivePlayToEarn = 0xAaD88154D6b5338be746e53021bB8BF75F783a78;
    string public urlToken = "localhost:5000/";
    uint256 public profitPerPlayLevel1 = 5 * 10**16;
    uint256 public profitPerPlayLevel2 = 8 * 10**16;
    uint256 public profitPerPlayLevel3 = 12 * 10**16;
    uint256 public profitPerPlayLevel4 = 15 * 10**16;
    uint256 timeOfaDay = 86400; // 1 day 
    uint256 timeLockThreeDay = 259200; // 3 days
    uint256 openTime;
    uint256 public limitPlayPerDay = 5;
    uint256 public amountPerLock = 5000000000000000000000;
    mapping(uint256 => uint256) public levelBird; // tokenId => level
    mapping(uint256 => uint256) public playDay; 
    // mapping(uint256 => uint256) public numberPlayPerDay;
    mapping(uint256 => mapping(uint256 => uint256)) public numberPlayPerDay; // tokenId => day = > numberPlay 
    mapping(address => uint256) public amountDebirdLock; 
    mapping(address => uint256) public balanceBird;
    uint256 public maxPointPerPlay = 200; // level => maxProfit 
    event Buy(address indexed user, uint256 tokenId, uint256 blockTime);
    event Deposit(address indexed user, uint256 amount, uint256 blockTime);
    event Withdraw(address indexed user,  uint256 amount, uint256 blockTime);
    event WithdrawOfBird(address indexed user,  uint256 amount, uint256 blockTime);
    // event Claim(address indexed user, uint256 tokenId, uint256 playId, uint256 blockTime);
    constructor(address minter, address _tokenDebird, address _tokenBird, address _tokenUsdt, address _birdMask){
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CREATOR_ADMIN, minter);
        tokenDebird = IERC20(_tokenDebird);
        tokenBird = Bird(_tokenBird);
        tokenUsdt = IERC20(_tokenUsdt);
        birdMask = BirdMask(_birdMask);
        openTime = block.timestamp;
    }

    struct WithdrawInfo {
        uint256 amount;
        uint256 timwWithdraw;
        uint256 status;
    }
    struct WithdrawBird {
        uint256 amount;
        uint256 timwWithdraw;
        uint256 status;
    }
    mapping (address => WithdrawInfo[]) public withdrawInfo;
    mapping (address => WithdrawBird[]) public withdrawBird;
    mapping (address => mapping(uint256 => uint256)) public playId; // playId[player][playnumber] = tokenId
    mapping(address => uint256) public numberPlayMember;
    function getWithdrawInfoByAddress(address _address) public view returns (WithdrawInfo[]  memory) {
        return withdrawInfo[_address];
    }
    function getWithdrawBirdByAddress(address _address) public view returns (WithdrawBird[]  memory) {
        return withdrawBird[_address];
    }
    function buyEgg(uint256 tokenId) public {
        require(currentEgg < totalEgg, "Sold out");
        uint256 numberEgg = randomNumber(tokenId);
        string memory uri = string(abi.encodePacked(urlToken, tokenId));
        birdMask.mint(msg.sender , tokenId, uri);
        tokenDebird.safeTransferFrom(msg.sender, receivePlayToEarn , priceEgg);
        currentEgg.add(1);
        if(numberEgg <= 50){ levelBird[tokenId] = 1; }
        if(numberEgg > 50 && numberEgg <= 80){ levelBird[tokenId] = 2; }
        if(numberEgg > 80 && numberEgg <= 95){ levelBird[tokenId] = 3; }
        if(numberEgg > 95){ levelBird[tokenId] = 4; }
        emit Buy(msg.sender, tokenId, block.timestamp);
    }
    function randomNumber(uint256 _randNonce) public view returns(uint256){
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _randNonce))) % 100;
        return (random + 1);
    }
    function loginGame(uint256 tokenId, uint256 _playId) public {
        // uint256 numberPlay = getNumberPlayInDay(msg.sender, tokenId);
        // require(numberPlay != 3 , "You have run out of turns for the day");

        // if(numberPlay == 1) {
        //     playDay[tokenId] = getCurrentDay();
        //     numberPlayPerDay[tokenId] = 1;
        // }
        // if(numberPlay == 2) {
        //     numberPlayPerDay[tokenId] = numberPlayPerDay[tokenId].add(1);
        // }
        
        // numberPlayMember[msg.sender] = numberPlayMember[msg.sender].add(1);
        require(playId[msg.sender][_playId] == 0, "playId exist");
        uint256 currentDay = getCurrentDay();
        uint256 nummberPlay = numberPlayPerDay[tokenId][currentDay];
        require(nummberPlay < getLimitPlay(msg.sender), "Enough plays for the day");
        numberPlayPerDay[tokenId][currentDay] = numberPlayPerDay[tokenId][currentDay].add(1);
        numberPlayMember[msg.sender] = numberPlayMember[msg.sender].add(1);
        playId[msg.sender][_playId] = tokenId;
    }
    // function claimBird(uint256 _tokenId, uint256 _playId) public {
    //     emit Claim(msg.sender, _tokenId, _playId, block.timestamp);
    // }
    function adminSetClaim(address player, uint256 _amount) public {
        require(hasRole(CREATOR_ADMIN, msg.sender), "Caller is not a admin");
        balanceBird[player] = balanceBird[player].add(_amount);
    }
    function unlockBird(uint256 _amount) public {
        require(balanceBird[msg.sender] >= _amount, "The withdrawal amount is greater than the amount");
        withdrawBird[msg.sender].push(WithdrawBird(_amount, block.timestamp, 0));
        balanceBird[msg.sender] = balanceBird[msg.sender].sub(_amount);
    }
    function withdrawlBird(uint256 _id) public {
        uint256 status = withdrawBird[msg.sender][_id].status;
        uint256 amount = withdrawBird[msg.sender][_id].amount;
        uint256 timeWithdraw = withdrawBird[msg.sender][_id].timwWithdraw;
        require(status == 0, 'You have withdrawn');
        require(amount > 0 , 'withdraw: not good');
        require((block.timestamp - timeWithdraw) > timeLockThreeDay, 'you are still in lock');
        withdrawBird[msg.sender][_id].status = 1; 
        tokenBird.mintBird(msg.sender, amount);
        emit WithdrawOfBird(msg.sender, amount, block.timestamp);
    }
    function getCurrentDay() public view returns(uint256){
        uint256 current = (block.timestamp - openTime).div(timeOfaDay);
        return current;
    }
    // function getNumberPlayInDay(address player, uint256 tokenId) public view returns(uint256){
    //     uint256 currentDay = getCurrentDay();
    //     uint256 dayOfTokenId = playDay[tokenId];
    //     uint256 result;
    //     if(dayOfTokenId < currentDay){
    //         // update playDay and Reset numberPlayPerDay = 1;
    //         result = 1;
    //     }else {
    //         if(numberPlayPerDay[tokenId] < getLimitPlay(player)){
    //             //update numberPlayPerDay +1
    //             result = 2;
    //         }else{
    //             result = 3;
    //         }
    //     }
    //     return result;
    // }   

    function getLimitPlay(address player) public view returns(uint256) {
        uint256 morePlayInDay =  amountDebirdLock[player].div(amountPerLock);
        uint256 limitPlay = limitPlayPerDay + morePlayInDay;
        return limitPlay;
    }

    function lockTokenDebird(uint256 _amount) public {
        tokenDebird.safeTransferFrom(address(msg.sender), address(this), _amount);
        amountDebirdLock[msg.sender] = amountDebirdLock[msg.sender].add(_amount);
        emit Deposit(msg.sender, _amount, block.timestamp);
    }

    function unlockTokenDebird(uint256 _amount) public {
        require(amountDebirdLock[msg.sender] >= _amount, "The withdrawal amount is greater than the amount of the lock");
        withdrawInfo[msg.sender].push(WithdrawInfo(_amount, block.timestamp, 0)); 
        amountDebirdLock[msg.sender] = amountDebirdLock[msg.sender].sub(_amount);
    }

    function withdrawTokenDebird(uint256 _id) public {
        uint256 status = withdrawInfo[msg.sender][_id].status;
        uint256 amount = withdrawInfo[msg.sender][_id].amount;
        uint256 timeWithdraw = withdrawInfo[msg.sender][_id].timwWithdraw;
        require(status == 0, 'You have withdrawn');
        require(amount > 0 , 'withdraw: not good');
        require((block.timestamp - timeWithdraw) > timeOfaDay, 'you are still in lock');
        withdrawInfo[msg.sender][_id].status = 1;
        tokenDebird.safeTransfer(address(msg.sender), amount);
        emit Withdraw(msg.sender, amount, block.timestamp);
    }
}