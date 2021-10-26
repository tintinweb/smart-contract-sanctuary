/**
 *Submitted for verification at BscScan.com on 2021-10-25
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
    
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

contract CriptoManagerMembership
{
    address private CriptoManagerAddress;
    uint8 private MembershipID = 0;
    address BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    
    mapping(address => uint8) Members;
    mapping(uint256 => uint256) public Memberships;
    
    event NewMember(address member, uint8 membershipID);
    
    constructor()
    {
        CriptoManagerAddress = msg.sender;
    }
    
    function CreateMembership(uint256 amount) external
    {
        require(msg.sender == CriptoManagerAddress, 'This address cannot create memberships.');

        Memberships[MembershipID] = amount;
        MembershipID++;
    }
    
    function PayMembership(uint8 membershipID) external
    {
        require(msg.sender != address(0), 'Invalid user address');
        require(Members[msg.sender] < membershipID, 'User have a higher membership.');
        require(msg.sender != CriptoManagerAddress, 'Invalid address');
        require(msg.sender != address(this), 'Invalid address');
        
        IERC20 ercToken = IERC20(BUSD);
        
        if(ercToken.transferFrom(msg.sender, CriptoManagerAddress, Memberships[membershipID] * (10 ** ercToken.decimals())))
        {
            Members[msg.sender] = membershipID;
            emit NewMember(msg.sender, membershipID);   
        }
    }
    
    function GetMembership() external view returns (uint8)
    {
        require(msg.sender != address(0), 'Invalid address');
        
        if(msg.sender == CriptoManagerAddress)
        {
            return MembershipID;
        }
        
        return Members[msg.sender];
    }
    
    function SetMembership(address member, uint8 membershipID) external
    {
        require(msg.sender == CriptoManagerAddress, 'This address cannot set memberships');
        Members[member] = membershipID;
        emit NewMember(member, membershipID);
    }
}