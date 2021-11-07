/**
 *Submitted for verification at Etherscan.io on 2021-11-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.9;

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

library MerkleProof {
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash == root;
    }
}

interface IMerkleDistributor {
    function owner() external view returns (address);
    function wallet() external view returns (address payable);
    function token() external view returns (address);
    function endOn() external view returns (uint256);
    function merkleRoot() external view returns (bytes32);
    function isClaimed(uint256 index) external view returns (bool);
    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external ;
    function changeOwner(address newOwner) external;
    function changeWallet(address payable newWallet) external;
    function setRoot(bytes32 merkleRoot_) external;
    function extension(uint256 endOn_) external;
    event EndSet(uint256 indexed oldEnd, uint256 indexed newEnd);
    event RootSet(bytes32 indexed oldRoot, bytes32 indexed newRoot);
    event WalletSet(address indexed oldWallet, address indexed newWallet);
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    event Claimed(uint256 index, address account, uint256 amount);
    event EndDrops(uint256 indexed block, uint256 indexed returned);
    event ScheduleResult(bool success, bytes data, uint selfDestructBlock);
}

contract AirDrop is IMerkleDistributor {
    uint256 public endOn;
    address public immutable override token;
    bytes32 public override merkleRoot;
    address public override owner;
    address payable public override wallet;
    mapping(uint256 => uint256) private claimedBitMap;
    
    constructor(uint256 endOn_, address token_, bytes32 merkleRoot_,address payable  wallet_) {
        require(endOn_>block.number,"Wrong END block number");
        token = token_;
        emit EndSet(endOn, endOn_);
        endOn = endOn_;
        merkleRoot = merkleRoot_;
        emit RootSet(bytes32(0), merkleRoot_);
        owner = msg.sender;
        emit OwnerSet(address(0), owner);
        wallet = wallet_;
        
        bytes4 sig = bytes4(keccak256("end()"));
        (bool success, bytes memory data) = address(this).call(abi.encodeWithSignature("scheduleCall(bytes4,uint256)", sig, endOn));
        emit ScheduleResult(success, data, endOn);
    }
    
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    modifier inTime(){
        require(block.number < endOn , "You'r late");
        _;
    }
    
    modifier outTime(){
        require(block.number > endOn);
        _;
    }
    
    function extension(uint256 endOn_) isOwner inTime() public override{
        emit EndSet(endOn,endOn_);
        endOn = endOn_;
    }
    
    function end() public outTime(){
        uint256 balance = IERC20(token).balanceOf(address(this));
        emit EndDrops(block.number, balance);
        if (balance > 0) {
            require(IERC20(token).transfer(wallet, balance));
        }
        selfdestruct(wallet);
    }
    
    function changeWallet(address payable newWallet) external isOwner inTime{
        emit WalletSet(wallet, newWallet);
        wallet = newWallet;
    }

    function changeOwner(address newOwner) isOwner inTime external override {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }
    
    function setRoot(bytes32 merkleRoot_) isOwner inTime external override {
        emit RootSet(merkleRoot,merkleRoot_);
        merkleRoot = merkleRoot_;
    }
    
    function isClaimed(uint256 index) inTime public view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) inTime external override {
        require(!isClaimed(index), 'MerkleDistributor: Drop already claimed.');
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof.');
        _setClaimed(index);
        require(IERC20(token).transfer(account, amount), 'MerkleDistributor: Transfer failed.');
        emit Claimed(index, account, amount);
    }
}