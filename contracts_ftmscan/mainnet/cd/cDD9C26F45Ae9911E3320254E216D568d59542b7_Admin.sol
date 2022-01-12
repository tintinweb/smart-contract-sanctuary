/**
 *Submitted for verification at FtmScan.com on 2022-01-12
*/

// Sources flattened with hardhat v2.8.2 https://hardhat.org

// File contracts/Dependencies/Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

/**
 * Based on OpenZeppelin's Ownable contract:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 *
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
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
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

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
        
    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     *
     * NOTE: This function is not safe, as it doesn’t check owner is calling it.
     * Make sure you check it before calling it.
     */
    function _renounceOwnership() internal {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}


// File contracts/B.Protocol/Admin.sol



pragma solidity 0.6.11;

interface WithAdmin {
    function admin() external view returns(address);
}

interface BAMMLikeInterface {
    function setParams(uint _A, uint _fee, uint _callerFee) external;
    function transferOwnership(address _newOwner) external;
}

contract Admin is Ownable {
    WithAdmin public immutable comptroller;
    BAMMLikeInterface public immutable bamm;
    
    address public pendingOwner;
    uint public ttl;

    event PendingOwnerAlert(address newOwner);

    constructor(WithAdmin _comptroller, BAMMLikeInterface _bamm) public {
        comptroller = _comptroller;
        bamm = _bamm;
    }

    function setParams(uint _A, uint _fee, uint _callerFee) public onlyOwner {
        bamm.setParams(_A, _fee, _callerFee);
    }

    function setBAMMPendingOwnership(address newOwner) public {
        require(msg.sender == comptroller.admin(), "only market admin can change ownership");
        pendingOwner = newOwner;
        ttl = now + 14 days;

        emit PendingOwnerAlert(newOwner);
    }

    function transferBAMMOwnership() public onlyOwner {
        require(pendingOwner != address(0), "pending owner is 0");
        require(now >= ttl, "too early");

        bamm.transferOwnership(pendingOwner);

        pendingOwner = address(0);
    }
}