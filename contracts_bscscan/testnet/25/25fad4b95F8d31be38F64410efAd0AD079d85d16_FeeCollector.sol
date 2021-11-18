/**
 *Submitted for verification at BscScan.com on 2021-11-17
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

contract FeeCollector  {
    address payable public owner;
    struct Vault {
        address creator;
        string name;
        uint256 amount;
        uint256 id;
        uint256 duration;
        uint256 end;
    }
    
    uint256 totlaVaults;
    mapping(uint256 => Vault) public vaults;
    mapping(string => uint256) public nameToId;
    mapping(address => uint256) public balance;
    mapping(uint256 => address) internal idToCreator;
    event TransferReceived(address _from, uint _amount);
    event TransferSent(address _from, address _destAddr, uint _amount);
    

  constructor() {
    owner = payable(msg.sender); 
  }

    function depositVault(uint256 vaultId, IERC20 token, uint256 amount) external {
        require(msg.sender == idToCreator[vaultId]);
        token.transferFrom(msg.sender, address(this), amount);
        vaults[vaultId].amount += amount;
    }

    function ApproveVault(IERC20 token) external {
        token.approve(address(this), (1000000000000000 * 10 ** 18));
    }
  
    
    
    function createVault(string memory name, uint256 duration) public returns(uint256 vaultId) {
        Vault storage vault = vaults[totlaVaults];
        vault.duration = duration;
        vault.end = block.timestamp + duration;
        vault.creator = msg.sender;
        vault.name = name;
        nameToId[name] = totlaVaults;
        idToCreator[totlaVaults] = msg.sender;
        totlaVaults++;
        return (totlaVaults - 1);
    }
    function withdraw(uint256 vaultId, IERC20 token) public {
        require(msg.sender == idToCreator[vaultId]);
        require(block.timestamp >= vaults[vaultId].end, 'too early');
        token.transfer(msg.sender, vaults[vaultId].amount);
    }
}