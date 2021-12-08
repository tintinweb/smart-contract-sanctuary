// CompoundVault.sol
// SPDX-License-Identifier: MIT

/**
        IDX Digital Labs Strategist iComp Vault
        Author: Ian Decentralize

        You must own an NFT key to interact with the protocol
 */

pragma solidity ^0.8.0;

import "../interfaces/protocols/idx/IKEY.sol";
import "../interfaces/protocols/compound/Comptroller.sol";
import "../interfaces/protocols/compound/CErc20.sol";
import "../interfaces/protocols/compound/CEther.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";



contract iCOMPV2Test is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address ETHER;
    address public strategist;           
    address public collateral;          
    address public farming;           
    address public borrowed;          
    address public borrowedCollateral;
    bool debt;
    uint256 public fees;
    uint256 feeBase;
    uint256 public vaultTier;
    string public symbol;
    
    //ID => AMOUNT
    mapping(uint256 => uint256) public shares;  
    mapping(uint256 => uint256) public collaterals; 

    bytes32 STRATEGIST_ROLE;

     // Compound
     IERC20Upgradeable COMP;                                     
     Comptroller comptroller;

     // IDNFT
     IKEY idnft;
    
    // event
    event Mint(address user, uint256 id, address asset, uint256 amount);
    event Redeem(address user, uint256 id, address asset, uint256 amount);
    event CompoundClaimed(address caller, uint256 amount);
    event Borrowed(address asset, uint256 amount);
    event Repayed(address asset, uint256 amount);
    event VaultOwnershipTransferred(address oldStrategist, address newStrategist);

    /// @dev Constructor
    /// @param _strategist address of the strategist contract.
    /// @param _compoundedAsset address of the cToken contract (collateral).
    /// @param _underlyingAsset address of the asset to farm.
    /// @param _protocolFees fees in base 3
    /// @param _comptroller Compound controller address
    /// @param _COMP COMP Token address
    /// @param _idnftAddress address of NFT ID Contract.

    function initialize(
        address _strategist,
        address _compoundedAsset,
        address _underlyingAsset,
        uint256 _protocolFees,
        address _comptroller,
        address _COMP,
        address _idnftAddress,
        uint256 _vaultTier
    ) public initializer {
        __AccessControl_init();
        __Pausable_init();
        STRATEGIST_ROLE = keccak256("STRATEGIST_ROLE");
        _setupRole(STRATEGIST_ROLE, _strategist);
        strategist = _strategist;
        fees = _protocolFees;
        feeBase = 10000;
        collateral = _compoundedAsset;
        farming = _underlyingAsset;
        comptroller = Comptroller(_comptroller);
        _enterMarketInt(_compoundedAsset);
        COMP = IERC20Upgradeable(_COMP);
        ETHER = address(0);
        idnft = IKEY(_idnftAddress);
        vaultTier = _vaultTier;
        symbol = "iComp";
    }

    /// @notice PUBLIC FUNCTIONS
    /// @notice Mint
    /// @dev INTERFACABLE
    /// @param _amount The amount to deposit that must be approved in farming asset. The call must be made by the key owner
    /// @param _id The NFT Key id
    /// @return returnedCollateral the amount minted

    function mint(uint256 _amount, uint256 _id)
        external
        payable
        whenNotPaused
        returns (uint256 returnedCollateral)
    {
        require(_callerID(_id),"Use mintOnBehalfOf!");
        returnedCollateral = _mint(_amount, _id);
        return returnedCollateral;
    }

    /// @notice Mint On Behalf Of a key not in the callers wallet.
    /// @param _amount The amount to deposit that must be approved in farming asset
    /// @param _id The NFT ID
    /// @return returnedCollateral the amount minted

    function mintOnBehalfOf(uint256 _amount, uint256 _id)
        external
        payable
        whenNotPaused
        returns (uint256 returnedCollateral)
    {
        require(_id <= idnft.totalSupply(),'iComp : Inexistant id!');
        require(idnft.tokenTier(_id) >= vaultTier,'iComp : Key tier not met!');
        returnedCollateral = _mint(_amount, _id);
        return returnedCollateral;
    }


    /// @notice Redeem an amount on a key. The Call must be make by the key owner
    /// @param _amount the amount redemed in vault asset
    /// @param _id the Key Id 

    function redeem(uint256 _amount, uint256 _id) external whenNotPaused returns (uint256 transferedAmount) {
        require(_callerID(_id),"Must be id holder!");
        require(_amount > 0, "iCOMP : Zero Amount!");
        transferedAmount = _redeem(_amount, _id);

        return transferedAmount;

    }

    /// @notice Return the balance of a key in this vault
    function balanceOf(uint256 _id) public view returns(uint256){

        return _getAssetAmount(collaterals[_id]);
    }

    /// @notice INTERNAL MINT
    function _mint(uint256 _amount, uint256 _id) internal returns(uint256 returnedCollateral) {

        IERC20Upgradeable asset = IERC20Upgradeable(farming);
        if (farming == ETHER) {
            require(msg.value > 0, "iCOMP : Zero Ether!");
            returnedCollateral = buyETHPosition(msg.value);
            shares[_id] += msg.value;
        } else if (farming != ETHER) {
            require(_amount > 0, "iCOMP : Zero Amount!");
            require(
                asset.transferFrom(msg.sender, address(this), _amount),
                "iCOMP : Transfer failled!"
            );
            returnedCollateral = buyERC20Position(_amount);
            shares[_id] += _amount;
        }
        collaterals[_id] += returnedCollateral;

        emit Mint(msg.sender, _id, farming, _amount);
        
        return returnedCollateral;
    }

    /// @notice INTERNAL REDEEM
    /// @dev receipt 0 must euqalr 0 
    function _redeem(uint256 _amount, uint256 _id) internal returns(uint256 transferedAmount){
      CErc20(collateral).exchangeRateCurrent();
       uint256[] memory receipt = _vaultComputation(_amount, _id);
      
        require(receipt[0] == 0, "iCOMP : Overflow");
        require(
            collaterals[_id] >= (receipt[3] + receipt[4]),
            "iCOMP : Insufucient collaterals!"
        );
        if(receipt[4] > 0){
           collaterals[0] += receipt[4];
        }
        collaterals[_id] -= (receipt[3] + receipt[4]);
        shares[_id] -= receipt[1];
        if (farming == ETHER) {
            transferedAmount = sellETHPosition(receipt[3]);
            payable(msg.sender).transfer(transferedAmount);
        } else if (farming != ETHER) {
            IERC20Upgradeable asset = IERC20Upgradeable(farming);
            transferedAmount = sellERC20Position(receipt[3]);
            asset.transfer(msg.sender, transferedAmount);
        }
     
     
        
        emit Redeem(msg.sender, _id, farming, transferedAmount);

        return transferedAmount;

 }

    /// @notice BUY ERC20 Position
    /// @dev INTERNAL 
    /// @param _amount the amount to deposit in IDXVault
    /// @return returnedAmount in collateral shares

    function buyERC20Position(uint256 _amount)
        internal
        whenNotPaused
        returns (uint256 returnedAmount)
    {
        CErc20 cToken = CErc20(collateral);
        IERC20Upgradeable asset = IERC20Upgradeable(farming);
        uint256 balanceBefore = cToken.balanceOf(address(this));
        asset.safeApprove(address(cToken), _amount);
        assert(cToken.mint(_amount) == 0);
        uint256 balanceAfter = cToken.balanceOf(address(this));
        returnedAmount = balanceAfter - balanceBefore;

        return returnedAmount;
    }

    /// @notice BUY ETH Position
    /// @dev
    /// @param _amount the amount to deposit in IDXVault
    /// @return returnedAmount in collateral shares

    function buyETHPosition(uint256 _amount)
        internal
        whenNotPaused
        returns (uint256 returnedAmount)
    {
        CEther cToken = CEther(collateral);
        uint256 balanceBefore = cToken.balanceOf(address(this));
        cToken.mint{value: _amount}();
        uint256 balanceAfter = cToken.balanceOf(address(this));
        returnedAmount = balanceAfter - balanceBefore;

        return returnedAmount;
    }

    /// @notice SELL ERC20 Position
    /// @dev will get the current rate to sell position at current price.
    /// @param _amount the amount in collateralls
    /// @return returnedAmount is in native asset

    function sellERC20Position(uint256 _amount)
        internal
        whenNotPaused
        returns (uint256 returnedAmount)
    {
        CErc20 cToken = CErc20(collateral);
        IERC20Upgradeable asset = IERC20Upgradeable(farming);
        // we want latest rate
        uint256 balanceB = asset.balanceOf(address(this));
        cToken.approve(address(cToken), _amount);
        require(cToken.redeem(_amount) == 0, "iCOMP : CToken Redeemed Error?");
        uint256 balanceA = asset.balanceOf(address(this));
        returnedAmount = balanceA - balanceB;

        return returnedAmount; //in ERC20 native asset
    }


    /// @notice SELL ERC20 Position
    /// @dev will get the current rate to sell position at current price.
    /// @param _amount in USD
    /// @return returnedAmount in ETH based on balance

    function sellETHPosition(uint256 _amount)
        internal
        whenNotPaused
        returns (uint256 returnedAmount)
    {
        CEther cToken = CEther(collateral);
        uint256 balanceBefore = address(this).balance;
        cToken.approve(address(cToken), _amount);
        require(
            cToken.redeem(_amount) == 0,
            "iCOMP : CToken Redeemed Error?"
        );
        uint256 balanceAfter = address(this).balance;
        returnedAmount = balanceAfter - balanceBefore;

        return returnedAmount; // in Ether
    }

    /// @notice Compute the gains and fees
    /// @dev VAULT SPECIFIC Must return 0 error
    
    function _vaultComputation(uint256 _amount, uint256 _id)
        public
        view
        returns (uint256[] memory)
    {

        uint256[] memory txData = new uint256[](5);

        // already include rate
       uint256 underlyingMax = _getAssetAmount(collaterals[_id]);

        if(_amount > underlyingMax){
            txData[0] = 1;
            return txData;
        }

        uint256 gainQuotient = quotient(underlyingMax,shares[_id],18);
        // no gain factor is 1
        if(gainQuotient <= 1e18){
            gainQuotient = 1e18;
        }
        
        uint256 shareConsumed = _amount * 1e18 / gainQuotient; 

        txData[1] = shareConsumed;

        uint256 gain  = (gainQuotient * shareConsumed / 1e18 ) - shareConsumed;

        uint256 _fees  = gain / feeBase * fees; 
        
        uint256 feesInCollateral = _getCollateralAmount(_fees);
        
        uint256 redeemedCollaterals = _getCollateralAmount(_amount);
      
        txData[2] = _getAssetAmount( redeemedCollaterals - feesInCollateral ); 

        txData[3]  =  redeemedCollaterals;  // collateral withdrawn from compound
        txData[4]  = feesInCollateral;      // collateral payed in fees

        if((txData[3] + txData[4]) > collaterals[_id]){
           txData[0] = 1;
           return txData;
        }
    
        return txData;    
    }


    /// @dev UTIL MATH
    function quotient(
        uint256 numerator,
        uint256 denominator,
        uint256 precision
    ) internal pure returns (uint256 _quotient) {
        uint256 _numerator = numerator * 10**(precision + 1);
        _quotient = ((_numerator / denominator) + 5) / 10;
        return (_quotient);
    }

    /// @notice Get the collaterall amount expected
    /// @dev INTERNAL
    /// @param _amount the amount in farming asset
    /// @return collateralAmount : The amount of cToken for the input amount in farmed asset

    function _getCollateralAmount(uint256 _amount)
        public
        view
        returns (uint256 collateralAmount)
    {   
        if(farming == ETHER){
            collateralAmount = (_amount * 1e18) / CEther(collateral).exchangeRateStored();
        }else{
            collateralAmount = (_amount * 1e18) / CErc20(collateral).exchangeRateStored();
        }
        return collateralAmount;
    }

    /// @notice Get the collaterall amount expected
    /// @dev INTERNAL
    /// @param _amount in cToken
    /// @return assetAmount : The amount of cToken for the input amount in farmed asset

    function _getAssetAmount(uint256 _amount)
        public
        view
        returns (uint256 assetAmount)
    {
        if(farming == ETHER){
             assetAmount = CEther(collateral).exchangeRateStored() * _amount / 1e18;
        }else{
             assetAmount = CErc20(collateral).exchangeRateStored() * _amount / 1e18;
        }
        return assetAmount;
    }

    /// @notice Claim Compound Distribution and transfer the balance to the strategist
    /// @dev VAULT SPECISFIC
    function claimUnderlyingReward() external whenNotPaused returns (uint256) {
       
        address[] memory cTokens;
        if(CErc20(collateral).balanceOf(address(this)) == 0){
            return 0;
        }
        // dual claim only when borrowing
        if(borrowedAmount() > 0){
            cTokens = new address[](2); 
            cTokens[0] = collateral;
            cTokens[1] = borrowedCollateral;
        }else{
            cTokens = new address[](1);
            cTokens[0] = collateral;
        }
        comptroller.claimComp(address(this), cTokens);
        uint256 balance = COMP.balanceOf(address(this));
        COMP.transfer(strategist, balance);
        emit CompoundClaimed(msg.sender, balance);
        return balance; 
    }

    /// @notice ENTER COMPOUND MARKET
    /// @param cAsset The cToken we want to interact with on Compound 
    /// @dev Exiting market for unused asset will lower the TX cost with Compound

    function _enterMarket(address cAsset) public {
        require(hasRole(STRATEGIST_ROLE, msg.sender), "iCOMP : Unauthorized?");
        address[] memory cTokens = new address[](1);
        cTokens[0] = cAsset;
        uint256[] memory errors = comptroller.enterMarkets(cTokens);
        require(errors[0] == 0, "iCOMP : Market Fail");
    }

    function _enterMarketInt(address cAsset) internal {
        address[] memory cTokens = new address[](1);
        cTokens[0] = cAsset;
        uint256[] memory errors = comptroller.enterMarkets(cTokens);
        require(errors[0] == 0, "iCOMP : Market Fail");
    }

    /// @notice EXIT COMPOUND MARKET.
    /// @param cAsset The asset we want to remove (cToken)
    /// @dev Exiting market for unused asset will lower the TX cost with Compound

    function _exitMarket(address cAsset) public {
        require(hasRole(STRATEGIST_ROLE, msg.sender), "iCOMP : Unauthorized?");
        uint256 errors = comptroller.exitMarket(cAsset);
        require(errors == 0, "Exit CMarket?");
    }

    /// @notice BORROW ON COMPOUND.
    /// @dev INTERFACABLE
    /// @param amount the amount to borrow
    /// @param cAsset the asset to borrow
    /// @param asset the native asset
  
    function _borrow(
        uint256 amount,
        address cAsset,
        address asset
    ) external whenNotPaused returns (uint256 _borrowed) {
        require(hasRole(STRATEGIST_ROLE, msg.sender), "iCOMP : Unauthorized?");
        IERC20Upgradeable token = IERC20Upgradeable(asset);
        uint256 balanceBefore = token.balanceOf(address(this));
        if(farming == ETHER){
            CEther cToken = CEther(cAsset);
            require(cToken.borrow(amount) == 0, "got collateral?");
        }else{
            CErc20 cToken = CErc20(cAsset);
            require(cToken.borrow(amount) == 0, "got collateral?");
        }
        uint256 balanceAfter = token.balanceOf(address(this));
        _borrowed = balanceAfter - balanceBefore;
        token.transfer(strategist, _borrowed);
        borrowed = asset;
        borrowedCollateral = cAsset;
        debt = true;
        emit Borrowed(asset, amount);
        return _borrowed;
    }

    /// @dev need to be improved
    function borrowedAmount() public view returns(uint256 _borrowedAmount){
       if (debt){
            _borrowedAmount = CErc20(borrowedCollateral).borrowBalanceStored(address(this));
            return _borrowedAmount;
       }
       return 0;
    }

    /// @notice Strategist fees.
    /// @dev INTERFACABLE Fees are sent to startegist
    function _getFees() external {
        require(hasRole(STRATEGIST_ROLE, msg.sender), "iCOMP : Unauthorized?");
        if(farming == ETHER){
            CEther cToken = CEther(collateral);
            cToken.transfer(strategist, collaterals[0]);
        }else{
              CErc20 cToken = CErc20(collateral);  
              cToken.transfer(strategist, collaterals[0]);
        }       
        collaterals[0] = 0;
    }

    /// @notice SECURITY.

   /// @notice THIS VAULT ACCEPT ETHER
    receive() external payable {
        // nothing to do
    }

    /// @notice Check that the key his authorized 
    function _callerID(uint256 _tokenId) internal view returns(bool){
        if(_tokenId < 1){
           return false;
        }
        if(_tokenId > idnft.totalSupply()){
           return false;
        }

        if(idnft.ownerOf(_tokenId) != msg.sender ){
           return false;
        }
        if( vaultTier >  idnft.tokenTier(_tokenId)  ){
           return false;
        }

       return true;
    }

    /// @notice pause or unpause.
    /// @dev INTERFACABLE

    function pause() public whenNotPaused {
        require(
            hasRole(STRATEGIST_ROLE, msg.sender),
            "iCOMP : Unauthorized!"
        );
        _pause();
    }

    function unpause() public whenPaused {
        require(
            hasRole(STRATEGIST_ROLE, msg.sender),
            "iCOMP : Unauthorized!"
        );
        _unpause();
    }

        function _transferOwnership(address newStrategist) public {
          require(newStrategist != address(0),'Transfer to address 0!');
          require(
            hasRole(STRATEGIST_ROLE, msg.sender),
            "iCOMP : Unauthorized!"
        );
       
         address _oldStrategist = strategist;
         _setupRole(STRATEGIST_ROLE, newStrategist);
         revokeRole(STRATEGIST_ROLE, strategist); 
         strategist = payable(newStrategist);

          emit VaultOwnershipTransferred(_oldStrategist, newStrategist);
    }
}

