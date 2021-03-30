/**
 *Submitted for verification at Etherscan.io on 2021-03-29
*/

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.6.0;

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

// File: contracts/interface/ILiquidityProtection.sol

pragma solidity >=0.6.0;


interface IConverterAnchor {

}

interface ILiquidityProtection {
    function addLiquidity(
        IConverterAnchor _poolAnchor,
        IERC20 _reserveToken,
        uint256 _amount
    ) external payable returns(uint);
    // returns id of deposit

    function removeLiquidity(uint256 _id, uint32 _portion) external;

    function removeLiquidityReturn(
        uint256 _id,
        uint32 _portion,
        uint256 _removeTimestamp
    ) external view returns (uint256, uint256, uint256);
    // returns amount in the reserve token
    // returns actual return amount in the reserve token
    // returns compensation in the network token

    // call 24 hours after removing liquidity
    function claimBalance(uint256 _startIndex, uint256 _endIndex) external;
}

// File: contracts/interface/IStakingRewards.sol

pragma solidity >=0.6.0;

interface IDSToken {

}

interface IStakingRewards {
    // claims all rewards from providing address
    function claimRewards() external returns (uint256);
    // returns pending rewards from providing address
    function pendingRewards(address provider) external view returns (uint256);
    // returns all staked rewards and the ID of the new position
    function stakeRewards(uint256 maxAmount, IDSToken poolToken) external returns (uint256, uint256);
}

// File: contracts/interface/IContractRegistry.sol

pragma solidity >=0.6.0;

interface IContractRegistry {
    function addressOf(bytes32 contractName) external view returns(address);
}

// File: contracts/interface/IxBNT.sol

pragma solidity 0.6.2;

interface IxBNT {
    function getProxyAddressDepositIds(address proxyAddress) external view returns(uint256[] memory);
}

// File: contracts/helpers/LiquidityProvider.sol

pragma solidity 0.6.2;





contract LiquidityProvider {
    bool private initialized;

    IContractRegistry private contractRegistry;
    IERC20 private bnt;
    IERC20 private vbnt;

    address private xbnt;
    uint256 public nextDepositIndexToClaimBalance;

    function initializeAndAddLiquidity(
        IContractRegistry _contractRegistry,
        address _xbnt,
        IERC20 _bnt,
        IERC20 _vbnt,
        address _poolToken,
        uint256 _amount
    ) external returns(uint256) {
        require(msg.sender == _xbnt, "Invalid caller");
        require(!initialized, "Already initialized");
        initialized = true;

        contractRegistry = _contractRegistry;
        xbnt = _xbnt;
        bnt = _bnt;
        vbnt = _vbnt;

        return _addLiquidity(_poolToken, _amount);
    }

    function _addLiquidity(
        address _poolToken,
        uint256 _amount
    ) private returns(uint256 id) {
        ILiquidityProtection lp = getLiquidityProtectionContract();
        bnt.approve(address(lp), uint(-1));

        id = lp.addLiquidity(IConverterAnchor(_poolToken), bnt, _amount);

        _retrieveVbntBalance();
    }

    /*
     * @notice Restake this proxy's rewards
     */
    function claimAndRestake(address _poolToken) external onlyXbntContract returns(uint256 newDepositId, uint256 restakedBal){
        (, newDepositId) = getStakingRewardsContract().stakeRewards(uint(-1), IDSToken(_poolToken));
        restakedBal = _retrieveVbntBalance();
    }

    function claimRewards() external onlyXbntContract returns(uint256 rewardsAmount){
        rewardsAmount = _claimRewards();
    }

    function _claimRewards() private returns(uint256 rewards){
        rewards = getStakingRewardsContract().claimRewards();
        _retrieveBntBalance();
    }

    function _removeLiquidity(ILiquidityProtection _lp, uint256 _id) private {
        _lp.removeLiquidity(_id, 1000000); // full PPM resolution
    }

    /*
     * @notice Initiate final exit from this proxy
     */
    function claimRewardsAndRemoveLiquidity() external onlyXbntContract returns(uint256 rewards) {
        rewards = _claimRewards();
        uint256[] memory depositIds = getDepositIds();

        ILiquidityProtection lp = getLiquidityProtectionContract();
        vbnt.approve(address(lp), uint(-1));

        for(uint256 i = 0; i < depositIds.length; i++){
            _removeLiquidity(lp, depositIds[i]);
        }
    }

    /*
     * @notice Called 24 hours after `claimRewardsAndRemoveLiquidity`
     */
    function claimBalance() external onlyXbntContract {
        getLiquidityProtectionContract().claimBalance(0, getDepositIds().length);
        _retrieveBntBalance();
    }

    function _retrieveBntBalance() private {
        bnt.transfer(xbnt, bnt.balanceOf(address(this)));
    }

    function _retrieveVbntBalance() private returns(uint256 vbntBal) {
        vbntBal = vbnt.balanceOf(address(this));
        vbnt.transfer(xbnt, vbntBal);
    }

    function pendingRewards() external view returns(uint){
        return getStakingRewardsContract().pendingRewards(address(this));
    }

    function getStakingRewardsContract() private view returns(IStakingRewards){
        return IStakingRewards(contractRegistry.addressOf("StakingRewards"));
    }

    function getLiquidityProtectionContract() private view returns(ILiquidityProtection){
        return ILiquidityProtection(contractRegistry.addressOf("LiquidityProtection"));
    }

    function getDepositIds() private view returns(uint256[] memory){
        return IxBNT(xbnt).getProxyAddressDepositIds(address(this));
    }

    modifier onlyXbntContract {
        require(msg.sender == xbnt, "Invalid caller");
        _;
    }
}