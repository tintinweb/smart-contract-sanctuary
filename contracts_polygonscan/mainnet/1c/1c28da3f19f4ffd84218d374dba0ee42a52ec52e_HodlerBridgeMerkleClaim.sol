// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./AccessControl.sol";
import {MerkleProof} from "./MerkleProof.sol";
import "./IERC20.sol";

/// @title Claim bridge for hodler rewards
/// @author Daniel Hazlewood - <twitter: @alphasoups>
contract HodlerBridgeMerkleClaim is AccessControl {
    using MerkleProof for bytes32[];

    /*
     *  Events
     */
    event StateUpdated(uint256 indexed blockNumber, bytes32 indexed rootHash);
    event Claimed(address indexed user, uint256 claimedAmount, uint256 totalBalance);
    event PausedStateUpdate(bool indexed pause);

    /*
     *  Storage
     */
    // Create a new role identifier for the minter role
    bytes32 public constant SUBMITTER_ROLE = keccak256("SUBMITTER_ROLE");
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    uint256 public lastBlockNumber = 0;
    bytes32 public merkleRoot = 0;
    bool public paused = false;
    IERC20 public token;
    
    mapping(address => uint256) public claimedAmount;


    /// @dev This contract doesn't accept ether
    fallback() external payable
    {
        revert("");
    }

    // Function to receive Ether.
    receive() external payable {
        revert("");
    }

    /*
     *  Modifiers
     */
    modifier onlyNotPaused() {
        require(paused == false, "ex10: Contract paused");
        _;
    }
    
    modifier onlyPaused() {
        require(paused, "ex10: Contract is not paused");
        _;
    }
    /* 
     * Public functions
     */
    constructor(address admin, address _token) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(PAUSER_ROLE, admin);
        token = IERC20(_token);
    }

    /// @dev Add a submitter role, which grants the ability to submit new merkle root hashes.
    function addSubmitter(address adr) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bytes32 role) {   
        _setupRole(SUBMITTER_ROLE, adr);
        return SUBMITTER_ROLE;
    }

    
    /// @dev Add a pauser role which allows one to pause the contract
    function addPauser(address adr) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bytes32 role) {   
        _setupRole(PAUSER_ROLE, adr);
        return PAUSER_ROLE;
    }


    /// @dev Add a withdrawer role which allows for withdrawing tokens form the contract
    function addWithdrawer(address adr) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bytes32 role) {   
        _setupRole(WITHDRAWER_ROLE, adr);
        return WITHDRAWER_ROLE;
    }

    /// @dev Paused state update
    function updatePausedState(bool _paused) external onlyRole(PAUSER_ROLE) {
        paused = _paused;
        emit PausedStateUpdate(_paused);
    }

    /// @dev Emergency withdraw function, can only be used when the contract is paused.
    function withdrawAllToken(address receiver, address tokenAddr) external onlyRole(WITHDRAWER_ROLE) onlyPaused {
        require(IERC20(tokenAddr).transfer(receiver, IERC20(tokenAddr).balanceOf(address(this))));
    }

    /// @dev Emergency withdraw function, can only be used when the contract is paused.
    function withdrawToken(address tokenAddr, address receiver, uint256 amount) external onlyRole(WITHDRAWER_ROLE) onlyPaused {
        require(IERC20(tokenAddr).transfer(receiver, amount));
    }

    /// @dev Creates a hash which should coincidence with a leaf node
    function getMerkleHash(address receiver, uint256 totalBalance) public pure returns(bytes32) {
        return keccak256(abi.encode(receiver, totalBalance));
    }

    /// @dev Updates the merkle root hash
    // note: this call can break if the root hash has changed when they made the call.
    function claim(uint256 totalBalance, bytes32[] calldata proof) external onlyNotPaused {
        // Check
        require(merkleRoot != 0, "No merkle proof has been set");
        require(proof.verify(merkleRoot, getMerkleHash(msg.sender, totalBalance)), "ex01: Out of date claim or verification failed");

        // Will be the amount of tokens they haven't claimed yet
        uint256 delta = totalBalance - claimedAmount[msg.sender];
        require(delta > 0, "No tokens claimable");

        // Effect
        // Token amount gets updated to the new total
        claimedAmount[msg.sender] = totalBalance;

        emit Claimed(msg.sender, delta, totalBalance);

        // Interact

        // Purposely left out making sure the transferred amount is not above total balance.
        // Firstly, this protects against some potential overflows if it exists in logics
        // secondly the user may not be aware they didn't receive all the tokens
        // thirdly I don't like designs that don't do what the user expects, and would rather fail a TX than let it pass, especially if other contracts are using this code.
        require(token.transfer(msg.sender, delta));
        
    }

    /// @dev Updates the merkle root hash
    function updateState(uint256 blockNumber, bytes32 roothash) external onlyRole(SUBMITTER_ROLE) {
        require(blockNumber > lastBlockNumber, "ex03: Block number is out of date");
        require(roothash != 0, "ex04: Root hash is invalid");
        
        lastBlockNumber = blockNumber;
        merkleRoot = roothash;
        emit StateUpdated(blockNumber, roothash);
    }
}