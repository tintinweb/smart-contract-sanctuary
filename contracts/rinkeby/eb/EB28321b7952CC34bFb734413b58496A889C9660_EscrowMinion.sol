// Based on https://github.com/HausDAO/MinionSummoner/blob/main/MinionFactory.sol
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.5;

interface IERC721 {
    // brief interface for minion erc721 token txs
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface IERC1155 {
    // brief interface for minion erc1155 token txs
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

interface IERC721Receiver {
    // Safely receive ERC721 tokens
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC1155PartialReceiver {
    // Safely receive ERC1155 tokens
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    // ERC1155 batch receive not implemented in this escrow contract
}

interface IMOLOCH {
    // brief interface for moloch dao v2

    function depositToken() external view returns (address);

    function tokenWhitelist(address token) external view returns (bool);

    function getProposalFlags(uint256 proposalId)
        external
        view
        returns (bool[6] memory);

    function members(address user)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            bool,
            uint256,
            uint256
        );

    function userTokenBalances(address user, address token)
        external
        view
        returns (uint256);

    function cancelProposal(uint256 proposalId) external;

    function submitProposal(
        address applicant,
        uint256 sharesRequested,
        uint256 lootRequested,
        uint256 tributeOffered,
        address tributeToken,
        uint256 paymentRequested,
        address paymentToken,
        string calldata details
    ) external returns (uint256);

    function withdrawBalance(address token, uint256 amount) external;
}

/// @title EscrowMinion - Token escrow for ERC20, ERC721, ERC1155 tokens tied to Moloch DAO proposals
/// @dev Ties arbitrary token escrow to a Moloch DAO proposal
///  Can be used to tribute tokens in exchange for shares, loot, or DAO funds
///
///  Any number and combinations of tokens can be escrowed
///  If any tokens become untransferable, the rest of the tokens in escrow can be released individually
///
///  If proposal passes, tokens become withdrawable to destination - usually a Gnosis Safe or Minion
///  If proposal fails, or cancelled before sponsorship, token become withdrawable to applicant
///
///  If any tokens become untransferable, the rest of the tokens in escrow can be released individually
///
/// @author Isaac Patka, Dekan Brown
contract EscrowMinion is
    IERC721Receiver,
    ReentrancyGuard,
    IERC1155PartialReceiver
{
    using Address for address; /*Address library provides isContract function*/
    using SafeERC20 for IERC20; /*SafeERC20 automatically checks optional return*/

    // Track token tribute type to use so we know what transfer interface to use
    enum TributeType {
        ERC20,
        ERC721,
        ERC1155
    }

    // Track the balance and withdrawl state for each token
    struct EscrowBalance {
        uint256[3] typesTokenIdsAmounts; /*Tribute type | ID (for 721, 1155) | Amount (for 20, 1155)*/
        address tokenAddress; /* Address of tribute token */
        bool executed; /* Track if this specific token has been withdrawn*/
    }

    // Store destination vault and proposer for each proposal
    struct TributeEscrowAction {
        address vaultAddress; /*Destination for escrow tokens - must be token receiver*/
        address proposer; /*Applicant address*/
    }

    mapping(address => mapping(uint256 => TributeEscrowAction)) public actions; /*moloch => proposalId => Action*/
    mapping(address => mapping(uint256 => mapping(uint256 => EscrowBalance)))
        public escrowBalances; /* moloch => proposal => token index => balance */
        
    /* 
    * Moloch proposal ID
    * Applicant addr
    * Moloch addr
    * escrow token addr
    * escrow token types
    * escrow token IDs (721, 1155)
    * amounts (20, 1155)
    * destination for escrow
    */
    event ProposeAction(
        uint256 proposalId,
        address proposer,
        address moloch,
        address[] tokens,
        uint256[] types,
        uint256[] tokenIds,
        uint256[] amounts,
        address destinationVault
    ); 
    event ExecuteAction(uint256 proposalId, address executor, address moloch);
    event ActionCanceled(uint256 proposalId, address moloch);

    // internal tracking for destinations to ensure escrow can't get stuck
    // Track if already checked so we don't do it multiple times per proposal
    mapping(TributeType => uint256) internal destinationChecked_;
    uint256 internal constant NOTCHECKED_ = 1;
    uint256 internal constant CHECKED_ = 2;

    /// @dev Construtor sets the status of the destination checkers
    constructor() {
        // Follow a similar pattern to reentency guard from OZ
        destinationChecked_[TributeType.ERC721] = NOTCHECKED_;
        destinationChecked_[TributeType.ERC1155] = NOTCHECKED_;
    }

    // Reset the destination checkers for the next proposal
    modifier safeDestination() {
        _;
        destinationChecked_[TributeType.ERC721] = NOTCHECKED_;
        destinationChecked_[TributeType.ERC1155] = NOTCHECKED_;
    }

    // Safely receive ERC721s
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    // Safely receive ERC1155s
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    /**
     * @dev internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param _operator address representing the entity calling the function
     * @param _from address representing the previous owner of the given token ID
     * @param _to target address that will receive the tokens
     * @param _tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address _operator,
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) internal returns (bool) {
        if (!_to.isContract()) {
            return true;
        }
        bytes memory _returndata = _to.functionCall(
            abi.encodeWithSelector(
                IERC721Receiver(_to).onERC721Received.selector,
                _operator,
                _from,
                _tokenId,
                _data
            ),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
        bytes4 _retval = abi.decode(_returndata, (bytes4));
        return (_retval == IERC721Receiver(_to).onERC721Received.selector);
    }

    /**
     * @dev internal function to invoke {IERC1155-onERC1155Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param _operator address representing the entity calling the function
     * @param _from address representing the previous owner of the given token ID
     * @param _to target address that will receive the tokens
     * @param _id uint256 ID of the token to be transferred
     * @param _amount uint256 amount of token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC1155Received(
        address _operator,
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) internal returns (bool) {
        if (!_to.isContract()) {
            return true;
        }
        bytes memory _returndata = _to.functionCall(
            abi.encodeWithSelector(
                IERC1155PartialReceiver(_to).onERC1155Received.selector,
                _operator,
                _from,
                _id,
                _amount,
                _data
            ),
            "ERC1155: transfer to non ERC1155Receiver implementer"
        );
        bytes4 _retval = abi.decode(_returndata, (bytes4));
        return (_retval ==
            IERC1155PartialReceiver(_to).onERC1155Received.selector);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on both vault & applicant
     * Ensures tokens cannot get stuck here due to interface issue
     *
     * @param _vaultAddress Destination for tokens on successful proposal
     * @param _applicantAddress Destination for tokens on failed proposal
     */
    function checkERC721Recipients(address _vaultAddress, address _applicantAddress) internal {
        require(
            _checkOnERC721Received(
                address(this),
                address(this),
                _vaultAddress,
                0,
                ""
            ),
            "!ERC721"
        );
        require(
            _checkOnERC721Received(
                address(this),
                address(this),
                _applicantAddress,
                0,
                ""
            ),
            "!ERC721"
        );
        // Mark 721 as checked so we don't check again during this tx
        destinationChecked_[TributeType.ERC721] = CHECKED_;
    }

    /**
     * @dev Internal function to invoke {IERC1155Receiver-onERC1155Received} on both vault & applicant
     * Ensures tokens cannot get stuck here due to interface issue
     *
     * @param _vaultAddress Destination for tokens on successful proposal
     * @param _applicantAddress Destination for tokens on failed proposal
     */
    function checkERC1155Recipients(address _vaultAddress, address _applicantAddress) internal {
        require(
            _checkOnERC1155Received(
                address(this),
                address(this),
                _vaultAddress,
                0,
                0,
                ""
            ),
            "!ERC1155"
        );
        require(
            _checkOnERC1155Received(
                address(this),
                address(this),
                _applicantAddress,
                0,
                0,
                ""
            ),
            "!ERC1155"
        );
        // Mark 1155 as checked so we don't check again during this tx
        destinationChecked_[TributeType.ERC1155] = CHECKED_;
    }

    /**
     * @dev Internal function to move token into or out of escrow depending on type
     * Only valid for 721, 1155, 20
     *
     * @param _tokenAddress Token to escrow
     * @param _typesTokenIdsAmounts Type: 0-20, 1-721, 2-1155 TokenIds: for 721, 1155 Amounts: for 20, 1155
     * @param _from Sender (applicant or this)
     * @param _to Recipient (this or applicant or destination)
     */
    function doTransfer(
        address _tokenAddress,
        uint256[3] memory _typesTokenIdsAmounts,
        address _from,
        address _to
    ) internal {
        // Use 721 interface for 721
        if (_typesTokenIdsAmounts[0] == uint256(TributeType.ERC721)) {
            IERC721 _erc721 = IERC721(_tokenAddress);
            _erc721.safeTransferFrom(_from, _to, _typesTokenIdsAmounts[1]);
        // Use 20 interface for 20
        } else if (_typesTokenIdsAmounts[0] == uint256(TributeType.ERC20)) {
            // Fail if attempt to send 0 tokens
            require(_typesTokenIdsAmounts[2] != 0, "!amount");
            IERC20 _erc20 = IERC20(_tokenAddress);
            if (_from == address(this)) {
                _erc20.safeTransfer(_to, _typesTokenIdsAmounts[2]);
            } else {
                _erc20.safeTransferFrom(_from, _to, _typesTokenIdsAmounts[2]);
            }
            // use 1155 interface for 1155
        } else if (_typesTokenIdsAmounts[0] == uint256(TributeType.ERC1155)) {
            // Fail if attempt to send 0 tokens
            require(_typesTokenIdsAmounts[2] != 0, "!amount");
            IERC1155 _erc1155 = IERC1155(_tokenAddress);
            _erc1155.safeTransferFrom(
                _from,
                _to,
                _typesTokenIdsAmounts[1],
                _typesTokenIdsAmounts[2],
                ""
            );
        } else {
            revert("Invalid type");
        }
    }

    /**
     * @dev Internal function to move token into escrow on proposal
     *
     * @param _molochAddress Moloch to read proposal data from
     * @param _tokenAddresses Addresses of tokens to escrow
     * @param _typesTokenIdsAmounts ERC20, 721, or 1155 | id for 721, 1155 | amount for 20, 1155
     * @param _vaultAddress Addresses of destination of proposal successful
     * @param _proposalId ID of Moloch proposal for this escrow
     */
    function processTributeProposal(
        address _molochAddress,
        address[] memory _tokenAddresses,
        uint256[3][] memory _typesTokenIdsAmounts,
        address _vaultAddress,
        uint256 _proposalId
    ) internal {
        
        // Initiate arrays to flatten 2d array for event
        uint256[] memory _types = new uint256[](_tokenAddresses.length);
        uint256[] memory _tokenIds = new uint256[](_tokenAddresses.length);
        uint256[] memory _amounts = new uint256[](_tokenAddresses.length);

        // Store proposal metadata
        actions[_molochAddress][_proposalId] = TributeEscrowAction({
            vaultAddress: _vaultAddress,
            proposer: msg.sender
        });
        
        // Store escrow data, check destinations, and do transfers
        for (uint256 _index = 0; _index < _tokenAddresses.length; _index++) {
            // Store withdrawable balances
            escrowBalances[_molochAddress][_proposalId][_index] = EscrowBalance({
                typesTokenIdsAmounts: _typesTokenIdsAmounts[_index],
                tokenAddress: _tokenAddresses[_index],
                executed: false
            });

            if (destinationChecked_[TributeType.ERC721] == NOTCHECKED_)
                checkERC721Recipients(_vaultAddress, msg.sender);
            if (destinationChecked_[TributeType.ERC1155] == NOTCHECKED_)
                checkERC1155Recipients(_vaultAddress, msg.sender);

            // Move tokens into escrow
            doTransfer(
                _tokenAddresses[_index],
                _typesTokenIdsAmounts[_index],
                msg.sender,
                address(this)
            );

            // Store in memory so they can be emitted in an event
            _types[_index] = _typesTokenIdsAmounts[_index][0];
            _tokenIds[_index] = _typesTokenIdsAmounts[_index][1];
            _amounts[_index] = _typesTokenIdsAmounts[_index][2];
        }
        emit ProposeAction(
            _proposalId,
            msg.sender,
            _molochAddress,
            _tokenAddresses,
            _types,
            _tokenIds,
            _amounts,
            _vaultAddress
        );
    }

    //  -- Proposal Functions --
    /**
     * @notice Creates a proposal and moves NFT into escrow
     * @param _molochAddress Address of DAO
     * @param _tokenAddresses Token contract address
     * @param _typesTokenIdsAmounts Token id.
     * @param _vaultAddress Address of DAO's NFT vault
     * @param _requestSharesLootFunds Amount of shares requested
     // add funding request token
     * @param _details Info about proposal
     */
    function proposeTribute(
        address _molochAddress,
        address[] calldata _tokenAddresses,
        uint256[3][] calldata _typesTokenIdsAmounts,
        address _vaultAddress,
        uint256[3] calldata _requestSharesLootFunds, // also request loot or treasury funds
        string calldata _details
    ) external nonReentrant safeDestination returns (uint256) {
        IMOLOCH _thisMoloch = IMOLOCH(_molochAddress); /*Initiate interface to relevant moloch*/
        address _thisMolochDepositToken = _thisMoloch.depositToken(); /*Get deposit token for proposals*/

        require(_vaultAddress != address(0), "invalid vaultAddress"); /*Cannot set destination to 0*/

        require(
            _typesTokenIdsAmounts.length == _tokenAddresses.length,
            "!same-length"
        );

        // Submit proposal to moloch for loot, shares, or funds in the deposit token
        uint256 _proposalId = _thisMoloch.submitProposal(
            msg.sender,
            _requestSharesLootFunds[0],
            _requestSharesLootFunds[1],
            0, // No ERC20 tribute directly to Moloch
            _thisMolochDepositToken,
            _requestSharesLootFunds[2],
            _thisMolochDepositToken,
            _details
        );

        processTributeProposal(
            _molochAddress,
            _tokenAddresses,
            _typesTokenIdsAmounts,
            _vaultAddress,
            _proposalId
        );

        return _proposalId;
    }

    /**
     * @notice Internal function to move tokens to destination ones it can be processed or has been cancelled
     * @param _molochAddress Address of DAO
     * @param _tokenIndices Indices in proposed tokens array - have to specify this so frozen tokens cant make the whole payload stuck
     * @param _destination Address of DAO's NFT vault or Applicant if failed/ cancelled
     * @param _proposalId Moloch proposal ID
     */
    function processWithdrawls(
        address _molochAddress,
        uint256[] calldata _tokenIndices, // only withdraw indices in this list
        address _destination,
        uint256 _proposalId
    ) internal {
        for (uint256 _index = 0; _index < _tokenIndices.length; _index++) {
            // Retrieve withdrawable balances
            EscrowBalance storage _escrowBalance = escrowBalances[_molochAddress][
                _proposalId
            ][_tokenIndices[_index]];
            // Ensure this token has not been withdrawn
            require(!_escrowBalance.executed, "executed");
            require(_escrowBalance.tokenAddress != address(0), "!token");
            _escrowBalance.executed = true;

            // Move tokens to 
            doTransfer(
                _escrowBalance.tokenAddress,
                _escrowBalance.typesTokenIdsAmounts,
                address(this),
                _destination
            );
        }
    }

    /**
     * @notice External function to move tokens to destination ones it can be processed or has been cancelled
     * @param _proposalId Moloch proposal ID
     * @param _molochAddress Address of DAO
     * @param _tokenIndices Indices in proposed tokens array - have to specify this so frozen tokens cant make the whole payload stuck
     */
    function withdrawToDestination(
        uint256 _proposalId,
        address _molochAddress,
        uint256[] calldata _tokenIndices
    ) external nonReentrant {
        IMOLOCH _thisMoloch = IMOLOCH(_molochAddress);
        bool[6] memory _flags = _thisMoloch.getProposalFlags(_proposalId);

        require(
            _flags[1] || _flags[3],
            "proposal not processed and not cancelled"
        );

        TributeEscrowAction memory _action = actions[_molochAddress][_proposalId];
        address _destination;
        // if passed, send NFT to vault
        if (_flags[2]) {
            _destination = _action.vaultAddress;
            // if failed or cancelled, send back to proposer
        } else {
            _destination = _action.proposer;
        }

        processWithdrawls(_molochAddress, _tokenIndices, _destination, _proposalId);

        emit ExecuteAction(_proposalId, msg.sender, _molochAddress);
    }

    /**
     * @notice External function to cancel proposal by applicant if not sponsored 
     * @param _proposalId Moloch proposal ID
     * @param _molochAddress Address of DAO
     */
    function cancelAction(uint256 _proposalId, address _molochAddress)
        external
        nonReentrant
    {
        IMOLOCH _thisMoloch = IMOLOCH(_molochAddress);
        TributeEscrowAction memory _action = actions[_molochAddress][_proposalId];

        require(msg.sender == _action.proposer, "not proposer");
        _thisMoloch.cancelProposal(_proposalId); /*reverts if not cancelable*/

        emit ActionCanceled(_proposalId, _molochAddress);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}