/**
 *Submitted for verification at Etherscan.io on 2021-06-01
*/

// ┏━━━┓━┏┓━┏┓━━┏━━━┓━━┏━━━┓━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━┏┓━━━━━┏━━━┓━━━━━━━━━┏┓━━━━━━━━━━━━━━┏┓━
// ┃┏━━┛┏┛┗┓┃┃━━┃┏━┓┃━━┃┏━┓┃━━━━┗┓┏┓┃━━━━━━━━━━━━━━━━━━┏┛┗┓━━━━┃┏━┓┃━━━━━━━━┏┛┗┓━━━━━━━━━━━━┏┛┗┓
// ┃┗━━┓┗┓┏┛┃┗━┓┗┛┏┛┃━━┃┃━┃┃━━━━━┃┃┃┃┏━━┓┏━━┓┏━━┓┏━━┓┏┓┗┓┏┛━━━━┃┃━┗┛┏━━┓┏━┓━┗┓┏┛┏━┓┏━━┓━┏━━┓┗┓┏┛
// ┃┏━━┛━┃┃━┃┏┓┃┏━┛┏┛━━┃┃━┃┃━━━━━┃┃┃┃┃┏┓┃┃┏┓┃┃┏┓┃┃━━┫┣┫━┃┃━━━━━┃┃━┏┓┃┏┓┃┃┏┓┓━┃┃━┃┏┛┗━┓┃━┃┏━┛━┃┃━
// ┃┗━━┓━┃┗┓┃┃┃┃┃┃┗━┓┏┓┃┗━┛┃━━━━┏┛┗┛┃┃┃━┫┃┗┛┃┃┗┛┃┣━━┃┃┃━┃┗┓━━━━┃┗━┛┃┃┗┛┃┃┃┃┃━┃┗┓┃┃━┃┗┛┗┓┃┗━┓━┃┗┓
// ┗━━━┛━┗━┛┗┛┗┛┗━━━┛┗┛┗━━━┛━━━━┗━━━┛┗━━┛┃┏━┛┗━━┛┗━━┛┗┛━┗━┛━━━━┗━━━┛┗━━┛┗┛┗┛━┗━┛┗┛━┗━━━┛┗━━┛━┗━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┃┃━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┗┛━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.6.11;

contract Owned{
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface ERC20{
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) ;
}

