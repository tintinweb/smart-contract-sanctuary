// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./external/util/Initializable.sol";
import "./interfaces/IProjectFactory.sol";
import "./interfaces/IProject.sol";
import "./interfaces/IERC20Decimals.sol";
import "./CWToken.sol";
import "./ProjectBase.sol";
import { DataTypes } from "./DataTypes.sol";

////////////////////////////////////////////////////////////////////////////////////////////
/// @title Project
/// @author @ace-contributor, @eratos
/// @notice project contract
////////////////////////////////////////////////////////////////////////////////////////////

contract Project is ProjectBase, IProject, Initializable {
    using Clones for address;
    using SafeERC20 for IERC20;
    using DataTypes for DataTypes.MetaData;

    /// @dev latest funding synced time;
    uint256 private lastFundingSyncTime;

    /// @dev epoch to sync funding;
    uint256 private fundingEpoch = 13000;

    /// @notice used for no-reentrancy of withdraw
    bool public override lockedWithdraw;

    /// @notice display project funding is successed
    bool public override funded;

    /// @notice project threshold
    uint256 public override threshold;

    /// @notice project deadline
    uint256 public override deadline;

    /// @notice project fee for curators
    uint256 public override curatorFee;

    /// @notice project total funded amount;
    uint256 public override totalFunding;

    /// @notice project BToken for backers
    mapping(address => address) public override getBToken;

    /// @notice project CToken for curators;
    mapping(address => address) public override getCToken;

    /// @dev setup a vault
    constructor() {}

    /// @notice initizlie
    function initialize(
        DataTypes.MetaData memory _metaData,
        address[] memory _tokens,
        address[] memory _nominations,
        uint256 _threshold,
        uint256 _deadline,
        uint256 _curatorFee
        
    ) public override initializer returns (bool) {
        metaData = _metaData;
        threshold = _threshold;
        deadline = _deadline;
        curatorFee = _curatorFee;

        _addNominations(_nominations);
        _addAcceptedTokens(_tokens);
        return true;
    }

    function getAcceptedTokens() public view override returns(address[] memory) {
        return acceptedTokens;
    }

    /// @dev sync funding
    function _syncFunding() internal {
        totalFunding = 0;
        uint256 length = acceptedTokens.length;
        for (uint256 i = 0; i < length; i++) {
            address token = acceptedTokens[i]; // each accepted token address
            uint256 totalSupply = IERC20(getBToken[token]).totalSupply();
            if (totalSupply > 0) {
                totalFunding +=
                    (totalSupply *
                        IProjectFactory(metaData.factory)
                        .priceOralceAggregator()
                        .getPriceInUSD(token)) /
                    (10**IERC20Decimals(getBToken[token]).decimals());
            }
        }
        lastFundingSyncTime = block.timestamp;
    }

    /// @dev add funnding to totalFunding
    function addFunding(address _token, uint256 amount) internal {
        if (block.timestamp - lastFundingSyncTime >= fundingEpoch) {
            _syncFunding();
        } else {
            totalFunding +=
                (amount *
                    IProjectFactory(metaData.factory)
                    .priceOralceAggregator()
                    .getPriceInUSD(_token)) /
                (10**IERC20Decimals(getBToken[_token]).decimals());
        }
        if (totalFunding >= threshold) {
            funded = true;
            emit Succeeded();
        }
    }

    /// @dev backers deposit ETH and receive BETH as BTokens
    function backWithETH()
        external
        payable
        override
        onlyAcceptedToken(ETH_ADDRESS)
        onlyActiveProject
        returns (bool)
    {
        require(msg.value > 0, "PJ: INVALID_BACKING_AMOUNT");

        // bToken mints the same amount of the token to the msg.sender
        CWToken(getBToken[ETH_ADDRESS]).mint(msg.sender, msg.value);

        // increment funding amounts from backer and for total
        addFunding(ETH_ADDRESS, msg.value);

        emit Deposit(msg.sender, ETH_ADDRESS, msg.value);

        return true;
    }

    /// @notice backers depsoit ERC20 tokens and receive BTokens
    /// @param _token address to backing token
    /// @param _value backing amount
    function back(address _token, uint256 _value)
        external
        override
        onlyAcceptedToken(_token)
        onlyActiveProject
        returns (bool)
    {
        require(_value > 0, "PJ: INVALID_BACKING_AMOUNT");
        require(_token != address(0), "PJ: INVALID_TOKEN");

        // deposit _value to backing deposit address
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _value);
        // mints the same amount of _token to the msg.sender
        CWToken(getBToken[_token]).mint(msg.sender, _value);
        // increment funding amounts from backer and for total
        addFunding(_token, _value);

        emit Deposit(msg.sender, _token, _value);
        return true;
    }

    /// @notice curators deposit ETH and receive CETH as CTokens
    function curateWithETH()
        external
        payable
        override
        onlyAcceptedToken(ETH_ADDRESS)
        onlyActiveProject
        returns (bool)
    {
        require(msg.value > 0, "PJ: INVALID_CURATING_AMOUNT");
        require(!funded, "PJ: FUNDED_PROJECT");

        // re-sync the funding and return curated ETH, if funded
        addFunding(ETH_ADDRESS, 0);
        if (funded) {
            safeTransferETH(payable(msg.sender), msg.value);
            return false;
        }

        // bToken mints the same amount of the token to the msg.sender
        CWToken(getCToken[ETH_ADDRESS]).mint(msg.sender, msg.value);

        emit Curate(msg.sender, ETH_ADDRESS, msg.value);
        return true;
    }

    /// @notice backers deposit ERC20 tokens and receive CTokens
    function curate(address _token, uint256 _value)
        external
        override
        onlyAcceptedToken(_token)
        onlyActiveProject
        returns (bool)
    {
        require(_value > 0, "PJ: INVALID_CURATING_AMOUNT");
        require(_token != address(0), "PJ: INVALID_TOKEN");
        require(!funded, "PJ: FUNDED_PROJECT");

        // re-sync the funding and stop it, if funded
        addFunding(_token, 0);
        if (funded) {
            return false;
        }

        // deposit _token to the Project
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _value);
        // mints the same amount of _token to the msg.sender
        CWToken(getCToken[_token]).mint(msg.sender, _value);

        emit Curate(msg.sender, _token, _value);
        return true;
    }

    /// @dev withdraw all funds to the beneficiary
    function withdraw()
        public
        override
        noRewithdraw
        onlyFinishedProject
        returns (bool)
    {
        require(funded, "PJ: NOT_FUNDED");

        uint256 length = acceptedTokens.length;
        uint256 protocolFee = IProjectFactory(metaData.factory).getProtocolData().protocolFee;
        uint256 withdrawPercent = 10000 - curatorFee - protocolFee;
        address payable protocolFeeTo = IProjectFactory(metaData.factory).getProtocolData().feeTo;

        for (uint256 i = 0; i < length; i++) {
            address token = acceptedTokens[i]; // each accepted token address
            uint256 amount = IERC20(getBToken[token]).totalSupply();

            if (amount > 0) {
                // withdraw only available amount of the token
                uint256 withdrawAmount = (amount * withdrawPercent) / 10000;
                // send protocol fee to protocol
                uint256 protocolFeeAmount = (amount * protocolFee) / 10000;

                if (token == ETH_ADDRESS) {
                    bool sent = safeTransferETH(metaData.beneficiary, withdrawAmount);
                    bool sent_ = safeTransferETH(
                        protocolFeeTo,
                        protocolFeeAmount
                    );
                    require(sent && sent_, "PJ: ETH_WITHDRAW_FAILED");
                } else {
                    safeTransferToken(token, metaData.beneficiary, withdrawAmount);
                    safeTransferToken(token, protocolFeeTo, protocolFeeAmount);
                }
            }
        }

        emit Withdraw(metaData.beneficiary, (totalFunding * withdrawPercent) / 10000);
        return true;
    }

    /// @notice backers redeem their BTokens when projectFunding is failed
    /// @dev burn bTokens and backer receive "donated funds" + "bonus from the curators funds"
    /// @param _token redeem token
    /// @param _amount redeem amount
    function redeemBToken(address _token, uint256 _amount)
        public
        override
        onlyAcceptedToken(_token)
        onlyFinishedProject
        returns (bool)
    {
        require(_amount > 0, "PJ: INVALID_REDEEM_AMOUNT");
        require(!funded, "PJ: FUNDED_PROJECT");
        require(_token != address(0), "PJ: INVALID_TOKEN");

        address bToken = getBToken[_token];
        require(
            IERC20(bToken).balanceOf(msg.sender) >= _amount,
            "PJ: Redeem amount exceeds backed balance"
        );

        // Calculate the Backed Percent
        uint256 funding = (_amount *
            IProjectFactory(metaData.factory).priceOralceAggregator().getPriceInUSD(
                _token
            )) / (10**IERC20Decimals(bToken).decimals());
        uint256 restTotalFunding;
        uint256 length = acceptedTokens.length;

        for (uint256 i = 0; i < length; i++) {
            address token = acceptedTokens[i]; // each accepted token address
            uint256 totalSupply = IERC20(getBToken[token]).totalSupply();

            if (totalSupply > 0) {
                restTotalFunding +=
                    (totalSupply *
                        IProjectFactory(metaData.factory)
                        .priceOralceAggregator()
                        .getPriceInUSD(token)) /
                    (10**IERC20Decimals(getBToken[token]).decimals());
            }
        }

        // Burn BToken
        CWToken(bToken).burnFrom(msg.sender, _amount);

        // Redeem Backed Amount
        address payable protocolFeeTo = IProjectFactory(metaData.factory).getProtocolData().feeTo;

        uint256 redeemPercent = 10000 -
            (IProjectFactory(metaData.factory).getProtocolData().protocolFee);
        uint256 backedAmount = (_amount * redeemPercent) / 10000;
        uint256 protocolFeeAmount = _amount - backedAmount;

        if (_token == ETH_ADDRESS) {
            bool sent = safeTransferETH(payable(msg.sender), backedAmount);
            bool sent_ = safeTransferETH(protocolFeeTo, protocolFeeAmount);
            require(sent && sent_, "PJ: REDEEM_ETH_FAILED");
        } else {
            safeTransferToken(_token, msg.sender, backedAmount);
            safeTransferToken(_token, protocolFeeTo, protocolFeeAmount);
        }

        // Redeem Bonus Amount
        for (uint256 i = 0; i < length; i++) {
            address token = acceptedTokens[i]; // each accepted token address
            if (token == ETH_ADDRESS) {
                uint256 bonusAmount = ((address(this).balance -
                    IERC20(getBToken[token]).totalSupply()) * funding) /
                    restTotalFunding;
                if (bonusAmount > 0) {
                    bool sent = safeTransferETH(
                        payable(msg.sender),
                        bonusAmount
                    );
                    require(sent, "PJ: REDEEM_ETH_FAILED");
                }
            } else {
                uint256 bonusAmount = (((IERC20(token).balanceOf(
                    address(this)
                ) - IERC20(getBToken[token]).totalSupply()) * funding) /
                    restTotalFunding);
                if (bonusAmount > 0) {
                    safeTransferToken(token, msg.sender, bonusAmount);
                }
            }
        }

        return true;
    }

    /// @notice curators redeem their CTokens when projectFunding is successed
    /// @dev burn bTokens and curator receive "donated funds" + "curatorFee as bonus"
    /// @param _token redeem token
    /// @param _amount redeem amount
    function redeemCToken(address _token, uint256 _amount)
        public
        override
        onlyAcceptedToken(_token)
        onlyFinishedProject
        returns (bool)
    {
        require(_amount > 0, "PJ: INVALID_REDEEM_AMOUNT");
        require(funded, "PJ: NOT_FUNDED_PROJECT");
        require(_token != address(0), "PJ: INVALID_TOKEN");

        address cToken = getCToken[_token];
        require(
            IERC20(cToken).balanceOf(msg.sender) >= _amount,
            "PJ: AMOUNT_EXCEEDS_CURATED"
        );

        // Calculate the Curated Percent
        uint256 curating = (_amount *
            IProjectFactory(metaData.factory).priceOralceAggregator().getPriceInUSD(
                _token
            )) / (10**IERC20Decimals(cToken).decimals());
        uint256 restTotalCurating;
        uint256 length = acceptedTokens.length;

        for (uint256 i = 0; i < length; i++) {
            address token = acceptedTokens[i]; // each accepted token address
            uint256 totalSupply = IERC20(getCToken[token]).totalSupply();

            if (totalSupply > 0) {
                restTotalCurating +=
                    (totalSupply *
                        IProjectFactory(metaData.factory)
                        .priceOralceAggregator()
                        .getPriceInUSD(token)) /
                    (10**IERC20Decimals(getCToken[token]).decimals());
            }
        }

        // Burn CToken
        CWToken(cToken).burnFrom(msg.sender, _amount);

        // Redeem Curated Amount
        if (_token == ETH_ADDRESS) {
            bool sent = safeTransferETH(payable(msg.sender), _amount);
            require(sent, "PJ: REDEEM_ETH_FAILED");
        } else {
            safeTransferToken(_token, msg.sender, _amount);
        }

        // Redeem Bonus Amount
        for (uint256 i = 0; i < length; i++) {
            address token = acceptedTokens[i]; // each accepted token address
            uint256 withdrawAmount = 0;
            if (!lockedWithdraw) {
                withdrawAmount =
                    (IERC20(getBToken[token]).totalSupply() *
                        (10000 - curatorFee)) /
                    (10000);
            }

            if (token == ETH_ADDRESS) {
                uint256 bonusAmount = ((address(this).balance -
                    IERC20(getCToken[token]).totalSupply() -
                    withdrawAmount) * curating) / restTotalCurating;
                if (bonusAmount > 0) {
                    bool sent = safeTransferETH(
                        payable(msg.sender),
                        bonusAmount
                    );
                    require(sent, "PJ: REDEEM_ETH_FAILED");
                }
            } else {
                uint256 bonusAmount = ((IERC20(token).balanceOf(address(this)) -
                    IERC20(getCToken[token]).totalSupply() -
                    withdrawAmount) * curating) / restTotalCurating;
                if (bonusAmount > 0) {
                    safeTransferToken(token, msg.sender, bonusAmount);
                }
            }
        }

        return true;
    }

    function _mintFee(uint256 _amount) private returns (bool feeOn) {
        /// To be discussed: _minFee is needed in Project?
    }

    /// @dev add accepted Token
    function _addAcceptedTokens(address[] memory _tokens) internal {
        uint256 length = _tokens.length;
        require(length > 0, "PJ: NO_ACCEPTED_TOKEN");

        for (uint256 i = 0; i < length; i++) {
            require(_tokens[i] != address(0), "PJ: INVALID_TOKEN");

            if (!isAcceptedToken[_tokens[i]]) {
                isAcceptedToken[_tokens[i]] = true;
                acceptedTokens.push(_tokens[i]);

                bytes32 bTokenSalt = keccak256(
                    abi.encodePacked(
                        metaData.name,
                        metaData.ipfsHash,
                        metaData.cwUrl,
                        "BToken",
                        _tokens[i]
                    )
                );
                address bToken = IProjectFactory(metaData.factory)
                    .getProtocolData()
                    .cwTokenImp
                    .cloneDeterministic(bTokenSalt);
                CWToken(bToken).initialize(_tokens[i], true);
                getBToken[_tokens[i]] = bToken;

                bytes32 cTokenSalt = keccak256(
                    abi.encodePacked(
                        metaData.name,
                        metaData.ipfsHash,
                        metaData.cwUrl,
                        "CToken",
                        _tokens[i]
                    )
                );
                address cToken = IProjectFactory(metaData.factory)
                    .getProtocolData()
                    .cwTokenImp
                    .cloneDeterministic(cTokenSalt);
                CWToken(cToken).initialize(_tokens[i], false);
                getCToken[_tokens[i]] = cToken;
            }
        }
    }

    /// @notice remove nominations
    function removeNominations(address[] memory _nominations)
        external
        onlyCreator
    {
        _removeNominations(_nominations);
    }

    modifier onlyAcceptedToken(address _token) {
        require(isAcceptedToken[_token], "PJ: NOT_ACCEPTED_TOKEN");
        _;
    }

    modifier onlyActiveProject() {
        require(block.timestamp < deadline, "PJ: DEADLINE_PASSED");
        _;
    }

    modifier onlyFinishedProject() {
        require(block.timestamp >= deadline, "PJ: NOT_FINISHED");
        _;
    }

    modifier noRewithdraw() {
        require(!lockedWithdraw, "PJ: RE_WITHDRAW");
        lockedWithdraw = true;
        _;
    }

    /// @dev transfer ethereum by checking the balance
    function safeTransferETH(address payable _to, uint256 _amount)
        internal
        returns (bool sent)
    {
        uint256 balance = address(this).balance;
        uint256 amount = _amount;

        if (balance < amount) {
            amount = balance;
        }

        (sent, ) = _to.call{value: amount}("");
    }

    /// @dev transfer token by checking the balance
    function safeTransferToken(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        uint256 amount = _amount;

        if (balance < amount) {
            amount = balance;
        }

        IERC20(_token).safeTransfer(_to, amount);
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(
            _initializing || _isConstructor() || !_initialized,
            "Initializable: contract is already initialized"
        );

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPriceOracleAggregator.sol";
import { DataTypes } from "../DataTypes.sol";

interface IProjectFactory {
    event ProjectCreation(bytes32 projectHash, address project);

    function owner() external view returns (address);
    function getProtocolData() external view returns (DataTypes.ProtocolData memory);

    function setFeeTo(address payable _feeTo) external;
    function setProtocolFee(uint256 _protocolFee) external;
    function setCWTokenImpl(address _cwToken) external;
    
    function projectImp() external view returns (address);
    function setProjectImpl(address _projectImpl) external;

    function allProjects(uint) external view returns (address);
    function getAllProjects() external view returns(address[] memory);

    function acceptedTokens(uint) external view returns (address);
    function getAllAcceptedTokens() external view returns(address[] memory);

    function priceOralceAggregator() external view returns (IPriceOracleAggregator);
    function isAcceptedToken(address _token) external view returns (bool);
    function addAcceptedTokens(address[] memory _tokens) external;

    function createProject(
        bytes32 _name,
        bytes32 _ipfsHash,
        bytes32 _cwUrl,
        address payable _beneficiary,
        address[] memory _acceptedTokens,
        address[] memory _nominations,
        uint256 _threshold,
        uint256 _deadline,
        uint256 _curatorFee
    ) external returns (address project);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { DataTypes } from "../DataTypes.sol";

interface IProject {
    event Deposit(address sender, address token, uint256 amount);
    event Curate(address sender, address token, uint256 amount);
    event Withdraw(address sender, uint256 amount);
    event Succeeded();
    event Failed();

    function lockedWithdraw() external view returns(bool);
    function funded() external view returns (bool);
    function totalFunding() external view returns (uint256);
    function threshold() external view returns (uint256); // backing threshold in native token
    function deadline() external view returns (uint256); // deadline in blocktime
    function curatorFee() external view returns (uint256);

    function getBToken(address _token) external view returns (address);
    function getCToken(address _token) external view returns (address);
    function getAcceptedTokens() external view returns(address[] memory);

    function initialize(
        DataTypes.MetaData memory _metaData,
        address[] memory _acceptedTokens,
        address[] memory _nominations,
        uint256 _threshold,
        uint256 _deadline,
        uint256 _curatorFee
    ) external returns (bool);

    function backWithETH() external payable returns (bool);
    function back(address _token, uint256 _value) external returns (bool);
    function curateWithETH() external payable returns (bool);
    function curate(address _token, uint256 _value) external returns (bool);
    function withdraw() external returns (bool);
    function redeemBToken(address _token, uint256 _valueToRemove) external returns (bool);
    function redeemCToken(address _token, uint256 _valueToRemove) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20Decimals {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./external/token/ERC20Burnable.sol";
import "./external/token/ERC20.sol";

////////////////////////////////////////////////////////////////////////////////////////////
/// @title CWToken
/// @author @ace-contributor, @eratos
/// @notice ?? more accurate description
////////////////////////////////////////////////////////////////////////////////////////////

contract CWToken is ERC20, ERC20Burnable {
    /// @dev Ethereum address
    address internal constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /// @notice initialize
    function initialize(address _token, bool _isBToken) external {
        require(_token != address(0), "CWT: INVALID_TOKEN");

        string memory tokenName = string(
            abi.encodePacked(
                "CW ",
                _isBToken ? "B" : "C",
                _token == ETH_ADDRESS ? "Ethereum" : ERC20(_token).name(),
                " Token"
            )
        );

        string memory tokenSymbol = string(
            abi.encodePacked(
                _isBToken ? "B" : "C",
                _token == ETH_ADDRESS ? "ETH" : ERC20(_token).symbol()
            )
        );

        uint8 tokenDecimals = _token == ETH_ADDRESS
            ? 18
            : ERC20(_token).decimals();

        initializeERC20(tokenName, tokenSymbol, tokenDecimals);
    }

    /// @notice mint
    function mint(address _owner, uint256 _amount) external {
        _mint(_owner, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { DataTypes } from "./DataTypes.sol";

////////////////////////////////////////////////////////////////////////////////////////////
/// @title ProjectBase
/// @author @ace-contributor
/// @notice will be used for both Project and Collectives
////////////////////////////////////////////////////////////////////////////////////////////

abstract contract ProjectBase {
    event Nominated(uint256 projectId, address addr);

    using DataTypes for DataTypes.MetaData;

    /// @notice metaData
    DataTypes.MetaData public metaData;

    /// @notice project accepted tokens;
    address[] public acceptedTokens;

    /// @notice mapping bool to return if token is accepted by this project
    mapping(address => bool) public isAcceptedToken;

    /// @notice mapping bool to return if nominated
    mapping(address => bool) public isNominationed;

    /// @dev Ethereum address
    address internal constant ETH_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /// @notice set project Name
    function setName(bytes32 _name) external onlyCreator {
        metaData.name = _name;
    }

    /// @notice set project ipfsHash
    function setIpfsHash(bytes32 _ipfsHash) external onlyCreator {
        metaData.ipfsHash = _ipfsHash;
    }

    /// @notice set project CW url
    function setCwUrl(bytes32 _cwUrl) external onlyCreator {
        metaData.cwUrl = _cwUrl;
    }

    /// @notice set project Beneficary
    function setBeneficiary(address payable _beneficiary) external onlyCreator {
        require(_beneficiary != address(0), "PJFAC: INVALID_BENEFICIARY");
        metaData.beneficiary = _beneficiary;
    }

    /// @notice add nominations
    function addNominations(address[] memory _nominations) external onlyCreator {
        _addNominations(_nominations);
    }

    /// @notice add nominations
    function _addNominations(address[] memory _nominations) internal {
        uint256 length = _nominations.length;
        for (uint256 i = 0; i < length; i++) {
            /// To be discussed: what else logic is required here?

            // push new _nomination to nominations array
            isNominationed[_nominations[i]] = true;

            // emit event with projectId and string of address
            emit Nominated(metaData.id, _nominations[i]); // @TODO: determine second param
        }
    }

    /// @notice remove nominations
    function _removeNominations(address[] memory _nominations) internal {
        for (uint256 i = 0; i < _nominations.length; i++) {
            require(isNominationed[_nominations[i]] == true);
            isNominationed[_nominations[i]] = false;
        }
    }

    modifier onlyCreator {
        require(msg.sender == metaData.creator);
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

////////////////////////////////////////////////////////////////////////////////////////////
/// @title DataTypes
/// @author @ace-contributor
////////////////////////////////////////////////////////////////////////////////////////////

library DataTypes {
    struct MetaData {
        bytes32 name;
        bytes32 ipfsHash;
        bytes32 cwUrl;
        address payable beneficiary;
        address creator;
        uint256 id;
        address factory;
        bytes32 hashBytes;
    }

    struct ProtocolData {
        address cwTokenImp;
        uint256 protocolFee;
        address payable feeTo;
        uint256 maxFee;
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IOracle.sol";

interface IPriceOracleAggregator {
    
    event UpdateOracle(address token, IOracle oracle);

    function getPriceInUSD(address _token) external returns (uint256);
    function updateOracleForAsset(address _asset, IOracle _oracle) external;
    function viewPriceInUSD(address _token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    /// @notice Price update event
    /// @param asset the asset
    /// @param newPrice price of the asset
    event PriceUpdated(address asset, uint256 newPrice);

    function getPriceInUSD() external returns (uint256);

    function viewPriceInUSD() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = _allowances[account][msg.sender];
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        _approve(account, msg.sender, currentAllowance - amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 *
 * !!! samparsky modified: use initializeERC20 to replace constructor for proxy
 */
contract ERC20 is IERC20 {
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _totalSupply;

    string public name;
    uint8 public decimals;
    string public symbol;

    function initializeERC20(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) internal {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    function _mint(address _account, uint256 _amount) internal virtual {
        require(_account != address(0), "ERC20: mint to the zero address");

        _totalSupply += _amount;
        _balances[_account] += _amount;
        emit Transfer(address(0), _account, _amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account] - amount;
        _totalSupply = _totalSupply - amount;
        emit Transfer(account, address(0), amount);
    }
}

