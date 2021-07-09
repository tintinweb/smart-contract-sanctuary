/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

pragma solidity >=0.5.0 <0.7.0;

// Ownable contract from open zepplin

contract Ownable {
    
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */


    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
    }
}


// safemath library for addition and subtraction

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


// erc20 interface

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


// contract

contract B26_SwapToken is Ownable, ERC20{
    
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
        _name = "B26 to BYB";
        _symbol = "B26BYB";
        _decimal = 18;
        _totalSupply = 26000 * 10 ** _decimal;
        _balances[msg.sender] = _totalSupply;
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
    // don't accept eth
    receive () external payable {
        revert();
    }

}