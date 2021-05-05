/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

/**

Deployed by Ren Project, https://renproject.io

Commit hash: 087fa49
Repository: https://github.com/renproject/gateway-sol
Issues: https://github.com/renproject/gateway-sol/issues

Licenses
@openzeppelin/contracts: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/LICENSE
gateway-sol: https://github.com/renproject/gateway-sol/blob/master/LICENSE

*/

pragma solidity ^0.5.17;


contract Initializable {

  
  bool private initialized;

  
  bool private initializing;

  
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  
  function isConstructor() private view returns (bool) {
    
    
    
    
    
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  
  uint256[50] private ______gap;
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

library ECDSA {
    
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        
        if (signature.length != 65) {
            revert("ECDSA: signature length is invalid");
        }

        
        bytes32 r;
        bytes32 s;
        uint8 v;

        
        
        
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        
        
        
        
        
        
        
        
        
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("ECDSA: signature.s is in the wrong range");
        }

        if (v != 27 && v != 28) {
            revert("ECDSA: signature.v is in the wrong range");
        }

        
        return ecrecover(hash, v, r, s);
    }

    
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        
        
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

contract Proxy {
  
  function () payable external {
    _fallback();
  }

  
  function _implementation() internal view returns (address);

  
  function _delegate(address implementation) internal {
    assembly {
      
      
      
      calldatacopy(0, 0, calldatasize)

      
      
      let result := delegatecall(gas, implementation, 0, calldatasize, 0, 0)

      
      returndatacopy(0, 0, returndatasize)

      switch result
      
      case 0 { revert(0, returndatasize) }
      default { return(0, returndatasize) }
    }
  }

  
  function _willFallback() internal {
  }

  
  function _fallback() internal {
    _willFallback();
    _delegate(_implementation());
  }
}

library OpenZeppelinUpgradesAddress {
    
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        
        
        
        
        
        
        
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

contract BaseUpgradeabilityProxy is Proxy {
  
  event Upgraded(address indexed implementation);

  
  bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  
  function _implementation() internal view returns (address impl) {
    bytes32 slot = IMPLEMENTATION_SLOT;
    assembly {
      impl := sload(slot)
    }
  }

  
  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

  
  function _setImplementation(address newImplementation) internal {
    require(OpenZeppelinUpgradesAddress.isContract(newImplementation), "Cannot set a proxy implementation to a non-contract address");

    bytes32 slot = IMPLEMENTATION_SLOT;

    assembly {
      sstore(slot, newImplementation)
    }
  }
}

contract UpgradeabilityProxy is BaseUpgradeabilityProxy {
  
  constructor(address _logic, bytes memory _data) public payable {
    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
    _setImplementation(_logic);
    if(_data.length > 0) {
      (bool success,) = _logic.delegatecall(_data);
      require(success);
    }
  }  
}

contract BaseAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
  
  event AdminChanged(address previousAdmin, address newAdmin);

  

  bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  
  modifier ifAdmin() {
    if (msg.sender == _admin()) {
      _;
    } else {
      _fallback();
    }
  }

  
  function admin() external ifAdmin returns (address) {
    return _admin();
  }

  
  function implementation() external ifAdmin returns (address) {
    return _implementation();
  }

  
  function changeAdmin(address newAdmin) external ifAdmin {
    require(newAdmin != address(0), "Cannot change the admin of a proxy to the zero address");
    emit AdminChanged(_admin(), newAdmin);
    _setAdmin(newAdmin);
  }

  
  function upgradeTo(address newImplementation) external ifAdmin {
    _upgradeTo(newImplementation);
  }

  
  function upgradeToAndCall(address newImplementation, bytes calldata data) payable external ifAdmin {
    _upgradeTo(newImplementation);
    (bool success,) = newImplementation.delegatecall(data);
    require(success);
  }

  
  function _admin() internal view returns (address adm) {
    bytes32 slot = ADMIN_SLOT;
    assembly {
      adm := sload(slot)
    }
  }

  
  function _setAdmin(address newAdmin) internal {
    bytes32 slot = ADMIN_SLOT;

    assembly {
      sstore(slot, newAdmin)
    }
  }

  
  function _willFallback() internal {
    require(msg.sender != _admin(), "Cannot call fallback function from the proxy admin");
    super._willFallback();
  }
}

contract InitializableUpgradeabilityProxy is BaseUpgradeabilityProxy {
  
  function initialize(address _logic, bytes memory _data) public payable {
    require(_implementation() == address(0));
    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
    _setImplementation(_logic);
    if(_data.length > 0) {
      (bool success,) = _logic.delegatecall(_data);
      require(success);
    }
  }  
}

contract InitializableAdminUpgradeabilityProxy is BaseAdminUpgradeabilityProxy, InitializableUpgradeabilityProxy {
  
  function initialize(address _logic, address _admin, bytes memory _data) public payable {
    require(_implementation() == address(0));
    InitializableUpgradeabilityProxy.initialize(_logic, _data);
    assert(ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));
    _setAdmin(_admin);
  }
}

