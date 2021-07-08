/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
  
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IBEP20 {
   
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

contract AirdropAndBuy {
    using SafeMath for uint256;
    
    IBEP20 token;
    address[] private _airaddress;
    
    struct AirdropList{
        mapping(address => bool) airtoken_;
    }
    
    
    AirdropList[] private adList;
    
    uint256 private lastAirdropIndex = 0;
    uint256 public airtoken = 500 * 10**18;
    uint256 public MaxNoOfReceiver = 40000;
    uint256 public tokenRate = 1 * 10 ** 16;
    address payable private owner_;
    
    modifier onlyOwner {
        require(msg.sender == owner_);
        _;
    }
    
    constructor() {
        owner_ = payable(msg.sender);
        token = IBEP20(0x703e43C81C635D997085877f02d0B6d822556AF8);
        adList.push();
    } 
    
    // No of Token User receive in Airdrop 
    function NoOfTokenUserReceive(uint256 _airtoken) public onlyOwner returns(bool) {
        airtoken = _airtoken;
        return true;
    }
    
    // How mucch amount is allowed to this contract by the Admin to use
    function CheckAllowance() public view returns(uint256) {
        return token.allowance(owner_, address(this));
    }
    
    // If the Owner want to create a new airdrop
    function CreateNewAirdrop(uint256 _NumberOfTokensPerUser, uint256 _MaxNoOfReceiver) public onlyOwner {
        MaxNoOfReceiver = _MaxNoOfReceiver;
        airtoken = _NumberOfTokensPerUser;
        adList.push();
        lastAirdropIndex++;
    }
    
    // Change the Token address of the contract
    function changeTokenContract(address _tokenAddress) public onlyOwner {
        token = IBEP20(_tokenAddress);
    }
    
    // Max No Of User who receive the Clik token 
    function ReceiverMaxNoOfUser(uint256 _MaxNoOfReceiver) public onlyOwner {
        MaxNoOfReceiver += _MaxNoOfReceiver; 
    }
    
    // Use to initate the airdrop to each user
    function Airdrop(address _refaddress) public {
        require(_refaddress == msg.sender, "Address Not Match");
        require(adList[lastAirdropIndex].airtoken_[msg.sender] != true,"Already Collected!");
        require(CheckAllowance() >= airtoken, "Less Supply");
        require(MaxNoOfReceiver !=  0,"Allowed Limit Reeached");
        
        token.transferFrom(owner_, msg.sender, airtoken);
        
        MaxNoOfReceiver--;
        adList[lastAirdropIndex].airtoken_[msg.sender] = true;
    }
    
    // Rate of the token 
     function ratetoken(uint256 _rate) public virtual onlyOwner returns (bool) {
        tokenRate = _rate;
        return true;
    }
    
    // User can buy Token use this
    function buyToken() public payable {
        require(msg.sender != address(0), "Zero address");
        uint256 bnbValue = msg.value;
        require (bnbValue > 0, "Zero Amount!");
        uint256 tokens = bnbValue.div(tokenRate) * 10**18;
        owner_.transfer(msg.value);
        token.transferFrom(owner_, msg.sender, tokens);
    }
}