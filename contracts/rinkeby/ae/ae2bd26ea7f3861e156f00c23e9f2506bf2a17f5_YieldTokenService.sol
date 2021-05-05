/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

// SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------
// yBXTB Service Contract V2
//
// Changes since V1:
// 1) Option to directly cash out CHIPs without unstaking yBXTB. A fee is applied, which
//    is paid into the commission pool to be shared by all yBXTB holders
// 2) Contract owner may deactivate project. This allows all CHIP holders to recover
//    USDT collateral and a proportional share of CHIP Backstop pool (paid out in USDT) without
//    unstaking yBXTB
// 3) Added dead man's switch to deactivate project if no commissions are received for 45 days, and
//    allow unconditional redemption of CHIP for USDT collateral and backstop
// 4) Improve CHIP Backstop management. Removed ability to manually draw down Backstop before
//    project is deactivated
// 5) Added migrate() function that transfers collateral, backstop, BXTB, CHIP, and yBXTB to
//    upgraded Contract in case of future migration
//
// As a result of the migration:
// A) 100 million yBXTB and 100 million CHIP tokens are irrevocably locked in V1 Contract
// B) Need to mint 100 million yBXTB and 100 million CHIP more to load into V2 Contract reserves
// C) The migration process involves:
//    - Deploy and initialize V2 Contract
//    - Mint 100 million CHIP and load into V2 Contract reserve
//    - Mint 100 million yBXTB and load into V2 Contract reserve
//    - Disable V1 Contract (staking and commission taking)
//    - Mint enough Migration Tokens (CHIP and yBXTB) to unstake all V1 Contract collateral
//    - Unstake all V1 Contract USDT with Migration Tokens
//    - Borrow BXTB tokens from BXTB Foundation
//    - Re-stake all USDT collateral into V2 Contract using borrowed BXTB
//    - Burn all Migration Tokens (CHIP and yBXTB)
//    - Withdraw all backstop (CHIP) and transfer to V2 Contract
//    - Update Service Contract address in CHIP contract from V1 to V2 Contract
//    - Update Service Contract address in yBXTB contract from V1 to V2 Contract
// ----------------------------------------------------------------------------
pragma solidity ^0.8.1;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function addSafe(uint _a, uint _b) internal pure returns (uint c) {
        c = _a + _b;
        require(c >= _a);
    }
    function subSafe(uint _a, uint _b) internal pure returns (uint c) {
        require(_b <= _a, "Insufficient balance");
        c = _a - _b;
    }
    function mulSafe(uint _a, uint _b) internal pure returns (uint c) {
        c = _a * _b;
        require(_a == 0 || c / _a == _b);
    }
    function divSafe(uint _a, uint _b) internal pure returns (uint c) {
        require(_b > 0);
        c = _a / _b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
// For BXTB Interface
interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address _tokenOwner) external view returns (uint);
    function allowance(address _tokenOwner, address _spender) external view returns (uint);
    function transfer(address _to, uint _amount) external returns (bool);
    function approve(address _spender, uint _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint _amount) external returns (bool);
}

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
// ----------------------------------------------------------------------------
interface ApproveAndCallFallBack {
    function receiveApproval(address _tokenOwner, uint256 _amount, address _tokenContract, bytes memory _data) external;
}

interface SettlementInterface {
    function disburseCommissions(bool _disburseBackstop) external;
}

// For USDT Interface
// Changed 'constant' to 'view' for compiler 0.5.4
interface ERC20_USDT {
    function totalSupply() external view returns (uint);
    function balanceOf(address who) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function transfer(address to, uint value) external;
    function approve(address spender, uint value) external;
    function transferFrom(address from, address to, uint value) external;
}

// Migrate to new Service Contract
interface Migrate_YieldTokenService {
    function migrate(
        uint _BXTBAmount,
        uint _USDTAmount,
        uint _CHIPBackstop,
        uint _CHIPCommissionsAvailable,
        uint _CHIPCommissionsTotal,
        uint _CHIPOutstanding,
        uint _CHIPTotal,
        uint _yieldTokenOutstanding,
        uint _yieldTokenTotal) external;
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        owner = newOwner;
        newOwner = address(0);
        emit OwnershipTransferred(owner, newOwner);
    }

    event OwnershipTransferred(address indexed _from, address indexed _to);
}


