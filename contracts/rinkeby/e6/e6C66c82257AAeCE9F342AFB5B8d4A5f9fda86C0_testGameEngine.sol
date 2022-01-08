/**
 *Submitted for verification at Etherscan.io on 2022-01-08
*/

// File: contracts/base/IMetadata.sol

pragma solidity ^0.8.0;

interface IMetadata{

    function addMetadata(uint8 tokenType,uint8 level) external;
    function createRandomZombie(uint8 level) external returns(uint8[] memory traits);
    function createRandomSurvivor(uint8 level) external returns(uint8[] memory traits);
    function getTokenURI(uint tokenId) external view returns (string memory);
    function changeNft(uint tokenID, uint8 nftType, uint8 level, bool canClaim, uint stakedTime, uint lastClaimTime) external;
    function getToken(uint256 _tokenId) external view returns(uint8, uint8, bool, uint,uint);
}
// File: contracts/base/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
// File: contracts/base/IVRF.sol

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IVRF{

    function initiateRandomness(uint _tokenId,uint _timestamp) external view returns(uint);
    function stealRandomness() external view returns(uint);
}
// File: contracts/base/Context.sol



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
// File: contracts/base/Ownable.sol




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

// File: contracts/base/IERC165.sol



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
// File: contracts/base/IERC721.sol


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
    function burnNFT(uint tokenId) external ;
    // function getToken(uint256 _tokenId) external view returns(uint8, uint8, bool, uint, uint);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function tokenOwnerSetter(uint tokenId, address _owner) external;
    function setTimeStamp(uint tokenId) external;
    function actionTimestamp(uint tokenId) external returns(uint);
    // function buyPresale(bool stake,uint8 tokenType, uint tokenAmount,address receiver) external payable;
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

// File: contracts/base/IERC20.sol


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

// File: contracts/base/ISUPFactory.sol

pragma solidity ^0.8.0;

interface ISUP is IERC20{
    function mintFromEngine(address _receiver, uint _amount) external;
}


// File: contracts/TestContracts/testGameEngine.sol


/**
 * Author : Lil Ye, Ace, Anyx
 */
pragma solidity ^0.8.0;









