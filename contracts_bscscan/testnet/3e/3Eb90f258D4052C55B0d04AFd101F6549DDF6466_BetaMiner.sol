// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.0;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./TransferHelper.sol";
import "./IBEP20.sol";
import "./LpWallet.sol";
import "./Partner.sol";
import "./BetaMinepool.sol";

contract BetaMiner is ReentrancyGuard {
    using TransferHelper for address;
    using SafeMath for uint256;

    address private _betaaddr;
    address private _owner;
    address private _feeowner;
    BetaMinePool private _minepool;

    mapping(address => address) internal _parents;
    mapping(address => address[]) _mychilders;
    mapping(address => PoolInfo) _lpPools;
    mapping(address => mapping(address => uint256)) _userLphash;
    mapping(address => mapping(uint256 => uint256)) _userlevelhashtotal;
    mapping(address => mapping(address => UserInfo)) _userInfos;
    mapping(address => uint256) _nowtotalhash;

    address[] _lpaddresses;
    uint256[2] _levelconfig;

    struct PoolInfo {
        LpWallet poolwallet;
        uint256 hashrate;
    }

    struct UserInfo {
        uint256 selfhash;
        uint256 teamhash;
        uint256 lastblock;
    }

    event BindingParents(address indexed user, address inviter);
    event TradingPooladded(address indexed tradetoken);
    event UserBuied(address indexed tokenaddress, uint256 amount);
    event TakedBack(address indexed tokenaddress);

    constructor() {
        _owner = msg.sender;
    }

    function InitalContract(address betaToken, address feeowner) public {
        require(msg.sender == _owner);
        require(_feeowner == address(0));
        _betaaddr = betaToken;
        _feeowner = feeowner;
        _minepool = new BetaMinePool(betaToken, _owner);
        _parents[msg.sender] = address(_minepool);

        _levelconfig = [200, 100];
    }

    function setOwner(address newOwner) public returns (bool) {
        require(msg.sender == _owner, "sender must owner");
        _owner = newOwner;
        return true;
    }

    function getOwner() public view returns (address) {
        return _owner;
    }

    function setFeeOwner(address newFeeOwner) public returns (bool) {
        require(msg.sender == _owner, "sender must owner");
        _feeowner = newFeeOwner;
        return true;
    }

    function getFeeOwner() public view returns (address) {
        return _feeowner;
    }

    function getMinerPoolAddress() public view returns (address) {
        return address(_minepool);
    }

    function getMyChilders(address user)
        public
        view
        returns (address[] memory)
    {
        return _mychilders[user];
    }

    function getParent(address user) public view returns (address) {
        return _parents[user];
    }

    function bindParent(address parent) public returns (bool) {
        require(_parents[msg.sender] == address(0), "Already bind");
        require(parent != address(0), "ERROR parent");
        require(parent != msg.sender, "ERROR parent");
        require(_parents[parent] != address(0));
        _parents[msg.sender] = parent;
        _mychilders[parent].push(msg.sender);
        emit BindingParents(msg.sender, parent);
        return true;
    }

    function setParentByAdmin(address user, address parent)
        public
        returns (bool)
    {
        require(_parents[user] == address(0), "Already bind");
        require(msg.sender == _owner, "sender must deployer");
        _parents[user] = parent;
        _mychilders[parent].push(user);
        return true;
    }

    function addTradingPool(address tokenAddress, uint256 rate)
        public
        returns (bool)
    {
        require(msg.sender == _owner);
        require(rate > 0, "EOOOR RATE");
        require(_lpPools[tokenAddress].hashrate == 0, "LP EXISTS");

        LpWallet wallet = new LpWallet(
            tokenAddress,
            _betaaddr,
            _feeowner,
            _owner
        );
        _lpPools[tokenAddress] = PoolInfo({poolwallet: wallet, hashrate: rate});
        _lpaddresses.push(tokenAddress);
        emit TradingPooladded(tokenAddress);
        return true;
    }

    function getWalletAddress(address lptoken) public view returns (address) {
        return address(_lpPools[lptoken].poolwallet);
    }

    function getTotalHash(address lptoken) public view returns (uint256) {
        return _nowtotalhash[lptoken];
    }

    function getMyLpInfo(address user, address tokenaddress)
        public
        view
        returns (uint256[3] memory)
    {
        uint256[3] memory bb;
        bb[0] = _lpPools[tokenaddress].poolwallet.getBalance(user, true);
        bb[1] = _lpPools[tokenaddress].poolwallet.getBalance(user, false);
        bb[2] = _userLphash[user][tokenaddress];
        return bb;
    }

    function stake(address tokenAddress, uint256 amount)
        public
        nonReentrant
        returns (bool)
    {
        require(amount > 0, "The number must be greater than 0");

        tokenAddress.safeTransferFrom(
            msg.sender,
            address(_lpPools[tokenAddress].poolwallet),
            amount
        );
        tokenAddress.safeTransferFrom(msg.sender, address(_feeowner), amount.div(10));

        _lpPools[tokenAddress].poolwallet.addBalance(
            msg.sender,
            amount,
            amount.div(10)
        );
        _userLphash[msg.sender][tokenAddress] = _userLphash[msg.sender][
            tokenAddress
        ].add(amount);

        address parent = msg.sender;
        uint256 dhash;

        for (uint256 i = 0; i < 2; i++) {
            parent = _parents[parent];
            if (parent == address(0)) break;

            uint256 levelconfig = _levelconfig[i];
            uint256 addhash = amount.mul(levelconfig).div(1000);
            dhash = dhash.add(addhash);
            UserHashChanged(
                tokenAddress,
                parent,
                0,
                addhash,
                true,
                block.number
            );
        }
        UserHashChanged(
            tokenAddress,
            msg.sender,
            amount,
            0,
            true,
            block.number
        );
        logCheckPoint(tokenAddress, amount.add(dhash), true);
        emit UserBuied(tokenAddress, amount);
        return true;
    }

    function logCheckPoint(
        address tokenAddress,
        uint256 totalhashdiff,
        bool add
    ) private {
        if (add) {
            _nowtotalhash[tokenAddress] = _nowtotalhash[tokenAddress].add(
                totalhashdiff
            );
        } else {
            _nowtotalhash[tokenAddress] = _nowtotalhash[tokenAddress].sub(
                totalhashdiff
            );
        }
    }

    function UserHashChanged(
        address tokenAddress,
        address user,
        uint256 selfhash,
        uint256 teamhash,
        bool add,
        uint256 blocknum
    ) private {
        UserInfo memory info = _userInfos[user][tokenAddress];
        info.lastblock = blocknum;
        if (selfhash > 0) {
            if (add) {
                info.selfhash = info.selfhash.add(selfhash);
            } else info.selfhash = info.selfhash.sub(selfhash);
        }
        if (teamhash > 0) {
            if (add) {
                info.teamhash = info.teamhash.add(teamhash);
            } else {
                if (info.teamhash > teamhash)
                    info.teamhash = info.teamhash.sub(teamhash);
                else info.teamhash = 0;
            }
        }
        _userInfos[user][tokenAddress] = info;
    }

    function exit(address tokenAddress) public nonReentrant returns (bool) {
        uint256 balancea = _lpPools[tokenAddress].poolwallet.getBalance(
            msg.sender,
            true
        );

        _userLphash[msg.sender][tokenAddress] = 0;

        address parent = msg.sender;
        uint256 dhash;

        for (uint256 i = 0; i < 2; i++) {
            parent = _parents[parent];
            if (parent == address(0)) break;

            uint256 levelconfig = _levelconfig[i];
            uint256 subhash = _userLphash[msg.sender][tokenAddress]
                .mul(levelconfig)
                .div(1000);
            dhash = dhash.add(
                _userLphash[msg.sender][tokenAddress].mul(levelconfig).div(1000)
            );
            UserHashChanged(
                tokenAddress,
                parent,
                0,
                subhash,
                false,
                block.number
            );
        }
        UserHashChanged(
            tokenAddress,
            msg.sender,
            _userLphash[msg.sender][tokenAddress],
            0,
            false,
            block.number
        );
        logCheckPoint(
            tokenAddress,
            _userLphash[msg.sender][tokenAddress].add(dhash),
            false
        );
        _lpPools[tokenAddress].poolwallet.TakeBack(
            msg.sender,
            balancea,
            0
        );
        emit TakedBack(tokenAddress);
        return true;
    }
}