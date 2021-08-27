//SourceUnit: NFT.sol

// NFT合约
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


interface IJustswapExchange {
    // 卖出trx, 换取token
    function trxToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256);
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

    // token的名字
    string public name = "NFT";
    // token的简称
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

    // 参数1: HNFT(GDCV)代币合约地址;
    // 参数2: 二级管理员地址;
    // 参数3: just swap; GDCV-TRX配对合约地址;
    // GDCV18-TRX: TLFdzUnUypKT3aCw3mNsn7T6m9nGLtSHBp;0x70cCc61a63C4824043d95b0e573EFb95bfecC331;
    // GDCV真-TRX: TBu8mRm3CD6EhUSnh7QxMJAoLM3KvwYxHf=0x152B0d70C0fEE3B471f02dA25Ea4B176BC33cdE7;
    constructor(address _hnftAddress, address _secondOwner, address _justSwapPair) public {
        hnftAddress = _hnftAddress;
        secondOwner = _secondOwner;
        justSwapPair = _justSwapPair;
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
        require(_from != address(0), "NFTERC721: From is zero address");
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

    // 转让token的封装2; 用于市场购买和首发购买
    function _transfer2(address _from, address _to, uint256 _tokenId) private {
        // 发送方不能是0地址
        require(_from != address(0), "NFTERC721: From is zero address");
        // 修改token数据
        tokenToOwner[_tokenId] = _to;
        delete tokenApproveToOwner[_tokenId];
        // 修改发送方数据
        balances[_from] = balances[_from].sub(1);
        // 修改接受方数据
        balances[_to] = balances[_to].add(1);
        // 触发交易事件
        // emit Transfer(_from, _to, _tokenId);
    }

    // 交易Token
    function transfer(address _to, uint256 _tokenId) external {
        // token必须是拥有者
        require(tokenToOwner[_tokenId] == msg.sender, "NFTERC721: You not owner");
        // 交易token
        _transfer(msg.sender, _to, _tokenId);
    }

    // 授权token给他人; 如果之前授权了, 将会覆盖之前的授权;
    function approve(address _to, uint256 _tokenId) external {
        // token必须是拥有者
        require(tokenToOwner[_tokenId] == msg.sender, "NFTERC721: You not owner");
        // 授权给地址
        tokenApproveToOwner[_tokenId] = _to;
        // 触发授权事件
        emit Approval(msg.sender, _to, _tokenId);
    }

    // 交易授权的Token
    function transferFrom(address _from, address _to, uint256 _tokenId) external {
        // 检查token拥有者是否是from
        require(tokenToOwner[_tokenId] == _from, "NFTERC721: From not owner");
        // 检查是否批准了
        require(tokenApproveToOwner[_tokenId] == msg.sender, "NFTERC721: Not approve");
        // 转让
        _transfer(_from, _to, _tokenId);
    }


    // hnft代币地址(GDCV地址)
    address public hnftAddress;
    address public justSwapPair;
    // 0地址, 用于销毁代币的; 考虑的有写合约不能转给0地址, 所有使用99地址
    address public constant zeroAddress = 0x0000000000000000000000000000000000000001;
    // 双重签名的messageHash
    mapping (bytes32 => bool) public signHash;
    // 全局的订单号, 确保不会被重复消耗到gas; orderId => 是否被他人先完成交易;
    mapping (uint256 => bool) public orderIdMapping;
    // 铸造事件; 只有开盲盒和合成会触发;
    event Mint(address owner, uint256 tokenId);
    // 合成事件;
    event Join(address owner, uint256 tokenId1, uint256 tokenId2, uint256 tokenId3, uint256 tokenId4, uint256 newTokenId);
    // 购买事件; nonce值作为唯一订单号;
    event Buy(address seller, address buyer, uint256 tokenId, uint256 value, uint256 nonce);
    // 购买首发事件; nonce值作为唯一订单号;
    event BuyNipo(address seller, address buyer, uint256 tokenId, uint256 value, uint256 nonce);
    // 领取收益事件
    event DrawRed(address owner, uint256 value, uint256 nonce);


    // 铸造token;
    // 参数1: 拥有者
    // 参数2: token id
    function _mint(address _owner, uint256 _tokenId) private {
        // 增加全局的数据
        allToken.push(_tokenId);
        allTokenNumber++;
        // 增加用户的数据
        balances[_owner]++;
        tokenToOwner[_tokenId] = _owner;
        // 触发铸造事件
        emit Mint(_owner, _tokenId);
    }

    // 铸造token; 用于购买首发市场
    // 参数1: 拥有者
    // 参数2: token id
    function _mint2(address _owner, uint256 _tokenId) private {
        // 增加全局的数据
        allToken.push(_tokenId);
        allTokenNumber++;
        // 增加用户的数据
        balances[_owner]++;
        tokenToOwner[_tokenId] = _owner;
        // 触发铸造事件
        // emit Mint(_owner, _tokenId);
    }

    // 合成; 直接销毁4个, 增加一个新的;
    // 参数1: 拥有者;
    // 参数2,3,4,5: 销毁的4个tokenId;
    // 参数6: 新的tokenId;
    function _join(
        address _owner,
        uint256 _tokenId1,
        uint256 _tokenId2,
        uint256 _tokenId3,
        uint256 _tokenId4,
        uint256 _newTokenId
    ) private {
        // 修改全局的数据
        allTokenNumber = allTokenNumber.sub(3);
        allToken.push(_newTokenId);
        // 修改用户的数据
        balances[_owner] = balances[_owner].sub(3);
        tokenToOwner[_newTokenId] = _owner;
        // 修改token的数据
        delete tokenToOwner[_tokenId1];
        delete tokenToOwner[_tokenId2];
        delete tokenToOwner[_tokenId3];
        delete tokenToOwner[_tokenId4];
        delete tokenApproveToOwner[_tokenId1];
        delete tokenApproveToOwner[_tokenId2];
        delete tokenApproveToOwner[_tokenId3];
        delete tokenApproveToOwner[_tokenId4];
        // 触发合成事件
        emit Join(_owner, _tokenId1, _tokenId2, _tokenId3, _tokenId4, _newTokenId);
    }

    // 开盲盒; 需要用户消耗HNFT(GDCV)和碎片(碎片在后台); 用户当前的二次签名没有使用就不能继续后面开盲盒, 开盲盒就得使用这个先;
    // 参数1: token id; 确保唯一不重复;
    // 参数2: 消耗的HNFT数量;
    // 参数3: nonce值;
    // 参数4: orderId;
    // 参数5: 二次签名的signature;
    function openBox(uint256 _tokenId, uint256 _hnftNumber, uint256 _nonce, uint256 _orderId, bytes calldata _signature) external {
        address _owner = msg.sender;
        // 二次签名的验证; 验证得到的地址是不是secondOwner, 并且数据没有被修改;
        // 验证的数据有: 拥有者地址, tokenId, 消耗的HNFT数量, 随机数, orderId;
        bytes32 hash = keccak256(abi.encodePacked(_owner, _tokenId, _hnftNumber, _nonce, _orderId));
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        address signer = recoverSigner(messageHash, _signature);
        require(signer == secondOwner, "NFT: Signer is not secondOwner");
        // 签名的messageHash必须是没有使用过的
        require(!signHash[messageHash], "NFT: MessageHash is used");
        // 该messageHash设置为已使用
        signHash[messageHash] = true;
        // 确保这个orderId没有被其它用户先使用
        require(!orderIdMapping[_orderId], "NFT: Order id already used");
        // orderId 被这个用户使用
        orderIdMapping[_orderId] = true;

        // token必须是不存在的
        require(tokenToOwner[_tokenId] == address(0), "NFT: Token is exist");
        // 开始转账ERC20, 销毁掉;
        TransferHelper.safeTransferFrom(hnftAddress, _owner, zeroAddress, _hnftNumber);
        // 给用户铸造一个新的token;
        _mint(_owner, _tokenId);
    }

    // 合成; 销毁四个tokenId, 给用户一个新的tokenId;
    // 参数1,2,3,4: token id进行销毁的;
    // 参数5: 新的tokenId, 确保唯一不重复;
    // 参数6: nonce值;
    // 参数7: 二次签名的signature;
    function joinBox(
        uint256 _tokenId1,
        uint256 _tokenId2,
        uint256 _tokenId3,
        uint256 _tokenId4,
        uint256 _newTokenId,
        uint256 _nonce,
        bytes calldata _signature
    ) external {
        address _owner = msg.sender;
        // 二次签名的验证; 验证得到的地址是不是secondOwner, 并且数据没有被修改;
        // 验证的数据有: 拥有者地址, 4个需要销毁的tokenId, 新的tokenId, 随机数;
        bytes32 hash = keccak256(abi.encodePacked(_owner, _tokenId1, _tokenId2, _tokenId3, _tokenId4, _newTokenId, _nonce));
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        address signer = recoverSigner(messageHash, _signature);
        require(signer == secondOwner, "NFT: Signer is not secondOwner");
        // 签名的messageHash必须是没有使用过的
        require(!signHash[messageHash], "NFT: MessageHash is used");
        // 该messageHash设置为已使用
        signHash[messageHash] = true;

        // 新token必须是不存在的
        require(tokenToOwner[_newTokenId] == address(0), "NFT: Token is exist");
        // 其它四个必须是它的才可以
        require(tokenToOwner[_tokenId1] == msg.sender, "NFT: Token not you");
        require(tokenToOwner[_tokenId2] == msg.sender, "NFT: Token not you");
        require(tokenToOwner[_tokenId3] == msg.sender, "NFT: Token not you");
        require(tokenToOwner[_tokenId4] == msg.sender, "NFT: Token not you");
        // 合成
        _join(_owner, _tokenId1, _tokenId2, _tokenId3, _tokenId4, _newTokenId);
    }

    // 市场购买交易;
    // 参数1: 卖方地址
    // 参数2: 卖方获得的波场数量
    // 参数3: 合约获得的波场数量(手续费用于给用户挖矿的)
    // 参数4: tokenId;
    // 参数5: nonce值;
    // 参数6: orderId;
    // 参数7: 二次签名的signature;
    function marketBuyToken(
        address _sellerAddress,
        uint256 _sellerTrxValue,
        uint256 _contractTrxValue,
        uint256 _tokenId,
        uint256 _nonce,
        uint256 _orderId,
        bytes calldata _signature
    ) external payable {
        address _buyAddress = msg.sender;
        // 二次签名的验证; 验证得到的地址是不是secondOwner, 并且数据没有被修改;
        // 验证的数据有: 卖方地址, 买方地址, 卖方获得的波场数量, 合约获得的波场数量, tokenId, 随机数, orderId;
        bytes32 hash = keccak256(abi.encodePacked(_sellerAddress, _buyAddress, _sellerTrxValue, _contractTrxValue, _tokenId, _nonce, _orderId));
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        address signer = recoverSigner(messageHash, _signature);
        require(signer == secondOwner, "NFT: Signer is not secondOwner");
        // 签名的messageHash必须是没有使用过的
        require(!signHash[messageHash], "NFT: MessageHash is used");
        // 该messageHash设置为已使用
        signHash[messageHash] = true;
        // 确保这个orderId没有被其它用户先使用
        require(!orderIdMapping[_orderId], "NFT: Order id already used");
        // orderId 被这个用户使用
        orderIdMapping[_orderId] = true;

        // 判断买方给的trx是否等于_sellerTrxValue+_contractTrxValue;
        require(msg.value == _sellerTrxValue.add(_contractTrxValue), "NFT: Trx value error");
        // tokenId必须是卖方的
        require(tokenToOwner[_tokenId] == _sellerAddress, "NFT: Token not seller");
        // 开始转账; 用户携带的value是直接全部自动给到合约的, 然后合约再转给卖方, 发送trx是合约;
        TransferHelper.safeTransferETH(_sellerAddress, _sellerTrxValue);
        // 转让token
        _transfer2(_sellerAddress, _buyAddress, _tokenId);
        // 触发买单事件
        emit Buy(_sellerAddress, _buyAddress, _tokenId, msg.value, _nonce);
    }

    // 首发购买交易
    // 参数1: 卖方地址
    // 参数2: 卖方获得的波场数量
    // 参数3: 合约获得的波场数量(手续费用于给用户挖矿的)
    // 参数4: 波场兑换成HNFT(GDCV)销毁的数量
    // 参数5: tokenId;
    // 参数6: nonce值;
    // 参数7: orderId;
    // 参数8: 二次签名的signature;
    function nipoBuyToken(
        address _sellerAddress,
        uint256 _sellerTrxValue,
        uint256 _contractTrxValue,
        uint256 _burnTrxValue,
        uint256 _tokenId,
        uint256 _nonce,
        uint256 _orderId,
        bytes calldata _signature
    ) external payable {
        address _buyAddress = msg.sender;
        // 二次签名的验证; 验证得到的地址是不是secondOwner, 并且数据没有被修改;
        // 验证的数据有: 卖方地址, 买方地址, 卖方获得的波场数量, 合约获得的波场数量, 兑换进行销毁的波场数量, tokenId, 随机数, orderId;
        bytes32 hash = keccak256(abi.encodePacked(_sellerAddress, _buyAddress, _sellerTrxValue, _contractTrxValue, _burnTrxValue, _tokenId, _nonce, _orderId));
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        address signer = recoverSigner(messageHash, _signature);
        require(signer == secondOwner, "NFT: Signer is not secondOwner");
        // 签名的messageHash必须是没有使用过的
        require(!signHash[messageHash], "NFT: MessageHash is used");
        // 该messageHash设置为已使用
        signHash[messageHash] = true;
        // 确保这个orderId没有被其它用户先使用
        require(!orderIdMapping[_orderId], "NFT: Order id already used");
        // orderId 被这个用户使用
        orderIdMapping[_orderId] = true;

        // 判断买方给的trx是否等于_sellerTrxValue+_contractTrxValue;
        require(msg.value == _sellerTrxValue.add(_contractTrxValue).add(_burnTrxValue), "NFT: Trx value error");
        // 开始转账; 用户携带的value是直接全部自动给到合约的, 然后合约再转给卖方, 发送trx是合约;
        TransferHelper.safeTransferETH(_sellerAddress, _sellerTrxValue);
        // 兑换进行销毁的trx;=====================================================================
        /*(uint256 _tokenNumber) = IJustswapExchange(justSwapPair).trxToTokenSwapInput.value(_burnTrxValue)(1, block.timestamp + 300000);
        TransferHelper.safeTransfer(hnftAddress, zeroAddress, _tokenNumber);*/

        // 新token必须是不存在的
        require(tokenToOwner[_tokenId] == address(0), "NFT: Token is exist");
        // 铸造token
        _mint2(_buyAddress, _tokenId);
        // 触发买首发事件
        emit BuyNipo(_sellerAddress, _buyAddress, _tokenId, msg.value, _nonce);
    }

    // 用户领取NFT挖矿的收益
    // 参数1: 领取TXR的数量
    // 参数6: nonce值;
    // 参数8: 二次签名的signature;
    function drawRed(uint256 _trxValue, uint256 _nonce, bytes calldata _signature) external {
        address _owner = msg.sender;
        // 二次签名的验证; 验证得到的地址是不是secondOwner, 并且数据没有被修改;
        // 验证的数据有: 领取者地址, 领取的数量, 随机数;
        bytes32 hash = keccak256(abi.encodePacked(_owner, _trxValue, _nonce));
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        address signer = recoverSigner(messageHash, _signature);
        require(signer == secondOwner, "NFT: Signer is not secondOwner");
        // 签名的messageHash必须是没有使用过的
        require(!signHash[messageHash], "NFT: MessageHash is used");
        // 该messageHash设置为已使用
        signHash[messageHash] = true;

        // 转给用户
        (address(uint160(_owner))).transfer(_trxValue);
        // 触发事件
        emit DrawRed(_owner, _trxValue, _nonce);
    }


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

    function() payable external {}

}