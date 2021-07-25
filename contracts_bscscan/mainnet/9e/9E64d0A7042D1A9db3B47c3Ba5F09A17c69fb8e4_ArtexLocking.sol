/**
 *Submitted for verification at BscScan.com on 2021-07-25
*/

pragma solidity ^0.5.12;

interface ERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
}

contract ArtexLocking {
    using SafeMath for uint256;
    ERC20 public artexToken;

    uint256 public teamAllocation;

    uint256 public teamTimeLock;

    address payable public governance;

    constructor(address payable _governance, ERC20 _artexToken) public {
        governance = _governance;
        artexToken = _artexToken;
  
        teamAllocation = SafeMath.mul(10000000, 10**(18)); // 10 million  - 2 year lock
        
        teamTimeLock = SafeMath.add(now, 730 days);
       
       
    }
    
    
    function releaseTeamTokens() public returns (bool success) {
        require(msg.sender == governance, "!governance");
        require(now >= teamTimeLock, "!tokens cannot be withdrawn now");

        require(
            artexToken.transfer(governance, teamAllocation),
            "Transfer not successful"
        );

        return true;
    }


    function setGovernance(address payable _governance)
        public
        returns (bool success)
    {
        require(msg.sender == governance, "!governance");
        governance = _governance;

        return true;
    }

    function emergencyExit(uint256 _tokens) public returns (bool success) {
        require(msg.sender == governance, "Only authorized method !");
        require(
            artexToken.transfer(governance, _tokens),
            "Transfer not successful"
        );

        return true;
    }
}