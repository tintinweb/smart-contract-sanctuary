// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./BEP20Mintable.sol";
import "./BEP20Burnable.sol";
import "./BEP20Fee.sol";

/**
 * @title XBEP20
 * @dev Implementation of the XBEP20
 */
contract XBEP20 is BEP20Mintable, BEP20Burnable, BEP20Fee {

    uint public _active_status = 2;

    // blacklisted addressed can not send, receive tokens and tokens cannot be minted to this address.
    mapping (address => bool) public _blacklist;

    constructor (
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 initialBalance
    )
        BEP20(name, symbol)
        payable
    {
        _setupDecimals(decimals);
        _mint(_msgSender(), initialBalance);
    }

    modifier notFrozen() {
        require(_active_status != 0, "Transfers have been frozen.");
        _;
    }

    function active_status() public view returns(uint) {
        return _active_status;
    }

    /**
     * @dev Function to mint tokens.
     *
     * NOTE: restricting access to owner only. See {BEP20Mintable-mint}.
     *
     * @param account The address that will receive the minted tokens
     * @param amount The amount of tokens to mint
     */
    function _mint(address account, uint256 amount) internal override(BEP20) notFrozen onlyOwner {
        require(_blacklist[account] != true, "account is blacklisted");
        super._mint(account, amount);
    }

     /**
     * @dev See {BEP20Fee-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20}.
     * Take transaction fee from sender and transfer fee to the transaction fee wallet.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override(BEP20, BEP20Fee) notFrozen returns (bool) {
        require(_blacklist[sender] != true, "sender is blacklisted");
        require(_blacklist[recipient] != true, "recipient is blacklisted");
        return super.transferFrom(sender, recipient, amount);
    }

         /**
     * @dev See {BEP20Fee-transferFromByOwner}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20}.
     * Take transaction fee from sender and transfer fee to the transaction fee wallet.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFromByOwner(address sender, address recipient, uint256 amount) public notFrozen onlyOwner returns (bool) {
        require(_blacklist[sender] != true, "sender is blacklisted");
        require(_blacklist[recipient] != true, "recipient is blacklisted");
                _transfer(sender, recipient, amount);

        uint256 currentAllowance = allowance(sender, _msgSender());
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev See {BEP20Fee-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override(BEP20, BEP20Fee) notFrozen returns (bool) {
        require(_blacklist[msg.sender] != true, "You are blacklisted.");
        require(_blacklist[recipient] != true, "Recipient is blacklisted.");
        return super.transfer(recipient, amount);
    }

    event Set_Active_Status(
        uint status
    );

    function set_active_status(uint status) public onlyOwner { 
        _active_status = status;
        emit Set_Active_Status(status);
    }

    event Add_To_Blacklist(
        address address_banned
    );

    /**
     * @dev add address to blacklist.
     */
    function add_to_blacklist(address addr) public onlyOwner {
        _blacklist[addr] = true;
        emit Add_To_Blacklist(addr);
    }
    
    /**
     * @dev blacklist status.
     */
    function check_blacklist(address addr) public view returns(bool) {
        return _blacklist[addr];
    }

    event Remove_From_Blacklist(
        address address_banned
    );

    /**
     * @dev add address to blacklist.
     */
    function remove_from_blacklist(address addr) public onlyOwner {
        _blacklist[addr] = false;
        emit Remove_From_Blacklist(addr);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../lib/BEP20.sol";

/**
 * @title BEP20Mintable
 * @dev Implementation of the BEP20Mintable. Extension of {BEP20} that adds a minting behaviour.
 */
abstract contract BEP20Mintable is BEP20 {

    // indicates if minting is finished
    bool private _mintingFinished = false;

    /**
     * @dev Emitted during finish minting
     */
    event MintFinished();

    /**
     * @dev Tokens can be minted only before minting finished.
     */
    modifier canMint() {
        require(!_mintingFinished, "BEP20Mintable: minting is finished");
        _;
    }

    /**
     * @return if minting is finished or not.
     */
    function mintingFinished() public view returns (bool) {
        return _mintingFinished;
    }

    /**
     * @dev Function to mint tokens.
     *
     * WARNING: it allows everyone to mint new tokens. Access controls MUST be defined in derived contracts.
     *
     * @param account The address that will receive the minted tokens
     * @param amount The amount of tokens to mint
     */
    function mint(address account, uint256 amount) public canMint {
        _mint(account, amount);
    }

    /**
     * @dev Function to stop minting new tokens.
     *
     * WARNING: it allows everyone to finish minting. Access controls MUST be defined in derived contracts.
     */
    // function finishMinting() public canMint {
    //     _finishMinting();
    // }

    /**
     * @dev Function to stop minting new tokens.
     */
    // function _finishMinting() internal virtual {
    //     _mintingFinished = true;

    //     emit MintFinished();
    // }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./BEP20.sol";

/**
 * @dev Extension of {BEP20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract BEP20Burnable is BEP20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {BEP20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {BEP20-_burn} and {BEP20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
      uint256 currentAllowance = allowance(account, _msgSender());
      require(currentAllowance >= amount, "BEP20: burn amount exceeds allowance");
      _approve(account, _msgSender(), currentAllowance - amount);
      _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./BEP20.sol";

/**
 * @title BEP20Fee
 * @dev Implementation of the BEP20Fee. Extension of {BEP20} that adds a fee transaction behaviour.
 */
abstract contract BEP20Fee is BEP20 {
    
    // transaction fee
    uint public _transaction_fee = 0;
    uint public _transaction_fee_cap = 0;

    // ubi tax
    uint public _ubi_tax = 0;
    // transaction fee wallet
    uint public _referral_fee = 0;
    uint public _referrer_amount_threshold = 0;
    uint public _cashback = 0;
    // transaction fee decimal 
    uint public constant _fee_decimal = 8;
    
    struct Colony {
         uint128 _level;
         uint128 _transaction_tax;
         bytes32 _policy_hash;
         string _policy_link;
    }

    address public _tx_fee_wallet;
    address public _ubi_tax_wallet;
    address public _jaxcorp_dao_wallet;
    
    mapping (address => address) public _referrers;
    mapping (address => address) public _mother_colony_addresses;
    mapping (address => address) public _user_colony_addresses;
    mapping (address => Colony) public _colonies;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor () {
        _tx_fee_wallet = msg.sender;
        _jaxcorp_dao_wallet = msg.sender;
        _ubi_tax_wallet = msg.sender;
    }

    event Set_Transaction_Fee(
        uint transaction_fee,
        uint trasnaction_fee_cap,
        address transaction_fee_wallet
    );

    /**
     * @dev Function to set transaction fee.
     * @param tx_fee transaction fee
     */
    function setTransactionFee(uint tx_fee, uint tx_fee_cap, address wallet) public onlyOwner {
        require(tx_fee <= 10 ** _fee_decimal * 3 / 100 , "Tx Fee percent can't be more than 3.");
        _transaction_fee = tx_fee;
        _transaction_fee_cap = tx_fee_cap;
        _tx_fee_wallet = wallet;
        emit Set_Transaction_Fee(tx_fee, tx_fee_cap, wallet);
    }

    event Set_Ubi_Tax(
        uint ubi_tax,
        address ubi_tax_wallet
    );

    /**
     * @dev Set ubi tax and ubi tax wallet
     */
    function setUbiTax(uint ubi_tax, address wallet) public onlyOwner {
        require(ubi_tax <= 10 ** _fee_decimal * 100 / 100 , "UBI tax can't be more than 100.");
        _ubi_tax = ubi_tax;
        _ubi_tax_wallet = wallet;
        emit Set_Ubi_Tax(ubi_tax, wallet);
    }

    event Register_Colony(
        address colony_public_key,
        uint128 tx_tax,
        string colony_policy_link,
        bytes32 colony_policy_hash,
        address mother_colony_public_key 
    );

    /**
     * @dev Register Colony
     * @param colony_public_key colony wallet address
     * @param tx_tax transaction fee for colony
     * @param colony_policy_link policy link
     * @param colony_policy_hash policy hash
     * @param mother_colony_public_key wallet address of mother colony of this colony.
     */
    function registerColony(address colony_public_key, uint128 tx_tax, string memory colony_policy_link, bytes32 colony_policy_hash, address mother_colony_public_key) public onlyOwner {
        require(tx_tax <= (10 ** _fee_decimal) * 20 / 100, "Tx tax can't be more than 20%");
        require(colony_public_key != mother_colony_public_key, "Mother colony can't be set");
        require(_user_colony_addresses[colony_public_key] == address(0), "User can't be a colony");
        
        if (_colonies[mother_colony_public_key]._level == 0) {
            _mother_colony_addresses[colony_public_key] = address(0);
            _colonies[colony_public_key]._level = 2;
        } else {
            if (_colonies[mother_colony_public_key]._level < _colonies[colony_public_key]._level || _colonies[colony_public_key]._level == 0) {
                _mother_colony_addresses[colony_public_key] = mother_colony_public_key;
                _colonies[colony_public_key]._level = _colonies[mother_colony_public_key]._level + 1;
            }
        }
       
        _colonies[colony_public_key]._transaction_tax = tx_tax;
        _colonies[colony_public_key]._policy_link = colony_policy_link;
        _colonies[colony_public_key]._policy_hash = colony_policy_hash;
        emit Register_Colony(colony_public_key, tx_tax, colony_policy_link, colony_policy_hash, mother_colony_public_key);
    }

    function getColonyInfo(address addr) public view returns(Colony memory, address){
        
        address mother_colony_address = _mother_colony_addresses[addr];
        
        return (_colonies[addr], mother_colony_address);
    }

    function getUserColonyInfo(address addr) public view returns(address){
        
        return (_user_colony_addresses[addr]);

    }

    event Set_Colony_Address(
        address addr,
        address colony
    );

    /**
     * @dev Set colony address for the addr
     */
    function setColonyAddress(address addr,address colony) public onlyOwner {
        require(_mother_colony_addresses[addr] == address(0), "Colony can't be a user");
        require(addr != colony && _colonies[colony]._level != 0, "Mother Colony is invalid");
        _user_colony_addresses[addr] = colony;
        emit Set_Colony_Address(addr, colony);
    }

    event Set_Jax_Corp_Dao(
        address jaxCorpDao_wallet,
        uint128 tx_tax,
        string policy_link,
        bytes32 policy_hash
    );

    function setJaxCorpDAO(address jaxCorpDao_wallet, uint128 tx_tax, string memory policy_link, bytes32 policy_hash) public onlyOwner {
        require(tx_tax <= (10 ** _fee_decimal) * 20 / 100, "Tx tax can't be more than 20%");
        _jaxcorp_dao_wallet = jaxCorpDao_wallet;

        _colonies[address(0)]._transaction_tax = tx_tax;
        _colonies[address(0)]._policy_link = policy_link;
        _colonies[address(0)]._policy_hash = policy_hash;
        _colonies[address(0)]._level = 1;

        emit Set_Jax_Corp_Dao(jaxCorpDao_wallet, tx_tax, policy_link, policy_hash);
    }

    event Set_Referral_Fee(
        uint referral_fee, 
        uint referral_amount_threshold
    );

    /**
     * @dev Set referral fee and minimum amount that can set sender as referrer
     */
    function setReferralFee(uint referral_fee, uint referral_amount_threshold) public onlyOwner {
        require(_referral_fee <= 10 ** _fee_decimal * 50 / 100 , "Referral Fee percent can't be more than 50.");
        _referral_fee = referral_fee;
        _referrer_amount_threshold = referral_amount_threshold;
        emit Set_Referral_Fee(referral_fee, referral_amount_threshold);
    }

    event Set_Cashback(
        uint cashback_percent
    );

    /**
     * @dev Set cashback
     */
    function setCashback(uint cashback_percent) public onlyOwner {
        require(cashback_percent <= 10 ** _fee_decimal * 30 / 100 , "Cashback percent can't be more than 30.");
        _cashback = cashback_percent;
        emit Set_Cashback(cashback_percent);
    }
    
    /**
     * @dev Returns the referrer of address
     */
    function referrerOf(address sender) public view returns (address) {
        return _referrers[sender];
    }

    /**
     * @dev See {IBEP20-transferFrom}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {

        if(_referrers[msg.sender] == address(0)) {
            _referrers[msg.sender] = address(0xdEaD);
        }

        uint fee_decimals = (10 ** _fee_decimal);

        // Calculate transaction fee
        uint tx_fee_amount = amount * _transaction_fee / fee_decimals;

        if(tx_fee_amount > _transaction_fee_cap) {
            tx_fee_amount = _transaction_fee_cap;
        }
        
        address referrer = _referrers[recipient];
        uint total_referral_fees = 0;
        uint max_referral_fee = tx_fee_amount * _referral_fee;
        // Transfer referral fees to referrers (70% to first referrer, each 10% to other referrers)
        if( max_referral_fee > 0 && referrer != address(0xdEaD) && referrer != address(0)){

            super.transfer(referrer, 70 * max_referral_fee / fee_decimals / 100);
            referrer = _referrers[referrer];
            total_referral_fees += 70 * max_referral_fee / fee_decimals / 100;
            if( referrer != address(0xdEaD) && referrer != address(0)){
                super.transfer(referrer, 10 * max_referral_fee / fee_decimals / 100);
                referrer = _referrers[referrer];
                total_referral_fees += 10 * max_referral_fee / fee_decimals / 100;
                if( referrer != address(0xdEaD) && referrer != address(0)){
                    super.transfer(referrer, 10 * max_referral_fee / fee_decimals / 100);
                    referrer = _referrers[referrer];
                    total_referral_fees += 10 * max_referral_fee / fee_decimals / 100;
                    if( referrer != address(0xdEaD) && referrer != address(0)){
                        super.transfer(referrer, 10 * max_referral_fee / fee_decimals / 100);
                        referrer = _referrers[referrer];
                        total_referral_fees += 10 * max_referral_fee / fee_decimals / 100;
                    }
                }
            }
        }

        // Transfer transaction fee to transaction fee wallet
        // Sender will get cashback.
        if( tx_fee_amount > 0){
            super.transfer(_tx_fee_wallet, tx_fee_amount - total_referral_fees - (tx_fee_amount * _cashback / fee_decimals));
        }
        
        //Transfer of UBI Tax        
        uint ubi_tax_amount = amount * _ubi_tax / fee_decimals;
        if(ubi_tax_amount > 0){
            super.transfer(_ubi_tax_wallet, ubi_tax_amount);  // ubi tax
        }

        address colony_address = _user_colony_addresses[recipient];

        if(colony_address == address(0)) {
            colony_address = _mother_colony_addresses[recipient];
        }

        // Transfer transaction tax to colonies.
        // immediate colony will get 50% of transaction tax, mother of that colony will get 25% ... mother of 4th colony will get 3.125%
        // 3.125% of transaction tax will go to JaxCorp Dao public key address.
        uint tx_tax_amount = amount * _colonies[colony_address]._transaction_tax / fee_decimals;     // Calculate transaction tax amount
        
        // transferTransactionTax(_mother_colony_addresses[recipient], tx_tax_amount, 1);          // Transfer tax to colonies and jaxCorp Dao
        // Optimize transferTransactionTax by using loop instead of recursive function

        if( tx_tax_amount > 0 ){
            uint level = 1;
            uint tx_tax_temp = tx_tax_amount;
            

            // Level is limited to 5
            while( colony_address != address(0) && level++ <= 5 ){
                super.transfer(colony_address, tx_tax_temp / 2);
                colony_address = _mother_colony_addresses[colony_address];
                tx_tax_temp = tx_tax_temp / 2;            
            }

            // transfer remain tx_tax to jaxcorpDao
            super.transfer(_jaxcorp_dao_wallet, tx_tax_temp);
        }

        // Transfer tokens to recipient. recipient will pay the fees.
        require( amount > (tx_fee_amount + ubi_tax_amount + tx_tax_amount), "Total fee is greater than the transfer amount");
        super.transfer(recipient, amount - tx_fee_amount - ubi_tax_amount - tx_tax_amount);

        // set _referrers as first sender when transferred amount exceeds the certain limit.
        // recipient mustn't be sender's referrer, recipient couldn't be referrer itself
        if( recipient != msg.sender  && amount >= _referrer_amount_threshold  && _referrers[recipient] == address(0)) {
            _referrers[recipient] = msg.sender;

        }
        return true;
    } 

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {

        if(_referrers[sender] == address(0)) {
            _referrers[sender] = address(0xdEaD);
        }

        uint fee_decimals = (10 ** _fee_decimal);

        // Calculate transaction fee
        uint tx_fee_amount = amount * _transaction_fee / fee_decimals;

        if(tx_fee_amount > _transaction_fee_cap) {
            tx_fee_amount = _transaction_fee_cap;
        }
        
        address referrer = _referrers[recipient];
        uint total_referral_fees = 0;
        uint max_referral_fee = tx_fee_amount * _referral_fee;
        // Transfer referral fees to referrers (70% to first referrer, each 10% to other referrers)
        if( max_referral_fee > 0 && referrer != address(0xdEaD) && referrer != address(0)){

            super.transferFrom(sender, referrer, 70 * max_referral_fee / fee_decimals / 100);
            referrer = _referrers[referrer];
            total_referral_fees += 70 * max_referral_fee / fee_decimals / 100;
            if( referrer != address(0xdEaD) && referrer != address(0)){
                super.transferFrom(sender, referrer, 10 * max_referral_fee / fee_decimals / 100);
                referrer = _referrers[referrer];
                total_referral_fees += 10 * max_referral_fee / fee_decimals / 100;
                if( referrer != address(0xdEaD) && referrer != address(0)){
                    super.transferFrom(sender, referrer, 10 * max_referral_fee / fee_decimals / 100);
                    referrer = _referrers[referrer];
                    total_referral_fees += 10 * max_referral_fee / fee_decimals / 100;
                    if( referrer != address(0xdEaD) && referrer != address(0)){
                        super.transferFrom(sender, referrer, 10 * max_referral_fee / fee_decimals / 100);
                        referrer = _referrers[referrer];
                        total_referral_fees += 10 * max_referral_fee / fee_decimals / 100;
                    }
                }
            }
        }

        // Transfer transaction fee to transaction fee wallet
        // Sender will get cashback.
        if( tx_fee_amount > 0){
            super.transferFrom(sender, _tx_fee_wallet, tx_fee_amount - total_referral_fees - (tx_fee_amount * _cashback / fee_decimals));
        }
        
        //Transfer of UBI Tax        
        uint ubi_tax_amount = amount * _ubi_tax / fee_decimals;
        if(ubi_tax_amount > 0){
            super.transferFrom(sender, _ubi_tax_wallet, ubi_tax_amount);  // ubi tax
        }

        address colony_address = _user_colony_addresses[recipient];

        if(colony_address == address(0)) {
            colony_address = _mother_colony_addresses[recipient];
        }

        // Transfer transaction tax to colonies.
        // immediate colony will get 50% of transaction tax, mother of that colony will get 25% ... mother of 4th colony will get 3.125%
        // 3.125% of transaction tax will go to JaxCorp Dao public key address.
        uint tx_tax_amount = amount * _colonies[colony_address]._transaction_tax / fee_decimals;     // Calculate transaction tax amount
        
        // transferTransactionTax(_mother_colony_addresses[recipient], tx_tax_amount, 1);          // Transfer tax to colonies and jaxCorp Dao
        // Optimize transferTransactionTax by using loop instead of recursive function

        if( tx_tax_amount > 0 ){
            uint level = 1;
            uint tx_tax_temp = tx_tax_amount;
            

            // Level is limited to 5
            while( colony_address != address(0) && level++ <= 5 ){
                super.transferFrom(sender, colony_address, tx_tax_temp / 2);
                colony_address = _mother_colony_addresses[colony_address];
                tx_tax_temp = tx_tax_temp / 2;            
            }

            // transfer remain tx_tax to jaxcorpDao
            super.transferFrom(sender, _jaxcorp_dao_wallet, tx_tax_temp);
        }

        // Transfer tokens to recipient. recipient will pay the fees.
        super.transferFrom(sender, recipient, amount - tx_fee_amount - ubi_tax_amount - tx_tax_amount);

        // set _referrers as first sender when transferred amount exceeds the certain limit.
        // recipient mustn't be sender's referrer, recipient couldn't be referrer itself
        if( recipient != sender  && amount >= _referrer_amount_threshold  && _referrers[recipient] == address(0)) {
            _referrers[recipient] = sender;

        }
        return true;
    } 


}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./IBEP20.sol";

/**
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of BEP20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IBEP20-approve}.
 */
contract BEP20 is Ownable, IBEP20 {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {BEP20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IBEP20-balanceOf} and {IBEP20-transfer}.
     */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IBEP20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IBEP20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IBEP20-getOwner}.
     */
    function getOwner() public view override returns (address) {
        return owner();
    }

    /**
     * @dev See {IBEP20-transfer}.
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
     * @dev See {IBEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20}.
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

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev See {IBEP20-approve}.
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
     * @dev See {IBEP20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IBEP20-approve}.
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
     * problems described in {IBEP20-approve}.
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
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
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
        require(account != address(0), "BEP20: mint to the zero address");

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
        require(account != address(0), "BEP20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "BEP20: burn amount exceeds balance");
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
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @dev Interface of the BEP standard.
 */
interface IBEP20 {

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

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