/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library MySafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            revert();
        }
        c = a * b;
        require(c / a == b);
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
abstract contract MyERC20Interface {
    function totalSupply() external virtual view returns (uint256);
    function balanceOf(address _tokenOwner) external virtual view returns (uint256 balance);
    function allowance(address _tokenOwner, address _spender) external virtual view returns (uint256 remaining);
    function transfer(address _to, uint256 _tokens) external virtual;
    function approve(address _spender, uint256 _tokens) external virtual;
    function transferFrom(address _from, address _to, uint256 _tokens) external virtual;
    event Transfer(address indexed _from, address indexed _to, uint256 _tokens);
    event Approval(address indexed _tokenOwner, address indexed _spender, uint256 _tokens);
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
abstract contract MyOwned {
    address internal owner_;
    address internal newOwner_;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner_ = msg.sender;
    }

    function owner() external view returns (address) {
        return owner_;
    }    

    function transferOwnership(address _newOwner) external {
        require(msg.sender == owner_);
        newOwner_ = _newOwner;
    }

    function acceptOwnership() external {
        require(msg.sender == newOwner_);
        emit OwnershipTransferred(owner_, newOwner_);
        owner_ = newOwner_;
        newOwner_ = address(0);
    }
}

/**
 * The /**
  * The Delegated contract allows a set of delegate accounts
  * to perform special tasks such as admin tasks to the contract
  */
 contract MyDelegated is MyOwned {
    mapping (address => bool) delegates;
    
    event DelegateChanged(address delegate, bool state);

    constructor() {
    }

    fallback() external {
    }

    function checkDelegate(address _user) internal view {
        require(_user == owner_ || delegates[_user]);
    }
    
    function checkOwner(address _user) internal view {
        require(_user == owner_);
    }
    
    function setDelegate(address _address, bool _state) external {
        checkDelegate(msg.sender);

        delegates[_address] = _state;
        
        emit DelegateChanged(_address, _state);
    }
 
    function isDelegate(address _account) external view returns (bool delegate)  {
        return (_account == owner_ || delegates[_account]);
    }
 }

// ----------------------------------------------------------------------------
// NFTStore.Top Token
// ----------------------------------------------------------------------------
contract NFTStoreTopToken is MyERC20Interface, MyDelegated {
    using MySafeMath for uint256;

    string internal name_ = "NFTStore.Top"; 
    string internal symbol_ = "NFTS";
    uint256 internal  decimals_ = 18;
    uint256 internal  totalSupply_ = 0;
    bool internal halted_ = false;

    mapping(address => uint256) internal balances_;
    mapping(address => mapping(address => uint256)) internal allowed_;

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() {
    }

    function name() external view returns (string memory) {
        return name_;
    }

    function symbol() external view returns (string memory) {
        return symbol_;
    }

    function decimals() external view returns (uint8) {
        return uint8(decimals_);
    }

    function mint(address _to, uint256 _amount) external {
        checkDelegate(msg.sender);
        require(_to != address(0));
        require(_amount > 0);

        balances_[_to] = balances_[_to].add(_amount);
        totalSupply_ = totalSupply_.add(_amount);
        emit Transfer(address(0), _to, _amount);
    }

    function burn(address _to, uint256 _amount) external {
        checkDelegate(msg.sender);
        require(_amount > 0);

        balances_[_to] = balances_[_to].sub(_amount);
        totalSupply_ = totalSupply_.sub(_amount);
        emit Transfer(_to, address(0), _amount);
    }

    // ------------------------------------------------------------------------
    // Set the halted tag when the emergent case happened
    // ------------------------------------------------------------------------
    function setEmergentHalt(bool _tag) external {
        checkOwner(msg.sender);
        halted_ = _tag;
    }

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() external override view returns (uint256) {
        return totalSupply_;
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address _tokenOwner) external override view returns (uint256) {
        return balances_[_tokenOwner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address _to, uint256 _tokens) external override {
        require(!halted_);

        balances_[msg.sender] = balances_[msg.sender].sub(_tokens);
        balances_[_to] = balances_[_to].add(_tokens);

        emit Transfer(msg.sender, _to, _tokens);
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address _spender, uint256 _tokens) external override {
        require(_spender != msg.sender);

        allowed_[msg.sender][_spender] = _tokens;

        emit Approval(msg.sender, _spender, _tokens);
    }

    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address _from, address _to, uint256 _tokens) external override {
        require(!halted_);

        allowed_[_from][msg.sender] = allowed_[_from][msg.sender].sub(_tokens);
        balances_[_from] = balances_[_from].sub(_tokens);
        balances_[_to] = balances_[_to].add(_tokens);

        emit Transfer(_from, _to, _tokens);
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address _tokenOwner, address _spender) external override view returns (uint256) {
        return allowed_[_tokenOwner][_spender];
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address _tokenAddress, uint256 _tokens) external {
        checkOwner(msg.sender);
        MyERC20Interface(_tokenAddress).transfer(owner_, _tokens);
    }
}