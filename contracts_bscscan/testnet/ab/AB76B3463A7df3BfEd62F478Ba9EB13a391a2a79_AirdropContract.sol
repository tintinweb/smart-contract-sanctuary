/**
 *Submitted for verification at BscScan.com on 2021-11-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
interface EIP20Interface {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    /**
      * @notice Get the total number of tokens in circulation
      * @return The supply of tokens
      */
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address owner) external view returns (uint256 balance);

    
    function transfer(address dst, uint256 amount) external returns (bool success);

    
    function transferFrom(address src, address dst, uint256 amount) external returns (bool success);

    function approve(address spender, uint256 amount) external returns (bool success);

    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

contract AirdropContract is Ownable {
    
    EIP20Interface public _gammaAddress = EIP20Interface(0x8E9Ce0b83CD5970b920cfB85141Ec1E70AEee583);
    
    address public transferrer;
    
    mapping (address => bool) public fundsClaimed;
    mapping (address => uint256) public gammaAlloted;
    
    address[] public gammaAllocatedAddress;
    
    
    modifier OnlyTransferrer() {
        require(msg.sender == transferrer, "only transferrer can call");
        _;
    }
   
   event TransferrerSet(address oldTransferrer, address newTransferrer);
   event TransferrerRemoved(address oldTransferrer);
   event GAMMATransfered(address user, uint256 amount);
   event GAMMAWithdrawn(uint256);
   
    function withdrawGamma(uint256 amount) public onlyOwner {
        EIP20Interface(_gammaAddress).transferFrom(address(this), msg.sender, amount);  
        emit GAMMAWithdrawn(amount);
    }
    
    function transferGAMMA(address user, uint256 amount) public OnlyTransferrer {
        require(fundsClaimed[user] == false, "funds already claimed");
        gammaAlloted[user] = amount;
        EIP20Interface(_gammaAddress).transfer(user, amount);
        fundsClaimed[user] = true;
        gammaAllocatedAddress.push(user);
        
        emit GAMMATransfered(user, amount);
    }
    
    function setTransferrer(address _transferrer) public onlyOwner {
        address oldTransferrer = transferrer;
        transferrer = _transferrer;
        emit TransferrerSet(oldTransferrer, _transferrer);
    }
    
    function removeTransferrer() public onlyOwner {
        address oldTransferrer = transferrer;
        transferrer = address(0);
        emit TransferrerRemoved(oldTransferrer);
    }
    
    function getLength() view public returns(uint256) {
        return gammaAllocatedAddress.length;
    }
    
    function getUsers() view public returns(address[] memory) {
        return gammaAllocatedAddress;
    }
}