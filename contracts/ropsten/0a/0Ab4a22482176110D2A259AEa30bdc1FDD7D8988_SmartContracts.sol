/**
 *Submitted for verification at Etherscan.io on 2021-09-10
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/GSN/Context.sol

pragma solidity ^0.8.0;

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Roles.sol

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/ownership/Ownable.sol

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = msg.sender;
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
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
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal virtual {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol

struct Teammate{
    address mate;
    uint256 percentage;
}

/**
 * 
 * Master contract to handle all children team contracts
 * Author: Lastraum K.
 * Creation Date: 09.07.2021
 * Version: 1.0
 * 
 */
contract SmartContracts is Ownable{
    using Roles for Roles.Role;
    Roles.Role private _adminmnz;
    address[] private _adminarr;
    
    mapping(uint256 => bool) private allTeamNames;
    mapping(uint256 => address[]) private allMatesForTeam;
    mapping(uint256 => mapping(address => Teammate)) private mateForTeam;
    mapping(address => uint256) private amountForMate;
    
    mapping(address => uint256[]) public allTeamNamesForMate;
    mapping(uint256 => uint256) public amountForTeam;

    uint256 platformFee = 0;
    
    function addAdmin(address[] memory adminmnz) public {
        require(msg.sender == owner(), "not owner");
        for (uint256 i = 0; i < adminmnz.length; ++i) {
            _adminmnz.add(adminmnz[i]);
            _adminarr.push(adminmnz[i]);
        }
    }
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function createTeam(string memory name, address[] memory members, uint256[] memory splits) public{
        uint256 nameNum = random(name);
        require(!allTeamNames[nameNum], "name already taken");
        
        allTeamNames[nameNum] = true;
        
        uint256 percentageCheck;
        for(uint i =0; i < members.length; i++){
            
            mateForTeam[nameNum][members[i]].mate = members[i];
            mateForTeam[nameNum][members[i]].percentage = splits[i];
            
            percentageCheck = percentageCheck + splits[i];
            allMatesForTeam[nameNum].push(members[i]);
            allTeamNamesForMate[members[i]].push(nameNum);
        }
        
        allMatesForTeam[nameNum].push(address(this));
        mateForTeam[nameNum][address(this)].mate = address(this);
        mateForTeam[nameNum][address(this)].percentage = platformFee;
        
        require(percentageCheck <= 100, "percentages are over 100%");
        
        percentageCheck = percentageCheck + platformFee;
        if(percentageCheck < 100){
          mateForTeam[nameNum][address(this)].percentage = mateForTeam[nameNum][address(this)].percentage + (100 - percentageCheck);
        }
        
    }

    function payTeam(string memory name) public payable{
        uint256 value = msg.value;
        uint256 nameNum = random(name);
        amountForTeam[nameNum] =  amountForTeam[nameNum] + value;
        
        require(allTeamNames[nameNum], "team doesn't exist");
        
        for(uint i = 0; i < allMatesForTeam[nameNum].length; i++){
            Teammate memory mate = mateForTeam[nameNum][allMatesForTeam[nameNum][i]];
            uint256 percentage = mate.percentage;
            uint256 added = value * percentage / 100;
            uint256 current = amountForMate[mate.mate];
            amountForMate[mate.mate] = current + added;
        }
        
    }
    
    function withdraw() public{
        uint256 mateBalance = amountForMate[msg.sender];
        
        uint256 currentBalance = (address(this).balance);
        require(currentBalance > 0, "contract has nothing to withdraw");
       
        uint256 withdrawAmt = mateBalance;
        address payable paymember = payable(msg.sender);
        paymember.transfer(withdrawAmt);
        amountForMate[msg.sender] = 0;
    }
    
    /*
    function getTeamCount() public view returns (uint256){
        return amountForMate[msg.sender];
    }
    */
    
    function getMateAmount() public view returns (uint256){
        return amountForMate[msg.sender];
    }
    
    function getAllTeamsForMate() public view returns (uint256[] memory){
        return allTeamNamesForMate[msg.sender];
    }
    
    function getTeamForMate(string memory name) public view returns (address, uint256){
        uint256 nameNum = random(name);
        return (mateForTeam[nameNum][msg.sender].mate, mateForTeam[nameNum][msg.sender].percentage);
    }
    
    function adminWithdraw() public{
        require(_adminmnz.has(msg.sender), "not admin");
        
        uint256 currentBalance = (address(this).balance);
        address payable paymember = payable(msg.sender);
        paymember.transfer(currentBalance);
    }
    
    function adminWithdrawSpecificMate(address mate) public{
        uint256 mateBalance = amountForMate[mate];
        
        uint256 currentBalance = (address(this).balance);
        require(currentBalance > 0, "contract has nothing to withdraw");
        require(mateBalance > 0, "nothing to withdraw");
       
        uint256 withdrawAmt = mateBalance;
        address payable paymember = payable(msg.sender);
        paymember.transfer(withdrawAmt);
        amountForMate[mate] = 0;
    }
    
    function platformWithdraw() public{
        require(_adminmnz.has(msg.sender), "not admin");
        
        uint256 mateBalance = amountForMate[address(this)];
        
        require(address(this).balance > 0, "contract has nothing to withdraw");
        require(mateBalance > 0, "nothing to withdraw");
       
        uint256 withdrawAmt = mateBalance;
        address payable paymember = payable(msg.sender);
        paymember.transfer(withdrawAmt);
        amountForMate[address(this)] = 0;
    }
    
    /**
     *
     * allow this contract to receive ETH
     * 
     */
    receive() external payable{
        //emit event taht says we received plain eth payment
    } 
}