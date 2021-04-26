// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "Ownable.sol";
import "ZeroCopySink.sol";
import "ZeroCopySource.sol";
import "Utils.sol";
import "Address.sol";
import "IERC721Metadata.sol";
import "IERC721Receiver.sol";
import "SafeMath.sol";
import "IEthCrossChainManager.sol";
import "IEthCrossChainManagerProxy.sol";

contract PolyNFTLockProxy is IERC721Receiver, Ownable {
    using SafeMath for uint;
    using Address for address;

    struct TxArgs {
        bytes toAssetHash;
        bytes toAddress;
        uint256 tokenId;
        bytes tokenURI;
    }

    address public managerProxyContract;
    mapping(uint64 => bytes) public proxyHashMap;
    mapping(address => mapping(uint64 => bytes)) public assetHashMap;
    mapping(address => bool) safeTransfer;

    event SetManagerProxyEvent(address manager);
    event BindProxyEvent(uint64 toChainId, bytes targetProxyHash);
    event BindAssetEvent(address fromAssetHash, uint64 toChainId, bytes targetProxyHash);
    event UnlockEvent(address toAssetHash, address toAddress, uint256 tokenId);
    event LockEvent(address fromAssetHash, address fromAddress, bytes toAssetHash, bytes toAddress, uint64 toChainId, uint256 tokenId);
    
    modifier onlyManagerContract() {
        IEthCrossChainManagerProxy ieccmp = IEthCrossChainManagerProxy(managerProxyContract);
        require(_msgSender() == ieccmp.getEthCrossChainManager(), "msgSender is not EthCrossChainManagerContract");
        _;
    }
    
    function setManagerProxy(address ethCCMProxyAddr) onlyOwner public {
        managerProxyContract = ethCCMProxyAddr;
        emit SetManagerProxyEvent(managerProxyContract);
    }
    
    function bindProxyHash(uint64 toChainId, bytes memory targetProxyHash) onlyOwner public returns (bool) {
        proxyHashMap[toChainId] = targetProxyHash;
        emit BindProxyEvent(toChainId, targetProxyHash);
        return true;
    }
    
    function bindAssetHash(address fromAssetHash, uint64 toChainId, bytes memory toAssetHash) onlyOwner public returns (bool) {
        assetHashMap[fromAssetHash][toChainId] = toAssetHash;
        emit BindAssetEvent(fromAssetHash, toChainId, toAssetHash);
        return true;
    }
    
    // /* @notice                  This function is meant to be invoked by the ETH crosschain management contract,
    // *                           then mint a certin amount of tokens to the designated address since a certain amount 
    // *                           was burnt from the source chain invoker.
    // *  @param argsBs            The argument bytes recevied by the ethereum lock proxy contract, need to be deserialized.
    // *                           based on the way of serialization in the source chain proxy contract.
    // *  @param fromContractAddr  The source chain contract address
    // *  @param fromChainId       The source chain id
    // */
    function unlock(bytes memory argsBs, bytes memory fromContractAddr, uint64 fromChainId) public onlyManagerContract returns (bool) {
        TxArgs memory args = _deserializeTxArgs(argsBs);

        require(fromContractAddr.length != 0, "from proxy contract address cannot be empty");
        require(Utils.equalStorage(proxyHashMap[fromChainId], fromContractAddr), "From Proxy contract address error!");
        
        require(args.toAssetHash.length != 0, "toAssetHash cannot be empty");
        address toAssetHash = Utils.bytesToAddress(args.toAssetHash);

        require(args.toAddress.length != 0, "toAddress cannot be empty");
        address toAddress = Utils.bytesToAddress(args.toAddress);
        
        bool success;
        bytes memory res;
        address owner;
        bytes memory raw = abi.encodeWithSignature("ownerOf(uint256)", args.tokenId);
        (success, res) = toAssetHash.call(raw);
        if (success) {
            owner = abi.decode(res, (address));
            require(owner == address(this) || owner == address(0), "your token ID is not hold by lockproxy.");
            if (owner == address(this)) {
                raw = abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", address(this), toAddress, args.tokenId);
                (success, ) = toAssetHash.call(raw);
                require(success, "failed to call safeTransferFrom");
            }
        }
        if (!success || owner == address(0)) {
            raw = abi.encodeWithSignature("mintWithURI(address,uint256,string)", toAddress, args.tokenId, string(args.tokenURI));
            (success, ) = toAssetHash.call(raw);
            require(success, "failed to call mintWithURI to mint a new mapping NFT");
        }
        
        emit UnlockEvent(toAssetHash, toAddress, args.tokenId);
        return true;
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) public override returns (bytes4) {
        address fromAssetHash = _msgSender();
        require(data.length > 0, "length of toAddress can't be zero. ");
        require(fromAssetHash.isContract(), "caller must be a contract. ");
            
        bytes memory toAddress;
        uint64 toChainId;
        bytes memory toAssetHash;
        {
            (toAddress, toChainId) = _deserializeCallData(data);
            toAssetHash = assetHashMap[fromAssetHash][toChainId];
            require(toAssetHash.length != 0, "empty illegal toAssetHash");
    
            IERC721Metadata nft = IERC721Metadata(fromAssetHash);
            require(nft.ownerOf(tokenId) == address(this), "wrong owner for this token ID");
    
            string memory uri = nft.tokenURI(tokenId);
            TxArgs memory txArgs = TxArgs({
                toAssetHash: toAssetHash,
                toAddress: toAddress,
                tokenId: tokenId,
                tokenURI: bytes(uri)
            });
            bytes memory txData = _serializeTxArgs(txArgs);
            IEthCrossChainManager eccm = IEthCrossChainManager(IEthCrossChainManagerProxy(managerProxyContract).getEthCrossChainManager());
            
            bytes memory toProxyHash = proxyHashMap[toChainId];
            require(toProxyHash.length != 0, "empty illegal toProxyHash");
            require(eccm.crossChain(toChainId, toProxyHash, "unlock", txData), "EthCrossChainManager crossChain executed error!");
        }
        {
            emit LockEvent(fromAssetHash, from, toAssetHash, toAddress, toChainId, tokenId);
        }

        return this.onERC721Received.selector;
    }
    
    function _serializeTxArgs(TxArgs memory args) internal pure returns (bytes memory) {
        bytes memory buff;
        buff = abi.encodePacked(
            ZeroCopySink.WriteVarBytes(args.toAssetHash),
            ZeroCopySink.WriteVarBytes(args.toAddress),
            ZeroCopySink.WriteUint256(args.tokenId),
            ZeroCopySink.WriteVarBytes(args.tokenURI)
            );
        return buff;
    }

    function _deserializeTxArgs(bytes memory valueBs) internal pure returns (TxArgs memory) {
        TxArgs memory args;
        uint256 off = 0;
        (args.toAssetHash, off) = ZeroCopySource.NextVarBytes(valueBs, off);
        (args.toAddress, off) = ZeroCopySource.NextVarBytes(valueBs, off);
        (args.tokenId, off) = ZeroCopySource.NextUint256(valueBs, off);
        (args.tokenURI, off) = ZeroCopySource.NextVarBytes(valueBs, off);
        return args;
    }
    
    function _deserializeCallData(bytes memory valueBs) internal pure returns (bytes memory, uint64) {
        bytes memory toAddress;
        uint64 chainId;
        uint256 off = 0;
        (toAddress, off) = ZeroCopySource.NextVarBytes(valueBs, off);
        (chainId, off) = ZeroCopySource.NextUint64(valueBs, off);
        return (toAddress, chainId);
    }
}