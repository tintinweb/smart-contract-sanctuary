/**
 *Submitted for verification at BscScan.com on 2022-01-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

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
    function existed(uint256 tokenId) external view returns (bool);
    function identityLevel(uint256 tokenId) external view returns (uint256 tokenLevel);
}

contract Claim4JIDReward {
    using SafeMath for uint256;

    IERC721 public immutable fourJID;   //4JID NFT
    uint256 public totalReward;
    uint256 public claimedReward;
    mapping(uint256 => uint256) public rewards;

    constructor(IERC721 _fourJID) {
        fourJID = _fourJID;
    }

    fallback() external payable {}
    receive() external payable {}

    function updateReward() public {
        if (totalReward.sub(claimedReward) < address(this).balance) {
            totalReward = claimedReward.add(address(this).balance);
        }
    }

    function claimReward(uint256 _tokenID) public {
        updateReward();

        require(fourJID.ownerOf(_tokenID) == msg.sender, "Claim4JIDReward: no authority.");
        uint256 idLevel = fourJID.identityLevel(_tokenID);
        require(idLevel > 0, "Claim4JIDReward: nft level is too low.");
        uint256 currentReward = totalReward.div(800000).mul(10**idLevel);
        uint256 leftReward = currentReward.sub(rewards[_tokenID]);
        if (leftReward > 0) {
            rewards[_tokenID] = currentReward;
            claimedReward = claimedReward.add(leftReward);
            TransferHelper.safeTransferETH(msg.sender, leftReward);
        }
    }

    function pendingReward(uint256 _tokenID) public view returns (uint256) {
        uint256 idLevel = fourJID.identityLevel(_tokenID);
        require(idLevel > 0, "Claim4JIDReward: nft level is too low.");

        uint256 _totalReward = claimedReward.add(address(this).balance);
        uint256 currentReward = _totalReward.div(800000).mul(10**idLevel);
        uint256 leftReward = currentReward.sub(rewards[_tokenID]);
        return leftReward;
    }
}