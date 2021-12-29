/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

// File: base/IOracle.sol

pragma solidity ^0.8.0;

interface IOracle{
    function getTimestampCountById(bytes32 _queryId)
        external
        view
        returns (uint256);
    function getReportTimestampByIndex(bytes32 _queryId, uint256 _index)
        external
        view
        returns (uint256);
    function getValueByTimestamp(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (bytes memory);
}

// File: base/Context.sol



pragma solidity ^0.8.0;
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */

contract Context {

    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor ()  {}

    function _msgSender() internal view returns (address payable) {
        return payable (msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
// File: base/Ownable.sol




pragma solidity ^0.8.0;
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
   */
    constructor ()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
   */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
   */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: base/IERC165.sol



pragma solidity ^0.8.0;
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
// File: base/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
    function restrictedChangeNft(uint tokenID, uint8 nftType, uint8 level, bool canClaim, uint stakedTime, uint lastClaimTime) external;
    function tokenOwnerCall(uint tokenId) external view  returns (address);
    function burnNFT(uint tokenId) external;
    function getToken(uint256 _tokenId) external view returns(uint8, uint8, bool, uint,uint, uint);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    //function nftStatus (uint tokenId) external view returns (uint,uint,bool,uint,uint);

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

// File: base/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

    function burn(uint256 amount) external returns (bool);

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

// File: TestContracts/testGameEngine.sol

pragma solidity ^0.8.0;





contract testGameEngine is Ownable{
    mapping (uint => uint) public firstStakeLockPeriod;
    mapping (uint => bool) public stakeConfirmation;
    mapping (uint => bool) public isStaked;
    mapping (uint => uint) public stakeTime;
    mapping (uint => uint) public lastClaim;
    mapping (uint => uint) public levelOfToken;
    mapping (uint => uint) public tokenToArrayPosition;
    mapping (uint => uint) public tokenToRandomHourInStake;

    IERC20 public token;
    IERC721 public nftToken;
    IOracle public Oracle;

    bool public frenzyStarted;

    mapping (uint8 => mapping(uint8 =>uint[])) public pool; //0 zombie 1 survivor (1-5) levels
    mapping(uint=>uint) nftTimeStamp;

    constructor() {
        for (uint8 i=0;i<2;i++) {
            for (uint8 j=1; j<6;j++) {
                pool[i][j].push(0);
            }
        }
    }

    function setContract( address _nftAddress, address _tokenaddress,address _oracleAddress) external onlyOwner {
        token = IERC20(_tokenaddress);
        nftToken = IERC721(_nftAddress);
        Oracle = IOracle(_oracleAddress);
    }
    function onERC721Received( address operator, address from, uint256 tokenId, bytes calldata data ) public pure returns (bytes4) {
        return 0x150b7a02;
    }

    //todo: its important***
    // in this case stakeConfirmation is checking whether the token is first-time staked or not.
    // if staked for the first time it returns false hence only chance of a tokenId level having a false return is 1
    // and if its staked before it returns true and hence the calculation is done in that way
    function unstakeNFT ( uint tokenId ) external {
        require(nftToken.tokenOwnerCall(tokenId)==msg.sender, "Caller is not the owner");
        uint randomNumber = initiateRandomness(tokenId);
        if (stakeConfirmation[tokenId] == true){
            require (isStaked[tokenId]==true);
            uint level = levelOfToken[tokenId];
            uint burnPercent = unstakeBurnCalculator(level);
            if(randomNumber%100 <= burnPercent){
                nftToken.burnNFT(tokenId);
            }
            else{nftToken.safeTransferFrom(address(this), msg.sender, tokenId);}
            isStaked[tokenId] = false;
        }
        else {
            require (tokenToRandomHourInStake[tokenId]+stakeTime[tokenId] <= block.timestamp,"time not over");
            uint burnPercent = unstakeBurnCalculator(1);
            if(randomNumber%100 <= burnPercent){
                nftToken.burnNFT(tokenId);
            }
            else{
                nftToken.safeTransferFrom(address(this), msg.sender, tokenId);}
            stakeConfirmation[tokenId] = true;
            isStaked[tokenId] = false;
        }
    }

    function alertStake (uint tokenId, uint8 tokenType) external {
        require (isStaked[tokenId] == false);
        require (nftToken.ownerOf(tokenId)==address(this));
        (,,,uint creationTime,,) = nftToken.getToken(tokenId);
        //      todo we need to restore this line asap as this line marks the safety of restaking without unstaked but inserting uint creationTime in the nftFactory.sol
        //        require ( block.timestamp-creationTime < 6 minutes);
        uint randomNo = initiateRandomness(tokenId)%7;
        if (randomNo < 2) {randomNo += 2;}
        firstStakeLockPeriod[tokenId] = block.timestamp + randomNo; //convert randomNo from hours to sec
        isStaked[tokenId] = true;
        stakeTime[tokenId] = block.timestamp;
        tokenToRandomHourInStake[tokenId]= randomNo; //conversion required
        levelOfToken[tokenId] = 1;
        if (tokenType == 1) {
            pool[1][1].push(tokenId);
            tokenToArrayPosition[tokenId] = pool[1][1].length;
        } else {
            pool[0][1].push(tokenId);
            tokenToArrayPosition[tokenId] = pool[0][1].length;
        }
    }

    function stake ( uint tokenId ) external {
        require (isStaked[tokenId] == false);
        if ( stakeConfirmation [tokenId] == true ){
            nftToken.safeTransferFrom(msg.sender, address(this), tokenId);
            stakeTime[tokenId] = block.timestamp;
            isStaked[tokenId] = true;
            determineAndPush(tokenId);

        } else if ( stakeConfirmation[tokenId] == false && firstStakeLockPeriod[tokenId]==0 ) {
            uint randomNo = initiateRandomness(tokenId) % 7;
            if (randomNo < 2) {randomNo += 2;}
            firstStakeLockPeriod[tokenId] = block.timestamp + randomNo; //convert randomNo from hours to sec
            nftToken.safeTransferFrom(msg.sender, address (this), tokenId);
            stakeTime[tokenId] = block.timestamp;
            isStaked[tokenId] = true;
            tokenToRandomHourInStake[tokenId]= randomNo; //conversion required
            levelOfToken[tokenId] = 1;
            determineAndPush(tokenId);
        }
    }

    function determineAndPush(uint tokenId) internal {
        uint8 tokenLevel = uint8(levelOfToken[tokenId]);
        (uint8 tokenType,,,,,) = nftToken.getToken(tokenId);
        pool[tokenType][tokenLevel].push(tokenId);
        tokenToArrayPosition[tokenId] = pool[tokenType][tokenLevel].length-1;
    }
    function unstakeBurnCalculator(uint tokenLevel) internal returns(uint){
        bool frenzy = isFrenzy();
        bool aggression = isAggression();
        if(frenzy == true){
            return 50-5*tokenLevel;
        }
        else if(aggression == true){
            uint val = whichAggression();
            return (25+5*val)-(5*tokenLevel);
        }
        else{
            return 25-5*tokenLevel;
        }
    }
    function isFrenzy() internal returns(bool){
        uint totalPoolStrength = pool[0][1].length+ pool[0][2].length+ pool[0][3].length+
        pool[0][4].length+pool[0][5].length+pool[1][1].length+pool[1][2].length+pool[1][3].length+
        pool[1][4].length+pool[1][5].length;
        if(totalPoolStrength<10000 && frenzyStarted == true){
            frenzyStarted = false;

            return false;
        }
        else if(totalPoolStrength >= 20000){
            frenzyStarted = true;
            return true;
        }
    }
    function moveToLast(uint _tokenId) internal {
        (uint8 tokenType,,,,,) = nftToken.getToken(_tokenId);
        uint8 level = uint8(levelOfToken[_tokenId]);
        uint position = tokenToArrayPosition[_tokenId];
        uint[] storage currentPool = pool[tokenType][level];
        uint length = currentPool.length;
        uint lastToken = currentPool[length-1];
        currentPool[position] = lastToken;
        tokenToArrayPosition[lastToken] = position;
        currentPool[length-1] = _tokenId;
        currentPool.pop();
    }
    function isAggression() view internal returns(bool){
        uint totalPoolStrength = pool[0][1].length+ pool[0][2].length+ pool[0][3].length+
        pool[0][4].length+pool[0][5].length+pool[1][1].length+pool[1][2].length+pool[1][3].length+
        pool[1][4].length+pool[1][5].length;
        if(totalPoolStrength >= 12000) return true;
        else return false;
    }
    function whichAggression() view internal returns(uint){
        uint totalPoolStrength = pool[0][1].length+ pool[0][2].length+ pool[0][3].length+
        pool[0][4].length+pool[0][5].length+pool[1][1].length+pool[1][2].length+pool[1][3].length+
        pool[1][4].length+pool[1][5].length;
        if(totalPoolStrength>=12000 && totalPoolStrength<14000) return 1;
        else if(totalPoolStrength>=14000 && totalPoolStrength<16000) return 2;
        else if(totalPoolStrength>=16000 && totalPoolStrength<18000) return 3;
        else if(totalPoolStrength>=18000 && totalPoolStrength<20000) return 4;
        else return 0;
    }
    //Token ID - helper - mapping - find position in pool - swaps it out
    //helper - someMapping[tokenId] = position;
    //length = lenght of pool (swap)
    // 
    function onSuccess (uint tokenId) internal {
        (uint8 tokenType,,,,,) = nftToken.getToken(tokenId);
        uint level = levelOfToken[tokenId];
        token.transfer(msg.sender, calculateSUP(tokenId));
        lastClaim[tokenId] = block.timestamp;
        uint randomNumber = initiateRandomness(tokenId)%100;
        
        if(randomNumber>=0 && randomNumber<40 && level < 5 ) {

            moveToLast (tokenId);
            levelOfToken[tokenId] ++;
            determineAndPush(tokenId);
            //uint tokenID, uint8 nftType, uint8 level, bool canClaim, uint stakedTime, uint lastClaimTime

            nftToken.restrictedChangeNft(tokenId, tokenType, uint8(levelOfToken[tokenId]), false, stakeTime[tokenId],lastClaim[tokenId]);
        }

    }
    function onCriticalSuccess (uint tokenId) internal {
        (uint8 nftType,uint8 level,,,,) =
        nftToken.getToken(tokenId);

        token.transfer(msg.sender, calculateSUP(tokenId));
        lastClaim[tokenId] = block.timestamp;
        uint randomNumber = initiateRandomness(tokenId)%100;
        if (randomNumber >= 0 && randomNumber < 40) {
            moveToLast (tokenId);
            levelOfToken[tokenId] ++;
            determineAndPush(tokenId);
            nftToken.restrictedChangeNft(tokenId, nftType, uint8(levelOfToken[tokenId]), false, stakeTime[tokenId],lastClaim[tokenId]);
            uint numberOfSteal = howManyTokensCanSteal(nftType);
            uint[] memory stolenNFTIds;
            for (uint i=0;i < numberOfSteal;i++) {
                uint stolenTokenId = steal(nftType,tokenId);
                stolenNFTIds[(stolenNFTIds.length)-1]=stolenTokenId; //stores stolen tokenIds
            }
            for (uint j=0; j< stolenNFTIds.length; j++) {
                nftToken.safeTransferFrom(address(this),msg.sender, stolenNFTIds[j]);
                nftToken.restrictedChangeNft(stolenNFTIds[j], 1-nftType, uint8(levelOfToken[tokenId]), false, stakeTime[tokenId],lastClaim[tokenId]);
            }
        }
        else {
            uint numberOfSteal = howManyTokensCanSteal(nftType);
            uint[] memory stolenNFTIds;
            for (uint i=0;i < numberOfSteal;i++) {
                uint stolenTokenId = steal(nftType,tokenId);
                stolenNFTIds[(stolenNFTIds.length)-1]=stolenTokenId; //stores stolen tokenIds
            }
            for (uint j=0; j< stolenNFTIds.length; j++) {
                nftToken.safeTransferFrom(address(this),msg.sender, stolenNFTIds[j]);
                nftToken.restrictedChangeNft(stolenNFTIds[j], 1-nftType, uint8(levelOfToken[tokenId]), false, stakeTime[tokenId],lastClaim[tokenId]);
            }
        }

    }
    function onCriticalFail(uint tokenId) internal  {
        uint randomNumber = initiateRandomness(tokenId);
        if (randomNumber  >= 0  && randomNumber <90) {
            nftToken.safeTransferFrom(address(this),msg.sender, tokenId);

        } else {
            nftToken.burnNFT(tokenId);
        }
    }
    function steal(uint8 tokenType,uint tokenId) internal returns (uint) {
            uint randomNumber = initiateRandomness(tokenId);
            uint8 level = whichLevelToChoose(tokenType, randomNumber); //
            uint tokenToGet = randomNumber % pool[tokenType][level].length;
            uint stealtokenId = pool[tokenType][level][tokenToGet];
            return stealtokenId;
    }
    function whichLevelToChoose(uint tokenType, uint randomNumber) internal view returns(uint8) {
        uint x1 = 1000;
        uint x2 = 875;
        uint x3 = 750;
        uint x4 = 625;
        uint x5 = 500;
        if (tokenType == 0) {
            //zPool1 = pool[0][1].length
            uint lvl1Steal = (pool[0][1].length*x1*1000000)/((pool[0][1].length*x1)+(pool[0][2].length*x2)+(pool[0][3].length*x3)+(pool[0][4].length*x4)+(pool[0][5].length*x5));

            uint lvl2Steal = (pool[0][2].length*x2*1000000)/((pool[0][1].length*x1)+(pool[0][2].length*x2)+(pool[0][3].length*x3)+(pool[0][4].length*x4)+(pool[0][5].length*x5));

            uint lvl3Steal = (pool[0][3].length*x3*1000000)/((pool[0][1].length*x1)+(pool[0][2].length*x2)+(pool[0][3].length*x3)+(pool[0][4].length*x4)+(pool[0][5].length*x5));

            uint lvl4Steal = (pool[0][4].length*x4*1000000)/((pool[0][1].length*x1)+(pool[0][2].length*x2)+(pool[0][3].length*x3)+(pool[0][4].length*x4)+(pool[0][5].length*x5));

            // uint lvl5Steal = (pool[0][5].length*x5*1000000)/((pool[0][1].length*x1)+(pool[0][2].length*x2)+(pool[0][3].length*x3)+(pool[0][4].length*x4)+(pool[0][5].length*x5));

            randomNumber = randomNumber %1000000;
            if (randomNumber > 0 && randomNumber < lvl1Steal) {
                return 1;
            } else if (randomNumber >= lvl1Steal && randomNumber < lvl1Steal+lvl2Steal) {
                return 2;
            } else if (randomNumber >= lvl1Steal+lvl2Steal && randomNumber < lvl1Steal+lvl2Steal+lvl3Steal) {
                return 3;
            } else if (randomNumber >= lvl1Steal+lvl2Steal+lvl3Steal && randomNumber < lvl1Steal+lvl2Steal+lvl3Steal+lvl4Steal) {
                return 4;
            } else {
                return 5;
            }
        }
        else {
            uint lvl1Steal = (pool[1][1].length*x1*1000000)/((pool[1][1].length*x1)+(pool[1][2].length*x2)+(pool[1][3].length*x3)+(pool[1][4].length*x4)+(pool[1][5].length*x5));

            uint lvl2Steal = (pool[1][2].length*x2*1000000)/((pool[1][1].length*x1)+(pool[1][2].length*x2)+(pool[1][3].length*x3)+(pool[1][4].length*x4)+(pool[1][5].length*x5));

            uint lvl3Steal = (pool[1][3].length*x3*1000000)/((pool[1][1].length*x1)+(pool[1][2].length*x2)+(pool[1][3].length*x3)+(pool[1][4].length*x4)+(pool[1][5].length*x5));

            uint lvl4Steal = (pool[1][4].length*x4*1000000)/((pool[1][1].length*x1)+(pool[1][2].length*x2)+(pool[1][3].length*x3)+(pool[1][4].length*x4)+(pool[1][5].length*x5));

            //   uint lvl5Steal = (pool[1][5].length*x5*1000000)/((pool[1][1].length*x1)+(pool[1][2].length*x2)+(pool[1][3].length*x3)+(pool[1][4].length*x4)+(pool[1][5].length*x5));

            randomNumber = randomNumber %1000000;
            if (randomNumber > 0 && randomNumber < lvl1Steal) {
                return 1;
            } else if (randomNumber >= lvl1Steal && randomNumber < lvl1Steal+lvl2Steal) {
                return 2;
            } else if (randomNumber >= lvl1Steal+lvl2Steal && randomNumber < lvl1Steal+lvl2Steal+lvl3Steal) {
                return 3;
            } else if (randomNumber >= lvl1Steal+lvl2Steal+lvl3Steal && randomNumber < lvl1Steal+lvl2Steal+lvl3Steal+lvl4Steal) {
                return 4;
            } else {
                return 5;
            }

        }
    }
    function howManyTokensCanSteal(uint tokenType) view internal returns (uint) {
        uint totalZombieStaked = pool[0][1].length+pool[0][2].length+pool[0][3].length+pool[0][4].length+pool[0][5].length;
        uint totalSurvivorStaked = pool[1][1].length+pool[1][2].length+pool[1][3].length+pool[1][4].length+pool[1][5].length;


        if (tokenType == 0){

            if ((totalZombieStaked / (totalSurvivorStaked+totalZombieStaked)) <= 10) {return 5;}

            else if ((totalZombieStaked / (totalSurvivorStaked+totalZombieStaked)) > 10 && (totalZombieStaked / (totalSurvivorStaked+totalZombieStaked)) <=20 ) {return 4;}

            else if ((totalZombieStaked / (totalSurvivorStaked+totalZombieStaked)) > 20 && (totalZombieStaked / (totalSurvivorStaked+totalZombieStaked)) <=30 ) {return 3;}

            else if ((totalZombieStaked / (totalSurvivorStaked+totalZombieStaked)) > 30 && (totalZombieStaked / (totalSurvivorStaked+totalZombieStaked)) <=40 ) {return 2;}

            else if ((totalZombieStaked / (totalSurvivorStaked+totalZombieStaked)) > 40 && (totalZombieStaked / (totalSurvivorStaked+totalZombieStaked)) <=50 ) {return 1;}

            else {
                return 0;
            }
        }
        else {

            if ((totalSurvivorStaked / (totalSurvivorStaked+totalZombieStaked)) <= 10) {return 5;}

            else if ((totalSurvivorStaked / (totalSurvivorStaked+totalZombieStaked)) > 10 && (totalSurvivorStaked / (totalSurvivorStaked+totalZombieStaked)) <=20 ) {return 4;}

            else if ((totalSurvivorStaked / (totalSurvivorStaked+totalZombieStaked)) > 20 && (totalSurvivorStaked / (totalSurvivorStaked+totalZombieStaked)) <=30 ) {return 3;}

            else if ((totalSurvivorStaked / (totalSurvivorStaked+totalZombieStaked)) > 30 && (totalSurvivorStaked / (totalSurvivorStaked+totalZombieStaked)) <=40 ) {return 2;}

            else if ((totalSurvivorStaked / (totalSurvivorStaked+totalZombieStaked)) > 40 && (totalSurvivorStaked / (totalSurvivorStaked+totalZombieStaked)) <=50 ) {return 1;}

            else {
                return 0;
            }
        }
    }

    function calculateSUP (uint tokenId) internal  returns (uint) {
        uint calculatedDuration;
        uint calculatedTime;
        uint stakedTime = stakeTime[tokenId];
        uint lastClaimTime = lastClaim[tokenId];
        if (lastClaimTime == 0) {
            calculatedTime = block.timestamp - (stakedTime+tokenToRandomHourInStake[tokenId]);
            calculatedDuration = (calculatedTime);//todo /60*60

            if (calculatedDuration >= 12) {//37
                calculatedDuration = calculatedDuration / 6; //todo 12
                uint toReturn = calculateFinalAmountInDays (calculatedDuration);
                return toReturn;
            } else {
                return 0;
            }
        } else {
            uint calculatedTime = block.timestamp - lastClaimTime;//lct=>4pm bt=> 9am
            calculatedDuration = (block.timestamp - lastClaimTime)/(60*60);
            if (calculatedDuration > 12) {
                calculatedDuration = calculatedDuration/12;
                uint toReturn = calculateFinalAmountInDays (calculatedDuration);
                return toReturn;
            }
            else {
                return 0;
            }
        }
    }
    function calculateFinalAmountInDays (uint _calculatedHour)internal pure returns (uint) {
        return _calculatedHour * 250 ether;//for ease of test we have converted 250ether to 1eth
    }
    function executeClaims (uint randomNumber, uint tokenId, uint firstHold, uint secondHold) internal {
        if (randomNumber >=0 && randomNumber < firstHold) {
            onSuccess(tokenId);
        }
        else if (randomNumber >= firstHold && randomNumber < secondHold) {
            onCriticalSuccess(tokenId);
        }
        else {
            onCriticalFail(tokenId);
        }
    }
    function claimStake ( uint tokenId ) external {
        require (nftToken.tokenOwnerCall(tokenId)== msg.sender,"Caller is not the owner");
        if (stakeConfirmation[tokenId] == false) {
            require (block.timestamp >= firstStakeLockPeriod[tokenId]);
            uint randomNumber = initiateRandomness(tokenId)%100;
            (,uint8 level,,,,) =
            nftToken.getToken(tokenId);
            if(isFrenzy()) {
                //63+2*(level)
                executeClaims(randomNumber, tokenId, 55, 63+2*(level));
            }
            else if(isAggression()){
                uint aggKicker = whichAggression();
                executeClaims(randomNumber, tokenId, 80-3*aggKicker, 85+2*(level));
            }
            else {
                executeClaims(randomNumber, tokenId, 80, 88+2*(level));
            }
            stakeConfirmation[tokenId] = true;
        }
        else {
            uint randomNumber = initiateRandomness(tokenId)%100;
            (,uint8 level,,,,) = nftToken.getToken(tokenId);
            if(isFrenzy()){
                executeClaims(randomNumber, tokenId, 55, 63+2*(level));
            }
            else if(isAggression()){
                uint aggKicker = whichAggression();
                executeClaims(randomNumber, tokenId, 80-3*aggKicker, 85+2*(level));
                }
            else{
                executeClaims(randomNumber, tokenId, 80, 88+2*(level));
            }
        }
    }

    //VRF

    function initiateRandomness(uint _tokenId) internal returns(uint) {

        require ( block.timestamp - nftTimeStamp[_tokenId] >= 30 seconds );
        nftTimeStamp[_tokenId] = block.timestamp;
        bytes32 tellorId = 0x0000000000000000000000000000000000000000000000000000000000000001;
        uint result = Oracle.getTimestampCountById(tellorId);
        uint tellorTimeStamp = Oracle.getReportTimestampByIndex(tellorId,result-1);
        for(uint i=(result-2);i>0;i--){
            if(tellorTimeStamp < nftTimeStamp[_tokenId])
            break;
            tellorTimeStamp = Oracle.getReportTimestampByIndex(tellorId,i);
        }
        bytes memory tellorValue = Oracle.getValueByTimestamp(tellorId,tellorTimeStamp);
        return uint(keccak256(abi.encodePacked(tellorValue,_tokenId)));
    }
}