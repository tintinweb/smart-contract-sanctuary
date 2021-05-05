// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import './IERC20.sol';
import './IERC721.sol';
import "./IERC721Receiver.sol";
import "./ERC165.sol";
import './Ownable.sol';
import './SafeMath.sol';
import './Address.sol';
import './Context.sol';

interface ILink is IERC20 {
    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success);
}

interface IApymonPack {
    function depositErc20IntoEgg(
        uint256 eggId,
        address[] memory tokens,
        uint256[] memory amounts
    ) external;
    function depositErc721IntoEgg(
        uint256 eggId,
        address token,
        uint256[] memory tokenIds
    ) external;
    function isOpened(
        uint256 eggId
    ) external view returns (bool);
}

interface IApymon {
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface ICryptoPunk {
    function transferPunk(address to, uint punkIndex) external;
}

contract VRFRequestIDBase {
    function makeVRFInputSeed(
        bytes32 _keyHash,
        uint256 _userSeed,
        address _requester,
        uint256 _nonce
    ) internal pure returns (uint256) {
        return  uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
    }
    function makeRequestId(
        bytes32 _keyHash,
        uint256 _vRFInputSeed
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
    }
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
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

abstract contract VRFConsumerBase is VRFRequestIDBase {
    using SafeMath for uint256;
    
    function fulfillRandomness(
        bytes32 requestId,
        uint256 randomness
    ) internal virtual;

    function requestRandomness(
        bytes32 _keyHash,
        uint256 _fee,
        uint256 _seed
    ) internal returns (bytes32 requestId) {
        LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, _seed));
        uint256 vRFSeed  = makeVRFInputSeed(_keyHash, _seed, address(this), nonces[_keyHash]);
        nonces[_keyHash] = nonces[_keyHash].add(1);
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
    ) external {
        require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
        fulfillRandomness(requestId, randomness);
    }
}

