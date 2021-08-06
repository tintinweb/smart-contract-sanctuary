pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";


contract NFTFarming is Ownable, IERC721Receiver {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    struct UserInfo {
        uint256 amount;         // total staked amount
        uint256 lastUpdateAt;   // timestamp
        uint256 pointsDebt;     // points earned before latest deposit
    }
    
    struct NFTInfo {
        address contractAddress;
        uint256 nftId;             // NFT id
        bool redeemed;
        uint256 price;          // points required to redeem NFT
    }
    
    uint256 public pointsPerSecond;     // points generated per LP token per second staked
    IERC20 lpToken;                    // token being staked
    
    NFTInfo[] public nftInfo;
    mapping(address => UserInfo) public userInfo;
    
    uint256 participationFee;
    uint256 withdrawalFee;
    address feeAddress;

    uint256 deduction;

    constructor(uint256 _pointsPerSecond, IERC20 _lpToken, uint256 _participationFee, uint256 _withdrawalFee, address _feeAddress, uint256 _deduction) {
        pointsPerSecond = _pointsPerSecond;
        lpToken = _lpToken;
        participationFee = _participationFee;
        withdrawalFee = _withdrawalFee;
        feeAddress = _feeAddress;
        deduction = _deduction;
    }
    
    function addNFT(address contractAddress, uint256 nftId, uint256 price) external onlyOwner {
        IERC721(contractAddress).safeTransferFrom(msg.sender, address(this), nftId);
        nftInfo.push(NFTInfo({contractAddress: contractAddress, nftId: nftId, redeemed:false, price: price}));
    }
    
    // Deposit Token
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
    
    // redeem NFT with points earned
    function redeem(uint256 _nftIndex) public {
        NFTInfo storage nft = nftInfo[_nftIndex];
        require(nft.redeemed == false, "Token is already redeemed");
        require(pointsBalance(msg.sender) >= nft.price, "Insufficient Points");
        UserInfo storage user = userInfo[msg.sender];
        
        // deduct points
        user.pointsDebt = pointsBalance(msg.sender).sub(nft.price);
        user.lastUpdateAt = block.timestamp;
        
        nft.redeemed = true;

        // transfer nft
        IERC721(nft.contractAddress).safeTransferFrom(address(this),msg.sender,nft.nftId);
    }
    
    function withdraw(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "Insufficient staked");
        
        // update userInfo
        user.pointsDebt = pointsBalance(msg.sender);
        user.amount = user.amount.sub(_amount);
        user.lastUpdateAt = block.timestamp;
        
        if (withdrawalFee > 0){
            uint256 fee = _amount.mul(withdrawalFee).div(10000);
            lpToken.safeTransfer(feeAddress, fee);
            uint256 withdrawal = user.amount.add(_amount).sub(fee);
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
    
    function nftCount() public view returns (uint256) {
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

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}