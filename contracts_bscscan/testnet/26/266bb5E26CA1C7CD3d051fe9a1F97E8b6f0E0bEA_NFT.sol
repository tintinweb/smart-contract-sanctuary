/**
 *Submitted for verification at BscScan.com on 2021-09-02
*/

// NFT合约, 代币和领取代币收益; BSC链;
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


// ERC20
contract ERC20 {
    function balanceOf(address _address) public view returns (uint256);
    function transfer(address _to, uint256 _value) public;
    function transferFrom(address _from, address _to, uint256 _value) public;
    function approve(address _spender, uint256 _value) public;
    function allowance(address _owner, address _spender) public view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract NFTToken is ERC20 {
    string public name = "NFT Token";
    string public symbol = "NFT";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    function _transfer(address _from, address _to, uint256 _value) internal {
        balances[_from] = SafeMath.sub(balances[_from], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        emit Transfer(_from, _to, _value);
    }

    function balanceOf(address _address) public view returns (uint256) {
        return balances[_address];
    }

    function transfer(address _to, uint256 _value) public {
        require(balances[msg.sender] >= _value, "NFTToken: Insufficient balance");
        _transfer(msg.sender, _to, _value);
    }

    function approve(address _spender, uint256 _amount) public {
        require(_spender != address(0), "Zero address error");
        require((allowed[msg.sender][_spender] == 0) || (_amount == 0), "NFTToken: Approve amount error");
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
    }

    function transferFrom(address _from, address _to, uint256 _value) public {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value, "NFTToken: Insufficient balance");
        allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
        _transfer(_from, _to, _value);
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
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
        require(msg.sender == owner, "NFTToken: You are not owner");
        _;
    }

    function updateOwner(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    modifier onlySecondOwner() {
        require(msg.sender == secondOwner, "NFTToken: You are not second owner");
        _;
    }

    function updateSecondOwner(address newSecondOwner) onlyOwner public {
        if (newSecondOwner != address(0)) {
            secondOwner = newSecondOwner;
        }
    }

}


// NFT
contract NFT is NFTToken, Ownable {
    using SafeMath for uint256;
    // USDT代币合约地址;
    address public usdtAddress;
    // 收USDT地址
    address public feeUsdtAddress;
    // 收取管理费的地址, 15%;
    address public feeManageAddress;
    // 双重签名的messageHash是否已经使用, 全局唯一;
    mapping (bytes32 => bool) public signHash;
    // 全局的nonce值是否已经使用, 全局唯一;
    mapping (uint256 => bool) public nonceMapping;


    // 参数1: USDT代币合约地址;
    // 参数2: 二级管理员地址;
    // 参数3: 收USDT地址;
    // 参数4: 收管理费地址
    constructor(address _usdtAddress, address _secondOwner, address _feeUsdtAddress, address _feeManageAddress) public {
        usdtAddress = _usdtAddress;
        secondOwner = _secondOwner;
        feeUsdtAddress = _feeUsdtAddress;
        feeManageAddress = _feeManageAddress;
    }

    // 铸造事件;
    event Mint(address owner, uint256 value);
    // 购买矿机事件;
    event BuyMill(address owner, uint256 usdtValue, uint256 nftValue, uint256 nonce);
    // 用户领取代币事件
    event UserRed(address owner, address tokenAddress, uint256 tokenValue, uint256 feeManageValue, uint256 nonce);

    // 铸造token;
    // 参数1: 拥有者
    // 参数2: _value
    function _mint(address _owner, uint256 _value) private {
        totalSupply = totalSupply.add(_value);
        balances[_owner] = balances[_owner].add(_value);
        // 触发铸造事件
        emit Mint(_owner, _value);
    }

    // 用户购买矿机; 需要用户转入USDT, 给用户铸造NFT代币;
    // 参数1: 转入USDT的数量
    // 参数2: 给用户铸造NFT代币的数量
    // 参数3: nonce值
    // 参数4: 二次签名的signature
   function buyMill(uint256 _usdtValue, uint256 _nftValue, uint256 _nonce, bytes calldata _signature) external {
       address _owner = msg.sender;
       // 验证的数据有: 用户地址, USDT的数量, NFT的数量, 随机数;
       bytes32 hash = keccak256(abi.encodePacked(_owner, _usdtValue, _nftValue, _nonce));
       bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
       address signer = recoverSigner(messageHash, _signature);
       require(signer == secondOwner, "NFTToken: Signer is not secondOwner");
       // 签名的messageHash必须是没有使用过的
       require(!signHash[messageHash], "NFTToken: MessageHash is used");
       // 该messageHash设置为已使用
       signHash[messageHash] = true;
       // nonce必须是没有使用的
       require(!nonceMapping[_nonce], "NFTToken: Nonce is used");
       // 设置为已使用
       nonceMapping[_nonce] = true;

       // 把用户转的USDT转给收币地址
       TransferHelper.safeTransferFrom(usdtAddress, _owner, feeUsdtAddress, _usdtValue);
       // 给用户铸造NFT Token
       _mint(_owner, _nftValue);
       emit BuyMill(_owner, _usdtValue, _nftValue, _nonce);
   }

    // 用户领取挖矿的收益
    // 参数1: 领取的币种地址
    // 参数2: 领取的数量
    // 参数3: 管理费的数量
    // 参数4: nonce值
    // 参数5: 二次签名的signature
    function userRed(address _tokenAddress, uint256 _tokenValue, uint256 _feeManageValue, uint256 _nonce, bytes calldata _signature) external {
        address _owner = msg.sender;
        // 验证的数据有: 用户地址, 币种地址, 领取的数量, 管理费的数量, 随机数;
        bytes32 hash = keccak256(abi.encodePacked(_owner, _tokenAddress, _tokenValue, _feeManageValue, _nonce));
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        address signer = recoverSigner(messageHash, _signature);
        require(signer == secondOwner, "NFTToken: Signer is not secondOwner");
        // 签名的messageHash必须是没有使用过的
        require(!signHash[messageHash], "NFTToken: MessageHash is used");
        // 该messageHash设置为已使用
        signHash[messageHash] = true;
        // nonce必须是没有使用的
        require(!nonceMapping[_nonce], "NFTToken: Nonce is used");
        // 设置为已使用
        nonceMapping[_nonce] = true;

        // 转给用户
        TransferHelper.safeTransfer(_tokenAddress, _owner, _tokenValue);
        // 转管理费
        TransferHelper.safeTransfer(_tokenAddress, feeManageAddress, _feeManageValue);
        // 触发事件
        emit UserRed(_owner, _tokenAddress, _tokenValue, _feeManageValue, _nonce);
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

    // 二级管理员设置某个nonce为已经使用, 备用;
    function setNonceMapping(uint256 _nonce) external onlySecondOwner {
        if(!nonceMapping[_nonce]) {
            // 该messageHash设置为已使用
            nonceMapping[_nonce] = true;
        }
    }

    // 设置收取USDT的地址
    function updateFeeUsdtAddress(address _feeUsdtAddress) external onlySecondOwner {
        if (_feeUsdtAddress != address(0)) {
            feeUsdtAddress = _feeUsdtAddress;
        }
    }

    // 设置收取管理费的地址
    function updateFeeManageAddress(address _feeManageAddress) external onlySecondOwner {
        if (_feeManageAddress != address(0)) {
            feeManageAddress = _feeManageAddress;
        }
    }


}