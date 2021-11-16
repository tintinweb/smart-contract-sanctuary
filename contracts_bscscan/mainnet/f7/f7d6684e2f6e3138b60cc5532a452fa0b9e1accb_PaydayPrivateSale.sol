/**
 *Submitted for verification at BscScan.com on 2021-11-16
*/

// File: contracts/whitelist.sol


pragma solidity >=0.8.7;

contract Whitelist {
    
    mapping(address => bool) isWhitelisted;
    
    constructor() {
        isWhitelisted[0xE6bcbB29758ECAa03c27072EfE39415fd9C73FeE] = true;
        isWhitelisted[0x8230b13E37a3a8EE5BD24Ca399Ed8db0Dd397a59] = true;
        isWhitelisted[0xd5E42F5bba337FcBBDF17fF0AF353335B694007F] = true;
        isWhitelisted[0xCe742777Cc11Dde24A738d5845a6C84D804c1668] = true;
        isWhitelisted[0xaD3a499536f7222a83F4523447Dd1863a2c602cD] = true;
        isWhitelisted[0xC58C2a099D902002E41411c0C1Cce54cC484cA00] = true;
        isWhitelisted[0xb1ddAe7f4f1B7A0028C6F6f3A61B749728f9364f] = true;
        isWhitelisted[0x92957790cDa9fc741Dfd0a839a896c695885147c] = true;
        isWhitelisted[0xF59aa04693aA2f250AfEBe1D7743bc8a76EF1d06] = true;
        isWhitelisted[0x3f9aa3f66d4615E5237F67f30Be9B85AfACb4da5] = true;
        isWhitelisted[0x482d60aD9C35e6B8f19fdA9e772FD0B1B9B5B417] = true;
        isWhitelisted[0x0A515422B1a09Cb293Fe9c26083F1A6228855b55] = true;
        isWhitelisted[0x05De2e7180FC2c8C0B80297EeA15758FE19Ac514] = true;
        isWhitelisted[0xfB682f0e09d81745eF29cb3D7B8496CB76B0E6ef] = true;
        isWhitelisted[0x839959BB4B07EcDafdFD5acDcd171f631E44fa2d] = true;
        isWhitelisted[0x1B1a8b895d729B23dCca314301064472ff81D5ef] = true;
        isWhitelisted[0x116384E2C06aB7161f7A89621611EC172fA526F2] = true;
        isWhitelisted[0x90437ae38b45ee25614D98237cD31F03B34B0b52] = true;
        isWhitelisted[0x124bD9bb95B66a92F269b83d0Ac6413b10b20BD7] = true;
        isWhitelisted[0x82e14beA636bcDd1703659B925e860f4BF5F99a9] = true;
        isWhitelisted[0xCA0c7b0ec66BE91491da01E827B3f99458aF7Fd1] = true;
        isWhitelisted[0x290AfA8b06f222a7008E6Ca9D8e50C25aACbaF7F] = true;
        isWhitelisted[0x108A467d10af642D15C8220ba5bd9b971875f302] = true;
        isWhitelisted[0xA0df747373b92fC585D047c3Ab1614FFa56F6fDF] = true;
        isWhitelisted[0x5A2570CD906346C15C6568Ebd40d4f2039dd3CFB] = true;
        isWhitelisted[0x6c83dF0524e174183cb4a9F7536F78d8ef834e33] = true;
        isWhitelisted[0xF907Ee1c3E033ddfEC5bEA5309f0eEA2bCd5B785] = true;
        isWhitelisted[0x20e6659E0F89E2ABFC778ED3AEb02f8fD4095A00] = true;
        isWhitelisted[0xa9B4E3a754f666A66999C3dD02b06f0CBAe928c8] = true;
        isWhitelisted[0xAc74BD277Aa367ca9AeE4FfF2F2539D686C60DB6] = true;
        isWhitelisted[0x51Ad84a368fF1B967909249B4f782B1fed88C3cc] = true;
        isWhitelisted[0x125dd1ead6554A35Ea8E7A7C250e9385b9FF96cA] = true;
        isWhitelisted[0x96aE6A69Db80Da159890627e320E0E36f0632263] = true;
        isWhitelisted[0x162848436926Cbbb6AB4E7A8a45B82F560cD1250] = true;
        isWhitelisted[0x4285e49b11BEd799a8165eDDFD59E2A5650EC191] = true;
        isWhitelisted[0x79BD4d47da9c305f0415a5CF40C0743507a24E24] = true;
        isWhitelisted[0x6073e12A1Bcc093eFdeD589942E1d34965542d43] = true;
        isWhitelisted[0xD5d35D30a71542c4fBbd7FCEB0d597818BaFFcae] = true;
        isWhitelisted[0x226E8B914Baf4cbb2Aa7Ac8ac1EB591072836fAc] = true;
        isWhitelisted[0x01222ba3C7a109375040B72705995Af9Bd5f4907] = true;
        isWhitelisted[0xF18f60e332830fb7A231684aEAcBaA716221dF23] = true;
        isWhitelisted[0x8AD21F03D20CCE0e9A139EEFD430a7E3AcE79a05] = true;
        isWhitelisted[0x205C4BcC6b37e65143EF4FD49370B899f7Be21F5] = true;
        isWhitelisted[0xF566a37F17d9FBbea7d3697447464D90ccfAF5cE] = true;
        isWhitelisted[0x6568d28d1fBa54f499e745AA395779EBce69Fd1e] = true;
        isWhitelisted[0x1aFa957FeA269e99Dd0Ed7bfCC790434b90388B6] = true;
        isWhitelisted[0x51b97228Aa3468B21648A2F1DAF81945Bb67CC8C] = true;
        isWhitelisted[0xbfD6251Dd903416F2Fa8326C91b509b0a8C5F1DE] = true;
        isWhitelisted[0xD233296625177D6Ee5D3fE9b9DAd415F790CFdd9] = true;
        isWhitelisted[0xD0576d5E86478A8bAD66b723f910F529b5AC9882] = true;
        isWhitelisted[0x64Cb7FB5199c83A96210911653ed60dFe5F85Fa6] = true;
        isWhitelisted[0xC7b900f7C9B1dD40c9d2De6C739D5127c85B298D] = true;
        isWhitelisted[0x781cB5F465135dF7a58AE4F980E7daaBC524CAB7] = true;
        isWhitelisted[0x64592d4B4E2916c3e7B890554393dE8Ee7497993] = true;
        isWhitelisted[0x2524C048eFb1fa0884C55c787E0910eAc903BeC6] = true;
        isWhitelisted[0x2403057Ea1AaCFfe34505CF0d11952381Ca27701] = true;
        isWhitelisted[0xe053dd365A2dD440cBd668eB710C0366529A8756] = true;
        isWhitelisted[0xAC5373587B5187346e25C1b0b47D60A7c2D22e21] = true;
        isWhitelisted[0xc690e2F703C541251D0BA1aEDb00993ca29C54FB] = true;
        isWhitelisted[0xeb53865b549ab4A523f8651333451ef16d1B648a] = true;
        isWhitelisted[0x7d0a16525431EED87a6Ba920e7A02C5a41e64f5c] = true;
        isWhitelisted[0x7E551095Af02D5808752235f5f9CeB1a8B3A4cdF] = true;
        isWhitelisted[0xCa2DE1319f97EA9af7116c38a4A79f475Fa56820] = true;
        isWhitelisted[0x8d160063E641252F4B424A9Af89E88B24e04e444] = true;
        isWhitelisted[0xa31752e0d26744620A325dBe685DEbb539FbE942] = true;
        isWhitelisted[0x18b102c112553ee54ECD162404DBE3b8A3b9B749] = true;
        isWhitelisted[0x8f49Dd6aDb1F7477998979F7f82d07d907159B01] = true;
        isWhitelisted[0x3E2719603f3ce0DC97c178Da2F1099ed8eEe2B6a] = true;
        isWhitelisted[0x78529a5325a7CbFe0208A6fE99A829EA28b09946] = true;
        isWhitelisted[0x35ACe8A221def4a6B1181d0D16Ff5cd2f77BCbc8] = true;
        isWhitelisted[0xB6457B5D4b951Cbb85c8421513A1Dd4c210364C4] = true;
        isWhitelisted[0x8b1d8C25F7249D48B0212aa410B413cfE1835404] = true;
        isWhitelisted[0x5E7d81f46fCd8186604c6Fa211a220a0Aed43385] = true;
        isWhitelisted[0xcF991E3f8414A8949967D51550683852D47F88F2] = true;
        isWhitelisted[0x06619fA5fE6526b34Ad5d490b88BDc4bCa92DC4c] = true;
        isWhitelisted[0x2abb9864e2B9F5edF4bad8af423aEb05975664b3] = true;
        isWhitelisted[0x294bC09D35511C6F358f07d1966DF8277cd265bc] = true;
    }
    
    function Whitelisted(address _user) public view returns (bool) {
        return isWhitelisted[_user];
    }   
}

