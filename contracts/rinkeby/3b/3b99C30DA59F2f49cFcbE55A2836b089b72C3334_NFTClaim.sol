pragma solidity 0.8.6;

import "INFTPool.sol";
import "IJellyAccessControls.sol";
import "IJellyRewarder.sol";
import "IJellyContract.sol";
// import "IERC20.sol";
import "BoringMath.sol";
import "Documents.sol";
import "SafeERC20.sol";
import "IERC721Enumerable.sol";

contract NFTClaim is  IJellyContract, Documents {

    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using BoringMath64 for uint64;
    using SafeERC20 for OZIERC20;

    /// @notice Jelly template id for the pool factory.
    uint256 public constant override TEMPLATE_TYPE = 2;
    bytes32 public constant override TEMPLATE_ID = keccak256("NFT_CLAIM");

    /// @notice Token to stake.
    address public poolToken;
    /// @notice Address that manages approvals.
    address public allowList;

    IJellyAccessControls public accessControls;
    IJellyRewarder public rewardsContract;

    struct TokenInfo {
        uint128 rewardsOwed;
        uint128 lastAccRewards;
    }
    /// @notice Mapping from token ID => reward token => reward info.
    mapping (uint256 => mapping (address => TokenInfo)) public tokenRewards;

    struct RewardInfo {
        uint64 lastUpdateTime;
        uint128 accRewardsPerToken;
    }

    /// @notice reward token address => accRewardsPerToken
    mapping(address => RewardInfo) public poolRewards;

    /// @notice Sets the token to be claimable or not (cannot claim if it set to false).
    bool public tokensClaimable;

    /// @notice Sets if the pool requires an approval to stake.
    bool public useList;

    /// @notice Whether staking has been initialised or not.
    bool private initialised;

    /**
     * @notice Event emitted when a user claims rewards.
     * @param user Address of the user.
     * @param reward Reward amount.
     */
    event RewardPaid(address indexed user, uint256 reward);
    /**
     * @notice Event emitted when claimable status is updated.
     * @param status True or False.
     */
    event ClaimableStatusUpdated(bool status);
    /**
     * @notice Event emitted when user unstaked in emergency mode.
     * @param user Address of the user.
     * @param amount Amount unstaked in tokens.
     */
    event EmergencyUnstake(address indexed user, uint256 amount);
    /**
     * @notice Event emitted when rewards contract has been updated.
     * @param oldRewardsToken Address of the old reward token contract.
     * @param newRewardsToken Address of the new reward token contract.
     */
    event RewardsContractUpdated(address indexed oldRewardsToken, address newRewardsToken);

    constructor() {

    }

    /**
     * @notice Admin can change rewards contract through this function.
     * @param _addr Address of the new rewards contract.
     */
    function setRewardsContract(address _addr) external  {
        require(accessControls.hasAdminRole(msg.sender), "JellyPool.setRewardsContract: Sender must be admin");
        require(_addr != address(0));
        emit RewardsContractUpdated(address(rewardsContract), _addr);
        rewardsContract = IJellyRewarder(_addr);
    }

    /**
     * @notice Admin can set reward tokens claimable through this function.
     * @param _enabled True or False.
     */
    function setTokensClaimable(bool _enabled) external    {
        require(accessControls.hasAdminRole(msg.sender), "setTokensClaimable: Sender must be admin");
        emit ClaimableStatusUpdated(_enabled);
        tokensClaimable = _enabled;
    }

    function totalSupply() public view returns (uint256 balance) {
        return IERC721Enumerable(poolToken).totalSupply();
    }

    function getOwnerTokens(address _owner) public returns (uint256[] memory tokenIds) {
        uint256 count = IERC721Enumerable(poolToken).balanceOf(_owner);
        for(uint i = 0; i < count; i++) {
            tokenIds[i] = IERC721Enumerable(poolToken).tokenOfOwnerByIndex(_owner,i);
        }
    }

    function ownerOf(uint256 _tokenId) public returns (address owner) {
        return IERC721Enumerable(poolToken).ownerOf(_tokenId);
    }


    // PW: This will go through all of the users tokenID
    // PW: TODO Rewrite to sum the total reward balances and only erc20 transfer once
    function claimUser(address _user) external  {
        // Get user NFT balance/list of token IDs
        uint256[] memory tokenIds = getOwnerTokens(_user);
        // loop through all token IDs
        // PW: This can be refactored 
        for(uint i = 0; i < tokenIds.length; i++) {
            claimId(tokenIds[i]);
        }
    }

    /**
     * @notice Claiming rewards for user.
     * @param _tokenId Token ID.
     */
    function claimId(uint256 _tokenId) public {
        require(
            tokensClaimable == true,
            "Tokens cannnot be claimed yet"
        );
        address user = ownerOf(_tokenId);

        updateReward(user);

        address[] memory rewardTokens = rewardsContract.rewardTokens(address(this));

        for(uint i = 0; i < rewardTokens.length; i++) {
            _claimRewards(_tokenId, rewardTokens[i]);
        }
    }

    /**
     * @notice Claiming rewards for user for specific rewards.
     * @param _tokenId Specific token ID.
     */
    function claimRewards(uint256 _tokenId, address[] calldata _rewardTokens) public {
        require(
            tokensClaimable == true,
            "Tokens cannnot be claimed yet"
        );
        address user = ownerOf(_tokenId);
        updateReward(user);

        for(uint i = 0; i < _rewardTokens.length; i++) {
            _claimRewards(_tokenId, _rewardTokens[i]);
        }
    }

    /**
     * @notice Claiming rewards for user.
     * @param _tokenId Token ID.
     */
    function _claimRewards(uint256 _tokenId, address _rewardToken) internal {

        address user = ownerOf(_tokenId);

        TokenInfo storage _tokenRewards =  tokenRewards[_tokenId][_rewardToken];
        uint256 payableAmount = uint256(_tokenRewards.rewardsOwed);
        _tokenRewards.rewardsOwed = 0;
        /// @dev accounts for dust, also overflows from erc20
        uint256 rewardBal =  OZIERC20(_rewardToken).balanceOf(address(this));

        if (payableAmount > rewardBal) {
            payableAmount = rewardBal;
        }
        OZIERC20(_rewardToken).safeTransfer(user, payableAmount);

        emit RewardPaid(user, payableAmount);
    }

    /// @dev Updates the amount of rewards owed for each user before any tokens are moved
    // PW: TODO: revert for an non existing user?

    function updateReward(
        address _user
    ) 
        public
    {
        address[] memory rewardTokens = rewardsContract.rewardTokens(address(this));
        uint256 count = IERC721Enumerable(poolToken).balanceOf(_user);
        _updatePoolRewards(rewardTokens);

        for(uint i = 0; i < rewardTokens.length; i++) {
            address rewardToken = rewardTokens[i];
            uint128 accRewardsPerToken = poolRewards[rewardToken].accRewardsPerToken;

            for(uint j = 0; j < count; j++) {
                uint256 tokenId = IERC721Enumerable(poolToken).tokenOfOwnerByIndex(_user,j);
                uint256 rewards = accRewardsPerToken -  tokenRewards[tokenId][rewardToken].lastAccRewards ;
                tokenRewards[tokenId][rewardToken] = TokenInfo(tokenRewards[tokenId][rewardToken].rewardsOwed + BoringMath.to128(rewards), accRewardsPerToken);
            }
        }
    }

    function _updatePoolRewards(address[] memory rewardTokens) internal {
        uint256 tSupply = IERC721Enumerable(poolToken).totalSupply();
        rewardsContract.updateRewards(address(this));
        for(uint i = 0; i < rewardTokens.length; i++) {
            address rewardToken = rewardTokens[i];
            uint256 lastRewardTime = uint256(poolRewards[rewardToken].lastUpdateTime); 
            uint256 currentRewards = rewardsContract.poolRewards(address(this), rewardToken, lastRewardTime, block.timestamp);
            // PW: need to check overflows
            uint128 accRewardsPerToken = poolRewards[rewardToken].accRewardsPerToken + BoringMath.to128(currentRewards * 1e18 / tSupply);
            poolRewards[rewardToken] = RewardInfo(BoringMath.to64(block.timestamp),accRewardsPerToken);
        }
    }

    /// @notice Returns the rewards owing for a token Id
    function rewardsOwing(
        uint256 _tokenId,
        address _rewardToken
    )
        public 
        view
        returns(uint256)
    {

        return uint256(poolRewards[_rewardToken].accRewardsPerToken - tokenRewards[_tokenId][_rewardToken].lastAccRewards);

    }


    /// @notice Returns the about of rewards yet to be claimed
    /// @return address[] reward tokens
    /// @return uint256[] unclaimed rewards
    function unclaimedRewards(address _user) public view returns(address[] memory, uint256[] memory) {

        address[] memory rTokens = rewardsContract.rewardTokens(address(this));
        uint256[] memory uRewards = new uint[](rTokens.length);

        for(uint i = 0; i < rTokens.length; i++) {
            uRewards[i] = unclaimedRewards( _user,  rTokens[i]);
        }

        return (rTokens, uRewards);
    }

    function unclaimedRewards(address _user, address _rewardToken) public view returns(uint256) {

    }

    function unclaimedRewards(uint256 _tokenId, address _rewardToken) public view returns(uint256) {
        uint256 currentRewards = rewardsContract.poolRewards(address(this), _rewardToken, uint256(poolRewards[_rewardToken].lastUpdateTime), block.timestamp);    
        uint256 accRewardsPerToken = poolRewards[_rewardToken].accRewardsPerToken + currentRewards;
        uint256 rewards = accRewardsPerToken - tokenRewards[_tokenId][_rewardToken].lastAccRewards;
        return rewards;
    }


    //--------------------------------------------------------
    // Documents
    //--------------------------------------------------------

    function setDocument(string calldata _name, string calldata _data) external {
        require(accessControls.hasAdminRole(msg.sender) );
        _setDocument( _name, _data);
    }

    function setDocuments(string[] calldata _name, string[] calldata _data) external {
        require(accessControls.hasAdminRole(msg.sender) );
        uint256 numDocs = _name.length;
        for (uint256 i = 0; i < numDocs; i++) {
            _setDocument( _name[i], _data[i]);
        }
    }

    function removeDocument(string calldata _name) external {
        require(accessControls.hasAdminRole(msg.sender));
        _removeDocument(_name);
    }

    /**
     * @notice Initializes main contract variables.
     * @dev Init function.
     * @param _poolToken Address of the pool token.
     * @param _accessControls Access controls interface.

     */
    function initNFTPool(
        address _poolToken,
        address _accessControls
    ) public 
    {
        require(!initialised, "Already initialised");
        poolToken = _poolToken;
        accessControls = IJellyAccessControls(_accessControls);
        initialised = true;
    }

    function init(bytes calldata _data) external override payable {}

    function initContract(
        bytes calldata _data
    ) public override {
        (
        address _poolToken,
        address _accessControls
        ) = abi.decode(_data, (address, address));

        initNFTPool(
                        _poolToken,
                        _accessControls
                    );
    }

   /** 
     * @dev Generates init data for Farm Factory
  */
    function getInitData(
        address _poolToken,
        address _accessControls
    )
        external
        pure
        returns (bytes memory _data)
    {
        return abi.encode(
                        _poolToken,
                        _accessControls
                        );
    }

}

