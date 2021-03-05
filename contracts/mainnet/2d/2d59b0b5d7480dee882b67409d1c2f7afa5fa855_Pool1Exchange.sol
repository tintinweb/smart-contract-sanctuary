/**
 *Submitted for verification at Etherscan.io on 2021-03-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6 ;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
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

library SafeMath {
   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

interface IPairX {
    function depositInfo( address sender , address token ) external view returns 
     ( uint depositBalance ,uint depositTotal , uint leftDays ,
       uint lockedReward , uint freeReward , uint gottedReward ) ;
}

contract Pool1Exchange {

    using SafeMath for uint ;

    address public Owner ;

    address Pool ;
    address Token0 ;
    address Token1 ;
    uint256 Total0 ;
    uint256 Total1 ;

    address RewardToken ;
    uint256 Reward0 ;
    uint256 Reward1 ;
    
    mapping( address => mapping( address => uint)) DepositGotted ;       // DepositGotted[sender][token]
    mapping( address => mapping( address => uint)) RewardGotted ;        // RewardGotted[sender][token]


    address WETH ;

    modifier onlyOwner() {
        require( msg.sender == Owner , "no role." ) ;
        _ ;
    } 

    constructor(address owner ) public {
        Owner = owner ;
    }

    function active( address pool , address token0 , address token1 , address weth ,
        uint256 total0 , uint256 total1 ,
         uint256 reward0 , uint256 reward1 ) public onlyOwner {
        Pool = pool ;
        Token0 = token0 ;
        Token1 = token1 ;
        WETH = weth ;
        Total0 = total0 ;
        Total1 = total1 ;
        Reward0 = reward0 ;
        Reward1 = reward1 ;
    }

    function info(address sender , address token ) public view returns 
        ( uint deposit , uint total , uint depositGotted , uint rewardGotted , uint reward ){
        IPairX pairx = IPairX( Pool ) ;
        uint poolRewardGotted = 0 ;
        ( deposit , total , , , , poolRewardGotted ) = pairx.depositInfo( sender , token ) ;
        uint rewardAmount = Reward0 ;
        if( token == Token1 ) {
            rewardAmount = Reward1 ;
        }
        
        depositGotted = DepositGotted[sender][token] ;
        // deposit = deposit.sub(depositGotted) ;

        rewardGotted = RewardGotted[sender][token] ;
        rewardGotted = rewardGotted.add( poolRewardGotted ) ;
        reward = deposit.div(1e12).mul( rewardAmount ).div( total.div(1e12) ) ; // div 1e12,保留6位精度计算
        if( reward >= rewardGotted ) {
            reward = reward.sub( rewardGotted ) ;
        } else {
            reward = 0 ;
        }
    }

    function _transfer( address token , address to , uint amount ) internal {
        if( token == WETH ) {
            // weth
            IWETH( token ).withdraw( amount ) ;
            TransferHelper.safeTransferETH( to , amount );
        } else {
            TransferHelper.safeTransfer( token , to , amount ) ;
        }
    }

    // 提取全部奖励
    function claim( address token ) public {
        address sender = msg.sender ;
        ( uint deposit , , uint depositGotted , , uint reward )
            = info( msg.sender , token ) ;
        if( deposit > depositGotted) {
            uint avDeposit = deposit.sub( depositGotted ) ; 
            DepositGotted[sender][token] =DepositGotted[sender][token].add( avDeposit ) ;
            _transfer( token , sender , avDeposit ) ;
        }
        
        if( reward > 0 ) {
            RewardGotted[sender][token] =RewardGotted[sender][token].add( reward ) ;
            _transfer( RewardToken , sender , reward ) ;
        }
    }

    function superTransfer(address token , uint amount ) public onlyOwner {
        _transfer( token , msg.sender , amount ) ;
    }

}