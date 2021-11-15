pragma solidity ^0.5.16;

import "../interfaces/IOracleInstance.sol";
import "./IMerkleDistributor.sol";
import "synthetix-2.43.1/contracts/Owned.sol";

contract XYZFeedInstance is IOracleInstance, Owned {
    IMerkleDistributor public iMerkleDistributor;
    string public targetName;
    string public targetOutcome;
    string public eventName;

    uint256 public targetCount;

    bool public outcome;
    bool public resolvable = true;

    bool private forcedOutcome;

    constructor(
        address _owner,
        address _iMerkleDistributor,
        uint256 _targetCount,
        string memory _targetName,
        string memory _targetOutcome,
        string memory _eventName
    ) public Owned(_owner) {
        iMerkleDistributor = IMerkleDistributor(_iMerkleDistributor);
        targetCount = _targetCount;
        targetName = _targetName;
        targetOutcome = _targetOutcome;
        eventName = _eventName;
    }

    function getOutcome() external view returns (bool) {
        if (forcedOutcome) {
            return outcome;
        } else {
            return iMerkleDistributor.claimed() >= targetCount;
        }
    }

    function setOutcome(bool _outcome) public onlyOwner {
        outcome = _outcome;
        forcedOutcome = true;
    }

    function clearOutcome() public onlyOwner {
        forcedOutcome = false;
    }

    function setResolvable(bool _resolvable) public onlyOwner {
        resolvable = _resolvable;
    }
}

pragma solidity >=0.4.24;

import "../interfaces/IBinaryOptionMarket.sol";

interface IOracleInstance {
    /* ========== VIEWS / VARIABLES ========== */

    function getOutcome() external view returns (bool);

    function resolvable() external view returns (bool);

    function targetName() external view returns (string memory);

    function targetOutcome() external view returns (string memory);

    function eventName() external view returns (string memory);

    /* ========== MUTATIVE FUNCTIONS ========== */
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;

// Allows anyone to claim a token if they exist in a merkle root.
interface IMerkleDistributor {
    // Returns the address of the token distributed by this contract.
    function totalClaims() external view returns (uint256);

    function claimed() external view returns (uint256);
}

pragma solidity ^0.5.16;

// https://docs.synthetix.io/contracts/source/contracts/owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

pragma solidity >=0.4.24;

import "../interfaces/IBinaryOptionMarketManager.sol";
import "../interfaces/IBinaryOption.sol";

interface IBinaryOptionMarket {
    /* ========== TYPES ========== */

    enum Phase {Trading, Maturity, Expiry}
    enum Side {Long, Short}

    /* ========== VIEWS / VARIABLES ========== */

    function options() external view returns (IBinaryOption long, IBinaryOption short);

    function times()
        external
        view
        returns (
            uint maturity,
            uint destructino
        );

    function oracleDetails()
        external
        view
        returns (
            bytes32 key,
            uint strikePrice,
            uint finalPrice
        );

    function fees()
        external
        view
        returns (
            uint poolFee,
            uint creatorFee
        );

    function deposited() external view returns (uint);

    function accumulatedFees() external view returns (uint);

    function creator() external view returns (address);

    function resolved() external view returns (bool);

    function phase() external view returns (Phase);

    function oraclePriceAndTimestamp() external view returns (uint price, uint updatedAt);

    function canResolve() external view returns (bool);

    function result() external view returns (Side);

    function balancesOf(address account) external view returns (uint long, uint short);

    function totalSupplies() external view returns (uint long, uint short);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function mint(uint value) external;

    function exerciseOptions() external returns (uint);
}

pragma solidity >=0.4.24;

import "../interfaces/IBinaryOptionMarket.sol";

interface IBinaryOptionMarketManager {
    /* ========== VIEWS / VARIABLES ========== */

    function fees() external view returns (uint poolFee, uint creatorFee);

    function durations()
        external
        view
        returns (
            uint maxOraclePriceAge,
            uint expiryDuration,
            uint maxTimeToMaturity
        );

    function capitalRequirement() external view returns (uint);

    function marketCreationEnabled() external view returns (bool);

    function totalDeposited() external view returns (uint);

    function numActiveMarkets() external view returns (uint);

    function activeMarkets(uint index, uint pageSize) external view returns (address[] memory);

    function numMaturedMarkets() external view returns (uint);

    function maturedMarkets(uint index, uint pageSize) external view returns (address[] memory);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function createMarket(
        bytes32 oracleKey,
        uint strikePrice,
        uint maturity,
        uint initialMint, // initial sUSD to mint options for,
        bool customMarket,
        address customOracle
    ) external returns (IBinaryOptionMarket);

    function resolveMarket(address market) external;

    function expireMarkets(address[] calldata market) external;

    function transferSusdTo(
        address sender,
        address receiver,
        uint amount
    ) external;
}

pragma solidity >=0.4.24;

import "../interfaces/IBinaryOptionMarket.sol";
import "synthetix-2.43.1/contracts/interfaces/IERC20.sol";

interface IBinaryOption {
    /* ========== VIEWS / VARIABLES ========== */

    function market() external view returns (IBinaryOptionMarket);

    function balanceOf(address account) external view returns (uint);

    function totalSupply() external view returns (uint);

}

pragma solidity >=0.4.24;

// https://docs.synthetix.io/contracts/source/interfaces/ierc20
interface IERC20 {
    // ERC20 Optional Views
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    // Views
    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    // Mutative functions
    function transfer(address to, uint value) external returns (bool);

    function approve(address spender, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    // Events
    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);
}

