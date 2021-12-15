/**
 *Submitted for verification at BscScan.com on 2021-12-15
*/

// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File contracts/interfaces/IKAP20.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

interface IKAP20 {
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);

    function totalSupply() external view returns (uint256);

    function balanceOf(address tokenOwner) external view returns (uint256 balance);

    function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);

    function transfer(address to, uint256 tokens) external returns (bool success);

    function approve(address spender, uint256 tokens) external returns (bool success);
    
    function internalTransfer(address from, address to, uint256 value) external returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool success);

    function adminTransfer(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);
}


// File contracts/interfaces/IKYC.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

interface IKYC {
    function kycsLevel(address _addr) external view returns (uint256);
}


// File contracts/interfaces/IAdminProject.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

interface IAdminProject {
    function isSuperAdmin(address _addr, string calldata _project) external view returns (bool);

    function isAdmin(address _addr, string calldata _project) external view returns (bool);
}


// File contracts/abstract/Authorization.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

abstract contract Authorization {
    IAdminProject public admin;
    string public project = "RS";

    modifier onlySuperAdmin() {
        require(admin.isSuperAdmin(msg.sender, project), "Restricted only super admin");
        _;
    }

    modifier onlySuperAdminOrAdmin() {
        require(
            admin.isSuperAdmin(msg.sender, project) || admin.isAdmin(msg.sender, project),
            "Restricted only super admin or admin"
        );
        _;
    }

    function setAdmin(address _admin) external onlySuperAdmin {
        admin = IAdminProject(_admin);
    }
}


// File contracts/POPToken.sol

pragma solidity ^0.6.6;



contract POPCoinToken is IKAP20, Authorization {
    string public name = "POPCOIN TOKEN";
    string public symbol = "POP";
    uint256 public decimals = 18;
    uint256 public hardcap;
    uint256 public year = 1;
    uint256 private _totalSupply;
    uint256 private _maxHardcapNumber = 10000000000 * (10**18);
    IKYC public kyc;
    address public owner;
    address public router;
    bool public paused;
    bool public isActivatedOnlyKycAddress;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 value);
    event Paused(address account);
    event Unpaused(address account);
    event StepUpHardcap(address indexed owner, uint256 year, uint256 hardcap);

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowed;
    mapping(address => bool) public blacklist;

    modifier onlyOwner() {
        require(msg.sender == owner, "Restricted owner");
        _;
    }
    modifier onlyRouter() {
        require(msg.sender == router, "Restricted router");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    constructor(
        uint256 _hardcap,
        address _owner,
        address _admin,
        address _kyc
    ) public {
        hardcap = _hardcap;
        owner = _owner;
        admin = IAdminProject(_admin);
        kyc = IKYC(_kyc);
    }

    function setKYC(address _kyc) external onlySuperAdmin {
        kyc = IKYC(_kyc);
    }

    function setOwner(address _newOwner) external onlyOwner returns (bool) {
        owner = _newOwner;
        return true;
    }

    function setRouter(address _newRouter) external onlyOwner returns (bool) {
        router = _newRouter;
        return true;
    }

    function activateOnlyKycAddress() external onlySuperAdmin {
        isActivatedOnlyKycAddress = true;
    }

    function mint(uint256 amount, address _toAddr) public whenNotPaused onlyOwner {
        require(!blacklist[_toAddr], "Address is in the blacklist");
        require(amount + _totalSupply <= hardcap, "balance more than hardcap");
        _balances[_toAddr] += amount;
        _totalSupply += amount;
        emit Transfer(address(0), _toAddr, amount);
    }

    function burn(uint256 _value, address _toAddr) public whenNotPaused onlyOwner {
        require(!blacklist[_toAddr], "Address is in the blacklist");
        _balances[_toAddr] -= _value;
        _totalSupply -= _value;
        emit Transfer(_toAddr, address(0), _value);
    }

    function stepUpHardcap() public whenNotPaused onlyOwner returns (bool) {
        require(!blacklist[msg.sender], "Address is in the blacklist");
        year += 1;
        if ((hardcap <= _maxHardcapNumber) && (year <= 4)) {
            hardcap = (hardcap + (((_maxHardcapNumber * 25) / 100)));
        } else {
            hardcap = (hardcap + (((_totalSupply * 4) / 100)));
        }
        emit StepUpHardcap(msg.sender, year, hardcap);
        return true;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _addr) public view override returns (uint256) {
        return _balances[_addr];
    }

    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return _allowed[_owner][_spender];
    }

    function approve(address _spender, uint256 _value) public override whenNotPaused returns (bool) {
        require(!blacklist[msg.sender], "Address is in the blacklist");
        _approve(msg.sender, _spender, _value);
        return true;
    }

    function _approve(
        address _owner,
        address spender,
        uint256 amount
    ) internal {
        require(_owner != address(0), "KAP20: approve from the zero address");
        require(spender != address(0), "KAP20: approve to the zero address");

        _allowed[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function transfer(address _to, uint256 _value) public override whenNotPaused returns (bool) {
        require(_value <= _balances[msg.sender], "Insufficient Balance");
        require(blacklist[msg.sender] == false && blacklist[_to] == false, "Address is in the blacklist");
        _balances[msg.sender] -= _value;
        _balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override whenNotPaused returns (bool) {
        require(_value <= _balances[_from]);
        require(_value <= _allowed[_from][msg.sender]);
        require(blacklist[_from] == false && blacklist[_to] == false, "Address is in the blacklist");

        _balances[_from] -= _value;
        _balances[_to] += _value;
        _allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function internalTransfer(
        address _from,
        address _to,
        uint256 _value
    ) external override onlyRouter returns (bool) {
        require(_balances[_from] >= _value, "Transfer amount exceed balance");
        require(_to != address(0), "Transfer to zero address");
        _balances[_from] -= _value;
        _balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function adminTransfer(
        address _from,
        address _to,
        uint256 _value
    ) external override onlyOwner returns (bool) {
        if (isActivatedOnlyKycAddress) {
            require(kyc.kycsLevel(_from) > 1 && kyc.kycsLevel(_to) > 1, "Admin can control only KYC Address");
        }

        require(_balances[_from] >= _value, "Transfer amount exceed balance");
        require(_to != address(0), "Transfer to zero address");
        _balances[_from] -= _value;
        _balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function pause() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    function addBlacklist(address _addr) external onlyOwner {
        blacklist[_addr] = true;
    }

    function revokeBlacklist(address _addr) external onlyOwner {
        blacklist[_addr] = false;
    }
}