// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "./interface/IDC2CFactory.sol";
import "./interface/IDC2CDeployer.sol";
import "./abstract/Ownable.sol";

// DC2CFactory: deploys DC2CPool and manages ownership and control over protocol fees
contract DC2CFactory is IDC2CFactory, Ownable{

    address public poolDeployer;
    address public tokenDeployer;

    mapping(address => bool) public pools;
    mapping(address => address) public getDC2CPool;
    mapping(address => address) public getDToken;
    address[] public allToken;

    mapping(address => address) public inviters;
    mapping(address => bytes8) public inviter2Code;
    mapping(bytes8 => address) public code2Inviter;

    Config public config;
    uint256 public accCnt;

    event ConfigChanged(address indexed org, uint256 fee, uint256 inviterPer);

    constructor(address _poolDeployer, address _tokenDeployer) {
        poolDeployer = _poolDeployer;
        tokenDeployer = _tokenDeployer;

        config = Config({
            org:msg.sender,   // org default owner
            fee: 3,           // fee default 0.3%
            returnPer:100,    //percent value of fee will return to payer , inviter, stockholder
            oldPer:30,        //percent value of returnPer will return to old stockholder
            inviterPer:20,    //percent of returnPer token will be send to inviter
            topNum: 32
            });
    }

    modifier onlyPool() {
        require(pools[msg.sender] == true, "DC2CFactory: caller is not the pool");
        _;
    }

    //deploy DC2CPool
    function createPool(
        address token//external token,eg: USDT
    ) external override returns (bool) {
        require(token != address(0), 'DC2CFactory: EXT_TOKEN_INVALID');
        require(getDC2CPool[token] == address(0), 'DC2CFactory: TOKEN_EXIST');

        getDToken[token] = IDC2CDeployer(tokenDeployer).develop(address(this), token);

        address pool = IDC2CDeployer(poolDeployer).develop(address(this), token);
        getDC2CPool[token] = pool;
        pools[pool] = true;

        allToken.push(token);
        emit DC2CPoolCreated(token);
        return true;
    }

    //update config
    function setConfig(address org, uint256 fee,  uint256 returnPer, uint256 oldPer, uint256 inviterPer, uint256 topNum) external override onlyGovernor{
        require(org != address(0), 'DC2CFactory: ORGANIZER_INVALID');
        require(fee <= 1000, 'DC2CFactory: FEE_RATIO_INVALID');
        require(returnPer <= 100, 'DC2CFactory: RETURN_P_INVALID');
        require(oldPer <= 100, 'DC2CFactory: OLD_P_INVALID');
        require(inviterPer<= 100, 'DC2CFactory: INVITER_P_INVALID');
        require(topNum > config.topNum, 'DC2CFactory: TOP_NUM_INVALID');

        config = Config({org:org, fee:fee,  returnPer:returnPer, oldPer:oldPer, inviterPer:inviterPer, topNum:topNum});
        emit ConfigChanged(org, fee, inviterPer);
    }
    function getConfig() external override view returns (Config memory){
        return config;
    }

    function tokenSize() external override view returns (uint size){
        size = allToken.length;
    }
    //return token list[from,to)
    function getTokens(uint from, uint to) external override view returns (address[] memory){
        if(to > allToken.length){
            to = allToken.length;
        }
        require(from <= to, "DC2CFactory: FROM_INVALID");

        address[] memory ret = new address[](to-from);
        uint i = from;
        for(; i < to; i++){
            ret[i-from] = allToken[i];
        }
        return ret;
    }

    function getInviter(address account) external override view returns (address){
        return inviters[account];
    }
    function setInviter(address account, address inviter) external override onlyPool returns (bool){
        if(inviters[account] == address(0)) {
            if(inviter == address(0)){
                inviter = account;
            }
            inviters[account] = inviter;
            accCnt+=1;
        }
        return true;
    }
    function setInviterCode(bytes8 code) public {
        require(inviter2Code[msg.sender] == "", "DC2CFactory: CODE_EXIST");
        require(code2Inviter[code] == address(0), "DC2CFactory: INVITER_EXIST");
        inviter2Code[msg.sender] = code;
        code2Inviter[code] = msg.sender;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity  ^0.8.9;

interface IDC2CFactory {

    struct Config{
        address org;
        uint256 fee; // feeRatio = fee / 1000
        uint256 returnPer; //percent value of fee will return to payer and stockholder and inviter
        uint256 oldPer; //percent value of returnPer will return to old stockholder
        uint256 inviterPer;//percent of returnPer token will be send to inviter
        uint256 topNum;
    }

    event DC2CPoolCreated(address token);

    //deploy DC2CPool
    function createPool(
        address token//external token,eg: USDT
    ) external returns (bool);

    function setConfig(address org, uint256 fee,  uint256 returnPer, uint256 oldPer,  uint256 inviterPer, uint256 topNum) external;
    function getConfig() external view returns (Config memory);
    function getDC2CPool(address token) external view returns (address);
    function getDToken(address token) external view returns (address);

    function tokenSize() external view returns (uint size);
    //return token list[from,to)
    function getTokens(uint from, uint to) external view returns (address[] memory);

    function getInviter(address account) external view returns (address);
    function setInviter(address account, address inviter) external returns (bool);

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.9;

interface IDC2CDeployer {
    function develop(address factory, address token) external returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

abstract contract Ownable {
    address public owner;
    address public governor;//reserve authority management for contract governance

    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event GovernorChanged(address indexed oldOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;     // default sender
        governor = owner; //default owner
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    modifier onlyGovernor{
        require(governor == msg.sender, "Ownable: caller is not the governor");
        _;
    }

    //update owner
    function setOwner(address _owner) external virtual onlyOwner{
        require(_owner != address(0), "Ownable: new owner is the zero address");
        address oldOwner = _owner;
        owner = _owner;
        emit OwnerChanged(oldOwner, _owner);
    }

    //update governor
    function setGovernor(address _governor) external virtual onlyOwner{
        require(_governor != address(0), "Ownable: new governor is the zero address");
        address oldGovernor = _governor;
        governor = _governor;
        emit OwnerChanged(oldGovernor, _governor);
    }
}