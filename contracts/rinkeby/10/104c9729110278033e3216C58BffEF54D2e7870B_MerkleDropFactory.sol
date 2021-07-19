/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

pragma solidity >=0.4.21 <0.6.0;

library SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a, "add");
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a, "sub");
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "mul");
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0, "div");
        c = a / b;
    }
}

pragma solidity >=0.4.21 <0.6.0;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

pragma solidity >=0.4.21 <0.6.0;

contract TokenBankInterface{
  function issue(address token_addr, address payable _to, uint _amount) public returns (bool success);
}

pragma solidity >=0.4.21 <0.6.0;

contract Ownable {
    address private _contract_owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = msg.sender;
        _contract_owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _contract_owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_contract_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_contract_owner, newOwner);
        _contract_owner = newOwner;
    }
}



contract MerkleDrop is Ownable{
  using SafeMath for uint;

  address public token;
  string public info;
  TokenBankInterface public token_bank;
  uint public total_dropped;
  bytes32 public merkle_root;

  bool public paused;
  mapping(address => bool) private claim_status;

  constructor(string memory _info, address _token_bank, address _token,
              bytes32 _merkle_root)  public{
    token = _token;
    info = _info;
    token_bank = TokenBankInterface(_token_bank);
    total_dropped = 0;
    merkle_root = _merkle_root;
    paused = false;
  }

  function pause() public onlyOwner{
    paused = true;
  }
  function unpause() public onlyOwner{
    paused = false;
  }

  event DropToken(address claimer, address to, uint amount);
  function claim(address payable to, uint amount, bytes32[] memory proof)  public returns(bool){
    require(paused == false, "already paused");
    require(claim_status[msg.sender] == false, "you claimed already");

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));

    bool ret = MerkleProof.verify(proof, merkle_root, leaf);
    require(ret, "invalid merkle proof");

    claim_status[msg.sender] = true;
    token_bank.issue(token, to, amount);
    total_dropped = total_dropped.safeAdd(amount);
    emit DropToken(msg.sender, to, amount);
    return true;
  }
}

contract MerkleDropFactory{

  event NewMerkleDrop(address addr);
  function createMerkleDrop(string memory _info, address _token_bank,
                            address _token, bytes32 _merkle_root) public returns(address){
    MerkleDrop mm = new MerkleDrop(_info, _token_bank, _token,
                                  _merkle_root);
    mm.transferOwnership(msg.sender);
    emit NewMerkleDrop(address(mm));
    return address(mm);
  }

}