// ----------------------------------------------------------------------------
// yBXTB Service Contract
// ----------------------------------------------------------------------------
contract YieldTokenService is ApproveAndCallFallBack, SettlementInterface, Owned {
    using SafeMath for uint;

    address public constant USDTContract = 0xDd088A66Afe9754d569989903d77F7D86e576D0E;      // USDT contract
    address public constant BXTBContract = 0xF896fe97511EAf6af3Eb33EBFae4079811d0C387;      // BXTB contract
    address public constant yieldTokenContract = 0x5523FE671D6BB10f24088fdAFDB9f823BFa8c1A7;     // yBXTB contract
    address public constant CHIPContract = 0x8B78eFf754B99b74d401634E6D89A17f892F0cdf;      // CHIP contract

    address public bxtbFoundation = 0x95501d974714b8efb27Bc04106e11232bA6e5B24;
    address public recoveryAdmin = 0x133aFDf26c8cD3bc819dfe6c9e6437a1aE7DA722;
    address public settlementAdmin = 0x8ea3dC5aD23F884B1d34ce17cE7ebEd0c794A9bA;

    uint public totalPoolUSDTCollateral;
    uint public totalPoolBXTB;

    uint public totalPoolCHIPBackStop;

    uint public totalPoolCHIPCommissions;
    uint public totalPoolCHIPCommissionsAvailable;

    uint public totalSupplyYieldToken;
    uint public outstandingYieldToken;

    uint public totalSupplyCHIP;
    uint public outstandingCHIP;

    uint public constant decimals = 6;
    uint public collateralizationRatio;

    uint public bxtbTokenRatio;
    uint public cashoutRate;

    uint internal constant oneHundredPercent = 100 * 1000000;  // 100.000000% with six decimal places
    uint internal constant minimumCashoutRate = 10 * 1000000;  // 10.000000% with six decimal places

    uint public lastCommissionTimestamp;
    uint public migrateTimestamp;
    address public migrateNewAddress;

    bool public allowStaking;
    bool public allowCommissions;
    bool public projectDeactivated;

    constructor() {
        bxtbTokenRatio = 100;           // 100%
        collateralizationRatio = 100;   // 100%
        cashoutRate = 0;                // 0% with 3 decimals

        allowStaking = true;
        allowCommissions = false;
        projectDeactivated = false;
    }

    event TotalSupplyYieldTokenChanged(uint _amount);                   // Load YieldToken supply
    event TotalSupplyCHIPChanged(uint _amount);                         // Load CHIP supply
    event OutstandingSupplyChanged();                                   // Change in YieldToken & CHIP in circulation
    event ChangeBxtbTokenRatio(uint _amount);                           // Token ratio changed
    event CommissionReceived(address indexed _sender, uint _amount);    // Commissions received
    event CommissionsDisbursed(uint _amount);
    event Migrate(address _newContract);

    function receiveApproval(address _tokenOwner, uint256 _amount, address _tokenContract, bytes memory _data) public override {
        // Prevent ERC20 short address attack
        // _data length is not fixed
        require((msg.data.length == (6 * 32) + 4) && (_data.length == 1), "Input length error");

        require(msg.sender == yieldTokenContract ||
            msg.sender == CHIPContract ||
            msg.sender == BXTBContract, "Unknown caller");

        // Mode 0x10: Normal deposit
        // Mode 0xF0: Load reserve tokens
        uint8 mode = uint8(_data[0]);
        require(mode == 0x10 || mode == 0xD0 || mode == 0xE0 || mode == 0xF0, "Mode not accepted");

        if(mode == 0x10) {
            // Normal deposits for Stake and Redeem
            // Sanity check
            // require(totalSupplyYieldToken == totalSupplyCHIP, "Supply imbalance");  // Requirement removed in V2
            uint wildChip;

            // Credit to caller
            if(msg.sender == BXTBContract) {
                // Stake
                // Staking paused by admin
                // Don't allow staking if project is not active
                require((allowStaking == true) && (projectDeactivated == false), "Staking is paused");

                // Get allowance
                uint allowanceUsdt = ERC20_USDT(USDTContract).allowance(_tokenOwner, address(this));
                uint allowanceBxtb = _amount;

                // Enforce token staking ratio
                if(bxtbTokenRatio == 100) {  // 100 percent
                    // Get minimum common size. Size must be the same
                    if(allowanceUsdt <= allowanceBxtb) allowanceBxtb = allowanceUsdt;
                    else allowanceUsdt = allowanceBxtb;
                }
                else {
                    if(bxtbTokenRatio > 0) {
                        uint allowanceBxtbExpected = allowanceUsdt.mulSafe(bxtbTokenRatio).divSafe(100);
                        if(allowanceBxtb >= allowanceBxtbExpected) allowanceBxtb = allowanceBxtbExpected;  // Sufficient BXTB
                        else allowanceUsdt = allowanceBxtb.mulSafe(100).divSafe(bxtbTokenRatio);  // Reduce USDT due to insufficient BXTB
                    }
                    else allowanceBxtb = 0;  // Prevent divide-by-zero errors
                }

                // Issue YieldToken 'n' CHIP
                require(allowanceUsdt > 0, "Zero stake");

                // How many YieldToken are in reserve?
                uint remainderYieldToken = totalSupplyYieldToken.subSafe(outstandingYieldToken);
                // If not enough YieldToken. Reject transaction
                require((allowanceUsdt <= remainderYieldToken) && (remainderYieldToken > 0), "Staking size exceeded");

                // Accept USDT
                ERC20_USDT(USDTContract).transferFrom(_tokenOwner, address(this), allowanceUsdt);

                // For every USDT stake, issue 1 CHIP and 1 YieldToken
                // Update pool counter
                totalPoolUSDTCollateral = totalPoolUSDTCollateral.addSafe(allowanceUsdt);

                // Send out event for change in outstanding supply
                emit OutstandingSupplyChanged();

                // Accept BXTB
                if(allowanceBxtb > 0) {
                    ERC20Interface(BXTBContract).transferFrom(_tokenOwner, address(this), allowanceBxtb);
                    totalPoolBXTB = totalPoolBXTB.addSafe(allowanceBxtb);
                }

                // Issue YieldToken and CHIP, and update outstanding tokens
                // outstandingYieldToken and outstandingCHIP must be synchronized
                outstandingYieldToken = outstandingYieldToken.addSafe(allowanceUsdt);
                outstandingCHIP = outstandingCHIP.addSafe(allowanceUsdt);

                // Calculate collat ratio
                wildChip = outstandingCHIP.subSafe(totalPoolCHIPBackStop);
                if(wildChip > 0) collateralizationRatio = totalPoolUSDTCollateral.mulSafe(100).divSafe(wildChip);  // In percent
                else collateralizationRatio = 100;

                // Send out tokens
                ERC20Interface(yieldTokenContract).transfer(_tokenOwner, allowanceUsdt);
                ERC20Interface(CHIPContract).transfer(_tokenOwner, allowanceUsdt);
            }
            else if(msg.sender == CHIPContract) {
                // Redeem
                uint shareOfBxtb;

                if(projectDeactivated == false) {
                    // Get allowance
                    uint allowanceYieldToken = ERC20Interface(yieldTokenContract).allowance(_tokenOwner, address(this));

                    uint allowanceSize;
                    // Get minimum common size. Size must be the same
                    if(allowanceYieldToken <= _amount) allowanceSize = allowanceYieldToken;
                    else allowanceSize = _amount;

                    // Redeem YieldToken and CHIP tokens
                    require(allowanceSize > 0, "Zero redeem");

                    // Can't redeem more than outstanding CHIP
                    require((allowanceSize <= outstandingCHIP) && (outstandingCHIP > 0), "Redemption size exceeded");

                    // Accept YieldToken and CHIP
                    ERC20Interface(yieldTokenContract).transferFrom(_tokenOwner, address(this), allowanceSize);
                    ERC20Interface(CHIPContract).transferFrom(_tokenOwner, address(this), allowanceSize);

                    // Take YieldToken and CHIP out of circulation
                    // outstandingYieldToken and outstandingCHIP must be synchronized at all cost
                    outstandingYieldToken = outstandingYieldToken.subSafe(allowanceSize);
                    outstandingCHIP = outstandingCHIP.subSafe(allowanceSize);

                    // Emit event for change in outstanding supply
                    emit OutstandingSupplyChanged();

                    // Pay out equivalent amount of USDT, and send BXTB to Foundation
                    if(outstandingCHIP > 0) {
                        // Enforce token redemption ratio
                        if(bxtbTokenRatio == 100) shareOfBxtb = allowanceSize;  // 100 percent
                        else shareOfBxtb = allowanceSize.mulSafe(bxtbTokenRatio).divSafe(100);

                        // Can't take out more BXTB than exists
                        if(shareOfBxtb > totalPoolBXTB) shareOfBxtb = totalPoolBXTB;

                        // Update counters
                        totalPoolBXTB = totalPoolBXTB.subSafe(shareOfBxtb);
                        // Send BXTB to foundation
                        ERC20Interface(BXTBContract).transfer(bxtbFoundation, shareOfBxtb);

                        // Update pool counters
                        totalPoolUSDTCollateral = totalPoolUSDTCollateral.subSafe(allowanceSize);

                        // Calculate collat ratio
                        wildChip = outstandingCHIP.subSafe(totalPoolCHIPBackStop);
                        if(wildChip > 0) collateralizationRatio = totalPoolUSDTCollateral.mulSafe(100).divSafe(wildChip);  // In percent
                        else collateralizationRatio = 100;

                        // Send back collateral
                        ERC20_USDT(USDTContract).transfer(_tokenOwner, allowanceSize);
                    }
                    else {
                        // Last redeemer: Disburse everything
                        // In case contract accumulates more than expected, this clears out the account
                        // Hard resets all counter. No more outstanding CHIP and YieldTokens...
                        outstandingCHIP = 0;
                        totalPoolCHIPBackStop = 0;
                        totalPoolUSDTCollateral = 0;
                        totalPoolBXTB = 0;
                        collateralizationRatio = 100;

                        // Update commission counters
                        // Pay all commissions to last CHIP holder directly. No event emitted
                        totalPoolCHIPCommissions = totalPoolCHIPCommissions.addSafe(totalPoolCHIPCommissionsAvailable);
                        totalPoolCHIPCommissionsAvailable = 0;

                        // Send all BXTB to foundation
                        shareOfBxtb = ERC20Interface(BXTBContract).balanceOf(address(this));
                        ERC20Interface(BXTBContract).transfer(bxtbFoundation, shareOfBxtb);

                        // Pay out all USDT. Takes everything including totalPoolCHIPBackStop balance and lost USDTs
                        uint residualValue = ERC20_USDT(USDTContract).balanceOf(address(this));
                        ERC20_USDT(USDTContract).transfer(_tokenOwner, residualValue);
                    }
                }
                else {
                    // If project is not live, let users redeem without yBXTB, and distriute backstop proportionately
                    // Redeem CHIP tokens for USDT
                    require(_amount > 0, "Zero redeem");

                    // Can't redeem more than outstanding CHIP
                    require((_amount <= outstandingCHIP) && (outstandingCHIP > 0), "Redemption size exceeded");

                    // Retrieve CHIP
                    ERC20Interface(CHIPContract).transferFrom(_tokenOwner, address(this), _amount);

                    // Free unstaking, return proportional share of backstop
                    uint withdrawAmount;

                    wildChip = outstandingCHIP.subSafe(totalPoolCHIPBackStop);
                    if(wildChip > 0) withdrawAmount = _amount.mulSafe(totalPoolCHIPBackStop).divSafe(wildChip);  // Take portion of backstop
                    else withdrawAmount = totalPoolCHIPBackStop;  // Take all the backstop

                    // Reduce backstop amount
                    totalPoolCHIPBackStop = totalPoolCHIPBackStop.subSafe(withdrawAmount);
                    // Total withdrawal amount
                    withdrawAmount = _amount.addSafe(withdrawAmount);
                    // Take CHIP out of circulation
                    outstandingCHIP = outstandingCHIP.subSafe(withdrawAmount);
                    // Emit event for change in outstanding supply
                    emit OutstandingSupplyChanged();

                    // Pay out equivalent amount of USDT, and send BXTB to Foundation
                    if(outstandingCHIP > 0) {
                        // Enforce token redemption ratio
                        if(bxtbTokenRatio == 100) shareOfBxtb = withdrawAmount;  // 100 percent
                        else shareOfBxtb = withdrawAmount.mulSafe(bxtbTokenRatio).divSafe(100);

                        // Can't take out more BXTB than exists
                        if(shareOfBxtb > totalPoolBXTB) shareOfBxtb = totalPoolBXTB;

                        // Update counters
                        totalPoolBXTB = totalPoolBXTB.subSafe(shareOfBxtb);
                        // Send BXTB to foundation
                        ERC20Interface(BXTBContract).transfer(bxtbFoundation, shareOfBxtb);

                        // Update pool counters
                        totalPoolUSDTCollateral = totalPoolUSDTCollateral.subSafe(withdrawAmount);

                        // Calculate collat ratio
                        wildChip = outstandingCHIP.subSafe(totalPoolCHIPBackStop);
                        if(wildChip > 0) collateralizationRatio = totalPoolUSDTCollateral.mulSafe(100).divSafe(wildChip);  // In percent
                        else collateralizationRatio = 100;

                        // Send back collateral
                        ERC20_USDT(USDTContract).transfer(_tokenOwner, withdrawAmount);
                    }
                    else {
                        // Last redeemer: Disburse everything
                        // In case contract accumulates more than expected, this clears out the account
                        // Hard resets USDT counter. No more outstanding CHIP
                        outstandingCHIP = 0;
                        totalPoolCHIPBackStop = 0;

                        // Reset totalPoolCHIPCommissions
                        // No event is emitted. Pay directly to last CHIP holder
                        totalPoolCHIPCommissions = totalPoolCHIPCommissions.addSafe(totalPoolCHIPCommissionsAvailable);
                        totalPoolCHIPCommissionsAvailable = 0;  // No more chips. Therefore, no more USDT, and no more commission

                        // Reset collat ratio
                        collateralizationRatio = 100;

                        // Hard reset BXTB counters
                        totalPoolBXTB = 0;
                        // Send all BXTB to foundation
                        shareOfBxtb = ERC20Interface(BXTBContract).balanceOf(address(this));
                        ERC20Interface(BXTBContract).transfer(bxtbFoundation, shareOfBxtb);

                        // Pay out all USDT
                        totalPoolUSDTCollateral = 0;
                        uint residualValue = ERC20_USDT(USDTContract).balanceOf(address(this));
                        ERC20_USDT(USDTContract).transfer(_tokenOwner, residualValue);
                    }
                }
            }
            else revert("Unknown stake/redeem token");
        }
        else if(mode == 0xD0) {
            // Cash out coins, paying fee to compensate commission pool
            // This is a courtesy function for CHIP holders to recover USDT when there are no other options
            require(msg.sender == CHIPContract, "Only CHIP accepted");
            require((_amount > 0) && (projectDeactivated == false), "Cashout denied");

            // Take CHIP back
            ERC20Interface(CHIPContract).transferFrom(_tokenOwner, address(this), _amount);

            // Calculate fee and deduct it
            uint shareOfBxtb;
            uint cashoutCommission;
            uint cashoutAmount;

            if(outstandingYieldToken > 0) {
                // Calculate ending fee rate
                // f(x) = 1 - R
                // R = outstandingCHIP/outstandingYieldToken
                uint endOutstandingCHIP = outstandingCHIP.subSafe(_amount);
                uint endRate = oneHundredPercent.subSafe(endOutstandingCHIP.mulSafe(oneHundredPercent).divSafe(outstandingYieldToken));

                // Effective rate is the mid point
                uint effectiveRate = cashoutRate.addSafe(endRate).divSafe(2);  // In percent with 6 decimal places

                // Update new cashoutRate
                cashoutRate = endRate;

                // Apply minimum 10%
                if(effectiveRate < minimumCashoutRate) effectiveRate = minimumCashoutRate;

                cashoutCommission = _amount.mulSafe(effectiveRate).divSafe(oneHundredPercent);
                cashoutAmount = _amount.subSafe(cashoutCommission);

                // Pay out yBXTB holders through CHIP commission pool distribution
                distributeToPools(cashoutCommission);
                emit CommissionReceived(_tokenOwner, cashoutCommission);
            }
            else {
                // Unreachable code
                // No more yield token holders. Return full amount
                cashoutCommission = 0;
                cashoutAmount = _amount;
            }

            // Update outstanding supply counters
            outstandingCHIP = outstandingCHIP.subSafe(cashoutAmount);
            emit OutstandingSupplyChanged();

            // Return BXTB amount to bxtbFoundation
            // Enforce token redemption ratio
            if(bxtbTokenRatio == 100) shareOfBxtb = cashoutAmount;  // 100 percent
            else shareOfBxtb = cashoutAmount.mulSafe(bxtbTokenRatio).divSafe(100);

            // Can't take out more BXTB than exists
            if(shareOfBxtb > totalPoolBXTB) shareOfBxtb = totalPoolBXTB;

            // Update counters
            totalPoolBXTB = totalPoolBXTB.subSafe(shareOfBxtb);
            // Send BXTB to foundation
            ERC20Interface(BXTBContract).transfer(bxtbFoundation, shareOfBxtb);

            // Update USDT counter
            totalPoolUSDTCollateral = totalPoolUSDTCollateral.subSafe(cashoutAmount);

            // Calculate collat ratio
            uint wildChip = outstandingCHIP.subSafe(totalPoolCHIPBackStop);
            if(wildChip > 0) collateralizationRatio = totalPoolUSDTCollateral.mulSafe(100).divSafe(wildChip);  // In percent
            else collateralizationRatio = 100;

            // Return USDT balance to sender
            ERC20_USDT(USDTContract).transfer(_tokenOwner, cashoutAmount);
        }
        else if(mode == 0xE0) {
            // Pay commissions
            require(msg.sender == CHIPContract, "Only CHIP accepted");
            payCommission(_tokenOwner);
        }
        else if(mode == 0xF0) {
            // Load reserve tokens
            // Only contract owner can load it
            require((_tokenOwner == owner) && (owner != address(0)), "Caller must be owner");
            // Check allowance
            require(_amount > 0, "Zero deposit");

            // YieldToken and CHIP reserve must be equal prior to staking commencement
            if(msg.sender == yieldTokenContract) {
                // Retrieve tokens
                ERC20Interface(yieldTokenContract).transferFrom(_tokenOwner, address(this), _amount);
                // Update total supply
                totalSupplyYieldToken = totalSupplyYieldToken.addSafe(_amount);
                // Emit event
                emit TotalSupplyYieldTokenChanged(totalSupplyYieldToken);
            }
            else if(msg.sender == CHIPContract) {
                // Retrieve tokens
                ERC20Interface(CHIPContract).transferFrom(_tokenOwner, address(this), _amount);
                // Update total supply
                totalSupplyCHIP = totalSupplyCHIP.addSafe(_amount);
                // Emit event
                emit TotalSupplyCHIPChanged(totalSupplyCHIP);
            }
            else revert("Unknown reserve token");
        }
    }

    // Pay commission
    function payCommission(address _sender) internal {
        // Don't take commissions if project is not active
        require((allowCommissions == true) && (projectDeactivated == false), "Commissions paused");

        uint allowanceCHIP = ERC20Interface(CHIPContract).allowance(_sender, address(this));
        require(allowanceCHIP > 0, "Zero commission");

        // Save timestamp
        lastCommissionTimestamp = block.timestamp;

        if(outstandingYieldToken > 0) {
            // Distribute commission to unit holders
            // Accept the deposit
            ERC20Interface(CHIPContract).transferFrom(_sender, address(this), allowanceCHIP);
            // Send to comission pools
            distributeToPools(allowanceCHIP);
            // Log event
            emit CommissionReceived(_sender, allowanceCHIP);
        }
        else {
            // This code should be unreachable
            // No more unit holders
            address recipient;
            if(owner != address(0)) recipient = owner;  // Send to contract owner
            else if(settlementAdmin != address(0)) recipient = settlementAdmin;  // If no contract owner, send to Settlement Admin
            else if(bxtbFoundation != address(0)) recipient = bxtbFoundation;  // If no contract owner, send to BXTB Foundation
            else revert("No recipients");  // No foundation, decline commission

            // Accept the deposit
            ERC20Interface(CHIPContract).transferFrom(_sender, recipient, allowanceCHIP);
            // Log event
            emit CommissionReceived(_sender, allowanceCHIP);
        }
    }

    function distributeToPools(uint _amount) internal {
        require(outstandingYieldToken > 0, "No more unit holders");

        uint backstopShortfall;
        uint backstopTarget = totalPoolUSDTCollateral.divSafe(10);  // Target backstop to be 10% of collateral

        // Over collateralize coin up to 10% (100% collateral + 10% backstop)
        if(totalPoolCHIPBackStop < backstopTarget) backstopShortfall = backstopTarget.subSafe(totalPoolCHIPBackStop);

        // Share commission between internal totalPools
        if(backstopShortfall > 0) {
            // Send portion to backstop pool
            uint allocateBackstop = _amount.divSafe(6);  // 1/6th goes to backstop pool

            if(allocateBackstop > backstopShortfall) allocateBackstop = backstopShortfall;  // Limit reached

            uint allocateCommission = _amount.subSafe(allocateBackstop);

            // Send to pools
            totalPoolCHIPBackStop = totalPoolCHIPBackStop.addSafe(allocateBackstop);                    // Cumulative amount deposited

            totalPoolCHIPCommissions = totalPoolCHIPCommissions.addSafe(allocateCommission);                    // Cumulative amount deposited
            totalPoolCHIPCommissionsAvailable = totalPoolCHIPCommissionsAvailable.addSafe(allocateCommission);  // Current balance in contract
        }
        else {
            // Send all to commissions pool
            totalPoolCHIPCommissions = totalPoolCHIPCommissions.addSafe(_amount);                       // Cumulative amount deposited
            totalPoolCHIPCommissionsAvailable = totalPoolCHIPCommissionsAvailable.addSafe(_amount);     // Current balance in contract
        }

        // Calculate collat ratio
        uint wildChip = outstandingCHIP.subSafe(totalPoolCHIPBackStop);
        if(wildChip > 0) collateralizationRatio = totalPoolUSDTCollateral.mulSafe(100).divSafe(wildChip);  // In percent
        else collateralizationRatio = 100;
    }

    // Perform settlement
    // _disburseBackstop is ignored in V2. But, it is kept for backwards compatibility
    function disburseCommissions(bool _disburseBackstop) external override {
        require((msg.sender == yieldTokenContract) ||
            (msg.sender == settlementAdmin) ||
            (msg.sender == owner) , "Caller not authorized");

        require(settlementAdmin != address(0), "Settlement Admin address error");

        // How much funds to disburse?
        uint withdrawAmount = totalPoolCHIPCommissionsAvailable;
        totalPoolCHIPCommissionsAvailable = 0;
        // Pay out to settlementAdmin account
        ERC20Interface(CHIPContract).transfer(settlementAdmin, withdrawAmount);
        emit CommissionsDisbursed(withdrawAmount);
    }

    // Change Recovery Admin for lost coins
    function changeRecoveryAdmin(address _newAddress) external {
        require(msg.data.length == 32 + 4, "Address error");  // Prevent input error
        require((msg.sender == recoveryAdmin) || (msg.sender == owner), "Caller not authorized");
        recoveryAdmin = _newAddress;
    }

    // Change Settlement Admin for daily settlements
    function changeSettlementAdmin(address _newAddress) external {
        require(msg.data.length == 32 + 4, "Address error");  // Prevent input error
        require((msg.sender == settlementAdmin) || (msg.sender == owner), "Caller not authorized");
        settlementAdmin = _newAddress;
    }

    // Change BXBT Foundation Address
    function changeBxtbFoundation(address _newAddress) external {
        require(msg.data.length == 32 + 4, "Address error");  // Prevent input error
        require(msg.sender == bxtbFoundation, "Caller not authorized");
        bxtbFoundation = _newAddress;
    }

    // Change BXTB-to-USDT ratio for staking, and BXTB-to-YieldToken ratio redemption
    function changeBxtbTokenRatio(uint _newRatio) external {
        require(msg.sender == bxtbFoundation, "Caller not authorized");
        bxtbTokenRatio = _newRatio;
        emit ChangeBxtbTokenRatio(_newRatio);
    }

    function setAllowStaking(bool _allow) external onlyOwner {
        allowStaking = _allow;
    }

    function setAllowCommissions(bool _allow) external onlyOwner {
        allowCommissions = _allow;
    }

    // Change project state. Or trigger dead man's switch to deactivate project if no commission
    // has been paid for more than 45 days
    function setProjectDeactivated(bool _deactivate) external {
        bool keepGoing = true;

        if(lastCommissionTimestamp > 0) {
            // Switch armed
            uint timeDiff = block.timestamp - lastCommissionTimestamp;
            // If time elapsed is more than 45 days
//            if(timeDiff > (45 * 86400)) {
            if(timeDiff > 10800) {  // For testnet. 3 hours
                projectDeactivated = true;  // Deactivate project
                keepGoing = false;

                // Owner can override deactivation
                if(msg.sender == owner) keepGoing = true;
            }
        }

        if((keepGoing == true) && (msg.sender == owner)) {
            projectDeactivated = _deactivate;
        }
    }

    // Function must be called twice to give community members at least 3 days notice of
    // the new contract migration
    function migrate(address _newContract) external onlyOwner {
        if(migrateTimestamp > 0) {
            uint timeDiff = block.timestamp - migrateTimestamp;
            // Three days notice required
//            if(timeDiff > (3 * 86400)) {
            if(timeDiff > 7200) {  // For testnet. 2 hours
                // New contract address must match too
                if(_newContract == migrateNewAddress) {
                    // Transfer all BXTB
                    uint transferAmount = ERC20Interface(BXTBContract).balanceOf(address(this));  // Take all coins, including accidental ones
                    ERC20Interface(BXTBContract).transferFrom(address(this), _newContract, transferAmount);
                    // Transfer all USDT
                    transferAmount = ERC20_USDT(USDTContract).balanceOf(address(this));  // Take all coins, including accidental ones
                    ERC20_USDT(USDTContract).transferFrom(address(this), _newContract, transferAmount);
                    // Transfer all CHIP
                    transferAmount = ERC20Interface(CHIPContract).balanceOf(address(this));  // Take all coins, including accidental ones
                    ERC20Interface(CHIPContract).transferFrom(address(this), _newContract, transferAmount);
                    // Transfer all yBXTB
                    transferAmount = ERC20Interface(yieldTokenContract).balanceOf(address(this));  // Take all coins, including accidental ones
                    ERC20Interface(yieldTokenContract).transferFrom(address(this), _newContract, transferAmount);

                    // Do migration
                    // *Target contract must adjust own collateralizationRatio
                    Migrate_YieldTokenService(_newContract).migrate(
                        totalPoolBXTB,
                        totalPoolUSDTCollateral,
                        totalPoolCHIPBackStop,
                        totalPoolCHIPCommissionsAvailable,
                        totalPoolCHIPCommissions,
                        outstandingCHIP,
                        totalSupplyCHIP,
                        outstandingYieldToken,
                        totalSupplyYieldToken);

                    // Reset local counters
                    totalPoolBXTB = 0;
                    totalPoolUSDTCollateral = 0;
                    totalPoolCHIPBackStop = 0;
                    totalPoolCHIPCommissionsAvailable = 0;
                    outstandingCHIP = 0;
                    totalSupplyCHIP = 0;
                    outstandingYieldToken = 0;
                    totalSupplyYieldToken = 0;
                    collateralizationRatio = 100;
                }
            }
        }

        // Save request info
        migrateTimestamp = block.timestamp;
        migrateNewAddress = _newContract;
        emit Migrate(_newContract);
    }

    // Let user estimate the cashout amount
    function estimateCashoutAmount(uint _amount) external view returns (uint cashoutAmount) {
        if(outstandingYieldToken > 0) {
            // Calculate ending fee rate
            // f(x) = 1 - R
            // R = outstandingCHIP/outstandingYieldToken
            uint endOutstandingCHIP = outstandingCHIP.subSafe(_amount);
            uint endRate = oneHundredPercent.subSafe(endOutstandingCHIP.mulSafe(oneHundredPercent).divSafe(outstandingYieldToken));

            // Effective rate is the mid point
            uint effectiveRate = cashoutRate.addSafe(endRate).divSafe(2);  // In percent with 6 decimal places

            // Apply minimum 10%
            if(effectiveRate < minimumCashoutRate) effectiveRate = minimumCashoutRate;

            uint cashoutCommission = _amount.mulSafe(effectiveRate).divSafe(oneHundredPercent);
            cashoutAmount = _amount.subSafe(cashoutCommission);
        }
        else {
            // No more yield token holders. Return full amount
            if(_amount > totalPoolUSDTCollateral) cashoutAmount = totalPoolUSDTCollateral;
            else cashoutAmount = _amount;
        }
    }
    
    // Special function for V1 -> V2 migration
    // This should be removed after V1 and performed in migrate()
    // Should only call once for migration purposes only
    function migrateV1toV2(uint _initBackstopAmount, uint _initCommissionsAmount, uint _initCommissionsAvailable) external onlyOwner {
        if((totalPoolCHIPBackStop == 0) && (totalPoolCHIPCommissions == 0) &&
           (totalPoolCHIPCommissionsAvailable == 0) && (projectDeactivated == false)) {
            totalPoolCHIPBackStop = _initBackstopAmount;
            totalPoolCHIPCommissions = _initCommissionsAmount;
            totalPoolCHIPCommissionsAvailable = _initCommissionsAvailable;

            // Calculate collat ratio
            uint wildChip = outstandingCHIP.subSafe(totalPoolCHIPBackStop);
            if(wildChip > 0) collateralizationRatio = totalPoolUSDTCollateral.mulSafe(100).divSafe(wildChip);  // In percent
            else collateralizationRatio = 100;
        }
    }

    // Retrieve lost coins (USDT, BXTB, YieldToken, CHIP)
    // If coins are accidentally sent to the contract, calling this function will recover them
    function recoverLostCoins(uint _amount, address _fromTokenContract, address _recoveryAddress) external {
        require(msg.data.length == (3 * 32) + 4, "Input length error");

        bool hasAdmin;
        if(recoveryAdmin != address(0)) {
            if(msg.sender == recoveryAdmin) {
                hasAdmin = true;
            }
            else if(_fromTokenContract == BXTBContract) {
                // But also let foundation call for BXTB
                if(bxtbFoundation != address(0)) {
                    if(msg.sender != bxtbFoundation) revert("Caller must be admin");
                }
                else revert("Caller must be admin");
            }
            else revert("Caller must be admin");
        }

        if(_fromTokenContract == USDTContract) recoverLostUSDT(_amount, _fromTokenContract, _recoveryAddress, msg.sender, hasAdmin);
        else if(_fromTokenContract == BXTBContract) recoverLostBXTB(_amount, _fromTokenContract, _recoveryAddress, msg.sender, hasAdmin);
        else recoverLostERC20(_amount, _fromTokenContract, _recoveryAddress, msg.sender, hasAdmin);
    }

    function recoverLostUSDT(uint _amount, address _fromTokenContract, address _recoveryAddress, address _sender, bool _hasAdmin) internal {
        uint amountAdmin;
        uint amountOwner;
        uint amountRecoveryAddress;
        uint amountSender;

        uint sweepAmount;
        uint recoverAmount;

        // How much is lost in this contract?
        sweepAmount = ERC20_USDT(_fromTokenContract).balanceOf(address(this));
        if(sweepAmount > totalPoolUSDTCollateral) {
            sweepAmount = sweepAmount.subSafe(totalPoolUSDTCollateral);

            // Retrieve amount
            if(_amount <= sweepAmount) {
                recoverAmount = _amount.mulSafe(3).divSafe(4);
                sweepAmount = sweepAmount.subSafe(recoverAmount);
            }

            if(_hasAdmin) {
                // Send 1/4 + swept up amounts to admin
                amountAdmin = sweepAmount;

                // Send 3/4 to recovery address or admin
                if(_recoveryAddress != address(0)) amountRecoveryAddress = recoverAmount;
                else amountAdmin = amountAdmin.addSafe(recoverAmount);
            }
            else {
                // Send 1/4 fees + swept up amounts to: Owner
                amountOwner = sweepAmount;

                // Send 3/4 balance to: Recovery address, Sender
                if(_recoveryAddress != address(0)) amountRecoveryAddress = recoverAmount;
                else amountSender = recoverAmount;
            }

            if(amountAdmin > 0) ERC20_USDT(_fromTokenContract).transfer(recoveryAdmin, amountAdmin);
            if(amountOwner > 0) ERC20_USDT(_fromTokenContract).transfer(owner, amountOwner);
            if(amountRecoveryAddress > 0) ERC20_USDT(_fromTokenContract).transfer(_recoveryAddress, amountRecoveryAddress);
            if(amountSender > 0) ERC20_USDT(_fromTokenContract).transfer(_sender, amountSender);
        }
    }

    function recoverLostBXTB(uint _amount, address _fromTokenContract, address _recoveryAddress, address _sender, bool _hasAdmin) internal {
        uint amountAdmin;
        uint amountFoundation;
        uint amountRecoveryAddress;
        uint amountSender;

        uint sweepAmount;
        uint recoverAmount;

        // How much is lost in this contract?
        sweepAmount = ERC20Interface(_fromTokenContract).balanceOf(address(this));
        if(sweepAmount > totalPoolBXTB) {
            sweepAmount = sweepAmount.subSafe(totalPoolBXTB);

            // Retrieve amount
            if(_amount <= sweepAmount) {
                recoverAmount = _amount.mulSafe(3).divSafe(4);
                sweepAmount = sweepAmount.subSafe(recoverAmount);
            }

            if(_hasAdmin) {
                // Send 1/4 fees + swept up amounts to: BXTB foundation, Admin
                if(bxtbFoundation != address(0)) amountFoundation = sweepAmount;
                else amountAdmin = sweepAmount;
                // Send 3/4 balance to: Recovery address, Admin
                if(_recoveryAddress != address(0)) amountRecoveryAddress = recoverAmount;
                else amountAdmin = amountAdmin.addSafe(recoverAmount);
            }
            else {
                // Send 1/4 fees + swept up amounts to: BXTB foundation, Recovery address, Sender
                if(bxtbFoundation != address(0)) amountFoundation = sweepAmount;
                else if(_recoveryAddress != address(0)) amountRecoveryAddress = sweepAmount;
                else amountSender = sweepAmount;

                // Send 3/4 balance to: Recovery address, Sender
                if(_recoveryAddress != address(0)) amountRecoveryAddress = amountRecoveryAddress.addSafe(recoverAmount);
                else amountSender = amountSender.addSafe(recoverAmount);
            }

            if(amountAdmin > 0) ERC20Interface(_fromTokenContract).transfer(recoveryAdmin, amountAdmin);
            if(amountFoundation > 0) ERC20Interface(_fromTokenContract).transfer(bxtbFoundation, amountFoundation);
            if(amountRecoveryAddress > 0) ERC20Interface(_fromTokenContract).transfer(_recoveryAddress, amountRecoveryAddress);
            if(amountSender > 0) ERC20Interface(_fromTokenContract).transfer(_sender, amountSender);
        }
    }

    function recoverLostERC20(uint _amount, address _fromTokenContract, address _recoveryAddress, address _sender, bool _hasAdmin) internal {
        uint amountAdmin;
        uint amountOwner;
        uint amountRecoveryAddress;
        uint amountSender;

        uint sweepAmount;
        uint recoverAmount;
        uint poolSize;

        // How much is lost in this contract?
        sweepAmount = ERC20Interface(_fromTokenContract).balanceOf(address(this));

        if(_fromTokenContract == yieldTokenContract) poolSize = outstandingYieldToken;
        else if(_fromTokenContract == CHIPContract) poolSize = outstandingCHIP;
        else poolSize = 0;

        if(sweepAmount > poolSize) {
            sweepAmount = sweepAmount.subSafe(poolSize);

            // Retrieve amount
            if(_amount <= sweepAmount) {
                recoverAmount = _amount.mulSafe(3).divSafe(4);
                sweepAmount = sweepAmount.subSafe(recoverAmount);
            }

            if(_hasAdmin) {
                // Send 1/4 fees + swept up amounts to: Admin
                amountAdmin = sweepAmount;

                // Send 3/4 balance to: Recovery address, Admin
                if(_recoveryAddress != address(0)) amountRecoveryAddress = recoverAmount;
                else amountAdmin = amountAdmin.addSafe(recoverAmount);
            }
            else {
                // Send 1/4 fees + swept up amounts to: Owner
                amountOwner = sweepAmount;

                // Send 3/4 balance to: Recovery address, Sender
                if(_recoveryAddress != address(0)) amountRecoveryAddress = recoverAmount;
                else amountSender = recoverAmount;
            }

            if(amountAdmin > 0) ERC20Interface(_fromTokenContract).transfer(recoveryAdmin, amountAdmin);
            if(amountOwner > 0) ERC20Interface(_fromTokenContract).transfer(owner, amountOwner);
            if(amountRecoveryAddress > 0) ERC20Interface(_fromTokenContract).transfer(_recoveryAddress, amountRecoveryAddress);
            if(amountSender > 0) ERC20Interface(_fromTokenContract).transfer(_sender, amountSender);
        }
    }

}