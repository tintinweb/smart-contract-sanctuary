/**
 *Submitted for verification at Etherscan.io on 2021-04-04
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// File: solidity/contracts/utility/interfaces/IOwned.sol


pragma solidity 0.6.12;

/*
    Owned contract interface
*/
interface IOwned {
    // this function isn't since the compiler emits automatically generated getter functions as external
    function owner() external view returns (address);

    function transferOwnership(address _newOwner) external;

    function acceptOwnership() external;
}

// File: solidity/contracts/utility/interfaces/ITokenHolder.sol


pragma solidity 0.6.12;



/*
    Token Holder interface
*/
interface ITokenHolder is IOwned {
    receive() external payable;

    function withdrawTokens(
        IERC20 token,
        address payable to,
        uint256 amount
    ) external;

    function withdrawTokensMultiple(
        IERC20[] calldata tokens,
        address payable to,
        uint256[] calldata amounts
    ) external;
}

// File: solidity/contracts/INetworkSettings.sol


pragma solidity 0.6.12;


interface INetworkSettings {
    function networkFeeParams() external view returns (ITokenHolder, uint32);

    function networkFeeWallet() external view returns (ITokenHolder);

    function networkFee() external view returns (uint32);
}

// File: solidity/contracts/utility/Owned.sol


pragma solidity 0.6.12;


/**
 * @dev This contract provides support and utilities for contract ownership.
 */
contract Owned is IOwned {
    address public override owner;
    address public newOwner;

    /**
     * @dev triggered when the owner is updated
     *
     * @param _prevOwner previous owner
     * @param _newOwner  new owner
     */
    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

    /**
     * @dev initializes a new Owned instance
     */
    constructor() public {
        owner = msg.sender;
    }

    // allows execution by the owner only
    modifier ownerOnly {
        _ownerOnly();
        _;
    }

    // error message binary size optimization
    function _ownerOnly() internal view {
        require(msg.sender == owner, "ERR_ACCESS_DENIED");
    }

    /**
     * @dev allows transferring the contract ownership
     * the new owner still needs to accept the transfer
     * can only be called by the contract owner
     *
     * @param _newOwner    new contract owner
     */
    function transferOwnership(address _newOwner) public override ownerOnly {
        require(_newOwner != owner, "ERR_SAME_OWNER");
        newOwner = _newOwner;
    }

    /**
     * @dev used by a new owner to accept an ownership transfer
     */
    function acceptOwnership() public override {
        require(msg.sender == newOwner, "ERR_ACCESS_DENIED");
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// File: solidity/contracts/utility/Utils.sol


pragma solidity 0.6.12;


/**
 * @dev Utilities & Common Modifiers
 */
contract Utils {
    uint32 internal constant PPM_RESOLUTION = 1000000;
    IERC20 internal constant NATIVE_TOKEN_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    // verifies that a value is greater than zero
    modifier greaterThanZero(uint256 _value) {
        _greaterThanZero(_value);
        _;
    }

    // error message binary size optimization
    function _greaterThanZero(uint256 _value) internal pure {
        require(_value > 0, "ERR_ZERO_VALUE");
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address _address) {
        _validAddress(_address);
        _;
    }

    // error message binary size optimization
    function _validAddress(address _address) internal pure {
        require(_address != address(0), "ERR_INVALID_ADDRESS");
    }

    // ensures that the portion is valid
    modifier validPortion(uint32 _portion) {
        _validPortion(_portion);
        _;
    }

    // error message binary size optimization
    function _validPortion(uint32 _portion) internal pure {
        require(_portion > 0 && _portion <= PPM_RESOLUTION, "ERR_INVALID_PORTION");
    }

    // validates an external address - currently only checks that it isn't null or this
    modifier validExternalAddress(address _address) {
        _validExternalAddress(_address);
        _;
    }

    // error message binary size optimization
    function _validExternalAddress(address _address) internal view {
        require(_address != address(0) && _address != address(this), "ERR_INVALID_EXTERNAL_ADDRESS");
    }

    // ensures that the fee is valid
    modifier validFee(uint32 fee) {
        _validFee(fee);
        _;
    }

    // error message binary size optimization
    function _validFee(uint32 fee) internal pure {
        require(fee <= PPM_RESOLUTION, "ERR_INVALID_FEE");
    }
}

// File: solidity/contracts/NetworkSettings.sol


pragma solidity 0.6.12;




/**
 * @dev This contract maintains the network settings.
 *
 */
contract NetworkSettings is INetworkSettings, Owned, Utils {
    ITokenHolder private _networkFeeWallet;
    uint32 private _networkFee;

    /**
     * @dev triggered when the network fee wallet is updated
     *
     * @param prevNetworkFeeWallet  previous network fee wallet
     * @param newNetworkFeeWallet   new network fee wallet
     */
    event NetworkFeeWalletUpdated(ITokenHolder prevNetworkFeeWallet, ITokenHolder newNetworkFeeWallet);

    /**
     * @dev triggered when the network fee is updated
     *
     * @param prevNetworkFee    previous network fee
     * @param newNetworkFee     new network fee
     */
    event NetworkFeeUpdated(uint32 prevNetworkFee, uint32 newNetworkFee);

    /**
     * @dev initializes a new NetworkSettings contract
     *
     * @param initialNetworkFeeWallet initial network fee wallet
     * @param initialNetworkFee initial network fee in ppm units
     */
    constructor(ITokenHolder initialNetworkFeeWallet, uint32 initialNetworkFee)
        public
        validAddress(address(initialNetworkFeeWallet))
        validFee(initialNetworkFee)
    {
        _networkFeeWallet = initialNetworkFeeWallet;
        _networkFee = initialNetworkFee;
    }

    /**
     * @dev returns the network fee parameters
     *
     * @return network fee wallet
     * @return network fee in ppm units
     */
    function networkFeeParams() external view override returns (ITokenHolder, uint32) {
        return (_networkFeeWallet, _networkFee);
    }

    /**
     * @dev returns the wallet that receives the global network fees
     *
     * @return network fee wallet
     */
    function networkFeeWallet() external view override returns (ITokenHolder) {
        return _networkFeeWallet;
    }

    /**
     * @dev returns the global network fee
     * the network fee is a portion of the total fees from each pool
     *
     * @return network fee in ppm units
     */
    function networkFee() external view override returns (uint32) {
        return _networkFee;
    }

    /**
     * @dev sets the network fee wallet
     * can be executed only by the owner
     *
     * @param newNetworkFeeWallet new network fee wallet
     */
    function setNetworkFeeWallet(ITokenHolder newNetworkFeeWallet)
        external
        ownerOnly
        validAddress(address(newNetworkFeeWallet))
    {
        emit NetworkFeeWalletUpdated(_networkFeeWallet, newNetworkFeeWallet);
        _networkFeeWallet = newNetworkFeeWallet;
    }

    /**
     * @dev sets the network fee
     * can be executed only by the owner
     *
     * @param newNetworkFee new network fee in ppm units
     */
    function setNetworkFee(uint32 newNetworkFee) external ownerOnly validFee(newNetworkFee) {
        emit NetworkFeeUpdated(_networkFee, newNetworkFee);
        _networkFee = newNetworkFee;
    }
}