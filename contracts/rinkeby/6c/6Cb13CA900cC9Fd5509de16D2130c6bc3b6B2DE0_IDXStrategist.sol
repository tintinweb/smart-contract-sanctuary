// contracts/IDXStrategist.sol
// SPDX-License-Identifier: MIT
// non-upgradeable

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interface/compound/CErc20.sol";
import "./interface/compound/CEther.sol";
import "./interface/compound/Comptroller.sol";
import "./vaults/CompoundVault.sol";

/**

IDX Digital Labs Strategist Smart Contract

Author: Ian Decentralize

  - CREATE VAULT
  - UPDATE VAULT FEES
  - BORROW FROM A VAULT 
  - REPAY ON BEHALF OF A VAULT
  - LIQUIDATE A POSITION

*/

contract IDXStrategist

{
    using SafeERC20 for IERC20;
  

    CErc20 cCOMP;
    IERC20 COMP;

    address public STRATEGIST;
    uint256 public vaultCount;

    mapping(address => uint256) public vaultsIds;
    mapping(uint256 => COMPVault) public vaults;

    COMPVault vaultRegistry;
    mapping(address => address) public cTokenAddr;
    mapping(address => mapping(address => uint256)) avgIdx;

    struct  COMPVault {
        uint256 id;
        uint256 fees;
        CompoundVault logic;
        address asset;
        address collateral;
    }


    event VaultCreated(uint256 id, address logic, address asset);

     modifier onlyStrategist() {
        require(msg.sender == STRATEGIST);
        _;
    }

    constructor(address startegist) {
        STRATEGIST = payable(startegist);
        COMP = IERC20(0x61460874a7196d6a22D1eE4922473664b3E95270);
        cCOMP = CErc20(0x70e36f6BF80a52b3B46b3aF8e106CC0ed743E8e4);
    }

    /// @notice Create and Deploy a new vault
    /// @dev Will add a contract vault to the vaults

    /// @param cToken collaterall token
    /// @param asset native asset
    /// @param fees vault fees
  
    function createVault(
        address cToken,
        address asset,
        uint256 fees
    ) public 
      onlyStrategist
     {
      
        COMPVault storage vault = vaults[vaultCount];
        vault.id = vaultCount;
        vault.fees = fees;
        vault.collateral = cToken;
        vault.asset = asset;

        vault.logic = new CompoundVault( 
            address(this),
            cToken,
            asset,
            fees
            );
  
        vaultsIds[address(vault.logic)] = vaultCount;
        vaultCount += 1;
        emit VaultCreated(vault.id, address(vault.logic), address(asset));
    }

    /// @notice Enter and exit Market con Com Vault
    /// @dev Borrowing from a vault increase it's yield in Comp

    function enterVaultMarket(address _vault, address cAsset) public onlyStrategist {
        COMPVault memory vault = vaults[vaultsIds[_vault]];
        vault.logic._enterCompMarket(cAsset);
    }

    function exitCompMarket(address _vault, address cAsset) public onlyStrategist {
        COMPVault memory vault = vaults[vaultsIds[_vault]];
        vault.logic._exitCompMarket(cAsset);
    }

    /// @notice Get Vault Return
    /// @dev Borrowing from a vault increase it's yield in Comp
    /// @param fromVault vault we borrow from
    /// @param asset asset to repay / must not be farming asset
    /// @param amount to repay
    /// @dev the funds must be in this contract

    function _VaultSwap(
        address fromVault,
        address asset,
        address cToken,
        uint256 amount
    ) public onlyStrategist returns(bool){
        COMPVault memory vaultOut = vaults[vaultsIds[fromVault]];
        uint256 returnedAmount = vaultOut.logic._borrowComp(amount, cToken, asset);
        require(returnedAmount == amount, 'iStrategist : Borrow failed!');
        return true;
    }

    /// @notice REPAY IN A VAULT
    /// @dev The funds must be in this contract
    /// @param vaultAddress address of the vault
    /// @param cAsset asset to repay
    /// @param asset asset to repay
    /// @param amount to repay
    /// @dev the funds must be in this contract

    function _RepayCompVaultValue(
        address vaultAddress,
        address cAsset,
        address asset,
        uint256 amount
    ) public onlyStrategist {
        COMPVault memory vault = vaults[vaultsIds[vaultAddress]];
        IERC20 _asset = IERC20(asset);
        CErc20 _cAsset = CErc20(cAsset);
        _asset.safeApprove(address(_cAsset), amount);
        require(
            _cAsset.repayBorrowBehalf(address(vault.logic), amount) == 0,
            "iStrategist : Repay failed!"
        );
    }

    /// @notice Liquidate an account on Compound.
    /// @dev fees are already deducted on the share value based on earning
    /// @param _borrower address of the Borrower
    /// @param _amount to be repayed
    /// @param _collateral the asset to be received
    /// @param _repayed the contract to be repayed (cToken)
    /// @return value the amount transfered to this contract

     function liquidateBorrow(address _borrower, uint _amount, address _collateral, address _repayed) 
        public
        onlyStrategist
        returns (uint256)
    {   
        CErc20 repayedAsset = CErc20(_repayed);
        repayedAsset.approve(address(repayedAsset), _amount); 
        return  repayedAsset.liquidateBorrow(_borrower, _amount, _collateral);
        
    }

    /// @notice Redeem and Withdraw fees.
    /// @dev fees are already deducted on the share value based on earning
    /// @param _vaultAddress address of the vault

    function collectFees(address _vaultAddress)
        public
        onlyStrategist 
    {
        COMPVault memory vault = vaults[vaultsIds[_vaultAddress]];
        vault.logic.getFees();
        
    }




    /// @notice Pause and unPause a vault.
    /// @dev Will pause the vault preventing any transfer
    /// @param _vaultAddress address of the vault

    function pauseVault(address _vaultAddress)
        public
        onlyStrategist 
    {
        COMPVault memory vault = vaults[vaultsIds[_vaultAddress]];
        vault.logic.pause();
        
    }
        function unPauseVault(address _vaultAddress)
        public
        onlyStrategist 
    {
        COMPVault memory vault = vaults[vaultsIds[_vaultAddress]];
        vault.logic.unpause();
        
    }





     /// @notice Withdraw fees.
    function withdrawERC20Fees(address _asset) public onlyStrategist {
           IERC20 asset = IERC20(_asset);
           asset.transfer(msg.sender,asset.balanceOf(address(this)));
    }

    function withdrawETHFees() public onlyStrategist {
          payable(msg.sender).transfer(address(this).balance);
    }

    function transferOwnership(address newStrategist) public onlyStrategist {
         STRATEGIST = payable(newStrategist);
    }

    function isStrategist() public view returns (bool){
        if(msg.sender == STRATEGIST){
            return true;
        }else{
            return false;
        }
    }

    /// @notice THIS VAULT ACCEPT ETHER
    receive() external payable {
        // nothing to do
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

interface CErc20 {
    function mint(uint256 mintAmount) external returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);

    function exchangeRateStored() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);

    function borrowBalanceCurrent(address account) external view returns (uint);

    function underlying() external view returns (address);

    function getCash() external view returns (uint);

    function supplyRatePerBlock() external view returns (uint);

    function borrowRatePerBlock() external view returns (uint);

    function totalBorrowsCurrent() external view returns (uint);

    function totalSupply() external view returns (uint);

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

    function exchangeRateCurrent() external;

    function balanceOfUnderlying(address account) external view returns (uint);

    function liquidateBorrow(address borrower, uint amount, address collateral) external returns (uint);

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

// CompoundVault.sol
// SPDX-License-Identifier: MIT
// non-upgradeable

/**
        IDX Digital Labs Earning Protocol.
        Author: Ian Decentralize
        This contract is farming the Compound Protocol
 */

pragma solidity ^0.8.0;

import "../interface/compound/Comptroller.sol";
import "../interface/compound/CErc20.sol";
import "../interface/compound/CEther.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract CompoundVault is
    Pausable,
    AccessControl
{
    using SafeERC20 for IERC20;

    address ETHER = address(0);
  
    address public strategist;
    address public collateral;
    address public farming;
    uint256 fees;
    uint256 constant feeBase = 10000;

    mapping(address => uint256) public shares;                  
    mapping(address => uint256) public collaterals;             


    bytes32 STRATEGIST_ROLE = keccak256("STRATEGIST_ROLE");

    // MainNet
    // address COMP = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
    // Comptroller comptroller = Comptroller(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);

    // Rinkeby
    address COMP = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
    Comptroller comptroller = Comptroller(0x2EAa9D77AE4D8f9cdD9FAAcd44016E746485bddb);

    event Mint(address asset, uint256 amount);
    event Redeem(address asset, uint256 amount);
    event CompoundClaimed(address caller, uint256 amount);
    event Borrowed(address asset, uint256 amount);

    /// @dev Constructor
    /// @param _strategist address of the strategist contract.
    /// @param _compoundedAsset adress of the cToken contract (collateral).
    /// @param _underlyingAsset address of the asset to farm.
    /// @param _protocolFees fees in base 3 200 = 2%

    constructor(
        address _strategist,
        address _compoundedAsset,
        address _underlyingAsset,
        uint256 _protocolFees
    ) {
        _setupRole(STRATEGIST_ROLE, _strategist);
        fees = _protocolFees;
        collateral = _compoundedAsset;
        farming = _underlyingAsset;
        _enterCompMarket(_compoundedAsset);
    }

    /// @notice Mint idxComp.
    /// @dev Must be approved
    /// @param _amount The amount to deposit that must be approved in farming asset
    /// @return returnedCollateral the amount minted

    function mint(uint256 _amount)
        public
        payable
        whenNotPaused
        returns (uint256 returnedCollateral)
    {
        IERC20 asset = IERC20(farming);
       
        
        if (farming == ETHER) {
            require(msg.value > 0, "iCOMP : Zero Ether!");
            returnedCollateral = buyETHPosition(msg.value);
            shares[msg.sender] += msg.value;
        } else if (farming != ETHER) {
            require(_amount > 0, "iCOMP : Zero Amount!");
            require(
                asset.allowance(msg.sender, address(this)) >= _amount,
                "iCOMP : Insuficient allowance!"
            );
            require(
                asset.transferFrom(msg.sender, address(this), _amount),
                "iCOMP : Transfer failled!"
            );
            returnedCollateral = buyERC20Position(_amount);
            shares[msg.sender] += _amount;
        }

        collaterals[msg.sender] += returnedCollateral;
        
        emit Mint(farming, _amount);

        return returnedCollateral;
    }

    /// @notice Redeem your investement
    /// @dev require approval
    /// @param _amount the amount in native asset
    function redeem(uint256 _amount) external whenNotPaused returns (uint256 transferedAmount) {
        require(_amount > 0, "iCOMP : Zero Amount!");
          
          if(farming == ETHER){
                CEther(collateral).exchangeRateCurrent();
          }else{
                CErc20(collateral).exchangeRateCurrent();
          }
            
        uint256[] memory receipt = _vaultComputation(_amount);
        require(receipt[0] != 1, "iCOMP : Overflow");
        require(
            collaterals[msg.sender] >= (receipt[1] + receipt[2]),
            "iCOMP : Insufucient collaterals!"
        );
        if(receipt[1] > 0){
           collaterals[strategist] += receipt[1];
        }
        collaterals[msg.sender] -= (receipt[1] + receipt[2]) ;
        
        if (farming == ETHER) {
            transferedAmount = sellETHPosition(receipt[2]);
            payable(msg.sender).transfer(transferedAmount);
        } else if (farming != ETHER) {
            IERC20 asset = IERC20(farming);
            transferedAmount = sellERC20Position(receipt[2]);
            asset.transfer(msg.sender, transferedAmount);
        }
          if(transferedAmount >= shares[msg.sender]) {
              shares[msg.sender] = 0;
          }
          else{
              shares[msg.sender] -= transferedAmount;
          }

        emit Redeem(farming, transferedAmount);

        return transferedAmount;
    }

    /// @notice BUY ERC20 Position
    /// @dev buy a position
    /// @param _amount the amount to deposit in IDXVault
    /// @return returnedAmount in collateral shares

    function buyERC20Position(uint256 _amount)
        internal
        whenNotPaused
        returns (uint256 returnedAmount)
    {
        CErc20 cToken = CErc20(collateral);
        IERC20 asset = IERC20(farming);
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
        IERC20 asset = IERC20(farming);
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

    function _vaultComputation(uint256 _amount)
        public
        view
        returns (uint256[] memory)
    {

        uint256[] memory txData = new uint256[](4);
        uint256 rate;

        if(farming == ETHER){
            CEther token = CEther(collateral);
            rate = token.exchangeRateStored();

        }else{
           CErc20 token = CErc20(collateral);
           rate = token.exchangeRateStored();

        }
        
        uint256 underlyingMax = (rate * collaterals[msg.sender]) / 1e18;

        // if we have the available funds
        if (underlyingMax >= _amount) {
            // if the amount is not exceeding what is available

            uint256 gainQuotient = quotient(
                underlyingMax,
                shares[msg.sender],
                18
            );
            uint256 amountWithdraw = _getCollateralAmount(
                (gainQuotient * _amount) / 1e18
            );
            uint256 deductedFees = _getCollateralAmount(
                ((((gainQuotient * _amount) / 1e18) - _amount) / feeBase) * fees
            );
            uint256 shareConsumed = (rate * (amountWithdraw + deductedFees)) /
                1e18;

            if (amountWithdraw + deductedFees <= collaterals[msg.sender]) {

                txData[0] = 0; // 0 error
                txData[1] = deductedFees; // the fees in collateral
                txData[2] = amountWithdraw; // the collateral amount redeeam/burned must remove fee but not burn
                txData[3] = shareConsumed;
            } else if (amountWithdraw + deductedFees > collaterals[msg.sender]) {
                // we take the maxAvailable
                gainQuotient = quotient(underlyingMax, shares[msg.sender], 18); // must be very low
                amountWithdraw = _getCollateralAmount(
                    (gainQuotient * shares[msg.sender]) / 1e18
                );

                deductedFees = collaterals[msg.sender] - amountWithdraw; 
                shareConsumed = (rate * collaterals[msg.sender]) / 1e18;

                txData[0] = 2;
                txData[1] = deductedFees;
                txData[2] = amountWithdraw;
                txData[3] = shareConsumed;
            }
        }
        else {
            
            txData[0] = 1; // error = 1 
            
        }

        return txData;
    }


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
    /// @dev
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
    /// @dev
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


    /// @notice Comp Shares Distribution
    /// @dev

    function claimComp(address cToken) public whenNotPaused returns (uint256 amountClaimed) {

        address[] memory cTokens = new address[](1);
        cTokens[0] = cToken;
        IERC20 Comp = IERC20(COMP);
        comptroller.claimComp(address(this), cTokens);
        amountClaimed = Comp.balanceOf(address(this));
        Comp.transfer(strategist, amountClaimed);
        emit CompoundClaimed(msg.sender, amountClaimed);
        return amountClaimed; 
    }


    /// @notice ENTER COMPOUND MARKET
    /// @param cAsset The cToken we want to interact with on Compound 
    /// @dev Exiting market for unused asset will lower the TX cost with Compound

    function _enterCompMarket(address cAsset) public {
        require(hasRole(STRATEGIST_ROLE, msg.sender), "iCOMP : Unauthorized?");
        address[] memory cTokens = new address[](1);
        cTokens[0] = cAsset;
        uint256[] memory errors = comptroller.enterMarkets(cTokens);
        require(errors[0] == 0, "iCOMP : Market Fail");
    }

    /// @notice EXIT COMPOUND MARKET.
    /// @param cAsset The asset we want to remove (cToken)
    /// @dev Exiting market for unused asset will lower the TX cost with Compound

    function _exitCompMarket(address cAsset) public {
        require(hasRole(STRATEGIST_ROLE, msg.sender), "iCOMP : Unauthorized?");
        uint256 errors = comptroller.exitMarket(cAsset);
        require(errors == 0, "Exit CMarket?");
    }

    /// @notice BORROW ON COMPOUND.
    /// @param amount the amount to borrow
    /// @param cAsset the asset to borrow
    /// @param asset the native asset
    /// @dev funds are sent to strategist. The startegist can use the repayOnBehalf of this vault.

    function _borrowComp(
        uint256 amount,
        address cAsset,
        address asset
    ) external whenNotPaused returns (uint256 borrowed) {
        require(hasRole(STRATEGIST_ROLE, msg.sender), "iCOMP : Unauthorized?");
        IERC20 token = IERC20(asset);
        uint256 balanceBefore = token.balanceOf(address(this));
        if(farming == ETHER){
            CEther cToken = CEther(cAsset);
            require(cToken.borrow(amount) == 0, "got collateral?");
        }else{
            CErc20 cToken = CErc20(cAsset);
            require(cToken.borrow(amount) == 0, "got collateral?");
        }
        uint256 balanceAfter = token.balanceOf(address(this));
        borrowed = balanceAfter - balanceBefore;
        token.transfer(strategist, borrowed);
        emit Borrowed(asset, amount);
        return borrowed;
    }

    /// @notice SET VAULT FEES.
    /// @param _fees the fees in %
    /// @dev base3 where  200 = 2%

    function setFees(uint256 _fees) external {
        require(hasRole(STRATEGIST_ROLE, msg.sender), "iCOMP : Unauthorized?");
        fees = _fees;
    }

    /// @notice Strategist fees.
  
    function getFees() external {
        require(hasRole(STRATEGIST_ROLE, msg.sender), "iCOMP : Unauthorized?");
         uint256 feeCollected;
        if(farming == ETHER){
            CEther cToken = CEther(collateral);
            cToken.approve(address(cToken), collaterals[strategist]);
            feeCollected = sellETHPosition(collaterals[strategist]);
            payable(strategist).transfer(feeCollected);

        }else{
              IERC20 asset = IERC20(farming);
              CErc20 cToken = CErc20(collateral);  
              cToken.approve(address(cToken), collaterals[strategist]);  
              sellERC20Position(collaterals[strategist]);
              feeCollected = sellERC20Position(collaterals[strategist]);
              asset.transfer(strategist, feeCollected);
        }       
        collaterals[strategist] = 0;
    }

    /// @notice THIS VAULT ACCEPT ETHER
    receive() external payable {
        // nothing to do
    }

    /// @notice SECURITY.

    /// @notice pause or unpause.
    /// @dev Security feature to use with Defender for vault monitoring

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

        function transferOwnership(address newStrategist) public {
        
          require(
            hasRole(STRATEGIST_ROLE, msg.sender),
            "iCOMP : Unauthorized!"
        );

         _setupRole(STRATEGIST_ROLE, newStrategist);
         revokeRole(STRATEGIST_ROLE, strategist); 
         strategist = payable(newStrategist);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
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
    function grantRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to revoke");

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
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor () {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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
interface IERC165 {
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

