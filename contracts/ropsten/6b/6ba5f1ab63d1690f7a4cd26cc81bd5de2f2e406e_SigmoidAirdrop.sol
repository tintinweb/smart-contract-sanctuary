/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

pragma solidity ^0.6.2;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
     function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ISigmoidTokens {

    function isActive(bool _contract_is_active) external returns (bool);
    function setPhase(uint256 phase) external returns (bool);
    
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function maximumSupply() external view returns (uint256);
    function AirdropedSupply() external  view returns (uint256);
    function lockedBalance(address account) external view returns (uint256);
    function checkLockedBalance(address account, uint256 amount) external view returns (bool);
    
    function setGovernanceContract(address governance_address) external returns (bool);
    function setBankContract(address bank_address) external returns (bool);
    function setExchangeContract(address exchange_addres) external returns (bool);
    
    function setAirdropedSupply(uint256 total_airdroped_supply) external returns (bool);
    
    function mint(address _to, uint256 _amount) external returns (bool);
    function mintAllocation(address _to, uint256 _amount) external returns (bool);
    function mintAirdrop(address _to, uint256 _amount) external returns (bool);
    
    function bankTransfer(address _from, address _to, uint256 _amount) external returns (bool);
}

interface ISigmoidAirdrop{
    function merkleVerify(bytes32[] calldata proof, bytes32 root, bytes32 leaf) external pure returns (bool);
    
    function claimStatus(address _to) external view returns (bool);
    function time_now() external view returns (uint256);
    
    function claimAirdrop(bytes32[] calldata _proof, uint256 airdrop_index, address _to, uint256 _amount) external returns (bool);
    function setAirdrop(address token_address, bytes32 _merkleRoot, uint256 _total_airdrop) external  returns (bool);
    function startClaim()external returns (bool);
    
}

contract SigmoidAirdrop is ISigmoidAirdrop {
    
 /* @dev This contract is the Sigmoid airdrop contract. 
 **1. At the end of the event, dev will put the merkle root of airdrop list into this contract, using setAirdrop().
   2. After step 1, address in the list can withdraw their token, using claimAirdrop().
   3. No one can change the merkle root of airdrop list, once the claim is started.
   3. After the end of the claim of airdrop, no one can claim their unclaim reward.
   4. When token pair will be created on SWAP, the airdroped token will be unlocked progressively.
 */
    
    address public dev_address= msg.sender;
    address public Token_contract;

    // 1st July 1625097600
    uint256 public constant event_end = 162509760;
    
    bool public claim_started=false;
    bool public merkleRoot_set=false;
    bytes32 public merkleRoot;//airdrop_list_mercleRoof
    mapping (address=>bool) public withdrawClaimed;
  
    function merkleVerify(bytes32[] memory proof, bytes32 root, bytes32 leaf) public override pure returns (bool) {
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
  
    //check if the airdrop is claimed
    function claimStatus(address _to) public override view returns (bool) {
         
         if(withdrawClaimed[_to]==true){
            return true;}
            
         return false;
    }
    
    function time_now() public override view returns (uint256) {
          return now;
       
    }
    
    // _amount is the amount of Airdrop no need to enter decimals _amount 1  = 1 SASH or SGM
    function claimAirdrop(bytes32[]  memory _proof, uint256 airdrop_index, address _to, uint256 _amount) public override returns (bool) {
        require(_amount > 0,'Sigmoid Airdrop: amount must >0.');
        require(claim_started == true,'Sigmoid Airdrop: claim not started yet.');

        bytes32 node = keccak256(abi.encodePacked(airdrop_index, _to, _amount));
        assert(merkleVerify(_proof,merkleRoot,node) == true);
        require(claimStatus(_to) == false, 'Sigmoid Airdrop: Airdrop already claimed.');

        ISigmoidTokens(Token_contract).mintAirdrop(_to, _amount * 1e18);
        withdrawClaimed[_to] = true;
        
        return true;
    }
    
    //At the end of the event, dev will put the merkle root of airdrop list into this contract, using setAirdrop().
    function setAirdrop(address token_address, bytes32 _merkleRoot, uint256 _total_airdrop) public override returns (bool) {
        require(msg.sender == dev_address,'Sigmoid Airdrop: Dev only.');
        require(now >= event_end, 'Sigmoidt Airdrop: too early.');
        require(claim_started == false, 'Sigmoid Airdrop: already started.');
        merkleRoot = _merkleRoot;
        merkleRoot_set = true;
        Token_contract = token_address;
        ISigmoidTokens(Token_contract).setAirdropedSupply(_total_airdrop);
        return true;
    }
    
    //start the airdrop claim
    function startClaim()public override returns (bool) {
        require(msg.sender == dev_address,'Sigmoid Airdrop: Dev only.');
        require(now>=event_end, 'Sigmoid Airdrop: too early.');
        require(claim_started == false, 'Sigmoid Airdrop: Claim already started.');
        require(merkleRoot_set == true, 'Sigmoid Airdrop: Merkle root invalid.');
        claim_started = true; 
        return true;
    }

}