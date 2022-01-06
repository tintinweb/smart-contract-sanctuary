// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;
 
import "./Initializable.sol";
 
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
 
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
}
 
/**
 * interfaces from here
 **/
 
interface IRandom {
    function getRandom(address adrSeed, uint n) external returns (uint[] memory);
}

/**
 * interfaces to here
 **/
 
contract UpFinityLottery is Initializable {
    using SafeMath for uint256;
 
    // Upgradable Contract Test
    uint public _uptest;
 
    // My Basic Variables
    address public _owner;
    address public _token;
 
    /**
     * vars and events from here
     **/
    mapping(address => uint256) public _balance;
    
    event GotLotteryNumber(uint lotteryNumber);
    event WinPrize(uint prize);
    /**
     * vars and events to here
     **/
 
    fallback() external payable {}
    receive() external payable {}
 
    modifier onlyOwner {
        require(_owner == msg.sender, 'Only Owner can do this!!!!!');
        _;
    }
 
    // constructor() {
    //     _owner = msg.sender;
    // }
 
    function initialize(address owner_) public initializer {
        _owner = owner_;
 
        /**
         * inits from here
         **/
 
        //_token = token_;        

        /**
         * inits to here
         **/
    }
 
    function setUptest(uint uptest_) external {
        _uptest = uptest_;
    }
 
    function setToken(address token_) external onlyOwner {
        _token = token_;
    }
 
    /**
     * functions from here
     **/
     
    function getLottery(uint n) external returns (uint) {
        // Upfinity RNG
        address URNG = address(0x14a346835eDC99e8E82F2905BAef87Aa0fAc36f2);
        uint[] memory lotteryNumbers = IRandom(URNG).getRandom(msg.sender, n);
 
        uint totalPrize = 0;
        for (uint i = 0; i < n; i++) {
            uint lotteryNumber = lotteryNumbers[i];
            lotteryNumber = lotteryNumber.mod(10000);

            emit GotLotteryNumber(lotteryNumber);
            
            uint16[5] memory probs = [5000, 1200, 400, 100, 3300];
            uint totalProb = 0;
            uint8[5] memory prizes = [0, 1, 2, 5, 10];
            for (uint j = 0; j < 5; j++) {
                uint prob = uint(probs[j]);
                totalProb = totalProb.add(prob);

                if (lotteryNumber < totalProb) {
                    uint prize = uint(prizes[j]);
                    totalPrize = totalPrize.add(prize);
                    
                    emit WinPrize(prize);

                    break;
                }
            }
 
        }
 
        return totalPrize;
    }
}