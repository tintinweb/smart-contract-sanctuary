/**
 *Submitted for verification at Etherscan.io on 2021-06-24
*/

pragma solidity >=0.4.22 <0.7.0;
contract Context {
    constructor () internal { }
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}
contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Sauna_Emerging_1 is Ownable, ERC20, ERC20Detailed {
    struct Artist {
        string name;
        string surname;
        string art_product;
        uint share_amount;
        string info;
    }
    uint release_time;
    uint256 lock_ratio;
    Artist[] public artist_list; 
    constructor() ERC20Detailed("Sauna Emerging 1", "SE1", 2) Ownable() public {
        release_time = block.timestamp + 358 days;
        lock_ratio = 0;
        _mint(msg.sender, 11750000);
        artist_list.push(Artist({name:'Erdinc',surname:'Sakin', art_product:'Saygi', share_amount:7500, info:'Erdinc Sakin, Saygi, 7500'}));
        artist_list.push(Artist({name:'Mr.Hure',surname:'-', art_product:'Yengec', share_amount:17000, info:'Mr.Hure -, Yengec, 17000'}));
        artist_list.push(Artist({name:'Utku',surname:'Oksuz', art_product:'Mutsuz Kent', share_amount:8000, info:'Utku Oksuz, Mutsuz Kent, 8000'}));
        artist_list.push(Artist({name:'Erhan',surname:'Karagoz', art_product:'Tell Be If You Wanna BEE', share_amount:20000, info:'Erhan Karagoz, Tell Be If You Wanna BEE, 20000'}));
        artist_list.push(Artist({name:'Muhammet',surname:'Bakir', art_product:'Sesiz Seda', share_amount:11000, info:'Muhammet Bakir, Sesiz Seda, 11000'}));
        artist_list.push(Artist({name:'Ummuhan',surname:'Tuncturk', art_product:'Despotun Bir Gunu', share_amount:6500, info:'Ummuhan Tuncturk, Despotun Bir Gunu, 6500'}));
        artist_list.push(Artist({name:'Kuntay Tarik',surname:'Evren', art_product:'Teddy Bear', share_amount:10000, info:'Kuntay Tarik Evren, Teddy Bear, 10000'}));
        artist_list.push(Artist({name:'Saniye',surname:'Ozbek', art_product:'Nereye Aitim', share_amount:10000, info:'Saniye Ozbek, Nereye Aitim, 10000'}));
        artist_list.push(Artist({name:'Yasin',surname:'Canli', art_product:'Bu Yol Nereye Gider', share_amount:5000, info:'Yasin Canli, Bu Yol Nereye Gider, 5000'}));
        artist_list.push(Artist({name:'Mine',surname:'Akcaoglu', art_product:'Ayni Yerden Bakiyoruz', share_amount:15000, info:'Mine Akcaoglu, Ayni Yerden Bakiyoruz, 15000'}));
        artist_list.push(Artist({name:'Suleyman',surname:'Engin', art_product:'Gunesli Bir Gunde Dinazor Ailesinin Dusundukleri', share_amount:7500, info:'Suleyman Engin, Gunesli Bir Gunde Dinazor Ailesinin Dusundukleri, 7500'}));
    }
    function burn(address account, uint256 amount) public onlyOwner{
        _burn(account, amount);
    }
    function transfer(address recipient, uint256 amount) public onlyOwner returns (bool){
        if ( _msgSender() == owner() && release_time > block.timestamp){
            require( amount   <= balanceOf(_msgSender()) - totalSupply() * lock_ratio / 100, "Tokens are locked." );
            _transfer(_msgSender(), recipient, amount);
        }
        else{
            _transfer(_msgSender(), recipient, amount);    
        }
    }
    function getReleaseTime() public view returns (uint256) {
        return release_time;
    }
    function getLockRatio() public view returns (uint256) {
        return lock_ratio;
    }
    function getLockAmount() public view returns (uint256) {
        return totalSupply() * lock_ratio / 100;
    }
    function getArtistByID(uint id) public view returns (string memory) {
        return artist_list[id].info;
    }
    function getArtistListLength() public view returns (uint256) {
        return artist_list.length;
    }
    function Lock(uint256 new_lock_ratio, uint _days) public onlyOwner{
        require(release_time < block.timestamp, " Wait until tokens became unlocked. ");
        release_time = block.timestamp + _days * 1 days;
        lock_ratio = new_lock_ratio;
    }
}