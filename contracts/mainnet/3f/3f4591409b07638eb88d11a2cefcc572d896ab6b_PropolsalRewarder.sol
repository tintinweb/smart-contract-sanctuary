/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

// Dependency file: contracts/interfaces/IERC20.sol

// pragma solidity ^0.6.12;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


// Dependency file: contracts/Ownable.sol

// pragma solidity ^0.6.12;

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
        require(_owner == msg.sender, "Ownable: caller is not the owner");
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
}

// Root file: contracts/governance/PropolsalRewarder.sol

// SPDX-License-Identifier: GPL-3.0-or-later

// import 'contracts/interfaces/IERC20.sol';
// import 'contracts/Ownable.sol';

pragma experimental ABIEncoderV2;

pragma solidity ^0.6.12;

contract PropolsalRewarder is Ownable {
    address public rewardToken;
    address public governance;
    uint256 public idTreshold;

    uint256 public reward;
    mapping(uint256 => bool) public rewardedPropolsals;

    constructor(address _governance, address _rewardToken, uint256 _reward, uint256 _idTreshold) public {
        rewardToken = _rewardToken;
        governance = _governance;
        reward = _reward;
        idTreshold = _idTreshold;
    }

    function setReward(uint256 _newReward) external onlyOwner {
        reward = _newReward;
    }

    function setGovernance(address _newGovernance) external onlyOwner {
        governance = _newGovernance;
    }


    function withdrawLeftovers(address _to) external onlyOwner {
        IERC20(rewardToken).transfer(_to, IERC20(rewardToken).balanceOf(address(this)));
    }


    function getPropolsalReward(uint256 pid) external returns (bool) {
        require(pid > idTreshold, "This propolsal was created too early to be rewarded.");
        require(!rewardedPropolsals[pid], "This propolsal has been already rewarded.");
        rewardedPropolsals[pid] = true;

        bytes memory payload = abi.encodeWithSignature("proposals(uint256)", pid);
        (bool success, bytes memory returnData) = address(governance).call(payload);
        require(success, "Failed to get propolsal.");

        address proposer;
        bool executed;
        assembly {
            proposer := mload(add(returnData, add(0x20, 0x20)))
            executed := mload(add(returnData, add(0x20, 0x100)))
        }
        require(proposer == msg.sender, "Only proposer can achive reward.");
        require(executed, "Only executed porposers achive reward.");
        
        IERC20(rewardToken).transfer(msg.sender, reward);
    }

    receive() payable external {
        revert("Do not accept ether.");
    }
}