interface IUniswapRouterV2{
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

interface DepositContract{
    function deposit(bytes calldata pubkey,bytes calldata withdrawal_credentials,bytes calldata signature,bytes32 deposit_data_root) external payable;
}


contract Renew is Owned{
    uint public price=600000000;
    bool public isSend=false;
    uint public fee=90000000;
    address public uniswapAddress=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public WETHAddress=0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    address public USDAddress=0xda5C6931Cc4e44fDd22C6Aa86b4f1fDA7e20eC04;
    
    uint constant DEPOSIT_CONTRACT_TREE_DEPTH = 32;
    // NOTE: this also ensures `deposit_count` will fit into 64-bits
    uint constant MAX_DEPOSIT_COUNT = 2**DEPOSIT_CONTRACT_TREE_DEPTH - 1;
    uint256 deposit_count;
    bytes32[DEPOSIT_CONTRACT_TREE_DEPTH] branch;
    
    event renewFund(address user,uint period, uint amount);
    event depositLog(address user, bytes pubkey, uint amount);
    
    constructor () public {}
    
    function ERC20Renew(address from, ERC20 addr, uint amount, uint period) public returns (bool success) {
        require(amount == period * price);
        emit renewFund(msg.sender, period, amount);
        return addr.transferFrom(from, address(this), amount);
    }
    
    function receiveApproval(address from,uint amount, ERC20 addr, bytes calldata _extraData) external returns (bool success){
        require(amount % price == 0);
        uint period = amount/price;
        return ERC20Renew(from, addr, amount, period);
    }
    
    receive() external payable {
    }
    
    function generateMessageToSign(bytes memory pubkey, uint value) public view returns (bytes32) {
        bytes32 message = keccak256(abi.encodePacked(msg.sender, pubkey, value));
        return message;
    }
    
    function deposit(DepositContract addr, bytes calldata pubkey, bytes calldata withdrawal_credentials,bytes calldata signature,bytes32 deposit_data_root, uint _fee) external payable{
        require(_fee == msg.value - 1 ether, "fee is not match!");
        uint ethFee = getAmountsOut(fee*90/100, USDAddress, WETHAddress);
        require(_fee > ethFee, "fee is error!");

        if(isSend==true){
            addr.deposit{value: 32 ether}(pubkey, withdrawal_credentials, signature, deposit_data_root);
        }else{
            deposit(pubkey, withdrawal_credentials, signature, deposit_data_root);
        }
        emit depositLog(msg.sender, pubkey, msg.value);
    }
    
    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) internal {
        // Extended ABI length checks since dynamic types are used.
        require(pubkey.length == 48, "DepositContract: invalid pubkey length");
        require(withdrawal_credentials.length == 32, "DepositContract: invalid withdrawal_credentials length");
        require(signature.length == 96, "DepositContract: invalid signature length");

        // Check deposit amount
        require(msg.value >= 1 ether, "DepositContract: deposit value too low");
        require(msg.value % 1 gwei == 0, "DepositContract: deposit value not multiple of gwei");
        uint deposit_amount = msg.value / 1 gwei;
        require(deposit_amount <= type(uint64).max, "DepositContract: deposit value too high");

        // Emit `DepositEvent` log
        bytes memory amount = to_little_endian_64(uint64(deposit_amount));

        // Compute deposit data root (`DepositData` hash tree root)
        bytes32 pubkey_root = sha256(abi.encodePacked(pubkey, bytes16(0)));
        bytes32 signature_root = sha256(abi.encodePacked(
            sha256(abi.encodePacked(signature[:64])),
            sha256(abi.encodePacked(signature[64:], bytes32(0)))
        ));
        bytes32 node = sha256(abi.encodePacked(
            sha256(abi.encodePacked(pubkey_root, withdrawal_credentials)),
            sha256(abi.encodePacked(amount, bytes24(0), signature_root))
        ));

        // Verify computed and expected deposit data roots match
        require(node == deposit_data_root, "DepositContract: reconstructed DepositData does not match supplied deposit_data_root");

        // Avoid overflowing the Merkle tree (and prevent edge case in computing `branch`)
        require(deposit_count < MAX_DEPOSIT_COUNT, "DepositContract: merkle tree full");

        // Add deposit data root to Merkle tree (update a single `branch` node)
        deposit_count += 1;
        uint size = deposit_count;
        for (uint height = 0; height < DEPOSIT_CONTRACT_TREE_DEPTH; height++) {
            if ((size & 1) == 1) {
                branch[height] = node;
                return;
            }
            node = sha256(abi.encodePacked(branch[height], node));
            size /= 2;
        }
        // As the loop should always end prematurely with the `return` statement,
        // this code should be unreachable. We assert `false` just to be safe.
        assert(false); 
    }
    
    function to_little_endian_64(uint64 value) internal pure returns (bytes memory ret) {
        ret = new bytes(8);
        bytes8 bytesValue = bytes8(value);
        // Byteswapping during copying to bytes.
        ret[0] = bytesValue[7];
        ret[1] = bytesValue[6];
        ret[2] = bytesValue[5];
        ret[3] = bytesValue[4];
        ret[4] = bytesValue[3];
        ret[5] = bytesValue[2];
        ret[6] = bytesValue[1];
        ret[7] = bytesValue[0];
    }
    
    function getAmountsOut(uint _tokenNum, address _symbolAddress, address _returnSymbolAddress) public view returns (uint) {
        address[] memory addr = new address[](2);
        addr[0] = _symbolAddress;
        addr[1] = _returnSymbolAddress;
        uint[] memory amounts = IUniswapRouterV2(uniswapAddress).getAmountsOut(_tokenNum, addr);
        return amounts[1];
    }
    
    function setFeeConfigAddress(address _uniswapAddress,address _WETHAddress,address _USDAddress) public onlyOwner{
        uniswapAddress = _uniswapAddress;
        WETHAddress = _WETHAddress;
        USDAddress = _USDAddress;
    }
    function setFee(uint _fee) public onlyOwner{
        fee = _fee;
    }
    
    function setOpen(bool b) public onlyOwner{
        isSend = b;
    }
    
    function setPrice(uint _price) public onlyOwner{
        price = _price;
    }
    
    function withdrawBalance(address cfoAddr) external onlyOwner{
        uint256 balance = address(this).balance;
        address payable _cfoAddr = address(uint160(cfoAddr));
        _cfoAddr.transfer(balance);
    }
}