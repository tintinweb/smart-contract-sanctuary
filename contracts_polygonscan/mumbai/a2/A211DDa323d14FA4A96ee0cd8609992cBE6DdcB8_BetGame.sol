/**
 *Submitted for verification at polygonscan.com on 2021-12-20
*/

// SPDX-License-Identifier: APACHE LICENSE 2.0
pragma solidity 0.8.10;


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    function decimals() external view returns (uint8);

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


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)
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


/**
A lottery game that belongs to CryptoAnimalGameDAO
*/
contract BetGame {

    using SafeERC20 for IERC20;

    address[] public acceptedCoins;
    mapping(address => bool) public isAcceptedCoins;
    address[] public acceptedNFTs;
    mapping(address => bool) public isAcceptedNFTs;

    mapping(uint8 => mapping(address => bool)) public bets;
    uint public totalPlayers;
    uint8 public winnerNFTIndex;
    uint public whenWinnerWasSet;

    address payable public owner;
    address payable public daoAddress;
    address payable public donationAddress;
    address payable public daoDevAddress;

    uint constant public betAmount = 5;

    uint public lotteryBlock;
    
    uint8 constant public version = 1;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this operation");
        _;
    }

    event NewAcceptedCoin(address coin);
    event NewAcceptedNFT(address nft);
    event HoneypotHasChanged(address paymentToken, uint newTotalPrize, address NFT);

    /*    
    @notice Collect initial information to setup a Bet Game
    @param _lotteryBlock in which Ethereum block the game will start to collect players point
    @param _daoAddress DAO address that will receive part of bet values
    @paran _donationAddress third-party institution will receive part of bet values
    @param _daoDevAddress Developer's DAO that will receive his part
    */
    constructor(uint _lotteryBlock, address payable _daoAddress, address payable _donationAddress, address payable _daoDevAddress) payable {
        owner = payable(msg.sender);
        require(_lotteryBlock > block.number+10, "Minimum 10 blocks to receive bets");
        lotteryBlock = _lotteryBlock;
        daoAddress = _daoAddress;
        donationAddress = _donationAddress;
        daoDevAddress = _daoDevAddress;
    }

    /**
    @notice Add a new coin to the list of acceptable coins to pay the bet
    @param _coinAddress the new stable coin accepted to place a bet
    */
    function addAcceptedCoin(address _coinAddress) external onlyOwner returns (bool) {
        require(_coinAddress != address(0x0), "Invalid address");
        require(listContains(acceptedCoins, _coinAddress) == 0, "Coin already added");
        acceptedCoins.push(_coinAddress);
        isAcceptedCoins[_coinAddress] = true;
        emit NewAcceptedCoin(_coinAddress);
        return true;
    }

    /**
    @notice inform total of accepted coins 
    */
    function totalAcceptedCoins() public view returns (uint) {
        return acceptedCoins.length;
    }

    /**
    @notice Add a new NFT to the list of acceptable NFT to place a bet
    @param _nftAddress the new NFT accepted to place a bet
    */
    function addAcceptedNFT(address _nftAddress) external onlyOwner returns (bool) {
        require(_nftAddress != address(0x0), "Invalid address");
        require(listContains(acceptedNFTs, _nftAddress) == 0, "NFT already added");
        require(acceptedNFTs.length < 64, "Only 64 NFT type are accepted");
        acceptedNFTs.push(_nftAddress);
        isAcceptedNFTs[_nftAddress] = true;
        emit NewAcceptedCoin(_nftAddress);
        return true;
    }

    /**
    @notice inform total of accepted NFTs 
    */
    function totalAcceptedNFT() public view returns (uint) {
        return acceptedNFTs.length;
    }

    /**
    @notice allow player to place a bet
    @param _coin the coin to pay the bet
    @param _nft NFT in which the player is betting
    */
    function placeBet(address _coin, address _nft) external returns (bool)  {
        require( isAcceptedCoins[ _coin ] && isAcceptedNFTs[ _nft ], "Not accepted" );
        require(IERC20( _nft ).balanceOf(msg.sender)>0, "Need to have NFT to play");
        require(winnerNFTIndex == 0, "The game is closed");
        uint amount = betAmount * (10 ** IERC20( _coin ).decimals());
        IERC20( _coin ).safeTransferFrom( msg.sender, address(this), amount );
        bets[uint8(listContains(acceptedNFTs, _nft))][msg.sender] = true; 
        totalPlayers++;
        emit HoneypotHasChanged(_coin, calcPercentage(IERC20( _coin ).balanceOf(address(this)), 50), _nft);
        return true;
    }

    /**
    @notice set the animal winner of the game and pays the DAO, Devs and Donation beneficiary
    @param _nftIndex winner animal index
    */
    function setWinner(uint8 _nftIndex) onlyOwner external returns (bool) {
        require(winnerNFTIndex == 0, "The game is closed");
        require(_nftIndex < acceptedNFTs.length, "Invalid NFT index");
        require(block.number > lotteryBlock, "The lottery was not happened yet");
        winnerNFTIndex = _nftIndex+1;
        whenWinnerWasSet = block.timestamp;
        bool makePayment;
        for (uint i=0; i < acceptedCoins.length; i++) {
            uint balance = IERC20( acceptedCoins[i] ).balanceOf(address(this));
            if (balance > 0) {
                IERC20( acceptedCoins[i] ).safeTransfer(daoAddress, calcPercentage(balance, 40));
                IERC20( acceptedCoins[i] ).safeTransfer(donationAddress, calcPercentage(balance, 5));
                IERC20( acceptedCoins[i] ).safeTransfer(daoDevAddress, calcPercentage(balance, 5));
                makePayment = true;
            }
        }
        return makePayment;
    }

    /**
    @notice allow player to retrieve her prize
    */
    function retrievePrize() external returns (bool) {
        require(winnerNFTIndex > 0, "The game is not closed");
        require(bets[winnerNFTIndex-1][msg.sender], "You are not one of winners");
        bool makePayment;
        for (uint i=0; i < acceptedCoins.length; i++) {
            uint balance = IERC20( acceptedCoins[i] ).balanceOf(address(this));
            if (balance > 0) {
                balance = calcPercentage(balance, 50);
                balance = balance / totalPlayers;
                IERC20( acceptedCoins[i] ).safeTransfer(msg.sender, balance);
                makePayment = true;
            }
        }
        return makePayment;
    }


    /**
    @notice After one week the DAO can retrieve all non collected prizes
    */
    function endOperation() onlyOwner external returns (bool) {
        require(block.timestamp > (whenWinnerWasSet+604800), "Players still can redeem their prizes");
        bool makePayment;
        for (uint i=0; i < acceptedCoins.length; i++) {
            uint balance = IERC20( acceptedCoins[i] ).balanceOf(address(this));
            if (balance > 0) {                
                IERC20( acceptedCoins[i] ).safeTransfer(daoAddress, balance);
                makePayment = true;
            }
        }
        return makePayment;
    }

    /**
    @notice checks array to ensure against duplicate
    @param _list address[]
    @param _token address
    @return uint index number of item
     */
    function listContains( address[] storage _list, address _token ) internal view returns ( uint ) {
        for( uint i = 0; i < _list.length; i++ ) {
            if( _list[ i ] == _token ) {
                return i+1;
            }
        }
        return 0;
    }

    /**
    @notice helper function that calculates percentual of value 
    @param _total total to be divided
    @param _perc the percentual 
    */
    function calcPercentage(uint _total, uint _perc) pure public returns (uint) {
        if (_total < 1 || _perc < 1 || _perc > 99) {
            return 0;
        }
        return (_total * _perc) / 100;
    }
}