pragma solidity 0.8.6;

interface INFTPool {


    function setRewardsContract(address _addr) external;
    function setTokensClaimable(bool _enabled) external;

    function getStakedBalance(address _user) external view returns (uint256 balance);
    function stakedTokenTotal() external  view returns (uint256);
    function rewardsOwing(address _user, address _rewardToken) external view returns (uint256 rewards);

    function claimRewards(address _user) external;
    function updateReward(address _user) external;

    /**
     * @notice Event emmited when a user has staked NFTs.
     * @param owner Address of the staker.
     * @param tokenId Token ID that was staked
     */
    event Staked(address indexed owner, uint256 tokenId);

    /**
     * @notice Event emitted when a user has unstaked NFTs.
     * @param owner Address of the unstaker.
     * @param tokenId Token ID that was staked
     */
    event Unstaked(address indexed owner, uint256 tokenId);


}

pragma solidity 0.8.6;

interface IJellyAccessControls {
    function hasAdminRole(address _address) external  view returns (bool);
    function addAdminRole(address _address) external;
    function removeAdminRole(address _address) external;
    function hasMinterRole(address _address) external  view returns (bool);
    function addMinterRole(address _address) external;
    function removeMinterRole(address _address) external;
    function hasOperatorRole(address _address) external  view returns (bool);
    function addOperatorRole(address _address) external;
    function removeOperatorRole(address _address) external;
    function initAccessControls(address _admin) external ;

}

