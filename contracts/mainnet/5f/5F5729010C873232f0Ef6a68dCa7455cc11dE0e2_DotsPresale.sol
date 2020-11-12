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

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }


    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol) public {
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

contract DotsCoinCore is ERC20("DotSwaps", "DOTS") {
    using SafeMath for uint256;

    address internal _taxer;
    address internal _taxDestination;
    uint internal _taxRate = 0;
    mapping (address => bool) internal _taxWhitelist;

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 taxAmount = amount.mul(_taxRate).div(100);
        if (_taxWhitelist[msg.sender] == true) {
            taxAmount = 0;
        }
        uint256 transferAmount = amount.sub(taxAmount);
        require(balanceOf(msg.sender) >= transferAmount, "insufficient balance.");
        super.transfer(recipient, amount);

        if (taxAmount != 0) {
            super.transfer(_taxDestination, taxAmount);
        }
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 taxAmount = amount.mul(_taxRate).div(100);
        if (_taxWhitelist[sender] == true) {
            taxAmount = 0;
        }
        uint256 transferAmount = amount.sub(taxAmount);
        require(balanceOf(sender) >= transferAmount, "insufficient balance.");
        super.transferFrom(sender, recipient, amount);
        if (taxAmount != 0) {
            super.transferFrom(sender, _taxDestination, taxAmount);
        }
        return true;
    }
}

contract DotsCoin is DotsCoinCore, Ownable {
    mapping (address => bool) public minters;

    constructor() {
        _taxer = owner();
        _taxDestination = owner();
    }

    function mint(address to, uint amount) public onlyMinter {
        _mint(to, amount);
    }

    function burn(uint amount) public {
        require(amount > 0);
        require(balanceOf(msg.sender) >= amount);
        _burn(msg.sender, amount);
    }

    function addMinter(address account) public onlyOwner {
        minters[account] = true;
    }

    function removeMinter(address account) public onlyOwner {
        minters[account] = false;
    }

    modifier onlyMinter() {
        require(minters[msg.sender], "Restricted to minters.");
        _;
    }

    modifier onlyTaxer() {
        require(msg.sender == _taxer, "Only for taxer.");
        _;
    }

    function setTaxer(address account) public onlyOwner {
        _taxer = account;
    }

    function setTaxRate(uint256 rate) public onlyTaxer {
        _taxRate = rate;
    }

    function setTaxDestination(address account) public onlyTaxer {
        _taxDestination = account;
    }

    function addToWhitelist(address account) public onlyTaxer {
        _taxWhitelist[account] = true;
    }

    function removeFromWhitelist(address account) public onlyTaxer {
        _taxWhitelist[account] = false;
    }

    function taxer() public view returns(address) {
        return _taxer;
    }

    function taxDestination() public view returns(address) {
        return _taxDestination;
    }

    function taxRate() public view returns(uint256) {
        return _taxRate;
    }

    function isInWhitelist(address account) public view returns(bool) {
        return _taxWhitelist[account];
    }
}


library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        // assert(a == b * c + a % b); // There is no case in which this doesnt hold

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

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

