pragma solidity ^0.4.23;

/**
 * @title MerkleProof
 * @dev Merkle proof verification based on
 * https://github.com/ameensol/merkle-tree-solidity/blob/master/src/MerkleProof.sol
 */
library MerkleProof {
  /**
   * @dev Verifies a Merkle proof proving the existence of a leaf in a Merkle tree. Assumes that each pair of leaves
   * and each pair of pre-images are sorted.
   * @param _proof Merkle proof containing sibling hashes on the branch from the leaf to the root of the Merkle tree
   * @param _root Merkle root
   * @param _leaf Leaf of Merkle tree
   */
  function verifyProof(
    bytes32[] _proof,
    bytes32 _root,
    bytes32 _leaf
  )
    internal
    pure
    returns (bool)
  {
    bytes32 computedHash = _leaf;

    for (uint256 i = 0; i < _proof.length; i++) {
      bytes32 proofElement = _proof[i];

      if (computedHash < proofElement) {
        // Hash(current computed hash + current element of the proof)
        computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
      } else {
        // Hash(current element of the proof + current computed hash)
        computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
      }
    }

    // Check if the computed hash (root) is equal to the provided root
    return computedHash == _root;
  }
}



contract Controlled {

    mapping(address => bool) public controllers;

    /// @notice The address of the controller is the only address that can call
    ///  a function with this modifier
    modifier onlyController { 
        require(controllers[msg.sender]); 
        _; 
    }

    address public controller;

    constructor() internal { 
        controllers[msg.sender] = true; 
        controller = msg.sender;
    }

    /// @notice Changes the controller of the contract
    /// @param _newController The new controller of the contract
    function changeController(address _newController) public onlyController {
        controller = _newController;
    }

    function changeControllerAccess(address _controller, bool _access) public onlyController {
        controllers[_controller] = _access;
    }

}



// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20

interface ERC20Token {

    /**
     * @notice send `_value` token to `_to` from `msg.sender`
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transfer(address _to, uint256 _value) external returns (bool success);

    /**
     * @notice `msg.sender` approves `_spender` to spend `_value` tokens
     * @param _spender The address of the account able to transfer the tokens
     * @param _value The amount of tokens to be approved for transfer
     * @return Whether the approval was successful or not
     */
    function approve(address _spender, uint256 _value) external returns (bool success);

    /**
     * @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    /**
     * @param _owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address _owner) external view returns (uint256 balance);

    /**
     * @param _owner The address of the account owning tokens
     * @param _spender The address of the account able to transfer the tokens
     * @return Amount of remaining tokens allowed to spent
     */
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    /**
     * @notice return total supply of tokens
     */
    function totalSupply() external view returns (uint256 supply);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract SNTGiveaway is Controlled {
    
    mapping(address => bool) public sentToAddress;
    mapping(bytes5 => bool) public codeUsed;
    
    ERC20Token public SNT;
    
    uint public ethAmount;
    uint public sntAmount;
    bytes32 public root;
    
    event AddressFunded(address dest, bytes5 code, uint ethAmount, uint sntAmount);
    
    /// @notice Constructor
    /// @param _sntAddress address SNT contract address
    /// @param _ethAmount uint Amount of ETH in wei to send
    /// @param _sntAmount uint Amount of SNT in wei to send
    /// @param _root bytes32 Merkle tree root
    constructor(address _sntAddress, uint _ethAmount, uint _sntAmount, bytes32 _root) public {
        SNT = ERC20Token(_sntAddress);
        ethAmount = _ethAmount;
        sntAmount = _sntAmount;
        root = _root;
    }

    /// @notice Determine if a request to send SNT/ETH is valid based on merkle proof, and destination address
    /// @param _proof bytes32[] Merkle proof
    /// @param _code bytes5 Unhashed code
    /// @param _dest address Destination address
    function validRequest(bytes32[] _proof, bytes5 _code, address _dest) public view returns(bool) {
        return !sentToAddress[_dest] && !codeUsed[_code] && MerkleProof.verifyProof(_proof, root, keccak256(abi.encodePacked(_code)));
    }

    /// @notice Process request for SNT/ETH and send it to destination address
    /// @param _proof bytes32[] Merkle proof
    /// @param _code bytes5 Unhashed code
    /// @param _dest address Destination address
    function processRequest(bytes32[] _proof, bytes5 _code, address _dest) public onlyController {
        require(!sentToAddress[_dest] && !codeUsed[_code], "Funds already sent / Code already used");
        require(MerkleProof.verifyProof(_proof, root, keccak256(abi.encodePacked(_code))), "Invalid code");

        sentToAddress[_dest] = true;
        codeUsed[_code] = true;
        
        require(SNT.transfer(_dest, sntAmount), "Transfer did not work");
        _dest.transfer(ethAmount);
        
        emit AddressFunded(_dest, _code, ethAmount, sntAmount);
    }
    
    /// @notice Update configuration settings
    /// @param _ethAmount uint Amount of ETH in wei to send
    /// @param _sntAmount uint Amount of SNT in wei to send
    /// @param _root bytes32 Merkle tree root
    function updateSettings(uint _ethAmount, uint _sntAmount, bytes32 _root) public onlyController {
        ethAmount = _ethAmount;
        sntAmount = _sntAmount;
        root = _root;
        
    }

    function manualSend(address _dest, bytes5 _code) public onlyController {
        require(!sentToAddress[_dest] && !codeUsed[_code], "Funds already sent / Code already used");

        sentToAddress[_dest] = true;
        codeUsed[_code] = true;

        require(SNT.transfer(_dest, sntAmount), "Transfer did not work");
        _dest.transfer(ethAmount);
        
        emit AddressFunded(_dest, _code, ethAmount, sntAmount);
    }
    
    /// @notice Extract balance in ETH + SNT from the contract and destroy the contract
    function boom() public onlyController {
        uint sntBalance = SNT.balanceOf(address(this));
        require(SNT.transfer(msg.sender, sntBalance), "Transfer did not work");
        selfdestruct(msg.sender);
    }
    
    /// @notice Extract balance in ETH + SNT from the contract
    function retrieveFunds() public onlyController {
        uint sntBalance = SNT.balanceOf(address(this));
        require(SNT.transfer(msg.sender, sntBalance), "Transfer did not work");
        selfdestruct(msg.sender);
    }


    function() public payable {
          
    }

    
}