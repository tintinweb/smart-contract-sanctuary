// SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------
// yBXTB Service contract
// ----------------------------------------------------------------------------
pragma solidity ^0.7.4;

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

    address public constant USDTContract = 0xdAC17F958D2ee523a2206206994597C13D831ec7;      // USDT contract
    address public constant BXTBContract = 0x7bA9caa5D19002618F1D93e691490377361D5E60;      // BXTB contract
    address public constant yieldTokenContract = 0x39dCCA7984B22cCB0347DeEAeEaaEE6e6Ce9ba9F;     // yBXTB contract
    address public constant CHIPContract = 0x73F737dE96cF8987CA2C4C1FDC5134688BB2e10f;      // CHIP contract

    address public bxtbFoundation = 0x616143B2e9ADC2F48c9Ad4C30162e0782297f06f;
    address public recoveryAdmin;
    address public settlementAdmin;
    address public backstopAdmin;

    uint public totalPoolUSDTCollateral;
    uint public totalPoolBXTB;

    uint public totalPoolCHIPBackStop;
    uint public totalPoolCHIPBackStopAvailable;

    uint public totalPoolCHIPCommissions;
    uint public totalPoolCHIPCommissionsAvailable;

    uint public totalSupplyYieldToken;
    uint public outstandingYieldToken;

    uint public totalSupplyCHIP;
    uint public outstandingCHIP;

    uint public constant decimals = 6;
    uint public collateralizationRatio;

    uint public bxtbTokenRatio;

    bool public allowStaking;
    bool public allowCommissions;

    constructor() {
        bxtbTokenRatio = 100;           // 100%
        collateralizationRatio = 100;   // 100%

        allowStaking = true;
        allowCommissions = false;
    }

    event TotalSupplyYieldTokenChanged(uint _amount);                   // Load YieldToken supply
    event TotalSupplyCHIPChanged(uint _amount);                         // Load CHIP supply
    event OutstandingSupplyChanged();                                   // Change in YieldToken & CHIP in circulation
    event ChangeBxtbTokenRatio(uint _amount);                           // Token ratio changed
    event CommissionReceived(address indexed _sender, uint _amount);    // Commissions received
    event CommissionsDisbursed(uint _amount);
    event BackstopDisbursed(uint _amount);
    event BackstopAdjusted(bool _refunded, uint _amount);


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
        require(mode == 0x10 || mode == 0xE0 || mode == 0xF0, "Mode not accepted");

        if(mode == 0x10) {
            // Normal deposits for Stake and Redeem
            // Sanity check
            require(totalSupplyYieldToken == totalSupplyCHIP, "Supply imbalance");
            uint wildChip;

            // Credit to caller
            if(msg.sender == BXTBContract) {
                // Stake
                // Staking paused by admin
                require(allowStaking == true, "Staking is paused");

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
                // outstandingYieldToken and outstandingCHIP must be synchronized at all cost!
                outstandingYieldToken = outstandingYieldToken.addSafe(allowanceUsdt);
                outstandingCHIP = outstandingCHIP.addSafe(allowanceUsdt);

                ERC20Interface(yieldTokenContract).transfer(_tokenOwner, allowanceUsdt);
                ERC20Interface(CHIPContract).transfer(_tokenOwner, allowanceUsdt);

                // Calculate collat ratio
                wildChip = outstandingCHIP.subSafe(totalPoolCHIPBackStop);
                if(wildChip > 0) collateralizationRatio = totalPoolUSDTCollateral.mulSafe(100).divSafe(wildChip);  // In percent
                else collateralizationRatio = 100;
            }
            else if(msg.sender == CHIPContract) {
                // Redeem
                // Get allowance
                uint allowanceYieldToken = ERC20Interface(yieldTokenContract).allowance(_tokenOwner, address(this));
                uint allowanceCHIP = _amount;

                uint allowanceSize;
                // Get minimum common size. Size must be the same
                if(allowanceYieldToken <= allowanceCHIP) allowanceSize = allowanceYieldToken;
                else allowanceSize = allowanceCHIP;

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
                uint shareOfBxtb;

                if(outstandingCHIP > 0) {
                    // Update pool counters
                    totalPoolUSDTCollateral = totalPoolUSDTCollateral.subSafe(allowanceSize);
                    // Send back collateral
                    ERC20_USDT(USDTContract).transfer(_tokenOwner, allowanceSize);

                    // Enforce token redemption ratio
                    if(bxtbTokenRatio == 100) shareOfBxtb = allowanceSize;  // 100 percent
                    else shareOfBxtb = allowanceSize.mulSafe(bxtbTokenRatio).divSafe(100);

                    // Can't take out more BXTB than exists
                    if(shareOfBxtb > totalPoolBXTB) shareOfBxtb = totalPoolBXTB;

                    // Update counters
                    totalPoolBXTB = totalPoolBXTB.subSafe(shareOfBxtb);
                    // Send BXTB to foundation
                    ERC20Interface(BXTBContract).transfer(bxtbFoundation, shareOfBxtb);

                    // Calculate collat ratio
                    wildChip = outstandingCHIP.subSafe(totalPoolCHIPBackStop);
                    if(wildChip > 0) collateralizationRatio = totalPoolUSDTCollateral.mulSafe(100).divSafe(wildChip);  // In percent
                    else collateralizationRatio = 100;
                }
                else {
                    // Last redeemer: Disburse everything
                    // In case contract accumulates more than expected, this clears out the account
                    // Hard resets USDT counter. No more outstanding CHIP and YieldTokens
                    outstandingCHIP = 0;
                    outstandingYieldToken = 0;

                    // Pay out USDT
                    totalPoolUSDTCollateral = 0;
                    uint residualValue = ERC20_USDT(USDTContract).balanceOf(address(this));
                    ERC20_USDT(USDTContract).transfer(_tokenOwner, residualValue);

                    // Hard reset BXTB counters
                    totalPoolBXTB = 0;
                    // Send BXTB to foundation
                    shareOfBxtb = ERC20Interface(BXTBContract).balanceOf(address(this));
                    ERC20Interface(BXTBContract).transfer(bxtbFoundation, shareOfBxtb);

                    // Calculate collat ratio
                    collateralizationRatio = 100;
                }
            }
            else revert("Unknown stake/redeem token");
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
        require(allowCommissions == true, "Commissions paused");

        uint allowanceCHIP = ERC20Interface(CHIPContract).allowance(_sender, address(this));
        require(allowanceCHIP > 0, "Zero commission");

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
            totalPoolCHIPBackStopAvailable = totalPoolCHIPBackStopAvailable.addSafe(allocateBackstop);  // Current balance in contract

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

        // Send out the backstop balance too
        if(_disburseBackstop == true) {
            require(backstopAdmin != address(0), "Backstop Admin address error");

            // How much to pay out?
            withdrawAmount = totalPoolCHIPBackStopAvailable;
            totalPoolCHIPBackStopAvailable = 0;
            // Disburse backstop CHIPs to backstop Admin
            ERC20Interface(CHIPContract).transfer(backstopAdmin, withdrawAmount);
            emit BackstopDisbursed(withdrawAmount);
        }
    }

    // Send out backstop balance
    function disburseBackstop() external {
        require((msg.sender == backstopAdmin) || (msg.sender == owner), "Caller not authorized");
        require(backstopAdmin != address(0), "Backstop Admin address error");

        // How much to pay out?
        uint withdrawAmount = totalPoolCHIPBackStopAvailable;
        totalPoolCHIPBackStopAvailable = 0;
        // Disburse backstop CHIPs to backstop Admin
        ERC20Interface(CHIPContract).transfer(backstopAdmin, withdrawAmount);
        emit BackstopDisbursed(withdrawAmount);
    }

    // Update collat ratio after refunding backstop to CHIP or yBXTB holders
    function adjustBackstop(bool _refunded, uint _amount) external {
        require((msg.sender == backstopAdmin) || (msg.sender == owner), "Caller not authorized");

        if(_refunded == true) totalPoolCHIPBackStop = totalPoolCHIPBackStop.subSafe(_amount);  // Back out refunded amount
        else totalPoolCHIPBackStop = totalPoolCHIPBackStop.addSafe(_amount);  // Add more. This is used to fix user errors

        // Recalculate collateralization ratio
        uint wildChip = outstandingCHIP.subSafe(totalPoolCHIPBackStop);
        if(wildChip > 0) collateralizationRatio = totalPoolUSDTCollateral.mulSafe(100).divSafe(wildChip);  // In percent
        else collateralizationRatio = 100;

        emit BackstopAdjusted(_refunded, _amount);
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

    // Change Backstop Admin for managing backstop balance
    function changeBackstopAdmin(address _newAddress) external {
        require(msg.data.length == 32 + 4, "Address error");  // Prevent input error
        require((msg.sender == backstopAdmin) || (msg.sender == owner), "Caller not authorized");
        backstopAdmin = _newAddress;
    }

    // Change BXBT Foundation Address
    function changeBxtbFoundation(address _newAddress) external {
        require(msg.data.length == 32 + 4, "Address error");  // Prevent input error
        require(msg.sender == bxtbFoundation, "Caller not authorized");
        bxtbFoundation = _newAddress;
    }

    // Change BXTB-to-USDT ratio for staking, and BXTB-to-YieldToken ratio redemption
    function changebxtbTokenRatio(uint _newRatio) external {
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