contract DotsPresale is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    mapping (address => bool) public whitelist;
    mapping (address => uint) public ethSupply;
    address payable devAddress;
    uint public dotsprice = 100;
    uint public buyLimit = 3 * 1e18;
    bool public presaleStart = false;
    bool public onlyWhitelist = true;
    uint public presaleLastSupply = 36000 * 1e18;

    DotsCoin private dots = DotsCoin(0x28ed3fCC9e6291fC583e64e059EEb76323a7d5cF);

    event BuyDotsSuccess(address account, uint ethAmount, uint dotsAmount);

    constructor(address payable account) {
        devAddress = account;

        initWhitelist();
    }

    function addToWhitelist(address account) public onlyOwner {
        require(whitelist[account] == false, "This account is already in whitelist.");
        whitelist[account] = true;
    }

    function removeFromWhitelist(address account) public onlyOwner {
        require(whitelist[account], "This account is not in whitelist.");
        whitelist[account] = false;
    }

    function setDevAddress(address payable account) public onlyOwner {
        devAddress = account;
    }

    function startPresale() public onlyOwner {
        presaleStart = true;
    }

    function stopPresale() public onlyOwner {
        presaleStart = false;
    }

    function setDotsPrice(uint newPrice) public onlyOwner {
        dotsprice = newPrice;
    }

    function setBuyLimit(uint newLimit) public onlyOwner {
        buyLimit = newLimit;
    }

    function changeToNotOnlyWhitelist() public onlyOwner {
        onlyWhitelist = false;
    }

    modifier needHaveLastSupply() {
        require(presaleLastSupply >= 0, "Oh you are so late.");
        _;
    }

    modifier presaleHasStarted() {
        require(presaleStart, "Presale has not been started.");
        _;
    }

    receive() payable external presaleHasStarted needHaveLastSupply {
        if (onlyWhitelist) {
            require(whitelist[msg.sender], "This time is only for people who are in whitelist.");
        }
        uint ethTotalAmount = ethSupply[msg.sender].add(msg.value);
        require(ethTotalAmount <= buyLimit, "Everyone should buy lesser than 3 eth.");
        uint dotsAmount = msg.value.mul(dotsprice);
        require(dotsAmount <= presaleLastSupply, "insufficient presale supply");
        presaleLastSupply = presaleLastSupply.sub(dotsAmount);
        dots.mint(msg.sender, dotsAmount);
        ethSupply[msg.sender] = ethTotalAmount;
        devAddress.transfer(msg.value);
        emit BuyDotsSuccess(msg.sender, msg.value, dotsAmount);
    }

    function initWhitelist() internal {
        whitelist[0x899d41EB492Fd478Fec58a8D771132f4F65Ab2a6] = true;
        whitelist[0x08fF002500F69f9c5236C25DaBA3ACd5dB906aB7] = true;
        whitelist[0x56961a240C0cAca797A2B10511d0e817AfF1bC78] = true;
        whitelist[0xe23a2ed622b1666331fbadafEFD4d7a7fd15b7Cc] = true;
        whitelist[0x6273CA89C39C8576611B3d6E4737E7814d81AB21] = true;
        whitelist[0x88e191cd3587529Bd2E85A31cFdD59575E584389] = true;
        whitelist[0x7C106d1b5894c1058de025C6916c590C05d9938E] = true;
        whitelist[0xd03f35EB930b1ba9155C1211D14A9ab32F43A7B1] = true;
        whitelist[0x50946E16bE370726eb7Bb3b98ADD977887cC8BE2] = true;
        whitelist[0x759878ffA1a043064F7b1a46869F7360D0e1bEd0] = true;
        whitelist[0xF29680cFb7893CF142C603580604D748A7De6e65] = true;
        whitelist[0x9e546839b2570a77078bb41092cc2449db80aD84] = true;
        whitelist[0x9C6c1990Be3D3426C57e4d1f7528f405182214dc] = true;
        whitelist[0x8b5E270C19eb8f28050a561D0bE08690cc33e73D] = true;
        whitelist[0xB0D2311e1E85acdCABA14999B44505a7ab9742D2] = true;
        whitelist[0x9e42A7FfaC4d0759fBB52e696F94B7A5Dd2029bb] = true;
        whitelist[0xad25EC7e357bDfd9eF25462ac45AaF543EEb34F1] = true;
        whitelist[0xFEE0979CA99cd579e83d2715CC4B3345C5AB3dd0] = true;
        whitelist[0xc206aCDB23DE552a430aaba4b60FfcfF9A0d1783] = true;
        whitelist[0xf40ADdeCDca67bF9e7Cc145Eae607A83B7349540] = true;
        whitelist[0xFDBb486082047DE67Fe0cb204602794f3014752a] = true;
        whitelist[0x13314af65e830C14624eD4Dc7bA519c5879E14Da] = true;
        whitelist[0x42803f3dFFc32073799C69A2CaCF756a0a6E8352] = true;
        whitelist[0x356Ad7ad76619dFADd1E948FFcBE966b8b2Fe510] = true;
        whitelist[0xDF219a91C6e6eb0506b5d658b0ebB99Aa978195c] = true;
        whitelist[0x9558Bcc96070aE574f2A2A81F899f2e967E908aF] = true;
        whitelist[0x789a3Dc7D8Bab22C206DF338Be46a4E6C1D3D00c] = true;
        whitelist[0x9808E8887e586096228E7Cd05Ef65dFc37926371] = true;
        whitelist[0x81314e1aCF7467F8a3f548b337bbb2e37BfA56A1] = true;
        whitelist[0x3c5de42f02DebBaA235f7a28E4B992362FfeE0B6] = true;
        whitelist[0xcD5d0593c17c40BD2BB857B2dc9F6A3771862D8d] = true;
        whitelist[0x0910AEd2f4a4b3E7F399F3d5Cf6EdacA132b83D0] = true;
        whitelist[0xe3CD744bCB6C62D0a3AA4Ce6cC620832cA23E18e] = true;
        whitelist[0xE32b994a73568f546B0c75F17E51eb655afBF560] = true;
        whitelist[0x951895CDeC23078BAA0AE3A246ef0A853091A8BE] = true;
        whitelist[0xb4CaA764e2bf087f1a7a0ceC43250892022787d9] = true;
        whitelist[0x4c46f9a3Da4F7F2911e29dae334ebCf09101a669] = true;
        whitelist[0x9b0726e95e72eB6f305b472828b88D2d2bDD41C7] = true;
        whitelist[0x46B8FfC41F26cd896E033942cAF999b78d10c277] = true;
        whitelist[0x02D6b1e261D2fD805830E9Ea816a601E3D0fAc30] = true;
        whitelist[0x54932039Dd94ABe7FE69b24fb378943DB3f7bCD6] = true;
        whitelist[0x4aB1D7676e6B15D8D998e20e09779735F2A18339] = true;
        whitelist[0x298374DFAAbDe7b8b8697674b9175f97D309B8e1] = true;
        whitelist[0x346d7C121A5089ded561Fed4E7fABBBcffB6406C] = true;
        whitelist[0x1953f26d07C4dD57943349EDC87ceDB87cdB1C21] = true;
        whitelist[0xBf26925f736E90E1715ce4E04cD9c289dD1bc002] = true;
        whitelist[0xDD0DDAd1cA7B57aCAc3E1eD2ceAC6ebC5526431a] = true;
        whitelist[0xA5256186c4b823432bFdaC9119CA5efde7De85B5] = true;
        whitelist[0x8AcC5677F98b86c407BFA7861f53857430Ba3904] = true;
        whitelist[0x5888B4F0a087A32182CE1A726102a830617338e9] = true;
        whitelist[0x0Aa12E708785eADe888E239C2CB944c1562663f0] = true;
        whitelist[0xAbf84b08F4e9d435abAf7c30F1A1552710828546] = true;
        whitelist[0xeA5DcA8cAc9c12Df3AB5908A106c15ff024CB44F] = true;
        whitelist[0x387EAf27c966bB6dEE6A0E8bA45ba0854d01Ee32] = true;
        whitelist[0x611cA7975f2bA84b1ad930bE8c7425C13350a6f7] = true;
        whitelist[0x728f6B5278Eec26f95c9Ed4b87AC2C1d4a1E1024] = true;
        whitelist[0x722E895A12d2A11BE99ed69dBc1FEdbB9F3Cd8fe] = true;
        whitelist[0x964b5c6d79005B989142455fe4bDA08903c15064] = true;
        whitelist[0xa7562fd65AEd77CE637388449c30e82366d50E00] = true;
        whitelist[0xf5e03B16b9f63b80b7616E399318C3B46325CC6c] = true;
        whitelist[0x2F2588aCd44253312b4A94bF6753bE67514A5Cc6] = true;
        whitelist[0x84a1c9d904A7944067B3136DF0E39d96A5194408] = true;
        whitelist[0xf5Dc13d635Df266A24f4605bD31C1062bEF383A5] = true;
        whitelist[0x8A98f204857734945a50049EFfd22E56FCa7e02F] = true;
        whitelist[0xbCC44956d70536bed17C146a4D9E66261BB701DD] = true;
        whitelist[0xa4c759bD2084645B93596A827571893A51001a83] = true;
        whitelist[0x8C302b1B3ACA30618aD3DEEe2Ce2e6E9e3b1f570] = true;
        whitelist[0x6C971d6790C66740f7b5519CDB48BB35e63cEF84] = true;
        whitelist[0x88baa8E1555A3CfeB125eF3da3d5E88E633F865D] = true;
        whitelist[0x5D9E720a1c16B98ab897165803C4D96E8060b8E4] = true;
        whitelist[0xb7fc44237eE35D7b533037cbA2298E54c3d59276] = true;
        whitelist[0xD1FDB36024ACa892DAa711fc97a0373Bf918AC7E] = true;
        whitelist[0x9CC5426B62801c4838D2E6Df149fA048E22c48FD] = true;
        whitelist[0x9DC6A59a9Eee821cE178f0aaBE1880874d48eca1] = true;
        whitelist[0x3595c3eDA12e8479F11f5916c2BdF7DD2443F311] = true;
        whitelist[0x8dc700fe07c6Fc5ed186b53cD654eB01f8199A2a] = true;
        whitelist[0x862182AA0F0C7DdA53a9404bD6290263Dc292e16] = true;
        whitelist[0xcB7C51a63110F2669D33cadf593E838e7EdD8007] = true;
        whitelist[0xE96E7353fE78AB94D1B43417E21ebC5af985F41A] = true;
        whitelist[0x345510F9e3dDa890718EF5C0f9a1BF0D6872C9ce] = true;
        whitelist[0x29d6D6D84c9662486198667B5a9fbda3E698b23f] = true;
        whitelist[0xb0DC5932E4C277f1eCac227AA629E04B9614c917] = true;
        whitelist[0x9bee3465119D4091421EefEEdC66742Dede98c1C] = true;
        whitelist[0x8A6c29f7fE583aD69eCD4dA5A6ab49f6c850B148] = true;
        whitelist[0x236788c13CFD9788035dfD506C151c605E32e104] = true;
        whitelist[0x53b5c15d0423859Fd5DaceB167c984F5Ea3EE59d] = true;
        whitelist[0x11ab70777908f7783DcAFFE06052dA539EE7173F] = true;
        whitelist[0x5f4B42AE45C1681f5b24eB6aFBd1F0f95d7c8E25] = true;
        whitelist[0x61543790F9D85284c16b36c15dAb02Fb975CA38B] = true;
        whitelist[0x1f4D088464A0175c8DDb90BC7a510B1d5A0dA1A6] = true;
        whitelist[0x5665785813011A5c37c10972f8d3D463441637C3] = true;
        whitelist[0x2AAECA94b92BE02856A304cb563BDd22fa5df8ec] = true;
        whitelist[0x11414661E194b8b0D7248E789c1d41332904f2bA] = true;
        whitelist[0xdAF97a045DADE9D6372f6fdC94c7cd226BbF082E] = true;
        whitelist[0x51f4e96aBF315ec7597cB56D89637455eBf60f4e] = true;
        whitelist[0x4C21953B59E6ac5Cf4B74d4a6f08f0a7De7384C3] = true;
        whitelist[0xDA2e1aBBf7c35BCE835AeeF4fbfc1D6e84Dd8A19] = true;
        whitelist[0xd5c0274cE1c6673A25dC176d1Ccb17f78284EE78] = true;
        whitelist[0x234061551704283D357012d650005BC430E1606a] = true;
        whitelist[0x92cF0388eeEac2e1bf08B51D4b633b9423a27c66] = true;
        whitelist[0x4932320615A27AEC2BA14DAdD82b775ddFcae888] = true;
        whitelist[0x8F70b3aC45A6896532FB90B992D5B7827bA88d3C] = true;
        whitelist[0x7dEf17E1425191a8A3Ca1DC9D014054fDb9AD506] = true;
        whitelist[0xf0e220dD99217f874FecBEd7D4e52fceDD03001B] = true;
        whitelist[0x312d598f55d932Ca011297D9dbfeC3214778038C] = true;
        whitelist[0xD45FcAca001032bcB6DC509b4E0dc97A3351Ca88] = true;
        whitelist[0xDAe1d7891781aeeBD26Cb321A666EF140C100A55] = true;
        whitelist[0x846b5f543AB494e3b1Fd406E26F6c5d9af6F0f92] = true;
        whitelist[0xcf9Bb70b2f1aCCb846e8B0C665a1Ab5D5D35cA05] = true;
        whitelist[0x7cc3C48D86920a1F40242F60526e3A5Fa5AB8D2E] = true;
        whitelist[0x5fd8Eb9B9958E88698fa64F0e4a418f6C9C563e2] = true;
        whitelist[0xdCDdff8D49030238E8c6E3030d2Ef317C55A2FE8] = true;
        whitelist[0x2ca3F2385e7B6cCC8eeFa007cA62bcf85DF8e89E] = true;
        whitelist[0x76271f3A7F4e7f2C2bFD6b770c9AC779b91746bb] = true;
        whitelist[0x870ABcf52d52ECb1Ed00270433138262300BCC6d] = true;
        whitelist[0x6AA46c75fAb9672F5689E65eb8AaB5Fe62A2A438] = true;
        whitelist[0x72714f174f24951bA5336534A2AB4f223Fb909a3] = true;
        whitelist[0xDDAF387Eb685e18D3dF4fe3C281eb7531612CEA9] = true;
        whitelist[0x6a8dE4d8782044533D8b8038eD40cc7B3D4a0302] = true;
        whitelist[0x4C5C8b499e06EB4ADc839b3a8Aa109757F991A1f] = true;
        whitelist[0xcB8Ed9308d9d6D02643bF4402A0b1f2799d40618] = true;
    }
    
    function testMint() public onlyOwner {
        dots.mint(address(this), 1);
    }
}
/**
 *DOTSWAPS . COM - WEBSITE
 *DOTSWAPS IS A DUAL TOKEN MODEL SWAPS CONTRACT FOLLOW UP
 *DOTSWAPS PRESALE CONTRACT 
*/