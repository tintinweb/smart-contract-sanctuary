/**
 *Submitted for verification at BscScan.com on 2021-11-08
*/

// SPDX-License-Identifier: unlicensed

pragma solidity ^0.8.7;

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

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

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
  ) internal pure returns (uint256) {
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
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

abstract contract VRFConsumerBase is VRFRequestIDBase {

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

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
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

}

contract Jackpot is VRFConsumerBase {
    
    bytes32 internal keyHash;
    uint256 internal fee;
    address owner;
    
    IERC20 public token;   
    
    uint256 private randomNum;
    uint256 public totalToken;
    uint256 private devFee = 5;
    uint256 private burnFee = 15;
    uint256 private people = 0;
    uint256 private counter = 0;
    uint256 public min_token;

    address[3] public expandedValues;
    address private BURN = address(0x000000000000000000000000000000000000dEaD);
    
    mapping(uint256 => mapping(uint256=>address)) private players;
    mapping(uint256 => mapping(address=>bool)) private check;
    mapping(uint256=>mapping(address=>uint256)) private tokensCnt;
    bool private start = true;
    
    constructor(IERC20 _token) 
        VRFConsumerBase(
            0x747973a5A2a4Ae1D3a8fDF5479f1514F65Db9C31, // VRF Coordinator
            0x404460C6A5EdE2D891e8297795264fDe62ADBB75  // LINK Token
        )
    {
        token = _token;
        keyHash = 0xc251acd21ec4fb7f31bb8868288bfdbaeb4fbfec2df3735ddbd4f7dc8d60103c;
        fee = 0.2 * 10 ** 18; // 0.1 LINK (Varies by network)
        owner = msg.sender;
    }
    
    modifier onlyOwner {
      require(msg.sender == owner,"you are not owner");
      _;
    }
    
    /** 
     * Requests randomness 
     */
    function getRandomNumber() public returns (bool) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        randomNum = uint256(requestRandomness(keyHash, fee));
        return true;
    }
    
    function bid(uint256 tokens) external returns(bool){
        require(start,"not started");
        require(tokens >= min_token,"tokens should be more than minimum tokens");
        require(token.balanceOf(msg.sender) >= tokens,"less balance");
        require(!check[counter][msg.sender],"already bidded");
        check[counter][msg.sender] = true;
        players[counter][people] = msg.sender;
        totalToken += tokens;
        tokensCnt[counter][msg.sender] += tokens;
        token.transferFrom(msg.sender,address(this),tokens);
        people++;
        if(people == 12) start = false;
        return true;
    }
    
    mapping(uint256=>mapping(uint256=>bool)) public unique;
    
    function result() external onlyOwner returns (bool) {
        require(people == 12,"12 people have not bidded");
        getRandomNumber();
        uint256 canbeWinner = 3;
        uint256 winnertoken;
        uint256 x;
        address win;
        uint256 i = 0;
        while (i < canbeWinner) {
            x = uint256(keccak256(abi.encode(randomNum, i)))%people;
            if(!unique[counter][x]){
                win = players[counter][x];
                winnertoken += tokensCnt[counter][win];
                expandedValues[i] = win;
                unique[counter][x] = true;
                i++;
            }
        }
        
        uint256 dev_token = (totalToken * devFee)/100;
        uint256 burn_token = (totalToken * burnFee)/100;
        token.transfer(owner,dev_token);
        token.transfer(BURN,burn_token);
        totalToken = totalToken - (dev_token + burn_token);
        
        for (i = 0; i<canbeWinner; i++){
            uint256 amount = (totalToken * tokensCnt[counter][expandedValues[i]]) / winnertoken; 
            token.transfer(expandedValues[i],amount);
        } 
        people = 0;
        counter++;
        start = true;
        totalToken = 0;
        return true;
    }
    
    function set_bidding(bool value) external onlyOwner {
        start = value;
    }
    
    function set_minToken(uint256 minToken) external onlyOwner {
        min_token = minToken * 10**9;
    }
    
    function set_fee(uint256 dev_fee, uint256 burn_fee) external onlyOwner {
        require(dev_fee <= 10 && burn_fee <= 15, "set dev fee <= 10 and burn fee <= 15");
        devFee = dev_fee;
        burnFee = burn_fee;
    }

   
    function withdrawLink() external onlyOwner {
        LINK.transfer(msg.sender,LINK.balanceOf(address(this)));
    }
}