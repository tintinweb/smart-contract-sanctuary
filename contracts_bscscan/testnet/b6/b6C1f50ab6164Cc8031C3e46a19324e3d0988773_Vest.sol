/**
 *Submitted for verification at BscScan.com on 2022-01-03
*/

pragma solidity 0.8.4;
// SPDX-License-Identifier: Unlicensed

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor()  {}

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// 
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
    constructor()  {
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
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

contract Vest is Ownable {

     // Wallets
    address public privateWallet;
    address public teamWallet;
    address public seed;
    IBEP20 public token; 
    bool public lockStatus;

    // Percent
    uint public seedPercent = 8e18;
    uint public privatePercent = 17e18;
    uint public teamPercent = 14.5e18;
    uint public creationTime;
    uint public _privateTime;
    uint public _privateCount;
    uint public totalSupply;

    //Mapping
    mapping (address => uint)public seedTime;
    mapping (address => uint)public teamTime;
    mapping (address => uint)public partnerTime;
    mapping (address => uint)public claimCount;
    mapping (address => bool)public approvedPrivate;

    constructor (IBEP20 _token) {
       token = _token;
       creationTime = block.timestamp;
    }

    modifier isLock() {
        require(lockStatus == false, "Contract Locked");
        _;
    }

    function initialize(
       address _private,
       address _team,
       address _seed
    ) public onlyOwner {
       privateWallet = _private;
       teamWallet = _team;
       seed = _seed;
       totalSupply = token.balanceOf(address(this));
       uint _initialPrivate = totalSupply*privatePercent/100e18;
       token.transfer(privateWallet,_initialPrivate*10/100);
    }

    function claimSeed() public isLock{
        require (msg.sender == seed,"UnAuthorized user");
        require (block.timestamp >= creationTime + 1095 days,"Vesting time");
        require (seedTime[msg.sender] == 0 || block.timestamp >= seedTime[msg.sender] + 30 days,"Invalid time");
        require (claimCount[msg.sender] < 10,"Claimed fully");
        seedTime[msg.sender] = block.timestamp;
        uint amount = totalSupply * seedPercent /100e18;
        token.transfer(msg.sender,amount*10/100);
        claimCount[msg.sender]++;
    }

    function claimTeam() public isLock{
        require (msg.sender == teamWallet,"UnAuthorized user");
        require (block.timestamp >= creationTime + 1095 days,"Vesting time");
        require (teamTime[msg.sender] == 0 || block.timestamp >= teamTime[msg.sender] + 30 days,"Invalid time");
        require (claimCount[msg.sender] < 10,"Claimed fully");
        teamTime[msg.sender] = block.timestamp;
        uint amount = totalSupply * teamPercent /100e18;
        token.transfer(msg.sender,amount*10/100);
        claimCount[msg.sender]++;
    }

    function claimPrivate() public isLock{
        require (approvedPrivate[msg.sender],"UnAuthorized user");
        require (block.timestamp >= creationTime + 365 days,"Vesting time");
        require (_privateTime == 0 || block.timestamp >= _privateTime + 30 days,"Invalid time");
        require (_privateCount < 9,"Claimed fully");
        _privateTime = block.timestamp;
        uint amount = totalSupply * privatePercent /100e18;
        token.transfer(msg.sender,amount*10/100);
        _privateCount++;
    }

    function addPrivateWallet(address[] memory _addr) public isLock {
        require(msg.sender == privateWallet,"Caller not private wallet");
        for (uint i = 0; i <_addr.length; i++){
             approvedPrivate[_addr[i]] = true;
        }
    }

    function contractLock(bool _lockStatus) public onlyOwner returns(bool) {
        lockStatus = _lockStatus;
        return true;
    }
}