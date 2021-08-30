// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.4;

import "./draft-ERC20PermitUpgradeable.sol";
import "./OwnedInitializable.sol";
import "./IUniswapV2Router.sol";

contract Pika is OwnedInitializable, ERC20PermitUpgradeable {
    address public WETH;
    uint256 public minSupply;
    mapping(address => bool) public isExcludedFromFee;
    bool public feesEnabled;
    bool public swapEnabled;

    address public uniswapPair;

    // combine recipient and fee into a single storage slot
    uint256 public beneficiary;
    uint256 public staking;
    uint256 public liquidity;

    event MinSupplyUpdated(uint256 oldAmount, uint256 newAmount);
    event BeneficiaryRewardUpdated(address oldBeneficiary, address newBeneficiary, uint256 oldFee, uint256 newFee);
    event StakingRewardUpdated(address oldBeneficiary, address newBeneficiary, uint256 oldFee, uint256 newFee);
    event LiquidityRewardUpdated(address oldBeneficiary, address newBeneficiary, uint256 oldFee, uint256 newFee);
    event FeesEnabledUpdated(bool enabled);
    event SwapEnabledUpdated(bool enabled);
    event ExcludedFromFeeUpdated(address account, bool excluded);

    modifier ensureAddressSet(address _beneficiary, uint256 _fee) {
        if (_fee > 0) {
            require(_beneficiary != address(0), "address not set");
        } else {
            require(_beneficiary == address(0), "set address to zero");
        }
        _;
    }

    function initialize(
        uint256 _minSupply,
        uint256 _totalSupply,
        address _beneficiary,
        string calldata _name,
        string calldata _symbol,
        uint256 _initial_fee
    ) public virtual initializer {
        __Ownable_init();
        __ERC20_init(_name, _symbol);
        __ERC20Permit_init(_name);
        minSupply = _minSupply;
        _mint(_msgSender(), _totalSupply);

        // calculate future Uniswap V2 pair address
        address uniswapFactory = router().factory();
        address _WETH = router().WETH();
        WETH = _WETH;
        // calculate future uniswap pair address
        (address token0, address token1) = (_WETH < address(this) ? (_WETH, address(this)) : (address(this), _WETH));
        address pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            uniswapFactory,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f"
                        )
                    )
                )
            )
        );
        uniswapPair = pair;
        beneficiary = packBeneficiary(_beneficiary, _initial_fee);
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[_beneficiary] = true;
        isExcludedFromFee[_msgSender()] = true;
    }

    /**
     * @notice adds or removes an account that is exempt from fee collection
     * @dev only callable by owner
     * @param _account account to modify
     * @param _excluded new value
     */
    function setExcludeFromFee(address _account, bool _excluded) public onlyOwner {
        isExcludedFromFee[_account] = _excluded;
        emit ExcludedFromFeeUpdated(_account, _excluded);
    }

    /**
     * @dev helper function to pack address and fee into one storage slot
     */
    function packBeneficiary(address _beneficiary, uint256 _fee) public pure returns (uint256) {
        uint256 storedBeneficiary = uint256(uint160(_beneficiary));
        storedBeneficiary |= _fee << 160;
        return storedBeneficiary;
    }

    /**
     * @dev helper function to unpack address and fee from single storage slot
     */
    function unpackBeneficiary(uint256 _beneficiary) public pure returns (address, uint256) {
        return (address(uint160(_beneficiary)), uint256(uint96(_beneficiary >> 160)));
    }

    /**
     * @notice allows to burn tokens from own balance
     * @dev only allows burning tokens until minimum supply is reached
     * @param value amount of tokens to burn
     */
    function burn(uint256 value) external {
        _burn(_msgSender(), value);
        require(totalSupply() >= minSupply, "total supply exceeds min supply");
    }

    /**
     * @notice sets minimum supply of the token
     * @dev only callable by owner
     * @param _newMinSupply new minimum supply
     */
    function setMinSupply(uint256 _newMinSupply) external onlyOwner {
        emit MinSupplyUpdated(minSupply, _newMinSupply);
        minSupply = _newMinSupply;
    }

    /**
     * @notice sets recipient and fee amount of transfer fee
     * @dev excludes new beneficiary from fee
     * @dev only callable by owner
     * @param _newBeneficiary address of new beneficiary
     * @param _fee            fee sent to new beneficiary in permyriad
     */
    function setBeneficiary(address _newBeneficiary, uint256 _fee)
        external
        ensureAddressSet(_newBeneficiary, _fee)
        onlyOwner
    {
        setExcludeFromFee(_newBeneficiary, true);
        (address currentBeneficiary, uint256 currentFee) = unpackBeneficiary(beneficiary);
        uint256 newBeneficiary = packBeneficiary(_newBeneficiary, _fee);
        emit BeneficiaryRewardUpdated(currentBeneficiary, _newBeneficiary, currentFee, _fee);
        beneficiary = newBeneficiary;
    }

    /**
     * @notice sets recipient and fee amount of staking rewards
     * @dev excludes staking pool from fee
     * @dev only callable by owner
     * @param _contractAddress address of staking contract
     * @param _fee             fee sent to staking contract in permyriad
     */
    function setStaking(address _contractAddress, uint256 _fee)
        external
        ensureAddressSet(_contractAddress, _fee)
        onlyOwner
    {
        setExcludeFromFee(_contractAddress, true);
        (address currentAddress, uint256 currentFee) = unpackBeneficiary(staking);
        uint256 newStaking = packBeneficiary(_contractAddress, _fee);
        emit StakingRewardUpdated(currentAddress, _contractAddress, currentFee, _fee);
        staking = newStaking;
    }

    /**
     * @notice sets recipient and fee amount of liquidity rewards
     * @dev excludes liquidity rewards pool from fee
     * @dev only callable by owner
     * @param _contractAddress address of liquidity rewards pool contract
     * @param _fee             fee sent to new liquidity rewards pool in permyriad
     */
    function setLiquidity(address _contractAddress, uint256 _fee)
        external
        ensureAddressSet(_contractAddress, _fee)
        onlyOwner
    {
        setExcludeFromFee(_contractAddress, true);
        (address currentAddress, uint256 currentFee) = unpackBeneficiary(liquidity);
        uint256 newLiquidity = packBeneficiary(_contractAddress, _fee);
        emit LiquidityRewardUpdated(currentAddress, _contractAddress, currentFee, _fee);
        liquidity = newLiquidity;
    }

    /**
     * @notice sets whether account collects fees on token transfer
     * @dev only callable by owner
     * @param _enabled bool whether fees are enabled
     */
    function setFeesEnabled(bool _enabled) external onlyOwner {
        emit FeesEnabledUpdated(_enabled);
        feesEnabled = _enabled;
    }

    /**
     * @notice sets whether collected fees are autoswapped
     * @dev only callable by owner
     * @param _enabled bool whether swap is enabled
     */
    function setSwapEnabled(bool _enabled) external onlyOwner {
        emit SwapEnabledUpdated(_enabled);
        swapEnabled = _enabled;
    }

    function router() public pure virtual returns (IUniswapV2Router) {
        return IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        if (
            !feesEnabled ||
            isExcludedFromFee[sender] ||
            isExcludedFromFee[recipient] ||
            // when removing liquidity from uniswap, don't take fee multiple times
            (sender == uniswapPair && recipient == address(router()))
        ) {
            super._transfer(sender, recipient, amount);
            return;
        }
        // get fees and recipients from storage
        (address beneficiaryAddress, uint256 transferFee) = unpackBeneficiary(beneficiary);
        (address stakingContract, uint256 stakingFee) = unpackBeneficiary(staking);
        (address liquidityContract, uint256 liquidityFee) = unpackBeneficiary(liquidity);
        if (transferFee > 0) {
            transferFee = _calculateFee(amount, transferFee);
            address feeRecipient = swapEnabled ? address(this) : beneficiaryAddress;
            super._transfer(sender, feeRecipient, transferFee);
        }
        uint256 amountWithFee = amount - transferFee;
        // burn tokens if min supply not reached yet
        uint256 burnedFee = _calculateFee(amount, 25);
        if (totalSupply() - burnedFee >= minSupply) {
            _burn(sender, burnedFee);
            amountWithFee -= burnedFee;
        }
        if (stakingFee > 0) {
            stakingFee = _calculateFee(amount, stakingFee);
            super._transfer(sender, stakingContract, stakingFee);
            amountWithFee -= stakingFee;
        }
        if (liquidityFee > 0) {
            liquidityFee = _calculateFee(amount, liquidityFee);
            super._transfer(sender, liquidityContract, liquidityFee);
            amountWithFee -= liquidityFee;
        }
        // don't autoswap when uniswap pair or router are sending tokens
        if (swapEnabled && sender != uniswapPair && sender != address(router())) {
            _swapTokensForEth();
        }
        super._transfer(sender, recipient, amountWithFee);
    }

    function _swapTokensForEth() private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        uint256 tokenAmount = balanceOf(address(this));
        _approve(address(this), address(router()), tokenAmount);
        (address to, ) = unpackBeneficiary(beneficiary);
        router().swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, to, block.timestamp);
    }

    function _calculateFee(uint256 _amount, uint256 _fee) private pure returns (uint256) {
        return (_amount * _fee) / 10000;
    }
}