contract Context is Initializable {
    
    
    constructor () internal { }
    

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Initializable, Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    function initialize(address sender) public initializer {
        _owner = sender;
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

    uint256[50] private ______gap;
}

contract Claimable is Initializable, Ownable {
    address public pendingOwner;

    function initialize(address _nextOwner) public initializer {
        Ownable.initialize(_nextOwner);
    }

    modifier onlyPendingOwner() {
        require(
            _msgSender() == pendingOwner,
            "Claimable: caller is not the pending owner"
        );
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != owner() && newOwner != pendingOwner,
            "Claimable: invalid new owner"
        );
        pendingOwner = newOwner;
    }

    
    
    function _directTransferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function claimOwnership() public onlyPendingOwner {
        _transferOwnership(pendingOwner);
        delete pendingOwner;
    }
}

library String {
    
    
    function fromUint(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }

    
    function fromBytes32(bytes32 _value) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(32 * 2 + 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 32; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(_value[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(_value[i] & 0x0f))];
        }
        return string(str);
    }

    
    function fromAddress(address _addr) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(_addr));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(20 * 2 + 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(value[i + 12] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(value[i + 12] & 0x0f))];
        }
        return string(str);
    }

    
    function add8(
        string memory a,
        string memory b,
        string memory c,
        string memory d,
        string memory e,
        string memory f,
        string memory g,
        string memory h
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c, d, e, f, g, h));
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

contract ERC20 is Initializable, Context, IERC20 {
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

    uint256[50] private ______gap;
}

