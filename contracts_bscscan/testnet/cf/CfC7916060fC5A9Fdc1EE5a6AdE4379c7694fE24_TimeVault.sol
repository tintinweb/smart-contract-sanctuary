/**
 *Submitted for verification at BscScan.com on 2021-11-19
*/

pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT
interface IERC20 {

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

contract TimeVault  {
    address payable public Owner;
    struct Vault {
        address creator;
        bytes32 securitywordHASH;
        string name;
        uint256 amount;
        uint256 id;
        uint256 duration;
        uint256 end;
        IERC20 token;
    }
    
    uint256 totalVaults;
    mapping(uint256 => Vault) public vaults;
    mapping(string => uint256) public nameToId;
    mapping(address => uint256) public balance;
    mapping(uint256 => address) internal idToCreator;
    event TransferReceived(address _from, uint _amount);
    event TransferSent(address _from, address _destAddr, uint _amount);
    //mapping (address => mapping (address => uint256)) private _allowances;
    event approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    

  constructor() {
    Owner = payable(msg.sender); 
  }

    
    
    function nameToVaultId(string memory name) public view returns(uint256 id){
        return nameToId[name];
    }
    
    function VaultIdToCreator(uint256 VaultId) public view returns(address creator) {
        return idToCreator[VaultId];
    }
    
    function VaultInfo(uint256 VaultId) public view returns(Vault memory) {
        return vaults[VaultId];
    }
    
    function createHash(string memory word) public pure returns(bytes32) {
        return (keccak256(abi.encodePacked((word))));
    }
    
    function createVault(IERC20 token, string memory name, bytes32 securitywordHASH, uint256 duration, uint256 amount) public returns(uint256 vaultId) {
        require(token.transferFrom(msg.sender, address(this), amount), "Token not Approved!");
        Vault storage vault = vaults[totalVaults];
        vault.duration = duration;
        vault.securitywordHASH = securitywordHASH;
        vault.end = block.timestamp + duration;
        vault.creator = msg.sender;
        vault.name = name;
        vault.amount = amount;
        vault.token = token;
        nameToId[name] = totalVaults;
        idToCreator[totalVaults] = msg.sender;
        totalVaults++;
        return (totalVaults - 1);
    }
    

    
    function withdraw(uint256 vaultId, string memory securityword) public {
        require(msg.sender == idToCreator[vaultId]);
        require(block.timestamp >= vaults[vaultId].end, 'too early');
        
        bytes32 word = vaults[vaultId].securitywordHASH;
        require(createHash(securityword) == word);
        uint256 amount = vaults[vaultId].amount;
        vaults[vaultId].amount = 0; 
        vaults[vaultId].token.transfer(msg.sender, amount);
        amount = 0;
    }
}