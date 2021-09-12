/**
 *Submitted for verification at BscScan.com on 2021-09-11
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
    // 管理者
    address public owner;

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
    // 全部token的授权者
    mapping (address => address) public tokenAllApproveToOwner;

    // Mining合约地址, 高权限合约;
    address public miningAddress;

    constructor() public {}

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

    // 授权全部tokenID给某个地址; 授权0地址就等于清除;
    function approveAll(address _to) external {
        tokenAllApproveToOwner[msg.sender] = _to;
    }

    // 交易授权的Token
    function transferFrom(address _from, address _to, uint256 _tokenId) external {
        // 检查token拥有者是否是from
        require(tokenToOwner[_tokenId] == _from, "NFT: From not owner");
        // 检查是否批准了这个代币, 或者授权了全部TokenID
        require(tokenApproveToOwner[_tokenId] == msg.sender || tokenAllApproveToOwner[_from] == msg.sender, "NFT: Not approve");
        // 转让
        _transfer(_from, _to, _tokenId);
    }

    // 铸造事件;
    event Mint(address owner, uint256 tokenId);

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

    // 铸造tokenId; 只能mining合约可以调用;
    // 参数1: 拥有者地址
    // 参数2: token id; 确保唯一不重复;
    function mint(address _owner, uint256 _tokenId) external {
        // 调用者必须是mining合约
        require(msg.sender == miningAddress, "NFT: Must is mining contract");
        // token必须是不存在的
        require(tokenToOwner[_tokenId] == address(0), "NFT: Token is exist");
        // 给用户铸造一个新的token;
        _mint(_owner, _tokenId);
    }

    // 设置铸造TokenId合约的地址; 设置0地址就是没有任何地址可以铸造TokenId
    function setMiningAddress(address _miningAddress) external onlyOwner {
        miningAddress = _miningAddress;
    }


}