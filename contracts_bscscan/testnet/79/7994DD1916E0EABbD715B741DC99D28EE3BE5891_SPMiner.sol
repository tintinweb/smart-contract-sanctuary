// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ReentrancyGuard.sol";
import "./SPMinerDefine.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";


contract SPMiner is ReentrancyGuard, SPMinerDefine, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public usdt; 
    address public constant dead = 0x000000000000000000000000000000000000dEaD;
    address public feeOwner;
    address public primaryAddr;

    uint256 public startBlock;
    uint256 public constant price1 = 2e18;          // 1 usdt = 2 spot  
    uint256 public constant maxAmount1 = 296100e18;
    uint256 public amount1;     
    uint256 public constant price2 = 1.4286e18;     // 1 usdt = 1.4286 spot
    uint256 public constant maxAmount2 = 296100e18; 
    uint256 public amount2;
    uint256 public constant price3 = 1.1111e18;     // 1 usdt = 1.1111 spot
    uint256 public constant maxAmount3 = 394800e18; 
    uint256 public amount3;

    uint256 public constant blocksPerDay = 28800;
    uint256 public constant period = 28800 * 10;

    struct user {
        uint256 id;
        uint256 option;
        address referrer;
    }
    
    mapping(address => address[]) _mychilders;
    mapping(address => user) public users;
    mapping(uint256 => address) public index2User;
    uint256 public userCount = 0;       

    event Register(address indexed _userAddr, address indexed _referrer);   
    event Option(address indexed _userAddr, uint256 _option); 


    constructor (IERC20 _usdt, uint256 _startBlock,address _feeOwner, address _primaryAddr) public {
        usdt = _usdt;
        startBlock = _startBlock;
        feeOwner = _feeOwner;
        primaryAddr = _primaryAddr;

        userCount = userCount.add(1);
        users[primaryAddr].id = userCount;
    }


    /**
     * user register
     */
    function register(address _referrer) public {
        require(!Address.isContract(msg.sender), "SPM: the address is contract address ");
        require(!isExists(msg.sender), "SPM: user exists");
        require(isExists(_referrer), "SPM: referrer not exists");
        user storage regUser = users[msg.sender];
        userCount = userCount.add(1);
        regUser.id = userCount;
        index2User[userCount] = msg.sender;
        regUser.referrer = _referrer;

        _mychilders[_referrer].push(msg.sender);
        
        emit Register(msg.sender, _referrer);
    }


    /**
     * user buy option
     */
    function option(uint256 _amount) public {
        uint256 blockNumber = block.number;
        require(blockNumber > startBlock, "SPM: this activaty is not start.");
        require(blockNumber < startBlock.add(period.mul(3)), "SPM: this activaty is end.");
       
        uint256 _p  = (blockNumber-startBlock)/period;      
        uint256 price = price1;     // 0 == _p
        if( 1 == _p ){
            price = price2;
        }else{
            price = price3;
        }
        uint256 _option = _amount.mul(price);

        users[msg.sender].option = _option;
        // transfer usdt 
        require(usdt.balanceOf(msg.sender) >= _option, "SPM: usdt is not enough");
        transferFee(usdt, _amount);

        emit Option(msg.sender, _amount);
    }
    

    function transferFee(IERC20 token, uint256 fee) internal {
        if(address(token)==address(usdt)) {
            token.safeTransfer(feeOwner,fee);
        }
    }


    function isExists(address _userAddr) view public returns (bool) {
        return users[_userAddr].id != 0;
    }


    function getMyChilders(address _userAddr) public view returns (address[] memory)
    {
        return _mychilders[_userAddr];
    }

    
    function setFeeOwner (address _userAddr) public onlyOwner {
        require(!Address.isContract(msg.sender), "SPM: the address is contract address ");
        feeOwner = _userAddr;
    }


}