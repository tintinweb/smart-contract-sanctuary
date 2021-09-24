/**
 *Submitted for verification at BscScan.com on 2021-09-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Ownable {
    address private _owner;
    address public pendingOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _setOwner(msg.sender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    modifier onlyPendingOwner() {
        require(pendingOwner == msg.sender, "Ownable: caller is not the pendingOwner");
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }
    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    function claimOwnership() public onlyPendingOwner {
        _setOwner(pendingOwner);
        pendingOwner = address(0);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

interface IERC721 {
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
    function mint(address to, uint256 tokenId) external;
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

contract NFTBonus is Ownable {
    using SafeMath for uint256;

    address public immutable tokenAddress;
    IERC20  public immutable tokenContract;
    IERC721 public immutable NFTContract;
    uint256 private constant ONE_DAY = 1 days;
    uint256 private constant dayRate = 98;
    uint256 private constant totalSupply = 5000;
    uint256 public startTime;
    uint256 public calculateTime;
    uint256 public calculateAsset; //Calculated recoverable asset
    uint256 public totalClaim; //Asset that have been claimed
    uint256 public perCalcAsset; //Calculated recoverable asset of each NFT

    mapping (uint256 => uint256) public NFTClaims;

    constructor(address _tokenAddress, IERC20 _tokenContract, IERC721 _NFTContract) {
        tokenAddress = _tokenAddress;
        tokenContract = _tokenContract;
        NFTContract = _NFTContract;
    }

    function transferETH(uint256 value) public onlyOwner() {
        TransferHelper.safeTransferETH(owner(), value);
    }

    function transferOtherAsset(address token, uint256 value) public onlyOwner() {
        require(tokenAddress != token, "Token error.");
        TransferHelper.safeTransfer(token, owner(), value);
    }

    function setStartTime(uint256 _startTime) public onlyOwner() {
        require(startTime == 0, "StartTime has been set");
        startTime = _startTime;
        calculateTime = _startTime;
    }

    function update() public {
        uint256 _days = block.timestamp.sub(calculateTime).div(ONE_DAY);
        require(_days >= 1 && startTime > 0, "No update time");

        uint256 _left = tokenContract.balanceOf(address(this)).sub(calculateAsset.sub(totalClaim));
        uint256 _calcLeft = _left;
        for (uint256 i = 0; i < _days; i++) {
            _calcLeft = _calcLeft.mul(dayRate).div(100);
        }
        if (_left > _calcLeft) {
            calculateAsset = _left.sub(_calcLeft).add(calculateAsset);
            perCalcAsset = calculateAsset.div(totalSupply);
        }
        calculateTime = _days.mul(ONE_DAY).add(calculateTime);
    }

    function claimByTokenID(uint256 tokenId) public {
        if (block.timestamp.sub(calculateTime) > ONE_DAY) update();

        address _NFT_Owner = NFTContract.ownerOf(tokenId);
        require(_NFT_Owner == msg.sender, "Only NFT owner can claim the bonus");
        //require(_NFT_Owner != address(0), "NFT owner query for nonexistent token");

        uint256 beforeClaim = NFTClaims[tokenId];
        require(beforeClaim < perCalcAsset, "Asset has been claimed");
        NFTClaims[tokenId] = perCalcAsset;
        uint256 transAmount = perCalcAsset.sub(beforeClaim);
        totalClaim = totalClaim.add(transAmount);
        TransferHelper.safeTransfer(tokenAddress, _NFT_Owner, transAmount);
    }

    function claim() public {
        uint256 _count = NFTContract.balanceOf(msg.sender);
        require(_count > 0, "No NFT");

        if (block.timestamp.sub(calculateTime) > ONE_DAY) update();
        uint256 claimAmount;
        for(uint256 i = 0; i < _count; i++) {
            uint256 tokenId = NFTContract.tokenOfOwnerByIndex(msg.sender, i);
            uint256 beforeClaim = NFTClaims[tokenId];
            if (beforeClaim < perCalcAsset) {
                NFTClaims[tokenId] = perCalcAsset;
                claimAmount = claimAmount.add(perCalcAsset).sub(beforeClaim);
            }
        }
        require(claimAmount > 0, "No asset can be claimed");
        totalClaim = totalClaim.add(claimAmount);
        TransferHelper.safeTransfer(tokenAddress, msg.sender, claimAmount);
    }

    function rewardOf(address owner) public view returns (uint256) {
        uint256 _count = NFTContract.balanceOf(owner);
        require(_count > 0, "No NFT");

        uint256 rewardAmount;
        uint256 _perCalcAsset = perCalcAsset;
        if (block.timestamp.sub(calculateTime) > ONE_DAY) _perCalcAsset = calcPerAsset();
        
        for(uint256 i = 0; i < _count; i++) {
            uint256 tokenId = NFTContract.tokenOfOwnerByIndex(owner, i);
            if (NFTClaims[tokenId] < _perCalcAsset) {
                rewardAmount = rewardAmount.add(_perCalcAsset).sub(NFTClaims[tokenId]);
            }
        }
        return rewardAmount;
    }

    function calcPerAsset() internal view returns (uint256) {
        uint256 _days = block.timestamp.sub(calculateTime).div(ONE_DAY);
        uint256 _left = tokenContract.balanceOf(address(this)).sub(calculateAsset.sub(totalClaim));
        uint256 _calcLeft = _left;
        for (uint256 i = 0; i < _days; i++) {
            _calcLeft = _calcLeft.mul(dayRate).div(100);
        }
        uint256 _calcAsset = _left.sub(_calcLeft).add(calculateAsset);
        return _calcAsset.div(totalSupply);
    }
}