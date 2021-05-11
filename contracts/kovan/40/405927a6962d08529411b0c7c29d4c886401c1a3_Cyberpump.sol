/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

contract Songspire {
    struct Envoy {
        bool exists;
        bool active;
        uint256 power;
        mapping (address => bool) manager;
    }

    mapping (address => Envoy) private _envoys;

    uint256 private ENVOY_THRESHOLD;

    event EnvoyThresholdChanged(uint256 threshold);
    event NewEnvoy(address indexed account);
    event EnvoyBecameActive(address indexed account);
    event EnvoyBecameInactive(address indexed account);
    event EnvoyIncreasedPower(address indexed account, uint256 amount);
    event EnvoyDecreasedPower(address indexed account, uint256 amount);
    event EnvoyAddedManagement(address indexed account, address indexed sweatshop);
    event EnvoyRemovedManagement(address indexed account, address indexed sweatshop);

    function _addEnvoy(address _account) internal virtual {
        Envoy storage envoy = _envoys[_account];
        envoy.exists = true;
        emit NewEnvoy(_account);
    }

    function _setEnvoyActive(address _account) internal virtual {
        Envoy storage envoy = _envoys[_account];
        envoy.active = true;
        emit EnvoyBecameActive(_account);
    }

    function _setEnvoyInactive(address _account) internal virtual {
        Envoy storage envoy = _envoys[_account];
        envoy.active = false;
        emit EnvoyBecameInactive(_account);
    }

    function _increaseEnvoyPower(address _account, uint256 _power) internal virtual {
        Envoy storage envoy = _envoys[_account];
        envoy.power += _power;
        emit EnvoyIncreasedPower(_account, _power);
    }

    function _decreaseEnvoyPower(address _account, uint256 _power) internal virtual {
        Envoy storage envoy = _envoys[_account];
        envoy.power -= _power;
        emit EnvoyDecreasedPower(_account, _power);
    }

    function _addManager(address _account, address _sweatshop) internal virtual {
        Envoy storage envoy = _envoys[_account];
        envoy.manager[_sweatshop] = true;
        emit EnvoyAddedManagement(_account, _sweatshop);
    }

    function _removeManager(address _account, address _sweatshop) internal virtual {
        Envoy storage envoy = _envoys[_account];
        envoy.manager[_sweatshop] = false;
        emit EnvoyRemovedManagement(_account, _sweatshop);
    }

    function _setEnvoyThreshold(uint256 _thresh) internal virtual {
        ENVOY_THRESHOLD = _thresh;
        emit EnvoyThresholdChanged(_thresh);
    }

    function _checkEnvoyForThreshold(address _account) internal view returns (bool) {
        Envoy storage envoy = _envoys[_account];

        if (envoy.power >= ENVOY_THRESHOLD) {
            return true;
        } else {
            return false;
        }
    }

    function getEnvoyPower(address _account) public view returns (uint256) {
        Envoy storage envoy = _envoys[_account];
        return envoy.power;
    }

    function getEnvoyThreshold() public view returns (uint256) {
        return ENVOY_THRESHOLD;
    }

    function isEnvoy(address _account) public view returns (bool) {
        Envoy storage envoy = _envoys[_account];
        return envoy.exists;
    }

    function isActiveEnvoy(address _account) public view returns (bool) {
        Envoy storage envoy = _envoys[_account];
        return envoy.active;
    }

    function isEnvoyManagerOf(address _account, address _product) public view returns (bool) {
        Envoy storage envoy = _envoys[_account];
        return envoy.manager[_product];
    }

    modifier onlyEnvoys() {
        require(isEnvoy(msg.sender), "Songspire: user is not an Envoy.");
        _;
    }

    modifier onlyActiveEnvoys() {
        require(isActiveEnvoy(msg.sender), "Songspire: user is not an active Envoy.");
        _;
    }
}

interface ISweatshop {
    function create(address caller) external returns (address);
    function retire() external;
}

