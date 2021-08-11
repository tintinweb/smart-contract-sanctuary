pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC1155.sol";


contract NFTFarming is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    struct UserInfo {
        uint256 amount;         // total staked amount
        uint256 lastUpdateAt;   // timestamp
        uint256 pointsDebt;     // points earned before latest deposit
    }
    
    struct NFTInfo {
        address contractAddress;
        uint256 id;             // NFT id
        uint256 remaining;      // NFTs remaining to farm
        uint256 price;          // points required to claim NFT
    }
    
    uint256 public pointsPerSecond;     // points generated per LP token per second staked
    IERC20 lpToken;                   
    
    NFTInfo[] public nftInfo;
    mapping(address => UserInfo) public userInfo;
    
    uint256 participationFee;
    uint256 withdrawalFee;
    address feeAddress;

    uint256 deduction;

    constructor(uint256 _pointsPerSecond, IERC20 _lpToken, uint256 _participationFee, uint256 _withdrawalFee, address _feeAddress, uint256 _deduction)  {
        pointsPerSecond = _pointsPerSecond;
        lpToken = _lpToken;
        participationFee = _participationFee;
        withdrawalFee = _withdrawalFee;
        feeAddress = _feeAddress;
        deduction = _deduction;
    }
    
    function addNFT(address contractAddress, uint256 id, uint256 total,uint256 price) external onlyOwner {
        IERC1155(contractAddress).safeTransferFrom(msg.sender, address(this), id, total, "");
        nftInfo.push(NFTInfo({ contractAddress: contractAddress, id: id, remaining: total, price: price }));
    }
    
    function deposit(uint256 _amount) external {
        lpToken.safeTransferFrom(msg.sender,address(this),_amount);
        UserInfo storage user = userInfo[msg.sender];
        
        if(user.amount != 0) {
            user.pointsDebt = pointsBalance(msg.sender);
        }

        if(participationFee > 0){
            uint256 fee = _amount.mul(participationFee).div(10000);
            lpToken.safeTransfer(feeAddress, fee);
            user.amount = user.amount.add(_amount).sub(fee);
        }else{
            user.amount = user.amount.add(_amount);
        }
        user.lastUpdateAt = block.timestamp;
    }
    
    function redeem(uint256 _nftIndex, uint256 _quantity) external {
        NFTInfo storage nft = nftInfo[_nftIndex];
        require(nft.remaining > 0, "All NFTs farmed");
        require(pointsBalance(msg.sender) >= nft.price.mul(_quantity), "Insufficient Points");
        UserInfo storage user = userInfo[msg.sender];
        
        user.pointsDebt = pointsBalance(msg.sender).sub(nft.price.mul(_quantity));
        user.lastUpdateAt = block.timestamp;
        
        IERC1155(nft.contractAddress).safeTransferFrom(address(this),msg.sender,nft.id,_quantity,"");
        
        nft.remaining = nft.remaining.sub(_quantity);
    }
    
    function withdraw(uint256 _amount) external {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "Insufficient staked");
        
        // update userInfo
        user.pointsDebt = pointsBalance(msg.sender);
        user.amount = user.amount.sub(_amount);
        user.lastUpdateAt = block.timestamp;
        
        if (withdrawalFee > 0){
            uint256 fee = _amount.mul(withdrawalFee).div(10000);
            lpToken.safeTransfer(feeAddress, fee);
            uint256 withdrawal = _amount.sub(fee);
            lpToken.safeTransfer(msg.sender,withdrawal);
        } else{
            lpToken.safeTransfer(msg.sender,_amount);
        }        
    }

    function pointsBalance(address userAddress) public view returns (uint256) {
        UserInfo memory user = userInfo[userAddress];
        return user.pointsDebt.add(_unDebitedPoints(user));
    }
    
    function _unDebitedPoints(UserInfo memory user) internal view returns (uint256) {
        return block.timestamp.sub(user.lastUpdateAt).mul(pointsPerSecond).mul(user.amount.div(deduction));
    }
    
    function nftCount() external view returns (uint256) {
        return nftInfo.length;
    }

    function updateJoiningFee(uint256 fee) external {
        require(fee <= 50, "fees should not be more than 0.5%");
        participationFee = fee;
    }

    function updateWithdrawalFee(uint256 fee) external {
        require(fee <= 500, "fees should not be more than 5%");
        withdrawalFee = fee;
    }

    function updateDeduction(uint256 _deduction) external {
        deduction = _deduction;
    }

    function updateEmission(uint256 emission) external {
        pointsPerSecond = emission;
    }
    
    function onERC1155Received(address operator,address from,uint256 id,uint256 value,bytes calldata data) external returns(bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }
}