pragma solidity 0.8.6;

interface IJellyRewarder {

    // function setRewards( 
    //     uint256[] memory rewardPeriods, 
    //     uint256[] memory amounts
    // ) external;
    // function setBonus(
    //     uint256 poolId,
    //     uint256[] memory rewardPeriods,
    //     uint256[] memory amounts
    // ) external;
    function updateRewards() external returns(bool);
    function updateRewards(address _pool) external returns(bool);

    function totalRewards(address _poolAddress) external view returns (uint256 rewards);
    function totalRewards() external view returns (address[] memory, uint256[] memory);
    // function poolRewards(uint256 _pool, uint256 _from, uint256 _to) external view returns (uint256 rewards);
    function poolRewards(address _pool, address _rewardToken, uint256 _from, uint256 _to) external view returns (uint256 rewards);

    function rewardTokens() external view returns (address[] memory rewards);
    function rewardTokens(address _pool) external view returns (address[] memory rewards);


    function addPoolContract(address _tokenPool, uint256 _poolPoints) external;
    function setPoolPoints(address _poolAddress, uint256 _poolPoints) external;

    function setVault(address _addr) external;
    function addRewardsToPool(
        address _poolAddress,
        address _rewardAddress,
        uint256 _startTime,
        uint256 _duration,
        uint256 _amount

    ) external ;

}

