/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}





            

pragma solidity ^0.8.0;


interface IDaoToken {

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function transferWithoutTax(address to, uint256 value) external returns (bool);
    function newAirdrop() external;
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}





            



pragma solidity ^0.8.0;


interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}





            



pragma solidity ^0.8.0;




abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor() {
        _transferOwnership(_msgSender());
    }

    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}





            



pragma solidity ^0.8.0;


library MerkleProof {
    
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}





pragma solidity ^0.8.0;






contract BugAirdrop is Ownable {

    bytes32 public merkleRoot;
    uint256 public claimed;
    address public bugDaoToken;
    uint32  public round = 0;
    mapping(uint32 => mapping(address => bool)) isClaimed;

    event MerkleRootChanged(bytes32 merkleRoot);

    constructor(bytes32 root){
        merkleRoot = root;
    }

    function claimTokens(uint256 amount, uint256 deadline, bytes32[] calldata Proof) external {
        require(block.timestamp <= deadline, "BugDao: Too late.");
        require(!isClaimed[round][msg.sender],"BugDao: you have claimed.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount, deadline));
        bool valid = MerkleProof.verify(Proof, merkleRoot, leaf);
        require(valid, "BugDao: Valid proof required.");
        isClaimed[round][msg.sender] = true;
        claimed += amount;
        IDaoToken(bugDaoToken).transferWithoutTax(msg.sender, amount);
    }
    
    function setBugToken(address _bugDaoToken) external onlyOwner {
        require(bugDaoToken == address(0), "only once");
        bugDaoToken = _bugDaoToken;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        round++;
        _setMerkleRoot(_merkleRoot);
    }

    function _setMerkleRoot(bytes32 _merkleRoot) internal{
        uint256 balance = IDaoToken(bugDaoToken).balanceOf(address(this));
        IDaoToken(bugDaoToken).transferWithoutTax(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, balance);
        IDaoToken(bugDaoToken).newAirdrop();
        merkleRoot = _merkleRoot;
        emit MerkleRootChanged(_merkleRoot);
    }
}