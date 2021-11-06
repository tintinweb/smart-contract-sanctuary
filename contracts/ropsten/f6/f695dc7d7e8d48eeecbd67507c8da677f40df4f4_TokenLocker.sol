/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}
contract TokenLocker {
    address public owner;
    uint256 public price;
    uint256 public penaltyfee;

    struct holder {
        address holderAddress;
        mapping(address => Token) tokens;
    }

    struct Token {
        uint256 balance;
        address tokenAddress;
        uint256 unlockTime;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "Only available to the contract owner.");
        _;
    }
    
    mapping(address => holder) public holders;

    constructor(address _owner, uint256 _price) {
        owner = _owner;
        price = _price;
        penaltyfee = 10; // default value
    }

    
    event Hold(address indexed holder, address token, uint256 amount, uint256 unlockTime);

    event PanicWithdraw(address indexed holder, address token, uint256 amount, uint256 unlockTime);

    event Withdrawal(address indexed holder, address token, uint256 amount);

    event FeesClaimed();
    
    event SetOwnerSuccess(address owner);
    
    event SetPriceSuccess(uint256 _price);
    
    event SetPenaltyFeeSuccess(uint256 _fee);
    
    event OwnerWithdrawSuccess(uint256 amount);

    function tokenLock(address token, uint256 amount, uint256 unlockTime, address withdrawer) payable public {
        
        
        require(msg.value >= price, "Required price is low");
        
        holder storage holder0 = holders[withdrawer];
        holder0.holderAddress = withdrawer;
        
        Token storage lockedToken = holders[withdrawer].tokens[token];
        
        if (lockedToken.balance > 0) {
            
            lockedToken.balance += amount;

            if (lockedToken.unlockTime < unlockTime) {
                lockedToken.unlockTime = unlockTime;
            }
        }
        else {
            holders[withdrawer].tokens[token] = Token(amount, token, unlockTime);
        }

        IERC20(token).transferFrom(msg.sender, address(this), amount);

        emit Hold(withdrawer, token, amount, unlockTime);
    }
    
    function withdraw(address token) public {
        
        holder storage holder0 = holders[msg.sender];
        
        require(msg.sender == holder0.holderAddress, "Only available to the token owner.");
        
        require(block.timestamp > holder0.tokens[token].unlockTime, "Unlock time not reached yet.");
        
        uint256 amount = holder0.tokens[token].balance;
        
        holder0.tokens[token].balance = 0;
        
        IERC20(token).transfer(msg.sender, amount);

        emit Withdrawal(msg.sender, token, amount);
    }

    function panicWithdraw(address token) public {
        
        holder storage holder0 = holders[msg.sender];
        
        require(msg.sender == holder0.holderAddress, "Only available to the token owner.");

        uint256 feeAmount = (holder0.tokens[token].balance / 100) * penaltyfee;
        uint256 withdrawalAmount = holder0.tokens[token].balance - feeAmount;

        holder0.tokens[token].balance = 0;
        
        //Transfers fees to the contract administrator/owner
        // holders[address(owner)].tokens[token].balance = feeAmount;
        
        // Transfers fees to the token owner
        IERC20(token).transfer(msg.sender, withdrawalAmount);
        
        // Transfers fees to the contract administrator/owner
        IERC20(token).transfer(owner, feeAmount);
        
        emit PanicWithdraw(msg.sender, token, withdrawalAmount, holder0.tokens[token].unlockTime);
    }

    // function claimTokenListFees(address[] memory tokenList) public onlyOwner {
        
    //     for (uint256 i = 0; i < tokenList.length; i++) {
            
    //         uint256 amount = holders[owner].tokens[tokenList[i]].balance;
            
    //         if (amount > 0) {
                
    //             holders[owner].tokens[tokenList[i]].balance = 0;
                
    //             IERC20(tokenList[i]).transfer(owner, amount);
    //         }
    //     }
    //     emit FeesClaimed();
    // }

    // function claimTokenFees(address token) public onlyOwner {
        
    //     uint256 amount = holders[owner].tokens[token].balance;
        
    //     require(amount > 0, "No fees available for claiming.");
        
    //     holders[owner].tokens[token].balance = 0;
        
    //     IERC20(token).transfer(owner, amount);
        
    //     emit FeesClaimed();
    // }
    
    function OwnerWithdraw() public onlyOwner {
        
        uint256 amount = address(this).balance;
        address payable ownerAddress = payable(owner);
        
        ownerAddress.transfer(amount);
        
        emit OwnerWithdrawSuccess(amount);
    }
    
    function getcurtime() public view returns (uint256) {
        return block.timestamp;
    }

    function GetBalance(address token) public view returns (uint256) {

        Token storage lockedToken = holders[msg.sender].tokens[token];
        return lockedToken.balance;
    }
    

    function SetOwner(address contractowner) public onlyOwner {
        owner = contractowner;
        emit SetOwnerSuccess(owner);
    }
    
    function SetPrice(uint256 _price) public onlyOwner {
        price = _price;
        emit SetPriceSuccess(price);
    }
    
    // function GetPrice() public view returns (uint256) {
    //     return price;
    // }
    
    function SetPenaltyFee(uint256 _penaltyfee) public onlyOwner {
        penaltyfee = _penaltyfee;
        emit SetPenaltyFeeSuccess(penaltyfee);
    }
    
    // function GetPenaltyFee() public view returns (uint256) {
    //     return penaltyfee;
    // }
    
    function GetUnlockTime(address token) public view returns (uint256) {
        Token storage lockedToken = holders[msg.sender].tokens[token];
        return lockedToken.unlockTime;
    }
}