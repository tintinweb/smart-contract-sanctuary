pragma solidity 0.7.2;

// SPDX-License-Identifier: JPLv1.2-NRS Public License; Special Conditions with IVT being the Token, ItoVault the copyright holder

import "./SafeMath.sol";
import "./GeneralToken.sol";

contract VaultSystem {
    using SafeMath for uint256;
    
    event loguint(string name, uint value);
    
    GeneralToken public vSYMToken;
    GeneralToken public ivtToken;
    
    // NB: None of the storage variables below should store numbers greater than 1E36.   uint256 overflow above 1E73.
    // So it is safe to mul two numbers always. But to mul more than 2 requires decimal counting.
    
    uint public weiPervSYM = 10 ** 18; 
    uint public maxvSYME18 = 10000 * 10 ** 18;           // Upper Bound on Number of vSYM tokens
    uint public outstandingvSYME18 = 0;                 // Current outstanding vSYM tokens
    
    
    // Forward (not counter) Vault System
    uint public initialLTVE10   = 7 * 10 ** 9;    // Maximum starting loan to value of a vault                [Integer / 1E10]
    uint public maintLTVE10     = 8 * 10 ** 9;      // Maximum maintnenance loan to value of a vault            [Integer / 1E10]
    uint public liqPenaltyE10   = 1 * 10 ** 9;    // Bonus paid to any address for liquidating non-compliant
                                                // contract                                                 [Integer / 1E10]

    // In this system, individual vaults *are* addresses.  Instances of vaults then are mapped by bare address
    // Each vault has an "asset" side and a "debt" side
    mapping(address => uint) public weiAsset;           // Weis the Vault owns -- the asset side
    mapping(address => uint) public vSYMDebtE18;        // vSYM -- the debt side of the balance sheet of each Vault
    
    
    // Counter Vault Contract
    uint public initialLTVCounterVaultE10   = 7 * 10 ** 9;                // Maximum starting loan to value of a vault                [Integer / 1E10]
    uint public maintLTVCounterVaultE10     = 8 * 10 ** 9;                // Maximum maintnenance loan to value of a vault            [Integer / 1E10]
    uint public liqPenaltyCounterVaultE10   = 1 * 10 ** 9;              // Bonus paid to any address for liquidating non-compliant
                                                                        // contract                                                 [Integer / 1E10]
    mapping(address => uint) public vSYMAssetCounterVaultE18;             // vSYM deposited in inverse vault
    mapping(address => uint) public weiDebtCounterVault;                     // weiDebtCounterVault

    
    // The following variables track all Vaults.  Not strictly needed, but helps liquidate non-compliant vaults
    mapping(address => bool) public isAddressRegistered;    // Forward map to emulate a "set" struct
    address[] public registeredAddresses;                   // Backward map for "set" struct
    
    address payable public owner;                           // owner is also governor here.  to be passed to WATDAO in the future
    address payable public oracle;                          // 
    
    
    bool public inGlobalSettlement = false;
    uint public globalSettlementStartTime;
    uint public settledWeiPervSYM; 
    bool public isGloballySettled = false;
    
    
    uint public lastOracleTime;
    bool public oracleChallenged = false;   // Is the whitelisted oracle (system) in challenge?         
    uint public lastChallengeValue; // The weiPervSYM value of the last challenge                [Integer atomic weis per 1 unit SPX (e.g. SPX ~ $3300 in Oct 2020)]
    uint public lastChallengeIVT;   // The WATs staked in the last challenge                    [WAT atomic units]
    uint public lastChallengeTime;  // The time of the last challenge, used for challenge expiry[Seconds since Epoch]
    
    
    uint[] public challengeIVTokens;    // Dynamic array of all challenges, integer indexed to match analagous arrays, used like a stack in code
    uint[] public challengeValues;  // Dynamic array of all challenges, integer indexed, used like a stack in code
    address[] public challengers;   // Dynamic array of all challengers, integer indexed, used like a stack in code
    
    constructor() {
        owner = msg.sender;
        oracle = msg.sender;
        vSYMToken = new GeneralToken(10 ** 30, address(this), "vVTI Token V_1_0_0", "vVTI V1_0"); // 18 decimals after the point, 12 before
        ivtToken = GeneralToken(address(0xb5BC0481ff9EF553F11f031A469cd9DF71280A27));
    }

    
    // Oracle Functions
    function oracleUpdateweiPervSYM(uint _weiPervSYM) public {
        require(msg.sender == oracle, "Disallowed: You are not oracle");
        weiPervSYM = _weiPervSYM;
        lastOracleTime = block.timestamp;
    }
    

    // Governance Functions
    function govUpdateinitialLTVE10(uint _initialLTVE10) public {
        require(msg.sender == owner, "Disallowed: You are not governance");
        initialLTVE10 = _initialLTVE10;
    }
    
    function govUpdatemaintLTVE10(uint _maintLTVE10) public {
        require(msg.sender == owner, "Disallowed: You are not governance");
        maintLTVE10 = _maintLTVE10;
    }
    
    function govUpdateliqPenaltyE10(uint _liqPenaltyE10) public {
        require(msg.sender == owner, "Disallowed: You are not governance");
        liqPenaltyE10 = _liqPenaltyE10;
    }
    
    function govUpdateinitialLTVCounterVaultE10(uint _initialLTVCounterVaultE10) public {
        require(msg.sender == owner, "Disallowed: You are not governance");
        initialLTVCounterVaultE10 = _initialLTVCounterVaultE10;
    }
    
    function govUpdatemaintLTVCounterVaultE10(uint _maintLTVCounterVaultE10) public {
        require(msg.sender == owner, "Disallowed: You are not governance");
        maintLTVCounterVaultE10 = _maintLTVCounterVaultE10;
    }
    
    function govUpdateliqPenaltyCounterVaultE10(uint _liqPenaltyCounterVaultE10) public {
        require(msg.sender == owner, "Disallowed: You are not governance");
        liqPenaltyCounterVaultE10 = _liqPenaltyCounterVaultE10;
    }
    
    function govChangeOwner(address payable _owner) public {
        require(msg.sender == owner, "Disallowed: You are not governance");
        owner = _owner;
    }
    
    function govChangeOracle(address payable _oracle) public {
        require(msg.sender == owner, "Disallowed: You are not governance");
        oracle = _oracle;
    }
    
    function govChangeMaxvSYME18(uint _maxvSYME18) public {
        require(msg.sender == owner, "Disallowed: You are not governance");
        maxvSYME18 = _maxvSYME18;
    }
    
    function govStartGlobalSettlement() public {
        require(msg.sender == owner, "Disallowed: You are not governance");
        inGlobalSettlement = true;
        globalSettlementStartTime = block.timestamp;
    }
    
    
    
    // Vault Functions
    function depositWEI() public payable { // same as receive fallback; but explictily declared for symmetry
        require(msg.value > 0, "Must Deposit Nonzero Wei"); 
        weiAsset[msg.sender] = weiAsset[msg.sender].add( msg.value );
        
        if(isAddressRegistered[msg.sender] != true) { // if user was not registered before
            isAddressRegistered[msg.sender] = true;
            registeredAddresses.push(msg.sender);
        }
    }
    
    receive() external payable { // same as receive fallback; but explictily declared for symmetry
        require(msg.value > 0, "Must Deposit Nonzero Wei"); 
        
        // Receiving is automatic so double entry accounting not possible here
        weiAsset[msg.sender] = weiAsset[msg.sender].add( msg.value );
        
        if(isAddressRegistered[msg.sender] != true) { // if user was not registered before
            isAddressRegistered[msg.sender] = true;
            registeredAddresses.push(msg.sender);
        }
    }

    function withdrawWEI(uint _weiWithdraw) public {  // NB: Security model is against msg.sender
        // presuming contract withdrawal is from own vault
        require( _weiWithdraw < 10 ** 30, "Protective max bound for uint argument");
        
        // Maintenence Equation: (vSYMDebtE18/1E18) * weiPervSYM <= (weiAsset) * (initialLTVE10/1E10)
        // I need: (vSYMDebtE18)/1E18 * weiPervSYM <= (weiAsset - _weiWithdraw) * (initialLTVE10/1E10)
        uint LHS = vSYMDebtE18[msg.sender].mul( weiPervSYM ).mul( 10 ** 10 );
        uint RHS = (weiAsset[msg.sender].sub( _weiWithdraw )).mul( initialLTVE10 ).mul( 10 ** 18 );
        require ( LHS <= RHS, "Your initial margin is insufficient for withdrawing.");
        
        // Double Entry Accounting
        weiAsset[msg.sender] = weiAsset[msg.sender].sub( _weiWithdraw ); // penalize wei deposited before sending money out
        msg.sender.transfer(_weiWithdraw);
    }
    
    
    function lendvSYM(uint _vSYMLendE18) public {
        //presuming message sender is using his own vault
        require(_vSYMLendE18 < 10 ** 30, "Protective max bound for uint argument");
        require(outstandingvSYME18.add( _vSYMLendE18 ) <= maxvSYME18, "Current version limits max amount of vSYM possible");
        
        // Maintenence Equation: (vSYMDebtE18/1E18) * weiPervSYM <= (weiAsset) * (initialLTVE10/1E10)
        // I need: (_vSYMLendE18 + vSYMDebtE18)/1E18 * weiPervSYM  < weiAsset * (initialLTVE10/1E10)
        uint LHS = vSYMDebtE18[msg.sender].add( _vSYMLendE18 ).mul( weiPervSYM ).mul( 10 ** 10 );
        uint RHS = weiAsset[msg.sender].mul( initialLTVE10 ).mul( 10 ** 18 );
        require(LHS < RHS, "Your initial margin is insufficient for lending");
        
        // Double Entry Accounting
        vSYMDebtE18[msg.sender] = vSYMDebtE18[msg.sender].add( _vSYMLendE18 ); // penalize debt first.
        outstandingvSYME18 = outstandingvSYME18.add(_vSYMLendE18);
        vSYMToken.transfer(msg.sender, _vSYMLendE18);
    }
    
    function repayvSYM(uint _vSYMRepayE18) public {
        require(_vSYMRepayE18 < 10 ** 30, "Protective max bound for uint argument");
        
        vSYMToken.ownerApprove(msg.sender, _vSYMRepayE18); 
        
        // Double Entry Accounting
        vSYMToken.transferFrom(msg.sender, address(this), _vSYMRepayE18); // the actual deduction from the token contract
        vSYMDebtE18[msg.sender] = vSYMDebtE18[msg.sender].sub( _vSYMRepayE18 );
        outstandingvSYME18 = outstandingvSYME18.sub(_vSYMRepayE18);
    }
    
    
    function liquidateNonCompliant(uint _vSYMProvidedE18, address payable target_address) public { // liquidates a portion of the contract for non-compliance

        // While it possible to have a more complex liquidation system, since liqudations are off-equilibrium, for the MVP 
        // We have decided we want overly aggressive liqudiations 
        
        // Maintenence Equation: (vSYMDebtE18/1E18) * weiPervSYM <= (weiAsset) * (maintLTVE10/1E10)
        // For a violation, the above will be flipped: (vSYMDebtE18/1E18) * weiPervSYM > (weiAsset) * (maintLTVE10/1E10)
        
        require( _vSYMProvidedE18 <= vSYMDebtE18[target_address], "You cannot provide more vSYM than vSYMDebt outstanding");
        
        uint LHS = vSYMDebtE18[target_address].mul( weiPervSYM ).mul( 10 ** 10);
        uint RHS = weiAsset[target_address].mul( maintLTVE10 ).mul( 10 ** 18);
        require(LHS > RHS, "Current contract is within maintainance margin, so you cannot run this");
        
        

        
        
        // If this vault is underwater-with-respect-to-rewards (different than noncompliant), liquidation is pro-rata
        // underater iff: weiAsset[target_address] < vSYMDebtE18[target_address]/1E18 * weiPervSYM * (liqPenaltyE10+1E10)/1E10
        uint LHS2 = weiAsset[target_address].mul( 10 ** 18 ).mul( 10 ** 10);
        uint RHS2 = vSYMDebtE18[target_address].mul( weiPervSYM ).mul( liqPenaltyE10.add( 10 ** 10 ));
        
        uint weiClaim;
        if( LHS2 < RHS2 ) { // pro-rata claim
            // weiClaim = ( _vSYMProvidedE18 /  vSYMDebtE18[target_address]) * weiAsset[target_address];
            weiClaim = _vSYMProvidedE18.mul( weiAsset[target_address] ).div( vSYMDebtE18[target_address] );
        } else {
            // maxWeiClaim = _vSYMProvidedE18/1E18 * weiPervSYM * (1+liqPenaltyE10/1E10)
            weiClaim = _vSYMProvidedE18.mul( weiPervSYM ).mul( liqPenaltyE10.add( 10 ** 10 )).div( 10 ** 18 ).div( 10 ** 10 );
        }
        require(weiClaim <= weiAsset[target_address], "Code Error if you reached this point");
        
        
        // Double Entry Accounting for returning vSYM Debt back
        vSYMToken.ownerApprove(msg.sender, _vSYMProvidedE18); 
        vSYMToken.transferFrom(msg.sender, address(this), _vSYMProvidedE18); // the actual deduction from the token contract
        vSYMDebtE18[target_address] = vSYMDebtE18[target_address].sub( _vSYMProvidedE18 );
        outstandingvSYME18 = outstandingvSYME18.sub( _vSYMProvidedE18 );
        
        
        // Double Entry Accounting for deducting the vault's assets
        weiAsset[target_address] = weiAsset[target_address].sub( weiClaim );
        msg.sender.transfer( weiClaim );
    }


    

    
    // Counter Vault Functions
    function depositvSYMCounterVault(uint _vSYMDepositE18) public { 
        require( _vSYMDepositE18 < 10 ** 30, "Protective max bound for uint argument");
        
        // Transfer Tokens from sender, then double-entry account for it
        vSYMToken.ownerApprove(msg.sender, _vSYMDepositE18); 
        vSYMToken.transferFrom(msg.sender, address(this), _vSYMDepositE18);
        vSYMAssetCounterVaultE18[msg.sender] = vSYMAssetCounterVaultE18[msg.sender].add(_vSYMDepositE18);
        
        if(isAddressRegistered[msg.sender] != true) { // if user was not registered before
            isAddressRegistered[msg.sender] = true;
            registeredAddresses.push(msg.sender);
        }
    }
    

    function withdrawvSYMCounterVault(uint _vSYMWithdrawE18) public {
        require( _vSYMWithdrawE18 < 10 ** 30, "Protective max bound for uint argument");
        
        // Master equation for countervault: (weiDebtCounterVault ) < (vSYMAssetCounterVaultE18)/1E18 * weiPervSYM * (initialLTVCounterVaultE10/1E10) 
        // I need: (weiDebtCounterVault ) < (vSYMAssetCounterVaultE18 - _vSYMLendE18)/1E18 * weiPervSYM * (initialLTVCounterVaultE10/1E10) 
        uint LHS = weiDebtCounterVault[msg.sender].mul( 10 ** 10 ).mul( 10 ** 18 );
        uint RHS = vSYMAssetCounterVaultE18[msg.sender].sub( _vSYMWithdrawE18 ).mul( weiPervSYM ).mul( initialLTVCounterVaultE10 );
        require ( LHS <= RHS, 'Your initial margin is insufficient for withdrawing.' );
        
        vSYMAssetCounterVaultE18[msg.sender] =  vSYMAssetCounterVaultE18[msg.sender].sub( _vSYMWithdrawE18 ); // Penalize Account First
        vSYMToken.transfer(msg.sender, _vSYMWithdrawE18);
    }
    
    
    function lendWeiCounterVault(uint _weiLend) public {
        //presuming message sender is using his own vault
        require(_weiLend < 10 ** 30, "Protective Max Bound for Input Hit");

        // Master equation for countervault: (weiDebtCounterVault ) < (vSYMAssetCounterVaultE18)/1E18 * weiPervSYM * (initialLTVCounterVaultE10/1E10) 
        // I need: (weiDebtCounterVault + _weiWithdraw ) < weiPervSYM * (vSYMAssetCounterVaultE18/1E18) * (initialLTVCounterVaultE10/1E10) 
        
        uint LHS = weiDebtCounterVault[msg.sender].add( _weiLend ).mul( 10** 18 ).mul( 10 ** 10 );
        uint RHS = weiPervSYM.mul( vSYMAssetCounterVaultE18[msg.sender] ).mul( initialLTVCounterVaultE10 );
        
        require(LHS <= RHS, "Your initial margin is insufficient for lending.");
        
        // Double-entry accounting
        weiDebtCounterVault[msg.sender] = weiDebtCounterVault[msg.sender].add( _weiLend );    // penalize debt first.
        msg.sender.transfer(_weiLend);
    }
    
    function repayWeiCounterVault() public payable {
        require(msg.value < 10 ** 30, "Protective Max Bound for Input Hit");
        require(msg.value <= weiDebtCounterVault[msg.sender], "You cannot pay down more Wei debt than exists in this counterVault");
        
        // Single entry accounting
        weiDebtCounterVault[msg.sender] = weiDebtCounterVault[msg.sender].sub( msg.value );
    }
    
    


    

    function liquidateNonCompliantCounterVault(address payable _targetCounterVault) payable public { // liquidates a portion of the counterVault for non-compliance
        
        // Security Presumption here is against favor of the runner of this function
        require( msg.value < 10 ** 30 , "Protective Max Bound for WEI Hit");
        require( msg.value <= weiDebtCounterVault[_targetCounterVault], "You cannot provide more Wei than Wei debt outstanding");
        
        // Vault Needs to be in Violation: (weiDebtCounterVault ) > (vSYMAssetCounterVaultE18)/1E18 * weiPervSYM * (maintLTVE10InverseVault/1E10)
        uint LHS = weiDebtCounterVault[_targetCounterVault].mul( 10 ** 18 ).mul( 10 ** 10 );
        uint RHS = vSYMAssetCounterVaultE18[_targetCounterVault].mul( weiPervSYM ).mul( maintLTVCounterVaultE10 );
        emit loguint("RHS", RHS);
        emit loguint("LHS", LHS);
        
        require(LHS > RHS, "Current contract is within maintenence margin");
        
        
        // If this Counter Vault is underwater-with-respect-to-rewards (different than noncompliant), liquidation is pro-rata  
        // underater iff: vSYMAssetCounterVaultE18[_targetCounterVault] <  (weiDebtCounterVault[_targetCounterVault]/ weiPervSYM) * 1E18 * (liqPenaltyCounterVaultE10+1E10)/1E10
        uint LHS2 = vSYMAssetCounterVaultE18[_targetCounterVault];
        uint RHS2 = weiDebtCounterVault[_targetCounterVault].mul( liqPenaltyCounterVaultE10.add( 10 ** 10 )).mul( 10 ** 8 ).div( weiPervSYM );
        
        emit loguint("RHS2", RHS2);
        emit loguint("LHS2", LHS2);
        
        uint vSYMClaimE18;
        if( LHS2 < RHS2 ) { // if vault is rewards-underwater, pro-rate
            // vSYMClaimE18 = ( msg.value /  weiDebtCounterVault[_targetCounterVault]) * vSYMAssetCounterVaultE18[_targetCounterVault];
            vSYMClaimE18 = msg.value.mul( vSYMAssetCounterVaultE18[_targetCounterVault] ).div( weiDebtCounterVault[_targetCounterVault] );
            require(vSYMClaimE18 <= vSYMAssetCounterVaultE18[_targetCounterVault], "Code Error Branch 1 if you reached this point");
        } else { // if we have more than enough assets in this countervault
            // vSYMClaimE18 = (msg.value / weiPervSYM) * 1E18 * (1E10+liqPenaltyE10) /1E10
            vSYMClaimE18 = msg.value.mul( liqPenaltyCounterVaultE10.add( 10 ** 10 )).mul( 10 ** 8 ).div(weiPervSYM) ;
            require(vSYMClaimE18 <= vSYMAssetCounterVaultE18[_targetCounterVault], "Code Error Branch 2 if you reached this point");
            
        }
        
        
        // Single Entry Accounting for Returning the wei Debt
        weiDebtCounterVault[_targetCounterVault] = weiDebtCounterVault[_targetCounterVault].sub( msg.value );
        

        // Double Entry Accounting
        vSYMAssetCounterVaultE18[_targetCounterVault] = vSYMAssetCounterVaultE18[_targetCounterVault].sub( vSYMClaimE18 ); // Amount of Assets to Transfer override
        vSYMToken.transfer( msg.sender , vSYMClaimE18 );
        
    }
    
    
    
    function partial1LiquidateNonCompliantCounterVault(address payable _targetCounterVault) payable public returns(uint, uint)  { // liquidates a portion of the counterVault for non-compliance
        
        // Security Presumption here is against favor of the runner of this function
        require( msg.value < 10 ** 30 , "Protective Max Bound for WEI Hit");
        require( msg.value <= weiDebtCounterVault[_targetCounterVault], "You cannot provide more Wei than Wei debt outstanding");
        
        // Vault Needs to be in Violation: (weiDebtCounterVault ) > (vSYMAssetCounterVaultE18)/1E18 * weiPervSYM * (maintLTVE10InverseVault/1E10)
        uint LHS = weiDebtCounterVault[_targetCounterVault].mul( 10 ** 18 ).mul( 10 ** 10 );
        uint RHS = vSYMAssetCounterVaultE18[_targetCounterVault].mul( weiPervSYM ).mul( maintLTVCounterVaultE10 );
        
        require(LHS > RHS, "Current contract is within maintenence margin");
        
        return(LHS, RHS);
        
    }
    
    
    function partial2LiquidateNonCompliantCounterVault(address payable _targetCounterVault) payable public returns(uint, uint)  { // liquidates a portion of the counterVault for non-compliance
        
        // Security Presumption here is against favor of the runner of this function
        require( msg.value < 10 ** 30 , "Protective Max Bound for WEI Hit");
        require( msg.value <= weiDebtCounterVault[_targetCounterVault], "You cannot provide more Wei than Wei debt outstanding");
        
        // Vault Needs to be in Violation: (weiDebtCounterVault ) > (vSYMAssetCounterVaultE18)/1E18 * weiPervSYM * (maintLTVE10InverseVault/1E10)

        
        
        // If this Counter Vault is underwater-with-respect-to-rewards (different than noncompliant), liquidation is pro-rata  
        // underater iff: vSYMAssetCounterVaultE18[_targetCounterVault] <  (weiDebtCounterVault[_targetCounterVault]/ weiPervSYM) * 1E18 * (liqPenaltyCounterVaultE10+1E10)/1E10
        uint LHS2 = vSYMAssetCounterVaultE18[_targetCounterVault];
        uint RHS2 = weiDebtCounterVault[_targetCounterVault].mul( liqPenaltyCounterVaultE10.add( 10 ** 10 )).mul( 10 ** 8 ).div( weiPervSYM );
        return(LHS2, RHS2);
        
    }
    
    
    
    function findNoncompliantVaults(uint _limitNum) public view returns(address[] memory, uint[] memory, uint[] memory, uint[] memory, uint[] memory, uint) {   // Return the first N noncompliant vaults
        require(_limitNum > 0, 'Must run this on a positive integer');
        address[] memory noncompliantAddresses = new address[](_limitNum);
        uint[] memory LHSs_vault = new uint[](_limitNum);
        uint[] memory RHSs_vault = new uint[](_limitNum);
        
        uint[] memory LHSs_counterVault = new uint[](_limitNum);
        uint[] memory RHSs_counterVault = new uint[](_limitNum);
        
        
        uint j = 0;  // Iterator up to _limitNum
        for (uint i=0; i<registeredAddresses.length; i++) {
            if(j>= _limitNum) {
                break;
            } 
            // Vault maintainance margin violation: (vSYMDebtE18)/1E18 * weiPervSYM  > weiAsset * (maintLTVE10)/1E10 for a violation
            uint LHS_vault = vSYMDebtE18[registeredAddresses[i]].mul(weiPervSYM);
            uint RHS_vault  = weiAsset[registeredAddresses[i]].mul( maintLTVE10 ).mul( 10 ** 8);
            
            
            // Countervault maintenance margin violation:  (weiDebtCounterVault ) > (vSYMAssetCounterVaultE18)/1E18 * weiPervSYM * (maintLTVE10InverseVault/1E10)
            uint LHS_counterVault = weiDebtCounterVault[registeredAddresses[i]].mul( 10 ** 18 ).mul( 10 ** 10 );
            uint RHS_counterVault = vSYMAssetCounterVaultE18[registeredAddresses[i]].mul( weiPervSYM ).mul( maintLTVCounterVaultE10 );
            
            if( (LHS_vault > RHS_vault) || (LHS_counterVault > RHS_counterVault) ) {
                noncompliantAddresses[j] = registeredAddresses[i];
                LHSs_vault[j] = LHS_vault;
                RHSs_vault[j] = RHS_vault;
                LHSs_counterVault[j] = LHS_counterVault;
                RHSs_counterVault[j] = RHS_counterVault;

                j = j + 1;
            }
        }
        return(noncompliantAddresses, LHSs_vault, RHSs_vault, LHSs_counterVault, RHSs_counterVault,  j);
    }
    

    // The following functions are off off-equilibrium.  Thus they are vetted to be safe, but not necessarily efficient/optimal.


    // Global Settlement Functions
    function registerGloballySettled() public { // Anyone can run this closing function
        require(inGlobalSettlement, "Register function can only be run if governance has declared global settlement");
        require(block.timestamp > (globalSettlementStartTime + 14 days), "Need to wait 14 days to finalize global settlement");
        require(!isGloballySettled, "This function has already be run; can only be run once.");
        settledWeiPervSYM = weiPervSYM;
        isGloballySettled = true;
    }
    
    function settledConvertvSYMtoWei(uint _vSYMTokenToConvertE18) public {
        require(isGloballySettled);
        require(_vSYMTokenToConvertE18 < 10 ** 30, "Protective max bound for input hit");
        
        uint weiToReturn = _vSYMTokenToConvertE18.mul( settledWeiPervSYM ).div( 10 ** 18); // Rounds down
        
        // vSYM accounting is no longer double entry.  Destroy vSYM to get wei
        vSYMToken.ownerApprove(msg.sender, _vSYMTokenToConvertE18);                     // Factory gives itself approval
        vSYMToken.transferFrom(msg.sender, address(this), _vSYMTokenToConvertE18);    // the actual deduction from the token contract
        msg.sender.transfer(weiToReturn);                                           // return wei
    }
    
    
    function settledConvertVaulttoWei() public {
        require(isGloballySettled);
        
        uint weiDebt = vSYMDebtE18[msg.sender].mul( settledWeiPervSYM ).div( 10 ** 18).add( 1 );               // Round up value of debt
        require(weiAsset[msg.sender] > weiDebt, "This CTV is not above water, cannot convert");     
        
        uint weiEquity = weiAsset[msg.sender] - weiDebt;
        
        
        // Zero out CTV and transfer equity remaining
        vSYMDebtE18[msg.sender] = 0;
        weiAsset[msg.sender] = 0;
        msg.sender.transfer(weiEquity);  
    }

    

    // Challenge Functions -- non-optimized
    function startChallengeWeiPervSYM(uint _proposedWeiPervSYM, uint _ivtStaked) public {
        // Checking we're in the right state
        require(lastOracleTime > 0, "Cannot challenge a newly created smart contract");
        require(block.timestamp.sub( lastOracleTime ) > 14 days, "You must wait for the whitelist oracle to not respond for 14 days" );
        require(_ivtStaked >= 10 * 10 ** 18, 'You must challenge with at least ten IVT');
        require(_proposedWeiPervSYM != weiPervSYM, 'You do not disagree with current value of weiPervSYM');
        require(oracleChallenged == false);
        
        
        // Deducting tokens and crediting
        uint256 allowance = ivtToken.allowance(msg.sender, address(this));
        require(allowance >= _ivtStaked, 'You have not allowed this contract access to the number of IVTs you claim');
        ivtToken.transferFrom(msg.sender, address(this), _ivtStaked); // the actual deduction from the token contract
        
        // Credit this challenger
        challengers.push(msg.sender);
        
        // Start the challenge
        oracleChallenged = true;
        challengeValues.push(_proposedWeiPervSYM);
        challengeIVTokens.push(_ivtStaked);
        lastChallengeValue = _proposedWeiPervSYM;
        lastChallengeTime = block.timestamp;
    }
    
    function rechallengeWeiPervSYM(uint _proposedWeiPervSYM, uint _ivtStaked) public {
        require(oracleChallenged == true, "rechallenge cannot be run if challenge has not started.  consider startChallengeWeiPervSYM()");
        require(_ivtStaked >= lastChallengeIVT * 2, "You must double the IVT from the last challenge");
        require(_proposedWeiPervSYM != lastChallengeValue, "You do not disagree with last challenge of weiPervSYM");
        
        
        // Deducting tokens and crediting
        uint256 allowance = ivtToken.allowance(msg.sender, address(this));
        require(allowance >= _ivtStaked, 'You have not allowed this contract access to the number of WATs you claim');
        ivtToken.transferFrom(msg.sender, address(this), _ivtStaked); // the actual deduction from the token contract
        
        // Credit this challenger
        challengers.push(msg.sender);
        
        // Actually do the challenge
        challengeValues.push(_proposedWeiPervSYM);
        challengeIVTokens.push(_ivtStaked);
        lastChallengeValue = _proposedWeiPervSYM;
        lastChallengeTime = block.timestamp;
        lastChallengeIVT = _ivtStaked;
    }
    
    function endChallegeWeiPerSPX() public {
        require(oracleChallenged == true, "Consider startChallengeWeiPervSYM()");
        require(block.timestamp.sub( lastChallengeTime ) > 2 days, "You must wait 2 days since the last challenge to end the challenge");
        
        // This now makes effective the challenge oracle
        weiPervSYM = lastChallengeValue;
        
        // initialize cumulative counter of correct vs incorrect wats
        uint incorrectIvts = 0;
        uint correctIvts = 0; 
        
        // calculate the payback ratio
        for(uint i = 0; i < challengeIVTokens.length; i++) {
            if(challengeValues[i] == weiPervSYM) {
                correctIvts += challengeIVTokens[i];
            } else {
                incorrectIvts += challengeIVTokens[i];
            }
        }
        
        // Distribute the tokens
        for(uint i = 0; i < challengeIVTokens.length; i++) {  //NB -- this should not be very long due to block gas limits
            if(challengeValues[i] == weiPervSYM) {
                uint toTransfer =  incorrectIvts.add(correctIvts).mul( challengeIVTokens[i] ).div( correctIvts );
                
                // best practice: remove this person's credit first
                challengeIVTokens[i] = 0;
                vSYMToken.transfer(challengers[i], toTransfer);
            } else {
                // erase the challengeIVTokens
                challengeIVTokens[i] = 0;
            }
        }
        
        // reset arrays to zero type
        delete challengeIVTokens;
        delete challengeValues;
        delete challengers;
        
        lastChallengeValue = 0;
        lastChallengeIVT = 0;
        lastChallengeTime = 0;
        
        // end challenge
        oracleChallenged = false;
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