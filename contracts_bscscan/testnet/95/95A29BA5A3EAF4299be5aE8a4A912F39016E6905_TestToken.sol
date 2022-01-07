pragma solidity ^0.8.0;

import "./BEP20.sol";

contract TestToken is BEP20 {
    // khởi tạo token, tên, symbol, tổng số lượng phát hành
    constructor() BEP20("taptaphero", "TTC", 50000000000000000000000000) {
        // chuyển token tới địa chỉ ví
        mint(
            0xc408B7CCe2cA711cA0e92C7Ce8E2EdabcA0A7356,
            20000000000000000000000000
        );
        mint(
            0x1F3137545192B722A5fA7C0dd0164Ee5f6E0099d,
            5000000000000000000000000
        );
        mint(
            0xA7b11efF5f66CEe820c76BA8fB19aCE5c459bb72,
            5000000000000000000000000
        );
        mint(
            0x84B023Ea9D6fdA645271D42822F70406d6150901,
            5000000000000000000000000
        );
        mint(
            0x161b20e37dd627130B091913662806d9a613F5Ee,
            5000000000000000000000000
        );
        mint(
            0xC9DA2A9A0E320620BB5d05fb4933558e6301761E,
            5000000000000000000000000
        );
        mint(
            0xFcbecF86751F93C2521431d140cfFAD939176Cea,
            5000000000000000000000000
        );
    }
}

pragma solidity ^0.8.0;

import "./Context.sol";

abstract contract Ownable is Context {

    address private _owner;

    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    constructor() {
        address msgSender = getMsgSender();
        _owner = msgSender;
        emit OwnerSet(address(0), msgSender);
    }

    function getOwner() public view virtual returns (address){
        return _owner;
    }

    modifier isOwner(){
        require(getOwner() == getMsgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual isOwner {
        address _preOwner = _owner;
        _owner = address(0);
        emit OwnerSet(_preOwner, address(0));
    }

    function transferOwnership(address newOwner) public virtual isOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        address _preOwner = _owner;
        _owner = newOwner;
        emit OwnerSet(_preOwner, newOwner);
    }
}

pragma solidity ^0.8.0;

abstract contract Context {

    function getMsgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function getMsgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;

import "./Context.sol";
import "./Ownable.sol";

contract BEP20 is Context, Ownable {

    // sự kiện được public khi người dùng cấp quyền rút token
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    // sự kiện public khi token được chuyển
    event Transfer(address indexed from, address indexed to, uint tokens);
    // số dư token theo địa chỉ
    mapping(address => uint256) private _balances;
    // các tài khoản được chấp nhận rút token và số token được phép rút của mỗi tài khoản
    mapping(address => mapping(address => uint256)) private _allowances;
    // tổng số lượng token phát hành
    uint256 private _totalSupply;
    // số lượng tối đa token phát hành
    uint256 private _maxSupply;
    // metadata
    string private _name;
    string private _symbol;

    constructor(string memory name, string memory symbol, uint256 maxSupply) public {
        _maxSupply = maxSupply;
        _name = name;
        _symbol = symbol;
    }

    // view: trạng thái của contract không thay đổi bởi chức năng
    // public: chức năng có thể được truy cập bên contract
    // virtual override: ghi đè
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    // lấy số dư token
    function balanceOf(address tokenOwner) public view returns (uint256) {
        return _balances[tokenOwner];
    }

    // chuyển token sang tài khoản khách (owner ở đây là msg.sender)
    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(receiver != address(0), "BEP20: transfer from the zero address");
        require(numTokens < _balances[getMsgSender()], "BEP20: transfer amount exceeds balance");
        _balances[getMsgSender()] -= numTokens;
        _balances[receiver] += numTokens;
        emit Transfer(getMsgSender(), receiver, numTokens);
        return true;
    }

    // cho phép owner token (ở đây là msg.sender) chấp nhận tài khoản được uỷ quyền là (delegate) được phép rút
    // token và chuyển sang tài khoản khác
    function approve(address delegate, uint numTokens) public returns (bool) {
        _approve(getMsgSender(), delegate, numTokens);
        return true;
    }

    // lấy số token được chủ sở hữu chấp nhận phê duyệt
    function allowance(address owner, address delegate) public view returns (uint) {
        return _allowances[owner][delegate];
    }

    //
    function transferFrom(address sender, address receiver, uint numTokens) public returns (bool) {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(receiver != address(0), "BEP20: transfer from the zero address");
        require(numTokens <= _balances[sender], "BEP20: transfer amount exceeds balance");
        require(numTokens <= _allowances[sender][getMsgSender()], "BEP20: transfer amount exceeds allowance");
        _balances[sender] -= numTokens;
        _allowances[sender][getMsgSender()] -= numTokens;
        _balances[receiver] += numTokens;
        emit Transfer(sender, receiver, numTokens);
        return true;
    }

    // tăng số lượng token người uỷ quyền đc rút
    function increaseAllowance(address spender, uint256 plus) public virtual returns (bool){
        _approve(getMsgSender(), spender, _allowances[getMsgSender()][spender] + plus);
        return true;
    }

    // giảm số lượng token người uỷ quyền đc rút
    function decreaseAllowance(address spender, uint256 minus) public virtual returns (bool){
        uint256 currentAllowance = _allowances[getMsgSender()][spender];
        require(currentAllowance >= minus, "BEP20: decreased allowance exceeds balance");
        _approve(getMsgSender(), spender, currentAllowance - minus);
        return true;
    }

    function mint(address owner, uint256 numTokens) public virtual isOwner {
        require(owner != address(0), "BEP20: mint to the zero address");
        require(numTokens + _totalSupply <= _maxSupply, "BEP20: mint amount exceeds balance");
        _beforeTokenTransfer(address(0), owner, numTokens);
        _balances[owner] += numTokens;
        _totalSupply += numTokens;
        emit Transfer(address(0), owner, numTokens);
        _afterTokenTransfer(address(0), owner, numTokens);
    }

    function burn(address owner, uint256 numTokens) public virtual isOwner {
        require(owner != address(0), "BEP20: burn to the zero address");
        require(numTokens <= _balances[owner], "BEP20: burn amount exceeds balance");
        _beforeTokenTransfer(owner, address(0), numTokens);
        _balances[owner] -= numTokens;
        _totalSupply -= numTokens;
        emit Transfer(owner, address(0), numTokens);
        _afterTokenTransfer(owner, address(0), numTokens);
    }

    function _approve(address owner, address spender, uint numTokens) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        _allowances[owner][spender] = numTokens;
        emit Approval(owner, spender, numTokens);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}