pragma solidity 0.8.6;

import "IMasterContract.sol";

interface IJellyContract is IMasterContract {
    /// @notice Init function that gets called from `BoringFactory.deploy`.
    /// Also kown as the constructor for cloned contracts.

    function TEMPLATE_ID() external view returns(bytes32);
    function TEMPLATE_TYPE() external view returns(uint256);
    function initContract( bytes calldata data ) external;

}

pragma solidity 0.8.6;

interface IMasterContract {
    /// @notice Init function that gets called from `BoringFactory.deploy`.
    /// Also kown as the constructor for cloned contracts.
    /// Any ETH send to `BoringFactory.deploy` ends up here.
    /// @param data Can be abi encoded arguments or anything else.
    function init(bytes calldata data) external payable;
}

pragma solidity 0.8.6;

interface IERC20 {

    /// @notice ERC20 Functions 
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity 0.8.6;

/// @notice A library for performing overflow-/underflow-safe math,
/// updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math).
library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b == 0 || (c = a * b) / b == a, "BoringMath: Mul Overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0, "BoringMath: Div zero");
        c = a / b;
    }

    function to224(uint256 a) internal pure returns (uint224 c) {
        require(a <= type(uint224).max, "BoringMath: uint224 Overflow");
        c = uint224(a);
    }

    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= type(uint128).max, "BoringMath: uint128 Overflow");
        c = uint128(a);
    }

    function to64(uint256 a) internal pure returns (uint64 c) {
        require(a <= type(uint64).max, "BoringMath: uint64 Overflow");
        c = uint64(a);
    }

    function to48(uint256 a) internal pure returns (uint48 c) {
        require(a <= type(uint48).max, "BoringMath: uint48 Overflow");
        c = uint48(a);
    }

    function to32(uint256 a) internal pure returns (uint32 c) {
        require(a <= type(uint32).max, "BoringMath: uint32 Overflow");
        c = uint32(a);
    }

    function to16(uint256 a) internal pure returns (uint16 c) {
        require(a <= type(uint16).max, "BoringMath: uint16 Overflow");
        c = uint16(a);
    }

    function to8(uint256 a) internal pure returns (uint8 c) {
        require(a <= type(uint8).max, "BoringMath: uint8 Overflow");
        c = uint8(a);
    }

}