contract testGameEngine is Ownable,ReentrancyGuard{

    mapping (uint => uint) public firstStakeLockPeriod;
    mapping (uint => bool) public stakeConfirmation;
    mapping (uint => bool) public isStaked;
    mapping (uint => uint) public stakeTime;
    mapping (uint => uint) public lastClaim;
    mapping (uint8 => mapping(uint8 =>uint[])) public pool; //0 zombie 1 survivor (1-5) levels
    mapping (uint => uint) public levelOfToken;
    mapping (uint => uint) public tokenToArrayPosition;
    mapping (uint => uint) public tokenToRandomHourInStake;

    ISUP public token;
    IERC721 public nftToken;
    IVRF public randomNumberGenerated;
    IMetadata public metadataHandler;

    bool public frenzyStarted;

    constructor (address _randomEngineAddress, address _nftAddress, address _tokenAddress,address _metadata) {
        token = ISUP(_tokenAddress);
        nftToken = IERC721(_nftAddress);
        randomNumberGenerated = IVRF(_randomEngineAddress);
        metadataHandler = IMetadata(_metadata);
    }

    function setContract(address _randomEngineAddress, address _nftAddress, address _tokenaddress, address _metadata) external onlyOwner{
        token = ISUP(_tokenaddress);
        nftToken = IERC721(_nftAddress);
        randomNumberGenerated = IVRF(_randomEngineAddress);
        metadataHandler = IMetadata(_metadata);
    }

    function onERC721Received( address operator, address from, uint256 tokenId, bytes calldata data ) public pure returns (bytes4) {
        return 0x150b7a02;
    }

    function alertStake (uint tokenId) external {
        require (isStaked[tokenId] == false);
        require (nftToken.ownerOf(tokenId)==address(this));
        uint randomNo = randomNumberGenerated.initiateRandomness(tokenId,nftToken.actionTimestamp(tokenId))%7;
        nftToken.setTimeStamp(tokenId);
        if (randomNo < 2) {randomNo += 2;}
        firstStakeLockPeriod[tokenId] = block.timestamp + randomNo; //convert randomNo from hours to sec
        isStaked[tokenId] = true;
        stakeTime[tokenId] = block.timestamp;
        tokenToRandomHourInStake[tokenId]= randomNo; //conversion required
        levelOfToken[tokenId] = 1;
        determineAndPush(tokenId);
    }

    function stake (uint tokenId) external {
        require (isStaked[tokenId] == false);
        if ( stakeConfirmation [tokenId] == true ){
            nftToken.safeTransferFrom(msg.sender, address(this), tokenId);
            stakeTime[tokenId] = block.timestamp;
            isStaked[tokenId] = true;
            nftToken.setTimeStamp(tokenId);
            determineAndPush(tokenId);
        } else if ( stakeConfirmation[tokenId] == false && firstStakeLockPeriod[tokenId]==0 ) {
            uint randomNo = randomNumberGenerated.initiateRandomness(tokenId,nftToken.actionTimestamp(tokenId)) % 7;
            nftToken.setTimeStamp(tokenId);
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

    function moveToLast(uint _tokenId) internal {
        (uint8 tokenType,,,,) = metadataHandler.getToken(_tokenId);
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

    function determineAndPush(uint tokenId) internal {
        uint8 tokenLevel = uint8(levelOfToken[tokenId]);
        (uint8 tokenType,,,,) = metadataHandler.getToken(tokenId);
        pool[tokenType][tokenLevel].push(tokenId);
        tokenToArrayPosition[tokenId] = pool[tokenType][tokenLevel].length-1;
    }

    function unstakeBurnCalculator(uint8 tokenLevel) internal returns(uint){
        if(isFrenzy()){
            return 50-5*tokenLevel;
        }
        else if(isAggression()){
            uint val = whichAggression();
            return (25+5*val)-(5*tokenLevel);
        }
        else{
            return 25-5*tokenLevel;
        }
    }

    function isFrenzy() public returns (bool){
        uint totalPoolStrength;
        for(uint8 i=0;i<2;i++){
            for(uint8 j=1;j<6;j++){
                totalPoolStrength += pool[i][j].length;
            }
        }
        if(totalPoolStrength<10000 && frenzyStarted == true){
            frenzyStarted = false;
            return false;
        }
        else if(totalPoolStrength >= 20000){
            frenzyStarted = true;
            return true;
        }
        else{
            return false;
        }

    }

    function isAggression() view public returns(bool){
        uint totalPoolStrength;
        for(uint8 i=0;i<2;i++){
            for(uint8 j=1;j<6;j++){
                totalPoolStrength += pool[i][j].length;
            }
        }
        if(totalPoolStrength >= 12000) return true;
        else return false;
    }

    function whichAggression() view internal returns(uint){
        uint totalPoolStrength;
        for(uint8 i=0;i<2;i++){
            for(uint8 j=1;j<6;j++){
                totalPoolStrength += pool[i][j].length;
            }
        }
        if(totalPoolStrength>=12000 && totalPoolStrength<14000) return 1;
        else if(totalPoolStrength<16000) return 2;
        else if(totalPoolStrength<18000) return 3;
        else if(totalPoolStrength<20000) return 4;
        else return 0;
    }

    function steal(uint8 tokenType,uint nonce) internal view returns (uint) {
        uint randomNumber = randomNumberGenerated.stealRandomness();
        randomNumber = uint(keccak256(abi.encodePacked(randomNumber,nonce)));
        uint8 level = whichLevelToChoose(tokenType, randomNumber);
        uint tokenToGet = randomNumber % pool[tokenType][level].length;
        uint stealtokenId = pool[tokenType][level][tokenToGet];
        return stealtokenId;
    }

    function whichLevelToChoose(uint8 tokenType, uint randomNumber) internal view returns(uint8) {
        uint16[5] memory x = [1000,875,750,625,500];
        uint denom;
        for(uint8 level=1;level<6;level++){
            denom += pool[tokenType][level].length*x[level-1];
        }
        uint[5] memory stealing;
        for(uint8 level=1;level<6;level++){
            stealing[level-1] = (pool[tokenType][level].length*x[level-1]*1000000)/denom;
        }
        uint8 levelToReturn;
        randomNumber = randomNumber %1000000;
        if (randomNumber < stealing[0]) {
            levelToReturn = 1;
        } else if (randomNumber < stealing[0]+stealing[1]) {
            levelToReturn = 2;
        } else if (randomNumber < stealing[0]+stealing[1]+stealing[2]) {
            levelToReturn = 3;
        } else if (randomNumber < stealing[0]+stealing[1]+stealing[2]+stealing[3]) {
            levelToReturn = 4;
        } else {
            levelToReturn = 5;
        }
        return levelToReturn;
    }

    function howManyTokensCanSteal(uint8 tokenType) view internal returns (uint) {
        uint[2] memory totalStaked;

        for(uint8 i =0;i<2;i++){
            totalStaked[i] = totalStakedOfType(i);
        }
        for(uint i = 0;i<5;i++) {
            if((totalStaked[tokenType]*100)/(totalStaked[0]+totalStaked[1])<=10+10*i){
                if(totalStaked[1-tokenType] >= 5-i){
                    return 5-i;
                }
                return totalStaked[1-tokenType];
            }
        }

        return 0;
    }

    function calculateSUP (uint tokenId) internal view returns (uint) {
        uint calculatedDuration;
        uint stakedTime = stakeTime[tokenId];
        uint lastClaimTime = lastClaim[tokenId];
        if (lastClaimTime == 0) {
            calculatedDuration = block.timestamp - (stakedTime+tokenToRandomHourInStake[tokenId])/(60);//todo /60*60
            if (calculatedDuration >= tokenToRandomHourInStake[tokenId]) {
            return 250 ether;
            } else {
                return 0;
            }
        } else {
            calculatedDuration = (block.timestamp - lastClaimTime)/(60);//(60*60);
            if (calculatedDuration >= 12) {
            calculatedDuration = calculatedDuration / 12; //todo 12
            uint toReturn = calculateFinalAmountInDays (calculatedDuration);
            return toReturn;
            } else {
                return 0;
            }
        }
    }

    function calculateFinalAmountInDays (uint _calculatedHour)internal pure returns (uint) {
        return _calculatedHour * 250 ether;
    }

    function executeClaims (uint randomNumber, uint tokenId, uint firstHold, uint secondHold) internal returns (bool) {
        if (randomNumber >=0 && randomNumber < firstHold) {
            bool query = onSuccess(tokenId);
            return query;
        }
        else if (randomNumber >= firstHold && randomNumber < secondHold) {
            bool query = onCriticalSuccess(tokenId);
            return query;
        }
        else {
            bool query = onCriticalFail(tokenId);
            return query;
        }
    }

    function onSuccess (uint tokenId) internal returns (bool) {
        (uint8 nftType,,,,) = metadataHandler.getToken(tokenId);
        require (lastClaim[tokenId] + 12 minutes <= block.timestamp, "Claiming before 12 hours");//minutes to hour
        uint calculatedValue = calculateSUP(tokenId);
        token.mintFromEngine(msg.sender, calculatedValue);
        lastClaim[tokenId] = block.timestamp;
        uint randomNumber = randomNumberGenerated.initiateRandomness(tokenId,nftToken.actionTimestamp(tokenId))%100;
        if(randomNumber<40 && levelOfToken[tokenId] < 5){
            moveToLast(tokenId);
            levelOfToken[tokenId]++;
            determineAndPush(tokenId);
           nftToken.restrictedChangeNft(tokenId, nftType, uint8(levelOfToken[tokenId]), false, stakeTime[tokenId],lastClaim[tokenId]);
        }
        return false;
    }

    function onCriticalSuccess (uint tokenId) internal returns (bool) {
        (uint8 nftType,,,,) = metadataHandler.getToken(tokenId);
        require (lastClaim[tokenId] + 12 minutes <= block.timestamp, "Claiming before 12 hours");//minutes to hour
        token.mintFromEngine(msg.sender, calculateSUP(tokenId));
        lastClaim[tokenId] = block.timestamp;
        if (randomNumberGenerated.initiateRandomness(tokenId,nftToken.actionTimestamp(tokenId))%100 < 40 && levelOfToken[tokenId]<5) {
            moveToLast (tokenId);
            levelOfToken[tokenId]++;
            determineAndPush(tokenId);
            nftToken.restrictedChangeNft(tokenId, nftType, uint8(levelOfToken[tokenId]), false, stakeTime[tokenId],lastClaim[tokenId]);
        }
        uint value = howManyTokensCanSteal(nftType);
        uint nonce = 1;
        uint stolenTokenId;

            for (uint i=0;i < value;i++) {
                stolenTokenId = steal(1-nftType,nonce);
                nonce++;
                moveToLast(stolenTokenId);
                nftToken.restrictedChangeNft(stolenTokenId, 1-nftType, uint8(levelOfToken[tokenId]), false, stakeTime[tokenId],lastClaim[tokenId]);//s->1
                pool[nftType][uint8(levelOfToken[tokenId])].push(stolenTokenId);
                nftToken.tokenOwnerSetter(stolenTokenId, msg.sender);

            }
        return false;
        }

    function onCriticalFail(uint tokenId) internal returns (bool) {
            nftToken.burnNFT(tokenId);
            isStaked[tokenId] = false;
            moveToLast(tokenId);
            return true;
     }


//VITAL INTERNAL FUNCITONS
    function claimStake ( uint tokenId ) internal returns (bool){
        uint randomNumber = randomNumberGenerated.initiateRandomness(tokenId,nftToken.actionTimestamp(tokenId))%100;
        (,uint8 level,,,) =
        metadataHandler.getToken(tokenId);
        if (stakeConfirmation[tokenId] == false) {
            require (block.timestamp >= firstStakeLockPeriod[tokenId]);
            stakeConfirmation[tokenId] = true;
            if(isFrenzy()) {
                bool query =  executeClaims(randomNumber, tokenId, 55, 63+2*(level));
                return query;
            }
            else if(isAggression()){
                uint aggKicker = whichAggression();
                bool query = executeClaims(randomNumber, tokenId, 80-3*aggKicker, 85+2*(level));
                return query;
            }
            else {
                bool query =  executeClaims(randomNumber, tokenId, 80, 88+2*(level));
                return query;
            }
        }
        else {
            if(isFrenzy()){
                bool query = executeClaims(randomNumber, tokenId, 55, 63+2*(level));
                return query;
            }
            else if(isAggression()){
                uint aggKicker = whichAggression();
                bool query = executeClaims(randomNumber, tokenId, 80-3*aggKicker, 85+2*(level));
                return query;
            }
            else{
                bool query = executeClaims(randomNumber, tokenId, 80, 88+2*(level));
                return query;
            }
        }
    }

    function unstakeNFT ( uint tokenId ) internal {
        uint randomNumber = randomNumberGenerated.initiateRandomness(tokenId,nftToken.actionTimestamp(tokenId));
        if (stakeConfirmation[tokenId] == true) {
            (,uint8 level,,,) = metadataHandler.getToken(tokenId);
            uint burnPercent = unstakeBurnCalculator(level);
            if(randomNumber%100 <= burnPercent){
                nftToken.burnNFT(tokenId);
                moveToLast(tokenId);
            }
            else {
                nftToken.safeTransferFrom(address(this), msg.sender, tokenId);
                moveToLast(tokenId);
            }
        }
        else {
            uint burnPercent = unstakeBurnCalculator(1);
            if(randomNumber%100 <= burnPercent){
                nftToken.burnNFT(tokenId);
                moveToLast(tokenId);
            }
            else{
                nftToken.safeTransferFrom(address(this), msg.sender, tokenId);}
                moveToLast(tokenId);
        }
    }

    function claimAndUnstake (bool claim,uint[] memory tokenAmount) external nonReentrant{

        for (uint i=0;i<tokenAmount.length;i++) {
            require (nftToken.tokenOwnerCall(tokenAmount[i]) == msg.sender, "Caller not the owner");
            require (nftToken.ownerOf(tokenAmount[i]) == address(this),"Contract not the owner");
            require (isStaked[tokenAmount[i]] = true, "Not Staked");
            require (stakeTime[tokenAmount[i]]+ tokenToRandomHourInStake[tokenAmount[i]]<= block.timestamp,"Be Patient");
          
            if (claim == true) {
                claimStake(tokenAmount[i]);
            }
            else {
                bool isBurnt = claimStake(tokenAmount[i]);
                if (isBurnt == false)
                {
                    unstakeNFT(tokenAmount[i]);
                    isStaked[tokenAmount[i]] = false;
                }

            }
            nftToken.setTimeStamp(tokenAmount[i]);
        }
    }

    function totalStakedOfType(uint8 tokenType) public view returns(uint){       
        uint totalStaked; 
        for(uint8 j=1;j<6;j++){
                totalStaked += pool[tokenType][j].length;
        }
        return totalStaked;
        
    }
}