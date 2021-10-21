pragma solidity ^0.8.9;
// import "contracts/libraries/MerkleProof.sol";
// import "hardhat/console.sol";
 interface IERC20 {
     function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(
    address recipient, 
    uint256 amount) 
    external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}


library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
     bytes32 computedHash = leaf;
        bytes32 currentHash;
        for(uint i = 0;i<proof.length;i++){
            //sorting hash, so hash is same regardless of order
            currentHash = proof[i];
            if(computedHash< currentHash){
                computedHash = keccak256(abi.encodePacked(computedHash,currentHash));
            }
            else {
                computedHash = keccak256(abi.encodePacked(currentHash, computedHash));
            }
        }
            //check if root is equal to the computedhash
            return (computedHash == root);
   
    
    }
}

contract BridgeA {
    address private tokenA;
    address private gnosisAdd;
    mapping(bytes32=>bool) private rootArray;
    mapping(bytes32=>bool) private txClaim;
    event LockTokens(bytes32  leaf, bytes txDetails);
    event UnlockTokens(address receiver,uint amountUnlocked);
    constructor(address tokA, address _gnosisSafe) {
        tokenA = tokA;
        gnosisAdd = _gnosisSafe;     
    }
    modifier gnosisSafeOnly(address caller) {
        require(caller==gnosisAdd,"Only GnosisSmartContract Account can call this function");
        _;
    }
    //test  only
    function checkBlockHeader(bytes32 root) external view 
     returns(bool) {
        return rootArray[root]; 
    }
 
   function checkTx(bytes32 TX) external view 
     returns(bool) {
        return txClaim[TX]; 
    }
    //test only
    //submitBlockHeader
    function submitBlockHeader(bytes32 root) external gnosisSafeOnly(msg.sender) {
        require(rootArray[root]==false,"this root already exists");
        rootArray[root] = true;
    }
    function lockTokens(address targetChainAddress,uint amount) external {
        require(targetChainAddress!=address(0),"please provide a valid chain address");
        require(amount>=0,"please specify a amount greater than 0");
        require(IERC20(tokenA).transferFrom(msg.sender, address(this), amount)
        ,"Please approve the contract of the amount you wish to lock");
        //address,amount
        emit LockTokens(keccak256(abi.encode(targetChainAddress,amount)),abi.encode(targetChainAddress,amount));
    }
   
    //tokenFunctionality
     function unlockTokens(bytes32[] memory proof, bytes32 root, bytes memory leaf) external  {
            require(txClaim[keccak256(leaf)]==false,"tx already claimed");
            require(rootArray[root]==true,"this root is not a part our rootHeaders");
            //leaf is hash/encoding of receiving chain address and amount
             require(MerkleProof.verify(proof,root,keccak256(leaf)),"merkle proof verification failed");
             //tx is not claimed, root is in on chain root headers, use proof and leaf checks out, claim successful
             _unlockTokens(leaf);



    }
    function _unlockTokens(bytes memory arg) internal  {
        (address receiver, uint amountUnlocked) = abi.decode(arg,(address,uint));
        txClaim[keccak256(arg)] = true;        
        require(IERC20(tokenA).transfer(receiver,amountUnlocked),"transfer failed");
        emit UnlockTokens(receiver, amountUnlocked);
        
    }
  
}