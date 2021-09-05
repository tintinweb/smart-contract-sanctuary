/**
 *Submitted for verification at BscScan.com on 2021-09-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract ERC721Holder is IERC721Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

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

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TokenRecover is Ownable {
    function recoverERC20(address tokenAddress, uint256 tokenAmount) public virtual onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract GuildRentalContract is Ownable, TokenRecover, ERC721Holder {

    using SafeERC20 for IERC20;

    IERC20 public Token;
    IERC721 public Factory;

    uint256 public Guild_Creation_Fee = 5 * 1E18;
    uint256 public Guild_Utility_Fee = 1 * 1E18;
    // uint256 public Guild_Royalty_Tax = 1; 

    struct Guild {
        string guild_id;
        uint role;
    }

    struct Listing {
        address owner;
        address borrower;
        uint256 nftId;
        uint256 timestamp;
        uint256 listingId;
        string guildId;
        uint256 o_reward;
        uint256 b_reward;
    }

    mapping (address => Guild) public guilds;

    Listing[] public _listings;
    uint256 public totalListing = 0;

    mapping (address => bool) private gameMaster;
    mapping (address => uint) public rentals;


    uint public ownerShare = 70;
    uint public borrowerShare = 30;
    uint public duration = 43200 minutes; // 30 days
    uint256 public LIST_FEE = 0.01 * 1E18;

    event GuildCreation(address indexed account, uint256 fee, string guildId);

    event Listed(address indexed account, uint256 id, string guildId, uint256 listId, uint256 totalListing);
    event RewardClaimed(address indexed account, uint256 reward);
    event Rent(address indexed account, uint256 listId);
    event Restaked(address indexed account, uint256 id, uint256 listId);
    event Withdrawn(address indexed account, uint256 id, uint256 listId);

    constructor(address _token, address _factory) {
        Token = IERC20(_token);
        Factory = IERC721(_factory);
    }

    function setFee(uint256 _creation, uint256 _utility) external onlyOwner {
        Guild_Creation_Fee = _creation;
        Guild_Utility_Fee = _utility;
    }

    // function setTax(uint _tax) external onlyOwner {
    //     Guild_Royalty_Tax = _tax;
    // }

    function createGuild(string calldata _guild_id) external {
        require(Token.balanceOf(msg.sender) >= Guild_Creation_Fee , "Insufficient balance.");
        require(Token.approve(address(this), Guild_Creation_Fee) , "Insufficient allowance.");  

        string memory empty = "";
        require(keccak256(bytes(guilds[msg.sender].guild_id)) == keccak256(bytes(empty)), "Caller already joined a guild.");

        guilds[msg.sender].guild_id = _guild_id;
        guilds[msg.sender].role = 0;  

        Token.safeTransferFrom(msg.sender, address(this), Guild_Creation_Fee);
        emit GuildCreation(msg.sender, Guild_Creation_Fee, _guild_id);
    }

    function joinGuild(string calldata _guild_id) external {
        require(Token.balanceOf(msg.sender) >= Guild_Utility_Fee , "Insufficient balance.");
        require(Token.approve(address(this), Guild_Utility_Fee) , "Insufficient allowance.");  

        string memory empty = "";
        require(keccak256(bytes(guilds[msg.sender].guild_id)) == keccak256(bytes(empty)), "Caller already joined a guild.");

        Token.safeTransferFrom(msg.sender, address(this), Guild_Creation_Fee);
    }

    function approveGuildMember(address _account, string calldata _guild_id) external {
        require(Token.balanceOf(msg.sender) >= Guild_Utility_Fee  , "Insufficient balance.");   
        require(Token.approve(address(this), Guild_Utility_Fee) , "Insufficient allowance.");    

        string memory empty = "";
        require(keccak256(bytes(guilds[msg.sender].guild_id)) == keccak256(bytes(empty)), "Address already joined a guild.");
        require(keccak256(bytes(guilds[msg.sender].guild_id)) == keccak256(bytes(_guild_id)), "Wrong guild.");        
        require(guilds[msg.sender].role <= 1, "Leader or co-leader permission required.");

        guilds[_account].guild_id = _guild_id;
        guilds[_account].role = 2;

        Token.safeTransferFrom(msg.sender, address(this), Guild_Utility_Fee);
    }

    function promoteGuildMember(address _account, string calldata _guild_id) external {
        require(Token.balanceOf(msg.sender) >= Guild_Utility_Fee  , "Insufficient balance.");   
        require(Token.approve(address(this), Guild_Utility_Fee) , "Insufficient allowance.");    
        require(keccak256(bytes(guilds[msg.sender].guild_id)) == keccak256(bytes(_guild_id)), "Wrong guild.");  
        
        require(guilds[msg.sender].role <= 1, "Leader or co-leader permission required.");
        require(guilds[msg.sender].role < guilds[_account].role, "Higher role required.");

        if (guilds[_account].role > 0) {
            guilds[_account].role = guilds[_account].role - 1;
        }

        Token.safeTransferFrom(msg.sender, address(this), Guild_Utility_Fee);
    }


    function demoteGuildMember(address _account, string calldata _guild_id) external {
        require(Token.balanceOf(msg.sender) >= Guild_Utility_Fee  , "Insufficient balance.");   
        require(Token.approve(address(this), Guild_Utility_Fee) , "Insufficient allowance.");    
        require(keccak256(bytes(guilds[msg.sender].guild_id)) == keccak256(bytes(_guild_id)), "Wrong guild.");  
        require(guilds[msg.sender].role <= 1, "Leader or co-leader permission required.");
        require(guilds[msg.sender].role < guilds[_account].role, "Higher role required.");

        if (guilds[_account].role < 2) {
            guilds[_account].role = guilds[_account].role + 1;
        }

        Token.safeTransferFrom(msg.sender, address(this), Guild_Utility_Fee);
    }

    function kickGuildMember(address _account, string calldata _guild_id) external {
        require(Token.balanceOf(msg.sender) >= Guild_Utility_Fee  , "Insufficient balance.");   
        require(Token.approve(address(this), Guild_Utility_Fee) , "Insufficient allowance.");    
        require(keccak256(bytes(guilds[msg.sender].guild_id)) == keccak256(bytes(_guild_id)), "Wrong guild.");  
        require(guilds[msg.sender].role <= 1, "Leader or co-leader permission required.");
        require(guilds[msg.sender].role < guilds[_account].role, "Higher role required.");

        guilds[_account].guild_id = "";
        guilds[_account].role = 4;

        Token.safeTransferFrom(msg.sender, address(this), Guild_Utility_Fee);
    }

    function leaveGuildMember() external {
        require(Token.balanceOf(msg.sender) >= Guild_Utility_Fee  , "Insufficient balance.");   
        require(Token.approve(address(this), Guild_Utility_Fee) , "Insufficient allowance.");   

        string memory empty = "";
        require(keccak256(bytes(guilds[msg.sender].guild_id)) != keccak256(bytes(empty)), "Wrong guild.");  

        guilds[msg.sender].guild_id = "";
        guilds[msg.sender].role = 4;

        Token.safeTransferFrom(msg.sender, address(this), Guild_Utility_Fee);
    }

    receive() external payable { }

    function withdrawBNB(address _account) external onlyOwner {
        (bool success,) = _account.call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }




    function listNFT(uint256 _id) payable external {
        require(Factory.ownerOf(_id) == msg.sender, "Insufficient balance");
        require(Factory.isApprovedForAll(msg.sender, address(this)), "Insufficient allowance");
        require(msg.value >= LIST_FEE, "Insufficient fee.");
        
        string memory empty = "";
        require(keccak256(bytes(guilds[msg.sender].guild_id)) != keccak256(bytes(empty)), "Guild required.");  

        uint listId = _listings.length;
        _listings.push();
        Listing storage lis = _listings[listId];

        lis.owner = msg.sender;
        lis.nftId = _id;
        lis.timestamp = block.timestamp;
        lis.listingId = listId;
        lis.guildId = guilds[msg.sender].guild_id;
        lis.borrower = address(0);
        lis.o_reward = 0;
        lis.b_reward = 0;

        totalListing += 1;

        (bool success,) = address(this).call{value: msg.value}("");
        require(success, "Failed to send Ether");

        Factory.safeTransferFrom(msg.sender, address(this), _id);
        emit Listed(msg.sender, _id, guilds[msg.sender].guild_id, listId, totalListing);
    }



    function rentNFT(uint256 _listId) external {
        Listing storage lis = _listings[_listId];
        require( (lis.timestamp + duration) < block.timestamp, "Listing is not available.");
        require(lis.borrower != address(0), "Listing occupied.");
        require(lis.owner != msg.sender, "Caller is listing owner.");

        require(keccak256(bytes(lis.guildId)) != keccak256(bytes(guilds[msg.sender].guild_id)), "Guild required."); 

        lis.borrower = msg.sender;
        rentals[msg.sender] += 1;

        emit Rent(msg.sender, _listId);
    }

    function rentalOf(address _borrower) public view returns (Listing[] memory) {
        Listing[] memory lis = new Listing[](rentals[_borrower]);
        uint counter;
        for(uint i = 0; i < _listings.length; i++) {
            if (_listings[i].borrower == _borrower) continue;
                lis[counter] = _listings[i];
                counter++;
        }
        return lis;
    }

    function openListing(string calldata _guild_id) public view returns (Listing[] memory) {
        Listing[] memory lis = new Listing[](totalListing);
        uint counter;
        for(uint i = 0; i < _listings.length; i++) {
            if ( (_listings[i].timestamp + duration) > block.timestamp || keccak256(bytes( _listings[i].guildId)) != keccak256(bytes(_guild_id)) || _listings[i].borrower != address(0) ) continue;
                lis[counter] = _listings[i];
                counter++;
        }
        return lis;
    }

    function closeListing(string calldata _guild_id) public view returns (Listing[] memory) {
        Listing[] memory lis = new Listing[](_listings.length - totalListing);
        uint counter;
        for(uint i = 0; i < _listings.length; i++) {
            if ( (_listings[i].timestamp + duration) < block.timestamp || keccak256(bytes( _listings[i].guildId)) != keccak256(bytes(_guild_id)) || _listings[i].borrower != address(0) ) continue;
                lis[counter] = _listings[i];
                counter++;
        }
        return lis;
    }

    function rentedListing(string calldata _guild_id) public view returns (Listing[] memory) {
        Listing[] memory lis = new Listing[](totalListing);
        uint counter;
        for(uint i = 0; i < _listings.length; i++) {
            if ( (_listings[i].timestamp + duration) > block.timestamp || keccak256(bytes( _listings[i].guildId)) != keccak256(bytes(_guild_id)) || _listings[i].borrower == address(0) ) continue;
                lis[counter] = _listings[i];
                counter++;
        }
        return lis;
    }

    function expiredListing(string calldata _guild_id, address _account) public view returns (Listing[] memory) {
        Listing[] memory lis = new Listing[](totalListing);
        uint counter;
        for(uint i = 0; i < _listings.length; i++) {
            if ( (_listings[i].timestamp + duration) < block.timestamp || keccak256(bytes( _listings[i].guildId)) != keccak256(bytes(_guild_id)) || ( _listings[i].borrower != _account && _listings[i].owner != _account ) ) continue;
                lis[counter] = _listings[i];
                counter++;
        }
        return lis;
    }

    function claimReward(uint256 _listId, bool _restake) payable external {
        Listing storage lis = _listings[_listId];
        require( lis.owner == msg.sender || lis.borrower == msg.sender, "Caller is not owner or borrower");
        require( (lis.timestamp + duration) > block.timestamp, "Listing locked.");
        require( lis.o_reward > 0 || lis.b_reward > 0, "Nothing to claim.");

        if(msg.sender == lis.owner) {
            require( lis.o_reward > 0, "No reward to owner.");
            uint256 amount = lis.o_reward;
            lis.o_reward = 0;
            Token.safeTransferFrom(address(this), msg.sender, amount);
            emit RewardClaimed(msg.sender, amount);
            totalListing -= 1;

            if(_restake) {

                require(msg.value >= LIST_FEE, "Insufficient fee.");

                string memory empty = "";
                require(keccak256(bytes(guilds[msg.sender].guild_id)) != keccak256(bytes(empty)), "Guild required.");  

                uint NlistId = _listings.length;
                _listings.push();
                Listing storage Nlis = _listings[NlistId];

                Nlis.owner = msg.sender;
                Nlis.nftId = lis.nftId;
                Nlis.timestamp = block.timestamp;
                Nlis.listingId = NlistId;
                Nlis.guildId = guilds[msg.sender].guild_id;
                Nlis.borrower = address(0);
                Nlis.o_reward = 0;
                Nlis.b_reward = 0;

                totalListing += 1;

                (bool success,) = address(this).call{value: msg.value}("");
                require(success, "Failed to send Ether");

                emit Listed(msg.sender, lis.nftId, guilds[msg.sender].guild_id, NlistId, totalListing);
            } else {
                Factory.safeTransferFrom(address(this), msg.sender, lis.nftId);
                emit Withdrawn(msg.sender, lis.nftId, _listId);
            }

        } else if(msg.sender == lis.borrower) {
            require( lis.b_reward > 0, "No reward to borrower.");
            uint256 amount = lis.b_reward;
            lis.b_reward = 0;
            Token.safeTransferFrom(address(this), msg.sender, amount);
            emit RewardClaimed(msg.sender, amount);
        }

    }

    function setGameMaster(address _gm, bool _allow) external onlyOwner {
        gameMaster[msg.sender] = _allow;
    }

    function isGameMaster(address _address) public view returns (bool) {
        return gameMaster[_address];
    }

    function setShare(uint _ownerShare, uint _borrowerShare) external onlyOwner {
        borrowerShare = _borrowerShare;
        ownerShare = _ownerShare;
    }

    function distributeReward(uint256 _listId, uint256 _amount) external {
        Listing storage lis = _listings[_listId];
        require(isGameMaster(msg.sender), "Caller is not game master.");

        uint256 total = _amount;
        uint256 tOwener = total * ownerShare / 100;
        uint256 tBorrower = total * borrowerShare / 100;

        lis.o_reward = tOwener;
        lis.b_reward = tBorrower;
    }

    function setDuration(uint _duration) external onlyOwner {
        duration = _duration * 1 minutes;
    }

    function setListFee(uint256 _fee) external onlyOwner {
        LIST_FEE = _fee;
    }

}