/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

// File: contracts\interfaces\IReservesDistributor.sol

pragma solidity >=0.5.0;

interface IReservesDistributor {
	function imx() external view returns (address);
	function xImx() external view returns (address);
	function periodLength() external view returns (uint);
	function lastClaim() external view returns (uint);
	
    event Claim(uint previousBalance, uint timeElapsed, uint amount);
    event NewPeriodLength(uint oldPeriodLength, uint newPeriodLength);
    event Withdraw(uint previousBalance, uint amount);

	function claim() external returns (uint amount);
	function setPeriodLength(uint newPeriodLength) external;
	function withdraw(uint amount) external;
}

// File: contracts\interfaces\IKeeperCompatible.sol

pragma solidity >=0.5.0;

interface IKeeperCompatible {
    function checkUpkeep(bytes calldata checkData) external view returns (bool upkeepNeeded, bytes memory performData);
    function performUpkeep(bytes calldata performData) external;
}

// File: contracts\Ownable.sol

// SPDX-License-Identifier: MIT
// Audit on 5-Jan-2021 by Keno and BoringCrypto

// P1 - P3: OK
pragma solidity =0.5.16;

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Edited by BoringCrypto

// T1 - T4: OK
contract OwnableData {
    // V1 - V5: OK
    address public owner;
    // V1 - V5: OK
    address public pendingOwner;
}

// T1 - T4: OK
contract Ownable is OwnableData {
    // E1: OK
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // F1 - F9: OK
    // C1 - C21: OK
    function transferOwnership(address newOwner, bool direct, bool renounce) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    // F1 - F9: OK
    // C1 - C21: OK
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    // M1 - M5: OK
    // C1 - C21: OK
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

// File: contracts\Claimer.sol

pragma solidity =0.5.16;




contract Claimer is IKeeperCompatible, Ownable {	
	address public reservesDistributor;
	uint public maxClaimInterval;

	constructor(
		address reservesDistributor_,
		uint maxClaimInterval_
	) public {
		reservesDistributor = reservesDistributor_;
		maxClaimInterval = maxClaimInterval_;
	}
	
	function checkUpkeep(bytes calldata checkData) external view returns (bool upkeepNeeded, bytes memory performData) {
		uint lastClaim = IReservesDistributor(reservesDistributor).lastClaim();
		upkeepNeeded = (block.timestamp - lastClaim) > maxClaimInterval;
		performData = checkData;
	}

	function performUpkeep(bytes calldata performData) external {
		IReservesDistributor(reservesDistributor).claim();
		performData;   
	}
	
	function setMaxClaimInterval(uint newMaxClaimInterval) external onlyOwner {
		maxClaimInterval = newMaxClaimInterval;
	}
}