/**
 *Submitted for verification at Etherscan.io on 2021-03-17
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.6.12;



// Part: Documents

/**
 * @title Standard implementation of ERC1643 Document management
 */
contract Documents {

    struct Document {
        bytes32 docHash; // Hash of the document
        uint256 lastModified; // Timestamp at which document details was last modified
        string uri; // URI of the document that exist off-chain
    }

    // mapping to store the documents details in the document
    mapping(bytes32 => Document) internal _documents;
    // mapping to store the document name indexes
    mapping(bytes32 => uint256) internal _docIndexes;
    // Array use to store all the document name present in the contracts
    bytes32[] _docNames;

    // Document Events
    event DocumentRemoved(bytes32 indexed _name, string _uri, bytes32 _documentHash);
    event DocumentUpdated(bytes32 indexed _name, string _uri, bytes32 _documentHash);

    /**
     * @notice Used to attach a new document to the contract, or update the URI or hash of an existing attached document
     * @dev Can only be executed by the owner of the contract.
     * @param _name Name of the document. It should be unique always
     * @param _uri Off-chain uri of the document from where it is accessible to investors/advisors to read.
     * @param _documentHash hash (of the contents) of the document.
     */
    function _setDocument(bytes32 _name, string calldata _uri, bytes32 _documentHash) internal {
        require(_name != bytes32(0), "Zero value is not allowed");
        require(bytes(_uri).length > 0, "Should not be a empty uri");
        if (_documents[_name].lastModified == uint256(0)) {
            _docNames.push(_name);
            _docIndexes[_name] = _docNames.length;
        }
        _documents[_name] = Document(_documentHash, now, _uri);
        emit DocumentUpdated(_name, _uri, _documentHash);
    }

    /**
     * @notice Used to remove an existing document from the contract by giving the name of the document.
     * @dev Can only be executed by the owner of the contract.
     * @param _name Name of the document. It should be unique always
     */

    function _removeDocument(bytes32 _name) internal {
        require(_documents[_name].lastModified != uint256(0), "ERC1643: Document should exist");
        uint256 index = _docIndexes[_name] - 1;
        if (index != _docNames.length - 1) {
            _docNames[index] = _docNames[_docNames.length - 1];
            _docIndexes[_docNames[index]] = index + 1; 
        }
        _docNames.pop();
        emit DocumentRemoved(_name, _documents[_name].uri, _documents[_name].docHash);
        delete _documents[_name];
    }

    /**
     * @notice Used to return the details of a document with a known name (`bytes32`).
     * @param _name Name of the document
     * @return string The URI associated with the document.
     * @return bytes32 The hash (of the contents) of the document.
     * @return uint256 the timestamp at which the document was last modified.
     */
    function getDocument(bytes32 _name) external view returns (string memory, bytes32, uint256) {
        return (
            _documents[_name].uri,
            _documents[_name].docHash,
            _documents[_name].lastModified
        );
    }

    /**
     * @notice Used to retrieve a full list of documents attached to the smart contract.
     * @return bytes32 List of all documents names present in the contract.
     */
    function getAllDocuments() external view returns (bytes32[] memory) {
        return _docNames;
    }

}

// Part: IPointList

// ----------------------------------------------------------------------------
// White List interface
// ----------------------------------------------------------------------------

interface IPointList {
    function isInList(address account) external view returns (bool);
    function hasPoints(address account, uint256 amount) external view  returns (bool);
    function setPoints(
        address[] memory accounts,
        uint256[] memory amounts
    ) external; 
    function initPointList(address accessControl) external ;

}

// Part: OpenZeppelin/[email protected]/SafeMath

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// Part: SafeTransfer

contract SafeTransfer {

    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    //--------------------------------------------------------
    // Helper Functions
    //--------------------------------------------------------

    /// @dev Helper function to handle both ETH and ERC20 payments
    function _tokenPayment(
        address _token,
        address payable _to,
        uint256 _amount
    ) internal {
        if (address(_token) == ETH_ADDRESS) {
            _safeTransferETH(_to,_amount );
        } else {
            _safeTransfer(_token, _to, _amount);
        }
    }

    /// @dev Transfer helper from UniswapV2 Router
    function _safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }


    /**
     * There are many non-compliant ERC20 tokens... this can handle most, adapted from UniSwap V2
     * Im trying to make it a habit to put external calls last (reentrancy)
     * You can put this in an internal function if you like.
     */
    function _safeTransfer(
        address token,
        address to,
        uint256 amount
    ) internal virtual {
        // solium-disable-next-line security/no-low-level-calls
        (bool success, bytes memory data) =
            token.call(
                // 0xa9059cbb = bytes4(keccak256("transfer(address,uint256)"))
                abi.encodeWithSelector(0xa9059cbb, to, amount)
            );
        require(success && (data.length == 0 || abi.decode(data, (bool)))); // ERC20 Transfer failed
    }

    function _safeTransferFrom(
        address token,
        address from,
        uint256 amount
    ) internal virtual {
        // solium-disable-next-line security/no-low-level-calls
        (bool success, bytes memory data) =
            token.call(
                // 0x23b872dd = bytes4(keccak256("transferFrom(address,address,uint256)"))
                abi.encodeWithSelector(0x23b872dd, from, address(this), amount)
            );
        require(success && (data.length == 0 || abi.decode(data, (bool)))); // ERC20 TransferFrom failed
    }

    function _safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function _safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }


}

