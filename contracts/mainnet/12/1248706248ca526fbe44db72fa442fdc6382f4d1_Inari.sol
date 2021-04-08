/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

/// SPDX-License-Identifier: MIT
/*
▄▄█    ▄   ██   █▄▄▄▄ ▄█ 
██     █  █ █  █  ▄▀ ██ 
██ ██   █ █▄▄█ █▀▀▌  ██ 
▐█ █ █  █ █  █ █  █  ▐█ 
 ▐ █  █ █    █   █    ▐ 
   █   ██   █   ▀   
           ▀          */
/// Special thanks to Keno and Boring for reviewing early bridge patterns.
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/// @notice Interface for depositing into and withdrawing from SushiBar.
interface ISushiBarBridge { 
    function enter(uint256 amount) external;
    function leave(uint256 share) external;
}

/// @notice Interface for depositing into and withdrawing from Aave lending pool.
interface IAaveBridge {
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);

    function deposit( 
        address asset, 
        uint256 amount, 
        address onBehalfOf, 
        uint16 referralCode
    ) external;

    function withdraw( 
        address token, 
        uint256 amount, 
        address destination
    ) external;
}

/// @notice Interface for depositing into and withdrawing from BentoBox vault.
interface IBentoBridge {
    function registerProtocol() external;

    function deposit( 
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    function withdraw(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);
}

/// @notice Interface for depositing into and withdrawing from Compound finance protocol.
interface ICompoundBridge {
    function underlying() external view returns (address);
    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
}

/// @notice Interface for Dai Stablecoin (DAI) `permit()` primitive.
interface IDaiPermit {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// File @boringcrypto/boring-solidity/contracts/interfaces/[email protected]
/// License-Identifier: MIT

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// File @boringcrypto/boring-solidity/contracts/libraries/[email protected]
/// License-Identifier: MIT

library BoringERC20 {
    bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
    bytes4 private constant SIG_NAME = 0x06fdde03; // name()
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
    bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
    bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

    /// @notice Provides a safe ERC20.transfer version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
    }

    /// @notice Provides a safe ERC20.transferFrom version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param from Transfer tokens from.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
    }
}

// File @boringcrypto/boring-solidity/contracts/[email protected]
/// License-Identifier: MIT

contract BaseBoringBatchable {
    /// @dev Helper function to extract a useful revert message from a failed call.
    /// If the returned data is malformed or not correctly abi encoded then this call can fail itself.
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    /// @notice Allows batched call to self (this contract).
    /// @param calls An array of inputs for each call.
    /// @param revertOnFail If True then reverts after a failed call and stops doing further calls.
    /// @return successes An array indicating the success of a call, mapped one-to-one to `calls`.
    /// @return results An array with the returned data of each function call, mapped one-to-one to `calls`.
    // F1: External is ok here because this is the batch function, adding it to a batch makes no sense
    // F2: Calls in the batch may be payable, delegatecall operates in the same context, so each call in the batch has access to msg.value
    // C3: The length of the loop is fully under user control, so can't be exploited
    // C7: Delegatecall is only used on the same contract, so it's safe
    function batch(bytes[] calldata calls, bool revertOnFail) external payable returns (bool[] memory successes, bytes[] memory results) {
        successes = new bool[](calls.length);
        results = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            require(success || !revertOnFail, _getRevertMsg(result));
            successes[i] = success;
            results[i] = result;
        }
    }
}

contract BoringBatchable is BaseBoringBatchable {
    /// @notice Call wrapper that performs `ERC20.permit` on `token`.
    /// Lookup `IERC20.permit`.
    // F6: Parameters can be used front-run the permit and the user's permit will fail (due to nonce or other revert)
    //     if part of a batch this could be used to grief once as the second call would not need the permit
    function permitToken(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        token.permit(from, to, amount, deadline, v, r, s);
    }
}