contract ERC20Detailed is Initializable, IERC20 {
    string private _name;
    string internal _symbol;
    uint8 private _decimals;

    
    function initialize(string memory name, string memory symbol, uint8 decimals) public initializer {
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

    uint256[50] private ______gap;
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        
        
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        
        
        
        
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        
        

        
        
        
        
        
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { 
            
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract CanReclaimTokens is Claimable {
    using SafeERC20 for ERC20;

    mapping(address => bool) private recoverableTokensBlacklist;

    function initialize(address _nextOwner) public initializer {
        Claimable.initialize(_nextOwner);
    }

    function blacklistRecoverableToken(address _token) public onlyOwner {
        recoverableTokensBlacklist[_token] = true;
    }

    
    
    function recoverTokens(address _token) external onlyOwner {
        require(
            !recoverableTokensBlacklist[_token],
            "CanReclaimTokens: token is not recoverable"
        );

        if (_token == address(0x0)) {
            msg.sender.transfer(address(this).balance);
        } else {
            ERC20(_token).safeTransfer(
                msg.sender,
                ERC20(_token).balanceOf(address(this))
            );
        }
    }
}

contract ERC20WithRate is Initializable, Ownable, ERC20 {
    using SafeMath for uint256;

    uint256 public constant _rateScale = 1e18;
    uint256 internal _rate;

    event LogRateChanged(uint256 indexed _rate);

    
    function initialize(address _nextOwner, uint256 _initialRate)
        public
        initializer
    {
        Ownable.initialize(_nextOwner);
        _setRate(_initialRate);
    }

    function setExchangeRate(uint256 _nextRate) public onlyOwner {
        _setRate(_nextRate);
    }

    function exchangeRateCurrent() public view returns (uint256) {
        require(_rate != 0, "ERC20WithRate: rate has not been initialized");
        return _rate;
    }

    function _setRate(uint256 _nextRate) internal {
        require(_nextRate > 0, "ERC20WithRate: rate must be greater than zero");
        _rate = _nextRate;
    }

    function balanceOfUnderlying(address _account)
        public
        view
        returns (uint256)
    {
        return toUnderlying(balanceOf(_account));
    }

    function toUnderlying(uint256 _amount) public view returns (uint256) {
        return _amount.mul(_rate).div(_rateScale);
    }

    function fromUnderlying(uint256 _amountUnderlying)
        public
        view
        returns (uint256)
    {
        return _amountUnderlying.mul(_rateScale).div(_rate);
    }
}

contract ERC20WithPermit is Initializable, ERC20, ERC20Detailed {
    using SafeMath for uint256;

    mapping(address => uint256) public nonces;

    
    
    string public version;

    
    bytes32 public DOMAIN_SEPARATOR;
    
    
    bytes32 public constant PERMIT_TYPEHASH =
        0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;

    function initialize(
        uint256 _chainId,
        string memory _version,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public initializer {
        ERC20Detailed.initialize(_name, _symbol, _decimals);
        version = _version;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name())),
                keccak256(bytes(version)),
                _chainId,
                address(this)
            )
        );
    }

    
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            holder,
                            spender,
                            nonce,
                            expiry,
                            allowed
                        )
                    )
                )
            );

        require(holder != address(0), "ERC20WithRate: address must not be 0x0");
        require(
            holder == ecrecover(digest, v, r, s),
            "ERC20WithRate: invalid signature"
        );
        require(
            expiry == 0 || now <= expiry,
            "ERC20WithRate: permit has expired"
        );
        require(nonce == nonces[holder]++, "ERC20WithRate: invalid nonce");
        uint256 amount = allowed ? uint256(-1) : 0;
        _approve(holder, spender, amount);
    }
}

