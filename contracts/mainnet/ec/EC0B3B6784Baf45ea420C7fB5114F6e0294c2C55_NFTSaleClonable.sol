// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.7;
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

contract NFTSaleClonable {
    using Math for uint256;

    address public controller;
    address public hausAddress;
    address public stakingSwapContract;
    
    IERC1155 public nft;
    uint256  public price;
    uint256  public id;
    uint256  public start;
    uint256 public limitPerOrder;
    uint256 public stakingRewardPercentageBasisPoints;
    
    event Buy(address buyer, uint256 amount);
    
    function initialize(
        address _hausAddress,
        uint256 _startTime,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _priceWei,
        uint256 _limitPerOrder,
        uint256 _stakingRewardPercentageBasisPoints,
        address _stakingSwapContract,
        address _controllerAddress
    ) public {
        hausAddress = _hausAddress;
        start = _startTime;
        nft = IERC1155(_tokenAddress);
        id = _tokenId;
        price = _priceWei;
        limitPerOrder = _limitPerOrder;
        controller = _controllerAddress;
        stakingRewardPercentageBasisPoints = _stakingRewardPercentageBasisPoints;
        stakingSwapContract = _stakingSwapContract;
    }
    
    function buy(uint256 amount) public payable {
        require(msg.sender == tx.origin, "no contracts");
        require(block.timestamp >= start, "early");
        require(amount <= supply(), "ordered too many");
        require(amount <= limitPerOrder, "ordered too many");
        require(msg.value == price.mul(amount), "wrong amount");
        nft.safeTransferFrom(address(this), msg.sender, id, amount, new bytes(0x0));
        uint256 stakingReward = (address(this).balance * stakingRewardPercentageBasisPoints) / 10000;
        (bool stakingRewardSuccess, ) = stakingSwapContract.call{value: stakingReward}("");
        require(stakingRewardSuccess, "Staking reward transfer failed.");
        (bool successMultisig, ) = hausAddress.call{value: address(this).balance}("");
        require(successMultisig, "Multisig transfer failed.");
        emit Buy(msg.sender, amount);
    }
    
    function supply() public view returns(uint256) {
        return nft.balanceOf(address(this), id);
    }

    function setTokenAddress(address _tokenAddress) public onlyController {
        nft = IERC1155(_tokenAddress);
    }

    function setTokenId(uint256 _tokenId) public onlyController {
        id = _tokenId;
    }

    function pull() public onlyController {
        nft.safeTransferFrom(address(this), controller, id, nft.balanceOf(address(this), id), new bytes(0x0));
    }

    modifier onlyController {
      require(msg.sender == controller);
      _;
    }
    
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns(bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }
}