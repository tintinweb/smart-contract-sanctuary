// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IERC721.sol";
import "./interfaces/IERC721Receiver.sol";
import "./interfaces/IElemonInfo.sol";
import "./interfaces/IElemonNFT.sol";
import "./utils/ReentrancyGuard.sol";

contract ElemonCombine is
    ReentrancyGuard,
    VRFConsumerBase,
    ConfirmedOwner(msg.sender), IERC721Receiver
{
    struct RequestInfo {
        address account;
        uint256 tokenId1;
        uint256 tokenId2;
        uint256 newTokenId;
        uint256 rarityIndex;
    }

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    uint256 public MAX_RARELY = 5;
    uint256 public MIN_QUALITY = 1;
    uint256 public MAX_QUALITY = 9;

    uint256 public CONST_01 = 5;
    uint256 public CONST_02 = 5;
    uint256 public CONST_03 = 18;
    uint256 public CONST_04 = 30;
    uint256 public CONST_05 = 6;
    uint256 public CONST_06 = 5;
    uint256 public CONST_07 = 5;
    uint256 public CONST_08 = 3;
    uint256 public CONST_09 = 5;
    uint256 public CONST_10 = 30;

    mapping(bytes32 => RequestInfo) public _requestInfos;

    uint256[] public _avgRarities;
    mapping(uint256 => uint256[]) public _avgRarityGroups;
    mapping(uint256 => uint256[]) public _avgRarityGroupRates;

    //Mapping between rarity and price of each rarity to process combine
    mapping(uint256 => uint256) public _avgRarityPrices;

    address public _recipientTokenAddress;
    IElemonInfo public _elemonInfo;
    IElemonNFT public _elemonNFT;
    IERC20 public _paymentToken;

    bytes32 public s_keyHash;
    uint256 public s_fee;

    //List of base card id by group
    //Group => base card id list
    mapping(uint256 => uint256[]) public _baseCardIds;

    //Body parts
    //Group => Base card id => body part (1, 2, 3, 4, 5, 6) => list of body part
    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256[])))
        public _bodyParts;

    //Classes
    //Group => Base card id => list of class
    mapping(uint256 => mapping(uint256 => uint256[])) public _classes;

    //Group => Base card id => baseRarely
    mapping(uint256 => mapping(uint256 => uint256)) public _baseRarities;

    //Group => Base card id => allow to random
    mapping(uint256 => mapping(uint256 => uint256)) public _allowRandoms;

    mapping(uint256 => mapping(uint256 => uint256[])) public _qualityRates;

    bool public _isRunning;
    modifier whenRunning{
        require(_isRunning, "Contract is not running");
        _;
    }

    constructor(
        address paymentTokenAddress,
        address recipientTokenAddress,
        address elemonInfoAddress,
        address elemonNFTAddress,
        address vrfCoordinator,
        address link,
        bytes32 keyHash,
        uint256 fee
    ) VRFConsumerBase(vrfCoordinator, link) {
        s_keyHash = keyHash;
        s_fee = fee;

        _paymentToken = IERC20(paymentTokenAddress);
        _recipientTokenAddress = recipientTokenAddress;
        _elemonInfo = IElemonInfo(elemonInfoAddress);
        _elemonNFT = IElemonNFT(elemonNFTAddress);

        _isRunning = true;

        setDefaultRarityProperties();
    }

    function setDefaultRarityProperties() public onlyOwner{
        _avgRarities = [1,2,3];

        _avgRarityPrices[0] = 50000000000000000000;
        _avgRarityPrices[1] = 100000000000000000000;
        _avgRarityPrices[2] = 200000000000000000000;

        _avgRarityGroups[0] = [1,2,3,4,5,6,7,8];
        _avgRarityGroups[1] = [1,2,3,4,5,6,7,8];
        _avgRarityGroups[2] = [1,2,3,4,5,6,7,8];

        _avgRarityGroupRates[0] = [0, 50, 0, 0, 0, 0, 50, 0];
        _avgRarityGroupRates[1] = [0, 50, 0, 0, 0, 0,100, 10];
        _avgRarityGroupRates[2] = [15, 0, 400, 8000, 2000, 2200, 0, 0];
    }

    function combine(uint256 tokenId1, uint256 tokenId2) external nonReentrant whenRunning {
         require(
            _recipientTokenAddress != address(0),
            "Recepient address is not setted"
        );
        require(tokenId1 > 0, "TokenId1 is invalid");
        require(tokenId2 > 0, "tokenId2 is invalid");

        uint256 rarity1 = _elemonInfo.getRarity(tokenId1);
        require(rarity1 > 0, "Invalid tokenId1 rarity");
        uint256 rarity2 = _elemonInfo.getRarity(tokenId2);
        require(rarity2 > 0, "Invalid tokenId2 rarity");

        uint256 avgRarity = (rarity1 + rarity2) / 2;

        //Calculate price
        uint256 price = _avgRarityPrices[0];
        uint256 rarityIndex = 0;
        for (uint256 index = _avgRarities.length-1; index >= 0; index--){
            if(avgRarity >= _avgRarities[index]){
                price = _avgRarityPrices[index];
                rarityIndex = index;
                break;
            }
        }

        require(LINK.balanceOf(address(this)) >= s_fee, "Not enough LINK to pay fee");

        require(_paymentToken.transferFrom(msg.sender, _recipientTokenAddress, price), "Can not transfer payment token");

        //Get user NFTs
        _elemonNFT.safeTransferFrom(msg.sender, BURN_ADDRESS, tokenId1);
        _elemonNFT.safeTransferFrom(msg.sender, BURN_ADDRESS, tokenId2);

        uint256 newTokenId = _elemonNFT.mint(address(this));

        //Request chainlink VRF
        bytes32 requestId = requestRandomness(s_keyHash, s_fee);
        _requestInfos[requestId] = RequestInfo({
            account: msg.sender,
            tokenId1: tokenId1,
            tokenId2: tokenId2,
            newTokenId: newTokenId,
            rarityIndex: rarityIndex
        });

        emit Combined(msg.sender, tokenId1, tokenId2, newTokenId, requestId, block.timestamp);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override{
        RequestInfo storage requestInfo = _requestInfos[requestId];
        require(requestInfo.account != address(0), "Request is invalid");

        (uint256 baseCardId, uint256[6] memory bodyParts, uint256 quality, uint256 class, uint256 rarity) = 
            getRandomResult(requestInfo.rarityIndex, requestInfo.tokenId1, requestInfo.tokenId2, randomness);

        _elemonInfo.setInfo(requestInfo.newTokenId, baseCardId, bodyParts, quality, class, rarity, 0);

        _elemonNFT.safeTransferFrom(address(this), requestInfo.account, requestInfo.newTokenId);

        emit CombinationCompleted(requestInfo.newTokenId, baseCardId, bodyParts, quality, class, rarity);
        requestInfo.account = address(0);
    }

    function getRandomResult(uint256 rarityIndex, uint256 tokenId1, uint256 tokenId2, uint256 randomness) public view 
    returns(uint256 baseCardId, uint256[6] memory bodyParts, uint256 quality, uint256 class, uint256 rarity){
        uint256[] memory groupRates = _avgRarityGroupRates[rarityIndex];

        //Get group
        uint256 processValue = 0;
        for (uint256 index = 0; index < groupRates.length; index++) {
            processValue += groupRates[index];
        }
        uint256 processNumber = (randomness % processValue) + 1;
        processValue = 0;
        uint256 group = 0;
        for (uint256 index = 0; index < groupRates.length; index++) {
            processValue += groupRates[index];
            if (processNumber <= processValue) {
                group = _avgRarityGroups[rarityIndex][index];
                break;
            }
        }

        require(group > 0, "Fail to get group");
        randomness = getMoreRandomNumbers(randomness, 1)[0];

        {
            uint256 baseCardId1 = _elemonInfo.getBaseCardId(tokenId1);
            uint256 baseCardId2 = _elemonInfo.getBaseCardId(tokenId2);
            if(baseCardId1 == baseCardId2){
                baseCardId = baseCardId1;
            }else{
                uint256[] memory baseCardIds = new uint256[](_baseCardIds[group].length);
                processValue = 0;
                for (uint256 index = 0; index < _baseCardIds[group].length; index++) {
                    if(_allowRandoms[group][_baseCardIds[group][index]] == 1){
                        baseCardIds[processValue] = _baseCardIds[group][index];
                        processValue++;
                    }
                }

                if(processValue == _baseCardIds[group].length){
                    baseCardId = _baseCardIds[group][randomness % processValue];
                }else{
                    baseCardId = baseCardIds[randomness % processValue];      
                }
            }
        }

        uint256[] memory randomNumbers = getMoreRandomNumbers(randomness, 6);

        bodyParts = [
            _getBodyPartItem(randomNumbers[0], _bodyParts[group][baseCardId][1]),
            _getBodyPartItem(randomNumbers[1], _bodyParts[group][baseCardId][2]),
            _getBodyPartItem(randomNumbers[2], _bodyParts[group][baseCardId][3]),
            _getBodyPartItem(randomNumbers[3], _bodyParts[group][baseCardId][4]),
            _getBodyPartItem(randomNumbers[4], _bodyParts[group][baseCardId][5]),
            _getBodyPartItem(randomNumbers[5], _bodyParts[group][baseCardId][6])
        ];

        randomness = getMoreRandomNumbers(randomness, 1)[0];
        class = _getBodyPartItem(randomness, _classes[group][baseCardId]);

        {
            uint256 quality1 = _elemonInfo.getQuality(tokenId1);
            uint256 rarity2 = _elemonInfo.getRarity(tokenId2);

            //Quality of elemon1 and Rarity of elemon2
            randomness = getMoreRandomNumbers(randomness, 1)[0];
            quality = _getBodyPartItem(randomness, _qualityRates[quality1][rarity2]) - 1;
            if(quality == 0){       //Down
                if(quality1 > MIN_QUALITY)
                    quality = quality1 - 1;
                else
                    quality = quality1;
            }else if(quality == 1){ //Keep
                quality = quality1;
            }else{          //Up
                if(quality1< MAX_QUALITY)
                    quality = quality1 + 1;
                else
                    quality = quality1;
            }
        }

        rarity = _calculateRarity(quality, bodyParts, _baseRarities[group][baseCardId]);
    }

    function getMoreRandomNumbers(uint256 randomValue, uint256 n) public pure returns (uint256[] memory expandedValues) {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
        }
        return expandedValues;
    }

    function setAvgRarities(uint256[] memory avgRarities) public onlyOwner {
        _avgRarities = avgRarities;
    }

    function setAvgRarityGroupRate(uint256 rarityIndex, uint256[] memory groupRates) public onlyOwner {
        _avgRarityGroupRates[rarityIndex] = groupRates;
    }

    function setAvgRarityGroups(uint256 rarityIndex, uint256[] memory groups) public onlyOwner
    {
        _avgRarityGroups[rarityIndex] = groups;
    }

    function setBaseCardIds(uint256 group, uint256[] memory baseCardIds)
        external
        onlyOwner
    {
        _baseCardIds[group] = baseCardIds;
    }

    function setAllowRandom(uint256 group, uint256[] memory baseCardIds, uint256[] memory values)
        external
        onlyOwner
    {
        for (uint256 index = 0; index < baseCardIds.length; index++) {
            _allowRandoms[group][baseCardIds[index]] = values[index];
        }
    }

    function setBodyPart(
        uint256 group,
        uint256 baseCardId,
        uint256 part,
        uint256[] memory bodyParts
    ) external onlyOwner {
        _bodyParts[group][baseCardId][part] = bodyParts;
    }

    function setProperties(
        uint256 group,
        uint256 baseCardId,
        uint256[] memory bodyParts1,
        uint256[] memory bodyParts2,
        uint256[] memory bodyParts3,
        uint256[] memory bodyParts4,
        uint256[] memory bodyParts5,
        uint256[] memory bodyParts6,
        uint256[] memory classes,
        uint256[] memory baseRaritiesAndAllowRandoms
    ) external onlyOwner {
        _bodyParts[group][baseCardId][1] = bodyParts1;
        _bodyParts[group][baseCardId][2] = bodyParts2;
        _bodyParts[group][baseCardId][3] = bodyParts3;
        _bodyParts[group][baseCardId][4] = bodyParts4;
        _bodyParts[group][baseCardId][5] = bodyParts5;
        _bodyParts[group][baseCardId][6] = bodyParts6;

        _classes[group][baseCardId] = classes;
        _baseRarities[group][baseCardId] = baseRaritiesAndAllowRandoms[0];
        _allowRandoms[group][baseCardId] = baseRaritiesAndAllowRandoms[1];
    }

    function setClass(
        uint256 group,
        uint256 baseCardId,
        uint256[] memory classes
    ) external onlyOwner {
        _classes[group][baseCardId] = classes;
    }

    function setQualityRate(uint256 quality, uint256 rarity, uint256[] memory rates) external onlyOwner{
        _qualityRates[quality][rarity] = rates;
    }

    function setQualityRates(uint256 quality, uint256[] memory rarities,
        uint256[] memory rates1, uint256[] memory rates2, uint256[] memory rates3,
        uint256[] memory rates4, uint256[] memory rates5) external onlyOwner{
        _qualityRates[quality][rarities[0]] = rates1;
        _qualityRates[quality][rarities[1]] = rates2;
        _qualityRates[quality][rarities[2]] = rates3;
        _qualityRates[quality][rarities[3]] = rates4;
        _qualityRates[quality][rarities[4]] = rates5;
    }

    function setPaymentToken(address paymentTokenAddress) external onlyOwner {
        _paymentToken = IERC20(paymentTokenAddress);
    }

    function setRecepientTokenAddress(address recipientTokenAddress)
        external
        onlyOwner
    {
        _recipientTokenAddress = recipientTokenAddress;
    }

    function setElemonInfo(address newAddress) external onlyOwner {
        _elemonInfo = IElemonInfo(newAddress);
    }

    function setElemonNFT(address newAddress) external onlyOwner {
        _elemonNFT = IElemonNFT(newAddress);
    }

    function setRarityPrices(uint256 [] memory indexs, uint256[] memory prices)
        external
        onlyOwner
    {
        for (uint256 index = 0; index < indexs.length; index++) {
            _avgRarityPrices[indexs[index]] = prices[index];
        }
    }

    function setBaseRarities(
        uint256 group,
        uint256 baseCardId,
        uint256 value
    ) external onlyOwner {
        _baseRarities[group][baseCardId] = value;
    }

    function setAllowRandoms(
        uint256 group,
        uint256 baseCardId,
        uint256 value
    ) external onlyOwner {
        _allowRandoms[group][baseCardId] = value;
    }

    function setKeyHash(bytes32 keyHash) public onlyOwner {
        s_keyHash = keyHash;
    }

    function setFee(uint256 fee) public onlyOwner {
        s_fee = fee;
    }

    function setCombineConstantProperties(
        uint256 _MAX_RARELY,
        uint256 _MAX_QUALITY,
        uint256 _MIN_QUALITY
    ) public onlyOwner {
        MAX_RARELY = _MAX_RARELY;
        MAX_QUALITY = _MAX_QUALITY;
        MIN_QUALITY = _MIN_QUALITY;
    }

    function setCombineConstantNumbers(
        uint256 _CONST_01,
        uint256 _CONST_02,
        uint256 _CONST_03,
        uint256 _CONST_04,
        uint256 _CONST_05,
        uint256 _CONST_06,
        uint256 _CONST_07,
        uint256 _CONST_08,
        uint256 _CONST_09,
        uint256 _CONST_10
    ) public onlyOwner {
        CONST_01 = _CONST_01;
        CONST_02 = _CONST_02;
        CONST_03 = _CONST_03;
        CONST_04 = _CONST_04;
        CONST_05 = _CONST_05;
        CONST_06 = _CONST_06;
        CONST_07 = _CONST_07;
        CONST_08 = _CONST_08;
        CONST_09 = _CONST_09;
        CONST_10 = _CONST_10;
    }

    function batchWithdrawNft(uint256[] memory tokenIds, address recipient) external onlyOwner{
        require(recipient != address(0), "recipient is zero address");
        require(tokenIds.length > 0, "tokenIds is empty");
        for (uint256 index = 0; index < tokenIds.length; index++) {
            _elemonNFT.safeTransferFrom(address(this), recipient, tokenIds[index]);
        }
    }

    function toggleRunningStatus() external onlyOwner{
        _isRunning = !_isRunning;
    }

    function withdrawToken(
        address tokenAddress,
        address recepient,
        uint256 value
    ) public onlyOwner {
        IERC20(tokenAddress).transfer(recepient, value);
    }

    function _getBodyPartItem(uint256 number, uint256[] memory bodyParts)
        internal
        pure
        returns (uint256)
    {
        uint256 processValue = 0;
        for (uint256 index = 0; index < bodyParts.length; index++) {
            processValue += bodyParts[index];
        }
        uint256 rarityNumber = (number % processValue) + 1;
        processValue = 0;
        for (uint256 index = 0; index < bodyParts.length; index++) {
            processValue += bodyParts[index];
            if (rarityNumber <= processValue) {
                return index + 1;
            }
        }
        return 1;
    }

    function _calculateRarity(uint256 quality, uint256[6] memory bodyParts, uint256 baseRarity) internal view returns(uint256){
        uint256 cardRarelyPoint = quality > CONST_01 ? (quality - CONST_02) * CONST_03 + CONST_04 : quality * CONST_05;

        uint256 partsRarelyPoint =  0;
        for(uint256 i = 0; i< bodyParts.length; i++){
            uint256 partQuality = bodyParts[i];
            uint256 s =  partQuality > CONST_06 ?  (partQuality - CONST_07) * CONST_08 + CONST_09 : partQuality;
            partsRarelyPoint += s;
        }

        uint256 cardRarity =  baseRarity + (cardRarelyPoint + partsRarelyPoint)/ CONST_10;
        cardRarity =  cardRarity < MAX_RARELY ? cardRarity : MAX_RARELY;
        return cardRarity;
    }
        
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external view override returns (bytes4){
        return bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    event Combined(address account, uint256 tokenId1, uint256 tokenId2, uint256 newTokenId, bytes32 requestId, uint256 time);
    event CombinationCompleted(uint256 tokenId, uint256 baseCardId, uint256[6] bodyParts, uint256 quality, uint256 class, uint256 rarity);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner()
    external
    returns (
      address
    );

  function transferOwnership(
    address recipient
  )
    external;

  function acceptOwnership()
    external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {

  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(
    address indexed from,
    address indexed to
  );
  event OwnershipTransferred(
    address indexed from,
    address indexed to
  );

  constructor(
    address newOwner,
    address pendingOwner
  ) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(
    address to
  )
    public
    override
    onlyOwner()
  {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership()
    external
    override
  {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner()
    public
    view
    override
    returns (
      address
    )
  {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(
    address to
  )
    private
  {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership()
    internal
    view
  {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {

  constructor(
    address newOwner
  )
    ConfirmedOwnerWithProposal(
      newOwner,
      address(0)
    )
  {
  }

}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

abstract contract ReentrancyGuard {
    uint256 public constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 internal _status;

    constructor() {
         _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IElemonNFT{
    function mint(address to) external returns(uint256);
    function setContractOwner(address newOwner) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IElemonInfo {
    struct Info {
        uint256 rarity;
        uint256 baseCardId;
        uint256[6] bodyParts;
        uint256 quality;
        uint256 class;
        uint256 star;
    }

    function getTokenInfo(uint256 tokenId) external returns(Info memory);
    function getTokenInfoValues(uint256 tokenId) external view 
        returns (uint256 rarity, uint256 baseCardId, uint256[] memory bodyParts, uint256 quality, uint256 class, uint256 star);
    function getRarity(uint256 tokenId) external view returns(uint256);
    function getBaseCardId(uint256 tokenId) external view returns (uint256);
    function getBodyPart(uint256 tokenId) external view returns (uint256[] memory);
    function getQuality(uint256 tokenId) external view returns (uint256);
    function getClass(uint256 tokenId) external view returns (uint256);
    function getStar(uint256 tokenId) external view returns (uint256);

    function setRarity(uint256 tokenId, uint256 rarity) external;
    function setBodyParts(uint256 tokenId, uint256[6] memory bodyParts) external;
    function setQuality(uint256 tokenId, uint256 quality) external;
    function setClass(uint256 tokenId, uint256 class) external;
    function setStar(uint256 tokenId, uint256 star) external;
    function setInfo(
        uint256 tokenId,
        uint256 baseCardId,
        uint256[6] memory bodyParts,
        uint256 quality,
        uint256 class,
        uint256 rarity,
        uint256 star
    ) external;
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC165.sol";

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    
    function isExisted(uint256 tokenId) external view returns(bool);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}