contract RenERC20LogicV1 is
    Initializable,
    ERC20,
    ERC20Detailed,
    ERC20WithRate,
    ERC20WithPermit,
    Claimable,
    CanReclaimTokens
{
    
    function initialize(
        uint256 _chainId,
        address _nextOwner,
        uint256 _initialRate,
        string memory _version,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public initializer {
        ERC20Detailed.initialize(_name, _symbol, _decimals);
        ERC20WithRate.initialize(_nextOwner, _initialRate);
        ERC20WithPermit.initialize(
            _chainId,
            _version,
            _name,
            _symbol,
            _decimals
        );
        Claimable.initialize(_nextOwner);
        CanReclaimTokens.initialize(_nextOwner);
    }

    function updateSymbol(string memory symbol) public onlyOwner {
        ERC20Detailed._symbol = symbol;
    }

    
    
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    
    
    function burn(address _from, uint256 _amount) public onlyOwner {
        _burn(_from, _amount);
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        
        
        
        require(
            recipient != address(this),
            "RenERC20: can't transfer to token address"
        );
        return super.transfer(recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        
        
        require(
            recipient != address(this),
            "RenERC20: can't transfer to token address"
        );
        return super.transferFrom(sender, recipient, amount);
    }
}

contract RenERC20Proxy is InitializableAdminUpgradeabilityProxy {

}

interface IMintGateway {
    function mint(
        bytes32 _pHash,
        uint256 _amount,
        bytes32 _nHash,
        bytes calldata _sig
    ) external returns (uint256);

    function mintFee() external view returns (uint256);
}

interface IBurnGateway {
    function burn(bytes calldata _to, uint256 _amountScaled)
        external
        returns (uint256);

    function burnFee() external view returns (uint256);
}

interface IGateway {
    
    function mint(
        bytes32 _pHash,
        uint256 _amount,
        bytes32 _nHash,
        bytes calldata _sig
    ) external returns (uint256);

    function mintFee() external view returns (uint256);

    
    function burn(bytes calldata _to, uint256 _amountScaled)
        external
        returns (uint256);

    function burnFee() external view returns (uint256);
}

contract MintGatewayStateV1 {
    uint256 constant BIPS_DENOMINATOR = 10000;
    uint256 public minimumBurnAmount;

    
    RenERC20LogicV1 public token;

    
    address public mintAuthority;

    
    
    
    
    address public feeRecipient;

    
    uint16 public mintFee;

    
    uint16 public burnFee;

    
    mapping(bytes32 => bool) public status;

    
    
    uint256 public nextN = 0;
}

contract MintGatewayLogicV1 is
    Initializable,
    Claimable,
    CanReclaimTokens,
    IGateway,
    MintGatewayStateV1
{
    using SafeMath for uint256;

    event LogMintAuthorityUpdated(address indexed _newMintAuthority);
    event LogMint(
        address indexed _to,
        uint256 _amount,
        uint256 indexed _n,
        bytes32 indexed _signedMessageHash
    );
    event LogBurn(
        bytes _to,
        uint256 _amount,
        uint256 indexed _n,
        bytes indexed _indexedTo
    );

    
    modifier onlyOwnerOrMintAuthority() {
        require(
            msg.sender == mintAuthority || msg.sender == owner(),
            "Gateway: caller is not the owner or mint authority"
        );
        _;
    }

    
    
    
    
    
    
    
    
    function initialize(
        RenERC20LogicV1 _token,
        address _feeRecipient,
        address _mintAuthority,
        uint16 _mintFee,
        uint16 _burnFee,
        uint256 _minimumBurnAmount
    ) public initializer {
        Claimable.initialize(msg.sender);
        CanReclaimTokens.initialize(msg.sender);
        minimumBurnAmount = _minimumBurnAmount;
        token = _token;
        mintFee = _mintFee;
        burnFee = _burnFee;
        updateMintAuthority(_mintAuthority);
        updateFeeRecipient(_feeRecipient);
    }

    

    
    
    
    function claimTokenOwnership() public {
        token.claimOwnership();
    }

    
    function transferTokenOwnership(MintGatewayLogicV1 _nextTokenOwner)
        public
        onlyOwner
    {
        token.transferOwnership(address(_nextTokenOwner));
        _nextTokenOwner.claimTokenOwnership();
    }

    
    
    
    function updateMintAuthority(address _nextMintAuthority)
        public
        onlyOwnerOrMintAuthority
    {
        
        
        require(
            _nextMintAuthority != address(0),
            "Gateway: mintAuthority cannot be set to address zero"
        );
        mintAuthority = _nextMintAuthority;
        emit LogMintAuthorityUpdated(mintAuthority);
    }

    
    
    
    function updateMinimumBurnAmount(uint256 _minimumBurnAmount)
        public
        onlyOwner
    {
        minimumBurnAmount = _minimumBurnAmount;
    }

    
    
    
    function updateFeeRecipient(address _nextFeeRecipient) public onlyOwner {
        
        require(
            _nextFeeRecipient != address(0x0),
            "Gateway: fee recipient cannot be 0x0"
        );

        feeRecipient = _nextFeeRecipient;
    }

    
    
    
    function updateMintFee(uint16 _nextMintFee) public onlyOwner {
        mintFee = _nextMintFee;
    }

    
    
    
    function updateBurnFee(uint16 _nextBurnFee) public onlyOwner {
        burnFee = _nextBurnFee;
    }

    
    
    
    
    
    
    
    
    
    
    function mint(
        bytes32 _pHash,
        uint256 _amountUnderlying,
        bytes32 _nHash,
        bytes memory _sig
    ) public returns (uint256) {
        
        bytes32 sigHash =
            hashForSignature(_pHash, _amountUnderlying, msg.sender, _nHash);

        

        
        require(status[sigHash] == false, "Gateway: nonce hash already spent");

        
        
        if (!verifySignature(sigHash, _sig)) {
            
            
            
            revert(
                String.add8(
                    "Gateway: invalid signature. pHash: ",
                    String.fromBytes32(_pHash),
                    ", amount: ",
                    String.fromUint(_amountUnderlying),
                    ", msg.sender: ",
                    String.fromAddress(msg.sender),
                    ", _nHash: ",
                    String.fromBytes32(_nHash)
                )
            );
        }

        
        
        status[sigHash] = true;

        uint256 amountScaled = token.fromUnderlying(_amountUnderlying);

        
        uint256 absoluteFeeScaled =
            amountScaled.mul(mintFee).div(BIPS_DENOMINATOR);
        uint256 receivedAmountScaled =
            amountScaled.sub(absoluteFeeScaled, "Gateway: fee exceeds amount");

        
        token.mint(msg.sender, receivedAmountScaled);
        
        token.mint(feeRecipient, absoluteFeeScaled);

        
        uint256 receivedAmountUnderlying =
            token.toUnderlying(receivedAmountScaled);
        emit LogMint(msg.sender, receivedAmountUnderlying, nextN, sigHash);
        nextN += 1;

        return receivedAmountScaled;
    }

    
    
    
    
    
    
    
    
    
    
    function burn(bytes memory _to, uint256 _amount) public returns (uint256) {
        
        
        require(_to.length != 0, "Gateway: to address is empty");

        
        uint256 fee = _amount.mul(burnFee).div(BIPS_DENOMINATOR);
        uint256 amountAfterFee =
            _amount.sub(fee, "Gateway: fee exceeds amount");

        
        
        
        uint256 amountAfterFeeUnderlying = token.toUnderlying(amountAfterFee);

        
        token.burn(msg.sender, _amount);
        token.mint(feeRecipient, fee);

        require(
            
            
            amountAfterFeeUnderlying > minimumBurnAmount,
            "Gateway: amount is less than the minimum burn amount"
        );

        emit LogBurn(_to, amountAfterFeeUnderlying, nextN, _to);
        nextN += 1;

        return amountAfterFeeUnderlying;
    }

    
    
    function verifySignature(bytes32 _sigHash, bytes memory _sig)
        public
        view
        returns (bool)
    {
        return mintAuthority == ECDSA.recover(_sigHash, _sig);
    }

    
    
    function hashForSignature(
        bytes32 _pHash,
        uint256 _amount,
        address _to,
        bytes32 _nHash
    ) public view returns (bytes32) {
        return
            keccak256(abi.encode(_pHash, _amount, address(token), _to, _nHash));
    }
}

contract BTCGateway is InitializableAdminUpgradeabilityProxy {}

contract ZECGateway is InitializableAdminUpgradeabilityProxy {}

contract BCHGateway is InitializableAdminUpgradeabilityProxy {}

contract MintGatewayStateV2 {
    struct Burn {
        uint256 _blocknumber;
        bytes _to;
        uint256 _amount;
        
        string _chain;
        bytes _payload;
    }

    mapping(uint256 => Burn) internal burns;

    bytes32 public selectorHash;

    
    
    address public _legacy_mintAuthority;
}

contract MintGatewayLogicV2 is
    Initializable,
    Claimable,
    CanReclaimTokens,
    IGateway,
    MintGatewayStateV1,
    MintGatewayStateV2
{
    using SafeMath for uint256;

    event LogMintAuthorityUpdated(address indexed _newMintAuthority);
    event LogMint(
        address indexed _to,
        uint256 _amount,
        uint256 indexed _n,
        
        
        bytes32 indexed _nHash
    );
    event LogBurn(
        bytes _to,
        uint256 _amount,
        uint256 indexed _n,
        bytes indexed _indexedTo
    );

    
    modifier onlyOwnerOrMintAuthority() {
        require(
            msg.sender == mintAuthority || msg.sender == owner(),
            "MintGateway: caller is not the owner or mint authority"
        );
        _;
    }

    
    
    
    
    
    
    
    
    function initialize(
        RenERC20LogicV1 _token,
        address _feeRecipient,
        address _mintAuthority,
        uint16 _mintFee,
        uint16 _burnFee,
        uint256 _minimumBurnAmount
    ) public initializer {
        Claimable.initialize(msg.sender);
        CanReclaimTokens.initialize(msg.sender);
        minimumBurnAmount = _minimumBurnAmount;
        token = _token;
        mintFee = _mintFee;
        burnFee = _burnFee;
        updateMintAuthority(_mintAuthority);
        updateFeeRecipient(_feeRecipient);
    }

    
    
    
    function updateSelectorHash(bytes32 _selectorHash) public onlyOwner {
        selectorHash = _selectorHash;
    }

    
    function updateSymbol(string memory symbol) public onlyOwner {
        token.updateSymbol(symbol);
    }

    

    
    
    
    function claimTokenOwnership() public {
        token.claimOwnership();
    }

    
    function transferTokenOwnership(MintGatewayLogicV2 _nextTokenOwner)
        public
        onlyOwner
    {
        token.transferOwnership(address(_nextTokenOwner));
        _nextTokenOwner.claimTokenOwnership();
    }

    
    
    
    function updateMintAuthority(address _nextMintAuthority)
        public
        onlyOwnerOrMintAuthority
    {
        
        
        require(
            _nextMintAuthority != address(0),
            "MintGateway: mintAuthority cannot be set to address zero"
        );
        mintAuthority = _nextMintAuthority;
        emit LogMintAuthorityUpdated(mintAuthority);
    }

    
    
    
    function _legacy_updateMintAuthority(address _nextMintAuthority)
        public
        onlyOwner
    {
        _legacy_mintAuthority = _nextMintAuthority;
    }

    
    
    
    function updateMinimumBurnAmount(uint256 _minimumBurnAmount)
        public
        onlyOwner
    {
        minimumBurnAmount = _minimumBurnAmount;
    }

    
    
    
    function updateFeeRecipient(address _nextFeeRecipient) public onlyOwner {
        
        require(
            _nextFeeRecipient != address(0x0),
            "MintGateway: fee recipient cannot be 0x0"
        );

        feeRecipient = _nextFeeRecipient;
    }

    
    
    
    function updateMintFee(uint16 _nextMintFee) public onlyOwner {
        mintFee = _nextMintFee;
    }

    
    
    
    function updateBurnFee(uint16 _nextBurnFee) public onlyOwner {
        burnFee = _nextBurnFee;
    }

    
    
    
    
    
    
    
    
    
    
    function mint(
        bytes32 _pHash,
        uint256 _amountUnderlying,
        bytes32 _nHash,
        bytes memory _sig
    ) public returns (uint256) {
        
        bytes32 sigHash =
            hashForSignature(_pHash, _amountUnderlying, msg.sender, _nHash);

        
        bytes32 legacySigHash =
            _legacy_hashForSignature(
                _pHash,
                _amountUnderlying,
                msg.sender,
                _nHash
            );

        
        require(
            status[sigHash] == false && status[legacySigHash] == false,
            "MintGateway: nonce hash already spent"
        );

        
        
        if (
            !verifySignature(sigHash, _sig) &&
            !_legacy_verifySignature(legacySigHash, _sig)
        ) {
            
            
            
            revert(
                String.add8(
                    "MintGateway: invalid signature. pHash: ",
                    String.fromBytes32(_pHash),
                    ", amount: ",
                    String.fromUint(_amountUnderlying),
                    ", msg.sender: ",
                    String.fromAddress(msg.sender),
                    ", _nHash: ",
                    String.fromBytes32(_nHash)
                )
            );
        }

        
        
        
        
        status[sigHash] = true;
        status[legacySigHash] = true;

        uint256 amountScaled = token.fromUnderlying(_amountUnderlying);

        
        uint256 absoluteFeeScaled =
            amountScaled.mul(mintFee).div(BIPS_DENOMINATOR);
        uint256 receivedAmountScaled =
            amountScaled.sub(
                absoluteFeeScaled,
                "MintGateway: fee exceeds amount"
            );

        
        token.mint(msg.sender, receivedAmountScaled);
        
        if (absoluteFeeScaled > 0) {
            token.mint(feeRecipient, absoluteFeeScaled);
        }

        
        uint256 receivedAmountUnderlying =
            token.toUnderlying(receivedAmountScaled);
        emit LogMint(msg.sender, receivedAmountUnderlying, nextN, _nHash);
        nextN += 1;

        return receivedAmountScaled;
    }

    
    
    
    
    
    
    
    
    
    
    function burn(bytes memory _to, uint256 _amount) public returns (uint256) {
        
        
        require(_to.length != 0, "MintGateway: to address is empty");

        
        uint256 fee = _amount.mul(burnFee).div(BIPS_DENOMINATOR);
        uint256 amountAfterFee =
            _amount.sub(fee, "MintGateway: fee exceeds amount");

        
        
        
        uint256 amountAfterFeeUnderlying = token.toUnderlying(amountAfterFee);

        
        token.burn(msg.sender, _amount);
        if (fee > 0) {
            token.mint(feeRecipient, fee);
        }

        require(
            
            
            amountAfterFeeUnderlying > minimumBurnAmount,
            "MintGateway: amount is less than the minimum burn amount"
        );

        emit LogBurn(_to, amountAfterFeeUnderlying, nextN, _to);

        
        
        bytes memory payload;
        MintGatewayStateV2.burns[nextN] = Burn({
            _blocknumber: block.number,
            _to: _to,
            _amount: amountAfterFeeUnderlying,
            _chain: "",
            _payload: payload
        });

        nextN += 1;

        return amountAfterFeeUnderlying;
    }

    function getBurn(uint256 _n)
        public
        view
        returns (
            uint256 _blocknumber,
            bytes memory _to,
            uint256 _amount,
            
            string memory _chain,
            bytes memory _payload
        )
    {
        Burn memory burnStruct = MintGatewayStateV2.burns[_n];
        require(burnStruct._to.length > 0, "MintGateway: burn not found");
        return (
            burnStruct._blocknumber,
            burnStruct._to,
            burnStruct._amount,
            burnStruct._chain,
            burnStruct._payload
        );
    }

    
    
    function verifySignature(bytes32 _sigHash, bytes memory _sig)
        public
        view
        returns (bool)
    {
        return mintAuthority == ECDSA.recover(_sigHash, _sig);
    }

    
    
    function _legacy_verifySignature(bytes32 _sigHash, bytes memory _sig)
        public
        view
        returns (bool)
    {
        require(
            _legacy_mintAuthority != address(0x0),
            "MintGateway: legacy mintAuthority not set"
        );
        return _legacy_mintAuthority == ECDSA.recover(_sigHash, _sig);
    }

    
    
    function hashForSignature(
        bytes32 _pHash,
        uint256 _amount,
        address _to,
        bytes32 _nHash
    ) public view returns (bytes32) {
        return
            keccak256(abi.encode(_pHash, _amount, selectorHash, _to, _nHash));
    }

    
    
    function _legacy_hashForSignature(
        bytes32 _pHash,
        uint256 _amount,
        address _to,
        bytes32 _nHash
    ) public view returns (bytes32) {
        return
            keccak256(abi.encode(_pHash, _amount, address(token), _to, _nHash));
    }
}

contract MintGatewayProxy is InitializableAdminUpgradeabilityProxy {

}