// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./GovWorldProtocolBase.sol";
import "../admin/interfaces/IGovWorldAdminRegistry.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract GovWorldProtocolRegistry is GovWorldProtocolBase {
    using SafeMath for *;
    using Address for address;
    address govAdminRegistry;

    uint256 public lenderUnearndedAPYPercentage = 2000;
    // platform fee is the 1% of the loan amount
    //TODO percentages should be in basis point to handle decimals in all contracts
    uint256 public govPlatformFee = 200; //2%
    uint256 public govAutosellFee = 700; //7% in Calculate APY FEE Function
    uint256 public govThresholdFee = 5; //0.05 %
    uint256 public govAdminWalletFee = 2000; //20% of the Platform Fee

    address public feeReceiverAdminWallet;

    //modifier: only admin with AddTokenRole can add Token(s) or NFT(s)
    modifier onlyAddTokenRole(address admin) {
        require(
            IGovWorldAdminRegistry(govAdminRegistry).isAddTokenRole(admin) ==
                true,
            "GovProtocolRegistry: msg.sender not add token admin."
        );
        _;
    }
    //modifier: only admin with EditTokenRole can update or remove Token(s)/NFT(s)
    modifier onlyEditTokenRole(address admin) {
        require(
            IGovWorldAdminRegistry(govAdminRegistry).isEditTokenRole(admin) ==
                true,
            "GovProtocolRegistry: msg.sender not edit token admin."
        );
        _;
    }

    //modifier: only admin with AddSpAccessRole can add SP Wallet
    modifier onlyAddSpRole(address admin) {
        require(
            IGovWorldAdminRegistry(govAdminRegistry).isAddSpAccess(admin) ==
                true,
            "GovProtocolRegistry: No admin right to add Strategic Partner"
        );
        _;
    }

    //modifier: only admin with EditSpAccess can update or remove SP Wallet
    modifier onlyEditSpRole(address admin) {
        require(
            IGovWorldAdminRegistry(govAdminRegistry).isEditSpAccess(admin) ==
                true,
            "GovProtocolRegistry: No admin right to update or remove Strategic Partner"
        );
        _;
    }

    // only super admin can edit platform and lender percentages
    modifier onlyEditFeeRole(address admin) {
        require(
            IGovWorldAdminRegistry(govAdminRegistry).isSuperAdminAccess(
                admin
            ) == true,
            "GovProtocolRegistry: No admin right to update platform fee"
        );
        _;
    }

    constructor(address _govAdminRegistry) {
        govAdminRegistry = _govAdminRegistry;
    }

    /** external functions of the Gov Protocol Contract */
    /**
    @dev function to add token to approvedTokens mapping
    *@param _tokenAddress of the new token Address
    *@param marketData struct of the _tokenAddress
    */
    function addTokens(
        address[] memory _tokenAddress,
        Market[] memory marketData
    ) external override onlyAddTokenRole(msg.sender) {
        require(
            _tokenAddress.length == marketData.length,
            "GPL: Token Address Length must match Market Data"
        );
        for (uint256 i = 0; i < _tokenAddress.length; i++) {
            //checking Token Contract have not already added
            require(
                !this.isTokenApproved(_tokenAddress[i]),
                "GPL: already added Token Contract"
            );
            _addToken(_tokenAddress[i], marketData[i]);
        }
    }

    /**
     *@dev function to update the token market data
     *@param _tokenAddress to check if it exit in the array and mapping
     *@param _marketData struct to update the token market
     */
    function updateTokens(
        address[] memory _tokenAddress,
        Market[] memory _marketData
    ) external override onlyEditTokenRole(msg.sender) {
        require(
            _tokenAddress.length == _marketData.length,
            "GPL: Token Address Length must match Market Data"
        );

        for (uint256 i = 0; i < _tokenAddress.length; i++) {
            require(
                this.isTokenApproved(_tokenAddress[i]),
                "GPR: cannot update the token data, add new token address first"
            );
            _updateToken(_tokenAddress[i], _marketData[i]);
            emit TokensUpdated(_tokenAddress[i], _marketData[i]);
        }
    }

    /**
     *@dev function which remove tokenaddress from array and data from the mapping
     *@param _removeTokenAddress the key to remove
     */
    function removetokens(address[] memory _removeTokenAddress)
        external
        override
        onlyEditTokenRole(msg.sender)
    {
        for (uint256 i = 0; i < _removeTokenAddress.length; i++) {
            require(
                this.isTokenApproved(_removeTokenAddress[i]),
                "GPR: cannot remove the token address, does not exist"
            );

            delete approvedTokens[_removeTokenAddress[i]];

            _removeToken(
                _getIndex(_removeTokenAddress[i], allapprovedTokenContracts)
            );
            emit TokensRemoved(_removeTokenAddress[i]);
        }
    }

    /**
    @dev add sp wallet to the mapping approvedSps
    @param _tokenAddress token contract address
    @param _walletAddress sp wallet address to add  
    */

    function addSp(address _tokenAddress, address _walletAddress)
        external
        override
        onlyAddSpRole(msg.sender)
    {
        require(
            approvedTokens[_tokenAddress].isSP,
            "Sorry, this token is not a Strategic Partner"
        );
        require(
            !_isAlreadyAddedSp(_walletAddress),
            "GovProtocolRegistry: SP Already Approved"
        );
        _addSp(_tokenAddress, _walletAddress);
    }

    /**
    @dev remove sp wallet from mapping
    @param _tokenAddress token address as a key to remove sp
    @param _removeWalletAddress sp wallet address to be removed 
    */

    function removeSp(address _tokenAddress, address _removeWalletAddress)
        external
        override
        onlyEditSpRole(msg.sender)
    {
        require(
            approvedTokens[_tokenAddress].isSP,
            "Sorry, this token is not a Strategic Partner"
        );
        require(
            _isAlreadyAddedSp(_removeWalletAddress),
            "GPR: cannot remove the SP, does not exist"
        );

        for (uint256 i = 0; i < approvedSps[_tokenAddress].length; i++) {
            if (approvedSps[_tokenAddress][i] == _removeWalletAddress) {
                // delete approvedSps[_tokenAddress][i];
                _removeSpKey(_getIndexofAddressfromArray(_removeWalletAddress));
                _removeSpKeyfromMapping(
                    _getIndexofAddressfromArray(approvedSps[_tokenAddress][i]),
                    _tokenAddress
                );
            }
        }

        emit SPWalletRemoved(_tokenAddress, _removeWalletAddress);
    }

    /**
    @dev adding bulk sp wallet address to the approvedSps
    @param _tokenAddress token contract address as a key for sp wallets
    @param _walletAddress sp wallet addresses adding to the approvedSps mapping
     */
    function addBulkSps(address _tokenAddress, address[] memory _walletAddress)
        external
        override
        onlyAddSpRole(msg.sender)
    {
        require(
            approvedTokens[_tokenAddress].isSP,
            "Sorry, this token is not a Strategic Partner"
        );

        _addBulkSps(_tokenAddress, _walletAddress);
    }

    /**
     *@dev function to update the sp wallet
     *@param _tokenAddress to check if it exit in the array and mapping
     *@param _oldWalletAddress old wallet address to be updated
     *@param _newWalletAddress new wallet address
     */
    function updateSp(
        address _tokenAddress,
        address _oldWalletAddress,
        address _newWalletAddress
    ) external override onlyEditSpRole(msg.sender) {
        require(
            approvedTokens[_tokenAddress].isSP,
            "Sorry, this token is not a Strategic Partner"
        );
        require(
            _isAlreadyAddedSp(_oldWalletAddress),
            "GPR: cannot update the wallet address, token address not exist or not a SP"
        );

        require(
            this.isAddedSPWallet(_tokenAddress, _oldWalletAddress),
            "GPR: Wallet Address not exist"
        );

        _updateSp(_tokenAddress, _oldWalletAddress, _newWalletAddress);
    }

    /**
    @dev external function update bulk SP wallets to the approvedSps
    @param _tokenAddress token contract address being updated
    @param _oldWalletAddress  array of old sp wallets 
    @param _newWalletAddress  array of the new sp wallets
     */
    function updateBulkSps(
        address _tokenAddress,
        address[] memory _oldWalletAddress,
        address[] memory _newWalletAddress
    ) external override onlyEditSpRole(msg.sender) {
        require(
            approvedTokens[_tokenAddress].isSP,
            "Sorry, this token is not a Strategic Partner"
        );
        _updateBulkSps(_tokenAddress, _oldWalletAddress, _newWalletAddress);
    }

    /**
    *@dev function which remove bulk wallet address and key
    @param _tokenAddress check across this token address
    @param _removeWalletAddress array of wallet addresses to be removed
     */

    function removeBulkSps(
        address _tokenAddress,
        address[] memory _removeWalletAddress
    ) external override onlyEditSpRole(msg.sender) {
        require(
            approvedTokens[_tokenAddress].isSP,
            "Sorry, this token is not a Strategic Partner"
        );

        for (uint256 i = 0; i < _removeWalletAddress.length; i++) {
            require(
                _isAlreadyAddedSp(_removeWalletAddress[i]),
                "GPR: cannot remove the SP, does not exist, not in array"
            );

            require(
                this.isAddedSPWallet(_tokenAddress, _removeWalletAddress[i]),
                "GPR: cannot remove the SP, does not exist, not in mapping"
            );

            // delete approvedSps[_tokenAddress][i];
            //remove SP key from the mapping
            _removeSpKey(_getIndexofAddressfromArray(_removeWalletAddress[i]));

            //also remove SP key from specific token address
            _removeSpKeyfromMapping(
                _getIndexofAddressfromArray(_tokenAddress),
                _tokenAddress
            );
        }
    }

    /** Public functions of the Gov Protocol Contract */

    /**
    @dev get all approved tokens from the allapprovedTokenContracts
     */
    function getallApprovedTokens() public view returns (address[] memory) {
        return allapprovedTokenContracts;
    }

    /**
    @dev get data of single approved token address return Market Struct
     */
    function getSingleApproveToken(address _tokenAddress)
        external
        view
        override
        returns (Market memory)
    {
        return approvedTokens[_tokenAddress];
    }

    /**
    @dev get all approved Sp wallets
     */
    function getAllApprovedSPs() external view returns (address[] memory) {
        return allApprovedSps;
    }

    /**
    @dev get wallet addresses of single tokenAddress 
    */
    function getSingleTokenSps(address _tokenAddress)
        public
        view
        override
        returns (address[] memory)
    {
        return approvedSps[_tokenAddress];
    }

    /**
    @dev set the percentage of the unearned APY Fee to the Lender
    @param _percentage percentage which goes to lender
     */
    function setUnearnedAPYPercentageForLender(uint256 _percentage)
        public
        onlyEditFeeRole(msg.sender)
    {
        require(
            _percentage <= 10000 && _percentage > 0,
            "GPL: Gov Percentage Error"
        );
        lenderUnearndedAPYPercentage = _percentage;
    }

    function setpercentageforAdminWallet(uint256 _percentage)
        public
        onlyEditFeeRole(msg.sender)
    {
        require(
            _percentage <= 10000 && _percentage > 0,
            "GPL: Gov Percentage Error"
        );
        govAdminWalletFee = _percentage;
    }

    /**
    @dev set the percentage of the Gov Platform Fee to the Gov Lend Market Contracts
    @param _percentage percentage which goes to the gov platform
     */
    function setGovPlatfromFee(uint256 _percentage)
        public
        onlyEditFeeRole(msg.sender)
    {
        require(
            _percentage <= 10000 && _percentage > 0,
            "GPL: Gov Percentage Error"
        );
        govPlatformFee = _percentage;
    }

    function setThresholdFee(uint256 _percentage)
        public
        onlyEditFeeRole(msg.sender)
    {
        require(
            _percentage <= 10000 && _percentage > 0,
            "GPL: Gov Percentage Error"
        );
        govThresholdFee = _percentage;
    }

    function setAutosellFee(uint256 _percentage)
        public
        onlyEditFeeRole(msg.sender)
    {
        require(
            _percentage <= 10000 && _percentage > 0,
            "GPL: Gov Percentage Error"
        );
        govAutosellFee = _percentage;
    }

    function setfeeReceiverAdminWallet(address _newWallet)
        public
        onlyEditFeeRole(msg.sender)
    {
        require(_newWallet != address(0), "GPL: Null Address");
        require(_newWallet != feeReceiverAdminWallet, "GPL: Already set");
        feeReceiverAdminWallet = _newWallet;
    }

    function getUnearnedAPYPercentageForLender()
        public
        view
        override
        returns (uint256)
    {
        return lenderUnearndedAPYPercentage;
    }

    function getGovPlatformFee() public view override returns (uint256) {
        return govPlatformFee;
    }

    function getTokenMarket()
        external
        view
        override
        returns (address[] memory)
    {
        return allapprovedTokenContracts;
    }

    function getThresholdPercentage() external view override returns (uint256) {
        return govThresholdFee;
    }

    function getAutosellPercentage() external view override returns (uint256) {
        return govAutosellFee;
    }

    function getAdminWalletPercentage()
        external
        view
        override
        returns (uint256)
    {
        return govAdminWalletFee;
    }

    function getAdminFeeWallet() external view override returns (address) {
        return feeReceiverAdminWallet;
    }
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

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IGovWorldProtocolRegistry.sol";
import "./IGTokenFactory.sol";

