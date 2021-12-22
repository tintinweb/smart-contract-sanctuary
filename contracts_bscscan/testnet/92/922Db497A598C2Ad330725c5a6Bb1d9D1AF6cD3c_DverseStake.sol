/**
 *Submitted for verification at BscScan.com on 2021-12-22
*/

pragma solidity 0.8.4;
//SPDX-License-Identifier: UNLICENSED

interface IERC721 {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
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

abstract contract Verifier {
    bytes32 public constant SIGNATURE_PERMIT_TYPEHASH = keccak256("verify(address owner,uint nftId,uint level,uint power,uint skill,uint accuracy,uint deadline,bytes memory signature)");
    uint public chainId;
    
    using ECDSA for bytes32;
    
    constructor() {
        uint _chainId;
        assembly {
            _chainId := chainid()
        }
        
        chainId = _chainId;
    }
   
    function verify(
        address owner,
        uint nftId,
        uint level,
        uint power,
        uint skill,
        uint accuracy,
        uint deadline,
        bytes memory signature
    ) public view returns (address){
      // This recreates the message hash that was signed on the client.
      bytes32 hash = keccak256(abi.encodePacked(SIGNATURE_PERMIT_TYPEHASH, owner, nftId, level, power, skill, accuracy, chainId, deadline));
      bytes32 messageHash = hash.toSignedMessageHash();
    
      // Verify that the message's signer is the owner of the order
      return messageHash.recover(signature);
    }
}

library ECDSA {

  /**
   * @dev Recover signer address from a message by using their signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param signature bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 hash, bytes memory signature)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

    // Check the signature length
    if (signature.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables with inline assembly.
    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      // solium-disable-next-line arg-overflow
      return ecrecover(hash, v, r, s);
    }
  }

  /**
    * toEthSignedMessageHash
    * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
    * and hash the result
    */
  function toSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
    );
  }
}


contract DverseStake is Ownable, Verifier {
    IERC721 public DVERSENFT;
    IERC20 public DVERSE;

    event Stake( address indexed owner, uint indexed nftid);
    event UnStake( address indexed owner, uint indexed nftid, uint reward);

    mapping(uint => StakeInfo) public stakeInfo;
    mapping(address => UserInfo) public userInfo;
    mapping(bytes => bool)  public isSigned;

    struct StakeInfo {
        address owner;
        uint level;
        uint power;
        uint skill;
        uint accuracy;
        uint stakedAt;
    }

    struct UserInfo {
        uint8 totalStakedNFTs;
        uint totalRewards;
        mapping(uint => uint8) nftPos;
        uint[5] stakedNFTs;
    }

    uint stakePeriod = 30 days;
    uint earlyWithdrawalFee = 20;
    uint multiplier = 1;

    constructor(IERC721 dverseNFT, IERC20 dverse) {
        DVERSENFT = dverseNFT;
        DVERSE = dverse;
    }

    struct StakeParams {
        uint nftId;
        uint level;
        uint power;
        uint skill;
        uint accuracy;
        uint deadline;
        bytes signature;
    }

    function stake( StakeParams memory params) external {
        UserInfo storage usrInfo = userInfo[msg.sender];
        require(usrInfo.totalStakedNFTs < 5, "stake :: stake count exceed");
        _validateSignature(params);

        DVERSENFT.transferFrom(msg.sender, address(this), params.nftId);

        stakeInfo[params.nftId] = StakeInfo( msg.sender, params.level, params.power, params.skill, params.accuracy, block.timestamp);
        uint8 index = usrInfo.totalStakedNFTs++;
        usrInfo.nftPos[params.nftId] = index;
        usrInfo.stakedNFTs[index] = params.nftId;
        emit Stake( msg.sender, params.nftId);
    }

    function unstake( uint nftId) external {
        require(userInfo[msg.sender].totalStakedNFTs > 0, "unstake : no available stakes");
        require(DVERSENFT.ownerOf(nftId) == address(this), "unstake : nft not staked");
        require(stakeInfo[nftId].owner == msg.sender, "unstake : not a owner");

        userInfo[msg.sender].totalStakedNFTs--;
        uint8 index = userInfo[msg.sender].nftPos[nftId];
        userInfo[msg.sender].nftPos[nftId] = 0;

        uint reward = this.getReward(nftId);

        if(reward > 0) {
            if((stakeInfo[nftId].stakedAt + stakePeriod) > block.timestamp){
                uint _fee = reward * earlyWithdrawalFee / 10**2;
                reward = reward - _fee;
                DVERSE.transfer(owner(), _fee);
            }
            userInfo[msg.sender].totalRewards += reward;
            DVERSE.transfer(msg.sender, reward);
        }

        if((userInfo[msg.sender].stakedNFTs.length > 1) && (index != (userInfo[msg.sender].stakedNFTs.length -1))) {
            uint nftid = userInfo[msg.sender].stakedNFTs[index];
            userInfo[msg.sender].stakedNFTs[index] = userInfo[msg.sender].stakedNFTs[userInfo[msg.sender].stakedNFTs.length - 1];
            userInfo[msg.sender].stakedNFTs[userInfo[msg.sender].stakedNFTs.length - 1] = nftid;
        }

        userInfo[msg.sender].stakedNFTs[userInfo[msg.sender].stakedNFTs.length - 1] = 0;
        DVERSENFT.transferFrom( address(this), msg.sender, nftId);
        emit UnStake( msg.sender, nftId, reward);
    }

    function setDverse( IERC20 dverse) external onlyOwner {
        DVERSE = dverse;
    }

    function updateMultiplier( uint multiple) external onlyOwner {
        multiplier = multiple;
    }

    function updateStakePeriod( uint stakeTime) external onlyOwner {
        stakePeriod = stakeTime;
    }

    function updateEarlyWithdrawalFee( uint fee) external onlyOwner {
        earlyWithdrawalFee = fee;
    }

    function _validateSignature(StakeParams memory params) private {
        require(params.deadline >= block.timestamp, 'DefverseCharacters :: createCharacterBatch : deadline expired');
        require(!isSigned[params.signature], "_validateSignature : message already signed");
        address _signer = verify(
            msg.sender,
            params.nftId,
            params.level,
            params.power,
            params.skill,
            params.accuracy,
            params.deadline,
            params.signature
        );
        require(_signer == _msgSender(), "_validateSignature : invalid signature");
        isSigned[params.signature] = true;
    }

    function getReward( uint nftId) external view returns (uint) {
        StakeInfo memory nftInfo = stakeInfo[nftId];
        uint currentTime = block.timestamp;

        if((nftInfo.stakedAt + stakePeriod) < block.timestamp) currentTime = nftInfo.stakedAt + stakePeriod;

        uint totDays = (currentTime - nftInfo.stakedAt);
        uint monthlyAPR = getMonthlyAPR(nftId);

        if(monthlyAPR == 0 ) return 0;

        monthlyAPR = monthlyAPR / stakePeriod;

        return monthlyAPR*totDays;

    }

    function getMonthlyAPR( uint nftId) public view returns ( uint monthApr) {
        StakeInfo memory nftInfo = stakeInfo[nftId];
        uint[3] memory cal;
        cal[0] = (nftInfo.power*1e16) + (nftInfo.accuracy*1e16);
        cal[1] = (nftInfo.level*1e17) + (nftInfo.skill*1e16);
        cal[2] = (cal[0]*cal[1])/1e18;
        monthApr = (cal[2] + cal[0]) * multiplier;
    }
}