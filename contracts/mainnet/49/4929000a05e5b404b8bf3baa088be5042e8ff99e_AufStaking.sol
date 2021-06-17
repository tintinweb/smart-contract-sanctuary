/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.5.0 <0.7.0;

contract Ownable {
    
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () public {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
    }
}


library SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


interface ERC20{
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address _tokenOwner) external view returns (uint256);
    function allowance(address _tokenOwner, address _spender) external view returns (uint256);
    function transfer(address _to, uint256 _tokens) external returns (bool);
    function approve(address _spender, uint256 _tokens)  external returns (bool);
    function transferFrom(address _from, address _to, uint256 _tokens) external returns (bool);
    
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    
}




contract AufToken is Ownable, ERC20{
    
    using SafeMath for uint256;

    string _name;
    string  _symbol;
    uint256 _totalSupply;
    uint256 _decimal;
    
    mapping(address => uint256) _balances;
    mapping(address => mapping (address => uint256)) _allowances;
    
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    
    constructor() public {
        _name = "Amongus.finance";
        _symbol = "AMONG";
        _decimal = 18;
        _totalSupply = 21000000 * 10 ** _decimal;
        _balances[0xf2596513BccbCbF318d5A18AF9A8A24EA589D0C7] = _totalSupply;
        emit Transfer(address(0), 0xf2596513BccbCbF318d5A18AF9A8A24EA589D0C7, _totalSupply);
    }
    
    
    function name() public view returns (string memory) {
        return _name;
    }
    
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view returns (uint256) {
        return _decimal;
    }
    
    function totalSupply() external view  override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address _tokenOwner) external view override returns (uint256) {
        return _balances[_tokenOwner];
    }
    
    function transfer(address _to, uint256 _tokens) external override returns (bool) {
        _transfer(msg.sender, _to, _tokens);
        return true;
    }
    
    function _transfer(address _sender, address _recipient, uint256 _amount) internal {
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(_recipient != address(0), "ERC20: transfer to the zero address");

        _balances[_sender] = _balances[_sender].safeSub(_amount);
        _balances[_recipient] = _balances[_recipient].safeAdd(_amount);
        emit Transfer(_sender, _recipient, _amount);
    }
    
    function allowance(address _tokenOwner, address _spender) external view override returns (uint256) {
        return _allowances[_tokenOwner][_spender];
    }
    
    function approve(address _spender, uint256 _tokens) external override returns (bool) {
        _approve(msg.sender, _spender, _tokens);
        return true;
    }
    
    function _approve(address _owner, address _spender, uint256 _value) internal {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        _allowances[_owner][_spender] = _value;
        emit Approval(_owner, _spender, _value);
    }
    
    
    function transferFrom(address _from, address _to, uint256 _tokens) external override returns (bool) {
        _transfer(_from, _to, _tokens);
        _approve(_from, msg.sender, _allowances[_from][msg.sender].safeSub(_tokens));
        return true;
    }
    receive () external payable {
        revert();
    }

}

contract AufStaking {
    string public name = "Stake AMONG";
    address public owner;
    AufToken public aufToken;

    address[] public stakers;
    mapping(address => uint) public stakingBalance;
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public isStaking;

    constructor(AufToken _aufToken) public {
        aufToken = _aufToken;
        
        owner = msg.sender;
    }

    function stakeTokens(uint _amount) public {
        // Require amount greater than 0
        require(_amount > 0, "amount cannot be 0");

        // Trasnfer Auf tokens to this contract for staking
        aufToken.transferFrom(msg.sender, address(this), _amount);

        // Update staking balance
        stakingBalance[msg.sender] = stakingBalance[msg.sender] + _amount;

        // Add user to stakers array *only* if they haven't staked already
        if(!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
        }

        // Update staking status
        isStaking[msg.sender] = true;
        hasStaked[msg.sender] = true;
    }

    // Unstaking Tokens (Withdraw)
    function unstakeTokens() public {
        // Fetch staking balance
        uint balance = stakingBalance[msg.sender];

        // Require amount greater than 0
        require(balance > 0, "staking balance cannot be 0");

        // Transfer Auf tokens to this contract for staking
        aufToken.transfer(msg.sender, balance);

        // Reset staking balance
        stakingBalance[msg.sender] = 0;

        // Update staking status
        isStaking[msg.sender] = false;
    }

    // Issuing Tokens
    function issueTokens_10() public {
        // Only owner can call this function
        require(msg.sender == owner, "caller must be the owner");

        // Issue tokens to all stakers
        for (uint i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint balance = stakingBalance[recipient];
            if(balance > 0) {
                aufToken.transfer(recipient, balance * 10 / 100);
            }
        }
    }
    function issueTokens_5() public {
        // Only owner can call this function
        require(msg.sender == owner, "caller must be the owner");

        // Issue tokens to all stakers
        for (uint i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint balance = stakingBalance[recipient];
            if(balance > 0) {
                aufToken.transfer(recipient, balance * 5 / 100);
            }
        }
    }
     function issueTokens_1() public {
        // Only owner can call this function
        require(msg.sender == owner, "caller must be the owner");

        // Issue tokens to all stakers
        for (uint i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint balance = stakingBalance[recipient];
            if(balance > 0) {
                aufToken.transfer(recipient, balance * 1 / 100);
            }
        }
    }
}