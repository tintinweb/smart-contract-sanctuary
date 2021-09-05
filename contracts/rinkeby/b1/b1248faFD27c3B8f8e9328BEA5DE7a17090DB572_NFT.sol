/**
 *Submitted for verification at Etherscan.io on 2021-09-05
*/

// ERC721 NFT合约
pragma solidity ^0.5.16;


// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)
library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}


// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
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
        // (bool success,) = to.call{value:value}(new bytes(0));
        (bool success,) = to.call.value(value)(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// erc721
contract ERC721 {
    // Required methods
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // Optional
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    // function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    // function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}


// Owner
contract Ownable {
    // 一级管理者
    address public owner;
    // 二级管理者
    address public secondOwner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "NFT: You are not owner");
        _;
    }

    function updateOwner(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    modifier onlySecondOwner() {
        require(msg.sender == secondOwner, "NFT: You are not second owner");
        _;
    }

    function updateSecondOwner(address newSecondOwner) onlyOwner public {
        if (newSecondOwner != address(0)) {
            secondOwner = newSecondOwner;
        }
    }

}


// NFT卡牌
contract NFT is ERC721, Ownable {
    using SafeMath for uint256;

    string public name = "NFT Card";
    string public symbol = "NFT";
    // 所有的token; token id后台随机生成给到合约, 确保不重复就ok;
    uint256[] public allToken;
    // 总token数量;
    uint256 public allTokenNumber;
    // 用户拥有的token数量
    mapping (address => uint256) public balances;
    // token的拥有者
    mapping (uint256 => address) public tokenToOwner;
    // token的授权者
    mapping (uint256 => address) public tokenApproveToOwner;

    // NFTS代币合约地址
    address public nftsAddress;
    // 收nfts代币的地址
    address public feeNftsAddress;

    // 参数1: NFTS代币合约地址;
    // 参数2: 收nfts代币的地址;
    // 参数3: 二级管理员地址;
    constructor(address _nftsAddress, address _feeNftsAddress, address _secondOwner) public {
        nftsAddress = _nftsAddress;
        feeNftsAddress = _feeNftsAddress;
        secondOwner = _secondOwner;
    }

    // 获取Token的总量
    function totalSupply() public view returns (uint256) {
        return allTokenNumber;
    }

    // 查询用户的Token余额
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    // 查询TokenId的拥有者; 如果不存在将会返回0地址
    function ownerOf(uint256 _tokenId) public view returns (address) {
        return tokenToOwner[_tokenId];
    }

    // 转让token的封装
    function _transfer(address _from, address _to, uint256 _tokenId) private {
        // 发送方不能是0地址
        require(_from != address(0), "NFT: From is zero address");
        // 修改token数据
        tokenToOwner[_tokenId] = _to;
        delete tokenApproveToOwner[_tokenId];
        // 修改发送方数据
        balances[_from] = balances[_from].sub(1);
        // 修改接受方数据
        balances[_to] = balances[_to].add(1);
        // 触发交易事件
        emit Transfer(_from, _to, _tokenId);
    }

    // 交易Token
    function transfer(address _to, uint256 _tokenId) external {
        // token必须是拥有者
        require(tokenToOwner[_tokenId] == msg.sender, "NFT: You not owner");
        // 交易token
        _transfer(msg.sender, _to, _tokenId);
    }

    // 授权token给他人; 如果之前授权了, 将会覆盖之前的授权;
    function approve(address _to, uint256 _tokenId) external {
        // token必须是拥有者
        require(tokenToOwner[_tokenId] == msg.sender, "NFT: You not owner");
        // 授权给地址
        tokenApproveToOwner[_tokenId] = _to;
        // 触发授权事件
        emit Approval(msg.sender, _to, _tokenId);
    }

    // 交易授权的Token
    function transferFrom(address _from, address _to, uint256 _tokenId) external {
        // 检查token拥有者是否是from
        require(tokenToOwner[_tokenId] == _from, "NFT: From not owner");
        // 检查是否批准了
        require(tokenApproveToOwner[_tokenId] == msg.sender, "NFT: Not approve");
        // 转让
        _transfer(_from, _to, _tokenId);
    }


    // 双重签名的messageHash是否已经使用, 全局唯一;
    mapping (bytes32 => bool) public signHash;
    // 全局的nonce值是否已经使用, 全局唯一;
    mapping (uint256 => bool) public nonceMapping;
    // 铸造事件;
    event Mint(address owner, uint256 tokenId, uint256 nftsValue, uint256 nonce);

    // 购买事件; nonce值作为唯一订单号;
    event Buy(address seller, address buyer, uint256 tokenId, uint256 value, uint256 nonce);


    // 铸造token;
    // 参数1: 拥有者
    // 参数2: token id
    // 参数3: 消耗的NFTS数量
    // 参数4: nonce值
    function _mint(address _owner, uint256 _tokenId, uint256 nftsValue, uint256 nonce) private {
        // 增加全局的数据
        allToken.push(_tokenId);
        allTokenNumber++;
        // 增加用户的数据
        balances[_owner]++;
        tokenToOwner[_tokenId] = _owner;
        // 触发铸造事件
        emit Mint(_owner, _tokenId, nftsValue, nonce);
    }

    // 铸造tokenId
    // 参数1: token id; 确保唯一不重复;
    // 参数2: 消耗的NFTS数量;
    // 参数3: nonce值;
    // 参数4: orderId;
    // 参数5: 二次签名的signature;
    function mint(uint256 _tokenId, uint256 _nftsValue, uint256 _nonce, bytes calldata _signature) external {
        address _owner = msg.sender;
        // 验证的数据有: 拥有者地址, tokenId, 消耗的NFTS数量, 随机数;
        bytes32 hash = keccak256(abi.encodePacked(_owner, _tokenId, _nftsValue, _nonce));
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        address signer = recoverSigner(messageHash, _signature);
        require(signer == secondOwner, "Mining: Signer is not secondOwner");
        // 签名的messageHash必须是没有使用过的
        require(!signHash[messageHash], "Mining: MessageHash is used");
        // 该messageHash设置为已使用
        signHash[messageHash] = true;
        // nonce必须是没有使用的
        require(!nonceMapping[_nonce], "Mining: Nonce is used");
        // 设置为已使用
        nonceMapping[_nonce] = true;

        // token必须是不存在的
        require(tokenToOwner[_tokenId] == address(0), "NFT: Token is exist");
        // 开始转账ERC20;
        TransferHelper.safeTransferFrom(nftsAddress, _owner, feeNftsAddress, _nftsValue);
        // 给用户铸造一个新的token;
        _mint(_owner, _tokenId, _nftsValue, _nonce);
    }

    // 市场购买交易; 使用代币购买;=================================


    // 提取签名中的发起方地址
    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }

    // 分离签名信息的 v r s
    function splitSignature(bytes memory sig) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(sig.length == 65);
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        return (v, r, s);
    }

    // 二级管理员设置某个messageHash为已经使用, 备用;
    function setMessageHash(bytes32 _messageHash) external onlySecondOwner {
        if(!signHash[_messageHash]) {
            // 该messageHash设置为已使用
            signHash[_messageHash] = true;
        }
    }

    // 二级管理员设置某个nonce为已经使用, 备用;
    function setNonceMapping(uint256 _nonce) external onlySecondOwner {
        if(!nonceMapping[_nonce]) {
            // 该messageHash设置为已使用
            nonceMapping[_nonce] = true;
        }
    }

}