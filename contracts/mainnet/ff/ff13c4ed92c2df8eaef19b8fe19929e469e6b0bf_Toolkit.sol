/**
 *Submitted for verification at Etherscan.io on 2021-03-04
*/

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

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

/**
 * @title yV1
 * @dev yearn v1 vault
 */
interface yV1 {
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _shares) external;
}

/**
 * @title yS1
 * @dev yearn v1 strategy
 */
interface yS1 {
    function setStrategist(address _strategist) external;
    function setKeeper(address _keeper) external;
}

/**
 * @title yV2
 * @dev yearn v2 vault
 */
interface yV2 {
    function deposit() external;
    function deposit(uint256 _amount) external;
    function withdraw() external;
    function withdraw(uint256 _shares) external;
}

/**
 * @title yS2
 * @dev yearn v2 strategy
 */
interface yS2 {
    function setRewards(address _rewards) external;
}

/**
 * @title 1SplitAudit
 * @dev 1split on-chain aggregator
 */
interface One {
    /**
     * @notice Calculate expected returning amount of `destToken`
     * @param fromToken (IERC20) Address of token or `address(0)` for Ether
     * @param destToken (IERC20) Address of token or `address(0)` for Ether
     * @param amount (uint256) Amount for `fromToken`
     * @param parts (uint256) Number of pieces source volume could be splitted,
     * works like granularity, higly affects gas usage. Should be called offchain,
     * but could be called onchain if user swaps not his own funds, but this is still considered as not safe.
     * @param flags (uint256) Flags for enabling and disabling some features, default 0
     */
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags // See contants in IOneSplit.sol
    )
        external
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        );

    /**
     * @notice Calculate expected returning amount of `destToken`
     * @param fromToken (IERC20) Address of token or `address(0)` for Ether
     * @param destToken (IERC20) Address of token or `address(0)` for Ether
     * @param amount (uint256) Amount for `fromToken`
     * @param parts (uint256) Number of pieces source volume could be splitted,
     * works like granularity, higly affects gas usage. Should be called offchain,
     * but could be called onchain if user swaps not his own funds, but this is still considered as not safe.
     * @param flags (uint256) Flags for enabling and disabling some features, default 0
     * @param destTokenEthPriceTimesGasPrice (uint256) destToken price to ETH multiplied by gas price
     */
    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags, // See constants in IOneSplit.sol
        uint256 destTokenEthPriceTimesGasPrice
    )
        external
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        );

    /**
     * @notice Swap `amount` of `fromToken` to `destToken`
     * @param fromToken (IERC20) Address of token or `address(0)` for Ether
     * @param destToken (IERC20) Address of token or `address(0)` for Ether
     * @param amount (uint256) Amount for `fromToken`
     * @param minReturn (uint256) Minimum expected return, else revert
     * @param distribution (uint256[]) Array of weights for volume distribution returned by `getExpectedReturn`
     * @param flags (uint256) Flags for enabling and disabling some features, default 0
     */
    function swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256 flags // See contants in IOneSplit.sol
    ) external payable returns(uint256);

    /**
     * @notice Swap `amount` of `fromToken` to `destToken`
     * @param fromToken (IERC20) Address of token or `address(0)` for Ether
     * @param destToken (IERC20) Address of token or `address(0)` for Ether
     * @param amount (uint256) Amount for `fromToken`
     * @param minReturn (uint256) Minimum expected return, else revert
     * @param distribution (uint256[]) Array of weights for volume distribution returned by `getExpectedReturn`
     * @param flags (uint256) Flags for enabling and disabling some features, default 0
     * @param referral (address) Address of referral
     * @param feePercent (uint256) Fees percents normalized to 1e18, limited to 0.03e18 (3%)
     */
    function swapWithReferral(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata distribution,
        uint256 flags, // See contants in IOneSplit.sol
        address referral,
        uint256 feePercent
    ) external payable returns(uint256);
}

