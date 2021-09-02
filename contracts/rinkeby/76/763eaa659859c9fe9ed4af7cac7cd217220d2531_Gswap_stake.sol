/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

// File: src/lib/Ownable.sol

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// File: src/lib/Authorizable.sol

contract Authorizable is Ownable {

    mapping(address => bool) public authorized;

    modifier onlyAuthorized() {
        require(authorized[msg.sender] || owner == msg.sender);
        _;
    }

    function addAuthorized(address _toAdd) onlyOwner public {
        require(_toAdd != address(0));
        authorized[_toAdd] = true;
    }

    function removeAuthorized(address _toRemove) onlyOwner public {
        require(_toRemove != address(0));
        require(_toRemove != msg.sender);
        authorized[_toRemove] = false;
    }

}

// File: src/lib/IERC20.sol

//pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: src/lib/SafeMath.sol

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

// File: src/gswap/2_ipo.sol

// SPDX-License-Identifier: MIT
pragma solidity =0.6.6;
pragma experimental ABIEncoderV2;





interface INFT {
    function mintNft(address _to, string calldata _symbol, string calldata  _name, string calldata _icon, uint _goal) external returns (uint256);
    function addFile(uint _tokenId, string calldata _file) external;
    function tokenByTokenId(uint _tokenId) external returns (string memory, string memory, string memory);
}
interface IFactory {
    function createContract(string calldata name, string calldata symbol, bytes32 salt) external returns (address);
}

