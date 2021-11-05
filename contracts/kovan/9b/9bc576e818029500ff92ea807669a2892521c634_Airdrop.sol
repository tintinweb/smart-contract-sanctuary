/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

/**
 *SPDX-License-Identifier: Unlicensed
*/

pragma solidity ^0.6.12;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

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

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}
contract Airdrop is Ownable {

    mapping(address => bool) public claimed;
    uint256 public total;    
    uint256 public airdrop = 900 * 10**9 * 10**9;
    address public Token;

    event Claimed(address addr,uint256 n);
   constructor(address _tokenAddress) public {  
        Token = _tokenAddress;
    }  
    
    function setToken(address _token) external onlyOwner {
        Token = _token;
    }
    
    function setAirdrop(uint256 _airdrop) external onlyOwner {
        airdrop = _airdrop;
    }
    
    function setClaimed(address _addr) external onlyOwner {
        claimed[_addr] = true;
    }

    function unsetClaimed(address _addr) external onlyOwner {
        claimed[_addr] = false;
    }
    
    function claimAirdrop() external {
        require(!claimed[msg.sender],"claimed");
        claimed[msg.sender]=true;
        total++;
        IERC20 token = IERC20(Token);
        uint256 tb = token.balanceOf(address(this));
        require(airdrop<=tb,"not enough");
        token.transfer(msg.sender,airdrop);
        emit Claimed(msg.sender,total);
    }
    
    function emergencyTransfer(uint256 a) external onlyOwner {
        require(a<=address(this).balance,"not enough");
        msg.sender.transfer(a);
    }
    
    function emergencyTransferToken(address _token,uint256 a) external onlyOwner {
        IERC20 token = IERC20(_token);
        uint256 tb = token.balanceOf(address(this));
        require(a<=tb,"not enough");
        token.transfer(msg.sender,a);
    } 
}