// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PresaleSplitter is Ownable {
    address[] PRESALE_WALLETS = [
        0x6BFD376A9F519c063aF2955622410a1d526FA5D3,
        0x74e829F10d708f03fC14891D808392E4769d821e,
        0x1859f52B0711975aC47a98B520d8D6A6fF13f82A,
        0x20d1299605C8842DD07Fe7e419d0606000Ee4b35,
        0xdFE538562f84267efbbc44c15f8A82894ece365e,
        0x0a0Bdc24B88004c4E106B9E76384270f2D785098,
        0xAB48D6E6a704CDBEeD1707a7171783C523849F9a,
        0x2c59900B9442b7A865F93219c04f553a0D7BD003,
        0x5b890462b028EA5aB990EC835DC025546675ed4c,
        0xF4C246a7756518E800c7906B3e839b8F59be34B4,
        0x6205de9C5FA8c78601DF3497234CbDcb06145d84,
        0x3c118d8FFD841075B4fF7E0a17B9246ed307F943,
        0x09F20Ee17434203A70DACf56D77d4Ea2FaBF3AD7,
        0xdd1aCbb332Ac0BB474331af06239Eb19766f012a,
        0x2549855C91685aE5712A2eaEC98Ab77DB3D95f92,
        0xBd300dEBe2bDe209D0EC52d54EaEfCea03162738,
        0xDddd34f88B475daE9feF76af218B00CCa0d7a06A,
        0x2F7F73C12aF065bc9F543200687EADFfE2765d6B,
        0x678DA03Ee2c311Daa7ED32D4aD9C351Af3A6e9de,
        0x3fF069c5b6A2B7f24Bab39010De631c76024Bd85,
        0x6B594BdF1867EC53A23533a11dd59bCC1F3996c8,
        0xcf7450A761D0e6e5A5Fb9c4fCEe6d70E86Afb7C9,
        0xB386326f66F08B0A4E9DeD768Ae58082c4d5Df84,
        0x53ee0bAa5a782249E7bA8E1601c6d63ef14831e1,
        0xa0EfB61e502935c184DF81202B8A03c3a24F8820,
        0x5B25E9C1A6bA6dD713f985759497fDC022B2BC1C,
        0x6f1fbcdFc8B93D9EddA20aCdE12b7A8Ee69c66B0,
        0xf74ea010C41520741D984A6dc4c95E576D13b199,
        0x1978fF6F1c0A3760696169B001647f7f7D9600C8,
        0xBe47430010C3eB40188c72e6D77ad1111abB8177,
        0xa2ebD1C59EB79e3e48BDdB9Ebff46292638ef868,
        0x76CA63269Ef4868Ce3a49E4B5C8AE5af697F1b7b,
        0xfB67a6a59609662330171f63142c7259f241f346,
        0x3fd2870fdE84C13087883A02f02d6620Dcf1a6c8,
        0xC386D86Aa8d2562d16542A01CFb707Deb4591047,
        0x5bdB7099528Cf257a250EFFB205147CCa6Ce4297,
        0xcc91ab199b9E33F6677Cb43c1554f4dE873471c5,
        0x4066643f04859fa538Ba8EAa906C197c57e4e3e0,
        0x1a356127c8f71c4D806dacCAD55E713bF5d7694C,
        0xF3dcf73975a657822ce3F00d3558f5D7523FAB8b,
        0x0655c24b35EAa1d45A802Ae4EA90E032322DAA2A,
        0xE18C488e8f06B1C23a18034652263754fBf2b85d,
        0xE9EE334a1fE1567905Be99205BBB147c6362A86f,
        0x0462096A2631fA4974713F0C0E29B43b510f6570,
        0x589f1CA208E199835E9900717Ae512B2d1d0b615,
        0x5e46c8281b928B339E37eACec196c90E6C97117b,
        0x68C30f76246d44AADa78847b55563d76d480802b,
        0x47D11cD57c4E82a4740C03943A4F0A7FFd3B1e98,
        0xC28B1f5692c3D02e6AB9631a8BEf49A7750A9826,
        0xc7d376cdEcCBE2f853ca42E4bF92f1ADb4e7E104,
        0x953F88cE7F3180A5dBB7e677f6400c43E50F7c88,
        0xb9B97A6aDeaD5f721B731bE71C6f350462fc5855,
        0x352Ec5E1370302C4137C1B48A5273e057053d7DA,
        0x19f168a360184AE820b39bB7045B586417c72693,
        0xA8E35427c5E8819537A4722beE6D31C1170193ae,
        0x2E3BfE75EE3e95a8d8964D27c4ea19D51FCb488E,
        0xa03Fa6E5A08d0e03D317CaBd975bC1e6005195a6,
        0x5E40ca84Dd0aEBeb70178D811742001b5A84C572,
        0x4ab79a32a0f6Eb1D2eb3d9CcfCd74485f8c2F2D6,
        0xbD9492AAfcea713BF5dE6D42E5c142Ac67A37cdA,
        0x14F258325A985e11C2c492f903e0a87FdA0dE33f,
        0xB35f652428ED26216D2331D5ce0978acE42287Ec,
        0xF124A32E40ba76b529955F25a0e93f41b5387A87,
        0x1F1c72835e4a6886cB9FeF58D153580B0efF78ae,
        0xe73e8e809ED6Effdc9A8c892fc69f2ED6F70a62F,
        0x376A2F01F821FfF7bb2f19b2D0480673c7F73c95,
        0xD7ec863643e06a548A6d9f0B0bd9Aa0AB2B80a8e,
        0xb36669a35e2E8383D3F02d196f8A757Fb2eE0CbC,
        0xA6F10047C07f4e3f8Ca38997953D5F99520A8469,
        0x2B14F0bE362DC03650e3dA2723C6e38117845376,
        0x804CB947D282e493f166aef62abd69e80e5047Ff,
        0xd201489f6efebb671E616Da8E1BE280d63A614F7,
        0xF38e7F44783e53597206Fc3d55B53e844c244Cc6,
        0x1afe3b339440F2367f3B11B69CA60dB5b3f122A1,
        0xbA2A8E5C9771203aa3de81E12C95034EAD915e56,
        0x2F442Ad2d8fb7ebc65e89055Cbf7eeF64b60DF96,
        0x380CFcD0b98Cc56aA57A7eB9D90996A98360A494,
        0x60Ee29796DbeaC110a92D2C4c4ca2A2CDaC35B3a,
        0xB8Cd77756cA8550c285f32deCE441262540C020d,
        0x9c46305ecA4879656252a4323bF2ef85C22a14Fb,
        0x08A1390B69650e69DA1457dc30F4FF6b3685f71C,
        0xA932162f59ac303E1154E1B0af14aBa16663aCB1,
        0x362776a5e816db882AD238d1706F03A0d55A095f,
        0xbd42878d3cC49BB4903DF1f04E7b445ECA4bd238,
        0x4d60E753c22A3be2ee4Fe05086B792644a425335,
        0x811f1A08aA3eC1C681a4D67EF66689d51b3C3429,
        0x70Ceb37b18B283F7DeA1B614376D4A5C1d33F367,
        0x895802A41eb1E61F8Ea49Ca6281F2F4eAECE1c71,
        0x5Fe3A3FdaBbBcDbDD5c914F403f8428316338A3D,
        0xE41Cc125107cf0196e85FffA61d69C5A12D2693b,
        0xfC322C620e7c5D6d3E9543b42dFE820e15bA6Ab8,
        0xD7ec863643e06a548A6d9f0B0bd9Aa0AB2B80a8e,
        0x07aae53152f477AF1C62C22583FDED69b0A5382F,
        0x2B9858Dab41ea07249d58f82e566404bd1778e9b,
        0x73B5509bfa1107186C7705C9dE4887C79f230044,
        0x1276a8C0F81c2575e7435645b62766422B8399cb,
        0x036Dbf52BA4C6F58B0855d9c0fd3997d67180361,
        0x6b17bb77F8Bde7cBE21306BFB6E3969A9bA70841,
        0xa5335cC80cCC0a09d1657dceAf423C241793E9B5,
        0x321d57d82714bb173f40C134881590Eee4792E1F,
        0x1010fb622aD9D19F3B62cC82fEfC5cb95a71aA34
    ];

    mapping(address => uint256) public lastTimeClaim;
    mapping(address => uint256) public totalClaimedAmount;
    uint256 public presaleStartDate;
    uint256 public claimInterval;
    uint256 public claimValueByDay = 100000000000000000000;
    uint256 public maxClaimValue = 2500000000000000000000;
    uint256 public maxClaimTimes = 25;
    address public presaleWalletAddress =
        0x0aEa3638B16633e970c7311f22635e6064559a70;
    address public tokenAddress;

    constructor() {
        presaleStartDate = 1640381536;
        claimInterval = 86400;
        tokenAddress = address(0x9c6383Dbba84b935c0A9Ef7167d1BF2fb45F4D9c);
    }

    function changeClaimValueByDay(uint256 value) external onlyOwner {
        claimValueByDay = value;
    }

    function changeClaimInterval(uint256 value) external onlyOwner {
        claimInterval = value;
    }

    function updatePresaleAddress(address value) external onlyOwner {
        presaleWalletAddress = value;
    }

    function getClaimInterval() internal returns (uint256 time) {
        return block.timestamp + claimInterval;
    }

    function findAddressOnPresaleList(address wallet)
        internal
        returns (int256 index)
    {
        for (uint256 i = 0; i < PRESALE_WALLETS.length; i++) {
            if (wallet == address(PRESALE_WALLETS[i])) {
                return int256(i);
            }
        }
        return -1;
    }

    function calculateClaimableAmount(address wallet)
        public
        view
        returns (uint256 claimAmount)
    {
        uint256 totalClaimableValue = 0;
        uint256 lastClaimDate = lastTimeClaim[wallet];

        uint256 endDate = block.timestamp;

        uint256 diff = (endDate - presaleStartDate) / 60 / 60 / 24;

        if (diff > 0) {
            totalClaimableValue = diff * claimValueByDay;
        }
        return totalClaimableValue;
    }

    function claim() external {
        require(msg.sender != address(0), "SENDER CAN'T BE ZERO");
        require(
            findAddressOnPresaleList(msg.sender) != -1,
            "SENDER NOT FOUNDED ON PRESALE LIST"
        );
        require(
            lastTimeClaim[msg.sender] > getClaimInterval(),
            "TOO EARLY TO CLAIM"
        );
        require(
            totalClaimedAmount[msg.sender] < maxClaimValue,
            "MAX TOKEN AMOUNT CLAIMED "
        );
        require(
            calculateClaimableAmount(msg.sender) > 0,
            "AMOUNT TO CLAIM HAS TO BE GREATER THAN 0"
        );
        require(
            ERC20(tokenAddress).balanceOf(presaleWalletAddress) > calculateClaimableAmount(msg.sender),
            "PRESALES POOL EMPTY"
        );

        ERC20(tokenAddress).transferFrom(
            presaleWalletAddress,
            msg.sender,
            calculateClaimableAmount(msg.sender)
        );
        totalClaimedAmount[msg.sender] += calculateClaimableAmount(msg.sender);
        lastTimeClaim[msg.sender] = block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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