contract NightCorp {
    struct ProductLine {
        string name;
        uint256 createdtime; // block.timestamp
        address inventor;
        bool status; // active or retired
        address sweatshop; // factory contract
        uint256 creations;
        mapping (uint256 => Product) products;
    }
    struct Product {
        uint256 createdtime; // block.timestamp
        address creator;
        address product;
    }

    // @notice acts as an ID number
    uint256 internal numProductLines;

    /// @notice maps productLineID to ProductLine data
    mapping (uint256 => ProductLine) public productLines;

    event NewProductLine(
        uint256 id,
        string name,
        uint256 createdtime,
        address inventor,
        address indexed sweatshop
    );
    event RetiredProductLine(uint256 id, address actor);
    event NewProductCreated(
        uint256 sweatshopID,
        address sweatshop,
        uint256 createdtime,
        address creator,
        address product
    );

    /// @notice creates a new active ProductLine in storage
    /// @param name is string of what the product will be
    /// @param inventor is address of the person who wrote the sweatshop
    /// @param sweatshop is contract address for a factory to create a product
    function _addProductLine(
        string memory name,
        address inventor,
        address sweatshop
    ) internal virtual {
        ProductLine storage pl = productLines[numProductLines];
        pl.name = name;
        pl.createdtime = block.timestamp;
        pl.status = true;
        pl.inventor = inventor;
        pl.sweatshop = sweatshop;

        emit NewProductLine(numProductLines, pl.name, pl.createdtime, pl.inventor, pl.sweatshop);

        numProductLines++;
    }

    /// @notice sets existing ProductLine's status to false, preventing sweatshop from being used
    function _retireProductLine(uint sweatshopID) internal virtual {
        ProductLine storage pl = productLines[sweatshopID];
        require(msg.sender == pl.inventor, "NightCorp: retirement caller is not inventor.");
        ISweatshop(pl.sweatshop).retire();
        pl.status = false;

        emit RetiredProductLine(sweatshopID, msg.sender);
    }

    function _createProduct(uint sweatshopID, address caller) internal virtual returns (address) {
        ProductLine storage pl = productLines[sweatshopID];
        require(pl.status == true, "NightCorp: product line has been retired.");
        address result = ISweatshop(pl.sweatshop).create(caller);

        Product storage prod = pl.products[pl.creations];
        prod.createdtime = block.timestamp;
        prod.creator = msg.sender;
        prod.product = result;

        emit NewProductCreated(sweatshopID, pl.sweatshop, prod.createdtime, prod.creator, prod.product);

        pl.creations++;
        return result;
    }
}

contract Treasury {
    event LogTreasuryETHTransfer(address indexed recipient, uint amount);
    event LogTreasuryTokenTransfer(address indexed token, address indexed recipient, uint amount);

    receive() external payable {}

    function _transferETH(address payable recipient, uint amount) private {
        require(recipient != address(0), "CyberTreasury: cannot transfer to 0x0.");
        require(address(this).balance >= amount, "CyberTreasury: not enough ETH for transfer.");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "CyberTreasury: unable to send ETH, recipient may have reverted");
        emit LogTreasuryETHTransfer(recipient, amount);
    }

    function _transferERC20(address token, address to, uint amount) private {
        require(IERC20(token).balanceOf(address(this)) >= amount, "CyberTreasury: token balance insufficient");
        IERC20(token).transfer(to, amount);
        emit LogTreasuryTokenTransfer(token, to, amount);
    }
}

contract Cyberpump is Treasury, Songspire, NightCorp {
    IERC20 public immutable JOI;

    event AddedStake(address indexed account, uint256 amount);
    event RemovedStake(address indexed account, uint256 amount);

    constructor(IERC20 _joi) {
        JOI = _joi;

        // must have 1 JOI staked to become ActiveEnvoy
        _setEnvoyThreshold(1 * (10**18));
    }

    function stakeJOI(uint256 _amount) public {
        JOI.approve(address(this), _amount);
        JOI.transferFrom(msg.sender, address(this), _amount);

        if (isEnvoy(msg.sender)) {
            _increaseEnvoyPower(msg.sender, _amount);
        } else {
            _addEnvoy(msg.sender);
            _increaseEnvoyPower(msg.sender, _amount);
        }

        if (_checkEnvoyForThreshold(msg.sender)) {
            _setEnvoyActive(msg.sender);
        }

        emit AddedStake(msg.sender, _amount);
    }

    function unstakeJOI(uint256 _amount) public onlyEnvoys {
        require(getEnvoyPower(msg.sender) >= _amount, "Cyberpump: unstake amount is greater than staked.");
        _decreaseEnvoyPower(msg.sender, _amount);

        if (!_checkEnvoyForThreshold(msg.sender)) {
            _setEnvoyInactive(msg.sender);
        }

        JOI.transfer(msg.sender, _amount);
        emit RemovedStake(msg.sender, _amount);
    }

    function addProductLine(string memory name, address inventor, address sweatshop) public onlyActiveEnvoys {
        _addProductLine(name, inventor, sweatshop);
        _addManager(inventor, sweatshop);
    }

    function retireProductLine(uint productLineID) public onlyActiveEnvoys {
        _retireProductLine(productLineID);
    }

    function createProduct(uint productLineID) public onlyActiveEnvoys returns (address) {
        return _createProduct(productLineID, msg.sender);
    }
}