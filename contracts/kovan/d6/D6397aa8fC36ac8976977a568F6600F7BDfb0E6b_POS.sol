// SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;

import "./interface/IProcessPayments.sol";
import "./interface/IMerchant.sol";
import "./chainlink/IAggregatorV3.sol";
import "./token/IERC20.sol";
import "./utils/Context.sol";
import "./utils/Ownable.sol";

contract POS is IProcessPayments, Ownable {
    address public merchantOracle;
    /**
     * Mapping of bytes string representing token ticker to an oracle address.
     */
    mapping(bytes => address) private _oracles;

    /**
     * Mapping of bytes string representing token ticker to token smart contract.
     */
    mapping(bytes => address) private _contracts;

    /**
     *
     */
    mapping(bytes => uint8) private _isStable;

    /**
     * @dev verifies whether a contract address is configured for a specific ticker.
     */
    modifier Available(string memory _ticker) {
        require(
            _contracts[bytes(_ticker)] != address(0),
            "PoS Error: contract address for ticker not available"
        );
        _;
    }

    /**
     * @dev validates whether the given asset is a stablecoin.
     */
    modifier Stablecoin(string memory _ticker) {
        require(
            _isStable[bytes(_ticker)] == 1,
            "PoS Error: token doesn't represent a stablecoin"
        );
        _;
    }

    event Payment(
        address indexed from,
        address indexed merchant,
        uint256 amount,
        string token,
        string notes
    );

    /**
     * @dev sets the owners in the Ownable Contract.
     */
    constructor(address _merchantOracle) Ownable() {
        merchantOracle = _merchantOracle;
    }

    /**
     * @dev sets the address of the oracle for the token ticker.
     *
     * Requirements:
     * `_oracleAddress` is the chainlink oracle address for price.
     * `_ticker` is the TICKER for the asset. Eg., BTC for Bitcoin.
     */
    function setOracle(address _oracleAddress, string memory _ticker)
        public
        virtual
        override
        onlyOwner
        returns (bool)
    {
        require(
            _oracleAddress != address(0),
            "PoS Error: oracle cannot be a zero address"
        );
        bytes memory ticker = bytes(_ticker);

        if (_oracles[ticker] == address(0)) {
            _oracles[ticker] = _oracleAddress;
            return true;
        } else {
            revert("PoS Error: oracle address already found");
        }
    }

    /**
     * @dev sets the address of the contract for token ticker.
     *
     * Requirements:
     * `_ticker` is the TICKER of the asset.
     * `_contractAddress` is the address of the token smart contract.
     * `_contractAddress` should follow BEP20/ERC20 standards.
     *
     * @return bool representing the status of the transaction.
     */
    function setContract(address _contractAddress, string memory _ticker)
        public
        virtual
        override
        onlyOwner
        returns (bool)
    {
        require(
            _contractAddress != address(0),
            "PoS Error: contract cannot be a zero address"
        );
        bytes memory ticker = bytes(_ticker);

        if (_contracts[ticker] == address(0)) {
            _contracts[ticker] = _contractAddress;
            return true;
        } else {
            revert("PoS Error: contract already initialized.");
        }
    }

    /**
     * @dev replace the oracle for an existing ticker.
     *
     * Requirements:
     * `_newOracle` is the chainlink oracle source that's changed.
     * `_ticker` is the TICKER of the asset.
     */
    function replaceOracle(address _newOracle, string memory _ticker)
        public
        virtual
        override
        onlyOwner
        returns (bool)
    {
        require(
            _newOracle != address(0),
            "PoS Error: oracle cannot be a zero address"
        );
        bytes memory ticker = bytes(_ticker);

        if (_oracles[ticker] != address(0)) {
            _oracles[ticker] = _newOracle;
            return true;
        } else {
            revert("PoS Error: set oracle to replace.");
        }
    }

    /**
     * @dev sets the address of the contract for token ticker.
     *
     * Requirements:
     * `_ticker` is the TICKER of the asset.
     * `_contractAddress` is the address of the token smart contract.
     * `_contractAddress` should follow BEP20/ERC20 standards.
     *
     * @return bool representing the status of the transaction.
     */
    function replaceContract(address _newAddress, string memory _ticker)
        public
        virtual
        override
        onlyOwner
        returns (bool)
    {
        require(
            _newAddress != address(0),
            "PoS Error: contract cannot be a zero address"
        );
        bytes memory ticker = bytes(_ticker);

        if (_contracts[ticker] != address(0)) {
            _contracts[ticker] = _newAddress;
            return true;
        } else {
            revert("PoS Error: contract not initialized yet.");
        }
    }

    /**
     * @dev marks a specific asset as stablecoin.
     *
     * Requirements:
     * `_ticker` - TICKER of the token that's contract address is already configured.
     *
     * @return bool representing the status of the transaction.
     */
    function markAsStablecoin(string memory _ticker)
        public
        virtual
        override
        Available(_ticker)
        onlyOwner
        returns (bool)
    {
        _isStable[bytes(_ticker)] = 1;
        return true;
    }

    /**
     * @dev processes all payments inside smart contracts.
     *
     * Requirements:
     * `_ticker` is the name of token to be processed.
     * `_usd` is the USD amount in 8-decimal.
     */
    function payment(
        string memory _pointer,
        string memory _ticker,
        string memory _notes,
        uint256 _usd
    ) public virtual returns (bool, uint256) {
        address merchant = IMerchant(merchantOracle).pointerAddress(_pointer);
        require(merchant != address(0), "PoS Error: Invalid Merchant Address");
        if (_isStable[bytes(_ticker)] == 1) {
            return sPayment(merchant, _ticker, _usd, _notes);
        } else {
            return tPayment(merchant, _ticker, _usd, _notes);
        }
    }

    /**
     * @dev process payments for stablecoins.
     *
     * Requirements:
     * `_ticker` is the name of the token to be processed.
     * `_usd` is the amount of USD to be processed in 8-decimals.
     *
     * 1 Stablecoin is considered as 1 USD.
     */
    function sPayment(
        address _merchant,
        string memory _ticker,
        uint256 _usd,
        string memory _notes
    )
        internal
        virtual
        Available(_ticker)
        Stablecoin(_ticker)
        returns (bool, uint256)
    {
        uint256 tokens = sAmount(_ticker, _usd);
        address spender = _msgSender();
        address contractAddress = _contracts[bytes(_ticker)];
        require(
            fetchApproval(_ticker, spender) >= tokens,
            "PoS Error: insufficient allowance for spender"
        );
        emit Payment(spender, _merchant, tokens, _ticker, _notes);
        return (
            IERC20(contractAddress).transferFrom(spender, _merchant, tokens),
            tokens
        );
    }

    function sAmount(string memory _ticker, uint256 _usd)
        public
        view
        virtual
        returns (uint256)
    {
        address contractAddress = _contracts[bytes(_ticker)];
        uint256 decimals = IERC20(contractAddress).decimals();
        if (decimals > 8) {
            return _usd * 10**(decimals - 8);
        } else {
            return _usd / 10**(8 - decimals);
        }
    }

    /**
     * @dev process payments for tokens.
     *
     * Requirements:
     * `_ticker` of the token.
     * `_usd` is the amount of USD to be processed.
     *
     * Price of token is fetched from Chainlink.
     */
    function tPayment(
        address _merchant,
        string memory _ticker,
        uint256 _usd,
        string memory _notes
    ) internal virtual Available(_ticker) returns (bool, uint256) {
        uint256 amount = tAmount(_ticker, _usd);
        address user = _msgSender();

        require(
            fetchApproval(_ticker, user) >= amount,
            "PoS Error: Insufficient Approval"
        );
        address contractAddress = _contracts[bytes(_ticker)];
        emit Payment(user, _merchant, amount, _ticker, _notes);
        return (
            IERC20(contractAddress).transferFrom(user, _merchant, amount),
            amount
        );
    }

    /**
     * @dev checks the approval value of each token.
     *
     * Requirements:
     * `_ticker` is the name of the token to check approval.
     * '_holder` is the address of the account to be processed.
     *
     * @return the approval of any stablecoin in 18-decimal.
     */
    function fetchApproval(string memory _ticker, address _holder)
        public
        view
        returns (uint256)
    {
        address contractAddress = _contracts[bytes(_ticker)];
        return IERC20(contractAddress).allowance(_holder, address(this));
    }

    /**
     * @dev resolves the amount of tokens to be paid for the amount of usd.
     *
     * Requirements:
     * `_ticker` represents the token to be accepted for payments.
     * `_usd` represents the value in USD.
     */
    function tAmount(string memory _ticker, uint256 _usd)
        public
        view
        returns (uint256)
    {
        uint256 value = _usd * 10**18;
        uint256 price = fetchOraclePrice(_ticker);

        address contractAddress = _contracts[bytes(_ticker)];
        uint256 decimal = IERC20(contractAddress).decimals();

        require(decimal <= 18, "PoS Error: asset class cannot be supported");
        uint256 decimalCorrection = 18 - decimal;

        uint256 tokensAmount = value / price;
        return tokensAmount / 10**decimalCorrection;
    }

    /**
     * @dev returns the contract address.
     */
    function fetchContract(string memory _ticker)
        public
        view
        returns (address)
    {
        return _contracts[bytes(_ticker)];
    }

    /**
     * @dev returns the latest round price from chainlink oracle.
     *
     * Requirements:
     * `_oracleAddress` the address of the oracle.
     *
     * @return the current latest price from the oracle.
     */
    function fetchOraclePrice(string memory _ticker)
        private
        view
        returns (uint256)
    {
        address oracleAddress = _oracles[bytes(_ticker)];
        (, int256 price, , , ) = IAggregatorV3(oracleAddress).latestRoundData();
        return uint256(price);
    }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;

/**
 * SC for handling payments outside of the marketplace SC.
 *
 * Provides flexibility for handling new payment methods in future.
 * Handles payments now in BNB, ADA, ETH & StableCoins.
 *
 * All prices are handles as 8-decimal irrespective of oracle source.
 */

interface IProcessPayments {
    /**
     * @dev sets the address of the oracle for the token ticker for the first time.
     *
     * Requirements:
     * `_oracleAddress` is the chainlink oracle address for price.
     * `_ticker` is the TICKER for the asset. Eg., BTC for Bitcoin.
     */
    function setOracle(address _oracleAddress, string memory _ticker)
        external
        returns (bool);

    /**
     * @dev sets the address of the contract for token ticker.
     *
     * Requirements:
     * `_ticker` is the TICKER of the asset.
     * `_contractAddress` is the address of the token smart contract.
     * `_contractAddress` should follow BEP20/ERC20 standards.
     *
     * @return bool representing the status of the transaction.
     */
    function setContract(address _contractAddress, string memory _ticker)
        external
        returns (bool);

    /**
     * @dev replace the address of the oracle for the token ticker.
     *
     * Requirements:
     * `_newOracle` is the chainlink oracle address for price.
     * `_ticker` is the TICKER for the asset. Eg., BTC for Bitcoin.
     */
    function replaceOracle(address _newOracle, string memory _ticker)
        external
        returns (bool);

    /**
     * @dev replaces the address of an existing contract for token ticker.
     *
     * Requirements:
     * `_ticker` is the TICKER of the asset.
     * `_contractAddress` is the address of the token smart contract.
     * `_contractAddress` should follow BEP20/ERC20 standards.
     *
     * @return bool representing the status of the transaction.
     */
    function replaceContract(address _newAddress, string memory _ticker)
        external
        returns (bool);

    /**
     * @dev marks a specific asset as stablecoin.
     *
     * Requirements:
     * `_ticker` - TICKER of the token that's contract address is already configured.
     *
     * @return bool representing the status of the transaction.
     */
    function markAsStablecoin(string memory _ticker) external returns (bool);

    // /**
    //  * @dev process payments for stablecoins.
    //  *
    //  * Requirements:
    //  * `_ticker` is the name of the token to be processed.
    //  * `_usd` is the amount of USD to be processed in 8-decimals.
    //  *
    //  * @return bool representing the status of payment.
    //  * uint256 representing the amount of tokens processed.
    //  */
    // function sPayment(string memory _ticker, uint256 _usd) external returns (bool, uint256);

    // /**
    //  * @dev process payments for ERC20 tokens.
    //  *
    //  * Requirements:
    //  * `_ticker` is the name of the token to be processed.
    //  * `_usd` is the amount of USD to be processed in 8-decimals.
    //  *
    //  * @return bool representing the status of payment.
    //  * uint256 representing the amount of tokens processed.
    //  */
    // function tPayment(string memory _ticker, uint256 _usd) external returns (bool, uint256);
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.4;

interface IMerchant {
    function register(string memory _pointer, string memory _hash)
        external
        returns (bool);

    function merchantInfo(address _query)
        external
        view
        returns (
            address,
            bytes memory,
            bytes memory
        );

    function pointerAddress(string memory _pointer)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;

interface IAggregatorV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;

/**
 * Interface of ZNFT Shares ERC20 Token As in EIP
 */

interface IERC20 {
    /**
     * @dev returns the name of the token
     */
    function name() external view returns (string memory);

    /**
     * @dev returns the symbol of the token
     */
    function symbol() external view returns (string memory);

    /**
     * @dev returns the decimal places of a token
     */
    function decimals() external view returns (uint8);

    /**
     * @dev returns the total tokens in existence
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev returns the tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev transfers the `amount` of tokens from caller's account
     * to the `recipient` account.
     *
     * returns boolean value indicating the operation status.
     *
     * Emits a {Transfer} event
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev returns the remaining number of tokens the `spender' can spend
     * on behalf of the owner.
     *
     * This value changes when {approve} or {transferFrom} is executed.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev sets `amount` as the `allowance` of the `spender`.
     *
     * returns a boolean value indicating the operation status.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev transfers the `amount` on behalf of `spender` to the `recipient` account.
     *
     * returns a boolean indicating the operation status.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address spender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted from tokens are moved from one account('from') to another account ('to)
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when allowance of a `spender` is set by the `owner`
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;

/**
 * @dev provides information about the current execution context.
 *
 * This includes the sender of the transaction & it's data.
 * Useful for meta-transaction as the message sender & gas payer can be different.
 */

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;

import "./Context.sol";

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;

        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev returns the current owner of the SC.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws error if the function is called by account other than owner
     */
    modifier onlyOwner() {
        require(_msgSender() == owner(), "Ownable: caller not owner");
        _;
    }

    /**
     * @dev Leaves the contract without any owner.
     *
     * It will be impossible to call onlyOwner Functions.
     * NOTE: use with caution.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(owner(), address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`)
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner cannot be zero address"
        );
        address msgSender = _msgSender();

        emit OwnershipTransferred(msgSender, newOwner);
        _owner = newOwner;
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}