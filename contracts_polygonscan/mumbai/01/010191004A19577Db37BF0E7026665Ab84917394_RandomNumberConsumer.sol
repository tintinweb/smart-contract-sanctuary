/**
 *Submitted for verification at polygonscan.com on 2021-09-17
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;
contract VRFRequestIDBase {
    
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


abstract contract VRFConsumerBase is VRFRequestIDBase {


  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;


  uint256 constant private USER_SEED_PLACEHOLDER = 0;

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
   
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);

    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }


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

 interface IERCRandom {
    function getRandomNumber(uint256 _tokenId, address  _contractaddress) external returns (bytes32);
    function getRandomResult(uint256 _tokenId) external view returns(uint256);
 }
 
 interface IERC721{
    function _setTokenURI(uint256 tokenId, uint256 tokenIndex) external ; 
 }
 
contract RandomNumberConsumer is VRFConsumerBase {
    
    bytes32 internal keyHash;
    uint256 internal fee;
    IERC721 private ERC721;
    mapping(uint256 => bytes32) public requestIds;
    mapping (uint256 => uint256) private randomIndex;
    mapping(bytes32 => uint256) private tokenIds;
    mapping(bytes32 => mapping (uint256 => uint256)) private randomindex;
    
    uint256 public randomResult;
    
    constructor() 
        VRFConsumerBase(
            0x8C7382F9D8f56b33781fE506E897a4F1e2d17255, // VRF Coordinator
            0x326C977E6efc84E512bB9C30f76E30c160eD06FB  // LINK Token
        )
    {
        keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
        fee = 0.0001 * 10 ** 18; // 0.1 LINK (Varies by network)
    }
    
    /** 
     * Requests randomness 
     */
    function getRandomNumber(uint256 _tokenId, IERC721 _contractaddress) external returns (bytes32) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        ERC721 = _contractaddress;
        bytes32 requestId = requestRandomness(keyHash, fee);
        requestIds[_tokenId] = requestId;
        tokenIds[requestId] = _tokenId;
        return requestId;
        
    }
    
    
    function getRandomResult(uint256 _tokenId) external view returns(uint256){
        return randomIndex[_tokenId];
        
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness % 64;
        uint256 _tokenId = tokenIds[requestId];
        randomIndex[_tokenId] = randomResult;
        randomindex[requestId][_tokenId] = randomResult;
        ERC721._setTokenURI(tokenIds[requestId], randomIndex[_tokenId]);
        
    }
}