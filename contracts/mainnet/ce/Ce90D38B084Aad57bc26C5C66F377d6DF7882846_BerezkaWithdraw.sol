// SPDX-License-Identifier: Unlicense
// Developed by EasyChain Blockchain Development Team (easychain.tech)
//
pragma solidity ^0.8.4;

import "./api/IAgent.sol";
import "./api/ITokens.sol";
import "./common/BerezkaOracleClient.sol";
import "./common/BerezkaDaoManager.sol";
import "./common/BerezkaStableCoinManager.sol";

// This contract provides Withdraw function for Berezka DAO
// Basic flow is:
//  1. User obtains signed price data from trusted off-chain Oracle
//  2. Exchange rate is computed
//  3. User's tokens are burned (no approval need thanks to Aragon)
//  4. Stable coins are transferred to user
//
contract BerezkaWithdraw is
    BerezkaOracleClient,
    BerezkaDaoManager,
    BerezkaStableCoinManager
{
    // Events
    event WithdrawSuccessEvent(
        address indexed daoToken,
        uint256 daoTokenAmount,
        address indexed stableToken,
        uint256 stableTokenAmount,
        address indexed sender,
        uint256 price,
        uint256 timestamp
    );

    // Main function. Allows user (msg.sender) to withdraw funds from DAO.
    // _amount - amount of DAO tokens to exhange
    // _token - token of DAO to exchange
    // _targetToken - token to receive in exchange
    // _optimisticPrice - an optimistic price of DAO token. Used to check if DAO Agent
    //                    have enough funds on it's balance. Is not used to calculare
    //                    use returns
    function withdraw(
        uint256 _amount,
        address _token,
        address _targetToken,
        uint256 _optimisticPrice,
        uint256 _optimisticPriceTimestamp,
        bytes memory _signature
    )
        public
        withValidOracleData(
            _token,
            _optimisticPrice,
            _optimisticPriceTimestamp,
            _signature
        )
        isWhitelisted(_targetToken)
    {
        // Require that amount is positive
        //
        require(_amount > 0, "ZERO_TOKEN_AMOUNT");

        _checkUserBalance(_amount, _token, msg.sender);

        // Require that an agent have funds to fullfill request (optimisitcally)
        // And that this contract can withdraw neccesary amount of funds from agent
        //
        uint256 optimisticAmount = computeExchange(
            _amount,
            _optimisticPrice,
            _targetToken
        );
        
        _doWithdraw(
            _amount,
            _token,
            _targetToken,
            msg.sender,
            optimisticAmount
        );

        // Emit withdraw success event
        //
        emit WithdrawSuccessEvent(
            _token,
            _amount,
            _targetToken,
            optimisticAmount,
            msg.sender,
            _optimisticPrice,
            _optimisticPriceTimestamp
        );
    }

    function _doWithdraw(
        uint256 _amount,
        address _token,
        address _targetToken,
        address _user,
        uint256 _optimisticAmount
    ) internal {
        address agentAddress = _agentAddress(_token);
        
        IERC20 targetToken = IERC20(_targetToken);
        require(
            targetToken.balanceOf(agentAddress) >= _optimisticAmount,
            "INSUFFICIENT_FUNDS_ON_AGENT"
        );

        // Perform actual exchange
        //
        IAgent agent = IAgent(agentAddress);
        agent.transfer(_targetToken, _user, _optimisticAmount);

        // Burn tokens
        //
        ITokens tokens = ITokens(daoConfig[_token].tokens);
        tokens.burn(_user, _amount);
    }

    function _checkUserBalance(
        uint256 _amount,
        address _token,
        address _user
    ) internal view {
        // Check DAO token balance on iuser
        //
        IERC20 token = IERC20(_token);
        require(
            token.balanceOf(_user) >= _amount,
            "NOT_ENOUGH_TOKENS_TO_BURN_ON_BALANCE"
        );
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IAgent {
    function transfer(
        address _token,
        address _to,
        uint256 _value
    ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface ITokens {
    
    function burn(address _holder, uint256 _amount) external;

    function mint(address _holder, uint256 _amount) external;
}

// SPDX-License-Identifier: Unlicense
// Developed by EasyChain Blockchain Development Team (easychain.tech)
//
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BerezkaOracleClient is Ownable {
    // Address of Oracle
    //
    address public oracleAddress = 0xAb66dE3DF08318922bb4cE15553E4C2dCf9187A1;

    // Signature expiration time
    //
    uint256 public signatureValidityDuractionSec = 3600;

    modifier withValidOracleData(
        address _token,
        uint256 _optimisticPrice,
        uint256 _optimisticPriceTimestamp,
        bytes memory _signature
    ) {
        // Check price is not Zero
        //
        require(_optimisticPrice > 0, "ZERO_OPTIMISTIC_PRICE");

        // Check that signature is not expired and is valid
        //
        require(
            isValidSignatureDate(_optimisticPriceTimestamp),
            "EXPIRED_PRICE_DATA"
        );

        require(
            isValidSignature(
                _optimisticPrice,
                _optimisticPriceTimestamp,
                _token,
                _signature
            ),
            "INVALID_SIGNATURE"
        );

        _;
    }

    function isValidSignatureDate(uint256 _optimisticPriceTimestamp)
        public
        view
        returns (bool)
    {
        return computeSignatureDateDelta(_optimisticPriceTimestamp) <= signatureValidityDuractionSec;
    }

    function computeSignatureDateDelta(uint256 _optimisticPriceTimestamp)
        public
        view
        returns (uint256)
    {
        uint256 timeDelta = 0;
        if (_optimisticPriceTimestamp >= block.timestamp) {
            timeDelta = _optimisticPriceTimestamp - block.timestamp;
        } else {
            timeDelta = block.timestamp - _optimisticPriceTimestamp;
        }
        return timeDelta;
    }

    // Validates oracle price signature
    //
    function isValidSignature(
        uint256 _price,
        uint256 _timestamp,
        address _token,
        bytes memory _signature
    ) public view returns (bool) {
        return recover(_price, _timestamp, _token, _signature) == oracleAddress;
    }

    // Validates oracle price signature
    //
    function recover(
        uint256 _price,
        uint256 _timestamp,
        address _token,
        bytes memory _signature
    ) public pure returns (address) {
        bytes32 dataHash = keccak256(
            abi.encodePacked(_price, _timestamp, _token)
        );
        bytes32 signedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)
        );
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        address signer = ecrecover(signedMessageHash, v, r, s);
        return signer;
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    // Adds possible tokens (stableconins) to withdraw to
    // _whitelisted - list of stableconins to withdraw to
    //
    function setSignatureValidityDurationSec(
        uint256 _signatureValidityDuractionSec
    ) public onlyOwner {
        require(_signatureValidityDuractionSec > 0);

        signatureValidityDuractionSec = _signatureValidityDuractionSec;
    }

    // Sets an address of Oracle
    // _oracleAddres - Oracle
    //
    function setOracleAddress(address _oracleAddres) public onlyOwner {
        oracleAddress = _oracleAddres;
    }
}

// SPDX-License-Identifier: Unlicense
// Developed by EasyChain Blockchain Development Team (easychain.tech)
//
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BerezkaDaoManager is Ownable {
    // Information about DAO
    struct Dao {
        address agent; // Address of Aragon DAO Agent App
        address tokens; // Address of Aragon DAO Tokens App
    }

    // Each token have an agent to withdraw tokens from
    //
    mapping(address => Dao) public daoConfig;

    function _agentAddress(
        address _token
    ) public view returns (address) {
        address agentAddress = daoConfig[_token].agent;
        // Require that there is an agent (vault) address for a given token
        //
        require(agentAddress != address(0), "NO_DAO_FOR_TOKEN");
        return agentAddress;
    }

    // Adds new DAO to contract.
    // _token - DAO token
    // _tokens - corresponding Tokens service in Aragon, that manages _token
    // _agent - agent contract in Aragon (fund holder)
    //
    function addDao(
        address _token,
        address _tokens,
        address _agent
    ) public onlyOwner {
        daoConfig[_token] = Dao(_agent, _tokens);
    }

    // Removes DAO from contract
    // _token - token to remove
    //
    function deleteDao(address _token) public onlyOwner {
        delete daoConfig[_token];
    }
}

// SPDX-License-Identifier: Unlicense
// Developed by EasyChain Blockchain Development Team (easychain.tech)
//
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract BerezkaStableCoinManager is Ownable {
    
    // Stable token whitelist to use
    //
    mapping(address => bool) public whitelist;

    modifier isWhitelisted(
        address _targetToken
    ) {
        require(whitelist[_targetToken], "INVALID_TOKEN_TO_DEPOSIT");
        _;
    }

    // Computes an amount of _targetToken that user will get in exchange for
    // a given amount for DAO tokens
    // _amount - amount of DAO tokens
    // _price - price in 6 decimals per 10e18 of DAO token
    // _targetToken - target token to receive
    //
    function computeExchange(
        uint256 _amount,
        uint256 _price,
        address _targetToken
    ) public view returns (uint256) {
        IERC20Metadata targetToken = IERC20Metadata(_targetToken);
        uint256 result = _amount * _price / 10 ** (24 - targetToken.decimals());
        require(result > 0, "INVALID_TOKEN_AMOUNT");
        return result;
    }

    // Adds possible tokens (stableconins) to use
    // _whitelisted - list of stableconins to use
    //
    function addWhitelistTokens(address[] memory _whitelisted)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _whitelisted.length; i++) {
            whitelist[_whitelisted[i]] = true;
        }
    }

    // Removes possible tokens (stableconins) to use
    // _whitelisted - list of stableconins to use
    //
    function removeWhitelistTokens(address[] memory _whitelisted)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _whitelisted.length; i++) {
            whitelist[_whitelisted[i]] = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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