/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

/**
 *SPDX-License-Identifier: UNLICENSED
*/
pragma solidity >=0.6.8 <0.8.0;

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

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        _owner = msg.sender;
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _owner = newOwner;
    }
}

// File: contracts/TellorProxy.sol

interface ITellor {
    function addTip(uint256 _requestId, uint256 _tip) external;

    function submitMiningSolution(
        string calldata _nonce,
        uint256[5] calldata _requestId,
        uint256[5] calldata _value
    ) external;

    function depositStake() external;

    function requestStakingWithdraw() external;

    function withdrawStake() external;

    function getUintVar(bytes32 _data) external view returns (uint256);

    function vote(uint256 _disputeId, bool _supportsDispute) external;

    function transfer(address _to, uint256 _amount) external returns (bool);
}

contract TellorProxy is Ownable {
    address tellorAddress; // Address of Tellor Oracle

    constructor(address _tellorAddress) public
    {
        tellorAddress = _tellorAddress;
    }

    function addTip(uint256 _requestId, uint256 _tip) external onlyOwner {
        ITellor(tellorAddress).addTip(_requestId, _tip);
    }

    function changeTRB(address _tellorAddress) external onlyOwner {
        tellorAddress = _tellorAddress;
    }

    function submitMiningSolution(
        string calldata _nonce,
        uint256[5] calldata _requestId,
        uint256[5] calldata _value,
        uint256 _pass
    ) external onlyOwner {
        if (_pass == 0) {
            bytes32 slotProgress =
                0xdfbec46864bc123768f0d134913175d9577a55bb71b9b2595fda21e21f36b082;
            uint256 _soltNum = ITellor(tellorAddress).getUintVar(slotProgress);
            require(_soltNum != 4, "out-ooff-gas");
        }
        ITellor(tellorAddress).submitMiningSolution(_nonce, _requestId, _value);
    }

    function depositStake() external onlyOwner {
        ITellor(tellorAddress).depositStake();
    }

    function requestStakingWithdraw() external onlyOwner {
        ITellor(tellorAddress).requestStakingWithdraw();
    }

    function payment(address _to, uint256 _amount) external onlyOwner {
        ITellor(tellorAddress).transfer(_to, _amount);
    }

    function getSlotProgress() external view returns (uint256) {
        bytes32 slotProgress =
            0xdfbec46864bc123768f0d134913175d9577a55bb71b9b2595fda21e21f36b082;
        return ITellor(tellorAddress).getUintVar(slotProgress);
    }

    function withdrawStake() external onlyOwner {
        ITellor(tellorAddress).withdrawStake();
    }

    function vote(uint256 _disputeId, bool _supportsDispute) external onlyOwner
    {
        ITellor(tellorAddress).vote(_disputeId, _supportsDispute);
    }
}