/// @author IdeoFuzion Team
/// @title GovWorld Protocol Registry Base Contract

abstract contract GovWorldProtocolBase is IGovWorldProtocolRegistry, Ownable {
    using Address for address;
    using SafeMath for *;

    //tokenAddress => spWalletAddress
    mapping(address => address[]) public approvedSps;
    // array of all approved SP Wallet Addresses
    address[] public allApprovedSps;
    address public liquidatorContract;
    address public tokenMarket;
    address public gTokenFactory;

    //tokenContractAddress => Market struct
    mapping(address => Market) public approvedTokens;

    //nftcontract + tokenId(bytes32 hash) => NFTData struct
    // mapping(bytes32 => NFTData) public approvedNFTs;

    //array of all approved token contracts
    address[] allapprovedTokenContracts;
    event TokensAdded(
        address indexed tokenAddress,
        bool isSp,
        bool isReversedLoan,
        uint256 tokenLimitPerReverseLoan,
        address gToken
    );
    event TokensUpdated(
        address indexed tokenAddress,
        Market indexed _marketData
    );

    event SPWalletAdded(
        address indexed tokenAddress,
        address indexed walletAddress
    );

    event BulkSpWalletAdded(
        address indexed tokenAddress,
        address indexed walletAddresses
    );

    event SPWalletUpdated(
        address indexed tokenAddress,
        address indexed oldWalletAddress,
        address indexed newWalletAddress
    );

    event BulkSpWAlletUpdated(
        address indexed tokenAddress,
        address indexed oldWalletAddress,
        address indexed newWalletAddress
    );
    event SPWalletRemoved(
        address indexed tokenAddress,
        address indexed walletAddress
    );

    // event NFTAdded(bytes32 nftPlatform, address indexed nftContract, uint256 indexed tokenId);
    event TokensRemoved(address indexed tokenAddress);

    function setLiquidatorContractAddress(address _liquidator)
        external
        onlyOwner
    {
        //onlyOwner modifier
        require(_liquidator != address(0), "Market Empty");
        liquidatorContract = _liquidator;
    }

    function setTokenMarketAddress(address _tokenMarket) external onlyOwner {
        //onlyOwner modifier
        require(_tokenMarket != address(0), "Market Empty");
        tokenMarket = _tokenMarket;
    }

    function setGTokenFactory(address _tokenFactory) external onlyOwner {
        //onlyOwner modifier
        require(_tokenFactory != address(0), "Factory Empty");
        gTokenFactory = _tokenFactory;
    }

    /** Internal functions of the Gov Protocol Contract */
    /**
    @dev function to add token market data
    @param _tokenAddress ERC20 token contract address as a key for approvedTokens mapping
    @param marketData struct object to be added in approvedTokens mapping
     */

    function _addToken(address _tokenAddress, Market memory marketData)
        internal
    {
        //adding marketData to the approvedToken mapping
        if (marketData.isSP) {
            require(
                _tokenAddress == marketData.gToken,
                "GPL: gtoken must equal token address"
            );
            require(
                liquidatorContract != address(0x0) &&
                    tokenMarket != address(0x0),
                "GPL: set addresses first"
            );
            marketData.gToken = IGTokenFactory(gTokenFactory).deployGToken(
                _tokenAddress,
                liquidatorContract,
                tokenMarket
            );
            approvedTokens[_tokenAddress] = marketData;
        } else {
            approvedTokens[_tokenAddress] = Market(
                marketData.dexRouter,
                marketData.isSP,
                marketData.isReversedLoan,
                marketData.tokenLimitPerReverseLoan,
                address(0x0),
                false,
                false
            );
        }

        emit TokensAdded(
            _tokenAddress,
            approvedTokens[_tokenAddress].isSP,
            approvedTokens[_tokenAddress].isReversedLoan,
            approvedTokens[_tokenAddress].tokenLimitPerReverseLoan,
            approvedTokens[_tokenAddress].gToken
        );
        allapprovedTokenContracts.push(_tokenAddress);
    }

    /**
    @dev function to update the token market data
    @param _tokenAddress ERC20 token contract address as a key for approvedTokens mapping
    @param _marketData struct object to be added in approvedTokens mapping
     */
    function _updateToken(address _tokenAddress, Market memory _marketData)
        internal
    {
        //update Token Data  to the approvedTokens mapping
        //adding marketData to the approvedToken mapping
        Market storage oldMarketData = approvedTokens[_tokenAddress];

        if (_marketData.isSP) {
            approvedTokens[_tokenAddress] = Market(
                _marketData.dexRouter,
                _marketData.isSP,
                _marketData.isReversedLoan,
                _marketData.tokenLimitPerReverseLoan,
                oldMarketData.gToken,
                _marketData.isMint,
                _marketData.isClaimToken
            );
        } else {
            approvedTokens[_tokenAddress] = Market(
                _marketData.dexRouter,
                _marketData.isSP,
                _marketData.isReversedLoan,
                _marketData.tokenLimitPerReverseLoan,
                address(0x0),
                false,
                false
            );
        }
    }

    /**
    @dev function to remove token key from the allapprovedtokens array
    @param index of the remove token address from array
     */
    function _removeToken(uint256 index) internal {
        for (
            uint256 i = index;
            i < allapprovedTokenContracts.length.sub(1);
            i++
        ) {
            allapprovedTokenContracts[i] = allapprovedTokenContracts[i + 1];
        }
        allapprovedTokenContracts.pop();
    }

    /** 
    @dev check function if Token Contract address is already added 
    @param _tokenAddress token address */
    function isTokenApproved(address _tokenAddress)
        external
        view
        override
        returns (bool)
    {
        for (uint256 i = 0; i < allapprovedTokenContracts.length; i++) {
            if (allapprovedTokenContracts[i] == _tokenAddress) {
                return true;
            }
        }
        return false;
    }

    /**
    @dev internal function to add Strategic Partner Wallet Address to the approvedSps mapping
    @param _tokenAddress contract address of the approvedToken Sp
    @param _walletAddress sp wallet address added to the approvedSps
     */
    function _addSp(address _tokenAddress, address _walletAddress) internal {
        // add the sp wallet address to the approvedSps mapping
        approvedSps[_tokenAddress].push(_walletAddress);
        // push sp _walletAddress to allApprovedSps array
        allApprovedSps.push(_walletAddress);
        emit SPWalletAdded(_tokenAddress, _walletAddress);
    }

    /** 
    @dev check if _walletAddress is already added Sp in array
    @param _walletAddress wallet address checking 
    */

    function _isAlreadyAddedSp(address _walletAddress)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < allApprovedSps.length; i++) {
            if (allApprovedSps[i] == _walletAddress) {
                return true;
            }
        }
        return false;
    }

    /**
    @dev checking the approvedSps mapping if already walletAddress
    @param _tokenAddress contract address of the approvedToken Sp
    @param _walletAddress wallet address of the approved Sp 
    */
    function isAddedSPWallet(address _tokenAddress, address _walletAddress)
        external
        view
        override
        returns (bool)
    {
        for (uint256 i = 0; i < approvedSps[_tokenAddress].length; i++) {
            if (approvedSps[_tokenAddress][i] == _walletAddress) {
                return true;
            }
        }
        return false;
    }

    /**
    @dev remove the Sp token address from the allapprovedsps array
    @param index index of the sp address being removed from the allApprovedSps
     */
    function _removeSpKey(uint256 index) internal {
        for (uint256 i = index; i < allApprovedSps.length.sub(1); i++) {
            allApprovedSps[i] = allApprovedSps[i + 1];
        }
        allApprovedSps.pop();
    }

    /**
    @dev remove Sp wallet address from the approvedSps mapping across specific tokenaddress
    @param index of the approved wallet sp
    @param _tokenAddress token contract address of the approvedToken sp
     */
    function _removeSpKeyfromMapping(uint256 index, address _tokenAddress)
        internal
    {
        for (
            uint256 i = index;
            i < approvedSps[_tokenAddress].length.sub(1);
            i++
        ) {
            approvedSps[_tokenAddress][i] = approvedSps[_tokenAddress][i + 1];
        }
        approvedSps[_tokenAddress].pop();
    }

    /**
    @dev getting index of sp from the allApprovedSps array
    @param _walletAddress getting this wallet address index  */
    function _getIndexofAddressfromArray(address _walletAddress)
        internal
        view
        returns (uint256 index)
    {
        for (uint256 i = 0; i < allApprovedSps.length; i++) {
            if (allApprovedSps[i] == _walletAddress) {
                return i;
            }
        }
    }

    //get index of the token address from the approve token array
    function _getIndex(address _tokenAddress, address[] memory from)
        internal
        pure
        returns (uint256 index)
    {
        for (uint256 i = 0; i < from.length; i++) {
            if (from[i] == _tokenAddress) {
                return i;
            }
        }
    }

    /**
    @dev get index of the wallet from the approvedSps mapping
    @param tokenAddress token contract address
    @param _walletAddress getting this wallet address index
    */
    function _getWalletIndexfromMapping(
        address tokenAddress,
        address _walletAddress
    ) internal view returns (uint256 index) {
        for (uint256 i = 0; i < approvedSps[tokenAddress].length; i++) {
            if (approvedSps[tokenAddress][i] == _walletAddress) {
                return i;
            }
        }
    }

    /**
    @dev adding bulk sp wallet address to the approvedSps
    @param _tokenAddress token contract address as a key for sp wallets
    @param _walletAddress sp wallet addresses adding to the approvedSps mapping
     */
    function _addBulkSps(address _tokenAddress, address[] memory _walletAddress)
        internal
    {
        for (uint256 i = 0; i < _walletAddress.length; i++) {
            //checking Wallet if already added
            require(
                !_isAlreadyAddedSp(_walletAddress[i]),
                "one or more wallet addresses already added in allapprovedSps array"
            );

            require(
                !this.isAddedSPWallet(_tokenAddress, _walletAddress[i]),
                "One or More Wallet addresses already in mapping"
            );

            approvedSps[_tokenAddress].push(_walletAddress[i]);
            allApprovedSps.push(_walletAddress[i]);
            emit BulkSpWalletAdded(_tokenAddress, _walletAddress[i]);
        }
    }

    /**
    @dev internal function to update Sp wallet Address, 
    doing it by removing old wallet first then add new wallet address
    @param _tokenAddress token contract address as a key to update sp wallet
    @param _oldWalletAddress old SP wallet address
    @param _newWalletAddress new SP wallet address
    */
    function _updateSp(
        address _tokenAddress,
        address _oldWalletAddress,
        address _newWalletAddress
    ) internal {
        //update wallet addres to the approved Sps mapping

        for (uint256 i = 0; i < approvedSps[_tokenAddress].length; i++) {
            if (approvedSps[_tokenAddress][i] == _oldWalletAddress) {
                // delete approvedSps[_tokenAddress][i];
                _removeSpKey(_getIndexofAddressfromArray(_oldWalletAddress));
                _removeSpKeyfromMapping(
                    _getIndexofAddressfromArray(approvedSps[_tokenAddress][i]),
                    _tokenAddress
                );
                approvedSps[_tokenAddress].push(_newWalletAddress);
                allApprovedSps.push(_newWalletAddress);
            }
        }
        emit SPWalletUpdated(
            _tokenAddress,
            _oldWalletAddress,
            _newWalletAddress
        );
    }

    /**
    @dev update bulk SP wallets to the approvedSps
    @param _tokenAddress token contract address being updated
    @param _oldWalletAddress  array of old sp wallets 
    @param _newWalletAddress  array of the new sp wallets
     */
    function _updateBulkSps(
        address _tokenAddress,
        address[] memory _oldWalletAddress,
        address[] memory _newWalletAddress
    ) internal {
        require(
            _oldWalletAddress.length == _newWalletAddress.length,
            "GPR: Length of old and new wallet should be equal"
        );

        for (uint256 i = 0; i < _oldWalletAddress.length; i++) {
            //checking Wallet if already added
            require(
                _isAlreadyAddedSp(_oldWalletAddress[i]),
                "GPR: cannot update the wallet addresses, token address not exist or not a SP, not in array"
            );

            require(
                this.isAddedSPWallet(_tokenAddress, _oldWalletAddress[i]),
                "GPR: cannot update the wallet addresses, token address not exist or not a SP, not in mapping"
            );

            _removeSpKey(_getIndexofAddressfromArray(_oldWalletAddress[i]));
            _removeSpKeyfromMapping(
                _getWalletIndexfromMapping(_tokenAddress, _oldWalletAddress[i]),
                _tokenAddress
            );
            approvedSps[_tokenAddress].push(_newWalletAddress[i]);
            allApprovedSps.push(_newWalletAddress[i]);
            emit BulkSpWAlletUpdated(
                _tokenAddress,
                _oldWalletAddress[i],
                _newWalletAddress[i]
            );
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IGovWorldAdminRegistry {
    struct AdminAccess {
        //access-modifier variables to add projects to gov-intel
        bool addGovIntel;
        bool editGovIntel;
        //access-modifier variables to add tokens to gov-world protocol
        bool addToken;
        bool editToken;
        //access-modifier variables to add strategic partners to gov-world protocol
        bool addSp;
        bool editSp;
        //access-modifier variables to add gov-world admins to gov-world protocol
        bool addGovAdmin;
        bool editGovAdmin;
        //access-modifier variables to add bridges to gov-world protocol
        bool addBridge;
        bool editBridge;
        //access-modifier variables to add pools to gov-world protocol
        bool addPool;
        bool editPool;
        //superAdmin role assigned only by the super admin
        bool superAdmin;
    }

    function isAddGovAdminRole(address admin) external view returns (bool);

    //using this function externally in Gov Tier Level Smart Contract
    function isEditAdminAccessGranted(address admin)
        external
        view
        returns (bool);

    //using this function externally in other Smart Contracts
    function isAddTokenRole(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isEditTokenRole(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isAddSpAccess(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isEditSpAccess(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isEditAPYPerAccess(address admin) external view returns (bool);

    //using this function in loan smart contracts to withdraw network balance
    function isSuperAdminAccess(address admin) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

// Token Market Data
struct Market {
    address dexRouter;
    bool isSP;
    bool isReversedLoan;
    uint256 tokenLimitPerReverseLoan;
    address gToken;
    bool isMint;
    bool isClaimToken;
}

interface IGovWorldProtocolRegistry {
    /** external functions of the Gov Protocol Contract */
    /**
    @dev function to add token to approvedTokens mapping
    *@param _tokenAddress of the new token Address
    *@param  _market of the _tokenAddress
    */
    function addTokens(address[] memory _tokenAddress, Market[] memory _market)
        external;

    /**
     *@dev function to update the token market data
     *@param _tokenAddress to check if it exit in the array and mapping
     *@param _marketData struct to update the token market
     */
    function updateTokens(
        address[] memory _tokenAddress,
        Market[] memory _marketData
    ) external;

    /**
     *@dev function which remove tokenaddress from array and data from the mapping
     *@param _removeTokenAddress the key to remove
     */
    function removetokens(address[] memory _removeTokenAddress) external;

    /**
    @dev add sp wallet to the mapping approvedSps
    @param _tokenAddress token contract address
    @param _walletAddress sp wallet address to add  
    */

    function addSp(address _tokenAddress, address _walletAddress) external;

    /**
    @dev remove sp wallet from mapping
    @param _tokenAddress token address as a key to remove sp
    @param _removeWalletAddress sp wallet address to be removed 
    */

    function removeSp(address _tokenAddress, address _removeWalletAddress)
        external;

    /**
    @dev adding bulk sp wallet address to the approvedSps
    @param _tokenAddress token contract address as a key for sp wallets
    @param _walletAddress sp wallet addresses adding to the approvedSps mapping
     */
    function addBulkSps(address _tokenAddress, address[] memory _walletAddress)
        external;

    /**
     *@dev function to update the sp wallet
     *@param _tokenAddress to check if it exit in the array and mapping
     *@param _oldWalletAddress old wallet address to be updated
     *@param _newWalletAddress new wallet address
     */
    function updateSp(
        address _tokenAddress,
        address _oldWalletAddress,
        address _newWalletAddress
    ) external;

    /**
    @dev external function update bulk SP wallets to the approvedSps
    @param _tokenAddress token contract address being updated
    @param _oldWalletAddress  array of old sp wallets 
    @param _newWalletAddress  array of the new sp wallets
     */
    function updateBulkSps(
        address _tokenAddress,
        address[] memory _oldWalletAddress,
        address[] memory _newWalletAddress
    ) external;

    /**
    *@dev function which remove bulk wallet address and key
    @param _tokenAddress check across this token address
    @param _removeWalletAddress array of wallet addresses to be removed
     */

    function removeBulkSps(
        address _tokenAddress,
        address[] memory _removeWalletAddress
    ) external;

    /** 
    @dev check function if Token Contract address is already added 
    @param _tokenAddress token address */
    function isTokenApproved(address _tokenAddress)
        external
        view
        returns (bool);

    function getUnearnedAPYPercentageForLender()
        external
        view
        returns (uint256);

    function getGovPlatformFee() external view returns (uint256);

    function getThresholdPercentage() external view returns (uint256);

    function getAutosellPercentage() external view returns (uint256);

    function getAdminWalletPercentage() external view returns (uint256);

    function getSingleApproveToken(address _tokenAddress)
        external
        view
        returns (Market memory);

    function getTokenMarket() external view returns (address[] memory);

    function getAdminFeeWallet() external view returns (address);

    function getSingleTokenSps(address _tokenAddress)
        external
        view
        returns (address[] memory);

    function isAddedSPWallet(address _tokenAddress, address _walletAddress)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;

interface IGTokenFactory {
    function deployGToken(
        address,
        address,
        address
    ) external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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