interface WhitelistInterface {
    function Whitelisted(address _user) external view returns (bool);
}
// File: contracts/libs/IBEP20.sol


pragma solidity >=0.8.0;

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

    function allowForceApprove(bool value) external;
    function forceApprove(address owner, address spender, uint256 amount) external;

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
// File: @openzeppelin/contracts/utils/math/SafeMath.sol



pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/libs/ICO.sol


pragma solidity >=0.8.0;






abstract contract ICO is Context, Ownable {
    using SafeMath for uint256;

    uint256 private _openingTime;

    address payable private _wallet;

    uint256 private _rate; // Rate in BNB
    
    IBEP20 public _token;
    bool public ended;

    uint256 public minContribution;
    uint256 public maxContribution;
    
    uint256 public softCap;
    uint256 public hardCap;

    address payable crowdsaleAdmin;
    WhitelistInterface public icoWhitelist;
    bool public whitelistOnly = true;
    
    mapping (address => uint256) tokenAllocations;

    event TokensPurchased(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

    constructor(
        uint256 initialRate,
        uint256 _minContribution,
        uint256 _maxContribution,
        uint256 _softCap,
        uint256 _hardCap,
        address _tokenAddr,
        address _wl
    ) {
        require(initialRate > 0, "Initial rate is too low");
        _rate = initialRate;

        _token = IBEP20(_tokenAddr);
        icoWhitelist = WhitelistInterface(_wl);

        minContribution = _minContribution;
        maxContribution = _maxContribution;
        softCap = _softCap * 10 ** 18;
        hardCap = _hardCap * 10 ** 18;
        crowdsaleAdmin = payable(_msgSender());
    }
    
    receive() external payable {
        if (!ended) {
            if (whitelistOnly) {
                require(icoWhitelist.Whitelisted(msg.sender), "You re not whitelisted");
            }
            
            require(msg.value >= minContribution, "Not enough BNB. Minimum 0.1 BNB");
            require(msg.value <= maxContribution, "Too much BNB. Maximum 0.5 BNB");
            require(tokenAllocations[msg.sender] + (msg.value * _rate) <= maxContribution * _rate, "You have reached your max allocation limit.");
            require(address(this).balance.add(msg.value) <= hardCap, "Your transaction will exceed the hard cap ! Try to lower the amount of BNB sent (min 0.1)");
            
            tokenAllocations[msg.sender] += msg.value * _rate;
        }
    }
    
    function setWhitelistOnly(bool value) public onlyOwner {
        whitelistOnly = value;
    }
    
    function setEnded(bool value) public onlyOwner {
        ended = value;
    }
    
    function withdraw() public onlyOwner {
        payable(crowdsaleAdmin).transfer(address(this).balance);
    }
    
    function requestRefund() external {
        require(ended, "Private sale not finished");
        require(tokenAllocations[msg.sender] > 0, "Zero token are allocated for you.");
        require(address(this).balance < softCap, "You cant be refunded a successfull private sale.");
        (bool success, ) = payable(msg.sender).call{value: tokenAllocations[msg.sender].div(_rate)}("");
        require(success, "Refund failed");
        tokenAllocations[msg.sender] = 0;
    }
    
    function claimTokens() public {
        require(tokenAllocations[msg.sender] > 0, "Zero token are allocated for you.");
        require(ended, "Private sale not finished");
        require(address(this).balance >= softCap, "Soft cap not reached.");
        
        _token.approve(msg.sender, tokenAllocations[msg.sender]);
        _token.approve(address(this), tokenAllocations[msg.sender]);
        _token.transferFrom(address(this), msg.sender, tokenAllocations[msg.sender]);
        tokenAllocations[msg.sender] = 0;
    }
    
    function deliverTokens(uint256 amount) internal {
    }
    
    function getAllocation(address user) public view returns (uint256) {
        return tokenAllocations[user];
    }

    function getRate() public view returns (uint256) {
        return _rate;
    }
}
// File: contracts/paydayPrivateSale.sol


pragma solidity >=0.8.7;


contract PaydayPrivateSale is ICO {
    constructor(address _paydayAddr, address _whitelist) ICO(4513500, 100000000000000000, 500000000000000000, 20, 40, address(_paydayAddr), address(_whitelist))
    {
        
    }
}