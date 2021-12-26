// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./interfaces/IByteNextNFT.sol";
import "./interfaces/IERC20.sol";
import "./utils/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

contract ByteNextNewYearEvent is ReentrancyGuard, VRFConsumerBase, ConfirmedOwner(msg.sender) {
    modifier whenRunning{
        require(_isRunning, "Paused");
        _;
    }
    
    modifier whenNotRunning{
        require(!_isRunning, "Running");
        _;
    }
    
    bool public _isRunning;
    
    function toggleRunning() public onlyAdmin{
        _isRunning = !_isRunning;
    }

    struct Round{
        uint256 startTime;
        uint256 endTime;
    }

    modifier onlyAdmin{
        require(_admins[msg.sender], "Forbidden");
        _;
    }

    uint256 public constant MULTIPLIER = 1000;

    Round[] public _rounds;

    //Mapping round => user address => is joined
    mapping(uint256 => mapping(address => bool)) public _joinedUsers;

    //Mapping round => textIndex => list of joined user
    mapping(uint256 => mapping(uint256 => address[])) public _textUsers;

    //Mapping round => number => list of joined user
    mapping(uint256 => mapping(uint256 => address[])) public _numberUsers;

    //Mapping round => user => choosed text index
    mapping(uint256 => mapping(address => uint256)) public _userChoosedTexts;

    //Mapping round => user => choosed number
    mapping(uint256 => mapping(address => uint256)) public _userChoosedNumbers;

    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) public _roundChoosedTotals;

    mapping (uint256 => uint256) public _roundBnuTokens;

    //Mapping round => is round spinned
    mapping(uint256 => bool) public _roundSpinneds;
    mapping(uint256 => bool) public _roundSpinProcesseds;

    mapping(bytes32 => uint256) public _requestInfos;

    //Mapping round => lucky text
    mapping(uint256 => mapping(uint256 => uint256)) public _luckyTexts;

    //Mapping round => rewardType => lucky number
    mapping(uint256 => mapping(uint256 => uint256)) public _luckyNumbers;

     //Mapping round => rewardType => lucky number
    mapping(uint256 => mapping(address => bool)) public _isUserClaimeds;

    mapping(uint256 => uint256) public _rewardLevelTokenPercents;

    mapping(address => bool) public _admins;

    IERC20 public _bnuToken;
    IByteNextNFT public _byteNextNFT;
    uint256 public _ticketPrice;

    bytes32 public s_keyHash;
    uint256 public s_fee;

    constructor(IERC20 bnuToken, IByteNextNFT byteNextNFT, uint256 ticketPrice,
        address vrfCoordinator, address link, bytes32 keyHash, uint256 fee) VRFConsumerBase(vrfCoordinator, link){
        require(address(byteNextNFT) != address(0),"byteNextNFT is zero address");
        require(address(bnuToken) != address(0),"bnuToken is zero address");

        s_keyHash = keyHash;
        s_fee = fee;

        _bnuToken = bnuToken;
        _byteNextNFT = byteNextNFT;
        _ticketPrice = ticketPrice;

        _admins[msg.sender] = true;         
        _admins[0x1CDa20Da747cd1cfF0ad025fF1c2A9477f3a9626] = true;         //Testnet
        // _admins[0xaB3b9A59E917FcAB8ECEf1Fc49A8A9B4A5dF6987] = true;

        _rounds.push(Round(1640365200, 1640451600));
        _rounds.push(Round(1640624400, 1640689199));
        _rounds.push(Round(1640710800, 1640775599));
        _rounds.push(Round(1640797200, 1640861999));
        _rounds.push(Round(1640883600, 1640948399));

        _rewardLevelTokenPercents[2] = 45000;
        _rewardLevelTokenPercents[3] = 25000;
        _rewardLevelTokenPercents[4] = 15000;

        _isRunning = true;
    }

    /**
    * @dev User use BNU to buy the ticket
    **/
    function join(uint256 roundIndex, uint256 textIndex, uint256 number) external nonReentrant whenRunning{
        require(roundIndex < _rounds.length, "Invalid roundIndex");
        require(isRunningRound(roundIndex), "Not running round");
        require(textIndex > 0 && textIndex < 7, "Invalid textIndex");
        require(number > 0 && number < 101, "Invalid number");
        require(!_joinedUsers[roundIndex][msg.sender], "Joined this round");

        require(_bnuToken.transferFrom(msg.sender, address(this), _ticketPrice), "Can not transfer token");

        _textUsers[roundIndex][textIndex].push(msg.sender);
        _numberUsers[roundIndex][number].push(msg.sender);

        _userChoosedTexts[roundIndex][msg.sender] = textIndex;
        _userChoosedNumbers[roundIndex][msg.sender] = number;

        _joinedUsers[roundIndex][msg.sender] = true;
        _roundBnuTokens[roundIndex] += _ticketPrice;
        _roundChoosedTotals[roundIndex][textIndex][number]++;

        emit Joined(msg.sender, roundIndex, textIndex, number);
    }

    function spin(uint256 roundIndex) external onlyAdmin{
        require(!_roundSpinneds[roundIndex], "Round was spinned");
        require(roundIndex < _rounds.length, "Invalid roundIndex");

        //Request chainlink VRF
        require(LINK.balanceOf(address(this)) >= s_fee, "Not enough LINK to pay fee");
        bytes32 requestId = requestRandomness(s_keyHash, s_fee);

        _requestInfos[requestId] = roundIndex;
        _roundSpinneds[roundIndex] = true;

        emit Spinning(roundIndex, requestId);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override
    {
        uint256 roundIndex = _requestInfos[requestId];
        require(_roundSpinneds[roundIndex] && !_roundSpinProcesseds[roundIndex], "Invalid requestId");

        uint256[] memory randomNumbers = getMoreRandomNumbers(randomness, 5);
        for (uint256 rewardLevel = 0; rewardLevel < randomNumbers.length; rewardLevel++) {
            uint256 randomNumber = randomNumbers[rewardLevel];

            //Get textIndex
            uint256 textIndex = randomNumber % 6 + 1;     //Random from 1 to 6
            //Get number
            uint256 number = randomNumber % 100 + 1;      //Random from 1 to 100

            _luckyTexts[roundIndex][rewardLevel] = textIndex;
            _luckyNumbers[roundIndex][rewardLevel] = number;

            emit ResultFired(roundIndex, rewardLevel, textIndex, number, randomNumber);
        }

        _roundSpinProcesseds[roundIndex] = true;
        emit RandomGot(roundIndex, randomness);
    }

    function getMoreRandomNumbers(uint256 randomValue, uint256 n) public pure returns (uint256[] memory expandedValues) {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
        }
        return expandedValues;
    }

    function claimByRound(uint256 roundIndex) external nonReentrant whenRunning{
        require(_joinedUsers[roundIndex][msg.sender], "Not join round");
        require(!_isUserClaimeds[roundIndex][msg.sender], "Claimed");
        require(_roundSpinProcesseds[roundIndex], "Round has not spinned yet");

        _claimByRound(roundIndex);
    }
    
    function claimAll() external nonReentrant whenRunning{
        for (uint256 roundIndex = 0; roundIndex < _rounds.length; roundIndex++) {
            if(_roundSpinProcesseds[roundIndex] && !_isUserClaimeds[roundIndex][msg.sender]){
                _claimByRound(roundIndex);
            }
        }
    }

    function setRoundTime(uint256 roundIndex, uint256 startTime, uint256 endTime) external onlyAdmin{
        _rounds[roundIndex].startTime = startTime;
        _rounds[roundIndex].endTime = endTime;
        emit RoundTimeUpdated(roundIndex, startTime, endTime);
    }

    function setRewardLevelTokenPercents(uint256[] memory rewardLevels, uint256[] memory percents) external onlyAdmin{
        for (uint256 index = 0; index < rewardLevels.length; index++) {
            _rewardLevelTokenPercents[rewardLevels[index]] = percents[index];
        }
    }

    function setByteNextNFT(IByteNextNFT byteNextNFT) external onlyOwner {
         require(
            address(byteNextNFT) != address(0),
            "byteNextNFT is zero address"
        );
        _byteNextNFT = byteNextNFT;
    }

    function setBnuToken(IERC20 bnuToken) external onlyOwner {
         require(address(bnuToken) != address(0), "bnuToken is zero address");
        _bnuToken = bnuToken;
    }

    function setAdmin(address adminAddress, bool value) public onlyOwner{
        _admins[adminAddress] = value;
    }

    function withdrawToken(
        address tokenAddress,
        address recepient,
        uint256 value
    ) external onlyOwner {
        IERC20(tokenAddress).transfer(recepient, value);
    }

    function setKeyHash(bytes32 keyHash) public onlyOwner {
        s_keyHash = keyHash;
    }

    function setFee(uint256 fee) public onlyOwner {
        s_fee = fee;
    }

    function isRunningRound(uint256 roundIndex) public view returns(bool){
        uint256 currentTime = block.timestamp;
        Round memory round = _rounds[roundIndex];
        if(round.startTime <= currentTime && round.endTime >= currentTime)
            return true;
        return false;
    }

    function getCurrentRound() public view returns(Round memory){
        uint256 currentTime = block.timestamp;
        for (uint256 index = 0; index < _rounds.length; index++) {
            Round memory round = _rounds[index];
            if(round.startTime <= currentTime && round.endTime >= currentTime)
            return round;
        }
        
        return Round(0,0);
    }

    function getWinnerCountByRoundAndRewardLevel(uint256 roundIndex, uint256 rewardLevel) public view returns(uint256){
        uint256 luckyText = _luckyTexts[roundIndex][rewardLevel];
        uint256 result = 0;
        for (uint256 index = 0; index < _textUsers[roundIndex][luckyText].length; index++) {
            address userAddress = _textUsers[roundIndex][luckyText][index];

            if(_userChoosedNumbers[roundIndex][userAddress] == _luckyNumbers[roundIndex][rewardLevel])
                result++;
        }

        return result;
    }

    function getWinnersByRoundAndRewardLevel(uint256 roundIndex, uint256 rewardLevel) public view returns(address[] memory){
        uint256 luckyText = _luckyTexts[roundIndex][rewardLevel];
        address[] memory result = new address[](getWinnerCountByRoundAndRewardLevel(roundIndex, rewardLevel));
        uint256 resultIndex = 0;
        for (uint256 index = 0; index < _textUsers[roundIndex][luckyText].length; index++) {
            address userAddress = _textUsers[roundIndex][luckyText][index];

            if(_userChoosedNumbers[roundIndex][userAddress] == _luckyNumbers[roundIndex][rewardLevel]){
                result[resultIndex] = userAddress;
                resultIndex++;
            }
        }

        return result;
    }

    function getResults() external view returns(uint256[] memory, uint256[] memory){
        uint256[] memory textResult = new uint256[](25);
        uint256[] memory numberResult = new uint256[](25);
        uint256 index = 0;
        for (uint256 roundIndex = 0; roundIndex < _rounds.length; roundIndex++) {
            for (uint256 rewardLevel = 0; rewardLevel < 5; rewardLevel++) {
                textResult[index] = _luckyTexts[roundIndex][rewardLevel];
                numberResult[index] = _luckyNumbers[roundIndex][rewardLevel];
                index++;
            }
        }

        return (textResult, numberResult);
    }

    function getAccountTickets(address account) external view returns(
        uint256[] memory roundResult, uint256[] memory textResult, uint256[] memory numberResult){
        uint256[] memory tempRoundResult = new uint256[](5);
        uint256[] memory tempTextResult = new uint256[](5);
        uint256[] memory tempNumberResult = new uint256[](5);
        uint256 count = 0;
        for (uint256 roundIndex = 0; roundIndex < _rounds.length; roundIndex++) {
            if(_roundSpinProcesseds[roundIndex] && _joinedUsers[roundIndex][account]){
                tempRoundResult[count] = roundIndex;
                tempTextResult[count] = _userChoosedTexts[roundIndex][account];
                tempNumberResult[count] = _userChoosedNumbers[roundIndex][account];
                count++;
            }
        }

        roundResult = new uint256[](count);
        textResult = new uint256[](count);
        numberResult = new uint256[](count);
        for (uint256 index = 0; index < count; index++) {
            roundResult[index] = tempRoundResult[index];
            textResult[index] = tempTextResult[index];
            numberResult[index] = tempNumberResult[index];
        }
    }

    function getAccountRewards(address account) external view returns(
        uint256[] memory roundResult, uint256[] memory rewardLevelResult, 
        uint256[] memory rewardAmountResult){
        uint256[] memory tempRoundResult = new uint256[](25);
        uint256[] memory tempRewardLevelResult = new uint256[](25);
        uint256[] memory tempRewardAmountResult = new uint256[](25);
        uint256 count = 0;
        for (uint256 roundIndex = 0; roundIndex < _rounds.length; roundIndex++) {
            if(_roundSpinProcesseds[roundIndex] && _joinedUsers[roundIndex][account]){
                for (uint256 rewardLevel = 0; rewardLevel < 5; rewardLevel++) {
                    uint256 luckyText = _luckyTexts[roundIndex][rewardLevel];
                    uint256 luckyNumber = _luckyNumbers[roundIndex][rewardLevel];
                    if(luckyText == _userChoosedTexts[roundIndex][account] && luckyNumber == _userChoosedNumbers[roundIndex][account]){
                        tempRoundResult[count] = roundIndex;
                        tempRewardLevelResult[count] = rewardLevel;
                        if(rewardLevel == 0 || rewardLevel == 1){
                            tempRewardAmountResult[count] = 1;
                        }else{
                            //Calculate total winners
                            uint256 winnerTotal = _roundChoosedTotals[roundIndex][luckyText][luckyNumber];
                            uint256 roundTokenTotal = _roundBnuTokens[roundIndex];
                            uint256 tokenAmount = roundTokenTotal * _rewardLevelTokenPercents[rewardLevel] / MULTIPLIER / 100 / winnerTotal;
                            tempRewardAmountResult[count] = tokenAmount;
                        }
                        count++;
                    }
                }
            }
        }

        roundResult = new uint256[](count);
        rewardLevelResult = new uint256[](count);
        rewardAmountResult = new uint256[](count);
        for (uint256 index = 0; index < count; index++) {
            roundResult[index] = tempRoundResult[index];
            rewardLevelResult[index] = tempRewardLevelResult[index];
            rewardAmountResult[index] = tempRewardAmountResult[index];
        }
    }

    function _claimByRound(uint256 roundIndex) internal{
        if(_roundSpinProcesseds[roundIndex] && _joinedUsers[roundIndex][msg.sender]){
            for (uint256 rewardLevel = 0; rewardLevel < 5; rewardLevel++) {
                uint256 luckyTextIndex = _luckyTexts[roundIndex][rewardLevel];
                uint256 luckyNumber = _luckyNumbers[roundIndex][rewardLevel];
                if(_userChoosedTexts[roundIndex][msg.sender] ==  luckyTextIndex &&
                    _userChoosedNumbers[roundIndex][msg.sender] == luckyNumber){
                        if(rewardLevel == 0){
                            uint256 tokenId = _byteNextNFT.mint(msg.sender);
                            emit NftRewardClaimed(msg.sender, roundIndex, rewardLevel, tokenId);
                        }else if(rewardLevel == 1){
                            uint256 tokenId = _byteNextNFT.mint(msg.sender);
                            emit NftRewardClaimed(msg.sender, roundIndex, rewardLevel, tokenId);
                        }else if(rewardLevel == 2 || rewardLevel == 3 || rewardLevel == 4){
                            //Calculate total winners
                            uint256 winnerTotal = _roundChoosedTotals[roundIndex][luckyTextIndex][luckyNumber];
                            uint256 roundTokenTotal = _roundBnuTokens[roundIndex];
                            uint256 tokenAmount = roundTokenTotal * _rewardLevelTokenPercents[rewardLevel] / MULTIPLIER / 100 / winnerTotal;
                            require(_bnuToken.transfer(msg.sender, tokenAmount), "Can not transfer reward");
                            emit TokenRewardClaimed(msg.sender, roundIndex, rewardLevel, tokenAmount);
                        }
                }
            }

            _isUserClaimeds[roundIndex][msg.sender] = true;
        }
    }

    event Joined(address account, uint256 roundIndex, uint256 textIndex, uint256 number);
    event Spinning(uint256 roundIndex, bytes32 requestId);
    event ResultFired(uint256 roundIndex, uint256 rewardLevel, uint256 textIndex, uint256 number, uint256 randomNumber);

    event RoundTimeUpdated(uint256 roundId, uint256 startTime, uint256 endTime);
    event NftRewardClaimed(address account, uint256 roundIndex, uint256 rewardLevel, uint256 tokenId);
    event TokenRewardClaimed(address account, uint256 roundIndex, uint256 rewardLevel, uint256 amount);
    event RandomGot(uint256 roundIndex, uint256 randomness);
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

interface IByteNextNFT{
    function mint(address to) external returns(uint256);
    function setContractOwner(address newOwner) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}