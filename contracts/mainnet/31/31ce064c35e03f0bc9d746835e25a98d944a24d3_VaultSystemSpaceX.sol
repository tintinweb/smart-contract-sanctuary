pragma solidity 0.7.2;

// SPDX-License-Identifier: JPLv1.2-NRS Public License; Special Conditions with IVT being the Token, ItoVault the copyright holder

import "./SafeMath.sol";           // Todo: Change Safemath Name Over 
import "./ExampleOracleSimple.sol";
import "./GeneralToken.sol";
import "./BackedToken.sol";

contract VaultSystemSpaceX {
    using SafeMath for uint256;
    
    event LogUint(string name, uint value);
    
    BackedToken public vSPACEXToken;                       // This token is initialized below.

    
    // Start Config Area to Change Between Testnet and Mainnet
    address public constant UNISWAP_FACTORY_ADDR = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    address public constant WETH_ADDR = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // For Kovan change to 0xd0A1E359811322d97991E03f863a0C30C2cF029C
    GeneralToken public ivtToken = GeneralToken(0xb5BC0481ff9EF553F11f031A469cd9DF71280A27); // For Kovan, use any; for mainnet use 0xb5bc0481ff9ef553f11f031a469cd9df71280a27
    
    
    uint constant public LIQ_WAIT_TIME = 28 hours; // Mainnet: 28 hours
    uint public constant TWAP_PERIOD = 2 hours; // Mainnet: 2 hours
    uint public constant GLOBAL_SETTLEMENT_PERIOD = 14 days; // Mainnet 14 days
    // End Config Area to Change Between Testnet and Mainnet
    
    
    uint public cAME18 = 10 ** 18;
    
    address payable public owner;                           // owner is also governor here. to be passed to IVTDAO in the future
    address payable public oracle;                          // oracle is only the oracle for secondary prices
    
    
    // NB: None of the storage variables below should store numbers greater than 1E36.   uint256 overflow above 1E73.
    // So, it is safe to mul two numbers always. But to mul more than 2 requires decimal counting.
    
    uint public maxvSPACEXE18 = (10 ** 6) * (10 ** 18);     // Upper Bound of a million vSPACEXE18 tokens
    uint public outstandingvSPACEXE18 = 0;                  // Current outstanding vSPACEX tokens
    
    
    // Vault Variables (in vSPY_1 notation, these are forward vaults, and not reverse vaults)
    uint public initialLTVE10   = 5 * 10 ** 9;              // Maximum initial loan to value of a vault                 [Integer / 1E10]
    uint public maintLTVE10     = 6 * 10 ** 9;              // Maximum maintnenance loan to value of a vault            [Integer / 1E10]
    uint public liqPenaltyE10   = 5 * 10 ** 8;              // Bonus paid to any address for liquidating non-compliant
                                                            // contract                                                 [Integer / 1E10]
                                                            
                                                            
    // Global Settlement Variables
    bool public inGlobalSettlement = false;
    uint public globalSettlementStartTime;
    uint public settledWeiPervSPACEX; 
    bool public isGloballySettled = false;
    
    // Corporate Action Multiplier
    
    

    
    // Price Feed Variables
    ExampleOracleSimple public uniswapTWAPOracle;
    uint public weiPervSPACEXTWAP = 10 ** 18;
    bool public isTWAPOracleAttached = false;
    
    uint public weiPervSPACEXSecondary = 10 ** 18;
    uint public weiPervSPACEXMin = 10 ** 18;
    uint public weiPervSPACEXMax = 10 ** 18;
    
    uint public secondaryStartTime;
    uint public secondaryEndTime;
    

    

    // In this system, individual vaults *are* addresses.  Instances of vaults then are mapped by bare address
    // Each vault has an "asset" side and a "debt" side
    // The following variables track all Vaults.  Not strictly needed, but helps liquidate non-compliant vaults
    mapping(address => bool) public isAddressRegistered;    // Forward map to emulate a "set" struct
    address[] public registeredAddresses;                   // Backward map for "set" struct
    

    // Vaults are defined here
    mapping(address => uint) public weiAsset;               // Weis the Vault owns -- the asset side. NET of queued assets
    mapping(address => uint) public vSPACEXDebtE18;         // vSPACEX -- the debt side of the balance sheet of each Vault.  NET of queued assets

    // Each Vault has a liquidation "queue".  It is not a strict queue.  While items are always enqueued on top (high serial number)
    // Items only *tend* to dequeue on bottom.
    
    struct VaultLiquidationQ {
        uint size;                              // Number of elements in this queue
        uint[] weiAssetInSpot;                  // wei amount being liquidated
        uint[] vSPACEXDebtInSpotE18;            // Amount of vSPACEX Debt being liqudiated.  Not strictly necessary but for recordkeeping.
        uint[] liqStartTime;                    // When did liquidation start?
        uint[] weiPervSPACEXTWAPAtChallenge;    // TWAP price at challenge time
        bool[] isLiqChallenged;                 // Is this liquidation being challenged?
        bool[] isHarvested;                     // Is this liquidation already harvested?
        uint[] liqChallengeWei;                 // Amount that has been put in for liquidation challenge purposes
        address payable[] liquidator;           // Who is liquidating?
    }
    
    mapping(address => VaultLiquidationQ) public VaultLiquidationQs;

    
    constructor() {
        owner = msg.sender;
        oracle = msg.sender;
        vSPACEXToken = new BackedToken("vSPACEX Token V1", "vSPACEX");
        //Pass in already existing ivtToken address

    }
    

    
    // This function attaches the Uniswap TWAP, without updating price at first.  After 24 hours of deploy, governance must update this price in order to make this smart contract usable.
    function govAttachTWAP() public {
        require(msg.sender == owner, "Denied: Gov Must Attach TWAP");
        require(isTWAPOracleAttached == false, "TWAP Already Attached");
        isTWAPOracleAttached = true;
        
        uniswapTWAPOracle = new ExampleOracleSimple(UNISWAP_FACTORY_ADDR, WETH_ADDR, address(vSPACEXToken), TWAP_PERIOD);
        
    }

    
    // Anyone can update the TWAP price.  Gov should update this at least once before the system is considered stable.
    function updateTWAPPrice() public { 
        uniswapTWAPOracle.update();
        weiPervSPACEXTWAP = uniswapTWAPOracle.consult(address(vSPACEXToken), 10 ** 18); // Verified 2021-02-17 Price Not Inverted
        weiPervSPACEXMax = (weiPervSPACEXTWAP >  weiPervSPACEXSecondary) ? weiPervSPACEXTWAP : weiPervSPACEXSecondary;
        weiPervSPACEXMin = (weiPervSPACEXTWAP >  weiPervSPACEXSecondary) ? weiPervSPACEXSecondary : weiPervSPACEXTWAP;
    }
    
    // Oracle Functions
    function oracleUpdatesecondaryTime(uint _secondaryStartTime, uint _secondaryEndTime) public {
        require(msg.sender == oracle, "Deny Update 2ndry Time: You are not oracle");
        require( (_secondaryStartTime <= _secondaryEndTime)  &&  (_secondaryEndTime <= block.timestamp), "Invalid time");
        
        secondaryStartTime = _secondaryStartTime;
        secondaryEndTime = _secondaryEndTime;
    }
    
    function oracleUpdateweiPervSPACEXSecondary(uint _weiPervSPACEXSecondary) public {
        require(msg.sender == oracle, "Denied: You are not oracle");
        weiPervSPACEXSecondary = _weiPervSPACEXSecondary;
        weiPervSPACEXMax = (weiPervSPACEXTWAP >  weiPervSPACEXSecondary) ? weiPervSPACEXTWAP : weiPervSPACEXSecondary;
        weiPervSPACEXMin = (weiPervSPACEXTWAP >  weiPervSPACEXSecondary) ? weiPervSPACEXSecondary : weiPervSPACEXTWAP;
    }
    

    // Governance Functions
    function govUpdateinitialLTVE10(uint _initialLTVE10) public {
        require(msg.sender == owner, "Denied: You are not gov");
        initialLTVE10 = _initialLTVE10;
    }
    
    function govUpdatecAME18(uint _cAME18) public {
        require(msg.sender == owner, "Denied: You are not gov");
        cAME18 = _cAME18;
    }
    
    
    function govUpdatemaintLTVE10(uint _maintLTVE10) public {
        require(msg.sender == owner, "Disallowed: You are not governance");
        maintLTVE10 = _maintLTVE10;
    }
    
    function govUpdateliqPenaltyE10(uint _liqPenaltyE10) public {
        require(msg.sender == owner, "Disallowed: You are not governance");
        liqPenaltyE10 = _liqPenaltyE10;
    }
    
    function govChangeOwner(address payable _owner) public {
        require(msg.sender == owner, "Disallowed: You are not governance");
        owner = _owner;
    }
    
    function govChangeOracle(address payable _oracle) public {
        require(msg.sender == owner, "Disallowed: You are not governance");
        oracle = _oracle;
    }
    
    function govChangemaxvSPACEXE18(uint _maxvSPACEXE18) public {
        require(msg.sender == owner, "Disallowed: You are not governance");
        maxvSPACEXE18 = _maxvSPACEXE18;
    }
    
    function govStartGlobalSettlement() public { // To be tested
        require(msg.sender == owner, "Disallowed: You are not governance");
        inGlobalSettlement = true;
        globalSettlementStartTime = block.timestamp;
    }
    
    
    
    
    // Vault Functions
    function depositWEI() public payable { // Same as receive fallback; but explictily declared for symmetry
        require(msg.value > 0, "Must Deposit Nonzero Wei"); 
        weiAsset[msg.sender] = weiAsset[msg.sender].add( msg.value );
        
        if(isAddressRegistered[msg.sender] != true) { // if user was not registered before
            isAddressRegistered[msg.sender] = true;
            registeredAddresses.push(msg.sender);
        }
    }
    
    receive() external payable { // Same as depositWEI()
        require(msg.value > 0, "Must Deposit Nonzero Wei"); 
        // Receiving is automatic so double entry accounting not possible here
        weiAsset[msg.sender] = weiAsset[msg.sender].add( msg.value );
        
        if(isAddressRegistered[msg.sender] != true) { // if user was not registered before
            isAddressRegistered[msg.sender] = true;
            registeredAddresses.push(msg.sender);
        }
    }

    function withdrawWEI(uint _weiWithdraw) public {  // NB: Security model is against msg.sender
        // Presuming contract withdrawal is from own vault
        require( _weiWithdraw < 10 ** 28, "Protective max bound for uint argument");
        
        // Maintenence Equation: (vSPYDebtE18/1E18) * weiPervSPY <= (weiAsset) * (initialLTVE10/1E10)
        // => After withdrawal (vSPYDebtE18)/1E18 * weiPervSPY <= (weiAsset - _weiWithdraw) * (initialLTVE10/1E10)
        uint LHS = vSPACEXDebtE18[msg.sender].mul( weiPervSPACEXMax ).mul( 10 ** 10 ); // presuming weiPervSPACEXMax < 10 ** 24 (million ETH spacex)
        uint RHS = (weiAsset[msg.sender].sub( _weiWithdraw )).mul( initialLTVE10 ).mul( 10 ** 18 );
        require ( LHS <= RHS, "Initial margin not enough to withdraw");
        
        // Double Entry Accounting
        weiAsset[msg.sender] = weiAsset[msg.sender].sub( _weiWithdraw ); // penalize wei deposited before sending money out
        msg.sender.transfer(_weiWithdraw);
    }
    
    
    function lendvSPACEX(uint _vSPACEXLendE18) public {
        //presuming message sender is using his own vault
        require(_vSPACEXLendE18 < 10 ** 30, "Protective max bound for uint argument");
        require(outstandingvSPACEXE18.add( _vSPACEXLendE18 ) <= maxvSPACEXE18, "Current version limits max amount of vSPACEX possible");
        
        // Maintenence Equation: (vSPYDebtE18/1E18) * weiPervSPY <= (weiAsset) * (initialLTVE10/1E10)
        // I need: (_vSPYLendE18 + vSPYDebtE18)/1E18 * weiPervSPY  < weiAsset * (initialLTVE10/1E10)
        uint LHS = vSPACEXDebtE18[msg.sender].add( _vSPACEXLendE18 ).mul( weiPervSPACEXMax ).mul( 10 ** 10 );
        uint RHS = weiAsset[msg.sender].mul( initialLTVE10 ).mul( 10 ** 18 );
        require(LHS < RHS, "Your initial margin is insufficient for lending");
        
        // Double Entry Accounting
        vSPACEXDebtE18[msg.sender] = vSPACEXDebtE18[msg.sender].add( _vSPACEXLendE18 ); // penalize debt first.
        outstandingvSPACEXE18 = outstandingvSPACEXE18.add(_vSPACEXLendE18);
        vSPACEXToken.ownerMint(msg.sender, _vSPACEXLendE18);
    }
    
    function repayvSPACEX(uint _vSPACEXRepayE18) public {
        require(_vSPACEXRepayE18 < 10 ** 30, "Protective max bound for uint argument");
        
        // vSPACEXToken.ownerApprove(msg.sender, _vSPACEXRepayE18);  //Todo: Make a separate react button for owner to approve.
        
        // Double Entry Accounting
        // vSPACEXToken.transferFrom(msg.sender, address(this), _vSPACEXRepayE18); // the actual deduction from the token contract
        vSPACEXToken.ownerBurn(msg.sender, _vSPACEXRepayE18);
        vSPACEXDebtE18[msg.sender] = vSPACEXDebtE18[msg.sender].sub( _vSPACEXRepayE18 );
        outstandingvSPACEXE18 = outstandingvSPACEXE18.sub(_vSPACEXRepayE18);
    }
    
    
    
    
    function findNoncompliantVaults(uint _limitNum) public view returns(address[] memory, uint[] memory, uint[] memory, uint) {   // Return the first N noncompliant vaults
        require(_limitNum > 0, "Must run this on a positive integer");
        address[] memory noncompliantAddresses = new address[](_limitNum);
        uint[] memory LHSs_vault = new uint[](_limitNum);
        uint[] memory RHSs_vault = new uint[](_limitNum);
        
        uint j = 0;  // Iterator up to _limitNum
        for (uint i=0; i<registeredAddresses.length; i++) { // Iterate up to all the registered addresses.  NB: Should cost zero gas because this is a view function.
            if(j>= _limitNum) { // Exits if _limitNum noncompliant vaults are found
                break;
            } 
            // Vault maintainance margin violation: (vSPYDebtE18)/1E18 * weiPervSPY  > weiAsset * (maintLTVE10)/1E10 for a violation
            uint LHS_vault = vSPACEXDebtE18[registeredAddresses[i]].mul(weiPervSPACEXMax);
            uint RHS_vault  = weiAsset[registeredAddresses[i]].mul( maintLTVE10 ).mul( 10 ** 8);
            
            if( (LHS_vault > RHS_vault) ) {
                noncompliantAddresses[j] = registeredAddresses[i];
                LHSs_vault[j] = LHS_vault;
                RHSs_vault[j] = RHS_vault;

                j = j + 1;
            }
        }
        return(noncompliantAddresses, LHSs_vault, RHSs_vault, j);
    }
    
    
    
    function liquidateNonCompliant(uint _vSPACEXProvidedE18, address payable target_address) public returns(uint) { // liquidates a portion of the contract for non-compliance
    
        // If the system is in the final stage of GS, you can't start a liquidation.
        require( isGloballySettled == false,"Cannot liq after GS closes." );
        
        // While it possible to have a more complex liquidation system, since liqudations are off-equilibrium, for the MVP 
        // We have decided we want overly aggressive liqudiations 
        require( _vSPACEXProvidedE18 <= vSPACEXDebtE18[target_address], "You cannot provide more vSPACEX than vSPACEXDebt outstanding");


        // Maintenence Equation: (vSPYDebtE18/1E18) * weiPervSPY <= (weiAsset) * (maintLTVE10/1E10)
        // For a violation, the above will be flipped: (vSPYDebtE18/1E18) * weiPervSPY > (weiAsset) * (maintLTVE10/1E10)        
        uint LHS = vSPACEXDebtE18[target_address].mul( weiPervSPACEXMax ).mul( 10 ** 10);
        uint RHS = weiAsset[target_address].mul( maintLTVE10 ).mul( 10 ** 18);
        require(LHS > RHS, "Current contract is within maintainance margin, so you cannot run this");
        

        // If this vault is underwater-with-respect-to-rewards (different than noncompliant), liquidation is pro-rata
        // underater iff: weiAsset[target_address] < vSPYDebtE18[target_address]/1E18 * weiPervSPY * (liqPenaltyE10+1E10)/1E10
        uint LHS2 = weiAsset[target_address].mul( 10 ** 18 ).mul( 10 ** 10);
        uint RHS2 = vSPACEXDebtE18[target_address].mul( weiPervSPACEXMax ).mul( liqPenaltyE10.add( 10 ** 10 ));
        
        uint weiClaim;
        if( LHS2 < RHS2 ) { // pro-rata claim
            // weiClaim = ( _vSPYProvidedE18 /  vSPYDebtE18[target_address]) * weiAsset[target_address];
            weiClaim = _vSPACEXProvidedE18.mul( weiAsset[target_address] ).div( vSPACEXDebtE18[target_address] );
        } else {
            // maxWeiClaim = _vSPYProvidedE18/1E18 * weiPervSPY * (1+liqPenaltyE10/1E10)
            weiClaim = _vSPACEXProvidedE18.mul( weiPervSPACEXMax ).mul( liqPenaltyE10.add( 10 ** 10 )).div( 10 ** 18 ).div( 10 ** 10 );
        }
        require(weiClaim <= weiAsset[target_address], "Code Error if you reached this point");
        
        
        // Double Entry Accounting for returning vSPY Debt back
        // vSPACEXToken.ownerApprove(msg.sender, _vSPACEXProvidedE18);  // Todo: Require Owner to approve token first.
        vSPACEXToken.ownerBurn(msg.sender, _vSPACEXProvidedE18); // the actual deduction from the token contract
        vSPACEXDebtE18[target_address] = vSPACEXDebtE18[target_address].sub( _vSPACEXProvidedE18 );
        outstandingvSPACEXE18 = outstandingvSPACEXE18.sub( _vSPACEXProvidedE18 );
        
        
        // Double Entry Accounting for deducting the vault's assets
        weiAsset[target_address] = weiAsset[target_address].sub( weiClaim );
        
        
        if(weiPervSPACEXSecondary == weiPervSPACEXMax) {    // If the secondary price is the basis of liquidation, no wait is needed
            msg.sender.transfer( weiClaim );
            return 10 ** 30; // Sentinel for 
        } else {  // Otherwise, we need to wait LIQ_WAIT_TIME for liquidation
        
       
        uint i = VaultLiquidationQs[target_address].size; // Index i must always be less than size.  Solidity is zero indexed
        VaultLiquidationQs[target_address].size = VaultLiquidationQs[target_address].size.add( 1 );
        
        VaultLiquidationQs[target_address].weiAssetInSpot.push(weiClaim);                                // wei amount being liquidated
        VaultLiquidationQs[target_address].vSPACEXDebtInSpotE18.push(_vSPACEXProvidedE18);               // amount of vSPACEX Debt being liqudiated
        VaultLiquidationQs[target_address].liqStartTime.push(block.timestamp);                           // when did liquidation start?
        VaultLiquidationQs[target_address].weiPervSPACEXTWAPAtChallenge.push(weiPervSPACEXTWAP);         // TWAP price at challenge time
        VaultLiquidationQs[target_address].isLiqChallenged.push(false);                                  // Is this liquidation being challenged?
        VaultLiquidationQs[target_address].liqChallengeWei.push(0);                                      // Amount that has been put in for liquidation challenge purposes
        VaultLiquidationQs[target_address].liquidator.push(msg.sender); 
        VaultLiquidationQs[target_address].isHarvested.push(false); 
        return i;   // Liquidator expictly gets back their claim ticket number
        }
    }
    
    function settleUnchallengedLiquidation(address _targetVault, uint _position) public { // Liquidator can call
        // If in Global Settlement Final: Still allow, because otherwise wei locked in Q cannot be retrieved
        // critical requirements
        require(_position <  VaultLiquidationQs[_targetVault].size, "Err: PosInv"); // position needs to be valid
        require(msg.sender == VaultLiquidationQs[_targetVault].liquidator[_position] , "Err: LiqCal"); // only liqudiator can call
        require(VaultLiquidationQs[_targetVault].liqStartTime[_position] + LIQ_WAIT_TIME < block.timestamp, "Err: WaitL"); // must be LIQ_WAIT_TIME (28 hour in v1) later.
        require(VaultLiquidationQs[_targetVault].isLiqChallenged[_position] == false, "Err: AlrCha"); // Must not be challenged
        require(VaultLiquidationQs[_targetVault].isHarvested[_position] == false, "Err: AlrHar"); // Must not be harvseted yet
        
        // other assumptions
        require( VaultLiquidationQs[_targetVault].weiAssetInSpot[_position] > 0, "SErr: Wei");
        require( VaultLiquidationQs[_targetVault].vSPACEXDebtInSpotE18[_position] > 0, "SErr: vSP");
        require( VaultLiquidationQs[_targetVault].liqChallengeWei[_position] == 0, "SErr: lCW"); 
        
        // end the challenge
        
        // set the future claimable values to zero
        VaultLiquidationQs[_targetVault].isHarvested[_position] = true; // blocks a second transfer from happening
        uint weiClaim = VaultLiquidationQs[_targetVault].weiAssetInSpot[_position];
        VaultLiquidationQs[_targetVault].weiAssetInSpot[_position] = 0;
        
        // make the transfer
        VaultLiquidationQs[_targetVault].liquidator[_position].transfer( weiClaim );
    }
    
    
        
    
    function challengeLiquidation(uint _position) public payable  {                     // usually owner of vault calls, but anyone can benefit the owner
    
        require( isGloballySettled == false,"Cannot challenge after GS Closes." );      // Vault owner will have had at least GLOBAL_SETTLEMENT_PERIOD or 28 hours to challenge.  
        // No need to allow this edge case of more challenges after global settlement closes.
    
        require(_position <  VaultLiquidationQs[msg.sender].size, "Err: PosInv");                      // position needs to be valid
        require(VaultLiquidationQs[msg.sender].isHarvested[_position] == false, "Err: AlrHar");        // Must not be harvested yet
        require(VaultLiquidationQs[msg.sender].isLiqChallenged[_position] == false, "Err: AlrCha");    // Must not be challenged

        
        require(msg.value >= ( VaultLiquidationQs[msg.sender].weiPervSPACEXTWAPAtChallenge[_position].mul( VaultLiquidationQs[msg.sender].vSPACEXDebtInSpotE18[_position] ).div(10 ** 18)), "Err: ChaAmt" ); 
        // Require owner to challenge the liqudiation with an amount of wei equal to the vSPACEX the liquidator provided, at the Uniswap price then.
        
        // other assumptions
        require( VaultLiquidationQs[msg.sender].weiAssetInSpot[_position] > 0 , "SErr: Wei");
        require( VaultLiquidationQs[msg.sender].vSPACEXDebtInSpotE18[_position] > 0, "SErr: vSP" );
        require( VaultLiquidationQs[msg.sender].liqChallengeWei[_position] == 0, "SErr: lCW");
        // INTENTIONALLY don't block challenges even after LIQ_WAIT_TIME, as long as vault hasn't yet been harvested
        // No restriction on liqudiator
        
        // at this point, record the challenged
        VaultLiquidationQs[msg.sender].isLiqChallenged[_position] = true;
        VaultLiquidationQs[msg.sender].liqChallengeWei[_position] = msg.value;
    } 
    
    
    
    function endChallengeLiquidation(address _targetVault, uint _position) public {                 // Anyone can run, but only owner and liqudiator have direct incentive.
        // NB: who the challege in ends in favor of depends on when it is run.  Thus it is in favor of the winning claimaint to run soon.
        require(_position <  VaultLiquidationQs[_targetVault].size, "Err: PosInv");                                // position needs to be valid
        require( VaultLiquidationQs[_targetVault].isLiqChallenged[_position] == true, "Err: NotCha");             // Must be challenged
        require( VaultLiquidationQs[_targetVault].isHarvested[_position] == false, "Err: AlrHar");                  // Must not be harvested yet
        
        if(isGloballySettled == false) { // Only in case of world where Global Settlement is closed, can the secondaryPrice can be old
            require( secondaryStartTime > VaultLiquidationQs[_targetVault].liqStartTime[_position], "Err: OldSO" );     // requires the secondary oracle to have been updated after the challenge started.
        }
        
        // optional checks
        require( VaultLiquidationQs[_targetVault].weiAssetInSpot[_position] > 0 , "SErr: Wei");
        require( VaultLiquidationQs[_targetVault].vSPACEXDebtInSpotE18[_position] > 0, "SErr: vSP"); 
        require( VaultLiquidationQs[_targetVault].liqStartTime[_position]  + LIQ_WAIT_TIME < block.timestamp , "SErr: lCW"); // 28 hours must have elapsed as sanity check
        // TWAP price checked later
        // Function runner could be anyone
        
        // Payoff is both the base liquidate amount and the challenge amount:
        uint weiClaim = VaultLiquidationQs[_targetVault].weiAssetInSpot[_position] + VaultLiquidationQs[_targetVault].liqChallengeWei[_position];
        VaultLiquidationQs[_targetVault].weiAssetInSpot[_position] = 0;
        VaultLiquidationQs[_targetVault].liqChallengeWei[_position] = 0;
        
        
        
        // settle vaults
        VaultLiquidationQs[_targetVault].isLiqChallenged[_position] = false;
        VaultLiquidationQs[_targetVault].isHarvested[_position] = true;
        
        
        // transfer out
        if( weiPervSPACEXSecondary * 3 < VaultLiquidationQs[_targetVault].weiPervSPACEXTWAPAtChallenge[_position] ) { // if the secondary price is much less than old TWAP (thus short squeeze)
            // End in favor of the challenger (vault owner).  Credit the target Vault.
            weiAsset[_targetVault] = weiClaim.add( weiAsset[_targetVault] );
        } else { // this was not a short squeeze
            // End in favor of the liquidator
            VaultLiquidationQs[_targetVault].liquidator[_position].transfer( weiClaim );
        }
    }
    
    // The following functions are off off-equilibrium.  Thus they are vetted to be safe, but not necessarily efficient/optimal.


    // Global Settlement Functions. Global settlement must start with governance. However, afterwards, closing of Global Settlement can be done by anyone
    function registerGloballySettled() public { // Anyone can run this closing function
        require(inGlobalSettlement, "Gov must start settlement");
        require(block.timestamp > (globalSettlementStartTime + GLOBAL_SETTLEMENT_PERIOD), "Wait TIME to finalize.");
        require(!isGloballySettled, "Settlement Already Closed");
        settledWeiPervSPACEX = weiPervSPACEXSecondary;  // For fidelity, only actual SPACEX transaction prices (not vSPACEX coin) used for settlement.
        isGloballySettled = true;
    }
    
    function settledConvertvSPACEXtoWei(uint _vSPACEXTokenToConvertE18) public { // After Global Settlement (GS) someone who has vSPACEX can run to redeem.
        require(isGloballySettled);
        require(_vSPACEXTokenToConvertE18 < 10 ** 30, "Protective max bound for input hit");
        
        uint weiToReturn = _vSPACEXTokenToConvertE18.mul( settledWeiPervSPACEX ).div( 10 ** 18); // Rounds down
        
        // vSPACEX accounting is no longer double entry.  Destroy vSPACEX to get wei
        //vSPACEXToken.ownerApprove(msg.sender, _vSPACEXTokenToConvertE18);                       // Factory gives itself approval. Todo: Require owner give this contract control
        vSPACEXToken.ownerBurn(msg.sender, _vSPACEXTokenToConvertE18);                          // the actual deduction from the token contract
        msg.sender.transfer(weiToReturn);                                                       // return wei
    }
    
    
    function settledConvertVaulttoWei() public {        // After GS, someone who has a vault can withdraw the remaining value in the vault.
        require(isGloballySettled);
        
        uint weiDebt = vSPACEXDebtE18[msg.sender].mul( settledWeiPervSPACEX ).div( 10 ** 18).add( 1 );       // Convert vSPACEX Debt to Wei. Round up.
        require(weiAsset[msg.sender] > weiDebt, "This CTV is not above water, cannot convert");     
        
        uint weiEquity = weiAsset[msg.sender] - weiDebt;
        
        
        // Zero out CTV and transfer equity remaining
        vSPACEXDebtE18[msg.sender] = 0;
        weiAsset[msg.sender] = 0;
        msg.sender.transfer(weiEquity);  
    }

    


    function detachOwner() public { // an emergency function to commitally shut off the owner account while retaining residual functionality of tokens
        require(msg.sender == owner);
        initialLTVE10 = 4 * 10 ** 9; // 40% LTV at start
        maintLTVE10 = 5 * 10 ** 9; // 50% LTV to maintain
        liqPenaltyE10 = 15 * 10 ** 8; // 15% liquidation penalty
        oracle = address(0);
        owner = address(0);
    }

    
}