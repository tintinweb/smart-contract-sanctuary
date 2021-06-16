// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./IO.sol";
import "./Storage.sol";
import "./Constants.sol";

import "./ABDKMath64x64.sol";

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

contract Logic is Storage, Constants, IO {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;

    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;

    // **** Events **** //
    event ModuleApproved(address indexed module);
    event ModuleRevoked(address indexed module);

    // **** Fallback **** //

    receive() external payable {}

    // **** Modifiers **** //

    modifier authorized(bytes32 role) {
        require(hasRole(role, msg.sender), "!authorized");
        _;
    }

    modifier authorized2(bytes32 role1, bytes32 role2) {
        require(hasRole(role1, msg.sender) || hasRole(role2, msg.sender), "!authorized");
        _;
    }

    // **** Getters **** //

    /// @notice Gets the assets and their balances within the basket
    /// @return (the addresses of the assets,
    ///          the amount held by the basket of each asset)
    function getAssetsAndBalances() public view returns (address[] memory, uint256[] memory) {
        uint256[] memory assetBalances = new uint256[](assets.length);

        for (uint256 i = 0; i < assets.length; i++) {
            assetBalances[i] = ERC20(assets[i]).balanceOf(address(this));
        }

        return (assets, assetBalances);
    }

    /// @notice Gets the amount of assets backing each Basket token
    /// @return (the addresses of the assets,
    ///          the amount of backing 1 Basket token)
    function getOne() public view returns (address[] memory, uint256[] memory) {
        uint256[] memory amounts = new uint256[](assets.length);

        uint256 supply = totalSupply();

        for (uint256 i = 0; i < assets.length; i++) {
            amounts[i] = ERC20(assets[i]).balanceOf(address(this)).mul(1e18).div(supply);
        }

        return (assets, amounts);
    }

    /// @notice Gets the fees and the fee recipient
    /// @return (mint fee, burn fee, recipient)
    function getFees()
        public
        view
        returns (
            uint256,
            uint256,
            address
        )
    {
        return (_readSlotUint256(MINT_FEE), _readSlotUint256(BURN_FEE), _readSlotAddress(FEE_RECIPIENT));
    }

    // **** Admin functions **** //

    /// @notice Pauses minting in case of emergency
    function pause() public authorized2(GOVERNANCE, TIMELOCK) {
        _pause();
    }

    /// @notice Unpauses burning in case of emergency
    function unpause() public authorized2(GOVERNANCE, TIMELOCK) {
        _unpause();
    }

    /// @notice Sets the mint/burn fee and fee recipient
    function setFee(
        uint256 _mintFee,
        uint256 _burnFee,
        address _recipient
    ) public authorized(TIMELOCK) {
        require(_mintFee < FEE_DIVISOR, "invalid-mint-fee");
        require(_burnFee < FEE_DIVISOR, "invalid-burn-fee");
        require(_recipient != address(0), "invalid-fee-recipient");

        _writeSlot(MINT_FEE, _mintFee);
        _writeSlot(BURN_FEE, _burnFee);
        _writeSlot(FEE_RECIPIENT, _recipient);
    }

    /// @notice Sets the list of assets backing the basket
    function setAssets(address[] memory _assets) public authorized(TIMELOCK) whenNotPaused {
        assets = _assets;
    }

    /// @notice Rescues ERC20 stuck in the contract (can't be on the list of assets)
    function rescueERC20(address _asset, uint256 _amount) public authorized2(MARKET_MAKER, GOVERNANCE) {
        for (uint256 i = 0; i < assets.length; i++) {
            require(_asset != assets[i], "!rescue asset");
        }
        ERC20(_asset).safeTransfer(msg.sender, _amount);
    }

    /// @notice Approves a module.
    /// @param _module Logic module to approve
    function approveModule(address _module) public authorized(TIMELOCK) {
        approvedModules[_module] = true;

        emit ModuleApproved(_module);
    }

    /// @notice Revokes a module.
    /// @param _module Logic module to approve
    function revokeModule(address _module) public authorized2(TIMELOCK, GOVERNANCE) {
        approvedModules[_module] = false;

        emit ModuleRevoked(_module);
    }

    /// @notice Executes arbitrary logic on approved modules. Mostly used for rebalancing.
    /// @param  _module  Logic code to assume
    /// @param  _data  Payload
    function execute(address _module, bytes memory _data)
        public
        payable
        authorized2(GOVERNANCE, TIMELOCK)
        returns (bytes memory response)
    {
        require(approvedModules[_module], "!module-approved");

        // call contract in current context
        assembly {
            let succeeded := delegatecall(sub(gas(), 5000), _module, add(_data, 0x20), mload(_data), 0, 0)
            let size := returndatasize()

            response := mload(0x40)
            mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            switch iszero(succeeded)
                case 1 {
                    // throw if delegatecall failed
                    revert(add(response, 0x20), size)
                }
        }
    }

    // **** Mint/Burn functionality **** //

    /// @notice Mints a new Basket token
    /// @param  _amountOut  Amount of Basket tokens to mint
    function mint(uint256 _amountOut) public whenNotPaused nonReentrant {
        require(totalSupply() > 0, "!migrated");

        uint256[] memory _amountsToTransfer = viewMint(_amountOut);

        for (uint256 i = 0; i < assets.length; i++) {
            ERC20(assets[i]).safeTransferFrom(msg.sender, address(this), _amountsToTransfer[i]);
        }

        // If user is a market maker then just mint the tokens
        if (hasRole(MARKET_MAKER, msg.sender)) {
            _mint(msg.sender, _amountOut);
            return;
        }

        // Otherwise charge a fee
        uint256 fee = _amountOut.mul(_readSlotUint256(MINT_FEE)).div(FEE_DIVISOR);
        address feeRecipient = _readSlotAddress(FEE_RECIPIENT);

        _mint(feeRecipient, fee);
        _mint(msg.sender, _amountOut.sub(fee));
    }

    /// @notice Previews the corresponding assets and amount required to mint `_amountOut` Basket tokens
    /// @param  _amountOut  Amount of Basket tokens to mint
    function viewMint(uint256 _amountOut) public view returns (uint256[] memory _amountsIn) {
        uint256 totalLp = totalSupply();

        _amountsIn = new uint256[](assets.length);

        // Precise math
        int128 amountOut128 = _amountOut.divu(1e18).add(uint256(1).divu(1e18));
        int128 totalLp128 = totalLp.divu(1e18).add(uint256(1).divu(1e18));
        int128 ratio128 = amountOut128.div(totalLp128);

        uint256 _amountToTransfer;

        for (uint256 i = 0; i < assets.length; i++) {
            _amountToTransfer = ratio128.mulu(ERC20(assets[i]).balanceOf(address(this)));
            _amountsIn[i] = _amountToTransfer;
        }
    }

    /// @notice Burns the basket token and retrieves
    /// @param  _amount  Amount of Basket tokens to burn
    function burn(uint256 _amount) public whenNotPaused nonReentrant {
        uint256 totalLp = totalSupply();

        require(totalLp > 0, "!initialMint");
        require(_amount >= 1e6, "!min-burn-1e6");

        // Precise math library
        int128 ratio128;
        int128 totalLp128 = totalLp.divu(1e18).add(uint256(1).divu(1e18));
        int128 amount128;

        uint256 amountOut;

        // If user is a market maker then no fee
        if (hasRole(MARKET_MAKER, msg.sender)) {
            amount128 = _amount.divu(1e18).add(uint256(1).divu(1e18));
            ratio128 = amount128.div(totalLp128);

            _burn(msg.sender, _amount);
        } else {
            // Otherwise calculate fee
            address feeRecipient = _readSlotAddress(FEE_RECIPIENT);
            uint256 fee = _amount.mul(_readSlotUint256(BURN_FEE)).div(FEE_DIVISOR);

            amount128 = _amount.sub(fee).divu(1e18).add(uint256(1).divu(1e18));
            ratio128 = amount128.div(totalLp128);

            _burn(msg.sender, _amount.sub(fee));
            _transfer(msg.sender, feeRecipient, fee);
        }

        for (uint256 i = 0; i < assets.length; i++) {
            amountOut = ratio128.mulu(ERC20(assets[i]).balanceOf(address(this)));
            ERC20(assets[i]).safeTransfer(msg.sender, amountOut);
        }
    }
}