contract Gswap_stake is Authorizable{
    using SafeMath for uint;
    uint private windowSeconds = 60*60*24*180;     //融资持续时间:180天, 计量单位：秒
    uint private ipoGiftLimit = 1000;                 //前1000家ipo送usdg
    uint private ipoGif = 30000*1000000000;                    //ipo送30000个usdg

    INFT public nft;
    IERC20 public usdg;
    IFactory public factory;
    uint public cost;

    mapping (uint => address) public tokenHolders;
    mapping (uint => address) public tokenErc20Map; // 发的token
    mapping (uint => uint) public goalMap;  //融资目标
    mapping (uint => mapping (address => uint)) public tokenUserMap;   //用户融资记录
    mapping (uint => mapping (address => uint)) public tokenUserGiftMap;   //系统送给用户融资记录

    mapping (uint => uint) public tokenUserCount;           //融资用户地址表, UI用
    mapping (uint => address[]) public tokenUserAddrList;   //融资用户地址数, UI用

    mapping (uint => uint) public tokenStaked;   //已融资总数
    mapping (uint => uint) public tokenEnds;  //融资关闭时间


    event GovWithdrawToken(address indexed token, address indexed to, uint256 value);
    event StakeEnv( address indexed from, uint tokenId, uint256 value);

    constructor(address _usdg,address _nft, address _factory, uint _cost )public {
        setParams(_usdg, _nft, _factory, _cost);
    }

    function ipo(string memory _symbol, string memory _name, string memory _icon,uint _goal) public {
        uint allowed = usdg.allowance(msg.sender,address(this));
        uint balanced = usdg.balanceOf(msg.sender);
        require(allowed >= cost, "!allowed");
        require(balanced >= cost, "!balanced");
        // usdg.transferFrom( msg.sender,address(this), cost);

        // uint tokenId = nft.mintNft(msg.sender,_symbol,_name,_icon,_goal);
        // goalMap[tokenId] = _goal;
        // tokenHolders[tokenId] = msg.sender;
        // // 前1000个送usdg质押
        // if(tokenId < ipoGiftLimit){
        //     giftStake(msg.sender,tokenId,ipoGif);
        // }
    }

    function addFile(uint _tokenId, string memory _file)public{
        require(tokenHolders[_tokenId] == msg.sender, "not authorized");
        nft.addFile(_tokenId,_file);
    }

    // 开启众筹
    function start(uint _tokenId)public{
        require(tokenHolders[_tokenId] == msg.sender, "not authorized");
        tokenEnds[_tokenId] = block.timestamp+windowSeconds;
    }

    function stake(uint _tokenId, uint _value)public{
        _value = doStake(msg.sender, _tokenId, _value);

        uint allowed = usdg.allowance(msg.sender,address(this));
        uint balanced = usdg.balanceOf(msg.sender);
        require(allowed >= _value, "!allowed");
        require(balanced >= _value, "!balanced");

        usdg.transferFrom( msg.sender,address(this), _value);

    }

    // 失败后回退质押
    function fallbackWithdraw(uint _tokenId) public{
        require(isFault(_tokenId), "not fault");
        uint value = userStaked(msg.sender,_tokenId);
        require(value > 0, "no staked");
        usdg.transfer( msg.sender, value);
    }
    // 成功后发行token
    function successIssue(uint _tokenId) public{
//        require(isSuccess(_tokenId), "not success");
        (string memory symbol,string memory name,) = nft.tokenByTokenId( _tokenId);
        address token = factory.createContract( name,  symbol, bytes32(_tokenId));
        tokenErc20Map[_tokenId] = token;
    }

    // 只读方法
    // 列出一个IPO下面的所有stake状况
    function stakeDetail(uint _tokenId) public view returns (address[] memory,uint[] memory){
        uint[] memory values;
        uint count = tokenUserCount[_tokenId];
        mapping (address => uint) storage uMap = tokenUserMap[_tokenId];   //用户融资记录
        address[] storage aList = tokenUserAddrList[_tokenId];
        for (uint i=0; i < count; i++) {
            values[i] = uMap[aList[i]];
        }
        return (aList,values);
    }
    // 用户的质押量，过程中或成功后用
    function userStaked(address _addr, uint _tokenId) public view returns (uint) {
        return tokenUserMap[_tokenId][_addr];
    }
    // 用户的可以退的质押量（减去系统送的)，退回的时候用
    function pureUserStaked(address _addr, uint _tokenId) public view returns (uint) {
        return tokenUserMap[_tokenId][_addr] - tokenUserGiftMap[_tokenId][_addr];
    }

    // 是否已融资失败(超时&&数量没到)
    function isFault(uint _tokenId) public view returns (bool) {
        uint end = tokenEnds[_tokenId];
        uint goal = goalMap[_tokenId];
        if(end > 0 && block.timestamp >= end){
            if(goal > 0 &&  tokenStaked[_tokenId] < goal ){
                return true;
            }
        }
        return false;
    }

    // 是否已融资成功
    function isSuccess(uint _tokenId) public view returns (bool) {
        uint goal = goalMap[_tokenId];
        if(goal > 0 && tokenStaked[_tokenId] >= goal){
            return true;
        }
        return false;
    }
    // 是否还能质押
    function canStake(uint _tokenId) public view returns (bool) {
        // check time
        uint end = tokenEnds[_tokenId];
        if(end == 0 || end < block.timestamp){
            return false;
        }
        // 不超出上限
        uint goal = goalMap[_tokenId];
        uint staked = tokenStaked[_tokenId];
        if(staked >= goal){
            return false;
        }
        return true;
    }


    // 私有方法
    // 执行stake
    function doStake(address _to, uint _tokenId, uint _value) private returns (uint){
        if(!canStake(_tokenId)){
            return 0;
        }
        uint goal = goalMap[_tokenId];
        uint staked = tokenStaked[_tokenId];
        if(staked+_value > goal){
            _value =  goal - staked;
        }
        uint uStaked = tokenUserMap[_tokenId][_to];
        tokenUserMap[_tokenId][_to] = uStaked + _value;
        tokenStaked[_tokenId] = tokenStaked[_tokenId] + _value;

        if(uStaked == 0){
            uint index = tokenUserCount[_tokenId];
            tokenUserAddrList[_tokenId][index] = _to;
            tokenUserCount[_tokenId] = index+1;
        }

        emit StakeEnv(_to, _tokenId, _value);
        return _value;
    }

    function giftStake(address _to, uint _tokenId, uint _value) private{
        _value = doStake(_to, _tokenId, _value);
        tokenUserGiftMap[_tokenId][_to] = tokenUserGiftMap[_tokenId][_to] + _value;
    }

    //owner方法
    function govWithdraUsdg(uint256 _amount)onlyOwner public {
        require(_amount > 0, "!zero input");
        usdg.transfer( msg.sender, _amount);
        emit GovWithdrawToken(address(usdg), msg.sender, _amount);
    }

    function setParams(address _usdg,address _nft, address _factory, uint _cost)onlyOwner public {
        usdg = IERC20(_usdg);
        nft = INFT(_nft);
        factory = IFactory(_factory);
        cost = _cost;
    }

    //onlyAuthorized方法
    function authedSendUsdg(address _to, uint _value) external onlyAuthorized{
        usdg.transfer( _to, _value);
    }

    function authedSendToken(address _token, address _to, uint _value) external onlyAuthorized{
        IERC20(_token).transfer( _to, _value);
    }

    // 系统送质押
    function authedGiftStake(address _to, uint _tokenId, uint _value) external onlyAuthorized{
        giftStake(_to, _tokenId, _value);
    }
}