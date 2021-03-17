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

// Part: IERC20

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    // function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    // function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
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

// File: Crowdsale.sol

/// @notice Attribution to delta.financial


contract Crowdsale is SafeTransfer, Documents /*, ReentrancyGuard */ {
    using SafeMath for uint256;

    /// @notice MISOMarket template id for the factory contract.
    uint256 public constant marketTemplate = 1;

    /// @notice The placeholder ETH address.
    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /** 
    * @notice rate - How many token units a buyer gets per token or wei.
    * The rate is the conversion between wei and the smallest and indivisible token unit.
    * So, if you are using a rate of 1 with a ERC20Detailed token with 3 decimals called TOK
    * 1 wei will give you 1 unit, or 0.001 TOK.
    */
    /// @notice goal - Minimum amount of funds to be raised in weis or tokens.
    struct MarketPrice {
        uint128 rate;
        uint128 goal; 
    }
    MarketPrice public marketPrice;

    /// @notice Starting time of crowdsale.
    /// @notice Ending time of crowdsale.
    /// @notice Total number of tokens to sell.
    struct MarketInfo {
        uint64 startTime;
        uint64 endTime; 
        uint128 totalTokens;
    }
    MarketInfo public marketInfo;

    /// @notice Amount of wei raised.
    /// @notice Whether crowdsale has been initialized or not.
    /// @notice Whether crowdsale has been finalized or not.
    struct MarketStatus {
        uint128 amountRaised;
        bool initialized; 
        bool finalized;
        bool hasPointList;
    }
    MarketStatus public marketStatus;

    /// @notice The token being sold.
    address public auctionToken;
    /// @notice Address where funds are collected.
    address payable private wallet;
    /// @notice The currency the crowdsale accepts for payment. Can be ETH or token address.
    address public paymentCurrency;
    /// @notice Address that can finalize crowdsale.
    address public operator;
    /// @notice Address that manages auction approvals.
    address public pointList;

    /// @notice The commited amount of accounts.
    mapping(address => uint256) public commitments;
    /// @notice Amount of tokens to claim per address.
    mapping(address => uint256) public claimed;

    /**
     * @notice Event for token purchase logging.
     * @param purchaser Who paid for the tokens.
     * @param beneficiary Who got the tokens.
     * @param value Value of wei or token paid for purchase.
     * @param amount Amount of tokens purchased.
     */
    event TokensPurchased(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

    /// @notice Event for finalization of the crowdsale
    event CrowdsaleFinalized();

    /**
     * @notice Initializes main contract variables and transfers funds for the sale.
     * @dev Init function.
     * @param _funder The address that funds the token for crowdsale.
     * @param _token Address of the token being sold.
     * @param _paymentCurrency The currency the crowdsale accepts for payment. Can be ETH or token address.
     * @param _totalTokens The total number of tokens to sell in crowdsale.
     * @param _startTime Crowdsale start time.
     * @param _endTime Crowdsale end time.
     * @param _rate Number of token units a buyer gets per wei or token.
     * @param _goal Minimum amount of funds to be raised in weis or tokens.
     * @param _operator Address that can finalize crowdsale.
     * @param _pointList Address that will manage auction approvals.
     * @param _wallet Address where collected funds will be forwarded to.
     */
    function initCrowdsale(
        address _funder,
        address _token,
        address _paymentCurrency,
        uint256 _totalTokens,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        uint256 _goal,
        address _operator,
        address _pointList,
        address payable _wallet
    ) public {
        require(!marketStatus.initialized, "Crowdsale: already initialized"); 
        require(_startTime < 10000000000, 'Crowdsale: enter an unix timestamp in seconds, not miliseconds');
        require(_endTime < 10000000000, 'Crowdsale: enter an unix timestamp in seconds, not miliseconds');
        require(_startTime >= block.timestamp, "Crowdsale: start time is before current time");
        require(_endTime > _startTime, "Crowdsale: start time is not before end time");
        require(_rate > 0, "Crowdsale: rate is 0");
        require(_paymentCurrency != address(0), "Crowdsale: payment currency is the zero address");
        require(_wallet != address(0), "Crowdsale: wallet is the zero address");
        require(_operator != address(0), "Crowdsale: operator is the zero address");
        require(_totalTokens > 0, "Crowdsale: total tokens is 0");
        require(_goal > 0, "Crowdsale: goal is 0");

        marketPrice.rate = uint128(_rate);
        marketPrice.goal = uint128(_goal);

        marketInfo.startTime = uint64(_startTime);
        marketInfo.endTime = uint64(_endTime);
        marketInfo.totalTokens = uint128(_totalTokens);

        auctionToken = _token;
        paymentCurrency = _paymentCurrency;
        wallet = _wallet;
        operator = _operator;

        if (_pointList != address(0)) {
            pointList = _pointList;
            marketStatus.hasPointList = true;
        }

        require(_getTokenAmount(_goal) <= _totalTokens, "Crowdsale: goal should be equal to or lower than total tokens or equal");

        _safeTransferFrom(_token, _funder, _totalTokens);
        marketStatus.initialized = true;
    }


    ///--------------------------------------------------------
    /// Commit to buying tokens!
    ///--------------------------------------------------------

    receive() external payable {
        // revertBecauseUserDidNotProvideAgreement();
        // GP: Allow token direct transfers for testnet
        buyTokensEth(msg.sender, true);
    }


    function marketParticipationAgreement() public pure returns (string memory) {
        return "I understand that I'm interacting with a smart contract. I understand that tokens commited are subject to the token issuer and local laws where applicable. I reviewed code of the smart contract and understand it fully. I agree to not hold developers or other people associated with the project liable for any losses or misunderstandings";
    }
    /** 
     * @dev Not using modifiers is a purposeful choice for code readability.
    */ 
    function revertBecauseUserDidNotProvideAgreement() internal pure {
        revert("No agreement provided, please review the smart contract before interacting with it");
    }

    /**
     * @notice Checks the amount to commit and processes the buy. Refunds the buyer if commit is too high.
     * @dev low level token purchase with ETH ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param _beneficiary Recipient of the token purchase.
     */
    function buyTokensEth(
        address payable _beneficiary,
        bool readAndAgreedToMarketParticipationAgreement
    ) 
        public payable /* nonReentrant */   
    {
        require(paymentCurrency == ETH_ADDRESS, "Crowdsale: payment currency is not ETH"); 
        if(readAndAgreedToMarketParticipationAgreement == false) {
            revertBecauseUserDidNotProvideAgreement();
        }
        _preValidatePurchase(_beneficiary, msg.value);

        /// @notice Get ETH able to be committed.
        uint256 ethToTransfer = calculateCommitment(msg.value);

        /// @notice Accept ETH Payments.
        uint256 ethToRefund = msg.value.sub(ethToTransfer);
        if (ethToTransfer > 0) {
            _processBuy(_beneficiary, ethToTransfer);
        }

        /// @notice Return any ETH to be refunded.
        if (ethToRefund > 0) {
            _beneficiary.transfer(ethToRefund);
        }
    }

    /**
     * @notice Checks if the commitment doesn't exceed the goal of this sale.
     * @param _commitment Number of tokens to be commited.
     * @return committed The amount able to be purchased during a sale.
     */
    function calculateCommitment(uint256 _commitment)
        public
        view
        returns (uint256 committed)
    {
        if (uint256(marketStatus.amountRaised).add(_commitment) > uint256(marketPrice.goal)) {
            return uint256(marketPrice.goal).sub(uint256(marketStatus.amountRaised));
        }
        return _commitment;
    }

    /**
     * @notice Prevalidates purchase, transfers funds and processes the buy.
     * @dev Low level token purchase with a token ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param _beneficiary Recipient of the token purchase.
     * @param _tokenAmount Value in wei or token involved in the purchase.
     */
    function buyTokens(
        address _beneficiary,
        uint256 _tokenAmount,
        bool readAndAgreedToMarketParticipationAgreement
    ) 
        public /* nonReentrant */ 
    {
        require(paymentCurrency != ETH_ADDRESS, "Crowdsale: payment currency is not token");
        if(readAndAgreedToMarketParticipationAgreement == false) {
            revertBecauseUserDidNotProvideAgreement();
        }
        _preValidatePurchase(_beneficiary, _tokenAmount);
        _safeTransferFrom(paymentCurrency, msg.sender, _tokenAmount);
        _processBuy(_beneficiary, _tokenAmount);
    }

    /**
     * @notice Updates commitment of the buyer and the amount raised, emits an event.
     * @param beneficiary Recipient of the token purchase.
     * @param amount Value in wei or token involved in the purchase.
     */
    function _processBuy(address beneficiary, uint256 amount) internal {
        commitments[beneficiary] = commitments[beneficiary].add(amount);

        /// @notice Update state.
        // update state
        marketStatus.amountRaised = uint128(uint256(marketStatus.amountRaised).add(amount));

        emit TokensPurchased(msg.sender, beneficiary, amount, _getTokenAmount(amount));
    }

    /**
     * @notice Validation of an incoming purchase.
     * @param beneficiary Address performing the token purchase.
     * @param amount Value in wei or token involved in the purchase.
     */
    function _preValidatePurchase(address beneficiary, uint256 amount) internal view {
        require(block.timestamp >= uint256(marketInfo.startTime), "Crowdsale: not started");
        require(block.timestamp <= uint256(marketInfo.endTime), "Crowdsale: already closed");
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(amount != 0, "Crowdsale: amount is 0");
        if (marketStatus.hasPointList) {
            uint256 newCommitment = commitments[beneficiary].add(amount);
            require(IPointList(pointList).hasPoints(beneficiary, newCommitment));
        }
        uint256 tokensAvail = IERC20(auctionToken).balanceOf(address(this));
        require(_getTokenAmount(uint256(marketStatus.amountRaised).add(amount)) <= tokensAvail, "Crowdsale: amount of tokens exceeded");
    }

    function withdrawTokens() public  {
        withdrawTokens(msg.sender);
    }

    /**
     * @notice Withdraws bought tokens, or returns commitment if the sale is unsuccessful.
     * @dev Withdraw tokens only after crowdsale ends.
     * @param beneficiary Whose tokens will be withdrawn.
     */
    // GP: Think about moving to a safe transfer that considers the dust for the last withdraw
    function withdrawTokens(address payable beneficiary) public /* nonReentrant */ {    
        if (auctionSuccessful()) {
            require(marketStatus.finalized, "Crowdsale: not finalized");
            /// @dev Successful auction! Transfer claimed tokens.
            uint256 tokensToClaim = tokensClaimable(beneficiary);
            require(tokensToClaim > 0, "Crowdsale: no tokens to claim"); 
            claimed[beneficiary] = claimed[beneficiary].add(tokensToClaim);
            _tokenPayment(auctionToken, beneficiary, tokensToClaim);
        } else {
            /// @dev Auction did not meet reserve price.
            /// @dev Return committed funds back to user.

            require(block.timestamp > uint256(marketInfo.endTime), "Crowdsale: auction has not finished yet");
            uint256 accountBalance = commitments[beneficiary];
            /// @dev claimerBalance = tokensClaimable(beneficiary);
            /// @dev claimAmount = claimerBalance.div(uint256(marketPrice.rate));
            commitments[beneficiary] = 0; // Stop multiple withdrawals and free some gas
            _tokenPayment(paymentCurrency, beneficiary, accountBalance);
        }
    }

    /**
     * @notice Adjusts users commitment depending on amount already claimed and unclaimed tokens left.
     * @return claimerCommitment How many tokens the user is able to claim.
     */
    function tokensClaimable(address _user) public view returns (uint256 claimerCommitment) {
        uint256 unclaimedTokens = IERC20(auctionToken).balanceOf(address(this));
        claimerCommitment = _getTokenAmount(commitments[_user]);
        claimerCommitment = claimerCommitment.sub(claimed[_user]);
        /// @dev MZ: Is this good to calculate dust for last withdraw?
        /// @dev Does not transfer back the equivalent amount of dust.
        if(claimerCommitment > unclaimedTokens){
            claimerCommitment = unclaimedTokens;
        }
    }
    
    //--------------------------------------------------------
    // Finalize Auction
    //--------------------------------------------------------
    
    /**
     * @notice Manually finalizes the Crowdsale.
     * @dev Must be called after crowdsale ends, to do some extra finalization work.
     * Calls the contracts finalization function.
     */
    function finalize() public {
        require(            
            msg.sender == operator || finalizeTimeExpired(),
            "Crowdsale: sender must be an operator"
        );
        MarketStatus storage status = marketStatus;
        require(!status.finalized, "Crowdsale: already finalized");
        MarketInfo storage info = marketInfo;

        if (auctionSuccessful()) {
            /// @dev Successful auction
            /// @dev Transfer contributed tokens to wallet.
            require(auctionEnded(), "Crowdsale: Has not finished yet"); 
            _tokenPayment(paymentCurrency, wallet, uint256(status.amountRaised));
            /// @dev Transfer unsold tokens to wallet.
            uint256 soldTokens = _getTokenAmount(uint256(status.amountRaised));
            uint256 unsoldTokens = uint256(info.totalTokens).sub(soldTokens);
            if(unsoldTokens > 0) {
                _tokenPayment(auctionToken, wallet, unsoldTokens);
            }
        } else if ( block.timestamp <= uint256(info.startTime) ) {
            /// @dev Cancelled Auction
            /// @dev You can cancel the auction before it starts
            require( uint256(status.amountRaised) == 0, "Crowdsale: Funds already raised" );
            _tokenPayment(auctionToken, wallet, uint256(info.totalTokens));
        } else {
            /// @dev Failed auction
            /// @dev Return auction tokens back to wallet.
            require(auctionEnded(), "Crowdsale: Has not finished yet"); 
            _tokenPayment(auctionToken, wallet, uint256(info.totalTokens));
        }

        status.finalized = true;

        emit CrowdsaleFinalized();
    }

    /**
     * @notice Calculates the number of tokens to purchase.
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param amount Value in wei or token to be converted into tokens.
     * @return tokenAmount Number of tokens that can be purchased with the specified amount.
     */
    function _getTokenAmount(uint256 amount) internal view returns (uint256) {
        return amount.mul(uint256(marketPrice.rate));
    }

    /**
     * @notice Checks if the sale is open.
     * @return isOpen True if the crowdsale is open, false otherwise.
     */
    function isOpen() public view returns (bool) {
        return block.timestamp >= uint256(marketInfo.startTime) && block.timestamp <= uint256(marketInfo.endTime);
    }

    /**
     * @notice Checks if the sale minimum amount was raised.
     * @return auctionSuccessful True if the amountRaised is equal or higher than goal.
     */
    function auctionSuccessful() public view returns (bool) {
        return uint256(marketStatus.amountRaised) >= uint256(marketPrice.goal);
    }

    /**
     * @notice Checks if the sale has ended.
     * @return auctionEnded True if successful or time has ended.
     */
    function auctionEnded() public view returns (bool) {
        return block.timestamp > uint256(marketInfo.endTime) || _getTokenAmount(uint256(marketStatus.amountRaised)) == uint256(marketInfo.totalTokens);
    }

    /**
     * @return Returns true if market has been finalized
     */
    function finalized() public view returns (bool) {
        return marketStatus.finalized;
    }

    /**
     * @return True if 7 days have passed since the end of the auction
    */
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


    /**
     * @notice Decodes and hands Crowdsale data to the initCrowdsale function.
     * @param _data Encoded data for initialization.
     */
    function initMarket(bytes calldata _data) public {
        (
        address _funder,
        address _token,
        address _paymentCurrency,
        uint256 _totalTokens,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        uint256 _goal,
        address _operator,
        address _pointList,
        address payable _wallet
        ) = abi.decode(_data, (
            address,
            address,
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            address,
            address,
            address
            )
        );
    
        initCrowdsale(_funder, _token, _paymentCurrency, _totalTokens, _startTime, _endTime, _rate, _goal, _operator, _pointList, _wallet);
    }

    /**
     * @notice Collects data to initialize the crowd sale.
     * @param _funder The address that funds the token for crowdsale.
     * @param _token Address of the token being sold.
     * @param _paymentCurrency The currency the crowdsale accepts for payment. Can be ETH or token address.
     * @param _totalTokens The total number of tokens to sell in crowdsale.
     * @param _startTime Crowdsale start time.
     * @param _endTime Crowdsale end time.
     * @param _rate Number of token units a buyer gets per wei or token.
     * @param _goal Minimum amount of funds to be raised in weis or tokens.
     * @param _operator Address that can finalize crowdsale.
     * @param _pointList Address that will manage auction approvals.
     * @param _wallet Address where collected funds will be forwarded to.
     * @return _data All the data in bytes format.
     */
    function getCrowdsaleInitData(
        address _funder,
        address _token,
        address _paymentCurrency,
        uint256 _totalTokens,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        uint256 _goal,
        address _operator,
        address _pointList,
        address payable _wallet
    )
        external pure returns (bytes memory _data)
    {
        return abi.encode(
            _funder,
            _token,
            _paymentCurrency,
            _totalTokens,
            _startTime,
            _endTime,
            _rate,
            _goal,
            _operator,
            _pointList,
            _wallet
            );
    }

    function getMarketPrice() external view returns(uint128 rate, uint128 goal) {
        return (marketPrice.rate, marketPrice.goal);
    }

    function getMarketInfo() external view returns(address token, address _paymentCurrency, uint128 totalTokens, uint64 startTime, uint64 endTime) {
        return (auctionToken, paymentCurrency, marketInfo.totalTokens, marketInfo.startTime, marketInfo.endTime);
    }

    function getMarketStatus() external view returns(uint128 amountRaised, bool finalized, bool hasPointList) {
        return (marketStatus.amountRaised, marketStatus.finalized, marketStatus.hasPointList);
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