// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "Ownable.sol";
import "SafeERC20.sol";
import "SafeMath.sol";
import "Pausable.sol";
import "ZeroCopySink.sol";
import "ZeroCopySource.sol";
import "IERC721.sol";
import "IERC721Enumerable.sol";
import "IERC721Metadata.sol";
import "ReentrancyGuard.sol";
import "IPolyNFTLockProxy.sol";

contract PolyNFTWrapper is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    uint public chainId;
    address public feeCollector;
    address public lockProxy;
    
    struct CallArgs {
        bytes toAddress;
        uint64 toChainId;
    }

    event PolyWrapperLock(address indexed fromAsset, address indexed sender, uint64 toChainId, address toAddress, uint256 tokenId, address feeToken, uint256 fee, uint id);
    event PolyWrapperSpeedUp(address indexed feeToken, bytes indexed txHash, address indexed sender, uint256 efee);

    constructor(address _owner, uint _chainId) public {
        require(_chainId != 0, "!legal");
        transferOwnership(_owner);
        chainId = _chainId;
    }
    
    function setFeeCollector(address collector) external onlyOwner {
        require(collector != address(0), "emtpy address");
        feeCollector = collector;
    }

    function setLockProxy(address _lockProxy) external onlyOwner {
        require(_lockProxy != address(0));
        lockProxy = _lockProxy;
        require(IPolyNFTLockProxy(lockProxy).managerProxyContract() != address(0), "not lock proxy");
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function extractFee(address token) external {
        require(msg.sender == feeCollector, "!feeCollector");
        if (token == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20(token).safeTransfer(feeCollector, IERC20(token).balanceOf(address(this)));
        }
    }

    function lock(address fromAsset, uint64 toChainId, address toAddress, uint256 tokenId, address feeToken, uint256 fee, uint id) external payable nonReentrant whenNotPaused {    
        require(toChainId != chainId && toChainId != 0, "!toChainId");

        _pull(feeToken, fee);
        _push(fromAsset, toChainId, toAddress, tokenId);
        emit PolyWrapperLock(fromAsset, msg.sender, toChainId, toAddress, tokenId, feeToken, fee, id);
    }

    function speedUp(address feeToken, bytes memory txHash, uint256 fee) external payable nonReentrant whenNotPaused {
        _pull(feeToken, fee);
        emit PolyWrapperSpeedUp(feeToken, txHash, msg.sender, fee);
    }

    function _pull(address feeToken, uint256 fee) internal {
        if (feeToken == address(0)) {
            require(msg.value == fee, "insufficient ether");
        } else {
            IERC20(feeToken).safeTransferFrom(msg.sender, address(this), fee);
        }
    }

    function _push(address fromAsset, uint64 toChainId, address toAddress, uint256 tokenId) internal {
        CallArgs memory callArgs = CallArgs({
            toAddress: abi.encodePacked(toAddress),
            toChainId: toChainId
        });
        bytes memory callData = _serializeCallArgs(callArgs);
        IERC721(fromAsset).safeTransferFrom(msg.sender, lockProxy, tokenId, callData);
    }

    function _serializeCallArgs(CallArgs memory args) internal pure returns (bytes memory) {
        bytes memory buff;
        buff = abi.encodePacked(
            ZeroCopySink.WriteVarBytes(args.toAddress),
            ZeroCopySink.WriteUint64(args.toChainId)
            );
        return buff;
    }

    function _serializeProfile(bytes memory buff, uint tokenId, string memory url) internal pure returns (bytes memory) {
        buff = abi.encodePacked(
            buff,
            ZeroCopySink.WriteUint256(tokenId),
            ZeroCopySink.WriteVarBytes(bytes(url))
        );
        return buff;
    }

    function _calcEndIndex(uint start, uint length, uint total) internal pure returns (uint) {
        uint end = start + length - 1;
        if (end >= total) {
            end = total - 1;
        }
        return end;
    }
}