// File: BatchAuction.sol

/// @notice Attribution to delta.financial
/// @notice Attribution to dutchswap.com


contract BatchAuction is SafeTransfer, Documents/*, ReentrancyGuard */ {
    using SafeMath for uint256;

    /// @notice MISOMarket template id for the factory contract.
    uint256 public constant marketTemplate = 3;

    /// @dev The placeholder ETH address.
    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @notice Main market variables.
    struct MarketInfo {
        uint64 startTime;
        uint64 endTime; 
        uint128 totalTokens;
    }
    MarketInfo public marketInfo;

    /// @notice Market dynamic variables.
    struct MarketStatus {
        uint256 commitmentsTotal;
        uint256 minimumCommitmentAmount;
        bool initialized; 
        bool finalized;
        bool hasPointList;
    }

    MarketStatus public marketStatus;
    // bool private initialized;
    // bool public finalized;
    // bool public hasPointList;

    address public auctionToken;
    /// @notice The currency the crowdsale accepts for payment. Can be ETH or token address.
    address public paymentCurrency;
    /// @notice Address that can finalize auction.
    address public operator;
    /// @notice Address that manages auction approvals.
    address public pointList;
    address payable public wallet; // Where the auction funds will get paid

    mapping(address => uint256) public commitments;
    /// @notice Amount of tokens to claim per address.
    mapping(address => uint256) public claimed;

    /// @notice Event for adding a commitment.
    event AddedCommitment(address addr, uint256 commitment);
    /// @notice Event for finalization of the auction.
    event AuctionFinalized();

    /**
     * @notice Initializes main contract variables and transfers funds for the auction.
     * @dev Init function.
     * @param _funder The address that funds the token for crowdsale.
     * @param _token Address of the token being sold.
     * @param _totalTokens The total number of tokens to sell in auction.
     * @param _startTime Auction start time.
     * @param _endTime Auction end time.
     * @param _paymentCurrency The currency the crowdsale accepts for payment. Can be ETH or token address.
     * @param _minimumCommitmentAmount Minimum amount user can commit in auction.
     * @param _operator Address that can finalize auction.
     * @param _wallet Address where collected funds will be forwarded to.
     */
    function initAuction(
        address _funder,
        address _token,
        uint256 _totalTokens,
        uint256 _startTime,
        uint256 _endTime,
        address _paymentCurrency,
        uint256 _minimumCommitmentAmount,
        address _operator,
        address _pointList,
        address payable _wallet
    ) public {
        require(!marketStatus.initialized, "BatchAuction: auction already initialized");
        require(_startTime < 10000000000, 'BatchAuction: enter an unix timestamp in seconds, not miliseconds');
        require(_endTime < 10000000000, 'BatchAuction: enter an unix timestamp in seconds, not miliseconds');
        require(_startTime >= block.timestamp, "BatchAuction: start time is before current time");
        require(_endTime > _startTime, "BatchAuction: end time must be older than start price");
        require(_totalTokens > 0,"BatchAuction: total tokens must be greater than zero");
        require(_paymentCurrency != address(0), "BatchAuction: payment currency is the zero address");
        require(_operator != address(0), "BatchAuction: operator is the zero address");
        require(_wallet != address(0), "BatchAuction: wallet is the zero address");

        auctionToken = _token;
        paymentCurrency = _paymentCurrency;
        marketStatus.minimumCommitmentAmount = _minimumCommitmentAmount;
        
        marketInfo.startTime = uint64(_startTime);
        marketInfo.endTime = uint64(_endTime);
        marketInfo.totalTokens = uint128(_totalTokens);

        operator = _operator;
        wallet = _wallet;

        if (_pointList != address(0)) {
            pointList = _pointList;
            marketStatus.hasPointList = true;
        }

        // There are many non-compliant ERC20 tokens... this can handle most, adapted from UniSwap V2
        _safeTransferFrom(auctionToken, _funder, _totalTokens);
        marketStatus.initialized = true;
    }


    ///--------------------------------------------------------
    /// Commit to buying tokens!
    ///--------------------------------------------------------

    receive() external payable {
        // revertBecauseUserDidNotProvideAgreement();
        // GP: Allow token direct transfers for testnet
        commitEth(msg.sender, true);
    }

    function marketParticipationAgreement() public pure returns (string memory) {
        return "I understand that I'm interacting with a smart contract. I understand that tokens commited are subject to the token issuer and local laws where applicable. I have reviewed the code of this smart contract and understand it fully. I agree to not hold developers or other people associated with the project liable for any losses or misunderstandings";
    }
    /** 
     * @dev Not using modifiers is a purposeful choice for code readability.
    */ 
    function revertBecauseUserDidNotProvideAgreement() internal pure {
        revert("No agreement provided, please review the smart contract before interacting with it");
    }

    /**
     * @notice Commit ETH to buy tokens on auction.
     * @param _beneficiary Auction participant ETH address.
     */
    function commitEth(address payable _beneficiary, bool readAndAgreedToMarketParticipationAgreement) public payable {
        require(paymentCurrency == ETH_ADDRESS, "BatchAuction: payment currency is not ETH");

        require(msg.value > 0, "BatchAuction: Value must be higher than 0");
        if(readAndAgreedToMarketParticipationAgreement == false) {
            revertBecauseUserDidNotProvideAgreement();
        }
        _addCommitment(_beneficiary, msg.value);
    }

    /**
     * @notice Buy Tokens by commiting approved ERC20 tokens to this contract address.
     * @param _amount Amount of tokens to commit.
     */
    function commitTokens(uint256 _amount, bool readAndAgreedToMarketParticipationAgreement) public {
        commitTokensFrom(msg.sender, _amount, readAndAgreedToMarketParticipationAgreement);
    }

    /**
     * @notice Checks if amout not 0 and makes the transfer and adds commitment.
     * @dev Users must approve contract prior to committing tokens to auction.
     * @param _from User ERC20 address.
     * @param _amount Amount of approved ERC20 tokens.
     */
    function commitTokensFrom(address _from, uint256 _amount, bool readAndAgreedToMarketParticipationAgreement) public /* nonReentrant */ {
        /// @dev Isn't "paymentCurrency == ETH_ADDRESS" enough?
        require(paymentCurrency != ETH_ADDRESS, "BatchAuction: Payment currency is not a token");
        if(readAndAgreedToMarketParticipationAgreement == false) {
            revertBecauseUserDidNotProvideAgreement();
        }
        require(_amount> 0, "BatchAuction: Value must be higher than 0");
        _safeTransferFrom(paymentCurrency, _from, _amount);
        _addCommitment(_from, _amount);

    }


    /// @notice Commits to an amount during an auction
    /**
     * @notice Updates commitment for this address and total commitment of the auction.
     * @param _addr Auction participant address.
     * @param _commitment The amount to commit.
     */
    function _addCommitment(address _addr, uint256 _commitment) internal {
        require(block.timestamp >= marketInfo.startTime && block.timestamp <= marketInfo.endTime, "BatchAuction: outside auction hours"); 

        uint256 newCommitment = commitments[_addr].add(_commitment);
        if (marketStatus.hasPointList) {
            require(IPointList(pointList).hasPoints(_addr, newCommitment));
        }
        commitments[_addr] = newCommitment;
        marketStatus.commitmentsTotal = marketStatus.commitmentsTotal.add(_commitment);
        emit AddedCommitment(_addr, _commitment);
    }

    /**
     * @notice Calculates amount of auction tokens for user to receive.
     * @param amount Amount of tokens to commit.
     * @return Auction token amount.
     */
    function _getTokenAmount(uint256 amount) internal view returns (uint256) {
        if (marketStatus.commitmentsTotal == 0) return 0;
        return amount.mul(1e18).div(tokenPrice());
    }

    /**
     * @notice Calculates the price of each token from all commitments.
     * @return Token price.
     */
    function tokenPrice() public view returns (uint256) {
        return marketStatus.commitmentsTotal.mul(1e18).div(uint256(marketInfo.totalTokens));
    }


    ///--------------------------------------------------------
    /// Finalize Auction
    ///--------------------------------------------------------

    /// @notice Auction finishes successfully above the reserve
    /// @dev Transfer contract funds to initialized wallet.
    function finalize() public  /* nonReentrant */
    {
        require(msg.sender == operator || finalizeTimeExpired(),  "BatchAuction: Sender must be operator");
        require(!marketStatus.finalized, "BatchAuction: Auction has already finalized");
        require(block.timestamp > marketInfo.endTime, "BatchAuction: Auction has not finished yet");
        if (auctionSuccessful()) {
            /// @dev Successful auction
            /// @dev Transfer contributed tokens to wallet.
            _tokenPayment(paymentCurrency, wallet, marketStatus.commitmentsTotal);
        } else {
            /// @dev Failed auction
            /// @dev Return auction tokens back to wallet.
            require(block.timestamp > marketInfo.endTime, "BatchAuction: Auction has not finished yet");
            _tokenPayment(auctionToken, wallet, marketInfo.totalTokens);
        }
        marketStatus.finalized = true;
        emit AuctionFinalized();
    }

    /// @notice Withdraws bought tokens, or returns commitment if the sale is unsuccessful.
    function withdrawTokens() public  {
        withdrawTokens(msg.sender);
    }

    /// @notice Withdraw your tokens once the Auction has ended.
    function withdrawTokens(address payable beneficiary) public /* nonReentrant */ {
        if (auctionSuccessful()) {
            require(marketStatus.finalized, "BatchAuction: not finalized");
            /// @dev Successful auction! Transfer claimed tokens.
            uint256 tokensToClaim = tokensClaimable(beneficiary);
            require(tokensToClaim > 0, "BatchAuction: No tokens to claim");
            claimed[beneficiary] = tokensToClaim;
            claimed[beneficiary] = claimed[beneficiary].add(tokensToClaim);

            _tokenPayment(auctionToken, beneficiary, tokensToClaim);
        } else {
            /// @dev Auction did not meet reserve price.
            /// @dev Return committed funds back to user.
            require(block.timestamp > marketInfo.endTime, "BatchAuction: Auction has not finished yet");
            uint256 fundsCommitted = commitments[beneficiary];
            require(fundsCommitted > 0, "BatchAuction: No funds committed");
            commitments[beneficiary] = 0; // Stop multiple withdrawals and free some gas
            _tokenPayment(paymentCurrency, beneficiary, fundsCommitted);
        }
    }


    /**
     * @notice How many tokens the user is able to claim.
     * @param _user Auction participant address.
     * @return Tokens left to claim.
     */
    function tokensClaimable(address _user) public view returns (uint256) {
        if (commitments[_user] == 0) return 0;
        uint256 tokensAvailable = _getTokenAmount(commitments[_user]);
        return tokensAvailable.sub(claimed[_user]);
    }

    /**
     * @notice Checks if raised more than minimum amount.
     * @return True if tokens sold greater than or equals to the minimum commitment amount.
     */
    function auctionSuccessful() public view returns (bool) {
        return marketStatus.commitmentsTotal >= marketStatus.minimumCommitmentAmount && marketStatus.commitmentsTotal > 0;
    }

    /**
     * @notice Checks if the auction has ended.
     * @return True if current time is greater than auction end time.
     */
    function auctionEnded() public view returns (bool) {
        return block.timestamp > marketInfo.endTime;
    }


    /// @notice Returns true if 7 days have passed since the end of the auction
    function finalizeTimeExpired() public view returns (bool) {
        return uint256(marketInfo.endTime) + 14 days < block.timestamp;
    }


    //--------------------------------------------------------
    // Documents
    //--------------------------------------------------------

    function setDocument(bytes32 _name, string calldata _uri, bytes32 _documentHash) external {
        require(msg.sender == operator);
        _setDocument( _name, _uri, _documentHash);
    }

    function removeDocument(bytes32 _name) external {
        require(msg.sender == operator);
        _removeDocument(_name);
    }


    //--------------------------------------------------------
    // Market Launchers
    //--------------------------------------------------------


    function initMarket(
        bytes calldata _data
    ) public {
        (
        address _funder,
        address _token,
        uint256 _totalTokens,
        uint256 _startTime,
        uint256 _endTime,
        address _paymentCurrency,
        uint256 _minimumCommitmentAmount,
        address _operator,
        address _pointList,
        address payable _wallet
        ) = abi.decode(_data, (
            address,
            address,
            uint256,
            uint256,
            uint256,
            address,
            uint256,
            address,
            address,
            address
        ));
        initAuction(_funder, _token, _totalTokens, _startTime, _endTime, _paymentCurrency, _minimumCommitmentAmount, _operator, _pointList,  _wallet);
    }

     function getBatchAuctionInitData(
       address _funder,
        address _token,
        uint256 _totalTokens,
        uint256 _startTime,
        uint256 _endTime,
        address _paymentCurrency,
        uint256 _minimumCommitmentAmount,
        address _operator,
        address _pointList,
        address payable _wallet
    )
        external
        pure
        returns (bytes memory _data)
    {
        return abi.encode(
            _funder,
            _token,
            _totalTokens,
            _startTime,
            _endTime,
            _paymentCurrency,
            _minimumCommitmentAmount,
            _operator,
            _pointList,
            _wallet
            );
    }

    function getBaseInformation() external view returns(
        address token, 
        uint64 startTime,
        uint64 endTime,
        bool finalized
    ) {
        return (auctionToken, marketInfo.startTime, marketInfo.endTime, marketStatus.finalized);
    }

}