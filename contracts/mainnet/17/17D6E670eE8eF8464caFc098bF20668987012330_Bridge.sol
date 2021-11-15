pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./BridgeInterface.sol";
import "./SignatureChecker.sol";
import "./WrappedTON.sol";


contract Bridge is SignatureChecker, BridgeInterface, WrappedTON {
    address[] public oraclesSet;
    mapping(address => bool) public isOracle;
    mapping(bytes32 => bool) public finishedVotings;

    constructor (string memory name_, string memory symbol_, address[] memory initialSet) ERC20(name_, symbol_) {
        updateOracleSet(0, initialSet);
    }
    
    function generalVote(bytes32 digest, Signature[] memory signatures) internal {
      require(signatures.length >= 2 * oraclesSet.length / 3, "Not enough signatures");
      require(!finishedVotings[digest], "Vote is already finished");
      uint signum = signatures.length;
      uint last_signer = 0;
      for(uint i=0; i<signum; i++) {
        address signer = signatures[i].signer;
        require(isOracle[signer], "Unauthorized signer");
        uint next_signer = uint(signer);
        require(next_signer > last_signer, "Signatures are not sorted");
        last_signer = next_signer;
        checkSignature(digest, signatures[i]);
      }
      finishedVotings[digest] = true;
    }

    function voteForMinting(SwapData memory data, Signature[] memory signatures) override public {
      bytes32 _id = getSwapDataId(data);
      generalVote(_id, signatures);
      executeMinting(data);
    }

    function voteForNewOracleSet(int oracleSetHash, address[] memory newOracles, Signature[] memory signatures) override  public {
      bytes32 _id = getNewSetId(oracleSetHash, newOracles);
      require(newOracles.length > 2, "New set is too short");
      generalVote(_id, signatures);
      updateOracleSet(oracleSetHash, newOracles);
    }

    function voteForSwitchBurn(bool newBurnStatus, int nonce, Signature[] memory signatures) override public {
      bytes32 _id = getNewBurnStatusId(newBurnStatus, nonce);
      generalVote(_id, signatures);
      allowBurn = newBurnStatus;
    }

    function executeMinting(SwapData memory data) internal {
      mint(data);
    }

    function updateOracleSet(int oracleSetHash, address[] memory newSet) internal {
      uint oldSetLen = oraclesSet.length;
      for(uint i = 0; i < oldSetLen; i++) {
        isOracle[oraclesSet[i]] = false;
      }
      oraclesSet = newSet;
      uint newSetLen = oraclesSet.length;
      for(uint i = 0; i < newSetLen; i++) {
        require(!isOracle[newSet[i]], "Duplicate oracle in Set");
        isOracle[newSet[i]] = true;
      }
      emit NewOracleSet(oracleSetHash, newSet);
    }
    function getFullOracleSet() public view returns (address[] memory) {
        return oraclesSet;
    }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./TonUtils.sol";


interface BridgeInterface is TonUtils {
  function voteForMinting(SwapData memory data, Signature[] memory signatures) external;
  function voteForNewOracleSet(int oracleSetHash, address[] memory newOracles, Signature[] memory signatures) external;
  function voteForSwitchBurn(bool newBurnStatus, int nonce, Signature[] memory signatures) external;
  event NewOracleSet(int oracleSetHash, address[] newOracles);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "./IERC20.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is IERC20 {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
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
        _transfer(msg.sender, recipient, amount);
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
        _approve(msg.sender, spender, amount);
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);

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
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

pragma solidity ^0.7.0;

/* Source: @openzeppelin/contracts */
// SPDX-License-Identifier: MIT

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

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./TonUtils.sol";

contract SignatureChecker is TonUtils {

    function checkSignature(bytes32 digest, Signature memory sig) public pure {
          if (sig.signature.length != 65) {
              revert("ECDSA: invalid signature length");
          }

          // Divide the signature in r, s and v variables
          bytes32 r;
          bytes32 s;
          uint8 v;

          bytes memory signature = sig.signature;

          // ecrecover takes the signature parameters, and the only way to get them
          // currently is to use assembly.
          // solhint-disable-next-line no-inline-assembly
          assembly {
              r := mload(add(signature, 0x20))
              s := mload(add(signature, 0x40))
              v := byte(0, mload(add(signature, 0x60)))
          }

          if (
              uint256(s) >
              0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
          ) {
              revert("ECDSA: invalid signature 's' value");
          }

          if (v != 27 && v != 28) {
              revert("ECDSA: invalid signature 'v' value");
          }
          bytes memory prefix = "\x19Ethereum Signed Message:\n32";
          bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, digest));
          require(ecrecover(prefixedHash, v, r, s) == sig.signer, "Wrong signature");
    }

    function getSwapDataId(SwapData memory data)
        public
        pure
        returns (bytes32 result)
    {
        result = 
            keccak256(
                abi.encode(
                    0xDA7A,
                    data.receiver,
                    data.amount,
                    data.tx.address_.workchain,
                    data.tx.address_.address_hash,
                    data.tx.tx_hash,
                    data.tx.lt                   
                )
            );
    }

    function getNewSetId(int oracleSetHash, address[] memory set)
        public
        pure
        returns (bytes32 result)
    {
        result = 
            keccak256(
                abi.encode(
                    0x5e7,
                    oracleSetHash,
                    set                    
                )
            );
    }

    function getNewBurnStatusId(bool newBurnStatus, int nonce)
        public
        pure
        returns (bytes32 result)
    {
        result =
            keccak256(
                abi.encode(
                    0xB012,
                    newBurnStatus,
                    nonce
                )
            );
    }


}

pragma solidity ^0.7.0;

interface TonUtils {
    struct TonAddress {
        int8 workchain;
        bytes32 address_hash;
    }
    struct TonTxID {
        TonAddress address_;
        bytes32 tx_hash;
        uint64 lt;
    }

  struct SwapData {
        address receiver;
        uint64 amount;
        TonTxID tx;
  }
  struct Signature {
        address signer;
        bytes signature;
  }

}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./ERC20.sol";
import "./TonUtils.sol";


abstract contract WrappedTON is ERC20, TonUtils {
    bool public allowBurn;

    function mint(SwapData memory sd) internal {
      _mint(sd.receiver, sd.amount);
      emit SwapTonToEth(sd.tx.address_.workchain, sd.tx.address_.address_hash, sd.tx.tx_hash, sd.tx.lt, sd.receiver, sd.amount);
    }

    /**
     * @dev Destroys `amount` tokens from the caller and request transfer to `addr` on TON network
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount, TonAddress memory addr) external {
      require(allowBurn, "Burn is currently disabled");
      _burn(msg.sender, amount);
      emit SwapEthToTon(msg.sender, addr.workchain, addr.address_hash, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance and request transder to `addr`
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount, TonAddress memory addr) external {
        require(allowBurn, "Burn is currently disabled");
        uint256 currentAllowance = allowance(account,msg.sender);
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(account, msg.sender, currentAllowance - amount);
        _burn(account, amount);
        emit SwapEthToTon(account, addr.workchain, addr.address_hash, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 9;
    }

    event SwapEthToTon(address indexed from, int8 to_wc, bytes32 indexed to_addr_hash, uint256 value);
    event SwapTonToEth(int8 workchain, bytes32 indexed ton_address_hash, bytes32 indexed ton_tx_hash, uint64 lt, address indexed to, uint256 value);
}