// IKEY.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC721EnumerableUpgradeable.sol";

interface IKEY is IERC721EnumerableUpgradeable{

    function tokenTier(uint256 id) external view returns(uint256);

    function pause() external;
    
    function unpause() external;

    function _transferOwnership(address newStrategist) external;

    function _create(string memory _tokenHash, address _to, uint256 _tier, bool _transferable) external;
 }

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface Comptroller {

    function enterMarkets(address[] calldata) external returns (uint256[] memory);

    function exitMarket(address cToken) external returns (uint);

    function claimComp(address holder, address[] calldata) external;

    function getAssetsIn(address account) external view returns (address[] memory);

    function markets(address cTokenAddress) external view returns (bool, uint, bool);

    function getAccountLiquidity(address account) external view returns (uint, uint, uint);

    function liquidationIncentiveMantissa() external view returns (uint);

    function closeFactorMantissa() external returns (uint);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface CErc20 {
    function mint(uint256 mintAmount) external returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external;

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);

    function exchangeRateStored() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint);

    function borrowBalanceStored(address account) external view returns (uint);

    function underlying() external view returns (address);

    function getCash() external view returns (uint);

    function supplyRatePerBlock() external view returns (uint);

    function borrowRatePerBlock() external view returns (uint);

    function totalBorrowsCurrent() external view returns (uint);

    function totalSupply() external view returns (uint);

    function decimals() external view returns (uint);

    function totalReserves() external view returns (uint);

    function exchangeRateCurrent() external ;

    function balanceOfUnderlying(address account) external view returns (uint);

    function liquidateBorrow(address borrower, uint amount, address collateral) external returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface CEther {
    
    function balanceOf(address owner) external view returns (uint);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external;

    function mint() external payable;

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);

    function exchangeRateStored() external view returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint);

    function borrow(uint borrowAmount) external returns (uint);

    function repayBorrow() external payable;

    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);

    function getCash() external view returns (uint);

    function supplyRatePerBlock() external view returns (uint);

    function borrowRatePerBlock() external view returns (uint);

    function totalBorrowsCurrent() external view returns (uint);

    function totalSupply() external view returns (uint);

    function totalReserves() external view returns (uint);

    function decimals() external view returns (uint);

    function exchangeRateCurrent() external;

    function balanceOfUnderlying(address account) external view returns (uint);

    function liquidateBorrow(address borrower, uint amount, address collateral) external returns (uint);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}