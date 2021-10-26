/**
 *Submitted for verification at BscScan.com on 2021-10-26
*/

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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



pragma solidity 0.6.12;

/**
 * @dev ERC-721 non-fungible token standard.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface ERC721
{

  /**
   * @dev Emits when ownership of any NFT changes by any mechanism. This event emits when NFTs are
   * created (`from` == 0) and destroyed (`to` == 0). Exception: during contract creation, any
   * number of NFTs may be created and assigned without emitting Transfer. At the time of any
   * transfer, the approved address for that NFT (if any) is reset to none.
   */
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );

  /**
   * @dev This emits when the approved address for an NFT is changed or reaffirmed. The zero
   * address indicates there is no approved address. When a Transfer event emits, this also
   * indicates that the approved address for that NFT (if any) is reset to none.
   */
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );

  /**
   * @dev This emits when an operator is enabled or disabled for an owner. The operator can manage
   * all NFTs of the owner.
   */
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  /**
   * @notice Throws unless `msg.sender` is the current owner, an authorized operator, or the
   * approved address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is
   * the zero address. Throws if `_tokenId` is not a valid NFT. When transfer is complete, this
   * function checks if `_to` is a smart contract (code size > 0). If so, it calls
   * `onERC721Received` on `_to` and throws if the return value is not
   * `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
   * @dev Transfers the ownership of an NFT from one address to another address. This function can
   * be changed to payable.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   * @param _data Additional data with no specified format, sent in call to `_to`.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  )
    external;

  /**
   * @notice This works identically to the other function with an extra data parameter, except this
   * function just sets data to ""
   * @dev Transfers the ownership of an NFT from one address to another address. This function can
   * be changed to payable.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  /**
   * @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
   * they may be permanently lost.
   * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
   * address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is the zero
   * address. Throws if `_tokenId` is not a valid NFT.  This function can be changed to payable.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  /**
   * @notice The zero address indicates there is no approved address. Throws unless `msg.sender` is
   * the current NFT owner, or an authorized operator of the current owner.
   * @param _approved The new approved NFT controller.
   * @dev Set or reaffirm the approved address for an NFT. This function can be changed to payable.
   * @param _tokenId The NFT to approve.
   */
  function approve(
    address _approved,
    uint256 _tokenId
  )
    external;

  /**
   * @notice The contract MUST allow multiple operators per owner.
   * @dev Enables or disables approval for a third party ("operator") to manage all of
   * `msg.sender`'s assets. It also emits the ApprovalForAll event.
   * @param _operator Address to add to the set of authorized operators.
   * @param _approved True if the operators is approved, false to revoke approval.
   */
  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external;

  /**
   * @dev Returns the number of NFTs owned by `_owner`. NFTs assigned to the zero address are
   * considered invalid, and this function throws for queries about the zero address.
   * @notice Count all NFTs assigned to an owner.
   * @param _owner Address for whom to query the balance.
   * @return Balance of _owner.
   */
  function balanceOf(
    address _owner
  )
    external
    view
    returns (uint256);

  /**
   * @notice Find the owner of an NFT.
   * @dev Returns the address of the owner of the NFT. NFTs assigned to the zero address are
   * considered invalid, and queries about them do throw.
   * @param _tokenId The identifier for an NFT.
   * @return Address of _tokenId owner.
   */
  function ownerOf(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  /**
   * @notice Throws if `_tokenId` is not a valid NFT.
   * @dev Get the approved address for a single NFT.
   * @param _tokenId The NFT to find the approved address for.
   * @return Address that _tokenId is approved for.
   */
  function getApproved(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  /**
   * @notice Query if an address is an authorized operator for another address.
   * @dev Returns true if `_operator` is an approved operator for `_owner`, false otherwise.
   * @param _owner The address that owns the NFTs.
   * @param _operator The address that acts on behalf of the owner.
   * @return True if approved for all, false otherwise.
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    view
    returns (bool);

}



pragma solidity >=0.4.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}


pragma solidity >=0.4.0;

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


pragma solidity >=0.4.0;



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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



pragma solidity 0.6.12;
contract Raid is Ownable {
    
    using SafeMath for uint256;
    
    
    struct UserInfo {
        uint256 Life;     // 
        uint256 Attack;
        uint256 Defense; // 
        uint256 Afinity;
        uint256 TrueAfinity;
        uint256 LuckSt;
        uint256 AP;
        uint256 ID;
    
        bool enter;
        bool blaze;
        bool iron;
        bool crest;
        bool badegg;
    }
    
    struct Contest{
        address UserContest;
    }
    
        

    
     mapping (address => UserInfo) public userInfo;
     mapping (uint256 => Contest) public contest;
     
     address EggcContract;
     address vault;
     
     
     
     
     address EssentialContract;
     address EvolutiveContract;
     address MineralContract;
     address FusionContract;
     address GemsContract;
     address BlazeContract;
     address IronContract;
     address CrestContract;
     address BadEggContract;
     
     uint256 HP;
     uint256 Attack;
     uint256 Defense;
     uint256 Afinity;
     uint256 Luck;
     uint256 AP;
     
     uint256 TotalUser;
     
     
     uint256 Attack_B;
     uint256 Defense_B;
     uint256 AP_B;
     
         uint256 code;
         address userW;
         uint256 APattack;
     
     uint256 InitRaid;
     uint256 EndRaid;
     uint256 bolsa;
     
     bool win;
     uint256 status;

    
     
     
     
     function deposit1() public  {
        UserInfo storage user = userInfo[msg.sender];
        require(user.enter == false && block.number > InitRaid && block.number < EndRaid);
        user.Life = (ERC721(address(EssentialContract)).balanceOf(msg.sender)) * 1;
        user.Attack = (ERC721(address(EvolutiveContract)).balanceOf(msg.sender)) * 3;
        user.Defense = (ERC721(address(MineralContract)).balanceOf(msg.sender)) * 3;
        user.Afinity = (ERC721(address(FusionContract)).balanceOf(msg.sender)) * 2;
        user.TrueAfinity = (ERC721(address(FusionContract)).balanceOf(msg.sender)) * 5;
        user.LuckSt = (ERC721(address(GemsContract)).balanceOf(msg.sender)) * 1;
        user.AP = user.Life + user.Attack + user.Defense + user.TrueAfinity + (user.LuckSt*10);
        APattack = user.AP;
        HP = HP + user.Life;
        Attack = Attack + user.Attack;
        Defense = Defense + user.Defense;
        Afinity = Afinity + user.Afinity;
        Luck = Luck + user.LuckSt;
        AP_B = AP_B - user.AP;
        AP = AP + user.AP;
        userW = msg.sender;
        code = 1;
        TotalUser = TotalUser + 1;
        user.ID = TotalUser;
        Contest storage userC = contest[TotalUser];
        userC.UserContest = msg.sender;
        user.enter = true;
    }
    
    function claim() public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.enter == true  );
        IBEP20 r150 = IBEP20(EggcContract);
        if(win == true){
           uint256 reward = ((bolsa * 10 ** 18) / AP) * user.AP;
           require(r150.transferFrom(vault, msg.sender, reward  ));
        }
       user.blaze = false;
       user.iron = false;
       user.crest = false;
       user.badegg = false;
        user.enter = false;
        
        
    }
    
    function SendBlaze() public  {
        UserInfo storage user = userInfo[msg.sender];
        require(user.blaze == false && block.number > InitRaid && block.number < EndRaid );
        uint256 Blaze = (ERC721(address(BlazeContract)).balanceOf(msg.sender));
        userW = msg.sender;
        code = 2;
        Attack = Attack + (Blaze * 1000);
        AP = AP + (Blaze * 3000);
        AP_B = AP_B - (Blaze * 3000);
        user.AP = user.AP + (Blaze * 3000);
        user.blaze = true;
    }
    
    function SendIron() public  {
        UserInfo storage user = userInfo[msg.sender];
        require(user.iron == false && block.number > InitRaid && block.number < EndRaid );
        uint256 Iron = (ERC721(address(IronContract)).balanceOf(msg.sender));
        userW = msg.sender;
        code = 3;
        Defense = Defense + (Iron * 1000);
        AP = AP + (Iron * 3000);
        user.AP = user.AP + (Iron * 3000);
        user.iron = true;
    }
    
    function SendCrest() public  {
        UserInfo storage user = userInfo[msg.sender];
        require(user.crest == false && block.number > InitRaid && block.number < EndRaid);
        uint256 Crest = (ERC721(address(CrestContract)).balanceOf(msg.sender));
        userW = msg.sender;
        code = 4;
        HP = HP + (Crest * 5000);
        AP = AP + (Crest * 500);
        user.AP = user.AP + (Crest * 500);
        user.crest = true;
    }
    
    function SendBadEgg() public  {
        UserInfo storage user = userInfo[msg.sender];
        require(user.badegg == false && block.number > InitRaid && block.number < EndRaid);
        uint256 BadEgg = (ERC721(address(BadEggContract)).balanceOf(msg.sender));
        userW = msg.sender;
        code = 5;
        AP_B = AP_B - (BadEgg * 5500);
        AP = AP + (BadEgg * 550);
        user.AP = user.AP + (BadEgg * 550);
        user.badegg = true;
    }
    
    
    
    // Question Section --------------------------------------------------
    
    
    function SetAttack(uint256 _APFAIL) public onlyOwner {
        HP = HP - _APFAIL;
        status = 1;
    }
    
    function SetPlus(uint256 _APB, uint256 _Reward) public onlyOwner {
        AP_B = AP_B - _APB;
        bolsa = bolsa + _Reward;
    }
    
    
    // --------------------------------------------------- INITIALITED
    
    function StartRaid(uint256 _InitRaid,uint256 _EndRaid, uint256 _bolsa) public onlyOwner {
        InitRaid = _InitRaid;
        EndRaid = _EndRaid;
        bolsa = _bolsa;
    }
    
    function BornBoss(uint256 _Attack_B, uint256 _Defense_B, uint256 _HPB) public onlyOwner {
        Attack_B = _Attack_B;
        Defense_B = _Defense_B;
        AP_B = _HPB;
    }
    
    function SetWin() public onlyOwner {
        win = true;
    }
    
     function setAllContract(address _Essential, address _Evolutive, address _Mineral, address _Fusion , address _Gems, address _Blaze , address _Iron, address _Crest, address _BadEgg, address _EGGC) public onlyOwner {
         EssentialContract = _Essential ;
         EvolutiveContract = _Evolutive ;
         MineralContract = _Mineral ;
         FusionContract = _Fusion ;
         GemsContract = _Gems ;
         BlazeContract = _Blaze;
         IronContract = _Iron;
         CrestContract = _Crest;
         BadEggContract = _BadEgg;
         EggcContract = _EGGC;
     }
     
        
     
     function setVault(address _Vault) public onlyOwner {
         vault = _Vault;
     }
     
     //---------------------------------------------- Messages console 
     
     function ViewCode() external view returns (uint256) {
         
      return code;
    }
     
     function ViewUserCode() external view returns (address) {
         
      return userW;
    }
    
    function ViewUserAttack() external view returns (uint256) {
         
      return APattack;
    }
    
    function ViewAttackQuestion() external view returns (uint256) {
         
      return status;
    }
    //-------------------------------------- View Winners 
     
    function ViewUserID(address _user) external view returns (uint256) {
         UserInfo storage user = userInfo[_user];
      return user.ID;
    }
     
     
     //-------------------------------------- View Contadores 
function ViewInitRaid() external view returns (uint256) {
         
      return InitRaid;
    }
    
    function ViewEndRaid() external view returns (uint256) {
         
      return EndRaid;
    }
    
    //view Stats
   
    function ViewAP() external view returns (uint256) {
         
      return AP;
    }
    
    function ViewAP_B() external view returns (uint256) {
         
      return AP_B;
    }
    
    function ViewHP() external view returns (uint256) {
         
      return HP;
    }
    
   

    function ViewAttack() external view returns (uint256) {
         
      return Attack;
    }
    
    function ViewAttack_B() external view returns (uint256) {
         
      return Attack_B;
    }
    
    function ViewDefense() external view returns (uint256) {
         
      return Defense;
    }
    
    function ViewDefense_B() external view returns (uint256) {
         
      return Defense_B;
    }
    
    function ViewAfinity() external view returns (uint256) {
         
      return Afinity;
    }
    
    
    
    function ViewLuck() external view returns (uint256) {
         
      return Luck;
    }
    
    
    
    function ViewTotalUser() external view returns (uint256) {
         
      return TotalUser;
    }
    
    function ViewBolsa() external view returns (uint256) {
         
      return bolsa;
    }
    
    function ViewWin() external view returns (bool) {
         
      return win;
    }
    
    function ViewYourAP(address _user) external view returns (uint256) {
         UserInfo storage user = userInfo[_user];
      return user.AP;
    }
    
    
    // Reset ALL 
    
    
    function Reset() public onlyOwner {
        Attack_B = 0;
        Defense_B = 0;
        AP_B = 0;
        HP = 0;
        Attack = 0;
        Defense = 0;
        Afinity = 0;
        Luck = 0;
        AP = 0;
        win = false;
        TotalUser = 0;
        bolsa = 0;
    }
    
     
}