contract Toolkit {

    address public oneProto = address(0x50FDA034C0Ce7a8f7EFDAebDA7Aa7cA21CC1267e);

    constructor() public {}

    function setStrategists(address[] calldata _targets, address _strategist) public {
        for(uint256 i = 0; i < _targets.length; ++i) {
            yS1(_targets[i]).setStrategist(_strategist);
        }
    }

    function setKeepers(address[] calldata _targets, address _keeper) public {
        for(uint256 i = 0; i < _targets.length; ++i) {
            yS1(_targets[i]).setKeeper(_keeper);
        }
    }

    function setRewards(address[] calldata _targets, address _rewards) public {
        for(uint256 i = 0; i < _targets.length; ++i) {
            yS2(_targets[i]).setRewards(_rewards);
        }
    }

    function approves(
        address[] calldata _tokens, 
        address[] calldata _spenders, 
        uint256[] calldata _amounts
    ) public returns (bool) {
        for(uint256 i = 0; i < _tokens.length; ++i) {
            IERC20 token = IERC20(_tokens[i]);
            token.approve(_spenders[i], _amounts[i]);
        }
        return true;
    }

    function approvesMAX(
        address[] calldata _tokens, 
        address[] calldata _spenders
    ) public returns (bool) {
        for(uint256 i = 0; i < _tokens.length; ++i) {
            IERC20 token = IERC20(_tokens[i]);
            token.approve(_spenders[i], uint256(-1));
        }
        return true;
    }

    function transfers(
        address[] calldata _tokens, 
        address[] calldata _recipients, 
        uint256[] calldata _amounts
    ) public returns (bool) {
        for(uint256 i = 0; i < _tokens.length; ++i) {
            IERC20 token = IERC20(_tokens[i]);
            token.transfer(_recipients[i], _amounts[i]);
        }
        return true;
    }

    function transferFroms(
        address[] calldata _tokens, 
        address[] calldata _senders, 
        address[] calldata _recipients, 
        uint256[] calldata _amounts
    ) external returns (bool) {
        for(uint256 i = 0; i < _tokens.length; ++i) {
            IERC20 token = IERC20(_tokens[i]);
            token.transferFrom(_senders[i], _recipients[i], _amounts[i]);
        }
        return true;
    }

    function batchTransfers(
        address _token, 
        address[] calldata _recipients, 
        uint256[] calldata _amounts
    ) public returns (bool) {
        IERC20 token = IERC20(_token);
        for(uint256 i = 0; i < _recipients.length; ++i) {
            token.transfer(_recipients[i], _amounts[i]);
        }
        return true;
    }

    function deposit(address _to, uint256 _amount) external {
        yV1(_to).deposit(_amount);
    }

    function deposits(address[] calldata _tos, uint256[] calldata _amounts) external {
        for(uint256 i = 0; i < _tos.length; ++i) {
            yV1(_tos[i]).deposit(_amounts[i]);
        }
    }

    function withdraw(address _to, uint256 _share) external {
        yV1(_to).withdraw(_share);
    }

    function withdraws(address[] calldata _tos, uint256[] calldata _shares) external {
        for(uint256 i = 0; i < _tos.length; ++i) {
            yV1(_tos[i]).withdraw(_shares[i]);
        }
    }

    function swap(
        address _from, 
        address _to, 
        uint256 _fromAmount, 
        uint256 _minReturn, 
        uint256[] calldata distribution, 
        uint256 _flags
    ) public payable {
        if (_from == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
            require(_fromAmount == msg.value, "swap::eth value not match");
        }
        else {
            IERC20(_from).approve(oneProto, uint256(-1));
        }
        One(oneProto).swap(IERC20(_from), IERC20(_to), _fromAmount, _minReturn, distribution, _flags);
    }

    function seizes(address[] calldata _tokens) public returns (bool) {
        for(uint256 i = 0; i < _tokens.length; ++i) {
            IERC20 token = IERC20(_tokens[i]);
            token.transfer(msg.sender, token.balanceOf(address(this)));
        }
        return true;
    }

    function sweep() public returns (bool success) {
        address sender = address(uint160(msg.sender));
        uint256 _balance = address(this).balance;
        (success, ) = sender.call{value: _balance}("");
    }
}