contract RandomNumberConsumer is VRFConsumerBase {
    bytes32 internal keyHash;
    uint256 internal fee;
    
    bool private progress = false;
    uint256 private winner = 0;
    address private distributer;
    
    modifier onlyDistributer() {
        require(distributer == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    /**
     * Constructor inherits VRFConsumerBase
     * 
     * Network: Kovan
     * Chainlink VRF Coordinator address: 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
     * LINK token address:                0xa36085F69e2889c224210F603D836748e7dC0088
     * Key Hash: 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
     */
    constructor(address _distributer) 
        VRFConsumerBase(
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
            0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token
        )
    {
        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        fee = 2 * 10 ** 18; // 2 LINK
        distributer = _distributer;
    }
    
    /** 
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber(uint256 userProvidedSeed) public onlyDistributer returns (bytes32 requestId) {        
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        require(!progress, "now getting an random number.");
        winner = 0;
        progress = true;
        return requestRandomness(keyHash, fee, userProvidedSeed);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        requestId = 0;
        progress = false;
        winner = randomness;
    }

    function getWinner() external view onlyDistributer returns (uint256) {
        if(progress)
            return 0;
        return winner;
    }
}

contract Distribution is ERC165, IERC721Receiver, Context, Ownable {
    using SafeMath for uint256;
    using Address for address;

    RandomNumberConsumer public rnGenerator;
    
    ICryptoPunk public _cryptoPunk = ICryptoPunk(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB);
    IApymonPack public _apymonPack = IApymonPack(0x3dFCB488F6e96654e827Ab2aB10a463B9927d4f9);
    IApymonPack public _apymonPack721 = IApymonPack(0x74F9177825E3b0B7b242e0fEb03c38b3fF2dcB18);
    IApymon public _apymon = IApymon(0x9C008A22D71B6182029b694B0311486e4C0e53DB);
    address public wethAddr = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint256 public _randomCallCount = 0;
    uint256 public _prevRandomCallCount = 0;

    uint256 public _endIdForEthDistribution = 0;

    // mapping eggId->punkId
    mapping(uint256 => uint256) private _eggIdsOwnedPunk;

    event WithdrawERC20(address indexed owner, address indexed token, uint256 amount);
    event WithdrawERC721(address indexed owner, address indexed token, uint256 id);
    event WithdrawPunk(address indexed owner, uint256 id);
    
    constructor () {
        rnGenerator = new RandomNumberConsumer(address(this));
    }

    function getRandomNumber() external onlyOwner {
        rnGenerator.getRandomNumber(_randomCallCount);
        _randomCallCount = _randomCallCount + 1;
    }

    function distributeFirstCryptoPunk() external onlyOwner {
        require(_prevRandomCallCount != _randomCallCount, "Please generate random number.");
        require(rnGenerator.getWinner() != 0, "Please wait until random number generated.");

        _prevRandomCallCount = _randomCallCount;
        uint256 eggId = rnGenerator.getWinner().mod(6000); // distribute first cryptoPunk to 0~5999
        _eggIdsOwnedPunk[eggId] = 7207;
    }

    function distributeSecondCryptoPunk() external onlyOwner {
        require(_prevRandomCallCount != _randomCallCount, "Please generate random number.");
        require(rnGenerator.getWinner() != 0, "Please wait until random number generated.");

        _prevRandomCallCount = _randomCallCount;
        uint256 eggId = rnGenerator.getWinner().mod(400) + 6000; // distribute first cryptoPunk to 6000~6399
        _eggIdsOwnedPunk[eggId] = 7006;
    }

    function withdrawPunk(uint256 eggId) external {
        address eggOwner = _apymon.ownerOf(eggId);

        require(eggOwner == msg.sender, "Invalid egg owner");
        require(_apymonPack.isOpened(eggId), "Unopened egg");

        uint256 punkId = _eggIdsOwnedPunk[eggId];

        require(punkId > 0, "Invalid punk id");

        _cryptoPunk.transferPunk(msg.sender, punkId);
        _eggIdsOwnedPunk[eggId] = 0;
    }

    function checkPunk(uint256 eggId) external view returns(uint256 punkId) {
        address eggOwner = _apymon.ownerOf(eggId);

        require(eggOwner == msg.sender, "Invalid egg owner");
        require(_apymonPack.isOpened(eggId), "Unopened egg");

        punkId = _eggIdsOwnedPunk[eggId];

        require(punkId > 0, "Invalid punk id");
    }

    function distributeERC20Token(address token, uint256 amount) external onlyOwner returns (uint256 eggId) {
        require(token != address(0));
        require(amount > 0, "Invalide erc20 amount to deposit");
        require(_prevRandomCallCount != _randomCallCount, "Please generate random number.");
        require(rnGenerator.getWinner() != 0, 'Please wait until random number generated.');

        _prevRandomCallCount = _randomCallCount;
        eggId = rnGenerator.getWinner().mod(6400);
        
        address[] memory tokens = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        
        tokens[0] = token;
        amounts[0] = amount;
        
        IERC20(token).approve(address(_apymonPack), amount);
        _apymonPack.depositErc20IntoEgg(eggId, tokens, amounts);
    }

    function distributeERC721Token(address token, uint256 tokenId) external onlyOwner {
        require(token != address(0));
        require(_prevRandomCallCount != _randomCallCount, "Please generate random number.");
        require(rnGenerator.getWinner() != 0, 'Please wait until random number generated.');

        _prevRandomCallCount = _randomCallCount;

        uint256 eggId = rnGenerator.getWinner().mod(6400);
        uint256[] memory tokenIds = new uint256[](1);

        tokenIds[0] = tokenId;
        
        IERC721(token).approve(address(_apymonPack721), tokenId);
        _apymonPack721.depositErc721IntoEgg(eggId, token, tokenIds);        
    }

    function distributeApymonToken(uint256 tokenId) external onlyOwner {
        require(_prevRandomCallCount != _randomCallCount, "Please generate random number.");
        require(rnGenerator.getWinner() != 0, 'Please wait until random number generated.');

        _prevRandomCallCount = _randomCallCount;

        uint256 eggId = rnGenerator.getWinner().mod(6400);
        if(eggId == tokenId) {
            if(eggId >= 3200)
                eggId = eggId - 1;
            else
                eggId = eggId + 1;
        }
        
        uint256[] memory tokenIds = new uint256[](1);

        tokenIds[0] = tokenId;
        
        IERC721(address(_apymon)).approve(address(_apymonPack721), tokenId);
        _apymonPack721.depositErc721IntoEgg(eggId, address(_apymon), tokenIds);
    }

    function approveWethToPack() external {
        IERC20(wethAddr).approve(address(_apymonPack), 100 ether);
    }

    function distributeWeth(uint256 startId, uint256 endId) external onlyOwner {
        require((_endIdForEthDistribution == 0 && startId == 0) || (startId == _endIdForEthDistribution + 1), "startId is incorrect.");
        require(endId >= startId && endId <= 6399, "endId is incorrect.");

        _endIdForEthDistribution = endId;

        address[] memory tokens = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        
        tokens[0] = wethAddr;

        for (uint256 i = startId; i <= endId; i++) {
            if (i > 6395) { // 6396 ~ 6400
                amounts[0] = 0.2 ether;
            } else if (i > 6365) { // 6366 ~ 6395
                amounts[0] = 0.1 ether;
            } else if (i > 6300) { // 6301 ~ 6365
               amounts[0] = 0.064 ether;
            } else if (i > 6000) { // 6001 ~ 6300
                amounts[0] = 0.032 ether;
            } else if (i > 4000) { // 4001 ~ 6000
                amounts[0] = 0.016 ether;
            } else if (i > 500) { // 501 ~ 4000
                amounts[0] = 0.008 ether;
            } else {
                amounts[0] = 0.004 ether; // 1 ~ 500
            }

            IApymonPack(_apymonPack).depositErc20IntoEgg(i, tokens, amounts);
        }
    }

    function withdrawERC20ToOwner(address token) external onlyOwner {
        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(owner(), amount);
        emit WithdrawERC20(owner(), token, amount);
    }
    
    function withdrawERC721ToOwner(address token, uint256 id) external onlyOwner {
        IERC721(token).safeTransferFrom(address(this), owner(), id);
        emit WithdrawERC721(owner(), token, id);
    }

    function withdrawPunkToOwner(uint256 id) external onlyOwner {
        _cryptoPunk.transferPunk(owner(), id);
        emit WithdrawPunk(owner(), id);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}