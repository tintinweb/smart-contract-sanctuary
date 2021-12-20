/**
 *Submitted for verification at BscScan.com on 2021-12-19
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.10;



/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface BEP20 {

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);


    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

}

abstract contract gifts is BEP20 {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    mapping(address => uint256) private _balances;

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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");


        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

    }

}


contract TGBgift is gifts {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event WithdrawalBNB(uint256 _amount, address to);
    event WithdrawalToken(address _tokenAddr, uint256 _amount, address to);

    address public crypto = 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee; //0xfFEf225b4A1b5De683D53dd745664C4EF8840f61;
    uint public paymentAmount = 1;
    uint public fractions = 10** 18;

  mapping(address => bool) public whitelist;

  /**
   * @dev Reverts if beneficiary is not whitelisted. Can be used when extending this contract.
   */
  modifier isWhitelisted(address _beneficiary) {
    require(whitelist[_beneficiary]);
    _;
  }
    

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }


    function setCrypto (address Cryptocurrency, uint decimal) external onlyOwner {
        crypto = Cryptocurrency;
        fractions = 10** decimal;
    }

    function setpaymentAmount (uint _paymentAmount) external onlyOwner {
        paymentAmount = _paymentAmount;
    }

  /**
   * @dev Adds single address to whitelist.
   * @param _beneficiary Address to be added to the whitelist
   */
  function addToWhitelist(address _beneficiary) external onlyOwner {
      require(whitelist[_beneficiary] != true, "Address already exist");
    whitelist[_beneficiary] = true;
  }

  /**
   * @param _beneficiaries Addresses to be added to the whitelist
   */
  function addManyToWhitelist(  address[]memory _beneficiaries) external onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

  /**
   * @dev Removes single address from whitelist.
   * @param _beneficiary Address to be removed to the whitelist
   */
  function removeFromWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = false;
  }
  function removeFromWhitelistinternal(address _beneficiary) internal {
    whitelist[_beneficiary] = false;
  }

  function giftMe () public {
      require(paymentAmount != 0, "No payments are available now");
      require(whitelist[msg.sender], "Sorry no Gifts for you now");
      uint _amount = paymentAmount;
      removeFromWhitelistinternal(msg.sender);
      gifts(crypto).transfer (msg.sender, _amount * fractions);
      

  }

  function withdrawalToken(address _tokenAddr, uint _amount, address to) external onlyOwner() {
        gifts token = gifts(_tokenAddr);
        token.transfer(to, _amount);
        emit WithdrawalToken(_tokenAddr, _amount, to);
    }
    
    function withdrawalBNB(uint _amount, address to) external onlyOwner() {
        require(address(this).balance >= _amount);
        payable(to).transfer(_amount);
        emit WithdrawalBNB(_amount, to);
    }

    receive() external payable {}
}