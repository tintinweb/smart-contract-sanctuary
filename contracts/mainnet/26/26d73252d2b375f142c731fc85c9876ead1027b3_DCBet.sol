// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.7.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/math/SafeMath.sol

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

// File: @openzeppelin/contracts/utils/Address.sol

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

contract Ownable is Context {
    address private _owner;
    address[] private _partners = new address[](11);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PartnershipTransferred(address indexed previousPartner, address indexed newPartner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        //partner
        _partners[0] = 0x8f25F0C8Af94DFA6E3F7D50F428fD5C14204D85B;
        _partners[1] = 0x8367691777d6a919EC9093b1F46F68A913933609;
        _partners[2] = 0x21D617Ee5b9CF68c428515B47bD2709119eD0b8f;
        _partners[3] = 0xb07E36Ec905D791954890476A8E9C4e7d9ae0522;
        _partners[4] = 0xa839ff7466F6bF060d2f3a9a9302610b2f71a89b;
        _partners[5] = 0x68D0b8490F76B1B021132d17C247bfDC68BD6f0D;
        _partners[6] = 0x13AA9831D816ab81C4d0C139c1e480B197f2046c;
        _partners[7] = 0xb8A14ECc4AF32012BD305667c82Db4156572043e;
        _partners[8] = 0x0034Eb324848303411177075bf2fB66376aEa90d;
        //presale
        _partners[9] = 0x0000000000000000000000000000000000000000;
        //exchange
        _partners[10] = 0x0000000000000000000000000000000000000000;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    function partner(uint256 index) public view returns (address) {
        require(index < _partners.length, "Ownable: index of partner is incorrect");
        return _partners[index];
    }
    function is_partner(address addr) public view returns (bool) {
        bool partnership = false;
        uint256 partnerIndex = _partners.length;
        for(uint256 i=0; i<partnerIndex; i++){
            if(_partners[i] == addr) {
                partnership = true;
                break;
            }
        }
        return partnership;
    }
    function partner_length() public view returns (uint256) {
        return _partners.length;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    modifier onlyPartner() {
        bool partnership = false;
        address msgSender = _msgSender();
        uint256 partnerIndex = _partners.length;
        for(uint256 i=0; i<partnerIndex; i++){
            if(_partners[i] == msgSender) {
                partnership = true;
                break;
            }
        }
        require(partnership == true, "Partner not found");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    function transferPartnership(address newPartner,uint256 index) public virtual onlyPartner {
        require(index < _partners.length, "Ownable: index of partner is incorrect");
        require(_partners[index] == _msgSender(), "Ownable: partner can only change its address");
        emit PartnershipTransferred(_partners[index], newPartner);
        _partners[index] = newPartner;
    }
    function transferPresaleship(address newPartner) public virtual onlyOwner {
        require(newPartner != address(0), "Ownable: new partner is the zero address");
        emit PartnershipTransferred(_partners[partner_length()-2], newPartner);
        _partners[partner_length()-2] = newPartner;
    }
    function transferExchangeship(address newPartner) public virtual onlyOwner {
        require(newPartner != address(0), "Ownable: new partner is the zero address");
        emit PartnershipTransferred(_partners[partner_length()-1], newPartner);
        _partners[partner_length()-1] = newPartner;
    }
}

// File: @openzeppelin/contracts/utils/Pausable.sol

contract Pausable is Context {
    event Paused(address account);
    event Unpaused(address account);
    bool private _paused;
    constructor () {
        _paused = false;
    }
    function paused() public view returns (bool) {
        return _paused;
    }
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    constructor (string memory name, string memory symbol) {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
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
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20Capped.sol

abstract contract ERC20Capped is ERC20 {
    using SafeMath for uint256;
    uint256 private _cap;
    constructor (uint256 cap) {
        require(cap > 0, "ERC20Capped: cap is 0");
        _cap = cap;
    }
    function cap() public view returns (uint256) {
        return _cap;
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        if (from == address(0)) {
            require(totalSupply().add(amount) <= _cap, "ERC20Capped: cap exceeded");
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20Burnable.sol

abstract contract ERC20Burnable is Context, ERC20 {
    using SafeMath for uint256;
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");
        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20Pausable.sol

abstract contract ERC20Pausable is ERC20, Pausable {
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}

// File: eth-token-recover/contracts/TokenRecover.sol

contract TokenRecover is Ownable {
    function recoverERC20(address tokenAddress, uint256 tokenAmount) public onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }
}

// File: @vittominacori/erc20-token/contracts/ERC20Base.sol

contract ERC20Base is ERC20Capped, ERC20Burnable, ERC20Pausable, TokenRecover {
    bool private _mintingFinished = false;
    bool private _transferEnabled = false;
    event MintFinished();
    event TransferEnabled();
    event TransferDisabled();
    modifier canMint() {
        require(!_mintingFinished, "ERC20Base: minting is finished");
        _;
    }
    modifier canTransfer(address from) {
        require(
            _transferEnabled || owner() == from || is_partner(from) == true,
            "ERC20Base: transfer is not enabled or from does not have status owner"
        );
        _;
    }
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 cap,
        uint256 initialSupply,
        bool transferEnabled,
        bool mintingFinished
    )
    ERC20Capped(cap)
    ERC20(name, symbol)
    {
        require(
            mintingFinished == false || cap == initialSupply,
            "ERC20Base: if finish minting, cap must be equal to initialSupply"
        );
        _setupDecimals(decimals);
        if (initialSupply > 0) {
            _mint(owner(), initialSupply);
            _mint(partner(0), 100000*10**uint256(decimals));
            _mint(partner(1), 100000*10**uint256(decimals));
            _mint(partner(2), 100000*10**uint256(decimals));
            _mint(partner(3), 100000*10**uint256(decimals));
            _mint(partner(4), 100000*10**uint256(decimals));
            _mint(partner(5), 100000*10**uint256(decimals));
            _mint(partner(6), 100000*10**uint256(decimals));
            _mint(partner(7), 100000*10**uint256(decimals));
            _mint(partner(8), 100000*10**uint256(decimals));
        }
        if (mintingFinished) {
            finishMinting();
        }
        if (transferEnabled) {
            enableTransfer();
        }
    }
    function mintingFinished() public view returns (bool) {
        return _mintingFinished;
    }
    function transferEnabled() public view returns (bool) {
        return _transferEnabled;
    }
    function mint(address to, uint256 value) public canMint onlyOwner {
        _mint(to, value);
    }
    function transfer(address to, uint256 value) public virtual override(ERC20) canTransfer(_msgSender()) returns (bool) {
        return super.transfer(to, value);
    }
    function transferFrom(address from, address to, uint256 value) public virtual override(ERC20) canTransfer(from) returns (bool) {
        return super.transferFrom(from, to, value);
    }
    function finishMinting() public canMint onlyOwner {
        _mintingFinished = true;
        emit MintFinished();
    }
    function disableTransfer() public onlyOwner {
        _transferEnabled = false;
        emit TransferDisabled();
    }
    function enableTransfer() public onlyOwner {
        _transferEnabled = true;
        emit TransferEnabled();
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Capped, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}

// File: contracts/DCBet.sol

pragma solidity ^0.7.1;

contract DCBet is ERC20Base {
    string private constant _VERSION = "v3.2.0";
    constructor (
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 cap,
        uint256 initialSupply,
        bool transferEnabled,
        bool mintingFinished
    ) ERC20Base(name, symbol, decimals, cap, initialSupply, transferEnabled, mintingFinished) { }
    function version() public pure returns (string memory) {
        return _VERSION;
    }
}