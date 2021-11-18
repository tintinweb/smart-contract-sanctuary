// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.7;

interface IRandomNumberConsumer {
  function getRandomNumber() external returns (bytes32 requestId);
  function readFulfilledRandomness(bytes32 requestId) external view returns (uint256);
  function setRandomnessRequesterApproval(address _requester, bool _approvalStatus) external;
}

interface IERC1155 {
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 value, bytes calldata _data) external;
    function balanceOf(address _owner, uint256 _id) external view returns(uint256);
}

interface IERC20 {
    function balanceOf(address _who) external returns (uint256);
}

library Math {
    function add(uint a, uint b) internal pure returns (uint c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint a, uint b) internal pure returns (uint c) {require((c = a - b) <= a, "BoringMath: Underflow");}
    function mul(uint a, uint b) internal pure returns (uint c) {require(a == 0 || (c = a * b)/b == a, "BoringMath: Mul Overflow");}
}

contract VRFNFTSaleClonable {
    using Math for uint256;

    address public controller;
    address public hausAddress;
    address public stakingSwapContract;
    address public vrfProvider;
    
    IERC1155 public nft;
    uint256 public price;
    uint256[] public ids;
    uint256 public start;
    uint256 public end;
    uint256 public limitPerOrder;
    uint256 public stakingRewardPercentageBasisPoints;

    uint256 public ticketId;
    mapping(address => uint256[]) public buyerToTicketIds;

    bool public isInitialized;
    bool public isRandomnessRequested;
    bytes32 public randomNumberRequestId;
    uint256 public vrfResult;
    uint256 public randomOffset;
    
    event Buy(address buyer, uint256 amount);
    event RequestedVRF(bool isRequested, bytes32 randomNumberRequestId);
    event CommittedVRF(bytes32 randomNumberRequestId, uint256 vrfResult, uint256 randomOffset);
    event ClaimedAssigned(address indexed claimant, uint256 quantity);
    
    function initialize(
        address _hausAddress,
        uint256 _startTime,
        uint256 _endTime,
        address _tokenAddress,
        uint256[] memory _tokenIds,
        uint256 _priceWei,
        uint256 _limitPerOrder,
        uint256 _stakingRewardPercentageBasisPoints,
        address _stakingSwapContract,
        address _vrfProvider,
        address _controllerAddress
    ) public {
        require(isInitialized == false, "Already initialized.");
        hausAddress = _hausAddress;
        start = _startTime;
        end = _endTime;
        nft = IERC1155(_tokenAddress);
        ids = _tokenIds;
        price = _priceWei;
        limitPerOrder = _limitPerOrder;
        controller = _controllerAddress;
        stakingRewardPercentageBasisPoints = _stakingRewardPercentageBasisPoints;
        stakingSwapContract = _stakingSwapContract;
        ticketId = 0;
        vrfProvider = _vrfProvider;
        isInitialized = true;
    }
    
    function buy(uint256 amount) public payable {
        require(msg.sender == tx.origin, "no contracts");
        require(block.timestamp >= start, "early");
        require(block.timestamp <= end, "sale has ended");
        require(amount > 0, "can't buy zero items");
        require((amount <= limitPerOrder) && ((amount + ticketId) <= ids.length), "ordered too many");
        require(msg.value == price.mul(amount), "wrong amount");
        uint256 stakingReward = (address(this).balance * stakingRewardPercentageBasisPoints) / 10000;
        (bool stakingRewardSuccess, ) = stakingSwapContract.call{value: stakingReward}("");
        require(stakingRewardSuccess, "Staking reward transfer failed.");
        (bool successMultisig, ) = hausAddress.call{value: address(this).balance}("");
        require(successMultisig, "Multisig transfer failed.");
        for(uint256 i = 0; i < amount; i++) {
          buyerToTicketIds[msg.sender].push(ticketId);
          ticketId++;
        }
        if(ticketId == (ids.length - 1)) {
          end = block.timestamp;
        }
        emit Buy(msg.sender, amount);
    }

    function isReservationPeriodOver() public view returns (bool) {
      return (block.timestamp > end) || (ticketId == (ids.length - 1));
    }

    function addressToTicketCount(address _address) public view returns (uint256) {
      return buyerToTicketIds[_address].length;
    }
    
    function supply() public view returns(uint256) {
        uint256 response = 0;
        for(uint256 i = 0; i < ids.length; i++) {
          response += nft.balanceOf(address(this), ids[i]);
        }
        return response;
    }

    function setTokenAddress(address _tokenAddress) public onlyController {
        nft = IERC1155(_tokenAddress);
    }

    function setTokenIds(uint256[] memory _tokenIds) public onlyController {
        ids = _tokenIds;
    }

    function pull() public onlyController {
        for(uint256 i = 0; i < ids.length; i++) {
          if(nft.balanceOf(address(this), ids[i]) > 0) {
            nft.safeTransferFrom(address(this), controller, ids[i], nft.balanceOf(address(this), ids[i]), new bytes(0x0));
          }
        }
    }

    function setEndTime(uint256 _newEndTime) public onlyController {
      require(block.timestamp <= _newEndTime, "VRF721NFT::setEndTime: new endTime must be in the future");
      end = _newEndTime;
    }

    modifier onlyController {
      require(msg.sender == controller);
      _;
    }

    function initiateRandomDistribution() external {
      require(block.timestamp > end, "VRF721NFT::initiateRandomDistribution: minting period has not ended");
      require(ticketId > 0, "VRF721NFT::initiateRandomDistribution: ticketId must be more than 0");
      require(isRandomnessRequested == false, "VRF721NFT::beginReveal: request for random number has already been initiated");
      IRandomNumberConsumer randomNumberConsumer = IRandomNumberConsumer(vrfProvider);
      randomNumberRequestId = randomNumberConsumer.getRandomNumber();
      isRandomnessRequested = true;
      emit RequestedVRF(isRandomnessRequested, randomNumberRequestId);
    }

    function commitRandomDistribution() external {
      require(isRandomnessRequested == true, "VRF721NFT::completeReveal: request for random number has not been initiated");
      IRandomNumberConsumer randomNumberConsumer = IRandomNumberConsumer(vrfProvider);
      uint256 result = randomNumberConsumer.readFulfilledRandomness(randomNumberRequestId);
      require(result > 0, "VRF721NFT::completeReveal: randomResult has not been provided to vrfProvider");
      vrfResult = result;
      randomOffset = result % ticketId;
      emit CommittedVRF(randomNumberRequestId, vrfResult, randomOffset);
    }

    function claimAssigned() external {
      require(vrfResult > 0, "Randomness has not been assigned");
      uint256[] memory buyerToTicketIdsMemory = buyerToTicketIds[msg.sender]; // Load into memory to save some gas
      uint256 buyerTicketCount = buyerToTicketIdsMemory.length;
      require(buyerTicketCount > 0, "buyerTicketCount is not a positive number");
      uint256[] memory idsMemory = ids; // Load into memory to save some gas
      for(uint256 i = 0; i < buyerTicketCount; i++) {
        if((buyerToTicketIdsMemory[i] + randomOffset) <= idsMemory.length - 1) {
          uint256 offsetIndex = (buyerToTicketIdsMemory[i] + randomOffset);
          nft.safeTransferFrom(address(this), msg.sender, ids[offsetIndex], nft.balanceOf(address(this), ids[offsetIndex]), new bytes(0x0));
        } else {
          uint256 offsetIndex = randomOffset - (idsMemory.length - buyerToTicketIdsMemory[i]);
          nft.safeTransferFrom(address(this), msg.sender, ids[offsetIndex], nft.balanceOf(address(this), ids[offsetIndex]), new bytes(0x0));
        }
      }
      emit ClaimedAssigned(msg.sender, buyerTicketCount);
    }
    
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns(bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }
}