/// @notice Contract that batches SUSHI staking and DeFi strategies.
contract Inari is BoringBatchable {
    using BoringERC20 for IERC20;
    
    IERC20 constant sushiToken = IERC20(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2); // SUSHI token contract
    address constant sushiBar = 0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272; // xSUSHI staking contract for SUSHI
    IAaveBridge constant aave = IAaveBridge(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9); // AAVE lending pool contract for xSUSHI staking into aXSUSHI
    IERC20 constant aaveSushiToken = IERC20(0xF256CC7847E919FAc9B808cC216cAc87CCF2f47a); // aXSUSHI staking contract for xSUSHI
    IBentoBridge constant bento = IBentoBridge(0xF5BCE5077908a1b7370B9ae04AdC565EBd643966); // BENTO vault contract
    address constant crSushiToken = 0x338286C0BC081891A4Bda39C7667ae150bf5D206; // crSUSHI staking contract for SUSHI
    address constant crXSushiToken = 0x228619CCa194Fbe3Ebeb2f835eC1eA5080DaFbb2; // crXSUSHI staking contract for xSUSHI
    address constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // DAI token contract
    
    /// @notice Initialize this Inari contract and core SUSHI strategies.
    constructor() public {
        bento.registerProtocol(); // register this contract with BENTO
        sushiToken.approve(address(sushiBar), type(uint256).max); // max approve `sushiBar` spender to stake SUSHI into xSUSHI from this contract
        sushiToken.approve(crSushiToken, type(uint256).max); // max approve `crSushiToken` spender to stake SUSHI into crSUSHI from this contract
        IERC20(sushiBar).approve(address(aave), type(uint256).max); // max approve `aave` spender to stake xSUSHI into aXSUSHI from this contract
        IERC20(sushiBar).approve(address(bento), type(uint256).max); // max approve `bento` spender to stake xSUSHI into BENTO from this contract
        IERC20(sushiBar).approve(crXSushiToken, type(uint256).max); // max approve `crXSushiToken` spender to stake xSUSHI into crXSUSHI from this contract
        IERC20(dai).approve(address(bento), type(uint256).max); // max approve `bento` spender to pull DAI into BENTO from this contract
    }
    
    /// @notice Helper function to approve this contract to spend and bridge more tokens among DeFi contracts.
    function approveTokenBridge(IERC20[] calldata underlying, address[] calldata cToken) external {
        for (uint256 i = 0; i < underlying.length; i++) {
            underlying[i].approve(address(aave), type(uint256).max); // max approve `aave` spender to pull `underlying` from this contract
            underlying[i].approve(address(bento), type(uint256).max); // max approve `bento` spender to pull `underlying` from this contract
            underlying[i].approve(cToken[i], type(uint256).max); // max approve `cToken` spender to pull `underlying` from this contract
        }
    }
/*
██   ██       ▄   ▄███▄   
█ █  █ █       █  █▀   ▀  
█▄▄█ █▄▄█ █     █ ██▄▄    
█  █ █  █  █    █ █▄   ▄▀ 
   █    █   █  █  ▀███▀   
  █    █     █▐           
 ▀    ▀      ▐         */
    /**************************
    AAVE -> UNDERLYING -> BENTO 
    **************************/
    /// @notice Migrate AAVE `aToken` underlying `amount` into BENTO by batching calls to `aave` and `bento`.
    function aaveToBento(address aToken, uint256 amount) external {
        IERC20(aToken).safeTransferFrom(msg.sender, address(this), amount); // deposit `msg.sender` `aToken` `amount` into this contract
        address underlying = IAaveBridge(aToken).UNDERLYING_ASSET_ADDRESS(); // sanity check for `underlying` token
        aave.withdraw(underlying, amount, address(this)); // burn deposited `aToken` from `aave` into `underlying`
        bento.deposit(IERC20(underlying), address(this), msg.sender, amount, 0); // stake `underlying` into BENTO for `msg.sender`
    }
    
    /// @notice Migrate AAVE `aToken` underlying `amount` into BENTO for benefit of `to` by batching calls to `aave` and `bento`.
    function aaveToBentoTo(address aToken, address to, uint256 amount) external {
        IERC20(aToken).safeTransferFrom(msg.sender, address(this), amount); // deposit `msg.sender` `aToken` `amount` into this contract
        address underlying = IAaveBridge(aToken).UNDERLYING_ASSET_ADDRESS(); // sanity check for `underlying` token
        aave.withdraw(underlying, amount, address(this)); // burn deposited `aToken` from `aave` into `underlying`
        bento.deposit(IERC20(underlying), address(this), to, amount, 0); // stake `underlying` into BENTO for `to`
    }
    
    /**************************
    BENTO -> UNDERLYING -> AAVE 
    **************************/
    /// @notice Migrate `underlying` `amount` from BENTO into AAVE by batching calls to `bento` and `aave`.
    function bentoToAave(IERC20 underlying, uint256 amount) external {
        bento.withdraw(underlying, msg.sender, address(this), amount, 0); // withdraw `amount` of `underlying` from BENTO into this contract
        aave.deposit(address(underlying), amount, msg.sender, 0); // stake `underlying` into `aave` for `msg.sender`
    }
    
    /// @notice Migrate `underlying` `amount` from BENTO into AAVE for benefit of `to` by batching calls to `bento` and `aave`.
    function bentoToAaveTo(IERC20 underlying, address to, uint256 amount) external {
        bento.withdraw(underlying, msg.sender, address(this), amount, 0); // withdraw `amount` of `underlying` from BENTO into this contract
        aave.deposit(address(underlying), amount, to, 0); // stake `underlying` into `aave` for `to`
    }
    
    /**********************
    SUSHI -> XSUSHI -> AAVE 
    **********************/
    /// @notice Stake SUSHI `amount` into aXSUSHI by batching calls to `sushiBar` and `aave`.
    function stakeSushiToAave(uint256 amount) external {
        sushiToken.safeTransferFrom(msg.sender, address(this), amount); // deposit `msg.sender` SUSHI `amount` into this contract
        ISushiBarBridge(sushiBar).enter(amount); // stake deposited SUSHI into `sushiBar` xSUSHI
        aave.deposit(sushiBar, IERC20(sushiBar).balanceOf(address(this)), msg.sender, 0); // stake resulting xSUSHI into `aave` aXSUSHI for `msg.sender`
    }
    
    /// @notice Stake SUSHI `amount` into aXSUSHI for benefit of `to` by batching calls to `sushiBar` and `aave`.
    function stakeSushiToAaveTo(address to, uint256 amount) external {
        sushiToken.safeTransferFrom(msg.sender, address(this), amount); // deposit `msg.sender` SUSHI `amount` into this contract
        ISushiBarBridge(sushiBar).enter(amount); // stake deposited SUSHI into `sushiBar` xSUSHI
        aave.deposit(sushiBar, IERC20(sushiBar).balanceOf(address(this)), to, 0); // stake resulting xSUSHI into `aave` aXSUSHI for `to`
    }
    
    /**********************
    AAVE -> XSUSHI -> SUSHI 
    **********************/
    /// @notice Unstake aXSUSHI `amount` into SUSHI by batching calls to `aave` and `sushiBar`.
    function unstakeSushiFromAave(uint256 amount) external {
        aaveSushiToken.safeTransferFrom(msg.sender, address(this), amount); // deposit `msg.sender` aXSUSHI `amount` into this contract
        aave.withdraw(sushiBar, amount, address(this)); // burn deposited aXSUSHI from `aave` into xSUSHI
        ISushiBarBridge(sushiBar).leave(amount); // burn resulting xSUSHI from `sushiBar` into SUSHI
        sushiToken.safeTransfer(msg.sender, sushiToken.balanceOf(address(this))); // transfer resulting SUSHI to `msg.sender`
    }
    
    /// @notice Unstake aXSUSHI `amount` into SUSHI for benefit of `to` by batching calls to `aave` and `sushiBar`.
    function unstakeSushiFromAaveTo(address to, uint256 amount) external {
        aaveSushiToken.safeTransferFrom(msg.sender, address(this), amount); // deposit `msg.sender` aXSUSHI `amount` into this contract
        aave.withdraw(sushiBar, amount, address(this)); // burn deposited aXSUSHI from `aave` into xSUSHI
        ISushiBarBridge(sushiBar).leave(amount); // burn resulting xSUSHI from `sushiBar` into SUSHI
        sushiToken.safeTransfer(to, sushiToken.balanceOf(address(this))); // transfer resulting SUSHI to `to`
    }
/*
███   ▄███▄      ▄     ▄▄▄▄▀ ████▄ 
█  █  █▀   ▀      █ ▀▀▀ █    █   █ 
█ ▀ ▄ ██▄▄    ██   █    █    █   █ 
█  ▄▀ █▄   ▄▀ █ █  █   █     ▀████ 
███   ▀███▀   █  █ █  ▀            
              █   ██            */ 
    /// @notice Helper function to `permit()` this contract to deposit `dai` into `bento`.
    function daiToBentoWithPermit(
        uint256 amount, uint256 nonce, uint256 deadline,
        uint8 v, bytes32 r, bytes32 s
    ) external {
        IDaiPermit(dai).permit(msg.sender, address(this), nonce, deadline, true, v, r, s); // `permit()` this contract to spend `msg.sender` `dai` `amount`
        IERC20(dai).safeTransferFrom(msg.sender, address(this), amount); // pull `dai` `amount` into this contract
        bento.deposit(IERC20(dai), address(this), msg.sender, amount, 0); // stake `dai` into BENTO for `msg.sender`
    }

    /***********************
    SUSHI -> XSUSHI -> BENTO 
    ***********************/
    /// @notice Stake SUSHI `amount` into BENTO xSUSHI by batching calls to `sushiBar` and `bento`.
    function stakeSushiToBento(uint256 amount) external {
        sushiToken.safeTransferFrom(msg.sender, address(this), amount); // deposit `msg.sender` SUSHI `amount` into this contract
        ISushiBarBridge(sushiBar).enter(amount); // stake deposited SUSHI into `sushiBar` xSUSHI
        bento.deposit(IERC20(sushiBar), address(this), msg.sender, IERC20(sushiBar).balanceOf(address(this)), 0); // stake resulting xSUSHI into BENTO for `msg.sender`
    }
    
    /// @notice Stake SUSHI `amount` into BENTO xSUSHI for benefit of `to` by batching calls to `sushiBar` and `bento`.
    function stakeSushiToBentoTo(address to, uint256 amount) external {
        sushiToken.safeTransferFrom(msg.sender, address(this), amount); // deposit `msg.sender` SUSHI `amount` into this contract
        ISushiBarBridge(sushiBar).enter(amount); // stake deposited SUSHI into `sushiBar` xSUSHI
        bento.deposit(IERC20(sushiBar), address(this), to, IERC20(sushiBar).balanceOf(address(this)), 0); // stake resulting xSUSHI into BENTO for `to`
    }
    
    /***********************
    BENTO -> XSUSHI -> SUSHI 
    ***********************/
    /// @notice Unstake xSUSHI `amount` from BENTO into SUSHI by batching calls to `bento` and `sushiBar`.
    function unstakeSushiFromBento(uint256 amount) external {
        bento.withdraw(IERC20(sushiBar), msg.sender, address(this), amount, 0); // withdraw `amount` of xSUSHI from BENTO into this contract
        ISushiBarBridge(sushiBar).leave(amount); // burn withdrawn xSUSHI from `sushiBar` into SUSHI
        sushiToken.safeTransfer(msg.sender, sushiToken.balanceOf(address(this))); // transfer resulting SUSHI to `msg.sender`
    }
    
    /// @notice Unstake xSUSHI `amount` from BENTO into SUSHI for benefit of `to` by batching calls to `bento` and `sushiBar`.
    function unstakeSushiFromBentoTo(address to, uint256 amount) external {
        bento.withdraw(IERC20(sushiBar), msg.sender, address(this), amount, 0); // withdraw `amount` of xSUSHI from BENTO into this contract
        ISushiBarBridge(sushiBar).leave(amount); // burn withdrawn xSUSHI from `sushiBar` into SUSHI
        sushiToken.safeTransfer(to, sushiToken.balanceOf(address(this))); // transfer resulting SUSHI to `to`
    }
/*    
▄█▄    █▄▄▄▄ ▄███▄   ██   █▀▄▀█ 
█▀ ▀▄  █  ▄▀ █▀   ▀  █ █  █ █ █ 
█   ▀  █▀▀▌  ██▄▄    █▄▄█ █ ▄ █ 
█▄  ▄▀ █  █  █▄   ▄▀ █  █ █   █ 
▀███▀    █   ▀███▀      █    █  
        ▀              █    ▀  
                      ▀      */
// - COMPOUND - //
    /**************************
    COMP -> UNDERLYING -> BENTO 
    **************************/
    /// @notice Migrate COMP/CREAM `cToken` underlying `amount` into BENTO by batching calls to `cToken` and `bento`.
    function compoundToBento(address cToken, uint256 cTokenAmount) external {
        IERC20(cToken).safeTransferFrom(msg.sender, address(this), cTokenAmount); // deposit `msg.sender` `cToken` `cTokenAmount` into this contract
        ICompoundBridge(cToken).redeem(cTokenAmount); // burn deposited `cToken` into `underlying`
        IERC20 underlying = IERC20(ICompoundBridge(cToken).underlying()); // sanity check for `underlying` token
        bento.deposit(underlying, address(this), msg.sender, underlying.balanceOf(address(this)), 0); // stake resulting `underlying` into BENTO for `msg.sender`
    }
    
    /// @notice Migrate COMP/CREAM `cToken` underlying `amount` into BENTO for benefit of `to` by batching calls to `cToken` and `bento`.
    function compoundToBentoTo(address cToken, address to, uint256 cTokenAmount) external {
        IERC20(cToken).safeTransferFrom(msg.sender, address(this), cTokenAmount); // deposit `msg.sender` `cToken` `cTokenAmount` into this contract
        ICompoundBridge(cToken).redeem(cTokenAmount); // burn deposited `cToken` into `underlying`
        IERC20 underlying = IERC20(ICompoundBridge(cToken).underlying()); // sanity check for `underlying` token
        bento.deposit(underlying, address(this), to, underlying.balanceOf(address(this)), 0); // stake resulting `underlying` into BENTO for `to`
    }
    
    /**************************
    BENTO -> UNDERLYING -> COMP 
    **************************/
    /// @notice Migrate `cToken` `underlyingAmount` from BENTO into COMP/CREAM by batching calls to `bento` and `cToken`.
    function bentoToCompound(address cToken, uint256 underlyingAmount) external {
        IERC20 underlying = IERC20(ICompoundBridge(cToken).underlying()); // sanity check for `underlying` token
        bento.withdraw(underlying, msg.sender, address(this), underlyingAmount, 0); // withdraw `underlyingAmount` of `underlying` from BENTO into this contract
        ICompoundBridge(cToken).mint(underlyingAmount); // stake `underlying` into `cToken`
        IERC20(cToken).safeTransfer(msg.sender, IERC20(cToken).balanceOf(address(this))); // transfer resulting `cToken` to `msg.sender`
    }
    
    /// @notice Migrate `cToken` `underlyingAmount` from BENTO into COMP/CREAM for benefit of `to` by batching calls to `bento` and `cToken`.
    function bentoToCompoundTo(address cToken, address to, uint256 underlyingAmount) external {
        IERC20 underlying = IERC20(ICompoundBridge(cToken).underlying()); // sanity check for `underlying` token
        bento.withdraw(underlying, msg.sender, address(this), underlyingAmount, 0); // withdraw `underlyingAmount` of `underlying` from BENTO into this contract
        ICompoundBridge(cToken).mint(underlyingAmount); // stake `underlying` into `cToken`
        IERC20(cToken).safeTransfer(to, IERC20(cToken).balanceOf(address(this))); // transfer resulting `cToken` to `to`
    }
    
    /**********************
    SUSHI -> CREAM -> BENTO 
    **********************/
    /// @notice Stake SUSHI `amount` into crSUSHI and BENTO by batching calls to `crSushiToken` and `bento`.
    function sushiToCreamToBento(uint256 amount) external {
        sushiToken.safeTransferFrom(msg.sender, address(this), amount); // deposit `msg.sender` SUSHI `amount` into this contract
        ICompoundBridge(crSushiToken).mint(amount); // stake deposited SUSHI into crSUSHI
        bento.deposit(IERC20(crSushiToken), address(this), msg.sender, IERC20(crSushiToken).balanceOf(address(this)), 0); // stake resulting crSUSHI into BENTO for `msg.sender`
    }
    
    /// @notice Stake SUSHI `amount` into crSUSHI and BENTO for benefit of `to` by batching calls to `crSushiToken` and `bento`.
    function sushiToCreamToBentoTo(address to, uint256 amount) external {
        sushiToken.safeTransferFrom(msg.sender, address(this), amount); // deposit `msg.sender` SUSHI `amount` into this contract
        ICompoundBridge(crSushiToken).mint(amount); // stake deposited SUSHI into crSUSHI
        bento.deposit(IERC20(crSushiToken), address(this), to, IERC20(crSushiToken).balanceOf(address(this)), 0); // stake resulting crSUSHI into BENTO for `to`
    }
    
    /**********************
    BENTO -> CREAM -> SUSHI 
    **********************/
    /// @notice Unstake crSUSHI `amount` into SUSHI from BENTO by batching calls to `bento` and `crSushiToken`.
    function sushiFromCreamFromBento(uint256 amount) external {
        bento.withdraw(IERC20(crSushiToken), msg.sender, address(this), amount, 0); // withdraw `amount` of `crSushiToken` from BENTO into this contract
        ICompoundBridge(crSushiToken).redeem(amount); // burn deposited `crSushiToken` into SUSHI
        sushiToken.safeTransfer(msg.sender, sushiToken.balanceOf(address(this))); // transfer resulting SUSHI to `msg.sender`
    }
    
    /// @notice Unstake crSUSHI `amount` into SUSHI from BENTO for benefit of `to` by batching calls to `bento` and `crSushiToken`.
    function sushiFromCreamFromBentoTo(address to, uint256 amount) external {
        bento.withdraw(IERC20(crSushiToken), msg.sender, address(this), amount, 0); // withdraw `amount` of `crSushiToken` from BENTO into this contract
        ICompoundBridge(crSushiToken).redeem(amount); // burn deposited `crSushiToken` into SUSHI
        sushiToken.safeTransfer(to, sushiToken.balanceOf(address(this))); // transfer resulting SUSHI to `to`
    }
    
    /***********************
    SUSHI -> XSUSHI -> CREAM 
    ***********************/
    /// @notice Stake SUSHI `amount` into crXSUSHI by batching calls to `sushiBar` and `crXSushiToken`.
    function stakeSushiToCream(uint256 amount) external {
        sushiToken.safeTransferFrom(msg.sender, address(this), amount); // deposit `msg.sender` SUSHI `amount` into this contract
        ISushiBarBridge(sushiBar).enter(amount); // stake deposited SUSHI `amount` into `sushiBar` xSUSHI
        ICompoundBridge(crXSushiToken).mint(IERC20(sushiBar).balanceOf(address(this))); // stake resulting xSUSHI into crXSUSHI
        IERC20(crXSushiToken).safeTransfer(msg.sender, IERC20(crXSushiToken).balanceOf(address(this))); // transfer resulting crXSUSHI to `msg.sender`
    }
    
    /// @notice Stake SUSHI `amount` into crXSUSHI for benefit of `to` by batching calls to `sushiBar` and `crXSushiToken`.
    function stakeSushiToCreamTo(address to, uint256 amount) external {
        sushiToken.safeTransferFrom(msg.sender, address(this), amount); // deposit `msg.sender` SUSHI `amount` into this contract
        ISushiBarBridge(sushiBar).enter(amount); // stake deposited SUSHI `amount` into `sushiBar` xSUSHI
        ICompoundBridge(crXSushiToken).mint(IERC20(sushiBar).balanceOf(address(this))); // stake resulting xSUSHI into crXSUSHI
        IERC20(crXSushiToken).safeTransfer(to, IERC20(crXSushiToken).balanceOf(address(this))); // transfer resulting crXSUSHI to `to`
    }
    
    /***********************
    CREAM -> XSUSHI -> SUSHI 
    ***********************/
    /// @notice Unstake crXSUSHI `amount` into SUSHI by batching calls to `crXSushiToken` and `sushiBar`.
    function unstakeSushiFromCream(uint256 amount) external {
        IERC20(crXSushiToken).safeTransferFrom(msg.sender, address(this), amount); // deposit `msg.sender` `crXSushiToken` `amount` into this contract
        ICompoundBridge(crXSushiToken).redeem(amount); // burn deposited `crXSushiToken` `amount` into xSUSHI
        ISushiBarBridge(sushiBar).leave(IERC20(sushiBar).balanceOf(address(this))); // burn resulting xSUSHI `amount` from `sushiBar` into SUSHI
        sushiToken.safeTransfer(msg.sender, sushiToken.balanceOf(address(this))); // transfer resulting SUSHI to `msg.sender`
    }
    
    /// @notice Unstake crXSUSHI `amount` into SUSHI for benefit of `to` by batching calls to `crXSushiToken` and `sushiBar`.
    function unstakeSushiFromCreamTo(address to, uint256 amount) external {
        IERC20(crXSushiToken).safeTransferFrom(msg.sender, address(this), amount); // deposit `msg.sender` `crXSushiToken` `amount` into this contract
        ICompoundBridge(crXSushiToken).redeem(amount); // burn deposited `crXSushiToken` `amount` into xSUSHI
        ISushiBarBridge(sushiBar).leave(IERC20(sushiBar).balanceOf(address(this))); // burn resulting xSUSHI `amount` from `sushiBar` into SUSHI
        sushiToken.safeTransfer(to, sushiToken.balanceOf(address(this))); // transfer resulting SUSHI to `to`
    }
    
    /********************************
    SUSHI -> XSUSHI -> CREAM -> BENTO 
    ********************************/
    /// @notice Stake SUSHI `amount` into crXSUSHI and BENTO by batching calls to `sushiBar`, `crXSushiToken` and `bento`.
    function stakeSushiToCreamToBento(uint256 amount) external {
        sushiToken.safeTransferFrom(msg.sender, address(this), amount); // deposit `msg.sender` SUSHI `amount` into this contract
        ISushiBarBridge(sushiBar).enter(amount); // stake deposited SUSHI `amount` into `sushiBar` xSUSHI
        ICompoundBridge(crXSushiToken).mint(IERC20(sushiBar).balanceOf(address(this))); // stake resulting xSUSHI into crXSUSHI
        bento.deposit(IERC20(crXSushiToken), address(this), msg.sender, IERC20(crXSushiToken).balanceOf(address(this)), 0); // stake resulting crXSUSHI into BENTO for `msg.sender`
    }
    
    /// @notice Stake SUSHI `amount` into crXSUSHI and BENTO for benefit of `to` by batching calls to `sushiBar`, `crXSushiToken` and `bento`.
    function stakeSushiToCreamToBentoTo(address to, uint256 amount) external {
        sushiToken.safeTransferFrom(msg.sender, address(this), amount); // deposit `msg.sender` SUSHI `amount` into this contract
        ISushiBarBridge(sushiBar).enter(amount); // stake deposited SUSHI `amount` into `sushiBar` xSUSHI
        ICompoundBridge(crXSushiToken).mint(IERC20(sushiBar).balanceOf(address(this))); // stake resulting xSUSHI into crXSUSHI
        bento.deposit(IERC20(crXSushiToken), address(this), to, IERC20(crXSushiToken).balanceOf(address(this)), 0); // stake resulting crXSUSHI into BENTO for `to`
    }
    
    /********************************
    BENTO -> CREAM -> XSUSHI -> SUSHI 
    ********************************/
    /// @notice Unstake crXSUSHI `amount` into SUSHI from BENTO by batching calls to `bento`, `crXSushiToken` and `sushiBar`.
    function unstakeSushiFromCreamFromBento(uint256 amount) external {
        bento.withdraw(IERC20(crXSushiToken), msg.sender, address(this), amount, 0); // withdraw `amount` of `crXSushiToken` from BENTO into this contract
        ICompoundBridge(crXSushiToken).redeem(amount); // burn deposited `crXSushiToken` `amount` into xSUSHI
        ISushiBarBridge(sushiBar).leave(IERC20(sushiBar).balanceOf(address(this))); // burn resulting xSUSHI `amount` from `sushiBar` into SUSHI
        sushiToken.safeTransfer(msg.sender, sushiToken.balanceOf(address(this))); // transfer resulting SUSHI to `msg.sender`
    }
    
    /// @notice Unstake crXSUSHI `amount` into SUSHI from BENTO for benefit of `to` by batching calls to `bento`, `crXSushiToken` and `sushiBar`.
    function unstakeSushiFromCreamFromBentoTo(address to, uint256 amount) external {
        bento.withdraw(IERC20(crXSushiToken), msg.sender, address(this), amount, 0); // withdraw `amount` of `crXSushiToken` from BENTO into this contract
        ICompoundBridge(crXSushiToken).redeem(amount); // burn deposited `crXSushiToken` `amount` into xSUSHI
        ISushiBarBridge(sushiBar).leave(IERC20(sushiBar).balanceOf(address(this))); // burn resulting xSUSHI `amount` from `sushiBar` into SUSHI
        sushiToken.safeTransfer(to, sushiToken.balanceOf(address(this))); // transfer resulting SUSHI to `to`
    }
}