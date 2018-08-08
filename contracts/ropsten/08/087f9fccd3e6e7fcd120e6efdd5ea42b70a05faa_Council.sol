pragma solidity ^0.4.24;

// File: contracts/council/CouncilInterface.sol

interface CouncilInterface {
    function getCdRate() external view returns (uint256);
    function getDepositRate() external view returns (uint256);
    function getInitialDeposit() external view returns (uint256);
    function getUserPaybackRate() external view returns (uint256);
    function getReportRegistrationFee() view external returns (uint256);
    function getUserPaybackPool() external view returns (address);
    function getDepositPool() external view returns (address);
    function getToken() external view returns (address);
    function getRoleManager() external view returns (address);
    function getContentsManager() external view returns (address);
    function getFundManager() external view returns (address);
    function getPixelDistributor() external view returns (address);
    function getMarketer() external view returns (address);
}

// File: contracts/utils/ExtendsOwnable.sol

contract ExtendsOwnable {

    mapping(address => bool) owners;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipExtended(address indexed host, address indexed guest);

    modifier onlyOwner() {
        require(owners[msg.sender]);
        _;
    }

    constructor() public {
        owners[msg.sender] = true;
    }

    function addOwner(address guest) public onlyOwner {
        require(guest != address(0));
        owners[guest] = true;
        emit OwnershipExtended(msg.sender, guest);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owners[newOwner] = true;
        delete owners[msg.sender];
        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// File: contracts/utils/ValidValue.sol

contract ValidValue {
  modifier validRange(uint256 _value) {
      require(_value > 0);
      _;
  }

  modifier validAddress(address _account) {
      require(_account != address(0));
      require(_account != address(this));
      _;
  }

  modifier validString(string _str) {
      require(bytes(_str).length > 0);
      _;
  }
}

// File: contracts/council/Council.sol

/**
 * @title Council contract
 *
 * @author Junghoon Seo - <jh.seo@battleent.com>
 */
contract Council is ExtendsOwnable, ValidValue, CouncilInterface {
    uint256 cdRate;
    uint256 depositRate;
    uint256 initialDeposit;
    uint256 userPaybackRate;
    uint256 reportRegistrationFee;
    address userPaybackPool;
    address depositPool;
    address token;
    address roleManager;
    address contentsManager;
    address fundManager;
    address pixelDistributor;
    address marketer;

    constructor(
        uint256 _cdRate,
        uint256 _depositRate,
        uint256 _initialDeposit,
        uint256 _userPaybackRate,
        uint256 _reportRegistrationFee,
        address _token)
        public
        validRange(_cdRate)
        validRange(_depositRate)
        validRange(_initialDeposit)
        validRange(_userPaybackRate)
        validRange(_reportRegistrationFee)
        validAddress(_token)
    {
        cdRate = _cdRate;
        depositRate = _depositRate;
        initialDeposit = _initialDeposit;
        userPaybackRate = _userPaybackRate;
        reportRegistrationFee = _reportRegistrationFee;
        token = _token;

        emit RegisterCouncil(msg.sender, _cdRate, _depositRate, _initialDeposit, _userPaybackRate, _reportRegistrationFee, _token);
    }

    function setCdRate(uint256 _cdRate) external onlyOwner validRange(_cdRate) {
        cdRate = _cdRate;

        emit ChangeDistributionRate(msg.sender, "cd rate", _cdRate);
    }

    function getCdRate() external view returns (uint256) {
        return cdRate;
    }

    function setDepositRate(uint256 _depositRate) external onlyOwner validRange(_depositRate) {
        depositRate = _depositRate;

        emit ChangeDistributionRate(msg.sender, "deposit rate", _depositRate);
    }

    function getDepositRate() external view returns (uint256) {
        return depositRate;
    }

    function setInitialDeposit(uint256 _initialDeposit) external onlyOwner validRange(_initialDeposit) {
        initialDeposit = _initialDeposit;

        emit ChangeDistributionRate(msg.sender, "initial deposit", _initialDeposit);
    }

    function getInitialDeposit() external view returns (uint256) {
        return initialDeposit;
    }

    function setUserPaybackRate(uint256 _userPaybackRate) external onlyOwner validRange(_userPaybackRate) {
        userPaybackRate = _userPaybackRate;

        emit ChangeDistributionRate(msg.sender, "user payback rate", _userPaybackRate);
    }

    function getUserPaybackRate() external view returns (uint256) {
        return userPaybackRate;
    }

    function setReportRegistrationFee(uint256 _reportRegistrationFee) external onlyOwner validRange(_reportRegistrationFee) {
        reportRegistrationFee = _reportRegistrationFee;

        emit ChangeDistributionRate(msg.sender, "report registration fee", _reportRegistrationFee);
    }

    function getReportRegistrationFee() view external returns (uint256) {
        return reportRegistrationFee;
    }

    function setUserPaybackPool(address _userPaybackPool) external onlyOwner validAddress(_userPaybackPool) {
        userPaybackPool = _userPaybackPool;

        emit ChangeAddress(msg.sender, "user payback pool", _userPaybackPool);
    }

    function getUserPaybackPool() external view returns (address) {
        return userPaybackPool;
    }

    function setDepositPool(address _depositPool) external onlyOwner validAddress(_depositPool) {
        depositPool = _depositPool;

        emit ChangeAddress(msg.sender, "deposit pool", _depositPool);
    }

    function getDepositPool() external view returns (address) {
        return depositPool;
    }

    function getToken() external view returns (address) {
        return token;
    }

    function setRoleManager(address _roleManager) external onlyOwner validAddress(_roleManager) {
        roleManager = _roleManager;

        emit ChangeAddress(msg.sender, "role manager", _roleManager);
    }

    function getRoleManager() external view returns (address) {
        return roleManager;
    }

    function setContentsManager(address _contentsManager) external onlyOwner validAddress(_contentsManager) {
        contentsManager = _contentsManager;

        emit ChangeAddress(msg.sender, "contents manager", _contentsManager);
    }

    function getContentsManager() external view returns (address) {
        return contentsManager;
    }

    function setFundManager(address _fundManager) external onlyOwner validAddress(_fundManager) {
        fundManager = _fundManager;

        emit ChangeAddress(msg.sender, "fund manager", _fundManager);
    }

    function getFundManager() external view returns (address) {
        return fundManager;
    }

    function setPixelDistributor(address _pixelDistributor) external onlyOwner validAddress(_pixelDistributor) {
        pixelDistributor = _pixelDistributor;

        emit ChangeAddress(msg.sender, "pixel distributor", _pixelDistributor);
    }

    function getPixelDistributor() external view returns (address) {
        return pixelDistributor;
    }

    function setMarketer(address _marketer) external onlyOwner validAddress(_marketer) {
        marketer = _marketer;

        emit ChangeAddress(msg.sender, "marketer", _marketer);
    }

    function getMarketer() external view returns (address) {
        return marketer;
    }

    event RegisterCouncil(address _sender, uint256 _cdRate, uint256 _deposit, uint256 _initialDeposit, uint256 _userPaybackRate, uint256 _reportRegistrationFee, address _token);
    event ChangeDistributionRate(address _sender, string _name, uint256 _value);
    event ChangeAddress(address _sender, string addressName, address _addr);
}