/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint224.
library BoringMath224 {
    function add(uint224 a, uint224 b) internal pure returns (uint224 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint224 a, uint224 b) internal pure returns (uint224 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}


/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint128.
library BoringMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint64.
library BoringMath64 {
    function add(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint48.
library BoringMath48 {
    function add(uint48 a, uint48 b) internal pure returns (uint48 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint48 a, uint48 b) internal pure returns (uint48 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint32.
library BoringMath32 {
    function add(uint32 a, uint32 b) internal pure returns (uint32 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint32 a, uint32 b) internal pure returns (uint32 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint32.
library BoringMath16 {
    function add(uint16 a, uint16 b) internal pure returns (uint16 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint16 a, uint16 b) internal pure returns (uint16 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint8.
library BoringMath8 {
    function add(uint8 a, uint8 b) internal pure returns (uint8 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint8 a, uint8 b) internal pure returns (uint8 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

pragma solidity 0.8.6;
// pragma experimental ABIEncoderV2;


/**
 * @title Standard implementation of ERC1643 Document management
 */
contract Documents {

    struct Document {
        uint32 docIndex;    // Store the document name indexes
        uint64 lastModified; // Timestamp at which document details was last modified
        string data; // data of the document that exist off-chain
    }

    // mapping to store the documents details in the document
    mapping(string => Document) internal _documents;
    // mapping to store the document name indexes
    mapping(string => uint32) internal _docIndexes;
    // Array use to store all the document name present in the contracts
    string[] _docNames;

    // Document Events
    event DocumentRemoved(string indexed _name, string _data);
    event DocumentUpdated(string indexed _name, string _data);

    /**
     * @notice Used to attach a new document to the contract, or update the data or hash of an existing attached document
     * @dev Can only be executed by the owner of the contract.
     * @param _name Name of the document. It should be unique always
     * @param _data Off-chain data of the document from where it is accessible to investors/advisors to read.
     */
    function _setDocument(string calldata _name, string calldata _data) internal {
        require(bytes(_name).length > 0, "Zero name is not allowed");
        require(bytes(_data).length > 0, "Should not be a empty data");
        // Document storage document = _documents[_name];
        if (_documents[_name].lastModified == uint64(0)) {
            _docNames.push(_name);
            _documents[_name].docIndex = uint32(_docNames.length);
        }
        _documents[_name] = Document(_documents[_name].docIndex, uint64(block.timestamp), _data);
        emit DocumentUpdated(_name, _data);
    }

    /**
     * @notice Used to remove an existing document from the contract by giving the name of the document.
     * @dev Can only be executed by the owner of the contract.
     * @param _name Name of the document. It should be unique always
     */

    function _removeDocument(string calldata _name) internal {
        require(_documents[_name].lastModified != uint64(0), "Document should exist");
        uint32 index = _documents[_name].docIndex - 1;
        if (index != _docNames.length - 1) {
            _docNames[index] = _docNames[_docNames.length - 1];
            _documents[_docNames[index]].docIndex = index + 1; 
        }
        _docNames.pop();
        emit DocumentRemoved(_name, _documents[_name].data);
        delete _documents[_name];
    }

    /**
     * @notice Used to return the details of a document with a known name (`string`).
     * @param _name Name of the document
     * @return string The data associated with the document.
     * @return uint256 the timestamp at which the document was last modified.
     */
    function getDocument(string calldata _name) external view returns (string memory, uint256) {
        return (
            _documents[_name].data,
            uint256(_documents[_name].lastModified)
        );
    }

    /**
     * @notice Used to retrieve a full list of documents attached to the smart contract.
     * @return string List of all documents names present in the contract.
     */
    function getAllDocuments() external view returns (string[] memory) {
        return _docNames;
    }

    /**
     * @notice Used to retrieve the total documents in the smart contract.
     * @return uint256 Count of the document names present in the contract.
     */
    function getDocumentCount() external view returns (uint256) {
        return _docNames.length;
    }

    /**
     * @notice Used to retrieve the document name from index in the smart contract.
     * @return string Name of the document name.
     */
    function getDocumentName(uint256 _index) external view returns (string memory) {
        require(_index < _docNames.length, "Index out of bounds");
        return _docNames[_index];
    }

}

pragma solidity ^0.8.0;

import "OZIERC20.sol";
import "Address.sol";

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
        OZIERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        OZIERC20 token,
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
        OZIERC20 token,
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
        OZIERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        OZIERC20 token,
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
    function _callOptionalReturn(OZIERC20 token, bytes memory data) private {
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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface OZIERC20 {
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

pragma solidity ^0.8.0;

import "IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

pragma solidity ^0.8.0;

import "IERC165.sol";

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