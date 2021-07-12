/**
 *Submitted for verification at Etherscan.io on 2021-07-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/******************************************/
/*       IERC20 starts here               */
/******************************************/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

/******************************************/
/*       Context starts here              */
/******************************************/

// File: @openzeppelin/contracts/GSN/Context.sol

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/******************************************/
/*       Ownable starts here              */
/******************************************/

// File: @openzeppelin/contracts/access/Ownable.sol

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/******************************************/
/*       DinoAllocation starts here       */
/******************************************/

contract DinoAllocation is Ownable {

    IERC20 public DINO; 

    uint256 public startBlock;
    uint256 public endBlock;
    bool initialized;
    bool treasuryExecuted;
    address constant treasury = 0x15c3a1ea1fc90b7fc07B8C12fb275271170fB143;
    address constant liquidity = 0x06992C1E01206FBaaD17ECda434d3D0A736498a2;
    uint256 constant treasuryAllocation = 3640000*1e18;
    uint256 constant liquidityAllocation = 42250000*1e18;


    mapping (address => Allocation) public allocations;

    struct Allocation {
        uint256 sharePerBlock;
        uint256 lastWithdrawalBlock;
        bool team;
    }

    /**
     * @dev Populate allocations.
     */
    constructor()
    {
        // Team
        allocations[0x636981134A6c38295AF85521CfCBFEBe6c5995eC] = Allocation({
            sharePerBlock: 273972602739726000,
            lastWithdrawalBlock: block.number,
            team: true  
        });
        allocations[0x1b2a371135bfD32C5AeB58238E54D2b26f756D41] = Allocation({
            sharePerBlock: 410958904109589000,
            lastWithdrawalBlock: block.number,
            team: true  
        });
        allocations[0x4a3953B59132ed60999e9954738D1CD588F2BD74] = Allocation({
            sharePerBlock: 273972602739726000,
            lastWithdrawalBlock: block.number,
            team: true  
        });
        allocations[0x4D6945c269195Ab9ef821ed67baEeC7c16B5002E] = Allocation({
            sharePerBlock: 479452054794521000,
            lastWithdrawalBlock: block.number,
            team: true  
        });
        allocations[0x350661d34c58a8eb8ec7e3aD5bc809753B60FD59] = Allocation({
            sharePerBlock: 239726027397260000,
            lastWithdrawalBlock: block.number,
            team: true  
        });
        allocations[0x4a7fAA271539b039C72c15bC085802e19EA25432] = Allocation({
            sharePerBlock: 239726027397260000,
            lastWithdrawalBlock: block.number,
            team: true  
        });
        allocations[0xD534B942A243e6fc69C66d1ec3AbcD55991bE24C] = Allocation({
            sharePerBlock: 164383561643836000,
            lastWithdrawalBlock: block.number,
            team: true  
        });
        allocations[0x267A6E6d9e4cD70aA0382B02E9b5cDcE67807a93] = Allocation({
            sharePerBlock: 315068493150685000,
            lastWithdrawalBlock: block.number,
            team: true  
        });
        allocations[0x4B2EC9B3202c2de0923bf21A099121656c087ba5] = Allocation({
            sharePerBlock: 205479452054795000,
            lastWithdrawalBlock: block.number,
            team: true  
        });
        allocations[0x04FB55364a095a0566AFEb96cC73F0c400871ac5] = Allocation({
            sharePerBlock: 273972602739726000,
            lastWithdrawalBlock: block.number,
            team: true  
        });
        allocations[0x8d1D80296Bc224B50c31412A0C3C2534581D3c99] = Allocation({
            sharePerBlock: 295047418335090000,
            lastWithdrawalBlock: block.number,
            team: true  
        });
        allocations[0x3217ee17d78260EC39d2ece486C143bB0507cFD8] = Allocation({
            sharePerBlock: 326659641728135000,
            lastWithdrawalBlock: block.number,
            team: true  
        });
        allocations[0x4D5764BFBfFa5F09B7966D876Bfc4dF4E749991F] = Allocation({
            sharePerBlock: 337197049525817000,
            lastWithdrawalBlock: block.number,
            team: true  
        });
        allocations[0xF131aCEF5A608241467dA98f3f6961a37874176A] = Allocation({
            sharePerBlock: 41095890410958900,
            lastWithdrawalBlock: block.number,
            team: true  
        });
        allocations[0xF0190aacF9Cd574004D2bE21cb780c45d51A50a7] = Allocation({
            sharePerBlock: 41095890410958900,
            lastWithdrawalBlock: block.number,
            team: true  
        });
        allocations[0xb426CF07A9cFe0c0674D9B551Fd48144d2a18885] = Allocation({
            sharePerBlock: 27397260273972600,
            lastWithdrawalBlock: block.number,
            team: true  
        });

        // Investors
        allocations[0xFbA3E27cC635051Bb030Dcc7EAa0a224dB2dD5C7] = Allocation({
            sharePerBlock: 177569258166492000,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0x120e6B24f0E60d952db82E4a092fbA6806A7B45B] = Allocation({
            sharePerBlock: 177569258166492000,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0x57500Df016294f21B5366a35B1B6669689BDC69D] = Allocation({
            sharePerBlock: 177569258166492000,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0x1814b585Db8ACefAa4ebf96240Ed28528B8CC958] = Allocation({
            sharePerBlock: 177569258166492000,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0xf957Fa14eA72a9ECD7BDC06c5be89A5a34C7aa89] = Allocation({
            sharePerBlock: 41095890410958900,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0x96a5fec92E43E7E68502C75FE98abc9436BD1e40] = Allocation({
            sharePerBlock: 41095890410958900,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0x3974B53404800c7bd83d1FD0fDF014a5E394B300] = Allocation({
            sharePerBlock: 651263317175975000,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0x66E9cb06ab7CC033c6d40173384cee7D7d177359] = Allocation({
            sharePerBlock: 21917808219178100,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0x4Cb3E05e4eE4F55173792F1432A004AdE5e3E46a] = Allocation({
            sharePerBlock: 19178082191780800,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0xFa2C58416e564fc4C19f09747b7aADBCc94066a6] = Allocation({
            sharePerBlock: 10958904109589000,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0x08cC804300491D1A500520b6264ae7A5B52414A7] = Allocation({
            sharePerBlock: 76712328767123300,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0x8Ae4aA31C8D4cbBCdeF62fA2e301145bfd77F06B] = Allocation({
            sharePerBlock: 28006086406743900,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0x9080196182F77B89BB5B0EeE3Ddb48cFA716c4c3] = Allocation({
            sharePerBlock: 2191780821917810,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0x0ACAC28a6d03570896236a99847A92c2e7f9B6Bd] = Allocation({
            sharePerBlock: 35312025289778700,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0x58D95B6B20dEDCA1b066d8478fF6Df2f1F736714] = Allocation({
            sharePerBlock: 261796042149631000,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0x67df21B9a8e79352649E0A304767eC02571c8197] = Allocation({
            sharePerBlock: 176560122233930000,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0x9B5ea8C719e29A5bd0959FaF79C9E5c8206d0499] = Allocation({
            sharePerBlock: 136986301369863000,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0x57BB6525C489EE43BEe420F90379B047d7c40f31] = Allocation({
            sharePerBlock: 136986301369863000,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0x66CC7F5F88f65ad480a285b1FCAb824Cf0617dF1] = Allocation({
            sharePerBlock: 219178082191781000,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0x9413Da1bC1797179e5D019A9420cEEc44680A4bf] = Allocation({
            sharePerBlock: 76712328767123300,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0x3a6b4135B5B83c0A9AC46eDBFDc413952854db3d] = Allocation({
            sharePerBlock: 7671232876712330,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0xd8190FD3E70A76a2222E692eba259b77ca903594] = Allocation({
            sharePerBlock: 54794520547945200,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0x0DC874Fb5260Bd8749e6e98fd95d161b7605774D] = Allocation({
            sharePerBlock: 219178082191781000,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0xE6da9b009b16e55dF73bFA544C4f4B32E74dFFbE] = Allocation({
            sharePerBlock: 118721462592202000,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0xBbb6e8eabFBF4D1A6ebf16801B62cF7Bdf70cE57] = Allocation({
            sharePerBlock: 14003043203372000,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0xb6C3B5Efc0f4AA24f9e18d6Ce3f80e0371316657] = Allocation({
            sharePerBlock: 35799085353003200,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0xB1885A84C53f22587a3e49A27e8C92c8d6B44374] = Allocation({
            sharePerBlock: 45662099051633300,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0x84FABD111C71A5A0B20E5864fFcb213C7429e556] = Allocation({
            sharePerBlock: 152207001053741000,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0xEaf3B28A87D498530cDC7f0700E70502CF896D3f] = Allocation({
            sharePerBlock: 304414002107482000,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0x2eE1367F51B4381feA82DBF2729c2226DE578084] = Allocation({
            sharePerBlock: 45662099051633300,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0xF14c9dbDb31b0a18aF44Fcf97Ed12b0abfE1b92e] = Allocation({
            sharePerBlock: 60882798735511100,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0xb8F03E0a03673B5e9E094880EdE376Dc2caF4286] = Allocation({
            sharePerBlock: 76103502634352000,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0x9b7686c3af3f6Fb73374E1dC89D971335f09fAFb] = Allocation({
            sharePerBlock: 3044139093782930,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0xc055A10E57598303B2874a665dD79BE92dc41777] = Allocation({
            sharePerBlock: 30441399367755500,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0x99F229481Bbb6245BA2763f224f733A7Cd784f0c] = Allocation({
            sharePerBlock: 15220699683877800,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0xF5bC8bb5FA79B608f55AfbE002884f736dAf11ee] = Allocation({
            sharePerBlock: 12176560590094800,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0xf2BADeCF0c986b6E4039AF276494E744a9A0432F] = Allocation({
            sharePerBlock: 6070014752370920,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0xfDaA37F9D01f96b348C7Ce8853EA563082ff71Bb] = Allocation({
            sharePerBlock: 9132421496311910,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0xbe535c49d8e65DA9cd9a809A3D59248A89A2496B] = Allocation({
            sharePerBlock: 1522069546891460,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0xcbf4Ec5e64ff05C170a07fa839Ece108f7332734] = Allocation({
            sharePerBlock: 9132421496311910,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0x8c4209A00682164F1b1fFFe7D11895a4beC45855] = Allocation({
            sharePerBlock: 3044139093782930,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0x34ceD0b5f7F4983CF12b3D598E76BCb610321A01] = Allocation({
            sharePerBlock: 6088278187565860,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0xd2337058Ef96b3E2675b0f1cc0F0ef0b2D425f6A] = Allocation({
            sharePerBlock: 9132421496311910,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0x0051437667689B36f9cFec31E4F007f1497c0F98] = Allocation({
            sharePerBlock: 6088278187565860,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0x4d5a77B869312A8E2b3daA67C01C59753F6254AE] = Allocation({
            sharePerBlock: 6088278187565860,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0x90FFFbbdf770eFB530d950C24bf56a292CDab3F7] = Allocation({
            sharePerBlock: 9132421496311910,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0xbb3016fa2eeCD283eF40133754a83313D15210c1] = Allocation({
            sharePerBlock: 6088278187565860,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0x9C9bb489800568943a42082E7a8294544d298ac5] = Allocation({
            sharePerBlock: 1522069546891460,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0xb5d226e52E1547119EF74B90890b7e22A09339A3] = Allocation({
            sharePerBlock: 1522069546891460,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0x2Aaa2483b5cFe7719595779579Cf36819021bcaE] = Allocation({
            sharePerBlock: 6088278187565860,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0x8c5608579970CDf93EE59A05f5d97a3f15B843Bc] = Allocation({
            sharePerBlock: 71841702845100100,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0xae4F08dF03f1Dd837f5e1c96255E078426e4f4Ab] = Allocation({
            sharePerBlock: 65753424657534200,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0x3b8D277F1D1f194733F204aa85dAdb0fa7ffE7c3] = Allocation({
            sharePerBlock: 12176560590094800,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0x285b7EEa81a5B66B62e7276a24c1e0F83F7409c1] = Allocation({
            sharePerBlock: 15220699683877800,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0xE0a47370ef5847add20330282105C498CD625aeF] = Allocation({
            sharePerBlock: 8036531085353000,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        allocations[0x10885898F58f73Cba69E0Df9114779d8740E8B83] = Allocation({
            sharePerBlock: 13698630136986300,
            lastWithdrawalBlock: block.number,
            team: false  
        });
        
        startBlock = block.number;
        endBlock = block.number + 2372500;
    }

    function initialize(IERC20 _DINO) external onlyOwner
    {
        require(initialized == false, "Already initialized.");
        initialized = true;
        DINO = _DINO;
    }

    /**
     * @dev Withdraw all unlocked shares.
     */
    function withdrawShare() external
    {
        require(allocations[msg.sender].lastWithdrawalBlock < endBlock, "All shares have already been claimed.");
        uint256 unlockedBlock;
        if (block.number > endBlock) {
            unlockedBlock = endBlock;
        } else {
            unlockedBlock = block.number;
        }
        uint256 tempLastWithdrawalBlock = allocations[msg.sender].lastWithdrawalBlock;
        allocations[msg.sender].lastWithdrawalBlock = unlockedBlock;                    // Avoid reentrancy
        uint256 unlockedShares = allocations[msg.sender].sharePerBlock * (unlockedBlock - tempLastWithdrawalBlock);
        DINO.transfer(msg.sender, unlockedShares);
    }

    /**
     * @dev Get the remaining balance of a shareholder's total outstanding shares.
     */
    function getOutstandingShares() external view returns(uint256)
    {
        return allocations[msg.sender].sharePerBlock * (endBlock - allocations[msg.sender].lastWithdrawalBlock);
    }

    /**
     * @dev Get the balance of a shareholder's claimable shares.
     */
    function getUnlockedShares() external view returns(uint256)
    {
        uint256 unlockedBlock;
        if (block.number > endBlock) {
            unlockedBlock = endBlock;
        } else {
            unlockedBlock = block.number;
        }
        return allocations[msg.sender].sharePerBlock * (unlockedBlock - allocations[msg.sender].lastWithdrawalBlock);
    }

    /**
     * @dev Get the withdrawn shares of a shareholder.
     */
    function getWithdrawnShares() external view returns(uint256)
    {
        return allocations[msg.sender].sharePerBlock * (allocations[msg.sender].lastWithdrawalBlock - startBlock);
    }

    /**
     * @dev Get the total shares of shareholder.
     */
    function getTotalShares(address shareholder) external view returns(uint256)
    {
        return allocations[shareholder].sharePerBlock * 2372500;
    }

    /**
     * @dev Withdraw initial share attributed towards the treasury.
     */
    function treasuryWithdraw() external 
    {
        require(treasuryExecuted == false, "Treasury share already withdrawn.");
        treasuryExecuted = true;
        DINO.transfer(treasury, treasuryAllocation);
        DINO.transfer(liquidity, liquidityAllocation);
    }

    /**
     * @dev Emergency function to change allocations.
     */
    function emergencyChangeAllocation(address _allocation, uint256 _newSharePerBlock) external onlyOwner 
    {
        require (allocations[_allocation].team == false, "Can't change allocations of team members.");
        allocations[_allocation].sharePerBlock = _newSharePerBlock;
    }

}