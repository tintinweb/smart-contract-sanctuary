// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./interfaces/IDeFiatGov.sol";
import "./utils/DeFiatUtils.sol";

contract DeFiatGov is IDeFiatGov, DeFiatUtils {
    event RightsUpdated(address indexed caller, address indexed subject, uint256 level);
    event RightsRevoked(address indexed caller, address indexed subject);
    event MastermindUpdated(address indexed caller, address indexed subject);
    event FeeDestinationUpdated(address indexed caller, address feeDestination);
    event TxThresholdUpdated(address indexed caller, uint256 txThreshold);
    event BurnRateUpdated(address indexed caller, uint256 burnRate);
    event FeeRateUpdated(address indexed caller, uint256 feeRate);

    address public override mastermind;
    mapping (address => uint256) private actorLevel; // governance = multi-tier level
    
    address private feeDestination; // target address for fees
    uint256 private txThreshold; // min dft transferred to mint dftp
    uint256 private burnRate; // % burn on each tx, 10 = 1%
    uint256 private feeRate; // % fee on each tx, 10 = 1% 

    modifier onlyMastermind {
        require(msg.sender == mastermind, "Gov: Only Mastermind");
        _;
    }

    modifier onlyGovernor {
        require(actorLevel[msg.sender] >= 2,"Gov: Only Governors");
        _;
    }

    modifier onlyPartner {
        require(actorLevel[msg.sender] >= 1,"Gov: Only Partners");
        _;
    }

    constructor() public {
        mastermind = msg.sender;
        actorLevel[mastermind] = 3;
        feeDestination = mastermind;
    }
    
    // VIEW

    // Gov - Actor Level
    function viewActorLevelOf(address _address) public override view returns (uint256) {
        return actorLevel[_address];
    }

    // Gov - Fee Destination / Treasury
    function viewFeeDestination() public override view returns (address) {
        return feeDestination;
    }

    // Points - Transaction Threshold
    function viewTxThreshold() public override view returns (uint256) {
        return txThreshold;
    }

    // Token - Burn Rate
    function viewBurnRate() public override view returns (uint256) {
        return burnRate;
    }

    // Token - Fee Rate
    function viewFeeRate() public override view returns (uint256) {
        return feeRate;
    }

    // Governed Functions

    // Update Actor Level, can only be performed with level strictly lower than msg.sender's level
    // Add/Remove user governance rights
    function setActorLevel(address user, uint256 level) public {
        require(level < actorLevel[msg.sender], "ActorLevel: Can only grant rights below you");
        require(actorLevel[user] < actorLevel[msg.sender], "ActorLevel: Can only update users below you");

        actorLevel[user] = level; // updates level -> adds or removes rights
        emit RightsUpdated(msg.sender, user, level);
    }
    
    // MasterMind - Revoke all rights
    function removeAllRights(address user) public onlyMastermind {
        require(user != mastermind, "Mastermind: Cannot revoke own rights");

        actorLevel[user] = 0; 
        emit RightsRevoked(msg.sender, user);
    }

    // Mastermind - Transfer ownership of Governance
    function setMastermind(address _mastermind) public onlyMastermind {
        require(_mastermind != mastermind, "Mastermind: Cannot call self");

        mastermind = _mastermind; // Only one mastermind
        actorLevel[_mastermind] = 3;
        actorLevel[mastermind] = 2; // new level for previous mastermind
        emit MastermindUpdated(msg.sender, mastermind);
    }

    // Gov - Update the Fee Destination
    function setFeeDestination(address _feeDestination) public onlyGovernor {
        require(_feeDestination != feeDestination, "FeeDestination: No destination change");

        feeDestination = _feeDestination;
        emit FeeDestinationUpdated(msg.sender, feeDestination);
    }

    // Points - Update the Tx Threshold
    function changeTxThreshold(uint _txThreshold) public onlyGovernor {
        require(_txThreshold != txThreshold, "TxThreshold: No threshold change");

        txThreshold = _txThreshold;
        emit TxThresholdUpdated(msg.sender, txThreshold);
    }
    
    // Token - Update the Burn Rate
    function changeBurnRate(uint _burnRate) public onlyGovernor {
        require(_burnRate <= 200, "BurnRate: 20% limit");

        burnRate = _burnRate; 
        emit BurnRateUpdated(msg.sender, burnRate);
    }

    // Token - Update the Fee Rate
    function changeFeeRate(uint _feeRate) public onlyGovernor {
        require(_feeRate <= 200, "FeeRate: 20% limit");

        feeRate = _feeRate;
        emit FeeRateUpdated(msg.sender, feeRate);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IDeFiatGov {
    function mastermind() external view returns (address);
    function viewActorLevelOf(address _address) external view returns (uint256);
    function viewFeeDestination() external view returns (address);
    function viewTxThreshold() external view returns (uint256);
    function viewBurnRate() external view returns (uint256);
    function viewFeeRate() external view returns (uint256);
}

// SPDX-License-Identifier: MIT



pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT



pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT





pragma solidity ^0.6.0;

import "../lib/@openzeppelin/token/ERC20/IERC20.sol";
import "../lib/@openzeppelin/access/Ownable.sol";

abstract contract DeFiatUtils is Ownable {
    event TokenSweep(address indexed user, address indexed token, uint256 amount);

    // Sweep any tokens/ETH accidentally sent or airdropped to the contract
    function sweep(address token) external onlyOwner {
        uint256 amount = IERC20(token).balanceOf(address(this));
        require(amount > 0, "Sweep: No token balance");

        IERC20(token).transfer(msg.sender, amount); // use of the ERC20 traditional transfer

        if (address(this).balance > 0) {
            payable(msg.sender).transfer(address(this).balance);
        }

        emit TokenSweep(msg.sender, token, amount);
    }

    // Self-Destruct contract to free space on-chain, sweep any ETH to owner
    function kill() external onlyOwner {
        selfdestruct(payable(msg.sender));
    }
}