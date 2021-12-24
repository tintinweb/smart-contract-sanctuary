/**
 *Submitted for verification at BscScan.com on 2021-12-24
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface GameItems is IERC165 {

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

interface Rupee {

    function balanceOf(address account) external view returns (uint);

    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

interface IERC20 {
    
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);
}


interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata, Ownable {

    Rupee private rupee;
    GameItems private nft;
    
    mapping(address => uint) _tokenStaked;
    mapping(address => uint) _tokenamount;
    mapping(address => bool) _hasStaked;
    mapping(address => uint) private _balances;
    uint private _totalSupply;
    string private _name;
    string private _symbol;
    uint private time;
    mapping(address => uint) _buyTime;
    
    constructor(string memory name_, string memory symbol_, address _rupee, address nftaddress){
        _name = name_;
        _symbol = symbol_;
        rupee = Rupee(_rupee);
        nft = GameItems(nftaddress);
    }
    
    function name() public view virtual override returns(string memory){
        return _name;
    }
    
    function symbol() public view virtual override returns(string memory){
        return _symbol;
    }
    
    function decimals() public view virtual override returns(uint){
        return 0;
    }
    
    function totalSupply() public view virtual override returns(uint){
        return _totalSupply;
    }
    
    function balanceOf(address account) public view virtual override returns(uint){
        return _balances[account];
    }

    function setTimeLock(uint _time) public onlyOwner(){
        time = _time;
    }

    function _mint(address account, uint amount) internal virtual{
        require(account != address(0), "ERC20: mint to the zero address");
        
        _beforeTokenTransfer(address(0), account, amount);
        
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        
        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint amount) internal virtual{
        require(account != address(0), "ERC20: burn from the zero address");
        
        _beforeTokenTransfer(account, address(0), amount);
        
        uint accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked{
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        
        _afterTokenTransfer(account, address(0), amount);
    }

    function stakenft(uint tokenid, uint amount) public returns(bool){
        nft.safeTransferFrom(_msgSender(), owner(), tokenid, amount, "");
        _tokenStaked[_msgSender()] = tokenid;
        _tokenamount[_msgSender()] = amount;
        _hasStaked[_msgSender()] = true;
        return true;
    }

    function buy(uint amount) public returns(bool){
        uint payamount = amount*10000*1000000000000000000;
        if(_hasStaked[_msgSender()]){
            uint discount = (payamount*20)/100;
            payamount -= discount;
        }
        require(rupee.balanceOf(msg.sender) >= payamount, "Oops! You dont have enough Rupees");
        rupee.transferFrom(msg.sender, owner(), payamount);
        _mint(_msgSender(), amount);
        _buyTime[_msgSender()] = block.timestamp;
        return true;
    }

    function sell(uint amount) public returns(bool){
        require(balanceOf(msg.sender) >= amount, "Oops! You dont have enough Lots");
        require(_buyTime[_msgSender()] + time <= block.timestamp, "Sorry! Your INR tokens are locked for the time being");
        _burn(_msgSender(), amount);
        uint payamount = amount*10000*1000000000000000000;
        if(_hasStaked[_msgSender()]){
            uint tokenid = _tokenStaked[_msgSender()];
            uint tokenamount = _tokenamount[_msgSender()];
            nft.safeTransferFrom(owner(), _msgSender(), tokenid, tokenamount, "");
            uint discount = (payamount*20)/100;
            payamount -= discount;
        }
        rupee.transferFrom(owner(), msg.sender, payamount);
        return true;
    }
    
    function _beforeTokenTransfer(address from, address to, uint amount) internal virtual{}
    function _afterTokenTransfer(address from, address to, uint amount) internal virtual{}
}