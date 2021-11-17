// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
//import "@openzeppelin/contracts/access/Ownable.sol";
//import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "ERC721Enumerable.sol";
import "Ownable.sol";
import "VRFConsumerBase.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

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

contract RandomEDGE is ERC721Enumerable, Ownable, VRFConsumerBase, ReentrancyGuard {
    using Strings for uint256;

    // Constants
    // ------------------------------------------------------------------------
    uint256 public constant MAX_SUPPLY = 5000;
    uint256 public constant PRICE = 0.5 ether;
    uint256 internal constant WINNER_CUT = 70;
    string internal constant IPFS_UNKNOWN = "Qmbzf9grQq4rN1ZmZvrrjyWg3wC8Hx3BqUv16kpWsPpVLM"; // ***
    string internal constant IPFS_WINNER = "QmXyasrdptv9zzGU1iK6uNSth4RpRAxn4r8ga9GK4R68nY"; // ***
    string internal constant IPFS_LOSER = "QmZEDgZ8ujyu6gfvU1gHsTfZN2MnKUe57j5qXQ2ePBWKjA"; // ***
    string internal constant TOKEN_NAME = "RandomEDGE";
    string internal constant TOKEN_SYMBOL = "RE";

    // State
    // ------------------------------------------------------------------------
    bool public isFinished;
    bool public isRngRequested;
    address public winnerAddress;
    uint256 public contributed;
    uint256 public startTime;
    
    // Chainlink
    // ------------------------------------------------------------------------
    bytes32 internal constant KEY_HASH = 0xc251acd21ec4fb7f31bb8868288bfdbaeb4fbfec2df3735ddbd4f7dc8d60103c; // BSC
    uint256 internal constant VRF_FEE = 0.2 * 10 ** 18; // BSC
    address public constant VRF_COORDINATOR = 0x747973a5A2a4Ae1D3a8fDF5479f1514F65Db9C31; // BSC
    address public constant LINK_TOKEN = 0x404460C6A5EdE2D891e8297795264fDe62ADBB75; // BSC
    bytes32 public requestId;
    uint256 public randomResult;

    // Events
    // ------------------------------------------------------------------------
    event BaseTokenURIChanged(string baseTokenURI);
    event Received(address, uint256);

    // Constructor
    // ------------------------------------------------------------------------
    constructor() VRFConsumerBase(VRF_COORDINATOR, LINK_TOKEN) ERC721(TOKEN_NAME, TOKEN_SYMBOL) {
        startTime = block.timestamp + 7 days;
    }

    // Randomness/state advancing functions
    // ------------------------------------------------------------------------
    function requestResult() external onlyOwner {
        require(totalSupply() > 0, "NO_TICKETS");
        require(!isRngRequested, "ALREADY_REQUESTED");
        require(LINK.balanceOf(address(this)) >= VRF_FEE, "NEED_LINK");
        requestId = requestRandomness(KEY_HASH, VRF_FEE);
        isRngRequested = true;
    }

    function fulfillRandomness(bytes32 _requestId, uint256 randomness) internal override {
        require(requestId == _requestId, "INVALID_REQUEST");
        randomResult = (randomness % totalSupply()) + 1; // 1 to totalSupply() inclusive
    }
    
    function finalize() external onlyOwner {
        winnerAddress = ownerOf(randomResult);
        require(winnerAddress != address(0), "NO_WINNER");
        require(!isFinished, "PAID_OUT");
        isFinished = true;
        winnerAddress.call{value: winnerCut()}("");
    }
    
    function winnerCut() public view returns (uint256) {
        return contributed * WINNER_CUT / 100;
    }
    
    function isStarted() public view returns (bool) {
        return startTime < block.timestamp;
    }
    
    function setStartTime(uint256 _startTime) external onlyOwner {
        require(_startTime < startTime, "REDUCE_ONLY");
        startTime = _startTime;
    }

    // Mint functions
    // ------------------------------------------------------------------------
    function mint(uint256 quantity) external payable nonReentrant {
        require(isStarted(), "NOT_YET_STARTED");
        require(totalSupply() < MAX_SUPPLY, "SOLD_OUT");
        require(!isRngRequested, "LATE_CUTOFF");
        require(quantity > 0, "ZERO_QUANTITY");
        require(totalSupply() + quantity <= MAX_SUPPLY, "EXCEEDS_MAX_SUPPLY");
        require(msg.value >= PRICE * quantity, "INVALID_ETH_AMOUNT");

        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
        contributed = contributed + msg.value;
    }

    // URI Functions
    // ------------------------------------------------------------------------
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        string memory outStr = string(abi.encodePacked("data:application/json;utf8,", '{"name":"', TOKEN_NAME, ' #', tokenId.toString(), '","image": "ipfs://'));
        string memory attributes = string(abi.encodePacked('", "attributes":[{"trait_type": "Winner","value":"'));
        string memory endJson = '"}]}';
        if (randomResult != 0) {
            if (randomResult == tokenId) {
                outStr = string(abi.encodePacked(outStr, IPFS_WINNER, attributes, "Yes", endJson));
            } else {
                outStr = string(abi.encodePacked(outStr, IPFS_LOSER, attributes, "No", endJson));
            }
        } else {
            outStr = string(abi.encodePacked(outStr, IPFS_UNKNOWN, attributes, "???", endJson));
        }
        return outStr;
    }

    // Receive & Withdrawal functions
    // ------------------------------------------------------------------------
    receive() external payable {
        if (!isFinished) {
            contributed = contributed + msg.value;
        }
        emit Received(msg.sender, msg.value);
    }
    
    function teamWithdraw() external onlyOwner {
        require(isFinished);
        uint256 _teamCut = address(this).balance;
        uint256 _aAmount = _teamCut * 31 / 100;
        address(0xec90215396Fd13d3e847901580f4085CA097526c).call{value: _aAmount}("");
        address(0xa00810DEe91919FEb293B0af23b19a208488789e).call{value: _aAmount}("");
        address(0xa368B9d05E45D8D39347c25c52De7BEf4d12960c).call{value: _aAmount}("");
        address(0x36Ca2318F22AB822AEf100Ff003B0CaC62cB3813).call{value: address(this).balance}("");
    }
    
    function withdrawErc20(IERC20 token) external onlyOwner {
        require(token.transfer(msg.sender, token.balanceOf(address(this))), "Transfer failed");
    }
}